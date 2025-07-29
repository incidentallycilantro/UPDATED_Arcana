//
// CodeEvolution.swift
// Arcana
//
// Revolutionary code evolution tracking with semantic versioning and pattern learning
// Tracks code changes, improvements, and learning patterns across development sessions
//

import Foundation

// MARK: - Code Evolution

/// Revolutionary code evolution tracking system that learns from development patterns
/// Provides intelligent version management, change analysis, and improvement suggestions
public struct CodeEvolution: Codable, Hashable, Identifiable {
    
    // MARK: - Properties
    
    public let id: UUID
    public let projectId: UUID
    public let threadId: UUID
    public let creationDate: Date
    public var lastModified: Date
    
    // Version information
    public var currentVersion: SemanticVersion
    public var versionHistory: [CodeVersion]
    public var branchingStrategy: BranchingStrategy
    public var versioningScheme: VersioningScheme
    
    // Code analysis
    public var codeMetrics: CodeMetrics
    public var qualityTrends: [QualityTrend]
    public var complexityEvolution: ComplexityEvolution
    public var performanceMetrics: [PerformanceSnapshot]
    
    // Pattern learning
    public var developmentPatterns: [DevelopmentPattern]
    public var refactoringHistory: [RefactoringEvent]
    public var bugPatterns: [BugPattern]
    public var improvementSuggestions: [ImprovementSuggestion]
    
    // Collaboration tracking
    public var contributors: [Contributor]
    public var codeReviews: [CodeReview]
    public var knowledgeTransfer: [KnowledgeTransferEvent]
    
    // Intelligence features
    public var predictedIssues: [PredictedIssue]
    public var optimizationOpportunities: [OptimizationOpportunity]
    public var learningInsights: [LearningInsight]
    public var evolutionMilestones: [EvolutionMilestone]
    
    // MARK: - Initialization
    
    public init(projectId: UUID, threadId: UUID) {
        self.id = UUID()
        self.projectId = projectId
        self.threadId = threadId
        self.creationDate = Date()
        self.lastModified = Date()
        
        self.currentVersion = SemanticVersion(major: 0, minor: 1, patch: 0)
        self.versionHistory = []
        self.branchingStrategy = .feature
        self.versioningScheme = .semantic
        
        self.codeMetrics = CodeMetrics()
        self.qualityTrends = []
        self.complexityEvolution = ComplexityEvolution()
        self.performanceMetrics = []
        
        self.developmentPatterns = []
        self.refactoringHistory = []
        self.bugPatterns = []
        self.improvementSuggestions = []
        
        self.contributors = []
        self.codeReviews = []
        self.knowledgeTransfer = []
        
        self.predictedIssues = []
        self.optimizationOpportunities = []
        self.learningInsights = []
        self.evolutionMilestones = []
    }
    
    // MARK: - Computed Properties
    
    /// Overall code health score (0.0 - 1.0)
    public var healthScore: Double {
        let qualityScore = codeMetrics.overallQuality
        let complexityScore = 1.0 - min(1.0, complexityEvolution.currentComplexity / 10.0)
        let bugScore = bugPatterns.isEmpty ? 1.0 : max(0.3, 1.0 - Double(bugPatterns.count) / 10.0)
        let performanceScore = performanceMetrics.last?.performanceIndex ?? 0.8
        
        return (qualityScore * 0.3 + complexityScore * 0.25 + bugScore * 0.25 + performanceScore * 0.2)
    }
    
    /// Development velocity trend
    public var velocityTrend: VelocityTrend {
        guard versionHistory.count >= 3 else { return .stable }
        
        let recentVersions = versionHistory.suffix(3)
        let intervals = recentVersions.map { $0.developmentTime }
        
        let averageRecent = intervals.suffix(2).reduce(0, +) / 2.0
        let averageOlder = intervals.prefix(1).first ?? averageRecent
        
        if averageRecent < averageOlder * 0.8 {
            return .accelerating
        } else if averageRecent > averageOlder * 1.2 {
            return .decelerating
        } else {
            return .stable
        }
    }
    
    /// Technical debt level
    public var technicalDebtLevel: TechnicalDebtLevel {
        let complexityFactor = complexityEvolution.currentComplexity / 10.0
        let bugFactor = Double(bugPatterns.count) / 5.0
        let refactoringNeed = refactoringHistory.isEmpty ? 1.0 : 0.5
        
        let debtScore = (complexityFactor + bugFactor + refactoringNeed) / 3.0
        
        switch debtScore {
        case 0.0..<0.3: return .low
        case 0.3..<0.6: return .moderate
        case 0.6..<0.8: return .high
        default: return .critical
        }
    }
    
    /// Evolution maturity level
    public var maturityLevel: MaturityLevel {
        let versionCount = versionHistory.count
        let ageInDays = Date().timeIntervalSince(creationDate) / 86400
        let stabilityScore = healthScore
        
        if versionCount >= 20 && ageInDays >= 90 && stabilityScore > 0.8 {
            return .mature
        } else if versionCount >= 10 && ageInDays >= 30 && stabilityScore > 0.7 {
            return .stable
        } else if versionCount >= 5 && ageInDays >= 7 && stabilityScore > 0.6 {
            return .developing
        } else {
            return .experimental
        }
    }
    
    // MARK: - Version Management
    
    /// Create a new version with changes
    public mutating func createVersion(
        changes: [CodeChange],
        type: VersionType,
        description: String,
        author: String
    ) -> CodeVersion {
        
        // Update semantic version based on type
        updateSemanticVersion(for: type)
        
        // Analyze changes
        let changeAnalysis = analyzeChanges(changes)
        
        // Create new version
        let newVersion = CodeVersion(
            version: currentVersion,
            changes: changes,
            type: type,
            description: description,
            author: author,
            timestamp: Date(),
            metrics: codeMetrics,
            changeAnalysis: changeAnalysis
        )
        
        // Add to history
        versionHistory.append(newVersion)
        
        // Update tracking data
        updateMetricsFromVersion(newVersion)
        updatePatterns(from: changes)
        generateInsights()
        
        lastModified = Date()
        
        return newVersion
    }
    
    /// Track refactoring event
    public mutating func trackRefactoring(
        description: String,
        files: [String],
        reason: RefactoringReason,
        impact: RefactoringImpact
    ) {
        let refactoringEvent = RefactoringEvent(
            description: description,
            files: files,
            reason: reason,
            impact: impact,
            timestamp: Date(),
            beforeMetrics: codeMetrics,
            afterMetrics: nil // Will be updated when next version is created
        )
        
        refactoringHistory.append(refactoringEvent)
        
        // Learn from refactoring patterns
        learnFromRefactoring(refactoringEvent)
        
        lastModified = Date()
    }
    
    /// Track bug pattern
    public mutating func trackBugPattern(
        description: String,
        category: BugCategory,
        severity: BugSeverity,
        rootCause: String,
        fix: String
    ) {
        let bugPattern = BugPattern(
            description: description,
            category: category,
            severity: severity,
            rootCause: rootCause,
            fix: fix,
            occurrenceCount: 1,
            firstSeen: Date(),
            lastSeen: Date()
        )
        
        // Check if similar pattern exists
        if let existingIndex = bugPatterns.firstIndex(where: { $0.isSimilar(to: bugPattern) }) {
            bugPatterns[existingIndex].recordOccurrence()
        } else {
            bugPatterns.append(bugPattern)
        }
        
        // Generate predictions based on patterns
        updatePredictedIssues()
        
        lastModified = Date()
    }
    
    /// Add contributor
    public mutating func addContributor(
        name: String,
        role: ContributorRole,
        expertise: [String],
        joinDate: Date = Date()
    ) {
        let contributor = Contributor(
            id: UUID(),
            name: name,
            role: role,
            expertise: expertise,
            joinDate: joinDate,
            contributions: 0,
            lastActivity: Date()
        )
        
        contributors.append(contributor)
        lastModified = Date()
    }
    
    // MARK: - Analysis Methods
    
    /// Generate comprehensive evolution report
    public func generateEvolutionReport() -> EvolutionReport {
        return EvolutionReport(
            codeEvolution: self,
            executiveSummary: generateExecutiveSummary(),
            versionAnalysis: analyzeVersionHistory(),
            qualityAnalysis: analyzeQualityTrends(),
            performanceAnalysis: analyzePerformanceEvolution(),
            patternAnalysis: analyzeDevelopmentPatterns(),
            recommendations: generateRecommendations(),
            futureProjections: generateProjections()
        )
    }
    
    /// Compare with another evolution timeline
    public func compare(with other: CodeEvolution) -> EvolutionComparison {
        return EvolutionComparison(
            baseline: self,
            comparison: other,
            healthScoreDifference: healthScore - other.healthScore,
            velocityComparison: compareVelocity(with: other),
            qualityComparison: compareQuality(with: other),
            complexityComparison: compareComplexity(with: other),
            insights: generateComparisonInsights(with: other)
        )
    }
    
    /// Get evolution insights for improvement
    public func getEvolutionInsights() -> [EvolutionInsight] {
        var insights: [EvolutionInsight] = []
        
        // Health insights
        if healthScore < 0.7 {
            insights.append(EvolutionInsight(
                type: .healthConcern,
                priority: .high,
                description: "Code health score is below recommended threshold",
                recommendation: "Focus on code quality improvements and bug fixes",
                impact: .quality
            ))
        }
        
        // Velocity insights
        if velocityTrend == .decelerating {
            insights.append(EvolutionInsight(
                type: .velocityDecline,
                priority: .medium,
                description: "Development velocity is decreasing",
                recommendation: "Consider process improvements or additional resources",
                impact: .productivity
            ))
        }
        
        // Technical debt insights
        if technicalDebtLevel == .high || technicalDebtLevel == .critical {
            insights.append(EvolutionInsight(
                type: .technicalDebt,
                priority: .high,
                description: "Technical debt level is concerning",
                recommendation: "Prioritize refactoring and code cleanup",
                impact: .maintainability
            ))
        }
        
        return insights
    }
    
