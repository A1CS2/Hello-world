//
//  RealTimeCompletion.swift
//  AI Coding Suite
//
//  Real-time AI code completion engine with caching and debouncing
//

import Foundation
import Combine

class RealTimeCompletionEngine: ObservableObject {
    @Published var currentSuggestion: CodeSuggestion?
    @Published var isProcessing: Bool = false

    private var aiManager: AIManager
    private var lspClient: LSPClient?
    private var cancellables = Set<AnyCancellable>()
    private var debounceTimer: Timer?
    private var cache: CompletionCache = CompletionCache()

    // Configuration
    private let debounceInterval: TimeInterval = 0.3
    private let minCharactersForCompletion: Int = 2
    private let cacheTimeout: TimeInterval = 60

    init(aiManager: AIManager, lspClient: LSPClient? = nil) {
        self.aiManager = aiManager
        self.lspClient = lspClient
    }

    // MARK: - Public Methods

    func requestCompletion(
        context: CompletionContext,
        completion: @escaping (CodeSuggestion?) -> Void
    ) {
        // Cancel any pending requests
        debounceTimer?.invalidate()

        // Check minimum length
        guard context.currentLine.count >= minCharactersForCompletion else {
            completion(nil)
            return
        }

        // Check cache
        if let cached = cache.get(for: context) {
            completion(cached)
            return
        }

        // Debounce
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceInterval, repeats: false) { [weak self] _ in
            self?.performCompletion(context: context, completion: completion)
        }
    }

    func acceptSuggestion(_ suggestion: CodeSuggestion) {
        currentSuggestion = nil
        // Log acceptance for learning
        logAcceptance(suggestion)
    }

    func rejectSuggestion(_ suggestion: CodeSuggestion) {
        currentSuggestion = nil
        // Log rejection for learning
        logRejection(suggestion)
    }

    // MARK: - Private Methods

    private func performCompletion(
        context: CompletionContext,
        completion: @escaping (CodeSuggestion?) -> Void
    ) {
        isProcessing = true

        // Try LSP completion first (faster, local)
        if let lspClient = lspClient {
            requestLSPCompletion(context: context) { [weak self] lspSuggestion in
                if let suggestion = lspSuggestion {
                    self?.cache.set(suggestion, for: context)
                    self?.isProcessing = false
                    completion(suggestion)
                } else {
                    // Fall back to AI completion
                    self?.requestAICompletion(context: context, completion: completion)
                }
            }
        } else {
            // Use AI completion only
            requestAICompletion(context: context, completion: completion)
        }
    }

    private func requestLSPCompletion(
        context: CompletionContext,
        completion: @escaping (CodeSuggestion?) -> Void
    ) {
        lspClient?.completion(
            uri: context.fileUri,
            line: context.cursorLine,
            character: context.cursorCharacter
        ) { items in
            if let firstItem = items.first {
                let suggestion = CodeSuggestion(
                    id: UUID(),
                    text: firstItem.insertText ?? firstItem.label,
                    displayText: firstItem.label,
                    source: .lsp,
                    confidence: 0.9,
                    documentation: firstItem.documentation
                )
                completion(suggestion)
            } else {
                completion(nil)
            }
        }
    }

    private func requestAICompletion(
        context: CompletionContext,
        completion: @escaping (CodeSuggestion?) -> Void
    ) {
        let aiContext = CodeContext(
            currentFile: context.fileName,
            language: context.language,
            cursorPosition: context.cursorPosition,
            surroundingCode: buildSurroundingCode(context),
            projectFiles: context.projectContext
        )

        aiManager.completeCode(context: aiContext) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false

                switch result {
                case .success(let completionText):
                    let suggestion = CodeSuggestion(
                        id: UUID(),
                        text: completionText,
                        displayText: completionText,
                        source: .ai,
                        confidence: 0.85,
                        documentation: nil
                    )
                    self?.cache.set(suggestion, for: context)
                    completion(suggestion)

                case .failure:
                    completion(nil)
                }
            }
        }
    }

    private func buildSurroundingCode(_ context: CompletionContext) -> String {
        let before = context.linesBefore.suffix(10).joined(separator: "\n")
        let after = context.linesAfter.prefix(10).joined(separator: "\n")

        return """
        \(before)
        \(context.currentLine)
        \(after)
        """
    }

    private func logAcceptance(_ suggestion: CodeSuggestion) {
        // In production, log to analytics for model improvement
        print("Accepted suggestion from \(suggestion.source): \(suggestion.displayText)")
    }

    private func logRejection(_ suggestion: CodeSuggestion) {
        // In production, log to analytics for model improvement
        print("Rejected suggestion from \(suggestion.source): \(suggestion.displayText)")
    }
}

