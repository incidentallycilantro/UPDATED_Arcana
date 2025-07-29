//
// MainView.swift
// Arcana
//
// Revolutionary three-pane adaptive layout with Claude Desktop aesthetics
// Provides seamless workspace management with Gentler Streak inspired animations
//

import SwiftUI

// MARK: - Main View

/// Revolutionary main interface that adapts intelligently to user workflow
/// Features three-pane layout with magical UX elements and sophisticated animations
struct MainView: View {
    
    // MARK: - Environment & State
    
    @StateObject private var workspaceManager = WorkspaceManager.shared
    @StateObject private var threadManager = ThreadManager.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @StateObject private var userSettings = UserSettings.shared
    
    @State private var selectedSidebarItem: SidebarItem = .workspaces
    @State private var showingNewWorkspaceSheet = false
    @State private var showingSettingsSheet = false
    @State private var showingPerformanceDashboard = false
    @State private var sidebarWidth: CGFloat = 280
    @State private var detailsWidth: CGFloat = 320
    @State private var isFullScreen = false
    
    // Window management
    @State private var windowFrame: CGRect = .zero
    @State private var isWindowFocused = true
    
    // Animation state
    @State private var layoutTransition: AnyTransition = .opacity
    @State private var animationNamespace = Namespace().wrappedValue
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // MARK: - Sidebar
                sidebarView
                    .frame(width: shouldShowSidebar ? sidebarWidth : 0)
                    .opacity(shouldShowSidebar ? 1 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: shouldShowSidebar)
                
                // MARK: - Main Content
                mainContentView
                    .frame(maxWidth: .infinity)
                    .background(Color(NSColor.controlBackgroundColor))
                
