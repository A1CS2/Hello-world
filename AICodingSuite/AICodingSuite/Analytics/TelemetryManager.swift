//
//  TelemetryManager.swift
//  AI Coding Suite
//
//  Privacy-first telemetry and analytics system (opt-in only)
//

import SwiftUI
import Combine

class TelemetryManager: ObservableObject {
    static let shared = TelemetryManager()

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "telemetryEnabled")
            if !isEnabled {
                clearAllData()
            }
        }
    }

    @Published var includeUsageData: Bool {
        didSet {
            UserDefaults.standard.set(includeUsageData, forKey: "includeUsageData")
        }
    }

    @Published var includeCrashReports: Bool {
        didSet {
            UserDefaults.standard.set(includeCrashReports, forKey: "includeCrashReports")
        }
    }

    private var eventQueue: [TelemetryEvent] = []
    private var sessionID: String = UUID().uuidString
    private var sessionStartTime: Date = Date()

    init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: "telemetryEnabled")
        self.includeUsageData = UserDefaults.standard.bool(forKey: "includeUsageData")
        self.includeCrashReports = UserDefaults.standard.bool(forKey: "includeCrashReports")
    }

    // MARK: - Event Tracking

    func trackEvent(_ event: TelemetryEvent) {
        guard isEnabled else { return }

        let anonymizedEvent = anonymize(event)
        eventQueue.append(anonymizedEvent)

        // Send events in batches
        if eventQueue.count >= 10 {
            sendEvents()
        }
    }

    func trackAppLaunch() {
        trackEvent(TelemetryEvent(
            type: .appLaunch,
            category: .lifecycle,
            metadata: [
                "session_id": sessionID,
                "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
                "platform": "macOS",
                "os_version": ProcessInfo.processInfo.operatingSystemVersionString
            ]
        ))
    }

    func trackFeatureUsage(_ feature: String, metadata: [String: Any] = [:]) {
        guard includeUsageData else { return }

        trackEvent(TelemetryEvent(
            type: .featureUsage,
            category: .usage,
            feature: feature,
            metadata: metadata
        ))
    }

    func trackError(_ error: Error, context: String) {
        guard includeCrashReports else { return }

        trackEvent(TelemetryEvent(
            type: .error,
            category: .diagnostic,
            metadata: [
                "error": String(describing: error),
                "context": context
            ]
        ))
    }

    func trackPerformanceMetric(_ metric: PerformanceMetric) {
        guard includeUsageData else { return }

        trackEvent(TelemetryEvent(
            type: .performance,
            category: .diagnostic,
            metadata: [
                "metric_name": metric.name,
                "value": metric.value,
                "unit": metric.unit
            ]
        ))
    }

    // MARK: - Privacy Protection

    private func anonymize(_ event: TelemetryEvent) -> TelemetryEvent {
        var sanitizedMetadata = event.metadata

        // Remove any potentially identifying information
        let sensitiveKeys = ["username", "email", "path", "file_path", "ip_address"]
        for key in sensitiveKeys {
            sanitizedMetadata.removeValue(forKey: key)
        }

        // Hash any remaining string values longer than 100 chars
        for (key, value) in sanitizedMetadata {
            if let stringValue = value as? String, stringValue.count > 100 {
                sanitizedMetadata[key] = stringValue.hashValue
            }
        }

        return TelemetryEvent(
            type: event.type,
            category: event.category,
            feature: event.feature,
            metadata: sanitizedMetadata,
            timestamp: event.timestamp
        )
    }

    private func sendEvents() {
        guard !eventQueue.isEmpty else { return }

        // In production, send to analytics endpoint
        print("📊 Sending \(eventQueue.count) anonymized telemetry events")

        // Simulate sending
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.eventQueue.removeAll()
        }
    }

    private func clearAllData() {
        eventQueue.removeAll()
        print("🔒 All telemetry data cleared")
    }

    // MARK: - Session Tracking

    func startSession() {
        sessionID = UUID().uuidString
        sessionStartTime = Date()
        trackAppLaunch()
    }

    func endSession() {
        let duration = Date().timeIntervalSince(sessionStartTime)

        trackEvent(TelemetryEvent(
            type: .appQuit,
            category: .lifecycle,
            metadata: [
                "session_id": sessionID,
                "duration": duration
            ]
        ))

        sendEvents()
    }

    // MARK: - Data Export

    func exportData() -> String {
        let data = eventQueue.map { event in
            """
            Event: \(event.type.rawValue)
            Category: \(event.category.rawValue)
            Timestamp: \(event.timestamp)
            Metadata: \(event.metadata)
            """
        }.joined(separator: "\n\n")

        return """
        # Telemetry Data Export
        Session ID: \(sessionID)
        Total Events: \(eventQueue.count)

        \(data)
        """
    }
}

// MARK: - Models

struct TelemetryEvent {
    let type: EventType
    let category: EventCategory
    var feature: String?
    var metadata: [String: Any]
    var timestamp: Date

