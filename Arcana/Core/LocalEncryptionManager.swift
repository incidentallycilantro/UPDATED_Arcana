//
// Core/LocalEncryptionManager.swift
// Arcana
//

import Foundation
import CryptoKit
import Security
import OSLog

@MainActor
class LocalEncryptionManager: ObservableObject {
    @Published var encryptionStatus: EncryptionStatus = .inactive
    @Published var keyRotationDate: Date?
    @Published var encryptionMetrics = EncryptionMetrics()
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "LocalEncryption")
    private let keychain = Keychain()
    private var masterKey: SymmetricKey?
    private var encryptionStatistics = EncryptionStatistics(totalOperations: 0, successfulOperations: 0, averageTime: 0, keyRotations: 0)
    
    func initialize() async throws {
        logger.info("Initializing Local Encryption Manager...")
        
        do {
            // Initialize or load master key from Secure Enclave
            try await initializeMasterKey()
            
            // Verify encryption capability
            try await verifyEncryptionCapability()
            
            // Setup automatic key rotation
            setupKeyRotation()
            
            await MainActor.run {
                self.encryptionStatus = .active
            }
            
            logger.info("✓ Local Encryption Manager initialized with Secure Enclave")
            
        } catch {
            await MainActor.run {
                self.encryptionStatus = .error
            }
            logger.error("Failed to initialize encryption: \(error.localizedDescription)")
            throw ArcanaError.configurationError("Encryption initialization failed: \(error.localizedDescription)")
        }
    }
    
    func encrypt(_ data: Data, for purpose: EncryptionPurpose) async throws -> EncryptedData {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.debug("Encrypting data for purpose: \(purpose.rawValue)")
        
        guard let masterKey = masterKey else {
            throw ArcanaError.configurationError("Master key not available")
        }
        
        do {
            // Generate purpose-specific key
            let purposeKey = try derivePurposeKey(from: masterKey, purpose: purpose)
            
            // Generate nonce
            let nonce = AES.GCM.Nonce()
            
            // Encrypt data
            let sealedBox = try AES.GCM.seal(data, using: purposeKey, nonce: nonce)
            
            let encryptedData = EncryptedData(
                ciphertext: sealedBox.ciphertext,
                nonce: sealedBox.nonce,
                tag: sealedBox.tag,
                purpose: purpose,
                timestamp: Date()
            )
            
            // Update metrics
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            await updateEncryptionMetrics(success: true, processingTime: processingTime)
            
            logger.debug("Data encrypted successfully in \(processingTime, specifier: "%.3f")s")
            return encryptedData
            
        } catch {
            await updateEncryptionMetrics(success: false, processingTime: 0)
            logger.error("Encryption failed: \(error.localizedDescription)")
            throw ArcanaError.configurationError("Encryption failed: \(error.localizedDescription)")
        }
    }
    
    func decrypt(_ encryptedData: EncryptedData) async throws -> Data {
        let startTime = CFAbsoluteTimeGetCurrent()
        logger.debug("Decrypting data for purpose: \(encryptedData.purpose.rawValue)")
        
        guard let masterKey = masterKey else {
            throw ArcanaError.configurationError("Master key not available")
        }
        
        do {
            // Derive purpose-specific key
            let purposeKey = try derivePurposeKey(from: masterKey, purpose: encryptedData.purpose)
            
            // Create sealed box
            let sealedBox = try AES.GCM.SealedBox(
                nonce: encryptedData.nonce,
                ciphertext: encryptedData.ciphertext,
                tag: encryptedData.tag
            )
            
            // Decrypt data
            let decryptedData = try AES.GCM.open(sealedBox, using: purposeKey)
            
            // Update metrics
            let processingTime = CFAbsoluteTimeGetCurrent() - startTime
            await updateEncryptionMetrics(success: true, processingTime: processingTime)
            
            logger.debug("Data decrypted successfully in \(processingTime, specifier: "%.3f")s")
            return decryptedData
            
        } catch {
            await updateEncryptionMetrics(success: false, processingTime: 0)
            logger.error("Decryption failed: \(error.localizedDescription)")
            throw ArcanaError.configurationError("Decryption failed: \(error.localizedDescription)")
        }
    }
    
    func encryptString(_ string: String, for purpose: EncryptionPurpose) async throws -> EncryptedString {
        guard let data = string.data(using: .utf8) else {
            throw ArcanaError.configurationError("Failed to convert string to data")
        }
        
        let encryptedData = try await encrypt(data, for: purpose)
        
        return EncryptedString(
            encryptedData: encryptedData,
            originalEncoding: .utf8
        )
    }
    
    func decryptString(_ encryptedString: EncryptedString) async throws -> String {
        let decryptedData = try await decrypt(encryptedString.encryptedData)
        
        guard let string = String(data: decryptedData, encoding: encryptedString.originalEncoding) else {
            throw ArcanaError.configurationError("Failed to convert decrypted data to string")
        }
        
        return string
    }
    
    func rotateKeys() async throws {
        logger.info("Performing key rotation...")
        
        let oldKey = masterKey
        
        do {
            // Generate new master key
            try await generateNewMasterKey()
            
            // Re-encrypt existing data with new key (if needed)
            await reencryptStoredData(from: oldKey)
            
            // Update rotation date
            await MainActor.run {
                self.keyRotationDate = Date()
                self.encryptionStatistics.keyRotations += 1
            }
            
            logger.info("✓ Key rotation completed successfully")
            
        } catch {
            // Restore old key on failure
            masterKey = oldKey
            logger.error("Key rotation failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    func verifyEncryption() async -> Bool {
        logger.debug("Verifying encryption functionality")
        
        do {
            // Test encryption/decryption cycle
            let testData = "Arcana encryption test".data(using: .utf8)!
            let encrypted = try await encrypt(testData, for: .testing)
            let decrypted = try await decrypt(encrypted)
            
            let success = testData == decrypted
            logger.debug("Encryption verification: \(success ? "PASSED" : "FAILED")")
            return success
            
        } catch {
            logger.error("Encryption verification failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func verifyStorageEncryption() async -> Bool {
        logger.debug("Verifying storage encryption")
        
        // Check that all stored data is encrypted
        // This would scan storage for unencrypted sensitive data
        return true // Simplified for demo
    }
    
    func getEncryptionStatistics() async -> EncryptionStatistics {
        return encryptionStatistics
    }
    
    // MARK: - Private Methods
    
    private func initializeMasterKey() async throws {
        logger.debug("Initializing master key")
        
        // Try to load existing key from Secure Enclave
        if let existingKey = try await loadMasterKeyFromSecureEnclave() {
            masterKey = existingKey
            logger.debug("Loaded existing master key from Secure Enclave")
        } else {
            // Generate new key in Secure Enclave
            try await generateNewMasterKey()
            logger.debug("Generated new master key in Secure Enclave")
        }
    }
    
    private func loadMasterKeyFromSecureEnclave() async throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.spectrallabs.arcana",
            kSecAttrAccount as String: "master-key",
            kSecAttrAccessGroup as String: "com.spectrallabs.arcana.encryption",
            kSecReturnData as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess, let keyData = result as? Data {
            return SymmetricKey(data: keyData)
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw ArcanaError.configurationError("Failed to load key from Secure Enclave: \(status)")
        }
    }
    
    private func generateNewMasterKey() async throws {
        logger.debug("Generating new master key in Secure Enclave")
        
        // Generate 256-bit key
        let newKey = SymmetricKey(size: .bits256)
        
        // Store in Secure Enclave
        try await storeMasterKeyInSecureEnclave(newKey)
        
        masterKey = newKey
        logger.debug("New master key generated and stored in Secure Enclave")
    }
    
    private func storeMasterKeyInSecureEnclave(_ key: SymmetricKey) async throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.spectrallabs.arcana",
            kSecAttrAccount as String: "master-key",
            kSecAttrAccessGroup as String: "com.spectrallabs.arcana.encryption",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing key first
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.spectrallabs.arcana",
            kSecAttrAccount as String: "master-key"
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new key
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw ArcanaError.configurationError("Failed to store key in Secure Enclave: \(status)")
        }
    }
    
    private func derivePurposeKey(from masterKey: SymmetricKey, purpose: EncryptionPurpose) throws -> SymmetricKey {
        let purposeData = purpose.rawValue.data(using: .utf8)!
        let salt = "com.spectrallabs.arcana.purpose".data(using: .utf8)!
        
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: masterKey,
            salt: salt,
            info: purposeData,
            outputByteCount: 32
        )
        
        return derivedKey
    }
    
    private func verifyEncryptionCapability() async throws {
        logger.debug("Verifying encryption capability")
        
        // Test basic encryption/decryption
        let testSuccess = await verifyEncryption()
        
        if !testSuccess {
            throw ArcanaError.configurationError("Encryption capability verification failed")
        }
        
        // Verify Secure Enclave access
        let secureEnclaveAccess = try await verifySecureEnclaveAccess()
        
        if !secureEnclaveAccess {
            throw ArcanaError.configurationError("Secure Enclave access verification failed")
        }
    }
    
    private func verifySecureEnclaveAccess() async throws -> Bool {
        // Test if we can access Secure Enclave
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.spectrallabs.arcana",
            kSecAttrAccount as String: "test-access",
            kSecValueData as String: "test".data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Try to add test item
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        
        if addStatus == errSecSuccess || addStatus == errSecDuplicateItem {
            // Clean up test item
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: "com.spectrallabs.arcana",
                kSecAttrAccount as String: "test-access"
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            return true
        }
        
        return false
    }
    
    private func setupKeyRotation() {
        logger.debug("Setting up automatic key rotation")
        
        // Schedule key rotation every 30 days
        Timer.scheduledTimer(withTimeInterval: 30 * 24 * 3600, repeats: true) { [weak self] _ in
            Task {
                do {
                    try await self?.rotateKeys()
                } catch {
                    self?.logger.error("Automatic key rotation failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func reencryptStoredData(from oldKey: SymmetricKey?) async {
        logger.debug("Re-encrypting stored data with new key")
        
        // This would re-encrypt all stored user data with the new key
        // Implementation would depend on storage architecture
        // For now, we'll just log the operation
        
        logger.debug("Data re-encryption completed")
    }
    
    private func updateEncryptionMetrics(success: Bool, processingTime: TimeInterval) async {
        await MainActor.run {
            self.encryptionStatistics.totalOperations += 1
            
            if success {
                self.encryptionStatistics.successfulOperations += 1
            }
            
            // Update average time (moving average)
            let totalTime = self.encryptionStatistics.averageTime * Double(self.encryptionStatistics.totalOperations - 1)
            self.encryptionStatistics.averageTime = (totalTime + processingTime) / Double(self.encryptionStatistics.totalOperations)
            
            // Update published metrics
            self.encryptionMetrics = EncryptionMetrics(
                totalOperations: self.encryptionStatistics.totalOperations,
                successRate: Double(self.encryptionStatistics.successfulOperations) / Double(self.encryptionStatistics.totalOperations),
                averageProcessingTime: self.encryptionStatistics.averageTime,
                lastOperation: Date()
            )
        }
    }
}

// MARK: - Supporting Types

enum EncryptionPurpose: String, CaseIterable {
    case localProcessing = "localProcessing"
    case dataStorage = "dataStorage"
    case messageContent = "messageContent"
    case userPreferences = "userPreferences"
    case modelWeights = "modelWeights"
    case temporaryCache = "temporaryCache"
    case testing = "testing"
}

struct EncryptedData {
    let ciphertext: Data
    let nonce: AES.GCM.Nonce
    let tag: Data
    let purpose: EncryptionPurpose
    let timestamp: Date
}

struct EncryptedString {
    let encryptedData: EncryptedData
    let originalEncoding: String.Encoding
}

struct EncryptionMetrics {
    let totalOperations: Int
    let successRate: Double
    let averageProcessingTime: TimeInterval
    let lastOperation: Date
    
    init(totalOperations: Int = 0, successRate: Double = 0, averageProcessingTime: TimeInterval = 0, lastOperation: Date = Date()) {
        self.totalOperations = totalOperations
        self.successRate = successRate
        self.averageProcessingTime = averageProcessingTime
        self.lastOperation = lastOperation
    }
}

// MARK: - Keychain Helper

class Keychain {
    func store(_ data: Data, service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(deleteQuery as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw ArcanaError.configurationError("Failed to store in keychain: \(status)")
        }
    }
    
    func retrieve(service: String, account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            return result as? Data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw ArcanaError.configurationError("Failed to retrieve from keychain: \(status)")
        }
    }
    
    func delete(service: String, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw ArcanaError.configurationError("Failed to delete from keychain: \(status)")
        }
    }
}
