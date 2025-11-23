//
//  AutoUpdateManager.swift
//  AI Coding Suite
//
//  Automatic update system with Sparkle framework integration
//

import SwiftUI
import Combine

class AutoUpdateManager: ObservableObject {
    static let shared = AutoUpdateManager()

    @Published var updateAvailable: Bool = false
    @Published var latestVersion: AppVersion?
    @Published var currentVersion: AppVersion
    @Published var downloadProgress: Double = 0
    @Published var isCheckingForUpdates: Bool = false
    @Published var isDownloading: Bool = false
    @Published var updateChannel: UpdateChannel = .stable

    private var cancellables = Set<AnyCancellable>()
    private let updateFeedURL = "https://updates.aicodingsuite.app/appcast.xml"

    init() {
        // Get current version from bundle
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            self.currentVersion = AppVersion(version: version, build: build)
        } else {
            self.currentVersion = AppVersion(version: "1.0.0", build: "1")
        }

        // Load update preferences
        loadPreferences()

        // Set up automatic update checks
        setupAutomaticUpdateChecks()
    }

    // MARK: - Update Checking

    func checkForUpdates(manual: Bool = false) {
        guard !isCheckingForUpdates else { return }

        isCheckingForUpdates = true

        // Simulate update check
        // In production, use Sparkle framework or custom update feed
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.isCheckingForUpdates = false

            // Simulate finding an update
            let simulatedVersion = AppVersion(
                version: "1.1.0",
                build: "42",
                releaseDate: Date(),
                releaseNotes: """
                ## What's New in 1.1.0

                ### New Features
                - Enhanced AI code completion with better context awareness
                - New Cyberpunk Purple theme
                - Docker Compose support with multi-container orchestration
                - Database query history and saved connections

                ### Improvements
                - 40% faster LSP initialization
                - Reduced memory usage by 25%
                - Improved syntax highlighting performance
                - Better git diff visualization

                ### Bug Fixes
                - Fixed terminal color rendering issues
                - Resolved plugin marketplace search crashes
                - Fixed file watcher memory leaks
                - Corrected theme switching animation glitches

                ### Security
                - Updated dependencies to address CVE-2024-XXXX
                - Enhanced plugin sandbox security
                """,
                downloadURL: "https://updates.aicodingsuite.app/AICodingSuite-1.1.0.dmg",
                fileSize: 124_857_600,
                isCritical: false
            )

            if manual || simulatedVersion > self!.currentVersion {
                self?.latestVersion = simulatedVersion
                self?.updateAvailable = true
            }
        }
    }

    func downloadAndInstallUpdate() {
        guard let update = latestVersion else { return }

        isDownloading = true
        downloadProgress = 0

        // Simulate download progress
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }

            self.downloadProgress += 0.05

            if self.downloadProgress >= 1.0 {
                timer.invalidate()
                self.isDownloading = false
                self.downloadProgress = 1.0

                // In production, verify signature and install
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.promptForRestart()
                }
            }
        }
    }

    private func promptForRestart() {
        // Show restart prompt
        print("Update downloaded. Ready to install and restart.")
    }

    func skipVersion(_ version: AppVersion) {
        UserDefaults.standard.set(version.version, forKey: "skippedVersion")
        updateAvailable = false
    }

    // MARK: - Automatic Updates

    private func setupAutomaticUpdateChecks() {
        // Check for updates every 24 hours
        Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.checkForUpdates(manual: false)
        }

        // Check on app launch (after 10 seconds)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.checkForUpdates(manual: false)
        }
    }

    // MARK: - Settings

    private func loadPreferences() {
        if let channelRaw = UserDefaults.standard.string(forKey: "updateChannel"),
           let channel = UpdateChannel(rawValue: channelRaw) {
            self.updateChannel = channel
        }
    }

    func setUpdateChannel(_ channel: UpdateChannel) {
        self.updateChannel = channel
        UserDefaults.standard.set(channel.rawValue, forKey: "updateChannel")
    }
}

// MARK: - Models

struct AppVersion: Comparable {
    let version: String
    let build: String
    var releaseDate: Date?
    var releaseNotes: String?
    var downloadURL: String?
    var fileSize: Int64?
    var isCritical: Bool?

    var displayVersion: String {
        "\(version) (\(build))"
    }

    var formattedSize: String? {
        guard let size = fileSize else { return nil }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        // Compare version numbers
        let lhsComponents = lhs.version.split(separator: ".").compactMap { Int($0) }
        let rhsComponents = rhs.version.split(separator: ".").compactMap { Int($0) }

        for i in 0..<max(lhsComponents.count, rhsComponents.count) {
            let lhsValue = i < lhsComponents.count ? lhsComponents[i] : 0
            let rhsValue = i < rhsComponents.count ? rhsComponents[i] : 0

            if lhsValue < rhsValue { return true }
            if lhsValue > rhsValue { return false }
        }

        // If versions are equal, compare build numbers
        guard let lhsBuild = Int(lhs.build), let rhsBuild = Int(rhs.build) else {
            return lhs.build < rhs.build
        }

        return lhsBuild < rhsBuild
    }

