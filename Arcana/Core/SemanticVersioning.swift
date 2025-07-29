//
// Core/SemanticVersioning.swift
// Arcana
//

import Foundation
import OSLog

@MainActor
class SemanticVersioning: ObservableObject {
    @Published var currentVersions: [String: Version] = [:]
    @Published var versionHistory: [VersionEntry] = []
    @Published var versioningRules: VersioningRules = VersioningRules()
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "SemanticVersioning")
    private var versionAnalyzer: VersionAnalyzer
    private var changeClassifier: ChangeClassifier
    
    init() {
        self.versionAnalyzer = VersionAnalyzer()
        self.changeClassifier = ChangeClassifier()
    }
    
    func initialize() async throws {
        logger.info("Initializing Semantic Versioning...")
        
        await versionAnalyzer.initialize()
        await changeClassifier.initialize()
        await loadVersionHistory()
        
        logger.info("Semantic Versioning initialized")
    }
    
    func generateVersion(for evolution: CodeEvolution) async -> String {
        logger.debug("Generating semantic version for code evolution")
        
        // Classify the type of change
        let changeType = await changeClassifier.classifyChange(evolution)
        
        // Get current version or start with 1.0.0
        let currentVersion = getCurrentVersion()
        
        // Generate next version based on change type
        let nextVersion = calculateNextVersion(
            current: currentVersion,
            changeType: changeType,
            evolution: evolution
        )
        
        // Record version entry
        let entry = VersionEntry(
            version: nextVersion,
            evolution: evolution,
            changeType: changeType,
            timestamp: Date(),
            description: generateVersionDescription(evolution, changeType)
        )
        
        await recordVersion(entry)
        
        logger.debug("Generated version: \(nextVersion.toString())")
        return nextVersion.toString()
    }
    
    func analyzeVersionTrend(project: String, timeframe: TimeFrame) async -> VersionTrend {
        logger.debug("Analyzing version trend for project: \(project)")
        
        let cutoffDate = getCutoffDate(for: timeframe)
        let recentVersions = versionHistory.filter {
            $0.timestamp > cutoffDate
        }
        
        let releaseFrequency = calculateReleaseFrequency(recentVersions, timeframe: timeframe)
        let changeDistribution = analyzeChangeDistribution(recentVersions)
        let stabilityScore = calculateStabilityScore(recentVersions)
        
        return VersionTrend(
            project: project,
            timeframe: timeframe,
            releaseFrequency: releaseFrequency,
            changeDistribution: changeDistribution,
            stabilityScore: stabilityScore,
            totalReleases: recentVersions.count,
            trend: determineTrendDirection(recentVersions)
        )
    }
    
    func suggestNextVersion(
        current: Version,
        plannedChanges: [PlannedChange]
    ) -> VersionSuggestion {
        
        logger.debug("Suggesting next version based on planned changes")
        
        var suggestedChangeType = ChangeType.patch
        var reasoning: [String] = []
        
        // Analyze planned changes
        for change in plannedChanges {
            switch change.impact {
            case .breaking:
                suggestedChangeType = .major
                reasoning.append("Breaking change: \(change.description)")
            case .feature:
                if suggestedChangeType != .major {
                    suggestedChangeType = .minor
                }
                reasoning.append("New feature: \(change.description)")
            case .fix, .improvement:
                // Keep current change type (patch by default)
                reasoning.append("Fix/improvement: \(change.description)")
            }
        }
        
        let suggestedVersion = calculateNextVersion(
            current: current,
            changeType: suggestedChangeType,
            evolution: nil
        )
        
        return VersionSuggestion(
            current: current,
            suggested: suggestedVersion,
            changeType: suggestedChangeType,
            reasoning: reasoning,
            confidence: calculateSuggestionConfidence(plannedChanges)
        )
    }
    
    func compareVersions(_ version1: String, _ version2: String) -> VersionComparison {
        let v1 = Version.parse(version1)
        let v2 = Version.parse(version2)
        
        let comparison: ComparisonResult
        if v1 < v2 {
            comparison = .older
        } else if v1 > v2 {
            comparison = .newer
        } else {
            comparison = .same
        }
        
        let distance = calculateVersionDistance(v1, v2)
        let compatibility = assessCompatibility(v1, v2)
        
        return VersionComparison(
            version1: v1,
            version2: v2,
            result: comparison,
            distance: distance,
            compatibility: compatibility
        )
    }
    
    func getVersionHistory(project: String? = nil, limit: Int = 50) -> [VersionEntry] {
        let filtered = versionHistory
        return Array(filtered.suffix(limit))
    }
    
    func isBreakingChange(_ evolution: CodeEvolution) async -> Bool {
        return await changeClassifier.isBreakingChange(evolution)
    }
    
    // MARK: - Private Methods
    
    private func loadVersionHistory() async {
        // Load version history from storage
        versionHistory = []
        logger.debug("Loaded version history")
    }
    
    private func getCurrentVersion() -> Version {
        // Get the most recent version, or default to 1.0.0
        return versionHistory.last?.version ?? Version(major: 1, minor: 0, patch: 0)
    }
    
    private func calculateNextVersion(
        current: Version,
        changeType: ChangeType,
        evolution: CodeEvolution?
    ) -> Version {
        
        switch changeType {
        case .major:
            return Version(major: current.major + 1, minor: 0, patch: 0)
        case .minor:
            return Version(major: current.major, minor: current.minor + 1, patch: 0)
        case .patch:
            return Version(major: current.major, minor: current.minor, patch: current.patch + 1)
        }
    }
    
    private func generateVersionDescription(_ evolution: CodeEvolution, _ changeType: ChangeType) -> String {
        var description = ""
        
        switch changeType {
        case .major:
            description = "Major release with breaking changes"
        case .minor:
            description = "Minor release with new features"
        case .patch:
            description = "Patch release with bug fixes and improvements"
        }
        
        // Add specific details from evolution
        if evolution.functionsAdded > 0 {
            description += " (+\(evolution.functionsAdded) functions)"
        }
        
        if evolution.linesAdded > 0 {
            description += " (+\(evolution.linesAdded) lines)"
        }
        
        if evolution.type == .refactoring {
            description += " (refactored)"
        }
        
        return description
    }
    
    private func recordVersion(_ entry: VersionEntry) async {
        await MainActor.run {
            self.versionHistory.append(entry)
            
            // Update current versions
            self.currentVersions["main"] = entry.version
            
            // Keep history manageable
            if self.versionHistory.count > 1000 {
                self.versionHistory.removeFirst()
            }
        }
        
        logger.debug("Recorded version: \(entry.version.toString())")
    }
    
    private func getCutoffDate(for timeframe: TimeFrame) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeframe {
        case .lastDay:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .lastWeek:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .lastMonth:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .lastYear:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
    
    private func calculateReleaseFrequency(_ versions: [VersionEntry], timeframe: TimeFrame) -> Double {
        guard !versions.isEmpty else { return 0.0 }
        
        let timeframeDays = Double(timeframe.days)
        return Double(versions.count) / timeframeDays
    }
    
    private func analyzeChangeDistribution(_ versions: [VersionEntry]) -> ChangeDistribution {
        let majorCount = versions.filter { $0.changeType == .major }.count
        let minorCount = versions.filter { $0.changeType == .minor }.count
        let patchCount = versions.filter { $0.changeType == .patch }.count
        
        let total = versions.count
        
        return ChangeDistribution(
            major: total > 0 ? Double(majorCount) / Double(total) : 0.0,
            minor: total > 0 ? Double(minorCount) / Double(total) : 0.0,
            patch: total > 0 ? Double(patchCount) / Double(total) : 0.0
        )
    }
    
    private func calculateStabilityScore(_ versions: [VersionEntry]) -> Double {
        guard !versions.isEmpty else { return 1.0 }
        
        // Higher stability = fewer major releases, more patch releases
        let majorCount = versions.filter { $0.changeType == .major }.count
        let patchCount = versions.filter { $0.changeType == .patch }.count
        
        let stabilityRatio = Double(patchCount) / Double(max(majorCount + patchCount, 1))
        return min(1.0, stabilityRatio)
    }
    
    private func determineTrendDirection(_ versions: [VersionEntry]) -> TrendDirection {
        guard versions.count > 1 else { return .stable }
        
        let recentVersions = versions.suffix(5)
        let earlierVersions = versions.prefix(5)
        
        let recentAvgInterval = calculateAverageReleaseInterval(Array(recentVersions))
        let earlierAvgInterval = calculateAverageReleaseInterval(Array(earlierVersions))
        
        if recentAvgInterval < earlierAvgInterval * 0.8 {
            return .increasing // Faster releases
        } else if recentAvgInterval > earlierAvgInterval * 1.2 {
            return .decreasing // Slower releases
        } else {
            return .stable
        }
    }
    
    private func calculateAverageReleaseInterval(_ versions: [VersionEntry]) -> TimeInterval {
        guard versions.count > 1 else { return 0 }
        
        let sortedVersions = versions.sorted { $0.timestamp < $1.timestamp }
        var totalInterval: TimeInterval = 0
        
        for i in 1..<sortedVersions.count {
            totalInterval += sortedVersions[i].timestamp.timeIntervalSince(sortedVersions[i-1].timestamp)
        }
        
        return totalInterval / Double(sortedVersions.count - 1)
    }
    
    private func calculateSuggestionConfidence(_ changes: [PlannedChange]) -> Double {
        guard !changes.isEmpty else { return 0.5 }
        
        // Higher confidence if changes are clearly categorized
        let clearlyBreaking = changes.filter { $0.impact == .breaking }.count
        let clearlyFeature = changes.filter { $0.impact == .feature }.count
        let total = changes.count
        
        let clarityRatio = Double(clearlyBreaking + clearlyFeature) / Double(total)
        return 0.5 + (clarityRatio * 0.4) // 0.5 to 0.9 range
    }
    
    private func calculateVersionDistance(_ v1: Version, _ v2: Version) -> Int {
        let majorDiff = abs(v1.major - v2.major) * 10000
        let minorDiff = abs(v1.minor - v2.minor) * 100
        let patchDiff = abs(v1.patch - v2.patch)
        
        return majorDiff + minorDiff + patchDiff
    }
    
    private func assessCompatibility(_ v1: Version, _ v2: Version) -> CompatibilityLevel {
        // Semantic versioning compatibility rules
        if v1.major != v2.major {
            return .incompatible // Breaking changes
        } else if v1.minor != v2.minor {
            return .backwardCompatible // New features, but backward compatible
        } else {
            return .fullyCompatible // Only patches/fixes
        }
    }
}

