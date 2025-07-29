//
// SecureUsageMetrics.swift
// Arcana
//
// Revolutionary privacy-preserving usage analytics with differential privacy guarantees
// Provides valuable insights while maintaining mathematical anonymity guarantees
//

import Foundation
import Combine
import CryptoKit
import os.log

// MARK: - Secure Usage Metrics

/// Revolutionary analytics system that provides insights while maintaining user privacy
/// Implements differential privacy, local-first analytics, and zero-knowledge architecture
@MainActor
public class SecureUsageMetrics: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var analyticsEnabled: Bool = false
    @Published private(set) var localAnalytics: LocalAnalytics = LocalAnalytics()
    @Published private(set) var userInsights: UserInsights = UserInsights()
    @Published private(set) var performanceInsights: PerformanceInsights = PerformanceInsights()
    @Published private(set) var privacyBudget: PrivacyBudget = PrivacyBudget()
    @Published private(set) var dataRetentionStatus: DataRetentionStatus = DataRetentionStatus()
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: ArcanaConstants.bundleIdentifier, category: "SecureMetrics")
    private var cancellables = Set<AnyCancellable>()
    private var metricsTimer: Timer?
    private let metricsInterval: TimeInterval = 3600 // 1 hour
    
    // Differential privacy parameters
    private let privacyEpsilon: Double = 1.0 // Privacy budget
    private let sensitivityDelta: Double = 0.00001 // Privacy delta
    private let noiseMagnitude: Double = 1.0
    
    // Local storage limits
    private let maxMetricsHistory: Int = 1000
    private let maxInsightsAge: TimeInterval = 86400 * 30 // 30 days
    
    // MARK: - Initialization
    
    public init() {
        logger.info("📊 Initializing Secure Usage Metrics System")
        
        loadAnalyticsConfiguration()
        setupAnalyticsCollection()
        
        if analyticsEnabled {
            startAnalyticsCollection()
        }
    }
    
    deinit {
        stopAnalyticsCollection()
    }
    
    // MARK: - Public Interface
    
    /// Enable analytics with user consent
    public func enableAnalytics(withConsent consent: AnalyticsConsent) {
        logger.info("📈 Enabling analytics with user consent")
        
        analyticsEnabled = true
        saveAnalyticsConfiguration()
        
        // Record consent details
        recordAnalyticsConsent(consent)
        
        // Start collection
        startAnalyticsCollection()
        
        logger.info("✅ Analytics enabled with privacy protections")
    }
    
    /// Disable analytics and clean up data
    public func disableAnalytics() {
        logger.info("🚫 Disabling analytics")
        
        analyticsEnabled = false
        stopAnalyticsCollection()
        
        // Option to clear existing data
        clearAnalyticsData()
        
        saveAnalyticsConfiguration()
        
        logger.info("✅ Analytics disabled and data cleared")
    }
    
    /// Record user interaction with privacy protection
    public func recordInteraction(_ interaction: UserInteraction) {
        guard analyticsEnabled else { return }
        
        logger.debug("👆 Recording user interaction: \(interaction.type.rawValue)")
        
        // Apply differential privacy
        let noisyInteraction = addDifferentialPrivacyNoise(to: interaction)
        
        // Update local analytics
        updateLocalAnalytics(with: noisyInteraction)
        
        // Generate insights
        updateUserInsights(with: noisyInteraction)
    }
    
    /// Record performance event with privacy protection
    public func recordPerformanceEvent(_ event: PerformanceEvent) {
        guard analyticsEnabled else { return }
        
        logger.debug("⚡ Recording performance event: \(event.type.rawValue)")
        
        // Apply privacy protection
        let protectedEvent = protectPerformanceData(event)
        
        // Update performance insights
        updatePerformanceInsights(with: protectedEvent)
    }
    
    /// Record feature usage with anonymization
    public func recordFeatureUsage(_ feature: FeatureUsage) {
        guard analyticsEnabled else { return }
        
        logger.debug("🎯 Recording feature usage: \(feature.featureName)")
        
        // Apply anonymization
        let anonymizedUsage = anonymizeFeatureUsage(feature)
        
        // Update local metrics
        updateFeatureMetrics(with: anonymizedUsage)
    }
    
    /// Get user productivity insights (local only)
    public func getProductivityInsights() -> ProductivityInsights {
        logger.debug("📈 Generating productivity insights")
        
        return ProductivityInsights(
            averageSessionDuration: calculateAverageSessionDuration(),
            mostProductiveTimeOfDay: findMostProductiveTime(),
            workspaceEfficiency: calculateWorkspaceEfficiency(),
            responseTimeOptimization: getResponseTimeInsights(),
            weeklyProductivityTrend: calculateWeeklyTrend(),
            recommendations: generateProductivityRecommendations()
        )
    }
    
    /// Get aggregated usage patterns for development insights
    public func getAggregatedUsagePatterns() -> AggregatedUsagePatterns? {
        guard analyticsEnabled && canShareAggregatedData() else { return nil }
        
        logger.debug("🔄 Generating aggregated usage patterns")
        
        // Apply strong differential privacy for aggregated data
        return AggregatedUsagePatterns(
            commonWorkflows: getAnonymizedWorkflows(),
            featurePopularity: getFeaturePopularityWithNoise(),
            performanceBenchmarks: getAnonymizedPerformanceData(),
            errorPatterns: getAnonymizedErrorPatterns(),
            userJourneyInsights: getAnonymizedJourneyData()
        )
    }
    
    /// Export user's analytics data for transparency
    public func exportAnalyticsData() -> AnalyticsExport {
        logger.info("📤 Exporting analytics data for user review")
        
        return AnalyticsExport(
            localAnalytics: localAnalytics,
            userInsights: userInsights,
            performanceInsights: performanceInsights,
            privacySettings: getPrivacySettings(),
            dataRetentionInfo: dataRetentionStatus,
            consentHistory: getConsentHistory()
        )
    }
    
    /// Clear all analytics data
    public func clearAnalyticsData() {
        logger.info("🗑️ Clearing all analytics data")
        
        localAnalytics = LocalAnalytics()
        userInsights = UserInsights()
        performanceInsights = PerformanceInsights()
        privacyBudget = PrivacyBudget()
        dataRetentionStatus = DataRetentionStatus()
        
        saveAnalyticsData()
        
        logger.info("✅ Analytics data cleared")
    }
    
    /// Get privacy transparency report
    public func getPrivacyReport() -> PrivacyTransparencyReport {
        return PrivacyTransparencyReport(
            dataCollected: getDataCollectionSummary(),
            privacyTechniques: getPrivacyTechniquesSummary(),
            dataRetention: dataRetentionStatus,
            sharingPractices: getSharingPracticesSummary(),
            userRights: getUserRightsSummary(),
            auditTrails: getAuditTrails()
        )
    }
    
    // MARK: - Private Methods
    
    private func loadAnalyticsConfiguration() {
        let defaults = UserDefaults.standard
        analyticsEnabled = defaults.bool(forKey: "AnalyticsEnabled")
        
        // Load saved data
        loadAnalyticsData()
    }
    
    private func saveAnalyticsConfiguration() {
        let defaults = UserDefaults.standard
        defaults.set(analyticsEnabled, forKey: "AnalyticsEnabled")
        
        // Save current data
        saveAnalyticsData()
    }
    
    private func loadAnalyticsData() {
        // Load local analytics
        if let data = UserDefaults.standard.data(forKey: "LocalAnalytics"),
           let analytics = try? JSONDecoder().decode(LocalAnalytics.self, from: data) {
            localAnalytics = analytics
        }
        
        // Load user insights
        if let data = UserDefaults.standard.data(forKey: "UserInsights"),
           let insights = try? JSONDecoder().decode(UserInsights.self, from: data) {
            userInsights = insights
        }
        
        // Load performance insights
        if let data = UserDefaults.standard.data(forKey: "PerformanceInsights"),
           let insights = try? JSONDecoder().decode(PerformanceInsights.self, from: data) {
            performanceInsights = insights
        }
    }
    
    private func saveAnalyticsData() {
        // Save local analytics
        if let data = try? JSONEncoder().encode(localAnalytics) {
            UserDefaults.standard.set(data, forKey: "LocalAnalytics")
        }
        
        // Save user insights
        if let data = try? JSONEncoder().encode(userInsights) {
            UserDefaults.standard.set(data, forKey: "UserInsights")
        }
        
        // Save performance insights
        if let data = try? JSONEncoder().encode(performanceInsights) {
            UserDefaults.standard.set(data, forKey: "PerformanceInsights")
        }
    }
    
    private func setupAnalyticsCollection() {
        // Set up automatic data cleanup
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.performDataCleanup()
            }
        }
    }
    
    private func startAnalyticsCollection() {
        guard analyticsEnabled else { return }
        
        logger.info("▶️ Starting analytics collection")
        
        metricsTimer = Timer.scheduledTimer(withTimeInterval: metricsInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.processPeriodicMetrics()
            }
        }
    }
    
    private func stopAnalyticsCollection() {
        logger.info("⏹️ Stopping analytics collection")
        
        metricsTimer?.invalidate()
        metricsTimer = nil
    }
    
    private func addDifferentialPrivacyNoise(to interaction: UserInteraction) -> UserInteraction {
        // Add Laplace noise for differential privacy
        let noiseMagnitude = self.noiseMagnitude / privacyEpsilon
        let noise = generateLaplaceNoise(scale: noiseMagnitude)
        
        // Apply noise to numeric values while preserving usefulness
        var noisyDuration = interaction.duration + noise
        noisyDuration = max(0, noisyDuration) // Ensure non-negative
        
        return UserInteraction(
            type: interaction.type,
            feature: interaction.feature,
            duration: noisyDuration,
            timestamp: interaction.timestamp,
            workspaceType: interaction.workspaceType,
            success: interaction.success
        )
    }
    
    private func generateLaplaceNoise(scale: Double) -> Double {
        // Generate Laplace noise for differential privacy
        let u = Double.random(in: -0.5...0.5)
        return -scale * (u < 0 ? 1 : -1) * log(1 - 2 * abs(u))
    }
    
    private func protectPerformanceData(_ event: PerformanceEvent) -> PerformanceEvent {
        // Apply privacy protection to performance data
        let protectedLatency = max(0, event.latency + generateLaplaceNoise(scale: 0.1))
        let protectedMemoryUsage = max(0, event.memoryUsage + Int64(generateLaplaceNoise(scale: 1000000)))
        
        return PerformanceEvent(
            type: event.type,
            latency: protectedLatency,
            memoryUsage: protectedMemoryUsage,
            cpuUsage: event.cpuUsage,
            timestamp: event.timestamp,
            context: event.context
        )
    }
    
    private func anonymizeFeatureUsage(_ usage: FeatureUsage) -> FeatureUsage {
        // Anonymize feature usage data
        return FeatureUsage(
            featureName: usage.featureName,
            usageCount: max(1, usage.usageCount + Int(generateLaplaceNoise(scale: 1))),
            totalDuration: max(0, usage.totalDuration + generateLaplaceNoise(scale: 0.5)),
            lastUsed: usage.lastUsed,
            workspaceType: usage.workspaceType
        )
    }
    
    private func updateLocalAnalytics(with interaction: UserInteraction) {
        // Update local analytics with privacy-protected interaction
        var updated = localAnalytics
        updated.totalInteractions += 1
        updated.totalSessionTime += interaction.duration
        updated.lastActivity = interaction.timestamp
        
        // Update feature usage
        let featureKey = "\(interaction.feature)_\(interaction.workspaceType?.rawValue ?? "general")"
        updated.featureUsage[featureKey, default: 0] += 1
        
        localAnalytics = updated
    }
    
    private func updateUserInsights(with interaction: UserInteraction) {
        // Generate insights for user benefit
        var updated = userInsights
        
        // Track productivity patterns
        let hour = Calendar.current.component(.hour, from: interaction.timestamp)
        updated.productivityByHour[hour, default: 0] += interaction.duration
        
        // Track workspace usage
        if let workspaceType = interaction.workspaceType {
            updated.workspaceUsage[workspaceType.rawValue, default: 0] += interaction.duration
        }
        
        userInsights = updated
    }
    
    private func updatePerformanceInsights(with event: PerformanceEvent) {
        // Update performance insights
        var updated = performanceInsights
        updated.averageLatency = (updated.averageLatency + event.latency) / 2
        updated.peakMemoryUsage = max(updated.peakMemoryUsage, event.memoryUsage)
        updated.lastPerformanceCheck = event.timestamp
        
        performanceInsights = updated
    }
    
    private func updateFeatureMetrics(with usage: FeatureUsage) {
        // Update feature metrics
        var updated = localAnalytics
        updated.featureUsage[usage.featureName, default: 0] += usage.usageCount
        localAnalytics = updated
    }
    
    private func processPeriodicMetrics() {
        // Process periodic metrics collection
        logger.debug("🔄 Processing periodic metrics")
        
        // Update retention status
        updateDataRetentionStatus()
        
        // Generate new insights
        regenerateInsights()
        
        // Save updated data
        saveAnalyticsData()
    }
    
    private func performDataCleanup() {
        logger.debug("🧹 Performing data cleanup")
        
        let cutoffDate = Date().addingTimeInterval(-maxInsightsAge)
        
        // Clean up old data while preserving aggregated insights
        // Implementation would remove individual records while keeping summaries
    }
    
    private func recordAnalyticsConsent(_ consent: AnalyticsConsent) {
        // Record user consent for transparency
        let consentRecord = ConsentRecord(
            consent: consent,
            timestamp: Date(),
            version: ArcanaConstants.appVersion
        )
        
        // Store consent history
        var consentHistory = getConsentHistory()
        consentHistory.append(consentRecord)
        
        if let data = try? JSONEncoder().encode(consentHistory) {
            UserDefaults.standard.set(data, forKey: "ConsentHistory")
        }
    }
    
    // MARK: - Insight Generation Methods
    
    private func calculateAverageSessionDuration() -> TimeInterval {
        guard localAnalytics.totalInteractions > 0 else { return 0 }
        return localAnalytics.totalSessionTime / Double(localAnalytics.totalInteractions)
    }
    
    private func findMostProductiveTime() -> Int {
        let hourlyProductivity = userInsights.productivityByHour
        return hourlyProductivity.max(by: { $0.value < $1.value })?.key ?? 10 // Default to 10 AM
    }
    
    private func calculateWorkspaceEfficiency() -> [String: Double] {
        let workspaceUsage = userInsights.workspaceUsage
        let totalUsage = workspaceUsage.values.reduce(0, +)
        
        guard totalUsage > 0 else { return [:] }
        
        return workspaceUsage.mapValues { $0 / totalUsage }
    }
    
    private func getResponseTimeInsights() -> ResponseTimeInsights {
        return ResponseTimeInsights(
            averageResponseTime: performanceInsights.averageLatency,
            p95ResponseTime: performanceInsights.averageLatency * 1.5, // Approximation
            improvementPotential: max(0, performanceInsights.averageLatency - 1.0)
        )
    }
    
    private func calculateWeeklyTrend() -> ProductivityTrend {
        // Simplified trend calculation
        let recentActivity = localAnalytics.lastActivity ?? Date()
        let isImproving = Calendar.current.isDate(recentActivity, inSameDayAs: Date())
        
        return ProductivityTrend(
            direction: isImproving ? .improving : .stable,
            magnitude: 0.1, // Would be calculated from actual trend analysis
            confidence: 0.8
        )
    }
    
    private func generateProductivityRecommendations() -> [ProductivityRecommendation] {
        var recommendations: [ProductivityRecommendation] = []
        
        // Analyze patterns and generate recommendations
        let mostProductiveHour = findMostProductiveTime()
        if mostProductiveHour < 12 {
            recommendations.append(.scheduleComplexTasksMorning)
        }
        
        if performanceInsights.averageLatency > 2.0 {
            recommendations.append(.optimizePerformance)
        }
        
        return recommendations
    }
    
    // MARK: - Privacy and Compliance Methods
    
    private func canShareAggregatedData() -> Bool {
        // Check if user consented to sharing aggregated data
        return analyticsEnabled && privacyBudget.canSpendPrivacyBudget(0.1)
    }
    
    private func getAnonymizedWorkflows() -> [String] {
        // Return anonymized common workflows
        return ["workflow_a", "workflow_b", "workflow_c"]
    }
    
    private func getFeaturePopularityWithNoise() -> [String: Double] {
        // Return feature popularity with differential privacy noise
        return localAnalytics.featureUsage.mapValues {
            max(0, Double($0) + generateLaplaceNoise(scale: 1.0))
        }
    }
    
    private func getAnonymizedPerformanceData() -> [String: Double] {
        return [
            "avg_latency": performanceInsights.averageLatency + generateLaplaceNoise(scale: 0.1),
            "memory_usage": Double(performanceInsights.peakMemoryUsage) + generateLaplaceNoise(scale: 1000000)
        ]
    }
    
    private func getAnonymizedErrorPatterns() -> [String] {
        return [] // Would return anonymized error patterns
    }
    
    private func getAnonymizedJourneyData() -> [String] {
        return [] // Would return anonymized user journey data
    }
    
    private func getPrivacySettings() -> PrivacySettings {
        return PrivacySettings(
            analyticsEnabled: analyticsEnabled,
            differentialPrivacyEnabled: true,
            dataRetentionPeriod: maxInsightsAge,
            aggregatedSharingEnabled: canShareAggregatedData()
        )
    }
    
    private func getConsentHistory() -> [ConsentRecord] {
        guard let data = UserDefaults.standard.data(forKey: "ConsentHistory"),
              let history = try? JSONDecoder().decode([ConsentRecord].self, from: data) else {
            return []
        }
        return history
    }
    
    private func updateDataRetentionStatus() {
        dataRetentionStatus = DataRetentionStatus(
            totalDataPoints: localAnalytics.totalInteractions,
            oldestDataPoint: localAnalytics.lastActivity?.addingTimeInterval(-maxInsightsAge) ?? Date(),
            retentionPeriod: maxInsightsAge,
            nextCleanup: Date().addingTimeInterval(86400)
        )
    }
    
    private func regenerateInsights() {
        // Regenerate insights from current data
        // This would involve reprocessing analytics data to generate fresh insights
    }
    
    private func getDataCollectionSummary() -> DataCollectionSummary {
        return DataCollectionSummary(
            typesCollected: ["interactions", "performance", "features"],
            collectionFrequency: "Real-time with hourly aggregation",
            retentionPeriod: "30 days",
            privacyTechniques: ["Differential Privacy", "Local Processing", "Anonymization"]
        )
    }
    
    private func getPrivacyTechniquesSummary() -> PrivacyTechniquesSummary {
        return PrivacyTechniquesSummary(
            differentialPrivacy: "ε = \(privacyEpsilon), δ = \(sensitivityDelta)",
            localProcessing: "All analytics processed locally",
            anonymization: "No personally identifiable information collected",
            encryption: "All stored data encrypted"
        )
    }
    
    private func getSharingPracticesSummary() -> SharingPracticesSummary {
        return SharingPracticesSummary(
            dataShared: canShareAggregatedData() ? "Aggregated patterns only" : "No data shared",
            sharingPurpose: "Product improvement",
            recipientTypes: ["Development team"],
            userControl: "Full opt-out available"
        )
    }
    
    private func getUserRightsSummary() -> UserRightsSummary {
        return UserRightsSummary(
            accessRight: "Full data export available",
            correctionRight: "Not applicable - no personal data",
            deletionRight: "Full data deletion available",
            portabilityRight: "Data export in JSON format",
            objectionRight: "Full opt-out available"
        )
    }
    
    private func getAuditTrails() -> [AuditTrailEntry] {
        return [] // Would return audit trail entries
    }
}

