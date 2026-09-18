//
//  AppSettings.swift
//  MacTrayOrganiser
//
//  User preferences and app settings
//

import Foundation
import SwiftUI
import ServiceManagement

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    /// Sentinel stored in `refreshInterval` when automatic scanning is off.
    static let manualRefreshInterval: Double = 0

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let showIconLabels = "showIconLabels"
        static let gridColumns = "gridColumns"
        static let pinnedItems = "pinnedItems"
        static let refreshInterval = "refreshInterval"
        static let showSystemIcons = "showSystemIcons"
        static let isCollapsed = "isCollapsed"
    }

    // MARK: - Published Properties

    /// Mirrors the login item state held by the system. The system is the
    /// source of truth, so this is read from `SMAppService` rather than
    /// UserDefaults, and reverts if registration fails.
    @Published var launchAtLogin: Bool {
        didSet {
            guard launchAtLogin != oldValue else { return }
            updateLaunchAtLogin()
        }
    }

    @Published var showIconLabels: Bool {
        didSet { defaults.set(showIconLabels, forKey: Keys.showIconLabels) }
    }

    @Published var gridColumns: Int {
        didSet { defaults.set(gridColumns, forKey: Keys.gridColumns) }
    }

    /// Seconds between automatic scans. `manualRefreshInterval` (or any
    /// non-positive or non-finite value) disables the timer.
    @Published var refreshInterval: Double {
        didSet { defaults.set(refreshInterval, forKey: Keys.refreshInterval) }
    }

    @Published var showSystemIcons: Bool {
        didSet { defaults.set(showSystemIcons, forKey: Keys.showSystemIcons) }
    }

    /// Whether the hidden section of the menu bar is currently tucked away.
    /// Written by `StatusBarController`, which owns the status items.
    @Published var isCollapsed: Bool {
        didSet { defaults.set(isCollapsed, forKey: Keys.isCollapsed) }
    }

    // MARK: - Pinned items

    /// Items the user has pinned to the top of the popover. This affects the
    /// order icons are listed in the app only; the real menu bar is not
    /// touched, because macOS does not allow an app to move another app's
    /// menu bar items.
    @Published private(set) var pinnedItems: Set<String> {
        didSet { defaults.set(Array(pinnedItems), forKey: Keys.pinnedItems) }
    }

    var isManualRefresh: Bool {
        !refreshInterval.isFinite || refreshInterval <= 0
    }

    // MARK: - Initialization

    private init() {
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
        self.showIconLabels = defaults.object(forKey: Keys.showIconLabels) as? Bool ?? true
        self.gridColumns = defaults.object(forKey: Keys.gridColumns) as? Int ?? 6
        self.showSystemIcons = defaults.object(forKey: Keys.showSystemIcons) as? Bool ?? true
        self.isCollapsed = defaults.object(forKey: Keys.isCollapsed) as? Bool ?? true

        // Earlier builds stored "manual only" as infinity; normalise it.
        let storedInterval = defaults.object(forKey: Keys.refreshInterval) as? Double ?? 5.0
        self.refreshInterval = storedInterval.isFinite ? storedInterval : AppSettings.manualRefreshInterval

        self.pinnedItems = Set(defaults.array(forKey: Keys.pinnedItems) as? [String] ?? [])

        // Discard keys from earlier builds that no longer have any effect
        for stale in ["hiddenItems", "knownItems", "revealNewItems", "itemOrder"] {
            defaults.removeObject(forKey: stale)
        }
    }

    // MARK: - Methods

    func togglePinned(_ itemKey: String) {
        if pinnedItems.contains(itemKey) {
            pinnedItems.remove(itemKey)
        } else {
            pinnedItems.insert(itemKey)
        }
    }

    func isPinned(_ itemKey: String) -> Bool {
        pinnedItems.contains(itemKey)
    }

    private func updateLaunchAtLogin() {
        let service = SMAppService.mainApp
        do {
            if launchAtLogin {
                if service.status != .enabled { try service.register() }
            } else if service.status != .notRegistered {
                try service.unregister()
            }
        } catch {
            NSLog("Failed to update launch at login: \(error)")
        }

        // Reflect what the system actually did (registration can fail or
        // require approval in System Settings).
        let actual = service.status == .enabled
        if actual != launchAtLogin { launchAtLogin = actual }
    }

    func resetToDefaults() {
        launchAtLogin = false
        showIconLabels = true
        gridColumns = 6
        refreshInterval = 5.0
        showSystemIcons = true
        pinnedItems = []
    }
}
