//
//  GitDiffViewer.swift
//  AI Coding Suite
//
//  Advanced git diff viewer with side-by-side and inline modes
//

import SwiftUI

struct GitDiffViewer: View {
    let filePath: String
    @State private var viewMode: DiffViewMode = .sideBySide
    @State private var diff: FileDiff?
    @State private var isLoading: Bool = true
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "arrow.triangle.branch")
                    .foregroundColor(themeManager.currentTheme.neonAccent)

                Text("Diff: \(filePath)")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                Picker("View Mode", selection: $viewMode) {
                    Text("Side by Side").tag(DiffViewMode.sideBySide)
                    Text("Inline").tag(DiffViewMode.inline)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(12)
            .background(themeManager.currentTheme.surface.opacity(0.5))

            Divider()

            // Diff content
            if isLoading {
                ProgressView("Loading diff...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let diff = diff {
                if viewMode == .sideBySide {
                    SideBySideDiffView(diff: diff)
                } else {
                    InlineDiffView(diff: diff)
                }
            } else {
                Text("No changes")
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(themeManager.currentTheme.background)
        .onAppear {
            loadDiff()
        }
    }

    private func loadDiff() {
        // Simulate loading diff
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            diff = generateMockDiff()
            isLoading = false
        }
    }

    private func generateMockDiff() -> FileDiff {
        FileDiff(
            filePath: filePath,
            hunks: [
                DiffHunk(
                    oldStart: 12,
                    oldLines: 8,
                    newStart: 12,
                    newLines: 10,
                    lines: [
                        DiffLine(type: .context, content: "func initialize() {", oldLineNumber: 12, newLineNumber: 12),
                        DiffLine(type: .context, content: "    setupTheme()", oldLineNumber: 13, newLineNumber: 13),
                        DiffLine(type: .deletion, content: "    loadOldConfig()", oldLineNumber: 14, newLineNumber: nil),
                        DiffLine(type: .addition, content: "    loadNewConfig()", oldLineNumber: nil, newLineNumber: 14),
                        DiffLine(type: .addition, content: "    validateSettings()", oldLineNumber: nil, newLineNumber: 15),
                        DiffLine(type: .context, content: "    startMonitoring()", oldLineNumber: 15, newLineNumber: 16),
                        DiffLine(type: .context, content: "}", oldLineNumber: 16, newLineNumber: 17),
                    ]
                ),
                DiffHunk(
                    oldStart: 45,
                    oldLines: 5,
                    newStart: 47,
                    newLines: 8,
                    lines: [
                        DiffLine(type: .context, content: "private func handleError() {", oldLineNumber: 45, newLineNumber: 47),
                        DiffLine(type: .deletion, content: "    print(error)", oldLineNumber: 46, newLineNumber: nil),
                        DiffLine(type: .addition, content: "    logger.error(error)", oldLineNumber: nil, newLineNumber: 48),
                        DiffLine(type: .addition, content: "    showErrorDialog()", oldLineNumber: nil, newLineNumber: 49),
                        DiffLine(type: .addition, content: "    reportToAnalytics()", oldLineNumber: nil, newLineNumber: 50),
                        DiffLine(type: .context, content: "}", oldLineNumber: 47, newLineNumber: 51),
                    ]
                )
            ]
        )
    }

    enum DiffViewMode {
        case sideBySide
        case inline
    }
}

// MARK: - Side-by-Side View
struct SideBySideDiffView: View {
    let diff: FileDiff
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(diff.hunks) { hunk in
                    HunkHeaderView(hunk: hunk)

                    HStack(spacing: 0) {
                        // Old version (left)
                        VStack(spacing: 0) {
                            ForEach(hunk.lines.filter { $0.type != .addition }) { line in
                                DiffLineView(line: line, side: .old)
                            }
                        }
                        .frame(maxWidth: .infinity)

                        Divider()

                        // New version (right)
                        VStack(spacing: 0) {
                            ForEach(hunk.lines.filter { $0.type != .deletion }) { line in
                                DiffLineView(line: line, side: .new)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(8)
        }
    }
}

// MARK: - Inline View
struct InlineDiffView: View {
    let diff: FileDiff
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(diff.hunks) { hunk in
                    HunkHeaderView(hunk: hunk)

                    VStack(spacing: 0) {
                        ForEach(hunk.lines) { line in
                            InlineDiffLineView(line: line)
                        }
                    }
                }
            }
            .padding(8)
        }
    }
}