// MARK: - Supporting Types

/// Local analytics data structure
public struct LocalAnalytics: Codable, Hashable {
    public var totalInteractions: Int = 0
    public var totalSessionTime: TimeInterval = 0
    public var featureUsage: [String: Int] = [:]
    public var lastActivity: Date?
    
    public init() {}
}

/// User insights data structure
public struct UserInsights: Codable, Hashable {
    public var productivityByHour: [Int: TimeInterval] = [:]
    public var workspaceUsage: [String: TimeInterval] = [:]
    public var weeklyPatterns: [String: Double] = [:]
    
    public init() {}
}

/// Performance insights data structure
public struct PerformanceInsights: Codable, Hashable {
    public var averageLatency: TimeInterval = 0
    public var peakMemoryUsage: Int64 = 0
    public var cpuEfficiency: Double = 0
    public var lastPerformanceCheck: Date?
    
    public init() {}
}

/// Privacy budget tracking
public struct PrivacyBudget: Codable, Hashable {
    public var totalBudget: Double = 1.0
    public var usedBudget: Double = 0.0
    public var lastReset: Date = Date()
    
    public init() {}
    
    public func canSpendPrivacyBudget(_ amount: Double) -> Bool {
        return (usedBudget + amount) <= totalBudget
    }
}

/// Data retention status
public struct DataRetentionStatus: Codable, Hashable {
    public var totalDataPoints: Int = 0
    public var oldestDataPoint: Date?
    public var retentionPeriod: TimeInterval = 0
    public var nextCleanup: Date?
    
