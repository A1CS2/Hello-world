//
//  LocalLLMProvider.swift
//  AI Coding Suite
//
//  Local LLM integration (future: llama.cpp, MLX)
//

import Foundation

class LocalLLMProvider: AIProvider {
    init() {
        // Future: Initialize local model
    }

    func completeCode(
        context: CodeContext,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        completion(.success("// Local model code completion"))
    }

    func explainCode(
        code: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        completion(.success("Local model explanation"))
    }

    func refactorCode(
        code: String,
        instruction: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        completion(.success("// Refactored by local model"))
    }

    func fixErrors(
        code: String,
        errors: [String],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        completion(.success("// Fixed by local model"))
    }

    func suggestCommand(
        description: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        completion(.success("echo 'command suggestion'"))
    }

    func chat(
        message: String,
        history: [ChatMessage],
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        completion(.success("Response from local model"))
    }
}