    init(type: EventType, category: EventCategory, feature: String? = nil, metadata: [String: Any] = [:], timestamp: Date = Date()) {
        self.type = type
        self.category = category
        self.feature = feature
        self.metadata = metadata
        self.timestamp = timestamp
    }

    enum EventType: String {
        case appLaunch = "app_launch"
        case appQuit = "app_quit"
        case featureUsage = "feature_usage"
        case error = "error"
        case performance = "performance"
        case interaction = "interaction"
    }

    enum EventCategory: String {
        case lifecycle = "lifecycle"
        case usage = "usage"
        case diagnostic = "diagnostic"
        case interaction = "interaction"
    }
}

struct PerformanceMetric {
    let name: String
    let value: Double
    let unit: String
}

// MARK: - Analytics Dashboard

struct AnalyticsDashboardView: View {
    @StateObject private var telemetry = TelemetryManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showExportSheet = false
    @State private var exportedData = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.neonAccent)

                Text("Privacy & Analytics")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()
            }
            .padding()
            .background(themeManager.currentTheme.surface.opacity(0.5))

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    // Privacy-first notice
                    PrivacyNoticeCard()

                    // Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Telemetry Settings")
                            .font(.headline)

                        Toggle("Enable Telemetry", isOn: $telemetry.isEnabled)
                            .toggleStyle(.switch)

                        if telemetry.isEnabled {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("Include Usage Data", isOn: $telemetry.includeUsageData)
                                    .toggleStyle(.switch)

                                Text("Helps us understand which features are most valuable")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                                    .padding(.leading, 8)

                                Toggle("Include Crash Reports", isOn: $telemetry.includeCrashReports)
                                    .toggleStyle(.switch)

                                Text("Helps us fix bugs and improve stability")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    .padding()
                    .background(themeManager.currentTheme.surface.opacity(0.3))
                    .cornerRadius(12)

                    // Data transparency
                    VStack(alignment: .leading, spacing: 16) {
                        Text("What We Collect")
                            .font(.headline)

                        DataCollectionItem(
                            icon: "checkmark.circle.fill",
                            title: "Anonymous Usage Statistics",
                            description: "Feature usage frequency, performance metrics",
                            color: .green
                        )

                        DataCollectionItem(
                            icon: "xmark.circle.fill",
                            title: "Never Collected",
                            description: "Your code, file paths, personal information, or credentials",
                            color: .red
                        )

                        DataCollectionItem(
                            icon: "lock.fill",
                            title: "Data Protection",
                            description: "All data is anonymized and encrypted before transmission",
                            color: .blue
                        )
                    }
                    .padding()
                    .background(themeManager.currentTheme.surface.opacity(0.3))
                    .cornerRadius(12)

                    // Actions
                    VStack(spacing: 12) {
                        Button("Export My Data") {
                            exportedData = telemetry.exportData()
                            showExportSheet = true
                        }
                        .buttonStyle(.bordered)

                        Button("Clear All Telemetry Data") {
                            telemetry.isEnabled = false
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 700)
        .background(themeManager.currentTheme.background)
        .sheet(isPresented: $showExportSheet) {
            ExportDataView(data: exportedData)
        }
    }
}

// MARK: - Privacy Notice Card

struct PrivacyNoticeCard: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "hand.raised.fill")
                    .font(.title2)
                    .foregroundColor(themeManager.currentTheme.neonAccent)

                Text("Your Privacy Matters")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            Text("Telemetry is completely optional and disabled by default. When enabled, we only collect anonymized usage statistics to improve the app. We never collect your code, personal information, or anything that could identify you.")
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Link("Read our Privacy Policy", destination: URL(string: "https://aicodingsuite.app/privacy")!)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.neonAccent)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.neonAccent.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(themeManager.currentTheme.neonAccent.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Data Collection Item

struct DataCollectionItem: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
        }
    }
}

// MARK: - Export Data View

struct ExportDataView: View {
    let data: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Your Telemetry Data")
                    .font(.headline)

                Spacer()

                Button("Done") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            ScrollView {
                Text(data)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(themeManager.currentTheme.background)
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Convenience Extensions

extension View {
    func trackFeature(_ name: String) -> some View {
        self.onAppear {
            TelemetryManager.shared.trackFeatureUsage(name)
        }
    }
}

// MARK: - Feature Tracking

extension TelemetryManager {
    // Predefined feature tracking
    func trackThemeChange(_ themeName: String) {
        trackFeatureUsage("theme_change", metadata: ["theme": themeName])
    }

    func trackPluginInstalled(_ pluginID: String) {
        trackFeatureUsage("plugin_installed", metadata: ["plugin_id": pluginID])
    }

    func trackAIInteraction(provider: String, tokenCount: Int) {
        trackFeatureUsage("ai_interaction", metadata: [
            "provider": provider,
            "tokens": tokenCount
        ])
    }

    func trackCommandUsage(_ command: String) {
        trackFeatureUsage("command_usage", metadata: ["command": command])
    }

    func trackFileOperation(_ operation: String, fileType: String) {
        trackFeatureUsage("file_operation", metadata: [
            "operation": operation,
            "file_type": fileType
        ])
    }
}
