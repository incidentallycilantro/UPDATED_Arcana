//
// ResponseQuality.swift
// Arcana
//
// Revolutionary response quality assessment and metrics system
// Provides comprehensive quality evaluation with confidence scoring and validation
//

import Foundation

// MARK: - Response Quality

/// Comprehensive response quality assessment with multi-dimensional evaluation
/// Tracks accuracy, relevance, helpfulness, and other quality metrics for continuous improvement
public struct ResponseQuality: Codable, Hashable, Identifiable {
    
    // MARK: - Properties
    
    public let id: UUID
    public let responseId: UUID
    public let timestamp: Date
    
    // Core quality metrics
    public let overallScore: Double // 0.0 - 1.0
    public let confidence: Double // 0.0 - 1.0
    public let accuracy: Double // 0.0 - 1.0
    public let relevance: Double // 0.0 - 1.0
    public let helpfulness: Double // 0.0 - 1.0
    public let clarity: Double // 0.0 - 1.0
    public let completeness: Double // 0.0 - 1.0
    
    // Specialized metrics
    public let factualConsistency: Double // 0.0 - 1.0
    public let contextualRelevance: Double // 0.0 - 1.0
    public let linguisticQuality: Double // 0.0 - 1.0
    public let creativityLevel: Double? // Optional, for creative tasks
    public let technicalAccuracy: Double? // Optional, for technical content
    
    // Validation metrics
    public let validationStatus: ValidationStatus
    public let validationFlags: [ValidationFlag]
    public let confidenceInterval: ConfidenceInterval
    public let uncertaintyMeasure: Double
    
    // Context information
    public let workspaceType: WorkspaceType
    public let queryComplexity: QueryComplexity
    public let responseLength: Int
    public let inferenceTime: TimeInterval
    public let modelUsed: String
    
    // Quality assessment metadata
    public let assessmentMethod: AssessmentMethod
    public let qualityDimensions: [QualityDimension]
    public let improvementSuggestions: [ImprovementSuggestion]
    public let benchmarkComparison: BenchmarkComparison?
    
    // MARK: - Initialization
    
    public init(
        responseId: UUID,
        overallScore: Double,
        confidence: Double,
        accuracy: Double,
        relevance: Double,
        helpfulness: Double,
        clarity: Double,
        completeness: Double,
        factualConsistency: Double,
        contextualRelevance: Double,
        linguisticQuality: Double,
        creativityLevel: Double? = nil,
        technicalAccuracy: Double? = nil,
        validationStatus: ValidationStatus,
        validationFlags: [ValidationFlag] = [],
        confidenceInterval: ConfidenceInterval,
        uncertaintyMeasure: Double,
        workspaceType: WorkspaceType,
        queryComplexity: QueryComplexity,
        responseLength: Int,
        inferenceTime: TimeInterval,
        modelUsed: String,
        assessmentMethod: AssessmentMethod,
        qualityDimensions: [QualityDimension] = [],
        improvementSuggestions: [ImprovementSuggestion] = [],
        benchmarkComparison: BenchmarkComparison? = nil
    ) {
        self.id = UUID()
        self.responseId = responseId
        self.timestamp = Date()
        
        // Ensure all scores are within valid range
        self.overallScore = max(0.0, min(1.0, overallScore))
        self.confidence = max(0.0, min(1.0, confidence))
        self.accuracy = max(0.0, min(1.0, accuracy))
        self.relevance = max(0.0, min(1.0, relevance))
        self.helpfulness = max(0.0, min(1.0, helpfulness))
        self.clarity = max(0.0, min(1.0, clarity))
        self.completeness = max(0.0, min(1.0, completeness))
        self.factualConsistency = max(0.0, min(1.0, factualConsistency))
        self.contextualRelevance = max(0.0, min(1.0, contextualRelevance))
        self.linguisticQuality = max(0.0, min(1.0, linguisticQuality))
        
        self.creativityLevel = creativityLevel.map { max(0.0, min(1.0, $0)) }
        self.technicalAccuracy = technicalAccuracy.map { max(0.0, min(1.0, $0)) }
        
        self.validationStatus = validationStatus
        self.validationFlags = validationFlags
        self.confidenceInterval = confidenceInterval
        self.uncertaintyMeasure = max(0.0, min(1.0, uncertaintyMeasure))
        
        self.workspaceType = workspaceType
        self.queryComplexity = queryComplexity
        self.responseLength = responseLength
        self.inferenceTime = inferenceTime
        self.modelUsed = modelUsed
        
        self.assessmentMethod = assessmentMethod
        self.qualityDimensions = qualityDimensions
        self.improvementSuggestions = improvementSuggestions
        self.benchmarkComparison = benchmarkComparison
    }
    
