//
//  IconGridView.swift
//  MacTrayOrganiser
//
//  Grid display of menu bar icons
//

import SwiftUI

struct IconGridView: View {
    let items: [MenuBarItem]
    @EnvironmentObject var appSettings: AppSettings

    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: max(1, appSettings.gridColumns))
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items) { item in
                    MenuBarItemView(item: item)
                }
            }
            .padding(12)
        }
    }
}

struct MenuBarItemView: View {
    let item: MenuBarItem
    @EnvironmentObject var appSettings: AppSettings
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isHovered ? Color.accentColor.opacity(0.3) : Color.clear, lineWidth: 1)
                    )

                VStack(spacing: 2) {
                    // Owning app's icon when we have one, otherwise a symbol guessed from the name
                    if let icon = item.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: iconForItem(item))
                            .font(.system(size: 18))
                            .foregroundColor(.primary)
                    }

                    if appSettings.showIconLabels {
                        Text(item.displayName)
                            .font(.caption2)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: appSettings.showIconLabels ? 50 : 40)
        }
        .contentShape(Rectangle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            isPressed = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                MenuBarScanner.shared.clickItem(item)
            }
        }
        .contextMenu {
            Button("Activate") {
                MenuBarScanner.shared.clickItem(item)
            }

            Button(item.isPinned ? "Unpin" : "Pin to Top of List") {
                appSettings.togglePinned(item.preferenceKey)
            }

            Divider()

            Text(item.ownerName)
                .foregroundColor(.secondary)
        }
        .help(item.displayName)
    }

    // Provide a reasonable icon based on the item name
    private func iconForItem(_ item: MenuBarItem) -> String {
        let name = item.displayName.lowercased()

        if name.contains("wifi") || name.contains("wi-fi") || name.contains("wi‑fi") {
            return "wifi"
        } else if name.contains("bluetooth") {
            return "dot.radiowaves.left.and.right"
        } else if name.contains("battery") {
            return "battery.100"
        } else if name.contains("sound") || name.contains("volume") || name.contains("audio") {
            return "speaker.wave.2"
        } else if name.contains("clock") || name.contains("time") || name.contains("date") {
            return "clock"
        } else if name.contains("spotlight") || name.contains("search") {
            return "magnifyingglass"
        } else if name.contains("control") {
            return "slider.horizontal.3"
        } else if name.contains("siri") {
            return "mic"
        } else if name.contains("notification") {
            return "bell"
        } else if name.contains("focus") || name.contains("do not disturb") {
            return "moon"
        } else if name.contains("screen") || name.contains("display") || name.contains("airplay") {
            return "display"
        } else if name.contains("keyboard") {
            return "keyboard"
        } else if name.contains("now playing") || name.contains("music") {
            return "music.note"
        } else if name.contains("vpn") {
            return "lock.shield"
        } else if name.contains("backup") || name.contains("time machine") {
            return "clock.arrow.circlepath"
        }

        return "app.badge"
    }
}

#Preview {
    IconGridView(items: [])
        .environmentObject(AppSettings.shared)
        .frame(width: 380, height: 280)
}
