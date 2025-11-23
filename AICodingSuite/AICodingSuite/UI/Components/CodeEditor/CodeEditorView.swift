//
//  CodeEditorView.swift
//  AI Coding Suite
//
//  Code editor with syntax highlighting and AI features
//

import SwiftUI

struct CodeEditorView: View {
    let file: OpenFile
    @State private var code: String
    @State private var cursorPosition: Int = 0
    @State private var showAICompletion: Bool = false
    @EnvironmentObject var themeManager: ThemeManager

    init(file: OpenFile) {
        self.file = file
        self._code = State(initialValue: file.content)
    }

    var body: some View {
        HSplitView {
            // Line numbers
            LineNumbersView(lineCount: code.components(separatedBy: "\n").count)
                .frame(width: 50)

            // Code area
            ZStack(alignment: .topLeading) {
                // Background
                themeManager.currentTheme.background
                    .opacity(0.3)

                // Text editor (simplified - would use NSTextView in production)
                TextEditor(text: $code)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .overlay(
                        SyntaxHighlightedText(
                            code: code,
                            language: file.language
                        )
                    )

                // AI completion overlay
                if showAICompletion {
                    AICompletionOverlay()
                }
            }
        }
        .background(themeManager.currentTheme.background)
    }
}

// MARK: - Line Numbers View
struct LineNumbersView: View {
    let lineCount: Int
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            ForEach(1...lineCount, id: \.self) { lineNumber in
                Text("\(lineNumber)")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.5))
                    .frame(height: 18)
            }
            Spacer()
        }
        .padding(.top, 8)
        .padding(.trailing, 8)
        .background(themeManager.currentTheme.surface.opacity(0.3))
    }
}

// MARK: - Syntax Highlighted Text (Simplified)
struct SyntaxHighlightedText: View {
    let code: String
    let language: ProgrammingLanguage

    var body: some View {
        // Note: This is a simplified version
        // Production would use TreeSitter or other advanced parsing
        Text("")
            .hidden()
    }
}

// MARK: - AI Completion Overlay
struct AICompletionOverlay: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                Text("AI Suggestion")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Text("func calculateTotal() -> Double {")
                .font(.system(size: 14, design: .monospaced))
                .foregroundColor(themeManager.currentTheme.neonAccent.opacity(0.7))
                .padding(.leading, 16)

            Text("Press Tab to accept")
                .font(.caption2)
                .foregroundColor(themeManager.currentTheme.textSecondary)
        }
        .padding(12)
        .background(
            themeManager.currentTheme.surface
                .opacity(0.95)
                .blur(radius: 10)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(themeManager.currentTheme.neonAccent.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: themeManager.currentTheme.neonAccent.opacity(0.3), radius: 15)
        .padding()
    }
}