    static func == (lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.version == rhs.version && lhs.build == rhs.build
    }
}

enum UpdateChannel: String, CaseIterable {
    case stable = "Stable"
    case beta = "Beta"
    case nightly = "Nightly"

    var description: String {
        switch self {
        case .stable:
            return "Recommended for most users. Stable and tested releases."
        case .beta:
            return "Early access to new features. May contain bugs."
        case .nightly:
            return "Latest development builds. Experimental and unstable."
        }
    }

    var icon: String {
        switch self {
        case .stable: return "checkmark.shield.fill"
        case .beta: return "ladybug.fill"
        case .nightly: return "moon.stars.fill"
        }
    }
}

// MARK: - Update Dialog View

struct UpdateDialogView: View {
    let version: AppVersion
    let onInstall: () -> Void
    let onSkip: () -> Void
    let onRemindLater: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(themeManager.currentTheme.neonAccent)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Update Available")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text("Version \(version.displayVersion)")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Spacer()
            }
            .padding(24)
            .background(themeManager.currentTheme.surface.opacity(0.5))

            Divider()

            // Release notes
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let releaseDate = version.releaseDate {
                        HStack {
                            Label(
                                releaseDate.formatted(date: .abbreviated, time: .omitted),
                                systemImage: "calendar"
                            )
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondary)

                            if let size = version.formattedSize {
                                Label(size, systemImage: "arrow.down.circle")
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.textSecondary)
                            }
                        }
                    }

                    if let notes = version.releaseNotes {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 300)

            Divider()

            // Actions
            HStack(spacing: 12) {
                Button("Skip This Version") {
                    onSkip()
                    dismiss()
                }
                .buttonStyle(.plain)
                .foregroundColor(themeManager.currentTheme.textSecondary)

                Spacer()

                Button("Remind Me Later") {
                    onRemindLater()
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("Install Update") {
                    onInstall()
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.currentTheme.neonAccent)
            }
            .padding(24)
            .background(themeManager.currentTheme.surface.opacity(0.3))
        }
        .frame(width: 600)
        .background(themeManager.currentTheme.background)
        .cornerRadius(12)
        .shadow(radius: 20)
    }
}

// MARK: - Download Progress View

struct UpdateDownloadView: View {
    @ObservedObject var updateManager: AutoUpdateManager
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.currentTheme.neonAccent)

            Text("Downloading Update...")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textPrimary)

            VStack(spacing: 8) {
                ProgressView(value: updateManager.downloadProgress)
                    .tint(themeManager.currentTheme.neonAccent)

                Text("\(Int(updateManager.downloadProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            .frame(width: 300)
        }
        .padding(40)
        .background(themeManager.currentTheme.surface)
        .cornerRadius(16)
    }
}

// MARK: - Update Settings View

struct UpdateSettingsView: View {
    @StateObject private var updateManager = AutoUpdateManager.shared
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Form {
            Section("Current Version") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Coding Suite")
                            .font(.headline)
                        Text("Version \(updateManager.currentVersion.displayVersion)")
                            .font(.subheadline)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }

                    Spacer()

                    Button(updateManager.isCheckingForUpdates ? "Checking..." : "Check for Updates") {
                        updateManager.checkForUpdates(manual: true)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.currentTheme.neonAccent)
                    .disabled(updateManager.isCheckingForUpdates)
                }
            }

            Section("Update Channel") {
                Picker("Channel", selection: $updateManager.updateChannel) {
                    ForEach(UpdateChannel.allCases, id: \.self) { channel in
                        Label(channel.rawValue, systemImage: channel.icon)
                            .tag(channel)
                    }
                }
                .onChange(of: updateManager.updateChannel) { _, newValue in
                    updateManager.setUpdateChannel(newValue)
                }

                Text(updateManager.updateChannel.description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Section("Automatic Updates") {
                Toggle("Check for updates automatically", isOn: .constant(true))
                Toggle("Download updates in the background", isOn: .constant(true))
                Toggle("Install updates on quit", isOn: .constant(false))
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - View Extension

extension View {
    func updateDialog(isPresented: Binding<Bool>, version: AppVersion, onInstall: @escaping () -> Void, onSkip: @escaping () -> Void, onRemindLater: @escaping () -> Void) -> some View {
        self.sheet(isPresented: isPresented) {
            UpdateDialogView(
                version: version,
                onInstall: onInstall,
                onSkip: onSkip,
                onRemindLater: onRemindLater
            )
        }
    }
}