    // MARK: - Computed Properties
    
    /// Overall quality grade based on score
    public var qualityGrade: QualityGrade {
        switch overallScore {
        case 0.9...1.0: return .excellent
        case 0.8..<0.9: return .good
        case 0.7..<0.8: return .satisfactory
        case 0.6..<0.7: return .needsImprovement
        default: return .poor
        }
    }
    
    /// Human-readable quality summary
    public var qualitySummary: String {
        let grade = qualityGrade.displayName
        let confidenceText = confidence > 0.8 ? "High confidence" : confidence > 0.6 ? "Medium confidence" : "Low confidence"
        return "\(grade) quality with \(confidenceText.lowercased())"
    }
    
    /// Key strengths of the response
    public var strengths: [String] {
        var strengths: [String] = []
        
        if accuracy > 0.8 { strengths.append("High accuracy") }
        if relevance > 0.8 { strengths.append("Highly relevant") }
        if helpfulness > 0.8 { strengths.append("Very helpful") }
        if clarity > 0.8 { strengths.append("Clear communication") }
        if completeness > 0.8 { strengths.append("Comprehensive") }
        if factualConsistency > 0.8 { strengths.append("Factually consistent") }
        
        if let creativity = creativityLevel, creativity > 0.8 {
            strengths.append("Creative")
        }
        
        if let technical = technicalAccuracy, technical > 0.8 {
            strengths.append("Technically accurate")
        }
        
        return strengths
    }
    
    /// Areas needing improvement
    public var weaknesses: [String] {
        var weaknesses: [String] = []
        
        if accuracy < 0.6 { weaknesses.append("Accuracy needs improvement") }
        if relevance < 0.6 { weaknesses.append("Relevance could be better") }
        if helpfulness < 0.6 { weaknesses.append("Could be more helpful") }
        if clarity < 0.6 { weaknesses.append("Clarity needs work") }
        if completeness < 0.6 { weaknesses.append("Incomplete response") }
        if factualConsistency < 0.6 { weaknesses.append("Factual inconsistencies") }
        
        return weaknesses
    }
    
    /// Risk level based on validation flags and scores
    public var riskLevel: RiskLevel {
        if validationFlags.contains(where: { $0.severity == .critical }) {
            return .high
        } else if validationFlags.contains(where: { $0.severity == .major }) {
            return .medium
        } else if overallScore < 0.6 || confidence < 0.5 {
            return .medium
        } else if validationFlags.contains(where: { $0.severity == .minor }) {
            return .low
        } else {
            return .minimal
        }
    }
    
    // MARK: - Methods
    
    /// Create a detailed quality report
    public func generateQualityReport() -> QualityReport {
        return QualityReport(
            responseQuality: self,
            executiveSummary: generateExecutiveSummary(),
            detailedMetrics: generateDetailedMetrics(),
            recommendations: generateRecommendations(),
            benchmarkAnalysis: benchmarkComparison,
            validationSummary: generateValidationSummary()
        )
    }
    
