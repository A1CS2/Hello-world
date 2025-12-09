//
//  ThemeManager.swift
//  AICodingSuite2
//
//  Created by Claude
//

import SwiftUI

class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme

    init() {
        self.currentTheme = Theme.neonDark
    }

    func applyTheme(_ themeType: AppSettings.ThemeType) {
        switch themeType {
        case .neonDark:
            currentTheme = .neonDark
        case .neonBlue:
            currentTheme = .neonBlue
        case .cyberpunk:
            currentTheme = .cyberpunk
        case .midnight:
            currentTheme = .midnight
        case .aurora:
            currentTheme = .aurora
        }
    }
}

struct Theme {
    // Background colors
    let background: Color
    let surface: Color
    let elevated: Color

    // Text colors
    let primaryText: Color
    let secondaryText: Color
    let accentText: Color

    // Neon accent colors
    let neonPrimary: Color
    let neonSecondary: Color
    let neonAccent: Color

    // Glass effect properties
    let glassOpacity: Double
    let blurRadius: CGFloat
    let glowIntensity: Double

    // Border properties
    let borderColor: Color
    let borderWidth: CGFloat

    // Syntax highlighting colors
    let syntaxKeyword: Color
    let syntaxString: Color
    let syntaxComment: Color
    let syntaxNumber: Color
    let syntaxFunction: Color
    let syntaxType: Color

    // Predefined themes
    static let neonDark = Theme(
        background: Color(red: 0.08, green: 0.08, blue: 0.12),
        surface: Color(red: 0.12, green: 0.12, blue: 0.18),
        elevated: Color(red: 0.16, green: 0.16, blue: 0.22),
        primaryText: .white,
        secondaryText: Color(.gray),
        accentText: Color(red: 0, green: 0.9, blue: 0.9),
        neonPrimary: Color(red: 0, green: 0.9, blue: 0.9), // Cyan
        neonSecondary: Color(red: 1, green: 0.2, blue: 0.6), // Hot pink
        neonAccent: Color(red: 0.5, green: 0, blue: 1), // Purple
        glassOpacity: 0.3,
        blurRadius: 20,
        glowIntensity: 0.8,
        borderColor: Color(red: 0, green: 0.9, blue: 0.9).opacity(0.5),
        borderWidth: 1,
        syntaxKeyword: Color(red: 1, green: 0.2, blue: 0.6),
        syntaxString: Color(red: 0, green: 0.9, blue: 0.5),
        syntaxComment: Color(.gray),
        syntaxNumber: Color(red: 0.6, green: 0.6, blue: 1),
        syntaxFunction: Color(red: 0, green: 0.9, blue: 0.9),
        syntaxType: Color(red: 1, green: 0.8, blue: 0)
    )

    static let neonBlue = Theme(
        background: Color(red: 0.05, green: 0.1, blue: 0.2),
        surface: Color(red: 0.08, green: 0.15, blue: 0.28),
        elevated: Color(red: 0.12, green: 0.2, blue: 0.35),
        primaryText: .white,
        secondaryText: Color(.gray),
        accentText: Color(red: 0.3, green: 0.6, blue: 1),
        neonPrimary: Color(red: 0.3, green: 0.6, blue: 1), // Electric blue
        neonSecondary: Color(red: 0.6, green: 0.3, blue: 1), // Purple
        neonAccent: Color(red: 0, green: 0.8, blue: 1), // Bright blue
        glassOpacity: 0.25,
        blurRadius: 24,
        glowIntensity: 0.9,
        borderColor: Color(red: 0.3, green: 0.6, blue: 1).opacity(0.6),
        borderWidth: 1.5,
        syntaxKeyword: Color(red: 0.6, green: 0.3, blue: 1),
        syntaxString: Color(red: 0.3, green: 0.9, blue: 0.6),
        syntaxComment: Color(.gray),
        syntaxNumber: Color(red: 0.5, green: 0.8, blue: 1),
        syntaxFunction: Color(red: 0.3, green: 0.6, blue: 1),
        syntaxType: Color(red: 1, green: 0.7, blue: 0.3)
    )

