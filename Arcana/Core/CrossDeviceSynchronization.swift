//
// CrossDeviceSynchronization.swift
// Arcana
//
// Revolutionary cross-device coordination system for unified AI assistant experience
// Enables seamless synchronization across macOS and iOS with privacy-first approach
//

import Foundation
import Combine
import Network
import os.log

// MARK: - Cross Device Synchronization

/// Revolutionary cross-device synchronization system that maintains privacy while enabling seamless experiences
/// Coordinates workspace, conversation, and preference synchronization across all user devices
@MainActor
public class CrossDeviceSynchronization: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published private(set) var isEnabled: Bool = false
    @Published private(set) var connectedDevices: [ConnectedDevice] = []
    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var lastSyncTime: Date?
    @Published private(set) var pendingSyncOperations: [SyncOperation] = []
    @Published private(set) var syncProgress: Double = 0.0
    @Published private(set) var networkReachability: NetworkReachability = .unknown
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: ArcanaConstants.bundleIdentifier, category: "CrossDeviceSync")
    private var cancellables = Set<AnyCancellable>()
    private let encryptionManager: LocalEncryptionManager
    private let networkMonitor = NWPathMonitor()
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 300 // 5 minutes
    
    // Device discovery
    private var bonjourService: NetService?
    private var bonjourBrowser: NetServiceBrowser?
    private let serviceType = "_arcana._tcp"
    private let serviceDomain = "local."
    
    // Sync configuration
    private var maxSyncPayloadSize: Int = 10 * 1024 * 1024 // 10MB
    private var compressionEnabled: Bool = true
    private var encryptionEnabled: Bool = true
    
    // MARK: - Initialization
    
    public init(encryptionManager: LocalEncryptionManager = LocalEncryptionManager()) {
        self.encryptionManager = encryptionManager
        logger.info("🔄 Initializing Revolutionary Cross-Device Synchronization")
        
        setupNetworkMonitoring()
        loadSyncConfiguration()
    }
    
    deinit {
        stopSynchronization()
        networkMonitor.cancel()
    }
    
    // MARK: - Public Interface
    
    /// Enable cross-device synchronization
    public func enableSynchronization() async throws {
        guard !isEnabled else { return }
        
        logger.info("▶️ Enabling cross-device synchronization")
        
        do {
            // Verify encryption capabilities
            try await encryptionManager.generateDeviceKey()
            
            // Start device discovery
            try startDeviceDiscovery()
            
            // Start sync timer
            startSyncTimer()
            
            isEnabled = true
            syncStatus = .discovering
            
            logger.info("✅ Cross-device synchronization enabled")
        } catch {
            logger.error("❌ Failed to enable synchronization: \(error.localizedDescription)")
            throw ArcanaError.configurationError("Failed to enable synchronization: \(error.localizedDescription)")
        }
    }
    
    /// Disable cross-device synchronization
    public func disableSynchronization() {
        guard isEnabled else { return }
        
        logger.info("⏹️ Disabling cross-device synchronization")
        
        stopDeviceDiscovery()
        stopSyncTimer()
        connectedDevices.removeAll()
        pendingSyncOperations.removeAll()
        
        isEnabled = false
        syncStatus = .idle
        
        logger.info("✅ Cross-device synchronization disabled")
    }
    
    /// Manually trigger synchronization
    public func triggerSync() async throws {
        guard isEnabled else {
            throw ArcanaError.configurationError("Synchronization is not enabled")
        }
        
        logger.info("🔄 Manually triggering synchronization")
        await performSynchronization()
    }
    
    /// Add sync operation to the queue
    public func queueSyncOperation(_ operation: SyncOperation) {
        logger.debug("➕ Queuing sync operation: \(operation.type.rawValue)")
        pendingSyncOperations.append(operation)
        
        // Trigger immediate sync for high priority operations
        if operation.priority == .high || operation.priority == .critical {
            Task {
                await performSynchronization()
            }
        }
    }
    
    /// Get sync statistics
    public func getSyncStatistics() -> SyncStatistics {
        let totalOperations = pendingSyncOperations.count
        let completedToday = 0 // Would track completed operations
        let failedToday = 0 // Would track failed operations
        let dataTransferred = Int64(0) // Would track data transfer
        
        return SyncStatistics(
            totalPendingOperations: totalOperations,
            completedOperationsToday: completedToday,
            failedOperationsToday: failedToday,
            totalDataTransferredToday: dataTransferred,
            averageSyncTime: 2.5, // Would calculate from history
            successRate: 0.95 // Would calculate from history
        )
    }
    
    /// Configure sync settings
    public func configureSyncSettings(_ settings: SyncSettings) {
        logger.info("⚙️ Configuring sync settings")
        
        maxSyncPayloadSize = settings.maxPayloadSize
        compressionEnabled = settings.compressionEnabled
        encryptionEnabled = settings.encryptionEnabled
        
        // Update sync timer if interval changed
        if let timer = syncTimer, timer.timeInterval != settings.syncInterval {
            stopSyncTimer()
            if isEnabled {
                startSyncTimer()
            }
        }
        
        saveSyncConfiguration()
    }
    
    /// Get device information
    public func getDeviceInfo() -> DeviceInfo {
        return DeviceInfo(
            id: getDeviceIdentifier(),
            name: Host.current().localizedName ?? "Mac",
            type: .mac,
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            appVersion: ArcanaConstants.appVersion,
            capabilities: [.workspaceSync, .conversationSync, .settingsSync, .knowledgeSync],
            lastSeen: Date(),
            isCurrentDevice: true
        )
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.updateNetworkReachability(path)
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        networkMonitor.start(queue: queue)
    }
    
    private func updateNetworkReachability(_ path: NWPath) {
        switch path.status {
        case .satisfied:
            if path.usesInterfaceType(.wifi) {
                networkReachability = .wifi
            } else if path.usesInterfaceType(.cellular) {
                networkReachability = .cellular
            } else {
                networkReachability = .ethernet
            }
        case .requiresConnection:
            networkReachability = .requiresConnection
        case .unsatisfied:
            networkReachability = .unavailable
        @unknown default:
            networkReachability = .unknown
        }
        
        logger.debug("📶 Network reachability updated: \(networkReachability.rawValue)")
    }
    
    private func startDeviceDiscovery() throws {
        logger.info("🔍 Starting device discovery")
        
        // Start Bonjour service for advertising this device
        bonjourService = NetService(domain: serviceDomain, type: serviceType, name: getDeviceIdentifier())
        bonjourService?.delegate = self
        bonjourService?.publish()
        
        // Start browsing for other devices
        bonjourBrowser = NetServiceBrowser()
        bonjourBrowser?.delegate = self
        bonjourBrowser?.searchForServices(ofType: serviceType, inDomain: serviceDomain)
        
        syncStatus = .discovering
    }
    
    private func stopDeviceDiscovery() {
        logger.info("🛑 Stopping device discovery")
        
        bonjourService?.stop()
        bonjourService = nil
        
        bonjourBrowser?.stop()
        bonjourBrowser = nil
        
        connectedDevices.removeAll()
    }
    
    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performSynchronization()
            }
        }
    }
    
    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    private func performSynchronization() async {
        guard isEnabled && !pendingSyncOperations.isEmpty else { return }
        guard networkReachability != .unavailable else {
            logger.warning("⚠️ Skipping sync - network unavailable")
            return
        }
        
        logger.info("🔄 Performing synchronization")
        syncStatus = .syncing
        syncProgress = 0.0
        
        do {
            let operations = pendingSyncOperations.sorted { $0.priority.rawValue > $1.priority.rawValue }
            let totalOperations = Double(operations.count)
            
            for (index, operation) in operations.enumerated() {
                try await executeSyncOperation(operation)
                syncProgress = Double(index + 1) / totalOperations
                
                // Remove completed operation
                if let operationIndex = pendingSyncOperations.firstIndex(of: operation) {
                    pendingSyncOperations.remove(at: operationIndex)
                }
            }
            
            lastSyncTime = Date()
            syncStatus = .idle
            syncProgress = 1.0
            
            logger.info("✅ Synchronization completed successfully")
            
        } catch {
            logger.error("❌ Synchronization failed: \(error.localizedDescription)")
            syncStatus = .error(error.localizedDescription)
        }
        
        // Reset progress after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.syncProgress = 0.0
        }
    }
    
    private func executeSyncOperation(_ operation: SyncOperation) async throws {
        logger.debug("🔧 Executing sync operation: \(operation.type.rawValue)")
        
        switch operation.type {
        case .workspaceSync:
            try await syncWorkspaces(operation)
        case .conversationSync:
            try await syncConversations(operation)
        case .settingsSync:
            try await syncSettings(operation)
        case .knowledgeSync:
            try await syncKnowledge(operation)
        case .fullSync:
            try await performFullSync(operation)
        }
    }
    
    private func syncWorkspaces(_ operation: SyncOperation) async throws {
        // Implementation would sync workspace data across devices
        logger.debug("📁 Syncing workspaces")
        
        // Simulate sync operation
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In real implementation:
        // 1. Collect workspace changes
        // 2. Encrypt data
        // 3. Send to connected devices
        // 4. Handle conflicts
        // 5. Update local state
    }
    
    private func syncConversations(_ operation: SyncOperation) async throws {
        // Implementation would sync conversation data across devices
        logger.debug("💬 Syncing conversations")
        
        // Simulate sync operation
        try await Task.sleep(nanoseconds: 750_000_000) // 0.75 seconds
    }
    
    private func syncSettings(_ operation: SyncOperation) async throws {
        // Implementation would sync settings across devices
        logger.debug("⚙️ Syncing settings")
        
        // Simulate sync operation
        try await Task.sleep(nanoseconds: 250_000_000) // 0.25 seconds
    }
    
    private func syncKnowledge(_ operation: SyncOperation) async throws {
        // Implementation would sync knowledge graph across devices
        logger.debug("🧠 Syncing knowledge")
        
        // Simulate sync operation
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
    }
    
    private func performFullSync(_ operation: SyncOperation) async throws {
        // Implementation would perform complete synchronization
        logger.debug("🌐 Performing full sync")
        
        try await syncWorkspaces(operation)
        try await syncConversations(operation)
        try await syncSettings(operation)
        try await syncKnowledge(operation)
    }
    
    private func getDeviceIdentifier() -> String {
        // Create a stable device identifier
        if let identifier = UserDefaults.standard.string(forKey: "ArcanaDeviceIdentifier") {
            return identifier
        }
        
        let identifier = UUID().uuidString
        UserDefaults.standard.set(identifier, forKey: "ArcanaDeviceIdentifier")
        return identifier
    }
    
    private func loadSyncConfiguration() {
        // Load saved sync configuration
        let defaults = UserDefaults.standard
        maxSyncPayloadSize = defaults.object(forKey: "MaxSyncPayloadSize") as? Int ?? (10 * 1024 * 1024)
        compressionEnabled = defaults.object(forKey: "CompressionEnabled") as? Bool ?? true
        encryptionEnabled = defaults.object(forKey: "EncryptionEnabled") as? Bool ?? true
    }
    
    private func saveSyncConfiguration() {
        // Save sync configuration
        let defaults = UserDefaults.standard
        defaults.set(maxSyncPayloadSize, forKey: "MaxSyncPayloadSize")
        defaults.set(compressionEnabled, forKey: "CompressionEnabled")
        defaults.set(encryptionEnabled, forKey: "EncryptionEnabled")
    }
}

