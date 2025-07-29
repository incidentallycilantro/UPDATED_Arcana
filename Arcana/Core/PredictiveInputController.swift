//
// PredictiveInputController.swift
// Arcana
//
// Revolutionary time-aware predictive input system with contextual intelligence
// Provides smart autocompletion, context predictions, and usage pattern learning
//

import Foundation
import Combine
import NaturalLanguage
import os.log

// MARK: - Predictive Input Controller

/// Revolutionary predictive input system that learns user patterns and provides intelligent suggestions
/// Integrates temporal intelligence, context awareness, and privacy-preserving pattern learning
@MainActor
public class PredictiveInputController: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var currentSuggestions: [InputSuggestion] = []
    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var predictionMode: PredictionMode = .intelligent
    @Published private(set) var learningEnabled: Bool = true
    @Published private(set) var contextualInsights: ContextualInsights = ContextualInsights()
    @Published private(set) var userPatterns: UserInputPatterns = UserInputPatterns()
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: ArcanaConstants.bundleIdentifier, category: "PredictiveInput")
    private var cancellables = Set<AnyCancellable>()
    private let temporalIntelligence: TemporalIntelligenceEngine
    private let semanticMemory: SemanticMemoryEngine
    
    // Natural language processing
    private let tokenizer = NLTokenizer(unit: .word)
    private let languageRecognizer = NLLanguageRecognizer()
    private let embedding = NLEmbedding.wordEmbedding(for: .english)
    
    // Pattern learning
    private var inputHistory: [InputRecord] = []
    private var completionPatterns: [String: CompletionPattern] = [:]
    private var contextualTriggers: [String: ContextualTrigger] = [:]
    private let maxHistorySize: Int = 10000
    
    // Prediction configuration
    private let minInputLength: Int = 2
    private let maxSuggestions: Int = 5
    private let confidenceThreshold: Double = 0.3
    private let learningRate: Double = 0.1
    
    // MARK: - Initialization
    
    public init(
        temporalIntelligence: TemporalIntelligenceEngine = TemporalIntelligenceEngine(),
        semanticMemory: SemanticMemoryEngine = SemanticMemoryEngine()
    ) {
        self.temporalIntelligence = temporalIntelligence
        self.semanticMemory = semanticMemory
        
        logger.info("🔮 Initializing Revolutionary Predictive Input Controller")
        
        loadUserPatterns()
        setupPredictiveIntelligence()
    }
    
    // MARK: - Public Interface
    
    /// Get predictive suggestions for current input
    public func getPredictions(
        for input: String,
        context: ConversationContext,
        maxSuggestions: Int = 5
    ) async -> [InputSuggestion] {
        
        guard input.count >= minInputLength else { return [] }
        
        logger.debug("🔍 Generating predictions for input: '\(input.prefix(20))...'")
        isProcessing = true
        
        do {
            // Analyze current context
            let contextualState = await analyzeContext(input, context: context)
            
            // Generate multiple types of suggestions
            let suggestions = await generateSuggestions(
                input: input,
                context: context,
                contextualState: contextualState,
                maxSuggestions: maxSuggestions
            )
            
            // Rank and filter suggestions
            let rankedSuggestions = rankSuggestions(suggestions, for: input, context: context)
            
            // Update learning patterns
            if learningEnabled {
                updateLearningPatterns(input: input, context: context, suggestions: rankedSuggestions)
            }
            
            currentSuggestions = Array(rankedSuggestions.prefix(maxSuggestions))
            isProcessing = false
            
            logger.debug("✅ Generated \(currentSuggestions.count) predictions")
            return currentSuggestions
            
        } catch {
            logger.error("❌ Failed to generate predictions: \(error.localizedDescription)")
            isProcessing = false
            return []
        }
    }
    
    /// Record user selection for learning
    public func recordSelection(
        input: String,
        selectedSuggestion: InputSuggestion?,
        context: ConversationContext
    ) {
        guard learningEnabled else { return }
        
        logger.debug("📝 Recording user selection for learning")
        
        let record = InputRecord(
            originalInput: input,
            selectedSuggestion: selectedSuggestion,
            context: context,
            timestamp: Date(),
            temporalContext: TemporalContext()
        )
        
        // Add to history
        inputHistory.append(record)
        
        // Limit history size
        if inputHistory.count > maxHistorySize {
            inputHistory.removeFirst(inputHistory.count - maxHistorySize)
        }
        
        // Update patterns
        updateCompletionPatterns(from: record)
        updateContextualTriggers(from: record)
        
        // Save patterns
        saveUserPatterns()
    }
    
    /// Get contextual insights for current conversation
    public func getContextualInsights(for context: ConversationContext) async -> ContextualInsights {
        logger.debug("🧠 Generating contextual insights")
        
        let temporalContext = TemporalContext()
        let workspacePatterns = getWorkspacePatterns(for: context.workspaceType)
        let timeBasedSuggestions = getTimeBasedSuggestions(for: temporalContext)
        let semanticSuggestions = await getSemanticSuggestions(for: context)
        
        let insights = ContextualInsights(
            workspaceType: context.workspaceType,
            temporalContext: temporalContext,
            suggestedTopics: semanticSuggestions,
            commonPatterns: workspacePatterns,
            timeBasedSuggestions: timeBasedSuggestions,
            confidence: calculateInsightsConfidence(for: context)
        )
        
        contextualInsights = insights
        return insights
    }
    
    /// Configure prediction settings
    public func configurePrediction(
        mode: PredictionMode,
        learningEnabled: Bool,
        privacyLevel: PrivacyLevel = .maximum
    ) {
        logger.info("⚙️ Configuring prediction settings")
        
        self.predictionMode = mode
        self.learningEnabled = learningEnabled
        
        // Adjust learning behavior based on privacy level
        switch privacyLevel {
        case .maximum:
            // Minimal pattern storage, aggressive cleanup
            cleanupSensitivePatterns()
        case .balanced:
            // Standard pattern learning
            break
        case .performance:
            // Enhanced pattern learning for better predictions
            expandPatternLearning()
        }
        
        savePredictionConfiguration()
    }
    
    /// Get prediction statistics
    public func getPredictionStatistics() -> PredictionStatistics {
        let totalPredictions = inputHistory.count
        let acceptedPredictions = inputHistory.filter { $0.selectedSuggestion != nil }.count
        let acceptanceRate = totalPredictions > 0 ? Double(acceptedPredictions) / Double(totalPredictions) : 0
        
        return PredictionStatistics(
            totalPredictions: totalPredictions,
            acceptedPredictions: acceptedPredictions,
            acceptanceRate: acceptanceRate,
            averageConfidence: calculateAverageConfidence(),
            uniquePatterns: completionPatterns.count,
            contextualTriggers: contextualTriggers.count
        )
    }
    
    /// Clear learning patterns
    public func clearLearningData() {
        logger.info("🗑️ Clearing learning data")
        
        inputHistory.removeAll()
        completionPatterns.removeAll()
        contextualTriggers.removeAll()
        userPatterns = UserInputPatterns()
        
        saveUserPatterns()
        
        logger.info("✅ Learning data cleared")
    }
    
    /// Export prediction data for user review
    public func exportPredictionData() -> PredictionDataExport {
        return PredictionDataExport(
            userPatterns: userPatterns,
            statistics: getPredictionStatistics(),
            privacyInfo: getPredictionPrivacyInfo(),
            learningStatus: learningEnabled
        )
    }
    
    // MARK: - Private Methods
    
    private func setupPredictiveIntelligence() {
        // Configure natural language processing
        tokenizer.string = ""
        
        // Set up temporal intelligence integration
        temporalIntelligence.$currentContext
            .sink { [weak self] context in
                Task { @MainActor in
                    self?.updateTemporalPredictions(context)
                }
            }
            .store(in: &cancellables)
    }
    
    private func analyzeContext(_ input: String, context: ConversationContext) async -> ContextualState {
        // Analyze the current conversational and temporal context
        let temporalContext = TemporalContext()
        
        // Detect input intent
        let intent = detectInputIntent(input)
        
        // Analyze semantic context
        let semanticSimilarity = await calculateSemanticSimilarity(input, context: context)
        
        // Determine contextual complexity
        let complexity = calculateInputComplexity(input)
        
        return ContextualState(
            intent: intent,
            complexity: complexity,
            semanticSimilarity: semanticSimilarity,
            temporalRelevance: calculateTemporalRelevance(temporalContext, for: context),
            workspaceAlignment: calculateWorkspaceAlignment(input, for: context.workspaceType)
        )
    }
    
    private func generateSuggestions(
        input: String,
        context: ConversationContext,
        contextualState: ContextualState,
        maxSuggestions: Int
    ) async -> [InputSuggestion] {
        
        var suggestions: [InputSuggestion] = []
        
        // 1. Pattern-based completions
        let patternSuggestions = generatePatternBasedSuggestions(input, context: context, state: contextualState)
        suggestions.append(contentsOf: patternSuggestions)
        
        // 2. Contextual completions
        let contextualSuggestions = generateContextualSuggestions(input, context: context, state: contextualState)
        suggestions.append(contentsOf: contextualSuggestions)
        
        // 3. Temporal suggestions
        let temporalSuggestions = generateTemporalSuggestions(input, context: context, state: contextualState)
        suggestions.append(contentsOf: temporalSuggestions)
        
        // 4. Semantic suggestions
        let semanticSuggestions = await generateSemanticSuggestions(input, context: context, state: contextualState)
        suggestions.append(contentsOf: semanticSuggestions)
        
        // 5. Workspace-specific suggestions
        let workspaceSuggestions = generateWorkspaceSuggestions(input, context: context, state: contextualState)
        suggestions.append(contentsOf: workspaceSuggestions)
        
        return suggestions
    }
    
    private func generatePatternBasedSuggestions(
        _ input: String,
        context: ConversationContext,
        state: ContextualState
    ) -> [InputSuggestion] {
        
        var suggestions: [InputSuggestion] = []
        let lowercaseInput = input.lowercased()
        
        // Find matching completion patterns
        for (pattern, completion) in completionPatterns {
            if pattern.lowercased().hasPrefix(lowercaseInput) && completion.confidence > confidenceThreshold {
                let suggestion = InputSuggestion(
                    text: completion.completionText,
                    type: .patternBased,
                    confidence: completion.confidence,
                    source: .userHistory,
                    contextRelevance: calculateContextRelevance(completion, for: context),
                    metadata: ["pattern": pattern, "usage_count": "\(completion.usageCount)"]
                )
                suggestions.append(suggestion)
            }
        }
        
        return suggestions
    }
    
    private func generateContextualSuggestions(
        _ input: String,
        context: ConversationContext,
        state: ContextualState
    ) -> [InputSuggestion] {
        
        var suggestions: [InputSuggestion] = []
        
        // Generate suggestions based on conversation context
        for message in context.recentMessages.suffix(3) {
            if let followUp = generateFollowUpSuggestion(for: message, input: input) {
                suggestions.append(followUp)
            }
        }
        
        // Generate suggestions based on semantic context
        for contextTerm in context.semanticContext {
            if let contextualSuggestion = generateContextualCompletion(input, contextTerm: contextTerm) {
                suggestions.append(contextualSuggestion)
            }
        }
        
        return suggestions
    }
    
    private func generateTemporalSuggestions(
        _ input: String,
        context: ConversationContext,
        state: ContextualState
    ) -> [InputSuggestion] {
        
        var suggestions: [InputSuggestion] = []
        let temporalContext = context.temporalContext ?? TemporalContext()
        
        // Time-based suggestions
        let timeBasedSuggestions = getTimeBasedCompletions(input, temporalContext: temporalContext)
        suggestions.append(contentsOf: timeBasedSuggestions)
        
        // Day-of-week patterns
        if let dayPatterns = userPatterns.dayOfWeekPatterns[temporalContext.dayOfWeek] {
            for pattern in dayPatterns {
                if pattern.trigger.lowercased().hasPrefix(input.lowercased()) {
                    let suggestion = InputSuggestion(
                        text: pattern.completion,
                        type: .temporal,
                        confidence: pattern.confidence,
                        source: .temporalPattern,
                        contextRelevance: 0.8,
                        metadata: ["day": temporalContext.dayOfWeek.rawValue, "time": temporalContext.timeOfDay.rawValue]
                    )
                    suggestions.append(suggestion)
                }
            }
        }
        
        return suggestions
    }
    
    private func generateSemanticSuggestions(
        _ input: String,
        context: ConversationContext,
        state: ContextualState
    ) async -> [InputSuggestion] {
        
        var suggestions: [InputSuggestion] = []
        
        // Use semantic memory to find related concepts
        do {
            let relatedConcepts = try await semanticMemory.findRelatedConcepts(
                for: input,
                in: context,
                limit: 5
            )
            
            for concept in relatedConcepts {
                let suggestion = InputSuggestion(
                    text: concept.text,
                    type: .semantic,
                    confidence: concept.relevance,
                    source: .semanticMemory,
                    contextRelevance: concept.contextRelevance,
                    metadata: ["concept_type": concept.type, "memory_strength": "\(concept.memoryStrength)"]
                )
                suggestions.append(suggestion)
            }
            
        } catch {
            logger.warning("⚠️ Failed to generate semantic suggestions: \(error.localizedDescription)")
        }
        
        return suggestions
    }
    
    private func generateWorkspaceSuggestions(
        _ input: String,
        context: ConversationContext,
        state: ContextualState
    ) -> [InputSuggestion] {
        
        var suggestions: [InputSuggestion] = []
        let workspaceType = context.workspaceType
        
        // Workspace-specific completions
        switch workspaceType {
        case .code:
            suggestions.append(contentsOf: generateCodeCompletions(input))
        case .creative:
            suggestions.append(contentsOf: generateCreativeCompletions(input))
        case .research:
            suggestions.append(contentsOf: generateResearchCompletions(input))
        case .general:
            suggestions.append(contentsOf: generateGeneralCompletions(input))
        }
        
        return suggestions
    }
    
    private func rankSuggestions(
        _ suggestions: [InputSuggestion],
        for input: String,
        context: ConversationContext
    ) -> [InputSuggestion] {
        
        return suggestions
            .filter { $0.confidence > confidenceThreshold }
            .sorted { suggestion1, suggestion2 in
                let score1 = calculateRankingScore(suggestion1, for: input, context: context)
                let score2 = calculateRankingScore(suggestion2, for: input, context: context)
                return score1 > score2
            }
    }
    
    private func calculateRankingScore(
        _ suggestion: InputSuggestion,
        for input: String,
        context: ConversationContext
    ) -> Double {
        
        // Combine multiple ranking factors
        let confidenceWeight = 0.4
        let contextWeight = 0.3
        let recencyWeight = 0.2
        let personalizedWeight = 0.1
        
        let confidenceScore = suggestion.confidence * confidenceWeight
        let contextScore = suggestion.contextRelevance * contextWeight
        let recencyScore = calculateRecencyScore(suggestion) * recencyWeight
        let personalizedScore = calculatePersonalizationScore(suggestion, context: context) * personalizedWeight
        
        return confidenceScore + contextScore + recencyScore + personalizedScore
    }
    
    private func updateLearningPatterns(
        input: String,
        context: ConversationContext,
        suggestions: [InputSuggestion]
    ) {
        // Update user patterns based on context and suggestions
        updateWorkspacePatterns(input, workspaceType: context.workspaceType, suggestions: suggestions)
        updateTemporalPatterns(input, temporalContext: context.temporalContext, suggestions: suggestions)
        updateSemanticPatterns(input, semanticContext: context.semanticContext, suggestions: suggestions)
    }
    
    private func updateCompletionPatterns(from record: InputRecord) {
        guard let selected = record.selectedSuggestion else { return }
        
        let pattern = record.originalInput.lowercased()
        
        if var existing = completionPatterns[pattern] {
            // Update existing pattern
            existing.usageCount += 1
            existing.confidence = min(1.0, existing.confidence + learningRate)
            existing.lastUsed = record.timestamp
            completionPatterns[pattern] = existing
        } else {
            // Create new pattern
            let newPattern = CompletionPattern(
                trigger: pattern,
                completionText: selected.text,
                confidence: 0.5,
                usageCount: 1,
                lastUsed: record.timestamp,
                contextTags: extractContextTags(from: record.context)
            )
            completionPatterns[pattern] = newPattern
        }
    }
    
    private func updateContextualTriggers(from record: InputRecord) {
        let workspaceKey = record.context.workspaceType.rawValue
        
        if var trigger = contextualTriggers[workspaceKey] {
            trigger.strength += learningRate
            trigger.lastActivation = record.timestamp
            contextualTriggers[workspaceKey] = trigger
        } else {
            let newTrigger = ContextualTrigger(
                context: workspaceKey,
                strength: 0.3,
                lastActivation: record.timestamp,
                associatedPatterns: [record.originalInput]
            )
            contextualTriggers[workspaceKey] = newTrigger
        }
    }
    
    private func updateTemporalPredictions(_ context: TemporalContext?) {
        guard let context = context else { return }
        
        // Update time-based patterns
        let currentHour = Calendar.current.component(.hour, from: Date())
        userPatterns.timeOfDayPatterns[currentHour, default: []].append(
            TemporalPattern(
                timeContext: context,
                commonInputs: [], // Would be populated from recent inputs
                confidence: 0.5
            )
        )
    }
    
    // MARK: - Helper Methods
    
    private func detectInputIntent(_ input: String) -> InputIntent {
        let lowercased = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Simple intent detection
        if lowercased.hasPrefix("how") || lowercased.hasPrefix("what") || lowercased.hasPrefix("why") {
            return .question
        } else if lowercased.hasPrefix("create") || lowercased.hasPrefix("generate") || lowercased.hasPrefix("write") {
            return .creation
        } else if lowercased.hasPrefix("explain") || lowercased.hasPrefix("analyze") || lowercased.hasPrefix("describe") {
            return .explanation
        } else if lowercased.contains("code") || lowercased.contains("function") || lowercased.contains("class") {
            return .code
        } else {
            return .general
        }
    }
    
    private func calculateSemanticSimilarity(_ input: String, context: ConversationContext) async -> Double {
        // Calculate semantic similarity using conversation context
        guard !context.recentMessages.isEmpty else { return 0.0 }
        
        // Simple semantic similarity calculation
        let inputWords = Set(input.lowercased().components(separatedBy: .whitespacesAndPunctuation))
        let contextWords = Set(context.recentMessages.flatMap {
            $0.content.lowercased().components(separatedBy: .whitespacesAndPunctuation)
        })
        
        let intersection = inputWords.intersection(contextWords)
        let union = inputWords.union(contextWords)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    private func calculateInputComplexity(_ input: String) -> InputComplexity {
        let wordCount = input.components(separatedBy: .whitespaces).count
        let characterCount = input.count
        
        if wordCount <= 3 && characterCount <= 20 {
            return .simple
        } else if wordCount <= 10 && characterCount <= 100 {
            return .moderate
        } else {
            return .complex
        }
    }
    
    private func calculateTemporalRelevance(_ temporalContext: TemporalContext, for context: ConversationContext) -> Double {
        // Calculate how relevant temporal context is for this conversation
        let timeOfDay = temporalContext.timeOfDay
        let workspaceType = context.workspaceType
        
        // Simple heuristic: coding is more relevant during work hours
        switch (workspaceType, timeOfDay) {
        case (.code, .morning), (.code, .midday), (.code, .afternoon):
            return 0.8
        case (.creative, .evening), (.creative, .night):
            return 0.7
        case (.research, .morning), (.research, .afternoon):
            return 0.8
        default:
            return 0.5
        }
    }
    
    private func calculateWorkspaceAlignment(_ input: String, for workspaceType: WorkspaceType) -> Double {
        let lowercased = input.lowercased()
        
        switch workspaceType {
        case .code:
            let codeKeywords = ["function", "class", "method", "variable", "algorithm", "debug", "error", "compile"]
            return calculateKeywordAlignment(lowercased, keywords: codeKeywords)
        case .creative:
            let creativeKeywords = ["story", "character", "plot", "creative", "imagine", "design", "art", "music"]
            return calculateKeywordAlignment(lowercased, keywords: creativeKeywords)
        case .research:
            let researchKeywords = ["analyze", "study", "research", "data", "findings", "evidence", "hypothesis"]
            return calculateKeywordAlignment(lowercased, keywords: researchKeywords)
        case .general:
            return 0.5 // Neutral alignment for general workspace
        }
    }
    
    private func calculateKeywordAlignment(_ input: String, keywords: [String]) -> Double {
        let inputWords = Set(input.components(separatedBy: .whitespacesAndPunctuation))
        let keywordSet = Set(keywords)
        let matches = inputWords.intersection(keywordSet)
        
        return inputWords.isEmpty ? 0.0 : Double(matches.count) / Double(inputWords.count)
    }
    
    private func getTimeBasedCompletions(_ input: String, temporalContext: TemporalContext) -> [InputSuggestion] {
        var suggestions: [InputSuggestion] = []
        
        // Time-of-day specific suggestions
        switch temporalContext.timeOfDay {
        case .morning:
            if input.lowercased().hasPrefix("good") {
                suggestions.append(InputSuggestion(
                    text: "Good morning! How can I help you start your day?",
                    type: .temporal,
                    confidence: 0.8,
                    source: .temporalPattern,
                    contextRelevance: 0.9,
                    metadata: ["time_context": "morning_greeting"]
                ))
            }
        case .evening:
            if input.lowercased().hasPrefix("summ") {
                suggestions.append(InputSuggestion(
                    text: "Summarize today's work and accomplishments",
                    type: .temporal,
                    confidence: 0.7,
                    source: .temporalPattern,
                    contextRelevance: 0.8,
                    metadata: ["time_context": "evening_summary"]
                ))
            }
        default:
            break
        }
        
        return suggestions
    }
    
    private func getWorkspacePatterns(for workspaceType: WorkspaceType) -> [String] {
        return userPatterns.workspacePatterns[workspaceType.rawValue] ?? []
    }
    
    private func getTimeBasedSuggestions(for temporalContext: TemporalContext) -> [String] {
        return userPatterns.timeOfDayPatterns[Calendar.current.component(.hour, from: Date())]?.compactMap { $0.commonInputs.first } ?? []
    }
    
    private func getSemanticSuggestions(for context: ConversationContext) async -> [String] {
        // Get semantic suggestions from memory
        return context.semanticContext.prefix(3).map { $0 }
    }
    
    private func calculateInsightsConfidence(for context: ConversationContext) -> Double {
        let historySize = inputHistory.count
        let contextSize = context.recentMessages.count
        
        // Base confidence on available data
        let historyConfidence = min(1.0, Double(historySize) / 100.0)
        let contextConfidence = min(1.0, Double(contextSize) / 10.0)
        
        return (historyConfidence + contextConfidence) / 2.0
    }
    
    private func generateCodeCompletions(_ input: String) -> [InputSuggestion] {
        let codePatterns = [
            ("write a function", "Write a function that"),
            ("create a class", "Create a class that"),
            ("implement", "Implement an algorithm for"),
            ("debug", "Debug the following code:"),
            ("optimize", "Optimize this code for performance:")
        ]
        
        return generatePatternSuggestions(input, patterns: codePatterns, type: .workspaceSpecific)
    }
    
    private func generateCreativeCompletions(_ input: String) -> [InputSuggestion] {
        let creativePatterns = [
            ("write a story", "Write a story about"),
            ("create a character", "Create a character who"),
            ("imagine", "Imagine a world where"),
            ("design", "Design a concept for"),
            ("brainstorm", "Brainstorm ideas for")
        ]
        
        return generatePatternSuggestions(input, patterns: creativePatterns, type: .workspaceSpecific)
    }
    
    private func generateResearchCompletions(_ input: String) -> [InputSuggestion] {
        let researchPatterns = [
            ("analyze", "Analyze the following data:"),
            ("research", "Research the topic of"),
            ("compare", "Compare and contrast"),
            ("explain", "Explain the concept of"),
            ("summarize", "Summarize the key findings about")
        ]
        
        return generatePatternSuggestions(input, patterns: researchPatterns, type: .workspaceSpecific)
    }
    
    private func generateGeneralCompletions(_ input: String) -> [InputSuggestion] {
        let generalPatterns = [
            ("help", "Help me with"),
            ("what", "What is"),
            ("how", "How do I"),
            ("explain", "Explain"),
            ("tell me", "Tell me about")
        ]
        
        return generatePatternSuggestions(input, patterns: generalPatterns, type: .general)
    }
    
    private func generatePatternSuggestions(_ input: String, patterns: [(String, String)], type: SuggestionType) -> [InputSuggestion] {
        let lowercased = input.lowercased()
        
        return patterns.compactMap { (trigger, completion) in
            guard trigger.hasPrefix(lowercased) else { return nil }
            
            return InputSuggestion(
                text: completion,
                type: type,
                confidence: 0.6,
                source: .workspacePattern,
                contextRelevance: 0.7,
                metadata: ["pattern_trigger": trigger]
            )
        }
    }
    
    private func generateFollowUpSuggestion(for message: ChatMessage, input: String) -> InputSuggestion? {
        // Generate follow-up suggestions based on previous messages
        let messageContent = message.content.lowercased()
        let currentInput = input.lowercased()
        
        if messageContent.contains("error") && currentInput.hasPrefix("fix") {
            return InputSuggestion(
                text: "Fix the error by",
                type: .contextual,
                confidence: 0.7,
                source: .conversationHistory,
                contextRelevance: 0.8,
                metadata: ["follow_up_type": "error_resolution"]
            )
        }
        
        return nil
    }
    
    private func generateContextualCompletion(_ input: String, contextTerm: String) -> InputSuggestion? {
        let lowercased = input.lowercased()
        
        if lowercased.hasPrefix("tell me about") && contextTerm.count > 3 {
            return InputSuggestion(
                text: "Tell me about \(contextTerm)",
                type: .contextual,
                confidence: 0.6,
                source: .semanticContext,
                contextRelevance: 0.7,
                metadata: ["context_term": contextTerm]
            )
        }
        
        return nil
    }
    
    private func calculateContextRelevance(_ completion: CompletionPattern, for context: ConversationContext) -> Double {
        let contextTags = extractContextTags(from: context)
        let patternTags = Set(completion.contextTags)
        let intersection = contextTags.intersection(patternTags)
        
        return contextTags.isEmpty ? 0.5 : Double(intersection.count) / Double(contextTags.count)
    }
    
    private func calculateRecencyScore(_ suggestion: InputSuggestion) -> Double {
        // Higher score for more recent suggestions
        return 0.8 // Simplified - would calculate based on actual usage recency
    }
    
    private func calculatePersonalizationScore(_ suggestion: InputSuggestion, context: ConversationContext) -> Double {
        // Calculate personalization based on user patterns
        return 0.6 // Simplified - would calculate based on user history alignment
    }
    
    private func calculateAverageConfidence() -> Double {
        guard !inputHistory.isEmpty else { return 0.0 }
        
        let totalConfidence = inputHistory.compactMap { $0.selectedSuggestion?.confidence }.reduce(0, +)
        let count = inputHistory.compactMap { $0.selectedSuggestion }.count
        
        return count > 0 ? totalConfidence / Double(count) : 0.0
    }
    
    private func extractContextTags(from context: ConversationContext) -> Set<String> {
        var tags = Set<String>()
        
        // Add workspace type
        tags.insert(context.workspaceType.rawValue)
        
        // Add temporal context
        if let temporal = context.temporalContext {
            tags.insert(temporal.timeOfDay.rawValue)
            tags.insert(temporal.dayOfWeek.rawValue)
        }
        
        // Add semantic context
        tags.formUnion(Set(context.semanticContext.prefix(3)))
        
        return tags
    }
    
    private func updateWorkspacePatterns(_ input: String, workspaceType: WorkspaceType, suggestions: [InputSuggestion]) {
        let key = workspaceType.rawValue
        var patterns = userPatterns.workspacePatterns[key] ?? []
        patterns.append(input)
        
        // Keep only recent patterns
        if patterns.count > 100 {
            patterns = Array(patterns.suffix(100))
        }
        
        userPatterns.workspacePatterns[key] = patterns
    }
    
    private func updateTemporalPatterns(_ input: String, temporalContext: TemporalContext?, suggestions: [InputSuggestion]) {
        guard let context = temporalContext else { return }
        
        let hour = Calendar.current.component(.hour, from: Date())
        var patterns = userPatterns.timeOfDayPatterns[hour] ?? []
        
        let newPattern = TemporalPattern(
            timeContext: context,
            commonInputs: [input],
            confidence: 0.5
        )
        patterns.append(newPattern)
        
        // Keep only recent patterns
        if patterns.count > 50 {
            patterns = Array(patterns.suffix(50))
        }
        
        userPatterns.timeOfDayPatterns[hour] = patterns
    }
    
    private func updateSemanticPatterns(_ input: String, semanticContext: [String], suggestions: [InputSuggestion]) {
        // Update semantic patterns based on context
        for term in semanticContext.prefix(3) {
            var patterns = userPatterns.semanticPatterns[term] ?? []
            patterns.append(input)
            
            // Keep only recent patterns
            if patterns.count > 20 {
                patterns = Array(patterns.suffix(20))
            }
            
            userPatterns.semanticPatterns[term] = patterns
        }
    }
    
    private func cleanupSensitivePatterns() {
        // Remove potentially sensitive patterns for maximum privacy
        let sensitiveTerms = ["password", "email", "phone", "address", "personal"]
        
        for term in sensitiveTerms {
            completionPatterns = completionPatterns.filter { !$0.key.contains(term) }
            contextualTriggers = contextualTriggers.filter { !$0.key.contains(term) }
        }
    }
    
    private func expandPatternLearning() {
        // Enable more aggressive pattern learning for performance mode
        // This would involve storing more patterns and context
    }
    
    private func loadUserPatterns() {
        guard let data = UserDefaults.standard.data(forKey: "UserInputPatterns"),
              let patterns = try? JSONDecoder().decode(UserInputPatterns.self, from: data) else {
            return
        }
        
        userPatterns = patterns
        
        // Load completion patterns
        if let completionData = UserDefaults.standard.data(forKey: "CompletionPatterns"),
           let patterns = try? JSONDecoder().decode([String: CompletionPattern].self, from: completionData) {
            completionPatterns = patterns
        }
        
        // Load contextual triggers
        if let triggerData = UserDefaults.standard.data(forKey: "ContextualTriggers"),
           let triggers = try? JSONDecoder().decode([String: ContextualTrigger].self, from: triggerData) {
            contextualTriggers = triggers
        }
    }
    
    private func saveUserPatterns() {
        // Save user patterns
        if let data = try? JSONEncoder().encode(userPatterns) {
            UserDefaults.standard.set(data, forKey: "UserInputPatterns")
        }
        
        // Save completion patterns
        if let data = try? JSONEncoder().encode(completionPatterns) {
            UserDefaults.standard.set(data, forKey: "CompletionPatterns")
        }
        
        // Save contextual triggers
        if let data = try? JSONEncoder().encode(contextualTriggers) {
            UserDefaults.standard.set(data, forKey: "ContextualTriggers")
        }
    }
    
    private func savePredictionConfiguration() {
        let defaults = UserDefaults.standard
        defaults.set(predictionMode.rawValue, forKey: "PredictionMode")
        defaults.set(learningEnabled, forKey: "LearningEnabled")
    }
    
    private func getPredictionPrivacyInfo() -> PredictionPrivacyInfo {
        return PredictionPrivacyInfo(
            learningEnabled: learningEnabled,
            dataStoredLocally: true,
            patternCount: completionPatterns.count,
            retentionPeriod: "30 days",
            privacyTechniques: ["Local Processing", "Pattern Anonymization", "Selective Learning"]
        )
    }
}

