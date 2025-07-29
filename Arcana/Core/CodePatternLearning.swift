//
// CodePatternLearning.swift
// Arcana
//
// Revolutionary code style learning engine that adapts to user preferences over time
// Part of the PRISM intelligence system for enhanced code generation
//

import Foundation
import Combine

// MARK: - Code Pattern Learning Engine

/// Revolutionary AI-powered code style learning system that adapts to user preferences
/// Continuously learns from user interactions to improve code generation quality
@MainActor
public class CodePatternLearning: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var learningProgress: Double = 0.0
    @Published private(set) var detectedPatterns: [CodePattern] = []
    @Published private(set) var stylePreferences: CodeStylePreferences = CodeStylePreferences()
    @Published private(set) var isLearning: Bool = false
    @Published private(set) var confidenceScore: Double = 0.0
    
    // MARK: - Private Properties
    
    private let quantumMemory: QuantumMemoryManager
    private let semanticMemory: SemanticMemoryEngine
    private let performanceMonitor: PerformanceMonitor
    private var patternCache: [String: [CodePattern]] = [:]
    private var learningTasks: Set<Task<Void, Never>> = []
    private let patternStorage = PatternStorage()
    
    // MARK: - Initialization
    
    public init(quantumMemory: QuantumMemoryManager,
                semanticMemory: SemanticMemoryEngine,
                performanceMonitor: PerformanceMonitor) {
        self.quantumMemory = quantumMemory
        self.semanticMemory = semanticMemory
        self.performanceMonitor = performanceMonitor
        
        Task {
            await loadStoredPatterns()
            await initializeLearningEngine()
        }
    }
    
    deinit {
        // Cancel all learning tasks
        learningTasks.forEach { $0.cancel() }
    }
    
    // MARK: - Public Interface
    
    /// Learn from user code interactions and improve pattern recognition
    public func learnFromCodeInteraction(_ interaction: CodeInteraction) async throws {
        guard !isLearning else { return }
        
        isLearning = true
        defer { isLearning = false }
        
        do {
            // Extract patterns from user interaction
            let extractedPatterns = await extractPatterns(from: interaction)
            
            // Update learning model with new patterns
            await updateLearningModel(with: extractedPatterns)
            
            // Reinforce successful patterns
            if interaction.wasAccepted {
                await reinforcePatterns(extractedPatterns)
            }
            
            // Update confidence score
            confidenceScore = calculateConfidenceScore()
            
            // Cache patterns for faster access
            await cachePatterns(extractedPatterns, for: interaction.language)
            
            // Save to persistent storage
            await patternStorage.save(patterns: extractedPatterns)
            
        } catch {
            throw ArcanaError.intelligence("Code pattern learning failed: \(error.localizedDescription)")
        }
    }
    
    /// Get style recommendations for specific code context
    public func getStyleRecommendations(for context: CodeContext) async -> CodeStyleRecommendations {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // Load relevant patterns from cache or memory
            let relevantPatterns = await getRelevantPatterns(for: context)
            
            // Generate recommendations based on learned patterns
            let recommendations = await generateRecommendations(
                from: relevantPatterns,
                context: context
            )
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            await performanceMonitor.recordMetric(
                .codePatternProcessing,
                value: processingTime,
                context: ["language": context.language.rawValue]
            )
            
            return recommendations
            
        } catch {
            // Fallback to default recommendations
            return CodeStyleRecommendations.defaultRecommendations(for: context.language)
        }
    }
    
    /// Update user style preferences based on feedback
    public func updateStylePreferences(_ preferences: CodeStylePreferences) async {
        stylePreferences = preferences
        
        // Re-evaluate existing patterns with new preferences
        await reevaluatePatterns(with: preferences)
        
        // Update learning weights
        await updateLearningWeights(basedOn: preferences)
        
        // Save updated preferences
        await patternStorage.savePreferences(preferences)
    }
    
    /// Get learning analytics for user insights
    public func getLearningAnalytics() -> CodeLearningAnalytics {
        return CodeLearningAnalytics(
            totalPatterns: detectedPatterns.count,
            languagesLearned: Set(detectedPatterns.map { $0.language }).count,
            confidenceScore: confidenceScore,
            learningProgress: learningProgress,
            mostCommonPatterns: getMostCommonPatterns(),
            styleEvolution: getStyleEvolution(),
            improvementSuggestions: getImprovementSuggestions()
        )
    }
    
    // MARK: - Private Implementation
    
    private func loadStoredPatterns() async {
        do {
            let storedPatterns = await patternStorage.loadPatterns()
            detectedPatterns = storedPatterns
            
            if let preferences = await patternStorage.loadPreferences() {
                stylePreferences = preferences
            }
            
            // Rebuild pattern cache
            for pattern in storedPatterns {
                let language = pattern.language.rawValue
                patternCache[language, default: []].append(pattern)
            }
            
        } catch {
            print("⚠️ Failed to load stored patterns: \(error)")
        }
    }
    
    private func initializeLearningEngine() async {
        // Initialize with common programming patterns
        let commonPatterns = getCommonPatterns()
        detectedPatterns.append(contentsOf: commonPatterns)
        
        // Set initial learning progress
        learningProgress = detectedPatterns.isEmpty ? 0.0 : 0.1
        
        // Start background learning optimization
        startBackgroundOptimization()
    }
    
    private func extractPatterns(from interaction: CodeInteraction) async -> [CodePattern] {
        var patterns: [CodePattern] = []
        
        let content = interaction.codeContent
        let language = interaction.language
        
        // Extract naming patterns
        let namingPatterns = extractNamingPatterns(from: content, language: language)
        patterns.append(contentsOf: namingPatterns)
        
        // Extract indentation patterns
        if let indentationPattern = extractIndentationPattern(from: content) {
            patterns.append(indentationPattern)
        }
        
        // Extract formatting patterns
        let formattingPatterns = extractFormattingPatterns(from: content, language: language)
        patterns.append(contentsOf: formattingPatterns)
        
        // Extract structural patterns
        let structuralPatterns = extractStructuralPatterns(from: content, language: language)
        patterns.append(contentsOf: structuralPatterns)
        
        // Extract comment patterns
        let commentPatterns = extractCommentPatterns(from: content, language: language)
        patterns.append(contentsOf: commentPatterns)
        
        return patterns
    }
    
    private func extractNamingPatterns(from content: String, language: ProgrammingLanguage) -> [CodePattern] {
        var patterns: [CodePattern] = []
        
        // Extract variable naming patterns
        let variableRegex = try? NSRegularExpression(pattern: "\\b(?:var|let|const)\\s+(\\w+)", options: [])
        let matches = variableRegex?.matches(in: content, options: [], range: NSRange(location: 0, length: content.count)) ?? []
        
        var namingStyles: [String] = []
        for match in matches {
            if let range = Range(match.range(at: 1), in: content) {
                let variableName = String(content[range])
                namingStyles.append(variableName)
            }
        }
        
        if !namingStyles.isEmpty {
            let pattern = CodePattern(
                id: UUID(),
                type: .naming,
                language: language,
                pattern: detectNamingConvention(from: namingStyles),
                confidence: 0.8,
                frequency: namingStyles.count,
                lastSeen: Date(),
                context: ["type": "variable"]
            )
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    private func extractIndentationPattern(from content: String) -> CodePattern? {
        let lines = content.components(separatedBy: .newlines)
        var indentationSizes: [Int] = []
        
        for line in lines {
            if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let leadingWhitespace = line.prefix { $0.isWhitespace }
                
                if leadingWhitespace.contains("\t") {
                    // Tab indentation
                    return CodePattern(
                        id: UUID(),
                        type: .indentation,
                        language: .swift, // Default to Swift
                        pattern: "tabs",
                        confidence: 0.9,
                        frequency: 1,
                        lastSeen: Date(),
                        context: ["style": "tabs"]
                    )
                } else {
                    // Space indentation
                    indentationSizes.append(leadingWhitespace.count)
                }
            }
        }
        
        if !indentationSizes.isEmpty {
            let mostCommonSize = Dictionary(grouping: indentationSizes, by: { $0 })
                .max { $0.value.count < $1.value.count }?.key ?? 4
            
            return CodePattern(
                id: UUID(),
                type: .indentation,
                language: .swift,
                pattern: "\(mostCommonSize) spaces",
                confidence: 0.8,
                frequency: indentationSizes.count,
                lastSeen: Date(),
                context: ["size": "\(mostCommonSize)", "style": "spaces"]
            )
        }
        
        return nil
    }
    
    private func extractFormattingPatterns(from content: String, language: ProgrammingLanguage) -> [CodePattern] {
        var patterns: [CodePattern] = []
        
        // Check for brace placement
        if content.contains("{\n") || content.contains("{ \n") {
            patterns.append(CodePattern(
                id: UUID(),
                type: .formatting,
                language: language,
                pattern: "newline_braces",
                confidence: 0.7,
                frequency: 1,
                lastSeen: Date(),
                context: ["style": "newline"]
            ))
        } else if content.contains(" {") {
            patterns.append(CodePattern(
                id: UUID(),
                type: .formatting,
                language: language,
                pattern: "inline_braces",
                confidence: 0.7,
                frequency: 1,
                lastSeen: Date(),
                context: ["style": "inline"]
            ))
        }
        
        return patterns
    }
    
    private func extractStructuralPatterns(from content: String, language: ProgrammingLanguage) -> [CodePattern] {
        var patterns: [CodePattern] = []
        
        // Extract function/method patterns
        let functionRegex = try? NSRegularExpression(pattern: "func\\s+(\\w+)", options: [])
        let functionMatches = functionRegex?.matches(in: content, options: [], range: NSRange(location: 0, length: content.count)) ?? []
        
        if !functionMatches.isEmpty {
            patterns.append(CodePattern(
                id: UUID(),
                type: .structure,
                language: language,
                pattern: "function_declaration",
                confidence: 0.9,
                frequency: functionMatches.count,
                lastSeen: Date(),
                context: ["type": "function"]
            ))
        }
        
        return patterns
    }
    
    private func extractCommentPatterns(from content: String, language: ProgrammingLanguage) -> [CodePattern] {
        var patterns: [CodePattern] = []
        
        // Check for different comment styles
        if content.contains("//") {
            patterns.append(CodePattern(
                id: UUID(),
                type: .comments,
                language: language,
                pattern: "single_line_comments",
                confidence: 0.8,
                frequency: content.components(separatedBy: "//").count - 1,
                lastSeen: Date(),
                context: ["style": "single_line"]
            ))
        }
        
        if content.contains("/*") && content.contains("*/") {
            patterns.append(CodePattern(
                id: UUID(),
                type: .comments,
                language: language,
                pattern: "block_comments",
                confidence: 0.8,
                frequency: content.components(separatedBy: "/*").count - 1,
                lastSeen: Date(),
                context: ["style": "block"]
            ))
        }
        
        return patterns
    }
    
    private func detectNamingConvention(from names: [String]) -> String {
        var conventions: [String: Int] = [:]
        
        for name in names {
            if name.contains("_") {
                conventions["snake_case", default: 0] += 1
            } else if name.first?.isLowercase == true && name.contains(where: { $0.isUppercase }) {
                conventions["camelCase", default: 0] += 1
            } else if name.first?.isUppercase == true {
                conventions["PascalCase", default: 0] += 1
            } else {
                conventions["lowercase", default: 0] += 1
            }
        }
        
        return conventions.max { $0.value < $1.value }?.key ?? "camelCase"
    }
    
    private func updateLearningModel(with patterns: [CodePattern]) async {
        for pattern in patterns {
            // Find existing similar patterns
            let existingPatternIndex = detectedPatterns.firstIndex { existingPattern in
                existingPattern.type == pattern.type &&
                existingPattern.language == pattern.language &&
                existingPattern.pattern == pattern.pattern
            }
            
            if let index = existingPatternIndex {
                // Update existing pattern
                var updatedPattern = detectedPatterns[index]
                updatedPattern = CodePattern(
                    id: updatedPattern.id,
                    type: updatedPattern.type,
                    language: updatedPattern.language,
                    pattern: updatedPattern.pattern,
                    confidence: min(1.0, updatedPattern.confidence + 0.1),
                    frequency: updatedPattern.frequency + pattern.frequency,
                    lastSeen: Date(),
                    context: updatedPattern.context
                )
                detectedPatterns[index] = updatedPattern
            } else {
                // Add new pattern
                detectedPatterns.append(pattern)
            }
        }
        
        // Update learning progress
        learningProgress = min(1.0, learningProgress + 0.01)
    }
    
    private func reinforcePatterns(_ patterns: [CodePattern]) async {
        for pattern in patterns {
            if let index = detectedPatterns.firstIndex(where: { $0.id == pattern.id }) {
                var reinforcedPattern = detectedPatterns[index]
                reinforcedPattern = CodePattern(
                    id: reinforcedPattern.id,
                    type: reinforcedPattern.type,
                    language: reinforcedPattern.language,
                    pattern: reinforcedPattern.pattern,
                    confidence: min(1.0, reinforcedPattern.confidence + 0.05),
                    frequency: reinforcedPattern.frequency + 1,
                    lastSeen: Date(),
                    context: reinforcedPattern.context
                )
                detectedPatterns[index] = reinforcedPattern
            }
        }
    }
    
    private func calculateConfidenceScore() -> Double {
        guard !detectedPatterns.isEmpty else { return 0.0 }
        
        let totalConfidence = detectedPatterns.reduce(0.0) { $0 + $1.confidence }
        return totalConfidence / Double(detectedPatterns.count)
    }
    
    private func cachePatterns(_ patterns: [CodePattern], for language: ProgrammingLanguage) async {
        let languageKey = language.rawValue
        patternCache[languageKey, default: []].append(contentsOf: patterns)
        
        // Keep cache size manageable
        if patternCache[languageKey]?.count ?? 0 > 1000 {
            patternCache[languageKey] = Array(patternCache[languageKey]?.suffix(500) ?? [])
        }
    }
    
    private func getRelevantPatterns(for context: CodeContext) async -> [CodePattern] {
        let languageKey = context.language.rawValue
        let cachedPatterns = patternCache[languageKey] ?? []
        
        // Filter patterns based on context
        return cachedPatterns.filter { pattern in
            pattern.confidence > 0.5 &&
            isPatternRelevant(pattern, for: context)
        }.sorted { $0.confidence > $1.confidence }
    }
    
    private func isPatternRelevant(_ pattern: CodePattern, for context: CodeContext) -> Bool {
        // Check if pattern type matches context needs
        switch context.requestType {
        case .formatting:
            return pattern.type == .formatting || pattern.type == .indentation
        case .naming:
            return pattern.type == .naming
        case .structure:
            return pattern.type == .structure
        case .comments:
            return pattern.type == .comments
        case .general:
            return true
        }
    }
    
    private func generateRecommendations(from patterns: [CodePattern], context: CodeContext) async -> CodeStyleRecommendations {
        var recommendations: [CodeRecommendation] = []
        
        // Generate recommendations based on learned patterns
        for pattern in patterns.prefix(10) { // Top 10 most relevant patterns
            let recommendation = CodeRecommendation(
                type: pattern.type,
                suggestion: generateSuggestion(for: pattern, context: context),
                confidence: pattern.confidence,
                rationale: "Based on your coding patterns (used \(pattern.frequency) times)",
                example: generateExample(for: pattern, context: context)
            )
            recommendations.append(recommendation)
        }
        
        return CodeStyleRecommendations(
            language: context.language,
            recommendations: recommendations,
            overallConfidence: patterns.isEmpty ? 0.0 : patterns.reduce(0.0) { $0 + $1.confidence } / Double(patterns.count),
            basedOnPatterns: patterns.count
        )
    }
    
    private func generateSuggestion(for pattern: CodePattern, context: CodeContext) -> String {
        switch pattern.type {
        case .naming:
            return "Use \(pattern.pattern) naming convention"
        case .indentation:
            return "Use \(pattern.pattern) for indentation"
        case .formatting:
            return "Apply \(pattern.pattern) formatting style"
        case .structure:
            return "Follow \(pattern.pattern) structural pattern"
        case .comments:
            return "Use \(pattern.pattern) commenting style"
        }
    }
    
    private func generateExample(for pattern: CodePattern, context: CodeContext) -> String {
        // Generate contextual examples based on pattern type
        switch pattern.type {
        case .naming:
            if pattern.pattern == "camelCase" {
                return "let myVariable = value"
            } else if pattern.pattern == "snake_case" {
                return "let my_variable = value"
            }
        case .indentation:
            if pattern.pattern.contains("spaces") {
                return "if condition {\n    // code here\n}"
            } else {
                return "if condition {\n\t// code here\n}"
            }
        case .formatting:
            if pattern.pattern == "inline_braces" {
                return "if condition { return true }"
            } else {
                return "if condition\n{\n    return true\n}"
            }
        default:
            break
        }
        
        return "Example based on your pattern: \(pattern.pattern)"
    }
    
    private func reevaluatePatterns(with preferences: CodeStylePreferences) async {
        // Adjust pattern confidence based on user preferences
        for i in detectedPatterns.indices {
            let pattern = detectedPatterns[i]
            let adjustedConfidence = adjustConfidenceBasedOnPreferences(pattern, preferences: preferences)
            
            detectedPatterns[i] = CodePattern(
                id: pattern.id,
                type: pattern.type,
                language: pattern.language,
                pattern: pattern.pattern,
                confidence: adjustedConfidence,
                frequency: pattern.frequency,
                lastSeen: pattern.lastSeen,
                context: pattern.context
            )
        }
    }
    
    private func adjustConfidenceBasedOnPreferences(_ pattern: CodePattern, preferences: CodeStylePreferences) -> Double {
        var adjustedConfidence = pattern.confidence
        
        // Adjust based on user preferences
        switch pattern.type {
        case .indentation:
            if pattern.pattern.contains("spaces") && preferences.preferSpaces {
                adjustedConfidence += 0.1
            } else if pattern.pattern.contains("tabs") && !preferences.preferSpaces {
                adjustedConfidence += 0.1
            } else {
                adjustedConfidence -= 0.05
            }
        case .naming:
            if pattern.pattern == preferences.preferredNamingConvention {
                adjustedConfidence += 0.1
            }
        default:
            break
        }
        
        return max(0.0, min(1.0, adjustedConfidence))
    }
    
    private func updateLearningWeights(basedOn preferences: CodeStylePreferences) async {
        // Implementation for updating internal learning weights
        // This would adjust how future patterns are weighted during learning
    }
    
    private func getMostCommonPatterns() -> [CodePattern] {
        return detectedPatterns
            .sorted { $0.frequency > $1.frequency }
            .prefix(5)
            .map { $0 }
    }
    
    private func getStyleEvolution() -> StyleEvolution {
        // Analyze how coding style has evolved over time
        let recentPatterns = detectedPatterns.filter {
            $0.lastSeen.timeIntervalSinceNow > -7 * 24 * 60 * 60 // Last 7 days
        }
        
        let olderPatterns = detectedPatterns.filter {
            $0.lastSeen.timeIntervalSinceNow <= -7 * 24 * 60 * 60
        }
        
        return StyleEvolution(
            recentPatterns: recentPatterns.count,
            historicalPatterns: olderPatterns.count,
            evolutionTrend: recentPatterns.count > olderPatterns.count ? .improving : .stable,
            keyChanges: identifyKeyChanges(recent: recentPatterns, historical: olderPatterns)
        )
    }
    
    private func identifyKeyChanges(recent: [CodePattern], historical: [CodePattern]) -> [String] {
        // Identify significant changes in coding patterns
        var changes: [String] = []
        
        let recentNaming = recent.filter { $0.type == .naming }.first?.pattern
        let historicalNaming = historical.filter { $0.type == .naming }.first?.pattern
        
        if let recent = recentNaming, let historical = historicalNaming, recent != historical {
            changes.append("Naming convention changed from \(historical) to \(recent)")
        }
        
        return changes
    }
    
    private func getImprovementSuggestions() -> [String] {
        var suggestions: [String] = []
        
        if confidenceScore < 0.7 {
            suggestions.append("Continue coding to improve pattern recognition accuracy")
        }
        
        if detectedPatterns.filter({ $0.type == .comments }).isEmpty {
            suggestions.append("Add more comments to help learn your documentation style")
        }
        
        let languagesCovered = Set(detectedPatterns.map { $0.language }).count
        if languagesCovered < 3 {
            suggestions.append("Work with more programming languages to expand pattern learning")
        }
        
        return suggestions
    }
    
    private func getCommonPatterns() -> [CodePattern] {
        // Initialize with common programming patterns
        return [
            CodePattern(
                id: UUID(),
                type: .naming,
                language: .swift,
                pattern: "camelCase",
                confidence: 0.6,
                frequency: 1,
                lastSeen: Date(),
                context: ["type": "default"]
            ),
            CodePattern(
                id: UUID(),
                type: .indentation,
                language: .swift,
                pattern: "4 spaces",
                confidence: 0.6,
                frequency: 1,
                lastSeen: Date(),
                context: ["size": "4", "style": "spaces"]
            )
        ]
    }
    
    private func startBackgroundOptimization() {
        let task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
                await self?.optimizePatternStorage()
            }
        }
        learningTasks.insert(task)
    }
    
    private func optimizePatternStorage() async {
        // Remove old, low-confidence patterns
        detectedPatterns = detectedPatterns.filter { pattern in
            pattern.confidence > 0.3 &&
            pattern.lastSeen.timeIntervalSinceNow > -30 * 24 * 60 * 60 // Keep patterns from last 30 days
        }
        
        // Consolidate similar patterns
        await consolidateSimilarPatterns()
    }
    
    private func consolidateSimilarPatterns() async {
        var consolidatedPatterns: [CodePattern] = []
        var processedPatterns: Set<UUID> = []
        
        for pattern in detectedPatterns {
            if processedPatterns.contains(pattern.id) { continue }
            
            let similarPatterns = detectedPatterns.filter { otherPattern in
                otherPattern.type == pattern.type &&
                otherPattern.language == pattern.language &&
                otherPattern.pattern == pattern.pattern &&
                !processedPatterns.contains(otherPattern.id)
            }
            
            if similarPatterns.count > 1 {
                // Consolidate similar patterns
                let totalFrequency = similarPatterns.reduce(0) { $0 + $1.frequency }
                let avgConfidence = similarPatterns.reduce(0.0) { $0 + $1.confidence } / Double(similarPatterns.count)
                let mostRecent = similarPatterns.max { $0.lastSeen < $1.lastSeen }?.lastSeen ?? Date()
                
                let consolidatedPattern = CodePattern(
                    id: pattern.id,
                    type: pattern.type,
                    language: pattern.language,
                    pattern: pattern.pattern,
                    confidence: avgConfidence,
                    frequency: totalFrequency,
                    lastSeen: mostRecent,
                    context: pattern.context
                )
                
                consolidatedPatterns.append(consolidatedPattern)
                similarPatterns.forEach { processedPatterns.insert($0.id) }
            } else {
                consolidatedPatterns.append(pattern)
                processedPatterns.insert(pattern.id)
            }
        }
        
        detectedPatterns = consolidatedPatterns
    }
}

