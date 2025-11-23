//
//  DebuggerClient.swift
//  AI Coding Suite
//
//  Integrated debugger with breakpoints, stepping, and variable inspection
//

import Foundation
import Combine

class DebuggerClient: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var isPaused: Bool = false
    @Published var currentLine: Int?
    @Published var breakpoints: Set<Breakpoint> = []
    @Published var variables: [Variable] = []
    @Published var callStack: [StackFrame] = []
    @Published var output: [DebugOutput] = []

    private var process: Process?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Debug Control

    func startDebugging(executable: String, arguments: [String] = []) {
        guard !isRunning else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                self?.handleOutput(output)
            }
        }

        do {
            try process.run()
            self.process = process
            isRunning = true

            addOutput("Debugger started", type: .system)
        } catch {
            addOutput("Failed to start debugger: \(error)", type: .error)
        }
    }

    func stopDebugging() {
        process?.terminate()
        process = nil
        isRunning = false
        isPaused = false
        currentLine = nil
        variables = []
        callStack = []

        addOutput("Debugger stopped", type: .system)
    }

    func pause() {
        guard isRunning && !isPaused else { return }
        process?.suspend()
        isPaused = true
        addOutput("Paused", type: .system)
        updateDebugInfo()
    }

    func resume() {
        guard isPaused else { return }
        process?.resume()
        isPaused = false
        currentLine = nil
        addOutput("Resumed", type: .system)
    }

    func stepOver() {
        guard isPaused else { return }
        // Execute next line
        addOutput("Step over", type: .system)
        updateDebugInfo()
    }

    func stepInto() {
        guard isPaused else { return }
        // Step into function
        addOutput("Step into", type: .system)
        updateDebugInfo()
    }

    func stepOut() {
        guard isPaused else { return }
        // Step out of function
        addOutput("Step out", type: .system)
        updateDebugInfo()
    }

    // MARK: - Breakpoints

    func toggleBreakpoint(file: String, line: Int) {
        let breakpoint = Breakpoint(file: file, line: line)

        if breakpoints.contains(breakpoint) {
            breakpoints.remove(breakpoint)
            addOutput("Removed breakpoint at \(file):\(line)", type: .system)
        } else {
            breakpoints.insert(breakpoint)
            addOutput("Added breakpoint at \(file):\(line)", type: .system)
        }
    }

    func clearAllBreakpoints() {
        breakpoints.removeAll()
        addOutput("Cleared all breakpoints", type: .system)
    }

    func hasBreakpoint(file: String, line: Int) -> Bool {
        breakpoints.contains(Breakpoint(file: file, line: line))
    }

    // MARK: - Variable Inspection

    func evaluateExpression(_ expression: String, completion: @escaping (String?) -> Void) {
        guard isPaused else {
            completion(nil)
            return
        }

        // Simulate expression evaluation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion("Evaluated: \(expression) = <value>")
        }
    }

    // MARK: - Private Methods

    private func updateDebugInfo() {
        // Simulate getting debug info
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.currentLine = Int.random(in: 10...100)
            self?.updateVariables()
            self?.updateCallStack()
        }
    }

    private func updateVariables() {
        // Mock variables
        variables = [
            Variable(name: "count", value: "42", type: "Int"),
            Variable(name: "message", value: "\"Hello, World!\"", type: "String"),
            Variable(name: "isEnabled", value: "true", type: "Bool"),
            Variable(name: "items", value: "[1, 2, 3, 4, 5]", type: "Array<Int>"),
        ]
    }

    private func updateCallStack() {
        // Mock call stack
        callStack = [
            StackFrame(function: "main()", file: "main.swift", line: 45),
            StackFrame(function: "processData()", file: "DataProcessor.swift", line: 78),
            StackFrame(function: "validate()", file: "Validator.swift", line: 23),
        ]
    }

    private func handleOutput(_ output: String) {
        DispatchQueue.main.async {
            self.addOutput(output, type: .stdout)
        }
    }

    private func addOutput(_ message: String, type: DebugOutputType) {
        output.append(DebugOutput(message: message, type: type, timestamp: Date()))
    }
}

// MARK: - Models

struct Breakpoint: Hashable, Identifiable {
    let id = UUID()
    let file: String
    let line: Int

    func hash(into hasher: inout Hasher) {
        hasher.combine(file)
        hasher.combine(line)
    }

    static func == (lhs: Breakpoint, rhs: Breakpoint) -> Bool {
        lhs.file == rhs.file && lhs.line == rhs.line
    }
}

struct Variable: Identifiable {
    let id = UUID()
    let name: String
    let value: String
    let type: String
}

