//
//  WorkspaceFile.swift
//  AICodingSuite2
//
//  Created by Claude
//

import Foundation

struct WorkspaceFile: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let path: String
    let type: FileType
    var isExpanded: Bool = false
    var children: [WorkspaceFile] = []

    enum FileType {
        case file
        case folder

        var icon: String {
            switch self {
            case .file: return "doc.text"
            case .folder: return "folder"
            }
        }
    }

    var fileExtension: String {
        URL(fileURLWithPath: path).pathExtension
    }

    var language: String {
        switch fileExtension.lowercased() {
        case "swift": return "Swift"
        case "py": return "Python"
        case "js": return "JavaScript"
        case "ts": return "TypeScript"
        case "rs": return "Rust"
        case "go": return "Go"
        case "java": return "Java"
        case "cpp", "cc", "cxx": return "C++"
        case "c": return "C"
        case "h", "hpp": return "C/C++ Header"
        case "md": return "Markdown"
        case "json": return "JSON"
        case "xml": return "XML"
        case "html": return "HTML"
        case "css": return "CSS"
        case "sh": return "Shell"
        default: return "Text"
        }
    }
}
