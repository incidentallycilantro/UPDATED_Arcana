//
// Core/TemporalCodeIntelligence.swift
// Arcana
//

import Foundation
import OSLog

@MainActor
class TemporalCodeIntelligence: ObservableObject {
    @Published var codeVersions: [CodeVersion] = []
    @Published var evolutionMetrics = CodeEvolutionMetrics()
    @Published var currentSession: CodingSession?
    @Published var patterns: [CodePattern] = []
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "TemporalCodeIntelligence")
    private let semanticVersioning: SemanticVersioning
    private let patternLearning: CodePatternLearning
    private var codeHistory: [CodeSnapshot] = []
    private var sessionTimer: Timer?
    
    init() {
        self.semanticVersioning = SemanticVersioning()
        self.patternLearning = CodePatternLearning()
    }
    
    func initialize() async throws {
        logger.info("Initializing Temporal Code Intelligence...")
        
        try await semanticVersioning.initialize()
        try await patternLearning.initialize()
        
        await loadCodeHistory()
        startSessionTracking()
        
        logger.info("Temporal Code Intelligence initialized")
    }
    
    func trackCodeEvolution(_ code: String, language: CodeLanguage, context: ConversationContext) async -> CodeEvolutionResult {
        logger.debug("Tracking code evolution for \(language.rawValue)")
        
        let snapshot = CodeSnapshot(
            code: code,
            language: language,
            timestamp: Date(),
            conversationId: context.threadId,
            workspaceType: context.workspaceType
        )
        
        // Add to history
        codeHistory.append(snapshot)
        
        // Analyze evolution
        let evolution = await analyzeEvolution(snapshot: snapshot)
        
        // Learn patterns
        await patternLearning.learnFromCode(code, language: language, context: context)
        
        // Update metrics
        await updateEvolutionMetrics(evolution)
        
        // Generate semantic version
        let version = await semanticVersioning.generateVersion(for: evolution)
        
        let result = CodeEvolutionResult(
            snapshot: snapshot,
            evolution: evolution,
            version: version,
            patterns: await patternLearning.getRelevantPatterns(for: code, language: language),
            suggestions: generateEvolutionSuggestions(evolution)
        )
        
        // Record version
        await recordCodeVersion(result)
        
        return result
    }
    
    func getCodeHistory(for language: CodeLanguage? = nil, limit: Int = 50) -> [CodeSnapshot] {
        let filtered = if let language = language {
            codeHistory.filter { $0.language == language }
        } else {
            codeHistory
        }
        
        return Array(filtered.suffix(limit))
    }
    
    func analyzeCodingPatterns(timeframe: TimeFrame = .lastWeek) -> CodingPatternAnalysis {
        let cutoffDate = getCutoffDate(for: timeframe)
        let recentHistory = codeHistory.filter { $0.timestamp > cutoffDate }
        
        let languageDistribution = Dictionary(grouping: recentHistory, by: \.language)
            .mapValues { $0.count }
        
        let hourlyDistribution = Dictionary(grouping: recentHistory, by: {
            Calendar.current.component(.hour, from: $0.timestamp)
        }).mapValues { $0.count }
        
        let complexity = calculateAverageComplexity(recentHistory)
        let productivity = calculateProductivity(recentHistory, timeframe: timeframe)
        
        return CodingPatternAnalysis(
            timeframe: timeframe,
            totalSessions: recentHistory.count,
            languageDistribution: languageDistribution,
            hourlyDistribution: hourlyDistribution,
            averageComplexity: complexity,
            productivityScore: productivity,
            trends: identifyTrends(recentHistory)
        )
    }
    
    func predictNextCode(context: ConversationContext, partialCode: String = "") -> CodePrediction {
        logger.debug("Predicting next code based on context and patterns")
        
        let relevantHistory = getRelevantHistory(for: context)
        let patterns = patternLearning.getApplicablePatterns(
            history: relevantHistory,
            partialCode: partialCode
        )
        
        let suggestions = generateCodeSuggestions(
            based: patterns,
            context: context,
            partialCode: partialCode
        )
        
        let confidence = calculatePredictionConfidence(
            patterns: patterns,
            historySize: relevantHistory.count
        )
        
        return CodePrediction(
            suggestions: suggestions,
            confidence: confidence,
            patterns: patterns,
            reasoning: generatePredictionReasoning(patterns, context)
        )
    }
    
    func getRefactoringOpportunities(_ code: String, language: CodeLanguage) async -> [RefactoringOpportunity] {
        logger.debug("Analyzing refactoring opportunities")
        
        var opportunities: [RefactoringOpportunity] = []
        
        // Analyze code complexity
        let complexity = calculateCodeComplexity(code, language: language)
        if complexity > 0.8 {
            opportunities.append(RefactoringOpportunity(
                type: .reduceComplexity,
                description: "Code complexity is high, consider breaking into smaller functions",
                severity: .high,
                codeLocation: findComplexSections(code),
                suggestedApproach: "Extract method pattern"
            ))
        }
        
        // Check for duplicate patterns
        let duplicates = await findDuplicatePatterns(code, language: language)
        for duplicate in duplicates {
            opportunities.append(RefactoringOpportunity(
                type: .removeDuplication,
                description: "Duplicate code pattern detected",
                severity: .medium,
                codeLocation: duplicate.location,
                suggestedApproach: "Extract common functionality"
            ))
        }
        
        // Analyze naming conventions
        let namingIssues = analyzeNamingConventions(code, language: language)
        for issue in namingIssues {
            opportunities.append(RefactoringOpportunity(
                type: .improveNaming,
                description: issue.description,
                severity: .low,
                codeLocation: issue.location,
                suggestedApproach: issue.suggestion
            ))
        }
        
        return opportunities
    }
    
    func startCodingSession(language: CodeLanguage, workspaceType: WorkspaceType) {
        logger.info("Starting coding session: \(language.rawValue)")
        
        let session = CodingSession(
            id: UUID(),
            language: language,
            workspaceType: workspaceType,
            startTime: Date(),
            codeSnapshots: []
        )
        
        currentSession = session
        
        // Start session timer
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.updateCurrentSession()
            }
        }
    }
    
    func endCodingSession() async -> CodingSessionSummary? {
        guard let session = currentSession else { return nil }
        
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        let summary = await generateSessionSummary(session)
        
        currentSession = nil
        
        logger.info("Ended coding session: \(session.language.rawValue), duration: \(summary.duration)")
        return summary
    }
    
    // MARK: - Private Methods
    
    private func loadCodeHistory() async {
        // Load code history from storage
        codeHistory = []
        logger.debug("Loaded code history")
    }
    
    private func startSessionTracking() {
        logger.debug("Started session tracking")
    }
    
    private func analyzeEvolution(snapshot: CodeSnapshot) async -> CodeEvolution {
        let previousSnapshots = codeHistory.filter {
            $0.language == snapshot.language && $0.timestamp < snapshot.timestamp
        }.suffix(5)
        
        if previousSnapshots.isEmpty {
            return CodeEvolution(
                type: .initial,
                changes: [.creation],
                complexity: calculateCodeComplexity(snapshot.code, language: snapshot.language),
                linesAdded: snapshot.code.components(separatedBy: .newlines).count,
                linesRemoved: 0,
                functionsAdded: countFunctions(snapshot.code, language: snapshot.language),
                functionsRemoved: 0
            )
        }
        
        let lastSnapshot = previousSnapshots.last!
        let changes = detectChanges(from: lastSnapshot.code, to: snapshot.code, language: snapshot.language)
        
        return CodeEvolution(
            type: determineEvolutionType(changes),
            changes: changes,
            complexity: calculateCodeComplexity(snapshot.code, language: snapshot.language),
            linesAdded: countAddedLines(from: lastSnapshot.code, to: snapshot.code),
            linesRemoved: countRemovedLines(from: lastSnapshot.code, to: snapshot.code),
            functionsAdded: countFunctions(snapshot.code, language: snapshot.language) - countFunctions(lastSnapshot.code, language: snapshot.language),
            functionsRemoved: max(0, countFunctions(lastSnapshot.code, language: snapshot.language) - countFunctions(snapshot.code, language: snapshot.language))
        )
    }
    
    private func detectChanges(from oldCode: String, to newCode: String, language: CodeLanguage) -> [CodeChange] {
        var changes: [CodeChange] = []
        
        let oldLines = oldCode.components(separatedBy: .newlines)
        let newLines = newCode.components(separatedBy: .newlines)
        
        // Simple diff algorithm
        if newLines.count > oldLines.count {
            changes.append(.addition)
        } else if newLines.count < oldLines.count {
            changes.append(.deletion)
        }
        
        // Check for function changes
        let oldFunctionCount = countFunctions(oldCode, language: language)
        let newFunctionCount = countFunctions(newCode, language: language)
        
        if newFunctionCount > oldFunctionCount {
            changes.append(.functionAddition)
        } else if newFunctionCount < oldFunctionCount {
            changes.append(.functionRemoval)
        }
        
        // Check for refactoring patterns
        if hasRefactoringPatterns(from: oldCode, to: newCode) {
            changes.append(.refactoring)
        }
        
        return changes.isEmpty ? [.modification] : changes
    }
    
    private func determineEvolutionType(_ changes: [CodeChange]) -> EvolutionType {
        if changes.contains(.functionAddition) || changes.contains(.addition) {
            return .expansion
        } else if changes.contains(.functionRemoval) || changes.contains(.deletion) {
            return .reduction
        } else if changes.contains(.refactoring) {
            return .refactoring
        } else {
            return .modification
        }
    }
    
    private func calculateCodeComplexity(_ code: String, language: CodeLanguage) -> Double {
        let lines = code.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let functions = countFunctions(code, language: language)
        let conditionals = countConditionals(code, language: language)
        let loops = countLoops(code, language: language)
        
        // Simple complexity calculation
        let baseComplexity = Double(lines.count) * 0.01
        let functionComplexity = Double(functions) * 0.1
        let conditionalComplexity = Double(conditionals) * 0.05
        let loopComplexity = Double(loops) * 0.08
        
        return min(1.0, baseComplexity + functionComplexity + conditionalComplexity + loopComplexity)
    }
    
    private func countFunctions(_ code: String, language: CodeLanguage) -> Int {
        switch language {
        case .swift:
            return code.components(separatedBy: "func ").count - 1
        case .python:
            return code.components(separatedBy: "def ").count - 1
        case .javascript:
            return code.components(separatedBy: "function ").count - 1 +
                   code.components(separatedBy: " => ").count - 1
        case .other:
            return 0
        }
    }
    
    private func countConditionals(_ code: String, language: CodeLanguage) -> Int {
        let patterns = ["if ", "else", "switch", "case", "when"]
        return patterns.reduce(0) { count, pattern in
            count + (code.components(separatedBy: pattern).count - 1)
        }
    }
    
    private func countLoops(_ code: String, language: CodeLanguage) -> Int {
        let patterns = ["for ", "while ", "repeat", "forEach"]
        return patterns.reduce(0) { count, pattern in
            count + (code.components(separatedBy: pattern).count - 1)
        }
    }
    
    private func countAddedLines(from oldCode: String, to newCode: String) -> Int {
        let oldLineCount = oldCode.components(separatedBy: .newlines).count
        let newLineCount = newCode.components(separatedBy: .newlines).count
        return max(0, newLineCount - oldLineCount)
    }
    
    private func countRemovedLines(from oldCode: String, to newCode: String) -> Int {
        let oldLineCount = oldCode.components(separatedBy: .newlines).count
        let newLineCount = newCode.components(separatedBy: .newlines).count
        return max(0, oldLineCount - newLineCount)
    }
    
    private func hasRefactoringPatterns(from oldCode: String, to newCode: String) -> Bool {
        // Check for common refactoring patterns
        let oldFunctionCount = countFunctions(oldCode, language: .swift)
        let newFunctionCount = countFunctions(newCode, language: .swift)
        
        // If function count increased but total lines didn't increase proportionally,
        // it might be extract method refactoring
        let oldLines = oldCode.components(separatedBy: .newlines).count
        let newLines = newCode.components(separatedBy: .newlines).count
        
        if newFunctionCount > oldFunctionCount && (newLines - oldLines) < (newFunctionCount - oldFunctionCount) * 5 {
            return true
        }
        
        return false
    }
    
    private func getCutoffDate(for timeframe: TimeFrame) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch timeframe {
        case .lastDay:
            return calendar.date(byAdding: .day, value: -1, to: now) ?? now
        case .lastWeek:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .lastMonth:
            return calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .lastYear:
            return calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
    }
    
    private func calculateAverageComplexity(_ snapshots: [CodeSnapshot]) -> Double {
        guard !snapshots.isEmpty else { return 0.0 }
        
        let complexities = snapshots.map { calculateCodeComplexity($0.code, language: $0.language) }
        return complexities.reduce(0, +) / Double(complexities.count)
    }
    
    private func calculateProductivity(_ snapshots: [CodeSnapshot], timeframe: TimeFrame) -> Double {
        guard !snapshots.isEmpty else { return 0.0 }
        
        let totalLines = snapshots.reduce(0) { count, snapshot in
            count + snapshot.code.components(separatedBy: .newlines).count
        }
        
        let timeframeDays = timeframe.days
        return Double(totalLines) / Double(timeframeDays)
    }
    
    private func identifyTrends(_ snapshots: [CodeSnapshot]) -> [CodeTrend] {
        var trends: [CodeTrend] = []
        
        // Analyze complexity trend
        let complexities = snapshots.map { calculateCodeComplexity($0.code, language: $0.language) }
        if complexities.count > 1 {
            let trend = complexities.last! > complexities.first! ? TrendDirection.increasing : .decreasing
            trends.append(CodeTrend(type: .complexity, direction: trend))
        }
        
        // Analyze activity trend
        let dailyActivity = Dictionary(grouping: snapshots, by: {
            Calendar.current.startOfDay(for: $0.timestamp)
        }).mapValues { $0.count }
        
        if dailyActivity.count > 1 {
            let sortedDays = dailyActivity.keys.sorted()
            let recentActivity = dailyActivity[sortedDays.last!] ?? 0
            let earlierActivity = dailyActivity[sortedDays.first!] ?? 0
            
            let activityTrend = recentActivity > earlierActivity ? TrendDirection.increasing : .decreasing
            trends.append(CodeTrend(type: .activity, direction: activityTrend))
        }
        
        return trends
    }
    
    private func getRelevantHistory(for context: ConversationContext) -> [CodeSnapshot] {
        return codeHistory.filter { snapshot in
            snapshot.workspaceType == context.workspaceType &&
            snapshot.timestamp > Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        }
    }
    
    private func generateCodeSuggestions(
        based patterns: [CodePattern],
        context: ConversationContext,
        partialCode: String
    ) -> [CodeSuggestion] {
        
        var suggestions: [CodeSuggestion] = []
        
        for pattern in patterns.prefix(3) {
            let suggestion = CodeSuggestion(
                code: pattern.template,
                description: pattern.description,
                confidence: pattern.frequency,
                type: .completion
            )
            suggestions.append(suggestion)
        }
        
        return suggestions
    }
    
    private func calculatePredictionConfidence(patterns: [CodePattern], historySize: Int) -> Double {
        guard !patterns.isEmpty && historySize > 0 else { return 0.1 }
        
        let patternConfidence = patterns.map(\.frequency).reduce(0, +) / Double(patterns.count)
        let historyConfidence = min(1.0, Double(historySize) / 20.0) // More history = higher confidence
        
        return (patternConfidence + historyConfidence) / 2.0
    }
    
    private func generatePredictionReasoning(_ patterns: [CodePattern], _ context: ConversationContext) -> String {
        if patterns.isEmpty {
            return "No similar patterns found in coding history"
        }
        
        let topPattern = patterns.max(by: { $0.frequency < $1.frequency })!
        return "Based on \(patterns.count) similar patterns, most commonly: \(topPattern.description)"
    }
    
    private func findDuplicatePatterns(_ code: String, language: CodeLanguage) async -> [DuplicatePattern] {
        // Simplified duplicate detection
        return []
    }
    
    private func analyzeNamingConventions(_ code: String, language: CodeLanguage) -> [NamingIssue] {
        // Simplified naming analysis
        return []
    }
    
    private func findComplexSections(_ code: String) -> String {
        // Find the most complex part of the code
        let lines = code.components(separatedBy: .newlines)
        let midPoint = lines.count / 2
        return "Lines \(max(1, midPoint - 5))-\(min(lines.count, midPoint + 5))"
    }
    
    private func updateEvolutionMetrics(_ evolution: CodeEvolution) async {
        await MainActor.run {
            self.evolutionMetrics.totalEvolutions += 1
            self.evolutionMetrics.lastEvolution = Date()
            self.evolutionMetrics.averageComplexity = (self.evolutionMetrics.averageComplexity + evolution.complexity) / 2.0
        }
    }
    
    private func generateEvolutionSuggestions(_ evolution: CodeEvolution) -> [String] {
        var suggestions: [String] = []
        
        if evolution.complexity > 0.8 {
            suggestions.append("Consider refactoring to reduce complexity")
        }
        
        if evolution.functionsAdded > 3 {
            suggestions.append("Good progress adding functionality")
        }
        
        if evolution.type == .refactoring {
            suggestions.append("Excellent refactoring work!")
        }
        
        return suggestions
    }
    
    private func recordCodeVersion(_ result: CodeEvolutionResult) async {
        let version = CodeVersion(
            id: UUID(),
            code: result.snapshot.code,
            version: result.version,
            language: result.snapshot.language,
            evolution: result.evolution,
            timestamp: result.snapshot.timestamp
        )
        
        await MainActor.run {
            self.codeVersions.append(version)
            
            // Keep only recent versions
            if self.codeVersions.count > 100 {
                self.codeVersions.removeFirst()
            }
        }
    }
    
    private func updateCurrentSession() async {
        guard var session = currentSession else { return }
        
        session.lastActivity = Date()
        currentSession = session
    }
    
    private func generateSessionSummary(_ session: CodingSession) async -> CodingSessionSummary {
        let duration = (session.endTime ?? Date()).timeIntervalSince(session.startTime)
        
        return CodingSessionSummary(
            sessionId: session.id,
            language: session.language,
            duration: duration,
            snapshotsCount: session.codeSnapshots.count,
            linesWritten: session.codeSnapshots.reduce(0) { count, snapshot in
                count + snapshot.code.components(separatedBy: .newlines).count
            },
            averageComplexity: session.codeSnapshots.isEmpty ? 0.0 :
                session.codeSnapshots.map { calculateCodeComplexity($0.code, language: $0.language) }
                    .reduce(0, +) / Double(session.codeSnapshots.count)
        )
    }
}