    /// Predict future issues based on patterns
    public func predictFutureIssues() -> [FutureIssue] {
        var predictions: [FutureIssue] = []
        
        // Analyze bug patterns for predictions
        for bugPattern in bugPatterns where bugPattern.occurrenceCount > 2 {
            let probability = min(0.8, Double(bugPattern.occurrenceCount) / 10.0)
            predictions.append(FutureIssue(
                type: .bugRecurrence,
                probability: probability,
                description: "Similar to: \(bugPattern.description)",
                timeline: .weeks(2),
                severity: bugPattern.severity,
                preventionStrategy: bugPattern.fix
            ))
        }
        
        // Analyze complexity trends
        if complexityEvolution.isIncreasing {
            predictions.append(FutureIssue(
                type: .complexityOverload,
                probability: 0.6,
                description: "Code complexity is trending upward",
                timeline: .months(1),
                severity: .medium,
                preventionStrategy: "Implement regular refactoring cycles"
            ))
        }
        
        return predictions
    }
    
    // MARK: - Private Methods
    
    private mutating func updateSemanticVersion(for type: VersionType) {
        switch type {
        case .major:
            currentVersion = SemanticVersion(
                major: currentVersion.major + 1,
                minor: 0,
                patch: 0
            )
        case .minor:
            currentVersion = SemanticVersion(
                major: currentVersion.major,
                minor: currentVersion.minor + 1,
                patch: 0
            )
        case .patch:
            currentVersion = SemanticVersion(
                major: currentVersion.major,
                minor: currentVersion.minor,
                patch: currentVersion.patch + 1
            )
        case .prerelease:
            // Handle prerelease versioning
            break
        }
    }
    
    private func analyzeChanges(_ changes: [CodeChange]) -> ChangeAnalysis {
        let totalLines = changes.reduce(0) { $0 + $1.linesAdded + $1.linesRemoved }
        let filesChanged = Set(changes.map { $0.filePath }).count
        let changeTypes = Set(changes.map { $0.type })
        
        return ChangeAnalysis(
            totalChanges: changes.count,
            linesChanged: totalLines,
            filesAffected: filesChanged,
            changeTypes: Array(changeTypes),
            complexity: calculateChangeComplexity(changes),
            riskLevel: assessChangeRisk(changes)
        )
    }
    
    private func calculateChangeComplexity(_ changes: [CodeChange]) -> Double {
        let complexityScore = changes.reduce(0.0) { total, change in
            var score = 0.0
            score += Double(change.linesAdded + change.linesRemoved) * 0.1
            score += change.type == .architecture ? 2.0 : 1.0
            score += change.filePath.contains("core") ? 1.5 : 1.0
            return total + score
        }
        
        return min(10.0, complexityScore / Double(changes.count))
    }
    
    private func assessChangeRisk(_ changes: [CodeChange]) -> RiskLevel {
        let architecturalChanges = changes.filter { $0.type == .architecture }.count
        let coreFileChanges = changes.filter { $0.filePath.contains("core") }.count
        let totalLines = changes.reduce(0) { $0 + $1.linesAdded + $1.linesRemoved }
        
        if architecturalChanges > 0 || coreFileChanges > 5 || totalLines > 1000 {
            return .high
        } else if coreFileChanges > 2 || totalLines > 500 {
            return .medium
        } else {
            return .low
        }
    }
    
    private mutating func updateMetricsFromVersion(_ version: CodeVersion) {
        // Update overall metrics based on version changes
        codeMetrics.updateFromVersion(version)
        
        // Add quality trend point
        let qualityTrend = QualityTrend(
            timestamp: version.timestamp,
            overallQuality: codeMetrics.overallQuality,
            maintainabilityIndex: codeMetrics.maintainabilityIndex,
            testCoverage: codeMetrics.testCoverage,
            codeReuse: codeMetrics.codeReuse
        )
        
        qualityTrends.append(qualityTrend)
        
        // Update complexity evolution
        complexityEvolution.addDataPoint(
            timestamp: version.timestamp,
            complexity: calculateComplexityFromChanges(version.changes)
        )
    }
    
    private func calculateComplexityFromChanges(_ changes: [CodeChange]) -> Double {
        return changes.reduce(0.0) { total, change in
            total + calculateChangeComplexity([change])
        }
    }
    
    private mutating func updatePatterns(from changes: [CodeChange]) {
        // Extract development patterns from changes
        let changePatterns = extractPatternsFromChanges(changes)
        
        for pattern in changePatterns {
            if let existingIndex = developmentPatterns.firstIndex(where: { $0.isSimilar(to: pattern) }) {
                developmentPatterns[existingIndex].recordOccurrence()
            } else {
                developmentPatterns.append(pattern)
            }
        }
    }
    
