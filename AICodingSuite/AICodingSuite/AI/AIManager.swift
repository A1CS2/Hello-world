//
//  AIManager.swift
//  AI Coding Suite
//
//  AI integration manager and provider abstraction
//

import Foundation
import Combine

class AIManager: ObservableObject {
    @Published var isProcessing: Bool = false
    @Published var currentProvider: AIProvider?

    private var providers: [String: AIProvider] = [:]
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupProviders()
        selectDefaultProvider()
    }

    private func setupProviders() {
        // Initialize AI providers
        providers["openai"] = OpenAIProvider()
        providers["anthropic"] = AnthropicProvider()
        providers["local"] = LocalLLMProvider()
    }

    private func selectDefaultProvider() {
        let savedProvider = UserDefaults.standard.string(forKey: "aiProvider") ?? "openai"
        currentProvider = providers[savedProvider]
    }

    func switchProvider(_ providerName: String) {
        if let provider = providers[providerName] {
            currentProvider = provider
            UserDefaults.standard.set(providerName, forKey: "aiProvider")
        }
    }

    // MARK: - AI Features

    func completeCode(
        context: CodeContext,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let provider = currentProvider else {
            completion(.failure(AIError.noProviderSelected))
            return
        }

        isProcessing = true

        provider.completeCode(context: context) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                completion(result)
            }
        }
    }

    func explainCode(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let provider = currentProvider else {
            completion(.failure(AIError.noProviderSelected))
            return
        }

        isProcessing = true

        provider.explainCode(code: code) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                completion(result)
            }
        }
    }

    func refactorCode(
        code: String,
        instruction: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let provider = currentProvider else {
            completion(.failure(AIError.noProviderSelected))
            return
        }

        isProcessing = true

        provider.refactorCode(code: code, instruction: instruction) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                completion(result)
            }
        }
    }

    func fixErrors(
        code: String,
        errors: [String],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let provider = currentProvider else {
            completion(.failure(AIError.noProviderSelected))
            return
        }

        isProcessing = true

        provider.fixErrors(code: code, errors: errors) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                completion(result)
            }
        }
    }

    func suggestCommand(
        description: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let provider = currentProvider else {
            completion(.failure(AIError.noProviderSelected))
            return
        }

        provider.suggestCommand(description: description, completion: completion)
    }

    func chat(
        message: String,
        history: [ChatMessage],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let provider = currentProvider else {
            completion(.failure(AIError.noProviderSelected))
            return
        }

        isProcessing = true

        provider.chat(message: message, history: history) { [weak self] result in
            DispatchQueue.main.async {
                self?.isProcessing = false
                completion(result)
            }
        }
    }
}

// MARK: - AI Provider Protocol
protocol AIProvider {
    func completeCode(
        context: CodeContext,
        completion: @escaping (Result<String, Error>) -> Void
    )

    func explainCode(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    )

    func refactorCode(
        code: String,
        instruction: String,
        completion: @escaping (Result<String, Error>) -> Void
    )

    func fixErrors(
        code: String,
        errors: [String],
        completion: @escaping (Result<String, Error>) -> Void
    )

    func suggestCommand(
        description: String,
        completion: @escaping (Result<String, Error>) -> Void
    )

    func chat(
        message: String,
        history: [ChatMessage],
        completion: @escaping (Result<String, Error>) -> Void
    )
}

// MARK: - Code Context
struct CodeContext {
    let currentFile: String
    let language: String
    let cursorPosition: Int
    let surroundingCode: String
    let projectFiles: [String]?
}

// MARK: - AI Error
enum AIError: Error {
    case noProviderSelected
    case apiKeyMissing
    case networkError
    case invalidResponse
    case rateLimitExceeded

    var localizedDescription: String {
        switch self {
        case .noProviderSelected: return "No AI provider selected"
        case .apiKeyMissing: return "API key is missing"
        case .networkError: return "Network error occurred"
        case .invalidResponse: return "Invalid response from AI"
        case .rateLimitExceeded: return "Rate limit exceeded"
        }
    }
}
