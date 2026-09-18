#!/usr/bin/env swift

import AppKit
import Foundation

// Create app icon with a gradient background and grid symbol.
//
// Renders into a bitmap of exactly `size` pixels. Drawing into an NSImage
// with lockFocus() would pick up the current display's backing scale and
// produce files twice the requested size on a Retina Mac.
func createAppIcon(size: Int) -> Data? {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    ) else {
        return nil
    }
    rep.size = NSSize(width: size, height: size)

    guard let context = NSGraphicsContext(bitmapImageRep: rep) else {
        return nil
    }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = context

    // Draw rounded rectangle background with gradient
    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = CGFloat(size) * 0.22
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)

    // Gradient from blue to purple
    let gradient = NSGradient(colors: [
        NSColor(red: 0.4, green: 0.5, blue: 1.0, alpha: 1.0),
        NSColor(red: 0.6, green: 0.3, blue: 0.9, alpha: 1.0)
    ])!
    gradient.draw(in: path, angle: -45)

    // Draw grid icon in white. The gap scales with the icon so every size
    // has the same proportions.
    let iconSize = CGFloat(size) * 0.5
    let iconX = (CGFloat(size) - iconSize) / 2
    let iconY = (CGFloat(size) - iconSize) / 2
    let gap = max(1, CGFloat(size) / 64)
    let cellSize = (iconSize - gap) / 2

    NSColor.white.setFill()

    let cells = [
        NSRect(x: iconX, y: iconY + cellSize + gap, width: cellSize, height: cellSize),                  // top-left
        NSRect(x: iconX + cellSize + gap, y: iconY + cellSize + gap, width: cellSize, height: cellSize), // top-right
        NSRect(x: iconX, y: iconY, width: cellSize, height: cellSize),                                   // bottom-left
        NSRect(x: iconX + cellSize + gap, y: iconY, width: cellSize, height: cellSize)                   // bottom-right
    ]
    for cell in cells {
        NSBezierPath(roundedRect: cell, xRadius: cellSize * 0.2, yRadius: cellSize * 0.2).fill()
    }

    context.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    return rep.representation(using: .png, properties: [:])
}

// Save PNG data
func savePNG(_ data: Data?, to path: String) -> Bool {
    guard let data else {
        print("Failed to create PNG data for \(path)")
        return false
    }

    do {
        try data.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path)")
        return true
    } catch {
        print("Failed to save \(path): \(error)")
        return false
    }
}

// Icon sizes required for macOS app icons (pixel size, file name)
let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

// Create iconset directory
let iconsetPath = "AppIcon.iconset"
let fm = FileManager.default

do {
    if fm.fileExists(atPath: iconsetPath) {
        try fm.removeItem(atPath: iconsetPath)
    }
    try fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)
} catch {
    print("Failed to prepare \(iconsetPath): \(error)")
    exit(1)
}

// Generate all icon sizes
var failed = false
for (size, filename) in sizes {
    if !savePNG(createAppIcon(size: size), to: "\(iconsetPath)/\(filename)") {
        failed = true
    }
}

if failed {
    exit(1)
}

print("Icon set created at \(iconsetPath)")
print("Run: iconutil -c icns AppIcon.iconset")
