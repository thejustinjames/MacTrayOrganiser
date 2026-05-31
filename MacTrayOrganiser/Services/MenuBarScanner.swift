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

class MenuBarScanner: ObservableObject {
    static let shared = MenuBarScanner()

    @Published var menuBarItems: [MenuBarItem] = []
    @Published var isScanning: Bool = false
    @Published var lastScanTime: Date?
    @Published var scanError: String?

    private let accessibilityService = AccessibilityService.shared
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Listen for permission changes
        NotificationCenter.default.publisher(for: .accessibilityPermissionGranted)
            .sink { [weak self] _ in
                self?.startAutoRefresh()
                self?.scan()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .accessibilityPermissionRevoked)
            .sink { [weak self] _ in
                self?.stopAutoRefresh()
                self?.menuBarItems = []
            }
            .store(in: &cancellables)

        // Start auto-refresh if we already have permission
        if PermissionManager.shared.hasAccessibilityPermission {
            startAutoRefresh()
        }
    }

    // MARK: - Scanning

    /// Perform a full scan of all menu bar items
    func scan() {
        guard PermissionManager.shared.hasAccessibilityPermission else {
            scanError = "Accessibility permission required"
            return
        }

        isScanning = true
        scanError = nil

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var items: [MenuBarItem] = []

            // Get SystemUIServer items (most third-party menu bar apps)
            items.append(contentsOf: self.scanSystemUIServer())

            // Get Control Center items
            items.append(contentsOf: self.scanControlCenter())

            // Get items from other running apps with menu bar extras
            items.append(contentsOf: self.scanRunningApps())

            // Sort by position (left to right)
            items.sort { $0.position.x < $1.position.x }

            // Apply user's custom ordering
            items = self.applyUserOrdering(items)

            DispatchQueue.main.async {
                self.menuBarItems = items
                self.isScanning = false
                self.lastScanTime = Date()
            }
        }
    }

    /// Scan SystemUIServer for menu bar extras
    private func scanSystemUIServer() -> [MenuBarItem] {
        let extras = accessibilityService.getMenuBarExtras()
        return extras.compactMap { createMenuBarItem(from: $0, ownerName: "SystemUIServer") }
    }

    /// Scan Control Center items
    private func scanControlCenter() -> [MenuBarItem] {
        let items = accessibilityService.getControlCenterItems()
        return items.compactMap { createMenuBarItem(from: $0, ownerName: "Control Center") }
    }

    /// Scan all running apps for menu bar items
    private func scanRunningApps() -> [MenuBarItem] {
        var items: [MenuBarItem] = []

        // List of bundle identifiers to skip (already scanned or system)
        let skipBundles = [
            "com.apple.systemuiserver",
            "com.apple.controlcenter",
            "com.apple.finder" // Finder's menu bar is the app menu, not extras
        ]

        for app in NSWorkspace.shared.runningApplications {
            // Skip apps without bundle identifiers or in skip list
            guard let bundleId = app.bundleIdentifier,
                  !skipBundles.contains(bundleId) else {
                continue
            }

            // Only check apps that might have menu bar items
            // (accessory apps are typically menu bar apps)
            if app.activationPolicy == .accessory || app.activationPolicy == .regular {
                let appItems = scanApp(pid: app.processIdentifier, name: app.localizedName ?? bundleId)
                items.append(contentsOf: appItems)
            }
        }

        return items
    }

    /// Scan a specific app for its menu bar extras
    private func scanApp(pid: pid_t, name: String) -> [MenuBarItem] {
        let appElement = accessibilityService.getApplicationElement(pid: pid)

        // Try to get extras menu bar
        guard let extrasMenuBar: AXUIElement = accessibilityService.getAttribute(
            appElement,
            attribute: kAXExtrasMenuBarAttribute as String
        ) else {
            return []
        }

        guard let children = accessibilityService.getChildren(extrasMenuBar) else {
            return []
        }

        return children.compactMap { createMenuBarItem(from: $0, ownerName: name, pid: pid) }
    }

    /// Create a MenuBarItem from an AXUIElement
    private func createMenuBarItem(from element: AXUIElement, ownerName: String, pid: pid_t? = nil) -> MenuBarItem? {
        // Get position and size
        guard let position = accessibilityService.getPosition(element),
              let size = accessibilityService.getSize(element) else {
            return nil
        }

        // Skip items at position 0,0 or with zero size (likely hidden or invalid)
        guard position.x > 0, size.width > 0, size.height > 0 else {
            return nil
        }

        // Get title/description
        let title = accessibilityService.getTitle(element)
            ?? accessibilityService.getDescription(element)
            ?? "unknown"

        // Get PID
        let itemPid: pid_t
        if let providedPid = pid {
            itemPid = providedPid
        } else if let elementPid = accessibilityService.getPID(element) {
            itemPid = elementPid
        } else {
            itemPid = 0
        }

        let settings = AppSettings.shared
        let itemKey = "\(ownerName)_\(title)"

        return MenuBarItem(
            title: title,
            ownerName: ownerName,
            ownerPID: itemPid,
            position: position,
            size: size,
            axElement: element,
            icon: nil, // Will be captured separately if needed
            isHidden: settings.isHidden(itemKey),
            isPinned: settings.isPinned(itemKey),
            sortOrder: settings.getOrder(itemKey)
        )
    }

    /// Apply user's custom ordering to items
    private func applyUserOrdering(_ items: [MenuBarItem]) -> [MenuBarItem] {
        return items.sorted { item1, item2 in
            // Pinned items first
            if item1.isPinned && !item2.isPinned {
                return true
            }
            if !item1.isPinned && item2.isPinned {
                return false
            }

            // Then by custom sort order
            if item1.sortOrder != item2.sortOrder {
                return item1.sortOrder < item2.sortOrder
            }

            // Finally by position
            return item1.position.x < item2.position.x
        }
    }

    // MARK: - Auto Refresh

    func startAutoRefresh(interval: TimeInterval? = nil) {
        let refreshInterval = interval ?? AppSettings.shared.refreshInterval
        stopAutoRefresh()

        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { [weak self] _ in
            self?.scan()
        }

        // Perform initial scan
        scan()
    }

    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }

    // MARK: - Item Actions

    /// Click a menu bar item
    func clickItem(_ item: MenuBarItem) {
        DispatchQueue.global(qos: .userInteractive).async {
            item.performClick()
        }
    }

    /// Get visible (non-hidden) items
    var visibleItems: [MenuBarItem] {
        menuBarItems.filter { !$0.isHidden }
    }

    /// Get hidden items
    var hiddenItems: [MenuBarItem] {
        menuBarItems.filter { $0.isHidden }
    }

    /// Get pinned items
    var pinnedItems: [MenuBarItem] {
        menuBarItems.filter { $0.isPinned }
    }
}
