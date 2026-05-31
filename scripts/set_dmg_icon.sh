#!/bin/bash

# Set custom icon on DMG file
DMG_PATH="dist/MacTrayOrganiser-1.0.0.dmg"
ICON_PATH="MacTrayOrganiser/AppIcon.icns"

if [ ! -f "$DMG_PATH" ] || [ ! -f "$ICON_PATH" ]; then
    echo "Error: DMG or icon file not found"
    exit 1
fi

# Create a temporary app bundle to hold the icon
TEMP_APP=$(mktemp -d)/IconSetter.app
mkdir -p "$TEMP_APP/Contents/Resources"
cp "$ICON_PATH" "$TEMP_APP/Contents/Resources/applet.icns"

cat > "$TEMP_APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIconFile</key>
    <string>applet.icns</string>
</dict>
</plist>
PLIST

# Use fileicon if available, otherwise use Python
if command -v fileicon &> /dev/null; then
    fileicon set "$DMG_PATH" "$ICON_PATH"
else
    # Use Python/PyObjC method
    python3 << PYTHON
import Cocoa
import os

icon_path = "$ICON_PATH"
dmg_path = "$DMG_PATH"

# Load the icon
icon = Cocoa.NSImage.alloc().initWithContentsOfFile_(icon_path)
if icon:
    workspace = Cocoa.NSWorkspace.sharedWorkspace()
    workspace.setIcon_forFile_options_(icon, dmg_path, 0)
    print(f"Icon set successfully on {dmg_path}")
else:
    print(f"Failed to load icon from {icon_path}")
PYTHON
fi

echo "Done setting icon on $DMG_PATH"
