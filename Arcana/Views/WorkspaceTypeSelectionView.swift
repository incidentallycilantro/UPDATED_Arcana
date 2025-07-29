//
// Views/WorkspaceTypeSelectionView.swift
// Arcana
//

import SwiftUI

struct WorkspaceTypeSelectionView: View {
    @Binding var selectedType: WorkspaceType
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Workspace Type")
                .font(.headline)
            
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(WorkspaceType.allCases, id: \.self) { type in
                    WorkspaceTypeCard(
                        type: type,
                        isSelected: selectedType == type
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedType = type
                        }
                    }
                }
            }
        }
    }
}

struct WorkspaceTypeCard: View {
    let type: WorkspaceType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isSelected ? type.color : .secondary)
                
                VStack(spacing: 4) {
                    Text(type.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? type.color.opacity(0.1) : .quaternary)
                    .stroke(isSelected ? type.color : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

extension WorkspaceType {
    var description: String {
        switch self {
        case .general:
            return "General purpose conversations and assistance"
        case .code:
            return "Programming, debugging, and software development"
        case .creative:
            return "Writing, brainstorming, and creative projects"
        case .research:
            return "Analysis, research, and data exploration"
        }
    }
}
