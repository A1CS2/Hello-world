//
//  AICodingSuiteApp.swift
//  Next-Gen AI Coding Suite
//
//  Main application entry point for the native macOS app
//

import SwiftUI

@main
struct AICodingSuiteApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var workspaceManager = WorkspaceManager()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
                .environmentObject(themeManager)
                .environmentObject(workspaceManager)
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands()
        }

        Settings {
            SettingsView()
                .environmentObject(themeManager)
                .environmentObject(workspaceManager)
        }
    }
}

// MARK: - App State Management
class AppState: ObservableObject {
    @Published var currentProject: Project?
    @Published var activeLayout: LayoutConfiguration?
    @Published var isAIProcessing: Bool = false
    @Published var notifications: [AppNotification] = []

    init() {
        loadLastSession()
    }

    private func loadLastSession() {
        // Load last workspace and layout
        if let savedLayout = UserDefaults.standard.data(forKey: "lastLayout"),
           let layout = try? JSONDecoder().decode(LayoutConfiguration.self, from: savedLayout) {
            activeLayout = layout
        } else {
            // Default layout
            activeLayout = LayoutConfiguration.defaultLayout
        }
    }

    func saveSession() {
        if let layout = activeLayout,
           let data = try? JSONEncoder().encode(layout) {
            UserDefaults.standard.set(data, forKey: "lastLayout")
        }
    }
}

// MARK: - App Notification Model
struct AppNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date

    enum NotificationType {
        case info, warning, error, success
    }
}
