//
//  DockerView.swift
//  AI Coding Suite
//
//  Docker containers and images management UI
//

import SwiftUI

struct DockerView: View {
    @StateObject private var dockerManager = DockerManager()
    @State private var selectedTab: DockerTab = .containers
    @State private var selectedContainer: DockerContainer?
    @State private var selectedImage: DockerImage?
    @State private var showLogs = false
    @State private var logs: String = ""
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "shippingbox.fill")
                    .font(.title2)
                    .foregroundColor(dockerManager.isDockerRunning ? themeManager.currentTheme.neonAccent : .gray)

                Text("Docker")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                if let version = dockerManager.dockerVersion {
                    Text(version)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                }

                Spacer()

                Button(action: {
                    dockerManager.checkDockerStatus()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(themeManager.currentTheme.neonAccent)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(themeManager.currentTheme.surface.opacity(0.5))

            Divider()

            // Tab selector
            Picker("Docker Tab", selection: $selectedTab) {
                ForEach(DockerTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            // Content
            Group {
                switch selectedTab {
                case .containers:
                    ContainersListView(
                        dockerManager: dockerManager,
                        selectedContainer: $selectedContainer,
                        showLogs: $showLogs,
                        logs: $logs
                    )
                case .images:
                    ImagesListView(
                        dockerManager: dockerManager,
                        selectedImage: $selectedImage
                    )
                case .compose:
                    ComposeView(dockerManager: dockerManager)
                }
            }
        }
        .background(themeManager.currentTheme.background)
        .sheet(isPresented: $showLogs) {
            LogsView(logs: logs)
        }
    }

    enum DockerTab: String, CaseIterable {
        case containers = "Containers"
        case images = "Images"
        case compose = "Compose"
    }
}

// MARK: - Containers List
struct ContainersListView: View {
    @ObservedObject var dockerManager: DockerManager
    @Binding var selectedContainer: DockerContainer?
    @Binding var showLogs: Bool
    @Binding var logs: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Containers table
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(dockerManager.containers) { container in
                        ContainerRow(
                            container: container,
                            isSelected: selectedContainer?.id == container.id,
                            onStart: {
                                dockerManager.startContainer(container.id) { _ in }
                            },
                            onStop: {
                                dockerManager.stopContainer(container.id) { _ in }
                            },
                            onRemove: {
                                dockerManager.removeContainer(container.id, force: true) { _ in }
                            },
                            onLogs: {
                                dockerManager.getContainerLogs(container.id) { result in
                                    if case .success(let output) = result {
                                        logs = output
                                        showLogs = true
                                    }
                                }
                            }
                        )
                        .onTapGesture {
                            selectedContainer = container
                        }
                    }

                    if dockerManager.containers.isEmpty {
                        Text("No containers")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .padding(40)
                    }
                }
            }
        }
    }
}

struct ContainerRow: View {
    let container: DockerContainer
    let isSelected: Bool
    let onStart: () -> Void
    let onStop: () -> Void
    let onRemove: () -> Void
    let onLogs: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            Circle()
                .fill(container.isRunning ? Color.green : Color.gray)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                Text(container.name)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                HStack(spacing: 8) {
                    Text(container.image)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    if !container.ports.isEmpty {
                        Text("•")
                        Text(container.ports)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }

            Spacer()

            // Status
            Text(container.status)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .frame(width: 120, alignment: .trailing)

            // Actions
            HStack(spacing: 8) {
                if container.isRunning {
                    Button(action: onStop) {
                        Image(systemName: "stop.fill")
                    }
                } else {
                    Button(action: onStart) {
                        Image(systemName: "play.fill")
                    }
                }

                Button(action: onLogs) {
                    Image(systemName: "doc.text")
                }

                Button(action: onRemove) {
                    Image(systemName: "trash")
                }
            }
            .buttonStyle(.plain)
            .foregroundColor(themeManager.currentTheme.neonAccent)
        }
        .padding(12)
        .background(isSelected ? themeManager.currentTheme.neonAccent.opacity(0.1) : Color.clear)
    }
}

// MARK: - Images List
struct ImagesListView: View {
    @ObservedObject var dockerManager: DockerManager
    @Binding var selectedImage: DockerImage?
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(dockerManager.images) { image in
                        ImageRow(
                            image: image,
                            isSelected: selectedImage?.id == image.id,
                            onRemove: {
                                dockerManager.removeImage(image.id, force: true) { _ in }
                            }
                        )
                        .onTapGesture {
                            selectedImage = image
                        }
                    }

                    if dockerManager.images.isEmpty {
                        Text("No images")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .padding(40)
                    }
                }
            }
        }
    }
}

struct ImageRow: View {
    let image: DockerImage
    let isSelected: Bool
    let onRemove: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "cube.box.fill")
                .foregroundColor(themeManager.currentTheme.neonAccent)

            VStack(alignment: .leading, spacing: 4) {
                Text(image.fullName)
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Text(image.id.prefix(12))
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                    .font(.system(.caption, design: .monospaced))
            }

            Spacer()

            Text(image.size)
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondary)

            Button(action: onRemove) {
                Image(systemName: "trash")
            }
            .buttonStyle(.plain)
            .foregroundColor(themeManager.currentTheme.neonAccent)
        }
        .padding(12)
        .background(isSelected ? themeManager.currentTheme.neonAccent.opacity(0.1) : Color.clear)
    }
}

// MARK: - Compose View
struct ComposeView: View {
    @ObservedObject var dockerManager: DockerManager
    @State private var composeFile: String = ""
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 16) {
            Text("Docker Compose")
                .font(.headline)

            TextField("Path to docker-compose.yml", text: $composeFile)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            HStack(spacing: 12) {
                Button("Up") {
                    dockerManager.composeUp(file: composeFile) { _ in }
                }
                .buttonStyle(.borderedProminent)

                Button("Down") {
                    dockerManager.composeDown(file: composeFile) { _ in }
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Logs View
struct LogsView: View {
    let logs: String
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Container Logs")
                    .font(.headline)

                Spacer()

                Button("Close") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            ScrollView {
                Text(logs)
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(themeManager.currentTheme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(themeManager.currentTheme.background)
        }
        .frame(width: 800, height: 600)
    }
}
