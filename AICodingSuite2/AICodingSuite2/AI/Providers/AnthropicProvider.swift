//
//  AnthropicProvider.swift
//  AICodingSuite2
//
//  Created by Claude
//

import Foundation

class AnthropicProvider: AIProvider {
    private let apiKey: String
    private let model: String = "claude-3-5-sonnet-20241022"
    private let baseURL = "https://api.anthropic.com/v1"

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func sendMessage(_ message: String) async throws -> String {
        guard !apiKey.isEmpty else {
            return "⚠️ Please configure your Anthropic API key in Settings"
        }

        let url = URL(string: "\(baseURL)/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let payload: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "messages": [
                ["role": "user", "content": message]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIError.requestFailed
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let content = json?["content"] as? [[String: Any]],
           let firstContent = content.first,
           let text = firstContent["text"] as? String {
            return text
        }

        throw AIError.invalidResponse
    }

    func streamMessage(_ message: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let response = try await sendMessage(message)
                    continuation.yield(response)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func getCodeCompletion(code: String, language: String) async throws -> String {
        let prompt = """
        Complete the following \(language) code. Only return the completion, no explanations:

        \(code)
        """

        return try await sendMessage(prompt)
    }
}
