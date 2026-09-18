//
//  SettingsView.swift
//  MacTrayOrganiser
//
//  App settings panel
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appSettings: AppSettings

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
        .frame(width: 450, height: 380)
    }
}

struct GeneralSettingsView: View {
    @EnvironmentObject var appSettings: AppSettings
    @ObservedObject private var permissionManager = PermissionManager.shared
    @State private var showResetAlert = false

    var body: some View {
        Form {
            Section {
                Toggle("Launch at Login", isOn: $appSettings.launchAtLogin)

                HStack {
                    Text("Refresh Interval")
                    Spacer()
                    Picker("Refresh Interval", selection: $appSettings.refreshInterval) {
                        Text("1 second").tag(1.0)
                        Text("5 seconds").tag(5.0)
                        Text("10 seconds").tag(10.0)
                        Text("30 seconds").tag(30.0)
                        Text("Manual only").tag(AppSettings.manualRefreshInterval)
                    }
                    .labelsHidden()
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
                    showResetAlert = true
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .alert("Reset all settings?", isPresented: $showResetAlert) {
            Button("Reset", role: .destructive) {
                appSettings.resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your pinned items and other preferences. It cannot be undone.")
        }
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
    private static let repositoryURL = URL(string: "https://github.com/thejustinjames/MacTrayOrganiser")!
    private static let issuesURL = URL(string: "https://github.com/thejustinjames/MacTrayOrganiser/issues")!

    private var versionText: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.1.0"
        let build = info?["CFBundleVersion"] as? String
        if let build, build != version {
            return "Version \(version) (\(build))"
        }
        return "Version \(version)"
    }

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

            Text(versionText)
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
                    NSWorkspace.shared.open(Self.repositoryURL)
                }
                .buttonStyle(.link)

                Button("Report Issue") {
                    NSWorkspace.shared.open(Self.issuesURL)
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

/// Opens the app's Settings window from the popover.
struct SettingsButton<Label: View>: View {
    @ViewBuilder let label: () -> Label

    var body: some View {
        Button(action: {
            StatusBarController.shared.openSettings()
        }) {
            label()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppSettings.shared)
}
