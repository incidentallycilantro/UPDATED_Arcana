//
// FileValidationEngine.swift
// Arcana
//
// Revolutionary file content verification and security scanning system
// Ensures file integrity and safety before processing in the PRISM intelligence engine
//

import Foundation
import Combine
import CryptoKit
import UniformTypeIdentifiers

// MARK: - File Validation Engine

/// Revolutionary file validation system with comprehensive security and integrity checks
/// Provides multi-layered validation before files enter the PRISM processing pipeline
@MainActor
public class FileValidationEngine: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isValidating: Bool = false
    @Published private(set) var validationProgress: Double = 0.0
    @Published private(set) var lastValidationResult: FileValidationResult?
    @Published private(set) var validationStatistics: ValidationStatistics = ValidationStatistics()
    
    // MARK: - Private Properties
    
    private let encryptionManager: LocalEncryptionManager
    private let performanceMonitor: PerformanceMonitor
    private var validationTasks: Set<Task<Void, Never>> = []
    private let maxFileSize: Int64 = 100 * 1024 * 1024 // 100MB limit
    private let allowedFileTypes: Set<UTType>
    private var validationCache: [String: FileValidationResult] = [:]
    
    // MARK: - Security Configuration
    
    private let malwareSignatures: [String] = [
        // Known malware patterns (simplified for demo)
        "X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*",
        "eval(", "exec(", "system(", "shell_exec(", "__import__",
        "document.write", "innerHTML", "createElement"
    ]
    
    private let suspiciousPatterns: [String] = [
        "javascript:", "vbscript:", "data:", "file://",
        "ftp://", "telnet://", "ldap://", "gopher://"
    ]
    
    // MARK: - Initialization
    
    public init(encryptionManager: LocalEncryptionManager,
                performanceMonitor: PerformanceMonitor) {
        self.encryptionManager = encryptionManager
        self.performanceMonitor = performanceMonitor
        
        // Define allowed file types
        self.allowedFileTypes = Set([
            .pdf, .plainText, .rtf, .html, .xml, .json,
            .commaSeparatedText, .tabSeparatedText,
            .swiftSource, .pythonScript, .javaScript,
            .cSource, .cPlusPlusSource, .objectiveCSource,
            .markdown, .yaml, .propertyList,
            .image, .jpeg, .png, .gif, .svg,
            .audio, .video, .movie, .mpeg4Movie,
            .zip, .gzip, .bz2, .tar
        ])
        
        Task {
            await loadValidationCache()
        }
    }
    
    deinit {
        // Cancel all validation tasks
        validationTasks.forEach { $0.cancel() }
    }
    
    // MARK: - Public Interface
    
    /// Comprehensive file validation with security and integrity checks
    public func validateFile(at url: URL) async throws -> FileValidationResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        guard !isValidating else {
            throw ArcanaError.fileProcessingError("Validation already in progress")
        }
        
        isValidating = true
        validationProgress = 0.0
        defer {
            isValidating = false
            validationProgress = 0.0
        }
        
        do {
            // Check cache first
            let fileHash = try await calculateFileHash(url)
            if let cachedResult = validationCache[fileHash] {
                lastValidationResult = cachedResult
                return cachedResult
            }
            
            // Step 1: Basic file system validation (10%)
            validationProgress = 0.1
            try await validateFileSystem(url)
            
            // Step 2: File type and size validation (20%)
            validationProgress = 0.2
            let fileType = try await validateFileType(url)
            try await validateFileSize(url)
            
            // Step 3: Content structure validation (40%)
            validationProgress = 0.4
            let structureResult = try await validateContentStructure(url, fileType: fileType)
            
            // Step 4: Security scanning (60%)
            validationProgress = 0.6
            let securityResult = try await performSecurityScan(url)
            
            // Step 5: Integrity verification (80%)
            validationProgress = 0.8
            let integrityResult = try await verifyFileIntegrity(url)
            
            // Step 6: Content analysis (100%)
            validationProgress = 1.0
            let contentAnalysis = try await analyzeContentSafety(url, fileType: fileType)
            
            // Compile final validation result
            let validationResult = FileValidationResult(
                fileURL: url,
                fileHash: fileHash,
                fileType: fileType,
                fileSize: try getFileSize(url),
                isValid: structureResult.isValid && securityResult.isSecure && integrityResult.isIntact,
                securityScore: securityResult.securityScore,
                integrityScore: integrityResult.integrityScore,
                contentSafetyScore: contentAnalysis.safetyScore,
                validationTimestamp: Date(),
                processingTime: CFAbsoluteTimeGetCurrent() - startTime,
                warnings: collectWarnings(structureResult, securityResult, integrityResult, contentAnalysis),
                errors: collectErrors(structureResult, securityResult, integrityResult, contentAnalysis),
                metadata: extractFileMetadata(url),
                recommendations: generateRecommendations(structureResult, securityResult, integrityResult, contentAnalysis)
            )
            
            // Cache the result
            validationCache[fileHash] = validationResult
            
            // Update statistics
            await updateValidationStatistics(validationResult)
            
            // Record performance metrics
            await recordValidationMetrics(validationResult)
            
            lastValidationResult = validationResult
            return validationResult
            
        } catch {
            let errorResult = FileValidationResult.errorResult(
                fileURL: url,
                error: error,
                processingTime: CFAbsoluteTimeGetCurrent() - startTime
            )
            
            lastValidationResult = errorResult
            throw error
        }
    }
    
    /// Batch validation of multiple files
    public func validateFiles(at urls: [URL]) async throws -> [FileValidationResult] {
        var results: [FileValidationResult] = []
        
        for (index, url) in urls.enumerated() {
            do {
                validationProgress = Double(index) / Double(urls.count)
                let result = try await validateFile(at: url)
                results.append(result)
            } catch {
                let errorResult = FileValidationResult.errorResult(
                    fileURL: url,
                    error: error,
                    processingTime: 0
                )
                results.append(errorResult)
            }
        }
        
        return results
    }
    
    /// Quick validation for trusted sources (faster, less comprehensive)
    public func quickValidate(fileAt url: URL) async throws -> Bool {
        // Basic checks only
        try await validateFileSystem(url)
        _ = try await validateFileType(url)
        try await validateFileSize(url)
        
        return true
    }
    
    /// Get validation recommendations for file processing
    public func getValidationRecommendations(for result: FileValidationResult) -> [ValidationRecommendation] {
        var recommendations: [ValidationRecommendation] = []
        
        if result.securityScore < 0.8 {
            recommendations.append(ValidationRecommendation(
                type: .security,
                priority: .high,
                title: "Security Concerns Detected",
                description: "File contains potentially unsafe content patterns",
                action: "Review file content manually before processing"
            ))
        }
        
        if result.integrityScore < 0.9 {
            recommendations.append(ValidationRecommendation(
                type: .integrity,
                priority: .medium,
                title: "File Integrity Questions",
                description: "File may be corrupted or modified",
                action: "Re-download or verify file source"
            ))
        }
        
        if result.fileSize > 50 * 1024 * 1024 { // 50MB
            recommendations.append(ValidationRecommendation(
                type: .performance,
                priority: .low,
                title: "Large File Detected",
                description: "File is quite large and may slow processing",
                action: "Consider splitting into smaller chunks"
            ))
        }
        
        return recommendations
    }
    
    /// Clear validation cache
    public func clearValidationCache() async {
        validationCache.removeAll()
        validationStatistics = ValidationStatistics()
    }
    
    /// Export validation report
    public func exportValidationReport() async throws -> Data {
        let report = ValidationReport(
            exportDate: Date(),
            totalValidations: validationStatistics.totalValidations,
            successfulValidations: validationStatistics.successfulValidations,
            failedValidations: validationStatistics.failedValidations,
            averageProcessingTime: validationStatistics.averageProcessingTime,
            commonFileTypes: validationStatistics.fileTypeDistribution,
            securityIssuesFound: validationStatistics.securityIssuesDetected,
            recommendationsGenerated: validationStatistics.recommendationsGenerated
        )
        
        return try JSONEncoder().encode(report)
    }
    
    // MARK: - Private Validation Methods
    
    private func validateFileSystem(_ url: URL) async throws {
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ArcanaError.fileProcessingError("File does not exist at path: \(url.path)")
        }
        
        // Check if file is readable
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw ArcanaError.fileProcessingError("File is not readable: \(url.path)")
        }
        
        // Check if it's actually a file (not a directory)
        var isDirectory: ObjCBool = false
        FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
        guard !isDirectory.boolValue else {
            throw ArcanaError.fileProcessingError("Path points to a directory, not a file: \(url.path)")
        }
        
        // Check file permissions
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        if let permissions = attributes[.posixPermissions] as? NSNumber {
            let perms = permissions.uint16Value
            if (perms & 0o044) == 0 { // Check read permissions
                throw ArcanaError.fileProcessingError("Insufficient permissions to read file")
            }
        }
    }
    
    private func validateFileType(_ url: URL) async throws -> UTType {
        let resourceValues = try url.resourceValues(forKeys: [.contentTypeKey])
        
        guard let contentType = resourceValues.contentType else {
            throw ArcanaError.fileProcessingError("Unable to determine file type")
        }
        
        // Check if file type is allowed
        let isAllowed = allowedFileTypes.contains { allowedType in
            contentType.conforms(to: allowedType)
        }
        
        guard isAllowed else {
            throw ArcanaError.fileProcessingError("File type not allowed: \(contentType.identifier)")
        }
        
        return contentType
    }
    
    private func validateFileSize(_ url: URL) async throws {
        let fileSize = try getFileSize(url)
        
        guard fileSize <= maxFileSize else {
            throw ArcanaError.fileProcessingError("File size exceeds maximum allowed: \(fileSize) bytes > \(maxFileSize) bytes")
        }
        
        guard fileSize > 0 else {
            throw ArcanaError.fileProcessingError("File is empty")
        }
    }
    
    private func getFileSize(_ url: URL) throws -> Int64 {
        let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
        return (attributes[.size] as? NSNumber)?.int64Value ?? 0
    }
    
    private func calculateFileHash(_ url: URL) async throws -> String {
        let data = try Data(contentsOf: url)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func validateContentStructure(_ url: URL, fileType: UTType) async throws -> StructureValidationResult {
        do {
            let fileContent = try String(contentsOf: url, encoding: .utf8)
            
            // Validate based on file type
            if fileType.conforms(to: .json) {
                return try await validateJSONStructure(fileContent)
            } else if fileType.conforms(to: .xml) {
                return try await validateXMLStructure(fileContent)
            } else if fileType.conforms(to: .commaSeparatedText) {
                return try await validateCSVStructure(fileContent)
            } else if fileType.conforms(to: .sourceCode) {
                return try await validateSourceCodeStructure(fileContent, fileType: fileType)
            } else {
                return try await validateGenericTextStructure(fileContent)
            }
            
        } catch {
            // Try binary validation if text fails
            return try await validateBinaryStructure(url, fileType: fileType)
        }
    }
    
    private func validateJSONStructure(_ content: String) async throws -> StructureValidationResult {
        do {
            _ = try JSONSerialization.jsonObject(with: content.data(using: .utf8) ?? Data())
            return StructureValidationResult(isValid: true, confidence: 1.0, issues: [], warnings: [])
        } catch {
            return StructureValidationResult(
                isValid: false,
                confidence: 0.0,
                issues: ["Invalid JSON structure: \(error.localizedDescription)"],
                warnings: []
            )
        }
    }
    
    private func validateXMLStructure(_ content: String) async throws -> StructureValidationResult {
        // Basic XML validation
        let hasXMLDeclaration = content.contains("<?xml")
        let hasRootElement = content.contains("<") && content.contains(">")
        let balancedTags = validateXMLTagBalance(content)
        
        var issues: [String] = []
        var warnings: [String] = []
        
        if !hasXMLDeclaration {
            warnings.append("Missing XML declaration")
        }
        
        if !hasRootElement {
            issues.append("No XML elements found")
        }
        
        if !balancedTags {
            issues.append("Unbalanced XML tags detected")
        }
        
        let isValid = hasRootElement && balancedTags
        let confidence = isValid ? (hasXMLDeclaration ? 1.0 : 0.8) : 0.0
        
        return StructureValidationResult(isValid: isValid, confidence: confidence, issues: issues, warnings: warnings)
    }
    
    private func validateXMLTagBalance(_ content: String) -> Bool {
        var tagStack: [String] = []
        let tagPattern = #"<(/?)(\w+)[^>]*>"#
        
        guard let regex = try? NSRegularExpression(pattern: tagPattern) else { return false }
        
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: content.count))
        
        for match in matches {
            if let closingSlashRange = Range(match.range(at: 1), in: content),
               let tagNameRange = Range(match.range(at: 2), in: content) {
                
                let isClosingTag = !content[closingSlashRange].isEmpty
                let tagName = String(content[tagNameRange])
                
                if isClosingTag {
                    if tagStack.last == tagName {
                        tagStack.removeLast()
                    } else {
                        return false // Mismatched closing tag
                    }
                } else {
                    // Check for self-closing tags
                    if let fullMatchRange = Range(match.range, in: content) {
                        let fullMatch = String(content[fullMatchRange])
                        if !fullMatch.hasSuffix("/>") {
                            tagStack.append(tagName)
                        }
                    }
                }
            }
        }
        
        return tagStack.isEmpty
    }
    
    private func validateCSVStructure(_ content: String) async throws -> StructureValidationResult {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard !lines.isEmpty else {
            return StructureValidationResult(
                isValid: false,
                confidence: 0.0,
                issues: ["CSV file is empty"],
                warnings: []
            )
        }
        
        // Check for consistent column count
        let firstLineColumns = lines.first?.components(separatedBy: ",").count ?? 0
        var inconsistentLines = 0
        
        for (index, line) in lines.enumerated() {
            let columnCount = line.components(separatedBy: ",").count
            if columnCount != firstLineColumns {
                inconsistentLines += 1
            }
        }
        
        let consistency = Double(lines.count - inconsistentLines) / Double(lines.count)
        var warnings: [String] = []
        
        if consistency < 0.9 {
            warnings.append("Inconsistent column count across rows")
        }
        
        return StructureValidationResult(
            isValid: true,
            confidence: consistency,
            issues: [],
            warnings: warnings
        )
    }
    
    private func validateSourceCodeStructure(_ content: String, fileType: UTType) async throws -> StructureValidationResult {
        var issues: [String] = []
        var warnings: [String] = []
        
        // Basic syntax checks
        if fileType.conforms(to: .swiftSource) {
            // Check for basic Swift syntax
            if !content.contains("import") && !content.contains("func") && !content.contains("class") && !content.contains("struct") {
                warnings.append("No typical Swift constructs found")
            }
        }
        
        // Check for extremely long lines
        let lines = content.components(separatedBy: .newlines)
        let longLines = lines.filter { $0.count > 500 }
        if !longLines.isEmpty {
            warnings.append("Found \(longLines.count) extremely long lines")
        }
        
        // Check for reasonable file structure
        let hasContent = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        return StructureValidationResult(
            isValid: hasContent,
            confidence: hasContent ? 0.8 : 0.0,
            issues: issues,
            warnings: warnings
        )
    }
    
    private func validateGenericTextStructure(_ content: String) async throws -> StructureValidationResult {
        let hasContent = !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let isReasonableLength = content.count < 10_000_000 // 10MB text limit
        
        var warnings: [String] = []
        if content.count > 1_000_000 { // 1MB
            warnings.append("Very large text file detected")
        }
        
        return StructureValidationResult(
            isValid: hasContent && isReasonableLength,
            confidence: hasContent ? 0.7 : 0.0,
            issues: isReasonableLength ? [] : ["File content too large"],
            warnings: warnings
        )
    }
    
    private func validateBinaryStructure(_ url: URL, fileType: UTType) async throws -> StructureValidationResult {
        let data = try Data(contentsOf: url)
        
        // Basic binary file validation
        var isValid = true
        var confidence = 0.5
        var issues: [String] = []
        var warnings: [String] = []
        
        if fileType.conforms(to: .pdf) {
            isValid = data.starts(with: [0x25, 0x50, 0x44, 0x46]) // PDF header
            if !isValid {
                issues.append("Invalid PDF header")
            } else {
                confidence = 0.9
            }
        } else if fileType.conforms(to: .jpeg) {
            isValid = data.starts(with: [0xFF, 0xD8, 0xFF]) // JPEG header
            if !isValid {
                issues.append("Invalid JPEG header")
            } else {
                confidence = 0.9
            }
        } else if fileType.conforms(to: .png) {
            isValid = data.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG header
            if !isValid {
                issues.append("Invalid PNG header")
            } else {
                confidence = 0.9
            }
        }
        
        return StructureValidationResult(
            isValid: isValid,
            confidence: confidence,
            issues: issues,
            warnings: warnings
        )
    }
    
    private func performSecurityScan(_ url: URL) async throws -> SecurityScanResult {
        let content: String
        
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            // For binary files, read as data and convert what we can
            let data = try Data(contentsOf: url)
            content = String(data: data, encoding: .utf8) ?? ""
        }
        
        var securityIssues: [SecurityIssue] = []
        var securityScore = 1.0
        
        // Scan for malware signatures
        for signature in malwareSignatures {
            if content.contains(signature) {
                securityIssues.append(SecurityIssue(
                    type: .malware,
                    severity: .critical,
                    description: "Malware signature detected",
                    pattern: signature
                ))
                securityScore -= 0.5
            }
        }
        
        // Scan for suspicious patterns
        for pattern in suspiciousPatterns {
            if content.lowercased().contains(pattern) {
                securityIssues.append(SecurityIssue(
                    type: .suspicious,
                    severity: .medium,
                    description: "Potentially unsafe pattern detected",
                    pattern: pattern
                ))
                securityScore -= 0.1
            }
        }
        
        // Check for script injections
        let scriptPatterns = ["<script", "javascript:", "onload=", "onerror=", "onclick="]
        for pattern in scriptPatterns {
            if content.lowercased().contains(pattern) {
                securityIssues.append(SecurityIssue(
                    type: .scriptInjection,
                    severity: .high,
                    description: "Potential script injection detected",
                    pattern: pattern
                ))
                securityScore -= 0.2
            }
        }
        
        securityScore = max(0.0, securityScore)
        
        return SecurityScanResult(
            isSecure: securityScore >= 0.7,
            securityScore: securityScore,
            issues: securityIssues,
            scanDate: Date()
        )
    }
    
    private func verifyFileIntegrity(_ url: URL) async throws -> IntegrityVerificationResult {
        let data = try Data(contentsOf: url)
        
        // Calculate various checksums
        let sha256Hash = SHA256.hash(data: data)
        let md5Hash = Insecure.MD5.hash(data: data)
        
        // Check for file corruption indicators
        var integrityScore = 1.0
        var issues: [String] = []
        
        // Check for truncated files (basic heuristic)
        if data.count < 100 && url.pathExtension != "txt" {
            issues.append("File appears to be truncated or unusually small")
            integrityScore -= 0.3
        }
        
        // Check for null bytes in text files
        if url.pathExtension == "txt" || url.pathExtension == "md" {
            if data.contains(0x00) {
                issues.append("Null bytes found in text file")
                integrityScore -= 0.2
            }
        }
        
        return IntegrityVerificationResult(
            isIntact: integrityScore >= 0.8,
            integrityScore: integrityScore,
            sha256Hash: sha256Hash.compactMap { String(format: "%02x", $0) }.joined(),
            md5Hash: md5Hash.compactMap { String(format: "%02x", $0) }.joined(),
            issues: issues,
            verificationDate: Date()
        )
    }
    
    private func analyzeContentSafety(_ url: URL, fileType: UTType) async throws -> ContentSafetyAnalysis {
        let content: String
        
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            // For binary files, return safe by default
            return ContentSafetyAnalysis(
                safetyScore: 0.8,
                concerns: [],
                recommendations: [],
                analysisDate: Date()
            )
        }
        
        var safetyScore = 1.0
        var concerns: [SafetyConcern] = []
        var recommendations: [String] = []
        
        // Check for sensitive information patterns
        let sensitivePatterns = [
            ("password", "Potential password found"),
            ("api_key", "Potential API key found"),
            ("secret", "Potential secret found"),
            ("token", "Potential token found"),
            ("private_key", "Potential private key found")
        ]
        
        for (pattern, description) in sensitivePatterns {
            if content.lowercased().contains(pattern) {
                concerns.append(SafetyConcern(
                    type: .sensitiveData,
                    severity: .medium,
                    description: description,
                    location: "File content"
                ))
                safetyScore -= 0.1
                recommendations.append("Review and remove sensitive information")
            }
        }
        
        // Check for excessive executable content
        let executablePatterns = ["eval(", "exec(", "system(", "shell_exec("]
        var executableCount = 0
        
        for pattern in executablePatterns {
            executableCount += content.components(separatedBy: pattern).count - 1
        }
        
        if executableCount > 5 {
            concerns.append(SafetyConcern(
                type: .executableContent,
                severity: .high,
                description: "High concentration of executable code patterns",
                location: "Multiple locations"
            ))
            safetyScore -= 0.3
            recommendations.append("Carefully review executable code sections")
        }
        
        safetyScore = max(0.0, safetyScore)
        
        return ContentSafetyAnalysis(
            safetyScore: safetyScore,
            concerns: concerns,
            recommendations: recommendations,
            analysisDate: Date()
        )
    }
    
    private func collectWarnings(_ structureResult: StructureValidationResult,
                                _ securityResult: SecurityScanResult,
                                _ integrityResult: IntegrityVerificationResult,
                                _ contentAnalysis: ContentSafetyAnalysis) -> [String] {
        var warnings: [String] = []
        
        warnings.append(contentsOf: structureResult.warnings)
        warnings.append(contentsOf: securityResult.issues.filter { $0.severity != .critical }.map { $0.description })
        warnings.append(contentsOf: integrityResult.issues)
        warnings.append(contentsOf: contentAnalysis.concerns.filter { $0.severity != .high }.map { $0.description })
        
        return warnings
    }
    
    private func collectErrors(_ structureResult: StructureValidationResult,
                              _ securityResult: SecurityScanResult,
                              _ integrityResult: IntegrityVerificationResult,
                              _ contentAnalysis: ContentSafetyAnalysis) -> [String] {
        var errors: [String] = []
        
        errors.append(contentsOf: structureResult.issues)
        errors.append(contentsOf: securityResult.issues.filter { $0.severity == .critical }.map { $0.description })
        errors.append(contentsOf: contentAnalysis.concerns.filter { $0.severity == .high }.map { $0.description })
        
        return errors
    }
    
    private func extractFileMetadata(_ url: URL) -> [String: String] {
        var metadata: [String: String] = [:]
        
        do {
            let resourceValues = try url.resourceValues(forKeys: [
                .nameKey, .fileSizeKey, .contentModificationDateKey,
                .contentTypeKey, .creationDateKey
            ])
            
            metadata["filename"] = resourceValues.name
            metadata["fileSize"] = resourceValues.fileSize?.description
            metadata["contentType"] = resourceValues.contentType?.identifier
            metadata["creationDate"] = resourceValues.creationDate?.description
            metadata["modificationDate"] = resourceValues.contentModificationDate?.description
            
        } catch {
            metadata["error"] = "Failed to extract metadata: \(error.localizedDescription)"
        }
        
        return metadata
    }
    
    private func generateRecommendations(_ structureResult: StructureValidationResult,
                                       _ securityResult: SecurityScanResult,
                                       _ integrityResult: IntegrityVerificationResult,
                                       _ contentAnalysis: ContentSafetyAnalysis) -> [String] {
        var recommendations: [String] = []
        
        if !structureResult.isValid {
            recommendations.append("Fix file structure issues before processing")
        }
        
        if !securityResult.isSecure {
            recommendations.append("Address security concerns before using this file")
        }
        
        if !integrityResult.isIntact {
            recommendations.append("Verify file integrity - consider re-downloading")
        }
        
        recommendations.append(contentsOf: contentAnalysis.recommendations)
        
        if recommendations.isEmpty {
            recommendations.append("File appears safe for processing")
        }
        
        return recommendations
    }
    
    private func updateValidationStatistics(_ result: FileValidationResult) async {
        validationStatistics.totalValidations += 1
        
        if result.isValid {
            validationStatistics.successfulValidations += 1
        } else {
            validationStatistics.failedValidations += 1
        }
        
        // Update average processing time
        let totalTime = validationStatistics.averageProcessingTime * Double(validationStatistics.totalValidations - 1)
        validationStatistics.averageProcessingTime = (totalTime + result.processingTime) / Double(validationStatistics.totalValidations)
        
        // Update file type distribution
        let fileTypeKey = result.fileType.identifier
        validationStatistics.fileTypeDistribution[fileTypeKey, default: 0] += 1
        
        // Update security issues count
        if result.securityScore < 0.8 {
            validationStatistics.securityIssuesDetected += 1
        }
        
        // Update recommendations count
        validationStatistics.recommendationsGenerated += result.recommendations.count
    }
    
    private func recordValidationMetrics(_ result: FileValidationResult) async {
        await performanceMonitor.recordMetric(
            .fileValidation,
            value: result.processingTime,
            context: [
                "file_type": result.fileType.identifier,
                "file_size": String(result.fileSize),
                "is_valid": String(result.isValid),
                "security_score": String(result.securityScore)
            ]
        )
    }
    
    private func loadValidationCache() async {
        // Implementation for loading cached validation results
        // This would persist validation results for frequently accessed files
    }
}