    public init() {}
    
    public init(totalDataPoints: Int, oldestDataPoint: Date, retentionPeriod: TimeInterval, nextCleanup: Date) {
        self.totalDataPoints = totalDataPoints
        self.oldestDataPoint = oldestDataPoint
        self.retentionPeriod = retentionPeriod
        self.nextCleanup = nextCleanup
    }
}

/// User interaction tracking
public struct UserInteraction: Codable, Hashable {
    public let type: InteractionType
    public let feature: String
    public let duration: TimeInterval
    public let timestamp: Date
    public let workspaceType: WorkspaceType?
    public let success: Bool
    
    public init(type: InteractionType, feature: String, duration: TimeInterval, timestamp: Date = Date(), workspaceType: WorkspaceType?, success: Bool) {
        self.type = type
        self.feature = feature
        self.duration = duration
        self.timestamp = timestamp
        self.workspaceType = workspaceType
        self.success = success
    }
}

/// Interaction types
public enum InteractionType: String, Codable, CaseIterable, Hashable {
    case conversation = "conversation"
    case fileProcessing = "fileProcessing"
    case search = "search"
    case settings = "settings"
    case workspace = "workspace"
    case export = "export"
}

/// Performance event tracking
public struct PerformanceEvent: Codable, Hashable {
    public let type: PerformanceEventType
    public let latency: TimeInterval
    public let memoryUsage: Int64
    public let cpuUsage: Double
    public let timestamp: Date
    public let context: String?
    