    /// Compare with another response quality
    public func compare(with other: ResponseQuality) -> QualityComparison {
        return QualityComparison(
            baseline: self,
            comparison: other,
            improvements: calculateImprovements(from: other),
            regressions: calculateRegressions(from: other),
            overallChange: overallScore - other.overallScore
        )
    }
    
    /// Check if quality meets minimum threshold
    public func meetsQualityThreshold(_ threshold: Double = 0.7) -> Bool {
        return overallScore >= threshold && !validationFlags.contains { $0.severity == .critical }
    }
    
    /// Get quality insights for improvement
    public func getQualityInsights() -> QualityInsights {
        return QualityInsights(
            primaryStrengths: Array(strengths.prefix(3)),
            primaryWeaknesses: Array(weaknesses.prefix(3)),
            improvementPriority: determineImprovementPriority(),
            confidenceAssessment: assessConfidenceLevel(),
            recommendedActions: getRecommendedActions()
        )
    }
    
    // MARK: - Private Methods
    
    private func generateExecutiveSummary() -> String {
        let qualityText = qualityGrade.displayName.lowercased()
        let confidenceText = confidence > 0.8 ? "high" : confidence > 0.6 ? "moderate" : "low"
        
        var summary = "Response demonstrates \(qualityText) quality with \(confidenceText) confidence (\(String(format: "%.1f%%", confidence * 100)))."
        
        if !strengths.isEmpty {
            summary += " Key strengths include \(strengths.prefix(2).joined(separator: " and "))."
        }
        
        if !weaknesses.isEmpty {
            summary += " Areas for improvement: \(weaknesses.prefix(2).joined(separator: " and "))."
        }
        
        return summary
    }
    
    private func generateDetailedMetrics() -> [QualityMetric] {
        return [
            QualityMetric(name: "Overall Score", value: overallScore, category: .overall),
            QualityMetric(name: "Confidence", value: confidence, category: .confidence),
            QualityMetric(name: "Accuracy", value: accuracy, category: .content),
            QualityMetric(name: "Relevance", value: relevance, category: .content),
            QualityMetric(name: "Helpfulness", value: helpfulness, category: .utility),
            QualityMetric(name: "Clarity", value: clarity, category: .communication),
            QualityMetric(name: "Completeness", value: completeness, category: .content),
            QualityMetric(name: "Factual Consistency", value: factualConsistency, category: .accuracy),
            QualityMetric(name: "Contextual Relevance", value: contextualRelevance, category: .context),
            QualityMetric(name: "Linguistic Quality", value: linguisticQuality, category: .communication)
        ]
    }
    
    private func generateRecommendations() -> [QualityRecommendation] {
        var recommendations: [QualityRecommendation] = []
        
        // Add specific recommendations based on weak areas
        if accuracy < 0.7 {
            recommendations.append(QualityRecommendation(
                type: .accuracy,
                priority: .high,
                description: "Improve fact-checking and verification processes",
                expectedImpact: 0.15
            ))
        }
        
        if clarity < 0.7 {
            recommendations.append(QualityRecommendation(
                type: .clarity,
                priority: .medium,
                description: "Enhance response structure and explanation clarity",
                expectedImpact: 0.12
            ))
        }
        
        if completeness < 0.7 {
            recommendations.append(QualityRecommendation(
                type: .completeness,
                priority: .medium,
                description: "Provide more comprehensive coverage of the topic",
                expectedImpact: 0.10
            ))
        }
        
        return recommendations
    }
    
    private func generateValidationSummary() -> ValidationSummary {
        let criticalFlags = validationFlags.filter { $0.severity == .critical }
        let majorFlags = validationFlags.filter { $0.severity == .major }
        let minorFlags = validationFlags.filter { $0.severity == .minor }
        
        return ValidationSummary(
            status: validationStatus,
            totalFlags: validationFlags.count,
            criticalIssues: criticalFlags.count,
            majorIssues: majorFlags.count,
            minorIssues: minorFlags.count,
            passedValidation: validationStatus == .validated && criticalFlags.isEmpty
        )
    }
    
