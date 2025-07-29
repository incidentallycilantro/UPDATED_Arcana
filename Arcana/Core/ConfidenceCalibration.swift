//
// ConfidenceCalibration.swift
// Arcana
//

@MainActor
class ConfidenceCalibration: ObservableObject {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ConfidenceCalibration")
    private var calibrationHistory: [CalibrationPoint] = []
    
    func calibrateConfidence(
        for response: String,
        context: ConversationContext,
        ensembleData: [EnsembleResponse]
    ) async -> Double {
        
        // Base confidence from ensemble agreement
        let ensembleAgreement = calculateEnsembleAgreement(ensembleData)
        
        // Model performance weighting
        let performanceWeight = calculatePerformanceWeight(ensembleData)
        
        // Context relevance factor
        let contextRelevance = calculateContextRelevance(response, context: context)
        
        // Temporal confidence adjustment
        let temporalAdjustment = getTemporalConfidenceAdjustment(context)
        
        // Combined confidence score
        var confidence = (ensembleAgreement * 0.4) +
                        (performanceWeight * 0.3) +
                        (contextRelevance * 0.2) +
                        (temporalAdjustment * 0.1)
        
        // Apply historical calibration
        confidence = applyHistoricalCalibration(confidence, context: context)
        
        // Clamp to valid range
        confidence = max(0.0, min(1.0, confidence))
        
        // Record calibration point
        let point = CalibrationPoint(
            predictedConfidence: confidence,
            actualPerformance: 0.0, // Would be updated later with user feedback
            context: context,
            timestamp: Date()
        )
        calibrationHistory.append(point)
        
        logger.debug("Calibrated confidence: \(confidence)")
        return confidence
    }
    
    private func calculateEnsembleAgreement(_ responses: [EnsembleResponse]) -> Double {
        guard responses.count > 1 else { return responses.first?.confidence ?? 0.5 }
        
        // Calculate confidence variance
        let confidences = responses.map(\.confidence)
        let average = confidences.reduce(0, +) / Double(confidences.count)
        let variance = confidences.map { pow($0 - average, 2) }.reduce(0, +) / Double(confidences.count)
        
        // Lower variance = higher agreement = higher confidence
        return max(0.0, average - (variance * 0.5))
    }
    
    private func calculatePerformanceWeight(_ responses: [EnsembleResponse]) -> Double {
        let performanceScores = responses.map { response in
            response.model.performance.accuracyScore / response.processingTime
        }
        
        return performanceScores.reduce(0, +) / Double(max(performanceScores.count, 1))
    }
    
    private func calculateContextRelevance(_ response: String, context: ConversationContext) -> Double {
        // Simplified context relevance calculation
        let workspaceRelevance = getWorkspaceRelevance(response, workspaceType: context.workspaceType)
        let historyRelevance = getHistoryRelevance(response, context: context)
        
        return (workspaceRelevance + historyRelevance) / 2.0
    }
    
    private func getWorkspaceRelevance(_ response: String, workspaceType: WorkspaceType) -> Double {
        // Check if response contains workspace-relevant content
        switch workspaceType {
        case .code:
            return response.contains("```") || response.lowercased().contains("code") ? 0.9 : 0.6
        case .creative:
            return response.lowercased().contains("creative") || response.lowercased().contains("idea") ? 0.9 : 0.6
        case .research:
            return response.lowercased().contains("analysis") || response.lowercased().contains("research") ? 0.9 : 0.6
        case .general:
            return 0.8 // General responses are always moderately relevant
        }
    }
    
    private func getHistoryRelevance(_ response: String, context: ConversationContext) -> Double {
        // Check relevance to conversation history
        guard !context.recentMessages.isEmpty else { return 0.7 }
        
        let recentContent = context.recentMessages.map(\.content).joined(separator: " ")
        let sharedWords = Set(response.lowercased().components(separatedBy: .whitespacesAndNewlines))
            .intersection(Set(recentContent.lowercased().components(separatedBy: .whitespacesAndNewlines)))
        
        return min(1.0, Double(sharedWords.count) / 10.0 + 0.5)
    }
    
    private func getTemporalConfidenceAdjustment(_ context: ConversationContext) -> Double {
        guard let temporal = context.temporalContext else { return 0.8 }
        
        // Adjust confidence based on time context
        switch temporal.circadianPhase {
        case .peak: return 0.9
        case .active: return 0.8
        case .declining: return 0.7
        case .recovery: return 0.6
        }
    }
    
    private func applyHistoricalCalibration(_ rawConfidence: Double, context: ConversationContext) -> Double {
        // Apply learned calibration adjustments
        let relevantHistory = calibrationHistory.filter { point in
            point.context.workspaceType == context.workspaceType
        }.suffix(100) // Last 100 relevant points
        
        if relevantHistory.isEmpty {
            return rawConfidence
        }
        
        // Calculate historical bias
        let predictions = relevantHistory.map(\.predictedConfidence)
        let actuals = relevantHistory.map(\.actualPerformance)
        
        let avgPrediction = predictions.reduce(0, +) / Double(predictions.count)
        let avgActual = actuals.reduce(0, +) / Double(actuals.count)
        
        let bias = avgPrediction - avgActual
        
        // Adjust confidence to reduce bias
        return max(0.0, min(1.0, rawConfidence - (bias * 0.1)))
    }
}

struct CalibrationPoint {
    let predictedConfidence: Double
    var actualPerformance: Double
    let context: ConversationContext
    let timestamp: Date
}
