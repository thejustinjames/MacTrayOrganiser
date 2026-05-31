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

    private let defaults = UserDefaults.standard

    // Keys for UserDefaults
    private enum Keys {
        static let launchAtLogin = "launchAtLogin"
        static let showIconLabels = "showIconLabels"
        static let gridColumns = "gridColumns"
        static let hiddenItems = "hiddenItems"
        static let pinnedItems = "pinnedItems"
        static let itemOrder = "itemOrder"
        static let refreshInterval = "refreshInterval"
        static let showSystemIcons = "showSystemIcons"
    }

    // MARK: - Published Properties

    @Published var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin()
        }
    }

    @Published var showIconLabels: Bool {
        didSet {
            defaults.set(showIconLabels, forKey: Keys.showIconLabels)
        }
    }

    @Published var gridColumns: Int {
        didSet {
            defaults.set(gridColumns, forKey: Keys.gridColumns)
        }
    }

    @Published var refreshInterval: Double {
        didSet {
            defaults.set(refreshInterval, forKey: Keys.refreshInterval)
        }
    }

    @Published var showSystemIcons: Bool {
        didSet {
            defaults.set(showSystemIcons, forKey: Keys.showSystemIcons)
        }
    }

    // MARK: - Stored Collections

    private(set) var hiddenItems: Set<String> {
        didSet {
            defaults.set(Array(hiddenItems), forKey: Keys.hiddenItems)
        }
    }

    private(set) var pinnedItems: Set<String> {
        didSet {
            defaults.set(Array(pinnedItems), forKey: Keys.pinnedItems)
        }
    }

    private(set) var itemOrder: [String: Int] {
        didSet {
            defaults.set(itemOrder, forKey: Keys.itemOrder)
        }
    }

    // MARK: - Initialization

    private init() {
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.showIconLabels = defaults.object(forKey: Keys.showIconLabels) as? Bool ?? true
        self.gridColumns = defaults.object(forKey: Keys.gridColumns) as? Int ?? 6
        self.refreshInterval = defaults.object(forKey: Keys.refreshInterval) as? Double ?? 5.0
        self.showSystemIcons = defaults.object(forKey: Keys.showSystemIcons) as? Bool ?? true

        if let hidden = defaults.array(forKey: Keys.hiddenItems) as? [String] {
            self.hiddenItems = Set(hidden)
        } else {
            self.hiddenItems = []
        }

        if let pinned = defaults.array(forKey: Keys.pinnedItems) as? [String] {
            self.pinnedItems = Set(pinned)
        } else {
            self.pinnedItems = []
        }

        if let order = defaults.dictionary(forKey: Keys.itemOrder) as? [String: Int] {
            self.itemOrder = order
        } else {
            self.itemOrder = [:]
        }
    }

    // MARK: - Methods

    func toggleHidden(_ itemKey: String) {
        objectWillChange.send()
        if hiddenItems.contains(itemKey) {
            hiddenItems.remove(itemKey)
        } else {
            hiddenItems.insert(itemKey)
        }
    }

    func togglePinned(_ itemKey: String) {
        objectWillChange.send()
        if pinnedItems.contains(itemKey) {
            pinnedItems.remove(itemKey)
        } else {
            pinnedItems.insert(itemKey)
        }
    }

    func isHidden(_ itemKey: String) -> Bool {
        hiddenItems.contains(itemKey)
    }

    func isPinned(_ itemKey: String) -> Bool {
        pinnedItems.contains(itemKey)
    }

    func setOrder(_ itemKey: String, order: Int) {
        objectWillChange.send()
        itemOrder[itemKey] = order
    }

    func getOrder(_ itemKey: String) -> Int {
        itemOrder[itemKey] ?? Int.max
    }

    private func updateLaunchAtLogin() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to update launch at login: \(error)")
        }
    }

    func resetToDefaults() {
        launchAtLogin = false
        showIconLabels = true
        gridColumns = 6
        refreshInterval = 5.0
        showSystemIcons = true
        hiddenItems = []
        pinnedItems = []
        itemOrder = [:]
    }
}
