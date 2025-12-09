//
//  MainWindowView.swift
//  AICodingSuite2
//
//  Created by Claude
//

import SwiftUI

struct MainWindowView: View {
    @StateObject var themeManager = ThemeManager()
    @StateObject var workspace = WorkspaceManager.shared
    @StateObject var aiManager = AIManager.shared
    @StateObject var settings = AppSettings.shared

    @State private var showFileExplorer = true
    @State private var showAIPanel = true
    @State private var showTerminal = true
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    // Main content area
                    HStack(spacing: 0) {
                        // Left sidebar - File Explorer
                        if showFileExplorer {
                            FileExplorerView(themeManager: themeManager)
                                .frame(width: 250)

                            Divider()
                                .overlay(themeManager.currentTheme.borderColor)
                        }

                        // Center - Code Editor
                        CodeEditorView(themeManager: themeManager)
                            .frame(maxWidth: .infinity)

                        // Right sidebar - AI Panel
                        if showAIPanel {
                            Divider()
                                .overlay(themeManager.currentTheme.borderColor)

                            AIChatView(themeManager: themeManager)
                                .frame(width: 320)
                        }
                    }
                    .frame(height: showTerminal ? geometry.size.height * 0.7 : geometry.size.height)

                    // Bottom - Terminal
                    if showTerminal {
                        Divider()
                            .overlay(themeManager.currentTheme.borderColor)

                        TerminalView(themeManager: themeManager)
                            .frame(height: geometry.size.height * 0.3)
                    }
                }
            }
            .background(themeManager.currentTheme.background)
            .toolbar {
                ToolbarItemGroup(placement: .navigation) {
                    Button(action: { showFileExplorer.toggle() }) {
                        Label("Explorer", systemImage: "sidebar.left")
                    }
                    .help("Toggle File Explorer")

                    Button(action: { showAIPanel.toggle() }) {
                        Label("AI", systemImage: "brain")
                    }
                    .help("Toggle AI Panel")

                    Button(action: { showTerminal.toggle() }) {
                        Label("Terminal", systemImage: "terminal")
                    }
                    .help("Toggle Terminal")
                }

                ToolbarItemGroup(placement: .automatic) {
                    Menu {
                        ForEach(AppSettings.ThemeType.allCases) { themeType in
                            Button(themeType.rawValue) {
                                settings.currentTheme = themeType
                                themeManager.applyTheme(themeType)
                                settings.saveSettings()
                            }
                        }
                    } label: {
                        Label("Theme", systemImage: "paintbrush")
                    }
                    .help("Change Theme")

                    Button(action: { showSettings.toggle() }) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    .help("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(themeManager: themeManager)
            }
        }
        .onAppear {
            // Apply saved theme
            themeManager.applyTheme(settings.currentTheme)
            // Update AI provider
            aiManager.updateProvider()
        }
        .preferredColorScheme(.dark)
    }
}

// Helper views
struct StatusBar: View {
    @ObservedObject var workspace: WorkspaceManager
    let theme: Theme

    var body: some View {
        HStack(spacing: 16) {
            if let file = workspace.selectedFile {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 11))

                    Text(file.name)
                        .font(.system(size: 11))

                    Text("•")
                        .foregroundColor(theme.secondaryText.opacity(0.5))

                    Text(file.language)
                        .font(.system(size: 11))
                        .foregroundColor(theme.secondaryText)
                }
            }

            Spacer()

            if workspace.currentWorkspace != nil {
                HStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 11))

                    Text(workspace.currentWorkspace?.lastPathComponent ?? "")
                        .font(.system(size: 11))
                        .foregroundColor(theme.secondaryText)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(theme.surface)
        .foregroundColor(theme.primaryText)
    }
}
