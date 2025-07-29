//
// Views/ThreadListView.swift
// Arcana
//

import SwiftUI

struct ThreadListView: View {
    @EnvironmentObject private var threadManager: ThreadManager
    @EnvironmentObject private var workspaceManager: WorkspaceManager
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("All Threads")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(filteredThreads.count) threads")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            
            // Thread List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(filteredThreads) { thread in
                        ThreadRowView(thread: thread)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .searchable(text: $searchText, prompt: "Search threads")
    }
    
    private var filteredThreads: [ChatThread] {
        let threads = threadManager.threads.filter { $0.status == .active }
        
        if searchText.isEmpty {
            return threads.sorted { $0.updatedAt > $1.updatedAt }
        } else {
            return threadManager.searchThreads(searchText).sorted { $0.updatedAt > $1.updatedAt }
        }
    }
}

struct ThreadRowView: View {
    let thread: ChatThread
    @EnvironmentObject private var threadManager: ThreadManager
    
    var body: some View {
        Button {
            threadManager.selectThread(thread)
        } label: {
            HStack(spacing: 16) {
                // Thread Icon
                Circle()
                    .fill(thread.workspaceType.color.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: thread.workspaceType.icon)
                            .foregroundStyle(thread.workspaceType.color)
                    }
                
                // Thread Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(thread.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        if threadManager.currentThread?.id == thread.id {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    
                    HStack {
                        Text(thread.workspaceType.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(thread.workspaceType.color.opacity(0.2))
                            .foregroundColor(thread.workspaceType.color)
                            .clipShape(Capsule())
                        
                        Text("•")
                            .foregroundStyle(.tertiary)
                        
                        Text("\(thread.messageCount) messages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if thread.averageConfidence > 0 {
                            Text("•")
                                .foregroundStyle(.tertiary)
                            
                            Text("\(thread.averageConfidence, specifier: "%.0%%") avg confidence")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(thread.updatedAt, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    if let lastMessage = thread.lastMessage {
                        Text(lastMessage.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(threadManager.currentThread?.id == thread.id ? .selection.opacity(0.3) : .quaternary)
            )
        }
        .buttonStyle(.plain)
    }
}