// MARK: - Supporting Types

/// Represents a learned code pattern
public struct CodePattern: Codable, Hashable, Identifiable {
    public let id: UUID
    public let type: CodePatternType
    public let language: ProgrammingLanguage
    public let pattern: String
    public let confidence: Double
    public let frequency: Int
    public let lastSeen: Date
    public let context: [String: String]
}

/// Types of code patterns that can be learned
public enum CodePatternType: String, Codable, CaseIterable, Hashable {
    case naming
    case indentation
    case formatting
    case structure
    case comments
}

/// Programming languages supported for pattern learning
public enum ProgrammingLanguage: String, Codable, CaseIterable, Hashable {
    case swift
    case python
    case javascript
    case typescript
    case go
    case rust
    case java
    case kotlin
    case cpp = "c++"
    case c
    case csharp = "c#"
    case php
    case ruby
    case dart
    case scala
    case haskell
    case clojure
    case elixir
    case crystal
    case nim
    case zig
}

/// User interaction with code
public struct CodeInteraction: Codable, Hashable {
    public let id: UUID
    public let codeContent: String
    public let language: ProgrammingLanguage
    public let wasAccepted: Bool
    public let timestamp: Date
    public let context: [String: String]
    
    public init(codeContent: String, language: ProgrammingLanguage, wasAccepted: Bool, context: [String: String] = [:]) {
        self.id = UUID()
        self.codeContent = codeContent
        self.language = language
        self.wasAccepted = wasAccepted
        self.timestamp = Date()
        self.context = context
    }
}

