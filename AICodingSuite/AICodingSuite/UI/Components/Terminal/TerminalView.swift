//
//  TerminalView.swift
//  AI Coding Suite
//
//  Embedded terminal with AI command suggestions
//

import SwiftUI

struct TerminalView: View {
    @State private var terminalOutput: [TerminalLine] = []
    @State private var currentInput: String = ""
    @State private var showAISuggestion: Bool = false
    @State private var aiSuggestion: String = ""
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Terminal header
            TerminalHeader()

            // Terminal content
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(terminalOutput) { line in
                        TerminalLineView(line: line)
                    }

                    // Current input line
                    HStack(spacing: 8) {
                        Text("❯")
                            .foregroundColor(themeManager.currentTheme.neonAccent)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))

                        TextField("", text: $currentInput)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, design: .monospaced))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                            .onSubmit {
                                executeCommand()
                            }
                            .onChange(of: currentInput) { _, newValue in
                                checkForAISuggestion(newValue)
                            }
                    }

                    // AI suggestion
                    if showAISuggestion && !aiSuggestion.isEmpty {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.caption2)
                                .foregroundColor(themeManager.currentTheme.neonAccent)

                            Text("AI suggests: \(aiSuggestion)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(themeManager.currentTheme.neonAccent.opacity(0.7))

                            Spacer()

                            Text("Press → to accept")
                                .font(.caption2)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(
                            themeManager.currentTheme.neonAccent.opacity(0.1)
                        )
                        .cornerRadius(4)
                    }
                }
                .padding(12)
            }
            .background(themeManager.currentTheme.background.opacity(0.5))
        }
        .background(themeManager.currentTheme.surface.opacity(0.8))
        .onAppear {
            // Demo output
            terminalOutput = [
                TerminalLine(id: UUID(), content: "Welcome to AI Terminal", type: .system),
                TerminalLine(id: UUID(), content: "Type 'help' for available commands", type: .system),
                TerminalLine(id: UUID(), content: "❯ ls -la", type: .input),
                TerminalLine(id: UUID(), content: "total 48", type: .output),
                TerminalLine(id: UUID(), content: "drwxr-xr-x  12 user  staff   384 Nov 23 10:30 .", type: .output),
                TerminalLine(id: UUID(), content: "drwxr-xr-x   8 user  staff   256 Nov 22 15:20 ..", type: .output),
            ]
        }
    }

    private func executeCommand() {
        guard !currentInput.isEmpty else { return }

        terminalOutput.append(
            TerminalLine(id: UUID(), content: "❯ \(currentInput)", type: .input)
        )

        // Simulate command execution
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            terminalOutput.append(
                TerminalLine(
                    id: UUID(),
                    content: "Executed: \(currentInput)",
                    type: .output
                )
            )
        }

        currentInput = ""
        showAISuggestion = false
    }

    private func checkForAISuggestion(_ input: String) {
        // Simulate AI suggestion
        if input.contains("git") && !input.contains("commit") {
            aiSuggestion = "git commit -m 'message'"
            showAISuggestion = true
        } else if input.contains("npm") {
            aiSuggestion = "npm install"
            showAISuggestion = true
        } else {
            showAISuggestion = false
        }
    }
}

// MARK: - Terminal Header
struct TerminalHeader: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "terminal.fill")
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                Text("Terminal")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "plus.circle")
                }
                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                }
                Button(action: {}) {
                    Image(systemName: "trash")
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(themeManager.currentTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeManager.currentTheme.surface)
    }
}

// MARK: - Terminal Line View
struct TerminalLineView: View {
    let line: TerminalLine
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Text(line.content)
            .font(.system(size: 14, design: .monospaced))
            .foregroundColor(line.type.color(theme: themeManager.currentTheme))
    }
}

// MARK: - Models
struct TerminalLine: Identifiable {
    let id: UUID
    let content: String
    let type: LineType

    enum LineType {
        case input, output, error, system

        func color(theme: AppTheme) -> Color {
            switch self {
            case .input: return theme.neonAccent
            case .output: return theme.textPrimary
            case .error: return .red
            case .system: return theme.textSecondary
            }
        }
    }
}
