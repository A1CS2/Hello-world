//
//  PerformanceProfiler.swift
//  AI Coding Suite
//
//  Real-time performance monitoring and profiling tools
//

import SwiftUI
import Combine

class PerformanceProfiler: ObservableObject {
    static let shared = PerformanceProfiler()

    @Published var metrics: PerformanceMetrics = PerformanceMetrics()
    @Published var isMonitoring: Bool = false
    @Published var history: [PerformanceSnapshot] = []

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var startTime: Date?

    // MARK: - Monitoring Control

    func startMonitoring() {
        guard !isMonitoring else { return }

        isMonitoring = true
        startTime = Date()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.collectMetrics()
        }
    }

    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Metrics Collection

    private func collectMetrics() {
        let snapshot = PerformanceSnapshot(
            timestamp: Date(),
            memoryUsage: getMemoryUsage(),
            cpuUsage: getCPUUsage(),
            fps: getFPS(),
            networkActivity: getNetworkActivity(),
            activeThreads: getActiveThreads()
        )

        DispatchQueue.main.async {
            self.metrics.update(with: snapshot)
            self.history.append(snapshot)

            // Keep only last 300 snapshots (5 minutes at 1 sec intervals)
            if self.history.count > 300 {
                self.history.removeFirst()
            }
        }
    }

    private func getMemoryUsage() -> MemoryMetrics {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }

        if kerr == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024 / 1024
            return MemoryMetrics(
                used: usedMB,
                total: Double(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024,
                percentage: usedMB / (Double(ProcessInfo.processInfo.physicalMemory) / 1024 / 1024) * 100
            )
        }

        return MemoryMetrics(used: 0, total: 0, percentage: 0)
    }

    private func getCPUUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)

        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)

        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_INFO_MAX)

                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }

                guard infoResult == KERN_SUCCESS else { continue }

                let threadBasicInfo = threadInfo as thread_basic_info
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU += (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
                }
            }

            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        }

        return totalUsageOfCPU
    }

    private func getFPS() -> Double {
        // Simplified FPS calculation
        // In production, hook into display link
        return 60.0
    }

    private func getNetworkActivity() -> NetworkMetrics {
        // Simplified network metrics
        // In production, track URLSession activity
        return NetworkMetrics(
            requestsPerSecond: 0,
            bytesReceived: 0,
            bytesSent: 0
        )
    }

    private func getActiveThreads() -> Int {
        var threadsCount = mach_msg_type_number_t(0)
        var threadsList: thread_act_array_t?

        let result = task_threads(mach_task_self_, &threadsList, &threadsCount)

        if result == KERN_SUCCESS, let threadsList = threadsList {
            vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
            return Int(threadsCount)
        }

        return 0
    }

    // MARK: - Performance Markers

    private var markers: [String: Date] = [:]

    func startMarker(_ name: String) {
        markers[name] = Date()
    }

    func endMarker(_ name: String) -> TimeInterval? {
        guard let start = markers[name] else { return nil }
        let duration = Date().timeIntervalSince(start)
        markers.removeValue(forKey: name)

        // Log to console for debugging
        print("⏱️ Performance: \(name) took \(String(format: "%.2f", duration * 1000))ms")

        return duration
    }

    // MARK: - App Startup Metrics

    func recordAppLaunch() {
        guard let startTime = startTime else { return }
        let launchDuration = Date().timeIntervalSince(startTime)

        print("🚀 App launched in \(String(format: "%.2f", launchDuration))s")

        DispatchQueue.main.async {
            self.metrics.appLaunchTime = launchDuration
        }
    }
}

// MARK: - Models

struct PerformanceMetrics {
    var memoryUsage: MemoryMetrics = MemoryMetrics(used: 0, total: 0, percentage: 0)
    var cpuUsage: Double = 0
    var fps: Double = 60
    var networkActivity: NetworkMetrics = NetworkMetrics(requestsPerSecond: 0, bytesReceived: 0, bytesSent: 0)
    var activeThreads: Int = 0
    var appLaunchTime: TimeInterval = 0

    mutating func update(with snapshot: PerformanceSnapshot) {
        self.memoryUsage = snapshot.memoryUsage
        self.cpuUsage = snapshot.cpuUsage
        self.fps = snapshot.fps
        self.networkActivity = snapshot.networkActivity
        self.activeThreads = snapshot.activeThreads
    }
}

struct MemoryMetrics {
    let used: Double  // MB
    let total: Double // MB
    let percentage: Double

    var formattedUsed: String {
        String(format: "%.1f MB", used)
    }

    var formattedTotal: String {
        String(format: "%.1f MB", total)
    }
}

struct NetworkMetrics {
    let requestsPerSecond: Int
    let bytesReceived: Int64
    let bytesSent: Int64

    var formattedReceived: String {
        ByteCountFormatter.string(fromByteCount: bytesReceived, countStyle: .file)
    }

    var formattedSent: String {
        ByteCountFormatter.string(fromByteCount: bytesSent, countStyle: .file)
    }
}