// MARK: - Supporting Types

struct Version: Codable, Comparable {
    let major: Int
    let minor: Int
    let patch: Int
    let prerelease: String?
    let build: String?
    
    init(major: Int, minor: Int, patch: Int, prerelease: String? = nil, build: String? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.build = build
    }
    
    func toString() -> String {
        var version = "\(major).\(minor).\(patch)"
        
        if let prerelease = prerelease {
            version += "-\(prerelease)"
        }
        
        if let build = build {
            version += "+\(build)"
        }
        
        return version
    }
    
    static func parse(_ versionString: String) -> Version {
        // Simple version parsing (would be more robust in production)
        let components = versionString.components(separatedBy: ".")
        
        guard components.count >= 3,
              let major = Int(components[0]),
              let minor = Int(components[1]),
              let patch = Int(components[2]) else {
            return Version(major: 1, minor: 0, patch: 0)
        }
        
        return Version(major: major, minor: minor, patch: patch)
    }
    
    static func < (lhs: Version, rhs: Version) -> Bool {
        if lhs.major != rhs.major {
            return lhs.major < rhs.major
        }
        if lhs.minor != rhs.minor {
            return lhs.minor < rhs.minor
        }
        return lhs.patch < rhs.patch
    }
    
    static func == (lhs: Version, rhs: Version) -> Bool {
        return lhs.major == rhs.major &&
               lhs.minor == rhs.minor &&
               lhs.patch == rhs.patch
    }
}

