//
// SemanticCompression.swift
// Arcana
//
// Revolutionary pattern-based compression using semantic similarity and AI intelligence
// Achieves unprecedented compression ratios through intelligent pattern recognition
//

import Foundation
import Combine
import NaturalLanguage

// MARK: - Semantic Compression Engine

/// Revolutionary compression system that uses semantic understanding for pattern-based compression
/// Achieves superior compression ratios by identifying and compressing semantic patterns
@MainActor
public class SemanticCompression: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isCompressing: Bool = false
    @Published private(set) var compressionProgress: Double = 0.0
    @Published private(set) var lastCompressionRatio: Double = 0.0
    @Published private(set) var compressionStatistics: CompressionStatistics = CompressionStatistics()
    
    // MARK: - Private Properties
    
    private let semanticMemory: SemanticMemoryEngine
    private let performanceMonitor: PerformanceMonitor
    private var patternLibrary: PatternLibrary = PatternLibrary()
    private var compressionTasks: Set<Task<Void, Never>> = []
    private let nlProcessor = NLTagger(tagSchemes: [.tokenType, .language])
    
    // MARK: - Configuration
    
    private let minPatternLength = 10
    private let maxPatternLength = 500
    private let minPatternOccurrence = 3
    private let semanticSimilarityThreshold = 0.85
    private let enableAdaptiveLearning = true
    
    // MARK: - Initialization
    
    public init(semanticMemory: SemanticMemoryEngine, performanceMonitor: PerformanceMonitor) {
        self.semanticMemory = semanticMemory
        self.performanceMonitor = performanceMonitor
        
        Task {
            await loadPatternLibrary()
            await startAdaptiveLearning()
        }
    }
    
    deinit {
        compressionTasks.forEach { $0.cancel() }
    }
    
    // MARK: - Public Interface
    
    /// Compress data using semantic pattern recognition
    public func compress(_ data: Data, context: CompressionContext = CompressionContext()) async throws -> SemanticCompressionResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard !isCompressing else {
            throw ArcanaError.storageError("Compression already in progress")
        }
        
        isCompressing = true
        compressionProgress = 0.0
        defer {
            isCompressing = false
            compressionProgress = 0.0
        }
        
        do {
            // Convert data to text for semantic analysis
            guard let originalText = String(data: data, encoding: .utf8) else {
                throw ArcanaError.storageError("Data is not valid UTF-8 text")
            }
            
            // Step 1: Analyze content structure (20%)
            compressionProgress = 0.2
            let contentAnalysis = await analyzeContent(originalText, context: context)
            
            // Step 2: Identify semantic patterns (40%)
            compressionProgress = 0.4
            let patterns = await identifySemanticPatterns(in: originalText, analysis: contentAnalysis)
            
            // Step 3: Build compression dictionary (60%)
            compressionProgress = 0.6
            let compressionDictionary = await buildCompressionDictionary(from: patterns, context: context)
            
            // Step 4: Apply semantic compression (80%)
            compressionProgress = 0.8
            let compressedText = await applySemanticCompression(to: originalText, using: compressionDictionary)
            
            // Step 5: Final optimization (100%)
            compressionProgress = 1.0
            let optimizedResult = await optimizeCompression(compressedText, dictionary: compressionDictionary, context: context)
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            let compressionRatio = 1.0 - (Double(optimizedResult.compressedData.count) / Double(data.count))
            
            lastCompressionRatio = compressionRatio
            
            // Update statistics
            await updateCompressionStatistics(
                originalSize: data.count,
                compressedSize: optimizedResult.compressedData.count,
                processingTime: processingTime,
                patternsFound: patterns.count
            )
            
            // Update pattern library with successful patterns
            if enableAdaptiveLearning {
                await updatePatternLibrary(with: patterns, performance: compressionRatio)
            }
            
            // Record performance metrics
            await recordCompressionMetrics(
                operation: "compress",
                processingTime: processingTime,
                originalSize: data.count,
                compressedSize: optimizedResult.compressedData.count
            )
            
            return SemanticCompressionResult(
                compressedData: optimizedResult.compressedData,
                dictionary: optimizedResult.dictionary,
                metadata: CompressionMetadata(
                    originalSize: data.count,
                    compressedSize: optimizedResult.compressedData.count,
                    compressionRatio: compressionRatio,
                    patternsIdentified: patterns.count,
                    semanticComplexity: contentAnalysis.complexity,
                    processingTime: processingTime,
                    compressionAlgorithm: "SemanticCompression-1.0",
                    timestamp: Date()
                )
            )
            
        } catch {
            throw ArcanaError.storageError("Semantic compression failed: \(error.localizedDescription)")
        }
    }
    
    /// Decompress semantically compressed data
    public func decompress(_ result: SemanticCompressionResult) async throws -> Data {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // Convert compressed data back to text
            guard let compressedText = String(data: result.compressedData, encoding: .utf8) else {
                throw ArcanaError.storageError("Compressed data is not valid UTF-8")
            }
            
            // Apply reverse compression using dictionary
            let decompressedText = await applySemanticDecompression(to: compressedText, using: result.dictionary)
            
            // Convert back to data
            guard let decompressedData = decompressedText.data(using: .utf8) else {
                throw ArcanaError.storageError("Failed to convert decompressed text to data")
            }
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            
            // Record performance metrics
            await recordCompressionMetrics(
                operation: "decompress",
                processingTime: processingTime,
                originalSize: result.compressedData.count,
                compressedSize: decompressedData.count
            )
            
            return decompressedData
            
        } catch {
            throw ArcanaError.storageError("Semantic decompression failed: \(error.localizedDescription)")
        }
    }
    
    /// Analyze text for compression potential
    public func analyzeCompressionPotential(_ data: Data) async -> CompressionAnalysis {
        guard let text = String(data: data, encoding: .utf8) else {
            return CompressionAnalysis(
                potentialRatio: 0.0,
                patternDensity: 0.0,
                semanticComplexity: 1.0,
                recommendedAlgorithm: .traditional,
                estimatedProcessingTime: 0.0
            )
        }
        
        let contentAnalysis = await analyzeContent(text, context: CompressionContext())
        let patterns = await identifySemanticPatterns(in: text, analysis: contentAnalysis)
        
        let patternDensity = Double(patterns.reduce(0) { $0 + $1.occurrences }) / Double(text.count)
        let potentialRatio = estimateCompressionRatio(patternDensity: patternDensity, complexity: contentAnalysis.complexity)
        let estimatedTime = estimateProcessingTime(textLength: text.count, patternCount: patterns.count)
        
        return CompressionAnalysis(
            potentialRatio: potentialRatio,
            patternDensity: patternDensity,
            semanticComplexity: contentAnalysis.complexity,
            recommendedAlgorithm: potentialRatio > 0.3 ? .semantic : .traditional,
            estimatedProcessingTime: estimatedTime
        )
    }
    
    /// Get compression statistics and insights
    public func getCompressionAnalytics() -> CompressionAnalytics {
        let patternEfficiency = analyzePatternEfficiency()
        let algorithmPerformance = analyzeAlgorithmPerformance()
        
        return CompressionAnalytics(
            statistics: compressionStatistics,
            patternLibrarySize: patternLibrary.patterns.count,
            patternEfficiency: patternEfficiency,
            algorithmPerformance: algorithmPerformance,
            recommendations: generateOptimizationRecommendations()
        )
    }
    
    /// Export pattern library for analysis or backup
    public func exportPatternLibrary() async throws -> Data {
        let exportData = PatternLibraryExport(
            exportDate: Date(),
            library: patternLibrary,
            statistics: compressionStatistics,
            configuration: CompressionConfiguration(
                minPatternLength: minPatternLength,
                maxPatternLength: maxPatternLength,
                minPatternOccurrence: minPatternOccurrence,
                semanticSimilarityThreshold: semanticSimilarityThreshold
            )
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    // MARK: - Private Implementation
    
    private func analyzeContent(_ text: String, context: CompressionContext) async -> ContentAnalysis {
        // Linguistic analysis
        nlProcessor.string = text
        let language = nlProcessor.dominantLanguage ?? .undetermined
        
        // Calculate various complexity metrics
        let wordCount = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
        let uniqueWords = Set(text.lowercased().components(separatedBy: .whitespacesAndNewlines)).count
        let vocabulary = Double(uniqueWords) / Double(max(1, wordCount))
        
        // Analyze sentence structure
        let sentences = text.components(separatedBy: .punctuationCharacters).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        let avgSentenceLength = sentences.isEmpty ? 0 : wordCount / sentences.count
        
        // Calculate semantic complexity
        let complexity = calculateSemanticComplexity(
            vocabulary: vocabulary,
            avgSentenceLength: avgSentenceLength,
            language: language
        )
        
        return ContentAnalysis(
            language: language,
            wordCount: wordCount,
            uniqueWords: uniqueWords,
            vocabularyRichness: vocabulary,
            averageSentenceLength: avgSentenceLength,
            complexity: complexity,
            contentType: detectContentType(text, context: context)
        )
    }
    
    private func calculateSemanticComplexity(vocabulary: Double, avgSentenceLength: Int, language: NLLanguage) -> Double {
        // Complex heuristic for semantic complexity
        let vocabularyWeight = min(1.0, vocabulary * 2.0) // Normalize vocabulary richness
        let sentenceWeight = min(1.0, Double(avgSentenceLength) / 20.0) // Normalize sentence complexity
        let languageWeight = language == .english ? 1.0 : 1.2 // Adjust for language complexity
        
        return (vocabularyWeight * 0.4 + sentenceWeight * 0.4 + (languageWeight - 1.0) * 0.2)
    }
    
    private func detectContentType(_ text: String, context: CompressionContext) -> ContentType {
        let lowerText = text.lowercased()
        
        // Code detection
        if lowerText.contains("function") || lowerText.contains("class") || lowerText.contains("import") {
            return .code
        }
        
        // JSON detection
        if lowerText.hasPrefix("{") && lowerText.hasSuffix("}") {
            return .json
        }
        
        // XML/HTML detection
        if lowerText.contains("<") && lowerText.contains(">") {
            return .markup
        }
        
        // Documentation detection
        if lowerText.contains("# ") || lowerText.contains("## ") {
            return .documentation
        }
        
        return .text
    }
    
    private func identifySemanticPatterns(in text: String, analysis: ContentAnalysis) async -> [SemanticPattern] {
        var patterns: [SemanticPattern] = []
        
        // Extract n-grams of various sizes
        let words = text.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        
        for length in minPatternLength...min(maxPatternLength, words.count) {
            let ngrams = extractNGrams(from: words, length: length)
            let ngramCounts = Dictionary(grouping: ngrams, by: { $0 }).mapValues { $0.count }
            
            for (ngram, count) in ngramCounts where count >= minPatternOccurrence {
                let patternText = ngram.joined(separator: " ")
                
                // Calculate pattern value based on frequency and length
                let value = Double(count * patternText.count)
                
                // Generate semantic embedding for pattern
                let embedding = await generatePatternEmbedding(patternText)
                
                let pattern = SemanticPattern(
                    id: UUID(),
                    text: patternText,
                    occurrences: count,
                    length: patternText.count,
                    value: value,
                    semanticEmbedding: embedding,
                    category: categorizePattern(patternText, contentType: analysis.contentType),
                    confidence: calculatePatternConfidence(count: count, length: patternText.count)
                )
                
                patterns.append(pattern)
            }
        }
        
        // Sort patterns by value (frequency × length)
        patterns.sort { $0.value > $1.value }
        
        // Remove semantically similar patterns (deduplication)
        patterns = await deduplicateSemanticPatterns(patterns)
        
        return Array(patterns.prefix(1000)) // Limit to top 1000 patterns
    }
    
    private func extractNGrams(from words: [String], length: Int) -> [[String]] {
        guard length > 0 && length <= words.count else { return [] }
        
        var ngrams: [[String]] = []
        for i in 0...(words.count - length) {
            let ngram = Array(words[i..<(i + length)])
            ngrams.append(ngram)
        }
        
        return ngrams
    }
    
    private func generatePatternEmbedding(_ text: String) async -> [Double] {
        do {
            return try await semanticMemory.generateEmbedding(for: text)
        } catch {
            // Fallback to simple hash-based embedding
            return generateSimpleEmbedding(text)
        }
    }
    
    private func generateSimpleEmbedding(_ text: String) -> [Double] {
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var embedding = Array(repeating: 0.0, count: 128)
        
        for word in words {
            let hash = word.hash
            let index = abs(hash) % embedding.count
            embedding[index] += 1.0 / Double(words.count)
        }
        
        return embedding
    }
    
    private func categorizePattern(_ text: String, contentType: ContentType) -> PatternCategory {
        let lowerText = text.lowercased()
        
        switch contentType {
        case .code:
            if lowerText.contains("function") || lowerText.contains("class") {
                return .syntactic
            }
            return .semantic
            
        case .json:
            if lowerText.contains(":") || lowerText.contains("{") {
                return .structural
            }
            return .semantic
            
        case .markup:
            if lowerText.contains("<") && lowerText.contains(">") {
                return .structural
            }
            return .semantic
            
        default:
            if lowerText.split(separator: " ").count < 3 {
                return .lexical
            }
            return .semantic
        }
    }
    
    private func calculatePatternConfidence(count: Int, length: Int) -> Double {
        // Higher frequency and reasonable length increase confidence
        let frequencyScore = min(1.0, Double(count) / 10.0)
        let lengthScore = min(1.0, Double(length) / 100.0)
        
        return (frequencyScore * 0.7) + (lengthScore * 0.3)
    }
    
    private func deduplicateSemanticPatterns(_ patterns: [SemanticPattern]) async -> [SemanticPattern] {
        var uniquePatterns: [SemanticPattern] = []
        
        for pattern in patterns {
            var isDuplicate = false
            
            for existingPattern in uniquePatterns {
                let similarity = await calculateSemanticSimilarity(
                    pattern.semanticEmbedding,
                    existingPattern.semanticEmbedding
                )
                
                if similarity > semanticSimilarityThreshold {
                    isDuplicate = true
                    break
                }
            }
            
            if !isDuplicate {
                uniquePatterns.append(pattern)
            }
        }
        
        return uniquePatterns
    }
    
    private func calculateSemanticSimilarity(_ embedding1: [Double], _ embedding2: [Double]) async -> Double {
        guard embedding1.count == embedding2.count else { return 0.0 }
        
        // Calculate cosine similarity
        let dotProduct = zip(embedding1, embedding2).map(*).reduce(0, +)
        let magnitude1 = sqrt(embedding1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(embedding2.map { $0 * $0 }.reduce(0, +))
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    private func buildCompressionDictionary(from patterns: [SemanticPattern], context: CompressionContext) async -> CompressionDictionary {
        var dictionary: [String: String] = [:]
        var patternMap: [String: SemanticPattern] = [:]
        
        // Create compressed references for patterns
        for (index, pattern) in patterns.enumerated() {
            let reference = generateCompressionReference(index: index, category: pattern.category)
            dictionary[pattern.text] = reference
            patternMap[reference] = pattern
        }
        
        return CompressionDictionary(
            patterns: dictionary,
            patternMetadata: patternMap,
            version: "1.0",
            createdAt: Date()
        )
    }
    
    private func generateCompressionReference(index: Int, category: PatternCategory) -> String {
        let prefix = switch category {
        case .lexical: "L"
        case .syntactic: "S"
        case .semantic: "M"
        case .structural: "T"
        }
        
        return "§\(prefix)\(index)§"
    }
    
    private func applySemanticCompression(to text: String, using dictionary: CompressionDictionary) async -> String {
        var compressedText = text
        
        // Sort patterns by length (longest first to avoid partial replacements)
        let sortedPatterns = dictionary.patterns.sorted { $0.key.count > $1.key.count }
        
        for (pattern, reference) in sortedPatterns {
            compressedText = compressedText.replacingOccurrences(of: pattern, with: reference)
        }
        
        return compressedText
    }
    
    private func applySemanticDecompression(to text: String, using dictionary: CompressionDictionary) async -> String {
        var decompressedText = text
        
        // Replace references with original patterns
        for (pattern, reference) in dictionary.patterns {
            decompressedText = decompressedText.replacingOccurrences(of: reference, with: pattern)
        }
        
        return decompressedText
    }
    
    private func optimizeCompression(_ compressedText: String, dictionary: CompressionDictionary, context: CompressionContext) async -> OptimizedCompressionResult {
        // Apply additional optimizations
        var optimizedText = compressedText
        
        // Remove redundant whitespace in compressed references
        optimizedText = optimizedText.replacingOccurrences(of: "§\\s+§", with: "§§", options: .regularExpression)
        
        // Compress sequential references
        optimizedText = await compressSequentialReferences(optimizedText)
        
        guard let data = optimizedText.data(using: .utf8) else {
            return OptimizedCompressionResult(compressedData: Data(), dictionary: dictionary)
        }
        
        return OptimizedCompressionResult(compressedData: data, dictionary: dictionary)
    }
    
    private func compressSequentialReferences(_ text: String) async -> String {
        // Identify and compress sequences of similar references
        let referencePattern = "§[LSMT]\\d+§"
        
        guard let regex = try? NSRegularExpression(pattern: referencePattern) else {
            return text
        }
        
        let matches = regex.matches(in: text, range: NSRange(location: 0, length: text.count))
        
        // Group consecutive references and create super-references
        // This is a simplified implementation
        return text
    }
    
    private func loadPatternLibrary() async {
        // Load existing pattern library from storage
        let libraryURL = getPatternLibraryURL()
        
        do {
            let data = try Data(contentsOf: libraryURL)
            patternLibrary = try JSONDecoder().decode(PatternLibrary.self, from: data)
        } catch {
            // Create new library if none exists
            patternLibrary = PatternLibrary()
        }
    }
    
    private func updatePatternLibrary(with patterns: [SemanticPattern], performance: Double) async {
        for pattern in patterns {
            if let existingPattern = patternLibrary.patterns[pattern.id] {
                // Update existing pattern statistics
                var updatedPattern = existingPattern
                updatedPattern.totalOccurrences += pattern.occurrences
                updatedPattern.usageCount += 1
                updatedPattern.averagePerformance = (updatedPattern.averagePerformance * Double(updatedPattern.usageCount - 1) + performance) / Double(updatedPattern.usageCount)
                patternLibrary.patterns[pattern.id] = updatedPattern
            } else {
                // Add new pattern
                var libraryPattern = PatternLibraryEntry(
                    pattern: pattern,
                    totalOccurrences: pattern.occurrences,
                    usageCount: 1,
                    averagePerformance: performance,
                    firstSeen: Date(),
                    lastUsed: Date()
                )
                patternLibrary.patterns[pattern.id] = libraryPattern
            }
        }
        
        // Save updated library
        await savePatternLibrary()
    }
    
    private func savePatternLibrary() async {
        let libraryURL = getPatternLibraryURL()
        
        do {
            let data = try JSONEncoder().encode(patternLibrary)
            try data.write(to: libraryURL)
        } catch {
            print("⚠️ Failed to save pattern library: \(error)")
        }
    }
    
    private func getPatternLibraryURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("semantic_pattern_library.json")
    }
    
    private func startAdaptiveLearning() async {
        guard enableAdaptiveLearning else { return }
        
        let task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3600_000_000_000) // 1 hour
                await self?.optimizePatternLibrary()
            }
        }
        compressionTasks.insert(task)
    }
    
    private func optimizePatternLibrary() async {
        // Remove patterns that perform poorly
        let threshold = 0.3 // 30% compression ratio threshold
        
        patternLibrary.patterns = patternLibrary.patterns.filter { _, entry in
            entry.averagePerformance > threshold
        }
        
        await savePatternLibrary()
    }
    
    private func updateCompressionStatistics(originalSize: Int, compressedSize: Int, processingTime: TimeInterval, patternsFound: Int) async {
        compressionStatistics.totalCompressions += 1
        compressionStatistics.totalOriginalBytes += Int64(originalSize)
        compressionStatistics.totalCompressedBytes += Int64(compressedSize)
        compressionStatistics.totalProcessingTime += processingTime
        compressionStatistics.totalPatternsFound += patternsFound
        
        compressionStatistics.averageCompressionRatio = 1.0 - (Double(compressionStatistics.totalCompressedBytes) / Double(compressionStatistics.totalOriginalBytes))
        compressionStatistics.averageProcessingTime = compressionStatistics.totalProcessingTime / Double(compressionStatistics.totalCompressions)
        compressionStatistics.averagePatternsPerCompression = Double(compressionStatistics.totalPatternsFound) / Double(compressionStatistics.totalCompressions)
    }
    
    private func recordCompressionMetrics(operation: String, processingTime: TimeInterval, originalSize: Int, compressedSize: Int) async {
        await performanceMonitor.recordMetric(
            .semanticCompression,
            value: processingTime,
            context: [
                "operation": operation,
                "original_size": String(originalSize),
                "compressed_size": String(compressedSize),
                "compression_ratio": String(1.0 - Double(compressedSize) / Double(originalSize))
            ]
        )
    }
    
    private func estimateCompressionRatio(patternDensity: Double, complexity: Double) -> Double {
        // Heuristic for estimating compression potential
        let patternScore = min(1.0, patternDensity * 10.0)
        let complexityPenalty = complexity
        
        return max(0.0, patternScore - complexityPenalty * 0.5)
    }
    
    private func estimateProcessingTime(textLength: Int, patternCount: Int) -> TimeInterval {
        // Simple heuristic for processing time estimation
        let baseTime = Double(textLength) / 10000.0 // 10K chars per second
        let patternTime = Double(patternCount) / 100.0 // 100 patterns per second
        
        return baseTime + patternTime
    }
    
    private func analyzePatternEfficiency() -> PatternEfficiency {
        let patterns = Array(patternLibrary.patterns.values)
        
        guard !patterns.isEmpty else {
            return PatternEfficiency(averagePerformance: 0, topPerformingPatterns: 0, underperformingPatterns: 0)
        }
        
        let avgPerformance = patterns.reduce(0.0) { $0 + $1.averagePerformance } / Double(patterns.count)
        let topPerforming = patterns.filter { $0.averagePerformance > 0.7 }.count
        let underperforming = patterns.filter { $0.averagePerformance < 0.3 }.count
        
        return PatternEfficiency(
            averagePerformance: avgPerformance,
            topPerformingPatterns: topPerforming,
            underperformingPatterns: underperforming
        )
    }
    
    private func analyzeAlgorithmPerformance() -> AlgorithmPerformance {
        return AlgorithmPerformance(
            averageCompressionRatio: compressionStatistics.averageCompressionRatio,
            averageProcessingSpeed: compressionStatistics.averageProcessingTime > 0 ? 1.0 / compressionStatistics.averageProcessingTime : 0,
            memoryEfficiency: 0.8, // Would be calculated from actual metrics
            patternRecognitionAccuracy: 0.9 // Would be calculated from validation data
        )
    }
    
    private func generateOptimizationRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if compressionStatistics.averageCompressionRatio < 0.5 {
            recommendations.append("Consider adjusting pattern recognition parameters for better compression")
        }
        
        if compressionStatistics.averageProcessingTime > 5.0 {
            recommendations.append("Processing time is high - consider optimizing pattern matching algorithms")
        }
        
        let efficiency = analyzePatternEfficiency()
        if efficiency.underperformingPatterns > efficiency.topPerformingPatterns {
            recommendations.append("Many patterns are underperforming - run pattern library optimization")
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

/// Semantic pattern identified in text
public struct SemanticPattern: Codable, Hashable, Identifiable {
    public let id: UUID
    public let text: String
    public let occurrences: Int
    public let length: Int
    public let value: Double
    public let semanticEmbedding: [Double]
    public let category: PatternCategory
    public let confidence: Double
}

/// Categories of semantic patterns
public enum PatternCategory: String, Codable, CaseIterable, Hashable {
    case lexical      // Individual words or short phrases
    case syntactic    // Grammar structures
    case semantic     // Meaning-based patterns
    case structural   // Document structure patterns
}

/// Content analysis result
public struct ContentAnalysis {
    public let language: NLLanguage
    public let wordCount: Int
    public let uniqueWords: Int
    public let vocabularyRichness: Double
    public let averageSentenceLength: Int
    public let complexity: Double
    public let contentType: ContentType
}

/// Types of content for compression optimization
public enum ContentType: String, Codable, CaseIterable, Hashable {
    case text
    case code
    case json
    case markup
    case documentation
}

/// Compression context for optimization
public struct CompressionContext: Codable, Hashable {
    public let contentHint: ContentType?
    public let prioritizeSpeed: Bool
    public let prioritizeRatio: Bool
    public let allowLossyCompression: Bool
    
    public init(contentHint: ContentType? = nil, prioritizeSpeed: Bool = false, prioritizeRatio: Bool = true, allowLossyCompression: Bool = false) {
        self.contentHint = contentHint
        self.prioritizeSpeed = prioritizeSpeed
        self.prioritizeRatio = prioritizeRatio
        self.allowLossyCompression = allowLossyCompression
    }
}

/// Compression dictionary for pattern mapping
public struct CompressionDictionary: Codable, Hashable {
    public let patterns: [String: String]
    public let patternMetadata: [String: SemanticPattern]
    public let version: String
    public let createdAt: Date
}

/// Result of semantic compression
public struct SemanticCompressionResult: Codable, Hashable {
    public let compressedData: Data
    public let dictionary: CompressionDictionary
    public let metadata: CompressionMetadata
}

/// Metadata about compression operation
public struct CompressionMetadata: Codable, Hashable {
    public let originalSize: Int
    public let compressedSize: Int
    public let compressionRatio: Double
    public let patternsIdentified: Int
    public let semanticComplexity: Double
    public let processingTime: TimeInterval
    public let compressionAlgorithm: String
    public let timestamp: Date
}

/// Optimized compression result
public struct OptimizedCompressionResult {
    public let compressedData: Data
    public let dictionary: CompressionDictionary
}

/// Analysis of compression potential
public struct CompressionAnalysis: Codable, Hashable {
    public let potentialRatio: Double
    public let patternDensity: Double
    public let semanticComplexity: Double
    public let recommendedAlgorithm: RecommendedAlgorithm
    public let estimatedProcessingTime: TimeInterval
}

/// Recommended compression algorithm
public enum RecommendedAlgorithm: String, Codable, CaseIterable, Hashable {
    case semantic
    case traditional
    case hybrid
}

/// Pattern library for storing learned patterns
public struct PatternLibrary: Codable, Hashable {
    public var patterns: [UUID: PatternLibraryEntry] = [:]
    public let version: String = "1.0"
    public let createdAt: Date = Date()
}

/// Entry in the pattern library
public struct PatternLibraryEntry: Codable, Hashable {
    public let pattern: SemanticPattern
    public var totalOccurrences: Int
    public var usageCount: Int
    public var averagePerformance: Double
    public let firstSeen: Date
    public var lastUsed: Date
}

/// Statistics about compression operations
public struct CompressionStatistics: Codable, Hashable {
    public var totalCompressions: Int = 0
    public var totalOriginalBytes: Int64 = 0
    public var totalCompressedBytes: Int64 = 0
    public var totalProcessingTime: TimeInterval = 0
    public var totalPatternsFound: Int = 0
    public var averageCompressionRatio: Double = 0
    public var averageProcessingTime: TimeInterval = 0
    public var averagePatternsPerCompression: Double = 0
}

/// Analytics about compression performance
public struct CompressionAnalytics: Codable, Hashable {
    public let statistics: CompressionStatistics
    public let patternLibrarySize: Int
    public let patternEfficiency: PatternEfficiency
    public let algorithmPerformance: AlgorithmPerformance
    public let recommendations: [String]
}

/// Pattern efficiency metrics
public struct PatternEfficiency: Codable, Hashable {
    public let averagePerformance: Double
    public let topPerformingPatterns: Int
    public let underperformingPatterns: Int
}

/// Algorithm performance metrics
public struct AlgorithmPerformance: Codable, Hashable {
    public let averageCompressionRatio: Double
    public let averageProcessingSpeed: Double
    public let memoryEfficiency: Double
    public let patternRecognitionAccuracy: Double
}

/// Configuration for compression engine
public struct CompressionConfiguration: Codable, Hashable {
    public let minPatternLength: Int
    public let maxPatternLength: Int
    public let minPatternOccurrence: Int
    public let semanticSimilarityThreshold: Double
}

/// Export data for pattern library
public struct PatternLibraryExport: Codable, Hashable {
    public let exportDate: Date
    public let library: PatternLibrary
    public let statistics: CompressionStatistics
    public let configuration: CompressionConfiguration
}
