//
//  AppSettings.swift
//  AICodingSuite2
//
//  Created by Claude
//

import Foundation
import SwiftUI

class AppSettings: ObservableObject {
    // General Settings
    @Published var autoSave: Bool = true
    @Published var checkForUpdates: Bool = true
    @Published var telemetryEnabled: Bool = false

    // Editor Settings
    @Published var fontSize: Double = 14
    @Published var tabSize: Int = 4
    @Published var wordWrap: Bool = true
    @Published var showLineNumbers: Bool = true
    @Published var fontName: String = "SF Mono"

    // AI Settings
    @Published var aiProvider: AIProvider = .openAI
    @Published var openAIModel: String = "gpt-4"
    @Published var openAIKey: String = ""
    @Published var anthropicKey: String = ""
    @Published var localModelEndpoint: String = "http://localhost:11434"

    // Theme Settings
    @Published var currentTheme: ThemeType = .neonDark

    enum AIProvider: String, CaseIterable, Identifiable {
        case openAI = "OpenAI"
        case anthropic = "Anthropic"
        case local = "Local Model"

        var id: String { rawValue }
    }

    enum ThemeType: String, CaseIterable, Identifiable {
        case neonDark = "Neon Dark"
        case neonBlue = "Neon Blue"
        case cyberpunk = "Cyberpunk"
        case midnight = "Midnight"
        case aurora = "Aurora"

        var id: String { rawValue }
    }

    // Singleton
    static let shared = AppSettings()

    private init() {
        loadSettings()
    }

    func saveSettings() {
        UserDefaults.standard.set(autoSave, forKey: "autoSave")
        UserDefaults.standard.set(checkForUpdates, forKey: "checkForUpdates")
        UserDefaults.standard.set(telemetryEnabled, forKey: "telemetryEnabled")
        UserDefaults.standard.set(fontSize, forKey: "fontSize")
        UserDefaults.standard.set(tabSize, forKey: "tabSize")
        UserDefaults.standard.set(wordWrap, forKey: "wordWrap")
        UserDefaults.standard.set(showLineNumbers, forKey: "showLineNumbers")
        UserDefaults.standard.set(fontName, forKey: "fontName")
        UserDefaults.standard.set(aiProvider.rawValue, forKey: "aiProvider")
        UserDefaults.standard.set(openAIModel, forKey: "openAIModel")
        UserDefaults.standard.set(openAIKey, forKey: "openAIKey")
        UserDefaults.standard.set(anthropicKey, forKey: "anthropicKey")
        UserDefaults.standard.set(localModelEndpoint, forKey: "localModelEndpoint")
        UserDefaults.standard.set(currentTheme.rawValue, forKey: "currentTheme")
    }

    func loadSettings() {
        autoSave = UserDefaults.standard.bool(forKey: "autoSave")
        checkForUpdates = UserDefaults.standard.bool(forKey: "checkForUpdates")
        telemetryEnabled = UserDefaults.standard.bool(forKey: "telemetryEnabled")
        fontSize = UserDefaults.standard.double(forKey: "fontSize")
        tabSize = UserDefaults.standard.integer(forKey: "tabSize")
        wordWrap = UserDefaults.standard.bool(forKey: "wordWrap")
        showLineNumbers = UserDefaults.standard.bool(forKey: "showLineNumbers")

        if let font = UserDefaults.standard.string(forKey: "fontName") {
            fontName = font
        }
        if let provider = UserDefaults.standard.string(forKey: "aiProvider"),
           let aiProv = AIProvider(rawValue: provider) {
            aiProvider = aiProv
        }
        if let model = UserDefaults.standard.string(forKey: "openAIModel") {
            openAIModel = model
        }
        if let key = UserDefaults.standard.string(forKey: "openAIKey") {
            openAIKey = key
        }
        if let key = UserDefaults.standard.string(forKey: "anthropicKey") {
            anthropicKey = key
        }
        if let endpoint = UserDefaults.standard.string(forKey: "localModelEndpoint") {
            localModelEndpoint = endpoint
        }
        if let theme = UserDefaults.standard.string(forKey: "currentTheme"),
           let themeType = ThemeType(rawValue: theme) {
            currentTheme = themeType
        }
    }
}
