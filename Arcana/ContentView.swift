//
// App/ContentView.swift
// Arcana
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var prismEngine: PRISMEngine
    @EnvironmentObject private var workspaceManager: WorkspaceManager
    @EnvironmentObject private var threadManager: ThreadManager
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var selectedSidebarItem: SidebarItem = .workspaces
    @State private var showingNewWorkspaceSheet = false
    @State private var showingSettings = false
    @State private var showingPerformanceDashboard = false
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            FluidSidebar(
                selectedItem: $selectedSidebarItem,
                onNewWorkspace: { showingNewWorkspaceSheet = true },
                onShowSettings: { showingSettings = true },
                onShowPerformance: { showingPerformanceDashboard = true }
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } content: {
            // Main Content Area
            MainContentView(selectedSidebarItem: selectedSidebarItem)
                .navigationSplitViewColumnWidth(min: 400, ideal: 600, max: 800)
        } detail: {
            // Detail/Chat Area
            ChatView()
                .navigationSplitViewColumnWidth(min: 300, ideal: 500)
        }
        .navigationSplitViewStyle(.balanced)
        .sheet(isPresented: $showingNewWorkspaceSheet) {
            NewWorkspaceSheet()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingPerformanceDashboard) {
            PerformanceDashboard()
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        // Keyboard shortcuts are handled by ArcanaCommands
    }
}

struct MainContentView: View {
    let selectedSidebarItem: SidebarItem
    
    @EnvironmentObject private var workspaceManager: WorkspaceManager
    @EnvironmentObject private var threadManager: ThreadManager
    
    var body: some View {
        Group {
            switch selectedSidebarItem {
            case .workspaces:
                WorkspaceListView()
            case .threads:
                ThreadListView()
            case .timeline:
                TimelineView()
            case .performance:
                PerformanceDashboard()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
