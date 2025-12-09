//
//  FileExplorerView.swift
//  AICodingSuite2
//
//  Created by Claude
//

import SwiftUI

struct FileExplorerView: View {
    @ObservedObject var workspace = WorkspaceManager.shared
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("EXPLORER")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.secondaryText)

                Spacer()

                Button(action: openFolder) {
                    Image(systemName: "folder.badge.plus")
                        .foregroundColor(themeManager.currentTheme.neonPrimary)
                }
                .buttonStyle(.plain)

                Button(action: newFile) {
                    Image(systemName: "doc.badge.plus")
                        .foregroundColor(themeManager.currentTheme.neonPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(themeManager.currentTheme.elevated)

            Divider()
                .overlay(themeManager.currentTheme.borderColor)

            // File tree
            ScrollView {
                if workspace.files.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundColor(themeManager.currentTheme.secondaryText.opacity(0.5))

                        Text("No folder open")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.secondaryText)

                        Button("Open Folder") {
                            openFolder()
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(themeManager.currentTheme.neonPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(workspace.files) { file in
                            FileTreeItem(file: file, level: 0, themeManager: themeManager)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(minWidth: 200)
        .background(themeManager.currentTheme.surface)
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            workspace.openWorkspace(url: url)
        }
    }

    private func newFile() {
        workspace.createNewFile(name: "untitled.txt")
    }
}

struct FileTreeItem: View {
    let file: WorkspaceFile
    let level: Int
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var workspace = WorkspaceManager.shared
    @State private var isExpanded: Bool = false
    @State private var isHovered: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File/folder row
            HStack(spacing: 4) {
                // Indentation
                ForEach(0..<level, id: \.self) { _ in
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 16)
                }

                // Disclosure triangle for folders
                if file.type == .folder {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(themeManager.currentTheme.secondaryText)
                        .frame(width: 12)
                }

                // Icon
                Image(systemName: file.type == .folder ? (isExpanded ? "folder.fill" : "folder") : "doc.text")
                    .font(.system(size: 14))
                    .foregroundColor(file.type == .folder ? themeManager.currentTheme.neonSecondary : themeManager.currentTheme.neonPrimary)

                // Name
                Text(file.name)
                    .font(.system(size: 12))
                    .foregroundColor(
                        workspace.selectedFile?.id == file.id
                            ? themeManager.currentTheme.neonPrimary
                            : themeManager.currentTheme.primaryText
                    )

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                workspace.selectedFile?.id == file.id
                    ? themeManager.currentTheme.neonPrimary.opacity(0.1)
                    : (isHovered ? themeManager.currentTheme.elevated.opacity(0.5) : Color.clear)
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                if file.type == .folder {
                    isExpanded.toggle()
                } else {
                    workspace.openFile(file)
                }
            }

            // Children (for folders)
            if file.type == .folder && isExpanded {
                ForEach(file.children) { child in
                    FileTreeItem(file: child, level: level + 1, themeManager: themeManager)
                }
            }
        }
    }
}
