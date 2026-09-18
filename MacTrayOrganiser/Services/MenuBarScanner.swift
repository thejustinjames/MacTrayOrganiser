//
//  MenuBarScanner.swift
//  MacTrayOrganiser
//
//  Scans and tracks all menu bar items
//

import Foundation
import AppKit
import ApplicationServices
import Combine

/// Discovers menu bar items over the Accessibility API and publishes them.
///
/// Discovery runs on a background queue and touches only the Accessibility
/// API. Everything that reads settings or the status bar layout happens on
/// the main actor in `publish()`, which reruns whenever the settings change
/// so the list stays in sync without a full rescan.
///
/// An item counts as hidden when it sits left of MacTrayOrganiser's separator
/// in the real menu bar, which the user arranges by ⌘-dragging icons across
/// the separator. macOS does not let an app move another app's menu bar
/// items, so the app never moves them itself.
@MainActor
final class MenuBarScanner: ObservableObject {
    static let shared = MenuBarScanner()

    @Published private(set) var menuBarItems: [MenuBarItem] = []
    @Published private(set) var isScanning: Bool = false
    @Published private(set) var lastScanTime: Date?
    @Published private(set) var scanError: String?

    private let settings = AppSettings.shared
    private let scanQueue = DispatchQueue(label: "com.mactrayorganiser.scan", qos: .userInitiated)
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    /// Items as discovered, before settings and layout are applied.
    private var discoveredItems: [MenuBarItem] = []

    private init() {
        NotificationCenter.default.publisher(for: .accessibilityPermissionGranted)
            .sink { _ in
                Task { @MainActor in
                    let scanner = MenuBarScanner.shared
                    if StatusBarController.shared.isPopoverShown { scanner.beginLiveRefresh() }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .accessibilityPermissionRevoked)
            .sink { _ in
                Task { @MainActor in
                    let scanner = MenuBarScanner.shared
                    scanner.endLiveRefresh()
                    scanner.discoveredItems = []
                    scanner.menuBarItems = []
                }
            }
            .store(in: &cancellables)

        // Re-apply preferences whenever any setting changes. objectWillChange
        // fires before the mutation; hopping to the main queue delivers it after.
        settings.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { _ in Task { @MainActor in MenuBarScanner.shared.publish() } }
            .store(in: &cancellables)

        settings.$refreshInterval
            .dropFirst()
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { _ in
                Task { @MainActor in
                    let scanner = MenuBarScanner.shared
                    guard PermissionManager.shared.hasAccessibilityPermission,
                          StatusBarController.shared.isPopoverShown else { return }
                    scanner.scheduleTimer()
                }
            }
            .store(in: &cancellables)
    }

    /// Do one scan at launch if permitted, so the first popover is not empty.
    /// Periodic refreshing only runs while the popover is open.
    func start() {
        if PermissionManager.shared.hasAccessibilityPermission {
            scan()
        }
    }

    // MARK: - Scanning

    func scan() {
        guard PermissionManager.shared.hasAccessibilityPermission else {
            scanError = "Accessibility permission required"
            return
        }
        guard !isScanning else { return }

        isScanning = true
        scanError = nil

        let ownBundleID = Bundle.main.bundleIdentifier
        scanQueue.async {
            let items = Self.discoverItems(ownBundleID: ownBundleID)
            Task { @MainActor in
                let scanner = MenuBarScanner.shared
                scanner.discoveredItems = items
                scanner.publish()
                scanner.isScanning = false
                scanner.lastScanTime = Date()
            }
        }
    }

    // MARK: - Discovery (background)

    private nonisolated static func discoverItems(ownBundleID: String?) -> [MenuBarItem] {
        var items: [MenuBarItem] = []

        items.append(contentsOf: AccessibilityService.shared.getMenuBarExtras().compactMap {
            createMenuBarItem(from: $0, ownerName: "SystemUIServer", isSystemItem: true)
        })
        items.append(contentsOf: AccessibilityService.shared.getControlCenterItems().compactMap {
            createMenuBarItem(from: $0, ownerName: "Control Center", isSystemItem: true)
        })
        items.append(contentsOf: scanRunningApps(ownBundleID: ownBundleID))

        items.sort { $0.position.x < $1.position.x }

        // Two items from the same app with the same title would otherwise
        // collide, which breaks SwiftUI's ForEach.
        var seen: [String: Int] = [:]
        for index in items.indices {
            let baseID = items[index].id
            let count = seen[baseID, default: 0]
            seen[baseID] = count + 1
            if count > 0 { items[index].id = "\(baseID)#\(count)" }
        }
        return items
    }

    private nonisolated static func scanRunningApps(ownBundleID: String?) -> [MenuBarItem] {
        var items: [MenuBarItem] = []
        var skipBundles: Set<String> = [
            "com.apple.systemuiserver",
            "com.apple.controlcenter",
            "com.apple.finder"
        ]
        if let ownBundleID { skipBundles.insert(ownBundleID) }

        for app in NSWorkspace.shared.runningApplications {
            guard let bundleId = app.bundleIdentifier, !skipBundles.contains(bundleId) else { continue }
            guard app.activationPolicy == .accessory || app.activationPolicy == .regular else { continue }
            items.append(contentsOf: scanApp(
                pid: app.processIdentifier,
                name: app.localizedName ?? bundleId,
                icon: app.icon
            ))
        }
        return items
    }

    private nonisolated static func scanApp(pid: pid_t, name: String, icon: NSImage?) -> [MenuBarItem] {
        let service = AccessibilityService.shared
        let appElement = service.getApplicationElement(pid: pid)
        guard let extrasMenuBar: AXUIElement = service.getAttribute(
            appElement, attribute: kAXExtrasMenuBarAttribute as String
        ), let children = service.getChildren(extrasMenuBar) else {
            return []
        }
        return children.compactMap {
            createMenuBarItem(from: $0, ownerName: name, pid: pid, icon: icon)
        }
    }

    private nonisolated static func createMenuBarItem(
        from element: AXUIElement,
        ownerName: String,
        pid: pid_t? = nil,
        isSystemItem: Bool = false,
        icon: NSImage? = nil
    ) -> MenuBarItem? {
        let service = AccessibilityService.shared
        guard let position = service.getPosition(element),
              let size = service.getSize(element) else {
            return nil
        }

        // Real status items sit in the menu bar band at the top of the
        // primary display. Zero-sized entries and items parked elsewhere are
        // placeholders macOS keeps for status items that are not shown.
        // Items pushed off the left edge by the collapsed separator keep a
        // negative x and are kept.
        guard size.width > 0, size.height > 0, position.y >= 0, position.y < 60 else {
            return nil
        }

        let title = service.getTitle(element)
            ?? service.getDescription(element)
            ?? "unknown"
        let itemPid = pid ?? service.getPID(element) ?? 0

        return MenuBarItem(
            title: title,
            ownerName: ownerName,
            ownerPID: itemPid,
            position: position,
            size: size,
            axElement: element,
            isSystemItem: isSystemItem,
            icon: icon
        )
    }

    // MARK: - Publishing (main actor)

    /// Filter and flag the discovered items using the current settings and
    /// the separator's position, then publish them in menu bar order with
    /// pinned items first.
    private func publish() {
        var items = discoveredItems

        if !settings.showSystemIcons {
            items.removeAll { $0.isSystemItem }
        }

        let boundary = StatusBarController.shared.hiddenBoundaryX
        for index in items.indices {
            let item = items[index]
            items[index].isHidden = boundary.map { item.position.x < $0 } ?? false
            items[index].isPinned = settings.isPinned(item.preferenceKey)
        }

        let ordered = items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.position.x < rhs.position.x
        }

        // Skip the assignment when nothing the popover renders has changed, so
        // a routine rescan does not churn the grid.
        if ordered.count == menuBarItems.count,
           zip(ordered, menuBarItems).allSatisfy({
               $0.id == $1.id && $0.isHidden == $1.isHidden && $0.isPinned == $1.isPinned
           }) {
            return
        }
        menuBarItems = ordered
    }

