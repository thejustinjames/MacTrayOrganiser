# MacTrayOrganiser User Guide

## Table of Contents
- [Installation](#installation)
- [Getting Started](#getting-started)
- [Using the App](#using-the-app)
- [Reordering Menu Bar Icons](#reordering-menu-bar-icons)
- [Settings](#settings)
- [Troubleshooting](#troubleshooting)
- [Uninstalling](#uninstalling)

---

## Installation

### Download & Install
1. Download `MacTrayOrganiser-1.0.0.dmg` from the [Releases page](https://github.com/thejustinjames/MacTrayOrganiser/releases)
2. Open the DMG file
3. Drag **MacTrayOrganiser** to your **Applications** folder
4. Eject the DMG

### First Launch
1. Open **MacTrayOrganiser** from your Applications folder
2. You'll see a permission request - this is required for the app to work

### Granting Accessibility Permission
MacTrayOrganiser needs Accessibility permission to read and interact with menu bar items.

1. Click **"Open System Settings"** when prompted
2. In System Settings, go to **Privacy & Security → Accessibility**
3. Find **MacTrayOrganiser** in the list
4. Toggle the switch **ON** to enable access
5. Return to MacTrayOrganiser - it will automatically detect the permission

> **Why is this needed?** The Accessibility API allows MacTrayOrganiser to see all menu bar items (including hidden ones) and simulate clicks when you interact with them in the app.

---

## Getting Started

### Finding the App
MacTrayOrganiser is a **menu bar app** - it does NOT appear in your Dock.

Look for the **grid icon (⊞)** in your menu bar at the top-right of your screen, near the clock, WiFi, and battery icons.

```
┌────────────────────────────────────────────────────────────────────┐
│  Apple  App  File  Edit  ...        [⊞] 📶 🔋 🔊  3:45 PM         │
│                                      ↑                             │
│                              MacTrayOrganiser                      │
└────────────────────────────────────────────────────────────────────┘
```

### Opening the Panel
Click the **grid icon** to open the MacTrayOrganiser panel, which displays all your menu bar items in an organized grid.

---

## Using the App

### Viewing All Menu Bar Items
The main panel shows all detected menu bar items, including:
- Third-party app icons (Claude, Ollama, Docker, etc.)
- System icons (WiFi, Bluetooth, Battery, etc.)
- Control Center items
- Items hidden by the notch or overflow

### Clicking Menu Bar Items
Click any icon in the MacTrayOrganiser panel to activate it - this simulates clicking the actual menu bar icon and will open its menu or trigger its action.

### Tabs
- **All** - Shows all visible menu bar items
- **Pinned** - Shows items you've pinned as favorites
- **Hidden** - Shows items you've chosen to hide

### Context Menu (Right-Click)
Right-click any icon to access options:
- **Pin to Top** - Keep this icon at the top of the list
- **Hide** - Remove this icon from the main view (access it in the Hidden tab)

### Refreshing
Click the **refresh button (↻)** in the top-right corner to rescan menu bar items. The app also auto-refreshes periodically.

---

## Reordering Menu Bar Icons

### Moving Icons in the Actual Menu Bar
MacTrayOrganiser shows your menu bar items, but to **permanently reorder** them in the actual macOS menu bar:

1. **Hold the Command (⌘) key**
2. **Click and drag** the menu bar icon you want to move
3. **Drop it** in the desired position
4. Release the Command key

> **Note:** This is a built-in macOS feature. Some system icons (Control Center items) may have restrictions on where they can be moved.

### Organizing Within MacTrayOrganiser
Within the app, you can:
- **Drag and drop** icons to reorder them in the grid
- **Pin** frequently used icons to keep them at the top
- **Hide** icons you rarely use

---

## Settings

Access settings by clicking the **gear icon (⚙)** in the bottom-left of the panel, or go to **MacTrayOrganiser → Settings** in the menu bar.

### General Settings
| Setting | Description |
|---------|-------------|
| **Launch at Login** | Start MacTrayOrganiser automatically when you log in |
| **Refresh Interval** | How often to scan for menu bar changes (1s, 5s, 10s, 30s, or Manual) |
| **Show System Icons** | Include macOS system icons in the display |

### Appearance Settings
| Setting | Description |
|---------|-------------|
| **Show Icon Labels** | Display names below each icon |
| **Grid Columns** | Number of icons per row (4-10) |

### Permissions
View the current status of Accessibility permission and grant it if needed.

---

## Troubleshooting

### "No Menu Bar Items Found"
1. Ensure Accessibility permission is granted
2. Click the **Refresh** button
3. Check System Settings → Privacy & Security → Accessibility

### App Not Visible
- The app appears in the **menu bar**, not the Dock
- Look for the grid icon (⊞) at the top of your screen
- If your menu bar is full, try Cmd+dragging icons to make room

### Icons Not Clickable
- Ensure Accessibility permission is enabled
- Some system icons may have limited interactivity
- Try clicking the actual menu bar icon directly

### Permission Was Revoked
If you accidentally revoke Accessibility permission:
1. Open **System Settings → Privacy & Security → Accessibility**
2. Find MacTrayOrganiser and toggle it **ON**
3. You may need to restart the app

### App Crashes or Freezes
1. Quit MacTrayOrganiser (click power icon in panel or force quit)
2. Relaunch from Applications
3. If issues persist, try removing and re-granting Accessibility permission

---

## Uninstalling

### Remove the App
1. Quit MacTrayOrganiser (click the power icon in the panel)
2. Open **Finder → Applications**
3. Drag **MacTrayOrganiser** to the Trash
4. Empty Trash

### Remove Permissions
1. Open **System Settings → Privacy & Security → Accessibility**
2. Select MacTrayOrganiser
3. Click the **minus (-)** button to remove it

### Remove Preferences (Optional)
To completely remove all settings:
```bash
defaults delete com.mactrayorganiser.app
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘ + ,` | Open Settings |
| `⌘ + R` | Refresh menu bar items |
| `⌘ + Q` | Quit MacTrayOrganiser |

---

## Tips & Tricks

1. **Quick Access**: Keep MacTrayOrganiser's icon visible by Cmd+dragging it to the far right of your menu bar

2. **Notch Users**: If icons are hidden behind your MacBook's notch, MacTrayOrganiser shows them all in the panel

3. **Pin Important Icons**: Right-click and pin your most-used icons so they're always at the top

4. **Reduce Clutter**: Hide icons you rarely use - you can still access them from the Hidden tab

5. **Launch at Login**: Enable this in Settings so MacTrayOrganiser is always ready

---

## Support

- **GitHub Issues**: [Report bugs or request features](https://github.com/thejustinjames/MacTrayOrganiser/issues)
- **Source Code**: [View on GitHub](https://github.com/thejustinjames/MacTrayOrganiser)

---

## License

MacTrayOrganiser is open source software released under the MIT License. See [LICENSE](../LICENSE) for details.
