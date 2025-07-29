//
// Views/SettingsView.swift
// Arcana
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedTab: SettingsTab = .privacy
    
    var body: some View {
        NavigationSplitView {
            // Settings Sidebar
            List(SettingsTab.allCases, id: \.self, selection: $selectedTab) { tab in
                Label(tab.displayName, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("Settings")
            .navigationSplitViewColumnWidth(200)
        } detail: {
            // Settings Content
            Group {
                switch selectedTab {
                case .privacy:
                    PrivacySettingsView()
                case .webResearch:
                    WebResearchSettingsView()
                case .performance:
                    PerformanceSettingsView()
                case .interface:
                    InterfaceSettingsView()
                case .advanced:
                    AdvancedSettingsView()
                }
            }
            .navigationTitle(selectedTab.displayName)
            .frame(minWidth: 500, minHeight: 400)
        }
        .frame(width: 800, height: 600)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Settings Tabs

enum SettingsTab: String, CaseIterable {
    case privacy = "privacy"
    case webResearch = "webResearch"
    case performance = "performance"
    case interface = "interface"
    case advanced = "advanced"
    
    var displayName: String {
        switch self {
        case .privacy: return "Privacy & Security"
        case .webResearch: return "Web Research"
        case .performance: return "Performance"
        case .interface: return "Interface"
        case .advanced: return "Advanced"
        }
    }
    
    var icon: String {
        switch self {
        case .privacy: return "lock.shield"
        case .webResearch: return "globe"
        case .performance: return "speedometer"
        case .interface: return "paintbrush"
        case .advanced: return "gearshape.2"
        }
    }
}

// MARK: - Privacy Settings

struct PrivacySettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        Form {
            Section("Data Privacy") {
                Toggle("Anonymous Web Research", isOn: $userSettings.webResearchEnabled)
                    .help("Enables secure web research through anonymous routing. Your searches cannot be traced back to you.")
                
                Toggle("Community Knowledge Sharing", isOn: $userSettings.communitySearchEnabled)
                    .help("Share anonymous search results to improve response speed for all users. No personal information is ever shared.")
                
                Picker("Privacy Level", selection: $userSettings.privacyLevel) {
                    ForEach(PrivacyLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(.segmented)
                .help("Choose your privacy preference level")
            }
            
            Section("Local Processing") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Zero-Knowledge Architecture")
                            .fontWeight(.medium)
                        Text("All AI processing happens locally on your device")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mathematical Privacy Guarantees")
                            .fontWeight(.medium)
                        Text("Cryptographically secure data protection")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
            }
            
            Section("Data Management") {
                HStack {
                    Text("Clear All Caches")
                    Spacer()
                    Button("Clear") {
                        userSettings.clearCache()
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    Text("Export User Data")
                    Spacer()
                    Button("Export") {
                        // Export user data
                    }
                    .buttonStyle(.bordered)
                }
                
                HStack {
                    Text("Reset Privacy Settings")
                    Spacer()
                    Button("Reset") {
                        // Reset only privacy settings
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Web Research Settings

struct WebResearchSettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        Form {
            Section("Search Engine Preference") {
                Picker("Default Strategy", selection: $userSettings.searchEnginePreference) {
                    ForEach(SearchEnginePreference.allCases, id: \.self) { preference in
                        Text(preference.displayName).tag(preference)
                    }
                }
                
                if userSettings.searchEnginePreference == .custom {
                    SearchEngineSelectionView()
                }
            }
            
            Section("Cache Settings") {
                Toggle("Enable Search Caching", isOn: $userSettings.searchCacheEnabled)
                    .help("Cache search results locally to improve performance and reduce API usage")
                
                HStack {
                    Text("Current Cache Usage:")
                    Spacer()
                    Text(userSettings.currentCacheUsage)
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
                
                Button("Clear Search Cache") {
                    userSettings.clearCache()
                }
                .buttonStyle(.bordered)
            }
            
            Section("Anonymous Routing") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Multi-VPN Routing")
                            .fontWeight(.medium)
                        Text("Searches routed through multiple VPN endpoints")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: userSettings.webResearchEnabled ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(userSettings.webResearchEnabled ? .green : .secondary)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Query Decomposition")
                            .fontWeight(.medium)
                        Text("Sensitive queries split across different engines")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: userSettings.webResearchEnabled ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundStyle(userSettings.webResearchEnabled ? .green : .secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct SearchEngineSelectionView: View {
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Search Engines")
                .font(.subheadline)
                .fontWeight(.medium)
            
            ForEach(SearchEngine.allCases, id: \.self) { engine in
                HStack {
                    Toggle(engine.displayName, isOn: binding(for: engine))
                    
                    Spacer()
                    
                    if engine.hasQuotaLimits {
                        Text("Limited")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    } else {
                        Text("Unlimited")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    private func binding(for engine: SearchEngine) -> Binding<Bool> {
        Binding(
            get: { userSettings.customSearchEngines.contains(engine) },
            set: { isSelected in
                if isSelected {
                    if !userSettings.customSearchEngines.contains(engine) {
                        userSettings.customSearchEngines.append(engine)
                    }
                } else {
                    userSettings.customSearchEngines.removeAll { $0 == engine }
                }
            }
        )
    }
}

// MARK: - Performance Settings

struct PerformanceSettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        Form {
            Section("Performance Mode") {
                Picker("Mode", selection: $userSettings.performanceMode) {
                    ForEach(PerformanceMode.allCases, id: \.self) { mode in
                        VStack(alignment: .leading) {
                            Text(mode.displayName)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("Storage Management") {
                Picker("Cache Storage Limit", selection: $userSettings.cacheStorageLimit) {
                    ForEach(StorageLimit.allCases, id: \.self) { limit in
                        Text(limit.displayName).tag(limit)
                    }
                }
                
                Picker("Data Retention Period", selection: $userSettings.dataRetentionPeriod) {
                    ForEach(RetentionPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                
                HStack {
                    Text("Current Storage Usage:")
                    Spacer()
                    Text(userSettings.currentCacheUsage)
                        .foregroundStyle(.secondary)
                        .monospaced()
                }
            }
            
            Section("Optimization") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apple Silicon Optimization")
                            .fontWeight(.medium)
                        Text("Metal Performance Shaders acceleration")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Quantum Memory System")
                            .fontWeight(.medium)
                        Text("Predictive model weight loading")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                
                Button("Optimize Now") {
                    // Run optimization
                }
                .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Interface Settings

struct InterfaceSettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    
    var body: some View {
        Form {
            Section("Appearance") {
                Picker("Theme", selection: $userSettings.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                
                Toggle("Enable Animations", isOn: $userSettings.animationsEnabled)
                    .help("Beautiful transitions and micro-interactions")
                
                Toggle("Compact Mode", isOn: $userSettings.compactMode)
                    .help("Reduce spacing and padding for more content")
            }
            
            Section("Information Display") {
                Toggle("Show Confidence Scores", isOn: $userSettings.showConfidenceScores)
                    .help("Display AI confidence ratings for responses")
            }
            
            Section("Design Philosophy") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Claude Desktop Aesthetics")
                            .fontWeight(.medium)
                        Text("Clean, professional interface design")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(.green)
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gentler Streak Animations")
                            .fontWeight(.medium)
                        Text("Sophisticated, fluid motion design")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: userSettings.animationsEnabled ? "checkmark.seal.fill" : "xmark.circle")
                        .foregroundStyle(userSettings.animationsEnabled ? .green : .secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Advanced Settings

struct AdvancedSettingsView: View {
    @EnvironmentObject private var userSettings: UserSettings
    @State private var showingResetAlert = false
    
    var body: some View {
        Form {
            Section("Developer Options") {
                Toggle("Debug Mode", isOn: $userSettings.debugMode)
                    .help("Enable debug logging and detailed diagnostics")
                
                Toggle("Developer Mode", isOn: $userSettings.developerMode)
                    .help("Show additional technical information and controls")
                
                Toggle("Experimental Features", isOn: $userSettings.experimentalFeatures)
                    .help("Enable cutting-edge features that may be unstable")
            }
            
            Section("Diagnostics") {
                Button("View System Diagnostics") {
                    // Show diagnostics
                }
                .buttonStyle(.bordered)
                
                Button("Export Debug Logs") {
                    // Export logs
                }
                .buttonStyle(.bordered)
                
                Button("Performance Benchmark") {
                    // Run benchmark
                }
                .buttonStyle(.bordered)
            }
            
            Section("Reset Options") {
                Button("Reset All Settings") {
                    showingResetAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
        }
        .formStyle(.grouped)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .alert("Reset All Settings", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                userSettings.resetToDefaults()
            }
        } message: {
            Text("This will reset all settings to their default values. This action cannot be undone.")
        }
    }
}