    private func extractPatternsFromChanges(_ changes: [CodeChange]) -> [DevelopmentPattern] {
        var patterns: [DevelopmentPattern] = []
        
        // Group changes by type and analyze patterns
        let changesByType = Dictionary(grouping: changes, by: { $0.type })
        
        for (type, typeChanges) in changesByType {
            if typeChanges.count > 1 {
                let pattern = DevelopmentPattern(
                    name: "Bulk \(type.rawValue) changes",
                    description: "Multiple \(type.rawValue) changes in single version",
                    frequency: 1,
                    confidence: 0.7,
                    impact: .medium,
                    lastOccurrence: Date()
                )
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    private mutating func learnFromRefactoring(_ refactoring: RefactoringEvent) {
        // Learn patterns from refactoring events
        let pattern = DevelopmentPattern(
            name: "Refactoring: \(refactoring.reason.rawValue)",
            description: refactoring.description,
            frequency: 1,
            confidence: 0.8,
            impact: refactoring.impact == .major ? .high : .medium,
            lastOccurrence: refactoring.timestamp
        )
        
        if let existingIndex = developmentPatterns.firstIndex(where: { $0.name == pattern.name }) {
            developmentPatterns[existingIndex].recordOccurrence()
        } else {
            developmentPatterns.append(pattern)
        }
    }
    
    private mutating func updatePredictedIssues() {
        predictedIssues.removeAll()
        
        // Predict issues based on bug patterns
        for bugPattern in bugPatterns where bugPattern.occurrenceCount > 1 {
            let issue = PredictedIssue(
                type: .bugRecurrence,
                description: "Potential recurrence of: \(bugPattern.description)",
                probability: min(0.8, Double(bugPattern.occurrenceCount) / 5.0),
                severity: bugPattern.severity,
                suggestedAction: "Review and strengthen: \(bugPattern.fix)",
                timeline: estimateIssueTimeline(for: bugPattern)
            )
            predictedIssues.append(issue)
        }
    }
    
    private func estimateIssueTimeline(for bugPattern: BugPattern) -> IssueTimeline {
        let daysSinceLastOccurrence = Date().timeIntervalSince(bugPattern.lastSeen) / 86400
        
        if daysSinceLastOccurrence < 7 {
            return .days(3)
        } else if daysSinceLastOccurrence < 30 {
            return .weeks(2)
        } else {
            return .months(1)
        }
    }
    
    private mutating func generateInsights() {
        learningInsights.removeAll()
        
        // Generate insights from development patterns
        for pattern in developmentPatterns where pattern.frequency > 3 {
            let insight = LearningInsight(
                category: .pattern,
                description: "Frequent pattern detected: \(pattern.name)",
                confidence: pattern.confidence,
                actionable: true,
                recommendation: generatePatternRecommendation(for: pattern)
            )
            learningInsights.append(insight)
        }
        
        // Generate insights from quality trends
        if let latestQuality = qualityTrends.last,
           qualityTrends.count > 3 {
            let previousQuality = qualityTrends[qualityTrends.count - 4]
            let qualityChange = latestQuality.overallQuality - previousQuality.overallQuality
            
            if qualityChange < -0.1 {
                let insight = LearningInsight(
                    category: .quality,
                    description: "Code quality declining over recent versions",
                    confidence: 0.8,
                    actionable: true,
                    recommendation: "Consider implementing code review processes or refactoring"
                )
                learningInsights.append(insight)
            }
        }
    }
    
    private func generatePatternRecommendation(for pattern: DevelopmentPattern) -> String {
        switch pattern.impact {
        case .high:
            return "Consider automating or optimizing this frequent pattern"
        case .medium:
            return "Monitor this pattern for potential optimization opportunities"
        case .low:
            return "Document this pattern for team knowledge sharing"
        }
    }
    
    private func generateExecutiveSummary() -> String {
        let healthText = healthScore > 0.8 ? "excellent" : healthScore > 0.6 ? "good" : "concerning"
        let velocityText = velocityTrend.rawValue
        let maturityText = maturityLevel.rawValue
        
        return "Code evolution shows \(healthText) health (score: \(String(format: "%.2f", healthScore))) with \(velocityText) development velocity. Project maturity level: \(maturityText). \(versionHistory.count) versions tracked with \(bugPatterns.count) bug patterns identified."
    }
    
    private func analyzeVersionHistory() -> VersionHistoryAnalysis {
        let totalVersions = versionHistory.count
        let averageChangeSize = versionHistory.map { $0.changeAnalysis.linesChanged }.reduce(0, +) / max(1, totalVersions)
        let versionTypes = Dictionary(grouping: versionHistory, by: { $0.type })
        
        return VersionHistoryAnalysis(
            totalVersions: totalVersions,
            averageChangeSize: averageChangeSize,
            versionDistribution: versionTypes.mapValues { $0.count },
            developmentTimeline: versionHistory.map { VersionTimelineEntry(version: $0.version, date: $0.timestamp, type: $0.type) }
        )
    }
    
    private func analyzeQualityTrends() -> QualityTrendAnalysis {
        guard !qualityTrends.isEmpty else {
            return QualityTrendAnalysis(overallTrend: .stable, averageQuality: 0.5, qualityVariability: 0.0, improvementRate: 0.0)
        }
        
        let averageQuality = qualityTrends.map { $0.overallQuality }.reduce(0, +) / Double(qualityTrends.count)
        let qualityVariability = calculateVariability(qualityTrends.map { $0.overallQuality })
        let improvementRate = calculateImprovementRate()
        
        let trend: QualityTrendDirection
        if improvementRate > 0.05 {
            trend = .improving
        } else if improvementRate < -0.05 {
            trend = .declining
        } else {
            trend = .stable
        }
        
        return QualityTrendAnalysis(
            overallTrend: trend,
            averageQuality: averageQuality,
            qualityVariability: qualityVariability,
            improvementRate: improvementRate
        )
    }
    
    private func calculateVariability(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        
        return sqrt(variance)
    }
    
    private func calculateImprovementRate() -> Double {
        guard qualityTrends.count > 2 else { return 0.0 }
        
        let recent = qualityTrends.suffix(3).map { $0.overallQuality }
        let older = qualityTrends.prefix(3).map { $0.overallQuality }
        
        let recentAverage = recent.reduce(0, +) / Double(recent.count)
        let olderAverage = older.reduce(0, +) / Double(older.count)
        
        return recentAverage - olderAverage
    }
    
    private func analyzePerformanceEvolution() -> PerformanceEvolutionAnalysis {
        guard !performanceMetrics.isEmpty else {
            return PerformanceEvolutionAnalysis(trend: .stable, averagePerformance: 0.5, performanceVariability: 0.0, bottlenecks: [])
        }
        
        let averagePerformance = performanceMetrics.map { $0.performanceIndex }.reduce(0, +) / Double(performanceMetrics.count)
        let performanceVariability = calculateVariability(performanceMetrics.map { $0.performanceIndex })
        let bottlenecks = identifyPerformanceBottlenecks()
        
        let trend = determinePerformanceTrend()
        
        return PerformanceEvolutionAnalysis(
            trend: trend,
            averagePerformance: averagePerformance,
            performanceVariability: performanceVariability,
            bottlenecks: bottlenecks
        )
    }
    
    private func identifyPerformanceBottlenecks() -> [String] {
        return performanceMetrics
            .filter { $0.performanceIndex < 0.5 }
            .map { "Performance issue at \($0.timestamp.formatted())" }
    }
    
    private func determinePerformanceTrend() -> PerformanceTrend {
        guard performanceMetrics.count > 2 else { return .stable }
        
        let recent = performanceMetrics.suffix(3).map { $0.performanceIndex }.reduce(0, +) / 3.0
        let older = performanceMetrics.prefix(3).map { $0.performanceIndex }.reduce(0, +) / 3.0
        
        if recent > older + 0.1 {
            return .improving
        } else if recent < older - 0.1 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func analyzeDevelopmentPatterns() -> DevelopmentPatternAnalysis {
        let frequentPatterns = developmentPatterns.filter { $0.frequency > 2 }
        let patternsByImpact = Dictionary(grouping: developmentPatterns, by: { $0.impact })
        
        return DevelopmentPatternAnalysis(
            totalPatterns: developmentPatterns.count,
            frequentPatterns: frequentPatterns,
            patternsByImpact: patternsByImpact.mapValues { $0.count },
            recommendations: generatePatternRecommendations()
        )
    }
    
    private func generatePatternRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let highImpactPatterns = developmentPatterns.filter { $0.impact == .high && $0.frequency > 2 }
        for pattern in highImpactPatterns {
            recommendations.append("Optimize high-impact pattern: \(pattern.name)")
        }
        
        return recommendations
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if healthScore < 0.7 {
            recommendations.append("Improve overall code health through refactoring and bug fixes")
        }
        
        if technicalDebtLevel == .high || technicalDebtLevel == .critical {
            recommendations.append("Address technical debt to improve maintainability")
        }
        
        if velocityTrend == .decelerating {
            recommendations.append("Investigate factors causing development velocity decline")
        }
        
        return recommendations
    }
    
    private func generateProjections() -> [String] {
        var projections: [String] = []
        
        // Project based on current trends
        if velocityTrend == .accelerating {
            projections.append("Development velocity likely to continue improving")
        }
        
        if qualityTrends.count > 3 {
            let qualityDirection = calculateImprovementRate() > 0 ? "improve" : "decline"
            projections.append("Code quality projected to \(qualityDirection) based on current trends")
        }
        
        return projections
    }
    
    private func compareVelocity(with other: CodeEvolution) -> String {
        let myVelocity = Double(versionHistory.count) / max(1, Date().timeIntervalSince(creationDate) / 86400)
        let otherVelocity = Double(other.versionHistory.count) / max(1, Date().timeIntervalSince(other.creationDate) / 86400)
        
        if myVelocity > otherVelocity * 1.2 {
            return "Significantly faster development velocity"
        } else if myVelocity < otherVelocity * 0.8 {
            return "Slower development velocity"
        } else {
            return "Similar development velocity"
        }
    }
    
    private func compareQuality(with other: CodeEvolution) -> String {
        let qualityDiff = healthScore - other.healthScore
        
        if qualityDiff > 0.2 {
            return "Significantly higher code quality"
        } else if qualityDiff < -0.2 {
            return "Lower code quality"
        } else {
            return "Similar code quality"
        }
    }
    
    private func compareComplexity(with other: CodeEvolution) -> String {
        let myComplexity = complexityEvolution.currentComplexity
        let otherComplexity = other.complexityEvolution.currentComplexity
        
        if myComplexity < otherComplexity * 0.8 {
            return "Lower complexity"
        } else if myComplexity > otherComplexity * 1.2 {
            return "Higher complexity"
        } else {
            return "Similar complexity"
        }
    }
    
    private func generateComparisonInsights(with other: CodeEvolution) -> [String] {
        var insights: [String] = []
        
        if bugPatterns.count < other.bugPatterns.count {
            insights.append("Fewer bug patterns detected")
        }
        
        if refactoringHistory.count > other.refactoringHistory.count {
            insights.append("More proactive refactoring activity")
        }
        
        return insights
    }
}

// MARK: - Supporting Types

/// Semantic version structure
public struct SemanticVersion: Codable, Hashable, Comparable {
    public let major: Int
    public let minor: Int
    public let patch: Int
    public let prerelease: String?
    public let build: String?
    
    public init(major: Int, minor: Int, patch: Int, prerelease: String? = nil, build: String? = nil) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.prerelease = prerelease
        self.build = build
    }
    
    public var versionString: String {
        var version = "\(major).\(minor).\(patch)"
        if let prerelease = prerelease {
            version += "-\(prerelease)"
        }
        if let build = build {
            version += "+\(build)"
        }
        return version
    }
    
    public static func < (lhs: SemanticVersion, rhs: SemanticVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}

/// Code version with metadata
public struct CodeVersion: Codable, Hashable, Identifiable {
    public let id: UUID
    public let version: SemanticVersion
    public let changes: [CodeChange]
    public let type: VersionType
    public let description: String
    public let author: String
    public let timestamp: Date
    public let metrics: CodeMetrics
    public let changeAnalysis: ChangeAnalysis
    public let developmentTime: TimeInterval
    
    public init(version: SemanticVersion, changes: [CodeChange], type: VersionType, description: String, author: String, timestamp: Date, metrics: CodeMetrics, changeAnalysis: ChangeAnalysis) {
        self.id = UUID()
        self.version = version
        self.changes = changes
        self.type = type
        self.description = description
        self.author = author
        self.timestamp = timestamp
        self.metrics = metrics
        self.changeAnalysis = changeAnalysis
        self.developmentTime = 3600 // Default 1 hour - would be calculated from actual development time
    }
}

/// Individual code change
public struct CodeChange: Codable, Hashable, Identifiable {
    public let id: UUID
    public let filePath: String
    public let type: ChangeType
    public let linesAdded: Int
    public let linesRemoved: Int
    public let description: String
    public let timestamp: Date
    
    public init(filePath: String, type: ChangeType, linesAdded: Int, linesRemoved: Int, description: String) {
        self.id = UUID()
        self.filePath = filePath
        self.type = type
        self.linesAdded = linesAdded
        self.linesRemoved = linesRemoved
        self.description = description
        self.timestamp = Date()
    }
}

/// Code metrics tracking
public struct CodeMetrics: Codable, Hashable {
    public var linesOfCode: Int
    public var complexity: Double
    public var maintainabilityIndex: Double
    public var testCoverage: Double
    public var codeReuse: Double
    public var documentation: Double
    public var overallQuality: Double
    
    public init() {
        self.linesOfCode = 0
        self.complexity = 0.0
        self.maintainabilityIndex = 0.8
        self.testCoverage = 0.0
        self.codeReuse = 0.5
        self.documentation = 0.3
        self.overallQuality = 0.6
    }
    
    public mutating func updateFromVersion(_ version: CodeVersion) {
        // Update metrics based on version changes
        let totalChanges = version.changes.reduce(0) { $0 + $1.linesAdded + $1.linesRemoved }
        linesOfCode += version.changes.reduce(0) { $0 + $1.linesAdded - $1.linesRemoved }
        
        // Recalculate overall quality
        overallQuality = (maintainabilityIndex + testCoverage + codeReuse + documentation) / 4.0
    }
}

/// Quality trend data point
public struct QualityTrend: Codable, Hashable {
    public let timestamp: Date
    public let overallQuality: Double
    public let maintainabilityIndex: Double
    public let testCoverage: Double
    public let codeReuse: Double
    
    public init(timestamp: Date, overallQuality: Double, maintainabilityIndex: Double, testCoverage: Double, codeReuse: Double) {
        self.timestamp = timestamp
        self.overallQuality = overallQuality
        self.maintainabilityIndex = maintainabilityIndex
        self.testCoverage = testCoverage
        self.codeReuse = codeReuse
    }
}

/// Complexity evolution tracking
public struct ComplexityEvolution: Codable, Hashable {
    public var dataPoints: [ComplexityDataPoint]
    public var currentComplexity: Double
    public var isIncreasing: Bool
    
    public init() {
        self.dataPoints = []
        self.currentComplexity = 1.0
        self.isIncreasing = false
    }
    
    public mutating func addDataPoint(timestamp: Date, complexity: Double) {
        let dataPoint = ComplexityDataPoint(timestamp: timestamp, complexity: complexity)
        dataPoints.append(dataPoint)
        
        // Update current complexity and trend
        currentComplexity = complexity
        
        if dataPoints.count > 3 {
            let recent = dataPoints.suffix(3).map { $0.complexity }.reduce(0, +) / 3.0
            let older = dataPoints.prefix(3).map { $0.complexity }.reduce(0, +) / 3.0
            isIncreasing = recent > older
        }
    }
}

/// Complexity data point
public struct ComplexityDataPoint: Codable, Hashable {
    public let timestamp: Date
    public let complexity: Double
    
    public init(timestamp: Date, complexity: Double) {
        self.timestamp = timestamp
        self.complexity = complexity
    }
}

/// Performance snapshot
public struct PerformanceSnapshot: Codable, Hashable {
    public let timestamp: Date
    public let performanceIndex: Double
    public let memoryUsage: Int64
    public let executionTime: TimeInterval
    public let throughput: Double
    
    public init(timestamp: Date, performanceIndex: Double, memoryUsage: Int64, executionTime: TimeInterval, throughput: Double) {
        self.timestamp = timestamp
        self.performanceIndex = performanceIndex
        self.memoryUsage = memoryUsage
        self.executionTime = executionTime
        self.throughput = throughput
    }
}

/// Development pattern
public struct DevelopmentPattern: Codable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public var frequency: Int
    public let confidence: Double
    public let impact: PatternImpact
    public var lastOccurrence: Date
    
    public init(name: String, description: String, frequency: Int, confidence: Double, impact: PatternImpact, lastOccurrence: Date) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.frequency = frequency
        self.confidence = confidence
        self.impact = impact
        self.lastOccurrence = lastOccurrence
    }
    
    public func isSimilar(to other: DevelopmentPattern) -> Bool {
        return name.lowercased().contains(other.name.lowercased()) ||
               other.name.lowercased().contains(name.lowercased())
    }
    
    public mutating func recordOccurrence() {
        frequency += 1
        lastOccurrence = Date()
    }
}

/// Refactoring event
public struct RefactoringEvent: Codable, Hashable, Identifiable {
    public let id: UUID
    public let description: String
    public let files: [String]
    public let reason: RefactoringReason
    public let impact: RefactoringImpact
    public let timestamp: Date
    public let beforeMetrics: CodeMetrics
    public var afterMetrics: CodeMetrics?
    
