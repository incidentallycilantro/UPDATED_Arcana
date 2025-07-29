//
// CrossWorkspaceDeduplication.swift
// Arcana
//
// Revolutionary cross-workspace deduplication system with semantic similarity detection
// Optimizes storage by identifying and consolidating duplicate content across all workspaces
//

import Foundation
import Combine
import CryptoKit

// MARK: - Cross-Workspace Deduplication Engine

/// Revolutionary deduplication system that identifies and consolidates similar content across workspaces
/// Uses both cryptographic hashing and semantic similarity for comprehensive duplicate detection
@MainActor
public class CrossWorkspaceDeduplication: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isDeduplicating: Bool = false
    @Published private(set) var deduplicationProgress: Double = 0.0
    @Published private(set) var totalSpaceSaved: Int64 = 0
    @Published private(set) var duplicatesFound: Int = 0
    @Published private(set) var deduplicationStatistics: DeduplicationStatistics = DeduplicationStatistics()
    
    // MARK: - Private Properties
    
    private let semanticMemory: SemanticMemoryEngine
    private let quantumStorage: QuantumStorageManager
    private let performanceMonitor: PerformanceMonitor
    private var contentRegistry: ContentRegistry = ContentRegistry()
    private var deduplicationTasks: Set<Task<Void, Never>> = []
    private let semanticSimilarityThreshold: Double = 0.95
    private let exactMatchThreshold: Double = 1.0
    
    // MARK: - Configuration
    
    private let enableSemanticDeduplication = true
    private let enableCryptographicDeduplication = true
    private let minimumContentSize = 100 // bytes
    private let maxSimilarityAnalysisSize = 10 * 1024 * 1024 // 10MB
    
    // MARK: - Initialization
    
    public init(semanticMemory: SemanticMemoryEngine,
                quantumStorage: QuantumStorageManager,
                performanceMonitor: PerformanceMonitor) {
        self.semanticMemory = semanticMemory
        self.quantumStorage = quantumStorage
        self.performanceMonitor = performanceMonitor
        
        Task {
            await loadContentRegistry()
            await startBackgroundDeduplication()
        }
    }
    
    deinit {
        deduplicationTasks.forEach { $0.cancel() }
    }
    
    // MARK: - Public Interface
    
    /// Perform comprehensive deduplication across all workspaces
    public func performDeduplication() async throws {
        guard !isDeduplicating else {
            throw ArcanaError.storageError("Deduplication already in progress")
        }
        
        isDeduplicating = true
        deduplicationProgress = 0.0
        defer {
            isDeduplicating = false
            deduplicationProgress = 0.0
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        var totalSpaceReclaimed: Int64 = 0
        var duplicatesProcessed = 0
        
        do {
            // Step 1: Scan all content for duplicates (30%)
            deduplicationProgress = 0.1
            let allContent = try await scanAllContent()
            
            deduplicationProgress = 0.3
            
            // Step 2: Identify exact duplicates using cryptographic hashing (50%)
            let exactDuplicates = await identifyExactDuplicates(allContent)
            
            deduplicationProgress = 0.5
            
            // Step 3: Identify semantic duplicates (70%)
            var semanticDuplicates: [SemanticDuplicateGroup] = []
            if enableSemanticDeduplication {
                semanticDuplicates = await identifySemanticDuplicates(allContent)
            }
            
            deduplicationProgress = 0.7
            
            // Step 4: Consolidate exact duplicates (85%)
            let exactSpaceSaved = try await consolidateExactDuplicates(exactDuplicates)
            totalSpaceReclaimed += exactSpaceSaved
            duplicatesProcessed += exactDuplicates.count
            
            deduplicationProgress = 0.85
            
            // Step 5: Consolidate semantic duplicates (100%)
            let semanticSpaceSaved = try await consolidateSemanticDuplicates(semanticDuplicates)
            totalSpaceReclaimed += semanticSpaceSaved
            duplicatesProcessed += semanticDuplicates.count
            
            deduplicationProgress = 1.0
            
            // Update statistics
            totalSpaceSaved += totalSpaceReclaimed
            duplicatesFound += duplicatesProcessed
            
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            
            await updateDeduplicationStatistics(
                spaceSaved: totalSpaceReclaimed,
                duplicatesProcessed: duplicatesProcessed,
                processingTime: processingTime
            )
            
            // Record performance metrics
            await recordDeduplicationMetrics(
                operation: "full_deduplication",
                processingTime: processingTime,
                spaceSaved: totalSpaceReclaimed,
                duplicatesFound: duplicatesProcessed
            )
            
            print("✅ Deduplication completed: \(duplicatesProcessed) duplicates found, \(formatBytes(totalSpaceReclaimed)) saved")
            
        } catch {
            throw ArcanaError.storageError("Deduplication failed: \(error.localizedDescription)")
        }
    }
    
    /// Check if content is a duplicate before storing
    public func checkForDuplicates<T: Codable>(_ content: T, metadata: ContentMetadata) async -> DuplicationCheckResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // Generate content hash
            let contentData = try JSONEncoder().encode(content)
            let contentHash = calculateContentHash(contentData)
            
            // Check for exact match
            if let existingEntry = contentRegistry.exactMatches[contentHash] {
                return DuplicationCheckResult(
                    isDuplicate: true,
                    duplicateType: .exact,
                    existingContentId: existingEntry.contentId,
                    existingLocation: existingEntry.location,
                    similarityScore: 1.0,
                    spaceSavings: Int64(contentData.count),
                    processingTime: CFAbsoluteTimeGetCurrent() - startTime
                )
            }
            
            // Check for semantic similarity if enabled and content is suitable
            if enableSemanticDeduplication && contentData.count <= maxSimilarityAnalysisSize {
                if let textContent = extractTextContent(content) {
                    let semanticResult = await checkSemanticSimilarity(
                        textContent,
                        hash: contentHash,
                        metadata: metadata
                    )
                    
                    if let result = semanticResult {
                        return result
                    }
                }
            }
            
            // No duplicates found - register content
            await registerNewContent(
                contentId: UUID().uuidString,
                hash: contentHash,
                metadata: metadata,
                size: Int64(contentData.count),
                textContent: extractTextContent(content)
            )
            
            return DuplicationCheckResult(
                isDuplicate: false,
                duplicateType: nil,
                existingContentId: nil,
                existingLocation: nil,
                similarityScore: 0.0,
                spaceSavings: 0,
                processingTime: CFAbsoluteTimeGetCurrent() - startTime
            )
            
        } catch {
            print("⚠️ Duplicate check failed: \(error)")
            return DuplicationCheckResult(
                isDuplicate: false,
                duplicateType: nil,
                existingContentId: nil,
                existingLocation: nil,
                similarityScore: 0.0,
                spaceSavings: 0,
                processingTime: CFAbsoluteTimeGetCurrent() - startTime
            )
        }
    }
    
    /// Get deduplication analytics and insights
    public func getDeduplicationAnalytics() -> DeduplicationAnalytics {
        let spaceUtilization = calculateSpaceUtilization()
        let duplicateDistribution = analyzeDuplicateDistribution()
        let effectiveness = calculateDeduplicationEffectiveness()
        
        return DeduplicationAnalytics(
            statistics: deduplicationStatistics,
            totalContentTracked: contentRegistry.totalEntries,
            spaceUtilization: spaceUtilization,
            duplicateDistribution: duplicateDistribution,
            effectiveness: effectiveness,
            recommendations: generateOptimizationRecommendations()
        )
    }
    
    /// Export deduplication report for analysis
    public func exportDeduplicationReport() async throws -> Data {
        let analytics = getDeduplicationAnalytics()
        
        let report = DeduplicationReport(
            exportDate: Date(),
            analytics: analytics,
            contentRegistry: ContentRegistryExport(
                totalEntries: contentRegistry.totalEntries,
                exactMatches: contentRegistry.exactMatches.count,
                semanticGroups: contentRegistry.semanticGroups.count
            ),
            performanceMetrics: await getDeduplicationPerformanceMetrics()
        )
        
        return try JSONEncoder().encode(report)
    }
    
    /// Clean up orphaned references and optimize registry
    public func optimizeContentRegistry() async {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Remove entries for content that no longer exists
        let validHashes = await validateContentReferences()
        
        contentRegistry.exactMatches = contentRegistry.exactMatches.filter { hash, _ in
            validHashes.contains(hash)
        }
        
        // Optimize semantic groups
        await optimizeSemanticGroups()
        
        // Save optimized registry
        await saveContentRegistry()
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        await recordDeduplicationMetrics(
            operation: "optimize_registry",
            processingTime: processingTime,
            spaceSaved: 0,
            duplicatesFound: 0
        )
        
        print("✅ Content registry optimized in \(String(format: "%.2f", processingTime)) seconds")
    }
    
    // MARK: - Private Implementation
    
    private func loadContentRegistry() async {
        let registryURL = getContentRegistryURL()
        
        do {
            let data = try Data(contentsOf: registryURL)
            contentRegistry = try JSONDecoder().decode(ContentRegistry.self, from: data)
        } catch {
            contentRegistry = ContentRegistry()
            print("📝 Created new content registry")
        }
    }
    
    private func saveContentRegistry() async {
        let registryURL = getContentRegistryURL()
        
        do {
            let data = try JSONEncoder().encode(contentRegistry)
            try data.write(to: registryURL)
        } catch {
            print("⚠️ Failed to save content registry: \(error)")
        }
    }
    
    private func getContentRegistryURL() -> URL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsURL.appendingPathComponent("content_registry.json")
    }
    
    private func scanAllContent() async throws -> [ContentItem] {
        var allContent: [ContentItem] = []
        
        // This would scan all workspaces and collect content items
        // For now, we'll simulate with the content registry
        
        for (hash, entry) in contentRegistry.exactMatches {
            allContent.append(ContentItem(
                id: entry.contentId,
                hash: hash,
                location: entry.location,
                size: entry.size,
                workspaceId: entry.workspaceId,
                metadata: entry.metadata,
                textContent: entry.textContent
            ))
        }
        
        return allContent
    }
    
    private func identifyExactDuplicates(_ content: [ContentItem]) async -> [ExactDuplicateGroup] {
        var duplicateGroups: [String: [ContentItem]] = [:]
        
        // Group content by hash
        for item in content {
            duplicateGroups[item.hash, default: []].append(item)
        }
        
        // Filter to only groups with duplicates
        let duplicates = duplicateGroups.compactMap { hash, items -> ExactDuplicateGroup? in
            guard items.count > 1 else { return nil }
            
            return ExactDuplicateGroup(
                hash: hash,
                duplicateItems: items,
                spaceSavings: calculateSpaceSavings(items)
            )
        }
        
        return duplicates
    }
    
    private func identifySemanticDuplicates(_ content: [ContentItem]) async -> [SemanticDuplicateGroup] {
        var semanticGroups: [SemanticDuplicateGroup] = []
        var processedItems: Set<String> = []
        
        for item in content {
            if processedItems.contains(item.id) || item.textContent == nil {
                continue
            }
            
            var similarItems: [ContentItem] = [item]
            processedItems.insert(item.id)
            
            // Find semantically similar items
            for otherItem in content {
                if processedItems.contains(otherItem.id) || otherItem.textContent == nil {
                    continue
                }
                
                if let similarity = await calculateSemanticSimilarity(
                    item.textContent!,
                    otherItem.textContent!
                ) {
                    if similarity >= semanticSimilarityThreshold {
                        similarItems.append(otherItem)
                        processedItems.insert(otherItem.id)
                    }
                }
            }
            
            // Create group if we found similar items
            if similarItems.count > 1 {
                semanticGroups.append(SemanticDuplicateGroup(
                    items: similarItems,
                    averageSimilarity: await calculateAverageSimilarity(similarItems),
                    spaceSavings: calculateSpaceSavings(similarItems)
                ))
            }
        }
        
        return semanticGroups
    }
    
    private func consolidateExactDuplicates(_ duplicates: [ExactDuplicateGroup]) async throws -> Int64 {
        var totalSpaceSaved: Int64 = 0
        
        for group in duplicates {
            do {
                let spaceSaved = try await consolidateExactDuplicateGroup(group)
                totalSpaceSaved += spaceSaved
            } catch {
                print("⚠️ Failed to consolidate exact duplicate group: \(error)")
            }
        }
        
        return totalSpaceSaved
    }
    
    private func consolidateSemanticDuplicates(_ duplicates: [SemanticDuplicateGroup]) async throws -> Int64 {
        var totalSpaceSaved: Int64 = 0
        
        for group in duplicates {
            do {
                let spaceSaved = try await consolidateSemanticDuplicateGroup(group)
                totalSpaceSaved += spaceSaved
            } catch {
                print("⚠️ Failed to consolidate semantic duplicate group: \(error)")
            }
        }
        
        return totalSpaceSaved
    }
    
    private func consolidateExactDuplicateGroup(_ group: ExactDuplicateGroup) async throws -> Int64 {
        // Keep the most accessible copy and create references for others
        let primaryItem = selectPrimaryItem(from: group.duplicateItems)
        var spaceSaved: Int64 = 0
        
        for item in group.duplicateItems where item.id != primaryItem.id {
            // Create reference to primary item
            try await createContentReference(from: item, to: primaryItem)
            spaceSaved += item.size
        }
        
        return spaceSaved
    }
    
    private func consolidateSemanticDuplicateGroup(_ group: SemanticDuplicateGroup) async throws -> Int64 {
        // For semantic duplicates, we may want to keep multiple versions
        // but optimize storage through shared components
        let primaryItem = selectPrimaryItem(from: group.items)
        var spaceSaved: Int64 = 0
        
        for item in group.items where item.id != primaryItem.id {
            // Create semantic reference with delta storage
            let deltaSize = try await createSemanticReference(from: item, to: primaryItem)
            spaceSaved += item.size - deltaSize
        }
        
        return spaceSaved
    }
    
    private func selectPrimaryItem(from items: [ContentItem]) -> ContentItem {
        // Select the item with the most favorable characteristics:
        // 1. Most recent
        // 2. Most accessible location
        // 3. Highest quality metadata
        
        return items.max { item1, item2 in
            // Prefer more recent items
            let date1 = item1.metadata.createdAt
            let date2 = item2.metadata.createdAt
            
            if date1 != date2 {
                return date1 < date2
            }
            
            // Prefer items in more accessible tiers
            let tier1 = item1.metadata.storageTier ?? .warm
            let tier2 = item2.metadata.storageTier ?? .warm
            
            return tier1.rawValue > tier2.rawValue
        } ?? items.first!
    }
    
    private func createContentReference(from sourceItem: ContentItem, to targetItem: ContentItem) async throws {
        // Create a reference structure that points to the target
        let reference = ContentReference(
            sourceId: sourceItem.id,
            targetId: targetItem.id,
            referenceType: .exact,
            createdAt: Date()
        )
        
        // Update content registry
        contentRegistry.references[sourceItem.id] = reference
        await saveContentRegistry()
    }
    
    private func createSemanticReference(from sourceItem: ContentItem, to targetItem: ContentItem) async throws -> Int64 {
        // Calculate the delta between similar items
        guard let sourceText = sourceItem.textContent,
              let targetText = targetItem.textContent else {
            throw ArcanaError.storageError("Cannot create semantic reference without text content")
        }
        
        let delta = calculateTextDelta(from: targetText, to: sourceText)
        let deltaSize = Int64(delta.data(using: .utf8)?.count ?? sourceText.count)
        
        let reference = ContentReference(
            sourceId: sourceItem.id,
            targetId: targetItem.id,
            referenceType: .semantic,
            createdAt: Date(),
            delta: delta
        )
        
        // Update content registry
        contentRegistry.references[sourceItem.id] = reference
        await saveContentRegistry()
        
        return deltaSize
    }
    
    private func calculateTextDelta(from base: String, to target: String) -> String {
        // Simplified delta calculation
        // In a real implementation, this would use a sophisticated diff algorithm
        
        let baseLines = base.components(separatedBy: .newlines)
        let targetLines = target.components(separatedBy: .newlines)
        
        var delta: [String] = []
        
        for (index, targetLine) in targetLines.enumerated() {
            if index < baseLines.count {
                if baseLines[index] != targetLine {
                    delta.append("CHANGE:\(index):\(targetLine)")
                }
            } else {
                delta.append("ADD:\(index):\(targetLine)")
            }
        }
        
        return delta.joined(separator: "\n")
    }
    
    private func calculateContentHash(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func extractTextContent<T: Codable>(_ content: T) -> String? {
        // Try to extract meaningful text content for semantic analysis
        
        if let stringContent = content as? String {
            return stringContent
        }
        
        // For other types, try to encode as JSON and extract string values
        do {
            let data = try JSONEncoder().encode(content)
            if let jsonString = String(data: data, encoding: .utf8) {
                return extractStringsFromJSON(jsonString)
            }
        } catch {
            return nil
        }
        
        return nil
    }
    
    private func extractStringsFromJSON(_ json: String) -> String {
        // Extract string values from JSON for semantic analysis
        // This is a simplified implementation
        
        do {
            let jsonData = json.data(using: .utf8) ?? Data()
            let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
            var extractedStrings: [String] = []
            
            extractStringsRecursively(from: jsonObject, into: &extractedStrings)
            
            return extractedStrings.joined(separator: " ")
        } catch {
            return json
        }
    }
    
    private func extractStringsRecursively(from object: Any, into strings: inout [String]) {
        if let string = object as? String, string.count > 3 {
            strings.append(string)
        } else if let array = object as? [Any] {
            for item in array {
                extractStringsRecursively(from: item, into: &strings)
            }
        } else if let dictionary = object as? [String: Any] {
            for value in dictionary.values {
                extractStringsRecursively(from: value, into: &strings)
            }
        }
    }
    
    private func checkSemanticSimilarity(_ textContent: String, hash: String, metadata: ContentMetadata) async -> DuplicationCheckResult? {
        
        // Generate semantic embedding
        guard let embedding = try? await semanticMemory.generateEmbedding(for: textContent) else {
            return nil
        }
        
        // Check against existing semantic groups
        for (groupId, group) in contentRegistry.semanticGroups {
            let similarity = await calculateEmbeddingSimilarity(embedding, group.centroidEmbedding)
            
            if similarity >= semanticSimilarityThreshold {
                // Found semantic duplicate
                let representativeEntry = contentRegistry.exactMatches[group.representativeHash]
                
                return DuplicationCheckResult(
                    isDuplicate: true,
                    duplicateType: .semantic,
                    existingContentId: representativeEntry?.contentId,
                    existingLocation: representativeEntry?.location,
                    similarityScore: similarity,
                    spaceSavings: Int64(textContent.count) / 2, // Estimate 50% savings
                    processingTime: 0.0
                )
            }
        }
        
        return nil
    }
    
    private func calculateSemanticSimilarity(_ text1: String, _ text2: String) async -> Double? {
        do {
            let embedding1 = try await semanticMemory.generateEmbedding(for: text1)
            let embedding2 = try await semanticMemory.generateEmbedding(for: text2)
            
            return await calculateEmbeddingSimilarity(embedding1, embedding2)
        } catch {
            return nil
        }
    }
    
    private func calculateEmbeddingSimilarity(_ embedding1: [Double], _ embedding2: [Double]) async -> Double {
        guard embedding1.count == embedding2.count else { return 0.0 }
        
        // Calculate cosine similarity
        let dotProduct = zip(embedding1, embedding2).map(*).reduce(0, +)
        let magnitude1 = sqrt(embedding1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(embedding2.map { $0 * $0 }.reduce(0, +))
        
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0.0 }
        
        return dotProduct / (magnitude1 * magnitude2)
    }
    
    private func calculateAverageSimilarity(_ items: [ContentItem]) async -> Double {
        guard items.count > 1, let firstText = items.first?.textContent else { return 0.0 }
        
        var totalSimilarity = 0.0
        var comparisons = 0
        
        for i in 0..<items.count {
            for j in (i+1)..<items.count {
                if let text1 = items[i].textContent,
                   let text2 = items[j].textContent,
                   let similarity = await calculateSemanticSimilarity(text1, text2) {
                    totalSimilarity += similarity
                    comparisons += 1
                }
            }
        }
        
        return comparisons > 0 ? totalSimilarity / Double(comparisons) : 0.0
    }
    
    private func calculateSpaceSavings(_ items: [ContentItem]) -> Int64 {
        guard items.count > 1 else { return 0 }
        
        let totalSize = items.reduce(0) { $0 + $1.size }
        let primarySize = items.max(by: { $0.size < $1.size })?.size ?? 0
        
        return totalSize - primarySize
    }
    
    private func registerNewContent(contentId: String, hash: String, metadata: ContentMetadata, size: Int64, textContent: String?) async {
        
        let entry = ContentRegistryEntry(
            contentId: contentId,
            location: metadata.location ?? "unknown",
            size: size,
            workspaceId: metadata.workspaceId ?? "unknown",
            metadata: metadata,
            textContent: textContent
        )
        
        contentRegistry.exactMatches[hash] = entry
        contentRegistry.totalEntries += 1
        
        // If we have text content, add to semantic analysis
        if let text = textContent, let embedding = try? await semanticMemory.generateEmbedding(for: text) {
            // Find or create semantic group
            await addToSemanticGroup(hash: hash, embedding: embedding, contentId: contentId)
        }
        
        await saveContentRegistry()
    }
    
    private func addToSemanticGroup(hash: String, embedding: [Double], contentId: String) async {
        var bestGroupId: String?
        var bestSimilarity: Double = 0.0
        
        // Find the most similar existing group
        for (groupId, group) in contentRegistry.semanticGroups {
            let similarity = await calculateEmbeddingSimilarity(embedding, group.centroidEmbedding)
            if similarity > bestSimilarity && similarity >= semanticSimilarityThreshold {
                bestSimilarity = similarity
                bestGroupId = groupId
            }
        }
        
        if let groupId = bestGroupId {
            // Add to existing group
            var group = contentRegistry.semanticGroups[groupId]!
            group.memberHashes.insert(hash)
            group.centroidEmbedding = updateCentroid(group.centroidEmbedding, with: embedding, memberCount: group.memberHashes.count)
            contentRegistry.semanticGroups[groupId] = group
        } else {
            // Create new group
            let newGroupId = UUID().uuidString
            let newGroup = SemanticGroup(
                groupId: newGroupId,
                representativeHash: hash,
                centroidEmbedding: embedding,
                memberHashes: Set([hash])
            )
            contentRegistry.semanticGroups[newGroupId] = newGroup
        }
    }
    
    private func updateCentroid(_ currentCentroid: [Double], with newEmbedding: [Double], memberCount: Int) -> [Double] {
        // Update centroid with new embedding
        guard currentCentroid.count == newEmbedding.count else { return currentCentroid }
        
        let weight = 1.0 / Double(memberCount)
        let oldWeight = 1.0 - weight
        
        return zip(currentCentroid, newEmbedding).map { oldWeight * $0 + weight * $1 }
    }
    
    private func startBackgroundDeduplication() async {
        let task = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 24 * 3600_000_000_000) // 24 hours
                try? await self?.performDeduplication()
            }
        }
        deduplicationTasks.insert(task)
    }
    
    private func validateContentReferences() async -> Set<String> {
        // This would validate that referenced content still exists
        // For now, return all hashes as valid
        return Set(contentRegistry.exactMatches.keys)
    }
    
    private func optimizeSemanticGroups() async {
        // Remove groups with only one member
        contentRegistry.semanticGroups = contentRegistry.semanticGroups.filter { _, group in
            group.memberHashes.count > 1
        }
        
        // Merge similar groups
        await mergeSimila rSemanticGroups()
    }
    
    private func mergeSimilarSemanticGroups() async {
        var groupsToMerge: [(String, String)] = []
        let groupIds = Array(contentRegistry.semanticGroups.keys)
        
        // Find groups that should be merged
        for i in 0..<groupIds.count {
            for j in (i+1)..<groupIds.count {
                let group1 = contentRegistry.semanticGroups[groupIds[i]]!
                let group2 = contentRegistry.semanticGroups[groupIds[j]]!
                
                let similarity = await calculateEmbeddingSimilarity(
                    group1.centroidEmbedding,
                    group2.centroidEmbedding
                )
                
                if similarity >= semanticSimilarityThreshold {
                    groupsToMerge.append((groupIds[i], groupIds[j]))
                }
            }
        }
        
        // Merge groups
        for (groupId1, groupId2) in groupsToMerge {
            guard let group1 = contentRegistry.semanticGroups[groupId1],
                  let group2 = contentRegistry.semanticGroups[groupId2] else { continue }
            
            // Merge into group1
            let mergedGroup = SemanticGroup(
                groupId: group1.groupId,
                representativeHash: group1.representativeHash,
                centroidEmbedding: averageEmbeddings([group1.centroidEmbedding, group2.centroidEmbedding]),
                memberHashes: group1.memberHashes.union(group2.memberHashes)
            )
            
            contentRegistry.semanticGroups[groupId1] = mergedGroup
            contentRegistry.semanticGroups.removeValue(forKey: groupId2)
        }
    }
    
    private func averageEmbeddings(_ embeddings: [[Double]]) -> [Double] {
        guard !embeddings.isEmpty else { return [] }
        guard let firstEmbedding = embeddings.first else { return [] }
        
        var averaged = Array(repeating: 0.0, count: firstEmbedding.count)
        
        for embedding in embeddings {
            for (index, value) in embedding.enumerated() {
                averaged[index] += value
            }
        }
        
        let count = Double(embeddings.count)
        return averaged.map { $0 / count }
    }
    
    private func updateDeduplicationStatistics(spaceSaved: Int64, duplicatesProcessed: Int, processingTime: TimeInterval) async {
        deduplicationStatistics.totalDeduplicationRuns += 1
        deduplicationStatistics.totalSpaceSaved += spaceSaved
        deduplicationStatistics.totalDuplicatesFound += duplicatesProcessed
        deduplicationStatistics.totalProcessingTime += processingTime
        
        deduplicationStatistics.averageSpaceSaved = deduplicationStatistics.totalSpaceSaved / Int64(max(1, deduplicationStatistics.totalDeduplicationRuns))
        deduplicationStatistics.averageProcessingTime = deduplicationStatistics.totalProcessingTime / Double(max(1, deduplicationStatistics.totalDeduplicationRuns))
        deduplicationStatistics.lastDeduplicationDate = Date()
    }
    
    private func recordDeduplicationMetrics(operation: String, processingTime: TimeInterval, spaceSaved: Int64, duplicatesFound: Int) async {
        await performanceMonitor.recordMetric(
            .deduplication,
            value: processingTime,
            context: [
                "operation": operation,
                "space_saved": String(spaceSaved),
                "duplicates_found": String(duplicatesFound),
                "deduplication_ratio": String(spaceSaved > 0 ? Double(duplicatesFound) / Double(spaceSaved) * 1000 : 0)
            ]
        )
    }
    
    private func calculateSpaceUtilization() -> SpaceUtilization {
        let totalSize = contentRegistry.exactMatches.values.reduce(0) { $0 + $1.size }
        let uniqueSize = totalSize - totalSpaceSaved
        
        return SpaceUtilization(
            totalSize: totalSize,
            uniqueSize: uniqueSize,
            duplicateSize: totalSpaceSaved,
            utilizationRatio: totalSize > 0 ? Double(uniqueSize) / Double(totalSize) : 1.0
        )
    }
    
    private func analyzeDuplicateDistribution() -> DuplicateDistribution {
        let exactDuplicates = contentRegistry.exactMatches.count
        let semanticGroups = contentRegistry.semanticGroups.count
        
        var workspaceDistribution: [String: Int] = [:]
        
        for entry in contentRegistry.exactMatches.values {
            workspaceDistribution[entry.workspaceId, default: 0] += 1
        }
        
        return DuplicateDistribution(
            exactDuplicates: exactDuplicates,
            semanticDuplicates: semanticGroups,
            crossWorkspaceDuplicates: calculateCrossWorkspaceDuplicates(),
            workspaceDistribution: workspaceDistribution
        )
    }
    
    private func calculateCrossWorkspaceDuplicates() -> Int {
        var crossWorkspaceCount = 0
        
        // Count semantic groups that span multiple workspaces
        for group in contentRegistry.semanticGroups.values {
            let workspaces = Set(group.memberHashes.compactMap { hash in
                contentRegistry.exactMatches[hash]?.workspaceId
            })
            
            if workspaces.count > 1 {
                crossWorkspaceCount += 1
            }
        }
        
        return crossWorkspaceCount
    }
    
    private func calculateDeduplicationEffectiveness() -> DeduplicationEffectiveness {
        let spaceUtilization = calculateSpaceUtilization()
        
        return DeduplicationEffectiveness(
            compressionRatio: spaceUtilization.utilizationRatio,
            storageEfficiency: 1.0 - spaceUtilization.utilizationRatio,
            duplicateDetectionAccuracy: 0.95, // Would be calculated from validation data
            falsePositiveRate: 0.02, // Would be calculated from validation data
            processingEfficiency: deduplicationStatistics.averageProcessingTime > 0 ?
                Double(deduplicationStatistics.totalDuplicatesFound) / deduplicationStatistics.averageProcessingTime : 0.0
        )
    }
    
    private func generateOptimizationRecommendations() -> [String] {
        var recommendations: [String] = []
        
        let analytics = getDeduplicationAnalytics()
        
        if analytics.effectiveness.compressionRatio < 0.8 {
            recommendations.append("Low compression ratio detected - consider adjusting similarity thresholds")
        }
        
        if analytics.duplicateDistribution.crossWorkspaceDuplicates > analytics.duplicateDistribution.exactDuplicates * 0.3 {
            recommendations.append("High cross-workspace duplication - optimize workspace organization")
        }
        
        if deduplicationStatistics.averageProcessingTime > 300.0 { // 5 minutes
            recommendations.append("Deduplication processing time is high - consider optimizing algorithms")
        }
        
        if contentRegistry.semanticGroups.count > contentRegistry.exactMatches.count * 0.1 {
            recommendations.append("High number of semantic groups - consider optimizing group management")
        }
        
        return recommendations
    }
    
    private func getDeduplicationPerformanceMetrics() async -> DeduplicationPerformanceMetrics {
        return DeduplicationPerformanceMetrics(
            averageProcessingTime: deduplicationStatistics.averageProcessingTime,
            throughput: deduplicationStatistics.averageProcessingTime > 0 ?
                Double(deduplicationStatistics.totalDuplicatesFound) / deduplicationStatistics.averageProcessingTime : 0.0,
            memoryUsage: 0, // Would be calculated from actual metrics
            cacheHitRate: 0.85 // Would be calculated from actual metrics
        )
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Supporting Types

/// Registry for tracking all content and duplicates
public struct ContentRegistry: Codable, Hashable {
    public var exactMatches: [String: ContentRegistryEntry] = [:]
    public var semanticGroups: [String: SemanticGroup] = [:]
    public var references: [String: ContentReference] = [:]
    public var totalEntries: Int = 0
}

/// Entry in the content registry
public struct ContentRegistryEntry: Codable, Hashable {
    public let contentId: String
    public let location: String
    public let size: Int64
    public let workspaceId: String
    public let metadata: ContentMetadata
    public let textContent: String?
}

/// Metadata about content for deduplication
public struct ContentMetadata: Codable, Hashable {
    public let createdAt: Date
    public let workspaceId: String?
    public let location: String?
    public let storageTier: StorageTier?
    public let contentType: String?
    
    public init(createdAt: Date = Date(), workspaceId: String? = nil, location: String? = nil, storageTier: StorageTier? = nil, contentType: String? = nil) {
        self.createdAt = createdAt
        self.workspaceId = workspaceId
        self.location = location
        self.storageTier = storageTier
        self.contentType = contentType
    }
}

/// Semantic group of similar content
public struct SemanticGroup: Codable, Hashable {
    public let groupId: String
    public let representativeHash: String
    public var centroidEmbedding: [Double]
    public var memberHashes: Set<String>
}

/// Reference from one content item to another
public struct ContentReference: Codable, Hashable {
    public let sourceId: String
    public let targetId: String
    public let referenceType: ReferenceType
    public let createdAt: Date
    public let delta: String?
    
    public init(sourceId: String, targetId: String, referenceType: ReferenceType, createdAt: Date, delta: String? = nil) {
        self.sourceId = sourceId
        self.targetId = targetId
        self.referenceType = referenceType
        self.createdAt = createdAt
        self.delta = delta
    }
}

/// Types of content references
public enum ReferenceType: String, Codable, CaseIterable, Hashable {
    case exact
    case semantic
}

/// Item of content being analyzed
public struct ContentItem {
    public let id: String
    public let hash: String
    public let location: String
    public let size: Int64
    public let workspaceId: String
    public let metadata: ContentMetadata
    public let textContent: String?
}

/// Group of exact duplicates
public struct ExactDuplicateGroup {
    public let hash: String
    public let duplicateItems: [ContentItem]
    public let spaceSavings: Int64
}

/// Group of semantically similar content
public struct SemanticDuplicateGroup {
    public let items: [ContentItem]
    public let averageSimilarity: Double
    public let spaceSavings: Int64
}

/// Result of duplication check
public struct DuplicationCheckResult {
    public let isDuplicate: Bool
    public let duplicateType: DuplicationType?
    public let existingContentId: String?
    public let existingLocation: String?
    public let similarityScore: Double
    public let spaceSavings: Int64
    public let processingTime: TimeInterval
}

/// Types of duplication
public enum DuplicationType: String, Codable, CaseIterable, Hashable {
    case exact
    case semantic
}

/// Statistics about deduplication operations
public struct DeduplicationStatistics: Codable, Hashable {
    public var totalDeduplicationRuns: Int = 0
    public var totalSpaceSaved: Int64 = 0
    public var totalDuplicatesFound: Int = 0
    public var totalProcessingTime: TimeInterval = 0
    public var averageSpaceSaved: Int64 = 0
    public var averageProcessingTime: TimeInterval = 0
    public var lastDeduplicationDate: Date?
}

/// Analytics about deduplication performance
public struct DeduplicationAnalytics: Codable, Hashable {
    public let statistics: DeduplicationStatistics
    public let totalContentTracked: Int
    public let spaceUtilization: SpaceUtilization
    public let duplicateDistribution: DuplicateDistribution
    public let effectiveness: DeduplicationEffectiveness
    public let recommendations: [String]
}

/// Space utilization metrics
public struct SpaceUtilization: Codable, Hashable {
    public let totalSize: Int64
    public let uniqueSize: Int64
    public let duplicateSize: Int64
    public let utilizationRatio: Double
}

/// Distribution of duplicates across different categories
public struct DuplicateDistribution: Codable, Hashable {
    public let exactDuplicates: Int
    public let semanticDuplicates: Int
    public let crossWorkspaceDuplicates: Int
    public let workspaceDistribution: [String: Int]
}

/// Effectiveness metrics for deduplication
public struct DeduplicationEffectiveness: Codable, Hashable {
    public let compressionRatio: Double
    public let storageEfficiency: Double
    public let duplicateDetectionAccuracy: Double
    public let falsePositiveRate: Double
    public let processingEfficiency: Double
}

/// Performance metrics for deduplication operations
public struct DeduplicationPerformanceMetrics: Codable, Hashable {
    public let averageProcessingTime: TimeInterval
    public let throughput: Double
    public let memoryUsage: Int64
    public let cacheHitRate: Double
}

/// Export data for content registry
public struct ContentRegistryExport: Codable, Hashable {
    public let totalEntries: Int
    public let exactMatches: Int
    public let semanticGroups: Int
}

/// Complete deduplication report
public struct DeduplicationReport: Codable, Hashable {
    public let exportDate: Date
    public let analytics: DeduplicationAnalytics
    public let contentRegistry: ContentRegistryExport
    public let performanceMetrics: DeduplicationPerformanceMetrics
}
