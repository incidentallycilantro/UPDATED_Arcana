//
// Models/ChatMessage.swift
// Arcana
//

import Foundation

struct ChatMessage: Codable, Hashable, Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let threadId: UUID
    let workspaceId: UUID
    let confidence: Double?
    let metadata: [String: String]?
    let processingTime: TimeInterval?
    let modelUsed: String?
    
    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        threadId: UUID,
        workspaceId: UUID,
        confidence: Double? = nil,
        metadata: [String: String]? = nil,
        processingTime: TimeInterval? = nil,
        modelUsed: String? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.threadId = threadId
        self.workspaceId = workspaceId
        self.confidence = confidence
        self.metadata = metadata
        self.processingTime = processingTime
        self.modelUsed = modelUsed
    }
    
    var isFromUser: Bool {
        return role == .user
    }
    
    var isFromAssistant: Bool {
        return role == .assistant
    }
    
    var hasHighConfidence: Bool {
        return (confidence ?? 0.0) > 0.8
    }
    
    var displayTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}
