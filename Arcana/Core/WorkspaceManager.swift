//
// Core/WorkspaceManager.swift
// Arcana
//

import Foundation
import Combine
import OSLog

@MainActor
class WorkspaceManager: ObservableObject {
    static let shared = WorkspaceManager()
    @Published var workspaces: [Project] = []
    @Published var currentWorkspace: Project?
    @Published var isLoading = false
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "WorkspaceManager")
    private let persistenceController: WorkspacePersistenceController
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.persistenceController = WorkspacePersistenceController()
        setupWorkspaceMonitoring()
    }
    
    func initialize() async throws {
        logger.info("Initializing Workspace Manager...")
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            // Initialize persistence controller
            try await persistenceController.initialize()
            
            // Load existing workspaces
            let loadedWorkspaces = try await persistenceController.loadWorkspaces()
            
            await MainActor.run {
                self.workspaces = loadedWorkspaces
                
                // Set current workspace to the most recently used
                self.currentWorkspace = loadedWorkspaces.max { $0.updatedAt < $1.updatedAt }
                
                self.isLoading = false
            }
            
            logger.info("Loaded \(loadedWorkspaces.count) workspaces")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            logger.error("Failed to initialize WorkspaceManager: \(error.localizedDescription)")
            throw error
        }
    }
    
    func createWorkspace(name: String, type: WorkspaceType, description: String = "") async throws -> Project {
        logger.info("Creating new workspace: \(name) (\(type.displayName))")
        
        let newWorkspace = Project(
            name: name,
            description: description,
            workspaceType: type,
            settings: ProjectSettings(
                enableWebResearch: type == .research,
                privacyLevel: .maximum
            )
        )
        
        // Save to persistence
        try await persistenceController.saveWorkspace(newWorkspace)
        
        await MainActor.run {
            self.workspaces.append(newWorkspace)
            self.currentWorkspace = newWorkspace
        }
        
        logger.info("Created workspace: \(newWorkspace.id)")
        return newWorkspace
    }
    
    // MARK: - Additional Methods for MainView Compatibility
    
    /// Create workspace with synchronous interface for MainView (compatibility method)
    func createWorkspace(name: String, type: WorkspaceType, description: String = "") -> Project {
        logger.info("Creating workspace (sync): \(name)")
        
        let workspace = Project(
            name: name,
            description: description,
            workspaceType: type,
            settings: ProjectSettings(
                enableWebResearch: type == .research,
                privacyLevel: .maximum
            )
        )
        
        // Add to array immediately for UI responsiveness
        workspaces.append(workspace)
        workspaces.sort { $0.updatedAt > $1.updatedAt }
        
        // Save asynchronously
        Task {
            do {
                try await persistenceController.saveWorkspace(workspace)
                logger.info("Workspace saved: \(workspace.displayName)")
            } catch {
                logger.error("Failed to save workspace: \(error.localizedDescription)")
                // Remove from array if save failed
                await MainActor.run {
                    self.workspaces.removeAll { $0.id == workspace.id }
                }
            }
        }
        
        return workspace
    }
    
    /// Get workspace by ID (utility method)
    func getWorkspaceById(_ id: UUID) -> Project? {
        return workspaces.first { $0.id == id }
    }
    
    func updateWorkspace(_ workspace: Project) async throws {
        logger.debug("Updating workspace: \(workspace.name)")
        
        // Save to persistence
        try await persistenceController.updateWorkspace(workspace)
        
        await MainActor.run {
            if let index = self.workspaces.firstIndex(where: { $0.id == workspace.id }) {
                self.workspaces[index] = workspace
            }
            
            if self.currentWorkspace?.id == workspace.id {
                self.currentWorkspace = workspace
            }
        }
    }
    
    func deleteWorkspace(_ workspace: Project) async throws {
        logger.info("Deleting workspace: \(workspace.name)")
        
        // Mark as deleted in persistence
        try await persistenceController.deleteWorkspace(workspace.id)
        
        await MainActor.run {
            self.workspaces.removeAll { $0.id == workspace.id }
            
            if self.currentWorkspace?.id == workspace.id {
                self.currentWorkspace = self.workspaces.first
            }
        }
    }
    
    func selectWorkspace(_ workspace: Project) {
        logger.debug("Selecting workspace: \(workspace.name)")
        
        currentWorkspace = workspace
        
        // Update last accessed time
        Task {
            try await updateWorkspace(workspace)
        }
    }
    
    func getWorkspacesByType(_ type: WorkspaceType) -> [Project] {
        return workspaces.filter { $0.workspaceType == type }
    }
    
    func getRecentWorkspaces(limit: Int = 10) -> [Project] {
        return Array(workspaces.sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
    }
    
    func searchWorkspaces(_ query: String) -> [Project] {
        guard !query.isEmpty else { return workspaces }
        
        return workspaces.filter { workspace in
            workspace.name.localizedCaseInsensitiveContains(query) ||
            workspace.description.localizedCaseInsensitiveContains(query)
        }
    }
    
    private func setupWorkspaceMonitoring() {
        // Monitor workspace changes and auto-save
        $workspaces
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] workspaces in
                Task {
                    await self?.autoSaveWorkspaces(workspaces)
                }
            }
            .store(in: &cancellables)
    }
    
    private func autoSaveWorkspaces(_ workspaces: [Project]) async {
        do {
            for workspace in workspaces where workspace.settings.autoSave {
                try await persistenceController.saveWorkspace(workspace)
            }
        } catch {
            logger.error("Auto-save failed: \(error.localizedDescription)")
        }
    }
}