enum ChangeType: String, Codable {
    case major = "major"
    case minor = "minor"
    case patch = "patch"
}

struct VersionEntry {
    let version: Version
    let evolution: CodeEvolution
    let changeType: ChangeType
    let timestamp: Date
    let description: String
}

struct VersioningRules {
    let majorChangeThreshold: Double = 0.8 // Complexity increase threshold for major
    let minorFeatureThreshold: Int = 2 // Number of new functions for minor
    let breakingChangePatterns: [String] = [
        "removed function",
        "changed signature",
        "breaking change"
    ]
}

struct VersionTrend {
    let project: String
    let timeframe: TimeFrame
    let releaseFrequency: Double
    let changeDistribution: ChangeDistribution
    let stabilityScore: Double
    let totalReleases: Int
    let trend: TrendDirection
}

struct ChangeDistribution {
    let major: Double
    let minor: Double
    let patch: Double
}

struct PlannedChange {
    let description: String
    let impact: ChangeImpact
    
    enum ChangeImpact {
        case breaking
        case feature
        case fix
        case improvement
    }
}

struct VersionSuggestion {
    let current: Version
    let suggested: Version
    let changeType: ChangeType
    let reasoning: [String]
    let confidence: Double
}

struct VersionComparison {
    let version1: Version
    let version2: Version
    let result: ComparisonResult
    let distance: Int
    let compatibility: CompatibilityLevel
}

