//
// Views/NewWorkspaceSheet.swift
// Arcana
//

import SwiftUI

struct NewWorkspaceSheet: View {
    @EnvironmentObject private var workspaceManager: WorkspaceManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var workspaceName = ""
    @State private var workspaceDescription = ""
    @State private var selectedType: WorkspaceType = .general
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 48))
                        .foregroundStyle(.linearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                    
                    Text("Create New Workspace")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Choose a workspace type that matches your intended use")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Workspace Type Selection
                WorkspaceTypeSelectionView(selectedType: $selectedType)
                
                // Configuration
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workspace Name")
                            .font(.headline)
                        
                        TextField("Enter workspace name", text: $workspaceName)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description (Optional)")
                            .font(.headline)
                        
                        TextField("Describe this workspace", text: $workspaceDescription, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                    }
                }
                
                Spacer()
            }
            .padding(24)
            .frame(width: 600, height: 500)
            .navigationTitle("New Workspace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createWorkspace()
                    }
                    .disabled(workspaceName.isEmpty || isCreating)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private func createWorkspace() {
        guard !workspaceName.isEmpty else { return }
        
        isCreating = true
        
        Task {
            do {
                _ = try await workspaceManager.createWorkspace(
                    name: workspaceName,
                    type: selectedType,
                    description: workspaceDescription
                )
                
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                }
                // Handle error
            }
        }
    }
}
