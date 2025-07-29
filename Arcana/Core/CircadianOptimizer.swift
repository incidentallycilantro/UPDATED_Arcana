//
// Core/CircadianOptimizer.swift
// Arcana
//

import Foundation
import OSLog

@MainActor
class CircadianOptimizer: ObservableObject {
    @Published var currentPhase: CircadianPhase = .active
    @Published var energyOptimization: Double = 0.8
    @Published var recommendedTaskTypes: [TaskType] = []
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "CircadianOptimizer")
    private var circadianHistory: [CircadianDataPoint] = []
    private var personalizedCurve: CircadianCurve?
    
    func initialize() async {
        logger.info("Initializing Circadian Optimizer...")
        
        await loadPersonalizedData()
        updateCurrentPhase()
        optimizeForCurrentTime()
        
        // Start background monitoring
        startCircadianMonitoring()
        
        logger.info("Circadian Optimizer initialized")
    }
    
    func optimizeResponseTiming(for message: String, context: ConversationContext) async -> ResponseOptimization {
        let currentHour = Calendar.current.component(.hour, from: Date())
        let energyLevel = calculateEnergyLevel(for: currentHour)
        let complexity = estimateTaskComplexity(message)
        
        let optimization = ResponseOptimization(
            shouldDelay: shouldDelayResponse(energyLevel: energyLevel, complexity: complexity),
            suggestedDelay: calculateOptimalDelay(energyLevel: energyLevel),
            energyBoost: suggestEnergyBoost(for: currentPhase),
            alternativeApproach: suggestAlternativeApproach(energyLevel: energyLevel, complexity: complexity)
        )
        
        logger.debug("Response optimization: delay=\(optimization.shouldDelay), energy=\(energyLevel)")
        return optimization
    }
    
    func getOptimalWorkTime() -> OptimalWorkPeriod {
        let now = Date()
        let calendar = Calendar.current
        
        // Get user's peak hours based on historical data
        let peakHours = personalizedCurve?.peakHours ?? [9, 10, 11, 14, 15, 16]
        
        let nextPeakTime = findNextOptimalTime(from: now, peakHours: peakHours)
        let currentEfficiency = calculateCurrentEfficiency()
        
        return OptimalWorkPeriod(
            nextPeakTime: nextPeakTime,
            currentEfficiency: currentEfficiency,
            suggestedBreakTime: calculateNextBreakTime(),
            optimalTaskTypes: getOptimalTasksForCurrentTime()
        )
    }
    
    private func loadPersonalizedData() async {
        // Load user's historical circadian data
        // This would read from secure local storage
        circadianHistory = []
        personalizedCurve = generateDefaultCurve()
        
        logger.debug("Loaded personalized circadian data")
    }
    
    private func updateCurrentPhase() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<9:
            currentPhase = .peak
        case 9..<12:
            currentPhase = .active
        case 12..<14:
            currentPhase = .declining
        case 14..<18:
            currentPhase = .active
        case 18..<22:
            currentPhase = .declining
        default:
            currentPhase = .recovery
        }
    }
    
    private func optimizeForCurrentTime() {
        let energyLevel = calculateEnergyLevel(for: Calendar.current.component(.hour, from: Date()))
        energyOptimization = energyLevel
        recommendedTaskTypes = getOptimalTasksForCurrentTime()
    }
    
    private func startCircadianMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCurrentPhase()
                self?.optimizeForCurrentTime()
                await self?.recordCircadianDataPoint()
            }
        }
    }
    
    private func calculateEnergyLevel(for hour: Int) -> Double {
        // Use personalized curve if available, otherwise default
        let curve = personalizedCurve ?? generateDefaultCurve()
        
        // Interpolate energy level for current hour
        let normalizedHour = Double(hour) / 24.0
        return curve.energyAtTime(normalizedHour)
    }
    
    private func generateDefaultCurve() -> CircadianCurve {
        // Default circadian rhythm curve
        let energyPoints: [Double] = [
            0.3, 0.2, 0.2, 0.2, 0.3, 0.4, // 0-5: Night/Early morning
            0.6, 0.8, 0.9, 0.95, 0.9, 0.8, // 6-11: Morning peak
            0.7, 0.5, 0.6, 0.8, 0.85, 0.8, // 12-17: Afternoon
            0.7, 0.6, 0.5, 0.4, 0.35, 0.3  // 18-23: Evening decline
        ]
        
        return CircadianCurve(energyPoints: energyPoints)
    }
    
    private func estimateTaskComplexity(_ message: String) -> TaskComplexity {
        let wordCount = message.components(separatedBy: .whitespacesAndNewlines).count
        let hasCodeKeywords = message.lowercased().contains("code") || message.contains("function")
        let hasAnalysisKeywords = message.lowercased().contains("analyze") || message.lowercased().contains("research")
        
        if wordCount > 50 || hasCodeKeywords || hasAnalysisKeywords {
            return .high
        } else if wordCount > 20 {
            return .medium
        } else {
            return .low
        }
    }
    
    private func shouldDelayResponse(energyLevel: Double, complexity: TaskComplexity) -> Bool {
        switch complexity {
        case .high:
            return energyLevel < 0.6
        case .medium:
            return energyLevel < 0.4
        case .low:
            return false
        }
    }
    
    private func calculateOptimalDelay(energyLevel: Double) -> TimeInterval {
        if energyLevel < 0.3 {
            return 300 // 5 minutes
        } else if energyLevel < 0.5 {
            return 120 // 2 minutes
        } else {
            return 0
        }
    }
    
    private func suggestEnergyBoost(for phase: CircadianPhase) -> String? {
        switch phase {
        case .declining:
            return "Consider taking a short break or having a healthy snack"
        case .recovery:
            return "This might be a good time for lighter tasks"
        case .peak, .active:
            return nil
        }
    }
    
    private func suggestAlternativeApproach(energyLevel: Double, complexity: TaskComplexity) -> String? {
        if energyLevel < 0.5 && complexity == .high {
            return "Consider breaking this into smaller, manageable tasks"
        }
        return nil
    }
    
    private func findNextOptimalTime(from date: Date, peakHours: [Int]) -> Date {
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: date)
        
        // Find next peak hour
        let nextPeakHour = peakHours.first { $0 > currentHour } ?? peakHours.first ?? 9
        
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = nextPeakHour
        components.minute = 0
        
        var nextPeak = calendar.date(from: components) ?? date
        
        // If it's in the past, move to next day
        if nextPeak <= date {
            nextPeak = calendar.date(byAdding: .day, value: 1, to: nextPeak) ?? date
        }
        
        return nextPeak
    }
    
    private func calculateCurrentEfficiency() -> Double {
        let currentEnergy = energyOptimization
        let timeOfDay = Calendar.current.component(.hour, from: Date())
        
        // Adjust efficiency based on time and personal patterns
        var efficiency = currentEnergy
        
        // Boost for peak hours
        if [9, 10, 11, 14, 15, 16].contains(timeOfDay) {
            efficiency *= 1.2
        }
        
        return min(1.0, efficiency)
    }
    
    private func calculateNextBreakTime() -> Date {
        let now = Date()
        let calendar = Calendar.current
        
        // Suggest break every 90 minutes during active periods
        return calendar.date(byAdding: .minute, value: 90, to: now) ?? now
    }
    
    private func getOptimalTasksForCurrentTime() -> [TaskType] {
        let hour = Calendar.current.component(.hour, from: Date())
        let energyLevel = calculateEnergyLevel(for: hour)
        
        if energyLevel > 0.8 {
            return [.creative, .analytical, .problemSolving]
        } else if energyLevel > 0.5 {
            return [.routine, .communication, .planning]
        } else {
            return [.reading, .organization, .reflection]
        }
    }
    
    private func recordCircadianDataPoint() async {
        let dataPoint = CircadianDataPoint(
            timestamp: Date(),
            energyLevel: energyOptimization,
            phase: currentPhase,
            taskTypes: recommendedTaskTypes
        )
        
        circadianHistory.append(dataPoint)
        
        // Keep only recent data (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        circadianHistory = circadianHistory.filter { $0.timestamp > thirtyDaysAgo }
        
        // Update personalized curve based on new data
        await updatePersonalizedCurve()
    }
    
    private func updatePersonalizedCurve() async {
        // Analyze historical data to refine personal circadian curve
        // This would implement machine learning to personalize the curve
        logger.debug("Updated personalized circadian curve")
    }
}

