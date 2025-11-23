//
//  CommandPalette.swift
//  AI Coding Suite
//
//  Command palette with fuzzy search and action execution
//

import SwiftUI

struct CommandPalette: View {
    @Binding var isPresented: Bool
    @State private var searchQuery: String = ""
    @State private var selectedIndex: Int = 0
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var commandManager = CommandManager()

    var filteredCommands: [Command] {
        if searchQuery.isEmpty {
            return commandManager.allCommands
        }
        return commandManager.allCommands.filter { command in
            fuzzyMatch(query: searchQuery.lowercased(), target: command.title.lowercased()) ||
            command.keywords.contains { fuzzyMatch(query: searchQuery.lowercased(), target: $0.lowercased()) }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search input
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                    .font(.title3)

                TextField("Type a command...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .onSubmit {
                        executeSelectedCommand()
                    }

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .background(themeManager.currentTheme.surface.opacity(0.8))

            Divider()

            // Command results
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                        CommandRow(
                            command: command,
                            isSelected: index == selectedIndex,
                            searchQuery: searchQuery
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedIndex = index
                            executeSelectedCommand()
                        }
                        .background(
                            index == selectedIndex ?
                            themeManager.currentTheme.neonAccent.opacity(0.2) :
                            Color.clear
                        )
                    }

                    if filteredCommands.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.5))

                            Text("No commands found")
                                .font(.headline)
                                .foregroundColor(themeManager.currentTheme.textSecondary)

                            Text("Try a different search term")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(40)
                    }
                }
            }
            .frame(maxHeight: 400)
            .background(themeManager.currentTheme.background.opacity(0.95))
        }
        .frame(width: 600)
        .background(
            themeManager.currentTheme.surface
                .opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(16)
        .shadow(color: themeManager.currentTheme.neonAccent.opacity(0.3), radius: 30)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(themeManager.currentTheme.neonAccent.opacity(0.5), lineWidth: 2)
        )
        .onAppear {
            selectedIndex = 0
        }
        .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            selectedIndex = min(filteredCommands.count - 1, selectedIndex + 1)
            return .handled
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }

    private func executeSelectedCommand() {
        guard selectedIndex < filteredCommands.count else { return }
        let command = filteredCommands[selectedIndex]
        command.action()
        isPresented = false
        searchQuery = ""
    }

    private func fuzzyMatch(query: String, target: String) -> Bool {
        var queryIndex = query.startIndex
        var targetIndex = target.startIndex

        while queryIndex < query.endIndex && targetIndex < target.endIndex {
            if query[queryIndex] == target[targetIndex] {
                queryIndex = query.index(after: queryIndex)
            }
            targetIndex = target.index(after: targetIndex)
        }

        return queryIndex == query.endIndex
    }
}

