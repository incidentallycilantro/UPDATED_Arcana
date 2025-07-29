//
// Models/ChatThread.swift
// Arcana
//

import Foundation

struct ChatThread: Codable, Hashable, Identifiable {
    let id: UUID
    let title: String
    let workspaceId: UUID
    let workspaceType: WorkspaceType
    let messages: [ChatMessage]
    let status: ThreadStatus
    let createdAt: Date
    let updatedAt: Date
    let metadata: ThreadMetadata?
    public let creationDate: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        workspaceId: UUID,
        workspaceType: WorkspaceType,
        messages: [ChatMessage] = [],
        status: ThreadStatus = .active,
        metadata: ThreadMetadata? = nil
    ) {
        self.id = id
        self.title = title
        self.workspaceId = workspaceId
        self.workspaceType = workspaceType
        self.messages = messages
        self.status = status
        self.createdAt = Date()
        self.updatedAt = Date()
        self.metadata = metadata
    }
    
    var lastMessage: ChatMessage? {
        return messages.last
    }
    
    var messageCount: Int {
        return messages.count
    }
    
    var userMessageCount: Int {
        return messages.filter { $0.role == .user }.count
    }
    
    var assistantMessageCount: Int {
        return messages.filter { $0.role == .assistant }.count
    }
    
    var averageConfidence: Double {
        let confidenceValues = messages.compactMap { $0.confidence }
        guard !confidenceValues.isEmpty else { return 0.0 }
        return confidenceValues.reduce(0, +) / Double(confidenceValues.count)
    }
    
    var isActive: Bool {
        return status == .active
    }
    
    func adding(message: ChatMessage) -> ChatThread {
        var newMessages = messages
        newMessages.append(message)
        
        return ChatThread(
            id: id,
            title: title,
            workspaceId: workspaceId,
            workspaceType: workspaceType,
            messages: newMessages,
            status: status,
            metadata: metadata
        )
    }
}

struct ThreadMetadata: Codable, Hashable {
    let tags: [String]
    let priority: ThreadPriority
    let estimatedDuration: TimeInterval?
    let complexity: ThreadComplexity
    let privacy: ThreadPrivacy
    
    init(
        tags: [String] = [],
        priority: ThreadPriority = .normal,
        estimatedDuration: TimeInterval? = nil,
        complexity: ThreadComplexity = .medium,
        privacy: ThreadPrivacy = .standard
    ) {
        self.tags = tags
        self.priority = priority
        self.estimatedDuration = estimatedDuration
        self.complexity = complexity
        self.privacy = privacy
    }
}

enum ThreadPriority: String, Codable, CaseIterable {
    case low = "low"
    case normal = "normal"
    case high = "high"
    case urgent = "urgent"
}

enum ThreadComplexity: String, Codable, CaseIterable {
    case simple = "simple"
    case medium = "medium"
    case complex = "complex"
    case expert = "expert"
}

enum ThreadPrivacy: String, Codable, CaseIterable {
    case standard = "standard"
    case enhanced = "enhanced"
    case maximum = "maximum"
}
