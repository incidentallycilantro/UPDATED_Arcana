//
// ResponseFusionEngine.swift
// Arcana
//

@MainActor
class ResponseFusionEngine: ObservableObject {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ResponseFusion")
    
    func initialize() async throws {
        logger.info("Response Fusion Engine initialized")
    }
    
    func fuseResponses(_ responses: [EnsembleResponse], context: ConversationContext) async -> String {
        logger.debug("Fusing \(responses.count) ensemble responses")
        
        guard !responses.isEmpty else {
            return "I apologize, but I'm unable to generate a response at this time."
        }
        
        if responses.count == 1 {
            return responses.first!.response
        }
        
        // Weight responses by confidence and model performance
        let weightedResponses = responses.map { response in
            WeightedResponse(
                content: response.response,
                weight: calculateResponseWeight(response, context: context)
            )
        }.sorted { $0.weight > $1.weight }
        
        // Use the highest weighted response as base
        let primaryResponse = weightedResponses.first!.content
        
        // Enhance with insights from other responses
        let enhancedResponse = enhanceWithSecondaryInsights(
            primary: primaryResponse,
            secondary: Array(weightedResponses.dropFirst()),
            context: context
        )
        
        return enhancedResponse
    }
    
    private func calculateResponseWeight(_ response: EnsembleResponse, context: ConversationContext) -> Double {
        var weight = response.confidence
        
        // Boost weight for models optimal for workspace
        let optimalCapabilities = getOptimalCapabilities(for: context.workspaceType)
        let modelCapabilities = Set(response.model.capabilities)
        let overlap = modelCapabilities.intersection(optimalCapabilities)
        
        if !overlap.isEmpty {
            weight *= 1.2 // 20% boost for relevant capabilities
        }
        
        // Penalize slow responses
        if response.processingTime > 1.0 {
            weight *= 0.9
        }
        
        return weight
    }
    
    private func getOptimalCapabilities(for workspaceType: WorkspaceType) -> Set<ModelCapability> {
        switch workspaceType {
        case .code: return [.codeGeneration, .reasoning]
        case .creative: return [.creativity, .textGeneration]
        case .research: return [.analysis, .reasoning]
        case .general: return [.textGeneration, .reasoning]
        }
    }
    
    private func enhanceWithSecondaryInsights(
        primary: String,
        secondary: [WeightedResponse],
        context: ConversationContext
    ) -> String {
        guard !secondary.isEmpty else { return primary }
        
        var enhanced = primary
        
        // Add valuable insights from secondary responses
        let additionalInsights = extractUniqueInsights(
            primary: primary,
            secondary: secondary.map(\.content)
        )
        
        if !additionalInsights.isEmpty {
            enhanced += "\n\nAdditional considerations:\n"
            for insight in additionalInsights.prefix(2) {
                enhanced += "• \(insight)\n"
            }
        }
        
        return enhanced
    }
    
    private func extractUniqueInsights(primary: String, secondary: [String]) -> [String] {
        // Simplified insight extraction
        var insights: [String] = []
        
        for response in secondary {
            let sentences = response.components(separatedBy: ". ")
            for sentence in sentences {
                if !primary.contains(sentence) && sentence.count > 20 {
                    insights.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
                }
            }
        }
        
        return Array(insights.prefix(3))
    }
}

struct WeightedResponse {
    let content: String
    let weight: Double
}
