//
// Core/ContextualAdaptation.swift
// Arcana
//

import Foundation
import OSLog

@MainActor
class ContextualAdaptation: ObservableObject {
    @Published var currentSeason: Season = Season()
    @Published var dayOfWeek: DayOfWeek = DayOfWeek()
    @Published var contextualSuggestions: [String] = []
    @Published var adaptationScore: Double = 0.85
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "ContextualAdaptation")
    private var adaptationHistory: [AdaptationRecord] = []
    private var seasonalPatterns: [Season: SeasonalPattern] = [:]
    private var weeklyPatterns: [DayOfWeek: WeeklyPattern] = [:]
    
    func initialize() async {
        logger.info("Initializing Contextual Adaptation...")
        
        updateCurrentContext()
        await loadAdaptationPatterns()
        generateContextualSuggestions()
        
        // Start background context monitoring
        startContextMonitoring()
        
        logger.info("Contextual Adaptation initialized")
    }
    
    func adaptResponse(_ response: String, context: ConversationContext) async -> String {
        logger.debug("Adapting response for current context")
        
        var adaptedResponse = response
        
        // Apply seasonal adaptation
        adaptedResponse = applySeasonalContext(to: adaptedResponse)
        
        // Apply day-of-week adaptation
        adaptedResponse = applyWeeklyContext(to: adaptedResponse)
        
        // Apply time-of-day adaptation
        adaptedResponse = applyTimeContext(to: adaptedResponse)
        
        // Apply weather awareness (if available)
        adaptedResponse = await applyWeatherContext(to: adaptedResponse)
        
        // Record adaptation
        await recordAdaptation(original: response, adapted: adaptedResponse, context: context)
        
        return adaptedResponse
    }
    
    func getContextualPrompts(for workspaceType: WorkspaceType) -> [ContextualPrompt] {
        var prompts: [ContextualPrompt] = []
        
        // Seasonal prompts
        prompts.append(contentsOf: getSeasonalPrompts(for: workspaceType))
        
        // Weekly prompts
        prompts.append(contentsOf: getWeeklyPrompts(for: workspaceType))
        
        // Time-based prompts
        prompts.append(contentsOf: getTimeBasedPrompts(for: workspaceType))
        
        return Array(prompts.prefix(5))
    }
    
    private func updateCurrentContext() {
        currentSeason = Season()
        dayOfWeek = DayOfWeek()
        
        logger.debug("Updated context: \(currentSeason.rawValue), \(dayOfWeek.rawValue)")
    }
    
    private func loadAdaptationPatterns() async {
        // Load learned adaptation patterns
        seasonalPatterns = generateDefaultSeasonalPatterns()
        weeklyPatterns = generateDefaultWeeklyPatterns()
        
        logger.debug("Loaded adaptation patterns")
    }
    
    private func generateContextualSuggestions() {
        var suggestions: [String] = []
        
        // Seasonal suggestions
        switch currentSeason {
        case .spring:
            suggestions.append("Perfect time for new projects and fresh starts!")
        case .summer:
            suggestions.append("Great weather for outdoor inspiration and energy.")
        case .autumn:
            suggestions.append("Ideal season for reflection and preparation.")
        case .winter:
            suggestions.append("Cozy time for deep focus and planning.")
        }
        
        // Weekly suggestions
        switch dayOfWeek {
        case .monday:
            suggestions.append("Start the week with clear goals and priorities.")
        case .friday:
            suggestions.append("Wrap up the week and prepare for relaxation.")
        case .saturday, .sunday:
            suggestions.append("Weekend time for personal projects and exploration.")
        default:
            suggestions.append("Maintain momentum and stay productive.")
        }
        
        contextualSuggestions = suggestions
    }
    
    private func startContextMonitoring() {
        // Update context every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateCurrentContext()
                self?.generateContextualSuggestions()
            }
        }
    }
    
    private func applySeasonalContext(to response: String) -> String {
        guard let pattern = seasonalPatterns[currentSeason] else { return response }
        
        var adapted = response
        
        // Add seasonal awareness
        if shouldAddSeasonalContext(to: response) {
            adapted += "\n\n\(pattern.contextualNote)"
        }
        
        return adapted
    }
    
    private func applyWeeklyContext(to response: String) -> String {
        guard let pattern = weeklyPatterns[dayOfWeek] else { return response }
        
        var adapted = response
        
        // Add day-specific context
        if shouldAddWeeklyContext(to: response) {
            adapted += pattern.enhancementSuffix
        }
        
        return adapted
    }
    
    private func applyTimeContext(to response: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeContext = getTimeContextualNote(for: hour)
        
        if !timeContext.isEmpty && shouldAddTimeContext(to: response) {
            return response + " " + timeContext
        }
        
        return response
    }
    
    private func applyWeatherContext(to response: String) async -> String {
        // Simulate weather awareness (would integrate with weather API)
        let weatherContext = getSimulatedWeatherContext()
        
        if !weatherContext.isEmpty && shouldAddWeatherContext(to: response) {
            return response + " " + weatherContext
        }
        
        return response
    }
    
    private func shouldAddSeasonalContext(to response: String) -> Bool {
        let keywords = ["project", "plan", "start", "begin", "new", "create"]
        return keywords.contains { response.lowercased().contains($0) }
    }
    
    private func shouldAddWeeklyContext(to response: String) -> Bool {
        let keywords = ["week", "plan", "schedule", "goal", "deadline"]
        return keywords.contains { response.lowercased().contains($0) }
    }
    
    private func shouldAddTimeContext(to response: String) -> Bool {
        let keywords = ["now", "today", "currently", "time"]
        return keywords.contains { response.lowercased().contains($0) }
    }
    
    private func shouldAddWeatherContext(to response: String) -> Bool {
        let keywords = ["outside", "mood", "energy", "inspiration", "outdoor"]
        return keywords.contains { response.lowercased().contains($0) }
    }
    
    private func getTimeContextualNote(for hour: Int) -> String {
        switch hour {
        case 6..<9:
            return "Starting your day early is a great approach!"
        case 9..<12:
            return "Perfect timing for focused morning work."
        case 12..<14:
            return "Good time for a break and reflection."
        case 14..<17:
            return "Afternoon energy is great for collaborative tasks."
        case 17..<20:
            return "Evening time for wrapping up and planning ahead."
        case 20..<23:
            return "Evening hours are perfect for personal projects."
        default:
            return ""
        }
    }
    
    private func getSimulatedWeatherContext() -> String {
        // Simulate weather context (would use actual weather data)
        let contexts = [
            "The clear weather today is perfect for focused thinking.",
            "Rainy days are great for indoor creativity.",
            "Sunny weather can boost energy and motivation.",
            ""
        ]
        
        return contexts.randomElement() ?? ""
    }
    
    private func getSeasonalPrompts(for workspaceType: WorkspaceType) -> [ContextualPrompt] {
        switch (currentSeason, workspaceType) {
        case (.spring, .creative):
            return [ContextualPrompt(text: "Spring inspiration for new creative projects", priority: .high)]
        case (.summer, .research):
            return [ContextualPrompt(text: "Summer reading and research opportunities", priority: .medium)]
        case (.autumn, .code):
            return [ContextualPrompt(text: "Autumn is perfect for organizing and refactoring code", priority: .medium)]
        case (.winter, .general):
            return [ContextualPrompt(text: "Winter planning and goal setting", priority: .high)]
        default:
            return []
        }
    }
    
    private func getWeeklyPrompts(for workspaceType: WorkspaceType) -> [ContextualPrompt] {
        switch (dayOfWeek, workspaceType) {
        case (.monday, _):
            return [ContextualPrompt(text: "Monday motivation: Set clear weekly objectives", priority: .high)]
        case (.friday, _):
            return [ContextualPrompt(text: "Friday wrap-up: Review achievements and plan ahead", priority: .medium)]
        case (.saturday, .creative), (.sunday, .creative):
            return [ContextualPrompt(text: "Weekend creativity: Explore personal projects", priority: .medium)]
        default:
            return []
        }
    }
    
    private func getTimeBasedPrompts(for workspaceType: WorkspaceType) -> [ContextualPrompt] {
        let hour = Calendar.current.component(.hour, from: Date())
        
        switch hour {
        case 6..<9:
            return [ContextualPrompt(text: "Morning clarity: Start with your most important task", priority: .high)]
        case 14..<16:
            return [ContextualPrompt(text: "Afternoon focus: Great time for collaborative work", priority: .medium)]
        case 20..<22:
            return [ContextualPrompt(text: "Evening reflection: Review and plan tomorrow", priority: .low)]
        default:
            return []
        }
    }
    
    private func generateDefaultSeasonalPatterns() -> [Season: SeasonalPattern] {
        return [
            .spring: SeasonalPattern(
                contextualNote: "Spring energy brings fresh perspectives and new possibilities.",
                moodInfluence: .energetic,
                suggestedActivities: ["start new projects", "brainstorm ideas", "plan goals"]
            ),
            .summer: SeasonalPattern(
                contextualNote: "Summer's longer days provide extended time for productivity.",
                moodInfluence: .optimistic,
                suggestedActivities: ["outdoor inspiration", "collaborate", "network"]
            ),
            .autumn: SeasonalPattern(
                contextualNote: "Autumn is perfect for harvesting the results of your hard work.",
                moodInfluence: .reflective,
                suggestedActivities: ["organize", "review progress", "prepare for winter"]
            ),
            .winter: SeasonalPattern(
                contextualNote: "Winter's introspective energy is ideal for deep focus and planning.",
                moodInfluence: .contemplative,
                suggestedActivities: ["plan ahead", "deep work", "skill development"]
            )
        ]
    }
    
    private func generateDefaultWeeklyPatterns() -> [DayOfWeek: WeeklyPattern] {
        return [
            .monday: WeeklyPattern(enhancementSuffix: " Starting the week strong!", energy: .high),
            .tuesday: WeeklyPattern(enhancementSuffix: " Tuesday momentum is building!", energy: .high),
            .wednesday: WeeklyPattern(enhancementSuffix: " Mid-week focus is key!", energy: .medium),
            .thursday: WeeklyPattern(enhancementSuffix: " Thursday productivity is peak!", energy: .high),
            .friday: WeeklyPattern(enhancementSuffix: " Finishing the week well!", energy: .medium),
            .saturday: WeeklyPattern(enhancementSuffix: " Saturday freedom for exploration!", energy: .relaxed),
            .sunday: WeeklyPattern(enhancementSuffix: " Sunday planning for success!", energy: .reflective)
        ]
    }
    
    private func recordAdaptation(original: String, adapted: String, context: ConversationContext) async {
        let record = AdaptationRecord(
            timestamp: Date(),
            original: original,
            adapted: adapted,
            season: currentSeason,
            dayOfWeek: dayOfWeek,
            workspaceType: context.workspaceType,
            improvementScore: calculateImprovementScore(original: original, adapted: adapted)
        )
        
        adaptationHistory.append(record)
        
        // Keep only recent records
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        adaptationHistory = adaptationHistory.filter { $0.timestamp > weekAgo }
        
        // Update adaptation score
        updateAdaptationScore()
    }
    
    private func calculateImprovementScore(original: String, adapted: String) -> Double {
        // Simple improvement score based on length and contextual additions
        let improvement = Double(adapted.count - original.count) / Double(original.count)
        return max(0.0, min(1.0, improvement))
    }
    
    private func updateAdaptationScore() {
        let recentScores = adaptationHistory.suffix(20).map(\.improvementScore)
        adaptationScore = recentScores.reduce(0, +) / Double(max(recentScores.count, 1))
    }
}

// MARK: - Supporting Types

struct ContextualPrompt {
    let text: String
    let priority: PromptPriority
}

enum PromptPriority {
    case low, medium, high
}

struct SeasonalPattern {
    let contextualNote: String
    let moodInfluence: MoodInfluence
    let suggestedActivities: [String]
}

struct WeeklyPattern {
    let enhancementSuffix: String
    let energy: EnergyLevel
}

enum MoodInfluence {
    case energetic, optimistic, reflective, contemplative
}

enum EnergyLevel {
    case low, medium, high, relaxed, reflective
}

struct AdaptationRecord {
    let timestamp: Date
    let original: String
    let adapted: String
    let season: Season
    let dayOfWeek: DayOfWeek
    let workspaceType: WorkspaceType
    let improvementScore: Double
}
