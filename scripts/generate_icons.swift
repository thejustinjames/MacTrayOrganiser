#!/usr/bin/env swift

import AppKit
import Foundation

// Create app icon with a gradient background and grid symbol
func createAppIcon(size: Int) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

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

    // Draw grid icon in white
    let iconSize = CGFloat(size) * 0.5
    let iconX = (CGFloat(size) - iconSize) / 2
    let iconY = (CGFloat(size) - iconSize) / 2
    let cellSize = iconSize / 2 - 2
    let gap: CGFloat = 4

    NSColor.white.setFill()

    // Top-left cell
    let cell1 = NSBezierPath(roundedRect: NSRect(x: iconX, y: iconY + cellSize + gap, width: cellSize, height: cellSize), xRadius: cellSize * 0.2, yRadius: cellSize * 0.2)
    cell1.fill()

    // Top-right cell
    let cell2 = NSBezierPath(roundedRect: NSRect(x: iconX + cellSize + gap, y: iconY + cellSize + gap, width: cellSize, height: cellSize), xRadius: cellSize * 0.2, yRadius: cellSize * 0.2)
    cell2.fill()

    // Bottom-left cell
    let cell3 = NSBezierPath(roundedRect: NSRect(x: iconX, y: iconY, width: cellSize, height: cellSize), xRadius: cellSize * 0.2, yRadius: cellSize * 0.2)
    cell3.fill()

    // Bottom-right cell
    let cell4 = NSBezierPath(roundedRect: NSRect(x: iconX + cellSize + gap, y: iconY, width: cellSize, height: cellSize), xRadius: cellSize * 0.2, yRadius: cellSize * 0.2)
    cell4.fill()

    image.unlockFocus()

    return image
}

// Save image as PNG
func saveImage(_ image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Saved: \(path)")
    } catch {
        print("Failed to save \(path): \(error)")
    }
}

// Icon sizes required for macOS app icons
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

if fm.fileExists(atPath: iconsetPath) {
    try? fm.removeItem(atPath: iconsetPath)
}
try! fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

// Generate all icon sizes
for (size, filename) in sizes {
    let icon = createAppIcon(size: size)
    saveImage(icon, to: "\(iconsetPath)/\(filename)")
}

print("Icon set created at \(iconsetPath)")
print("Run: iconutil -c icns AppIcon.iconset")
