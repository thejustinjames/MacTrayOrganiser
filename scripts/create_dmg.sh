#!/bin/bash

set -e

APP_NAME="MacTrayOrganiser"
DMG_NAME="MacTrayOrganiser"
VERSION="1.0.0"
VOLUME_NAME="${APP_NAME}"
DMG_TEMP="${DMG_NAME}-temp.dmg"
DMG_FINAL="${DMG_NAME}-${VERSION}.dmg"
DIST_DIR="dist"

# Get the built app path
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/MacTrayOrganiser-*/Build/Products/Release -name "MacTrayOrganiser.app" -type d 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app. Please build the project first."
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

# Copy background
mkdir -p "$DMG_CONTENTS/.background"
cp dmg_background.png "$DMG_CONTENTS/.background/background.png"

# Calculate size needed (app size + 50MB buffer)
APP_SIZE=$(du -sm "$APP_PATH" | cut -f1)
DMG_SIZE=$((APP_SIZE + 50))

echo "Creating DMG of size ${DMG_SIZE}MB..."

# Create temporary DMG
hdiutil create -srcfolder "$DMG_CONTENTS" -volname "$VOLUME_NAME" -fs HFS+ -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${DMG_SIZE}m "$DIST_DIR/$DMG_TEMP"

# Mount the DMG
echo "Mounting DMG..."
MOUNT_DIR="/Volumes/$VOLUME_NAME"

# Unmount if already mounted
if [ -d "$MOUNT_DIR" ]; then
    hdiutil detach "$MOUNT_DIR" -quiet || true
fi

hdiutil attach "$DIST_DIR/$DMG_TEMP" -readwrite -noverify -noautoopen

# Wait for mount
sleep 2

# Set window properties using AppleScript
echo "Setting DMG window properties..."
osascript <<EOF
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
EOF

# Finalize the DMG
sync
hdiutil detach "$MOUNT_DIR"

echo "Converting to compressed DMG..."
hdiutil convert "$DIST_DIR/$DMG_TEMP" -format UDZO -imagekey zlib-level=9 -o "$DIST_DIR/$DMG_FINAL"

# Cleanup
rm -f "$DIST_DIR/$DMG_TEMP"
rm -rf "$DMG_CONTENTS"

echo ""
echo "DMG created successfully: $DIST_DIR/$DMG_FINAL"
ls -lh "$DIST_DIR/$DMG_FINAL"