// MARK: - Command Row
struct CommandRow: View {
    let command: Command
    let isSelected: Bool
    let searchQuery: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: command.icon)
                .font(.title3)
                .foregroundColor(
                    isSelected ?
                    themeManager.currentTheme.neonAccent :
                    themeManager.currentTheme.textSecondary
                )
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                // Title with highlighting
                Text(command.title)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                // Description
                Text(command.description)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Spacer()

            // Keyboard shortcut
            if let shortcut = command.shortcut {
                Text(shortcut)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.currentTheme.surface.opacity(0.5))
                    .cornerRadius(4)
            }

            // Category badge
            Text(command.category.rawValue)
                .font(.caption2)
                .foregroundColor(command.category.color)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(command.category.color.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Command Manager
class CommandManager: ObservableObject {
    @Published var allCommands: [Command] = []

    init() {
        loadCommands()
    }

    private func loadCommands() {
        allCommands = [
            // File operations
            Command(
                id: "new-file",
                title: "New File",
                description: "Create a new file",
                icon: "doc.badge.plus",
                category: .file,
                keywords: ["create", "new", "file"],
                shortcut: "⌘N",
                action: { print("Create new file") }
            ),
            Command(
                id: "open-file",
                title: "Open File",
                description: "Open an existing file",
                icon: "doc",
                category: .file,
                keywords: ["open", "file"],
                shortcut: "⌘O",
                action: { print("Open file") }
            ),
            Command(
                id: "save-file",
                title: "Save File",
                description: "Save the current file",
                icon: "square.and.arrow.down",
                category: .file,
                keywords: ["save", "file"],
                shortcut: "⌘S",
                action: { print("Save file") }
            ),

            // Edit operations
            Command(
                id: "find",
                title: "Find in File",
                description: "Search in current file",
                icon: "magnifyingglass",
                category: .edit,
                keywords: ["find", "search"],
                shortcut: "⌘F",
                action: { print("Find in file") }
            ),
            Command(
                id: "replace",
                title: "Find and Replace",
                description: "Search and replace in current file",
                icon: "arrow.left.arrow.right",
                category: .edit,
                keywords: ["find", "replace", "search"],
                shortcut: "⌘⌥F",
                action: { print("Find and replace") }
            ),
            Command(
                id: "multi-file-search",
                title: "Search in All Files",
                description: "Search across entire workspace",
                icon: "doc.text.magnifyingglass",
                category: .edit,
                keywords: ["find", "search", "workspace", "global"],
                shortcut: "⌘⇧F",
                action: { print("Multi-file search") }
            ),

            // View operations
            Command(
                id: "toggle-sidebar",
                title: "Toggle Sidebar",
                description: "Show or hide the sidebar",
                icon: "sidebar.left",
                category: .view,
                keywords: ["toggle", "sidebar"],
                shortcut: "⌘B",
                action: { print("Toggle sidebar") }
            ),
            Command(
                id: "toggle-terminal",
                title: "Toggle Terminal",
                description: "Show or hide the terminal",
                icon: "terminal",
                category: .view,
                keywords: ["toggle", "terminal", "console"],
                shortcut: "⌘`",
                action: { print("Toggle terminal") }
            ),
            Command(
                id: "toggle-ai",
                title: "Toggle AI Panel",
                description: "Show or hide AI assistant",
                icon: "sparkles",
                category: .view,
                keywords: ["toggle", "ai", "assistant"],
                shortcut: "⌘⇧I",
                action: { print("Toggle AI panel") }
            ),

            // AI operations
            Command(
                id: "ai-chat",
                title: "Ask AI",
                description: "Open AI chat assistant",
                icon: "sparkles",
                category: .ai,
                keywords: ["ai", "chat", "ask"],
                shortcut: "⌘K",
                action: { print("AI chat") }
            ),
            Command(
                id: "ai-explain",
                title: "Explain Code",
                description: "Get AI explanation of selected code",
                icon: "text.bubble",
                category: .ai,
                keywords: ["ai", "explain", "code"],
                shortcut: "⌘⇧E",
                action: { print("AI explain") }
            ),
            Command(
                id: "ai-refactor",
                title: "Refactor Code",
                description: "AI-assisted code refactoring",
                icon: "arrow.triangle.2.circlepath",
                category: .ai,
                keywords: ["ai", "refactor", "improve"],
                shortcut: "⌘⇧R",
                action: { print("AI refactor") }
            ),
            Command(
                id: "ai-fix",
                title: "Fix Errors",
                description: "AI-powered error fixing",
                icon: "wrench.and.screwdriver",
                category: .ai,
                keywords: ["ai", "fix", "error", "debug"],
                shortcut: "⌘⇧F",
                action: { print("AI fix errors") }
            ),
            Command(
                id: "ai-complete",
                title: "Toggle AI Completion",
                description: "Enable or disable AI code completion",
                icon: "wand.and.stars",
                category: .ai,
                keywords: ["ai", "completion", "autocomplete"],
                shortcut: nil,
                action: { print("Toggle AI completion") }
            ),

            // Git operations
            Command(
                id: "git-commit",
                title: "Git Commit",
                description: "Commit staged changes",
                icon: "checkmark.circle",
                category: .git,
                keywords: ["git", "commit"],
                shortcut: nil,
                action: { print("Git commit") }
            ),
            Command(
                id: "git-push",
                title: "Git Push",
                description: "Push commits to remote",
                icon: "arrow.up.circle",
                category: .git,
                keywords: ["git", "push"],
                shortcut: nil,
                action: { print("Git push") }
            ),
            Command(
                id: "git-pull",
                title: "Git Pull",
                description: "Pull changes from remote",
                icon: "arrow.down.circle",
                category: .git,
                keywords: ["git", "pull"],
                shortcut: nil,
                action: { print("Git pull") }
            ),
            Command(
                id: "git-diff",
                title: "Show Git Diff",
                description: "View file changes",
                icon: "square.split.2x1",
                category: .git,
                keywords: ["git", "diff", "changes"],
                shortcut: nil,
                action: { print("Git diff") }
            ),

            // Debug operations
            Command(
                id: "debug-start",
                title: "Start Debugging",
                description: "Start debug session",
                icon: "play.circle",
                category: .debug,
                keywords: ["debug", "start", "run"],
                shortcut: "F5",
                action: { print("Start debugging") }
            ),
            Command(
                id: "debug-stop",
                title: "Stop Debugging",
                description: "Stop debug session",
                icon: "stop.circle",
                category: .debug,
                keywords: ["debug", "stop"],
                shortcut: "⇧F5",
                action: { print("Stop debugging") }
            ),
            Command(
                id: "toggle-breakpoint",
                title: "Toggle Breakpoint",
                description: "Add or remove breakpoint",
                icon: "circle.fill",
                category: .debug,
                keywords: ["breakpoint", "debug"],
                shortcut: "F9",
                action: { print("Toggle breakpoint") }
            ),

            // Settings
            Command(
                id: "settings",
                title: "Open Settings",
                description: "Open application settings",
                icon: "gearshape",
                category: .settings,
                keywords: ["settings", "preferences", "config"],
                shortcut: "⌘,",
                action: { print("Open settings") }
            ),
            Command(
                id: "theme",
                title: "Change Theme",
                description: "Select a different theme",
                icon: "paintbrush",
                category: .settings,
                keywords: ["theme", "color", "appearance"],
                shortcut: nil,
                action: { print("Change theme") }
            ),
        ]
    }
}

// MARK: - Command Model
struct Command: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let category: CommandCategory
    let keywords: [String]
    let shortcut: String?
    let action: () -> Void

    enum CommandCategory: String {
        case file = "File"
        case edit = "Edit"
        case view = "View"
        case ai = "AI"
        case git = "Git"
        case debug = "Debug"
        case settings = "Settings"

        var color: Color {
            switch self {
            case .file: return .blue
            case .edit: return .green
            case .view: return .purple
            case .ai: return .pink
            case .git: return .orange
            case .debug: return .red
            case .settings: return .gray
            }
        }
    }
}