// MARK: - Supporting Types

enum CodeLanguage: String, CaseIterable, Codable {
    case swift = "swift"
    case python = "python"
    case javascript = "javascript"
    case other = "other"
}

struct CodeSnapshot {
    let code: String
    let language: CodeLanguage
    let timestamp: Date
    let conversationId: UUID
    let workspaceType: WorkspaceType
}

struct CodeEvolution {
    let type: EvolutionType
    let changes: [CodeChange]
    let complexity: Double
    let linesAdded: Int
    let linesRemoved: Int
    let functionsAdded: Int
    let functionsRemoved: Int
}

enum EvolutionType {
    case initial
    case expansion
    case reduction
    case refactoring
    case modification
}

enum CodeChange {
    case creation
    case addition
    case deletion
    case modification
    case refactoring
    case functionAddition
    case functionRemoval
}

struct CodeEvolutionResult {
    let snapshot: CodeSnapshot
    let evolution: CodeEvolution
    let version: String
    let patterns: [CodePattern]
    let suggestions: [String]
}

struct CodeEvolutionMetrics {
    var totalEvolutions: Int = 0
    var lastEvolution: Date?
    var averageComplexity: Double = 0.0
}

enum TimeFrame {
    case lastDay
    case lastWeek
    case lastMonth
    case lastYear
    
