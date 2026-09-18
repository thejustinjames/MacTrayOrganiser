# Changelog

All notable changes to MacTrayOrganiser will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-09-18

### Added
- The app now places its own menu bar icon at the far left of the status items
- Collapsible hidden section: a separator that tucks icons on its left off-screen, toggled from the panel's eye button or by ⌥-click / right-click on the app icon (the Hidden Bar model)
- Right-click or ⌥-click the app icon to toggle the hidden section without opening the panel

### Changed
- Hiding an icon now moves it in the real menu bar via the collapsible section, rather than only hiding it inside the app. Because macOS does not let an app move another app's menu bar icons, the user places icons on either side of the separator with a ⌘-drag; the app collapses and reveals them
- The "Hidden" tab now reflects what is actually in the hidden section of the menu bar
- Clicking a hidden item reveals the section first, then activates it
- Removed in-app-only drag reordering, which could not affect the real menu bar

### Fixed
- Hidden items could not be recovered: the menu bar popover now has the All, Pinned and Hidden tabs
- "Show System Icons" and "Grid Columns" settings had no effect
- Changing the refresh interval did nothing until the app was relaunched
- Drag-and-drop reordering swapped two items instead of moving the dragged one
- The Settings button in the popover opened System Settings instead of the app's own Settings
- Settings could be opened behind other windows; the app now activates first
- The first scan after Accessibility permission was granted was skipped
- "Grant Permission" appeared to do nothing on repeat presses; it now opens the Accessibility pane directly
- "Launch at Login" showed a stale value if the login item was changed in System Settings
- User preferences were read from a background thread during scans
- Every rescan regenerated item identities, breaking drags and causing flicker
- MacTrayOrganiser listed its own menu bar icon
- An unresponsive app could stall scanning for several seconds per query
- Third-party items now show their app's icon instead of a guessed symbol
- Reset All Settings now asks for confirmation
- About tab links pointed at github.com rather than the repository
- App icon PNGs were twice their declared size (the generator rendered at the display scale)
- DMG scripts assumed the project root as working directory and left the image mounted on failure
- DMG icon script required PyObjC, which the system Python does not ship with

## [1.0.0] - 2024-05-31

### Added
- Initial release of MacTrayOrganiser
- View all menu bar items in an organized grid panel
- Click-through functionality to activate menu bar items
- Pin favorite icons to keep them at the top
- Hide unwanted icons from the main view
- Drag and drop to reorder icons within the panel
- Auto-refresh to detect menu bar changes
- Settings panel with customization options:
  - Launch at Login
  - Refresh interval (1s, 5s, 10s, 30s, or manual)
  - Show/hide icon labels
  - Adjustable grid columns (4-10)
  - Show/hide system icons
- Onboarding flow for Accessibility permission
- Tab view (All, Pinned, Hidden)
- Native SwiftUI interface
- macOS 13.0+ support

### Technical
- Built with Swift 5.9 and SwiftUI
- Uses Accessibility API (AXUIElement) for menu bar scanning
- MenuBarExtra with window style for panel display
- UserDefaults for preference persistence
- ServiceManagement for Launch at Login

---

## Future Releases

### Planned Features
- Keyboard navigation
- Search/filter icons
- Custom icon groups
- Multiple profiles
- Actual icon image capture

### Under Consideration
- Menu bar overflow management
- Widget support

---

[1.1.0]: https://github.com/thejustinjames/MacTrayOrganiser/releases/tag/v1.1.0
[1.0.0]: https://github.com/thejustinjames/MacTrayOrganiser/releases/tag/v1.0.0