    // MARK: - Live Refresh (only while the popover is open)

    /// Scan now and, unless refreshing is set to manual, keep scanning at the
    /// configured interval for as long as the popover stays open.
    func beginLiveRefresh() {
        scan()
        scheduleTimer()
    }

    /// Stop periodic scanning when the popover closes; there is nothing on
    /// screen to keep up to date.
    func endLiveRefresh() {
        stopTimer()
    }

    private func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    private func scheduleTimer() {
        stopTimer()
        let interval = settings.refreshInterval
        guard !settings.isManualRefresh else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in MenuBarScanner.shared.scan() }
        }
        timer.tolerance = interval * 0.2
        refreshTimer = timer
    }

    // MARK: - Item Actions

    /// Click a menu bar item. A hidden item is revealed first, since a menu
    /// cannot open from an item that is off the edge of the screen.
    func clickItem(_ item: MenuBarItem) {
        let bar = StatusBarController.shared
        if item.isHidden && bar.isCollapsed {
            bar.setCollapsed(false)
            DispatchQueue.global(qos: .userInteractive).asyncAfter(deadline: .now() + 0.35) {
                item.performClick()
            }
        } else {
            DispatchQueue.global(qos: .userInteractive).async {
                item.performClick()
            }
        }
    }

    var visibleItems: [MenuBarItem] { menuBarItems.filter { !$0.isHidden } }
    var hiddenItems: [MenuBarItem] { menuBarItems.filter { $0.isHidden } }
    var pinnedItems: [MenuBarItem] { menuBarItems.filter { $0.isPinned } }
}