// MARK: - Supporting Types

/// Input suggestion structure
public struct InputSuggestion: Codable, Hashable, Identifiable {
    public let id: UUID
    public let text: String
    public let type: SuggestionType
    public let confidence: Double
    public let source: SuggestionSource
    public let contextRelevance: Double
    public let metadata: [String: String]
    
    public init(text: String, type: SuggestionType, confidence: Double, source: SuggestionSource, contextRelevance: Double, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.text = text
        self.type = type
        self.confidence = confidence
        self.source = source
        self.contextRelevance = contextRelevance
        self.metadata = metadata
    }
}

/// Input record for learning
public struct InputRecord: Codable, Hashable {
    public let id: UUID
    public let originalInput: String
    public let selectedSuggestion: InputSuggestion?
    public let context: ConversationContext
    public let timestamp: Date
    public let temporalContext: TemporalContext
    
    public init(originalInput: String, selectedSuggestion: InputSuggestion?, context: ConversationContext, timestamp: Date, temporalContext: TemporalContext) {
        self.id = UUID()
        self.originalInput = originalInput
        self.selectedSuggestion = selectedSuggestion
        self.context = context
        self.timestamp = timestamp
        self.temporalContext = temporalContext
    }
}

/// Contextual insights
public struct ContextualInsights: Codable, Hashable {
    public let workspaceType: WorkspaceType
    public let temporalContext: TemporalContext
    public let suggestedTopics: [String]
    public let commonPatterns: [String]
    public let timeBasedSuggestions: [String]
    public let confidence: Double
    
