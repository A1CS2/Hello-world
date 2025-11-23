//
//  Sidebars.swift
//  AI Coding Suite
//
//  Left and right sidebar components
//

import SwiftUI

// MARK: - Left Sidebar
struct LeftSidebar: View {
    @Binding var showFileExplorer: Bool
    @Binding var showGitPanel: Bool
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // File Explorer
            if showFileExplorer {
                FileExplorerView()
                Divider()
            }

            // Git Panel
            if showGitPanel {
                GitPanelView()
            }

            Spacer()
        }
        .background(themeManager.currentTheme.surface.opacity(0.6))
    }
}

// MARK: - Right Sidebar
struct RightSidebar: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            AIChatPanelView()
        }
        .background(themeManager.currentTheme.surface.opacity(0.6))
    }
}

// MARK: - File Explorer
struct FileExplorerView: View {
    @State private var expandedFolders: Set<String> = []
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "folder.fill")
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                Text("Explorer")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "plus.circle")
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(themeManager.currentTheme.surface)

            // File tree
            ScrollView {
                VStack(alignment: .leading, spacing: 4) {
                    FileTreeItem(
                        name: "AICodingSuite",
                        icon: "folder.fill",
                        level: 0,
                        isFolder: true
                    )
                    FileTreeItem(
                        name: "UI",
                        icon: "folder.fill",
                        level: 1,
                        isFolder: true
                    )
                    FileTreeItem(
                        name: "ModularFramework",
                        icon: "folder.fill",
                        level: 2,
                        isFolder: true
                    )
                    FileTreeItem(
                        name: "DraggablePanel.swift",
                        icon: "doc.text",
                        level: 3,
                        isFolder: false
                    )
                    FileTreeItem(
                        name: "LayoutManager.swift",
                        icon: "doc.text",
                        level: 3,
                        isFolder: false
                    )
                    FileTreeItem(
                        name: "Components",
                        icon: "folder.fill",
                        level: 2,
                        isFolder: true
                    )
                    FileTreeItem(
                        name: "README.md",
                        icon: "doc.richtext",
                        level: 1,
                        isFolder: false
                    )
                }
                .padding(8)
            }
        }
        .frame(maxHeight: .infinity)
    }
}

struct FileTreeItem: View {
    let name: String
    let icon: String
    let level: Int
    let isFolder: Bool
    @State private var isExpanded: Bool = true
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: {
            if isFolder {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 6) {
                if isFolder {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(
                        isFolder ?
                        themeManager.currentTheme.neonAccent :
                        themeManager.currentTheme.textSecondary
                    )

                Text(name)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()
            }
            .padding(.leading, CGFloat(level * 16))
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Git Panel
struct GitPanelView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                Text("Source Control")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(themeManager.currentTheme.surface)

            // Changes list
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CHANGES (3)")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.top, 8)

                    GitChangeItem(
                        file: "AICodingSuiteApp.swift",
                        status: .modified
                    )
                    GitChangeItem(
                        file: "ThemeManager.swift",
                        status: .modified
                    )
                    GitChangeItem(
                        file: "NewFile.swift",
                        status: .added
                    )
                }
                .padding(.bottom, 8)
            }

            Divider()

            // Commit section
            VStack(spacing: 8) {
                TextField("Commit message", text: .constant(""))
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(themeManager.currentTheme.background.opacity(0.5))
                    .cornerRadius(6)

                Button(action: {}) {
                    Text("Commit")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .tint(themeManager.currentTheme.neonAccent)
            }
            .padding(12)
        }
        .frame(maxHeight: .infinity)
    }
}

struct GitChangeItem: View {
    let file: String
    let status: GitStatus
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            Text(status.symbol)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(status.color)
                .frame(width: 20)

            Text(file)
                .font(.system(size: 13))
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    enum GitStatus {
        case modified, added, deleted

        var symbol: String {
            switch self {
            case .modified: return "M"
            case .added: return "A"
            case .deleted: return "D"
            }
        }

        var color: Color {
            switch self {
            case .modified: return .orange
            case .added: return .green
            case .deleted: return .red
            }
        }
    }
}

// MARK: - AI Chat Panel
struct AIChatPanelView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                Text("AI Assistant")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                Button(action: {}) {
                    Image(systemName: "trash")
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(themeManager.currentTheme.surface)

            Divider()

            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { message in
                        ChatMessageView(message: message)
                    }
                }
                .padding(12)
            }

            Divider()

            // Input
            HStack(spacing: 8) {
                TextField("Ask AI anything...", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(8)
                    .background(themeManager.currentTheme.background.opacity(0.5))
                    .cornerRadius(6)

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.neonAccent)
                }
                .buttonStyle(.plain)
                .disabled(inputText.isEmpty)
            }
            .padding(12)
        }
        .onAppear {
            // Demo messages
            messages = [
                ChatMessage(
                    id: UUID(),
                    content: "Hello! I'm your AI coding assistant. How can I help you today?",
                    isUser: false,
                    timestamp: Date()
                )
            ]
        }
    }

    private func sendMessage() {
        guard !inputText.isEmpty else { return }

        messages.append(
            ChatMessage(
                id: UUID(),
                content: inputText,
                isUser: true,
                timestamp: Date()
            )
        )

        let userInput = inputText
        inputText = ""

        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            messages.append(
                ChatMessage(
                    id: UUID(),
                    content: "I understand you're asking about '\(userInput)'. Let me help you with that...",
                    isUser: false,
                    timestamp: Date()
                )
            )
        }
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.isUser {
                Spacer()
            }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .padding(10)
                    .background(
                        message.isUser ?
                        themeManager.currentTheme.neonAccent.opacity(0.2) :
                        themeManager.currentTheme.surface
                    )
                    .cornerRadius(12)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
}
