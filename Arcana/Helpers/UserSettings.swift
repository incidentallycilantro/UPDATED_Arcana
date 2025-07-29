//
// Helpers/UserSettings.swift
// Arcana
//

import Foundation
import Combine
import OSLog

@MainActor
class UserSettings: ObservableObject {
    static let shared = UserSettings()
    
    // MARK: - Published Settings
    
    // Privacy & Security
    @Published var webResearchEnabled: Bool = true
    @Published var communitySearchEnabled: Bool = true
    @Published var privacyLevel: PrivacyLevel = .maximum
    
    // Web Research
    @Published var searchEnginePreference: SearchEnginePreference = .automatic
    @Published var customSearchEngines: [SearchEngine] = SearchEngine.allCases
    @Published var searchCacheEnabled: Bool = true
    
    // Performance & Storage
    @Published var cacheStorageLimit: StorageLimit = .standard50MB
    @Published var dataRetentionPeriod: RetentionPeriod = .thirtyDays
    @Published var performanceMode: PerformanceMode = .balanced
    
    // Interface
    @Published var theme: AppTheme = .auto
    @Published var animationsEnabled: Bool = true
    @Published var showConfidenceScores: Bool = true
    @Published var compactMode: Bool = false
    
    // UI Display Settings - ADDED for MainView compatibility
    @Published var showWelcomeTips: Bool = true
    @Published var showDetailsPanel: Bool = true
    @Published var showTimelineView: Bool = false
    @Published var showPerformanceMetrics: Bool = false
    
    // Advanced Settings
    @Published var debugMode: Bool = false
    @Published var developerMode: Bool = false
    @Published var experimentalFeatures: Bool = false
    
    // MARK: - Computed Properties
    
    var currentCacheUsage: String {
        return "32.4 MB" // Would be calculated dynamically
    }
    