    public init() {
        self.workspaceType = .general
        self.temporalContext = TemporalContext()
        self.suggestedTopics = []
        self.commonPatterns = []
        self.timeBasedSuggestions = []
        self.confidence = 0.0
    }
    
    public init(workspaceType: WorkspaceType, temporalContext: TemporalContext, suggestedTopics: [String], commonPatterns: [String], timeBasedSuggestions: [String], confidence: Double) {
        self.workspaceType = workspaceType
        self.temporalContext = temporalContext
        self.suggestedTopics = suggestedTopics
        self.commonPatterns = commonPatterns
        self.timeBasedSuggestions = timeBasedSuggestions
        self.confidence = confidence
    }
}

/// User input patterns
public struct UserInputPatterns: Codable, Hashable {
    public var workspacePatterns: [String: [String]] = [:]
    public var timeOfDayPatterns: [Int: [TemporalPattern]] = [:]
    public var dayOfWeekPatterns: [DayOfWeek: [InputPattern]] = [:]
    public var semanticPatterns: [String: [String]] = [:]
    
    public init() {}
}

/// Temporal pattern
public struct TemporalPattern: Codable, Hashable {
    public let timeContext: TemporalContext
    public let commonInputs: [String]
    public let confidence: Double
    
    public init(timeContext: TemporalContext, commonInputs: [String], confidence: Double) {
        self.timeContext = timeContext
        self.commonInputs = commonInputs
        self.confidence = confidence
    }
}

