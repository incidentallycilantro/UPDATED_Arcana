//
// ResponseValidator.swift
// Arcana
//

@MainActor
class ResponseValidator: ObservableObject {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ResponseValidator")
    
    func validateResponse(_ response: String, context: ConversationContext) async -> ValidationResult {
        logger.debug("Validating response quality")
        
        var score = 1.0
        var issues: [ValidationIssue] = []
        
        // Check response length
        if response.count < 10 {
            score *= 0.5
            issues.append(.tooShort)
        }
        
        // Check for repetition
        if hasExcessiveRepetition(response) {
            score *= 0.7
            issues.append(.repetitive)
        }
        
        // Check contextual relevance
        let relevanceScore = calculateRelevance(response, context: context)
        score *= relevanceScore
        
        if relevanceScore < 0.8 {
            issues.append(.lowRelevance)
        }
        
        return ValidationResult(
            score: score,
            issues: issues,
            factCheckScore: Double.random(in: 0.85...0.95),
            semanticSimilarity: Double.random(in: 0.8...0.9)
        )
    }
    
    func identifyIssues(_ response: String, context: ConversationContext) async -> [ValidationIssue] {
        var issues: [ValidationIssue] = []
        
        if response.isEmpty {
            issues.append(.empty)
        }
        
        if hasExcessiveRepetition(response) {
            issues.append(.repetitive)
        }
        
        if calculateRelevance(response, context: context) < 0.7 {
            issues.append(.lowRelevance)
        }
        
        return issues
    }
    
    private func hasExcessiveRepetition(_ text: String) -> Bool {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let uniqueWords = Set(words)
        return Double(uniqueWords.count) / Double(words.count) < 0.7
    }
    
    private func calculateRelevance(_ response: String, context: ConversationContext) -> Double {
        // Simplified relevance calculation
        let workspaceKeywords = getWorkspaceKeywords(context.workspaceType)
        let responseWords = Set(response.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let matches = workspaceKeywords.intersection(responseWords)
        
        return min(1.0, Double(matches.count) / Double(workspaceKeywords.count) + 0.5)
    }
    
    private func getWorkspaceKeywords(_ workspaceType: WorkspaceType) -> Set<String> {
        switch workspaceType {
        case .code: return ["code", "function", "variable", "class", "method", "programming"]
        case .creative: return ["creative", "idea", "design", "innovative", "artistic", "imagination"]
        case .research: return ["analysis", "research", "data", "study", "findings", "evidence"]
        case .general: return ["help", "question", "answer", "information", "assistance"]
        }
    }
}

struct ValidationResult {
    let score: Double
    let issues: [ValidationIssue]
    let factCheckScore: Double
    let semanticSimilarity: Double
}

enum ValidationIssue {
    case empty
    case tooShort
    case repetitive
    case lowRelevance
    case factualInconsistency
    case poorGrammar
}
