//
//  DataVisualization.swift
//  AI Coding Suite
//
//  Live data visualization components - charts, graphs, metrics
//

import SwiftUI
import Charts

// MARK: - Dashboard View
struct VisualizationDashboard: View {
    @State private var selectedMetric: MetricType = .performance
    @State private var timeRange: TimeRange = .lastHour
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var metricsManager = MetricsManager()

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.neonAccent)

                Text("Live Metrics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            .padding(16)
            .background(themeManager.currentTheme.surface.opacity(0.5))

            Divider()

            // Metrics selector
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MetricType.allCases, id: \.self) { metric in
                        MetricCard(
                            metric: metric,
                            isSelected: selectedMetric == metric,
                            value: metricsManager.getValue(for: metric)
                        )
                        .onTapGesture {
                            selectedMetric = metric
                        }
                    }
                }
                .padding(16)
            }
            .background(themeManager.currentTheme.background.opacity(0.3))

            // Main chart
            ScrollView {
                VStack(spacing: 20) {
                    // Primary chart
                    MainChartView(
                        metric: selectedMetric,
                        timeRange: timeRange,
                        data: metricsManager.getData(for: selectedMetric, range: timeRange)
                    )
                    .frame(height: 300)
                    .padding(16)

                    // Secondary metrics
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        BuildStatusWidget()
                        TestCoverageWidget()
                        CodeQualityWidget()
                        AIUsageWidget()
                    }
                    .padding(16)
                }
            }
        }
        .background(themeManager.currentTheme.background)
        .onAppear {
            metricsManager.startCollecting()
        }
        .onDisappear {
            metricsManager.stopCollecting()
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let metric: MetricType
    let isSelected: Bool
    let value: Double
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: metric.icon)
                    .foregroundColor(isSelected ? themeManager.currentTheme.neonAccent : themeManager.currentTheme.textSecondary)

                Spacer()

                Text(metric.unit)
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Text(metric.rawValue)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            Text(metric.formatValue(value))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(
                    isSelected ?
                    themeManager.currentTheme.neonAccent :
                    themeManager.currentTheme.textPrimary
                )
        }
        .padding(12)
        .frame(width: 140)
        .background(
            isSelected ?
            themeManager.currentTheme.neonAccent.opacity(0.15) :
            themeManager.currentTheme.surface.opacity(0.5)
        )
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected ?
                    themeManager.currentTheme.neonAccent :
                    Color.clear,
                    lineWidth: 2
                )
        )
    }
}

// MARK: - Main Chart View
struct MainChartView: View {
    let metric: MetricType
    let timeRange: TimeRange
    let data: [DataPoint]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(metric.rawValue)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Chart(data) { point in
                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            themeManager.currentTheme.neonAccent,
                            themeManager.currentTheme.neonSecondary
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3))

                AreaMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Value", point.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            themeManager.currentTheme.neonAccent.opacity(0.3),
                            themeManager.currentTheme.neonAccent.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(themeManager.currentTheme.textSecondary.opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                        .foregroundStyle(themeManager.currentTheme.textSecondary.opacity(0.2))
                    AxisValueLabel()
                        .foregroundStyle(themeManager.currentTheme.textSecondary)
                }
            }
        }
        .padding(16)
        .background(themeManager.currentTheme.surface.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Widget Views
struct BuildStatusWidget: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var buildStatus: BuildStatus = .success

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hammer.circle.fill")
                    .foregroundColor(buildStatus.color)
                Text("Build Status")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }

            Text(buildStatus.rawValue)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(buildStatus.color)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last build")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Text("2m ago")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                    Text("34.2s")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }
            }
        }
        .padding(16)
        .background(themeManager.currentTheme.surface.opacity(0.5))
        .cornerRadius(12)
    }

    enum BuildStatus: String {
        case success = "Success"
        case failed = "Failed"
        case running = "Running"

        var color: Color {
            switch self {
            case .success: return .green
            case .failed: return .red
            case .running: return .orange
            }
        }
    }
}

