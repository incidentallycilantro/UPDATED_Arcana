//
// ThreadWebSettings.swift
// Arcana
//
// Revolutionary per-thread privacy and web research configuration system
// Provides granular control over AI capabilities with maximum privacy protection
//

import Foundation

// MARK: - Thread Web Settings

/// Revolutionary per-thread privacy configuration that allows granular control over AI capabilities
/// Enables users to customize web research, model selection, and privacy levels on a thread-by-thread basis
public struct ThreadWebSettings: Codable, Hashable, Identifiable {
    
    // MARK: - Properties
    
    public let id: UUID
    public let threadId: UUID
    public let creationDate: Date
    public var lastModified: Date
    
    // Web research settings
    public var webResearchEnabled: Bool
    public var allowedDomains: [String]
    public var blockedDomains: [String]
    public var searchEnginePreference: SearchEnginePreference
    public var customSearchEngines: [SearchEngine]
    public var maxSearchResults: Int
    public var searchTimeout: TimeInterval
    public var cacheSearchResults: Bool
    public var anonymousSearchOnly: Bool
    
    // Privacy settings
    public var privacyLevel: PrivacyLevel
    public var dataRetentionPeriod: RetentionPeriod
    public var shareAggregatedData: Bool
    public var enableAnalytics: Bool
    public var crossThreadLearning: Bool
    public var personalizedResponses: Bool
    
    // Model and intelligence settings
    public var preferredModels: [String]
    public var ensembleMode: EnsembleMode
    public var responseStyle: ResponseStyle
    public var creativityLevel: CreativityLevel
    public var factCheckingLevel: FactCheckingLevel
    public var confidenceThreshold: Double
    
    // Content filtering settings
    public var contentFilterLevel: ContentFilterLevel
    public var allowedContentTypes: [ContentType]
    public var languagePreferences: [String]
    public var topicFilters: [TopicFilter]
    
    // Performance settings
    public var maxResponseTime: TimeInterval
    public var qualityVsSpeed: QualitySpeedBalance
    public var enablePredictiveLoading: Bool
    public var backgroundProcessing: Bool
    
    // Collaboration settings
    public var allowSharing: Bool
    public var shareLevel: ShareLevel
    public var collaboratorPermissions: [CollaboratorPermission]
    public var exportPermissions: ExportPermissions
    
    // Advanced settings
    public var customPromptTemplates: [PromptTemplate]
    public var outputFormat: OutputFormat
    public var citationStyle: CitationStyle
    public var metadataInclusion: MetadataInclusion
    
    // MARK: - Initialization
    
    public init(threadId: UUID) {
        self.id = UUID()
        self.threadId = threadId
        self.creationDate = Date()
        self.lastModified = Date()
        
        // Default web research settings
        self.webResearchEnabled = true
        self.allowedDomains = []
        self.blockedDomains = []
        self.searchEnginePreference = .automatic
        self.customSearchEngines = []
        self.maxSearchResults = 10
        self.searchTimeout = 30.0
        self.cacheSearchResults = true
        self.anonymousSearchOnly = true
        
        // Default privacy settings
        self.privacyLevel = .maximum
        self.dataRetentionPeriod = .thirtyDays
        self.shareAggregatedData = false
        self.enableAnalytics = false
        self.crossThreadLearning = false
        self.personalizedResponses = true
        
        // Default model settings
        self.preferredModels = []
        self.ensembleMode = .intelligent
        self.responseStyle = .balanced
        self.creativityLevel = .balanced
        self.factCheckingLevel = .standard
        self.confidenceThreshold = 0.7
        
        // Default content filtering
        self.contentFilterLevel = .moderate
        self.allowedContentTypes = ContentType.allCases
        self.languagePreferences = ["en"]
        self.topicFilters = []
        
        // Default performance settings
        self.maxResponseTime = 10.0
        self.qualityVsSpeed = .balanced
        self.enablePredictiveLoading = true
        self.backgroundProcessing = true
        
        // Default collaboration settings
        self.allowSharing = false
        self.shareLevel = .none
        self.collaboratorPermissions = []
        self.exportPermissions = ExportPermissions()
        
        // Default advanced settings
        self.customPromptTemplates = []
        self.outputFormat = .markdown
        self.citationStyle = .apa
        self.metadataInclusion = .minimal
    }
    