// MARK: - Supporting Types

struct ResponseOptimization {
    let shouldDelay: Bool
    let suggestedDelay: TimeInterval
    let energyBoost: String?
    let alternativeApproach: String?
}

struct OptimalWorkPeriod {
    let nextPeakTime: Date
    let currentEfficiency: Double
    let suggestedBreakTime: Date
    let optimalTaskTypes: [TaskType]
}

enum TaskComplexity {
    case low, medium, high
}

enum TaskType: String, CaseIterable {
    case creative = "creative"
    case analytical = "analytical"
    case problemSolving = "problemSolving"
    case routine = "routine"
    case communication = "communication"
    case planning = "planning"
    case reading = "reading"
    case organization = "organization"
    case reflection = "reflection"
}

struct CircadianDataPoint {
    let timestamp: Date
    let energyLevel: Double
    let phase: CircadianPhase
    let taskTypes: [TaskType]
}

struct CircadianCurve {
    let energyPoints: [Double]
    
    func energyAtTime(_ normalizedTime: Double) -> Double {
        let index = Int(normalizedTime * Double(energyPoints.count))
        let clampedIndex = max(0, min(energyPoints.count - 1, index))
        return energyPoints[clampedIndex]
    }
    
    var peakHours: [Int] {
        var peaks: [Int] = []
        for i in 0..<energyPoints.count {
            if energyPoints[i] > 0.8 {
                peaks.append(i)
            }
        }
        return peaks
    }
}
