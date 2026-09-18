#!/bin/bash

set -euo pipefail

APP_NAME="MacTrayOrganiser"
DMG_NAME="MacTrayOrganiser"
VERSION="1.1.0"
VOLUME_NAME="${APP_NAME}"
DMG_TEMP="${DMG_NAME}-temp.dmg"
DMG_FINAL="${DMG_NAME}-${VERSION}.dmg"
DIST_DIR="dist"
MOUNT_DIR="/Volumes/$VOLUME_NAME"

# All paths below are relative to the project root, wherever this is run from
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

DMG_CONTENTS=""

cleanup() {
    if [ -d "$MOUNT_DIR" ]; then
        hdiutil detach "$MOUNT_DIR" -quiet 2>/dev/null || hdiutil detach "$MOUNT_DIR" -force -quiet 2>/dev/null || true
    fi
    if [ -n "$DMG_CONTENTS" ] && [ -d "$DMG_CONTENTS" ]; then
        rm -rf "$DMG_CONTENTS"
    fi
    rm -f "$DIST_DIR/$DMG_TEMP"
}
trap cleanup EXIT

# Get the most recently built Release app
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/MacTrayOrganiser-*/Build/Products/Release -maxdepth 1 -name "MacTrayOrganiser.app" -type d 2>/dev/null | xargs -I{} stat -f '%m %N' {} | sort -rn | head -1 | cut -d' ' -f2-)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app. Please build the project first (Release configuration)."
    exit 1
fi

echo "Found app at: $APP_PATH"

# Create dist directory
mkdir -p "$DIST_DIR"
rm -f "$DIST_DIR/$DMG_FINAL"
rm -f "$DIST_DIR/$DMG_TEMP"

# Create a temporary directory for DMG contents
DMG_CONTENTS=$(mktemp -d)
echo "Creating DMG contents in: $DMG_CONTENTS"

# Copy the app
cp -R "$APP_PATH" "$DMG_CONTENTS/"

# Create Applications symlink
ln -s /Applications "$DMG_CONTENTS/Applications"

# Copy background, generating it if not present
mkdir -p "$DMG_CONTENTS/.background"
if [ ! -f "dmg_background.png" ]; then
    swift scripts/create_dmg_background.swift
fi
cp dmg_background.png "$DMG_CONTENTS/.background/background.png"

# Copy volume icon (use app icon)
ICON_PATH="MacTrayOrganiser/AppIcon.icns"
if [ -f "$ICON_PATH" ]; then
    cp "$ICON_PATH" "$DMG_CONTENTS/.VolumeIcon.icns"
fi

# Calculate size needed (app size + 50MB buffer)
APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))

echo "Creating DMG of size ${DMG_SIZE}MB..."

# Create temporary DMG
hdiutil create -srcfolder "$DMG_CONTENTS" -volname "$VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DMG_SIZE}m "$DIST_DIR/$DMG_TEMP"

# Mount the DMG
echo "Mounting DMG..."

# Unmount if already mounted
if [ -d "$MOUNT_DIR" ]; then
    hdiutil detach "$MOUNT_DIR" -quiet || true
fi

hdiutil attach "$DIST_DIR/$DMG_TEMP" -readwrite -noverify -noautoopen

# Give Finder a moment to notice the volume
sleep 2

# Set window properties using AppleScript
echo "Setting DMG window properties..."
osascript <<EOS
tell application "Finder"
    tell disk "$VOLUME_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set bounds of container window to {100, 100, 700, 500}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 100
        set background picture of theViewOptions to file ".background:background.png"
        set position of item "${APP_NAME}.app" of container window to {150, 200}
        set position of item "Applications" of container window to {450, 200}
        close
        open
        update without registering applications
        delay 2
        close
    end tell
end tell
EOS

# Set volume icon. SetFile ships with the Xcode command line tools and is not
# guaranteed to exist, so skip the custom icon rather than abort.
if [ -f "$MOUNT_DIR/.VolumeIcon.icns" ]; then
    if command -v SetFile >/dev/null 2>&1; then
        SetFile -c icnC "$MOUNT_DIR/.VolumeIcon.icns"
        SetFile -a C "$MOUNT_DIR"
    else
        echo "Warning: SetFile not found; the DMG volume will not have a custom icon."
    fi
fi

# Finalize the DMG
sync
hdiutil detach "$MOUNT_DIR" || { sleep 2; hdiutil detach "$MOUNT_DIR" -force; }

echo "Converting to compressed DMG..."
hdiutil convert "$DIST_DIR/$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DIST_DIR/$DMG_FINAL"

# Set icon on DMG file itself
echo "Setting DMG file icon..."
"$SCRIPT_DIR/set_dmg_icon.sh" "$DIST_DIR/$DMG_FINAL"

echo ""
echo "DMG created successfully: $DIST_DIR/$DMG_FINAL"
ls -lh "$DIST_DIR/$DMG_FINAL"
