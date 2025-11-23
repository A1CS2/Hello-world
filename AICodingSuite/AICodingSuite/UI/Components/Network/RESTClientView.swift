//
//  RESTClientView.swift
//  AI Coding Suite
//
//  HTTP/REST API testing interface
//

import SwiftUI

struct RESTClientView: View {
    @StateObject private var restClient = RESTClient()
    @State private var request = HTTPRequest()
    @State private var selectedTab: ResponseTab = .body
    @State private var showHistory = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HSplitView {
            // Sidebar (if history shown)
            if showHistory {
                RequestHistoryView(
                    requests: restClient.requests,
                    onSelect: { request = $0 },
                    onDelete: { restClient.deleteRequest($0) }
                )
                .frame(width: 250)
            }

            // Main content
            VStack(spacing: 0) {
                // Header
                RequestHeader(
                    showHistory: $showHistory,
                    onSend: sendRequest,
                    onSave: saveRequest
                )

                Divider()

                // Request builder
                RequestBuilder(request: $request)

                Divider()

                // Response viewer
                if let response = restClient.response {
                    ResponseViewer(
                        response: response,
                        selectedTab: $selectedTab
                    )
                } else {
                    EmptyResponseView()
                }
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .background(themeManager.currentTheme.background)
        .onAppear {
            restClient.loadRequests()
        }
    }

    private func sendRequest() {
        restClient.sendRequest(request) { result in
            switch result {
            case .success:
                print("Request successful")
            case .failure(let error):
                print("Request failed: \(error)")
            }
        }
    }

    private func saveRequest() {
        restClient.saveRequest(request)
    }
}

// MARK: - Request Header
struct RequestHeader: View {
    @Binding var showHistory: Bool
    let onSend: () -> Void
    let onSave: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack {
            Button(action: { showHistory.toggle() }) {
                Image(systemName: "clock.arrow.circlepath")
            }
            .buttonStyle(.bordered)

            Spacer()

            Button("Send") {
                onSend()
            }
            .buttonStyle(.borderedProminent)
            .tint(themeManager.currentTheme.neonAccent)

            Button("Save") {
                onSave()
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
        .background(themeManager.currentTheme.surface.opacity(0.3))
    }
}

// MARK: - Request Builder
struct RequestBuilder: View {
    @Binding var request: HTTPRequest
    @State private var selectedTab: RequestTab = .headers
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Method and URL
            HStack(spacing: 12) {
                Picker("Method", selection: $request.method) {
                    ForEach(HTTPMethod.allCases, id: \.self) { method in
                        Text(method.rawValue)
                            .foregroundColor(method.color)
                            .tag(method)
                    }
                }
                .frame(width: 120)

                TextField("https://api.example.com/endpoint", text: $request.url)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(12)

            // Tabs
            Picker("Request Tab", selection: $selectedTab) {
                ForEach(RequestTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)

            // Tab content
            Group {
                switch selectedTab {
                case .headers:
                    HeadersEditor(headers: $request.headers)
                case .body:
                    BodyEditor(body: $request.body)
                case .params:
                    ParamsEditor()
                }
            }
            .frame(height: 250)
        }
    }