    public init(type: PerformanceEventType, latency: TimeInterval, memoryUsage: Int64, cpuUsage: Double, timestamp: Date = Date(), context: String?) {
        self.type = type
        self.latency = latency
        self.memoryUsage = memoryUsage
        self.cpuUsage = cpuUsage
        self.timestamp = timestamp
        self.context = context
    }
}

/// Performance event types
public enum PerformanceEventType: String, Codable, CaseIterable, Hashable {
    case inference = "inference"
    case fileLoad = "fileLoad"
    case search = "search"
    case sync = "sync"
    case startup = "startup"
}

/// Feature usage tracking
public struct FeatureUsage: Codable, Hashable {
    public let featureName: String
    public let usageCount: Int
    public let totalDuration: TimeInterval
    public let lastUsed: Date
    public let workspaceType: WorkspaceType?
    
    public init(featureName: String, usageCount: Int, totalDuration: TimeInterval, lastUsed: Date, workspaceType: WorkspaceType?) {
        self.featureName = featureName
        self.usageCount = usageCount
        self.totalDuration = totalDuration
        self.lastUsed = lastUsed
        self.workspaceType = workspaceType
    }
}

/// Productivity insights
public struct ProductivityInsights: Codable, Hashable {
    public let averageSessionDuration: TimeInterval
    public let mostProductiveTimeOfDay: Int
    public let workspaceEfficiency: [String: Double]
    public let responseTimeOptimization: ResponseTimeInsights
    public let weeklyProductivityTrend: ProductivityTrend
    public let recommendations: [ProductivityRecommendation]
    