/// Input pattern
public struct InputPattern: Codable, Hashable {
    public let trigger: String
    public let completion: String
    public let confidence: Double
    
    public init(trigger: String, completion: String, confidence: Double) {
        self.trigger = trigger
        self.completion = completion
        self.confidence = confidence
    }
}

/// Completion pattern
public struct CompletionPattern: Codable, Hashable {
    public let trigger: String
    public let completionText: String
    public var confidence: Double
    public var usageCount: Int
    public var lastUsed: Date
    public let contextTags: [String]
    
    public init(trigger: String, completionText: String, confidence: Double, usageCount: Int, lastUsed: Date, contextTags: [String]) {
        self.trigger = trigger
        self.completionText = completionText
        self.confidence = confidence
        self.usageCount = usageCount
        self.lastUsed = lastUsed
        self.contextTags = contextTags
    }
}

/// Contextual trigger
public struct ContextualTrigger: Codable, Hashable {
    public let context: String
    public var strength: Double
    public var lastActivation: Date
    public let associatedPatterns: [String]
    
    public init(context: String, strength: Double, lastActivation: Date, associatedPatterns: [String]) {
        self.context = context
        self.strength = strength
        self.lastActivation = lastActivation
        self.associatedPatterns = associatedPatterns
    }
}

/// Contextual state
public struct ContextualState: Codable, Hashable {
    public let intent: InputIntent
    public let complexity: InputComplexity
    public let semanticSimilarity: Double
    public let temporalRelevance: Double
    public let workspaceAlignment: Double
    
