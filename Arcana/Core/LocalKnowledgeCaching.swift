//
// LocalKnowledgeCaching.swift
// Arcana
//
// Revolutionary local web knowledge caching system with intelligent storage management
// Part of the PRISM privacy-first web intelligence architecture
//

import Foundation
import Combine
import CryptoKit

// MARK: - Local Knowledge Caching Engine

/// Revolutionary local caching system for web knowledge with privacy-first design
/// Intelligently stores and retrieves web research results with semantic similarity matching
@MainActor
public class LocalKnowledgeCaching: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var cacheSize: Int64 = 0
    @Published private(set) var cacheEntries: Int = 0
    @Published private(set) var hitRate: Double = 0.0
    @Published private(set) var isOptimizing: Bool = false
    @Published private(set) var storageLimit: StorageLimit = .standard50MB
    
    // MARK: - Private Properties
    
    private let encryptionManager: LocalEncryptionManager
    private let semanticMemory: SemanticMemoryEngine
    private let performanceMonitor: PerformanceMonitor
    private var cacheStorage: [String: CacheEntry] = [:]
    private var accessLog: [String: CacheAccessInfo] = [:]
    private let cacheDirectory: URL
    private var cacheHits: Int = 0
    private var totalRequests: Int = 0
    private var optimizationTasks: Set<Task<Void, Never>> = []
    
    // MARK: - Cache Configuration
    
    private let maxCacheEntryAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    private let semanticsimilarityThreshold: Double = 0.85
    private let compressionEnabled = true
    private let encryptionEnabled = true
    
    // MARK: - Initialization
    
    public init(encryptionManager: LocalEncryptionManager,
                semanticMemory: SemanticMemoryEngine,
                performanceMonitor: PerformanceMonitor,
                storageLimit: StorageLimit = .standard50MB) {
        self.encryptionManager = encryptionManager
        self.semanticMemory = semanticMemory
        self.performanceMonitor = performanceMonitor
        self.storageLimit = storageLimit
        
        // Initialize cache directory
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.cacheDirectory = documentsURL.appendingPathComponent("WebKnowledgeCache")
        
        Task {
            await initializeCache()
            await startBackgroundOptimization()
        }
    }
    
    deinit {
        // Cancel all optimization tasks
        optimizationTasks.forEach { $0.cancel() }
    }
    
    // MARK: - Public Interface
    
    /// Retrieve cached result for a query with semantic similarity matching
    public func retrieve(query: String) async -> SearchResult? {
        let startTime = CFAbsoluteTimeGetCurrent()
        totalRequests += 1
        
        do {
            // Generate query hash for exact matching
            let queryHash = generateQueryHash(query)
            
            // Check for exact match first
            if let exactMatch = await getExactMatch(queryHash: queryHash) {
                cacheHits += 1
                await updateAccessInfo(for: queryHash)
                await recordCacheMetrics(hitType: "exact", processingTime: CFAbsoluteTimeGetCurrent() - startTime)
                return exactMatch
            }
            
            // Check for semantic similarity match
            if let semanticMatch = await getSemanticMatch(query: query) {
                cacheHits += 1
                await updateAccessInfo(for: semanticMatch.cacheKey)
                await recordCacheMetrics(hitType: "semantic", processingTime: CFAbsoluteTimeGetCurrent() - startTime)
                return semanticMatch.result
            }
            
            await recordCacheMetrics(hitType: "miss", processingTime: CFAbsoluteTimeGetCurrent() - startTime)
            return nil
            
        } catch {
            print("⚠️ Cache retrieval error: \(error)")
            return nil
        }
    }
    
    /// Store search result in cache with intelligent optimization
    public func store(result: SearchResult) async {
        do {
            let queryHash = generateQueryHash(result.query)
            
            // Check if we need to make space
            await ensureStorageCapacity(for: result)
            
            // Create cache entry
            let cacheEntry = CacheEntry(
                id: UUID(),
                queryHash: queryHash,
                originalQuery: result.query,
                searchResult: result,
                timestamp: Date(),
                accessCount: 1,
                lastAccessed: Date(),
                semanticEmbedding: await generateSemanticEmbedding(for: result.query),
                expirationDate: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
                confidenceScore: result.confidenceScore,
                sourceEngine: result.engine
            )
            
            // Store in memory cache
            cacheStorage[queryHash] = cacheEntry
            
            // Initialize access info
            accessLog[queryHash] = CacheAccessInfo(
                queryHash: queryHash,
                firstAccess: Date(),
                lastAccess: Date(),
                accessCount: 1,
                averageAccessInterval: 0
            )
            
            // Persist to disk
            await persistCacheEntry(cacheEntry)
            
            // Update cache statistics
            await updateCacheStatistics()
            
        } catch {
            print("⚠️ Failed to store cache entry: \(error)")
        }
    }
    
    /// Clear all cached entries
    public func clearCache() async {
        do {
            // Clear memory cache
            cacheStorage.removeAll()
            accessLog.removeAll()
            
            // Clear disk cache
            let cacheFiles = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in cacheFiles {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            // Reset statistics
            cacheSize = 0
            cacheEntries = 0
            cacheHits = 0
            totalRequests = 0
            hitRate = 0.0
            
        } catch {
            print("⚠️ Failed to clear cache: \(error)")
        }
    }
    
    /// Update storage limit and optimize cache accordingly
    public func updateStorageLimit(_ newLimit: StorageLimit) async {
        storageLimit = newLimit
        
        if cacheSize > newLimit.bytes {
            await optimizeCacheStorage()
        }
    }
    
    /// Get cache analytics for user insights
    public func getCacheAnalytics() -> CacheAnalytics {
        let topQueries = getTopQueries()
        let cacheEfficiency = calculateCacheEfficiency()
        let storageBreakdown = getStorageBreakdown()
        
        return CacheAnalytics(
            totalEntries: cacheEntries,
            cacheSize: cacheSize,
            hitRate: hitRate,
            averageAge: calculateAverageAge(),
            topQueries: topQueries,
            efficiency: cacheEfficiency,
            storageBreakdown: storageBreakdown,
            recommendedOptimizations: getOptimizationRecommendations()
        )
    }
    
    /// Export cache data for manual backup (privacy-preserving)
    public func exportCacheData() async throws -> Data {
        let exportData = CacheExportData(
            exportDate: Date(),
            totalEntries: cacheEntries,
            cacheSize: cacheSize,
            anonymizedQueries: await getAnonymizedQueries(),
            performanceMetrics: getCachePerformanceMetrics()
        )
        
        return try JSONEncoder().encode(exportData)
    }
    
    // MARK: - Private Implementation
    
    private func initializeCache() async {
        do {
            // Create cache directory if it doesn't exist
            try FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true, attributes: nil)
            
            // Load existing cache entries from disk
            await loadCacheFromDisk()
            
            // Update cache statistics
            await updateCacheStatistics()
            
            print("✅ Local knowledge cache initialized with \(cacheEntries) entries")
            
        } catch {
            print("⚠️ Failed to initialize cache: \(error)")
        }
    }
    
    private func loadCacheFromDisk() async {
        do {
            let cacheFiles = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            
            for fileURL in cacheFiles where fileURL.pathExtension == "cache" {
                if let cacheEntry = await loadCacheEntry(from: fileURL) {
                    cacheStorage[cacheEntry.queryHash] = cacheEntry
                    
                    // Initialize access info
                    accessLog[cacheEntry.queryHash] = CacheAccessInfo(
                        queryHash: cacheEntry.queryHash,
                        firstAccess: cacheEntry.timestamp,
                        lastAccess: cacheEntry.lastAccessed,
                        accessCount: cacheEntry.accessCount,
                        averageAccessInterval: 0
                    )
                }
            }
            
        } catch {
            print("⚠️ Failed to load cache from disk: \(error)")
        }
    }
    
    private func loadCacheEntry(from fileURL: URL) async -> CacheEntry? {
        do {
            let encryptedData = try Data(contentsOf: fileURL)
            
            if encryptionEnabled {
                let decryptedData = try await encryptionManager.decrypt(encryptedData)
                return try JSONDecoder().decode(CacheEntry.self, from: decryptedData)
            } else {
                return try JSONDecoder().decode(CacheEntry.self, from: encryptedData)
            }
            
        } catch {
            print("⚠️ Failed to load cache entry from \(fileURL): \(error)")
            return nil
        }
    }
    
    private func generateQueryHash(_ query: String) -> String {
        let normalizedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let data = normalizedQuery.data(using: .utf8) ?? Data()
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func getExactMatch(queryHash: String) async -> SearchResult? {
        guard let cacheEntry = cacheStorage[queryHash] else { return nil }
        
        // Check if entry is still valid
        if cacheEntry.expirationDate < Date() {
            await removeCacheEntry(queryHash: queryHash)
            return nil
        }
        
        return cacheEntry.searchResult
    }
    
    private func getSemanticMatch(query: String) async -> (result: SearchResult, cacheKey: String)? {
        do {
            let queryEmbedding = await generateSemanticEmbedding(for: query)
            var bestMatch: (entry: CacheEntry, similarity: Double, key: String)?
            
            for (key, cacheEntry) in cacheStorage {
                // Skip expired entries
                if cacheEntry.expirationDate < Date() {
                    await removeCacheEntry(queryHash: key)
                    continue
                }
                
                let similarity = await calculateSemanticSimilarity(
                    queryEmbedding,
                    cacheEntry.semanticEmbedding
                )
                
                if similarity >= semanticsimilarityThreshold {
                    if bestMatch == nil || similarity > bestMatch!.similarity {
                        bestMatch = (cacheEntry, similarity, key)
                    }
                }
            }
            
            if let match = bestMatch {
                return (match.entry.searchResult, match.key)
            }
            
            return nil
            
        } catch {
            print("⚠️ Semantic matching error: \(error)")
            return nil
        }
    }
    
    private func generateSemanticEmbedding(for query: String) async -> [Double] {
        do {
            return try await semanticMemory.generateEmbedding(for: query)
        } catch {
            // Fallback to simple hash-based embedding
            return generateSimpleEmbedding(for: query)
        }
    }
    
    private func generateSimpleEmbedding(for query: String) -> [Double] {
        // Simple fallback embedding based on character frequencies
        let words = query.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var embedding = Array(repeating: 0.0, count: 128)
        
        for (index, word) in words.enumerated() {
            let wordHash = word.hash
            let embeddingIndex = abs(wordHash) % embedding.count
            embedding[embeddingIndex] += 1.0 / Double(words.count)
        }
        
        return embedding
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
    
    private func updateAccessInfo(for queryHash: String) async {
        guard var accessInfo = accessLog[queryHash] else { return }
        
        let now = Date()
        let timeSinceLastAccess = now.timeIntervalSince(accessInfo.lastAccess)
        
        accessInfo.accessCount += 1
        accessInfo.lastAccess = now
        
        // Update average access interval
        if accessInfo.accessCount > 1 {
            let totalInterval = now.timeIntervalSince(accessInfo.firstAccess)
            accessInfo.averageAccessInterval = totalInterval / Double(accessInfo.accessCount - 1)
        }
        
        accessLog[queryHash] = accessInfo
        
        // Update cache entry access count
        if var cacheEntry = cacheStorage[queryHash] {
            cacheEntry.accessCount += 1
            cacheEntry.lastAccessed = now
            cacheStorage[queryHash] = cacheEntry
            
            // Persist updated entry
            await persistCacheEntry(cacheEntry)
        }
    }
    
    private func ensureStorageCapacity(for result: SearchResult) async {
        let estimatedSize = estimateCacheEntrySize(result)
        
        if cacheSize + estimatedSize > storageLimit.bytes {
            await optimizeCacheStorage()
        }
    }
    
    private func estimateCacheEntrySize(_ result: SearchResult) -> Int64 {
        // Estimate the size of the cache entry
        let querySize = result.query.data(using: .utf8)?.count ?? 0
        let resultsSize = result.results.reduce(0) { total, item in
            total + (item.title.data(using: .utf8)?.count ?? 0) +
                   (item.snippet.data(using: .utf8)?.count ?? 0) +
                   (item.url.absoluteString.data(using: .utf8)?.count ?? 0)
        }
        
        // Add overhead for metadata, embedding, and encryption
        let overhead = 2048 // 2KB overhead
        
        return Int64(querySize + resultsSize + overhead)
    }
    
    private func optimizeCacheStorage() async {
        guard !isOptimizing else { return }
        
        isOptimizing = true
        defer { isOptimizing = false }
        
        do {
            // Get entries sorted by priority (least important first)
            let sortedEntries = getSortedEntriesByPriority()
            
            var currentSize = cacheSize
            let targetSize = Int64(Double(storageLimit.bytes) * 0.8) // Keep 80% of limit
            
            for (queryHash, entry) in sortedEntries {
                if currentSize <= targetSize { break }
                
                let entrySize = estimateCacheEntrySize(entry.searchResult)
                await removeCacheEntry(queryHash: queryHash)
                currentSize -= entrySize
            }
            
            await updateCacheStatistics()
            
        } catch {
            print("⚠️ Cache optimization error: \(error)")
        }
    }
    
    private func getSortedEntriesByPriority() -> [(String, CacheEntry)] {
        return cacheStorage.sorted { (entry1, entry2) in
            let priority1 = calculateEntryPriority(entry1.value, queryHash: entry1.key)
            let priority2 = calculateEntryPriority(entry2.value, queryHash: entry2.key)
            return priority1 < priority2 // Lower priority first (for removal)
        }
    }
    
    private func calculateEntryPriority(_ entry: CacheEntry, queryHash: String) -> Double {
        let accessInfo = accessLog[queryHash] ?? CacheAccessInfo(
            queryHash: queryHash,
            firstAccess: entry.timestamp,
            lastAccess: entry.lastAccessed,
            accessCount: entry.accessCount,
            averageAccessInterval: 0
        )
        
        // Calculate priority based on:
        // - Access frequency (higher is better)
        // - Recency (more recent is better)
        // - Confidence score (higher is better)
        // - Time since last access (shorter is better)
        
        let accessFrequency = Double(accessInfo.accessCount) / max(1.0, Date().timeIntervalSince(accessInfo.firstAccess) / (24 * 60 * 60))
        let recency = max(0.0, 1.0 - (Date().timeIntervalSince(entry.lastAccessed) / (7 * 24 * 60 * 60)))
        let confidenceWeight = entry.confidenceScore
        let accessRecency = max(0.0, 1.0 - (Date().timeIntervalSince(entry.lastAccessed) / (24 * 60 * 60)))
        
        return (accessFrequency * 0.3) + (recency * 0.3) + (confidenceWeight * 0.2) + (accessRecency * 0.2)
    }
    
    private func removeCacheEntry(queryHash: String) async {
        // Remove from memory
        cacheStorage.removeValue(forKey: queryHash)
        accessLog.removeValue(forKey: queryHash)
        
        // Remove from disk
        let fileURL = cacheDirectory.appendingPathComponent("\(queryHash).cache")
        try? FileManager.default.removeItem(at: fileURL)
    }
    
    private func persistCacheEntry(_ entry: CacheEntry) async {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(entry)
            
            let finalData: Data
            if encryptionEnabled {
                finalData = try await encryptionManager.encrypt(data)
            } else {
                finalData = data
            }
            
            let fileURL = cacheDirectory.appendingPathComponent("\(entry.queryHash).cache")
            try finalData.write(to: fileURL)
            
        } catch {
            print("⚠️ Failed to persist cache entry: \(error)")
        }
    }
    
    private func updateCacheStatistics() async {
        cacheEntries = cacheStorage.count
        hitRate = totalRequests > 0 ? Double(cacheHits) / Double(totalRequests) : 0.0
        
        // Calculate cache size
        var totalSize: Int64 = 0
        for (_, entry) in cacheStorage {
            totalSize += estimateCacheEntrySize(entry.searchResult)
        }
        cacheSize = totalSize
    }
    
    private func recordCacheMetrics(hitType: String, processingTime: TimeInterval) async {
        await performanceMonitor.recordMetric(
            .cacheOperation,
            value: processingTime,
            context: [
                "type": hitType,
                "hit_rate": String(hitRate),
                "cache_size": String(cacheSize)
            ]
        )
    }
    
    private func startBackgroundOptimization() async {
        let task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3600_000_000_000) // 1 hour
                await self?.performBackgroundMaintenance()
            }
        }
        optimizationTasks.insert(task)
    }
    
    private func performBackgroundMaintenance() async {
        // Remove expired entries
        let now = Date()
        let expiredHashes = cacheStorage.compactMap { (key, entry) in
            entry.expirationDate < now ? key : nil
        }
        
        for hash in expiredHashes {
            await removeCacheEntry(queryHash: hash)
        }
        
        // Optimize storage if needed
        if cacheSize > Int64(Double(storageLimit.bytes) * 0.9) {
            await optimizeCacheStorage()
        }
        
        await updateCacheStatistics()
    }
    
    private func getTopQueries() -> [TopQuery] {
        return accessLog.values
            .sorted { $0.accessCount > $1.accessCount }
            .prefix(10)
            .compactMap { accessInfo in
                guard let cacheEntry = cacheStorage[accessInfo.queryHash] else { return nil }
                return TopQuery(
                    query: cacheEntry.originalQuery,
                    accessCount: accessInfo.accessCount,
                    lastAccessed: accessInfo.lastAccess
                )
            }
    }
    
    private func calculateCacheEfficiency() -> CacheEfficiency {
        let avgAccessCount = accessLog.values.reduce(0) { $0 + $1.accessCount } / max(1, accessLog.count)
        let storageUtilization = Double(cacheSize) / Double(storageLimit.bytes)
        
        return CacheEfficiency(
            hitRate: hitRate,
            averageAccessCount: Double(avgAccessCount),
            storageUtilization: storageUtilization,
            overallScore: (hitRate * 0.5) + (min(1.0, Double(avgAccessCount) / 10.0) * 0.3) + (storageUtilization * 0.2)
        )
    }
    
    private func getStorageBreakdown() -> StorageBreakdown {
        var engineBreakdown: [String: Int64] = [:]
        
        for (_, entry) in cacheStorage {
            let engine = entry.sourceEngine.rawValue
            let size = estimateCacheEntrySize(entry.searchResult)
            engineBreakdown[engine, default: 0] += size
        }
        
        return StorageBreakdown(
            totalSize: cacheSize,
            byEngine: engineBreakdown,
            utilizationPercentage: Double(cacheSize) / Double(storageLimit.bytes) * 100
        )
    }
    
    private func calculateAverageAge() -> TimeInterval {
        guard !cacheStorage.isEmpty else { return 0 }
        
        let now = Date()
        let totalAge = cacheStorage.values.reduce(0.0) { total, entry in
            total + now.timeIntervalSince(entry.timestamp)
        }
        
        return totalAge / Double(cacheStorage.count)
    }
    
    private func getOptimizationRecommendations() -> [String] {
        var recommendations: [String] = []
        
        if hitRate < 0.3 {
            recommendations.append("Cache hit rate is low. Consider increasing storage limit or adjusting query patterns.")
        }
        
        if Double(cacheSize) / Double(storageLimit.bytes) > 0.9 {
            recommendations.append("Cache is nearly full. Consider clearing old entries or increasing storage limit.")
        }
        
        let averageAccessCount = accessLog.values.reduce(0) { $0 + $1.accessCount } / max(1, accessLog.count)
        if averageAccessCount < 2 {
            recommendations.append("Many cached entries are accessed only once. Consider more selective caching.")
        }
        
        return recommendations
    }
    
    private func getAnonymizedQueries() async -> [String] {
        return cacheStorage.values.map { entry in
            // Anonymize queries by replacing specific terms with placeholders
            return anonymizeQuery(entry.originalQuery)
        }
    }
    
    private func anonymizeQuery(_ query: String) -> String {
        // Simple anonymization - replace potential personal info with placeholders
        var anonymized = query
        
        // Replace email-like patterns
        anonymized = anonymized.replacingOccurrences(of: #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#, with: "[EMAIL]", options: .regularExpression)
        
        // Replace phone-like patterns
        anonymized = anonymized.replacingOccurrences(of: #"\b\d{3}-\d{3}-\d{4}\b"#, with: "[PHONE]", options: .regularExpression)
        
        // Replace URLs
        anonymized = anonymized.replacingOccurrences(of: #"https?://[^\s]+"#, with: "[URL]", options: .regularExpression)
        
        return anonymized
    }
    
    private func getCachePerformanceMetrics() -> CachePerformanceMetrics {
        return CachePerformanceMetrics(
            hitRate: hitRate,
            averageRetrievalTime: 0.05, // Would be calculated from actual metrics
            cacheSize: cacheSize,
            entryCount: cacheEntries,
            optimizationFrequency: 1.0 // Per day
        )
    }
}

// MARK: - Supporting Types

/// Represents a cached search result entry
public struct CacheEntry: Codable, Hashable {
    public let id: UUID
    public let queryHash: String
    public let originalQuery: String
    public let searchResult: SearchResult
    public let timestamp: Date
    public var accessCount: Int
    public var lastAccessed: Date
    public let semanticEmbedding: [Double]
    public let expirationDate: Date
    public let confidenceScore: Double
    public let sourceEngine: SearchEngine
}

/// Tracks access information for cache entries
public struct CacheAccessInfo: Codable, Hashable {
    public let queryHash: String
    public let firstAccess: Date
    public var lastAccess: Date
    public var accessCount: Int
    public var averageAccessInterval: TimeInterval
}

/// Analytics data for cache performance
public struct CacheAnalytics: Codable, Hashable {
    public let totalEntries: Int
    public let cacheSize: Int64
    public let hitRate: Double
    public let averageAge: TimeInterval
    public let topQueries: [TopQuery]
    public let efficiency: CacheEfficiency
    public let storageBreakdown: StorageBreakdown
    public let recommendedOptimizations: [String]
}

/// Top accessed query information
public struct TopQuery: Codable, Hashable {
    public let query: String
    public let accessCount: Int
    public let lastAccessed: Date
}

/// Cache efficiency metrics
public struct CacheEfficiency: Codable, Hashable {
    public let hitRate: Double
    public let averageAccessCount: Double
    public let storageUtilization: Double
    public let overallScore: Double
}

/// Storage breakdown by different categories
public struct StorageBreakdown: Codable, Hashable {
    public let totalSize: Int64
    public let byEngine: [String: Int64]
    public let utilizationPercentage: Double
}

/// Export data structure for cache backup
public struct CacheExportData: Codable, Hashable {
    public let exportDate: Date
    public let totalEntries: Int
    public let cacheSize: Int64
    public let anonymizedQueries: [String]
    public let performanceMetrics: CachePerformanceMetrics
}

/// Performance metrics for cache operations
public struct CachePerformanceMetrics: Codable, Hashable {
    public let hitRate: Double
    public let averageRetrievalTime: TimeInterval
    public let cacheSize: Int64
    public let entryCount: Int
    public let optimizationFrequency: Double
}