    public init(
        threadId: UUID,
        webResearchEnabled: Bool = true,
        privacyLevel: PrivacyLevel = .maximum,
        responseStyle: ResponseStyle = .balanced,
        contentFilterLevel: ContentFilterLevel = .moderate
    ) {
        self.init(threadId: threadId)
        
        self.webResearchEnabled = webResearchEnabled
        self.privacyLevel = privacyLevel
        self.responseStyle = responseStyle
        self.contentFilterLevel = contentFilterLevel
        
        // Adjust dependent settings based on privacy level
        applyPrivacyLevelDefaults()
    }
    
    // MARK: - Computed Properties
    
    /// Whether the thread allows external data access
    public var allowsExternalData: Bool {
        return webResearchEnabled && privacyLevel != .maximum
    }
    
    /// Whether the thread settings are privacy-compliant
    public var isPrivacyCompliant: Bool {
        switch privacyLevel {
        case .maximum:
            return !shareAggregatedData && !enableAnalytics && anonymousSearchOnly
        case .balanced:
            return anonymousSearchOnly
        case .performance:
            return true // Performance mode allows more data usage
        }
    }
    
    /// Estimated privacy score (0.0 - 1.0)
    public var privacyScore: Double {
        var score: Double = 0.0
        
        // Privacy level contribution (40%)
        switch privacyLevel {
        case .maximum: score += 0.4
        case .balanced: score += 0.25
        case .performance: score += 0.1
        }
        
        // Web research contribution (20%)
        if !webResearchEnabled {
            score += 0.2
        } else if anonymousSearchOnly {
            score += 0.15
        } else {
            score += 0.05
        }
        
        // Data sharing contribution (20%)
        if !shareAggregatedData && !enableAnalytics {
            score += 0.2
        } else if !shareAggregatedData {
            score += 0.15
        } else {
            score += 0.05
        }
        
        // Cross-thread learning contribution (10%)
        if !crossThreadLearning {
            score += 0.1
        } else {
            score += 0.05
        }
        
        // Collaboration contribution (10%)
        if !allowSharing {
            score += 0.1
        } else if shareLevel == .readOnly {
            score += 0.05
        }
        
        return min(1.0, score)
    }
    
    /// Performance impact score (0.0 - 1.0, higher = better performance)
    public var performanceImpact: Double {
        var impact: Double = 0.5 // Baseline
        
        // Web research impact
        if webResearchEnabled {
            impact += 0.2
        }
        
        // Quality vs speed balance
        switch qualityVsSpeed {
        case .speed: impact += 0.2
        case .balanced: impact += 0.1
        case .quality: impact -= 0.1
        }
        
        // Predictive loading
        if enablePredictiveLoading {
            impact += 0.1
        }
        
        // Background processing
        if backgroundProcessing {
            impact += 0.1
        }
        
        // Ensemble mode impact
        switch ensembleMode {
        case .single: impact += 0.1
        case .intelligent: impact += 0.05
        case .full: impact -= 0.1
        }
        
        return max(0.0, min(1.0, impact))
    }
    
    /// Configuration complexity level
    public var complexityLevel: ConfigurationComplexity {
        var complexity = 0
        
        if !allowedDomains.isEmpty || !blockedDomains.isEmpty { complexity += 1 }
        if !customSearchEngines.isEmpty { complexity += 1 }
        if !preferredModels.isEmpty { complexity += 1 }
        if !topicFilters.isEmpty { complexity += 1 }
        if !customPromptTemplates.isEmpty { complexity += 2 }
        if !collaboratorPermissions.isEmpty { complexity += 1 }
        if contentFilterLevel != .moderate { complexity += 1 }
        if privacyLevel != .balanced { complexity += 1 }
        
        switch complexity {
        case 0...2: return .simple
        case 3...5: return .moderate
        case 6...8: return .advanced
        default: return .expert
        }
    }
    
    // MARK: - Methods
    
    /// Update settings and refresh modification date
    public mutating func updateSettings() {
        lastModified = Date()
        applySettingsValidation()
    }
    
