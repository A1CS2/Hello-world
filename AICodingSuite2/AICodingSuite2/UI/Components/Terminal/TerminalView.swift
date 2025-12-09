//
//  TerminalView.swift
//  AICodingSuite2
//
//  Created by Claude
//

import SwiftUI

struct TerminalView: View {
    @ObservedObject var themeManager: ThemeManager
    @State private var commandHistory: [TerminalCommand] = []
    @State private var currentCommand: String = ""
    @State private var workingDirectory: String = FileManager.default.currentDirectoryPath

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "terminal")
                    .foregroundColor(themeManager.currentTheme.neonPrimary)

                Text("TERMINAL")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.secondaryText)

                Spacer()

                Text(workingDirectory)
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryText.opacity(0.6))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Button(action: clearTerminal) {
                    Image(systemName: "trash")
                        .foregroundColor(themeManager.currentTheme.neonSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(themeManager.currentTheme.elevated)

            Divider()
                .overlay(themeManager.currentTheme.borderColor)

            // Terminal output
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(commandHistory) { cmd in
                            TerminalCommandView(command: cmd, theme: themeManager.currentTheme)
                        }

                        // Current input
                        HStack(spacing: 8) {
                            Text("❯")
                                .foregroundColor(themeManager.currentTheme.neonPrimary)
                                .font(.system(size: 14, design: .monospaced))

                            TextField("", text: $currentCommand)
                                .textFieldStyle(.plain)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(themeManager.currentTheme.primaryText)
                                .onSubmit {
                                    executeCommand()
                                }
                                .id("input")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                    }
                    .padding(.vertical, 8)
                }
                .background(themeManager.currentTheme.background)
                .onChange(of: commandHistory.count) { _ in
                    withAnimation {
                        proxy.scrollTo("input", anchor: .bottom)
                    }
                }
            }
        }
        .onAppear {
            // Add welcome message
            let welcome = TerminalCommand(
                input: "",
                output: "AI Coding Suite Terminal v1.0\nType 'help' for available commands\n",
                isError: false
            )
            commandHistory.append(welcome)
        }
    }

    private func executeCommand() {
        guard !currentCommand.isEmpty else { return }

        let cmd = TerminalCommand(
            input: currentCommand,
            output: runCommand(currentCommand),
            isError: false
        )
        commandHistory.append(cmd)
        currentCommand = ""
    }

    private func runCommand(_ command: String) -> String {
        let parts = command.split(separator: " ").map(String.init)
        guard let mainCmd = parts.first else { return "" }

        switch mainCmd.lowercased() {
        case "help":
            return """
            Available commands:
              help     - Show this help message
              clear    - Clear terminal
              pwd      - Print working directory
              echo     - Echo text
              ls       - List files (simulated)
              cd       - Change directory (simulated)

            Note: Full terminal execution coming soon!
            """

        case "clear":
            commandHistory.removeAll()
            return ""

        case "pwd":
            return workingDirectory

        case "echo":
            return parts.dropFirst().joined(separator: " ")

        case "ls":
            return """
            file1.swift
            file2.py
            folder/
            README.md

            (Simulated output - real execution coming soon)
            """

        case "cd":
            if parts.count > 1 {
                workingDirectory = parts[1]
                return ""
            }
            return "Usage: cd <directory>"

        default:
            return "Command not found: \(mainCmd)\nType 'help' for available commands"
        }
    }

    private func clearTerminal() {
        commandHistory.removeAll()
    }
}

struct TerminalCommand: Identifiable {
    let id = UUID()
    let input: String
    let output: String
    let isError: Bool
    let timestamp = Date()
}

struct TerminalCommandView: View {
    let command: TerminalCommand
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if !command.input.isEmpty {
                HStack(spacing: 8) {
                    Text("❯")
                        .foregroundColor(theme.neonPrimary)
                        .font(.system(size: 14, design: .monospaced))

                    Text(command.input)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundColor(theme.primaryText)
                }
                .padding(.horizontal, 12)
            }

            if !command.output.isEmpty {
                Text(command.output)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(command.isError ? theme.neonSecondary : theme.secondaryText)
                    .padding(.horizontal, 12)
                    .padding(.leading, 24)
            }
        }
    }
}