    private func calculateImprovements(from other: ResponseQuality) -> [QualityImprovement] {
        var improvements: [QualityImprovement] = []
        
        let metrics = [
            ("Overall Score", overallScore, other.overallScore),
            ("Accuracy", accuracy, other.accuracy),
            ("Relevance", relevance, other.relevance),
            ("Helpfulness", helpfulness, other.helpfulness),
            ("Clarity", clarity, other.clarity),
            ("Completeness", completeness, other.completeness)
        ]
        
        for (name, current, previous) in metrics {
            if current > previous {
                improvements.append(QualityImprovement(
                    metric: name,
                    improvement: current - previous,
                    significance: determineSignificance(current - previous)
                ))
            }
        }
        
        return improvements
    }
    
    private func calculateRegressions(from other: ResponseQuality) -> [QualityRegression] {
        var regressions: [QualityRegression] = []
        
        let metrics = [
            ("Overall Score", overallScore, other.overallScore),
            ("Accuracy", accuracy, other.accuracy),
            ("Relevance", relevance, other.relevance),
            ("Helpfulness", helpfulness, other.helpfulness),
            ("Clarity", clarity, other.clarity),
            ("Completeness", completeness, other.completeness)
        ]
        
        for (name, current, previous) in metrics {
            if current < previous {
                regressions.append(QualityRegression(
                    metric: name,
                    regression: previous - current,
                    severity: determineRegressionSeverity(previous - current)
                ))
            }
        }
        
        return regressions
    }
    
    private func determineImprovementPriority() -> ImprovementPriority {
        let criticalIssues = validationFlags.filter { $0.severity == .critical }.count
        let majorIssues = validationFlags.filter { $0.severity == .major }.count
        
        if criticalIssues > 0 || overallScore < 0.5 {
            return .critical
        } else if majorIssues > 0 || overallScore < 0.7 {
            return .high
        } else if overallScore < 0.8 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func assessConfidenceLevel() -> ConfidenceAssessment {
        return ConfidenceAssessment(
            level: confidence > 0.8 ? .high : confidence > 0.6 ? .medium : .low,
            factors: getConfidenceFactors(),
            reliability: calculateReliability(),
            uncertaintyMeasure: uncertaintyMeasure
        )
    }
    
    private func getConfidenceFactors() -> [ConfidenceFactor] {
        var factors: [ConfidenceFactor] = []
        
        if factualConsistency > 0.8 {
            factors.append(ConfidenceFactor(type: .factualConsistency, impact: .positive, weight: 0.3))
        }
        
        if contextualRelevance > 0.8 {
            factors.append(ConfidenceFactor(type: .contextualAlignment, impact: .positive, weight: 0.2))
        }
        
        if validationFlags.isEmpty {
            factors.append(ConfidenceFactor(type: .validationClean, impact: .positive, weight: 0.2))
        }
        
        return factors
    }
    
    private func calculateReliability() -> Double {
        let validationReliability = validationStatus == .validated ? 0.3 : 0.0
        let consistencyReliability = factualConsistency * 0.3
        let confidenceReliability = confidence * 0.4
        
        return validationReliability + consistencyReliability + confidenceReliability
    }
    
    private func getRecommendedActions() -> [RecommendedAction] {
        var actions: [RecommendedAction] = []
        
        if overallScore < 0.7 {
            actions.append(RecommendedAction(
                type: .qualityImprovement,
                description: "Focus on improving overall response quality",
                priority: .high
            ))
        }
        
        if confidence < 0.6 {
            actions.append(RecommendedAction(
                type: .confidenceBuilding,
                description: "Enhance confidence through better validation",
                priority: .medium
            ))
        }
        
        if !validationFlags.isEmpty {
            actions.append(RecommendedAction(
                type: .validation,
                description: "Address validation issues before deployment",
                priority: .high
            ))
        }
        
        return actions
    }
    
    private func determineSignificance(_ improvement: Double) -> ImprovementSignificance {
        if improvement > 0.2 {
            return .major
        } else if improvement > 0.1 {
            return .moderate
        } else if improvement > 0.05 {
            return .minor
        } else {
            return .negligible
        }
    }
    
    private func determineRegressionSeverity(_ regression: Double) -> RegressionSeverity {
        if regression > 0.2 {
            return .severe
        } else if regression > 0.1 {
            return .moderate
        } else {
            return .minor
        }
    }
}

// MARK: - Supporting Types

/// Validation status for response quality
public enum ValidationStatus: String, Codable, CaseIterable, Hashable {
    case pending = "pending"
    case validated = "validated"
    case rejected = "rejected"
    case requiresReview = "requiresReview"
    
