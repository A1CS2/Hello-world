//
//  LocalLLMProvider.swift
//  AICodingSuite2
//
//  Created by Claude
//

import Foundation

class LocalLLMProvider: AIProvider {
    private let endpoint: String

    init(endpoint: String) {
        self.endpoint = endpoint
    }

    func sendMessage(_ message: String) async throws -> String {
        return "⚠️ Local LLM support coming soon. Please use OpenAI or Anthropic for now."
    }

    func streamMessage(_ message: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            continuation.yield("⚠️ Local LLM support coming soon.")
            continuation.finish()
        }
    }

    func getCodeCompletion(code: String, language: String) async throws -> String {
        return ""
    }
}