/// Context for code style recommendations
public struct CodeContext: Codable, Hashable {
    public let language: ProgrammingLanguage
    public let requestType: CodeRequestType
    public let existingCode: String?
    public let projectContext: [String: String]
    
    public init(language: ProgrammingLanguage, requestType: CodeRequestType, existingCode: String? = nil, projectContext: [String: String] = [:]) {
        self.language = language
        self.requestType = requestType
        self.existingCode = existingCode
        self.projectContext = projectContext
    }
}

/// Type of code assistance request
public enum CodeRequestType: String, Codable, CaseIterable, Hashable {
    case formatting
    case naming
    case structure
    case comments
    case general
}

/// User's code style preferences
public struct CodeStylePreferences: Codable, Hashable {
    public let preferSpaces: Bool
    public let indentationSize: Int
    public let preferredNamingConvention: String
    public let preferInlineBraces: Bool
    public let preferVerboseComments: Bool
    
    public init(preferSpaces: Bool = true, indentationSize: Int = 4, preferredNamingConvention: String = "camelCase", preferInlineBraces: Bool = true, preferVerboseComments: Bool = false) {
        self.preferSpaces = preferSpaces
        self.indentationSize = indentationSize
        self.preferredNamingConvention = preferredNamingConvention
        self.preferInlineBraces = preferInlineBraces
        self.preferVerboseComments = preferVerboseComments
    }
}

