//
//  AccessibilityService.swift
//  MacTrayOrganiser
//
//  Low-level wrapper for Accessibility API (AXUIElement)
//

import Foundation
import AppKit
import ApplicationServices

class AccessibilityService {
    static let shared = AccessibilityService()

    private init() {}

    // MARK: - System-Wide Element

    /// Get the system-wide accessibility element
    func getSystemWideElement() -> AXUIElement {
        return AXUIElementCreateSystemWide()
    }

    // MARK: - Attribute Retrieval

    /// Get an attribute value from an accessibility element
    func getAttribute<T>(_ element: AXUIElement, attribute: String) -> T? {
        var value: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

        guard result == .success else {
            return nil
        }

        return value as? T
    }

    /// Get multiple attribute values
    func getAttributes(_ element: AXUIElement, attributes: [String]) -> [String: Any] {
        var results: [String: Any] = [:]

        for attribute in attributes {
            var value: AnyObject?
            let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &value)

            if result == .success, let val = value {
                results[attribute] = val
            }
        }

        return results
    }

    /// Get the position of an element
    func getPosition(_ element: AXUIElement) -> CGPoint? {
        var position: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &position)

        guard result == .success,
              let positionValue = position,
              CFGetTypeID(positionValue) == AXValueGetTypeID(),
              AXValueGetType(positionValue as! AXValue) == .cgPoint else {
            return nil
        }

        var point = CGPoint.zero
        AXValueGetValue(positionValue as! AXValue, .cgPoint, &point)
        return point
    }

    /// Get the size of an element
    func getSize(_ element: AXUIElement) -> CGSize? {
        var size: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &size)

        guard result == .success,
              let sizeValue = size,
              CFGetTypeID(sizeValue) == AXValueGetTypeID(),
              AXValueGetType(sizeValue as! AXValue) == .cgSize else {
            return nil
        }

        var sizeRect = CGSize.zero
        AXValueGetValue(sizeValue as! AXValue, .cgSize, &sizeRect)
        return sizeRect
    }

    /// Get the title of an element
    func getTitle(_ element: AXUIElement) -> String? {
        return getAttribute(element, attribute: kAXTitleAttribute as String)
    }

    /// Get the role of an element
    func getRole(_ element: AXUIElement) -> String? {
        return getAttribute(element, attribute: kAXRoleAttribute as String)
    }

    /// Get the subrole of an element
    func getSubrole(_ element: AXUIElement) -> String? {
        return getAttribute(element, attribute: kAXSubroleAttribute as String)
    }

    /// Get the description of an element
    func getDescription(_ element: AXUIElement) -> String? {
        return getAttribute(element, attribute: kAXDescriptionAttribute as String)
    }

    /// Get the PID of the element's owning process
    func getPID(_ element: AXUIElement) -> pid_t? {
        var pid: pid_t = 0
        let result = AXUIElementGetPid(element, &pid)
        return result == .success ? pid : nil
    }

    // MARK: - Child Elements

    /// Get children of an element
    func getChildren(_ element: AXUIElement) -> [AXUIElement]? {
        var children: AnyObject?
        let result = AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children)

        guard result == .success,
              let childArray = children as? [AXUIElement] else {
            return nil
        }

        return childArray
    }

    /// Get the focused UI element
    func getFocusedElement(_ element: AXUIElement) -> AXUIElement? {
        return getAttribute(element, attribute: kAXFocusedUIElementAttribute as String)
    }

    // MARK: - Actions

    /// Perform an action on an element
    func performAction(_ element: AXUIElement, action: String) -> Bool {
        let result = AXUIElementPerformAction(element, action as CFString)
        return result == .success
    }

    /// Press/click an element
    func pressElement(_ element: AXUIElement) -> Bool {
        return performAction(element, action: kAXPressAction as String)
    }

    /// Show menu for an element
    func showMenu(_ element: AXUIElement) -> Bool {
        return performAction(element, action: kAXShowMenuAction as String)
    }

    // MARK: - Application Elements

    /// Get the accessibility element for an application by PID
    func getApplicationElement(pid: pid_t) -> AXUIElement {
        return AXUIElementCreateApplication(pid)
    }

    /// Get the menu bar element for an application
    func getMenuBar(for appElement: AXUIElement) -> AXUIElement? {
        return getAttribute(appElement, attribute: kAXMenuBarAttribute as String)
    }

    /// Get all running application PIDs
    func getRunningApplicationPIDs() -> [pid_t] {
        return NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular || $0.activationPolicy == .accessory }
            .map { $0.processIdentifier }
    }

    // MARK: - Menu Bar Extras

    /// Get the menu bar extras (status items) from the system UI Server
    func getMenuBarExtras() -> [AXUIElement] {
        // Find SystemUIServer process
        guard let systemUIServer = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.systemuiserver"
        ).first else {
            return []
        }

        let appElement = getApplicationElement(pid: systemUIServer.processIdentifier)

        // Get extras menu bar
        guard let menuBar: AXUIElement = getAttribute(appElement, attribute: kAXExtrasMenuBarAttribute as String) else {
            // Fallback to children approach
            return getMenuBarExtrasViaChildren(appElement)
        }

        guard let children = getChildren(menuBar) else {
            return []
        }

        return children
    }

    /// Fallback method to get menu bar extras via children
    private func getMenuBarExtrasViaChildren(_ appElement: AXUIElement) -> [AXUIElement] {
        guard let children = getChildren(appElement) else {
            return []
        }

        var extras: [AXUIElement] = []

        for child in children {
            let role = getRole(child)
            if role == kAXMenuBarRole as String {
                if let menuBarChildren = getChildren(child) {
                    extras.append(contentsOf: menuBarChildren)
                }
            }
        }

        return extras
    }

    // MARK: - ControlCenter items

    /// Get Control Center menu bar items
    func getControlCenterItems() -> [AXUIElement] {
        guard let controlCenter = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.controlcenter"
        ).first else {
            return []
        }

        let appElement = getApplicationElement(pid: controlCenter.processIdentifier)

        guard let menuBar: AXUIElement = getAttribute(appElement, attribute: kAXExtrasMenuBarAttribute as String),
              let children = getChildren(menuBar) else {
            return []
        }

        return children
    }
}