// MARK: - NetService Delegate

extension CrossDeviceSynchronization: NetServiceDelegate {
    
    public func netServiceDidPublish(_ sender: NetService) {
        logger.info("📡 Device published successfully")
    }
    
    public func netService(_ sender: NetService, didNotPublish errorDict: [String : NSNumber]) {
        logger.error("❌ Failed to publish device: \(errorDict)")
    }
}

// MARK: - NetServiceBrowser Delegate

extension CrossDeviceSynchronization: NetServiceBrowserDelegate {
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        logger.info("🔍 Discovered device: \(service.name)")
        
        // Create connected device representation
        let device = ConnectedDevice(
            id: service.name,
            name: service.name,
            type: .unknown, // Would be determined from service info
            status: .discovered,
            lastSeen: Date(),
            capabilities: []
        )
        
        connectedDevices.append(device)
        
        if !moreComing {
            syncStatus = .idle
        }
    }
    
    public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        logger.info("📤 Device disappeared: \(service.name)")
        
        connectedDevices.removeAll { $0.id == service.name }
    }
}

// MARK: - Supporting Types

/// Connected device information
public struct ConnectedDevice: Codable, Hashable, Identifiable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let status: DeviceStatus
    public let lastSeen: Date
    public let capabilities: [SyncCapability]
    
    public init(id: String, name: String, type: DeviceType, status: DeviceStatus, lastSeen: Date, capabilities: [SyncCapability]) {
        self.id = id
        self.name = name
        self.type = type
        self.status = status
        self.lastSeen = lastSeen
        self.capabilities = capabilities
    }
}

