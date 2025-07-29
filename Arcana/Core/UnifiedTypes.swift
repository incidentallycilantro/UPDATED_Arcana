//
// UnifiedTypes.swift
// Arcana
//
// CRITICAL: Single Source of Truth for ALL shared types across the entire system
// Every other file MUST import and reference this file - never duplicate type definitions
//

import Foundation
import SwiftUI

// MARK: - Core System Types

/// Workspace types that define the context and intelligence routing for conversations
enum WorkspaceType: String, Codable, CaseIterable, Hashable, Identifiable {
    case general = "general"
    case code = "code"
    case creative = "creative"
    case research = "research"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .general: return "General"
        case .code: return "Code"
        case .creative: return "Creative"
        case .research: return "Research"
        }
    }
    
    var icon: String {
        switch self {
        case .general: return "message"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .creative: return "paintbrush"
        case .research: return "magnifyingglass"
        }
    }
    
    var color: Color {
        switch self {
        case .general: return .blue
        case .code: return .green
        case .creative: return .purple
        case .research: return .orange
        }
    }
}

/// Message roles in conversations
enum MessageRole: String, Codable, CaseIterable, Hashable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}

/// Thread status for management and display
enum ThreadStatus: String, Codable, CaseIterable, Hashable {
    case active = "active"
    case archived = "archived"
    case deleted = "deleted"
}

// MARK: - PRISM Intelligence Types

/// Core response structure from PRISM engine
struct PRISMResponse: Codable, Hashable {
    let id: UUID
    let response: String
    let confidence: Double
    let inferenceTime: TimeInterval
    let modelUsed: String
    let tokensGenerated: Int
    let metadata: PRISMResponseMetadata
    let timestamp: Date
    
    init(response: String, confidence: Double, inferenceTime: TimeInterval, modelUsed: String, tokensGenerated: Int, metadata: PRISMResponseMetadata = PRISMResponseMetadata()) {
        self.id = UUID()
        self.response = response
        self.confidence = confidence
        self.inferenceTime = inferenceTime
        self.modelUsed = modelUsed
        self.tokensGenerated = tokensGenerated
        self.metadata = metadata
        self.timestamp = Date()
    }
}

/// Metadata for PRISM responses
struct PRISMResponseMetadata: Codable, Hashable {
    let ensembleModelsUsed: [String]
    let correctionLoops: Int
    let factCheckingScore: Double?
    let semanticSimilarity: Double?
    let temporalContext: TemporalContext?
    
    init(ensembleModelsUsed: [String] = [], correctionLoops: Int = 0, factCheckingScore: Double? = nil, semanticSimilarity: Double? = nil, temporalContext: TemporalContext? = nil) {
        self.ensembleModelsUsed = ensembleModelsUsed
        self.correctionLoops = correctionLoops
        self.factCheckingScore = factCheckingScore
        self.semanticSimilarity = semanticSimilarity
        self.temporalContext = temporalContext
    }
}

/// Conversation context for intelligent responses
struct ConversationContext: Codable, Hashable {
    let threadId: UUID
    let workspaceType: WorkspaceType
    let recentMessages: [ChatMessage]
    let semanticContext: [String]
    let temporalContext: TemporalContext?
    let userPreferences: UserPreferences?
    
    init(threadId: UUID, workspaceType: WorkspaceType, recentMessages: [ChatMessage] = [], semanticContext: [String] = [], temporalContext: TemporalContext? = nil, userPreferences: UserPreferences? = nil) {
        self.threadId = threadId
        self.workspaceType = workspaceType
        self.recentMessages = recentMessages
        self.semanticContext = semanticContext
        self.temporalContext = temporalContext
        self.userPreferences = userPreferences
    }
}

/// Temporal intelligence context
struct TemporalContext: Codable, Hashable {
    let timeOfDay: TimeOfDay
    let dayOfWeek: DayOfWeek
    let season: Season
    let circadianPhase: CircadianPhase
    let userEnergyLevel: Double // 0.0 - 1.0
    
