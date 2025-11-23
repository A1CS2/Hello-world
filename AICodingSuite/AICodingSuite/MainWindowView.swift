//
//  MainWindowView.swift
//  Next-Gen AI Coding Suite
//
//  Main window layout with modular, draggable panels
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var layoutManager = LayoutManager()

    @State private var showFileExplorer = true
    @State private var showGitPanel = true
    @State private var showAIPanel = true
    @State private var showTerminal = true
    @State private var showCommandPalette = false
    @State private var showMultiFileSearch = false
    @State private var showMetricsDashboard = false

    var body: some View {
        ZStack {
            // Background with theme
            themeManager.currentTheme.background
                .ignoresSafeArea()

            // Glassmorphic overlay
            if themeManager.currentTheme.enableGlassmorphism {
                GlassmorphicBackground()
            }

            // Main layout
            VStack(spacing: 0) {
                // Top bar
                TopBar()
                    .frame(height: 50)

                // Main content area
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Left sidebar
                        if showFileExplorer || showGitPanel {
                            LeftSidebar(
                                showFileExplorer: $showFileExplorer,
                                showGitPanel: $showGitPanel
                            )
                            .frame(width: 280)
                        }

                        Divider()

                        // Central workspace
                        CentralWorkspace()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                        Divider()

                        // Right sidebar
                        if showAIPanel {
                            RightSidebar()
                                .frame(width: 320)
                        }
                    }
                }

                // Bottom terminal
                if showTerminal {
                    Divider()
                    TerminalView()
                        .frame(height: 250)
                }
            }

            // Command Palette Overlay
            if showCommandPalette {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showCommandPalette = false
                    }

                CommandPalette(isPresented: $showCommandPalette)
                    .transition(.scale.combined(with: .opacity))
            }

            // Multi-File Search Overlay
            if showMultiFileSearch {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showMultiFileSearch = false
                    }

                MultiFileSearchView(isPresented: $showMultiFileSearch)
                    .transition(.scale.combined(with: .opacity))
            }

            // Metrics Dashboard Overlay
            if showMetricsDashboard {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        showMetricsDashboard = false
                    }

                VisualizationDashboard()
                    .frame(width: 900, height: 700)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            layoutManager.loadLayout(appState.activeLayout)
        }
        .onDisappear {
            appState.saveSession()
        }
        // Keyboard shortcuts for Phase 2 features
        .onKeyPress(.init("p", modifiers: [.command, .shift])) {
            showCommandPalette.toggle()
            return .handled
        }
        .onKeyPress(.init("f", modifiers: [.command, .shift])) {
            showMultiFileSearch.toggle()
            return .handled
        }
        .onKeyPress(.init("m", modifiers: [.command, .shift])) {
            showMetricsDashboard.toggle()
            return .handled
        }
    }
}

// MARK: - Top Bar
struct TopBar: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            // App icon/logo
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(themeManager.currentTheme.neonAccent)
                .shadow(color: themeManager.currentTheme.neonAccent.opacity(0.5), radius: 8)

            Text("AI Coding Suite")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Spacer()

            // Quick actions
            HStack(spacing: 12) {
                QuickActionButton(icon: "plus.circle", action: {})
                QuickActionButton(icon: "play.circle", action: {})
                QuickActionButton(icon: "hammer.circle", action: {})
                QuickActionButton(icon: "ant.circle", action: {})
                QuickActionButton(icon: "chart.xyaxis.line", action: {})
                QuickActionButton(icon: "command", action: {})
            }

            Spacer()

            // AI status indicator
            if appState.isAIProcessing {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("AI Processing...")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
            }

            // Notifications
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }
            .buttonStyle(.plain)

            // Settings
            Button(action: {}) {
                Image(systemName: "gearshape.fill")
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            themeManager.currentTheme.surface
                .opacity(0.8)
                .blur(radius: themeManager.currentTheme.enableGlassmorphism ? 10 : 0)
        )
    }
}

struct QuickActionButton: View {
    let icon: String
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(themeManager.currentTheme.neonAccent)
        }
        .buttonStyle(.plain)
        .help("Quick action")
    }
}

// MARK: - Preview
#Preview {
    MainWindowView()
        .environmentObject(AppState())
        .environmentObject(ThemeManager())
        .environmentObject(WorkspaceManager())
        .frame(width: 1400, height: 900)
}
