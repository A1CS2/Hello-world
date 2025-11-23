//
//  SettingsView.swift
//  AI Coding Suite
//
//  Application settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workspaceManager: WorkspaceManager
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettings()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(SettingsTab.general)

            ThemeSettings()
                .tabItem {
                    Label("Theme", systemImage: "paintbrush")
                }
                .tag(SettingsTab.theme)

            EditorSettings()
                .tabItem {
                    Label("Editor", systemImage: "doc.text")
                }
                .tag(SettingsTab.editor)

            AISettings()
                .tabItem {
                    Label("AI", systemImage: "sparkles")
                }
                .tag(SettingsTab.ai)

            PluginsSettings()
                .tabItem {
                    Label("Plugins", systemImage: "puzzlepiece.extension")
                }
                .tag(SettingsTab.plugins)
        }
        .frame(width: 600, height: 450)
    }

    enum SettingsTab {
        case general, theme, editor, ai, plugins
    }
}

// MARK: - General Settings
struct GeneralSettings: View {
    @AppStorage("autoSave") private var autoSave = true
    @AppStorage("checkUpdates") private var checkUpdates = true
    @AppStorage("telemetry") private var telemetry = false

    var body: some View {
        Form {
            Section("Application") {
                Toggle("Auto-save files", isOn: $autoSave)
                Toggle("Check for updates", isOn: $checkUpdates)
                Toggle("Send anonymous usage data", isOn: $telemetry)
            }

            Section("Workspace") {
                Button("Clear Recent Workspaces") {}
                Button("Reset Layout") {}
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Theme Settings
struct ThemeSettings: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Form {
            Section("Theme Selection") {
                Picker("Active Theme", selection: $themeManager.currentTheme) {
                    ForEach(themeManager.availableThemes) { theme in
                        Text(theme.name).tag(theme)
                    }
                }

                ThemePreview(theme: themeManager.currentTheme)
                    .frame(height: 200)
                    .cornerRadius(8)
            }

            Section("Customization") {
                Toggle("Enable Glassmorphism", isOn: .constant(themeManager.currentTheme.enableGlassmorphism))
                Slider(value: .constant(themeManager.currentTheme.glowIntensity), in: 0...2) {
                    Text("Glow Intensity")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ThemePreview: View {
    let theme: AppTheme

    var body: some View {
        ZStack {
            theme.background

            VStack(spacing: 16) {
                Text("Theme Preview")
                    .font(.headline)
                    .foregroundColor(theme.textPrimary)

                HStack(spacing: 12) {
                    Circle()
                        .fill(theme.neonAccent)
                        .frame(width: 40, height: 40)
                        .shadow(color: theme.neonAccent, radius: 10)

                    Circle()
                        .fill(theme.neonSecondary)
                        .frame(width: 40, height: 40)
                        .shadow(color: theme.neonSecondary, radius: 10)
                }

                Text("Sample Text")
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

// MARK: - Editor Settings
struct EditorSettings: View {
    @AppStorage("fontSize") private var fontSize = 14.0
    @AppStorage("tabSize") private var tabSize = 4.0
    @AppStorage("wordWrap") private var wordWrap = true
    @AppStorage("lineNumbers") private var lineNumbers = true

    var body: some View {
        Form {
            Section("Appearance") {
                Slider(value: $fontSize, in: 10...24, step: 1) {
                    Text("Font Size: \(Int(fontSize))")
                }
                Toggle("Show Line Numbers", isOn: $lineNumbers)
                Toggle("Word Wrap", isOn: $wordWrap)
            }

            Section("Formatting") {
                Slider(value: $tabSize, in: 2...8, step: 1) {
                    Text("Tab Size: \(Int(tabSize))")
                }
                Toggle("Format on Save", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - AI Settings
struct AISettings: View {
    @AppStorage("aiProvider") private var aiProvider = "openai"
    @AppStorage("aiModel") private var aiModel = "gpt-4"
    @AppStorage("enableAICompletion") private var enableAICompletion = true
    @AppStorage("enableAIChat") private var enableAIChat = true

    var body: some View {
        Form {
            Section("AI Provider") {
                Picker("Provider", selection: $aiProvider) {
                    Text("OpenAI").tag("openai")
                    Text("Anthropic").tag("anthropic")
                    Text("Local Model").tag("local")
                }

                if aiProvider == "openai" {
                    Picker("Model", selection: $aiModel) {
                        Text("GPT-4").tag("gpt-4")
                        Text("GPT-3.5").tag("gpt-3.5")
                    }
                }

                SecureField("API Key", text: .constant(""))
            }

            Section("Features") {
                Toggle("AI Code Completion", isOn: $enableAICompletion)
                Toggle("AI Chat Assistant", isOn: $enableAIChat)
                Toggle("AI Terminal Suggestions", isOn: .constant(true))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Plugins Settings
struct PluginsSettings: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Plugins")
                .font(.title)

            Text("Plugin system coming in Phase 3")
                .foregroundColor(.secondary)

            List {
                PluginRow(name: "Syntax Highlighter", enabled: true)
                PluginRow(name: "Git Lens", enabled: true)
                PluginRow(name: "Docker Support", enabled: false)
            }
        }
        .padding()
    }
}

struct PluginRow: View {
    let name: String
    @State var enabled: Bool

    var body: some View {
        HStack {
            Image(systemName: "puzzlepiece.extension")
            Text(name)
            Spacer()
            Toggle("", isOn: $enabled)
        }
    }
}

// MARK: - App Commands
struct AppCommands: Commands {
    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("New File") {}
                .keyboardShortcut("n", modifiers: .command)

            Button("New Window") {}
                .keyboardShortcut("n", modifiers: [.command, .shift])

            Button("Open Folder...") {}
                .keyboardShortcut("o", modifiers: .command)
        }

        CommandMenu("View") {
            Button("Toggle File Explorer") {}
                .keyboardShortcut("b", modifiers: .command)

            Button("Toggle Terminal") {}
                .keyboardShortcut("`", modifiers: .command)

            Button("Toggle AI Panel") {}
                .keyboardShortcut("i", modifiers: [.command, .shift])

            Divider()

            Button("Command Palette") {}
                .keyboardShortcut("p", modifiers: [.command, .shift])
        }

        CommandMenu("AI") {
            Button("Ask AI") {}
                .keyboardShortcut("k", modifiers: .command)

            Button("Explain Code") {}
                .keyboardShortcut("e", modifiers: [.command, .shift])

            Button("Refactor Code") {}
                .keyboardShortcut("r", modifiers: [.command, .shift])

            Button("Fix Errors") {}
                .keyboardShortcut("f", modifiers: [.command, .shift])
        }
    }
}