    public var displayName: String {
        switch self {
        case .pending: return "Pending Validation"
        case .validated: return "Validated"
        case .rejected: return "Rejected"
        case .requiresReview: return "Requires Review"
        }
    }
}

/// Validation flag for quality issues
public struct ValidationFlag: Codable, Hashable {
    public let type: ValidationFlagType
    public let severity: ValidationSeverity
    public let description: String
    public let recommendation: String?
    
    public init(type: ValidationFlagType, severity: ValidationSeverity, description: String, recommendation: String? = nil) {
        self.type = type
        self.severity = severity
        self.description = description
        self.recommendation = recommendation
    }
}

/// Types of validation flags
public enum ValidationFlagType: String, Codable, CaseIterable, Hashable {
    case factualError = "factualError"
    case contextualMismatch = "contextualMismatch"
    case linguisticIssue = "linguisticIssue"
    case completenessIssue = "completenessIssue"
    case relevanceIssue = "relevanceIssue"
    case clarityIssue = "clarityIssue"
    case technicalError = "technicalError"
    case biasDetected = "biasDetected"
    case privacyConcern = "privacyConcern"
    
    public var displayName: String {
        switch self {
        case .factualError: return "Factual Error"
        case .contextualMismatch: return "Contextual Mismatch"
        case .linguisticIssue: return "Linguistic Issue"
        case .completenessIssue: return "Completeness Issue"
        case .relevanceIssue: return "Relevance Issue"
        case .clarityIssue: return "Clarity Issue"
        case .technicalError: return "Technical Error"
        case .biasDetected: return "Bias Detected"
        case .privacyConcern: return "Privacy Concern"
        }
    }
}

/// Severity levels for validation flags
public enum ValidationSeverity: String, Codable, CaseIterable, Hashable {
    case minor = "minor"
    case major = "major"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .minor: return "Minor"
        case .major: return "Major"
        case .critical: return "Critical"
        }
    }
}

/// Confidence interval for quality scores
public struct ConfidenceInterval: Codable, Hashable {
    public let lowerBound: Double
    public let upperBound: Double
    public let confidenceLevel: Double // e.g., 0.95 for 95% confidence
    
    public init(lowerBound: Double, upperBound: Double, confidenceLevel: Double = 0.95) {
        self.lowerBound = max(0.0, min(1.0, lowerBound))
        self.upperBound = max(0.0, min(1.0, upperBound))
        self.confidenceLevel = max(0.0, min(1.0, confidenceLevel))
    }
    
    public var width: Double {
        return upperBound - lowerBound
    }
}

/// Query complexity assessment
public enum QueryComplexity: String, Codable, CaseIterable, Hashable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
    case veryComplex = "veryComplex"
    
    public var displayName: String {
        switch self {
        case .simple: return "Simple"
        case .moderate: return "Moderate"
        case .complex: return "Complex"
        case .veryComplex: return "Very Complex"
        }
    }
}

/// Assessment method used for quality evaluation
public enum AssessmentMethod: String, Codable, CaseIterable, Hashable {
    case automated = "automated"
    case hybrid = "hybrid"
    case manual = "manual"
    case ensemble = "ensemble"
    