// MARK: - Supporting Types

/// Comprehensive file validation result
public struct FileValidationResult: Codable, Hashable {
    public let fileURL: URL
    public let fileHash: String
    public let fileType: UTType
    public let fileSize: Int64
    public let isValid: Bool
    public let securityScore: Double
    public let integrityScore: Double
    public let contentSafetyScore: Double
    public let validationTimestamp: Date
    public let processingTime: TimeInterval
    public let warnings: [String]
    public let errors: [String]
    public let metadata: [String: String]
    public let recommendations: [String]
    
    static func errorResult(fileURL: URL, error: Error, processingTime: TimeInterval) -> FileValidationResult {
        return FileValidationResult(
            fileURL: fileURL,
            fileHash: "",
            fileType: UTType.data,
            fileSize: 0,
            isValid: false,
            securityScore: 0.0,
            integrityScore: 0.0,
            contentSafetyScore: 0.0,
            validationTimestamp: Date(),
            processingTime: processingTime,
            warnings: [],
            errors: [error.localizedDescription],
            metadata: [:],
            recommendations: ["Fix the underlying issue and try again"]
        )
    }
}

/// Structure validation result
public struct StructureValidationResult: Codable, Hashable {
    public let isValid: Bool
    public let confidence: Double
    public let issues: [String]
    public let warnings: [String]
}

