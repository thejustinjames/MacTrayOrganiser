# Changelog

All notable changes to MacTrayOrganiser will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
- Active icon hiding (moving icons off-screen)
- Menu bar overflow management
- Widget support

---

[1.0.0]: https://github.com/thejustinjames/MacTrayOrganiser/releases/tag/v1.0.0