    init(timeOfDay: TimeOfDay = TimeOfDay(), dayOfWeek: DayOfWeek = DayOfWeek(), season: Season = Season(), circadianPhase: CircadianPhase = .active, userEnergyLevel: Double = 0.8) {
        self.timeOfDay = timeOfDay
        self.dayOfWeek = dayOfWeek
        self.season = season
        self.circadianPhase = circadianPhase
        self.userEnergyLevel = userEnergyLevel
    }
}

/// Time of day classification
enum TimeOfDay: String, Codable, CaseIterable, Hashable {
    case earlyMorning = "earlyMorning"
    case morning = "morning"
    case midday = "midday"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    case lateNight = "lateNight"
    
    init() {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<7: self = .earlyMorning
        case 7..<12: self = .morning
        case 12..<14: self = .midday
        case 14..<18: self = .afternoon
        case 18..<21: self = .evening
        case 21..<23: self = .night
        default: self = .lateNight
        }
    }
}

/// Day of week classification
enum DayOfWeek: String, Codable, CaseIterable, Hashable {
    case monday = "monday"
    case tuesday = "tuesday"
    case wednesday = "wednesday"
    case thursday = "thursday"
    case friday = "friday"
    case saturday = "saturday"
    case sunday = "sunday"
    
    init() {
        let weekday = Calendar.current.component(.weekday, from: Date())
        switch weekday {
        case 1: self = .sunday
        case 2: self = .monday
        case 3: self = .tuesday
        case 4: self = .wednesday
        case 5: self = .thursday
        case 6: self = .friday
        case 7: self = .saturday
        default: self = .monday
        }
    }
}

/// Season classification
enum Season: String, Codable, CaseIterable, Hashable {
    case spring = "spring"
    case summer = "summer"
    case autumn = "autumn"
    case winter = "winter"
    
    init() {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 3...5: self = .spring
        case 6...8: self = .summer
        case 9...11: self = .autumn
        default: self = .winter
        }
    }
}

/// Circadian rhythm phases
enum CircadianPhase: String, Codable, CaseIterable, Hashable {
    case peak = "peak"
    case active = "active"
    case declining = "declining"
    case recovery = "recovery"
}

// MARK: - User Preferences & Settings

/// User preferences for personalization
struct UserPreferences: Codable, Hashable {
    let responseStyle: ResponseStyle
    let verbosity: VerbosityLevel
    let technicalLevel: TechnicalLevel
    let creativityPreference: CreativityLevel
    let privacyLevel: PrivacyLevel
    
    init(responseStyle: ResponseStyle = .balanced, verbosity: VerbosityLevel = .medium, technicalLevel: TechnicalLevel = .intermediate, creativityPreference: CreativityLevel = .balanced, privacyLevel: PrivacyLevel = .maximum) {
        self.responseStyle = responseStyle
        self.verbosity = verbosity
        self.technicalLevel = technicalLevel
        self.creativityPreference = creativityPreference
        self.privacyLevel = privacyLevel
    }
}

/// Response style preferences
enum ResponseStyle: String, Codable, CaseIterable, Hashable {
    case concise = "concise"
    case balanced = "balanced"
    case detailed = "detailed"
    case conversational = "conversational"
}

/// Verbosity level preferences
enum VerbosityLevel: String, Codable, CaseIterable, Hashable {
    case minimal = "minimal"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case verbose = "verbose"
}

/// Technical level preferences
enum TechnicalLevel: String, Codable, CaseIterable, Hashable {
    case beginner = "beginner"
    case intermediate = "intermediate"
    case advanced = "advanced"
    case expert = "expert"
}

/// Creativity level preferences
enum CreativityLevel: String, Codable, CaseIterable, Hashable {
    case conservative = "conservative"
    case balanced = "balanced"
    case creative = "creative"
    case experimental = "experimental"
}

/// Privacy level settings
enum PrivacyLevel: String, Codable, CaseIterable, Hashable {
    case maximum = "maximum"
    case balanced = "balanced"
    case performance = "performance"
    
    var displayName: String {
        switch self {
        case .maximum: return "Maximum Privacy"
        case .balanced: return "Balanced"
        case .performance: return "Performance First"
        }
    }
}

// MARK: - Web Research Types

