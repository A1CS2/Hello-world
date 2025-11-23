//
//  LSPClient.swift
//  AI Coding Suite
//
//  Language Server Protocol client implementation
//

import Foundation
import Combine

class LSPClient: ObservableObject {
    @Published var isConnected: Bool = false
    @Published var diagnostics: [Diagnostic] = []
    @Published var capabilities: ServerCapabilities?

    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var requestId: Int = 0
    private var pendingRequests: [Int: (Result<[String: Any], Error>) -> Void] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    func start(serverPath: String, rootPath: String) {
        let process = Process()
        let inputPipe = Pipe()
        let outputPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: serverPath)
        process.arguments = ["--stdio"]
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        self.process = process
        self.inputPipe = inputPipe
        self.outputPipe = outputPipe

        // Read output
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty {
                self?.handleOutput(data)
            }
        }

        do {
            try process.run()
            isConnected = true

            // Send initialize request
            initialize(rootPath: rootPath)
        } catch {
            print("Failed to start LSP server: \(error)")
        }
    }

    func stop() {
        shutdown()
        process?.terminate()
        isConnected = false
    }

    // MARK: - LSP Methods

    func initialize(rootPath: String) {
        let params: [String: Any] = [
            "processId": ProcessInfo.processInfo.processIdentifier,
            "rootUri": "file://\(rootPath)",
            "capabilities": [
                "textDocument": [
                    "completion": [
                        "completionItem": [
                            "snippetSupport": true
                        ]
                    ],
                    "hover": [:],
                    "signatureHelp": [:],
                    "definition": [:],
                    "references": [:],
                    "documentHighlight": [:],
                    "documentSymbol": [:],
                    "formatting": [:],
                    "codeAction": [:],
                    "rename": [:]
                ],
                "workspace": [
                    "applyEdit": true,
                    "workspaceEdit": [
                        "documentChanges": true
                    ]
                ]
            ]
        ]

        sendRequest(method: "initialize", params: params) { [weak self] result in
            switch result {
            case .success(let response):
                if let capabilities = response["capabilities"] as? [String: Any] {
                    self?.parseCapabilities(capabilities)
                }
                self?.sendNotification(method: "initialized", params: [:])

            case .failure(let error):
                print("Initialize failed: \(error)")
            }
        }
    }

    func didOpen(uri: String, languageId: String, text: String) {
        let params: [String: Any] = [
            "textDocument": [
                "uri": uri,
                "languageId": languageId,
                "version": 1,
                "text": text
            ]
        ]
        sendNotification(method: "textDocument/didOpen", params: params)
    }

    func didChange(uri: String, version: Int, changes: [[String: Any]]) {
        let params: [String: Any] = [
            "textDocument": [
                "uri": uri,
                "version": version
            ],
            "contentChanges": changes
        ]
        sendNotification(method: "textDocument/didChange", params: params)
    }

    func completion(uri: String, line: Int, character: Int, completion: @escaping ([CompletionItem]) -> Void) {
        let params: [String: Any] = [
            "textDocument": ["uri": uri],
            "position": [
                "line": line,
                "character": character
            ]
        ]

        sendRequest(method: "textDocument/completion", params: params) { result in
            switch result {
            case .success(let response):
                if let items = response["items"] as? [[String: Any]] {
                    let completions = items.compactMap { CompletionItem(from: $0) }
                    completion(completions)
                } else {
                    completion([])
                }

            case .failure:
                completion([])
            }
        }
    }

    func hover(uri: String, line: Int, character: Int, completion: @escaping (HoverInfo?) -> Void) {
        let params: [String: Any] = [
            "textDocument": ["uri": uri],
            "position": [
                "line": line,
                "character": character
            ]
        ]

        sendRequest(method: "textDocument/hover", params: params) { result in
            switch result {
            case .success(let response):
                completion(HoverInfo(from: response))

            case .failure:
                completion(nil)
            }
        }
    }

    func definition(uri: String, line: Int, character: Int, completion: @escaping ([Location]) -> Void) {
        let params: [String: Any] = [
            "textDocument": ["uri": uri],
            "position": [
                "line": line,
                "character": character
            ]
        ]

        sendRequest(method: "textDocument/definition", params: params) { result in
            switch result {
            case .success(let response):
                if let locations = response as? [[String: Any]] {
                    let locs = locations.compactMap { Location(from: $0) }
                    completion(locs)
                } else if let location = Location(from: response) {
                    completion([location])
                } else {
                    completion([])
                }

            case .failure:
                completion([])
            }
        }
    }

    func shutdown() {
        sendRequest(method: "shutdown", params: [:]) { _ in }
        sendNotification(method: "exit", params: [:])
    }

    // MARK: - Protocol Handling

    private func sendRequest(method: String, params: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        requestId += 1
        let id = requestId

        let message: [String: Any] = [
            "jsonrpc": "2.0",
            "id": id,
            "method": method,
            "params": params
        ]

        pendingRequests[id] = completion
        sendMessage(message)
    }

    private func sendNotification(method: String, params: [String: Any]) {
        let message: [String: Any] = [
            "jsonrpc": "2.0",
            "method": method,
            "params": params
        ]

        sendMessage(message)
    }

    private func sendMessage(_ message: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let json = String(data: data, encoding: .utf8) else {
            return
        }

        let content = "Content-Length: \(json.utf8.count)\r\n\r\n\(json)"

        if let data = content.data(using: .utf8) {
            inputPipe?.fileHandleForWriting.write(data)
        }
    }

    private func handleOutput(_ data: Data) {
        // Parse LSP message (Content-Length header + JSON)
        // This is simplified - production would handle streaming properly
        guard let string = String(data: data, encoding: .utf8) else { return }

        // Extract JSON part
        if let jsonStart = string.range(of: "{") {
            let jsonString = String(string[jsonStart.lowerBound...])

            if let jsonData = jsonString.data(using: .utf8),
               let message = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                handleMessage(message)
            }
        }
    }

    private func handleMessage(_ message: [String: Any]) {
        if let method = message["method"] as? String {
            // Notification or request from server
            handleNotification(method: method, params: message["params"] as? [String: Any] ?? [:])
        } else if let id = message["id"] as? Int {
            // Response to our request
            if let completion = pendingRequests.removeValue(forKey: id) {
                if let error = message["error"] {
                    completion(.failure(LSPError.serverError(error)))
                } else if let result = message["result"] as? [String: Any] {
                    completion(.success(result))
                } else {
                    completion(.success([:]))
                }
            }
        }
    }

    private func handleNotification(method: String, params: [String: Any]) {
        switch method {
        case "textDocument/publishDiagnostics":
            if let diags = params["diagnostics"] as? [[String: Any]] {
                DispatchQueue.main.async {
                    self.diagnostics = diags.compactMap { Diagnostic(from: $0) }
                }
            }

        default:
            break
        }
    }

    private func parseCapabilities(_ capabilities: [String: Any]) {
        self.capabilities = ServerCapabilities(from: capabilities)
    }
}