    /// Apply privacy level defaults to dependent settings
    public mutating func applyPrivacyLevelDefaults() {
        switch privacyLevel {
        case .maximum:
            shareAggregatedData = false
            enableAnalytics = false
            crossThreadLearning = false
            anonymousSearchOnly = true
            allowSharing = false
            backgroundProcessing = false
            
        case .balanced:
            anonymousSearchOnly = true
            shareAggregatedData = false
            enableAnalytics = true // Anonymous analytics only
            
        case .performance:
            // Performance mode allows more flexibility
            backgroundProcessing = true
            enablePredictiveLoading = true
        }
        
        updateSettings()
    }
    
    /// Configure for specific use case
    public mutating func configureForUseCase(_ useCase: ThreadUseCase) {
        switch useCase {
        case .research:
            webResearchEnabled = true
            maxSearchResults = 20
            factCheckingLevel = .strict
            citationStyle = .academic
            qualityVsSpeed = .quality
            
        case .creative:
            creativityLevel = .creative
            factCheckingLevel = .relaxed
            responseStyle = .conversational
            webResearchEnabled = false
            
        case .programming:
            preferredModels = ["CodeLlama", "Phi-2"]
            ensembleMode = .intelligent
            factCheckingLevel = .standard
            outputFormat = .code
            
        case .casual:
            responseStyle = .conversational
            qualityVsSpeed = .speed
            privacyLevel = .balanced
            webResearchEnabled = true
            
        case .professional:
            responseStyle = .detailed
            factCheckingLevel = .strict
            qualityVsSpeed = .quality
            citationStyle = .professional
            
        case .educational:
            webResearchEnabled = true
            factCheckingLevel = .strict
            responseStyle = .detailed
            citationStyle = .academic
            contentFilterLevel = .strict
        }
        
        updateSettings()
    }
    
    /// Validate domain settings
    public mutating func validateDomainSettings() -> [DomainValidationIssue] {
        var issues: [DomainValidationIssue] = []
        
        // Check for conflicts between allowed and blocked domains
        let conflicts = Set(allowedDomains).intersection(Set(blockedDomains))
        for domain in conflicts {
            issues.append(DomainValidationIssue(
                type: .conflict,
                domain: domain,
                description: "Domain appears in both allowed and blocked lists"
            ))
        }
        
        // Validate domain formats
        for domain in allowedDomains + blockedDomains {
            if !isValidDomain(domain) {
                issues.append(DomainValidationIssue(
                    type: .invalidFormat,
                    domain: domain,
                    description: "Invalid domain format"
                ))
            }
        }
        
        return issues
    }
    
    /// Get privacy summary
    public func getPrivacySummary() -> PrivacySummary {
        return PrivacySummary(
            level: privacyLevel,
            score: privacyScore,
            webResearchEnabled: webResearchEnabled,
            anonymousSearchOnly: anonymousSearchOnly,
            dataSharing: shareAggregatedData,
            analyticsEnabled: enableAnalytics,
            crossThreadLearning: crossThreadLearning,
            recommendations: getPrivacyRecommendations()
        )
    }
    
    /// Get performance summary
    public func getPerformanceSummary() -> PerformanceSummary {
        return PerformanceSummary(
            impactScore: performanceImpact,
            qualitySpeedBalance: qualityVsSpeed,
            predictiveLoadingEnabled: enablePredictiveLoading,
            backgroundProcessingEnabled: backgroundProcessing,
            maxResponseTime: maxResponseTime,
            ensembleMode: ensembleMode,
            optimizationSuggestions: getPerformanceOptimizations()
        )
    }
    
    /// Export settings as dictionary for external use
    public func exportSettings() -> [String: Any] {
        var settings: [String: Any] = [:]
        
        settings["threadId"] = threadId.uuidString
        settings["webResearchEnabled"] = webResearchEnabled
        settings["privacyLevel"] = privacyLevel.rawValue
        settings["responseStyle"] = responseStyle.rawValue
        settings["privacyScore"] = privacyScore
        settings["performanceImpact"] = performanceImpact
        settings["lastModified"] = lastModified.timeIntervalSince1970
        
        return settings
    }
    
