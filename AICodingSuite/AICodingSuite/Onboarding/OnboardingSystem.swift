//
//  OnboardingSystem.swift
//  AI Coding Suite
//
//  Interactive onboarding and tutorial system for new users
//

import SwiftUI
import Combine

class OnboardingManager: ObservableObject {
    static let shared = OnboardingManager()

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    @Published var currentStep: OnboardingStep?
    @Published var showTooltip: Bool = false
    @Published var tooltipConfig: TooltipConfig?

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    func startOnboarding() {
        currentStep = .welcome
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        currentStep = nil
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentStep = .welcome
    }

    func showTooltip(for feature: AppFeature, position: CGPoint) {
        tooltipConfig = TooltipConfig(
            feature: feature,
            position: position,
            title: feature.tooltipTitle,
            description: feature.tooltipDescription
        )
        showTooltip = true
    }

    func hideTooltip() {
        showTooltip = false
        tooltipConfig = nil
    }
}

// MARK: - Models

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case workspace
    case aiFeatures
    case terminal
    case plugins
    case shortcuts
    case complete

    var title: String {
        switch self {
        case .welcome: return "Welcome to AI Coding Suite"
        case .workspace: return "Your Workspace"
        case .aiFeatures: return "AI-Powered Features"
        case .terminal: return "Integrated Terminal"
        case .plugins: return "Plugin System"
        case .shortcuts: return "Keyboard Shortcuts"
        case .complete: return "You're All Set!"
        }
    }

    var description: String {
        switch self {
        case .welcome:
            return "A next-generation IDE combining the best of modern development tools with AI-powered assistance."
        case .workspace:
            return "Organize your files, customize your layout, and manage multiple projects with ease."
        case .aiFeatures:
            return "Get intelligent code completion, explanations, refactoring suggestions, and more."
        case .terminal:
            return "Access a powerful terminal with smart command suggestions and git integration."
        case .plugins:
            return "Extend functionality with plugins from our marketplace or create your own."
        case .shortcuts:
            return "Master keyboard shortcuts to boost your productivity."
        case .complete:
            return "You're ready to start coding! Explore features at your own pace."
        }
    }

    var icon: String {
        switch self {
        case .welcome: return "sparkles"
        case .workspace: return "folder.fill"
        case .aiFeatures: return "brain.head.profile"
        case .terminal: return "terminal.fill"
        case .plugins: return "puzzlepiece.extension.fill"
        case .shortcuts: return "keyboard"
        case .complete: return "checkmark.circle.fill"
        }
    }

    var next: OnboardingStep? {
        OnboardingStep(rawValue: self.rawValue + 1)
    }

    var previous: OnboardingStep? {
        OnboardingStep(rawValue: self.rawValue - 1)
    }
}

enum AppFeature {
    case codeEditor
    case fileExplorer
    case terminal
    case aiChat
    case gitPanel
    case commandPalette
    case themeSelector
    case pluginMarketplace
    case debugger
    case restClient
    case database

    var tooltipTitle: String {
        switch self {
        case .codeEditor: return "Code Editor"
        case .fileExplorer: return "File Explorer"
        case .terminal: return "Terminal"
        case .aiChat: return "AI Assistant"
        case .gitPanel: return "Git Integration"
        case .commandPalette: return "Command Palette"
        case .themeSelector: return "Theme Selector"
        case .pluginMarketplace: return "Plugin Marketplace"
        case .debugger: return "Debugger"
        case .restClient: return "REST Client"
        case .database: return "Database Manager"
        }
    }

    var tooltipDescription: String {
        switch self {
        case .codeEditor:
            return "Write code with syntax highlighting, IntelliSense, and AI-powered completions."
        case .fileExplorer:
            return "Browse and manage your project files. Right-click for more options."
        case .terminal:
            return "Run commands, scripts, and manage your development environment."
        case .aiChat:
            return "Chat with AI to get code explanations, suggestions, and help with debugging."
        case .gitPanel:
            return "Stage changes, commit, and push to remote repositories with visual diff viewing."
        case .commandPalette:
            return "Quick access to all commands. Press ⌘⇧P to open."
        case .themeSelector:
            return "Customize your IDE appearance with stunning themes."
        case .pluginMarketplace:
            return "Discover and install plugins to extend functionality."
        case .debugger:
            return "Set breakpoints, inspect variables, and debug your code."
        case .restClient:
            return "Test HTTP/REST APIs directly from your IDE."
        case .database:
            return "Connect to databases and run queries."
        }
    }
}

struct TooltipConfig {
    let feature: AppFeature
    let position: CGPoint
    let title: String
    let description: String
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @StateObject private var onboardingManager = OnboardingManager.shared
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss

    @State private var currentStepIndex: Int = 0