// MARK: - Models

struct CompletionItem {
    let label: String
    let kind: CompletionItemKind
    let detail: String?
    let documentation: String?
    let insertText: String?

    init?(from dict: [String: Any]) {
        guard let label = dict["label"] as? String else { return nil }

        self.label = label
        self.kind = CompletionItemKind(rawValue: dict["kind"] as? Int ?? 1) ?? .text
        self.detail = dict["detail"] as? String
        self.documentation = dict["documentation"] as? String
        self.insertText = dict["insertText"] as? String ?? label
    }

    enum CompletionItemKind: Int {
        case text = 1
        case method = 2
        case function = 3
        case constructor = 4
        case field = 5
        case variable = 6
        case `class` = 7
        case interface = 8
        case module = 9
        case property = 10
        case unit = 11
        case value = 12
        case `enum` = 13
        case keyword = 14
        case snippet = 15
        case color = 16
        case file = 17
        case reference = 18
    }
}

struct HoverInfo {
    let contents: String

    init?(from dict: [String: Any]) {
        if let contents = dict["contents"] as? String {
            self.contents = contents
        } else if let contents = dict["contents"] as? [String: Any],
                  let value = contents["value"] as? String {
            self.contents = value
        } else {
            return nil
        }
    }
}

struct Location {
    let uri: String
    let range: LSPRange

    init?(from dict: [String: Any]) {
        guard let uri = dict["uri"] as? String,
              let rangeDict = dict["range"] as? [String: Any],
              let range = LSPRange(from: rangeDict) else {
            return nil
        }

        self.uri = uri
        self.range = range
    }
}

struct LSPRange {
    let start: Position
    let end: Position

    init?(from dict: [String: Any]) {
        guard let startDict = dict["start"] as? [String: Any],
              let endDict = dict["end"] as? [String: Any],
              let start = Position(from: startDict),
              let end = Position(from: endDict) else {
            return nil
        }

        self.start = start
        self.end = end
    }
}

struct Position {
    let line: Int
    let character: Int

    init?(from dict: [String: Any]) {
        guard let line = dict["line"] as? Int,
              let character = dict["character"] as? Int else {
            return nil
        }

        self.line = line
        self.character = character
    }
}

struct Diagnostic: Identifiable {
    let id = UUID()
    let range: LSPRange
    let severity: DiagnosticSeverity
    let message: String
    let source: String?

    init?(from dict: [String: Any]) {
        guard let rangeDict = dict["range"] as? [String: Any],
              let range = LSPRange(from: rangeDict),
              let message = dict["message"] as? String else {
            return nil
        }

        self.range = range
        self.severity = DiagnosticSeverity(rawValue: dict["severity"] as? Int ?? 1) ?? .error
        self.message = message
        self.source = dict["source"] as? String
    }

    enum DiagnosticSeverity: Int {
        case error = 1
        case warning = 2
        case information = 3
        case hint = 4
    }
}

struct ServerCapabilities {
    let completionProvider: Bool
    let hoverProvider: Bool
    let definitionProvider: Bool
    let referencesProvider: Bool

    init(from dict: [String: Any]) {
        self.completionProvider = dict["completionProvider"] != nil
        self.hoverProvider = dict["hoverProvider"] as? Bool ?? false
        self.definitionProvider = dict["definitionProvider"] as? Bool ?? false
        self.referencesProvider = dict["referencesProvider"] as? Bool ?? false
    }
}

enum LSPError: Error {
    case serverError(Any)
    case timeout
    case invalidResponse
}
