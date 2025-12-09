//
//  OpenAIProvider.swift
//  AICodingSuite2
//
//  Created by Claude
//

import Foundation

class OpenAIProvider: AIProvider {
    private let apiKey: String
    private let model: String
    private let baseURL = "https://api.openai.com/v1"

    init(apiKey: String, model: String = "gpt-4") {
        self.apiKey = apiKey
        self.model = model
    }

    func sendMessage(_ message: String) async throws -> String {
        guard !apiKey.isEmpty else {
            return "⚠️ Please configure your OpenAI API key in Settings"
        }

        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": message]
            ],
            "temperature": 0.7
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIError.requestFailed
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        if let choices = json?["choices"] as? [[String: Any]],
           let firstChoice = choices.first,
           let message = firstChoice["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content
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

enum AIError: Error {
    case requestFailed
    case invalidResponse
    case apiKeyMissing
}