    public var displayName: String {
        switch self {
        case .automated: return "Automated Assessment"
        case .hybrid: return "Hybrid Assessment"
        case .manual: return "Manual Assessment"
        case .ensemble: return "Ensemble Assessment"
        }
    }
}

/// Quality dimension for detailed analysis
public struct QualityDimension: Codable, Hashable {
    public let name: String
    public let score: Double
    public let weight: Double
    public let description: String
    
    public init(name: String, score: Double, weight: Double, description: String) {
        self.name = name
        self.score = max(0.0, min(1.0, score))
        self.weight = max(0.0, min(1.0, weight))
        self.description = description
    }
}

/// Improvement suggestion
public struct ImprovementSuggestion: Codable, Hashable {
    public let category: ImprovementCategory
    public let description: String
    public let priority: SuggestionPriority
    public let expectedImpact: Double
    public let implementationDifficulty: ImplementationDifficulty
    
    public init(category: ImprovementCategory, description: String, priority: SuggestionPriority, expectedImpact: Double, implementationDifficulty: ImplementationDifficulty) {
        self.category = category
        self.description = description
        self.priority = priority
        self.expectedImpact = max(0.0, min(1.0, expectedImpact))
        self.implementationDifficulty = implementationDifficulty
    }
}

/// Improvement categories
public enum ImprovementCategory: String, Codable, CaseIterable, Hashable {
    case accuracy = "accuracy"
    case relevance = "relevance"
    case clarity = "clarity"
    case completeness = "completeness"
    case efficiency = "efficiency"
    case creativity = "creativity"
    case technical = "technical"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Suggestion priority levels
public enum SuggestionPriority: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Implementation difficulty levels
public enum ImplementationDifficulty: String, Codable, CaseIterable, Hashable {
    case easy = "easy"
    case moderate = "moderate"
    case difficult = "difficult"
    case veryDifficult = "veryDifficult"
    
    public var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .moderate: return "Moderate"
        case .difficult: return "Difficult"
        case .veryDifficult: return "Very Difficult"
        }
    }
}

/// Benchmark comparison data
public struct BenchmarkComparison: Codable, Hashable {
    public let benchmarkName: String
    public let benchmarkScore: Double
    public let relativePerformance: Double // Positive = better than benchmark
    public let percentileRank: Double
    public let comparisonNotes: String?
    
    public init(benchmarkName: String, benchmarkScore: Double, relativePerformance: Double, percentileRank: Double, comparisonNotes: String? = nil) {
        self.benchmarkName = benchmarkName
        self.benchmarkScore = max(0.0, min(1.0, benchmarkScore))
        self.relativePerformance = relativePerformance
        self.percentileRank = max(0.0, min(100.0, percentileRank))
        self.comparisonNotes = comparisonNotes
    }
}

/// Quality grade classification
public enum QualityGrade: String, Codable, CaseIterable, Hashable {
    case excellent = "excellent"
    case good = "good"
    case satisfactory = "satisfactory"
    case needsImprovement = "needsImprovement"
    case poor = "poor"
    
    public var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .satisfactory: return "Satisfactory"
        case .needsImprovement: return "Needs Improvement"
        case .poor: return "Poor"
        }
    }
    
    public var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .satisfactory: return "yellow"
        case .needsImprovement: return "orange"
        case .poor: return "red"
        }
    }
}

/// Risk level assessment
public enum RiskLevel: String, Codable, CaseIterable, Hashable {
    case minimal = "minimal"
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        return rawValue.capitalized
    }
    
    public var color: String {
        switch self {
        case .minimal: return "green"
        case .low: return "blue"
        case .medium: return "orange"
        case .high: return "red"
        }
    }
}

// MARK: - Quality Report Types

/// Comprehensive quality report
public struct QualityReport: Codable, Hashable {
    public let responseQuality: ResponseQuality
    public let executiveSummary: String
    public let detailedMetrics: [QualityMetric]
    public let recommendations: [QualityRecommendation]
    public let benchmarkAnalysis: BenchmarkComparison?
    public let validationSummary: ValidationSummary
    