                // MARK: - Details Panel
                if shouldShowDetailsPanel {
                    detailsPanelView
                        .frame(width: detailsWidth)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.9), value: shouldShowDetailsPanel)
                }
            }
            .background(Color(NSColor.windowBackgroundColor))
            .onAppear {
                windowFrame = geometry.frame(in: .global)
                setupKeyboardShortcuts()
                setupWindowObservation()
            }
            .onChange(of: geometry.size) { _, newSize in
                adaptToWindowSize(newSize)
            }
        }
        .sheet(isPresented: $showingNewWorkspaceSheet) {
            NewWorkspaceSheet()
                .environmentObject(workspaceManager)
        }
        .sheet(isPresented: $showingSettingsSheet) {
            SettingsView()
                .environmentObject(userSettings)
        }
        .sheet(isPresented: $showingPerformanceDashboard) {
            PerformanceDashboard()
                .environmentObject(performanceMonitor)
        }
        .environmentObject(workspaceManager)
        .environmentObject(threadManager)
        .environmentObject(performanceMonitor)
        .environmentObject(userSettings)
    }
    
    // MARK: - Sidebar View
    
    private var sidebarView: some View {
        FluidSidebar(
            selectedItem: $selectedSidebarItem,
            showingNewWorkspaceSheet: $showingNewWorkspaceSheet,
            showingSettingsSheet: $showingSettingsSheet
        )
        .background(Color(NSColor.sidebarBackgroundColor))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .trailing
        )
    }
    
    // MARK: - Main Content View
    
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Top toolbar
            topToolbarView
                .background(Color(NSColor.controlBackgroundColor))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(NSColor.separatorColor)),
                    alignment: .bottom
                )
            
            // Main content area
            ZStack {
                if let currentWorkspace = workspaceManager.currentWorkspace {
                    // Chat interface for active workspace
                    ChatView(workspace: currentWorkspace)
                        .id(currentWorkspace.id)
                        .transition(layoutTransition)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentWorkspace.id)
                } else {
                    // Welcome/empty state
                    welcomeView
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Top Toolbar
    
    private var topToolbarView: some View {
        HStack {
            // Workspace info
            if let currentWorkspace = workspaceManager.currentWorkspace {
                HStack(spacing: 12) {
                    // Workspace icon with subtle animation
                    Image(systemName: currentWorkspace.workspaceType.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(currentWorkspace.workspaceType.color)
                        .matchedGeometryEffect(id: "workspace-icon-\(currentWorkspace.id)", in: animationNamespace)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(currentWorkspace.displayName)
                            .font(.headline)
                            .lineLimit(1)
                        
                        if !currentWorkspace.description.isEmpty {
                            Text(currentWorkspace.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .padding(.leading, 16)
            }
            
            Spacer()
            
            // Toolbar buttons
            HStack(spacing: 8) {
                // Performance indicator
                performanceIndicatorView
                
                // Timeline toggle
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        toggleTimelineView()
                    }
                } label: {
                    Image(systemName: "timeline.selection")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(ToolbarButtonStyle())
                .help("Toggle Timeline View (⌘D)")
                
                // New thread
                Button {
                    createNewThread()
                } label: {
                    Image(systemName: "plus.message")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                }
                .buttonStyle(ToolbarButtonStyle())
                .help("New Thread (⌘T)")
                
                // Settings
                Button {
                    showingSettingsSheet = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(ToolbarButtonStyle())
                .help("Settings (⌘,)")
            }
            .padding(.trailing, 16)
        }
        .frame(height: 48)
    }
    
    // MARK: - Performance Indicator
    
    private var performanceIndicatorView: some View {
        Button {
            showingPerformanceDashboard = true
        } label: {
            HStack(spacing: 4) {
                Circle()
                    .fill(performanceIndicatorColor)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 1), value: performanceMonitor.systemHealth)
                
                if userSettings.showPerformanceMetrics {
                    Text(performanceIndicatorText)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
        .help("System Performance: \(performanceMonitor.systemHealth.displayName)")
    }
    
    private var performanceIndicatorColor: Color {
        switch performanceMonitor.systemHealth {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .orange
        case .poor: return .red
        }
    }
    
    private var performanceIndicatorText: String {
        let metrics = performanceMonitor.currentMetrics
        return String(format: "%.0f%% CPU", metrics.cpuUsage)
    }
    
    // MARK: - Welcome View
    
    private var welcomeView: some View {
        VStack(spacing: 32) {
            // Hero section
            VStack(spacing: 16) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 64, weight: .ultraLight))
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .symbolEffect(.pulse, options: .repeating)
                
                VStack(spacing: 8) {
                    Text("Welcome to Arcana")
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                    
                    Text("Your revolutionary AI assistant with privacy-first intelligence")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Quick actions
            VStack(spacing: 16) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
                    ForEach(WorkspaceType.allCases) { workspaceType in
                        QuickActionCard(
                            title: workspaceType.displayName,
                            icon: workspaceType.icon,
                            color: workspaceType.color,
                            description: getWorkspaceDescription(workspaceType)
                        ) {
                            createWorkspace(type: workspaceType)
                        }
                    }
                }
            }
            .padding(.horizontal, 40)
            
            // Tips
            if userSettings.showWelcomeTips {
                tipsView
            }
        }
        .frame(maxWidth: 600)
        .padding(40)
    }
    
    // MARK: - Tips View
    
    private var tipsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pro Tips")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                TipRow(icon: "command", text: "Use ⌘N to create a new workspace")
                TipRow(icon: "command", text: "Use ⌘T to start a new conversation thread")
                TipRow(icon: "command", text: "Use ⌘F to search your conversations")
                TipRow(icon: "sparkles", text: "Try different workspace types for optimized responses")
            }
        }
        .padding(20)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
    
    // MARK: - Details Panel View
    
    private var detailsPanelView: some View {
        VStack(spacing: 0) {
            // Details header
            HStack {
                Text("Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        hideDetailsPanel()
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(NSColor.separatorColor)),
                alignment: .bottom
            )
            
            // Details content
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let currentWorkspace = workspaceManager.currentWorkspace {
                        WorkspaceDetailsSection(workspace: currentWorkspace)
                        
                        if let currentThread = threadManager.currentThread {
                            ThreadDetailsSection(thread: currentThread)
                        }
                        
                        PerformanceDetailsSection()
                    }
                }
                .padding(16)
            }
        }
        .background(Color(NSColor.sidebarBackgroundColor))
        .overlay(
            Rectangle()
                .frame(width: 1)
                .foregroundColor(Color(NSColor.separatorColor)),
            alignment: .leading
        )
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowSidebar: Bool {
        !isFullScreen && windowFrame.width > 800
    }
    
    private var shouldShowDetailsPanel: Bool {
        !isFullScreen && windowFrame.width > 1200 && userSettings.showDetailsPanel
    }
    
    // MARK: - Methods
    
    private func setupKeyboardShortcuts() {
        // Keyboard shortcuts are handled at the app level
        // This is where we would register shortcuts if needed
    }
    
    private func setupWindowObservation() {
        // Set up window state observation
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { _ in
            isWindowFocused = true
        }
        
        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: nil,
            queue: .main
        ) { _ in
            isWindowFocused = false
        }
    }
    
    private func adaptToWindowSize(_ size: CGSize) {
        windowFrame.size = size
        
        // Adapt sidebar width based on window size
        if size.width < 1000 {
            sidebarWidth = 240
            detailsWidth = 280
        } else if size.width < 1400 {
            sidebarWidth = 260
            detailsWidth = 300
        } else {
            sidebarWidth = 280
            detailsWidth = 320
        }
        
        // Update layout transition based on window size
        if size.width < 800 {
            layoutTransition = .slide
        } else {
            layoutTransition = .opacity.combined(with: .scale(scale: 0.98))
        }
    }
    
    private func createWorkspace(type: WorkspaceType) {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            let workspace = workspaceManager.createWorkspace(
                name: "\(type.displayName) Workspace",
                type: type,
                description: getWorkspaceDescription(type)
            )
            workspaceManager.selectWorkspace(workspace)
        }
    }
    
    private func getWorkspaceDescription(_ type: WorkspaceType) -> String {
        switch type {
        case .general:
            return "General conversations and assistance"
        case .code:
            return "Programming and development tasks"
        case .creative:
            return "Creative writing and brainstorming"
        case .research:
            return "Research and analysis projects"
        }
    }
    
    private func createNewThread() {
        guard let workspace = workspaceManager.currentWorkspace else { return }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            let thread = threadManager.createThread(in: workspace)
            threadManager.selectThread(thread)
        }
    }
    
    private func toggleTimelineView() {
        // Toggle timeline view implementation
        userSettings.showTimelineView.toggle()
    }
    
    private func hideDetailsPanel() {
        userSettings.showDetailsPanel = false
    }
}

