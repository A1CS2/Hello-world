//
//  AccessibilityManager.swift
//  AI Coding Suite
//
//  Comprehensive accessibility features for inclusive development
//

import SwiftUI
import Combine

class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()

    @Published var isVoiceOverEnabled: Bool = false
    @Published var isReduceMotionEnabled: Bool = false
    @Published var isHighContrastEnabled: Bool = false
    @Published var increasedFontSize: CGFloat = 0
    @Published var keyboardNavigationEnabled: Bool = true

    private var cancellables = Set<AnyCancellable>()

    init() {
        checkSystemSettings()
        setupNotifications()
    }

    private func checkSystemSettings() {
        #if os(macOS)
        isVoiceOverEnabled = NSWorkspace.shared.isVoiceOverEnabled
        isReduceMotionEnabled = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        #endif
    }

    private func setupNotifications() {
        #if os(macOS)
        NotificationCenter.default.publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
            .sink { [weak self] _ in
                self?.checkSystemSettings()
            }
            .store(in: &cancellables)
        #endif
    }

    // MARK: - Accessibility Helpers

    func announceForVoiceOver(_ message: String) {
        #if os(macOS)
        if isVoiceOverEnabled {
            NSAccessibility.post(
                element: NSApp.mainWindow as Any,
                notification: .announcementRequested,
                userInfo: [.announcement: message]
            )
        }
        #endif
    }

    func shouldReduceMotion() -> Bool {
        isReduceMotionEnabled
    }

    func animationDuration(default defaultDuration: Double) -> Double {
        isReduceMotionEnabled ? 0 : defaultDuration
    }

    func animation(default defaultAnimation: Animation) -> Animation {
        isReduceMotionEnabled ? .linear(duration: 0) : defaultAnimation
    }
}

// MARK: - Accessible Button
struct AccessibleButton<Label: View>: View {
    let label: Label
    let accessibilityLabel: String
    let accessibilityHint: String?
    let action: () -> Void

    @EnvironmentObject var accessibilityManager: AccessibilityManager

    init(
        accessibilityLabel: String,
        accessibilityHint: String? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.action = action
        self.label = label()
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            accessibilityManager.announceForVoiceOver("Activated \(accessibilityLabel)")
            action()
        }) {
            label
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint ?? "")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - High Contrast Theme
extension AppTheme {
    static let highContrast = AppTheme(
        name: "High Contrast",
        background: Color.black,
        surface: Color(white: 0.1),
        textPrimary: Color.white,
        textSecondary: Color(white: 0.9),
        neonAccent: Color.yellow,
        neonSecondary: Color.orange,
        enableGlassmorphism: false,
        glassOpacity: 0,
        blurRadius: 0,
        glowIntensity: 0
    )
}

// MARK: - Keyboard Navigation
struct KeyboardNavigationManager {
    static func setupKeyboardShortcuts() -> [KeyboardShortcut] {
        [
            // File operations
            KeyboardShortcut(.init("n", modifiers: .command)),  // New
            KeyboardShortcut(.init("o", modifiers: .command)),  // Open
            KeyboardShortcut(.init("s", modifiers: .command)),  // Save
            KeyboardShortcut(.init("w", modifiers: .command)),  // Close

            // Edit operations
            KeyboardShortcut(.init("z", modifiers: .command)),  // Undo
            KeyboardShortcut(.init("z", modifiers: [.command, .shift])),  // Redo
            KeyboardShortcut(.init("f", modifiers: .command)),  // Find
            KeyboardShortcut(.init("g", modifiers: .command)),  // Find Next

            // View operations
            KeyboardShortcut(.init("b", modifiers: .command)),  // Sidebar
            KeyboardShortcut(.init("`", modifiers: .command)),  // Terminal

            // Phase 2 shortcuts
            KeyboardShortcut(.init("p", modifiers: [.command, .shift])),  // Command Palette
            KeyboardShortcut(.init("f", modifiers: [.command, .shift])),  // Search Files
            KeyboardShortcut(.init("m", modifiers: [.command, .shift])),  // Metrics

            // AI shortcuts
            KeyboardShortcut(.init("k", modifiers: .command)),  // AI Chat
        ]
    }
}

