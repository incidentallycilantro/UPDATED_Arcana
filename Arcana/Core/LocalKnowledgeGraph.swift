//
// Core/LocalKnowledgeGraph.swift
// Arcana
//

import Foundation
import OSLog

@MainActor
class LocalKnowledgeGraph: ObservableObject {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "KnowledgeGraph")
    private var knowledgeNodes: [KnowledgeNode] = []
    private var connections: [KnowledgeConnection] = []
    
    func initialize() async throws {
        logger.info("Initializing Local Knowledge Graph...")
        
        // Load existing knowledge from storage
        await loadKnowledgeFromStorage()
        
        logger.info("Knowledge Graph initialized with \(knowledgeNodes.count) nodes")
    }
    
    func verifyAgainstKnowledge(_ claim: String) async -> Double {
        // Search for relevant knowledge nodes
        let relevantNodes = knowledgeNodes.filter { node in
            claim.localizedCaseInsensitiveContains(node.content) ||
            node.content.localizedCaseInsensitiveContains(claim)
        }
        
        if relevantNodes.isEmpty {
            return 0.5 // Neutral when no relevant knowledge
        }
        
        // Calculate verification score based on node reliability
        let scores = relevantNodes.map(\.reliability)
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    func getSuggestions(partialInput: String, context: ConversationContext) async -> [String] {
        // Find knowledge nodes related to the input
        let relevantNodes = knowledgeNodes.filter { node in
            node.content.localizedCaseInsensitiveContains(partialInput) ||
            node.tags.contains { tag in
                partialInput.localizedCaseInsensitiveContains(tag)
            }
        }.sorted { $0.relevanceScore > $1.relevanceScore }
        
        // Generate suggestions based on connected nodes
        var suggestions: [String] = []
        
        for node in relevantNodes.prefix(5) {
            let connectedNodes = getConnectedNodes(to: node.id)
            for connectedNode in connectedNodes.prefix(2) {
                suggestions.append(connectedNode.content)
            }
        }
        
        return Array(Set(suggestions)).prefix(5).map { $0 }
    }
    
    func updateWithResponse(_ response: PRISMResponse, context: ConversationContext) async {
        // Extract key concepts from the response
        let concepts = extractConcepts(from: response.response)
        
        // Create or update knowledge nodes
        for concept in concepts {
            await updateKnowledgeNode(
                content: concept,
                source: .aiResponse,
                reliability: response.confidence,
                context: context
            )
        }
        
        // Create connections between concepts
        await createConceptConnections(concepts, context: context)
    }
    
    private func loadKnowledgeFromStorage() async {
        // Load knowledge from persistent storage
        // This would read from actual files in production
        knowledgeNodes = []
        connections = []
        
        logger.debug("Loaded knowledge from storage")
    }
    
    private func extractConcepts(from text: String) -> [String] {
        // Simple concept extraction (would use NLP in production)
        let sentences = text.components(separatedBy: ". ")
        let concepts = sentences.compactMap { sentence in
            // Extract noun phrases, technical terms, etc.
            sentence.count > 10 ? sentence : nil
        }
        
        return Array(concepts.prefix(5))
    }
    
    private func updateKnowledgeNode(
        content: String,
        source: KnowledgeSource,
        reliability: Double,
        context: ConversationContext
    ) async {
        // Check if node already exists
        if let existingIndex = knowledgeNodes.firstIndex(where: { $0.content == content }) {
            // Update existing node
            knowledgeNodes[existingIndex].reinforceWith(reliability: reliability)
        } else {
            // Create new node
            let newNode = KnowledgeNode(
                content: content,
                source: source,
                reliability: reliability,
                workspaceType: context.workspaceType,
                tags: extractTags(from: content)
            )
            knowledgeNodes.append(newNode)
        }
    }
    
    private func createConceptConnections(_ concepts: [String], context: ConversationContext) async {
        // Create connections between related concepts
        for i in 0..<concepts.count {
            for j in (i+1)..<concepts.count {
                let concept1 = concepts[i]
                let concept2 = concepts[j]
                
                if let node1 = knowledgeNodes.first(where: { $0.content == concept1 }),
                   let node2 = knowledgeNodes.first(where: { $0.content == concept2 }) {
                    
                    let connection = KnowledgeConnection(
                        from: node1.id,
                        to: node2.id,
                        strength: calculateConnectionStrength(concept1, concept2),
                        type: .conceptual
                    )
                    
                    connections.append(connection)
                }
            }
        }
    }
    
    private func extractTags(from content: String) -> [String] {
        // Extract relevant tags from content
        let words = content.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at"])
        
        return words.filter { word in
            word.count > 3 && !stopWords.contains(word)
        }.prefix(5).map { $0 }
    }
    
    private func calculateConnectionStrength(_ concept1: String, _ concept2: String) -> Double {
        // Calculate semantic similarity between concepts
        let words1 = Set(concept1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(concept2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return Double(intersection.count) / Double(union.count)
    }
    
    private func getConnectedNodes(to nodeId: UUID) -> [KnowledgeNode] {
        let connectedIds = connections
            .filter { $0.from == nodeId || $0.to == nodeId }
            .map { $0.from == nodeId ? $0.to : $0.from }
        
        return knowledgeNodes.filter { connectedIds.contains($0.id) }
    }
}

// MARK: - Supporting Types

struct KnowledgeNode: Identifiable, Codable {
    let id: UUID
    let content: String
    let source: KnowledgeSource
    var reliability: Double
    let workspaceType: WorkspaceType
    let tags: [String]
    let createdAt: Date
    var updatedAt: Date
    var accessCount: Int
    var relevanceScore: Double
    
    init(content: String, source: KnowledgeSource, reliability: Double, workspaceType: WorkspaceType, tags: [String]) {
        self.id = UUID()
        self.content = content
        self.source = source
        self.reliability = reliability
        self.workspaceType = workspaceType
        self.tags = tags
        self.createdAt = Date()
        self.updatedAt = Date()
        self.accessCount = 1
        self.relevanceScore = reliability
    }
    
    mutating func reinforceWith(reliability: Double) {
        self.reliability = (self.reliability + reliability) / 2.0
        self.updatedAt = Date()
        self.accessCount += 1
        self.relevanceScore = self.reliability * Double(accessCount) * 0.1
    }
}

struct KnowledgeConnection: Identifiable, Codable {
    let id: UUID
    let from: UUID
    let to: UUID
    let strength: Double
    let type: ConnectionType
    let createdAt: Date
    
    init(from: UUID, to: UUID, strength: Double, type: ConnectionType) {
        self.id = UUID()
        self.from = from
        self.to = to
        self.strength = strength
        self.type = type
        self.createdAt = Date()
    }
}

enum KnowledgeSource: String, Codable {
    case aiResponse = "aiResponse"
    case userInput = "userInput"
    case webResearch = "webResearch"
    case fileImport = "fileImport"
}

enum ConnectionType: String, Codable {
    case conceptual = "conceptual"
    case temporal = "temporal"
    case causal = "causal"
    case similarity = "similarity"
}
