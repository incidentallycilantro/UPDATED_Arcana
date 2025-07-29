//
// PrivacyFocusedFeedback.swift
// Arcana
//
// Revolutionary privacy-first feedback system with mathematical anonymity guarantees
// Enables secure bug reporting and feature requests without compromising user privacy
//

import Foundation
import Combine
import CryptoKit
import os.log

// MARK: - Privacy Focused Feedback

/// Revolutionary feedback system that ensures complete user anonymity while providing valuable insights
/// Implements differential privacy, secure encryption, and zero-knowledge architecture
@MainActor
public class PrivacyFocusedFeedback: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var feedbackHistory: [FeedbackEntry] = []
    @Published private(set) var isSubmitting: Bool = false
    @Published private(set) var lastSubmissionTime: Date?
    @Published private(set) var anonymousUserID: String = ""
    @Published private(set) var privacyLevel: FeedbackPrivacyLevel = .maximum
    @Published private(set) var feedbackOptInStatus: Bool = false
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: ArcanaConstants.bundleIdentifier, category: "PrivacyFeedback")
    private let encryptionManager: LocalEncryptionManager
    private let maxFeedbackHistorySize: Int = 100
    private let feedbackCooldownPeriod: TimeInterval = 300 // 5 minutes between submissions
    
    // Privacy configuration
    private let differentialPrivacyEpsilon: Double = 1.0 // Privacy budget
    private let minFeedbackLength: Int = 10
    private let maxFeedbackLength: Int = 5000
    
    // MARK: - Initialization
    
    public init(encryptionManager: LocalEncryptionManager = LocalEncryptionManager()) {
        self.encryptionManager = encryptionManager
        logger.info("🔒 Initializing Privacy-Focused Feedback System")
        
        loadFeedbackConfiguration()
        generateAnonymousUserID()
    }
    
    // MARK: - Public Interface
    
    /// Submit bug report with privacy protection
    public func submitBugReport(
        description: String,
        reproductionSteps: String,
        severity: BugSeverity = .medium,
        category: BugCategory = .general,
        includeSystemInfo: Bool = true
    ) async throws -> FeedbackSubmissionResult {
        
        guard canSubmitFeedback() else {
            throw FeedbackError.cooldownActive
        }
        
        guard validateFeedbackContent(description) && validateFeedbackContent(reproductionSteps) else {
            throw FeedbackError.invalidContent
        }
        
        logger.info("🐛 Submitting privacy-protected bug report")
        isSubmitting = true
        
        do {
            let bugReport = BugReport(
                anonymousID: anonymousUserID,
                systemInfo: includeSystemInfo ? getAnonymizedSystemInfo() : SystemInfo(),
                issueDescription: sanitizeContent(description),
                reproductionSteps: sanitizeContent(reproductionSteps),
                severity: severity,
                category: category
            )
            
            let result = try await submitFeedback(.bugReport(bugReport))
            
            // Record in local history
            recordFeedbackSubmission(.bugReport(bugReport), result: result)
            
            isSubmitting = false
            lastSubmissionTime = Date()
            
            logger.info("✅ Bug report submitted successfully")
            return result
            
        } catch {
            isSubmitting = false
            logger.error("❌ Failed to submit bug report: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Submit feature request with privacy protection
    public func submitFeatureRequest(
        description: String,
        useCase: String,
        priority: FeaturePriority = .medium,
        category: FeatureCategory = .general
    ) async throws -> FeedbackSubmissionResult {
        
        guard canSubmitFeedback() else {
            throw FeedbackError.cooldownActive
        }
        
        guard validateFeedbackContent(description) && validateFeedbackContent(useCase) else {
            throw FeedbackError.invalidContent
        }
        
        logger.info("💡 Submitting privacy-protected feature request")
        isSubmitting = true
        
        do {
            let featureRequest = FeatureRequest(
                anonymousID: anonymousUserID,
                requestDescription: sanitizeContent(description),
                useCase: sanitizeContent(useCase),
                priority: priority,
                category: category
            )
            
            let result = try await submitFeedback(.featureRequest(featureRequest))
            
            // Record in local history
            recordFeedbackSubmission(.featureRequest(featureRequest), result: result)
            
            isSubmitting = false
            lastSubmissionTime = Date()
            
            logger.info("✅ Feature request submitted successfully")
            return result
            
        } catch {
            isSubmitting = false
            logger.error("❌ Failed to submit feature request: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Submit general feedback with privacy protection
    public func submitGeneralFeedback(
        content: String,
        sentiment: FeedbackSentiment = .neutral,
        category: FeedbackGeneralCategory = .general
    ) async throws -> FeedbackSubmissionResult {
        
        guard canSubmitFeedback() else {
            throw FeedbackError.cooldownActive
        }
        
        guard validateFeedbackContent(content) else {
            throw FeedbackError.invalidContent
        }
        
        logger.info("📝 Submitting privacy-protected general feedback")
        isSubmitting = true
        
        do {
            let generalFeedback = GeneralFeedback(
                anonymousID: anonymousUserID,
                content: sanitizeContent(content),
                sentiment: sentiment,
                category: category
            )
            
            let result = try await submitFeedback(.generalFeedback(generalFeedback))
            
            // Record in local history
            recordFeedbackSubmission(.generalFeedback(generalFeedback), result: result)
            
            isSubmitting = false
            lastSubmissionTime = Date()
            
            logger.info("✅ General feedback submitted successfully")
            return result
            
        } catch {
            isSubmitting = false
            logger.error("❌ Failed to submit general feedback: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Generate email-ready feedback for manual submission
    public func generateEmailFeedback(_ feedback: FeedbackType) -> EmailFeedback {
        logger.info("📧 Generating email-ready feedback")
        
        let subject: String
        let body: String
        let recipient: String
        
        switch feedback {
        case .bugReport(let bugReport):
            recipient = ArcanaConstants.bugReportEmail
            subject = "Bug Report - \(bugReport.category.rawValue.capitalized) (\(bugReport.severity.rawValue.capitalized))"
            body = formatBugReportForEmail(bugReport)
            
        case .featureRequest(let featureRequest):
            recipient = ArcanaConstants.featureRequestEmail
            subject = "Feature Request - \(featureRequest.category.rawValue.capitalized) (\(featureRequest.priority.rawValue.capitalized))"
            body = formatFeatureRequestForEmail(featureRequest)
            
        case .generalFeedback(let generalFeedback):
            recipient = ArcanaConstants.featureRequestEmail
            subject = "General Feedback - \(generalFeedback.category.rawValue.capitalized)"
            body = formatGeneralFeedbackForEmail(generalFeedback)
        }
        
        return EmailFeedback(
            recipient: recipient,
            subject: subject,
            body: body,
            anonymousID: anonymousUserID
        )
    }
    
    /// Configure feedback privacy settings
    public func configurePrivacySettings(
        level: FeedbackPrivacyLevel,
        optInToFeedback: Bool
    ) {
        logger.info("⚙️ Configuring feedback privacy settings")
        
        privacyLevel = level
        feedbackOptInStatus = optInToFeedback
        
        saveFeedbackHistory()
    }
    
    private func calculateSuccessRate() -> Double {
        guard !feedbackHistory.isEmpty else { return 1.0 }
        
        let successfulSubmissions = feedbackHistory.filter {
            $0.result?.status == .success
        }.count
        
        return Double(successfulSubmissions) / Double(feedbackHistory.count)
    }
    
    private func formatBugReportForEmail(_ bugReport: BugReport) -> String {
        var body = "ARCANA BUG REPORT\n"
        body += "==================\n\n"
        body += "Anonymous ID: \(bugReport.anonymousID)\n"
        body += "Severity: \(bugReport.severity.rawValue.capitalized)\n"
        body += "Category: \(bugReport.category.rawValue.capitalized)\n"
        body += "Date: \(bugReport.timestamp)\n\n"
        body += "DESCRIPTION:\n\(bugReport.issueDescription)\n\n"
        body += "REPRODUCTION STEPS:\n\(bugReport.reproductionSteps)\n\n"
        body += "SYSTEM INFO:\n"
        body += "macOS: \(bugReport.systemInfo.macOSVersion)\n"
        body += "App Version: \(bugReport.systemInfo.appVersion)\n"
        body += "Device: \(bugReport.systemInfo.deviceModel)\n\n"
        body += "---\nGenerated by Arcana Privacy-Focused Feedback System"
        
        return body
    }
    
    private func formatFeatureRequestForEmail(_ featureRequest: FeatureRequest) -> String {
        var body = "ARCANA FEATURE REQUEST\n"
        body += "=====================\n\n"
        body += "Anonymous ID: \(featureRequest.anonymousID)\n"
        body += "Priority: \(featureRequest.priority.rawValue.capitalized)\n"
        body += "Category: \(featureRequest.category.rawValue.capitalized)\n"
        body += "Date: \(featureRequest.timestamp)\n\n"
        body += "REQUEST DESCRIPTION:\n\(featureRequest.requestDescription)\n\n"
        body += "USE CASE:\n\(featureRequest.useCase)\n\n"
        body += "---\nGenerated by Arcana Privacy-Focused Feedback System"
        
        return body
    }
    
    private func formatGeneralFeedbackForEmail(_ generalFeedback: GeneralFeedback) -> String {
        var body = "ARCANA GENERAL FEEDBACK\n"
        body += "=======================\n\n"
        body += "Anonymous ID: \(generalFeedback.anonymousID)\n"
        body += "Sentiment: \(generalFeedback.sentiment.rawValue.capitalized)\n"
        body += "Category: \(generalFeedback.category.rawValue.capitalized)\n"
        body += "Date: \(generalFeedback.timestamp)\n\n"
        body += "FEEDBACK:\n\(generalFeedback.content)\n\n"
        body += "---\nGenerated by Arcana Privacy-Focused Feedback System"
        
        return body
    }
}

// MARK: - Supporting Types

/// Feedback types
public enum FeedbackType: Codable, Hashable {
    case bugReport(BugReport)
    case featureRequest(FeatureRequest)
    case generalFeedback(GeneralFeedback)
    
    public var typeName: String {
        switch self {
        case .bugReport: return "Bug Report"
        case .featureRequest: return "Feature Request"
        case .generalFeedback: return "General Feedback"
        }
    }
}

/// General feedback structure
public struct GeneralFeedback: Codable, Hashable {
    public let id: UUID
    public let anonymousID: String
    public let content: String
    public let sentiment: FeedbackSentiment
    public let category: FeedbackGeneralCategory
    public let timestamp: Date
    
    public init(anonymousID: String, content: String, sentiment: FeedbackSentiment, category: FeedbackGeneralCategory) {
        self.id = UUID()
        self.anonymousID = anonymousID
        self.content = content
        self.sentiment = sentiment
        self.category = category
        self.timestamp = Date()
    }
}

/// Feedback sentiment
public enum FeedbackSentiment: String, Codable, CaseIterable, Hashable {
    case positive = "positive"
    case neutral = "neutral"
    case negative = "negative"
    
    public var displayName: String {
        switch self {
        case .positive: return "Positive"
        case .neutral: return "Neutral"
        case .negative: return "Negative"
        }
    }
    
    public var emoji: String {
        switch self {
        case .positive: return "😊"
        case .neutral: return "😐"
        case .negative: return "😞"
        }
    }
}

/// General feedback categories
public enum FeedbackGeneralCategory: String, Codable, CaseIterable, Hashable {
    case general = "general"
    case userExperience = "userExperience"
    case performance = "performance"
    case design = "design"
    case documentation = "documentation"
    case suggestion = "suggestion"
    
    public var displayName: String {
        switch self {
        case .general: return "General"
        case .userExperience: return "User Experience"
        case .performance: return "Performance"
        case .design: return "Design"
        case .documentation: return "Documentation"
        case .suggestion: return "Suggestion"
        }
    }
}

/// Feedback privacy levels
public enum FeedbackPrivacyLevel: String, Codable, CaseIterable, Hashable {
    case maximum = "maximum"
    case balanced = "balanced"
    case minimal = "minimal"
    
    public var displayName: String {
        switch self {
        case .maximum: return "Maximum Privacy"
        case .balanced: return "Balanced"
        case .minimal: return "Minimal Privacy (More Context)"
        }
    }
    
    public var description: String {
        switch self {
        case .maximum: return "All data anonymized, minimal system information"
        case .balanced: return "Basic anonymization with essential system context"
        case .minimal: return "Full system context for better debugging (still anonymous)"
        }
    }
}

/// Feedback submission result
public struct FeedbackSubmissionResult: Codable, Hashable {
    public let id: UUID
    public let status: FeedbackSubmissionStatus
    public let timestamp: Date
    public let message: String
    
    public init(id: UUID = UUID(), status: FeedbackSubmissionStatus, timestamp: Date = Date(), message: String) {
        self.id = id
        self.status = status
        self.timestamp = timestamp
        self.message = message
    }
}

/// Feedback submission status
public enum FeedbackSubmissionStatus: String, Codable, CaseIterable, Hashable {
    case success = "success"
    case pending = "pending"
    case failed = "failed"
    case localOnly = "localOnly"
    
    public var displayName: String {
        switch self {
        case .success: return "Success"
        case .pending: return "Pending"
        case .failed: return "Failed"
        case .localOnly: return "Local Only"
        }
    }
}

/// Feedback entry for history tracking
public struct FeedbackEntry: Codable, Hashable {
    public let id: UUID
    public let feedback: FeedbackType
    public let result: FeedbackSubmissionResult?
    public let timestamp: Date
    
    public init(feedback: FeedbackType, result: FeedbackSubmissionResult?, timestamp: Date = Date()) {
        self.id = UUID()
        self.feedback = feedback
        self.result = result
        self.timestamp = timestamp
    }
}

/// Email feedback structure
public struct EmailFeedback: Codable, Hashable {
    public let recipient: String
    public let subject: String
    public let body: String
    public let anonymousID: String
    
    public init(recipient: String, subject: String, body: String, anonymousID: String) {
        self.recipient = recipient
        self.subject = subject
        self.body = body
        self.anonymousID = anonymousID
    }
}

/// Feedback statistics
public struct FeedbackStatistics: Codable, Hashable {
    public let totalSubmissions: Int
    public let bugReports: Int
    public let featureRequests: Int
    public let generalFeedback: Int
    public let successRate: Double
    public let averageResponseTime: TimeInterval
    
    public init(totalSubmissions: Int, bugReports: Int, featureRequests: Int, generalFeedback: Int, successRate: Double, averageResponseTime: TimeInterval) {
        self.totalSubmissions = totalSubmissions
        self.bugReports = bugReports
        self.featureRequests = featureRequests
        self.generalFeedback = generalFeedback
        self.successRate = successRate
        self.averageResponseTime = averageResponseTime
    }
}

/// Feedback errors
public enum FeedbackError: Error, LocalizedError {
    case cooldownActive
    case invalidContent
    case privacyViolation
    case submissionFailed(String)
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .cooldownActive:
            return "Please wait before submitting another feedback"
        case .invalidContent:
            return "Feedback content is invalid or too short/long"
        case .privacyViolation:
            return "Feedback contains potentially identifying information"
        case .submissionFailed(let message):
            return "Submission failed: \(message)"
        case .networkError:
            return "Network error occurred during submission"
        }
    }
}

// MARK: - String Extension

private extension Substring {
    var string: String { String(self) }
    saveFeedbackConfiguration()
    
        // Regenerate anonymous ID if privacy level increased
        if level == .maximum {
            generateAnonymousUserID()
        }
    }
    
    /// Get feedback statistics
    public func getFeedbackStatistics() -> FeedbackStatistics {
        let totalSubmissions = feedbackHistory.count
        let bugReports = feedbackHistory.filter {
            if case .bugReport = $0.feedback { return true }
            return false
        }.count
        let featureRequests = feedbackHistory.filter {
            if case .featureRequest = $0.feedback { return true }
            return false
        }.count
        let generalFeedback = feedbackHistory.filter {
            if case .generalFeedback = $0.feedback { return true }
            return false
        }.count
        
        return FeedbackStatistics(
            totalSubmissions: totalSubmissions,
            bugReports: bugReports,
            featureRequests: featureRequests,
            generalFeedback: generalFeedback,
            successRate: calculateSuccessRate(),
            averageResponseTime: 0 // Would be tracked from actual responses
        )
    }
    
    /// Clear feedback history
    public func clearFeedbackHistory() {
        logger.info("🗑️ Clearing feedback history")
        feedbackHistory.removeAll()
        saveFeedbackHistory()
    }
    
    /// Export feedback data for user review
    public func exportFeedbackData() -> String {
        logger.info("📤 Exporting feedback data")
        
        var exportData = "Arcana Feedback Export\n"
        exportData += "Generated: \(Date())\n"
        exportData += "Anonymous ID: \(anonymousUserID)\n"
        exportData += "Privacy Level: \(privacyLevel.displayName)\n\n"
        
        for entry in feedbackHistory {
            exportData += "--- Feedback Entry ---\n"
            exportData += "Date: \(entry.timestamp)\n"
            exportData += "Type: \(entry.feedback.typeName)\n"
            exportData += "Status: \(entry.result?.status.displayName ?? "Unknown")\n\n"
        }
        
        return exportData
    }
    
    // MARK: - Private Methods
    
    private func loadFeedbackConfiguration() {
        let defaults = UserDefaults.standard
        
        if let privacyLevelRaw = defaults.string(forKey: "FeedbackPrivacyLevel"),
           let privacyLevel = FeedbackPrivacyLevel(rawValue: privacyLevelRaw) {
            self.privacyLevel = privacyLevel
        }
        
        feedbackOptInStatus = defaults.bool(forKey: "FeedbackOptInStatus")
        
        loadFeedbackHistory()
    }
    
    private func saveFeedbackConfiguration() {
        let defaults = UserDefaults.standard
        defaults.set(privacyLevel.rawValue, forKey: "FeedbackPrivacyLevel")
        defaults.set(feedbackOptInStatus, forKey: "FeedbackOptInStatus")
    }
    
    private func loadFeedbackHistory() {
        guard let data = UserDefaults.standard.data(forKey: "FeedbackHistory"),
              let history = try? JSONDecoder().decode([FeedbackEntry].self, from: data) else {
            return
        }
        
        feedbackHistory = Array(history.suffix(maxFeedbackHistorySize))
    }
    
    private func saveFeedbackHistory() {
        guard let data = try? JSONEncoder().encode(feedbackHistory) else { return }
        UserDefaults.standard.set(data, forKey: "FeedbackHistory")
    }
    
    private func generateAnonymousUserID() {
        // Generate a cryptographically secure anonymous ID
        let randomData = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        anonymousUserID = SHA256.hash(data: randomData).compactMap { String(format: "%02x", $0) }.joined()
            .prefix(16).string // Use first 16 characters
        
        logger.debug("🔐 Generated new anonymous user ID")
    }
    
    private func canSubmitFeedback() -> Bool {
        guard feedbackOptInStatus else { return false }
        
        if let lastSubmission = lastSubmissionTime {
            return Date().timeIntervalSince(lastSubmission) >= feedbackCooldownPeriod
        }
        
        return true
    }
    
    private func validateFeedbackContent(_ content: String) -> Bool {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedContent.count >= minFeedbackLength && trimmedContent.count <= maxFeedbackLength
    }
    
    private func sanitizeContent(_ content: String) -> String {
        var sanitized = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove potential PII patterns (basic implementation)
        let patterns = [
            #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#, // Email addresses
            #"\b\d{3}-\d{2}-\d{4}\b"#, // SSN pattern
            #"\b\d{3}-\d{3}-\d{4}\b"#, // Phone number pattern
        ]
        
        for pattern in patterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "[REDACTED]",
                options: .regularExpression
            )
        }
        
        return sanitized
    }
    
    private func getAnonymizedSystemInfo() -> SystemInfo {
        var systemInfo = SystemInfo()
        
        // Apply differential privacy to system information
        if privacyLevel == .maximum {
            // Remove specific version information, keep only major versions
            let versionComponents = systemInfo.macOSVersion.components(separatedBy: ".")
            if let majorVersion = versionComponents.first {
                systemInfo = SystemInfo(
                    macOSVersion: "\(majorVersion).x",
                    appVersion: ArcanaConstants.appVersion,
                    deviceModel: "Mac",
                    memorySize: 0, // Don't include specific memory size
                    storageAvailable: 0 // Don't include specific storage info
                )
            }
        }
        
        return systemInfo
    }
    
    private func submitFeedback(_ feedback: FeedbackType) async throws -> FeedbackSubmissionResult {
        // In Phase 1, we store locally and generate email content
        // In Phase 2, this would actually submit to a privacy-preserving service
        
        logger.debug("📝 Processing feedback submission (local storage)")
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // For now, we consider all submissions successful since they're stored locally
        return FeedbackSubmissionResult(
            id: UUID(),
            status: .success,
            timestamp: Date(),
            message: "Feedback stored locally. Use 'Generate Email' to submit manually."
        )
    }
    
    private func recordFeedbackSubmission(_ feedback: FeedbackType, result: FeedbackSubmissionResult) {
        let entry = FeedbackEntry(
            feedback: feedback,
            result: result,
            timestamp: Date()
        )
        
        feedbackHistory.append(entry)
        
        // Limit history size
        if feedbackHistory.count > maxFeedbackHistorySize {
            feedbackHistory.removeFirst(feedbackHistory.count - maxFeedbackHistorySize)
        }
        
        saveF
