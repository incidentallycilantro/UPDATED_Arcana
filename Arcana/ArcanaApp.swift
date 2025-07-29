//
// App/ArcanaApp.swift
// Arcana
//

import SwiftUI
import OSLog

@main
struct ArcanaApp: App {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "App")
    
    @StateObject private var prismEngine = PRISMEngine()
    @StateObject private var workspaceManager = WorkspaceManager()
    @StateObject private var threadManager = ThreadManager()
    @StateObject private var userSettings = UserSettings.shared
    
    @State private var isInitialized = false
    @State private var initializationError: Error?
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isInitialized {
                    ContentView()
                        .environmentObject(prismEngine)
                        .environmentObject(workspaceManager)
                        .environmentObject(threadManager)
                        .environmentObject(userSettings)
                } else if let error = initializationError {
                    ErrorView(error: error) {
                        Task {
                            await initializeApp()
                        }
                    }
                } else {
                    LoadingView()
                }
            }
            .task {
                await initializeApp()
            }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            ArcanaCommands()
        }
    }
    
    private func initializeApp() async {
        logger.info("🚀 Initializing Arcana...")
        
        do {
            // Initialize core systems in order
            try await prismEngine.initialize()
            logger.info("✓ PRISM Engine initialized")
            
            try await workspaceManager.initialize()
            logger.info("✓ Workspace Manager initialized")
            
            try await threadManager.initialize()
            logger.info("✓ Thread Manager initialized")
            
            await userSettings.initialize()
            logger.info("✓ User Settings initialized")
            
            await MainActor.run {
                self.isInitialized = true
                self.initializationError = nil
            }
            
            logger.info("🎉 Arcana initialization complete!")
            
        } catch {
            logger.error("❌ Initialization failed: \(error.localizedDescription)")
            
            await MainActor.run {
                self.initializationError = error
                self.isInitialized = false
            }
        }
    }
}

struct LoadingView: View {
    @State private var progress: Double = 0.0
    @State private var loadingText = "Initializing PRISM Engine..."
    
    var body: some View {
        VStack(spacing: 30) {
            // App Logo/Icon
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
            
            VStack(spacing: 16) {
                Text("Arcana")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Revolutionary AI Assistant")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(.linear)
                    .frame(width: 300)
                
                Text(loadingText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .onAppear {
            startLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        let loadingSteps = [
            "Initializing PRISM Engine...",
            "Loading Quantum Memory...",
            "Starting Ensemble Orchestrator...",
            "Configuring Privacy Systems...",
            "Ready!"
        ]
        
        withAnimation(.easeInOut(duration: 0.5)) {
            progress = 0.2
        }
        
        for (index, step) in loadingSteps.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.8) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    loadingText = step
                    progress = Double(index + 1) / Double(loadingSteps.count)
                }
            }
        }
    }
}

struct ErrorView: View {
    let error: Error
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Initialization Failed")
                .font(.title)
                .fontWeight(.semibold)
            
            Text(error.localizedDescription)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Retry") {
                retry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}
