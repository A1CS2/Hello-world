# AI Coding Suite - Comprehensive User Guide

## 🎉 Welcome to AI Coding Suite!

This guide explains how every feature works, the architecture behind it, and how to get the most out of your AI-powered development environment.

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Architecture Overview](#architecture-overview)
3. [Core Features](#core-features)
4. [AI Features](#ai-features)
5. [Professional Tools](#professional-tools)
6. [Plugin System](#plugin-system)
7. [Customization](#customization)
8. [Performance & Optimization](#performance--optimization)
9. [Keyboard Shortcuts](#keyboard-shortcuts)
10. [Troubleshooting](#troubleshooting)

---

## Getting Started

### First Launch

When you first open AI Coding Suite, you'll see an interactive onboarding tutorial. This guides you through:

1. **Workspace Overview** - Understanding the layout
2. **AI Features** - Setting up AI providers
3. **Terminal** - Using the integrated terminal
4. **Plugins** - Discovering extensions
5. **Shortcuts** - Learning keyboard shortcuts

**How It Works**: The `OnboardingManager` tracks whether you've completed onboarding using `UserDefaults`. When `hasCompletedOnboarding` is false, the app displays the `OnboardingView` overlay with step-by-step instructions.

### Opening Your First Project

**Method 1: File Menu**
```
File → Open Workspace (⌘O)
```

**Method 2: Drag & Drop**
- Drag a folder onto the app icon or window

**Method 3: Recent Projects**
```
File → Open Recent
```

**Under the Hood**: The `WorkspaceManager` class handles workspace loading:
1. Validates the folder exists
2. Creates a `Workspace` model with path, name, and files
3. Initializes file watcher for change detection
4. Loads workspace-specific settings from `.aicodingsuite/` folder
5. Publishes changes via Combine's `@Published` to update UI

---

## Architecture Overview

### Technology Stack

**Core Technologies**:
- **Swift 5.9+**: Modern, type-safe programming language
- **SwiftUI**: Declarative UI framework for macOS
- **Combine**: Reactive programming for state management
- **AppKit**: Native macOS integration where needed

**Design Patterns**:
- **MVVM (Model-View-ViewModel)**: Separates UI from business logic
- **Protocol-Oriented**: Extensible interfaces for plugins
- **Dependency Injection**: Services injected via `@EnvironmentObject`
- **Observer Pattern**: Combine publishers for reactive updates

### App Structure

```
AICodingSuiteApp (Main Entry Point)
├── AppState (Global state management)
├── ThemeManager (Theme configuration)
├── WorkspaceManager (Project management)
└── MainWindowView (Root view)
    ├── Sidebar (File Explorer, Git Panel)
    ├── CentralArea (Editor, Visualizations)
    ├── RightPanel (AI Chat, Plugins)
    └── BottomPanel (Terminal, Debug Console)
```

### How Data Flows

1. **User Action** → Triggers SwiftUI view event
2. **View** → Calls ViewModel/Manager method
3. **Manager** → Updates `@Published` properties
4. **Combine** → Propagates changes to subscribers
5. **UI** → Automatically re-renders affected views

Example: Changing themes
```swift
// 1. User taps theme
Button("Neon Dark") {
    // 2. Call ThemeManager
    themeManager.setTheme(.neonDark)
}

// 3. ThemeManager updates @Published property
@Published var currentTheme: AppTheme

// 4. All views with @EnvironmentObject automatically update
@EnvironmentObject var themeManager: ThemeManager
```

---

## Core Features

### Code Editor

**File: `CodeEditorView.swift`**

The code editor is built using `NSTextView` (via `AppKit`) wrapped in SwiftUI for maximum performance.

**Features**:
- ✅ Syntax highlighting (50+ languages)
- ✅ Line numbers with current line highlighting
- ✅ Auto-indentation
- ✅ Code folding
- ✅ Multiple cursors (⌥ + Click)
- ✅ Bracket matching
- ✅ Real-time AI completions

**How Syntax Highlighting Works**:

1. **File Detection**: Language detected from file extension
   ```swift
   extension String {
       var languageType: LanguageType {
           switch self.lowercased() {
           case "swift": return .swift
           case "py": return .python
           // ... 50+ languages
           }
       }
   }
   ```

2. **Tokenization**: Code is parsed into tokens (keywords, strings, comments, etc.)

3. **Highlighting**: Each token type gets themed colors
   ```swift
   func highlightSyntax(code: String, language: LanguageType) -> NSAttributedString {
       // Parse code into tokens
       let tokens = tokenize(code, language)

       // Apply colors from current theme
       for token in tokens {
           switch token.type {
           case .keyword: applyColor(theme.syntaxKeyword)
           case .string: applyColor(theme.syntaxString)
           // ...
           }
       }
   }
   ```

4. **Performance**: Uses background thread for large files
   ```swift
   DispatchQueue.global(qos: .userInteractive).async {
       let highlighted = highlightSyntax(code)
       DispatchQueue.main.async {
           textView.attributedString = highlighted
       }
   }
   ```

**AI Code Completion**:

The editor integrates with `RealTimeCompletionEngine` for intelligent suggestions:

```swift
class RealTimeCompletionEngine {
    private let debounceInterval: TimeInterval = 0.3  // Wait 300ms after typing stops
    private var cache = CompletionCache(ttl: 60)      // Cache for 60 seconds

    func requestCompletion(context: CompletionContext) {
        // 1. Check cache first
        if let cached = cache.get(context.prefix) {
            return cached
        }

        // 2. Try LSP first (fast, local)
        lspClient.completion(uri: context.uri, line: context.line, char: context.char) { items in
            if !items.isEmpty {
                return items  // LSP succeeded, use it
            }

            // 3. Fall back to AI (slower, but smarter)
            aiManager.completeCode(context) { suggestion in
                cache.set(context.prefix, suggestion)
                return suggestion
            }
        }
    }
}
```

**Why This Approach?**:
- **Fast**: LSP provides instant completions for standard code
- **Smart**: AI handles complex patterns and context-aware suggestions
- **Efficient**: Caching prevents redundant API calls
- **Smooth**: Debouncing prevents completion spam while typing

### File Explorer

**File: `FileExplorerView.swift`**

The file explorer shows your project structure with real-time updates.

**Features**:
- 📁 Tree view with expand/collapse
- 🔍 Fuzzy search
- ➕ Create files/folders
- ✏️ Rename
- 🗑️ Delete
- 📋 Copy/Paste
- 👁️ Git status indicators

**How File Watching Works**:

```swift
class FileWatcher {
    private var eventStream: FSEventStreamRef?

    func watch(path: String, callback: @escaping ([String]) -> Void) {
        // 1. Create FSEvents stream
        eventStream = FSEventStreamCreate(
            nil,                          // Allocator
            callbackBlock,                // Callback when files change
            &context,                     // Context
            [path] as CFArray,            // Paths to watch
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            1.0,                          // Latency (seconds)
            UInt32(kFSEventStreamCreateFlagFileEvents)
        )

        // 2. Schedule on run loop
        FSEventStreamScheduleWithRunLoop(
            eventStream!,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )

        // 3. Start monitoring
        FSEventStreamStart(eventStream!)
    }
}
```

When files change:
1. FSEvents notifies callback
2. Callback updates `@Published var files`
3. SwiftUI re-renders affected tree nodes
4. Animations smoothly show changes

**Git Status Integration**:

Each file shows its git status (modified, added, deleted):

```swift
struct FileItem {
    var gitStatus: GitStatus?

    var statusColor: Color {
        switch gitStatus {
        case .modified: return .orange
        case .added: return .green
        case .deleted: return .red
        case .untracked: return .gray
        default: return .clear
        }
    }
}
```

### Integrated Terminal

**File: `TerminalView.swift`**

A full-featured terminal emulator built into the IDE.

**How It Works**:

1. **PTY (Pseudo-Terminal)**:
   ```swift
   class TerminalEmulator {
       private var masterFD: Int32 = -1
       private var slaveFD: Int32 = -1

       func spawn(shell: String = "/bin/zsh") {
           // 1. Create pseudo-terminal pair
           openpty(&masterFD, &slaveFD, nil, nil, nil)

           // 2. Fork process
           let pid = fork()

           if pid == 0 {
               // Child process: run shell
               dup2(slaveFD, STDIN_FILENO)
               dup2(slaveFD, STDOUT_FILENO)
               dup2(slaveFD, STDERR_FILENO)
               execl(shell, shell, nil)
           } else {
               // Parent process: read output
               readOutput()
           }
       }
   }
   ```

2. **Output Processing**:
   ```swift
   func readOutput() {
       let queue = DispatchQueue(label: "terminal.output")
       queue.async {
           while true {
               var buffer = [UInt8](repeating: 0, count: 4096)
               let bytesRead = read(masterFD, &buffer, 4096)

               if bytesRead > 0 {
                   let output = String(bytes: buffer[0..<bytesRead], encoding: .utf8)

                   DispatchQueue.main.async {
                       // Update UI with new output
                       self.terminalOutput += output
                   }
               }
           }
       }
   }
   ```

3. **Input Handling**:
   ```swift
   func sendInput(_ text: String) {
       let data = text.data(using: .utf8)!
       data.withUnsafeBytes { ptr in
           write(masterFD, ptr.baseAddress, data.count)
       }
   }
   ```

**Smart Features**:

- **Command History**: Stores last 100 commands in UserDefaults
- **Auto-complete**: Suggests commands and file paths
- **Git Integration**: Special handling for git commands with syntax highlighting
- **Environment**: Inherits environment variables from parent process

---

## AI Features

### AI Chat Panel

**File: `AIChatView.swift`**

Chat with AI to get code help, explanations, and suggestions.

**How It Works**:

1. **Message Processing**:
   ```swift
   func sendMessage(_ text: String) {
       // 1. Add user message to chat
       let userMessage = ChatMessage(role: .user, content: text)
       messages.append(userMessage)

       // 2. Get current code context
       let context = CodeContext(
           language: currentFile.language,
           code: currentFile.content,
           cursorPosition: editor.cursorPosition
       )

       // 3. Send to AI with context
       aiManager.chat(message: text, context: context) { response in
           let aiMessage = ChatMessage(role: .assistant, content: response)
           messages.append(aiMessage)
       }
   }
   ```

2. **Context Awareness**:
   ```swift
   struct CodeContext {
       let language: String
       let code: String
       let cursorPosition: Int
       let selectedText: String?
       let recentEdits: [Edit]

       var prompt: String {
           """
           Language: \(language)

           Current code:
           ```\(language)
           \(code)
           ```

           Cursor at line \(cursorLine)
           \(selectedText != nil ? "Selected: \(selectedText!)" : "")

           User question: {user_message}
           """
       }
   }
   ```

3. **Streaming Responses** (for supported providers):
   ```swift
   func chatStreaming(prompt: String, callback: @escaping (String) -> Void) {
       var accumulated = ""

       provider.streamCompletion(prompt) { chunk in
           accumulated += chunk

           DispatchQueue.main.async {
               // Update UI with each chunk for typewriter effect
               callback(accumulated)
           }
       }
   }
   ```

**AI Provider Integration**:

```swift
protocol AIProvider {
    func completeCode(context: CodeContext, completion: @escaping (Result<String, Error>) -> Void)
    func explainCode(code: String, completion: @escaping (Result<String, Error>) -> Void)
    func refactorCode(code: String, instruction: String, completion: @escaping (Result<String, Error>) -> Void)
    func fixError(code: String, error: String, completion: @escaping (Result<String, Error>) -> Void)
}

// Implementations:
class OpenAIProvider: AIProvider { /* ... */ }
class AnthropicProvider: AIProvider { /* ... */ }
class LocalLLMProvider: AIProvider { /* ... */ }
```

**Supported AI Features**:

1. **Code Completion**: Generate code from natural language
2. **Code Explanation**: Understand what code does
3. **Refactoring**: Improve code structure and style
4. **Error Fixing**: Get suggestions to fix errors
5. **Documentation**: Generate comments and docs
6. **Code Review**: Get feedback on code quality

### Language Server Protocol (LSP)

**File: `LSPClient.swift`**

LSP provides IDE features like autocomplete, go-to-definition, and diagnostics.

**How LSP Works**:

1. **Initialization**:
   ```swift
   func initialize(rootPath: String) {
       // 1. Spawn language server process
       let process = Process()
       process.executableURL = URL(fileURLWithPath: "/usr/local/bin/sourcekit-lsp")  // Swift
       process.arguments = []

       // 2. Set up stdin/stdout pipes
       let inputPipe = Pipe()
       let outputPipe = Pipe()
       process.standardInput = inputPipe
       process.standardOutput = outputPipe

       // 3. Start process
       process.launch()

       // 4. Send initialize request
       sendRequest(method: "initialize", params: [
           "processId": ProcessInfo.processInfo.processIdentifier,
           "rootPath": rootPath,
           "capabilities": clientCapabilities
       ])
   }
   ```

2. **JSON-RPC Communication**:
   ```swift
   func sendRequest(method: String, params: [String: Any], completion: @escaping (Any?) -> Void) {
       let request = [
           "jsonrpc": "2.0",
           "id": requestID,
           "method": method,
           "params": params
       ]

       let json = try! JSONSerialization.data(withJSONObject: request)
       let header = "Content-Length: \(json.count)\r\n\r\n"

       // Write to stdin
       inputPipe.fileHandleForWriting.write(header.data(using: .utf8)!)
       inputPipe.fileHandleForWriting.write(json)

       // Register callback for response
       pendingRequests[requestID] = completion
       requestID += 1
   }
   ```

3. **Document Synchronization**:
   ```swift
   func didOpen(uri: String, text: String, language: String) {
       sendNotification(method: "textDocument/didOpen", params: [
           "textDocument": [
               "uri": uri,
               "languageId": language,
               "version": 1,
               "text": text
           ]
       ])
   }

   func didChange(uri: String, changes: [TextChange]) {
       sendNotification(method: "textDocument/didChange", params: [
           "textDocument": ["uri": uri, "version": version],
           "contentChanges": changes.map { ["text": $0.text] }
       ])
   }
   ```

4. **Completion Requests**:
   ```swift
   func completion(uri: String, line: Int, character: Int) -> [CompletionItem] {
       sendRequest(method: "textDocument/completion", params: [
           "textDocument": ["uri": uri],
           "position": ["line": line, "character": character]
       ]) { response in
           // Parse completion items
           let items = response["items"] as? [[String: Any]]
           return items.map { CompletionItem(from: $0) }
       }
   }
   ```

**Supported LSP Features**:

- **textDocument/completion**: Auto-complete suggestions
- **textDocument/hover**: Hover information
- **textDocument/definition**: Go to definition
- **textDocument/references**: Find references
- **textDocument/formatting**: Code formatting
- **textDocument/publishDiagnostics**: Error/warning messages

---

## Professional Tools

### Git Integration

**File: `GitManager.swift`**

Full git integration with visual diff viewer and commit workflow.

**How Git Commands Work**:

```swift
class GitManager {
    func executeGitCommand(_ args: [String], completion: @escaping (Result<String, Error>) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: workspacePath)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        process.terminationHandler = { process in
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""

            DispatchQueue.main.async {
                if process.terminationStatus == 0 {
                    completion(.success(output))
                } else {
                    completion(.failure(GitError.commandFailed(output)))
                }
            }
        }

        try? process.run()
    }

    // Higher-level operations
    func status() { executeGitCommand(["status", "--porcelain"]) }
    func diff(file: String) { executeGitCommand(["diff", file]) }
    func add(files: [String]) { executeGitCommand(["add"] + files) }
    func commit(message: String) { executeGitCommand(["commit", "-m", message]) }
    func push() { executeGitCommand(["push"]) }
}
```

**Visual Diff Viewer**:

Shows side-by-side or inline diff with syntax highlighting:

```swift
struct DiffLine {
    enum LineType {
        case addition    // Green: New line
        case deletion    // Red: Removed line
        case context     // Gray: Unchanged line
    }

    let type: LineType
    let content: String
    let oldLineNumber: Int?
    let newLineNumber: Int?
}

func parseDiff(_ diffOutput: String) -> [DiffLine] {
    var lines: [DiffLine] = []

    for line in diffOutput.components(separatedBy: "\n") {
        if line.hasPrefix("+") {
            lines.append(DiffLine(type: .addition, content: line, ...))
        } else if line.hasPrefix("-") {
            lines.append(DiffLine(type: .deletion, content: line, ...))
        } else {
            lines.append(DiffLine(type: .context, content: line, ...))
        }
    }

    return lines
}
```

### Docker Integration

**File: `DockerManager.swift`**

Manage Docker containers and images without leaving the IDE.

**How It Works**:

```swift
class DockerManager {
    func executeCommand(_ args: [String], completion: @escaping (Result<String, Error>) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/docker")
        process.arguments = args

        // Same pattern as git: spawn process, read output
        // ...
    }

    // Container operations
    func listContainers() {
        executeCommand(["ps", "-a", "--format", "json"]) { result in
            let containers = parseJSON(result)
            self.containers = containers
        }
    }

    func startContainer(_ id: String) {
        executeCommand(["start", id]) { _ in
            self.listContainers()  // Refresh
        }
    }

    func stopContainer(_ id: String) {
        executeCommand(["stop", id])
    }

    func getContainerLogs(_ id: String) {
        executeCommand(["logs", id, "--tail", "100"])
    }
}
```

**Real-time Updates**:

```swift
class DockerManager: ObservableObject {
    @Published var containers: [DockerContainer] = []
    @Published var images: [DockerImage] = []

    private var refreshTimer: Timer?

    func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.listContainers()
            self.listImages()
        }
    }
}
```

### Database Manager

**File: `DatabaseManager.swift`**

Connect to databases and execute queries with visual results.

**Connection Management**:

```swift
struct DatabaseConnection {
    let id: UUID
    var name: String
    var type: DatabaseType  // PostgreSQL, MySQL, SQLite, MongoDB, Redis
    var host: String
    var port: Int
    var database: String
    var username: String
    var password: String  // Stored in Keychain in production
}

class DatabaseManager: ObservableObject {
    @Published var connections: [DatabaseConnection] = []
    @Published var activeConnection: DatabaseConnection?

    func connect(to connection: DatabaseConnection) {
        // In production, use actual database drivers
        // For now, simulated connection

        DispatchQueue.global().async {
            // Attempt connection
            Thread.sleep(forTimeInterval: 1)

            DispatchQueue.main.async {
                self.activeConnection = connection
            }
        }
    }

    func executeQuery(_ query: String) -> QueryResult {
        let queryType = determineQueryType(query)

        switch queryType {
        case .select:
            // Return rows
            return QueryResult(
                columns: ["id", "name", "email"],
                rows: [
                    ["1", "John", "john@example.com"],
                    ["2", "Jane", "jane@example.com"]
                ],
                executionTime: 0.042
            )
        case .insert, .update, .delete:
            // Return affected rows
            return QueryResult(rowsAffected: 1, executionTime: 0.028)
        }
    }
}
```

### REST API Client

**File: `RESTClient.swift`**

Test HTTP endpoints with request/response inspection.

**How Requests Work**:

```swift
class RESTClient: ObservableObject {
    func sendRequest(_ request: HTTPRequest) {
        // 1. Build URLRequest
        guard let url = URL(string: request.url) else { return }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        // 2. Add headers
        for header in request.headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        // 3. Add body
        if !request.body.isEmpty {
            urlRequest.httpBody = request.body.data(using: .utf8)
        }

        // 4. Send request
        let startTime = Date()
        URLSession.shared.dataTask(with: urlRequest) { data, response, error in
            let duration = Date().timeIntervalSince(startTime)

            // 5. Parse response
            let httpResponse = response as? HTTPURLResponse
            let responseBody = String(data: data ?? Data(), encoding: .utf8) ?? ""

            let result = HTTPResponse(
                statusCode: httpResponse?.statusCode ?? 0,
                headers: httpResponse?.allHeaderFields as? [String: String] ?? [:],
                body: responseBody,
                responseTime: duration
            )

            // 6. Update UI
            DispatchQueue.main.async {
                self.response = result
            }
        }.resume()
    }
}
```

**Request History**:

```swift
func saveRequest(_ request: HTTPRequest) {
    requests.append(request)

    // Persist to UserDefaults
    if let data = try? JSONEncoder().encode(requests) {
        UserDefaults.standard.set(data, forKey: "rest_requests")
    }
}

func loadRequests() {
    if let data = UserDefaults.standard.data(forKey: "rest_requests"),
       let requests = try? JSONDecoder().decode([HTTPRequest].self, from: data) {
        self.requests = requests
    }
}
```

---

## Plugin System

**File: `PluginSystem.swift`**

Extend functionality with third-party plugins.

### Plugin Architecture

**Sandbox Model**:

```swift
class PluginManager {
    private var activePlugins: [String: Plugin] = [:]

    func activatePlugin(_ pluginID: String) throws {
        guard let plugin = installedPlugins[pluginID] else {
            throw PluginError.notFound
        }

        // 1. Verify permissions
        let hasPermissions = verifyPermissions(plugin.manifest.permissions)
        guard hasPermissions else {
            throw PluginError.permissionDenied
        }

        // 2. Load plugin code
        guard let bundle = Bundle(url: plugin.url) else {
            throw PluginError.invalidBundle
        }

        // 3. Instantiate plugin class
        guard let pluginClass = bundle.principalClass as? PluginProtocol.Type else {
            throw PluginError.invalidPlugin
        }

        let instance = pluginClass.init()

        // 4. Create sandboxed context
        let context = PluginContext(
            workspace: workspaceManager,
            editor: editorManager,
            permissions: plugin.manifest.permissions
        )

        // 5. Initialize plugin
        instance.initialize(context: context)

        activePlugins[pluginID] = instance
    }
}
```

**Plugin Protocol**:

```swift
protocol PluginProtocol {
    var manifest: PluginManifest { get }

    func initialize(context: PluginContext)
    func activate()
    func deactivate()
    func executeCommand(_ command: String, args: [String: Any]) -> Any?
}
```

**Plugin API**:

```swift
class PluginContext {
    // Editor API
    func getCurrentFile() -> FileContent?
    func getSelectedText() -> String?
    func insertText(_ text: String, at position: Int)
    func replaceSelection(with text: String)

    // Workspace API
    func getAllFiles() -> [FileInfo]
    func createFile(path: String, content: String)
    func readFile(path: String) -> String?

    // Terminal API
    func executeCommand(_ command: String) -> String

    // UI API
    func showNotification(title: String, message: String)
    func showInputDialog(title: String, prompt: String) -> String?

    // All operations check permissions first
    private func checkPermission(_ permission: Permission) throws {
        guard permissions.contains(permission) else {
            throw PluginError.permissionDenied
        }
    }
}
```

**Permission System**:

```swift
enum Permission: String {
    case fileRead = "file.read"
    case fileWrite = "file.write"
    case networkAccess = "network.access"
    case terminalExec = "terminal.exec"
    case uiModify = "ui.modify"
    case gitAccess = "git.access"
    case aiAccess = "ai.access"
}

func verifyPermissions(_ requested: [Permission]) -> Bool {
    // Show permission dialog
    let alert = NSAlert()
    alert.messageText = "Plugin Permission Request"
    alert.informativeText = "This plugin requests:\n\(requested.map { "• \($0.rawValue)" }.joined(separator: "\n"))"
    alert.addButton(withTitle: "Allow")
    alert.addButton(withTitle: "Deny")

    return alert.runModal() == .alertFirstButtonReturn
}
```

### Creating Plugins

**Plugin Manifest** (`plugin.json`):

```json
{
  "id": "com.example.prettify",
  "name": "Code Prettifier",
  "version": "1.0.0",
  "description": "Automatically format code on save",
  "author": "John Doe",
  "permissions": [
    "file.read",
    "file.write"
  ],
  "capabilities": [
    "editor.onSave"
  ],
  "main": "index.js"
}
```

**Plugin Code** (`index.js`):

```javascript
class PrettifyPlugin {
    initialize(context) {
        this.context = context;

        // Subscribe to save events
        context.on('editor.willSave', (file) => {
            const formatted = this.formatCode(file.content);
            file.content = formatted;
        });
    }

    formatCode(code) {
        // Format code logic
        return prettify(code);
    }
}

module.exports = PrettifyPlugin;
```

---

## Customization

### Themes

**File: `ThemeManager.swift`**

**Built-in Themes**:

1. **Neon Dark**: Cyan accents, dark background
2. **Neon Blue**: Blue gradients, professional look
3. **Cyberpunk**: Purple/pink, high energy
4. **Midnight**: Deep blue, calming
5. **Aurora**: Green/purple northern lights

**Theme Structure**:

```swift
struct AppTheme {
    let name: String
    let background: Color
    let surface: Color
    let textPrimary: Color
    let textSecondary: Color
    let neonAccent: Color
    let neonSecondary: Color

    // Glassmorphism
    let enableGlassmorphism: Bool
    let glassOpacity: Double
    let blurRadius: CGFloat
    let glowIntensity: Double

    // Syntax highlighting
    let syntaxKeyword: Color
    let syntaxString: Color
    let syntaxComment: Color
    let syntaxFunction: Color
    let syntaxVariable: Color
}
```

**Creating Custom Themes**:

```swift
let myTheme = AppTheme(
    name: "Ocean Breeze",
    background: Color(red: 0.05, green: 0.15, blue: 0.25),
    surface: Color(red: 0.1, green: 0.2, blue: 0.3),
    textPrimary: Color.white,
    textSecondary: Color.gray,
    neonAccent: Color(red: 0.0, green: 0.7, blue: 0.9),
    neonSecondary: Color(red: 0.0, green: 0.5, blue: 0.7),
    enableGlassmorphism: true,
    glassOpacity: 0.3,
    blurRadius: 20,
    glowIntensity: 0.6,
    syntaxKeyword: Color.cyan,
    syntaxString: Color.green,
    syntaxComment: Color.gray,
    syntaxFunction: Color.yellow,
    syntaxVariable: Color.white
)

themeManager.addCustomTheme(myTheme)
```

### Animations

**File: `AnimationSystem.swift`**

**Animation Presets**:

```swift
enum AppAnimation {
    static let quick = Animation.easeOut(duration: 0.15)
    static let medium = Animation.easeInOut(duration: 0.3)
    static let slow = Animation.easeInOut(duration: 0.5)
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let springBouncy = Animation.spring(response: 0.5, dampingFraction: 0.6)
}
```

**Micro-interactions**:

```swift
// Shimmer effect (loading states)
Text("Loading...")
    .shimmer()

// Pulse effect (notifications)
Circle()
    .pulse()

// Typing animation
TypingAnimationView(text: "AI is thinking...")

// Bounce on appear
Button("Click me")
    .bounceOnAppear()
```

**Accessibility**:

All animations respect "Reduce Motion" setting:

```swift
func animation(default defaultAnimation: Animation) -> Animation {
    AccessibilityManager.shared.shouldReduceMotion()
        ? .linear(duration: 0)  // Instant for reduce motion
        : defaultAnimation      // Normal animation
}
```

---

## Performance & Optimization

### Performance Monitoring

**File: `PerformanceProfiler.swift`**

Monitor app performance in real-time.

**Metrics Tracked**:

1. **Memory Usage**:
   ```swift
   func getMemoryUsage() -> MemoryMetrics {
       var info = mach_task_basic_info()
       task_info(mach_task_self_, MACH_TASK_BASIC_INFO, ...)

       let usedMB = Double(info.resident_size) / 1024 / 1024
       return MemoryMetrics(used: usedMB, total: totalSystemRAM)
   }
   ```

2. **CPU Usage**:
   ```swift
   func getCPUUsage() -> Double {
       var threadsList: thread_act_array_t?
       task_threads(mach_task_self_, &threadsList, &threadsCount)

       var totalCPU = 0.0
       for thread in threadsList {
           var threadInfo = thread_basic_info()
           thread_info(thread, THREAD_BASIC_INFO, ...)
           totalCPU += Double(threadInfo.cpu_usage) / TH_USAGE_SCALE * 100
       }
       return totalCPU
   }
   ```

3. **Frame Rate**: Monitors SwiftUI rendering performance

4. **Network Activity**: Tracks URLSession requests

**Performance Markers**:

```swift
// Measure operation performance
PerformanceProfiler.shared.startMarker("file_open")
// ... perform file operation
let duration = PerformanceProfiler.shared.endMarker("file_open")
// Prints: "⏱️ Performance: file_open took 42.5ms"
```

### Optimization Techniques

**1. Lazy Loading**:

```swift
// Don't load all files at once
ScrollView {
    LazyVStack {  // Only creates visible views
        ForEach(files) { file in
            FileRow(file: file)
        }
    }
}
```

**2. Background Processing**:

```swift
// Heavy operations on background thread
DispatchQueue.global(qos: .userInteractive).async {
    let result = heavyComputation()

    DispatchQueue.main.async {
        // Update UI on main thread
        self.result = result
    }
}
```

**3. Caching**:

```swift
class CompletionCache {
    private var cache: [String: (suggestion: String, timestamp: Date)] = [:]
    private let ttl: TimeInterval = 60  // 60 seconds

    func get(_ key: String) -> String? {
        guard let entry = cache[key] else { return nil }

        // Check if expired
        if Date().timeIntervalSince(entry.timestamp) > ttl {
            cache.removeValue(forKey: key)
            return nil
        }

        return entry.suggestion
    }
}
```

**4. Debouncing**:

```swift
class Debouncer {
    private var workItem: DispatchWorkItem?
    private let delay: TimeInterval

    func debounce(_ action: @escaping () -> Void) {
        workItem?.cancel()
        workItem = DispatchWorkItem(block: action)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: workItem!)
    }
}

// Usage: Only send request after user stops typing for 300ms
let debouncer = Debouncer(delay: 0.3)
onTextChange { text in
    debouncer.debounce {
        sendCompletionRequest(text)
    }
}
```

---

## Keyboard Shortcuts

### Global Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘N | New File |
| ⌘O | Open Workspace |
| ⌘S | Save File |
| ⌘W | Close File |
| ⌘⇧S | Save All |
| ⌘Q | Quit |

### Editor Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘Z | Undo |
| ⌘⇧Z | Redo |
| ⌘F | Find in File |
| ⌘G | Find Next |
| ⌘⇧F | Search in Workspace |
| ⌘⌥F | Replace in File |
| ⌘L | Go to Line |
| ⌘D | Duplicate Line |
| ⌘/ | Toggle Comment |

### View Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘B | Toggle Sidebar |
| ⌘` | Toggle Terminal |
| ⌘⇧P | Command Palette |
| ⌘K | AI Chat |
| ⌘⇧M | Metrics Dashboard |

### AI Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘K | Open AI Chat |
| ⌥Space | Trigger Completion |
| ⌘⇧E | Explain Code |
| ⌘⇧R | Refactor Code |

### Custom Shortcuts

```swift
// Add in SettingsView
struct ShortcutCustomization: View {
    @State private var shortcuts: [String: KeyboardShortcut] = [:]

    var body: some View {
        Form {
            ForEach(actions) { action in
                HStack {
                    Text(action.name)
                    Spacer()
                    ShortcutRecorder(binding: $shortcuts[action.id])
                }
            }
        }
    }
}
```

---

## Troubleshooting

### Common Issues

#### 1. LSP Not Working

**Symptom**: No autocomplete, hover info, or diagnostics

**Solutions**:
- Check if language server is installed:
  ```bash
  which sourcekit-lsp  # Swift
  which pyls           # Python
  which typescript-language-server  # TypeScript
  ```
- Restart LSP: Settings → Advanced → Restart Language Servers
- Check LSP logs: View → Show LSP Logs

#### 2. AI Completions Slow

**Symptom**: Long wait for AI suggestions

**Solutions**:
- Check internet connection
- Try different AI provider (Settings → AI → Provider)
- Reduce context size (Settings → AI → Max Context Length)
- Enable caching (Settings → AI → Enable Cache)

#### 3. High Memory Usage

**Symptom**: App using >1GB RAM

**Solutions**:
- Close unused files
- Reduce file watcher scope (Settings → Workspace → Watch Patterns)
- Disable plugins (Settings → Plugins → Disable All)
- Check Performance Dashboard for memory leaks

#### 4. Terminal Not Responding

**Symptom**: Commands don't execute

**Solutions**:
- Restart terminal: Terminal → Restart
- Check shell path: Settings → Terminal → Shell Path
- Reset terminal: Terminal → Reset to Default

#### 5. Docker Integration Not Working

**Symptom**: Can't see containers/images

**Solutions**:
- Ensure Docker Desktop is running
- Check Docker path: Settings → Docker → Docker CLI Path
- Verify permissions: `docker ps` in terminal
- Restart Docker daemon

### Debug Mode

Enable debug logging:

```
Settings → Advanced → Enable Debug Logging
```

Logs location:
```
~/Library/Application Support/AI Coding Suite/Logs/
```

View logs:
```
View → Developer → Show Logs
```

### Reset Settings

If all else fails:

```
Settings → Advanced → Reset All Settings
```

Or manually delete:
```bash
rm -rf ~/Library/Application\ Support/AI\ Coding\ Suite/
rm -rf ~/Library/Preferences/app.aicodingsuite.macos.plist
```

---

## Advanced Topics

### Architecture Deep Dive

**State Management**:

```
AppState (Root @StateObject)
├── ThemeManager
│   └── @Published currentTheme
├── WorkspaceManager
│   ├── @Published currentWorkspace
│   └── @Published files
├── AIManager
│   ├── @Published provider
│   └── @Published chatHistory
└── PluginManager
    └── @Published activePlugins

Changes flow:
User Action → Manager Method → @Published Property → Combine → UI Update
```

**View Hierarchy**:

```
WindowGroup
└── MainWindowView
    ├── Sidebar
    │   ├── FileExplorerView
    │   ├── GitPanelView
    │   └── PluginPanelView
    ├── CentralArea
    │   ├── CodeEditorView
    │   ├── DataVisualizationView
    │   └── DockerView
    ├── RightPanel
    │   ├── AIChatView
    │   └── PluginMarketplaceView
    └── BottomPanel
        ├── TerminalView
        └── DebugConsoleView
```

**Data Flow Example** (Opening a file):

```
1. User clicks file in FileExplorer
   ↓
2. FileExplorerView calls:
   workspaceManager.openFile(path)
   ↓
3. WorkspaceManager:
   - Reads file from disk
   - Creates FileContent model
   - Updates @Published var currentFile
   ↓
4. Combine propagates change
   ↓
5. CodeEditorView receives new file
   ↓
6. Editor displays content with syntax highlighting
   ↓
7. LSP notified:
   lspClient.didOpen(uri, text, language)
   ↓
8. AI context updated:
   aiManager.updateContext(file)
```

### Performance Best Practices

1. **Use LazyVStack/LazyHStack**: Only create visible views
2. **Avoid expensive computations in body**: Use @State or computed properties
3. **Use .onChange instead of didSet**: Better SwiftUI integration
4. **Debounce text input**: Prevent excessive updates
5. **Cache expensive results**: Don't recompute unnecessarily
6. **Use background threads**: Keep UI responsive
7. **Profile regularly**: Use PerformanceProfiler to find bottlenecks

### Security Considerations

1. **Credential Storage**: Use Keychain for passwords
   ```swift
   func storePassword(service: String, account: String, password: String) {
       let query: [String: Any] = [
           kSecClass as String: kSecClassGenericPassword,
           kSecAttrService as String: service,
           kSecAttrAccount as String: account,
           kSecValueData as String: password.data(using: .utf8)!
       ]
       SecItemAdd(query as CFDictionary, nil)
   }
   ```

2. **Plugin Sandboxing**: Limit plugin access
3. **Input Validation**: Sanitize all user input
4. **Secure Communication**: Use HTTPS for all network requests
5. **Privacy**: No data collection without explicit opt-in

---

## Tips & Tricks

### Power User Tips

1. **Multi-cursor editing**: ⌥ + Click to add cursors
2. **Quick file switching**: ⌘P then type filename
3. **Zen mode**: Hide all panels for distraction-free coding
4. **AI on selection**: Select code, ⌘K to chat about it
5. **Git staging shortcuts**: Space to stage/unstage in Git panel
6. **Terminal split**: ⌘⇧T for split terminal

### Workflow Examples

**Full-stack Development**:
1. Open workspace with frontend + backend
2. Split editor: frontend code on left, backend on right
3. Docker panel: run database containers
4. Terminal: start dev servers
5. REST client: test APIs
6. AI chat: debug issues

**Mobile App Development**:
1. Open Xcode project
2. Enable Swift LSP for completions
3. Use AI to generate SwiftUI views
4. Test layouts with visual previews
5. Git integration for version control
6. Performance profiler for optimization

**Data Science**:
1. Python workspace with Jupyter notebooks
2. AI explains complex algorithms
3. Database manager for data queries
4. Terminal for running scripts
5. Visualizations for data exploration

---

## FAQ

**Q: Can I use my own AI models?**
A: Yes! Settings → AI → Provider → Local LLM, then point to your model endpoint.

**Q: Does it work offline?**
A: Editor, terminal, git, and file operations work offline. AI features require internet unless using local LLM.

**Q: How much does it cost?**
A: Free for core features. Premium tier ($9.99/month) includes advanced AI models and cloud sync.

**Q: Can I sync settings across Macs?**
A: Yes, with Premium subscription. Settings → Account → Enable Cloud Sync.

**Q: Is my code sent to AI providers?**
A: Only when you explicitly use AI features. You can disable AI entirely in Settings.

**Q: Can I create my own themes?**
A: Yes! Settings → Appearance → Create Custom Theme.

**Q: Does it support Windows/Linux?**
A: Currently macOS only. Windows/Linux support is planned.

**Q: How do I report bugs?**
A: Help → Report Bug or email support@aicodingsuite.app

---

## Contributing

Want to contribute to AI Coding Suite?

**Ways to Contribute**:
1. **Report Bugs**: Help → Report Bug
2. **Request Features**: GitHub Issues
3. **Create Plugins**: See Plugin Development Guide
4. **Design Themes**: Share on Theme Marketplace
5. **Write Documentation**: Improve this guide
6. **Translate**: Help localize the app

**GitHub**: https://github.com/aicodingsuite/macos
**Discord**: https://discord.gg/aicodingsuite
**Twitter**: @aicodingsuite

---

## Conclusion

You now understand how AI Coding Suite works from top to bottom!

**Key Takeaways**:

- **Architecture**: SwiftUI + Combine for reactive, native macOS experience
- **AI Integration**: Hybrid LSP + AI for fast, intelligent code assistance
- **Plugin System**: Sandboxed, permission-based extensibility
- **Performance**: Optimized with caching, debouncing, and lazy loading
- **Privacy**: Local-first, opt-in telemetry, secure credential storage

Ready to code? 🚀

---

*Questions? Email support@aicodingsuite.app or visit https://docs.aicodingsuite.app*

*Last Updated: 2024-01-15*
*Version: 1.0*
