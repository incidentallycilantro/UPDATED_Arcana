//
// Core/CrossReferenceValidator.swift
// Arcana
//

import Foundation
import OSLog

@MainActor
class CrossReferenceValidator: ObservableObject {
    @Published var validationResults: [ValidationResult] = []
    @Published var factCheckingStats = FactCheckingStats()
    @Published var isValidating = false
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "CrossReferenceValidator")
    private let knowledgeGraph: LocalKnowledgeGraph
    private let webIntelligence: PrivateWebIntelligence?
    private var factDatabase: [String: FactEntry] = [:]
    private var contradictionDetector: ContradictionDetector
    
    init(knowledgeGraph: LocalKnowledgeGraph, webIntelligence: PrivateWebIntelligence? = nil) {
        self.knowledgeGraph = knowledgeGraph
        self.webIntelligence = webIntelligence
        self.contradictionDetector = ContradictionDetector()
    }
    
    func initialize() async throws {
        logger.info("Initializing Cross Reference Validator...")
        
        await loadFactDatabase()
        await initializeContradictionDetector()
        
        logger.info("Cross Reference Validator initialized")
    }
    
    func validateClaim(_ claim: String, context: ConversationContext) async -> ClaimValidation {
        logger.debug("Validating claim: \(claim.prefix(50))...")
        
        await MainActor.run {
            self.isValidating = true
        }
        
        let validationId = UUID()
        let startTime = Date()
        
        var validationSources: [ValidationSource] = []
        var overallConfidence = 0.0
        var contradictions: [Contradiction] = []
        
        // 1. Check against local knowledge graph
        let knowledgeValidation = await validateAgainstKnowledge(claim, context: context)
        validationSources.append(knowledgeValidation)
        
        // 2. Check for internal contradictions
        let contradictionCheck = await checkForContradictions(claim, context: context)
        contradictions.append(contentsOf: contradictionCheck.contradictions)
        
        // 3. Cross-reference with conversation history
        let historyValidation = await validateAgainstHistory(claim, context: context)
        validationSources.append(historyValidation)
        
        // 4. Web verification (if enabled and appropriate)
        if let webIntelligence = webIntelligence, shouldUseWebValidation(for: claim) {
            let webValidation = await validateAgainstWeb(claim, using: webIntelligence)
            validationSources.append(webValidation)
        }
        
        // 5. Calculate overall confidence
        overallConfidence = calculateOverallConfidence(from: validationSources)
        
        // 6. Determine validation result
        let result = determineValidationResult(
            confidence: overallConfidence,
            contradictions: contradictions,
            sources: validationSources
        )
        
        let validation = ClaimValidation(
            id: validationId,
            claim: claim,
            result: result,
            confidence: overallConfidence,
            sources: validationSources,
            contradictions: contradictions,
            processingTime: Date().timeIntervalSince(startTime),
            timestamp: Date()
        )
        
        // Record validation
        await recordValidation(validation)
        
        await MainActor.run {
            self.isValidating = false
        }
        
        logger.debug("Claim validation completed with confidence: \(overallConfidence)")
        return validation
    }
    
    func validateResponse(_ response: String, context: ConversationContext) async -> ResponseValidation {
        logger.debug("Validating response for accuracy and consistency")
        
        let claims = extractClaims(from: response)
        var claimValidations: [ClaimValidation] = []
        
        // Validate each claim
        for claim in claims {
            let validation = await validateClaim(claim, context: context)
            claimValidations.append(validation)
        }
        
        // Calculate overall response validation
        let overallConfidence = claimValidations.isEmpty ? 1.0 :
            claimValidations.map(\.confidence).reduce(0, +) / Double(claimValidations.count)
        
        let contradictions = claimValidations.flatMap(\.contradictions)
        let hasContradictions = !contradictions.isEmpty
        
        let validation = ResponseValidation(
            response: response,
            claimValidations: claimValidations,
            overallConfidence: overallConfidence,
            hasContradictions: hasContradictions,
            contradictions: contradictions,
            timestamp: Date()
        )
        
        return validation
    }
    
    func checkConsistency(across messages: [ChatMessage]) async -> ConsistencyReport {
        logger.debug("Checking consistency across \(messages.count) messages")
        
        var inconsistencies: [Inconsistency] = []
        var factConflicts: [FactConflict] = []
        
        // Extract all claims from messages
        let allClaims = messages.flatMap { message in
            extractClaims(from: message.content).map { claim in
                (claim: claim, messageId: message.id, timestamp: message.timestamp)
            }
        }
        
        // Check for contradictions between claims
        for i in 0..<allClaims.count {
            for j in (i+1)..<allClaims.count {
                let claim1 = allClaims[i]
                let claim2 = allClaims[j]
                
                if let contradiction = await detectContradiction(
                    between: claim1.claim,
                    and: claim2.claim
                ) {
                    let conflict = FactConflict(
                        claim1: claim1.claim,
                        claim2: claim2.claim,
                        messageId1: claim1.messageId,
                        messageId2: claim2.messageId,
                        contradiction: contradiction,
                        severity: contradiction.severity
                    )
                    factConflicts.append(conflict)
                }
            }
        }
        
        // Check for temporal inconsistencies
        let temporalInconsistencies = await checkTemporalConsistency(claims: allClaims)
        inconsistencies.append(contentsOf: temporalInconsistencies)
        
        let consistencyScore = calculateConsistencyScore(
            totalClaims: allClaims.count,
            conflicts: factConflicts.count,
            inconsistencies: inconsistencies.count
        )
        
        return ConsistencyReport(
            messageCount: messages.count,
            totalClaims: allClaims.count,
            consistencyScore: consistencyScore,
            factConflicts: factConflicts,
            inconsistencies: inconsistencies,
            timestamp: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func loadFactDatabase() async {
        // Load known facts from storage
        // This would be populated from reliable sources
        factDatabase = [:]
        logger.debug("Loaded fact database")
    }
    
    private func initializeContradictionDetector() async {
        await contradictionDetector.initialize()
        logger.debug("Initialized contradiction detector")
    }
    
    private func validateAgainstKnowledge(_ claim: String, context: ConversationContext) async -> ValidationSource {
        let confidence = await knowledgeGraph.verifyAgainstKnowledge(claim)
        
        return ValidationSource(
            type: .knowledgeGraph,
            confidence: confidence,
            evidence: ["Local knowledge graph verification"],
            reliability: 0.8
        )
    }
    
    private func validateAgainstHistory(_ claim: String, context: ConversationContext) async -> ValidationSource {
        // Check claim against conversation history
        let historyContent = context.recentMessages.map(\.content).joined(separator: " ")
        
        var confidence = 0.5 // Neutral starting point
        var evidence: [String] = []
        
        // Check for supporting evidence in history
        if historyContent.localizedCaseInsensitiveContains(claim) {
            confidence = 0.9
            evidence.append("Claim directly mentioned in conversation history")
        } else {
            // Check for semantic similarity
            let similarity = calculateSemanticSimilarity(claim, historyContent)
            confidence = 0.5 + (similarity * 0.4)
            evidence.append("Semantic similarity with conversation context")
        }
        
        return ValidationSource(
            type: .conversationHistory,
            confidence: confidence,
            evidence: evidence,
            reliability: 0.7
        )
    }
    
    private func validateAgainstWeb(_ claim: String, using webIntelligence: PrivateWebIntelligence) async -> ValidationSource {
        // Use web intelligence for fact checking
        do {
            let searchResult = try await webIntelligence.verifyFact(claim)
            
            return ValidationSource(
                type: .webSearch,
                confidence: searchResult.confidence,
                evidence: searchResult.sources.map(\.title),
                reliability: 0.6 // Web sources have moderate reliability
            )
        } catch {
            logger.error("Web validation failed: \(error.localizedDescription)")
            
            return ValidationSource(
                type: .webSearch,
                confidence: 0.5,
                evidence: ["Web verification unavailable"],
                reliability: 0.0
            )
        }
    }
    
    private func checkForContradictions(_ claim: String, context: ConversationContext) async -> ContradictionCheck {
        let contradictions = await contradictionDetector.detectContradictions(
            in: claim,
            context: context
        )
        
        return ContradictionCheck(
            contradictions: contradictions,
            hasContradictions: !contradictions.isEmpty
        )
    }
    
    private func shouldUseWebValidation(for claim: String) -> Bool {
        // Determine if web validation is appropriate
        let factualKeywords = ["statistics", "data", "research", "study", "report", "official"]
        let personalKeywords = ["I think", "my opinion", "personally", "in my view"]
        
        let hasFactualKeywords = factualKeywords.contains { claim.lowercased().contains($0) }
        let hasPersonalKeywords = personalKeywords.contains { claim.lowercased().contains($0) }
        
        return hasFactualKeywords && !hasPersonalKeywords
    }
    
    private func extractClaims(from text: String) -> [String] {
        // Extract factual claims from text
        let sentences = text.components(separatedBy: ". ")
        
        return sentences.filter { sentence in
            // Filter for sentences that appear to be factual claims
            sentence.count > 20 &&
            !sentence.lowercased().contains("i think") &&
            !sentence.lowercased().contains("maybe") &&
            !sentence.lowercased().contains("possibly")
        }
    }
    
    private func calculateOverallConfidence(from sources: [ValidationSource]) -> Double {
        guard !sources.isEmpty else { return 0.5 }
        
        // Weighted average based on source reliability
        let totalWeight = sources.map(\.reliability).reduce(0, +)
        let weightedSum = sources.map { $0.confidence * $0.reliability }.reduce(0, +)
        
        return totalWeight > 0 ? weightedSum / totalWeight : 0.5
    }
    
    private func determineValidationResult(
        confidence: Double,
        contradictions: [Contradiction],
        sources: [ValidationSource]
    ) -> ValidationResult.Result {
        
        if !contradictions.isEmpty {
            let hasCriticalContradictions = contradictions.contains { $0.severity == .critical }
            return hasCriticalContradictions ? .contradicted : .questionable
        }
        
        switch confidence {
        case 0.8...1.0:
            return .verified
        case 0.6..<0.8:
            return .likely
        case 0.4..<0.6:
            return .uncertain
        case 0.2..<0.4:
            return .unlikely
        default:
            return .false
        }
    }
    
    private func detectContradiction(between claim1: String, and claim2: String) async -> Contradiction? {
        return await contradictionDetector.detectContradiction(between: claim1, and: claim2)
    }
    
    private func checkTemporalConsistency(claims: [(claim: String, messageId: UUID, timestamp: Date)]) async -> [Inconsistency] {
        var inconsistencies: [Inconsistency] = []
        
        // Check for claims that contradict earlier claims
        let sortedClaims = claims.sorted { $0.timestamp < $1.timestamp }
        
        for i in 0..<sortedClaims.count {
            for j in (i+1)..<sortedClaims.count {
                let earlierClaim = sortedClaims[i]
                let laterClaim = sortedClaims[j]
                
                if let contradiction = await detectContradiction(
                    between: earlierClaim.claim,
                    and: laterClaim.claim
                ) {
                    let inconsistency = Inconsistency(
                        type: .temporal,
                        description: "Later claim contradicts earlier claim",
                        earlierClaim: earlierClaim.claim,
                        laterClaim: laterClaim.claim,
                        timeGap: laterClaim.timestamp.timeIntervalSince(earlierClaim.timestamp)
                    )
                    inconsistencies.append(inconsistency)
                }
            }
        }
        
        return inconsistencies
    }
    
    private func calculateSemanticSimilarity(_ text1: String, _ text2: String) -> Double {
        // Simplified semantic similarity calculation
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func calculateConsistencyScore(totalClaims: Int, conflicts: Int, inconsistencies: Int) -> Double {
        guard totalClaims > 0 else { return 1.0 }
        
        let problemCount = conflicts + inconsistencies
        let consistencyRatio = 1.0 - (Double(problemCount) / Double(totalClaims))
        
        return max(0.0, consistencyRatio)
    }
    
    private func recordValidation(_ validation: ClaimValidation) async {
        await MainActor.run {
            self.validationResults.append(validation)
            
            // Keep only recent validations
            if self.validationResults.count > 100 {
                self.validationResults.removeFirst()
            }
            
            self.updateFactCheckingStats()
        }
    }
    
    private func updateFactCheckingStats() {
        let validations = validationResults
        let verifiedCount = validations.filter { $0.result == .verified }.count
        let contradictedCount = validations.filter { $0.result == .contradicted }.count
        
        factCheckingStats = FactCheckingStats(
            totalValidations: validations.count,
            verifiedClaims: verifiedCount,
            contradictedClaims: contradictedCount,
            averageConfidence: validations.map(\.confidence).reduce(0, +) / Double(max(validations.count, 1)),
            averageProcessingTime: validations.map(\.processingTime).reduce(0, +) / Double(max(validations.count, 1))
        )
    }
}

// MARK: - Supporting Types

struct ClaimValidation {
    let id: UUID
    let claim: String
    let result: ValidationResult.Result
    let confidence: Double
    let sources: [ValidationSource]
    let contradictions: [Contradiction]
    let processingTime: TimeInterval
    let timestamp: Date
}

struct ResponseValidation {
    let response: String
    let claimValidations: [ClaimValidation]
    let overallConfidence: Double
    let hasContradictions: Bool
    let contradictions: [Contradiction]
    let timestamp: Date
}

struct ValidationSource {
    let type: SourceType
    let confidence: Double
    let evidence: [String]
    let reliability: Double
    
    enum SourceType {
        case knowledgeGraph
        case conversationHistory
        case webSearch
        case factDatabase
        case userInput
    }
}

struct ValidationResult {
    enum Result {
        case verified
        case likely
        case uncertain
        case unlikely
        case false
        case contradicted
        case questionable
    }
}

struct ConsistencyReport {
    let messageCount: Int
    let totalClaims: Int
    let consistencyScore: Double
    let factConflicts: [FactConflict]
    let inconsistencies: [Inconsistency]
    let timestamp: Date
}

struct FactConflict {
    let claim1: String
    let claim2: String
    let messageId1: UUID
    let messageId2: UUID
    let contradiction: Contradiction
    let severity: ContradictionSeverity
}

struct Inconsistency {
    let type: InconsistencyType
    let description: String
    let earlierClaim: String
    let laterClaim: String
    let timeGap: TimeInterval
    
    enum InconsistencyType {
        case temporal
        case logical
        case factual
    }
}

struct ContradictionCheck {
    let contradictions: [Contradiction]
    let hasContradictions: Bool
}

struct Contradiction {
    let description: String
    let severity: ContradictionSeverity
    let evidence: [String]
}

enum ContradictionSeverity {
    case low
    case medium
    case high
    case critical
}

struct FactCheckingStats {
    let totalValidations: Int
    let verifiedClaims: Int
    let contradictedClaims: Int
    let averageConfidence: Double
    let averageProcessingTime: TimeInterval
    
    init(totalValidations: Int = 0, verifiedClaims: Int = 0, contradictedClaims: Int = 0, averageConfidence: Double = 0, averageProcessingTime: TimeInterval = 0) {
        self.totalValidations = totalValidations
        self.verifiedClaims = verifiedClaims
        self.contradictedClaims = contradictedClaims
        self.averageConfidence = averageConfidence
        self.averageProcessingTime = averageProcessingTime
    }
}

// MARK: - Supporting Classes

class ContradictionDetector {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ContradictionDetector")
    
    func initialize() async {
        logger.debug("Contradiction detector initialized")
    }
    
    func detectContradictions(in text: String, context: ConversationContext) async -> [Contradiction] {
        // Detect contradictions within text and context
        var contradictions: [Contradiction] = []
        
        // Simple contradiction patterns
        let contradictoryPairs = [
            ("always", "never"),
            ("all", "none"),
            ("possible", "impossible"),
            ("true", "false"),
            ("correct", "incorrect")
        ]
        
        let lowercaseText = text.lowercased()
        
        for (word1, word2) in contradictoryPairs {
            if lowercaseText.contains(word1) && lowercaseText.contains(word2) {
                contradictions.append(Contradiction(
                    description: "Text contains contradictory terms: '\(word1)' and '\(word2)'",
                    severity: .medium,
                    evidence: [text]
                ))
            }
        }
        
        return contradictions
    }
    
    func detectContradiction(between claim1: String, and claim2: String) async -> Contradiction? {
        // Detect contradiction between two claims
        let similarity = calculateSimilarity(claim1, claim2)
        
        if similarity > 0.7 && areContradictory(claim1, claim2) {
            return Contradiction(
                description: "Claims appear to contradict each other",
                severity: .high,
                evidence: [claim1, claim2]
            )
        }
        
        return nil
    }
    
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func areContradictory(_ claim1: String, _ claim2: String) -> Bool {
        // Simple contradiction detection
        let negationWords = ["not", "no", "never", "none", "false", "incorrect", "wrong"]
        
        let claim1Lower = claim1.lowercased()
        let claim2Lower = claim2.lowercased()
        
        let claim1HasNegation = negationWords.contains { claim1Lower.contains($0) }
        let claim2HasNegation = negationWords.contains { claim2Lower.contains($0) }
        
        // If one claim has negation and the other doesn't, they might be contradictory
        return claim1HasNegation != claim2HasNegation
    }
}