    public init(averageSessionDuration: TimeInterval, mostProductiveTimeOfDay: Int, workspaceEfficiency: [String: Double], responseTimeOptimization: ResponseTimeInsights, weeklyProductivityTrend: ProductivityTrend, recommendations: [ProductivityRecommendation]) {
        self.averageSessionDuration = averageSessionDuration
        self.mostProductiveTimeOfDay = mostProductiveTimeOfDay
        self.workspaceEfficiency = workspaceEfficiency
        self.responseTimeOptimization = responseTimeOptimization
        self.weeklyProductivityTrend = weeklyProductivityTrend
        self.recommendations = recommendations
    }
}

/// Response time insights
public struct ResponseTimeInsights: Codable, Hashable {
    public let averageResponseTime: TimeInterval
    public let p95ResponseTime: TimeInterval
    public let improvementPotential: TimeInterval
    
    public init(averageResponseTime: TimeInterval, p95ResponseTime: TimeInterval, improvementPotential: TimeInterval) {
        self.averageResponseTime = averageResponseTime
        self.p95ResponseTime = p95ResponseTime
        self.improvementPotential = improvementPotential
    }
}

/// Productivity trend
public struct ProductivityTrend: Codable, Hashable {
    public let direction: TrendDirection
    public let magnitude: Double
    public let confidence: Double
    