    var body: some View {
        ZStack {
            // Background with blur
            themeManager.currentTheme.background
                .overlay(
                    Color.black.opacity(0.7)
                )

            // Content
            VStack(spacing: 0) {
                if let step = OnboardingStep(rawValue: currentStepIndex) {
                    OnboardingStepView(step: step)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                }

                // Navigation
                HStack(spacing: 20) {
                    if currentStepIndex > 0 {
                        Button("Previous") {
                            withAnimation(.spring()) {
                                currentStepIndex -= 1
                            }
                        }
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    // Progress indicators
                    HStack(spacing: 8) {
                        ForEach(0..<OnboardingStep.allCases.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStepIndex ? themeManager.currentTheme.neonAccent : Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Spacer()

                    if currentStepIndex < OnboardingStep.allCases.count - 1 {
                        Button("Next") {
                            withAnimation(.spring()) {
                                currentStepIndex += 1
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(themeManager.currentTheme.neonAccent)
                    } else {
                        Button("Get Started") {
                            onboardingManager.completeOnboarding()
                            dismiss()
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(themeManager.currentTheme.neonAccent)
                    }
                }
                .padding(30)
            }
            .frame(width: 700, height: 550)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(themeManager.currentTheme.surface)
                    .shadow(color: themeManager.currentTheme.neonAccent.opacity(0.3), radius: 20)
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Onboarding Step View

struct OnboardingStepView: View {
    let step: OnboardingStep
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 30) {
            // Icon
            Image(systemName: step.icon)
                .font(.system(size: 80))
                .foregroundColor(themeManager.currentTheme.neonAccent)
                .shadow(color: themeManager.currentTheme.neonAccent.opacity(0.5), radius: 10)
                .padding(.top, 40)

            // Title
            Text(step.title)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            // Description
            Text(step.description)
                .font(.body)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 60)

            // Step-specific content
            stepContent
                .padding(.horizontal, 40)

            Spacer()
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .welcome:
            VStack(spacing: 16) {
                FeatureHighlight(icon: "wand.and.stars", title: "AI-Powered", description: "Intelligent code assistance")
                FeatureHighlight(icon: "paintbrush.fill", title: "Beautiful Themes", description: "Stunning visual experience")
                FeatureHighlight(icon: "bolt.fill", title: "Lightning Fast", description: "Optimized for Apple Silicon")
            }

        case .workspace:
            VStack(spacing: 12) {
                QuickTip(icon: "sidebar.left", text: "Drag panels to customize your layout")
                QuickTip(icon: "folder.badge.plus", text: "Open folders with ⌘O")
                QuickTip(icon: "magnifyingglass", text: "Search files with ⌘⇧F")
            }

        case .aiFeatures:
            VStack(spacing: 12) {
                QuickTip(icon: "brain", text: "Get code completions as you type")
                QuickTip(icon: "bubble.left.and.bubble.right", text: "Chat with AI using ⌘K")
                QuickTip(icon: "arrow.triangle.2.circlepath", text: "Refactor code with AI suggestions")
            }

        case .terminal:
            VStack(spacing: 12) {
                QuickTip(icon: "terminal", text: "Integrated terminal with smart suggestions")
                QuickTip(icon: "arrow.branch", text: "Git commands with auto-complete")
                QuickTip(icon: "clock.arrow.circlepath", text: "Command history with ↑/↓")
            }

        case .plugins:
            VStack(spacing: 12) {
                QuickTip(icon: "puzzlepiece.extension", text: "Browse the plugin marketplace")
                QuickTip(icon: "arrow.down.circle", text: "Install plugins with one click")
                QuickTip(icon: "hammer", text: "Create your own plugins")
            }

        case .shortcuts:
            VStack(spacing: 8) {
                ShortcutRow(keys: "⌘⇧P", description: "Command Palette")
                ShortcutRow(keys: "⌘K", description: "AI Chat")
                ShortcutRow(keys: "⌘B", description: "Toggle Sidebar")
                ShortcutRow(keys: "⌘`", description: "Toggle Terminal")
            }
            .font(.caption)

        case .complete:
            VStack(spacing: 16) {
                Text("🎉")
                    .font(.system(size: 60))

                Text("Ready to explore?")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Button("Take Interactive Tour") {
                    // Start interactive tour
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - Helper Components

struct FeatureHighlight: View {
    let icon: String
    let title: String
    let description: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(themeManager.currentTheme.neonAccent)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                Text(description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()
        }
        .padding()
        .background(themeManager.currentTheme.background.opacity(0.3))
        .cornerRadius(12)
    }
}

struct QuickTip: View {
    let icon: String
    let text: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(themeManager.currentTheme.neonAccent)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Spacer()
        }
    }
}

struct ShortcutRow: View {
    let keys: String
    let description: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack {
            Text(keys)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(themeManager.currentTheme.neonAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(themeManager.currentTheme.background.opacity(0.5))
                .cornerRadius(6)

            Text(description)
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Tooltip View

struct TooltipView: View {
    let config: TooltipConfig
    let onDismiss: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(config.title)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }

            Text(config.description)
                .font(.subheadline)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            Button("Got it!") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .tint(themeManager.currentTheme.neonAccent)
        }
        .padding(16)
        .frame(width: 300)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(themeManager.currentTheme.surface)
                .shadow(color: .black.opacity(0.3), radius: 10)
        )
        .position(config.position)
    }
}

// MARK: - Interactive Tour

class InteractiveTourManager: ObservableObject {
    @Published var isActive: Bool = false
    @Published var currentFeature: AppFeature?
    @Published var tourSteps: [AppFeature] = [
        .fileExplorer,
        .codeEditor,
        .aiChat,
        .terminal,
        .commandPalette
    ]
    @Published var currentStepIndex: Int = 0

    func startTour() {
        isActive = true
        currentStepIndex = 0
        currentFeature = tourSteps.first
    }

    func nextStep() {
        currentStepIndex += 1
        if currentStepIndex < tourSteps.count {
            currentFeature = tourSteps[currentStepIndex]
        } else {
            endTour()
        }
    }

    func endTour() {
        isActive = false
        currentFeature = nil
        currentStepIndex = 0
    }
}

// MARK: - View Extension

extension View {
    func onboardingOverlay() -> some View {
        self.overlay {
            if !OnboardingManager.shared.hasCompletedOnboarding,
               OnboardingManager.shared.currentStep != nil {
                OnboardingView()
                    .transition(.opacity)
            }
        }
    }

    func showTooltipOnHover(for feature: AppFeature) -> some View {
        self.onHover { isHovering in
            if isHovering {
                // Show tooltip after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    // Calculate position and show tooltip
                }
            } else {
                OnboardingManager.shared.hideTooltip()
            }
        }
    }
}
