//
// Core/ThreadManager.swift
// Arcana
//

import Foundation
import Combine
import OSLog

@MainActor
class ThreadManager: ObservableObject {
    static let shared = ThreadManager()
    @Published var threads: [ChatThread] = []
    @Published var currentThread: ChatThread?
    @Published var isLoading = false
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ThreadManager")
    private let persistenceController: WorkspacePersistenceController
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.persistenceController = WorkspacePersistenceController()
        setupThreadMonitoring()
    }
    
    func initialize() async throws {
        logger.info("Initializing Thread Manager...")
        
        await MainActor.run {
            self.isLoading = true
        }
        
        do {
            try await persistenceController.initialize()
            
            let loadedThreads = try await persistenceController.loadThreads()
            
            await MainActor.run {
                self.threads = loadedThreads
                self.currentThread = loadedThreads.first { $0.status == .active }
                self.isLoading = false
            }
            
            logger.info("Loaded \(loadedThreads.count) threads")
            
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
            throw error
        }
    }
    
    func createThread(title: String, workspaceId: UUID, workspaceType: WorkspaceType) async throws -> ChatThread {
        logger.info("Creating new thread: \(title)")
        
        let newThread = ChatThread(
            title: title,
            workspaceId: workspaceId,
            workspaceType: workspaceType,
            metadata: ThreadMetadata(
                priority: .normal,
                complexity: .medium,
                privacy: .standard
            )
        )
        
        try await persistenceController.saveThread(newThread)
        
        await MainActor.run {
            self.threads.append(newThread)
            self.currentThread = newThread
        }
        
        return newThread
    }
    
    // MARK: - Additional Methods for MainView Compatibility
    
    /// Create a new thread for a specific workspace (MainView compatibility method)
    func createThread(in workspace: Project) async throws -> ChatThread {
        logger.info("Creating thread in workspace: \(workspace.displayName)")
        
        let newThread = ChatThread(
            title: "New Thread",
            workspaceId: workspace.id,
            workspaceType: workspace.workspaceType,
            metadata: ThreadMetadata(
                priority: .normal,
                complexity: .medium,
                privacy: .standard
            )
        )
        
        try await persistenceController.saveThread(newThread)
        
        await MainActor.run {
            self.threads.append(newThread)
            self.currentThread = newThread
        }
        
        return newThread
    }
    
    func addMessage(to threadId: UUID, message: ChatMessage) async throws {
        logger.debug("Adding message to thread: \(threadId)")
        
        guard let threadIndex = threads.firstIndex(where: { $0.id == threadId }) else {
            throw ArcanaError.configurationError("Thread not found: \(threadId)")
        }
        
        let updatedThread = threads[threadIndex].adding(message: message)
        
        try await persistenceController.updateThread(updatedThread)
        
        await MainActor.run {
            self.threads[threadIndex] = updatedThread
            
            if self.currentThread?.id == threadId {
                self.currentThread = updatedThread
            }
        }
    }
    
    func getThreadsForWorkspace(_ workspaceId: UUID) -> [ChatThread] {
        return threads.filter { $0.workspaceId == workspaceId && $0.status == .active }
    }
    
    func selectThread(_ thread: ChatThread) {
        logger.debug("Selecting thread: \(thread.title)")
        currentThread = thread
    }
    
    func deleteThread(_ threadId: UUID) async throws {
        logger.info("Deleting thread: \(threadId)")
        
        guard let threadIndex = threads.firstIndex(where: { $0.id == threadId }) else {
            return
        }
        
        try await persistenceController.deleteThread(threadId)
        
        await MainActor.run {
            self.threads.remove(at: threadIndex)
            
            if self.currentThread?.id == threadId {
                self.currentThread = self.threads.first { $0.status == .active }
            }
        }
    }
    
    func searchThreads(_ query: String) -> [ChatThread] {
        guard !query.isEmpty else { return threads }
        
        return threads.filter { thread in
            thread.title.localizedCaseInsensitiveContains(query) ||
            thread.messages.contains { message in
                message.content.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    private func setupThreadMonitoring() {
        $threads
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] threads in
                Task {
                    await self?.autoSaveThreads(threads)
                }
            }
            .store(in: &cancellables)
    }
    
    private func autoSaveThreads(_ threads: [ChatThread]) async {
        do {
            for thread in threads where thread.status == .active {
                try await persistenceController.saveThread(thread)
            }
        } catch {
            logger.error("Thread auto-save failed: \(error.localizedDescription)")
        }
    }
}