// MARK: - Completion Context
struct CompletionContext: Hashable {
    let fileUri: String
    let fileName: String
    let language: String
    let cursorPosition: Int
    let cursorLine: Int
    let cursorCharacter: Int
    let currentLine: String
    let linesBefore: [String]
    let linesAfter: [String]
    let projectContext: [String]?

    func hash(into hasher: inout Hasher) {
        hasher.combine(fileUri)
        hasher.combine(cursorPosition)
        hasher.combine(currentLine)
    }

    static func == (lhs: CompletionContext, rhs: CompletionContext) -> Bool {
        lhs.fileUri == rhs.fileUri &&
        lhs.cursorPosition == rhs.cursorPosition &&
        lhs.currentLine == rhs.currentLine
    }
}

// MARK: - Code Suggestion
struct CodeSuggestion: Identifiable {
    let id: UUID
    let text: String
    let displayText: String
    let source: SuggestionSource
    let confidence: Double
    let documentation: String?
    let timestamp: Date = Date()

    enum SuggestionSource {
        case lsp
        case ai
        case hybrid
    }
}

// MARK: - Completion Cache
class CompletionCache {
    private var storage: [CompletionContext: CachedSuggestion] = [:]
    private let maxSize: Int = 100
    private let timeout: TimeInterval = 60

    func get(for context: CompletionContext) -> CodeSuggestion? {
        guard let cached = storage[context] else { return nil }

        // Check if expired
        if Date().timeIntervalSince(cached.timestamp) > timeout {
            storage.removeValue(forKey: context)
            return nil
        }

        return cached.suggestion
    }

    func set(_ suggestion: CodeSuggestion, for context: CompletionContext) {
        // Evict oldest if at capacity
        if storage.count >= maxSize {
            if let oldest = storage.min(by: { $0.value.timestamp < $1.value.timestamp }) {
                storage.removeValue(forKey: oldest.key)
            }
        }

        storage[context] = CachedSuggestion(
            suggestion: suggestion,
            timestamp: Date()
        )
    }

    func clear() {
        storage.removeAll()
    }

    private struct CachedSuggestion {
        let suggestion: CodeSuggestion
        let timestamp: Date
    }
}

// MARK: - Inline Completion View
struct InlineCompletionView: View {
    let suggestion: CodeSuggestion
    let onAccept: () -> Void
    let onReject: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: suggestion.source == .ai ? "sparkles" : "lightbulb")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.neonAccent)

                    Text(suggestion.source == .ai ? "AI Suggestion" : "Code Completion")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondary)

                    Text("\(Int(suggestion.confidence * 100))%")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.neonAccent)
                }

                Text(suggestion.displayText)
                    .font(.system(size: 14, design: .monospaced))
                    .foregroundColor(themeManager.currentTheme.neonAccent.opacity(0.8))
                    .lineLimit(3)

                if let documentation = suggestion.documentation {
                    Text(documentation)
                        .font(.caption)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .lineLimit(2)
                }

                HStack(spacing: 16) {
                    Button(action: onAccept) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Accept")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(themeManager.currentTheme.neonAccent)

                    Button(action: onReject) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text("Dismiss")
                        }
                        .font(.caption)
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Text("Tab to accept • Esc to dismiss")
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.7))
                }
                .padding(.top, 4)
            }
        }
        .padding(12)
        .background(
            themeManager.currentTheme.surface
                .opacity(0.95)
                .background(.ultraThinMaterial)
        )
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(themeManager.currentTheme.neonAccent.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: themeManager.currentTheme.neonAccent.opacity(0.3), radius: 15)
    }
}