    /// Import settings from dictionary
    public mutating func importSettings(from dictionary: [String: Any]) throws {
        guard let threadIdString = dictionary["threadId"] as? String,
              UUID(uuidString: threadIdString) == threadId else {
            throw ThreadSettingsError.invalidThreadId
        }
        
        if let webResearch = dictionary["webResearchEnabled"] as? Bool {
            webResearchEnabled = webResearch
        }
        
        if let privacyString = dictionary["privacyLevel"] as? String,
           let privacy = PrivacyLevel(rawValue: privacyString) {
            privacyLevel = privacy
        }
        
        if let styleString = dictionary["responseStyle"] as? String,
           let style = ResponseStyle(rawValue: styleString) {
            responseStyle = style
        }
        
        updateSettings()
    }
    
    /// Clone settings for another thread
    public func cloneForThread(_ newThreadId: UUID) -> ThreadWebSettings {
        var cloned = ThreadWebSettings(threadId: newThreadId)
        
        // Copy all settings except thread-specific identifiers
        cloned.webResearchEnabled = webResearchEnabled
        cloned.allowedDomains = allowedDomains
        cloned.blockedDomains = blockedDomains
        cloned.searchEnginePreference = searchEnginePreference
        cloned.customSearchEngines = customSearchEngines
        cloned.maxSearchResults = maxSearchResults
        cloned.searchTimeout = searchTimeout
        cloned.cacheSearchResults = cacheSearchResults
        cloned.anonymousSearchOnly = anonymousSearchOnly
        
        cloned.privacyLevel = privacyLevel
        cloned.dataRetentionPeriod = dataRetentionPeriod
        cloned.shareAggregatedData = shareAggregatedData
        cloned.enableAnalytics = enableAnalytics
        cloned.crossThreadLearning = crossThreadLearning
        cloned.personalizedResponses = personalizedResponses
        
        cloned.preferredModels = preferredModels
        cloned.ensembleMode = ensembleMode
        cloned.responseStyle = responseStyle
        cloned.creativityLevel = creativityLevel
        cloned.factCheckingLevel = factCheckingLevel
        cloned.confidenceThreshold = confidenceThreshold
        
        cloned.contentFilterLevel = contentFilterLevel
        cloned.allowedContentTypes = allowedContentTypes
        cloned.languagePreferences = languagePreferences
        cloned.topicFilters = topicFilters
        
        cloned.maxResponseTime = maxResponseTime
        cloned.qualityVsSpeed = qualityVsSpeed
        cloned.enablePredictiveLoading = enablePredictiveLoading
        cloned.backgroundProcessing = backgroundProcessing
        
        // Don't copy collaboration settings for security
        cloned.customPromptTemplates = customPromptTemplates
        cloned.outputFormat = outputFormat
        cloned.citationStyle = citationStyle
        cloned.metadataInclusion = metadataInclusion
        
        return cloned
    }
    
    // MARK: - Private Methods
    
    private mutating func applySettingsValidation() {
        // Ensure confidence threshold is within valid range
        confidenceThreshold = max(0.0, min(1.0, confidenceThreshold))
        
        // Ensure max response time is reasonable
        maxResponseTime = max(1.0, min(300.0, maxResponseTime))
        
        // Ensure search timeout is reasonable
        searchTimeout = max(5.0, min(120.0, searchTimeout))
        
        // Ensure max search results is reasonable
        maxSearchResults = max(1, min(50, maxSearchResults))
        
        // Validate privacy-dependent settings
        if privacyLevel == .maximum {
            shareAggregatedData = false
            enableAnalytics = false
            anonymousSearchOnly = true
        }
        
        // Remove invalid domains
        allowedDomains = allowedDomains.filter { isValidDomain($0) }
        blockedDomains = blockedDomains.filter { isValidDomain($0) }
    }
    
    private func isValidDomain(_ domain: String) -> Bool {
        let domainRegex = #"^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](?:\.[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9])*$"#
        return domain.range(of: domainRegex, options: .regularExpression) != nil
    }
    
    private func getPrivacyRecommendations() -> [PrivacyRecommendation] {
        var recommendations: [PrivacyRecommendation] = []
        
        if privacyScore < 0.7 {
            recommendations.append(PrivacyRecommendation(
                type: .increasePrivacyLevel,
                description: "Consider increasing privacy level for better protection",
                impact: .medium
            ))
        }
        
        if webResearchEnabled && !anonymousSearchOnly {
            recommendations.append(PrivacyRecommendation(
                type: .enableAnonymousSearch,
                description: "Enable anonymous search for better privacy",
                impact: .high
            ))
        }
        
        if shareAggregatedData {
            recommendations.append(PrivacyRecommendation(
                type: .disableDataSharing,
                description: "Disable data sharing for maximum privacy",
                impact: .medium
            ))
        }
        
        return recommendations
    }
    