    enum RequestTab: String, CaseIterable {
        case headers = "Headers"
        case body = "Body"
        case params = "Params"
    }
}

// MARK: - Headers Editor
struct HeadersEditor: View {
    @Binding var headers: [HTTPHeader]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Key")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("Value")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer().frame(width: 40)
            }
            .font(.caption)
            .foregroundColor(themeManager.currentTheme.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(themeManager.currentTheme.surface.opacity(0.3))

            ScrollView {
                VStack(spacing: 8) {
                    ForEach($headers) { $header in
                        HStack(spacing: 8) {
                            TextField("Key", text: $header.key)
                                .textFieldStyle(.roundedBorder)
                            TextField("Value", text: $header.value)
                                .textFieldStyle(.roundedBorder)
                            Button(action: {
                                headers.removeAll { $0.id == header.id }
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                    }

                    Button(action: {
                        headers.append(HTTPHeader())
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Header")
                        }
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(themeManager.currentTheme.neonAccent)
                    .padding()
                }
            }
        }
    }
}

// MARK: - Body Editor
struct BodyEditor: View {
    @Binding var body: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        TextEditor(text: $body)
            .font(.system(size: 13, design: .monospaced))
            .foregroundColor(themeManager.currentTheme.textPrimary)
            .scrollContentBackground(.hidden)
            .background(themeManager.currentTheme.background)
            .padding(12)
    }
}

// MARK: - Params Editor
struct ParamsEditor: View {
    var body: some View {
        Text("URL Parameters")
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Response Viewer
struct ResponseViewer: View {
    let response: HTTPResponse
    @Binding var selectedTab: ResponseTab
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 0) {
            // Status bar
            HStack {
                Text("Status:")
                    .foregroundColor(themeManager.currentTheme.textSecondary)
                Text("\(response.statusCode) \(response.statusText)")
                    .foregroundColor(response.statusColor)
                    .fontWeight(.bold)

                Spacer()

                Text("Time: \(String(format: "%.0f ms", response.responseTime * 1000))")
                    .foregroundColor(themeManager.currentTheme.textSecondary)

                Text("Size: \(response.formattedSize)")
                    .foregroundColor(themeManager.currentTheme.textSecondary)
            }
            .font(.caption)
            .padding(12)
            .background(themeManager.currentTheme.surface.opacity(0.3))

            // Tabs
            Picker("Response Tab", selection: $selectedTab) {
                ForEach(ResponseTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            // Tab content
            Group {
                switch selectedTab {
                case .body:
                    ResponseBodyView(body: response.formattedBody)
                case .headers:
                    ResponseHeadersView(headers: response.headers)
                }
            }
        }
    }

    enum ResponseTab: String, CaseIterable {
        case body = "Body"
        case headers = "Headers"
    }
}

// MARK: - Response Body View
struct ResponseBodyView: View {
    let body: String
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            Text(body)
                .font(.system(size: 13, design: .monospaced))
                .foregroundColor(themeManager.currentTheme.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
        }
        .background(themeManager.currentTheme.background)
    }
}

// MARK: - Response Headers View
struct ResponseHeadersView: View {
    let headers: [String: String]
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(headers.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack(alignment: .top) {
                        Text(key)
                            .fontWeight(.semibold)
                            .frame(width: 200, alignment: .leading)
                        Text(value)
                            .foregroundColor(themeManager.currentTheme.textSecondary)
                    }
                    .font(.caption)
                }
            }
            .padding(12)
        }
    }
}

// MARK: - Request History View
struct RequestHistoryView: View {
    let requests: [HTTPRequest]
    let onSelect: (HTTPRequest) -> Void
    let onDelete: (UUID) -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HISTORY")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.textSecondary)
                .padding(.horizontal, 12)

            ScrollView {
                VStack(spacing: 4) {
                    ForEach(requests) { request in
                        HistoryRow(
                            request: request,
                            onSelect: { onSelect(request) },
                            onDelete: { onDelete(request.id) }
                        )
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .background(themeManager.currentTheme.surface.opacity(0.3))
    }
}

struct HistoryRow: View {
    let request: HTTPRequest
    let onSelect: () -> Void
    let onDelete: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(request.name)
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.textPrimary)

                HStack {
                    Text(request.method.rawValue)
                        .font(.caption2)
                        .foregroundColor(request.method.color)
                    Text(request.url)
                        .font(.caption2)
                        .foregroundColor(themeManager.currentTheme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }
}

// MARK: - Empty Response View
struct EmptyResponseView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "network")
                .font(.system(size: 64))
                .foregroundColor(themeManager.currentTheme.textSecondary.opacity(0.3))

            Text("Send a request to see the response")
                .foregroundColor(themeManager.currentTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
