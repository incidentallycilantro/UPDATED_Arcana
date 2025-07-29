//
// IntelligentModelRouter.swift
// Arcana
//

@MainActor
class IntelligentModelRouter: ObservableObject {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ModelRouter")
    private var routingHistory: [RoutingDecision] = []
    
    func initialize() async throws {
        logger.info("Intelligent Model Router initialized")
    }
    
    func selectOptimalModels(for message: String, context: ConversationContext, availableModels: [ModelInfo]) async -> [ModelInfo] {
        logger.debug("Selecting optimal models for workspace: \(context.workspaceType)")
        
        let workspaceOptimized = getOptimalModelsForWorkspace(context.workspaceType)
        let filtered = availableModels.filter { model in
            workspaceOptimized.contains { $0.id == model.id }
        }
        
        // Record routing decision
        let decision = RoutingDecision(
            message: message,
            context: context,
            selectedModels: filtered,
            timestamp: Date()
        )
        routingHistory.append(decision)
        
        return Array(filtered.prefix(3)) // Max 3 models for ensemble
    }
    
    func getOptimalModelsForWorkspace(_ workspaceType: WorkspaceType) -> [ModelInfo] {
        let allModels = getAllAvailableModels()
        
        switch workspaceType {
        case .code:
            return allModels.filter { $0.capabilities.contains(.codeGeneration) }
        case .creative:
            return allModels.filter { $0.capabilities.contains(.creativity) }
        case .research:
            return allModels.filter { $0.capabilities.contains(.analysis) }
        case .general:
            return allModels.filter { $0.capabilities.contains(.textGeneration) }
        }
    }
    
    func getAlternativeModels(for context: ConversationContext, avoiding: [String]) async -> [ModelInfo] {
        let optimal = getOptimalModelsForWorkspace(context.workspaceType)
        return optimal.filter { !avoiding.contains($0.name) }
    }
    
    private func getAllAvailableModels() -> [ModelInfo] {
        return [
            ModelInfo(
                name: "CodeLlama-7B",
                version: "1.0",
                size: 7_000_000_000,
                capabilities: [.codeGeneration, .reasoning],
                performance: ModelPerformance(
                    averageInferenceTime: 0.5,
                    tokensPerSecond: 50,
                    accuracyScore: 0.92,
                    memoryUsage: 4_000_000_000,
                    powerEfficiency: 0.8
                )
            ),
            ModelInfo(
                name: "Mistral-7B",
                version: "0.1",
                size: 7_000_000_000,
                capabilities: [.textGeneration, .reasoning, .analysis, .creativity],
                performance: ModelPerformance(
                    averageInferenceTime: 0.4,
                    tokensPerSecond: 60,
                    accuracyScore: 0.90,
                    memoryUsage: 3_800_000_000,
                    powerEfficiency: 0.85
                )
            ),
            ModelInfo(
                name: "Phi-2",
                version: "2.0",
                size: 2_700_000_000,
                capabilities: [.textGeneration, .reasoning],
                performance: ModelPerformance(
                    averageInferenceTime: 0.2,
                    tokensPerSecond: 100,
                    accuracyScore: 0.88,
                    memoryUsage: 2_000_000_000,
                    powerEfficiency: 0.95
                )
            )
        ]
    }
}

struct RoutingDecision {
    let message: String
    let context: ConversationContext
    let selectedModels: [ModelInfo]
    let timestamp: Date
}
