//
//  CodeEditorView.swift
//  AICodingSuite2
//
//  Created by Claude
//

import SwiftUI

struct CodeEditorView: View {
    @ObservedObject var workspace = WorkspaceManager.shared
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            if !workspace.openFiles.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(workspace.openFiles) { file in
                            TabView(file: file, themeManager: themeManager)
                        }
                    }
                }
                .frame(height: 36)
                .background(themeManager.currentTheme.elevated)

                Divider()
                    .overlay(themeManager.currentTheme.borderColor)
            }

            // Editor content
            if let selectedFile = workspace.selectedFile {
                EditorContent(file: selectedFile, themeManager: themeManager, settings: settings)
            } else {
                EmptyEditorView(themeManager: themeManager)
            }
        }
        .background(themeManager.currentTheme.background)
    }
}

struct TabView: View {
    let file: WorkspaceFile
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var workspace = WorkspaceManager.shared
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "doc.text")
                .font(.system(size: 11))
                .foregroundColor(
                    workspace.selectedFile?.id == file.id
                        ? themeManager.currentTheme.neonPrimary
                        : themeManager.currentTheme.secondaryText
                )

            Text(file.name)
                .font(.system(size: 12))
                .foregroundColor(
                    workspace.selectedFile?.id == file.id
                        ? themeManager.currentTheme.primaryText
                        : themeManager.currentTheme.secondaryText
                )

            Button(action: {
                workspace.closeFile(file)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10))
                    .foregroundColor(themeManager.currentTheme.secondaryText)
            }
            .buttonStyle(.plain)
            .opacity(isHovered ? 1 : 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            workspace.selectedFile?.id == file.id
                ? themeManager.currentTheme.surface
                : (isHovered ? themeManager.currentTheme.surface.opacity(0.5) : Color.clear)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            workspace.selectedFile = file
        }
    }
}

struct EditorContent: View {
    let file: WorkspaceFile
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var settings: AppSettings
    @ObservedObject var workspace = WorkspaceManager.shared
    @State private var text: String = ""
    @State private var lineCount: Int = 1

    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 0) {
                // Line numbers
                if settings.showLineNumbers {
                    LineNumbersView(
                        count: lineCount,
                        themeManager: themeManager,
                        fontSize: settings.fontSize
                    )
                    .frame(width: 50)
                }

                // Text editor
                SyntaxHighlightedTextEditor(
                    text: $text,
                    file: file,
                    theme: themeManager.currentTheme,
                    fontSize: settings.fontSize
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onChange(of: text) { newValue in
                    lineCount = newValue.components(separatedBy: "\n").count
                    if settings.autoSave {
                        workspace.saveFile(file, contents: newValue)
                    }
                }
            }
        }
        .onAppear {
            if let contents = workspace.fileContents[file.path] {
                text = contents
            } else {
                workspace.loadFileContents(file)
                text = workspace.fileContents[file.path] ?? ""
            }
            lineCount = text.components(separatedBy: "\n").count
        }
    }
}

struct LineNumbersView: View {
    let count: Int
    @ObservedObject var themeManager: ThemeManager
    let fontSize: Double

    var body: some View {
        ScrollView {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...max(1, count), id: \.self) { lineNumber in
                    Text("\(lineNumber)")
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(themeManager.currentTheme.secondaryText.opacity(0.6))
                        .frame(height: fontSize + 6)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        }
        .background(themeManager.currentTheme.elevated.opacity(0.3))
    }
}

struct SyntaxHighlightedTextEditor: View {
    @Binding var text: String
    let file: WorkspaceFile
    let theme: Theme
    let fontSize: Double

    var body: some View {
        TextEditor(text: $text)
            .font(.system(size: fontSize, design: .monospaced))
            .foregroundColor(theme.primaryText)
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .padding(8)
    }
}

struct EmptyEditorView: View {
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 64))
                .foregroundColor(themeManager.currentTheme.secondaryText.opacity(0.3))

            VStack(spacing: 8) {
                Text("No file selected")
                    .font(.title3)
                    .foregroundColor(themeManager.currentTheme.primaryText)

                Text("Open a file from the explorer to start editing")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(themeManager.currentTheme.background)
    }
}