/// Security scan result
public struct SecurityScanResult: Codable, Hashable {
    public let isSecure: Bool
    public let securityScore: Double
    public let issues: [SecurityIssue]
    public let scanDate: Date
}

/// Security issue detected during scanning
public struct SecurityIssue: Codable, Hashable {
    public let type: SecurityIssueType
    public let severity: SecuritySeverity
    public let description: String
    public let pattern: String
}

/// Types of security issues
public enum SecurityIssueType: String, Codable, CaseIterable, Hashable {
    case malware
    case suspicious
    case scriptInjection
    case sensitiveData
    case executableContent
}

/// Security issue severity levels
public enum SecuritySeverity: String, Codable, CaseIterable, Hashable {
    case low
    case medium
    case high
    case critical
}

/// File integrity verification result
public struct IntegrityVerificationResult: Codable, Hashable {
    public let isIntact: Bool
    public let integrityScore: Double
    public let sha256Hash: String
    public let md5Hash: String
    public let issues: [String]
    public let verificationDate: Date
}

/// Content safety analysis result
public struct ContentSafetyAnalysis: Codable, Hashable {
    public let safetyScore: Double
    public let concerns: [SafetyConcern]
    public let recommendations: [String]
    public let analysisDate: Date
}

/// Safety concern found in content
public struct SafetyConcern: Codable, Hashable {
    public let type: SafetyConcernType
    public let severity: SecuritySeverity
    public let description: String
    public let location: String
}