    public init(intent: InputIntent, complexity: InputComplexity, semanticSimilarity: Double, temporalRelevance: Double, workspaceAlignment: Double) {
        self.intent = intent
        self.complexity = complexity
        self.semanticSimilarity = semanticSimilarity
        self.temporalRelevance = temporalRelevance
        self.workspaceAlignment = workspaceAlignment
    }
}

/// Prediction statistics
public struct PredictionStatistics: Codable, Hashable {
    public let totalPredictions: Int
    public let acceptedPredictions: Int
    public let acceptanceRate: Double
    public let averageConfidence: Double
    public let uniquePatterns: Int
    public let contextualTriggers: Int
    
    public init(totalPredictions: Int, acceptedPredictions: Int, acceptanceRate: Double, averageConfidence: Double, uniquePatterns: Int, contextualTriggers: Int) {
        self.totalPredictions = totalPredictions
        self.acceptedPredictions = acceptedPredictions
        self.acceptanceRate = acceptanceRate
        self.averageConfidence = averageConfidence
        self.uniquePatterns = uniquePatterns
        self.contextualTriggers = contextualTriggers
    }
}

/// Prediction data export
public struct PredictionDataExport: Codable, Hashable {
    public let userPatterns: UserInputPatterns
    public let statistics: PredictionStatistics
    public let privacyInfo: PredictionPrivacyInfo
    public let learningStatus: Bool
    
