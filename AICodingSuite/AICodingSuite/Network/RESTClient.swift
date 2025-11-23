//
//  RESTClient.swift
//  AI Coding Suite
//
//  HTTP/REST API testing client
//

import Foundation
import Combine

class RESTClient: ObservableObject {
    @Published var requests: [HTTPRequest] = []
    @Published var activeRequest: HTTPRequest?
    @Published var response: HTTPResponse?
    @Published var isLoading: Bool = false

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Request Execution

    func sendRequest(_ request: HTTPRequest, completion: @escaping (Result<HTTPResponse, Error>) -> Void) {
        guard let url = URL(string: request.url) else {
            completion(.failure(RESTError.invalidURL))
            return
        }

        isLoading = true
        activeRequest = request

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = TimeInterval(request.timeout)

        // Add headers
        for header in request.headers {
            urlRequest.setValue(header.value, forHTTPHeaderField: header.key)
        }

        // Add body
        if !request.body.isEmpty {
            urlRequest.httpBody = request.body.data(using: .utf8)
        }

        let startTime = Date()

        URLSession.shared.dataTask(with: urlRequest) { [weak self] data, response, error in
            let endTime = Date()
            let duration = endTime.timeIntervalSince(startTime)

            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(RESTError.invalidResponse))
                    return
                }

                let responseData = data ?? Data()
                let responseBody = String(data: responseData, encoding: .utf8) ?? ""

                let result = HTTPResponse(
                    statusCode: httpResponse.statusCode,
                    headers: httpResponse.allHeaderFields as? [String: String] ?? [:],
                    body: responseBody,
                    responseTime: duration,
                    size: responseData.count
                )

                self?.response = result
                completion(.success(result))
            }
        }.resume()
    }

    // MARK: - Request Management

    func saveRequest(_ request: HTTPRequest) {
        if let index = requests.firstIndex(where: { $0.id == request.id }) {
            requests[index] = request
        } else {
            requests.append(request)
        }
        saveRequests()
    }

    func deleteRequest(_ id: UUID) {
        requests.removeAll { $0.id == id }
        saveRequests()
    }

    private func saveRequests() {
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
}

// MARK: - Models

struct HTTPRequest: Identifiable, Codable {
    let id: UUID
    var name: String
    var method: HTTPMethod
    var url: String
    var headers: [HTTPHeader]
    var body: String
    var timeout: Int

    init(
        id: UUID = UUID(),
        name: String = "New Request",
        method: HTTPMethod = .get,
        url: String = "",
        headers: [HTTPHeader] = [],
        body: String = "",
        timeout: Int = 30
    ) {
        self.id = id
        self.name = name
        self.method = method
        self.url = url
        self.headers = headers
        self.body = body
        self.timeout = timeout
    }
}

enum HTTPMethod: String, Codable, CaseIterable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"

    var color: Color {
        switch self {
        case .get: return .blue
        case .post: return .green
        case .put: return .orange
        case .patch: return .purple
        case .delete: return .red
        case .head, .options: return .gray
        }
    }
}

struct HTTPHeader: Identifiable, Codable {
    let id: UUID
    var key: String
    var value: String

    init(id: UUID = UUID(), key: String = "", value: String = "") {
        self.id = id
        self.key = key
        self.value = value
    }
}

struct HTTPResponse {
    let statusCode: Int
    let headers: [String: String]
    let body: String
    let responseTime: TimeInterval
    let size: Int

    var statusText: String {
        switch statusCode {
        case 200: return "OK"
        case 201: return "Created"
        case 204: return "No Content"
        case 400: return "Bad Request"
        case 401: return "Unauthorized"
        case 403: return "Forbidden"
        case 404: return "Not Found"
        case 500: return "Internal Server Error"
        default: return "Unknown"
        }
    }

    var statusColor: Color {
        switch statusCode {
        case 200..<300: return .green
        case 300..<400: return .blue
        case 400..<500: return .orange
        case 500...: return .red
        default: return .gray
        }
    }

    var formattedBody: String {
        if let jsonData = body.data(using: .utf8),
           let jsonObject = try? JSONSerialization.jsonObject(with: jsonData),
           let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys]),
           let prettyString = String(data: prettyData, encoding: .utf8) {
            return prettyString
        }
        return body
    }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}

enum RESTError: Error {
    case invalidURL
    case invalidResponse
    case requestFailed(String)

    var localizedDescription: String {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response"
        case .requestFailed(let message): return message
        }
    }
}

import SwiftUI