/// Types of safety concerns
public enum SafetyConcernType: String, Codable, CaseIterable, Hashable {
    case sensitiveData
    case executableContent
    case maliciousCode
    case inappropriateContent
}

/// Validation recommendation
public struct ValidationRecommendation: Codable, Hashable {
    public let type: RecommendationType
    public let priority: RecommendationPriority
    public let title: String
    public let description: String
    public let action: String
}

/// Types of validation recommendations
public enum RecommendationType: String, Codable, CaseIterable, Hashable {
    case security
    case integrity
    case performance
    case structure
}

/// Recommendation priority levels
public enum RecommendationPriority: String, Codable, CaseIterable, Hashable {
    case low
    case medium
    case high
    case critical
}

/// Validation statistics
public struct ValidationStatistics: Codable, Hashable {
    public var totalValidations: Int = 0
    public var successfulValidations: Int = 0
    public var failedValidations: Int = 0
    public var averageProcessingTime: TimeInterval = 0.0
    public var fileTypeDistribution: [String: Int] = [:]
    public var securityIssuesDetected: Int = 0
    public var recommendationsGenerated: Int = 0
}

/// Validation report for export
public struct ValidationReport: Codable, Hashable {
    public let exportDate: Date
    public let totalValidations: Int
    public let successfulValidations: Int
    public let failedValidations: Int
    public let averageProcessingTime: TimeInterval
    public let commonFileTypes: [String: Int]
    public let securityIssuesFound: Int
    public let recommendationsGenerated: Int
}