    private func getPerformanceOptimizations() -> [PerformanceOptimization] {
        var optimizations: [PerformanceOptimization] = []
        
        if !enablePredictiveLoading {
            optimizations.append(PerformanceOptimization(
                type: .enablePredictiveLoading,
                description: "Enable predictive loading for faster responses",
                expectedSpeedup: 0.3
            ))
        }
        
        if qualityVsSpeed == .quality && maxResponseTime < 5.0 {
            optimizations.append(PerformanceOptimization(
                type: .adjustQualitySpeedBalance,
                description: "Consider balanced mode for faster responses",
                expectedSpeedup: 0.4
            ))
        }
        
        if ensembleMode == .full && maxResponseTime < 10.0 {
            optimizations.append(PerformanceOptimization(
                type: .optimizeEnsembleMode,
                description: "Use intelligent ensemble mode for better speed",
                expectedSpeedup: 0.25
            ))
        }
        
        return optimizations
    }
}

// MARK: - Supporting Types

/// Thread use case for configuration templates
public enum ThreadUseCase: String, Codable, CaseIterable, Hashable {
    case research = "research"
    case creative = "creative"
    case programming = "programming"
    case casual = "casual"
    case professional = "professional"
    case educational = "educational"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Configuration complexity levels
public enum ConfigurationComplexity: String, Codable, CaseIterable, Hashable {
    case simple = "simple"
    case moderate = "moderate"
    case advanced = "advanced"
    case expert = "expert"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Ensemble mode options
public enum EnsembleMode: String, Codable, CaseIterable, Hashable {
    case single = "single"
    case intelligent = "intelligent"
    case full = "full"
    
    public var displayName: String {
        switch self {
        case .single: return "Single Model"
        case .intelligent: return "Intelligent Ensemble"
        case .full: return "Full Ensemble"
        }
    }
}

/// Fact checking levels
public enum FactCheckingLevel: String, Codable, CaseIterable, Hashable {
    case relaxed = "relaxed"
    case standard = "standard"
    case strict = "strict"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Content filter levels
public enum ContentFilterLevel: String, Codable, CaseIterable, Hashable {
    case minimal = "minimal"
    case moderate = "moderate"
    case strict = "strict"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Content types
public enum ContentType: String, Codable, CaseIterable, Hashable {
    case text = "text"
    case code = "code"
    case academic = "academic"
    case news = "news"
    case reference = "reference"
    case creative = "creative"
    case technical = "technical"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Topic filters
public struct TopicFilter: Codable, Hashable {
    public let topic: String
    public let action: FilterAction
    public let priority: FilterPriority
    
    public init(topic: String, action: FilterAction, priority: FilterPriority) {
        self.topic = topic
        self.action = action
        self.priority = priority
    }
}

/// Filter actions
public enum FilterAction: String, Codable, CaseIterable, Hashable {
    case allow = "allow"
    case block = "block"
    case warn = "warn"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Filter priorities
public enum FilterPriority: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Quality vs speed balance
public enum QualitySpeedBalance: String, Codable, CaseIterable, Hashable {
    case speed = "speed"
    case balanced = "balanced"
    case quality = "quality"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Share levels for collaboration
public enum ShareLevel: String, Codable, CaseIterable, Hashable {
    case none = "none"
    case readOnly = "readOnly"
    case comment = "comment"
    case edit = "edit"
    
    public var displayName: String {
        switch self {
        case .none: return "No Sharing"
        case .readOnly: return "Read Only"
        case .comment: return "Comment Only"
        case .edit: return "Full Edit"
        }
    }
}

/// Collaborator permissions
public struct CollaboratorPermission: Codable, Hashable {
    public let userId: String
    public let permission: ShareLevel
    public let expirationDate: Date?
    
    public init(userId: String, permission: ShareLevel, expirationDate: Date? = nil) {
        self.userId = userId
        self.permission = permission
        self.expirationDate = expirationDate
    }
}

/// Export permissions
public struct ExportPermissions: Codable, Hashable {
    public let allowExport: Bool
    public let allowedFormats: [ExportFormat]
    public let includeMetadata: Bool
    public let watermarkRequired: Bool
    