    public init(description: String, files: [String], reason: RefactoringReason, impact: RefactoringImpact, timestamp: Date, beforeMetrics: CodeMetrics, afterMetrics: CodeMetrics?) {
        self.id = UUID()
        self.description = description
        self.files = files
        self.reason = reason
        self.impact = impact
        self.timestamp = timestamp
        self.beforeMetrics = beforeMetrics
        self.afterMetrics = afterMetrics
    }
}

/// Bug pattern tracking
public struct BugPattern: Codable, Hashable, Identifiable {
    public let id: UUID
    public let description: String
    public let category: BugCategory
    public let severity: BugSeverity
    public let rootCause: String
    public let fix: String
    public var occurrenceCount: Int
    public let firstSeen: Date
    public var lastSeen: Date
    
    public init(description: String, category: BugCategory, severity: BugSeverity, rootCause: String, fix: String, occurrenceCount: Int, firstSeen: Date, lastSeen: Date) {
        self.id = UUID()
        self.description = description
        self.category = category
        self.severity = severity
        self.rootCause = rootCause
        self.fix = fix
        self.occurrenceCount = occurrenceCount
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
    }
    
    public func isSimilar(to other: BugPattern) -> Bool {
        return category == other.category &&
               (description.lowercased().contains(other.description.lowercased()) ||
                rootCause.lowercased().contains(other.rootCause.lowercased()))
    }
    
    public mutating func recordOccurrence() {
        occurrenceCount += 1
        lastSeen = Date()
    }
}

/// Contributor information
public struct Contributor: Codable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let role: ContributorRole
    public let expertise: [String]
    public let joinDate: Date
    public var contributions: Int
    public var lastActivity: Date
    
    public init(id: UUID, name: String, role: ContributorRole, expertise: [String], joinDate: Date, contributions: Int, lastActivity: Date) {
        self.id = id
        self.name = name
        self.role = role
        self.expertise = expertise
        self.joinDate = joinDate
        self.contributions = contributions
        self.lastActivity = lastActivity
    }
}

/// Code review tracking
public struct CodeReview: Codable, Hashable, Identifiable {
    public let id: UUID
    public let reviewerId: UUID
    public let versionId: UUID
    public let rating: ReviewRating
    public let comments: [ReviewComment]
    public let timestamp: Date
    public let approved: Bool
    
    public init(reviewerId: UUID, versionId: UUID, rating: ReviewRating, comments: [ReviewComment], timestamp: Date, approved: Bool) {
        self.id = UUID()
        self.reviewerId = reviewerId
        self.versionId = versionId
        self.rating = rating
        self.comments = comments
        self.timestamp = timestamp
        self.approved = approved
    }
}

/// Review comment
public struct ReviewComment: Codable, Hashable, Identifiable {
    public let id: UUID
    public let text: String
    public let type: CommentType
    public let severity: CommentSeverity
    public let lineNumber: Int?
    public let fileName: String?
    
    public init(text: String, type: CommentType, severity: CommentSeverity, lineNumber: Int? = nil, fileName: String? = nil) {
        self.id = UUID()
        self.text = text
        self.type = type
        self.severity = severity
        self.lineNumber = lineNumber
        self.fileName = fileName
    }
}

/// Knowledge transfer event
public struct KnowledgeTransferEvent: Codable, Hashable, Identifiable {
    public let id: UUID
    public let fromContributor: UUID
    public let toContributor: UUID
    public let topic: String
    public let method: TransferMethod
    public let effectiveness: Double
    public let timestamp: Date
    
    public init(fromContributor: UUID, toContributor: UUID, topic: String, method: TransferMethod, effectiveness: Double, timestamp: Date) {
        self.id = UUID()
        self.fromContributor = fromContributor
        self.toContributor = toContributor
        self.topic = topic
        self.method = method
        self.effectiveness = effectiveness
        self.timestamp = timestamp
    }
}

/// Predicted issue
public struct PredictedIssue: Codable, Hashable, Identifiable {
    public let id: UUID
    public let type: IssueType
    public let description: String
    public let probability: Double
    public let severity: BugSeverity
    public let suggestedAction: String
    public let timeline: IssueTimeline
    
    public init(type: IssueType, description: String, probability: Double, severity: BugSeverity, suggestedAction: String, timeline: IssueTimeline) {
        self.id = UUID()
        self.type = type
        self.description = description
        self.probability = probability
        self.severity = severity
        self.suggestedAction = suggestedAction
        self.timeline = timeline
    }
}

/// Optimization opportunity
public struct OptimizationOpportunity: Codable, Hashable, Identifiable {
    public let id: UUID
    public let area: OptimizationArea
    public let description: String
    public let potentialImpact: Double
    public let difficulty: OptimizationDifficulty
    public let estimatedEffort: TimeInterval
    
    public init(area: OptimizationArea, description: String, potentialImpact: Double, difficulty: OptimizationDifficulty, estimatedEffort: TimeInterval) {
        self.id = UUID()
        self.area = area
        self.description = description
        self.potentialImpact = potentialImpact
        self.difficulty = difficulty
        self.estimatedEffort = estimatedEffort
    }
}

/// Learning insight
public struct LearningInsight: Codable, Hashable, Identifiable {
    public let id: UUID
    public let category: InsightCategory
    public let description: String
    public let confidence: Double
    public let actionable: Bool
    public let recommendation: String
    
    public init(category: InsightCategory, description: String, confidence: Double, actionable: Bool, recommendation: String) {
        self.id = UUID()
        self.category = category
        self.description = description
        self.confidence = confidence
        self.actionable = actionable
        self.recommendation = recommendation
    }
}

/// Evolution milestone
public struct EvolutionMilestone: Codable, Hashable, Identifiable {
    public let id: UUID
    public let name: String
    public let description: String
    public let achievedDate: Date
    public let significance: MilestoneSignificance
    public let metrics: [String: Double]
    
    public init(name: String, description: String, achievedDate: Date, significance: MilestoneSignificance, metrics: [String: Double]) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.achievedDate = achievedDate
        self.significance = significance
        self.metrics = metrics
    }
}

/// Change analysis result
public struct ChangeAnalysis: Codable, Hashable {
    public let totalChanges: Int
    public let linesChanged: Int
    public let filesAffected: Int
    public let changeTypes: [ChangeType]
    public let complexity: Double
    public let riskLevel: RiskLevel
    
    public init(totalChanges: Int, linesChanged: Int, filesAffected: Int, changeTypes: [ChangeType], complexity: Double, riskLevel: RiskLevel) {
        self.totalChanges = totalChanges
        self.linesChanged = linesChanged
        self.filesAffected = filesAffected
        self.changeTypes = changeTypes
        self.complexity = complexity
        self.riskLevel = riskLevel
    }
}

/// Future issue prediction
public struct FutureIssue: Codable, Hashable, Identifiable {
    public let id: UUID
    public let type: IssueType
    public let probability: Double
    public let description: String
    public let timeline: IssueTimeline
    public let severity: BugSeverity
    public let preventionStrategy: String
    
