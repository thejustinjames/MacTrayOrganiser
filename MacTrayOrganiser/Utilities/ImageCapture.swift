//
//  ImageCapture.swift
//  MacTrayOrganiser
//
//  Capture icon images from menu bar items
//

import Foundation
import AppKit
import ScreenCaptureKit

class ImageCapture {
    static let shared = ImageCapture()

    private init() {}

    /// Capture an image of a specific screen region
    /// Uses ScreenCaptureKit for macOS 12.3+
    @available(macOS 12.3, *)
    func captureRegion(rect: CGRect) async throws -> NSImage? {
        // Get available content
        let content = try await SCShareableContent.current

        // Find the main display
        guard let display = content.displays.first else {
            return nil
        }

        // Create a filter for just the display (no windows)
        let filter = SCContentFilter(display: display, excludingWindows: [])

        // Configure the stream for a single frame
        let config = SCStreamConfiguration()
        config.width = Int(rect.width * 2) // Retina
        config.height = Int(rect.height * 2)
        config.sourceRect = rect
        config.scalesToFit = false
        config.showsCursor = false

        // Capture a single frame
        let image = try await captureFrame(filter: filter, config: config)
        return image
    }

    @available(macOS 12.3, *)
    private func captureFrame(filter: SCContentFilter, config: SCStreamConfiguration) async throws -> NSImage? {
        return try await withCheckedThrowingContinuation { continuation in
            let stream = SCStream(filter: filter, configuration: config, delegate: nil)

            class OutputHandler: NSObject, SCStreamOutput {
                var continuation: CheckedContinuation<NSImage?, Error>?
                var didCapture = false

                func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
                    guard !didCapture, type == .screen else { return }
                    didCapture = true

                    if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
                        let ciImage = CIImage(cvImageBuffer: imageBuffer)
                        let rep = NSCIImageRep(ciImage: ciImage)
                        let nsImage = NSImage(size: rep.size)
                        nsImage.addRepresentation(rep)
                        continuation?.resume(returning: nsImage)
                    } else {
                        continuation?.resume(returning: nil)
                    }
                    continuation = nil

                    Task {
                        try? await stream.stopCapture()
                    }
                }
            }

            let handler = OutputHandler()
            handler.continuation = continuation

            Task {
                do {
                    try stream.addStreamOutput(handler, type: .screen, sampleHandlerQueue: .main)
                    try await stream.startCapture()

                    // Timeout after 1 second
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    if !handler.didCapture {
                        try await stream.stopCapture()
                        handler.continuation?.resume(returning: nil)
                        handler.continuation = nil
                    }
                } catch {
                    handler.continuation?.resume(throwing: error)
                    handler.continuation = nil
                }
            }
        }
    }

    /// Capture icon for a menu bar item using its position and size
    func captureMenuBarIcon(position: CGPoint, size: CGSize) async -> NSImage? {
        guard #available(macOS 12.3, *) else {
            return nil
        }

        // Menu bar is at the top of the screen
        // Need to account for screen coordinate system
        guard let screen = NSScreen.main else { return nil }

        let screenHeight = screen.frame.height
        let captureRect = CGRect(
            x: position.x,
            y: screenHeight - position.y - size.height,
            width: size.width,
            height: size.height
        )

        return try? await captureRegion(rect: captureRect)
    }

    /// Get an icon from a running application by PID
    func getAppIcon(pid: pid_t) -> NSImage? {
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            return nil
        }
        return app.icon
    }

    /// Get an icon from a bundle identifier
    func getAppIcon(bundleIdentifier: String) -> NSImage? {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return nil
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
}