    public init(allowExport: Bool = true, allowedFormats: [ExportFormat] = ExportFormat.allCases, includeMetadata: Bool = false, watermarkRequired: Bool = false) {
        self.allowExport = allowExport
        self.allowedFormats = allowedFormats
        self.includeMetadata = includeMetadata
        self.watermarkRequired = watermarkRequired
    }
}

/// Export formats
public enum ExportFormat: String, Codable, CaseIterable, Hashable {
    case markdown = "markdown"
    case html = "html"
    case pdf = "pdf"
    case plainText = "plainText"
    case json = "json"
    
    public var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .html: return "HTML"
        case .pdf: return "PDF"
        case .plainText: return "Plain Text"
        case .json: return "JSON"
        }
    }
}

/// Custom prompt templates
public struct PromptTemplate: Codable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let template: String
    public let variables: [TemplateVariable]
    public let category: TemplateCategory
    
    public init(name: String, template: String, variables: [TemplateVariable], category: TemplateCategory) {
        self.id = UUID()
        self.name = name
        self.template = template
        self.variables = variables
        self.category = category
    }
}

/// Template variables
public struct TemplateVariable: Codable, Hashable {
    public let name: String
    public let type: VariableType
    public let defaultValue: String?
    public let description: String
    
    public init(name: String, type: VariableType, defaultValue: String? = nil, description: String) {
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.description = description
    }
}

/// Variable types
public enum VariableType: String, Codable, CaseIterable, Hashable {
    case text = "text"
    case number = "number"
    case boolean = "boolean"
    case selection = "selection"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Template categories
public enum TemplateCategory: String, Codable, CaseIterable, Hashable {
    case research = "research"
    case creative = "creative"
    case technical = "technical"
    case educational = "educational"
    case business = "business"
    case personal = "personal"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Output formats
public enum OutputFormat: String, Codable, CaseIterable, Hashable {
    case markdown = "markdown"
    case html = "html"
    case plainText = "plainText"
    case code = "code"
    case structured = "structured"
    
    public var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .html: return "HTML"
        case .plainText: return "Plain Text"
        case .code: return "Code"
        case .structured: return "Structured"
        }
    }
}

/// Citation styles
public enum CitationStyle: String, Codable, CaseIterable, Hashable {
    case none = "none"
    case apa = "apa"
    case mla = "mla"
    case chicago = "chicago"
    case academic = "academic"
    case professional = "professional"
    
    public var displayName: String {
        switch self {
        case .none: return "No Citations"
        case .apa: return "APA Style"
        case .mla: return "MLA Style"
        case .chicago: return "Chicago Style"
        case .academic: return "Academic"
        case .professional: return "Professional"
        }
    }
}

/// Metadata inclusion levels
public enum MetadataInclusion: String, Codable, CaseIterable, Hashable {
    case none = "none"
    case minimal = "minimal"
    case standard = "standard"
    case comprehensive = "comprehensive"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Domain validation issues
public struct DomainValidationIssue: Codable, Hashable {
    public let type: ValidationIssueType
    public let domain: String
    public let description: String
    
    public init(type: ValidationIssueType, domain: String, description: String) {
        self.type = type
        self.domain = domain
        self.description = description
    }
}

/// Validation issue types
public enum ValidationIssueType: String, Codable, CaseIterable, Hashable {
    case conflict = "conflict"
    case invalidFormat = "invalidFormat"
    case security = "security"
    case performance = "performance"
    
    public var displayName: String {
        switch self {
        case .conflict: return "Conflict"
        case .invalidFormat: return "Invalid Format"
        case .security: return "Security Issue"
        case .performance: return "Performance Issue"
        }
    }
}

/// Privacy summary
public struct PrivacySummary: Codable, Hashable {
    public let level: PrivacyLevel
    public let score: Double
    public let webResearchEnabled: Bool
    public let anonymousSearchOnly: Bool
    public let dataSharing: Bool
    public let analyticsEnabled: Bool
    public let crossThreadLearning: Bool
    public let recommendations: [PrivacyRecommendation]
    
