//
//  AIChatView.swift
//  AICodingSuite2
//
//  Created by Claude
//

import SwiftUI

struct AIChatView: View {
    @ObservedObject var aiManager = AIManager.shared
    @ObservedObject var themeManager: ThemeManager
    @State private var inputMessage: String = ""
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(themeManager.currentTheme.neonPrimary)

                Text("AI ASSISTANT")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.currentTheme.secondaryText)

                Spacer()

                // Provider indicator
                Text(AppSettings.shared.aiProvider.rawValue)
                    .font(.caption2)
                    .foregroundColor(themeManager.currentTheme.secondaryText.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(themeManager.currentTheme.neonPrimary.opacity(0.1))
                    .cornerRadius(4)

                Button(action: { aiManager.clearChat() }) {
                    Image(systemName: "trash")
                        .foregroundColor(themeManager.currentTheme.neonSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(themeManager.currentTheme.elevated)

            Divider()
                .overlay(themeManager.currentTheme.borderColor)

            // Chat messages
            ScrollViewReader { proxy in
                ScrollView {
                    if aiManager.messages.isEmpty {
                        EmptyAIChatView(themeManager: themeManager)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            ForEach(aiManager.messages) { message in
                                ChatMessageView(message: message, theme: themeManager.currentTheme)
                                    .id(message.id)
                            }

                            if aiManager.isProcessing {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .tint(themeManager.currentTheme.neonPrimary)

                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundColor(themeManager.currentTheme.secondaryText)
                                }
                                .padding(.horizontal, 12)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                }
                .background(themeManager.currentTheme.background)
                .onChange(of: aiManager.messages.count) { _ in
                    if let lastMessage = aiManager.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider()
                .overlay(themeManager.currentTheme.borderColor)

            // Input field
            HStack(spacing: 8) {
                TextField("Ask AI anything...", text: $inputMessage, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(themeManager.currentTheme.primaryText)
                    .lineLimit(1...5)
                    .padding(8)
                    .background(themeManager.currentTheme.elevated)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(themeManager.currentTheme.borderColor, lineWidth: 1)
                    )
                    .onSubmit {
                        sendMessage()
                    }

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(inputMessage.isEmpty ? themeManager.currentTheme.secondaryText : themeManager.currentTheme.neonPrimary)
                }
                .buttonStyle(.plain)
                .disabled(inputMessage.isEmpty || aiManager.isProcessing)
            }
            .padding(12)
            .background(themeManager.currentTheme.surface)
        }
        .frame(minWidth: 280)
    }

    private func sendMessage() {
        guard !inputMessage.isEmpty else { return }

        let message = inputMessage
        inputMessage = ""

        Task {
            await aiManager.sendMessage(message)
        }
    }
}

struct ChatMessageView: View {
    let message: ChatMessage
    let theme: Theme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: message.role == .user ? "person.circle.fill" : "brain.head.profile")
                    .font(.system(size: 14))
                    .foregroundColor(message.role == .user ? theme.neonSecondary : theme.neonPrimary)

                Text(message.role.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.secondaryText)

                Spacer()

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(theme.secondaryText.opacity(0.6))
            }

            // Content
            Text(message.content)
                .font(.system(size: 13))
                .foregroundColor(theme.primaryText)
                .textSelection(.enabled)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    message.role == .user
                        ? theme.neonPrimary.opacity(0.1)
                        : theme.surface
                )
                .cornerRadius(8)
        }
        .padding(.horizontal, 12)
    }
}

struct EmptyAIChatView: View {
    @ObservedObject var themeManager: ThemeManager

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundColor(themeManager.currentTheme.neonPrimary.opacity(0.5))

            VStack(spacing: 8) {
                Text("AI Assistant Ready")
                    .font(.headline)
                    .foregroundColor(themeManager.currentTheme.primaryText)

                Text("Ask me anything about your code")
                    .font(.caption)
                    .foregroundColor(themeManager.currentTheme.secondaryText)
            }

            VStack(alignment: .leading, spacing: 8) {
                SuggestionChip(text: "Explain this code", icon: "doc.text")
                SuggestionChip(text: "Find bugs", icon: "ladybug")
                SuggestionChip(text: "Optimize performance", icon: "speedometer")
                SuggestionChip(text: "Write tests", icon: "checkmark.circle")
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }
}

struct SuggestionChip: View {
    let text: String
    let icon: String
    @ObservedObject var themeManager = ThemeManager()

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))

            Text(text)
                .font(.caption)
        }
        .foregroundColor(themeManager.currentTheme.secondaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(themeManager.currentTheme.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(themeManager.currentTheme.borderColor.opacity(0.3), lineWidth: 1)
        )
    }
}
