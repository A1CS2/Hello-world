//
//  DockerManager.swift
//  AI Coding Suite
//
//  Docker container and image management
//

import Foundation
import Combine

class DockerManager: ObservableObject {
    @Published var containers: [DockerContainer] = []
    @Published var images: [DockerImage] = []
    @Published var isDockerRunning: Bool = false
    @Published var dockerVersion: String?

    private var cancellables = Set<AnyCancellable>()
    private let dockerCommand = "/usr/local/bin/docker"

    init() {
        checkDockerStatus()
    }

    // MARK: - Docker Status

    func checkDockerStatus() {
        executeCommand(["--version"]) { [weak self] result in
            switch result {
            case .success(let output):
                self?.dockerVersion = output.trimmingCharacters(in: .whitespacesAndNewlines)
                self?.isDockerRunning = true
                self?.refreshContainers()
                self?.refreshImages()

            case .failure:
                self?.isDockerRunning = false
            }
        }
    }

    // MARK: - Container Management

    func refreshContainers() {
        executeCommand(["ps", "-a", "--format", "{{json .}}"]) { [weak self] result in
            switch result {
            case .success(let output):
                self?.parseContainers(output)
            case .failure(let error):
                print("Failed to get containers: \(error)")
            }
        }
    }

    private func parseContainers(_ output: String) {
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        containers = lines.compactMap { line in
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
                return nil
            }

            return DockerContainer(
                id: json["ID"] ?? "",
                name: json["Names"] ?? "",
                image: json["Image"] ?? "",
                status: json["Status"] ?? "",
                state: json["State"] ?? "exited",
                ports: json["Ports"] ?? ""
            )
        }
    }

    func startContainer(_ containerID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        executeCommand(["start", containerID]) { result in
            switch result {
            case .success:
                self.refreshContainers()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func stopContainer(_ containerID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        executeCommand(["stop", containerID]) { result in
            switch result {
            case .success:
                self.refreshContainers()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func removeContainer(_ containerID: String, force: Bool = false, completion: @escaping (Result<Void, Error>) -> Void) {
        var args = ["rm"]
        if force { args.append("-f") }
        args.append(containerID)

        executeCommand(args) { result in
            switch result {
            case .success:
                self.refreshContainers()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func getContainerLogs(_ containerID: String, tail: Int = 100, completion: @escaping (Result<String, Error>) -> Void) {
        executeCommand(["logs", "--tail", "\(tail)", containerID], completion: completion)
    }

    func executeInContainer(_ containerID: String, command: String, completion: @escaping (Result<String, Error>) -> Void) {
        let args = ["exec", containerID] + command.components(separatedBy: " ")
        executeCommand(args, completion: completion)
    }

    // MARK: - Image Management

    func refreshImages() {
        executeCommand(["images", "--format", "{{json .}}"]) { [weak self] result in
            switch result {
            case .success(let output):
                self?.parseImages(output)
            case .failure(let error):
                print("Failed to get images: \(error)")
            }
        }
    }

    private func parseImages(_ output: String) {
        let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
        images = lines.compactMap { line in
            guard let data = line.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
                return nil
            }

            return DockerImage(
                id: json["ID"] ?? "",
                repository: json["Repository"] ?? "",
                tag: json["Tag"] ?? "",
                size: json["Size"] ?? "",
                createdAt: json["CreatedAt"] ?? ""
            )
        }
    }

    func pullImage(_ imageName: String, completion: @escaping (Result<String, Error>) -> Void) {
        executeCommand(["pull", imageName], completion: completion)
    }

    func removeImage(_ imageID: String, force: Bool = false, completion: @escaping (Result<Void, Error>) -> Void) {
        var args = ["rmi"]
        if force { args.append("-f") }
        args.append(imageID)

        executeCommand(args) { result in
            switch result {
            case .success:
                self.refreshImages()
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func buildImage(from dockerfile: String, tag: String, completion: @escaping (Result<String, Error>) -> Void) {
        executeCommand(["build", "-t", tag, "-f", dockerfile, "."], completion: completion)
    }

    // MARK: - Compose Management

    func composeUp(file: String, completion: @escaping (Result<String, Error>) -> Void) {
        executeCommand(["compose", "-f", file, "up", "-d"], completion: completion)
    }

    func composeDown(file: String, completion: @escaping (Result<String, Error>) -> Void) {
        executeCommand(["compose", "-f", file, "down"], completion: completion)
    }

    // MARK: - Command Execution

    private func executeCommand(_ args: [String], completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global().async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.dockerCommand)
            process.arguments = args

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                if process.terminationStatus == 0 {
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    DispatchQueue.main.async {
                        completion(.success(output))
                    }
                } else {
                    let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    DispatchQueue.main.async {
                        completion(.failure(DockerError.commandFailed(error)))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
}

// MARK: - Docker Models

struct DockerContainer: Identifiable {
    let id: String
    let name: String
    let image: String
    let status: String
    let state: String
    let ports: String

    var isRunning: Bool {
        state.lowercased() == "running"
    }
}

struct DockerImage: Identifiable {
    let id: String
    let repository: String
    let tag: String
    let size: String
    let createdAt: String

    var fullName: String {
        "\(repository):\(tag)"
    }
}

enum DockerError: Error {
    case commandFailed(String)
    case dockerNotInstalled
    case invalidResponse

    var localizedDescription: String {
        switch self {
        case .commandFailed(let message): return message
        case .dockerNotInstalled: return "Docker is not installed"
        case .invalidResponse: return "Invalid response from Docker"
        }
    }
}