    public init(level: PrivacyLevel, score: Double, webResearchEnabled: Bool, anonymousSearchOnly: Bool, dataSharing: Bool, analyticsEnabled: Bool, crossThreadLearning: Bool, recommendations: [PrivacyRecommendation]) {
        self.level = level
        self.score = score
        self.webResearchEnabled = webResearchEnabled
        self.anonymousSearchOnly = anonymousSearchOnly
        self.dataSharing = dataSharing
        self.analyticsEnabled = analyticsEnabled
        self.crossThreadLearning = crossThreadLearning
        self.recommendations = recommendations
    }
}

/// Privacy recommendations
public struct PrivacyRecommendation: Codable, Hashable {
    public let type: PrivacyRecommendationType
    public let description: String
    public let impact: RecommendationImpact
    
    public init(type: PrivacyRecommendationType, description: String, impact: RecommendationImpact) {
        self.type = type
        self.description = description
        self.impact = impact
    }
}

/// Privacy recommendation types
public enum PrivacyRecommendationType: String, Codable, CaseIterable, Hashable {
    case increasePrivacyLevel = "increasePrivacyLevel"
    case enableAnonymousSearch = "enableAnonymousSearch"
    case disableDataSharing = "disableDataSharing"
    case limitWebResearch = "limitWebResearch"
    case reviewDomainSettings = "reviewDomainSettings"
    
    public var displayName: String {
        switch self {
        case .increasePrivacyLevel: return "Increase Privacy Level"
        case .enableAnonymousSearch: return "Enable Anonymous Search"
        case .disableDataSharing: return "Disable Data Sharing"
        case .limitWebResearch: return "Limit Web Research"
        case .reviewDomainSettings: return "Review Domain Settings"
        }
    }
}

/// Recommendation impact levels
public enum RecommendationImpact: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Performance summary
public struct PerformanceSummary: Codable, Hashable {
    public let impactScore: Double
    public let qualitySpeedBalance: QualitySpeedBalance
    public let predictiveLoadingEnabled: Bool
    public let backgroundProcessingEnabled: Bool
    public let maxResponseTime: TimeInterval
    public let ensembleMode: EnsembleMode
    public let optimizationSuggestions: [PerformanceOptimization]
    
    public init(impactScore: Double, qualitySpeedBalance: QualitySpeedBalance, predictiveLoadingEnabled: Bool, backgroundProcessingEnabled: Bool, maxResponseTime: TimeInterval, ensembleMode: EnsembleMode, optimizationSuggestions: [PerformanceOptimization]) {
        self.impactScore = impactScore
        self.qualitySpeedBalance = qualitySpeedBalance
        self.predictiveLoadingEnabled = predictiveLoadingEnabled
        self.backgroundProcessingEnabled = backgroundProcessingEnabled
        self.maxResponseTime = maxResponseTime
        self.ensembleMode = ensembleMode
        self.optimizationSuggestions = optimizationSuggestions
    }
}

/// Performance optimizations
public struct PerformanceOptimization: Codable, Hashable {
    public let type: OptimizationType
    public let description: String
    public let expectedSpeedup: Double
    
    public init(type: OptimizationType, description: String, expectedSpeedup: Double) {
        self.type = type
        self.description = description
        self.expectedSpeedup = expectedSpeedup
    }
}

/// Optimization types
public enum OptimizationType: String, Codable, CaseIterable, Hashable {
    case enablePredictiveLoading = "enablePredictiveLoading"
    case adjustQualitySpeedBalance = "adjustQualitySpeedBalance"
    case optimizeEnsembleMode = "optimizeEnsembleMode"
    case enableBackgroundProcessing = "enableBackgroundProcessing"
    case reduceCacheSize = "reduceCacheSize"
    
    public var displayName: String {
        switch self {
        case .enablePredictiveLoading: return "Enable Predictive Loading"
        case .adjustQualitySpeedBalance: return "Adjust Quality/Speed Balance"
        case .optimizeEnsembleMode: return "Optimize Ensemble Mode"
        case .enableBackgroundProcessing: return "Enable Background Processing"
        case .reduceCacheSize: return "Reduce Cache Size"
        }
    }
}

/// Thread settings errors
public enum ThreadSettingsError: Error, LocalizedError {
    case invalidThreadId
    case invalidDomain(String)
    case invalidConfiguration
    case privacyViolation
    case performanceConflict
    
