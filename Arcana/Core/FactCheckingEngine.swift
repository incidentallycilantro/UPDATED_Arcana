//
// FactCheckingEngine.swift
// Arcana
//

@MainActor
class FactCheckingEngine: ObservableObject {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "FactChecking")
    private let knowledgeGraph: LocalKnowledgeGraph
    
    init() {
        self.knowledgeGraph = LocalKnowledgeGraph()
    }
    
    func initialize() async throws {
        try await knowledgeGraph.initialize()
        logger.info("Fact Checking Engine initialized")
    }
    
    func checkFacts(_ response: String, context: ConversationContext) async -> FactCheckResult {
        logger.debug("Checking facts in response")
        
        let claims = extractClaims(from: response)
        var verifiedClaims: [ClaimVerification] = []
        
        for claim in claims {
            let verification = await verifyClaim(claim, context: context)
            verifiedClaims.append(verification)
        }
        
        let overallScore = calculateOverallScore(verifiedClaims)
        
        return FactCheckResult(
            overallScore: overallScore,
            verifiedClaims: verifiedClaims,
            flags: identifyFlags(verifiedClaims)
        )
    }
    
    private func extractClaims(from response: String) -> [String] {
        // Simplified claim extraction
        let sentences = response.components(separatedBy: ". ")
        return sentences.filter { sentence in
            sentence.count > 20 &&
            (sentence.lowercased().contains("is") ||
             sentence.lowercased().contains("are") ||
             sentence.lowercased().contains("will"))
        }
    }
    
    private func verifyClaim(_ claim: String, context: ConversationContext) async -> ClaimVerification {
        // Check against local knowledge graph
        let knowledgeScore = await knowledgeGraph.verifyAgainstKnowledge(claim)
        
        // Check for internal consistency
        let consistencyScore = checkInternalConsistency(claim, context: context)
        
        // Combine scores
        let overallVerification = (knowledgeScore + consistencyScore) / 2.0
        
        return ClaimVerification(
            claim: claim,
            verificationScore: overallVerification,
            sources: ["Local Knowledge Graph"],
            confidence: overallVerification
        )
    }
    
    private func checkInternalConsistency(_ claim: String, context: ConversationContext) -> Double {
        // Check consistency with conversation context
        let contextContent = context.recentMessages.map(\.content).joined(separator: " ")
        
        // Simple contradiction detection (would be more sophisticated in production)
        let contradictoryTerms = [
            ("always", "never"),
            ("all", "none"),
            ("impossible", "possible"),
            ("true", "false")
        ]
        
        for (term1, term2) in contradictoryTerms {
            if claim.lowercased().contains(term1) && contextContent.lowercased().contains(term2) {
                return 0.3 // Low consistency due to contradiction
            }
        }
        
        return 0.8 // Default to high consistency
    }
    
    private func calculateOverallScore(_ verifications: [ClaimVerification]) -> Double {
        guard !verifications.isEmpty else { return 0.5 }
        
        let scores = verifications.map(\.verificationScore)
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    private func identifyFlags(_ verifications: [ClaimVerification]) -> [FactCheckFlag] {
        var flags: [FactCheckFlag] = []
        
        for verification in verifications {
            if verification.verificationScore < 0.3 {
                flags.append(.highlyDisputed)
            } else if verification.verificationScore < 0.6 {
                flags.append(.needsVerification)
            }
        }
        
        return flags
    }
}

struct FactCheckResult {
    let overallScore: Double
    let verifiedClaims: [ClaimVerification]
    let flags: [FactCheckFlag]
}

struct ClaimVerification {
    let claim: String
    let verificationScore: Double
    let sources: [String]
    let confidence: Double
}

enum FactCheckFlag {
    case highlyDisputed
    case needsVerification
    case unverifiable
    case contradictory
}
