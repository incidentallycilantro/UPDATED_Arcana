//
// Models/Project.swift
// Arcana
//

import Foundation

struct Project: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let workspaceType: WorkspaceType
    let threads: [UUID] // Thread IDs
    let createdAt: Date
    let updatedAt: Date
    let status: ProjectStatus
    let settings: ProjectSettings
    let statistics: ProjectStatistics
    public let creationDate: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        workspaceType: WorkspaceType,
        threads: [UUID] = [],
        status: ProjectStatus = .active,
        settings: ProjectSettings = ProjectSettings(),
        statistics: ProjectStatistics = ProjectStatistics()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.workspaceType = workspaceType
        self.threads = threads
        self.createdAt = Date()
        self.updatedAt = Date()
        self.status = status
        self.settings = settings
        self.statistics = statistics
    }
    
    var threadCount: Int {
        return threads.count
    }
    
    var isActive: Bool {
        return status == .active
    }
    
    var displayName: String {
        return name.isEmpty ? "Untitled Project" : name
    }
    
    var lastActivity: Date {
        return updatedAt
    }
}

enum ProjectStatus: String, Codable, CaseIterable {
    case active = "active"
    case archived = "archived"
    case deleted = "deleted"
    case template = "template"
}

struct ProjectSettings: Codable, Hashable {
    let autoSave: Bool
    let enableWebResearch: Bool
    let privacyLevel: PrivacyLevel
    let defaultModel: String?
    let customInstructions: String?
    
    init(
        autoSave: Bool = true,
        enableWebResearch: Bool = true,
        privacyLevel: PrivacyLevel = .maximum,
        defaultModel: String? = nil,
        customInstructions: String? = nil
    ) {
        self.autoSave = autoSave
        self.enableWebResearch = enableWebResearch
        self.privacyLevel = privacyLevel
        self.defaultModel = defaultModel
        self.customInstructions = customInstructions
    }
}

struct ProjectStatistics: Codable, Hashable {
    let totalMessages: Int
    let totalThreads: Int
    let averageResponseTime: TimeInterval
    let totalProcessingTime: TimeInterval
    let averageConfidence: Double
    let lastUpdated: Date
    
    init(
        totalMessages: Int = 0,
        totalThreads: Int = 0,
        averageResponseTime: TimeInterval = 0,
        totalProcessingTime: TimeInterval = 0,
        averageConfidence: Double = 0,
        lastUpdated: Date = Date()
    ) {
        self.totalMessages = totalMessages
        self.totalThreads = totalThreads
        self.averageResponseTime = averageResponseTime
        self.totalProcessingTime = totalProcessingTime
        self.averageConfidence = averageConfidence
        self.lastUpdated = lastUpdated
    }
}