struct StackFrame: Identifiable {
    let id = UUID()
    let function: String
    let file: String
    let line: Int
}

struct DebugOutput: Identifiable {
    let id = UUID()
    let message: String
    let type: DebugOutputType
    let timestamp: Date
}

enum DebugOutputType {
    case stdout
    case stderr
    case system
    case error
}

// MARK: - Debug Panel View
struct DebugPanel: View {
    @ObservedObject var debugger: DebuggerClient
    @State private var selectedTab: DebugTab = .variables
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Header with controls
            HStack(spacing: 12) {
                Image(systemName: "ant.circle.fill")
                    .foregroundColor(debugger.isRunning ? .green : themeManager.currentTheme.textSecondary)

                Text("Debugger")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                Spacer()

                // Debug controls
                HStack(spacing: 8) {
                    DebugButton(
                        icon: debugger.isRunning ? "stop.fill" : "play.fill",
                        action: {
                            if debugger.isRunning {
                                debugger.stopDebugging()
                            } else {
                                debugger.startDebugging(executable: "/usr/bin/swift")
                            }
                        },
                        enabled: true
                    )

                    DebugButton(
                        icon: debugger.isPaused ? "play.fill" : "pause.fill",
                        action: {
                            if debugger.isPaused {
                                debugger.resume()
                            } else {
                                debugger.pause()
                            }
                        },
                        enabled: debugger.isRunning
                    )

                    DebugButton(icon: "arrow.right.to.line", action: debugger.stepOver, enabled: debugger.isPaused)
                    DebugButton(icon: "arrow.down.to.line", action: debugger.stepInto, enabled: debugger.isPaused)
                    DebugButton(icon: "arrow.up.to.line", action: debugger.stepOut, enabled: debugger.isPaused)
                }
            }
            .padding(12)
            .background(themeManager.currentTheme.surface.opacity(0.5))

            Divider()

            // Tab selector
            Picker("Debug Tab", selection: $selectedTab) {
                ForEach(DebugTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(8)

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .variables:
                    VariablesView(variables: debugger.variables)
                case .callStack:
                    CallStackView(frames: debugger.callStack)
                case .breakpoints:
                    BreakpointsView(breakpoints: Array(debugger.breakpoints))
                case .output:
                    DebugOutputView(output: debugger.output)
                }
            }
        }
        .frame(height: 300)
        .background(themeManager.currentTheme.background)
    }

    enum DebugTab: String, CaseIterable {
        case variables = "Variables"
        case callStack = "Call Stack"
        case breakpoints = "Breakpoints"
        case output = "Output"
    }
}

struct DebugButton: View {
    let icon: String
    let action: () -> Void
    let enabled: Bool
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(enabled ? themeManager.currentTheme.neonAccent : themeManager.currentTheme.textSecondary.opacity(0.3))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct VariablesView: View {
    let variables: [Variable]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(variables) { variable in
                    HStack {
                        Text(variable.name)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(themeManager.currentTheme.textPrimary)
                        Text(":")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Text(variable.type)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.blue)
                        Text("=")
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                        Text(variable.value)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(.green)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct CallStackView: View {
    let frames: [StackFrame]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(frames.enumerated()), id: \.element.id) { index, frame in
                    HStack(spacing: 8) {
                        Text("#\(index)")
                            .font(.caption)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .frame(width: 30, alignment: .trailing)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(frame.function)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(themeManager.currentTheme.textPrimary)

                            Text("\(frame.file):\(frame.line)")
                                .font(.caption)
                                .foregroundColor(themeManager.currentTheme.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(index == 0 ? themeManager.currentTheme.neonAccent.opacity(0.1) : Color.clear)
                }
            }
        }
    }
}

struct BreakpointsView: View {
    let breakpoints: [Breakpoint]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(breakpoints) { bp in
                    HStack {
                        Image(systemName: "circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)

                        Text("\(bp.file):\(bp.line)")
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundColor(themeManager.currentTheme.textPrimary)

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }

                if breakpoints.isEmpty {
                    Text("No breakpoints set")
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .padding(12)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

struct DebugOutputView: View {
    let output: [DebugOutput]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                ForEach(output) { item in
                    HStack(alignment: .top, spacing: 8) {
                        Text(item.timestamp, style: .time)
                            .font(.caption2)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                            .frame(width: 60, alignment: .trailing)

                        Text(item.message)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(item.type.color(theme: themeManager.currentTheme))

                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 2)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

extension DebugOutputType {
    func color(theme: AppTheme) -> Color {
        switch self {
        case .stdout: return theme.textPrimary
        case .stderr: return .red
        case .system: return theme.neonAccent
        case .error: return .red
        }
    }
}