    // MARK: - Private Properties
    
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "UserSettings")
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSettings()
        setupAutoSave()
    }
    
    // MARK: - Initialization
    
    func initialize() async {
        logger.info("Initializing User Settings...")
        
        // Load settings from storage
        loadSettings()
        
        // Apply theme
        applyTheme()
        
        logger.info("User Settings initialized")
    }
    
    // MARK: - Settings Management
    
    func loadSettings() {
        // Privacy & Security
        webResearchEnabled = userDefaults.bool(forKey: "webResearchEnabled", defaultValue: true)
        communitySearchEnabled = userDefaults.bool(forKey: "communitySearchEnabled", defaultValue: true)
        privacyLevel = PrivacyLevel(rawValue: userDefaults.string(forKey: "privacyLevel") ?? PrivacyLevel.maximum.rawValue) ?? .maximum
        
        // Web Research
        searchEnginePreference = SearchEnginePreference(rawValue: userDefaults.string(forKey: "searchEnginePreference") ?? SearchEnginePreference.automatic.rawValue) ?? .automatic
        searchCacheEnabled = userDefaults.bool(forKey: "searchCacheEnabled", defaultValue: true)
        
        // Performance & Storage
        cacheStorageLimit = StorageLimit(rawValue: userDefaults.string(forKey: "cacheStorageLimit") ?? StorageLimit.standard50MB.rawValue) ?? .standard50MB
        dataRetentionPeriod = RetentionPeriod(rawValue: userDefaults.string(forKey: "dataRetentionPeriod") ?? RetentionPeriod.thirtyDays.rawValue) ?? .thirtyDays
        performanceMode = PerformanceMode(rawValue: userDefaults.string(forKey: "performanceMode") ?? PerformanceMode.balanced.rawValue) ?? .balanced
        
        // Interface
        theme = AppTheme(rawValue: userDefaults.string(forKey: "theme") ?? AppTheme.auto.rawValue) ?? .auto
        animationsEnabled = userDefaults.bool(forKey: "animationsEnabled", defaultValue: true)
        showConfidenceScores = userDefaults.bool(forKey: "showConfidenceScores", defaultValue: true)
        compactMode = userDefaults.bool(forKey: "compactMode", defaultValue: false)
        
        // UI Display Settings - ADDED
        showWelcomeTips = userDefaults.bool(forKey: "showWelcomeTips", defaultValue: true)
        showDetailsPanel = userDefaults.bool(forKey: "showDetailsPanel", defaultValue: true)
        showTimelineView = userDefaults.bool(forKey: "showTimelineView", defaultValue: false)
        showPerformanceMetrics = userDefaults.bool(forKey: "showPerformanceMetrics", defaultValue: false)
        
        // Advanced Settings
        debugMode = userDefaults.bool(forKey: "debugMode", defaultValue: false)
        developerMode = userDefaults.bool(forKey: "developerMode", defaultValue: false)
        experimentalFeatures = userDefaults.bool(forKey: "experimentalFeatures", defaultValue: false)
        
        logger.debug("Settings loaded from UserDefaults")
    }
    
    func saveSettings() {
        // Privacy & Security
        userDefaults.set(webResearchEnabled, forKey: "webResearchEnabled")
        userDefaults.set(communitySearchEnabled, forKey: "communitySearchEnabled")
        userDefaults.set(privacyLevel.rawValue, forKey: "privacyLevel")
        
        // Web Research
        userDefaults.set(searchEnginePreference.rawValue, forKey: "searchEnginePreference")
        userDefaults.set(searchCacheEnabled, forKey: "searchCacheEnabled")
        
        // Performance & Storage
        userDefaults.set(cacheStorageLimit.rawValue, forKey: "cacheStorageLimit")
        userDefaults.set(dataRetentionPeriod.rawValue, forKey: "dataRetentionPeriod")
        userDefaults.set(performanceMode.rawValue, forKey: "performanceMode")
        
        // Interface
        userDefaults.set(theme.rawValue, forKey: "theme")
        userDefaults.set(animationsEnabled, forKey: "animationsEnabled")
        userDefaults.set(showConfidenceScores, forKey: "showConfidenceScores")
        userDefaults.set(compactMode, forKey: "compactMode")
        
        // UI Display Settings - ADDED
        userDefaults.set(showWelcomeTips, forKey: "showWelcomeTips")
        userDefaults.set(showDetailsPanel, forKey: "showDetailsPanel")
        userDefaults.set(showTimelineView, forKey: "showTimelineView")
        userDefaults.set(showPerformanceMetrics, forKey: "showPerformanceMetrics")
        
        // Advanced Settings
        userDefaults.set(debugMode, forKey: "debugMode")
        userDefaults.set(developerMode, forKey: "developerMode")
        userDefaults.set(experimentalFeatures, forKey: "experimentalFeatures")
        
        logger.debug("Settings saved to UserDefaults")
    }
    
    // MARK: - Reset Functions
    
    func resetToDefaults() {
        logger.info("Resetting settings to defaults")
        
        // Reset all settings to defaults
        webResearchEnabled = true
        communitySearchEnabled = true
        privacyLevel = .maximum
        searchEnginePreference = .automatic
        searchCacheEnabled = true
        cacheStorageLimit = .standard50MB
        dataRetentionPeriod = .thirtyDays
        performanceMode = .balanced
        theme = .auto
        animationsEnabled = true
        showConfidenceScores = true
        compactMode = false
        showWelcomeTips = true
        showDetailsPanel = true
        showTimelineView = false
        showPerformanceMetrics = false
        debugMode = false
        developerMode = false
        experimentalFeatures = false
        
        saveSettings()
    }
    
    func clearCache() {
        logger.info("Clearing application cache")
        // Implementation would clear application cache
    }
    
    func exportSettings() -> Data? {
        let settingsDict: [String: Any] = [
            "webResearchEnabled": webResearchEnabled,
            "communitySearchEnabled": communitySearchEnabled,
            "privacyLevel": privacyLevel.rawValue,
            "searchEnginePreference": searchEnginePreference.rawValue,
            "searchCacheEnabled": searchCacheEnabled,
            "cacheStorageLimit": cacheStorageLimit.rawValue,
            "dataRetentionPeriod": dataRetentionPeriod.rawValue,
            "performanceMode": performanceMode.rawValue,
            "theme": theme.rawValue,
            "animationsEnabled": animationsEnabled,
            "showConfidenceScores": showConfidenceScores,
            "compactMode": compactMode,
            "showWelcomeTips": showWelcomeTips,
            "showDetailsPanel": showDetailsPanel,
            "showTimelineView": showTimelineView,
            "showPerformanceMetrics": showPerformanceMetrics
        ]
        
        return try? JSONSerialization.data(withJSONObject: settingsDict, options: .prettyPrinted)
    }
    
    // MARK: - Theme Management
    
    private func applyTheme() {
        // Apply theme changes to the app
        switch theme {
        case .auto:
            // Follow system theme
            break
        case .light:
            // Force light theme
            break
        case .dark:
            // Force dark theme
            break
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAutoSave() {
        // Auto-save when any setting changes
        let publishers = [
            $webResearchEnabled.eraseToAnyPublisher(),
            $communitySearchEnabled.eraseToAnyPublisher(),
            $privacyLevel.eraseToAnyPublisher(),
            $searchEnginePreference.eraseToAnyPublisher(),
            $searchCacheEnabled.eraseToAnyPublisher(),
            $cacheStorageLimit.eraseToAnyPublisher(),
            $dataRetentionPeriod.eraseToAnyPublisher(),
            $performanceMode.eraseToAnyPublisher(),
            $theme.eraseToAnyPublisher(),
            $animationsEnabled.eraseToAnyPublisher(),
            $showConfidenceScores.eraseToAnyPublisher(),
            $compactMode.eraseToAnyPublisher(),
            $showWelcomeTips.eraseToAnyPublisher(),
            $showDetailsPanel.eraseToAnyPublisher(),
            $showTimelineView.eraseToAnyPublisher(),
            $showPerformanceMetrics.eraseToAnyPublisher(),
            $debugMode.eraseToAnyPublisher(),
            $developerMode.eraseToAnyPublisher(),
            $experimentalFeatures.eraseToAnyPublisher()
        ]
        
        Publishers.MergeMany(publishers)
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveSettings()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UserDefaults Extension

extension UserDefaults {
    func bool(forKey key: String, defaultValue: Bool) -> Bool {
        if object(forKey: key) == nil {
            return defaultValue
        }
        return bool(forKey: key)
    }
}