enum ComparisonResult {
    case older
    case newer
    case same
}

enum CompatibilityLevel {
    case fullyCompatible
    case backwardCompatible
    case incompatible
}

// MARK: - Supporting Classes

class VersionAnalyzer {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "VersionAnalyzer")
    
    func initialize() async {
        logger.debug("Version analyzer initialized")
    }
}

class ChangeClassifier {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ChangeClassifier")
    
    func initialize() async {
        logger.debug("Change classifier initialized")
    }
    
    func classifyChange(_ evolution: CodeEvolution) async -> ChangeType {
        // Classify the type of change based on evolution
        
        // Check for breaking changes
        if await isBreakingChange(evolution) {
            return .major
        }
        
        // Check for new features
        if evolution.functionsAdded > 2 || evolution.type == .expansion {
            return .minor
        }
        
        // Check for significant complexity increase
        if evolution.complexity > 0.8 {
            return .major
        }
        
        // Default to patch for bug fixes and small improvements
        return .patch
    }
    
    func isBreakingChange(_ evolution: CodeEvolution) async -> Bool {
        // Determine if the evolution represents a breaking change
        
        // Function removal is typically breaking
        if evolution.functionsRemoved > 0 {
            return true
        }
        
        // Significant code reduction might be breaking
        if evolution.type == .reduction && evolution.linesRemoved > evolution.linesAdded * 2 {
            return true
        }
        
        // Major complexity changes might be breaking
        if evolution.complexity > 0.9 {
            return true
        }
        
        return false
    }
}

//
// Core/CodePatternLearning.swift
// Arcana
//

import Foundation
import OSLog