    public init(responseQuality: ResponseQuality, executiveSummary: String, detailedMetrics: [QualityMetric], recommendations: [QualityRecommendation], benchmarkAnalysis: BenchmarkComparison?, validationSummary: ValidationSummary) {
        self.responseQuality = responseQuality
        self.executiveSummary = executiveSummary
        self.detailedMetrics = detailedMetrics
        self.recommendations = recommendations
        self.benchmarkAnalysis = benchmarkAnalysis
        self.validationSummary = validationSummary
    }
}

/// Individual quality metric
public struct QualityMetric: Codable, Hashable {
    public let name: String
    public let value: Double
    public let category: MetricCategory
    
    public init(name: String, value: Double, category: MetricCategory) {
        self.name = name
        self.value = max(0.0, min(1.0, value))
        self.category = category
    }
}

/// Metric categories for organization
public enum MetricCategory: String, Codable, CaseIterable, Hashable {
    case overall = "overall"
    case confidence = "confidence"
    case content = "content"
    case utility = "utility"
    case communication = "communication"
    case accuracy = "accuracy"
    case context = "context"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Quality recommendation
public struct QualityRecommendation: Codable, Hashable {
    public let type: RecommendationType
    public let priority: SuggestionPriority
    public let description: String
    public let expectedImpact: Double
    
    public init(type: RecommendationType, priority: SuggestionPriority, description: String, expectedImpact: Double) {
        self.type = type
        self.priority = priority
        self.description = description
        self.expectedImpact = max(0.0, min(1.0, expectedImpact))
    }
}

/// Recommendation types
public enum RecommendationType: String, Codable, CaseIterable, Hashable {
    case accuracy = "accuracy"
    case clarity = "clarity"
    case completeness = "completeness"
    case relevance = "relevance"
    case efficiency = "efficiency"
    case validation = "validation"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Validation summary
public struct ValidationSummary: Codable, Hashable {
    public let status: ValidationStatus
    public let totalFlags: Int
    public let criticalIssues: Int
    public let majorIssues: Int
    public let minorIssues: Int
    public let passedValidation: Bool
    
    public init(status: ValidationStatus, totalFlags: Int, criticalIssues: Int, majorIssues: Int, minorIssues: Int, passedValidation: Bool) {
        self.status = status
        self.totalFlags = totalFlags
        self.criticalIssues = criticalIssues
        self.majorIssues = majorIssues
        self.minorIssues = minorIssues
        self.passedValidation = passedValidation
    }
}

// MARK: - Comparison Types

/// Quality comparison between two responses
public struct QualityComparison: Codable, Hashable {
    public let baseline: ResponseQuality
    public let comparison: ResponseQuality
    public let improvements: [QualityImprovement]
    public let regressions: [QualityRegression]
    public let overallChange: Double
    
    public init(baseline: ResponseQuality, comparison: ResponseQuality, improvements: [QualityImprovement], regressions: [QualityRegression], overallChange: Double) {
        self.baseline = baseline
        self.comparison = comparison
        self.improvements = improvements
        self.regressions = regressions
        self.overallChange = overallChange
    }
}

/// Quality improvement
public struct QualityImprovement: Codable, Hashable {
    public let metric: String
    public let improvement: Double
    public let significance: ImprovementSignificance
    
    public init(metric: String, improvement: Double, significance: ImprovementSignificance) {
        self.metric = metric
        self.improvement = improvement
        self.significance = significance
    }
}

/// Quality regression
public struct QualityRegression: Codable, Hashable {
    public let metric: String
    public let regression: Double
    public let severity: RegressionSeverity
    
