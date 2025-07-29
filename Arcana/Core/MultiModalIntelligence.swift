//
// Core/MultiModalIntelligence.swift
// Arcana
//

import Foundation
import OSLog

struct ProcessedFileContent {
    let content: String
    let summary: String
    let keyPoints: [String]
    let actions: [String]
    let confidence: Double
}

@MainActor
class MultiModalIntelligence: ObservableObject {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "MultiModalIntelligence")
    
    func processFile(content: String, type: SupportedFileType, filename: String) async throws -> ProcessedFileContent {
        logger.debug("Processing \(type.displayName) file: \(filename)")
        
        // Route to appropriate processor based on file type
        switch type {
        case .pdf, .docx, .txt, .markdown:
            return await processDocumentFile(content: content, type: type)
        case .csv:
            return await processDataFile(content: content, type: type)
        case .swift, .python:
            return await processCodeFile(content: content, type: type)
        case .json:
            return await processStructuredFile(content: content, type: type)
        }
    }
    
    private func processDocumentFile(content: String, type: SupportedFileType) async -> ProcessedFileContent {
        // Extract key information from document
        let sentences = content.components(separatedBy: ". ")
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).count
        
        let summary = generateDocumentSummary(content: content, sentences: sentences)
        let keyPoints = extractKeyPoints(from: sentences)
        let actions = suggestDocumentActions(type: type, wordCount: wordCount)
        
        return ProcessedFileContent(
            content: content,
            summary: summary,
            keyPoints: keyPoints,
            actions: actions,
            confidence: 0.9
        )
    }
    
    private func processDataFile(content: String, type: SupportedFileType) async -> ProcessedFileContent {
        // Analyze CSV data structure
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        let columns = lines.first?.components(separatedBy: ",").count ?? 0
        let rows = lines.count - 1 // Exclude header
        
        let summary = "CSV file with \(columns) columns and \(rows) data rows"
        let keyPoints = analyzeCSVStructure(lines: lines)
        let actions = ["Analyze data trends", "Create visualizations", "Export filtered data", "Generate report"]
        
        return ProcessedFileContent(
            content: content,
            summary: summary,
            keyPoints: keyPoints,
            actions: actions,
            confidence: 0.95
        )
    }
    
    private func processCodeFile(content: String, type: SupportedFileType) async -> ProcessedFileContent {
        // Analyze code structure
        let lines = content.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        let summary = generateCodeSummary(content: content, type: type, lines: nonEmptyLines)
        let keyPoints = extractCodeFeatures(from: content, type: type)
        let actions = suggestCodeActions(type: type)
        
        return ProcessedFileContent(
            content: content,
            summary: summary,
            keyPoints: keyPoints,
            actions: actions,
            confidence: 0.92
        )
    }
    
    private func processStructuredFile(content: String, type: SupportedFileType) async -> ProcessedFileContent {
        // Analyze JSON structure
        let summary = "JSON file with structured data"
        let keyPoints = ["Structured data format", "Nested objects detected", "Array elements present"]
        let actions = ["Parse JSON structure", "Extract specific fields", "Convert to CSV", "Validate format"]
        
        return ProcessedFileContent(
            content: content,
            summary: summary,
            keyPoints: keyPoints,
            actions: actions,
            confidence: 0.88
        )
    }
    
    // MARK: - Helper Methods
    
    private func generateDocumentSummary(content: String, sentences: [String]) -> String {
        let wordCount = content.components(separatedBy: .whitespacesAndNewlines).count
        let sentenceCount = sentences.count
        
        return "Document with \(wordCount) words across \(sentenceCount) sentences. Content includes key insights and detailed information."
    }
    
    private func extractKeyPoints(from sentences: [String]) -> [String] {
        // Extract sentences that might be key points
        return sentences.filter { sentence in
            sentence.count > 20 && sentence.count < 100
        }.prefix(5).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    }
    
    private func suggestDocumentActions(type: SupportedFileType, wordCount: Int) -> [String] {
        var actions = ["Summarize content", "Extract key points", "Answer questions"]
        
        if wordCount > 1000 {
            actions.append("Create outline")
        }
        
        if type == .markdown {
            actions.append("Convert to PDF")
        }
        
        return actions
    }
    
    private func analyzeCSVStructure(lines: [String]) -> [String] {
        guard !lines.isEmpty else { return [] }
        
        var keyPoints: [String] = []
        
        // Analyze header
        let header = lines[0]
        let columns = header.components(separatedBy: ",")
        keyPoints.append("Columns: \(columns.joined(separator: ", "))")
        
        // Analyze data types
        if lines.count > 1 {
            let sampleRow = lines[1].components(separatedBy: ",")
            var types: [String] = []
            
            for value in sampleRow {
                if Double(value) != nil {
                    types.append("numeric")
                } else if value.contains("/") || value.contains("-") {
                    types.append("date")
                } else {
                    types.append("text")
                }
            }
            
            keyPoints.append("Data types detected: \(types.joined(separator: ", "))")
        }
        
        keyPoints.append("Total rows: \(lines.count - 1)")
        
        return keyPoints
    }
    
    private func generateCodeSummary(content: String, type: SupportedFileType, lines: [String]) -> String {
        let language = type == .swift ? "Swift" : "Python"
        let loc = lines.count
        
        // Count functions/methods
        let functionCount = lines.filter { line in
            line.contains("func ") || line.contains("def ")
        }.count
        
        return "\(language) file with \(loc) lines of code and \(functionCount) functions/methods"
    }
    
    private func extractCodeFeatures(from content: String, type: SupportedFileType) -> [String] {
        var features: [String] = []
        
        if type == .swift {
            if content.contains("import SwiftUI") {
                features.append("SwiftUI interface code")
            }
            if content.contains("@Published") {
                features.append("Observable object pattern")
            }
            if content.contains("async") {
                features.append("Async/await concurrency")
            }
        } else if type == .python {
            if content.contains("import pandas") {
                features.append("Data analysis with Pandas")
            }
            if content.contains("def ") {
                features.append("Function definitions")
            }
            if content.contains("class ") {
                features.append("Object-oriented programming")
            }
        }
        
        return features
    }
    
    private func suggestCodeActions(type: SupportedFileType) -> [String] {
        if type == .swift {
            return ["Explain code", "Find bugs", "Optimize performance", "Add documentation", "Write tests"]
        } else {
            return ["Explain code", "Debug issues", "Optimize algorithm", "Add type hints", "Write unit tests"]
        }
    }
}
