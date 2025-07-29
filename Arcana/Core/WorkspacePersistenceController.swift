//
// Core/WorkspacePersistenceController.swift
// Arcana
//

import Foundation
import OSLog

actor WorkspacePersistenceController {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "Persistence")
    private let fileManager = FileManager.default
    private var documentsDirectory: URL
    private var workspacesDirectory: URL
    private var threadsDirectory: URL
    
    init() {
        self.documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.workspacesDirectory = documentsDirectory.appendingPathComponent("Workspaces")
        self.threadsDirectory = documentsDirectory.appendingPathComponent("Threads")
    }
    
    func initialize() async throws {
        try createDirectoriesIfNeeded()
        logger.info("Persistence controller initialized")
    }
    
    // MARK: - Workspace Persistence
    
    func loadWorkspaces() async throws -> [Project] {
        let workspaceFiles = try fileManager.contentsOfDirectory(at: workspacesDirectory, includingPropertiesForKeys: nil)
        var workspaces: [Project] = []
        
        for file in workspaceFiles where file.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: file)
                let workspace = try JSONDecoder().decode(Project.self, from: data)
                workspaces.append(workspace)
            } catch {
                logger.error("Failed to load workspace from \(file.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        return workspaces.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func saveWorkspace(_ workspace: Project) async throws {
        let filename = "\(workspace.id.uuidString).json"
        let fileURL = workspacesDirectory.appendingPathComponent(filename)
        
        let data = try JSONEncoder().encode(workspace)
        try data.write(to: fileURL)
        
        logger.debug("Saved workspace: \(workspace.name)")
    }
    
    func updateWorkspace(_ workspace: Project) async throws {
        try await saveWorkspace(workspace)
    }
    
    func deleteWorkspace(_ workspaceId: UUID) async throws {
        let filename = "\(workspaceId.uuidString).json"
        let fileURL = workspacesDirectory.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
            logger.debug("Deleted workspace: \(workspaceId)")
        }
    }
    
    // MARK: - Thread Persistence
    
    func loadThreads() async throws -> [ChatThread] {
        let threadFiles = try fileManager.contentsOfDirectory(at: threadsDirectory, includingPropertiesForKeys: nil)
        var threads: [ChatThread] = []
        
        for file in threadFiles where file.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: file)
                let thread = try JSONDecoder().decode(ChatThread.self, from: data)
                threads.append(thread)
            } catch {
                logger.error("Failed to load thread from \(file.lastPathComponent): \(error.localizedDescription)")
            }
        }
        
        return threads.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    func saveThread(_ thread: ChatThread) async throws {
        let filename = "\(thread.id.uuidString).json"
        let fileURL = threadsDirectory.appendingPathComponent(filename)
        
        let data = try JSONEncoder().encode(thread)
        try data.write(to: fileURL)
        
        logger.debug("Saved thread: \(thread.title)")
    }
    
    func updateThread(_ thread: ChatThread) async throws {
        try await saveThread(thread)
    }
    
    func deleteThread(_ threadId: UUID) async throws {
        let filename = "\(threadId.uuidString).json"
        let fileURL = threadsDirectory.appendingPathComponent(filename)
        
        if fileManager.fileExists(atPath: fileURL.path) {
            try fileManager.removeItem(at: fileURL)
            logger.debug("Deleted thread: \(threadId)")
        }
    }
    
    // MARK: - Private Methods
    
    private func createDirectoriesIfNeeded() throws {
        let directories = [workspacesDirectory, threadsDirectory]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }
        }
    }
}