/// Search engine preferences
enum SearchEnginePreference: String, Codable, CaseIterable, Hashable {
    case automatic = "automatic"
    case privacyOnly = "privacyOnly"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .automatic: return "Automatic (Recommended)"
        case .privacyOnly: return "Privacy-Focused Only"
        case .custom: return "Custom Selection"
        }
    }
}

/// Available search engines
enum SearchEngine: String, Codable, CaseIterable, Hashable {
    case duckDuckGo = "duckDuckGo"
    case searx = "searx"
    case startPage = "startPage"
    case bing = "bing"
    case google = "google"
    
    var displayName: String {
        switch self {
        case .duckDuckGo: return "DuckDuckGo"
        case .searx: return "SearX"
        case .startPage: return "StartPage"
        case .bing: return "Bing"
        case .google: return "Google"
        }
    }
    
    var hasQuotaLimits: Bool {
        switch self {
        case .duckDuckGo, .searx, .startPage: return false
        case .bing, .google: return true
        }
    }
}

/// Search result structure
struct SearchResult: Codable, Hashable {
    let id: UUID
    let query: String
    let results: [SearchResultItem]
    let engine: SearchEngine
    let timestamp: Date
    let confidenceScore: Double
    let processingTime: TimeInterval
    
    init(query: String, results: [SearchResultItem], engine: SearchEngine, confidenceScore: Double, processingTime: TimeInterval) {
        self.id = UUID()
        self.query = query
        self.results = results
        self.engine = engine
        self.timestamp = Date()
        self.confidenceScore = confidenceScore
        self.processingTime = processingTime
    }
}

/// Individual search result item
struct SearchResultItem: Codable, Hashable {
    let title: String
    let url: URL
    let snippet: String
    let relevanceScore: Double
    let credibilityScore: Double?
    
    init(title: String, url: URL, snippet: String, relevanceScore: Double, credibilityScore: Double? = nil) {
        self.title = title
        self.url = url
        self.snippet = snippet
        self.relevanceScore = relevanceScore
        self.credibilityScore = credibilityScore
    }
}

// MARK: - File Processing Types

/// Supported file types
enum SupportedFileType: String, Codable, CaseIterable, Hashable {
    case pdf = "pdf"
    case docx = "docx"
    case markdown = "md"
    case csv = "csv"
    case txt = "txt"
    case swift = "swift"
    case python = "py"
    case json = "json"
    
    var displayName: String {
        switch self {
        case .pdf: return "PDF Document"
        case .docx: return "Word Document"
        case .markdown: return "Markdown"
        case .csv: return "CSV Spreadsheet"
        case .txt: return "Text File"
        case .swift: return "Swift Code"
        case .python: return "Python Code"
        case .json: return "JSON Data"
        }
    }
    
    var icon: String {
        switch self {
        case .pdf: return "doc.richtext"
        case .docx: return "doc.text"
        case .markdown: return "doc.plaintext"
        case .csv: return "tablecells"
        case .txt: return "doc.text"
        case .swift: return "chevron.left.forwardslash.chevron.right"
        case .python: return "chevron.left.forwardslash.chevron.right"
        case .json: return "curlybraces"
        }
    }
}

/// File processing result
struct FileProcessingResult: Codable, Hashable {
    let id: UUID
    let filename: String
    let fileType: SupportedFileType
    let extractedContent: String
    let summary: String
    let keyPoints: [String]
    let suggestedActions: [String]
    let processingTime: TimeInterval
    let confidence: Double
    let timestamp: Date
    
    init(filename: String, fileType: SupportedFileType, extractedContent: String, summary: String, keyPoints: [String], suggestedActions: [String], processingTime: TimeInterval, confidence: Double) {
        self.id = UUID()
        self.filename = filename
        self.fileType = fileType
        self.extractedContent = extractedContent
        self.summary = summary
        self.keyPoints = keyPoints
        self.suggestedActions = suggestedActions
        self.processingTime = processingTime
        self.confidence = confidence
        self.timestamp = Date()
    }
}

// MARK: - Storage & Performance Types

/// Storage limit options
enum StorageLimit: String, Codable, CaseIterable, Hashable {
    case small25MB = "small25MB"
    case standard50MB = "standard50MB"
    case large100MB = "large100MB"
    
