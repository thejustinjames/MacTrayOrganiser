# MacTrayOrganiser

<p align="center">
  <img src="MacTrayOrganiser/Assets.xcassets/AppIcon.appiconset/icon_256x256.png" alt="MacTrayOrganiser Icon" width="128" height="128">
</p>

<p align="center">
  <strong>A native macOS menu bar manager</strong><br>
  View and organize all your menu bar icons, including those hidden by the notch
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13.0+-blue?style=flat-square" alt="macOS 13.0+">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License">
  <img src="https://img.shields.io/github/v/release/thejustinjames/MacTrayOrganiser?style=flat-square" alt="Latest Release">
</p>

---

## ✨ Features

- **📱 See All Icons** — View every menu bar item, including those hidden behind the notch or in overflow
- **👆 Click Through** — Click any icon in the panel to activate its menu
- **🔀 Drag & Drop** — Reorder icons to your preference within the panel
- **📌 Pin Favorites** — Keep your most-used icons at the top
- **👁️ Hide Clutter** — Hide icons you rarely use (still accessible in Hidden tab)
- **🔄 Auto Refresh** — Automatically detects new menu bar items
- **⚙️ Customizable** — Adjust grid size, labels, refresh interval, and more
- **🚀 Native Performance** — Built with Swift and SwiftUI for optimal performance

---

## 📥 Installation

### Download
1. Download the latest DMG from the [Releases](https://github.com/thejustinjames/MacTrayOrganiser/releases) page
2. Open the DMG file
3. Drag **MacTrayOrganiser** to your **Applications** folder
4. Launch from Applications

### Grant Permission
On first launch, you'll need to grant Accessibility permission:
1. Click **"Open System Settings"** when prompted
2. Navigate to **Privacy & Security → Accessibility**
3. Toggle **MacTrayOrganiser** to ON

> **Why?** Accessibility permission allows the app to read menu bar item positions and simulate clicks.

---

## 🖥️ Usage

### Finding the App
MacTrayOrganiser lives in your **menu bar** (top of screen), not the Dock. Look for the **grid icon (⊞)** near your other menu bar icons.

### Basic Usage
1. **Click** the grid icon to open the panel
2. **Click** any icon to activate it
3. **Right-click** an icon to pin or hide it
4. **Drag** icons to reorder them

### Reordering in macOS Menu Bar
To move icons in the actual macOS menu bar:
- Hold **⌘ Command** and **drag** the icon to a new position

### Tabs
| Tab | Description |
|-----|-------------|
| **All** | All visible menu bar items |
| **Pinned** | Your pinned favorites |
| **Hidden** | Items you've hidden |

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [User Guide](dist/USER_GUIDE.md) | Complete user documentation |
| [Architecture](ARCHITECTURE.md) | Technical architecture overview |
| [Contributing](CONTRIBUTING.md) | Contribution guidelines |
| [Changelog](CHANGELOG.md) | Version history |

---

## 🛠️ Building from Source

### Requirements
- macOS 13.0+
- Xcode 15.0+

### Build
```bash
git clone https://github.com/thejustinjames/MacTrayOrganiser.git
cd MacTrayOrganiser
xcodebuild -project MacTrayOrganiser.xcodeproj -scheme MacTrayOrganiser -configuration Release build
```

### Create DMG
```bash
./scripts/create_dmg.sh
```

---

## 🏗️ Project Structure

```
MacTrayOrganiser/
├── MacTrayOrganiserApp.swift   # App entry point
├── Models/                     # Data models
│   ├── MenuBarItem.swift       # Menu bar item model
│   └── AppSettings.swift       # User preferences
├── Services/                   # Business logic
│   ├── AccessibilityService.swift
│   ├── MenuBarScanner.swift
│   └── PermissionManager.swift
├── Views/                      # SwiftUI views
│   ├── MenuBarView.swift
│   ├── IconGridView.swift
│   └── ...
└── Utilities/                  # Helpers
    └── ImageCapture.swift
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for detailed technical documentation.

---

## 🤝 Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Start
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📋 Requirements

- **macOS 13.0** (Ventura) or later
- **Accessibility permission** (required)

---

## 🔒 Privacy

- ✅ Works entirely offline
- ✅ No data collection or analytics
- ✅ No network requests
- ✅ Preferences stored locally

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Justin James** — [@thejustinjames](https://github.com/thejustinjames)

---

## 🙏 Acknowledgments

- Built with Swift and SwiftUI
- Uses macOS Accessibility APIs
- Icon design inspired by SF Symbols

---

<p align="center">
  Made with ❤️ for the Mac community
</p>
