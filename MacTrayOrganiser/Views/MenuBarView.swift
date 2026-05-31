//
//  MenuBarView.swift
//  MacTrayOrganiser
//
//  The view shown when clicking the menu bar icon (using MenuBarExtra window style)
//

import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var permissionManager: PermissionManager
    @StateObject private var scanner = MenuBarScanner.shared

    var body: some View {
        VStack(spacing: 0) {
            if !permissionManager.hasAccessibilityPermission {
                PermissionRequiredView()
            } else {
                MainContentView(scanner: scanner)
            }
        }
        .frame(width: 380, height: 320)
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

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView(scanner: scanner)

            Divider()

            // Content
            if scanner.isScanning && scanner.menuBarItems.isEmpty {
                LoadingView()
            } else if scanner.menuBarItems.isEmpty {
                EmptyStateView(scanner: scanner)
            } else {
                IconGridView(items: scanner.visibleItems)
            }

            Divider()

            // Footer
            FooterView()
        }
    }
}

struct HeaderView: View {
    @ObservedObject var scanner: MenuBarScanner

    var body: some View {
        HStack {
            Text("Menu Bar Items")
                .font(.headline)

            Spacer()

            if scanner.isScanning {
                ProgressView()
                    .scaleEffect(0.6)
            }

            Button(action: { scanner.scan() }) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
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
            Button(action: {
                if let url = URL(string: "x-apple.systempreferences:") {
                    NSWorkspace.shared.open(url)
                }
            }) {
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