    var displayName: String {
        switch self {
        case .small25MB: return "25 MB"
        case .standard50MB: return "50 MB (Recommended)"
        case .large100MB: return "100 MB"
        }
    }
    
    var bytes: Int64 {
        switch self {
        case .small25MB: return 25 * 1024 * 1024
        case .standard50MB: return 50 * 1024 * 1024
        case .large100MB: return 100 * 1024 * 1024
        }
    }
}

/// Data retention periods
enum RetentionPeriod: String, Codable, CaseIterable, Hashable {
    case sevenDays = "sevenDays"
    case thirtyDays = "thirtyDays"
    case ninetyDays = "ninetyDays"
    
    var displayName: String {
        switch self {
        case .sevenDays: return "7 Days"
        case .thirtyDays: return "30 Days (Recommended)"
        case .ninetyDays: return "90 Days"
        }
    }
    
    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        }
    }
}

/// Performance monitoring metrics
struct PerformanceMetrics: Codable, Hashable {
    let cpuUsage: Double
    let memoryUsage: Int64
    let diskUsage: Int64
    let networkUsage: Int64
    let inferenceTime: TimeInterval
    let uiResponseTime: TimeInterval
    let batteryImpact: Double
    let timestamp: Date
    
    init(cpuUsage: Double = 0, memoryUsage: Int64 = 0, diskUsage: Int64 = 0, networkUsage: Int64 = 0, inferenceTime: TimeInterval = 0, uiResponseTime: TimeInterval = 0, batteryImpact: Double = 0) {
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
        self.diskUsage = diskUsage
        self.networkUsage = networkUsage
        self.inferenceTime = inferenceTime
        self.uiResponseTime = uiResponseTime
        self.batteryImpact = batteryImpact
        self.timestamp = Date()
    }
}

/// Performance mode settings
enum PerformanceMode: String, Codable, CaseIterable, Hashable {
    case efficiency = "efficiency"
    case balanced = "balanced"
    case performance = "performance"
    
    var displayName: String {
        switch self {
        case .efficiency: return "Efficiency"
        case .balanced: return "Balanced"
        case .performance: return "Performance"
        }
    }
}

// MARK: - App Theme Types

/// App theme options
enum AppTheme: String, Codable, CaseIterable, Hashable {
    case auto = "auto"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

// MARK: - Animation Types

/// Animation duration presets
enum AnimationDuration: Double, Codable, CaseIterable, Hashable {
    case instant = 0.0
    case fast = 0.15
    case medium = 0.3
    case slow = 0.5
    case verySlow = 0.8
}

/// Animation easing curves
enum AnimationCurve: String, Codable, CaseIterable, Hashable {
    case linear = "linear"
    case easeIn = "easeIn"
    case easeOut = "easeOut"
    case easeInOut = "easeInOut"
    case spring = "spring"
}

// MARK: - Error Types

/// Unified error types for the entire system
enum ArcanaError: Error, LocalizedError, Hashable {
    case prismEngineFailure(String)
    case quantumMemoryError(String)
    case ensembleOrchestrationError(String)
    case fileProcessingError(String)
    case networkError(String)
    case storageError(String)
    case privacyViolation(String)
    case configurationError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .prismEngineFailure(let message): return "PRISM Engine Error: \(message)"
        case .quantumMemoryError(let message): return "Quantum Memory Error: \(message)"
        case .ensembleOrchestrationError(let message): return "Ensemble Error: \(message)"
        case .fileProcessingError(let message): return "File Processing Error: \(message)"
        case .networkError(let message): return "Network Error: \(message)"
        case .storageError(let message): return "Storage Error: \(message)"
        case .privacyViolation(let message): return "Privacy Error: \(message)"
        case .configurationError(let message): return "Configuration Error: \(message)"
        case .unknownError(let message): return "Unknown Error: \(message)"
        }
    }
}

// MARK: - Model Information Types

