//
//  AICodingSuite2App.swift
//  AICodingSuite2
//
//  Created by S. Griggs on 11/26/25.
//

import SwiftUI

@main
struct AICodingSuite2App: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView()
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New File") {
                    WorkspaceManager.shared.createNewFile(name: "untitled.txt")
                }
                .keyboardShortcut("n", modifiers: .command)
            }

            CommandGroup(after: .newItem) {
                Button("Open Folder...") {
                    openFolder()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(after: .sidebar) {
                Button("Toggle File Explorer") {
                    // This will be handled by the view
                }
                .keyboardShortcut("b", modifiers: .command)

                Button("Toggle Terminal") {
                    // This will be handled by the view
                }
                .keyboardShortcut("`", modifiers: .command)

                Button("Toggle AI Panel") {
                    // This will be handled by the view
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView(themeManager: ThemeManager())
                .frame(width: 700, height: 500)
        }
    }

    private func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            WorkspaceManager.shared.openWorkspace(url: url)
        }
    }
}

// Required for NSOpenPanel
import AppKit