    public init(metric: String, regression: Double, severity: RegressionSeverity) {
        self.metric = metric
        self.regression = regression
        self.severity = severity
    }
}

/// Improvement significance levels
public enum ImprovementSignificance: String, Codable, CaseIterable, Hashable {
    case negligible = "negligible"
    case minor = "minor"
    case moderate = "moderate"
    case major = "major"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Regression severity levels
public enum RegressionSeverity: String, Codable, CaseIterable, Hashable {
    case minor = "minor"
    case moderate = "moderate"
    case severe = "severe"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Insight Types

/// Quality insights for improvement guidance
public struct QualityInsights: Codable, Hashable {
    public let primaryStrengths: [String]
    public let primaryWeaknesses: [String]
    public let improvementPriority: ImprovementPriority
    public let confidenceAssessment: ConfidenceAssessment
    public let recommendedActions: [RecommendedAction]
    
    public init(primaryStrengths: [String], primaryWeaknesses: [String], improvementPriority: ImprovementPriority, confidenceAssessment: ConfidenceAssessment, recommendedActions: [RecommendedAction]) {
        self.primaryStrengths = primaryStrengths
        self.primaryWeaknesses = primaryWeaknesses
        self.improvementPriority = improvementPriority
        self.confidenceAssessment = confidenceAssessment
        self.recommendedActions = recommendedActions
    }
}

/// Improvement priority levels
public enum ImprovementPriority: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Confidence assessment
public struct ConfidenceAssessment: Codable, Hashable {
    public let level: ConfidenceLevel
    public let factors: [ConfidenceFactor]
    public let reliability: Double
    public let uncertaintyMeasure: Double
    
    public init(level: ConfidenceLevel, factors: [ConfidenceFactor], reliability: Double, uncertaintyMeasure: Double) {
        self.level = level
        self.factors = factors
        self.reliability = max(0.0, min(1.0, reliability))
        self.uncertaintyMeasure = max(0.0, min(1.0, uncertaintyMeasure))
    }
}

/// Confidence levels
public enum ConfidenceLevel: String, Codable, CaseIterable, Hashable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Confidence factor
public struct ConfidenceFactor: Codable, Hashable {
    public let type: ConfidenceFactorType
    public let impact: FactorImpact
    public let weight: Double
    
    public init(type: ConfidenceFactorType, impact: FactorImpact, weight: Double) {
        self.type = type
        self.impact = impact
        self.weight = max(0.0, min(1.0, weight))
    }
}

/// Confidence factor types
public enum ConfidenceFactorType: String, Codable, CaseIterable, Hashable {
    case factualConsistency = "factualConsistency"
    case contextualAlignment = "contextualAlignment"
    case validationClean = "validationClean"
    case modelAgreement = "modelAgreement"
    case historicalAccuracy = "historicalAccuracy"
    
    public var displayName: String {
        switch self {
        case .factualConsistency: return "Factual Consistency"
        case .contextualAlignment: return "Contextual Alignment"
        case .validationClean: return "Clean Validation"
        case .modelAgreement: return "Model Agreement"
        case .historicalAccuracy: return "Historical Accuracy"
        }
    }
}

/// Factor impact
public enum FactorImpact: String, Codable, CaseIterable, Hashable {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    
    public var displayName: String {
        return rawValue.capitalized
    }
}

/// Recommended action
public struct RecommendedAction: Codable, Hashable {
    public let type: ActionType
    public let description: String
    public let priority: SuggestionPriority
    
    public init(type: ActionType, description: String, priority: SuggestionPriority) {
        self.type = type
        self.description = description
        self.priority = priority
    }
}

/// Action types
public enum ActionType: String, Codable, CaseIterable, Hashable {
    case qualityImprovement = "qualityImprovement"
    case confidenceBuilding = "confidenceBuilding"
    case validation = "validation"
    case optimization = "optimization"
    case training = "training"
    
    public var displayName: String {
        switch self {
        case .qualityImprovement: return "Quality Improvement"
        case .confidenceBuilding: return "Confidence Building"
        case .validation: return "Validation"
        case .optimization: return "Optimization"
        case .training: return "Training"
        }
    }
}
