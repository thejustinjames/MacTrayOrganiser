//
//  MenuBarView.swift
//  MacTrayOrganiser
//
//  The view shown in the popover when clicking the menu bar icon
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var permissionManager: PermissionManager
    @ObservedObject private var scanner = MenuBarScanner.shared

    var body: some View {
        VStack(spacing: 0) {
            if !permissionManager.hasAccessibilityPermission {
                PermissionRequiredView()
            } else {
                MainContentView(scanner: scanner)
            }
        }
        .frame(width: 380, height: 360)
    }
}

struct PermissionRequiredView: View {
    @EnvironmentObject var permissionManager: PermissionManager

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("Accessibility Permission Required")
                .font(.headline)

            Text("MacTrayOrganiser needs Accessibility permission to read and interact with menu bar items.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                permissionManager.requestAccessibilityPermission()
            }) {
                Text("Grant Permission")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)

            Button("Open System Settings") {
                permissionManager.openAccessibilitySettings()
            }
            .buttonStyle(.link)
        }
        .padding()
    }
}

struct MainContentView: View {
    @ObservedObject var scanner: MenuBarScanner
    @EnvironmentObject var appSettings: AppSettings
    @State private var selectedTab: ItemTab = .all

    enum ItemTab: String, CaseIterable {
        case all = "All"
        case pinned = "Pinned"
        case hidden = "Hidden"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(scanner: scanner)

            Picker("View", selection: $selectedTab) {
                ForEach(ItemTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding(.horizontal, 12)
            .padding(.bottom, 8)

            Divider()

            // Content
            if scanner.isScanning && scanner.menuBarItems.isEmpty {
                LoadingView()
            } else if scanner.menuBarItems.isEmpty {
                EmptyStateView(scanner: scanner)
            } else {
                tabContent
            }

            Divider()

            // Footer
            FooterView()
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .all:
            if scanner.visibleItems.isEmpty {
                TabPlaceholderView(title: "All items are hidden", hint: "Tap the eye button to reveal them")
            } else {
                IconGridView(items: scanner.visibleItems)
            }
        case .pinned:
            if scanner.pinnedItems.isEmpty {
                TabPlaceholderView(title: "No pinned items", hint: "Right-click an icon to pin it")
            } else {
                IconGridView(items: scanner.pinnedItems)
            }
        case .hidden:
            if scanner.hiddenItems.isEmpty {
                TabPlaceholderView(title: "No hidden items", hint: "⌘-drag a menu bar icon left of the MacTrayOrganiser separator to hide it")
            } else {
                IconGridView(items: scanner.hiddenItems)
            }
        }
    }
}

struct TabPlaceholderView: View {
    let title: String
    let hint: String

    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            Text(title)
                .foregroundColor(.secondary)
            Text(hint)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

struct HeaderView: View {
    @ObservedObject var scanner: MenuBarScanner
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        HStack {
            Text("Menu Bar Items")
                .font(.headline)

            Spacer()

            if scanner.isScanning {
                ProgressView()
                    .scaleEffect(0.6)
            }

            Button(action: { StatusBarController.shared.toggleCollapsed() }) {
                Image(systemName: appSettings.isCollapsed ? "eye" : "eye.slash")
            }
            .buttonStyle(.borderless)
            .help(appSettings.isCollapsed ? "Reveal hidden items in the menu bar" : "Tuck hidden items away")

            Button(action: { scanner.scan() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .disabled(scanner.isScanning)
            .help("Refresh menu bar items")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            Spacer()
            ProgressView("Scanning menu bar...")
            Spacer()
        }
    }
}

struct EmptyStateView: View {
    @ObservedObject var scanner: MenuBarScanner

    var body: some View {
        VStack(spacing: 12) {
            Spacer()

            Image(systemName: "menubar.rectangle")
                .font(.system(size: 36))
                .foregroundColor(.secondary)

            Text("No Menu Bar Items Found")
                .font(.headline)

            if let error = scanner.scanError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("Click refresh to scan again")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button("Scan Now") {
                scanner.scan()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding()
    }
}

struct FooterView: View {
    var body: some View {
        HStack {
            SettingsButton {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
            .help("Open Settings")

            Spacer()

            Text("MacTrayOrganiser")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                NSApp.terminate(nil)
            }) {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit MacTrayOrganiser")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}

#Preview {
    MenuBarView()
        .environmentObject(AppSettings.shared)
        .environmentObject(PermissionManager.shared)
}
