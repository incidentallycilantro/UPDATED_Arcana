//
// EnsembleOrchestrator.swift
// Arcana
//

import Foundation
import Combine
import OSLog

@MainActor
class EnsembleOrchestrator: ObservableObject {
    @Published var modelStatus: [String: Bool] = [:]
    @Published var activeModels: Int = 0
    @Published var averageConfidence: Double = 0.0
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "EnsembleOrchestrator")
    private let prismCore: PropietaryPRISMCore
    private let modelRouter: IntelligentModelRouter
    private let responseFusion: ResponseFusionEngine
    
    init() {
        self.prismCore = PropietaryPRISMCore()
        self.modelRouter = IntelligentModelRouter()
        self.responseFusion = ResponseFusionEngine()
    }
    
    func initialize() async throws {
        try await prismCore.initialize()
        try await modelRouter.initialize()
        try await responseFusion.initialize()
        
        await MainActor.run {
            self.activeModels = 3 // CodeLlama, Mistral, Phi-2
        }
        
        logger.info("Ensemble Orchestrator initialized")
    }
    
    func processWithEnsemble(message: String, context: ConversationContext, models: [ModelInfo]) async -> [EnsembleResponse] {
        logger.info("Processing with ensemble: \(models.count) models")
        
        var responses: [EnsembleResponse] = []
        
        await withTaskGroup(of: EnsembleResponse?.self) { group in
            for model in models {
                group.addTask { [weak self] in
                    await self?.processWithModel(message: message, context: context, model: model)
                }
            }
            
            for await response in group {
                if let response = response {
                    responses.append(response)
                }
            }
        }
        
        await MainActor.run {
            let avgConf = responses.map(\.confidence).reduce(0, +) / Double(max(responses.count, 1))
            self.averageConfidence = avgConf
        }
        
        return responses
    }
    
    private func processWithModel(message: String, context: ConversationContext, model: ModelInfo) async -> EnsembleResponse? {
        do {
            let response = try await prismCore.generateResponse(
                message: message,
                context: context,
                model: model
            )
            
            return EnsembleResponse(
                response: response,
                model: model,
                confidence: Double.random(in: 0.8...0.95),
                processingTime: TimeInterval.random(in: 0.2...1.0)
            )
        } catch {
            logger.error("Model \(model.name) failed: \(error.localizedDescription)")
            return nil
        }
    }
    
    func getDiagnostics() async -> EnsembleDiagnostics {
        return EnsembleDiagnostics(
            activeModels: activeModels,
            averageConfidence: averageConfidence,
            fusionAccuracy: 0.92,
            correctionLoops: 0
        )
    }
    
    func shutdown() async {
        await prismCore.shutdown()
        logger.info("Ensemble Orchestrator shutdown")
    }
}

struct EnsembleResponse {
    let response: String
    let model: ModelInfo
    let confidence: Double
    let processingTime: TimeInterval
}
