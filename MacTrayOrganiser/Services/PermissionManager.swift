//
//  PermissionManager.swift
//  MacTrayOrganiser
//
//  Handles Accessibility and other permission requests
//

import Foundation
import AppKit
import ApplicationServices
import ScreenCaptureKit

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    @Published private(set) var hasAccessibilityPermission: Bool = false

    private var permissionCheckTimer: Timer?
    private let hasPromptedKey = "hasPromptedForAccessibility"

    private init() {
        hasAccessibilityPermission = AXIsProcessTrusted()
        startPermissionMonitoring(interval: hasAccessibilityPermission ? 30.0 : 5.0)
    }

    deinit {
        permissionCheckTimer?.invalidate()
    }

    // MARK: - Accessibility Permission

    /// Check if the app has Accessibility permission and publish the result.
    /// The published value is updated synchronously when called on the main
    /// thread so callers can rely on it straight after the call.
    @discardableResult
    func checkAccessibilityPermission() -> Bool {
        let trusted = AXIsProcessTrusted()
        if Thread.isMainThread {
            updatePermissionState(trusted)
        } else {
            DispatchQueue.main.async { self.updatePermissionState(trusted) }
        }
        return trusted
    }

    /// Prompt the user to grant Accessibility permission.
    ///
    /// macOS only shows its own prompt once per app, so after the first
    /// request this opens the Accessibility pane directly instead of
    /// appearing to do nothing.
    func requestAccessibilityPermission() {
        guard !checkAccessibilityPermission() else { return }

        let defaults = UserDefaults.standard
        if defaults.bool(forKey: hasPromptedKey) {
            openAccessibilitySettings()
        } else {
            defaults.set(true, forKey: hasPromptedKey)
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }

        // Check more frequently while the user is in System Settings
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

    private func startPermissionMonitoring(interval: TimeInterval) {
        permissionCheckTimer?.invalidate()
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkAccessibilityPermission()
        }
        timer.tolerance = interval * 0.2
        permissionCheckTimer = timer
    }

    /// Runs on the main thread. Publishes the new state and notifies
    /// listeners only when it actually changed.
    private func updatePermissionState(_ trusted: Bool) {
        guard trusted != hasAccessibilityPermission else { return }
        hasAccessibilityPermission = trusted

        if trusted {
            // Slow down monitoring now that we have permission
            startPermissionMonitoring(interval: 30.0)
            NotificationCenter.default.post(name: .accessibilityPermissionGranted, object: nil)
        } else {
            startPermissionMonitoring(interval: 5.0)
            NotificationCenter.default.post(name: .accessibilityPermissionRevoked, object: nil)
        }
    }

    // MARK: - Screen Recording Permission (Optional)

    /// Check if screen recording permission is available.
    /// This is needed for capturing actual icon images. Note that asking
    /// triggers the system's Screen Recording prompt the first time.
    func checkScreenRecordingPermission() async -> Bool {
        do {
            _ = try await SCShareableContent.current
            return true
        } catch {
            return false
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let accessibilityPermissionGranted = Notification.Name("accessibilityPermissionGranted")
    static let accessibilityPermissionRevoked = Notification.Name("accessibilityPermissionRevoked")
}