@MainActor
class CodePatternLearning: ObservableObject {
    @Published var learnedPatterns: [CodePattern] = []
    @Published var patternStats = PatternLearningStats()
    @Published var isLearning = false
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "CodePatternLearning")
    private var patternExtractor: PatternExtractor
    private var frequencyAnalyzer: FrequencyAnalyzer
    private var contextAnalyzer: ContextAnalyzer
    
    init() {
        self.patternExtractor = PatternExtractor()
        self.frequencyAnalyzer = FrequencyAnalyzer()
        self.contextAnalyzer = ContextAnalyzer()
    }
    
    func initialize() async throws {
        logger.info("Initializing Code Pattern Learning...")
        
        await patternExtractor.initialize()
        await frequencyAnalyzer.initialize()
        await contextAnalyzer.initialize()
        
        await loadLearnedPatterns()
        
        logger.info("Code Pattern Learning initialized")
    }
    
    func learnFromCode(_ code: String, language: CodeLanguage, context: ConversationContext) async {
        logger.debug("Learning patterns from \(language.rawValue) code")
        
        await MainActor.run {
            self.isLearning = true
        }
        
        // Extract patterns from code
        let extractedPatterns = await patternExtractor.extractPatterns(
            from: code,
            language: language,
            context: context
        )
        
        // Analyze frequency and context
        for pattern in extractedPatterns {
            await updatePatternFrequency(pattern, context: context)
            await analyzePatternContext(pattern, context: context)
        }
        
        // Update learned patterns
        await consolidatePatterns()
        
        // Update statistics
        await updatePatternStats()
        
        await MainActor.run {
            self.isLearning = false
        }
        
        logger.debug("Learned \(extractedPatterns.count) new patterns")
    }
    
    func getRelevantPatterns(for code: String, language: CodeLanguage) async -> [CodePattern] {
        logger.debug("Getting relevant patterns for code analysis")
        
        // Analyze the provided code to find similar patterns
        let codeFeatures = await extractCodeFeatures(code, language: language)
        
        // Find patterns that match the features
        let relevantPatterns = learnedPatterns.filter { pattern in
            hasMatchingFeatures(pattern: pattern, features: codeFeatures)
        }
        
        // Sort by relevance and frequency
        return relevantPatterns.sorted { pattern1, pattern2 in
            let relevance1 = calculateRelevance(pattern1, features: codeFeatures)
            let relevance2 = calculateRelevance(pattern2, features: codeFeatures)
            
            if relevance1 != relevance2 {
                return relevance1 > relevance2
            }
            
            return pattern1.frequency > pattern2.frequency
        }.prefix(10).map { $0 }
    }
    
    func getApplicablePatterns(history: [CodeSnapshot], partialCode: String) -> [CodePattern] {
        logger.debug("Getting applicable patterns based on history and partial code")
        
        // Analyze the context from history
        let contextFeatures = analyzeHistoryContext(history)
        
        // Analyze partial code features
        let codeFeatures = extractPartialCodeFeatures(partialCode)
        
        // Combine features to find applicable patterns
        let combinedFeatures = contextFeatures + codeFeatures
        
        return learnedPatterns.filter { pattern in
            pattern.applicableFeatures.contains { feature in
                combinedFeatures.contains(feature)
            }
        }.sorted { $0.frequency > $1.frequency }
    }
    
    func suggestPatternImprovements(_ pattern: CodePattern) async -> [PatternImprovement] {
        logger.debug("Suggesting improvements for pattern: \(pattern.name)")
        
        var improvements: [PatternImprovement] = []
        
        // Analyze pattern usage frequency
        if pattern.frequency < 0.1 {
            improvements.append(PatternImprovement(
                type: .increaseUsage,
                description: "This pattern is rarely used. Consider promoting it or reviewing its relevance.",
                priority: .low
            ))
        }
        
        // Analyze pattern complexity
        if pattern.complexity > 0.8 {
            improvements.append(PatternImprovement(
                type: .reduceComplexity,
                description: "This pattern is quite complex. Consider simplifying it.",
                priority: .high
            ))
        }
        
        // Check for similar patterns that could be consolidated
        let similarPatterns = await findSimilarPatterns(pattern)
        if similarPatterns.count > 1 {
            improvements.append(PatternImprovement(
                type: .consolidate,
                description: "Found \(similarPatterns.count) similar patterns that could be consolidated.",
                priority: .medium
            ))
        }
        
        // Analyze context coverage
        if pattern.contexts.count < 2 {
            improvements.append(PatternImprovement(
                type: .expandContext,
                description: "This pattern is only used in limited contexts. Consider expanding its applicability.",
                priority: .low
            ))
        }
        
        return improvements
    }
    
    func getPatternAnalytics() -> PatternAnalytics {
        let totalPatterns = learnedPatterns.count
        let languageDistribution = Dictionary(grouping: learnedPatterns, by: \.language)
            .mapValues { $0.count }
        
        let avgFrequency = learnedPatterns.isEmpty ? 0.0 :
            learnedPatterns.map(\.frequency).reduce(0, +) / Double(learnedPatterns.count)
        
        let avgComplexity = learnedPatterns.isEmpty ? 0.0 :
            learnedPatterns.map(\.complexity).reduce(0, +) / Double(learnedPatterns.count)
        
        let topPatterns = learnedPatterns.sorted { $0.frequency > $1.frequency }.prefix(10)
        
        return PatternAnalytics(
            totalPatterns: totalPatterns,
            languageDistribution: languageDistribution,
            averageFrequency: avgFrequency,
            averageComplexity: avgComplexity,
            topPatterns: Array(topPatterns),
            lastUpdated: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func loadLearnedPatterns() async {
        // Load patterns from storage
        learnedPatterns = []
        logger.debug("Loaded learned patterns from storage")
    }
    
    private func updatePatternFrequency(_ pattern: ExtractedPattern, context: ConversationContext) async {
        // Find existing pattern or create new one
        if let existingIndex = learnedPatterns.firstIndex(where: { $0.signature == pattern.signature }) {
            // Update existing pattern
            await MainActor.run {
                self.learnedPatterns[existingIndex].frequency += 0.1
                self.learnedPatterns[existingIndex].lastSeen = Date()
                self.learnedPatterns[existingIndex].usageCount += 1
            }
        } else {
            // Create new pattern
            let newPattern = CodePattern(
                id: UUID(),
                name: pattern.name,
                template: pattern.template,
                description: pattern.description,
                language: pattern.language,
                signature: pattern.signature,
                frequency: 0.1,
                complexity: pattern.complexity,
                contexts: [context.workspaceType],
                applicableFeatures: pattern.features,
                usageCount: 1,
                firstSeen: Date(),
                lastSeen: Date()
            )
            
            await MainActor.run {
                self.learnedPatterns.append(newPattern)
            }
        }
    }
    
    private func analyzePatternContext(_ pattern: ExtractedPattern, context: ConversationContext) async {
        // Update pattern context information
        if let existingIndex = learnedPatterns.firstIndex(where: { $0.signature == pattern.signature }) {
            await MainActor.run {
                var updatedPattern = self.learnedPatterns[existingIndex]
                if !updatedPattern.contexts.contains(context.workspaceType) {
                    updatedPattern.contexts.append(context.workspaceType)
                    self.learnedPatterns[existingIndex] = updatedPattern
                }
            }
        }
    }
    
    private func consolidatePatterns() async {
        // Remove duplicate or very similar patterns
        var consolidatedPatterns: [CodePattern] = []
        var processedSignatures: Set<String> = []
        
        for pattern in learnedPatterns {
            if !processedSignatures.contains(pattern.signature) {
                consolidatedPatterns.append(pattern)
                processedSignatures.insert(pattern.signature)
            }
        }
        
        await MainActor.run {
            self.learnedPatterns = consolidatedPatterns
        }
    }
    
    private func updatePatternStats() async {
        let totalPatterns = learnedPatterns.count
        let avgFrequency = learnedPatterns.isEmpty ? 0.0 :
            learnedPatterns.map(\.frequency).reduce(0, +) / Double(learnedPatterns.count)
        
        let recentPatterns = learnedPatterns.filter { pattern in
            pattern.lastSeen > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }.count
        
        await MainActor.run {
            self.patternStats = PatternLearningStats(
                totalPatterns: totalPatterns,
                averageFrequency: avgFrequency,
                recentlyUsedPatterns: recentPatterns,
                lastLearningSession: Date()
            )
        }
    }
    
    private func extractCodeFeatures(_ code: String, language: CodeLanguage) async -> [CodeFeature] {
        var features: [CodeFeature] = []
        
        // Extract basic features
        features.append(.lineCount(code.components(separatedBy: .newlines).count))
        
        // Extract language-specific features
        switch language {
        case .swift:
            if code.contains("func ") {
                features.append(.hasFunctions)
            }
            if code.contains("class ") || code.contains("struct ") {
                features.append(.hasClasses)
            }
            if code.contains("@") {
                features.append(.hasAttributes)
            }
            
        case .python:
            if code.contains("def ") {
                features.append(.hasFunctions)
            }
            if code.contains("class ") {
                features.append(.hasClasses)
            }
            if code.contains("import ") {
                features.append(.hasImports)
            }
            
        case .javascript:
            if code.contains("function ") || code.contains("=>") {
                features.append(.hasFunctions)
            }
            if code.contains("class ") {
                features.append(.hasClasses)
            }
            if code.contains("const ") || code.contains("let ") {
                features.append(.hasVariableDeclarations)
            }
            
        case .other:
            break
        }
        
        return features
    }
    
    private func hasMatchingFeatures(pattern: CodePattern, features: [CodeFeature]) -> Bool {
        let patternFeatureSet = Set(pattern.applicableFeatures)
        let codeFeatureSet = Set(features)
        
        // Check for intersection
        return !patternFeatureSet.intersection(codeFeatureSet).isEmpty
    }
    
    private func calculateRelevance(_ pattern: CodePattern, features: [CodeFeature]) -> Double {
        let patternFeatureSet = Set(pattern.applicableFeatures)
        let codeFeatureSet = Set(features)
        
        let intersection = patternFeatureSet.intersection(codeFeatureSet)
        let union = patternFeatureSet.union(codeFeatureSet)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func analyzeHistoryContext(_ history: [CodeSnapshot]) -> [CodeFeature] {
        var features: [CodeFeature] = []
        
        // Analyze patterns in history
        let languages = Set(history.map(\.language))
        if languages.count == 1 {
            features.append(.singleLanguage(languages.first!))
        }
        
        let avgComplexity = history.isEmpty ? 0.0 :
            history.map { calculateCodeComplexity($0.code, language: $0.language) }
                .reduce(0, +) / Double(history.count)
        
        if avgComplexity > 0.7 {
            features.append(.highComplexity)
        }
        
        return features
    }
    
    private func extractPartialCodeFeatures(_ partialCode: String) -> [CodeFeature] {
        var features: [CodeFeature] = []
        
        if partialCode.isEmpty {
            features.append(.empty)
        } else if partialCode.count < 20 {
            features.append(.short)
        }
        
        if partialCode.contains("{") && !partialCode.contains("}") {
            features.append(.incompleteBlock)
        }
        
        return features
    }
    
    private func calculateCodeComplexity(_ code: String, language: CodeLanguage) -> Double {
        // Simplified complexity calculation
        let lines = code.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let functions = countFunctions(code, language: language)
        let conditionals = countConditionals(code)
        
        let baseComplexity = Double(lines.count) * 0.01
        let functionComplexity = Double(functions) * 0.1
        let conditionalComplexity = Double(conditionals) * 0.05
        
        return min(1.0, baseComplexity + functionComplexity + conditionalComplexity)
    }
    
    private func countFunctions(_ code: String, language: CodeLanguage) -> Int {
        switch language {
        case .swift:
            return code.components(separatedBy: "func ").count - 1
        case .python:
            return code.components(separatedBy: "def ").count - 1
        case .javascript:
            return code.components(separatedBy: "function ").count - 1 +
                   code.components(separatedBy: " => ").count - 1
        case .other:
            return 0
        }
    }
    
    private func countConditionals(_ code: String) -> Int {
        let patterns = ["if ", "else", "switch", "case"]
        return patterns.reduce(0) { count, pattern in
            count + (code.components(separatedBy: pattern).count - 1)
        }
    }
    
    private func findSimilarPatterns(_ pattern: CodePattern) async -> [CodePattern] {
        return learnedPatterns.filter { otherPattern in
            otherPattern.id != pattern.id &&
            calculatePatternSimilarity(pattern, otherPattern) > 0.8
        }
    }
    
    private func calculatePatternSimilarity(_ pattern1: CodePattern, _ pattern2: CodePattern) -> Double {
        // Calculate similarity between two patterns
        let templateSimilarity = calculateStringSimilarity(pattern1.template, pattern2.template)
        let featureSimilarity = calculateFeatureSimilarity(pattern1.applicableFeatures, pattern2.applicableFeatures)
        
        return (templateSimilarity + featureSimilarity) / 2.0
    }
    
    private func calculateStringSimilarity(_ str1: String, _ str2: String) -> Double {
        let words1 = Set(str1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(str2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func calculateFeatureSimilarity(_ features1: [CodeFeature], _ features2: [CodeFeature]) -> Double {
        let set1 = Set(features1.map { $0.description })
        let set2 = Set(features2.map { $0.description })
        
        let intersection = set1.intersection(set2)
        let union = set1.union(set2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
}

// MARK: - Supporting Types

struct CodePattern {
    let id: UUID
    let name: String
    let template: String
    let description: String
    let language: CodeLanguage
    let signature: String
    var frequency: Double
    let complexity: Double
    var contexts: [WorkspaceType]
    let applicableFeatures: [CodeFeature]
    var usageCount: Int
    let firstSeen: Date
    var lastSeen: Date
}

struct PatternLearningStats {
    let totalPatterns: Int
    let averageFrequency: Double
    let recentlyUsedPatterns: Int
    let lastLearningSession: Date
}

struct ExtractedPattern {
    let name: String
    let template: String
    let description: String
    let language: CodeLanguage
    let signature: String
    let complexity: Double
    let features: [CodeFeature]
}

enum CodeFeature: Hashable {
    case lineCount(Int)
    case hasFunctions
    case hasClasses
    case hasAttributes
    case hasImports
    case hasVariableDeclarations
    case singleLanguage(CodeLanguage)
    case highComplexity
    case empty
    case short
    case incompleteBlock
    
    var description: String {
        switch self {
        case .lineCount(let count): return "lineCount_\(count)"
        case .hasFunctions: return "hasFunctions"
        case .hasClasses: return "hasClasses"
        case .hasAttributes: return "hasAttributes"
        case .hasImports: return "hasImports"
        case .hasVariableDeclarations: return "hasVariableDeclarations"
        case .singleLanguage(let lang): return "singleLanguage_\(lang.rawValue)"
        case .highComplexity: return "highComplexity"
        case .empty: return "empty"
        case .short: return "short"
        case .incompleteBlock: return "incompleteBlock"
        }
    }
}

struct PatternImprovement {
    let type: ImprovementType
    let description: String
    let priority: Priority
    
    enum ImprovementType {
        case increaseUsage
        case reduceComplexity
        case consolidate
        case expandContext
    }
    
    enum Priority {
        case low, medium, high
    }
}

struct PatternAnalytics {
    let totalPatterns: Int
    let languageDistribution: [CodeLanguage: Int]
    let averageFrequency: Double
    let averageComplexity: Double
    let topPatterns: [CodePattern]
    let lastUpdated: Date
}

// MARK: - Supporting Classes

class PatternExtractor {
    func initialize() async {
        // Initialize pattern extraction
    }
    
    func extractPatterns(from code: String, language: CodeLanguage, context: ConversationContext) async -> [ExtractedPattern] {
        var patterns: [ExtractedPattern] = []
        
        // Extract function patterns
        let functionPatterns = extractFunctionPatterns(code, language: language)
        patterns.append(contentsOf: functionPatterns)
        
        // Extract structural patterns
        let structuralPatterns = extractStructuralPatterns(code, language: language)
        patterns.append(contentsOf: structuralPatterns)
        
        return patterns
    }
    
    private func extractFunctionPatterns(_ code: String, language: CodeLanguage) -> [ExtractedPattern] {
        // Simplified pattern extraction
        return []
    }
    
    private func extractStructuralPatterns(_ code: String, language: CodeLanguage) -> [ExtractedPattern] {
        // Simplified pattern extraction
        return []
    }
}

class FrequencyAnalyzer {
    func initialize() async {
        // Initialize frequency analysis
    }
}

class ContextAnalyzer {
    func initialize() async {
        // Initialize context analysis
    }
}