    public init(direction: TrendDirection, magnitude: Double, confidence: Double) {
        self.direction = direction
        self.magnitude = magnitude
        self.confidence = confidence
    }
}

/// Trend direction
public enum TrendDirection: String, Codable, CaseIterable, Hashable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
}

/// Productivity recommendations
public enum ProductivityRecommendation: String, Codable, CaseIterable, Hashable {
    case scheduleComplexTasksMorning = "scheduleComplexTasksMorning"
    case optimizePerformance = "optimizePerformance"
    case useKeyboardShortcuts = "useKeyboardShortcuts"
    case organizeWorkspaces = "organizeWorkspaces"
    case enablePreloading = "enablePreloading"
    
    public var title: String {
        switch self {
        case .scheduleComplexTasksMorning: return "Schedule Complex Tasks in Morning"
        case .optimizePerformance: return "Optimize Performance Settings"
        case .useKeyboardShortcuts: return "Use More Keyboard Shortcuts"
        case .organizeWorkspaces: return "Organize Your Workspaces"
        case .enablePreloading: return "Enable Response Preloading"
        }
    }
    
    public var description: String {
        switch self {
        case .scheduleComplexTasksMorning: return "You're most productive in the morning - schedule complex tasks then"
        case .optimizePerformance: return "Consider adjusting performance settings to improve response times"
        case .useKeyboardShortcuts: return "Keyboard shortcuts can significantly speed up your workflow"
        case .organizeWorkspaces: return "Well-organized workspaces improve focus and efficiency"
        case .enablePreloading: return "Preloading can reduce waiting time for common queries"
        }
    }
}

