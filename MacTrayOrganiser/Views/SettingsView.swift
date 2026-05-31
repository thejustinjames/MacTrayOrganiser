//
//  SettingsView.swift
//  MacTrayOrganiser
//
//  App settings panel
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @State private var showResetAlert = false

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            AboutView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @StateObject private var permissionManager = PermissionManager.shared

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $appSettings.launchAtLogin)

                HStack {
                    Text("Refresh Interval")
                    Spacer()
                    Picker("", selection: $appSettings.refreshInterval) {
                        Text("1 second").tag(1.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("30 seconds").tag(30.0)
                        Text("Manual only").tag(Double.infinity)
                    }
                    .frame(width: 140)
                }
            } header: {
                Text("Behavior")
            }

            Section {
                Toggle("Show System Icons", isOn: $appSettings.showSystemIcons)
                    .help("Include macOS system icons like Control Center, Wi-Fi, etc.")
            } header: {
                Text("Items")
            }

            Section {
                HStack {
                    Text("Accessibility")
                    Spacer()
                    if permissionManager.hasAccessibilityPermission {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Not Granted", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                    }
                }

                if !permissionManager.hasAccessibilityPermission {
                    Button("Grant Permission") {
                        permissionManager.requestAccessibilityPermission()
                    }
                }
            } header: {
                Text("Permissions")
            }

            Section {
                Button("Reset All Settings", role: .destructive) {
                    appSettings.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AppearanceSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings

    var body: some View {
        Form {
            Section {
                Toggle("Show Icon Labels", isOn: $appSettings.showIconLabels)
                    .help("Display the name below each icon")
            } header: {
                Text("Icons")
            }

            Section {
                Stepper("Grid Columns: \(appSettings.gridColumns)", value: $appSettings.gridColumns, in: 4...10)
                    .help("Number of icons per row")
            } header: {
                Text("Layout")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 64))
                .foregroundStyle(.linearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))

            Text("MacTrayOrganiser")
                .font(.title)
                .fontWeight(.semibold)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("A native macOS menu bar manager that lets you view and organize all your menu bar icons.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            HStack(spacing: 20) {
                Button("GitHub") {
                    if let url = URL(string: "https://github.com/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)

                Button("Report Issue") {
                    if let url = URL(string: "https://github.com/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.link)
            }

            Text("Made with Swift & SwiftUI")
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings.shared)
}
