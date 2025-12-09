//
//  WorkspaceManager.swift
//  AICodingSuite2
//
//  Created by Claude
//

import Foundation
import SwiftUI

class WorkspaceManager: ObservableObject {
    @Published var currentWorkspace: URL?
    @Published var files: [WorkspaceFile] = []
    @Published var openFiles: [WorkspaceFile] = []
    @Published var selectedFile: WorkspaceFile?
    @Published var fileContents: [String: String] = [:]

    static let shared = WorkspaceManager()

    private init() {}

    func openWorkspace(url: URL) {
        currentWorkspace = url
        loadFiles(from: url)
    }

    func loadFiles(from url: URL) {
        guard url.hasDirectoryPath else { return }

        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            files = contents.compactMap { fileURL in
                let isDirectory = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                let file = WorkspaceFile(
                    name: fileURL.lastPathComponent,
                    path: fileURL.path,
                    type: isDirectory ? .folder : .file
                )

                if isDirectory {
                    var fileWithChildren = file
                    fileWithChildren.children = loadChildFiles(from: fileURL)
                    return fileWithChildren
                }
                return file
            }.sorted { $0.type == .folder && $1.type == .file }

        } catch {
            print("Error loading files: \(error)")
        }
    }

    private func loadChildFiles(from url: URL) -> [WorkspaceFile] {
        do {
            let fileManager = FileManager.default
            let contents = try fileManager.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )

            return contents.compactMap { fileURL in
                let isDirectory = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
                let file = WorkspaceFile(
                    name: fileURL.lastPathComponent,
                    path: fileURL.path,
                    type: isDirectory ? .folder : .file
                )

                if isDirectory {
                    var fileWithChildren = file
                    fileWithChildren.children = loadChildFiles(from: fileURL)
                    return fileWithChildren
                }
                return file
            }.sorted { $0.type == .folder && $1.type == .file }

        } catch {
            return []
        }
    }

    func openFile(_ file: WorkspaceFile) {
        guard file.type == .file else { return }

        if !openFiles.contains(where: { $0.id == file.id }) {
            openFiles.append(file)
        }
        selectedFile = file
        loadFileContents(file)
    }

    func closeFile(_ file: WorkspaceFile) {
        openFiles.removeAll { $0.id == file.id }
        if selectedFile?.id == file.id {
            selectedFile = openFiles.first
        }
    }

    func loadFileContents(_ file: WorkspaceFile) {
        guard file.type == .file else { return }

        do {
            let contents = try String(contentsOfFile: file.path, encoding: .utf8)
            fileContents[file.path] = contents
        } catch {
            fileContents[file.path] = "// Error loading file: \(error.localizedDescription)"
        }
    }

    func saveFile(_ file: WorkspaceFile, contents: String) {
        do {
            try contents.write(toFile: file.path, atomically: true, encoding: .utf8)
            fileContents[file.path] = contents
        } catch {
            print("Error saving file: \(error)")
        }
    }

    func createNewFile(name: String, in folder: URL? = nil) {
        let targetFolder = folder ?? currentWorkspace ?? FileManager.default.homeDirectoryForCurrentUser
        let newFileURL = targetFolder.appendingPathComponent(name)

        FileManager.default.createFile(atPath: newFileURL.path, contents: Data(), attributes: nil)
        if let workspace = currentWorkspace {
            loadFiles(from: workspace)
        }
    }
}