    public var errorDescription: String? {
        switch self {
        case .invalidThreadId:
            return "Invalid thread ID provided"
        case .invalidDomain(let domain):
            return "Invalid domain format: \(domain)"
        case .invalidConfiguration:
            return "Invalid configuration detected"
        case .privacyViolation:
            return "Configuration violates privacy settings"
        case .performanceConflict:
            return "Configuration causes performance conflicts"
        }
    }
}

// MARK: - Default Configurations

extension ThreadWebSettings {
    
    /// Create settings optimized for maximum privacy
    public static func maximumPrivacy(threadId: UUID) -> ThreadWebSettings {
        var settings = ThreadWebSettings(threadId: threadId)
        settings.privacyLevel = .maximum
        settings.webResearchEnabled = false
        settings.shareAggregatedData = false
        settings.enableAnalytics = false
        settings.crossThreadLearning = false
        settings.anonymousSearchOnly = true
        settings.allowSharing = false
        settings.backgroundProcessing = false
        settings.dataRetentionPeriod = .sevenDays
        return settings
    }
    
    /// Create settings optimized for performance
    public static func maximumPerformance(threadId: UUID) -> ThreadWebSettings {
        var settings = ThreadWebSettings(threadId: threadId)
        settings.privacyLevel = .performance
        settings.qualityVsSpeed = .speed
        settings.enablePredictiveLoading = true
        settings.backgroundProcessing = true
        settings.ensembleMode = .intelligent
        settings.maxResponseTime = 5.0
        settings.cacheSearchResults = true
        settings.maxSearchResults = 5
        return settings
    }
    
    /// Create balanced settings for general use
    public static func balanced(threadId: UUID) -> ThreadWebSettings {
        var settings = ThreadWebSettings(threadId: threadId)
        settings.privacyLevel = .balanced
        settings.qualityVsSpeed = .balanced
        settings.webResearchEnabled = true
        settings.anonymousSearchOnly = true
        settings.enableAnalytics = true
        settings.shareAggregatedData = false
        settings.ensembleMode = .intelligent
        return settings
    }
    
    /// Create settings for research-focused threads
    public static func research(threadId: UUID) -> ThreadWebSettings {
        var settings = ThreadWebSettings(threadId: threadId)
        settings.configureForUseCase(.research)
        return settings
    }
    
    /// Create settings for creative threads
    public static func creative(threadId: UUID) -> ThreadWebSettings {
        var settings = ThreadWebSettings(threadId: threadId)
        settings.configureForUseCase(.creative)
        return settings
    }
    
    /// Create settings for programming threads
    public static func programming(threadId: UUID) -> ThreadWebSettings {
        var settings = ThreadWebSettings(threadId: threadId)
        settings.configureForUseCase(.programming)
        return settings
    }
}

// MARK: - Settings Manager

/// Manager for thread web settings with persistence and validation
public class ThreadWebSettingsManager: ObservableObject {
    
    @Published private(set) var settings: [UUID: ThreadWebSettings] = [:]
    private let storageKey = "ThreadWebSettings"
    
    public init() {
        loadSettings()
    }
    
    /// Get settings for a specific thread
    public func getSettings(for threadId: UUID) -> ThreadWebSettings {
        return settings[threadId] ?? ThreadWebSettings(threadId: threadId)
    }
    
    /// Update settings for a specific thread
    public func updateSettings(_ newSettings: ThreadWebSettings) {
        settings[newSettings.threadId] = newSettings
        saveSettings()
    }
    
    /// Remove settings for a thread
    public func removeSettings(for threadId: UUID) {
        settings.removeValue(forKey: threadId)
        saveSettings()
    }
    
    /// Get all configured threads
    public func getAllConfiguredThreads() -> [UUID] {
        return Array(settings.keys)
    }
    
    /// Export all settings
    public func exportAllSettings() -> Data? {
        return try? JSONEncoder().encode(settings)
    }
    
    /// Import settings from data
    public func importSettings(from data: Data) throws {
        let importedSettings = try JSONDecoder().decode([UUID: ThreadWebSettings].self, from: data)
        settings.merge(importedSettings) { (_, new) in new }
        saveSettings()
    }
    
    private func loadSettings() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let loadedSettings = try? JSONDecoder().decode([UUID: ThreadWebSettings].self, from: data) else {
            return
        }
        settings = loadedSettings
    }
    
    private func saveSettings() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
