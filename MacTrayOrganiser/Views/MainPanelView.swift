//
//  MainPanelView.swift
//  MacTrayOrganiser
//
//  Main floating panel view (used when opening via NSPanel)
//

import SwiftUI

struct MainPanelView: View {
    @EnvironmentObject var appSettings: AppSettings
    @EnvironmentObject var permissionManager: PermissionManager
    @StateObject private var scanner = MenuBarScanner.shared

    @State private var selectedTab: Tab = .all

    enum Tab: String, CaseIterable {
        case all = "All"
        case pinned = "Pinned"
        case hidden = "Hidden"
    }

    var body: some View {
        VStack(spacing: 0) {
            if !permissionManager.hasAccessibilityPermission {
                OnboardingView()
            } else {
                // Tab selector
                Picker("View", selection: $selectedTab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.top, 12)

                // Content based on selected tab
                tabContent

                Divider()

                // Footer
                HStack {
                    if let lastScan = scanner.lastScanTime {
                        Text("Last scan: \(lastScan, formatter: timeFormatter)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: { scanner.scan() }) {
                        Label("Refresh", systemImage: "arrow.clockwise")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)

                    Button(action: {
                        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    }) {
                        Label("Settings", systemImage: "gear")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
                .padding(12)
            }
        }
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .all:
            if scanner.menuBarItems.isEmpty {
                emptyState
            } else {
                IconGridView(items: scanner.visibleItems)
            }
        case .pinned:
            if scanner.pinnedItems.isEmpty {
                VStack {
                    Spacer()
                    Text("No pinned items")
                        .foregroundColor(.secondary)
                    Text("Right-click an icon to pin it")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                IconGridView(items: scanner.pinnedItems)
            }
        case .hidden:
            if scanner.hiddenItems.isEmpty {
                VStack {
                    Spacer()
                    Text("No hidden items")
                        .foregroundColor(.secondary)
                    Text("Right-click an icon to hide it")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                IconGridView(items: scanner.hiddenItems)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()

            if scanner.isScanning {
                ProgressView("Scanning...")
            } else {
                Image(systemName: "menubar.rectangle")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)

                Text("No menu bar items found")
                    .font(.headline)

                Button("Scan Now") {
                    scanner.scan()
                }
                .buttonStyle(.bordered)
            }

            Spacer()
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

// Visual effect view for macOS vibrancy
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

#Preview {
    MainPanelView()
        .environmentObject(AppSettings.shared)
        .environmentObject(PermissionManager.shared)
        .frame(width: 400, height: 300)
}
