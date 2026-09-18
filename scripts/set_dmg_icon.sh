#!/bin/bash

# Set the app icon as the Finder icon of a DMG file.
# Usage: scripts/set_dmg_icon.sh [path/to/file.dmg]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

DMG_PATH="${1:-dist/MacTrayOrganiser-1.1.0.dmg}"
ICON_PATH="MacTrayOrganiser/AppIcon.icns"

if [ ! -f "$DMG_PATH" ]; then
    echo "Error: DMG not found at $DMG_PATH"
    exit 1
fi

if [ ! -f "$ICON_PATH" ]; then
    echo "Error: icon not found at $ICON_PATH"
    exit 1
fi

# Absolute paths for the AppKit calls below
DMG_ABS="$(cd "$(dirname "$DMG_PATH")" && pwd)/$(basename "$DMG_PATH")"
ICON_ABS="$PROJECT_DIR/$ICON_PATH"

# Use fileicon if available, otherwise AppKit via osascript (no extra
# dependencies; the previous Python route needed PyObjC, which the system
# python3 does not ship with).
if command -v fileicon >/dev/null 2>&1; then
    fileicon set "$DMG_ABS" "$ICON_ABS"
else
    osascript <<APPLESCRIPT
use framework "AppKit"
set theImage to current application's NSImage's alloc()'s initWithContentsOfFile:"$ICON_ABS"
if theImage is missing value then error "Could not load icon from $ICON_ABS"
set ok to current application's NSWorkspace's sharedWorkspace()'s setIcon:theImage forFile:"$DMG_ABS" options:0
if not ok then error "NSWorkspace refused to set the icon on $DMG_ABS"
APPLESCRIPT
fi

echo "Done setting icon on $DMG_PATH"
