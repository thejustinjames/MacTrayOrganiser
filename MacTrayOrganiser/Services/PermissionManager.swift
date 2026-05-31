//
//  PermissionManager.swift
//  MacTrayOrganiser
//
//  Handles Accessibility and other permission requests
//

import Foundation
import AppKit
import ApplicationServices

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published var hasAccessibilityPermission: Bool = false
    @Published var showOnboarding: Bool = false

    private var permissionCheckTimer: Timer?

    private init() {
        hasAccessibilityPermission = checkAccessibilityPermission()
        startPermissionMonitoring()
    }

    deinit {
        permissionCheckTimer?.invalidate()
    }

    // MARK: - Accessibility Permission

    /// Check if the app has Accessibility permission
    func checkAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        DispatchQueue.main.async {
            self.hasAccessibilityPermission = trusted
        }
        return trusted
    }

    /// Prompt the user to grant Accessibility permission
    func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)

        // Start checking more frequently after requesting
        startPermissionMonitoring(interval: 1.0)
    }

    /// Open System Settings to the Accessibility pane
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Open System Settings to the Privacy & Security pane
    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security") {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Permission Monitoring

    private func startPermissionMonitoring(interval: TimeInterval = 5.0) {
        permissionCheckTimer?.invalidate()
        permissionCheckTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkAndUpdatePermission()
        }
    }

    private func checkAndUpdatePermission() {
        let wasGranted = hasAccessibilityPermission
        let isGranted = checkAccessibilityPermission()

        if !wasGranted && isGranted {
            // Permission was just granted
            DispatchQueue.main.async {
                self.showOnboarding = false
            }
            // Slow down monitoring now that we have permission
            startPermissionMonitoring(interval: 30.0)

            // Notify the app that permissions changed
            NotificationCenter.default.post(
                name: .accessibilityPermissionGranted,
                object: nil
            )
        } else if wasGranted && !isGranted {
            // Permission was revoked
            NotificationCenter.default.post(
                name: .accessibilityPermissionRevoked,
                object: nil
            )
        }
    }

    // MARK: - Screen Recording Permission (Optional)

    /// Check if screen recording permission is available
    /// This is needed for capturing actual icon images
    @available(macOS 12.3, *)
    func checkScreenRecordingPermission() async -> Bool {
        // Use ScreenCaptureKit to check permission
        do {
            _ = try await SCShareableContent.current
            return true
        } catch {
            return false
        }
    }
}

import ScreenCaptureKit

// MARK: - Notification Names

extension Notification.Name {
    static let accessibilityPermissionGranted = Notification.Name("accessibilityPermissionGranted")
    static let accessibilityPermissionRevoked = Notification.Name("accessibilityPermissionRevoked")
}
