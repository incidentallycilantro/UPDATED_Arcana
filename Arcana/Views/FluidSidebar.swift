//
// Views/FluidSidebar.swift
// Arcana
//

import SwiftUI

struct FluidSidebar: View {
    @Binding var selectedItem: SidebarItem
    let onNewWorkspace: () -> Void
    let onShowSettings: () -> Void
    let onShowPerformance: () -> Void
    
    @EnvironmentObject private var workspaceManager: WorkspaceManager
    @EnvironmentObject private var threadManager: ThreadManager
    @EnvironmentObject private var prismEngine: PRISMEngine
    @EnvironmentObject private var userSettings: UserSettings
    
    @State private var hoveredItem: SidebarItem?
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            sidebarHeader
            
            // Navigation Items
            ScrollView {
                LazyVStack(spacing: 4) {
                    // Main Navigation
                    navigationSection
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Workspaces
                    workspacesSection
                    
                    Divider()
                        .padding(.vertical, 8)
                    
                    // Recent Threads
                    recentThreadsSection
                }
                .padding(.horizontal, 12)
            }
            
            Spacer()
            
            // Status Footer
            statusFooter
        }
        .background(.ultraThinMaterial)
        .searchable(text: $searchText, placement: .sidebar)
    }
    
    private var sidebarHeader: some View {
        VStack(spacing: 12) {
            HStack {
                // App Icon
                Image(systemName: "brain.head.profile")
                    .font(.title2)
                    .foregroundStyle(.linearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                
                Text("Arcana")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // New Workspace Button
                Button(action: onNewWorkspace) {
                    Image(systemName: "plus")
                        .font(.caption)
                        .padding(6)
                        .background(.quaternary, in: Circle())
                }
                .buttonStyle(.plain)
                .help("New Workspace (⌘N)")
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
    }
    
    private var navigationSection: some View {
        VStack(spacing: 2) {
            ForEach(SidebarItem.allCases, id: \.self) { item in
                SidebarItemView(
                    item: item,
                    isSelected: selectedItem == item,
                    isHovered: hoveredItem == item
                ) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedItem = item
                    }
                }
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        hoveredItem = hovering ? item : nil
                    }
                }
            }
        }
    }
    
    private var workspacesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Workspaces")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(workspaceManager.workspaces.count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            
            ForEach(filteredWorkspaces) { workspace in
                WorkspaceItemView(
                    workspace: workspace,
                    isSelected: workspaceManager.currentWorkspace?.id == workspace.id
                ) {
                    workspaceManager.selectWorkspace(workspace)
                }
            }
        }
    }
    
    private var recentThreadsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Recent Threads")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(threadManager.threads.count)")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.quaternary, in: Capsule())
            }
            
            ForEach(recentThreads.prefix(5), id: \.id) { thread in
                ThreadItemView(
                    thread: thread,
                    isSelected: threadManager.currentThread?.id == thread.id
                ) {
                    threadManager.selectThread(thread)
                }
            }
        }
    }
    
    private var statusFooter: some View {
        VStack(spacing: 8) {
            // PRISM Status
            HStack {
                Circle()
                    .fill(prismEngine.isInitialized ? .green : .orange)
                    .frame(width: 8, height: 8)
                
                Text("PRISM")
                    .font(.caption2)
                    .fontWeight(.medium)
                
                Spacer()
                
                if prismEngine.isProcessing {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 12, height: 12)
                } else {
                    Text("\(prismEngine.confidence, specifier: "%.0%%")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Settings Button
            HStack {
                Button("Settings", systemImage: "gearshape") {
                    onShowSettings()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Performance", systemImage: "chart.line.uptrend.xyaxis") {
                    onShowPerformance()
                }
                .buttonStyle(.plain)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    private var filteredWorkspaces: [Project] {
        if searchText.isEmpty {
            return workspaceManager.workspaces
        } else {
            return workspaceManager.searchWorkspaces(searchText)
        }
    }
    
    private var recentThreads: [ChatThread] {
        return threadManager.threads
            .filter { $0.status == .active }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
}

// MARK: - Supporting Views

struct SidebarItemView: View {
    let item: SidebarItem
    let isSelected: Bool
    let isHovered: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 16)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                Text(item.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? .selection : (isHovered ? .quaternary : .clear))
            )
        }
        .buttonStyle(.plain)
    }
}

struct WorkspaceItemView: View {
    let workspace: Project
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: workspace.workspaceType.icon)
                    .font(.system(size: 12))
                    .foregroundStyle(workspace.workspaceType.color)
                    .frame(width: 14)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(workspace.displayName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("\(workspace.threadCount) threads")
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? .selection.opacity(0.3) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

struct ThreadItemView: View {
    let thread: ChatThread
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle()
                    .fill(thread.workspaceType.color.opacity(0.3))
                    .frame(width: 8, height: 8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(thread.title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Text("\(thread.messageCount) messages")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(isSelected ? .selection.opacity(0.2) : .clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Supporting Types

enum SidebarItem: String, CaseIterable {
    case workspaces = "workspaces"
    case threads = "threads"
    case timeline = "timeline"
    case performance = "performance"
    
    var displayName: String {
        switch self {
        case .workspaces: return "Workspaces"
        case .threads: return "All Threads"
        case .timeline: return "Timeline"
        case .performance: return "Performance"
        }
    }
    
    var icon: String {
        switch self {
        case .workspaces: return "folder"
        case .threads: return "bubble.left.and.bubble.right"
        case .timeline: return "clock"
        case .performance: return "chart.bar"
        }
    }
}
