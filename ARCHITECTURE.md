# MacTrayOrganiser Architecture Guide

This document provides a technical overview of MacTrayOrganiser's architecture, design decisions, and implementation details for developers and contributors.

## Table of Contents
- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Core Components](#core-components)
- [Data Flow](#data-flow)
- [Key APIs](#key-apis)
- [Design Decisions](#design-decisions)
- [Security Considerations](#security-considerations)
- [Building & Distribution](#building--distribution)

---

## Overview

MacTrayOrganiser is a native macOS menu bar manager that allows users to view all menu bar icons (including those hidden by the notch or overflow) and interact with them from a centralized panel.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         macOS System                             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ SystemUI    │  │  Control    │  │   Third-Party Apps      │  │
│  │ Server      │  │  Center     │  │   (Menu Bar Extras)     │  │
│  └──────┬──────┘  └──────┬──────┘  └───────────┬─────────────┘  │
│         │                │                      │                │
│         └────────────────┼──────────────────────┘                │
│                          │                                       │
│                 ┌────────▼────────┐                              │
│                 │  Accessibility  │                              │
│                 │      API        │                              │
│                 │  (AXUIElement)  │                              │
│                 └────────┬────────┘                              │
└──────────────────────────┼──────────────────────────────────────┘
                           │
              ┌────────────▼────────────┐
              │   MacTrayOrganiser      │
              │  ┌──────────────────┐   │
              │  │ AccessibilityService │
              │  └─────────┬────────┘   │
              │            │            │
              │  ┌─────────▼────────┐   │
              │  │  MenuBarScanner  │   │
              │  └─────────┬────────┘   │
              │            │            │
              │  ┌─────────▼────────┐   │
              │  │   SwiftUI Views  │   │
              │  │  (MenuBarExtra)  │   │
              │  └──────────────────┘   │
              └─────────────────────────┘
```

---

## Tech Stack

| Component | Technology |
|-----------|------------|
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI with AppKit bridging |
| **Minimum Target** | macOS 13.0 (Ventura) |
| **Menu Bar** | SwiftUI `MenuBarExtra` |
| **System Integration** | Accessibility API (AXUIElement) |
| **Persistence** | UserDefaults |
| **Distribution** | Direct download (DMG) - non-App Store |

### Why These Choices?

- **SwiftUI**: Modern, declarative UI that integrates well with macOS
- **macOS 13.0+**: Required for `MenuBarExtra` with window style and modern SwiftUI features
- **Non-App Store**: Accessibility API usage requires entitlements not available in sandboxed App Store apps

---

## Project Structure

```
MacTrayOrganiser/
├── MacTrayOrganiserApp.swift      # App entry point, MenuBarExtra setup
│
├── Models/
│   ├── MenuBarItem.swift          # Data model for menu bar items
│   └── AppSettings.swift          # User preferences (ObservableObject)
│
├── Services/
│   ├── AccessibilityService.swift # Low-level AXUIElement wrapper
│   ├── MenuBarScanner.swift       # Discovers and tracks menu bar items
│   └── PermissionManager.swift    # Handles permission requests
│
├── Views/
│   ├── MenuBarView.swift          # Main MenuBarExtra content
│   ├── IconGridView.swift         # Grid display with drag-and-drop
│   ├── MainPanelView.swift        # Floating panel variant
│   ├── OnboardingView.swift       # First-run permission flow
│   └── SettingsView.swift         # App settings
│
├── Utilities/
│   └── ImageCapture.swift         # Screen capture for icon images
│
├── Assets.xcassets/               # App icons and assets
├── AppIcon.icns                   # App icon file
├── Info.plist                     # App configuration
└── MacTrayOrganiser.entitlements  # Entitlements (no sandbox)
```

---

## Core Components

### 1. MacTrayOrganiserApp (Entry Point)

```swift
@main
struct MacTrayOrganiserApp: App {
    var body: some Scene {
        MenuBarExtra { ... }
            .menuBarExtraStyle(.window)

        Settings { ... }
    }
}
```

- Uses `@NSApplicationDelegateAdaptor` for AppKit integration
- Sets `NSApp.setActivationPolicy(.accessory)` to hide from Dock
- Configures `MenuBarExtra` with window style for panel display

### 2. AccessibilityService

The core service for interacting with macOS Accessibility API.

```swift
class AccessibilityService {
    // Get system-wide element
    func getSystemWideElement() -> AXUIElement

    // Query attributes
    func getAttribute<T>(_ element: AXUIElement, attribute: String) -> T?
    func getPosition(_ element: AXUIElement) -> CGPoint?
    func getSize(_ element: AXUIElement) -> CGSize?

    // Get menu bar items
    func getMenuBarExtras() -> [AXUIElement]
    func getControlCenterItems() -> [AXUIElement]

    // Actions
    func pressElement(_ element: AXUIElement) -> Bool
}
```

**Key AXUIElement Attributes Used:**
- `kAXPositionAttribute` - Screen position
- `kAXSizeAttribute` - Element dimensions
- `kAXTitleAttribute` - Display title
- `kAXChildrenAttribute` - Child elements
- `kAXExtrasMenuBarAttribute` - Menu bar extras

### 3. MenuBarScanner

Orchestrates scanning and maintains the list of menu bar items.

```swift
class MenuBarScanner: ObservableObject {
    @Published var menuBarItems: [MenuBarItem] = []
    @Published var isScanning: Bool = false

    func scan()                    // Full scan
    func startAutoRefresh()        // Periodic scanning
    func clickItem(_ item: MenuBarItem)  // Simulate click
}
```

**Scanning Process:**
1. Query SystemUIServer for menu bar extras
2. Query ControlCenter for system items
3. Query each running app for their extras
4. Merge, deduplicate, and sort by position
5. Apply user preferences (hidden, pinned, order)

### 4. PermissionManager

Handles Accessibility permission lifecycle.

```swift
class PermissionManager: ObservableObject {
    @Published var hasAccessibilityPermission: Bool

    func checkAccessibilityPermission() -> Bool
    func requestAccessibilityPermission()
    func openAccessibilitySettings()
}
```

**Permission Flow:**
1. Check `AXIsProcessTrusted()` on launch
2. If not trusted, show onboarding
3. Call `AXIsProcessTrustedWithOptions()` with prompt
4. Poll periodically until granted
5. Post notification when permission changes

### 5. MenuBarItem (Model)

```swift
struct MenuBarItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let ownerName: String
    let ownerPID: pid_t
    let position: CGPoint
    let size: CGSize
    let axElement: AXUIElement
    var icon: NSImage?
    var isHidden: Bool
    var isPinned: Bool
    var sortOrder: Int

    func performClick()
}
```

### 6. AppSettings

Persisted user preferences using `@Published` properties and UserDefaults.

```swift
class AppSettings: ObservableObject {
    @Published var launchAtLogin: Bool
    @Published var showIconLabels: Bool
    @Published var gridColumns: Int
    @Published var refreshInterval: Double

    private(set) var hiddenItems: Set<String>
    private(set) var pinnedItems: Set<String>
    private(set) var itemOrder: [String: Int]
}
```

---

## Data Flow

```
┌─────────────────┐
│  User clicks    │
│  menu bar icon  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  MenuBarView    │
│  opens panel    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐     ┌─────────────────┐
│ MenuBarScanner  │────▶│ AccessibilityService │
│    .scan()      │     │  (AXUIElement)  │
└────────┬────────┘     └─────────────────┘
         │
         ▼
┌─────────────────┐
│ @Published      │
│ menuBarItems    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  IconGridView   │
│  renders items  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  User clicks    │
│  an icon        │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ AXUIElement     │
│ PerformAction   │
│ (kAXPressAction)│
└─────────────────┘
```

---

## Key APIs

### Accessibility API (ApplicationServices)

```swift
import ApplicationServices

// Check if trusted
AXIsProcessTrusted() -> Bool
AXIsProcessTrustedWithOptions(_ options: CFDictionary?) -> Bool

// Create elements
AXUIElementCreateSystemWide() -> AXUIElement
AXUIElementCreateApplication(_ pid: pid_t) -> AXUIElement

// Query attributes
AXUIElementCopyAttributeValue(_ element: AXUIElement,
                               _ attribute: CFString,
                               _ value: UnsafeMutablePointer<CFTypeRef?>) -> AXError

// Perform actions
AXUIElementPerformAction(_ element: AXUIElement,
                         _ action: CFString) -> AXError
```

### SwiftUI Menu Bar

```swift
MenuBarExtra {
    // Content view
} label: {
    Image(systemName: "square.grid.2x2")
}
.menuBarExtraStyle(.window)  // Panel style (macOS 13+)
```

### Launch at Login (ServiceManagement)

```swift
import ServiceManagement

try SMAppService.mainApp.register()    // Enable
try SMAppService.mainApp.unregister()  // Disable
```

---

## Design Decisions

### 1. Menu Bar Only (LSUIElement)

The app sets `LSUIElement = true` in Info.plist to:
- Not appear in the Dock
- Not appear in Cmd+Tab app switcher
- Behave as a background/accessory app

### 2. No Sandbox

The app is not sandboxed (`com.apple.security.app-sandbox = false`) because:
- Accessibility API requires non-sandboxed access
- Cannot be distributed on the App Store
- Distributed as a direct download DMG

### 3. Window-Style MenuBarExtra

Using `.menuBarExtraStyle(.window)` instead of `.menu` provides:
- Custom SwiftUI views
- Drag-and-drop support
- Rich interactions
- Better visual design

### 4. Polling for Permission

Rather than using complex notification systems, the app polls for permission changes:
- Simple and reliable
- Works across all macOS versions
- Adjustable frequency based on state

### 5. Generic Icons

Instead of capturing actual menu bar icon images (which requires Screen Recording permission), the app uses:
- SF Symbols for known item types
- Generic app icon for unknown items
- This reduces permission requirements

---

## Security Considerations

### Accessibility Permission
- Required for core functionality
- User must explicitly grant in System Settings
- App guides user through the process
- Permission can be revoked at any time

### No Network Access
- App works entirely offline
- No data is sent anywhere
- No analytics or telemetry

### No Sensitive Data
- Only reads menu bar item metadata (title, position)
- Does not access app contents or user data
- Preferences stored locally in UserDefaults

### Code Signing
- App should be signed for distribution
- Users may need to allow in Gatekeeper on first run

---

## Building & Distribution

### Requirements
- Xcode 15.0+
- macOS 13.0+ SDK

### Build Commands

```bash
# Debug build
xcodebuild -project MacTrayOrganiser.xcodeproj \
           -scheme MacTrayOrganiser \
           -configuration Debug build

# Release build
xcodebuild -project MacTrayOrganiser.xcodeproj \
           -scheme MacTrayOrganiser \
           -configuration Release build
```

### Creating DMG

```bash
./scripts/create_dmg.sh
```

This script:
1. Finds the built app
2. Creates a temporary DMG with the app and Applications symlink
3. Sets up the DMG background and layout
4. Converts to compressed format
5. Sets the custom volume icon

### Distribution Checklist
- [ ] Build Release configuration
- [ ] Code sign the app
- [ ] Create DMG
- [ ] Set DMG icon
- [ ] Test on clean macOS installation
- [ ] Create GitHub release
- [ ] Upload DMG to release

---

## Future Improvements

### Potential Enhancements
1. **Actual Icon Capture**: Use ScreenCaptureKit to capture real menu bar icons
2. **Icon Hiding**: Actively hide icons from the menu bar (complex, may require private APIs)
3. **Keyboard Navigation**: Full keyboard support for accessibility
4. **Search**: Filter icons by name
5. **Groups**: Organize icons into custom groups
6. **Profiles**: Save different arrangements for different contexts

### Known Limitations
1. Cannot programmatically reorder the actual menu bar (macOS limitation)
2. Some system icons may not respond to simulated clicks
3. Menu bar changes may take a few seconds to detect
4. Private/internal menu bar items may not be accessible

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Code style
- Pull request process
- Issue reporting
- Development setup

---

## License

MIT License - See [LICENSE](LICENSE) for details.