    static let cyberpunk = Theme(
        background: Color(red: 0.1, green: 0, blue: 0.15),
        surface: Color(red: 0.15, green: 0.05, blue: 0.2),
        elevated: Color(red: 0.2, green: 0.1, blue: 0.25),
        primaryText: Color(red: 1, green: 0, blue: 0.8),
        secondaryText: Color(.gray),
        accentText: Color(red: 1, green: 0, blue: 0.8),
        neonPrimary: Color(red: 1, green: 0, blue: 0.8), // Magenta
        neonSecondary: Color(red: 0, green: 1, blue: 0.8), // Cyan
        neonAccent: Color(red: 1, green: 0.8, blue: 0), // Yellow
        glassOpacity: 0.35,
        blurRadius: 18,
        glowIntensity: 1.0,
        borderColor: Color(red: 1, green: 0, blue: 0.8).opacity(0.7),
        borderWidth: 2,
        syntaxKeyword: Color(red: 1, green: 0, blue: 0.8),
        syntaxString: Color(red: 0, green: 1, blue: 0.8),
        syntaxComment: Color(red: 0.5, green: 0.5, blue: 0.5),
        syntaxNumber: Color(red: 1, green: 0.8, blue: 0),
        syntaxFunction: Color(red: 0.8, green: 0, blue: 1),
        syntaxType: Color(red: 1, green: 0.5, blue: 0)
    )

    static let midnight = Theme(
        background: Color.black,
        surface: Color(red: 0.05, green: 0.05, blue: 0.08),
        elevated: Color(red: 0.1, green: 0.1, blue: 0.15),
        primaryText: .white,
        secondaryText: Color(.lightGray),
        accentText: Color(red: 0.4, green: 0.7, blue: 1),
        neonPrimary: Color(red: 0.4, green: 0.7, blue: 1), // Sky blue
        neonSecondary: Color(red: 0.6, green: 0.8, blue: 1), // Light blue
        neonAccent: Color(red: 0.5, green: 0.9, blue: 1), // Bright sky
        glassOpacity: 0.2,
        blurRadius: 16,
        glowIntensity: 0.6,
        borderColor: Color(red: 0.4, green: 0.7, blue: 1).opacity(0.4),
        borderWidth: 1,
        syntaxKeyword: Color(red: 0.6, green: 0.8, blue: 1),
        syntaxString: Color(red: 0.5, green: 0.9, blue: 0.7),
        syntaxComment: Color(.gray),
        syntaxNumber: Color(red: 0.7, green: 0.7, blue: 1),
        syntaxFunction: Color(red: 0.4, green: 0.7, blue: 1),
        syntaxType: Color(red: 1, green: 0.9, blue: 0.5)
    )

    static let aurora = Theme(
        background: Color(red: 0.05, green: 0.15, blue: 0.15),
        surface: Color(red: 0.08, green: 0.2, blue: 0.2),
        elevated: Color(red: 0.12, green: 0.25, blue: 0.25),
        primaryText: .white,
        secondaryText: Color(.gray),
        accentText: Color(red: 0.4, green: 1, blue: 0.8),
        neonPrimary: Color(red: 0.4, green: 1, blue: 0.8), // Mint
        neonSecondary: Color(red: 0.6, green: 0.8, blue: 1), // Light blue
        neonAccent: Color(red: 0.8, green: 0.4, blue: 1), // Light purple
        glassOpacity: 0.28,
        blurRadius: 22,
        glowIntensity: 0.75,
        borderColor: Color(red: 0.4, green: 1, blue: 0.8).opacity(0.5),
        borderWidth: 1.2,
        syntaxKeyword: Color(red: 0.8, green: 0.4, blue: 1),
        syntaxString: Color(red: 0.4, green: 1, blue: 0.8),
        syntaxComment: Color(.gray),
        syntaxNumber: Color(red: 0.6, green: 0.8, blue: 1),
        syntaxFunction: Color(red: 0.5, green: 0.9, blue: 0.9),
        syntaxType: Color(red: 1, green: 0.8, blue: 0.4)
    )
}

// Custom view modifiers for themed components
extension View {
    func glassEffect(theme: Theme) -> some View {
        self
            .background(
                theme.surface
                    .opacity(theme.glassOpacity)
                    .blur(radius: theme.blurRadius * 0.1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(theme.borderColor, lineWidth: theme.borderWidth)
            )
            .shadow(color: theme.neonPrimary.opacity(theme.glowIntensity * 0.3), radius: 10)
    }

    func neonGlow(color: Color, intensity: Double) -> some View {
        self
            .shadow(color: color.opacity(intensity * 0.5), radius: 5)
            .shadow(color: color.opacity(intensity * 0.3), radius: 10)
            .shadow(color: color.opacity(intensity * 0.1), radius: 20)
    }
}