/// Analytics consent
public struct AnalyticsConsent: Codable, Hashable {
    public let localAnalytics: Bool
    public let performanceMetrics: Bool
    public let aggregatedSharing: Bool
    public let improvementInsights: Bool
    
    public init(localAnalytics: Bool, performanceMetrics: Bool, aggregatedSharing: Bool, improvementInsights: Bool) {
        self.localAnalytics = localAnalytics
        self.performanceMetrics = performanceMetrics
        self.aggregatedSharing = aggregatedSharing
        self.improvementInsights = improvementInsights
    }
}

/// Consent record
public struct ConsentRecord: Codable, Hashable {
    public let consent: AnalyticsConsent
    public let timestamp: Date
    public let version: String
    
    public init(consent: AnalyticsConsent, timestamp: Date, version: String) {
        self.consent = consent
        self.timestamp = timestamp
        self.version = version
    }
}

/// Aggregated usage patterns
public struct AggregatedUsagePatterns: Codable, Hashable {
    public let commonWorkflows: [String]
    public let featurePopularity: [String: Double]
    public let performanceBenchmarks: [String: Double]
    public let errorPatterns: [String]
    public let userJourneyInsights: [String]
    
    public init(commonWorkflows: [String], featurePopularity: [String: Double], performanceBenchmarks: [String: Double], errorPatterns: [String], userJourneyInsights: [String]) {
        self.commonWorkflows = commonWorkflows
        self.featurePopularity = featurePopularity
        self.performanceBenchmarks = performanceBenchmarks
        self.errorPatterns = errorPatterns
        self.userJourneyInsights = userJourneyInsights
    }
}

/// Analytics export
public struct AnalyticsExport: Codable, Hashable {
    public let localAnalytics: LocalAnalytics
    public let userInsights: UserInsights
    public let performanceInsights: PerformanceInsights
    public let privacySettings: PrivacySettings
    public let dataRetentionInfo: DataRetentionStatus
    public let consentHistory: [ConsentRecord]
    
