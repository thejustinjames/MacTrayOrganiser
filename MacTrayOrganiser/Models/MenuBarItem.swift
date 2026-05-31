//
//  MenuBarItem.swift
//  MacTrayOrganiser
//
//  Model representing a menu bar item
//

import Foundation
import AppKit
import ApplicationServices

struct MenuBarItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let ownerName: String
    let ownerPID: pid_t
    let position: CGPoint
    let size: CGSize
    let axElement: AXUIElement
    var icon: NSImage?
    var isHidden: Bool
    var isPinned: Bool
    var sortOrder: Int

    init(
        title: String,
        ownerName: String,
        ownerPID: pid_t,
        position: CGPoint,
        size: CGSize,
        axElement: AXUIElement,
        icon: NSImage? = nil,
        isHidden: Bool = false,
        isPinned: Bool = false,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.title = title
        self.ownerName = ownerName
        self.ownerPID = ownerPID
        self.position = position
        self.size = size
        self.axElement = axElement
        self.icon = icon
        self.isHidden = isHidden
        self.isPinned = isPinned
        self.sortOrder = sortOrder
    }

    // For display purposes
    var displayName: String {
        if !title.isEmpty && title != "unknown" {
            return title
        }
        return ownerName
    }

    // Hashable conformance - exclude axElement since it's not Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: MenuBarItem, rhs: MenuBarItem) -> Bool {
        lhs.id == rhs.id
    }

    // Perform a click on this menu bar item
    func performClick() {
        AXUIElementPerformAction(axElement, kAXPressAction as CFString)
    }
}

// Extension for storing hidden/pinned preferences
extension MenuBarItem {
    var preferenceKey: String {
        "\(ownerName)_\(title)"
    }
}