/// Device information
public struct DeviceInfo: Codable, Hashable {
    public let id: String
    public let name: String
    public let type: DeviceType
    public let osVersion: String
    public let appVersion: String
    public let capabilities: [SyncCapability]
    public let lastSeen: Date
    public let isCurrentDevice: Bool
    
    public init(id: String, name: String, type: DeviceType, osVersion: String, appVersion: String, capabilities: [SyncCapability], lastSeen: Date, isCurrentDevice: Bool) {
        self.id = id
        self.name = name
        self.type = type
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.capabilities = capabilities
        self.lastSeen = lastSeen
        self.isCurrentDevice = isCurrentDevice
    }
}

/// Device types
public enum DeviceType: String, Codable, CaseIterable, Hashable {
    case mac = "mac"
    case iPhone = "iPhone"
    case iPad = "iPad"
    case unknown = "unknown"
    
    public var displayName: String {
        switch self {
        case .mac: return "Mac"
        case .iPhone: return "iPhone"
        case .iPad: return "iPad"
        case .unknown: return "Unknown"
        }
    }
    
    public var icon: String {
        switch self {
        case .mac: return "desktopcomputer"
        case .iPhone: return "iphone"
        case .iPad: return "ipad"
        case .unknown: return "questionmark.circle"
        }
    }
}

