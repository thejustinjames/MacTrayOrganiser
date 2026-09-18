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
    /// Stable identity derived from the owning app and title, so SwiftUI keeps
    /// the same view identity across rescans. The scanner appends a suffix when
    /// two items would otherwise share an identifier.
    var id: String
    let title: String
    let ownerName: String
    let ownerPID: pid_t
    let position: CGPoint
    let size: CGSize
    let axElement: AXUIElement
    /// True for items hosted by Control Center or SystemUIServer.
    let isSystemItem: Bool
    var icon: NSImage?
    /// True when the item sits in the hidden section of the menu bar
    /// (left of MacTrayOrganiser's separator).
    var isHidden: Bool
    var isPinned: Bool

    init(
        title: String,
        ownerName: String,
        ownerPID: pid_t,
        position: CGPoint,
        size: CGSize,
        axElement: AXUIElement,
        isSystemItem: Bool = false,
        icon: NSImage? = nil,
        isHidden: Bool = false,
        isPinned: Bool = false
    ) {
        self.id = MenuBarItem.preferenceKey(ownerName: ownerName, title: title)
        self.title = title
        self.ownerName = ownerName
        self.ownerPID = ownerPID
        self.position = position
        self.size = size
        self.axElement = axElement
        self.isSystemItem = isSystemItem
        self.icon = icon
        self.isHidden = isHidden
        self.isPinned = isPinned
    }

    /// Frame in the global top-left coordinate space used by the
    /// Accessibility API and Core Graphics events.
    var frame: CGRect {
        CGRect(origin: position, size: size)
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
    @discardableResult
    func performClick() -> Bool {
        AXUIElementPerformAction(axElement, kAXPressAction as CFString) == .success
    }
}

// Extension for storing hidden/pinned preferences
extension MenuBarItem {
    /// Key used to persist per-item preferences. Stable across relaunches
    /// because it does not include the process identifier.
    static func preferenceKey(ownerName: String, title: String) -> String {
        "\(ownerName)_\(title)"
    }

    var preferenceKey: String {
        MenuBarItem.preferenceKey(ownerName: ownerName, title: title)
    }
}
