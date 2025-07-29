//
// Core/PerformanceMonitor.swift
// Arcana
//

import Foundation
import OSLog

@MainActor
class PerformanceMonitor: ObservableObject {
    private let logger = Logger(subsystem: "com.spectrallabs.arcana", category: "PerformanceMonitor")
    
    @Published var currentMetrics = PerformanceMetrics()
    @Published var historicalData: [PerformanceSnapshot] = []
    @Published var alerts: [PerformanceAlert] = []
    
    private var monitoringTimer: Timer?
    
    func startMonitoring() {
        logger.info("Starting performance monitoring...")
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.collectMetrics()
            }
        }
    }
    
    func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        logger.info("Performance monitoring stopped")
    }
    
    func collectMetrics() async {
        let metrics = PerformanceMetrics(
            cpuUsage: getCurrentCPUUsage(),
            memoryUsage: getCurrentMemoryUsage(),
            diskUsage: getCurrentDiskUsage(),
            networkUsage: 0, // Local processing only
            inferenceTime: getAverageInferenceTime(),
            uiResponseTime: 0.05, // Target 50ms
            batteryImpact: estimateBatteryImpact()
        )
        
        currentMetrics = metrics
        
        // Add to historical data
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            metrics: metrics
        )
        historicalData.append(snapshot)
        
        // Keep only last 100 snapshots
        if historicalData.count > 100 {
            historicalData.removeFirst()
        }
        
        // Check for performance alerts
        checkForAlerts(metrics)
    }
    
    private func getCurrentCPUUsage() -> Double {
        // Simulate CPU usage calculation
        return Double.random(in: 0.1...0.4) // 10-40% CPU usage
    }
    
    private func getCurrentMemoryUsage() -> Int64 {
        // Get actual memory usage
        let info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
    
    private func getCurrentDiskUsage() -> Int64 {
        // Calculate disk usage for app data
        do {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let resourceValues = try documentsPath.resourceValues(forKeys: [.fileSizeKey])
            return Int64(resourceValues.fileSize ?? 0)
        } catch {
            return 0
        }
    }
    
    private func getAverageInferenceTime() -> TimeInterval {
        // Would calculate from recent inference times
        return Double.random(in: 0.5...2.0) // 0.5-2.0 seconds
    }
    
    private func estimateBatteryImpact() -> Double {
        // Estimate battery impact based on CPU and memory usage
        let cpuImpact = currentMetrics.cpuUsage * 0.6
        let memoryImpact = Double(currentMetrics.memoryUsage) / 8_000_000_000 * 0.4 // Normalize to 8GB
        
        return min(1.0, cpuImpact + memoryImpact)
    }
    
    private func checkForAlerts(_ metrics: PerformanceMetrics) {
        var newAlerts: [PerformanceAlert] = []
        
        // Memory usage alert
        if metrics.memoryUsage > 6_000_000_000 { // 6GB
            newAlerts.append(PerformanceAlert(
                type: .highMemoryUsage,
                message: "High memory usage detected: \(formatBytes(metrics.memoryUsage))",
                severity: .warning
            ))
        }
        
        // CPU usage alert
        if metrics.cpuUsage > 0.8 { // 80%
            newAlerts.append(PerformanceAlert(
                type: .highCPUUsage,
                message: "High CPU usage: \(metrics.cpuUsage * 100, specifier: "%.1f")%",
                severity: .warning
            ))
        }
        
        // Inference time alert
        if metrics.inferenceTime > 5.0 { // 5 seconds
            newAlerts.append(PerformanceAlert(
                type: .slowInference,
                message: "Slow inference time: \(metrics.inferenceTime, specifier: "%.1f")s",
                severity: .info
            ))
        }
        
        // Update alerts (keep only recent ones)
        alerts.append(contentsOf: newAlerts)
        alerts = alerts.suffix(10).map { $0 } // Keep last 10 alerts
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: bytes)
    }
}

struct PerformanceSnapshot {
    let timestamp: Date
    let metrics: PerformanceMetrics
}

struct PerformanceAlert: Identifiable {
    let id = UUID()
    let type: AlertType
    let message: String
    let severity: AlertSeverity
    let timestamp = Date()
    
    enum AlertType {
        case highMemoryUsage
        case highCPUUsage
        case slowInference
        case diskSpaceLow
    }
    
    enum AlertSeverity {
        case info
        case warning
        case critical
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
}

// MARK: - C Interop for memory info

import Darwin

struct mach_task_basic_info {
    var virtual_size: mach_vm_size_t = 0
    var resident_size: mach_vm_size_t = 0
    var resident_size_max: mach_vm_size_t = 0
    var user_time: time_value_t = time_value_t()
    var system_time: time_value_t = time_value_t()
    var policy: policy_t = 0
    var suspend_count: integer_t = 0
}
