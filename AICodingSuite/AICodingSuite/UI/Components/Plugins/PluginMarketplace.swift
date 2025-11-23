//
//  PluginMarketplace.swift
//  AI Coding Suite
//
//  Plugin marketplace for discovering and installing plugins
//

import SwiftUI

struct PluginMarketplaceView: View {
    @Binding var isPresented: Bool
    @StateObject private var pluginManager = PluginManager.shared
    @State private var searchQuery: String = ""
    @State private var selectedCategory: PluginCategory = .all
    @State private var selectedPlugin: PluginManifest?
    @EnvironmentObject var themeManager: ThemeManager

    var filteredPlugins: [PluginManifest] {
        var plugins = pluginManager.availablePlugins

        if selectedCategory != .all {
            plugins = plugins.filter { $0.capabilities.contains(selectedCategory.capability) }
        }

        if !searchQuery.isEmpty {
            plugins = plugins.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.description.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        return plugins
    }

    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "puzzlepiece.extension.fill")
                        .font(.title2)
                        .foregroundColor(themeManager.currentTheme.neonAccent)

                    Text("Marketplace")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(themeManager.currentTheme.textPrimary)

                    Spacer()

                    Button(action: { isPresented = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)

                Divider()

                // Categories
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(PluginCategory.allCases, id: \.self) { category in
                            CategoryButton(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(8)
                }

                Divider()

                // Installed plugins
                VStack(alignment: .leading, spacing: 8) {
                    Text("INSTALLED")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .padding(.horizontal, 12)

                    ScrollView {
                        VStack(spacing: 4) {
                            ForEach(pluginManager.installedPlugins) { plugin in
                                InstalledPluginRow(plugin: plugin)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            .frame(width: 220)
            .background(themeManager.currentTheme.surface.opacity(0.3))

            Divider()

            // Main content
            VStack(spacing: 0) {
                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    TextField("Search plugins...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.body)
                        .foregroundColor(themeManager.currentTheme.textPrimary)
                }
                .padding(12)
                .background(themeManager.currentTheme.surface.opacity(0.5))
                .cornerRadius(8)
                .padding(16)

                Divider()

                // Plugin grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredPlugins) { plugin in
                            PluginCard(plugin: plugin, selectedPlugin: $selectedPlugin)
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(width: 1000, height: 700)
        .background(themeManager.currentTheme.background)
        .cornerRadius(12)
        .shadow(color: themeManager.currentTheme.neonAccent.opacity(0.3), radius: 20)
        .sheet(item: $selectedPlugin) { plugin in
            PluginDetailView(plugin: plugin)
        }
        .onAppear {
            loadAvailablePlugins()
        }
    }

    private func loadAvailablePlugins() {
        // Mock plugins for demo
        pluginManager.availablePlugins = [
            PluginManifest(
                id: "com.example.docker",
                name: "Docker Tools",
                version: "1.0.0",
                author: "Example Corp",
                description: "Manage Docker containers and images directly from the editor",
                icon: "shippingbox.fill",
                homepage: "https://example.com",
                capabilities: [.commands, .ui, .terminal],
                permissions: [.terminal, .process, .network],
                dependencies: nil,
                entryPoint: "main.js",
                minimumAppVersion: "1.0.0"
            ),
            PluginManifest(
                id: "com.example.database",
                name: "Database Client",
                version: "2.1.0",
                author: "DB Tools Inc",
                description: "Connect to and manage SQL databases with a visual query builder",
                icon: "externaldrive.fill",
                homepage: "https://example.com",
                capabilities: [.ui, .network],
                permissions: [.network, .fileRead, .fileWrite],
                dependencies: nil,
                entryPoint: "main.js",
                minimumAppVersion: "1.0.0"
            ),
            PluginManifest(
                id: "com.example.rest",
                name: "REST Client",
                version: "1.5.0",
                author: "API Tools",
                description: "Test and debug REST APIs with a beautiful interface",
                icon: "network",
                homepage: "https://example.com",
                capabilities: [.ui, .network],
                permissions: [.network, .fileRead],
                dependencies: nil,
                entryPoint: "main.js",
                minimumAppVersion: "1.0.0"
            ),
        ]
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: PluginCategory
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .frame(width: 20)

                Text(category.rawValue)
                    .font(.subheadline)

                Spacer()
            }
            .foregroundColor(
                isSelected ?
                themeManager.currentTheme.neonAccent :
                themeManager.currentTheme.textPrimary
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? themeManager.currentTheme.neonAccent.opacity(0.15) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Plugin Card
struct PluginCard: View {
    let plugin: PluginManifest
    @Binding var selectedPlugin: PluginManifest?
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var pluginManager = PluginManager.shared

    var isInstalled: Bool {
        pluginManager.installedPlugins.contains { $0.manifest.id == plugin.id }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: plugin.icon ?? "puzzlepiece.extension")
                    .font(.largeTitle)
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                    .frame(width: 60, height: 60)
                    .background(themeManager.currentTheme.neonAccent.opacity(0.1))
                    .cornerRadius(12)

                Spacer()

                if isInstalled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(plugin.name)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text(plugin.author)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }

            Text(plugin.description)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .lineLimit(3)
                .frame(height: 45)

            Spacer()

            HStack {
                Text("v\(plugin.version)")
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.textSecondary)

                Spacer()

                if isInstalled {
                    Button("Manage") {
                        selectedPlugin = plugin
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Install") {
                        installPlugin()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.currentTheme.neonAccent)
                }
            }
        }
        .padding(16)
        .background(themeManager.currentTheme.surface.opacity(0.5))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.neonAccent.opacity(0.2), lineWidth: 1)
        )
    }

    private func installPlugin() {
        // Mock installation
        print("Installing plugin: \(plugin.name)")
    }
}

// MARK: - Installed Plugin Row
struct InstalledPluginRow: View {
    let plugin: Plugin
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var pluginManager = PluginManager.shared

    var isActive: Bool {
        pluginManager.activePlugins.contains(plugin.manifest.id)
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            Text(plugin.manifest.name)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textPrimary)
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

// MARK: - Plugin Detail View
struct PluginDetailView: View {
    let plugin: PluginManifest
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: plugin.icon ?? "puzzlepiece.extension")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager.currentTheme.neonAccent)

                VStack(alignment: .leading) {
                    Text(plugin.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("by \(plugin.author)")
                        .font(.subheadline)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Spacer()

                Button("Close") {
                    dismiss()
                }
            }
            .padding(20)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(plugin.description)
                        .font(.body)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Capabilities")
                            .font(.headline)

                        ForEach(plugin.capabilities, id: \.self) { capability in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text(capability.rawValue)
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Permissions")
                            .font(.headline)

                        ForEach(plugin.permissions, id: \.self) { permission in
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.orange)
                                Text(permission.rawValue)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Plugin Category
enum PluginCategory: String, CaseIterable {
    case all = "All Plugins"
    case languages = "Languages"
    case themes = "Themes"
    case tools = "Developer Tools"
    case ai = "AI & ML"
    case ui = "UI Extensions"

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .languages: return "chevron.left.forwardslash.chevron.right"
        case .themes: return "paintbrush"
        case .tools: return "wrench.and.screwdriver"
        case .ai: return "sparkles"
        case .ui: return "rectangle.3.group"
        }
    }

    var capability: PluginCapability {
        switch self {
        case .all: return .commands
        case .languages: return .languageSupport
        case .themes: return .theme
        case .tools: return .commands
        case .ai: return .ai
        case .ui: return .ui
        }
    }
}
