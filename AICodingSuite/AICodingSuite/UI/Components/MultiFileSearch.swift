//
//  MultiFileSearch.swift
//  AI Coding Suite
//
//  Multi-file search and replace functionality
//

import SwiftUI
import Foundation

struct MultiFileSearchView: View {
    @Binding var isPresented: Bool
    @State private var searchQuery: String = ""
    @State private var replaceText: String = ""
    @State private var caseSensitive: Bool = false
    @State private var useRegex: Bool = false
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching: Bool = false
    @State private var selectedResult: SearchResult?
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var workspaceManager: WorkspaceManager

    var body: some View {
        VStack(spacing: 0) {
            // Search header
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.neonAccent)

                    Text("Search in Files")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Spacer()

                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }

                // Search input
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    TextField("Search for...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                        .onSubmit {
                            performSearch()
                        }

                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
                .padding(10)
                .background(themeManager.currentTheme.surface)
                .cornerRadius(8)

                // Replace input
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    TextField("Replace with...", text: $replaceText)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }
                .padding(10)
                .background(themeManager.currentTheme.surface)
                .cornerRadius(8)

                // Options
                HStack(spacing: 16) {
                    Toggle("Case sensitive", isOn: $caseSensitive)
                        .toggleStyle(.checkbox)

                    Toggle("Regular expression", isOn: $useRegex)
                        .toggleStyle(.checkbox)

                    Spacer()

                    Button("Search") {
                        performSearch()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.currentTheme.neonAccent)
                    .disabled(searchQuery.isEmpty)
                }
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textPrimary)
            }
            .padding(16)
            .background(themeManager.currentTheme.background.opacity(0.8))

            Divider()

            // Results
            if searchResults.isEmpty && !isSearching {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 64))
                        .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.3))

                    Text(searchQuery.isEmpty ? "Enter search terms" : "No results found")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    // Results summary
                    HStack {
                        Text("\(searchResults.count) results in \(uniqueFileCount) files")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondary)

                        Spacer()

                        if !searchResults.isEmpty {
                            Button("Replace All") {
                                replaceAll()
                            }
                            .buttonStyle(.bordered)
                            .disabled(replaceText.isEmpty)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(themeManager.currentTheme.surface.opacity(0.5))

                    // Results list
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(groupedResults, id: \.key) { fileName, results in
                                SearchFileGroup(
                                    fileName: fileName,
                                    results: results,
                                    replaceText: replaceText,
                                    selectedResult: $selectedResult
                                )
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 700, height: 600)
        .background(themeManager.currentTheme.background)
        .cornerRadius(12)
        .shadow(color: themeManager.currentTheme.neonAccent.opacity(0.3), radius: 20)
    }

    private var uniqueFileCount: Int {
        Set(searchResults.map { $0.filePath }).count
    }

    private var groupedResults: [(key: String, value: [SearchResult])] {
        Dictionary(grouping: searchResults, by: { $0.fileName })
            .sorted { $0.key < $1.key }
    }

    private func performSearch() {
        guard !searchQuery.isEmpty else { return }

        isSearching = true
        searchResults = []

        // Simulate search (in production, this would search actual files)
        DispatchQueue.global().async {
            let mockResults = generateMockResults()

            DispatchQueue.main.async {
                searchResults = mockResults
                isSearching = false
            }
        }
    }

    private func generateMockResults() -> [SearchResult] {
        let files = [
            ("MainWindowView.swift", "AICodingSuite/UI"),
            ("ThemeManager.swift", "AICodingSuite/UI/Theme"),
            ("CodeEditorView.swift", "AICodingSuite/UI/Components/CodeEditor"),
            ("TerminalView.swift", "AICodingSuite/UI/Components/Terminal"),
        ]

        var results: [SearchResult] = []

        for (fileName, path) in files {
            for lineNum in [12, 45, 78, 134] {
                if Bool.random() {
                    results.append(
                        SearchResult(
                            id: UUID(),
                            fileName: fileName,
                            filePath: path,
                            lineNumber: lineNum,
                            lineContent: "Example line with \(searchQuery) in it",
                            matchRange: NSRange(location: 18, length: searchQuery.count)
                        )
                    )
                }
            }
        }

        return results
    }

    private func replaceAll() {
        // In production, this would perform actual replacements
        print("Replacing all occurrences of '\(searchQuery)' with '\(replaceText)'")
        searchResults = []
    }
}

// MARK: - Search File Group
struct SearchFileGroup: View {
    let fileName: String
    let results: [SearchResult]
    let replaceText: String
    @Binding var selectedResult: SearchResult?
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isExpanded: Bool = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // File header
            Button(action: { isExpanded.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Image(systemName: "doc.text")
                        .foregroundColor(themeManager.currentTheme.neonAccent)

                    Text(fileName)
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Text("(\(results.count))")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(themeManager.currentTheme.surface.opacity(0.3))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            // Results
            if isExpanded {
                ForEach(results) { result in
                    SearchResultRow(
                        result: result,
                        replaceText: replaceText,
                        isSelected: selectedResult?.id == result.id
                    )
                    .onTapGesture {
                        selectedResult = result
                    }
                }
            }
        }
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResult
    let replaceText: String
    let isSelected: Bool
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Line number
            Text("\(result.lineNumber)")
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.7))
                .frame(width: 50, alignment: .trailing)

            // Line content with highlighting
            Text(highlightedContent)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(themeManager.currentTheme.textPrimary)
                .lineLimit(1)

            Spacer()

            // Replace button
            if !replaceText.isEmpty {
                Button(action: {
                    // Perform replace
                }) {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(themeManager.currentTheme.neonAccent)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(isSelected ? themeManager.currentTheme.neonAccent.opacity(0.1) : Color.clear)
    }

    private var highlightedContent: AttributedString {
        var attr = AttributedString(result.lineContent)

        if let range = Range(result.matchRange, in: result.lineContent) {
            attr[range].backgroundColor = themeManager.currentTheme.neonAccent.opacity(0.3)
            attr[range].foregroundColor = themeManager.currentTheme.neonAccent
        }

        return attr
    }
}

// MARK: - Search Result Model
struct SearchResult: Identifiable {
    let id: UUID
    let fileName: String
    let filePath: String
    let lineNumber: Int
    let lineContent: String
    let matchRange: NSRange
}
