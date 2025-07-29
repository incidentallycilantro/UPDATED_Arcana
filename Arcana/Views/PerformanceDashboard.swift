//
// Views/PerformanceDashboard.swift
// Arcana
//

import SwiftUI
import Charts

struct PerformanceDashboard: View {
    @EnvironmentObject private var prismEngine: PRISMEngine
    @State private var selectedMetric: PerformanceMetric = .inference
    @State private var refreshTimer: Timer?
    @State private var performanceData: [PerformanceDataPoint] = []
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview Cards
                    overviewCards
                    
                    // Performance Chart
                    performanceChart
                    
                    // PRISM Engine Status
                    prismEngineStatus
                    
                    // Memory Statistics
                    memoryStatistics
                    
                    // Model Performance
                    modelPerformance
                }
                .padding(20)
            }
            .navigationTitle("Performance Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Refresh") {
                        refreshData()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .frame(width: 900, height: 700)
        .onAppear {
            startPerformanceMonitoring()
        }
        .onDisappear {
            stopPerformanceMonitoring()
        }
    }
    
    private var overviewCards: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            PerformanceCard(
                title: "Avg Response Time",
                value: "\(prismEngine.performanceMetrics.inferenceTime, specifier: "%.2f")s",
                trend: .down,
                color: .green
            )
            
            PerformanceCard(
                title: "Confidence Score",
                value: "\(prismEngine.confidence, specifier: "%.0f")%%",
                trend: .up,
                color: .blue
            )
            
            PerformanceCard(
                title: "Memory Usage",
                value: formatBytes(prismEngine.performanceMetrics.memoryUsage),
                trend: .stable,
                color: .orange
            )
            
            PerformanceCard(
                title: "CPU Usage",
                value: "\(prismEngine.performanceMetrics.cpuUsage, specifier: "%.1f")%%",
                trend: .stable,
                color: .purple
            )
        }
    }
    
    private var performanceChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Performance Metrics")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Picker("Metric", selection: $selectedMetric) {
                    ForEach(PerformanceMetric.allCases, id: \.self) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            
            Chart(performanceData) { dataPoint in
                LineMark(
                    x: .value("Time", dataPoint.timestamp),
                    y: .value("Value", dataPoint.value(for: selectedMetric))
                )
                .foregroundStyle(selectedMetric.color)
                .interpolationMethod(.catmullRom)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .minute, count: 5))
            }
        }
        .padding(20)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var prismEngineStatus: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PRISM Engine Status")
                .font(.title2)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatusCard(
                    title: "Engine Status",
                    value: prismEngine.isInitialized ? "Online" : "Offline",
                    color: prismEngine.isInitialized ? .green : .red
                )
                
                StatusCard(
                    title: "Processing",
                    value: prismEngine.isProcessing ? "Active" : "Idle",
                    color: prismEngine.isProcessing ? .orange : .green
                )
                
                StatusCard(
                    title: "Available Models",
                    value: "\(prismEngine.availableModels.count)",
                    color: .blue
                )
                
                StatusCard(
                    title: "Loaded Models",
                    value: "\(prismEngine.ensembleStatus.values.filter { $0 }.count)",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var memoryStatistics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Memory Statistics")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                MemoryBar(
                    title: "Total Memory",
                    used: prismEngine.performanceMetrics.memoryUsage,
                    total: 8_000_000_000, // 8GB
                    color: .blue
                )
                
                MemoryBar(
                    title: "Model Cache",
                    used: 2_000_000_000, // 2GB
                    total: 4_000_000_000, // 4GB
                    color: .green
                )
                
                MemoryBar(
                    title: "Response Cache",
                    used: 500_000_000, // 500MB
                    total: 1_000_000_000, // 1GB
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var modelPerformance: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Model Performance")
                .font(.title2)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ForEach(prismEngine.availableModels) { model in
                    ModelPerformanceRow(model: model)
                }
            }
        }
        .padding(20)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private func startPerformanceMonitoring() {
        refreshData()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            refreshData()
        }
    }
    
    private func stopPerformanceMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func refreshData() {
        let now = Date()
        let dataPoint = PerformanceDataPoint(
            timestamp: now,
            inferenceTime: prismEngine.performanceMetrics.inferenceTime,
            memoryUsage: Double(prismEngine.performanceMetrics.memoryUsage),
            cpuUsage: prismEngine.performanceMetrics.cpuUsage,
            confidence: prismEngine.confidence
        )
        
        performanceData.append(dataPoint)
        
        // Keep only last 50 data points
        if performanceData.count > 50 {
            performanceData.removeFirst()
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Supporting Views

struct PerformanceCard: View {
    let title: String
    let value: String
    let trend: Trend
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundStyle(trend.color)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .padding(16)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct StatusCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundStyle(color)
            }
            
            Spacer()
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

struct MemoryBar: View {
    let title: String
    let used: Int64
    let total: Int64
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(used) / Double(total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(formatBytes(used)) / \(formatBytes(total))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospaced()
            }
            
            ProgressView(value: percentage)
                .progressViewStyle(.linear)
                .tint(color)
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

struct ModelPerformanceRow: View {
    let model: ModelInfo
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    Text("v\(model.version)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.secondary.opacity(0.2))
                        .clipShape(Capsule())
                    
                    ForEach(model.capabilities.prefix(3), id: \.self) { capability in
                        Text(capability.displayName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Text("\(model.performance.tokensPerSecond, specifier: "%.0f") tok/s")
                        .font(.caption)
                        .monospaced()
                    
                    Circle()
                        .fill(model.isLoaded ? .green : .secondary)
                        .frame(width: 8, height: 8)
                }
                
                Text("\(model.performance.averageInferenceTime, specifier: "%.2f")s avg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospaced()
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Supporting Types

enum Trend {
    case up, down, stable
    
    var icon: String {
        switch self {
        case .up: return "arrow.up"
        case .down: return "arrow.down"
        case .stable: return "minus"
        }
    }
    
    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .stable: return .secondary
        }
    }
}

enum PerformanceMetric: String, CaseIterable {
    case inference = "inference"
    case memory = "memory"
    case cpu = "cpu"
    case confidence = "confidence"
    
    var displayName: String {
        switch self {
        case .inference: return "Inference Time"
        case .memory: return "Memory Usage"
        case .cpu: return "CPU Usage"
        case .confidence: return "Confidence"
        }
    }
    
    var color: Color {
        switch self {
        case .inference: return .green
        case .memory: return .orange
        case .cpu: return .purple
        case .confidence: return .blue
        }
    }
}

struct PerformanceDataPoint {
    let timestamp: Date
    let inferenceTime: TimeInterval
    let memoryUsage: Double
    let cpuUsage: Double
    let confidence: Double
    
    func value(for metric: PerformanceMetric) -> Double {
        switch metric {
        case .inference: return inferenceTime
        case .memory: return memoryUsage / 1_000_000_000 // Convert to GB
        case .cpu: return cpuUsage
        case .confidence: return confidence
        }
    }
}