struct TestCoverageWidget: View {
    @EnvironmentObject var themeManager: ThemeManager
    let coverage: Double = 87.5

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                Text("Test Coverage")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(Int(coverage))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                Text("%")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            ProgressView(value: coverage, total: 100)
                .tint(themeManager.currentTheme.neonAccent)
        }
        .padding(16)
        .background(themeManager.currentTheme.surface.opacity(0.5))
        .cornerRadius(12)
    }
}

struct CodeQualityWidget: View {
    @EnvironmentObject var themeManager: ThemeManager
    let quality: Double = 8.9

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                Text("Code Quality")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text(String(format: "%.1f", quality))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                Text("/ 10")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            HStack(spacing: 12) {
                QualityBadge(label: "0 Issues", color: .green)
                QualityBadge(label: "2 Warnings", color: .orange)
            }
        }
        .padding(16)
        .background(themeManager.currentTheme.surface.opacity(0.5))
        .cornerRadius(12)
    }
}

struct QualityBadge: View {
    let label: String
    let color: Color

    var body: some View {
        Text(label)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

struct AIUsageWidget: View {
    @EnvironmentObject var themeManager: ThemeManager
    let completions: Int = 142
    let acceptanceRate: Double = 76.5

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                Text("AI Usage")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }

            HStack(alignment: .bottom, spacing: 4) {
                Text("\(completions)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                Text("suggestions")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            HStack {
                Text("Acceptance rate:")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                Text("\(Int(acceptanceRate))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.neonAccent)
            }
        }
        .padding(16)
        .background(themeManager.currentTheme.surface.opacity(0.5))
        .cornerRadius(12)
    }
}

// MARK: - Models

enum MetricType: String, CaseIterable {
    case performance = "Performance"
    case memory = "Memory Usage"
    case cpu = "CPU Usage"
    case network = "Network"
    case aiRequests = "AI Requests"

    var icon: String {
        switch self {
        case .performance: return "speedometer"
        case .memory: return "memorychip"
        case .cpu: return "cpu"
        case .network: return "network"
        case .aiRequests: return "sparkles"
        }
    }

    var unit: String {
        switch self {
        case .performance: return "ms"
        case .memory: return "MB"
        case .cpu: return "%"
        case .network: return "KB/s"
        case .aiRequests: return "req/m"
        }
    }

    func formatValue(_ value: Double) -> String {
        switch self {
        case .performance:
            return String(format: "%.1f", value)
        case .memory:
            return String(format: "%.0f", value)
        case .cpu:
            return String(format: "%.1f", value)
        case .network:
            return String(format: "%.1f", value)
        case .aiRequests:
            return String(format: "%.0f", value)
        }
    }
}

enum TimeRange: String, CaseIterable {
    case lastHour = "1H"
    case last6Hours = "6H"
    case last24Hours = "24H"
    case lastWeek = "1W"
}

struct DataPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let value: Double
}

// MARK: - Metrics Manager
class MetricsManager: ObservableObject {
    @Published var isCollecting: Bool = false
    private var timer: Timer?

    func startCollecting() {
        isCollecting = true
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.collectMetrics()
        }
    }

    func stopCollecting() {
        isCollecting = false
        timer?.invalidate()
        timer = nil
    }

    func getValue(for metric: MetricType) -> Double {
        switch metric {
        case .performance: return Double.random(in: 10...50)
        case .memory: return Double.random(in: 200...800)
        case .cpu: return Double.random(in: 10...60)
        case .network: return Double.random(in: 50...500)
        case .aiRequests: return Double.random(in: 5...25)
        }
    }

    func getData(for metric: MetricType, range: TimeRange) -> [DataPoint] {
        let count = 20
        let now = Date()

        return (0..<count).map { i in
            DataPoint(
                timestamp: now.addingTimeInterval(TimeInterval(-i * 300)),
                value: getValue(for: metric)
            )
        }.reversed()
    }

    private func collectMetrics() {
        // In production, collect real metrics
    }
}
