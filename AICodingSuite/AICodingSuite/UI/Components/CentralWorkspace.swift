//
//  CentralWorkspace.swift
//  AI Coding Suite
//
//  Central workspace with tab-based editor and draggable panels
//

import SwiftUI

struct CentralWorkspace: View {
    @State private var openFiles: [OpenFile] = []
    @State private var selectedFileIndex: Int = 0
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            if !openFiles.isEmpty {
                TabBar(
                    openFiles: $openFiles,
                    selectedIndex: $selectedFileIndex
                )
            }

            // Editor area
            ZStack {
                if openFiles.isEmpty {
                    WelcomeView()
                } else if selectedFileIndex < openFiles.count {
                    CodeEditorView(file: openFiles[selectedFileIndex])
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(themeManager.currentTheme.background)
        .onAppear {
            // Load demo file for demonstration
            openFiles = [
                OpenFile(
                    id: UUID(),
                    name: "main.swift",
                    path: "/demo/main.swift",
                    language: .swift,
                    content: demoSwiftCode
                )
            ]
        }
    }
}

// MARK: - Tab Bar
struct TabBar: View {
    @Binding var openFiles: [OpenFile]
    @Binding var selectedIndex: Int
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(Array(openFiles.enumerated()), id: \.element.id) { index, file in
                    TabItem(
                        file: file,
                        isSelected: index == selectedIndex,
                        action: { selectedIndex = index },
                        closeAction: {
                            openFiles.remove(at: index)
                            if selectedIndex >= openFiles.count {
                                selectedIndex = max(0, openFiles.count - 1)
                            }
                        }
                    )
                }
            }
        }
        .frame(height: 36)
        .background(themeManager.currentTheme.surface.opacity(0.5))
    }
}

struct TabItem: View {
    let file: OpenFile
    let isSelected: Bool
    let action: () -> Void
    let closeAction: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: file.language.icon)
                    .font(.caption)
                    .foregroundColor(file.language.color)

                Text(file.name)
                    .font(.subheadline)
                    .foregroundColor(
                        isSelected ?
                        themeManager.currentTheme.textPrimary :
                        themeManager.currentTheme.textSecondary
                    )

                Button(action: closeAction) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                themeManager.currentTheme.surface :
                Color.clear
            )
            .overlay(
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(
                        isSelected ?
                        themeManager.currentTheme.neonAccent :
                        Color.clear
                    ),
                alignment: .bottom
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "chevron.left.forwardslash.chevron.right")
                .font(.system(size: 80))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            themeManager.currentTheme.neonAccent,
                            themeManager.currentTheme.neonSecondary
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: themeManager.currentTheme.neonAccent.opacity(0.5), radius: 20)

            Text("Welcome to AI Coding Suite")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Text("Open a file or create a new project to get started")
                .font(.title3)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            HStack(spacing: 16) {
                WelcomeButton(
                    icon: "doc.badge.plus",
                    title: "New File",
                    action: {}
                )

                WelcomeButton(
                    icon: "folder.badge.plus",
                    title: "Open Folder",
                    action: {}
                )

                WelcomeButton(
                    icon: "sparkles",
                    title: "AI Assistant",
                    action: {}
                )
            }
            .padding(.top, 24)
        }
    }
}

struct WelcomeButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(themeManager.currentTheme.neonAccent)

                Text(title)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)
            }
            .frame(width: 140, height: 120)
            .background(
                themeManager.currentTheme.surface
                    .opacity(0.6)
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(themeManager.currentTheme.neonAccent.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Models
struct OpenFile: Identifiable {
    let id: UUID
    let name: String
    let path: String
    let language: ProgrammingLanguage
    var content: String
}

enum ProgrammingLanguage {
    case swift, python, javascript, typescript, rust, go, cpp

    var icon: String {
        switch self {
        case .swift: return "swift"
        case .python: return "doc.text"
        case .javascript, .typescript: return "doc.text.fill"
        case .rust: return "gearshape.2"
        case .go: return "square.stack.3d.up"
        case .cpp: return "chevron.left.slash.chevron.right"
        }
    }

    var color: Color {
        switch self {
        case .swift: return .orange
        case .python: return .blue
        case .javascript, .typescript: return .yellow
        case .rust: return .orange
        case .go: return .cyan
        case .cpp: return .blue
        }
    }
}

// MARK: - Demo Code
private let demoSwiftCode = """
import SwiftUI

struct ContentView: View {
    @State private var count = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("Counter: \\(count)")
                .font(.largeTitle)

            Button("Increment") {
                count += 1
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
"""
