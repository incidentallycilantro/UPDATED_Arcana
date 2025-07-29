//
// Views/WorkspaceListView.swift
// Arcana
//

import SwiftUI

struct WorkspaceListView: View {
    @EnvironmentObject private var workspaceManager: WorkspaceManager
    @State private var searchText = ""
    @State private var selectedWorkspaceType: WorkspaceType?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Workspaces")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(filteredWorkspaces.count) workspaces")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterChip(
                        title: "All",
                        isSelected: selectedWorkspaceType == nil
                    ) {
                        selectedWorkspaceType = nil
                    }
                    
                    ForEach(WorkspaceType.allCases, id: \.self) { type in
                        FilterChip(
                            title: type.displayName,
                            isSelected: selectedWorkspaceType == type,
                            color: type.color
                        ) {
                            selectedWorkspaceType = selectedWorkspaceType == type ? nil : type
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 16)
            
            // Workspace Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(filteredWorkspaces) { workspace in
                        WorkspaceCard(workspace: workspace)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .searchable(text: $searchText, prompt: "Search workspaces")
    }
    
    private var filteredWorkspaces: [Project] {
        var workspaces = workspaceManager.workspaces
        
        // Filter by type
        if let selectedType = selectedWorkspaceType {
            workspaces = workspaces.filter { $0.workspaceType == selectedType }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            workspaces = workspaces.filter { workspace in
                workspace.name.localizedCaseInsensitiveContains(searchText) ||
                workspace.description.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return workspaces.sorted { $0.updatedAt > $1.updatedAt }
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .blue
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color.opacity(0.2) : .quaternary)
                )
                .foregroundStyle(isSelected ? color : .secondary)
        }
        .buttonStyle(.plain)
    }
}

struct WorkspaceCard: View {
    let workspace: Project
    @EnvironmentObject private var workspaceManager: WorkspaceManager
    
    var body: some View {
        Button {
            workspaceManager.selectWorkspace(workspace)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: workspace.workspaceType.icon)
                        .font(.title2)
                        .foregroundStyle(workspace.workspaceType.color)
                    
                    Spacer()
                    
                    if workspaceManager.currentWorkspace?.id == workspace.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workspace.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    if !workspace.description.isEmpty {
                        Text(workspace.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
                
                Spacer()
                
                HStack {
                    Text("\(workspace.threadCount) threads")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    Spacer()
                    
                    Text(workspace.lastActivity, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(16)
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.quaternary)
                    .stroke(workspaceManager.currentWorkspace?.id == workspace.id ? workspace.workspaceType.color : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