/// Model information for the PRISM ensemble
struct ModelInfo: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let version: String
    let size: Int64
    let capabilities: [ModelCapability]
    let performance: ModelPerformance
    let isLoaded: Bool
    let loadTime: TimeInterval?
    
    init(name: String, version: String, size: Int64, capabilities: [ModelCapability], performance: ModelPerformance, isLoaded: Bool = false, loadTime: TimeInterval? = nil) {
        self.id = UUID()
        self.name = name
        self.version = version
        self.size = size
        self.capabilities = capabilities
        self.performance = performance
        self.isLoaded = isLoaded
        self.loadTime = loadTime
    }
}

/// Model capabilities
enum ModelCapability: String, Codable, CaseIterable, Hashable {
    case textGeneration = "textGeneration"
    case codeGeneration = "codeGeneration"
    case reasoning = "reasoning"
    case creativity = "creativity"
    case analysis = "analysis"
    case translation = "translation"
    case summarization = "summarization"
    case questionAnswering = "questionAnswering"
    case embedding = "embedding"
    
    var displayName: String {
        switch self {
        case .textGeneration: return "Text Generation"
        case .codeGeneration: return "Code Generation"
        case .reasoning: return "Reasoning"
        case .creativity: return "Creativity"
        case .analysis: return "Analysis"
        case .translation: return "Translation"
        case .summarization: return "Summarization"
        case .questionAnswering: return "Q&A"
        case .embedding: return "Embeddings"
        }
    }
}

/// Model performance metrics
struct ModelPerformance: Codable, Hashable {
    let averageInferenceTime: TimeInterval
    let tokensPerSecond: Double
    let accuracyScore: Double
    let memoryUsage: Int64
    let powerEfficiency: Double
    
    init(averageInferenceTime: TimeInterval, tokensPerSecond: Double, accuracyScore: Double, memoryUsage: Int64, powerEfficiency: Double) {
        self.averageInferenceTime = averageInferenceTime
        self.tokensPerSecond = tokensPerSecond
        self.accuracyScore = accuracyScore
        self.memoryUsage = memoryUsage
        self.powerEfficiency = powerEfficiency
    }
}

// MARK: - Feedback Types

/// Bug report structure
struct BugReport: Codable, Hashable {
    let id: UUID
    let anonymousID: String
    let systemInfo: SystemInfo
    let issueDescription: String
    let reproductionSteps: String
    let timestamp: Date
    let severity: BugSeverity
    let category: BugCategory
    
    init(anonymousID: String, systemInfo: SystemInfo, issueDescription: String, reproductionSteps: String, severity: BugSeverity = .medium, category: BugCategory = .general) {
        self.id = UUID()
        self.anonymousID = anonymousID
        self.systemInfo = systemInfo
        self.issueDescription = issueDescription
        self.reproductionSteps = reproductionSteps
        self.timestamp = Date()
        self.severity = severity
        self.category = category
    }
}

/// Feature request structure
struct FeatureRequest: Codable, Hashable {
    let id: UUID
    let anonymousID: String
    let requestDescription: String
    let useCase: String
    let priority: FeaturePriority
    let category: FeatureCategory
    let timestamp: Date
    
    init(anonymousID: String, requestDescription: String, useCase: String, priority: FeaturePriority = .medium, category: FeatureCategory = .general) {
        self.id = UUID()
        self.anonymousID = anonymousID
        self.requestDescription = requestDescription
        self.useCase = useCase
        self.priority = priority
        self.category = category
        self.timestamp = Date()
    }
}

/// System information for feedback
struct SystemInfo: Codable, Hashable {
    let macOSVersion: String
    let appVersion: String
    let deviceModel: String
    let memorySize: Int64
    let storageAvailable: Int64
    
    init() {
        self.macOSVersion = ProcessInfo.processInfo.operatingSystemVersionString
        self.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        self.deviceModel = "Mac" // Simplified for privacy
        self.memorySize = Int64(ProcessInfo.processInfo.physicalMemory)
        self.storageAvailable = 0 // Would be calculated at runtime
    }
}

/// Bug severity levels
enum BugSeverity: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

/// Bug categories
enum BugCategory: String, Codable, CaseIterable, Hashable {
    case general = "general"
    case performance = "performance"
    case ui = "ui"
    case privacy = "privacy"
    case intelligence = "intelligence"
    case storage = "storage"
}

/// Feature priority levels
enum FeaturePriority: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
}

