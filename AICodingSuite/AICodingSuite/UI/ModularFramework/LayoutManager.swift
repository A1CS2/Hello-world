//
//  LayoutManager.swift
//  AI Coding Suite
//
//  Manages panel layouts, saving and loading configurations
//

import SwiftUI

class LayoutManager: ObservableObject {
    @Published var panels: [PanelConfiguration] = []
    @Published var activeLayout: LayoutConfiguration?

    func loadLayout(_ layout: LayoutConfiguration?) {
        guard let layout = layout else {
            loadDefaultLayout()
            return
        }

        activeLayout = layout
        panels = layout.panels
    }

    func loadDefaultLayout() {
        activeLayout = .defaultLayout
        panels = LayoutConfiguration.defaultLayout.panels
    }

    func saveLayout(name: String) {
        let layout = LayoutConfiguration(
            id: UUID(),
            name: name,
            panels: panels,
            createdAt: Date()
        )

        if let data = try? JSONEncoder().encode(layout) {
            UserDefaults.standard.set(data, forKey: "layout_\(layout.id.uuidString)")
        }
    }

    func addPanel(_ panel: PanelConfiguration) {
        panels.append(panel)
    }

    func removePanel(id: UUID) {
        panels.removeAll { $0.id == id }
    }

    func updatePanel(_ panel: PanelConfiguration) {
        if let index = panels.firstIndex(where: { $0.id == panel.id }) {
            panels[index] = panel
        }
    }
}

// MARK: - Layout Configuration
struct LayoutConfiguration: Codable, Identifiable {
    let id: UUID
    var name: String
    var panels: [PanelConfiguration]
    let createdAt: Date

    static let defaultLayout = LayoutConfiguration(
        id: UUID(),
        name: "Default",
        panels: [
            PanelConfiguration(
                id: UUID(),
                type: .codeEditor,
                frame: PanelFrame(
                    position: CGPoint(x: 600, y: 400),
                    size: CGSize(width: 800, height: 600)
                ),
                isVisible: true
            ),
            PanelConfiguration(
                id: UUID(),
                type: .terminal,
                frame: PanelFrame(
                    position: CGPoint(x: 600, y: 700),
                    size: CGSize(width: 800, height: 200)
                ),
                isVisible: true
            )
        ],
        createdAt: Date()
    )
}

// MARK: - Panel Configuration
struct PanelConfiguration: Codable, Identifiable {
    let id: UUID
    var type: PanelType
    var frame: PanelFrame
    var isVisible: Bool
    var settings: [String: String]?

    enum PanelType: String, Codable {
        case codeEditor
        case terminal
        case fileExplorer
        case gitPanel
        case aiChat
        case preview
        case debugger
        case chart
        case custom
    }
}