struct PerformanceSnapshot {
    let timestamp: Date
    let memoryUsage: MemoryMetrics
    let cpuUsage: Double
    let fps: Double
    let networkActivity: NetworkMetrics
    let activeThreads: Int
}

// MARK: - Performance Dashboard View

struct PerformanceDashboardView: View {
    @StateObject private var profiler = PerformanceProfiler.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "speedometer")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.neonAccent)

                Text("Performance Monitor")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button(profiler.isMonitoring ? "Stop" : "Start") {
                    if profiler.isMonitoring {
                        profiler.stopMonitoring()
                    } else {
                        profiler.startMonitoring()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(profiler.isMonitoring ? .red : themeManager.currentTheme.neonAccent)

                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(themeManager.currentTheme.surface.opacity(0.5))

            Divider()

            ScrollView {
                VStack(spacing: 20) {
                    // Real-time metrics
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        MetricCard(
                            title: "Memory",
                            value: profiler.metrics.memoryUsage.formattedUsed,
                            subtitle: "of \(profiler.metrics.memoryUsage.formattedTotal)",
                            icon: "memorychip",
                            percentage: profiler.metrics.memoryUsage.percentage,
                            color: profiler.metrics.memoryUsage.percentage > 80 ? .red : .blue
                        )

                        MetricCard(
                            title: "CPU Usage",
                            value: String(format: "%.1f%%", profiler.metrics.cpuUsage),
                            subtitle: "\(profiler.metrics.activeThreads) threads",
                            icon: "cpu",
                            percentage: profiler.metrics.cpuUsage,
                            color: profiler.metrics.cpuUsage > 80 ? .red : .green
                        )

                        MetricCard(
                            title: "Frame Rate",
                            value: String(format: "%.0f FPS", profiler.metrics.fps),
                            subtitle: profiler.metrics.fps >= 60 ? "Optimal" : "Degraded",
                            icon: "waveform.path.ecg",
                            percentage: (profiler.metrics.fps / 60.0) * 100,
                            color: profiler.metrics.fps >= 60 ? .green : .orange
                        )

                        MetricCard(
                            title: "Network",
                            value: "\(profiler.metrics.networkActivity.requestsPerSecond) req/s",
                            subtitle: "↓ \(profiler.metrics.networkActivity.formattedReceived) ↑ \(profiler.metrics.networkActivity.formattedSent)",
                            icon: "network",
                            percentage: 0,
                            color: .purple
                        )
                    }
                    .padding(.horizontal)
                    .padding(.top)

                    // Performance history chart
                    if !profiler.history.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Performance History")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textPrimary)
                                .padding(.horizontal)

                            PerformanceChartView(history: profiler.history)
                                .frame(height: 200)
                                .padding(.horizontal)
                        }
                    }

                    // App startup metrics
                    if profiler.metrics.appLaunchTime > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Startup Metrics")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textPrimary)

                            HStack {
                                Label("App Launch Time", systemImage: "bolt.fill")
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                                Spacer()
                                Text(String(format: "%.2f seconds", profiler.metrics.appLaunchTime))
                                    .fontWeight(.semibold)
                                    .foregroundColor(themeManager.currentTheme.neonAccent)
                            }
                        }
                        .padding()
                        .background(themeManager.currentTheme.surface.opacity(0.3))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom)
            }
        }
        .frame(width: 800, height: 600)
        .background(themeManager.currentTheme.background)
    }
}

// MARK: - Metric Card

struct MetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let percentage: Double
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)

                Spacer()

                Text(title)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * min(percentage / 100.0, 1.0))
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(themeManager.currentTheme.surface.opacity(0.3))
        .cornerRadius(12)
    }
}

// MARK: - Performance Chart

struct PerformanceChartView: View {
    let history: [PerformanceSnapshot]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<5) { i in
                        Divider()
                            .background(Color.gray.opacity(0.2))
                        if i < 4 {
                            Spacer()
                        }
                    }
                }

                // CPU usage line
                Path { path in
                    guard !history.isEmpty else { return }

                    let maxCPU = 100.0
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let step = width / CGFloat(max(history.count - 1, 1))

                    for (index, snapshot) in history.enumerated() {
                        let x = CGFloat(index) * step
                        let y = height - (CGFloat(snapshot.cpuUsage / maxCPU) * height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.green, lineWidth: 2)

                // Memory usage line
                Path { path in
                    guard !history.isEmpty else { return }

                    let width = geometry.size.width
                    let height = geometry.size.height
                    let step = width / CGFloat(max(history.count - 1, 1))

                    for (index, snapshot) in history.enumerated() {
                        let x = CGFloat(index) * step
                        let y = height - (CGFloat(snapshot.memoryUsage.percentage / 100.0) * height)

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(Color.blue, lineWidth: 2)
            }
        }
        .background(themeManager.currentTheme.surface.opacity(0.3))
        .cornerRadius(8)
    }
}

// MARK: - View Extension

extension View {
    func measurePerformance(_ label: String) -> some View {
        self.onAppear {
            PerformanceProfiler.shared.startMarker(label)
        }
        .onDisappear {
            PerformanceProfiler.shared.endMarker(label)
        }
    }
}