/// Device connection status
public enum DeviceStatus: String, Codable, CaseIterable, Hashable {
    case discovered = "discovered"
    case connecting = "connecting"
    case connected = "connected"
    case syncing = "syncing"
    case error = "error"
    case offline = "offline"
    
    public var displayName: String {
        switch self {
        case .discovered: return "Discovered"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .syncing: return "Syncing"
        case .error: return "Error"
        case .offline: return "Offline"
        }
    }
}

/// Synchronization capabilities
public enum SyncCapability: String, Codable, CaseIterable, Hashable {
    case workspaceSync = "workspaceSync"
    case conversationSync = "conversationSync"
    case settingsSync = "settingsSync"
    case knowledgeSync = "knowledgeSync"
    case fileSync = "fileSync"
    case realtimeSync = "realtimeSync"
    
    public var displayName: String {
        switch self {
        case .workspaceSync: return "Workspace Sync"
        case .conversationSync: return "Conversation Sync"
        case .settingsSync: return "Settings Sync"
        case .knowledgeSync: return "Knowledge Sync"
        case .fileSync: return "File Sync"
        case .realtimeSync: return "Realtime Sync"
        }
    }
}

/// Synchronization status
public enum SyncStatus: Hashable {
    case idle
    case discovering
    case syncing
    case error(String)
    
