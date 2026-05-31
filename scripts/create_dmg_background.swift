#!/usr/bin/env swift

import AppKit
import Foundation

// Create DMG background image
func createDMGBackground() -> NSImage {
    let width = 600
    let height = 400
    let image = NSImage(size: NSSize(width: width, height: height))

    image.lockFocus()

    // Draw gradient background
    let rect = NSRect(x: 0, y: 0, width: width, height: height)

    let gradient = NSGradient(colors: [
        NSColor(red: 0.12, green: 0.12, blue: 0.15, alpha: 1.0),
        NSColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)
    ])!
    gradient.draw(in: rect, angle: -90)

    // Draw app name
    let titleFont = NSFont.systemFont(ofSize: 28, weight: .bold)
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: titleFont,
        .foregroundColor: NSColor.white
    ]
    let title = "MacTrayOrganiser"
    let titleSize = title.size(withAttributes: titleAttributes)
    let titleX = (CGFloat(width) - titleSize.width) / 2
    title.draw(at: NSPoint(x: titleX, y: CGFloat(height) - 60), withAttributes: titleAttributes)

    // Draw subtitle
    let subtitleFont = NSFont.systemFont(ofSize: 14, weight: .regular)
    let subtitleAttributes: [NSAttributedString.Key: Any] = [
        .font: subtitleFont,
        .foregroundColor: NSColor(white: 0.7, alpha: 1.0)
    ]
    let subtitle = "Drag to Applications to install"
    let subtitleSize = subtitle.size(withAttributes: subtitleAttributes)
    let subtitleX = (CGFloat(width) - subtitleSize.width) / 2
    subtitle.draw(at: NSPoint(x: subtitleX, y: 60), withAttributes: subtitleAttributes)

    // Draw arrow
    let arrowPath = NSBezierPath()
    let arrowY = CGFloat(height) / 2 - 20
    let arrowStartX = CGFloat(width) / 2 - 60
    let arrowEndX = CGFloat(width) / 2 + 60

    arrowPath.move(to: NSPoint(x: arrowStartX, y: arrowY))
    arrowPath.line(to: NSPoint(x: arrowEndX - 15, y: arrowY))
    arrowPath.move(to: NSPoint(x: arrowEndX - 15, y: arrowY))
    arrowPath.line(to: NSPoint(x: arrowEndX - 30, y: arrowY + 10))
    arrowPath.move(to: NSPoint(x: arrowEndX - 15, y: arrowY))
    arrowPath.line(to: NSPoint(x: arrowEndX - 30, y: arrowY - 10))

    NSColor(white: 0.5, alpha: 1.0).setStroke()
    arrowPath.lineWidth = 2
    arrowPath.stroke()

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

let background = createDMGBackground()
saveImage(background, to: "dmg_background.png")
print("DMG background created")