// MARK: - Supporting Views

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let description: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(color)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isHovered ? color : Color(NSColor.separatorColor), lineWidth: isHovered ? 2 : 1)
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 16, height: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}

struct ToolbarButtonStyle: ButtonStyle {
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        isHovered ? Color(NSColor.controlBackgroundColor) : Color.clear
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovered = hovering
                }
            }
    }
}

struct WorkspaceDetailsSection: View {
    let workspace: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Workspace")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Name", value: workspace.displayName)
                DetailRow(label: "Type", value: workspace.workspaceType.displayName)
                DetailRow(label: "Threads", value: "\(workspace.threadCount)")
                DetailRow(label: "Created", value: workspace.creationDate.formatted(date: .abbreviated, time: .omitted))
                DetailRow(label: "Modified", value: workspace.lastActivity.formatted(.relative(presentation: .named)))
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ThreadDetailsSection: View {
    let thread: ChatThread
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Thread")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "Messages", value: "\(thread.messageCount)")
                DetailRow(label: "Started", value: thread.creationDate.formatted(.relative(presentation: .named)))
                DetailRow(label: "Status", value: thread.status.rawValue.capitalized)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct PerformanceDetailsSection: View {
    @EnvironmentObject private var performanceMonitor: PerformanceMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Performance")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                DetailRow(label: "System Health", value: performanceMonitor.systemHealth.displayName)
                DetailRow(label: "CPU Usage", value: String(format: "%.1f%%", performanceMonitor.currentMetrics.cpuUsage))
                DetailRow(label: "Memory", value: ByteCountFormatter.string(fromByteCount: performanceMonitor.currentMetrics.memoryUsage, countStyle: .memory))
                DetailRow(label: "Inference Time", value: String(format: "%.2fs", performanceMonitor.currentMetrics.inferenceTime))
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Preview

#Preview {
    MainView()
        .frame(width: 1200, height: 800)
}
