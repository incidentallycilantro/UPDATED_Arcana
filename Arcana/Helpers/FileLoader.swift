//
// Helpers/FileLoader.swift
// Arcana
//

import Foundation
import OSLog
import UniformTypeIdentifiers

@MainActor
class FileLoader: ObservableObject {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "FileLoader")
    private let multiModalIntelligence: MultiModalIntelligence
    
    init() {
        self.multiModalIntelligence = MultiModalIntelligence()
    }
    
    func processFile(at url: URL) async throws -> FileProcessingResult {
        logger.info("Processing file: \(url.lastPathComponent)")
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Determine file type
        guard let fileType = determineFileType(for: url) else {
            throw ArcanaError.fileProcessingError("Unsupported file type")
        }
        
        // Read file content
        let content = try await readFileContent(url: url, type: fileType)
        
        // Process with appropriate model
        let processed = try await multiModalIntelligence.processFile(
            content: content,
            type: fileType,
            filename: url.lastPathComponent
        )
        
        let processingTime = CFAbsoluteTimeGetCurrent() - startTime
        
        let result = FileProcessingResult(
            filename: url.lastPathComponent,
            fileType: fileType,
            extractedContent: processed.content,
            summary: processed.summary,
            keyPoints: processed.keyPoints,
            suggestedActions: processed.actions,
            processingTime: processingTime,
            confidence: processed.confidence
        )
        
        logger.info("File processed: \(url.lastPathComponent) in \(processingTime, specifier: "%.2f")s")
        return result
    }
    
    private func determineFileType(for url: URL) -> SupportedFileType? {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "pdf": return .pdf
        case "docx": return .docx
        case "md", "markdown": return .markdown
        case "csv": return .csv
        case "txt": return .txt
        case "swift": return .swift
        case "py": return .python
        case "json": return .json
        default: return nil
        }
    }
    
    private func readFileContent(url: URL, type: SupportedFileType) async throws -> String {
        switch type {
        case .pdf:
            return try await extractPDFContent(from: url)
        case .docx:
            return try await extractDocxContent(from: url)
        case .markdown, .txt, .swift, .python, .json:
            return try String(contentsOf: url, encoding: .utf8)
        case .csv:
            return try await processCSVContent(from: url)
        }
    }
    
    private func extractPDFContent(from url: URL) async throws -> String {
        // Simplified PDF extraction (would use PDFKit in production)
        return "PDF content extracted from \(url.lastPathComponent)"
    }
    
    private func extractDocxContent(from url: URL) async throws -> String {
        // Simplified DOCX extraction (would use proper library in production)
        return "DOCX content extracted from \(url.lastPathComponent)"
    }
    
    private func processCSVContent(from url: URL) async throws -> String {
        let csvContent = try String(contentsOf: url, encoding: .utf8)
        let lines = csvContent.components(separatedBy: .newlines)
        
        if lines.count > 1 {
            let header = lines[0]
            let rowCount = lines.count - 1
            return "CSV file with headers: \(header)\nRows: \(rowCount)"
        }
        
        return csvContent
    }
}
