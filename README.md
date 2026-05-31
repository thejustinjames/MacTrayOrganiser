# MacTrayOrganiser

A native macOS menu bar manager that allows you to view all menu bar icons (including those hidden by the notch or overflow) and organize them via drag-and-drop.

![macOS](https://img.shields.io/badge/macOS-13.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **See All Icons**: View all menu bar items, including those hidden by the notch
- **Click Through**: Click any icon in the panel to trigger its menu
- **Drag & Drop**: Reorder icons to your preference
- **Pin Favorites**: Keep your most-used icons at the top
- **Hide Items**: Remove clutter by hiding icons you don't need
- **Auto Refresh**: Automatically detects new menu bar items
- **Native macOS**: Built with Swift and SwiftUI for optimal performance

## Screenshots

*Coming soon*

## Installation

### Download DMG

1. Download the latest release from the [Releases](https://github.com/thejustinjames/MacTrayOrganiser/releases) page
2. Open the DMG file
3. Drag MacTrayOrganiser to your Applications folder
4. Launch MacTrayOrganiser from Applications
5. Grant Accessibility permission when prompted

### Build from Source

```bash
git clone https://github.com/thejustinjames/MacTrayOrganiser.git
cd MacTrayOrganiser
xcodebuild -project MacTrayOrganiser.xcodeproj -scheme MacTrayOrganiser -configuration Release build
```

## Requirements

- macOS 13.0 (Ventura) or later
- Accessibility permission (required to read menu bar items)

## Permissions

MacTrayOrganiser requires **Accessibility** permission to:
- Read menu bar item positions and titles
- Simulate clicks on menu bar items

The app will guide you through enabling this permission on first launch.

## Usage

1. Click the grid icon in your menu bar
2. View all your menu bar items in a organized grid
3. Click any icon to open its menu
4. Right-click to pin or hide items
5. Drag icons to reorder them

## Building

### Prerequisites
- Xcode 15.0+
- macOS 13.0+

### Steps
1. Open `MacTrayOrganiser.xcodeproj` in Xcode
2. Select your signing team (or disable signing for local builds)
3. Build and run (⌘R)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Author

Justin James - [@thejustinjames](https://github.com/thejustinjames)

## Acknowledgments

- Built with SwiftUI and AppKit
- Uses macOS Accessibility APIs