/// Code style recommendations generated by the learning engine
public struct CodeStyleRecommendations: Codable, Hashable {
    public let language: ProgrammingLanguage
    public let recommendations: [CodeRecommendation]
    public let overallConfidence: Double
    public let basedOnPatterns: Int
    
    public static func defaultRecommendations(for language: ProgrammingLanguage) -> CodeStyleRecommendations {
        let defaultRecommendations = [
            CodeRecommendation(
                type: .naming,
                suggestion: "Use camelCase naming convention",
                confidence: 0.5,
                rationale: "Default recommendation",
                example: "let myVariable = value"
            ),
            CodeRecommendation(
                type: .indentation,
                suggestion: "Use 4 spaces for indentation",
                confidence: 0.5,
                rationale: "Default recommendation",
                example: "if condition {\n    // code here\n}"
            )
        ]
        
        return CodeStyleRecommendations(
            language: language,
            recommendations: defaultRecommendations,
            overallConfidence: 0.5,
            basedOnPatterns: 0
        )
    }
}

/// Individual code recommendation
public struct CodeRecommendation: Codable, Hashable {
    public let type: CodePatternType
    public let suggestion: String
    public let confidence: Double
    public let rationale: String
    public let example: String
}

/// Analytics about the learning process
public struct CodeLearningAnalytics: Codable, Hashable {
    public let totalPatterns: Int
    public let languagesLearned: Int
    public let confidenceScore: Double
    public let learningProgress: Double
    public let mostCommonPatterns: [CodePattern]
    public let styleEvolution: StyleEvolution
    public let improvementSuggestions: [String]
}

