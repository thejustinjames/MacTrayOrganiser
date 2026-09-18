//
//  StatusBarController.swift
//  MacTrayOrganiser
//
//  Owns the app's status items and the popover
//

import AppKit
import SwiftUI

/// Owns the two status items and the popover.
///
/// Layout, left to right: hidden items, separator, main icon, visible items.
/// When collapsed the separator is made extremely wide, which pushes
/// everything to its left off the edge of the menu bar. macOS keeps the
/// pushed-off items alive, so the scanner can still list them and a ⌘-drag
/// can bring them back. This is the same technique Hidden Bar uses.
@MainActor
final class StatusBarController: NSObject, NSPopoverDelegate {
    static let shared = StatusBarController()

    static let separatorAutosaveName = "MacTrayOrganiser.separator"
    static let mainAutosaveName = "MacTrayOrganiser.main"
    static let collapsedLength: CGFloat = 10_000
    static let separatorLength: CGFloat = 10

    private let separatorItem: NSStatusItem
    private let mainItem: NSStatusItem
    private let popover = NSPopover()
    private let settings = AppSettings.shared

    private override init() {
        Self.seedPreferredPositions()

        separatorItem = NSStatusBar.system.statusItem(withLength: Self.separatorLength)
        mainItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        separatorItem.autosaveName = Self.separatorAutosaveName
        mainItem.autosaveName = Self.mainAutosaveName

        if let button = separatorItem.button {
            button.image = Self.makeSeparatorImage()
            button.toolTip = "Everything to the left is hidden. Click to tuck it away."
            button.target = self
            button.action = #selector(separatorClicked)
        }

        if let button = mainItem.button {
            button.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: "MacTrayOrganiser")
            button.image?.isTemplate = true
            button.toolTip = "MacTrayOrganiser. Right-click or ⌥-click to show or hide the hidden section."
            button.target = self
            button.action = #selector(mainClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        applyCollapsedState()
    }

    // MARK: - Placement

    /// macOS stores a status item's position as its distance from the right
    /// edge of the screen under "NSStatusItem Preferred Position <name>".
    /// Larger is further left. Seeding a large value on first run puts our
    /// items at the left end of the status items, and the scanner then
    /// ⌘-drags them past anything that macOS placed further left still.
    private static func seedPreferredPositions() {
        let defaults = UserDefaults.standard
        for (name, position) in [(separatorAutosaveName, 100_000), (mainAutosaveName, 90_000)] {
            let key = "NSStatusItem Preferred Position \(name)"
            if defaults.object(forKey: key) == nil {
                defaults.set(position, forKey: key)
            }
        }
    }

    private static func makeSeparatorImage() -> NSImage {
        let image = NSImage(size: NSSize(width: 8, height: 16), flipped: false) { _ in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: NSRect(x: 3.5, y: 1, width: 1, height: 14), xRadius: 0.5, yRadius: 0.5).fill()
            return true
        }
        image.isTemplate = true
        return image
    }

    // MARK: - Frames

    /// Height of the screen that carries the menu bar, used to convert
    /// AppKit's bottom-left window frames to the top-left space shared by
    /// the Accessibility API and Core Graphics events.
    private var primaryScreenHeight: CGFloat {
        NSScreen.screens.first?.frame.height ?? 0
    }

    private func topLeftFrame(_ frame: NSRect) -> CGRect {
        CGRect(x: frame.minX, y: primaryScreenHeight - frame.maxY, width: frame.width, height: frame.height)
    }

    /// Separator frame in top-left coordinates, or nil if it is not on screen.
    var separatorFrame: CGRect? {
        separatorItem.button?.window.map { topLeftFrame($0.frame) }
    }

    /// Main icon frame in top-left coordinates, or nil if it is not on screen.
    var mainFrame: CGRect? {
        mainItem.button?.window.map { topLeftFrame($0.frame) }
    }

    /// Items whose x is left of this value are in the hidden section.
    var hiddenBoundaryX: CGFloat? {
        separatorFrame?.minX
    }

    // MARK: - Collapsing

    var isCollapsed: Bool {
        settings.isCollapsed
    }

    /// Tuck the hidden section away or reveal it. Pass `persist: false` to
    /// reveal it temporarily (for example while moving an item) without
    /// changing the user's choice.
    func setCollapsed(_ collapsed: Bool, persist: Bool = true) {
        if persist {
            settings.isCollapsed = collapsed
        }
        separatorItem.length = collapsed ? Self.collapsedLength : Self.separatorLength
    }

    func toggleCollapsed() {
        setCollapsed(!isCollapsed)
    }

    private func applyCollapsedState() {
        setCollapsed(settings.isCollapsed, persist: false)
    }

    @objc private func separatorClicked() {
        setCollapsed(true)
    }

    // MARK: - Popover

    @objc private func mainClicked() {
        let event = NSApp.currentEvent
        let isSecondary = event?.type == .rightMouseUp || event?.modifierFlags.contains(.option) == true
        if isSecondary {
            toggleCollapsed()
        } else {
            togglePopover()
        }
    }

    var isPopoverShown: Bool {
        popover.isShown
    }

    func togglePopover() {
        if popover.isShown {
            closePopover()
        } else {
            showPopover()
        }
    }

    func showPopover() {
        guard let button = mainItem.button else { return }

        // Built on first use. The view reaches for the scanner, and the
        // scanner reaches for this controller, so neither may be created
        // inside the other's initialiser.
        if popover.contentViewController == nil {
            popover.contentViewController = NSHostingController(
                rootView: MenuBarView()
                    .environmentObject(AppSettings.shared)
                    .environmentObject(PermissionManager.shared)
            )
        }

        MenuBarScanner.shared.scan()
        NSApp.activate(ignoringOtherApps: true)
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    func closePopover() {
        if popover.isShown {
            popover.performClose(nil)
        }
    }

    nonisolated func popoverDidClose(_ notification: Notification) {
        // The popover rescans on open, so nothing is needed here.
    }

    // MARK: - Settings window

    /// Opens the SwiftUI `Settings` scene. The app is activated first because
    /// an accessory (menu bar only) app otherwise opens the window behind
    /// others. `showSettingsWindow:` is the action for the Settings scene on
    /// macOS 13 and later, which is the app's minimum version.
    func openSettings() {
        closePopover()
        NSApp.activate(ignoringOtherApps: true)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
