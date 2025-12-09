//
//  AIManager.swift
//  AICodingSuite2
//
//  Created by Claude
//

import Foundation
import Combine

protocol AIProvider {
    func sendMessage(_ message: String) async throws -> String
    func streamMessage(_ message: String) -> AsyncThrowingStream<String, Error>
    func getCodeCompletion(code: String, language: String) async throws -> String
}

class AIManager: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isProcessing: Bool = false

    private var currentProvider: AIProvider?
    private let settings = AppSettings.shared

    static let shared = AIManager()

    private init() {
        updateProvider()
    }

    func updateProvider() {
        switch settings.aiProvider {
        case .openAI:
            currentProvider = OpenAIProvider(apiKey: settings.openAIKey, model: settings.openAIModel)
        case .anthropic:
            currentProvider = AnthropicProvider(apiKey: settings.anthropicKey)
        case .local:
            currentProvider = LocalLLMProvider(endpoint: settings.localModelEndpoint)
        }
    }

    func sendMessage(_ content: String) async {
        guard let provider = currentProvider else { return }

        let userMessage = ChatMessage(role: .user, content: content)
        await MainActor.run {
            messages.append(userMessage)
            isProcessing = true
        }

        do {
            let response = try await provider.sendMessage(content)
            let assistantMessage = ChatMessage(role: .assistant, content: response)

            await MainActor.run {
                messages.append(assistantMessage)
                isProcessing = false
            }
        } catch {
            let errorMessage = ChatMessage(role: .assistant, content: "Error: \(error.localizedDescription)")
            await MainActor.run {
                messages.append(errorMessage)
                isProcessing = false
            }
        }
    }

    func getCodeCompletion(code: String, language: String) async -> String {
        guard let provider = currentProvider else { return "" }

        do {
            return try await provider.getCodeCompletion(code: code, language: language)
        } catch {
            return ""
        }
    }

    func clearChat() {
        messages.removeAll()
    }
}

struct ChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: Role
    let content: String
    let timestamp: Date = Date()

    enum Role {
        case user
        case assistant
        case system

        var displayName: String {
            switch self {
            case .user: return "You"
            case .assistant: return "AI"
            case .system: return "System"
            }
        }
    }
}
