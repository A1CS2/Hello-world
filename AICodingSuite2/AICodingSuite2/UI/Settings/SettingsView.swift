//
//  SettingsView.swift
//  AICodingSuite2
//
//  Created by Claude
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab: SettingsTab = .general

    enum SettingsTab: String, CaseIterable {
        case general = "General"
        case editor = "Editor"
        case theme = "Theme"
        case ai = "AI"

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .editor: return "doc.text"
            case .theme: return "paintbrush"
            case .ai: return "brain"
            }
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.primaryText)
                    .padding(20)

                Divider()
                    .overlay(themeManager.currentTheme.borderColor)

                VStack(spacing: 4) {
                    ForEach(SettingsTab.allCases, id: \.self) { tab in
                        Button(action: { selectedTab = tab }) {
                            HStack(spacing: 12) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16))
                                    .foregroundColor(selectedTab == tab ? themeManager.currentTheme.neonPrimary : themeManager.currentTheme.secondaryText)
                                    .frame(width: 20)

                                Text(tab.rawValue)
                                    .font(.system(size: 14))
                                    .foregroundColor(selectedTab == tab ? themeManager.currentTheme.primaryText : themeManager.currentTheme.secondaryText)

                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedTab == tab ? themeManager.currentTheme.neonPrimary.opacity(0.1) : Color.clear)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(12)

                Spacer()
            }
            .frame(width: 200)
            .background(themeManager.currentTheme.surface)

            Divider()
                .overlay(themeManager.currentTheme.borderColor)

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedTab {
                    case .general:
                        GeneralSettings(settings: settings, theme: themeManager.currentTheme)
                    case .editor:
                        EditorSettings(settings: settings, theme: themeManager.currentTheme)
                    case .theme:
                        ThemeSettings(settings: settings, themeManager: themeManager)
                    case .ai:
                        AISettings(settings: settings, theme: themeManager.currentTheme)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(themeManager.currentTheme.background)
        }
        .frame(width: 700, height: 500)
    }
}

struct GeneralSettings: View {
    @ObservedObject var settings: AppSettings
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("General")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)

            VStack(alignment: .leading, spacing: 16) {
                Toggle("Auto-save files", isOn: $settings.autoSave)
                    .foregroundColor(theme.primaryText)

                Toggle("Check for updates", isOn: $settings.checkForUpdates)
                    .foregroundColor(theme.primaryText)

                Toggle("Enable telemetry", isOn: $settings.telemetryEnabled)
                    .foregroundColor(theme.primaryText)

                Text("Help improve AICodingSuite by sending anonymous usage data")
                    .font(.caption)
                    .foregroundColor(theme.secondaryText)
            }
        }
    }
}

struct EditorSettings: View {
    @ObservedObject var settings: AppSettings
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Editor")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Font Size: \(Int(settings.fontSize))")
                        .foregroundColor(theme.primaryText)
                    Slider(value: $settings.fontSize, in: 10...24, step: 1)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tab Size: \(settings.tabSize)")
                        .foregroundColor(theme.primaryText)
                    Slider(value: Binding(
                        get: { Double(settings.tabSize) },
                        set: { settings.tabSize = Int($0) }
                    ), in: 2...8, step: 1)
                }

                Toggle("Word wrap", isOn: $settings.wordWrap)
                    .foregroundColor(theme.primaryText)

                Toggle("Show line numbers", isOn: $settings.showLineNumbers)
                    .foregroundColor(theme.primaryText)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Font")
                        .foregroundColor(theme.primaryText)

                    Picker("Font", selection: $settings.fontName) {
                        Text("SF Mono").tag("SF Mono")
                        Text("Menlo").tag("Menlo")
                        Text("Monaco").tag("Monaco")
                        Text("Courier").tag("Courier")
                    }
                    .pickerStyle(.menu)
                }
            }
        }
    }
}

struct ThemeSettings: View {
    @ObservedObject var settings: AppSettings
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Theme")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.primaryText)

            VStack(alignment: .leading, spacing: 16) {
                Text("Select Theme")
                    .foregroundColor(themeManager.currentTheme.primaryText)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(AppSettings.ThemeType.allCases) { themeType in
                        ThemePreview(
                            themeType: themeType,
                            isSelected: settings.currentTheme == themeType,
                            onSelect: {
                                settings.currentTheme = themeType
                                themeManager.applyTheme(themeType)
                                settings.saveSettings()
                            }
                        )
                    }
                }
            }
        }
    }
}

struct ThemePreview: View {
    let themeType: AppSettings.ThemeType
    let isSelected: Bool
    let onSelect: () -> Void

    private var theme: Theme {
        switch themeType {
        case .neonDark: return .neonDark
        case .neonBlue: return .neonBlue
        case .cyberpunk: return .cyberpunk
        case .midnight: return .midnight
        case .aurora: return .aurora
        }
    }

    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 12) {
                // Color preview
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(theme.background)
                        .frame(height: 60)

                    VStack(spacing: 4) {
                        Rectangle()
                            .fill(theme.neonPrimary)
                            .frame(height: 28)

                        Rectangle()
                            .fill(theme.neonSecondary)
                            .frame(height: 28)
                    }
                }
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? theme.neonPrimary : Color.clear, lineWidth: 3)
                )

                Text(themeType.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(theme.primaryText)
            }
        }
        .buttonStyle(.plain)
    }
}

struct AISettings: View {
    @ObservedObject var settings: AppSettings
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("AI Configuration")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.primaryText)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Provider")
                        .foregroundColor(theme.primaryText)

                    Picker("Provider", selection: $settings.aiProvider) {
                        ForEach(AppSettings.AIProvider.allCases) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Divider()
                    .overlay(theme.borderColor)

                // OpenAI Settings
                if settings.aiProvider == .openAI {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("OpenAI Configuration")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Model")
                                .foregroundColor(theme.primaryText)

                            Picker("Model", selection: $settings.openAIModel) {
                                Text("GPT-4").tag("gpt-4")
                                Text("GPT-4 Turbo").tag("gpt-4-turbo-preview")
                                Text("GPT-3.5 Turbo").tag("gpt-3.5-turbo")
                            }
                            .pickerStyle(.menu)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .foregroundColor(theme.primaryText)

                            SecureField("sk-...", text: $settings.openAIKey)
                                .textFieldStyle(.roundedBorder)

                            Text("Get your API key from platform.openai.com")
                                .font(.caption)
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                }

                // Anthropic Settings
                if settings.aiProvider == .anthropic {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Anthropic Configuration")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .foregroundColor(theme.primaryText)

                            SecureField("sk-ant-...", text: $settings.anthropicKey)
                                .textFieldStyle(.roundedBorder)

                            Text("Get your API key from console.anthropic.com")
                                .font(.caption)
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                }

                // Local Model Settings
                if settings.aiProvider == .local {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Local Model Configuration")
                            .font(.headline)
                            .foregroundColor(theme.primaryText)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Endpoint")
                                .foregroundColor(theme.primaryText)

                            TextField("http://localhost:11434", text: $settings.localModelEndpoint)
                                .textFieldStyle(.roundedBorder)

                            Text("Support for Ollama and compatible endpoints")
                                .font(.caption)
                                .foregroundColor(theme.secondaryText)
                        }
                    }
                }

                Button("Save Settings") {
                    settings.saveSettings()
                    AIManager.shared.updateProvider()
                }
                .buttonStyle(.borderedProminent)
                .tint(theme.neonPrimary)
            }
        }
    }
}