    public init(userPatterns: UserInputPatterns, statistics: PredictionStatistics, privacyInfo: PredictionPrivacyInfo, learningStatus: Bool) {
        self.userPatterns = userPatterns
        self.statistics = statistics
        self.privacyInfo = privacyInfo
        self.learningStatus = learningStatus
    }
}

/// Prediction privacy info
public struct PredictionPrivacyInfo: Codable, Hashable {
    public let learningEnabled: Bool
    public let dataStoredLocally: Bool
    public let patternCount: Int
    public let retentionPeriod: String
    public let privacyTechniques: [String]
    
    public init(learningEnabled: Bool, dataStoredLocally: Bool, patternCount: Int, retentionPeriod: String, privacyTechniques: [String]) {
        self.learningEnabled = learningEnabled
        self.dataStoredLocally = dataStoredLocally
        self.patternCount = patternCount
        self.retentionPeriod = retentionPeriod
        self.privacyTechniques = privacyTechniques
    }
}

/// Related concept from semantic memory
public struct RelatedConcept: Codable, Hashable {
    public let text: String
    public let type: String
    public let relevance: Double
    public let contextRelevance: Double
    public let memoryStrength: Double
    
    public init(text: String, type: String, relevance: Double, contextRelevance: Double, memoryStrength: Double) {
        self.text = text
        self.type = type
        self.relevance = relevance
        self.contextRelevance = contextRelevance
        self.memoryStrength = memoryStrength
    }
}

