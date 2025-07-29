//
// Views/TimelineView.swift
// Arcana
//

import SwiftUI

struct TimelineView: View {
    @EnvironmentObject private var threadManager: ThreadManager
    @State private var selectedTimeRange: TimeRange = .today
    @State private var selectedThread: ChatThread?
    
    var body: some View {
        VStack(spacing: 0) {
            // Timeline Header
            timelineHeader
            
            Divider()
            
            // Timeline Content
            ScrollView {
                LazyVStack(spacing: 20) {
                    ForEach(groupedThreads.keys.sorted(by: >), id: \.self) { date in
                        TimelineDaySection(
                            date: date,
                            threads: groupedThreads[date] ?? [],
                            selectedThread: $selectedThread
                        )
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Timeline")
    }
    
    private var timelineHeader: some View {
        HStack {
            Text("Conversation Timeline")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Time Range Picker
            Picker("Time Range", selection: $selectedTimeRange) {
                ForEach(TimeRange.allCases, id: \.self) { range in
                    Text(range.displayName).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var groupedThreads: [Date: [ChatThread]] {
        let filteredThreads = threadManager.threads.filter { thread in
            thread.status == .active && isInSelectedTimeRange(thread.updatedAt)
        }
        
        return Dictionary(grouping: filteredThreads) { thread in
            Calendar.current.startOfDay(for: thread.updatedAt)
        }
    }
    
    private func isInSelectedTimeRange(_ date: Date) -> Bool {
        let now = Date()
        
        switch selectedTimeRange {
        case .today:
            return Calendar.current.isDate(date, inSameDayAs: now)
        case .week:
            return date > Calendar.current.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            return date > Calendar.current.date(byAdding: .month, value: -1, to: now) ?? now
        case .all:
            return true
        }
    }
}

enum TimeRange: String, CaseIterable {
    case today = "today"
    case week = "week"
    case month = "month"
    case all = "all"
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .week: return "This Week"
        case .month: return "This Month"
        case .all: return "All Time"
        }
    }
}

struct TimelineDaySection: View {
    let date: Date
    let threads: [ChatThread]
    @Binding var selectedThread: ChatThread?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day Header
            HStack {
                Text(dateFormatter.string(from: date))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(threads.count) conversations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Timeline Items
            VStack(alignment: .leading, spacing: 12) {
                ForEach(threads.sorted { $0.updatedAt > $1.updatedAt }) { thread in
                    TimelineItem(
                        thread: thread,
                        isSelected: selectedThread?.id == thread.id
                    ) {
                        selectedThread = thread
                    }
                }
            }
        }
    }
}

struct TimelineItem: View {
    let thread: ChatThread
    let isSelected: Bool
    let action: () -> Void
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Timeline Connector
                VStack {
                    Circle()
                        .fill(thread.workspaceType.color)
                        .frame(width: 12, height: 12)
                    
                    Rectangle()
                        .fill(Color.separator)
                        .frame(width: 2)
                        .opacity(0.5)
                }
                .frame(height: 60)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(thread.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(timeFormatter.string(from: thread.updatedAt))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    
                    HStack {
                        Label(thread.workspaceType.displayName, systemImage: thread.workspaceType.icon)
                            .font(.caption)
                            .foregroundStyle(thread.workspaceType.color)
                        
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        
                        Text("\(thread.messageCount) messages")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if thread.averageConfidence > 0 {
                            Text("•")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            
                            Label("\(thread.averageConfidence, specifier: "%.0%%")", systemImage: "checkmark.seal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    if let lastMessage = thread.lastMessage {
                        Text(lastMessage.content)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? .selection.opacity(0.3) : .clear)
                    .stroke(isSelected ? thread.workspaceType.color : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