/// Feature categories
enum FeatureCategory: String, Codable, CaseIterable, Hashable {
    case general = "general"
    case intelligence = "intelligence"
    case ui = "ui"
    case privacy = "privacy"
    case performance = "performance"
    case integration = "integration"
}

// MARK: - Global Constants

/// Global constants used throughout the app
struct ArcanaConstants {
    // App Information
    static let appName = "Arcana"
    static let appVersion = "1.0.0"
    static let buildNumber = "1"
    
    // Bundle Identifier
    static let bundleIdentifier = "com.spectrallabs.arcana"
    
    // Feedback Emails
    static let bugReportEmail = "arcana_bugs@protonmail.com"
    static let featureRequestEmail = "arcana_feedback@protonmail.com"
    
    // Performance Targets
    static let targetInferenceTime: TimeInterval = 2.0 // Max 2 seconds
    static let targetUIResponseTime: TimeInterval = 0.1 // Max 100ms
    static let maxMemoryUsage: Int64 = 500 * 1024 * 1024 // 500MB
    
    // Storage Paths
    static let documentsDirectory = "Documents"
    static let cacheDirectory = "Cache"
    static let modelsDirectory = "Models"
    static let knowledgeGraphDirectory = "KnowledgeGraph"
    
    // Default Settings
    static let defaultStorageLimit: StorageLimit = .standard50MB
    static let defaultRetentionPeriod: RetentionPeriod = .thirtyDays
    static let defaultPrivacyLevel: PrivacyLevel = .maximum
    static let defaultPerformanceMode: PerformanceMode = .balanced
    static let defaultTheme: AppTheme = .auto
}

// MARK: - Protocol Definitions

/// Protocol for objects that can be persisted
protocol Persistable: Codable {
    var id: UUID { get }
    var timestamp: Date { get }
}

/// Protocol for objects that can be cached
protocol Cacheable: Persistable {
    var cacheKey: String { get }
    var expirationDate: Date? { get }
}

/// Protocol for objects that can be encrypted
protocol Encryptable {
    func encrypt(with key: Data) throws -> Data
    static func decrypt(_ data: Data, with key: Data) throws -> Self
}

/// Protocol for intelligent components
protocol IntelligentComponent {
    func processWithContext(_ context: ConversationContext) async throws -> PRISMResponse
    var capabilities: [ModelCapability] { get }
    var performance: ModelPerformance { get }
}

/// Protocol for privacy-compliant components
protocol PrivacyCompliant {
    func anonymize() -> Self
    func stripPersonalData() -> Self
    var containsPersonalData: Bool { get }
}

// MARK: - Type Extensions

extension ChatMessage: Persistable, Cacheable {
    var cacheKey: String { id.uuidString }
    var expirationDate: Date? {
        Calendar.current.date(byAdding: .day, value: 30, to: timestamp)
    }
}

// MARK: - Helper Types

/// Result wrapper for async operations
enum AsyncResult<Success, Failure: Error> {
    case success(Success)
    case failure(Failure)
    
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
    
    var value: Success? {
        switch self {
        case .success(let value): return value
        case .failure: return nil
        }
    }
    
    var error: Failure? {
        switch self {
        case .success: return nil
        case .failure(let error): return error
        }
    }
}

/// Loading state for UI components
enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
    
    var isLoading: Bool {
        switch self {
        case .loading: return true
        default: return false
        }
    }
    
    var value: T? {
        switch self {
        case .loaded(let value): return value
        default: return nil
        }
    }
    
    var error: Error? {
        switch self {
        case .error(let error): return error
        default: return nil
        }
    }
}

// MARK: - Forward Declarations

/// Forward declaration for ChatMessage (defined in Models/ChatMessage.swift)
struct ChatMessage: Codable, Hashable, Identifiable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let threadId: UUID
    let workspaceId: UUID
    let confidence: Double?
    let metadata: [String: String]?
    
    init(id: UUID = UUID(), role: MessageRole, content: String, threadId: UUID, workspaceId: UUID, confidence: Double? = nil, metadata: [String: String]? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.threadId = threadId
        self.workspaceId = workspaceId
        self.confidence = confidence
        self.metadata = metadata
    }
}