/// Evolution of coding style over time
public struct StyleEvolution: Codable, Hashable {
    public let recentPatterns: Int
    public let historicalPatterns: Int
    public let evolutionTrend: EvolutionTrend
    public let keyChanges: [String]
}

/// Trend in style evolution
public enum EvolutionTrend: String, Codable, CaseIterable, Hashable {
    case improving
    case stable
    case declining
}

// MARK: - Pattern Storage

/// Handles persistent storage of learned patterns
private class PatternStorage {
    private let documentsURL: URL
    private let patternsFileName = "learned_patterns.json"
    private let preferencesFileName = "style_preferences.json"
    
    init() {
        documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func save(patterns: [CodePattern]) async {
        do {
            let patternsURL = documentsURL.appendingPathComponent(patternsFileName)
            let data = try JSONEncoder().encode(patterns)
            try data.write(to: patternsURL)
        } catch {
            print("⚠️ Failed to save patterns: \(error)")
        }
    }
    
    func loadPatterns() async -> [CodePattern] {
        do {
            let patternsURL = documentsURL.appendingPathComponent(patternsFileName)
            let data = try Data(contentsOf: patternsURL)
            return try JSONDecoder().decode([CodePattern].self, from: data)
        } catch {
            return []
        }
    }
    
    func savePreferences(_ preferences: CodeStylePreferences) async {
        do {
            let preferencesURL = documentsURL.appendingPathComponent(preferencesFileName)
            let data = try JSONEncoder().encode(preferences)
            try data.write(to: preferencesURL)
        } catch {
            print("⚠️ Failed to save preferences: \(error)")
        }
    }
    
    func loadPreferences() async -> CodeStylePreferences? {
        do {
            let preferencesURL = documentsURL.appendingPathComponent(preferencesFileName)
            let data = try Data(contentsOf: preferencesURL)
            return try JSONDecoder().decode(CodeStylePreferences.self, from: data)
        } catch {
            return nil
        }
    }
}