    public init(type: IssueType, probability: Double, description: String, timeline: IssueTimeline, severity: BugSeverity, preventionStrategy: String) {
        self.id = UUID()
        self.type = type
        self.probability = probability
        self.description = description
        self.timeline = timeline
        self.severity = severity
        self.preventionStrategy = preventionStrategy
    }
}

// MARK: - Enums

/// Version types for semantic versioning
public enum VersionType: String, Codable, CaseIterable, Hashable {
    case major = "major"
    case minor = "minor"
    case patch = "patch"
    case prerelease = "prerelease"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Code change types
public enum ChangeType: String, Codable, CaseIterable, Hashable {
    case feature = "feature"
    case bugfix = "bugfix"
    case refactor = "refactor"
    case documentation = "documentation"
    case test = "test"
    case performance = "performance"
    case security = "security"
    case architecture = "architecture"
    case style = "style"
    
    public var displayName: String {
        switch self {
        case .bugfix: return "Bug Fix"
        default: return rawValue.capitalized
        }
    }
}

/// Branching strategies
public enum BranchingStrategy: String, Codable, CaseIterable, Hashable {
    case feature = "feature"
    case gitflow = "gitflow"
    case github = "github"
    case trunk = "trunk"
    
    public var displayName: String {
        switch self {
        case .feature: return "Feature Branch"
        case .gitflow: return "Git Flow"
        case .github: return "GitHub Flow"
        case .trunk: return "Trunk-based"
        }
    }
}

/// Versioning schemes
public enum VersioningScheme: String, Codable, CaseIterable, Hashable {
    case semantic = "semantic"
    case calendar = "calendar"
    case sequential = "sequential"
    case custom = "custom"
    
    public var displayName: String {
        switch self {
        case .semantic: return "Semantic Versioning"
        case .calendar: return "Calendar Versioning"
        case .sequential: return "Sequential Versioning"
        case .custom: return "Custom Scheme"
        }
    }
}

/// Velocity trends
public enum VelocityTrend: String, Codable, CaseIterable, Hashable {
    case accelerating = "accelerating"
    case stable = "stable"
    case decelerating = "decelerating"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Technical debt levels
public enum TechnicalDebtLevel: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case moderate = "moderate"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        return rawValue.capitalized
    }
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .moderate: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

/// Maturity levels
public enum MaturityLevel: String, Codable, CaseIterable, Hashable {
    case experimental = "experimental"
    case developing = "developing"
    case stable = "stable"
    case mature = "mature"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Pattern impact levels
public enum PatternImpact: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Refactoring reasons
public enum RefactoringReason: String, Codable, CaseIterable, Hashable {
    case complexity = "complexity"
    case performance = "performance"
    case maintainability = "maintainability"
    case readability = "readability"
    case testing = "testing"
    case architecture = "architecture"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Refactoring impact levels
public enum RefactoringImpact: String, Codable, CaseIterable, Hashable {
    case minor = "minor"
    case moderate = "moderate"
    case major = "major"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Bug categories
public enum BugCategory: String, Codable, CaseIterable, Hashable {
    case logic = "logic"
    case syntax = "syntax"
    case runtime = "runtime"
    case performance = "performance"
    case security = "security"
    case ui = "ui"
    case integration = "integration"
    case data = "data"
    
    public var displayName: String {
        switch self {
        case .ui: return "UI/UX"
        default: return rawValue.capitalized
        }
    }
}

/// Bug severity levels
public enum BugSeverity: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        return rawValue.capitalized
    }
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "yellow"
        case .high: return "orange"
        case .critical: return "red"
        }
    }
}

/// Contributor roles
public enum ContributorRole: String, Codable, CaseIterable, Hashable {
    case developer = "developer"
    case architect = "architect"
    case tester = "tester"
    case reviewer = "reviewer"
    case maintainer = "maintainer"
    case lead = "lead"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Review ratings
public enum ReviewRating: String, Codable, CaseIterable, Hashable {
    case excellent = "excellent"
    case good = "good"
    case satisfactory = "satisfactory"
    case needsWork = "needsWork"
    case poor = "poor"
    
    public var displayName: String {
        switch self {
        case .needsWork: return "Needs Work"
        default: return rawValue.capitalized
        }
    }
}

/// Review comment types
public enum CommentType: String, Codable, CaseIterable, Hashable {
    case suggestion = "suggestion"
    case issue = "issue"
    case praise = "praise"
    case question = "question"
    case nitpick = "nitpick"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Comment severity levels
public enum CommentSeverity: String, Codable, CaseIterable, Hashable {
    case minor = "minor"
    case moderate = "moderate"
    case major = "major"
    case blocking = "blocking"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Knowledge transfer methods
public enum TransferMethod: String, Codable, CaseIterable, Hashable {
    case documentation = "documentation"
    case pairing = "pairing"
    case review = "review"
    case mentoring = "mentoring"
    case presentation = "presentation"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Issue types for prediction
public enum IssueType: String, Codable, CaseIterable, Hashable {
    case bugRecurrence = "bugRecurrence"
    case complexityOverload = "complexityOverload"
    case performanceDegradation = "performanceDegradation"
    case securityVulnerability = "securityVulnerability"
    case maintainabilityIssue = "maintainabilityIssue"
    
    public var displayName: String {
        switch self {
        case .bugRecurrence: return "Bug Recurrence"
        case .complexityOverload: return "Complexity Overload"
        case .performanceDegradation: return "Performance Degradation"
        case .securityVulnerability: return "Security Vulnerability"
        case .maintainabilityIssue: return "Maintainability Issue"
        }
    }
}

/// Issue timeline predictions
public enum IssueTimeline: Codable, Hashable {
    case days(Int)
    case weeks(Int)
    case months(Int)
    
    public var displayName: String {
        switch self {
        case .days(let count): return "\(count) day\(count == 1 ? "" : "s")"
        case .weeks(let count): return "\(count) week\(count == 1 ? "" : "s")"
        case .months(let count): return "\(count) month\(count == 1 ? "" : "s")"
        }
    }
}

/// Optimization areas
public enum OptimizationArea: String, Codable, CaseIterable, Hashable {
    case performance = "performance"
    case memory = "memory"
    case complexity = "complexity"
    case maintainability = "maintainability"
    case testability = "testability"
    case security = "security"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Optimization difficulty levels
public enum OptimizationDifficulty: String, Codable, CaseIterable, Hashable {
    case easy = "easy"
    case moderate = "moderate"
    case difficult = "difficult"
    case complex = "complex"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Insight categories
public enum InsightCategory: String, Codable, CaseIterable, Hashable {
    case pattern = "pattern"
    case quality = "quality"
    case performance = "performance"
    case security = "security"
    case team = "team"
    case process = "process"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Milestone significance levels
public enum MilestoneSignificance: String, Codable, CaseIterable, Hashable {
    case minor = "minor"
    case major = "major"
    case critical = "critical"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Risk levels
public enum RiskLevel: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        return rawValue.capitalized
    }
    