// MARK: - Hunk Header
struct HunkHeaderView: View {
    let hunk: DiffHunk
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack {
            Text("@@ -\(hunk.oldStart),\(hunk.oldLines) +\(hunk.newStart),\(hunk.newLines) @@")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(themeManager.currentTheme.neonAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(themeManager.currentTheme.neonAccent.opacity(0.1))
                .cornerRadius(4)

            Spacer()
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Diff Line View
struct DiffLineView: View {
    let line: DiffLine
    let side: DiffSide
    @EnvironmentObject var themeManager: ThemeManager

    var lineNumber: Int? {
        side == .old ? line.oldLineNumber : line.newLineNumber
    }

    var showLine: Bool {
        if side == .old {
            return line.type != .addition
        } else {
            return line.type != .deletion
        }
    }

    var body: some View {
        if showLine {
            HStack(spacing: 8) {
                // Line number
                Text(lineNumber.map { "\($0)" } ?? " ")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.5))
                    .frame(width: 40, alignment: .trailing)
                    .padding(.leading, 8)

                // Content
                Text(line.content)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(line.type.textColor(theme: themeManager.currentTheme))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.trailing, 8)
            }
            .frame(height: 20)
            .background(line.type.backgroundColor(theme: themeManager.currentTheme))
        }
    }

    enum DiffSide {
        case old, new
    }
}

// MARK: - Inline Diff Line
struct InlineDiffLineView: View {
    let line: DiffLine
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            // Old line number
            Text(line.oldLineNumber.map { "\($0)" } ?? " ")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.5))
                .frame(width: 40, alignment: .trailing)

            // New line number
            Text(line.newLineNumber.map { "\($0)" } ?? " ")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.5))
                .frame(width: 40, alignment: .trailing)

            // Indicator
            Text(line.type.indicator)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(line.type.textColor(theme: themeManager.currentTheme))
                .frame(width: 20)

            // Content
            Text(line.content)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(line.type.textColor(theme: themeManager.currentTheme))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
        }
        .frame(height: 20)
        .background(line.type.backgroundColor(theme: themeManager.currentTheme))
    }
}

// MARK: - Models

struct FileDiff: Identifiable {
    let id = UUID()
    let filePath: String
    let hunks: [DiffHunk]
}

struct DiffHunk: Identifiable {
    let id = UUID()
    let oldStart: Int
    let oldLines: Int
    let newStart: Int
    let newLines: Int
    let lines: [DiffLine]
}

struct DiffLine: Identifiable {
    let id = UUID()
    let type: DiffLineType
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?
}

enum DiffLineType {
    case addition
    case deletion
    case context

    var indicator: String {
        switch self {
        case .addition: return "+"
        case .deletion: return "-"
        case .context: return " "
        }
    }

    func backgroundColor(theme: AppTheme) -> Color {
        switch self {
        case .addition: return .green.opacity(0.15)
        case .deletion: return .red.opacity(0.15)
        case .context: return Color.clear
        }
    }

    func textColor(theme: AppTheme) -> Color {
        switch self {
        case .addition: return .green
        case .deletion: return .red
        case .context: return theme.textPrimary
        }
    }
}

// MARK: - Git Blame View
struct GitBlameView: View {
    let filePath: String
    @State private var blameInfo: [BlameInfo] = []
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                Text("Blame: \(filePath)")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                Spacer()
            }
            .padding(12)
            .background(themeManager.currentTheme.surface.opacity(0.5))

            Divider()

            // Blame lines
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(blameInfo) { blame in
                        BlameLineView(blame: blame)
                    }
                }
            }
        }
        .background(themeManager.currentTheme.background)
        .onAppear {
            loadBlameInfo()
        }
    }

    private func loadBlameInfo() {
        // Mock data
        blameInfo = (1...50).map { line in
            BlameInfo(
                lineNumber: line,
                commit: "abc1234",
                author: "John Doe",
                date: Date().addingTimeInterval(-Double.random(in: 0...86400*30)),
                content: "Line \(line) content here"
            )
        }
    }
}

struct BlameLineView: View {
    let blame: BlameInfo
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 8) {
            // Commit info
            VStack(alignment: .leading, spacing: 2) {
                Text(blame.commit)
                    .font(.system(size: 10, design: .monospaced))
                Text(blame.author)
                    .font(.caption2)
                Text(blame.date, style: .relative)
                    .font(.caption2)
            }
            .foregroundColor(themeManager.currentTheme.textSecondary)
            .frame(width: 120, alignment: .leading)
            .padding(.leading, 8)

            Divider()

            // Line number
            Text("\(blame.lineNumber)")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.5))
                .frame(width: 40, alignment: .trailing)

            // Content
            Text(blame.content)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(themeManager.currentTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, 8)
        }
        .frame(height: 24)
        .background(themeManager.currentTheme.surface.opacity(0.2))
    }
}

struct BlameInfo: Identifiable {
    let id = UUID()
    let lineNumber: Int
    let commit: String
    let author: String
    let date: Date
    let content: String
}