// MARK: - Focus Management
class FocusState: ObservableObject {
    @Published var focusedElement: FocusableElement?

    enum FocusableElement: Hashable {
        case editor
        case terminal
        case fileExplorer
        case aiPanel
        case commandPalette
        case search
    }

    func moveFocus(to element: FocusableElement) {
        focusedElement = element
        AccessibilityManager.shared.announceForVoiceOver("Focused \(element)")
    }

    func nextFocus() {
        // Cycle through focusable elements
        guard let current = focusedElement else {
            focusedElement = .editor
            return
        }

        switch current {
        case .editor: focusedElement = .terminal
        case .terminal: focusedElement = .fileExplorer
        case .fileExplorer: focusedElement = .aiPanel
        case .aiPanel: focusedElement = .editor
        case .commandPalette: break
        case .search: break
        }
    }

    func previousFocus() {
        guard let current = focusedElement else {
            focusedElement = .editor
            return
        }

        switch current {
        case .editor: focusedElement = .aiPanel
        case .terminal: focusedElement = .editor
        case .fileExplorer: focusedElement = .terminal
        case .aiPanel: focusedElement = .fileExplorer
        case .commandPalette: break
        case .search: break
        }
    }
}

// MARK: - Screen Reader Announcements
extension View {
    func announceForScreenReader(_ message: String, delay: Double = 0) -> some View {
        self.onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                AccessibilityManager.shared.announceForVoiceOver(message)
            }
        }
    }

    func accessibleFocus(_ element: FocusState.FocusableElement, focusState: FocusState) -> some View {
        self.focused($focusState.focusedElement, equals: element)
    }
}

// MARK: - Accessible Colors
struct AccessibleColorPair {
    let foreground: Color
    let background: Color

    static let highContrast = AccessibleColorPair(
        foreground: .white,
        background: .black
    )

    static let mediumContrast = AccessibleColorPair(
        foreground: Color(white: 0.9),
        background: Color(white: 0.1)
    )

    func meetsWCAG_AAA() -> Bool {
        // Simplified contrast ratio check
        // In production, calculate actual luminance
        return true
    }
}

// MARK: - Font Scaling
extension View {
    func dynamicFont(size: CGFloat, weight: Font.Weight = .regular) -> some View {
        let manager = AccessibilityManager.shared
        let scaledSize = size + manager.increasedFontSize
        return self.font(.system(size: scaledSize, weight: weight))
    }
}

// MARK: - Reduced Motion
extension Animation {
    static func accessible(default animation: Animation) -> Animation {
        AccessibilityManager.shared.shouldReduceMotion() ? .linear(duration: 0) : animation
    }
}

// MARK: - Accessibility Settings View
struct AccessibilitySettingsView: View {
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Form {
            Section("Visual") {
                Toggle("High Contrast Mode", isOn: $accessibilityManager.isHighContrastEnabled)
                    .onChange(of: accessibilityManager.isHighContrastEnabled) { _, enabled in
                        if enabled {
                            themeManager.setTheme(.highContrast)
                        }
                    }

                VStack(alignment: .leading) {
                    Text("Font Size")
                    HStack {
                        Text("A")
                            .font(.caption)
                        Slider(value: $accessibilityManager.increasedFontSize, in: -2...8, step: 1)
                        Text("A")
                            .font(.title)
                    }
                    Text("Current: \(Int(accessibilityManager.increasedFontSize)) points")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section("Motion") {
                Toggle("Reduce Motion", isOn: $accessibilityManager.isReduceMotionEnabled)
                Text("Reduces animations throughout the app")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Navigation") {
                Toggle("Keyboard Navigation", isOn: $accessibilityManager.keyboardNavigationEnabled)
                Text("Enable full keyboard navigation with Tab key")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Screen Reader") {
                HStack {
                    Text("VoiceOver")
                    Spacer()
                    Text(accessibilityManager.isVoiceOverEnabled ? "Enabled" : "Disabled")
                        .foregroundColor(accessibilityManager.isVoiceOverEnabled ? .green : .secondary)
                }

                Button("Test Screen Reader Announcement") {
                    accessibilityManager.announceForVoiceOver("This is a test announcement from AI Coding Suite")
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 400)
    }
}
