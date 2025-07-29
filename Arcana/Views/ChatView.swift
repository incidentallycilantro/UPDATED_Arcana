//
// Views/ChatView.swift
// Arcana
//

import SwiftUI

struct ChatView: View {
    @EnvironmentObject private var prismEngine: PRISMEngine
    @EnvironmentObject private var threadManager: ThreadManager
    @EnvironmentObject private var workspaceManager: WorkspaceManager
    
    @State private var messageText = ""
    @State private var isTyping = false
    @State private var showingTimeline = false
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat Header
            chatHeader
            
            Divider()
            
            // Messages Area
            messagesArea
            
            Divider()
            
            // Input Area
            inputArea
        }
        .background(.ultraThinMaterial)
        .navigationBarHidden(true)
    }
    
    private var chatHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                if let thread = threadManager.currentThread {
                    Text(thread.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack(spacing: 12) {
                        Label(thread.workspaceType.displayName, systemImage: thread.workspaceType.icon)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Label("\(thread.messageCount) messages", systemImage: "message")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if thread.averageConfidence > 0 {
                            Label("\(thread.averageConfidence, specifier: "%.0%%") confidence", systemImage: "checkmark.seal")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Text("No Thread Selected")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Select a thread or create a new workspace")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer()
            
            // Header Actions
            HStack(spacing: 8) {
                Button("Timeline", systemImage: "clock") {
                    showingTimeline.toggle()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Toggle Timeline View (⌘D)")
                
                if prismEngine.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 16) {
                    if let thread = threadManager.currentThread {
                        ForEach(thread.messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                    } else {
                        emptyStateView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .onChange(of: threadManager.currentThread?.messages.count) { _ in
                if let lastMessage = threadManager.currentThread?.messages.last {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.badge.waveform")
                .font(.system(size: 60))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 8) {
                Text("Start a Conversation")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Select a thread from the sidebar or create a new workspace to begin chatting with your AI assistant.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var inputArea: some View {
        VStack(spacing: 12) {
            // Quick Actions (if any)
            if !messageText.isEmpty && isTyping {
                quickActionsView
            }
            
            // Input Field
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Message Arcana...", text: $messageText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    .focused($isInputFocused)
                    .onSubmit {
                        sendMessage()
                    }
                    .onChange(of: messageText) { _ in
                        handleTyping()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(messageText.isEmpty ? .tertiary : .accent)
                }
                .buttonStyle(.plain)
                .disabled(messageText.isEmpty || prismEngine.isProcessing)
                .help("Send Message (⌘↩)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onAppear {
            isInputFocused = true
        }
    }
    
    private var quickActionsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(getQuickActions(), id: \.text) { action in
                    Button(action.text) {
                        messageText = action.text
                        sendMessage()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty,
              let currentThread = threadManager.currentThread,
              let currentWorkspace = workspaceManager.currentWorkspace else {
            return
        }
        
        let userMessage = ChatMessage(
            role: .user,
            content: messageText,
            threadId: currentThread.id,
            workspaceId: currentWorkspace.id
        )
        
        let messageCopy = messageText
        messageText = ""
        
        Task {
            do {
                // Add user message
                try await threadManager.addMessage(to: currentThread.id, message: userMessage)
                
                // Create conversation context
                let context = ConversationContext(
                    threadId: currentThread.id,
                    workspaceType: currentThread.workspaceType,
                    recentMessages: Array(currentThread.messages.suffix(10)),
                    semanticContext: extractSemanticContext(from: currentThread.messages),
                    temporalContext: TemporalContext()
                )
                
                // Generate AI response
                let response = try await prismEngine.processMessage(messageCopy, context: context)
                
                let assistantMessage = ChatMessage(
                    role: .assistant,
                    content: response.response,
                    threadId: currentThread.id,
                    workspaceId: currentWorkspace.id,
                    confidence: response.confidence,
                    processingTime: response.inferenceTime,
                    modelUsed: response.modelUsed
                )
                
                // Add assistant message
                try await threadManager.addMessage(to: currentThread.id, message: assistantMessage)
                
            } catch {
                // Handle error - could show error message
                print("Error sending message: \(error)")
            }
        }
    }
    
    private func handleTyping() {
        isTyping = !messageText.isEmpty
        
        // Get predictive suggestions if typing
        if isTyping, let currentThread = threadManager.currentThread {
            let context = ConversationContext(
                threadId: currentThread.id,
                workspaceType: currentThread.workspaceType,
                recentMessages: Array(currentThread.messages.suffix(5))
            )
            
            Task {
                let suggestions = await prismEngine.getRealtimeSuggestions(messageText, context: context)
                // Handle suggestions if needed
            }
        }
    }
    
    private func getQuickActions() -> [QuickAction] {
        guard let workspaceType = threadManager.currentThread?.workspaceType else {
            return []
        }
        
        switch workspaceType {
        case .code:
            return [
                QuickAction(text: "Explain this code"),
                QuickAction(text: "Optimize this function"),
                QuickAction(text: "Find bugs in this code"),
                QuickAction(text: "Write unit tests")
            ]
        case .creative:
            return [
                QuickAction(text: "Brainstorm ideas"),
                QuickAction(text: "Write a story"),
                QuickAction(text: "Create a design"),
                QuickAction(text: "Generate concepts")
            ]
        case .research:
            return [
                QuickAction(text: "Analyze this data"),
                QuickAction(text: "Find sources"),
                QuickAction(text: "Summarize findings"),
                QuickAction(text: "Compare options")
            ]
        case .general:
            return [
                QuickAction(text: "Help me understand"),
                QuickAction(text: "Explain simply"),
                QuickAction(text: "What should I do?"),
                QuickAction(text: "Give me advice")
            ]
        }
    }
    
    private func extractSemanticContext(from messages: [ChatMessage]) -> [String] {
        // Extract key terms and concepts from recent messages
        let recentContent = messages.suffix(5).map(\.content).joined(separator: " ")
        
        // Simple keyword extraction (would be more sophisticated in production)
        let words = recentContent.lowercased().components(separatedBy: .whitespacesAndNewlines)
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "is", "are", "was", "were", "be", "been", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should"])
        
        let keywords = words.filter { word in
            word.count > 3 && !stopWords.contains(word)
        }
        
        return Array(Set(keywords)).prefix(10).map { $0 }
    }
}

struct QuickAction {
    let text: String
}

struct MessageView: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.isFromUser {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                        .foregroundColor(.white)
                    
                    messageMetadata
                }
                .frame(maxWidth: .infinity * 0.7, alignment: .trailing)
                
                Circle()
                    .fill(.blue)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text("You")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
            } else {
                Circle()
                    .fill(.purple)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 16))
                    
                    messageMetadata
                }
                .frame(maxWidth: .infinity * 0.8, alignment: .leading)
                
                Spacer()
            }
        }
    }
    
    private var messageMetadata: some View {
        HStack(spacing: 8) {
            Text(message.displayTime)
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            if let confidence = message.confidence {
                Label("\(confidence, specifier: "%.0%%")", systemImage: "checkmark.seal")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if let processingTime = message.processingTime {
                Label("\(processingTime, specifier: "%.1f")s", systemImage: "clock")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            
            if let model = message.modelUsed {
                Text(model)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(.quaternary, in: Capsule())
            }
        }
    }
}
