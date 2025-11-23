//
//  OpenAIProvider.swift
//  AI Coding Suite
//
//  OpenAI API integration
//

import Foundation

class OpenAIProvider: AIProvider {
    private let apiKey: String?
    private let baseURL = "https://api.openai.com/v1"
    private let model: String

    init() {
        // Load API key from UserDefaults or Keychain
        self.apiKey = UserDefaults.standard.string(forKey: "openai_api_key")
        self.model = UserDefaults.standard.string(forKey: "openai_model") ?? "gpt-4"
    }

    func completeCode(
        context: CodeContext,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let prompt = buildCompletionPrompt(context)
        sendRequest(prompt: prompt, completion: completion)
    }

    func explainCode(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let prompt = """
        Explain the following code in detail:

        ```
        \(code)
        ```

        Provide a clear explanation of what this code does, how it works, and any notable patterns or potential issues.
        """

        sendRequest(prompt: prompt, completion: completion)
    }

    func refactorCode(
        code: String,
        instruction: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let prompt = """
        Refactor the following code according to this instruction: \(instruction)

        Original code:
        ```
        \(code)
        ```

        Provide the refactored code with explanations of the changes.
        """

        sendRequest(prompt: prompt, completion: completion)
    }

    func fixErrors(
        code: String,
        errors: [String],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let errorList = errors.joined(separator: "\n- ")
        let prompt = """
        Fix the following errors in this code:

        Errors:
        - \(errorList)

        Code:
        ```
        \(code)
        ```

        Provide the corrected code and explain the fixes.
        """

        sendRequest(prompt: prompt, completion: completion)
    }

    func suggestCommand(
        description: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let prompt = """
        Suggest a terminal command for the following task: \(description)

        Provide only the command without explanation.
        """

        sendRequest(prompt: prompt, completion: completion)
    }

    func chat(
        message: String,
        history: [ChatMessage],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        // Build conversation history
        var messages: [[String: String]] = []

        for msg in history {
            messages.append([
                "role": msg.isUser ? "user" : "assistant",
                "content": msg.content
            ])
        }

        messages.append([
            "role": "user",
            "content": message
        ])

        sendChatRequest(messages: messages, completion: completion)
    }

    // MARK: - Private Methods

    private func buildCompletionPrompt(_ context: CodeContext) -> String {
        """
        Complete the following \(context.language) code:

        ```\(context.language)
        \(context.surroundingCode)
        ```

        Provide only the code completion, without explanations.
        """
    }

    private func sendRequest(
        prompt: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            completion(.failure(AIError.apiKeyMissing))
            return
        }

        // In production, this would make actual API calls
        // For now, simulate response
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            completion(.success("AI response: \(prompt.prefix(50))..."))
        }
    }

    private func sendChatRequest(
        messages: [[String: String]],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            completion(.failure(AIError.apiKeyMissing))
            return
        }

        // Simulate API response
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            completion(.success("I can help you with that! Here's what I suggest..."))
        }
    }
}