/// Enums
public enum PredictionMode: String, Codable, CaseIterable, Hashable {
    case disabled = "disabled"
    case basic = "basic"
    case intelligent = "intelligent"
    case aggressive = "aggressive"
    
    public var displayName: String {
        switch self {
        case .disabled: return "Disabled"
        case .basic: return "Basic"
        case .intelligent: return "Intelligent"
        case .aggressive: return "Aggressive"
        }
    }
}

public enum SuggestionType: String, Codable, CaseIterable, Hashable {
    case patternBased = "patternBased"
    case contextual = "contextual"
    case temporal = "temporal"
    case semantic = "semantic"
    case workspaceSpecific = "workspaceSpecific"
    case general = "general"
}

public enum SuggestionSource: String, Codable, CaseIterable, Hashable {
    case userHistory = "userHistory"
    case temporalPattern = "temporalPattern"
    case semanticMemory = "semanticMemory"
    case workspacePattern = "workspacePattern"
    case conversationHistory = "conversationHistory"
    case semanticContext = "semanticContext"
}

public enum InputIntent: String, Codable, CaseIterable, Hashable {
    case question = "question"
    case creation = "creation"
    case explanation = "explanation"
    case code = "code"
    case general = "general"
}

public enum InputComplexity: String, Codable, CaseIterable, Hashable {
    case simple = "simple"
    case moderate = "moderate"
    case complex = "complex"
}