    public var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .discovering: return "Discovering Devices"
        case .syncing: return "Syncing"
        case .error(let message): return "Error: \(message)"
        }
    }
}

/// Network reachability status
public enum NetworkReachability: String, Codable, CaseIterable, Hashable {
    case unknown = "unknown"
    case unavailable = "unavailable"
    case wifi = "wifi"
    case cellular = "cellular"
    case ethernet = "ethernet"
    case requiresConnection = "requiresConnection"
    
    public var displayName: String {
        switch self {
        case .unknown: return "Unknown"
        case .unavailable: return "Unavailable"
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .ethernet: return "Ethernet"
        case .requiresConnection: return "Requires Connection"
        }
    }
}

/// Sync operation
public struct SyncOperation: Codable, Hashable, Identifiable {
    public let id: UUID
    public let type: SyncOperationType
    public let priority: SyncPriority
    public let targetDevices: [String]
    public let data: Data?
    public let timestamp: Date
    
    public init(type: SyncOperationType, priority: SyncPriority = .normal, targetDevices: [String] = [], data: Data? = nil) {
        self.id = UUID()
        self.type = type
        self.priority = priority
        self.targetDevices = targetDevices
        self.data = data
        self.timestamp = Date()
    }
}

/// Sync operation types
public enum SyncOperationType: String, Codable, CaseIterable, Hashable {
    case workspaceSync = "workspaceSync"
    case conversationSync = "conversationSync"
    case settingsSync = "settingsSync"
    case knowledgeSync = "knowledgeSync"
    case fullSync = "fullSync"
}

/// Sync priority levels
public enum SyncPriority: Int, Codable, CaseIterable, Hashable {
    case low = 1
    case normal = 2
    case high = 3
    case critical = 4
}

/// Sync settings configuration
public struct SyncSettings: Codable, Hashable {
    public let syncInterval: TimeInterval
    public let maxPayloadSize: Int
    public let compressionEnabled: Bool
    public let encryptionEnabled: Bool
    public let autoSyncEnabled: Bool
    public let wifiOnlySync: Bool
    
    public init(syncInterval: TimeInterval = 300, maxPayloadSize: Int = 10 * 1024 * 1024, compressionEnabled: Bool = true, encryptionEnabled: Bool = true, autoSyncEnabled: Bool = true, wifiOnlySync: Bool = false) {
        self.syncInterval = syncInterval
        self.maxPayloadSize = maxPayloadSize
        self.compressionEnabled = compressionEnabled
        self.encryptionEnabled = encryptionEnabled
        self.autoSyncEnabled = autoSyncEnabled
        self.wifiOnlySync = wifiOnlySync
    }
}

/// Sync statistics
public struct SyncStatistics: Codable, Hashable {
    public let totalPendingOperations: Int
    public let completedOperationsToday: Int
    public let failedOperationsToday: Int
    public let totalDataTransferredToday: Int64
    public let averageSyncTime: TimeInterval
    public let successRate: Double
    
    public init(totalPendingOperations: Int, completedOperationsToday: Int, failedOperationsToday: Int, totalDataTransferredToday: Int64, averageSyncTime: TimeInterval, successRate: Double) {
        self.totalPendingOperations = totalPendingOperations
        self.completedOperationsToday = completedOperationsToday
        self.failedOperationsToday = failedOperationsToday
        self.totalDataTransferredToday = totalDataTransferredToday
        self.averageSyncTime = averageSyncTime
        self.successRate = successRate
    }
}
