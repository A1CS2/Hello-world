//
//  WorkspaceManager.swift
//  AI Coding Suite
//
//  Workspace and project management
//

import SwiftUI
import Foundation

class WorkspaceManager: ObservableObject {
    @Published var currentWorkspace: Workspace?
    @Published var recentWorkspaces: [Workspace] = []
    @Published var openFolders: [URL] = []

    init() {
        loadRecentWorkspaces()
    }

    func openWorkspace(at url: URL) {
        let workspace = Workspace(
            id: UUID(),
            name: url.lastPathComponent,
            path: url,
            createdAt: Date(),
            lastOpened: Date()
        )

        currentWorkspace = workspace
        addToRecent(workspace)

        // Scan directory for files
        scanDirectory(url)
    }

    func closeWorkspace() {
        if let workspace = currentWorkspace {
            updateLastOpened(workspace)
        }
        currentWorkspace = nil
        openFolders = []
    }

    private func scanDirectory(_ url: URL) {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            openFolders = contents.filter { url in
                (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            }
        } catch {
            print("Error scanning directory: \(error)")
        }
    }

    private func loadRecentWorkspaces() {
        if let data = UserDefaults.standard.data(forKey: "recentWorkspaces"),
           let workspaces = try? JSONDecoder().decode([Workspace].self, from: data) {
            recentWorkspaces = workspaces
        }
    }

    private func addToRecent(_ workspace: Workspace) {
        recentWorkspaces.removeAll { $0.path == workspace.path }
        recentWorkspaces.insert(workspace, at: 0)

        if recentWorkspaces.count > 10 {
            recentWorkspaces = Array(recentWorkspaces.prefix(10))
        }

        saveRecentWorkspaces()
    }

    private func updateLastOpened(_ workspace: Workspace) {
        if let index = recentWorkspaces.firstIndex(where: { $0.id == workspace.id }) {
            var updated = workspace
            updated.lastOpened = Date()
            recentWorkspaces[index] = updated
            saveRecentWorkspaces()
        }
    }

    private func saveRecentWorkspaces() {
        if let data = try? JSONEncoder().encode(recentWorkspaces) {
            UserDefaults.standard.set(data, forKey: "recentWorkspaces")
        }
    }
}

// MARK: - Workspace Model
struct Workspace: Codable, Identifiable, Equatable {
    let id: UUID
    let name: String
    let path: URL
    let createdAt: Date
    var lastOpened: Date

    static func == (lhs: Workspace, rhs: Workspace) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Project Model
struct Project: Codable, Identifiable {
    let id: UUID
    let name: String
    let language: String
    let framework: String?
    let settings: ProjectSettings
}

struct ProjectSettings: Codable {
    var autoSave: Bool
    var formatOnSave: Bool
    var lintOnSave: Bool
    var aiAssistEnabled: Bool
    var aiProvider: String

    static let `default` = ProjectSettings(
        autoSave: true,
        formatOnSave: true,
        lintOnSave: true,
        aiAssistEnabled: true,
        aiProvider: "openai"
    )
}