    var days: Int {
        switch self {
        case .lastDay: return 1
        case .lastWeek: return 7
        case .lastMonth: return 30
        case .lastYear: return 365
        }
    }
}

struct CodingPatternAnalysis {
    let timeframe: TimeFrame
    let totalSessions: Int
    let languageDistribution: [CodeLanguage: Int]
    let hourlyDistribution: [Int: Int]
    let averageComplexity: Double
    let productivityScore: Double
    let trends: [CodeTrend]
}

struct CodeTrend {
    let type: TrendType
    let direction: TrendDirection
    
    enum TrendType {
        case complexity
        case activity
        case productivity
    }
}

enum TrendDirection {
    case increasing
    case decreasing
    case stable
}

struct CodePrediction {
    let suggestions: [CodeSuggestion]
    let confidence: Double
    let patterns: [CodePattern]
    let reasoning: String
}

struct CodeSuggestion {
    let code: String
    let description: String
    let confidence: Double
    let type: SuggestionType
    
    enum SuggestionType {
        case completion
        case refactoring
        case optimization
        case bugfix
    }
}

struct RefactoringOpportunity {
    let type: RefactoringType
    let description: String
    let severity: Severity
    let codeLocation: String
    let suggestedApproach: String
    
    enum RefactoringType {
        case reduceComplexity
        case removeDuplication
        case improveNaming
        case extractMethod
        case simplifyConditions
    }
    
    enum Severity {
        case low
        case medium
        case high
    }
}

struct CodingSession {
    let id: UUID
    let language: CodeLanguage
    let workspaceType: WorkspaceType
    let startTime: Date
    var endTime: Date?
    var lastActivity: Date?
    var codeSnapshots: [CodeSnapshot]
}

struct CodingSessionSummary {
    let sessionId: UUID
    let language: CodeLanguage
    let duration: TimeInterval
    let snapshotsCount: Int
    let linesWritten: Int
    let averageComplexity: Double
}

struct CodeVersion {
    let id: UUID
    let code: String
    let version: String
    let language: CodeLanguage
    let evolution: CodeEvolution
    let timestamp: Date
}

struct DuplicatePattern {
    let location: String
}

struct NamingIssue {
    let description: String
    let location: String
    let suggestion: String
}

// Forward declaration for CodePattern (defined in CodePatternLearning.swift)
struct CodePattern {
    let template: String
    let description: String
    let frequency: Double
}
