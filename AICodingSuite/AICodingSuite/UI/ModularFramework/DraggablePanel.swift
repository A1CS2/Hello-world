//
//  DraggablePanel.swift
//  AI Coding Suite
//
//  Draggable and resizable panel component for modular UI
//

import SwiftUI

struct DraggablePanel<Content: View>: View {
    let title: String
    let id: UUID
    @Binding var frame: PanelFrame
    let content: Content
    @State private var isDragging = false
    @State private var isResizing = false
    @EnvironmentObject var themeManager: ThemeManager

    init(
        title: String,
        id: UUID = UUID(),
        frame: Binding<PanelFrame>,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.id = id
        self._frame = frame
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Panel header
            PanelHeader(
                title: title,
                isDragging: $isDragging,
                frame: $frame
            )

            // Panel content
            content
                .frame(
                    width: frame.size.width,
                    height: frame.size.height
                )
        }
        .background(panelBackground)
        .cornerRadius(12)
        .shadow(
            color: themeManager.currentTheme.neonAccent.opacity(0.2),
            radius: isDragging ? 20 : 8
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    themeManager.currentTheme.neonAccent.opacity(isDragging ? 0.8 : 0.3),
                    lineWidth: isDragging ? 2 : 1
                )
        )
        .position(x: frame.position.x, y: frame.position.y)
        .overlay(alignment: .bottomTrailing) {
            ResizeHandle(isResizing: $isResizing, frame: $frame)
        }
    }

    private var panelBackground: some View {
        Group {
            if themeManager.currentTheme.enableGlassmorphism {
                themeManager.currentTheme.surface
                    .opacity(themeManager.currentTheme.glassOpacity)
                    .background(.ultraThinMaterial)
            } else {
                themeManager.currentTheme.surface
            }
        }
    }
}

// MARK: - Panel Header
struct PanelHeader: View {
    let title: String
    @Binding var isDragging: Bool
    @Binding var frame: PanelFrame
    @EnvironmentObject var themeManager: ThemeManager
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        HStack {
            Image(systemName: "chevron.right.circle.fill")
                .font(.caption)
                .foregroundColor(themeManager.currentTheme.neonAccent)

            Text(title)
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.textPrimary)

            Spacer()

            // Panel actions
            HStack(spacing: 8) {
                Button(action: {}) {
                    Image(systemName: "minus.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)

                Button(action: {}) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.caption)
                }
                .buttonStyle(.plain)
            }
            .foregroundColor(themeManager.currentTheme.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(themeManager.currentTheme.surface.opacity(0.5))
        .gesture(
            DragGesture()
                .onChanged { value in
                    isDragging = true
                    frame.position.x += value.translation.width - dragOffset.width
                    frame.position.y += value.translation.height - dragOffset.height
                    dragOffset = value.translation
                }
                .onEnded { _ in
                    isDragging = false
                    dragOffset = .zero
                }
        )
    }
}

// MARK: - Resize Handle
struct ResizeHandle: View {
    @Binding var isResizing: Bool
    @Binding var frame: PanelFrame
    @EnvironmentObject var themeManager: ThemeManager
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        Image(systemName: "arrow.up.left.and.arrow.down.right")
            .font(.caption2)
            .foregroundColor(themeManager.currentTheme.textSecondary)
            .padding(8)
            .background(themeManager.currentTheme.surface.opacity(0.8))
            .cornerRadius(6)
            .offset(x: -8, y: -8)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isResizing = true
                        let newWidth = frame.size.width + (value.translation.width - dragOffset.width)
                        let newHeight = frame.size.height + (value.translation.height - dragOffset.height)

                        frame.size.width = max(200, newWidth)
                        frame.size.height = max(150, newHeight)
                        dragOffset = value.translation
                    }
                    .onEnded { _ in
                        isResizing = false
                        dragOffset = .zero
                    }
            )
    }
}

// MARK: - Panel Frame Model
struct PanelFrame: Codable, Equatable {
    var position: CGPoint
    var size: CGSize

    static let defaultFrame = PanelFrame(
        position: CGPoint(x: 200, y: 200),
        size: CGSize(width: 400, height: 300)
    )
}

extension CGPoint: Codable {
    enum CodingKeys: String, CodingKey {
        case x, y
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let x = try container.decode(CGFloat.self, forKey: .x)
        let y = try container.decode(CGFloat.self, forKey: .y)
        self.init(x: x, y: y)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
    }
}

extension CGSize: Codable {
    enum CodingKeys: String, CodingKey {
        case width, height
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let width = try container.decode(CGFloat.self, forKey: .width)
        let height = try container.decode(CGFloat.self, forKey: .height)
        self.init(width: width, height: height)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
}