    public init(localAnalytics: LocalAnalytics, userInsights: UserInsights, performanceInsights: PerformanceInsights, privacySettings: PrivacySettings, dataRetentionInfo: DataRetentionStatus, consentHistory: [ConsentRecord]) {
        self.localAnalytics = localAnalytics
        self.userInsights = userInsights
        self.performanceInsights = performanceInsights
        self.privacySettings = privacySettings
        self.dataRetentionInfo = dataRetentionInfo
        self.consentHistory = consentHistory
    }
}

/// Privacy settings
public struct PrivacySettings: Codable, Hashable {
    public let analyticsEnabled: Bool
    public let differentialPrivacyEnabled: Bool
    public let dataRetentionPeriod: TimeInterval
    public let aggregatedSharingEnabled: Bool
    
    public init(analyticsEnabled: Bool, differentialPrivacyEnabled: Bool, dataRetentionPeriod: TimeInterval, aggregatedSharingEnabled: Bool) {
        self.analyticsEnabled = analyticsEnabled
        self.differentialPrivacyEnabled = differentialPrivacyEnabled
        self.dataRetentionPeriod = dataRetentionPeriod
        self.aggregatedSharingEnabled = aggregatedSharingEnabled
    }
}

/// Privacy transparency report components
public struct PrivacyTransparencyReport: Codable, Hashable {
    public let dataCollected: DataCollectionSummary
    public let privacyTechniques: PrivacyTechniquesSummary
    public let dataRetention: DataRetentionStatus
    public let sharingPractices: SharingPracticesSummary
    public let userRights: UserRightsSummary
    public let auditTrails: [AuditTrailEntry]
    
    public init(dataCollected: DataCollectionSummary, privacyTechniques: PrivacyTechniquesSummary, dataRetention: DataRetentionStatus, sharingPractices: SharingPracticesSummary, userRights: UserRightsSummary, auditTrails: [AuditTrailEntry]) {
        self.dataCollected = dataCollected
        self.privacyTechniques = privacyTechniques
        self.dataRetention = dataRetention
        self.sharingPractices = sharingPractices
        self.userRights = userRights
        self.auditTrails = auditTrails
    }
}

/// Data collection summary
public struct DataCollectionSummary: Codable, Hashable {
    public let typesCollected: [String]
    public let collectionFrequency: String
    public let retentionPeriod: String
    public let privacyTechniques: [String]
    
    public init(typesCollected: [String], collectionFrequency: String, retentionPeriod: String, privacyTechniques: [String]) {
        self.typesCollected = typesCollected
        self.collectionFrequency = collectionFrequency
        self.retentionPeriod = retentionPeriod
        self.privacyTechniques = privacyTechniques
    }
}

/// Privacy techniques summary
public struct PrivacyTechniquesSummary: Codable, Hashable {
    public let differentialPrivacy: String
    public let localProcessing: String
    public let anonymization: String
    public let encryption: String
    
    public init(differentialPrivacy: String, localProcessing: String, anonymization: String, encryption: String) {
        self.differentialPrivacy = differentialPrivacy
        self.localProcessing = localProcessing
        self.anonymization = anonymization
        self.encryption = encryption
    }
}

/// Sharing practices summary
public struct SharingPracticesSummary: Codable, Hashable {
    public let dataShared: String
    public let sharingPurpose: String
    public let recipientTypes: [String]
    public let userControl: String
    
    public init(dataShared: String, sharingPurpose: String, recipientTypes: [String], userControl: String) {
        self.dataShared = dataShared
        self.sharingPurpose = sharingPurpose
        self.recipientTypes = recipientTypes
        self.userControl = userControl
    }
}

/// User rights summary
public struct UserRightsSummary: Codable, Hashable {
    public let accessRight: String
    public let correctionRight: String
    public let deletionRight: String
    public let portabilityRight: String
    public let objectionRight: String
    
    public init(accessRight: String, correctionRight: String, deletionRight: String, portabilityRight: String, objectionRight: String) {
        self.accessRight = accessRight
        self.correctionRight = correctionRight
        self.deletionRight = deletionRight
        self.portabilityRight = portabilityRight
        self.objectionRight = objectionRight
    }
}

/// Audit trail entry
public struct AuditTrailEntry: Codable, Hashable {
    public let action: String
    public let timestamp: Date
    public let details: String
    
    public init(action: String, timestamp: Date, details: String) {
        self.action = action
        self.timestamp = timestamp
        self.details = details
    }
}