    public var color: String {
        switch self {
        case .low: return "green"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Analysis Types

/// Evolution insight
public struct EvolutionInsight: Codable, Hashable, Identifiable {
    public let id: UUID
    public let type: InsightType
    public let priority: InsightPriority
    public let description: String
    public let recommendation: String
    public let impact: InsightImpact
    
    public init(type: InsightType, priority: InsightPriority, description: String, recommendation: String, impact: InsightImpact) {
        self.id = UUID()
        self.type = type
        self.priority = priority
        self.description = description
        self.recommendation = recommendation
        self.impact = impact
    }
}

/// Insight types
public enum InsightType: String, Codable, CaseIterable, Hashable {
    case healthConcern = "healthConcern"
    case velocityDecline = "velocityDecline"
    case technicalDebt = "technicalDebt"
    case qualityImprovement = "qualityImprovement"
    case performanceOpportunity = "performanceOpportunity"
    
    public var displayName: String {
        switch self {
        case .healthConcern: return "Health Concern"
        case .velocityDecline: return "Velocity Decline"
        case .technicalDebt: return "Technical Debt"
        case .qualityImprovement: return "Quality Improvement"
        case .performanceOpportunity: return "Performance Opportunity"
        }
    }
}

/// Insight priorities
public enum InsightPriority: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Insight impact areas
public enum InsightImpact: String, Codable, CaseIterable, Hashable {
    case quality = "quality"
    case productivity = "productivity"
    case maintainability = "maintainability"
    case performance = "performance"
    case security = "security"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Report Types

/// Comprehensive evolution report
public struct EvolutionReport: Codable, Hashable {
    public let codeEvolution: CodeEvolution
    public let executiveSummary: String
    public let versionAnalysis: VersionHistoryAnalysis
    public let qualityAnalysis: QualityTrendAnalysis
    public let performanceAnalysis: PerformanceEvolutionAnalysis
    public let patternAnalysis: DevelopmentPatternAnalysis
    public let recommendations: [String]
    public let futureProjections: [String]
    
    public init(codeEvolution: CodeEvolution, executiveSummary: String, versionAnalysis: VersionHistoryAnalysis, qualityAnalysis: QualityTrendAnalysis, performanceAnalysis: PerformanceEvolutionAnalysis, patternAnalysis: DevelopmentPatternAnalysis, recommendations: [String], futureProjections: [String]) {
        self.codeEvolution = codeEvolution
        self.executiveSummary = executiveSummary
        self.versionAnalysis = versionAnalysis
        self.qualityAnalysis = qualityAnalysis
        self.performanceAnalysis = performanceAnalysis
        self.patternAnalysis = patternAnalysis
        self.recommendations = recommendations
        self.futureProjections = futureProjections
    }
}

/// Version history analysis
public struct VersionHistoryAnalysis: Codable, Hashable {
    public let totalVersions: Int
    public let averageChangeSize: Int
    public let versionDistribution: [VersionType: Int]
    public let developmentTimeline: [VersionTimelineEntry]
    
    public init(totalVersions: Int, averageChangeSize: Int, versionDistribution: [VersionType: Int], developmentTimeline: [VersionTimelineEntry]) {
        self.totalVersions = totalVersions
        self.averageChangeSize = averageChangeSize
        self.versionDistribution = versionDistribution
        self.developmentTimeline = developmentTimeline
    }
}

/// Version timeline entry
public struct VersionTimelineEntry: Codable, Hashable {
    public let version: SemanticVersion
    public let date: Date
    public let type: VersionType
    
    public init(version: SemanticVersion, date: Date, type: VersionType) {
        self.version = version
        self.date = date
        self.type = type
    }
}

/// Quality trend analysis
public struct QualityTrendAnalysis: Codable, Hashable {
    public let overallTrend: QualityTrendDirection
    public let averageQuality: Double
    public let qualityVariability: Double
    public let improvementRate: Double
    
    public init(overallTrend: QualityTrendDirection, averageQuality: Double, qualityVariability: Double, improvementRate: Double) {
        self.overallTrend = overallTrend
        self.averageQuality = averageQuality
        self.qualityVariability = qualityVariability
        self.improvementRate = improvementRate
    }
}

/// Quality trend directions
public enum QualityTrendDirection: String, Codable, CaseIterable, Hashable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Performance evolution analysis
public struct PerformanceEvolutionAnalysis: Codable, Hashable {
    public let trend: PerformanceTrend
    public let averagePerformance: Double
    public let performanceVariability: Double
    public let bottlenecks: [String]
    
    public init(trend: PerformanceTrend, averagePerformance: Double, performanceVariability: Double, bottlenecks: [String]) {
        self.trend = trend
        self.averagePerformance = averagePerformance
        self.performanceVariability = performanceVariability
        self.bottlenecks = bottlenecks
    }
}

/// Performance trends
public enum PerformanceTrend: String, Codable, CaseIterable, Hashable {
    case improving = "improving"
    case stable = "stable"
    case declining = "declining"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Development pattern analysis
public struct DevelopmentPatternAnalysis: Codable, Hashable {
    public let totalPatterns: Int
    public let frequentPatterns: [DevelopmentPattern]
    public let patternsByImpact: [PatternImpact: Int]
    public let recommendations: [String]
    
    public init(totalPatterns: Int, frequentPatterns: [DevelopmentPattern], patternsByImpact: [PatternImpact: Int], recommendations: [String]) {
        self.totalPatterns = totalPatterns
        self.frequentPatterns = frequentPatterns
        self.patternsByImpact = patternsByImpact
        self.recommendations = recommendations
    }
}

/// Evolution comparison
public struct EvolutionComparison: Codable, Hashable {
    public let baseline: CodeEvolution
    public let comparison: CodeEvolution
    public let healthScoreDifference: Double
    public let velocityComparison: String
    public let qualityComparison: String
    public let complexityComparison: String
    public let insights: [String]
    
    public init(baseline: CodeEvolution, comparison: CodeEvolution, healthScoreDifference: Double, velocityComparison: String, qualityComparison: String, complexityComparison: String, insights: [String]) {
        self.baseline = baseline
        self.comparison = comparison
        self.healthScoreDifference = healthScoreDifference
        self.velocityComparison = velocityComparison
        self.qualityComparison = qualityComparison
        self.complexityComparison = complexityComparison
        self.insights = insights
    }
}//
// CodeEvolution.swift
// Arcana
//
// Revolutionary code evolution tracking with semantic versioning and pattern learning
// Tracks code changes, improvements, and learning patterns across development sessions
//

import Foundation

// MARK: - Code Evolution

/// Revolutionary code evolution tracking system that learns from development patterns
/// Provides intelligent version management, change analysis, and improvement suggestions
public struct CodeEvolution: Codable, Hashable, Identifiable {
    
    // MARK: - Properties
    
    public let id: UUID
    public let projectId: UUID
    public let threadId: UUID
    public let creationDate: Date
    public var lastModified: Date
    
    // Version information
    public var currentVersion: SemanticVersion
    public var versionHistory: [CodeVersion]
    public var branchingStrategy: BranchingStrategy
    public var versioningScheme: VersioningScheme
    
    // Code analysis
    public var codeMetrics: CodeMetrics
    public var qualityTrends: [QualityTrend]
    public var complexityEvolution: ComplexityEvolution
    public var performanceMetrics: [PerformanceSnapshot]
    
    // Pattern learning
    public var developmentPatterns: [DevelopmentPattern]
    public var refactoringHistory: [RefactoringEvent]
    public var bugPatterns: [BugPattern]
    public var improvementSuggestions: [ImprovementSuggestion]
    
    // Collaboration tracking
    public var contributors: [Contributor]
    public var codeReviews: [CodeReview]
    public var knowledgeTransfer: [KnowledgeTransferEvent]
    
    // Intelligence features
    public var predictedIssues: [PredictedIssue]
    public var optimizationOpportunities: [OptimizationOpportunity]
    public var learningInsights: [LearningInsight]
    public var evolutionMilestones: [EvolutionMilestone]
    
    // MARK: - Initialization
    
    public init(projectId: UUID, threadId: UUID) {
        self.id = UUID()
        self.projectId = projectId
        self.threadId = threadId
        self.creationDate = Date()
        self.lastModified = Date()
        
        self.currentVersion = SemanticVersion(major: 0, minor: 1, patch: 0)
        self.versionHistory = []
        self.branchingStrategy = .feature
        self.versioningScheme = .semantic
        
        self.codeMetrics = CodeMetrics()
        self.qualityTrends = []
        self.complexityEvolution = ComplexityEvolution()
        self.performanceMetrics = []
        
        self.developmentPatterns = []
        self.refactoringHistory = []
        self.bugPatterns = []
        self.improvementSuggestions = []
        
        self.contributors = []
        self.codeReviews = []
        self.knowledgeTransfer = []
        
        self.predictedIssues = []
        self.optimizationOpportunities = []
        self.learningInsights = []
        self.evolutionMilestones = []
    }
    
    // MARK: - Computed Properties
    
    /// Overall code health score (0.0 - 1.0)
    public var healthScore: Double {
        let qualityScore = codeMetrics.overallQuality
        let complexityScore = 1.0 - min(1.0, complexityEvolution.currentComplexity / 10.0)
        let bugScore = bugPatterns.isEmpty ? 1.0 : max(0.3, 1.0 - Double(bugPatterns.count) / 10.0)
        let performanceScore = performanceMetrics.last?.performanceIndex ?? 0.8
        
        return (qualityScore * 0.3 + complexityScore * 0.25 + bugScore * 0.25 + performanceScore * 0.2)
    }
    
    /// Development velocity trend
    public var velocityTrend: VelocityTrend {
        guard versionHistory.count >= 3 else { return .stable }
        
        let recentVersions = versionHistory.suffix(3)
        let intervals = recentVersions.map { $0.developmentTime }
        
        let averageRecent = intervals.suffix(2).reduce(0, +) / 2.0
        let averageOlder = intervals.prefix(1).first ?? averageRecent
        
        if averageRecent < averageOlder * 0.8 {
            return .accelerating
        } else if averageRecent > averageOlder * 1.2 {
            return .decelerating
        } else {
            return .stable
        }
    }
    
    /// Technical debt level
    public var technicalDebtLevel: TechnicalDebtLevel {
        let complexityFactor = complexityEvolution.currentComplexity / 10.0
        let bugFactor = Double(bugPatterns.count) / 5.0
        let refactoringNeed = refactoringHistory.isEmpty ? 1.0 : 0.5
        
        let debtScore = (complexityFactor + bugFactor + refactoringNeed) / 3.0
        
        switch debtScore {
        case 0.0..<0.3: return .low
        case 0.3..<0.6: return .moderate
        case 0.6..<0.8: return .high
        default: return .critical
        }
    }
    
    /// Evolution maturity level
    public var maturityLevel: MaturityLevel {
        let versionCount = versionHistory.count
        let ageInDays = Date().timeIntervalSince(creationDate) / 86400
        let stabilityScore = healthScore
        
        if versionCount >= 20 && ageInDays >= 90 && stabilityScore > 0.8 {
            return .mature
        } else if versionCount >= 10 && ageInDays >= 30 && stabilityScore > 0.7 {
            return .stable
        } else if versionCount >= 5 && ageInDays >= 7 && stabilityScore > 0.6 {
            return .developing
        } else {
            return .experimental
        }
    }
    
    // MARK: - Version Management
    
    /// Create a new version with changes
    public mutating func createVersion(
        changes: [CodeChange],
        type: VersionType,
        description: String,
        author: String
    ) -> CodeVersion {
        
        // Update semantic version based on type
        updateSemanticVersion(for: type)
        
        // Analyze changes
        let changeAnalysis = analyzeChanges(changes)
        
        // Create new version
        let newVersion = CodeVersion(
            version: currentVersion,
            changes: changes,
            type: type,
            description: description,
            author: author,
            timestamp: Date(),
            metrics: codeMetrics,
            changeAnalysis: changeAnalysis
        )
        
        // Add to history
        versionHistory.append(newVersion)
        
        // Update tracking data
        updateMetricsFromVersion(newVersion)
        updatePatterns(from: changes)
        generateInsights()
        
        lastModified = Date()
        
        return newVersion
    }
    
    /// Track refactoring event
    public mutating func trackRefactoring(
        description: String,
        files: [String],
        reason: RefactoringReason,
        impact: RefactoringImpact
    ) {
        let refactoringEvent = RefactoringEvent(
            description: description,
            files: files,
            reason: reason,
            impact: impact,
            timestamp: Date(),
            beforeMetrics: codeMetrics,
            afterMetrics: nil // Will be updated when next version is created
        )
        
        refactoringHistory.append(refactoringEvent)
        
        // Learn from refactoring patterns
        learnFromRefactoring(refactoringEvent)
        
        lastModified = Date()
    }
    
    /// Track bug pattern
    public mutating func trackBugPattern(
        description: String,
        category: BugCategory,
        severity: BugSeverity,
        rootCause: String,
        fix: String
    ) {
        let bugPattern = BugPattern(
            description: description,
            category: category,
            severity: severity,
            rootCause: rootCause,
            fix: fix,
            occurrenceCount: 1,
            firstSeen: Date(),
            lastSeen: Date()
        )
        
        // Check if similar pattern exists
        if let existingIndex = bugPatterns.firstIndex(where: { $0.isSimilar(to: bugPattern) }) {
            bugPatterns[existingIndex].recordOccurrence()
        } else {
            bugPatterns.append(bugPattern)
        }
        
        // Generate predictions based on patterns
        updatePredictedIssues()
        
        lastModified = Date()
    }
    
    /// Add contributor
    public mutating func addContributor(
        name: String,
        role: ContributorRole,
        expertise: [String],
        joinDate: Date = Date()
    ) {
        let contributor = Contributor(
            id: UUID(),
            name: name,
            role: role,
            expertise: expertise,
            joinDate: joinDate,
            contributions: 0,
            lastActivity: Date()
        )
        
        contributors.append(contributor)
        lastModified = Date()
    }
    
    // MARK: - Analysis Methods
    
    /// Generate comprehensive evolution report
    public func generateEvolutionReport() -> EvolutionReport {
        return EvolutionReport(
            codeEvolution: self,
            executiveSummary: generateExecutiveSummary(),
            versionAnalysis: analyzeVersionHistory(),
            qualityAnalysis: analyzeQualityTrends(),
            performanceAnalysis: analyzePerformanceEvolution(),
            patternAnalysis: analyzeDevelopmentPatterns(),
            recommendations: generateRecommendations(),
            futureProjections: generateProjections()
        )
    }
    
    /// Compare with another evolution timeline
    public func compare(with other: CodeEvolution) -> EvolutionComparison {
        return EvolutionComparison(
            baseline: self,
            comparison: other,
            healthScoreDifference: healthScore - other.healthScore,
            velocityComparison: compareVelocity(with: other),
            qualityComparison: compareQuality(with: other),
            complexityComparison: compareComplexity(with: other),
            insights: generateComparisonInsights(with: other)
        )
    }
    
    /// Get evolution insights for improvement
    public func getEvolutionInsights() -> [EvolutionInsight] {
        var insights: [EvolutionInsight] = []
        
        // Health insights
        if healthScore < 0.7 {
            insights.append(EvolutionInsight(
                type: .healthConcern,
                priority: .high,
                description: "Code health score is below recommended threshold",
                recommendation: "Focus on code quality improvements and bug fixes",
                impact: .quality
            ))
        }
        
        // Velocity insights
        if velocityTrend == .decelerating {
            insights.append(EvolutionInsight(
                type: .velocityDecline,
                priority: .medium,
                description: "Development velocity is decreasing",
                recommendation: "Consider process improvements or additional resources",
                impact: .productivity
            ))
        }
        
        // Technical debt insights
        if technicalDebtLevel == .high || technicalDebtLevel == .critical {
            insights.append(EvolutionInsight(
                type: .technicalDebt,
                priority: .high,
                description: "Technical debt level is concerning",
                recommendation: "Prioritize refactoring and code cleanup",
                impact: .maintainability
            ))
        }
        
        return insights
    }
    
    /// Predict future issues based on patterns
    public func predictFutureIssues() -> [FutureIssue] {
        var predictions: [FutureIssue] = []
        
        // Analyze bug patterns for predictions
        for bugPattern in bugPatterns where bugPattern.occurrenceCount > 2 {
            let probability = min(0.8, Double(bugPattern.occurrenceCount) / 10.0)
            predictions.append(FutureIssue(
                type: .bugRecurrence,
                probability: probability,
                description: "Similar to: \(bugPattern.description)",
                timeline: .weeks(2),
                severity: bugPattern.severity,
                preventionStrategy: bugPattern.fix
            ))
        }
        
        // Analyze complexity trends
        if complexityEvolution.isIncreasing {
            predictions.append(FutureIssue(
                type: .complexityOverload,
                probability: 0.6,
                description: "Code complexity is trending upward",
                timeline: .months(1),
                severity: .medium,
                preventionStrategy: "Implement regular refactoring cycles"
            ))
        }
        
        return predictions
    }
    
    // MARK: - Private Methods
    
    private mutating func updateSemanticVersion(for type: VersionType) {
        switch type {
        case .major:
            currentVersion = SemanticVersion(
                major: currentVersion.major + 1,
                minor: 0,
                patch: 0
            )
        case .minor:
            currentVersion = SemanticVersion(
                major: currentVersion.major,
                minor: currentVersion.minor + 1,
                patch: 0
            )
        case .patch:
            currentVersion = SemanticVersion(
                major: currentVersion.major,
                minor: currentVersion.minor,
                patch: currentVersion.patch + 1
            )
        case .prerelease:
            // Handle prerelease versioning
            break
        }
    }
    
    private func analyzeChanges(_ changes: [CodeChange]) -> ChangeAnalysis {
        let totalLines = changes.reduce(0) { $0 + $1.linesAdded + $1.linesRemoved }
        let filesChanged = Set(changes.map { $0.filePath }).count
        let changeTypes = Set(changes.map { $0.type })
        
        return ChangeAnalysis(
            totalChanges: changes.count,
            linesChanged: totalLines,
            filesAffected: filesChanged,
            changeTypes: Array(changeTypes),
            complexity: calculateChangeComplexity(changes),
            riskLevel: assessChangeRisk(changes)
        )
    }
    
    private func calculateChangeComplexity(_ changes: [CodeChange]) -> Double {
        let complexityScore = changes.reduce(0.0) { total, change in
            var score = 0.0
            score += Double(change.linesAdded + change.linesRemoved) * 0.1
            score += change.type == .architecture ? 2.0 : 1.0
            score += change.filePath.contains("core") ? 1.5 : 1.0
            return total + score
        }
        
        return min(10.0, complexityScore / Double(changes.count))
    }
    
    private func assessChangeRisk(_ changes: [CodeChange]) -> RiskLevel {
        let architecturalChanges = changes.filter { $0.type == .architecture }.count
        let coreFileChanges = changes.filter { $0.filePath.contains("core") }.count
        let totalLines = changes.reduce(0) { $0 + $1.linesAdded + $1.linesRemoved }
        
        if architecturalChanges > 0 || coreFileChanges > 5 || totalLines > 1000 {
            return .high
        } else if coreFileChanges > 2 || totalLines > 500 {
            return .medium
        } else {
            return .low
        }
    }
    
    private mutating func updateMetricsFromVersion(_ version: CodeVersion) {
        // Update overall metrics based on version changes
        codeMetrics.updateFromVersion(version)
        
        // Add quality trend point
        let qualityTrend = QualityTrend(
            timestamp: version.timestamp,
            overallQuality: codeMetrics.overallQuality,
            maintainabilityIndex: codeMetrics.maintainabilityIndex,
            testCoverage: codeMetrics.testCoverage,
            codeReuse: codeMetrics.codeReuse
        )
        
        qualityTrends.append(qualityTrend)
        
        // Update complexity evolution
        complexityEvolution.addDataPoint(
            timestamp: version.timestamp,
            complexity: calculateComplexityFromChanges(version.changes)
        )
    }
    
    private func calculateComplexityFromChanges(_ changes: [CodeChange]) -> Double {
        return changes.reduce(0.0) { total, change in
            total + calculateChangeComplexity([change])
        }
    }
    
    private mutating func updatePatterns(from changes: [CodeChange]) {
        // Extract development patterns from changes
        let changePatterns = extractPatternsFromChanges(changes)
        
        for pattern in changePatterns {
            if let existingIndex = developmentPatterns.firstIndex(where: { $0.isSimilar(to: pattern) }) {
                developmentPatterns[existingIndex].recordOccurrence()
            } else {
                developmentPatterns.append(pattern)
            }
        }
    }
    
    private func extractPatternsFromChanges(_ changes: [CodeChange]) -> [DevelopmentPattern] {
        var patterns: [DevelopmentPattern] = []
        
        // Group changes by type and analyze patterns
        let changesByType = Dictionary(grouping: changes, by: { $0.type })
        
        for (type, typeChanges) in changesByType {
            if typeChanges.count > 1 {
                let pattern = DevelopmentPattern(
                    name: "Bulk \(type.rawValue) changes",
                    description: "Multiple \(type.rawValue) changes in single version",
                    frequency: 1,
                    confidence: 0.7,
                    impact: .medium,
                    lastOccurrence: Date()
                )
                patterns.append(pattern)
            }
        }
        
        return patterns
    }
    
    private mutating func learnFromRefactoring(_ refactoring: RefactoringEvent) {
        // Learn patterns from refactoring events
        let pattern = DevelopmentPattern(
            name: "Refactoring: \(refactoring.reason.rawValue)",
            description: refactoring.description,
            frequency: 1,
            confidence: 0.8,
            impact: refactoring.impact == .major ? .high : .medium,
            lastOccurrence: refactoring.timestamp
        )
        
        if let existingIndex = developmentPatterns.firstIndex(where: { $0.name == pattern.name }) {
            developmentPatterns[existingIndex].recordOccurrence()
        } else {
            developmentPatterns.append(pattern)
        }
    }
    
    private mutating func updatePredictedIssues() {
        predictedIssues.removeAll()
        
        // Predict issues based on bug patterns
        for bugPattern in bugPatterns where bugPattern.occurrenceCount > 1 {
            let issue = PredictedIssue(
                type: .bugRecurrence,
                description: "Potential recurrence of: \(bugPattern.description)",
                probability: min(0.8, Double(bugPattern.occurrenceCount) / 5.0),
                severity: bugPattern.severity,
                suggestedAction: "Review and strengthen: \(bugPattern.fix)",
                timeline: estimateIssueTimeline(for: bugPattern)
            )
            predictedIssues.append(issue)
        }
    }
    
    private func estimateIssueTimeline(for bugPattern: BugPattern) -> IssueTimeline {
        let daysSinceLastOccurrence = Date().timeIntervalSince(bugPattern.lastSeen) / 86400
        
        if daysSinceLastOccurrence < 7 {
            return .days(3)
        } else if daysSinceLastOccurrence < 30 {
            return .weeks(2)
        } else {
            return .months(1)
        }
    }
    
    private mutating func generateInsights() {
        learningInsights.removeAll()
        
        // Generate insights from development patterns
        for pattern in developmentPatterns where pattern.frequency > 3 {
            let insight = LearningInsight(
                category: .pattern,
                description: "Frequent pattern detected: \(pattern.name)",
                confidence: pattern.confidence,
                actionable: true,
                recommendation: generatePatternRecommendation(for: pattern)
            )
            learningInsights.append(insight)
        }
        
        // Generate insights from quality trends
        if let latestQuality = qualityTrends.last,
           qualityTrends.count > 3 {
            let previousQuality = qualityTrends[qualityTrends.count - 4]
            let qualityChange = latestQuality.overallQuality - previousQuality.overallQuality
            
            if qualityChange < -0.1 {
                let insight = LearningInsight(
                    category: .quality,
                    description: "Code quality declining over recent versions",
                    confidence: 0.8,
                    actionable: true,
                    recommendation: "Consider implementing code review processes or refactoring"
                )
                learningInsights.append(insight)
            }
        }
    }
    
    private func generatePatternRecommendation(for pattern: DevelopmentPattern) -> String {
        switch pattern.impact {
        case .high:
            return "Consider automating or optimizing this frequent pattern"
        case .medium:
            return "Monitor this pattern for potential optimization opportunities"
        case .low:
            return "Document this pattern for team knowledge sharing"
        }
    }
    
    private func generateExecutiveSummary() -> String {
        let healthText = healthScore > 0.8 ? "excellent" : healthScore > 0.6 ? "good" : "concerning"
        let velocityText = velocityTrend.rawValue
        let maturityText = maturityLevel.rawValue
        
        return "Code evolution shows \(healthText) health (score: \(String(format: "%.2f", healthScore))) with \(velocityText) development velocity. Project maturity level: \(maturityText). \(versionHistory.count) versions tracked with \(bugPatterns.count) bug patterns identified."
    }
    
    private func analyzeVersionHistory() -> VersionHistoryAnalysis {
        let totalVersions = versionHistory.count
        let averageChangeSize = versionHistory.map { $0.changeAnalysis.linesChanged }.reduce(0, +) / max(1, totalVersions)
        let versionTypes = Dictionary(grouping: versionHistory, by: { $0.type })
        
        return VersionHistoryAnalysis(
            totalVersions: totalVersions,
            averageChangeSize: averageChangeSize,
            versionDistribution: versionTypes.mapValues { $0.count },
            developmentTimeline: versionHistory.map { VersionTimelineEntry(version: $0.version, date: $0.timestamp, type: $0.type) }
        )
    }
    
    private func analyzeQualityTrends() -> QualityTrendAnalysis {
        guard !qualityTrends.isEmpty else {
            return QualityTrendAnalysis(overallTrend: .stable, averageQuality: 0.5, qualityVariability: 0.0, improvementRate: 0.0)
        }
        
        let averageQuality = qualityTrends.map { $0.overallQuality }.reduce(0, +) / Double(qualityTrends.count)
        let qualityVariability = calculateVariability(qualityTrends.map { $0.overallQuality })
        let improvementRate = calculateImprovementRate()
        
        let trend: QualityTrendDirection
        if improvementRate > 0.05 {
            trend = .improving
        } else if improvementRate < -0.05 {
            trend = .declining
        } else {
            trend = .stable
        }
        
        return QualityTrendAnalysis(
            overallTrend: trend,
            averageQuality: averageQuality,
            qualityVariability: qualityVariability,
            improvementRate: improvementRate
        )
    }
    
    private func calculateVariability(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        
        return sqrt(variance)
    }
    
    private func calculateImprovementRate() -> Double {
        guard qualityTrends.count > 2 else { return 0.0 }
        
        let recent = qualityTrends.suffix(3).map { $0.overallQuality }
        let older = qualityTrends.prefix(3).map { $0.overallQuality }
        
        let recentAverage = recent.reduce(0, +) / Double(recent.count)
        let olderAverage = older.reduce(0, +) / Double(older.count)
        
        return recentAverage - olderAverage
    }
    
    private func analyzePerformanceEvolution() -> PerformanceEvolutionAnalysis {
        guard !performanceMetrics.isEmpty else {
            return PerformanceEvolutionAnalysis(trend: .stable, averagePerformance: 0.5, performanceVariability: 0.0, bottlenecks: [])
        }
        
        let averagePerformance = performanceMetrics.map { $0.performanceIndex }.reduce(0, +) / Double(performanceMetrics.count)
        let performanceVariability = calculateVariability(performanceMetrics.map { $0.performanceIndex })
        let bottlenecks = identifyPerformanceBottlenecks()
        
        let trend = determinePerformanceTrend()
        
        return PerformanceEvolutionAnalysis(
            trend: trend,
            averagePerformance: averagePerformance,
            performanceVariability: performanceVariability,
            bottlenecks: bottlenecks
        )
    }
    
    private func identifyPerformanceBottlenecks() -> [String] {
        return performanceMetrics
            .filter { $0.performanceIndex < 0.5 }
            .map { "Performance issue at \($0.timestamp.formatted())" }
    }
    
    private func determinePerformanceTrend() -> PerformanceTrend {
        guard performanceMetrics.count > 2 else { return .stable }
        
        let recent = performanceMetrics.suffix(3).map { $0.performanceIndex }.reduce(0, +) / 3.0
        let older = performanceMetrics.prefix(3).map { $0.performanceIndex }.reduce(0, +) / 3.0
        
        if recent > older + 0.1 {
            return .improving
        } else if recent < older - 0.1 {
            return .declining
        } else {
            return .stable
        }
    }
    
    private func analyzeDevelopmentPatterns() -> DevelopmentPatternAnalysis {
        let frequentPatterns = developmentPatterns.filter { $0.frequency > 2 }
        let patternsByImpact = Dictionary(grouping: developmentPatterns, by: { $0.impact })
        
        return DevelopmentPatternAnalysis(
            totalPatterns: developmentPatterns.count,
            frequentPatterns: frequentPatterns,
            patternsByImpact: patternsByImpact.mapValues { $0.count },
            recommendations: generatePatternRecommendations()
        )
    }
    
    private func generatePatternRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let highImpactPatterns = developmentPatterns.filter { $0.impact == .high && $0.frequency > 2 }
        for pattern in highImpactPatterns {
            recommendations.append("Optimize high-impact pattern: \(pattern.name)")
        }
        
        return recommendations
    }
    
    private func generateRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if healthScore < 0.7 {
            recommendations.append("Improve overall code health through refactoring and bug fixes")
        }
        
        if technicalDebtLevel == .high || technicalDebtLevel == .critical {
            recommendations.append("Address technical debt to improve maintainability")
        }
        
        if velocityTrend == .decelerating {
            recommendations.append("Investigate factors causing development velocity decline")
        }
        
        return recommendations
    }
    
    private func generateProjections() -> [String] {
        var projections: [String] = []
        
        // Project based on current trends
        if velocityTrend == .accelerating {
            projections.append("Development velocity likely to continue improving")
        }
        
        if qualityTrends.count > 3 {
            let qualityDirection = calculateImprovementRate() > 0 ? "improve" : "decline"
            projections.append("Code quality projected to \(qualityDirection) based on current trends")
        }
        
        return projections
    }
    
    private func compareVelocity(with other: CodeEvolution) -> String {
        let myVelocity = Double(versionHistory.count) / max(1, Date().timeIntervalSince(creationDate) / 86400)
        let otherVelocity = Double(other.versionHistory.count) / max(1, Date().timeIntervalSince(other.creationDate) / 86400)
        
        if myVelocity > otherVelocity * 1.2 {
            return "Significantly faster development velocity"
        } else if myVelocity < otherVelocity * 0.8 {
            return "Slower development velocity"
        } else {
            return "Similar development velocity"
        }
    }
    
    private func compareQuality(with other: CodeEvolution) -> String {
        let qualityDiff = healthScore - other.healthScore
        
        if qualityDiff > 0.2 {
            return "Significantly higher code quality"
        } else if qualityDiff < -0.2 {
            return "Lower code quality"
        } else {
            return "Similar code quality"
        }
    }
    
    private func compareComplexity(with other: CodeEvolution) -> String {
        let myComplexity = complexityEvolution.currentComplexity
        let otherComplexity = other.complexityEvolution.currentComplexity
        
        if myComplexity < otherComplexity * 0.8 {
            return "Lower complexity"
        } else if myComplexity > otherComplexity * 1.2 {
            return "Higher complexity"
        } else {
            return "Similar complexity"
        }
    }
    
    private func generateComparisonInsights(with other: CodeEvolution) -> [String] {
        var insights: [String] = []
        
        if bugPatterns.count < other.bugPatterns.count {
            insights.append("Fewer bug patterns detected")
        }
        
        if refactoringHistory.count > other.refactoringHistory.count {
            insights.append("More proactive refactoring activity")
        }
        
        return insights
    }
}
