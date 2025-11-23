//
//  ThemeManager.swift
//  AI Coding Suite
//
//  Theme engine with support for neon, glassmorphism, and custom themes
//

import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: AppTheme
    @Published var availableThemes: [AppTheme] = []

    init() {
        // Initialize with default neon dark theme
        self.currentTheme = AppTheme.neonDark
        self.availableThemes = [
            .neonDark,
            .neonBlue,
            .cyberpunk,
            .midnight,
            .aurora
        ]

        loadSavedTheme()
    }

    func setTheme(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentTheme = theme
        }
        saveTheme()
    }

    private func loadSavedTheme() {
        if let themeName = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = availableThemes.first(where: { $0.name == themeName }) {
            currentTheme = theme
        }
    }

    private func saveTheme() {
        UserDefaults.standard.set(currentTheme.name, forKey: "selectedTheme")
    }
}

// MARK: - App Theme Definition
struct AppTheme: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let neonAccent: Color
    let neonSecondary: Color
    let enableGlassmorphism: Bool
    let glassOpacity: Double
    let blurRadius: CGFloat
    let glowIntensity: Double

    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Preset Themes
extension AppTheme {
    static let neonDark = AppTheme(
        name: "Neon Dark",
        background: Color(red: 0.05, green: 0.05, blue: 0.08),
        surface: Color(red: 0.1, green: 0.1, blue: 0.15),
        textPrimary: Color(red: 0.95, green: 0.95, blue: 0.98),
        textSecondary: Color(red: 0.7, green: 0.7, blue: 0.75),
        neonAccent: Color(red: 0.0, green: 0.9, blue: 1.0),      // Cyan
        neonSecondary: Color(red: 1.0, green: 0.0, blue: 0.6),   // Hot Pink
        enableGlassmorphism: true,
        glassOpacity: 0.15,
        blurRadius: 20,
        glowIntensity: 0.8
    )

    static let neonBlue = AppTheme(
        name: "Neon Blue",
        background: Color(red: 0.02, green: 0.05, blue: 0.12),
        surface: Color(red: 0.05, green: 0.1, blue: 0.2),
        textPrimary: Color(red: 0.9, green: 0.95, blue: 1.0),
        textSecondary: Color(red: 0.6, green: 0.7, blue: 0.85),
        neonAccent: Color(red: 0.2, green: 0.5, blue: 1.0),      // Electric Blue
        neonSecondary: Color(red: 0.6, green: 0.2, blue: 1.0),   // Purple
        enableGlassmorphism: true,
        glassOpacity: 0.2,
        blurRadius: 25,
        glowIntensity: 1.0
    )

    static let cyberpunk = AppTheme(
        name: "Cyberpunk",
        background: Color(red: 0.08, green: 0.0, blue: 0.12),
        surface: Color(red: 0.15, green: 0.05, blue: 0.2),
        textPrimary: Color(red: 1.0, green: 0.95, blue: 0.0),    // Yellow
        textSecondary: Color(red: 0.8, green: 0.4, blue: 0.9),
        neonAccent: Color(red: 1.0, green: 0.0, blue: 0.8),      // Magenta
        neonSecondary: Color(red: 0.0, green: 1.0, blue: 0.9),   // Cyan
        enableGlassmorphism: true,
        glassOpacity: 0.25,
        blurRadius: 30,
        glowIntensity: 1.2
    )

    static let midnight = AppTheme(
        name: "Midnight",
        background: Color(red: 0.0, green: 0.0, blue: 0.05),
        surface: Color(red: 0.05, green: 0.05, blue: 0.12),
        textPrimary: Color(red: 0.9, green: 0.9, blue: 0.95),
        textSecondary: Color(red: 0.6, green: 0.6, blue: 0.7),
        neonAccent: Color(red: 0.3, green: 0.6, blue: 1.0),      // Sky Blue
        neonSecondary: Color(red: 0.5, green: 0.3, blue: 0.8),   // Lavender
        enableGlassmorphism: false,
        glassOpacity: 0.1,
        blurRadius: 15,
        glowIntensity: 0.6
    )

    static let aurora = AppTheme(
        name: "Aurora",
        background: Color(red: 0.02, green: 0.08, blue: 0.08),
        surface: Color(red: 0.05, green: 0.15, blue: 0.15),
        textPrimary: Color(red: 0.95, green: 1.0, blue: 0.95),
        textSecondary: Color(red: 0.7, green: 0.85, blue: 0.8),
        neonAccent: Color(red: 0.0, green: 1.0, blue: 0.7),      // Mint
        neonSecondary: Color(red: 0.4, green: 0.8, blue: 1.0),   // Light Blue
        enableGlassmorphism: true,
        glassOpacity: 0.18,
        blurRadius: 22,
        glowIntensity: 0.9
    )
}

// MARK: - Glassmorphic Background
struct GlassmorphicBackground: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var animate = false

    var body: some View {
        ZStack {
            // Animated gradient orbs
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.currentTheme.neonAccent.opacity(0.3),
                            themeManager.currentTheme.neonAccent.opacity(0.0)
                        ],
                        center: .topLeading,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 600, height: 600)
                .offset(x: animate ? -100 : -200, y: animate ? -100 : -200)
                .blur(radius: 50)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            themeManager.currentTheme.neonSecondary.opacity(0.3),
                            themeManager.currentTheme.neonSecondary.opacity(0.0)
                        ],
                        center: .bottomTrailing,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .frame(width: 600, height: 600)
                .offset(x: animate ? 100 : 200, y: animate ? 100 : 200)
                .blur(radius: 50)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animate = true
            }
        }
    }
}
