//
//  MacTrayOrganiserApp.swift
//  MacTrayOrganiser
//
//  A native macOS menu bar manager app
//

import SwiftUI

@main
struct MacTrayOrganiserApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // The menu bar icon and its popover are AppKit status items owned by
        // StatusBarController, so their position in the menu bar can be
        // controlled. Only the Settings window is a SwiftUI scene.
        Settings {
            SettingsView()
                .environmentObject(AppSettings.shared)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - we're a menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Refresh the published permission state on launch
        PermissionManager.shared.checkAccessibilityPermission()

        // Create the status items, then begin scanning
        _ = StatusBarController.shared
        MenuBarScanner.shared.start()

        enableLoginItemOnFirstRun()
    }

    /// A menu bar utility is most useful when it is already in the bar at
    /// login, and launching early helps it keep its left-hand spot. Register
    /// as a login item once, on first launch; the user can turn it off in
    /// Settings and that choice then sticks.
    private func enableLoginItemOnFirstRun() {
        let key = "didConfigureInitialLogin"
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: key) else { return }
        defaults.set(true, forKey: key)
        AppSettings.shared.launchAtLogin = true
    }
}
