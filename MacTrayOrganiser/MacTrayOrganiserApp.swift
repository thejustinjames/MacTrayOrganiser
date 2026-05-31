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
    @StateObject private var appSettings = AppSettings.shared
    @StateObject private var permissionManager = PermissionManager.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appSettings)
                .environmentObject(permissionManager)
        } label: {
            Image(systemName: "square.grid.2x2")
                .imageScale(.large)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appSettings)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var panelController: PanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon - we're a menu bar only app
        NSApp.setActivationPolicy(.accessory)

        // Initialize panel controller
        panelController = PanelController()

        // Check accessibility permission on launch
        if !PermissionManager.shared.checkAccessibilityPermission() {
            PermissionManager.shared.showOnboarding = true
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup
    }
}

class PanelController: NSObject {
    var panel: NSPanel?

    func showPanel(relativeTo statusItem: NSStatusItem?) {
        if panel == nil {
            createPanel()
        }

        guard let panel = panel else { return }

        if let button = statusItem?.button {
            let buttonFrame = button.window?.frame ?? .zero
            let panelSize = panel.frame.size
            let x = buttonFrame.midX - panelSize.width / 2
            let y = buttonFrame.minY - panelSize.height - 5
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func hidePanel() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear

        let hostingView = NSHostingView(rootView: MainPanelView()
            .environmentObject(AppSettings.shared)
            .environmentObject(PermissionManager.shared))
        panel.contentView = hostingView

        self.panel = panel
    }
}
