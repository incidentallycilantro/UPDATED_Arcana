//
// Core/SemanticMemoryEngine.swift
// Arcana
//

import Foundation
import OSLog

@MainActor
class SemanticMemoryEngine: ObservableObject {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "SemanticMemory")
    private var embeddings: [String: [Float]] = [:]
    private var semanticClusters: [SemanticCluster] = []
    
    func initialize() async throws {
        logger.info("Initializing Semantic Memory Engine...")
        
        // Load existing embeddings and clusters
        await loadSemanticData()
        
        logger.info("Semantic Memory Engine initialized")
    }
    
    func getEmbedding(for text: String) async -> [Float] {
        // Check cache first
        if let cached = embeddings[text] {
            return cached
        }
        
        // Generate embedding (simplified - would use actual model)
        let embedding = generateSimulatedEmbedding(for: text)
        embeddings[text] = embedding
        
        return embedding
    }
    
    func getSuggestions(partialInput: String, context: ConversationContext) async -> [String] {
        let inputEmbedding = await getEmbedding(for: partialInput)
        
        // Find similar embeddings
        var similarities: [(String, Double)] = []
        
        for (text, embedding) in embeddings {
            let similarity = cosineSimilarity(inputEmbedding, embedding)
            if similarity > 0.7 && text != partialInput {
                similarities.append((text, similarity))
            }
        }
        
        // Sort by similarity and return top suggestions
        return similarities
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0.0 }
    }
    
    func updateWithResponse(_ response: PRISMResponse, context: ConversationContext) async {
        // Generate embedding for the response
        let embedding = await getEmbedding(for: response.response)
        
        // Update semantic clusters
        await updateSemanticClusters(text: response.response, embedding: embedding, context: context)
    }
    
    private func loadSemanticData() async {
        // Load embeddings and clusters from storage
        embeddings = [:]
        semanticClusters = []
        
        logger.debug("Loaded semantic data from storage")
    }
    
    private func generateSimulatedEmbedding(for text: String) -> [Float] {
        // Generate a simplified embedding (384 dimensions)
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var embedding = Array(repeating: Float(0), count: 384)
        
        // Simple hash-based embedding generation
        for (index, word) in words.enumerated() {
            let wordHash = word.hash
            let embeddingIndex = abs(wordHash) % 384
            embedding[embeddingIndex] += Float.random(in: -1...1)
        }
        
        // Normalize the embedding
        let magnitude = sqrt(embedding.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            embedding = embedding.map { $0 / magnitude }
        }
        
        return embedding
    }
    
    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count else { return 0 }
        
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let magnitudeA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        
        if magnitudeA == 0 || magnitudeB == 0 {
            return 0
        }
        
        return Double(dotProduct / (magnitudeA * magnitudeB))
    }
    
    private func updateSemanticClusters(text: String, embedding: [Float], context: ConversationContext) async {
        // Find the best matching cluster
        var bestCluster: SemanticCluster?
        var bestSimilarity = 0.0
        
        for cluster in semanticClusters {
            let similarity = cosineSimilarity(embedding, cluster.centroid)
            if similarity > bestSimilarity && similarity > 0.6 {
                bestSimilarity = similarity
                bestCluster = cluster
            }
        }
        
        if let cluster = bestCluster {
            // Add to existing cluster
            if let index = semanticClusters.firstIndex(where: { $0.id == cluster.id }) {
                semanticClusters[index].addText(text, embedding: embedding)
            }
        } else {
            // Create new cluster
            let newCluster = SemanticCluster(
                centroid: embedding,
                texts: [text],
                workspaceType: context.workspaceType
            )
            semanticClusters.append(newCluster)
        }
    }
}

struct SemanticCluster: Identifiable {
    let id = UUID()
    var centroid: [Float]
    var texts: [String]
    let workspaceType: WorkspaceType
    var createdAt = Date()
    var updatedAt = Date()
    
    mutating func addText(_ text: String, embedding: [Float]) {
        texts.append(text)
        updatedAt = Date()
        
        // Update centroid (simple average)
        for i in 0..<centroid.count {
            centroid[i] = (centroid[i] * Float(texts.count - 1) + embedding[i]) / Float(texts.count)
        }
    }
}
