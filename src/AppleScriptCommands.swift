import Cocoa
import CryptoKit

// MARK: - Notification

extension Notification.Name {
    static let iCHSShortcutsDidChange = Notification.Name("iCHSShortcutsDidChange")
}

// MARK: - ShortcutConfig ID extension

extension ShortcutConfig {
    /// Unique ID calculated as SHA1(action + command), first 10 hex characters.
    /// If multiple shortcuts produce the same ID, the first match wins.
    var uid: String {
        let input = action + command
        let digest = Insecure.SHA1.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined().prefix(10).lowercased()
    }
}

// MARK: - AppleScript error helpers

/// Apple Event error: object not found (-1728 / errAENoSuchObject)
private let errASNoSuchObject = -1728

/// Apple Event error: missing or invalid parameter (-50 / paramErr)
private let errASInvalidParam = -50

private func reportError(_ command: NSScriptCommand, number: Int, message: String) {
    command.scriptErrorNumber = number
    command.scriptErrorString = message
}

// MARK: - Lookup helpers

private func findShortcutIndexByAction(_ action: String) -> Int? {
    ConfigManager.shared.config.shortcuts.firstIndex {
        !$0.action.isEmpty && $0.action == action
    }
}

private func findShortcutIndexByID(_ id: String) -> Int? {
    ConfigManager.shared.config.shortcuts.firstIndex {
        $0.uid == id
    }
}

private func findShortcutIndexByShortcut(_ shortcut: String) -> Int? {
    ConfigManager.shared.config.shortcuts.firstIndex {
        !$0.shortcut.isEmpty && $0.shortcut == shortcut
    }
}

// MARK: - State change helpers

private func applyStateChange(at index: Int, enabled: Bool) {
    let shortcuts = ConfigManager.shared.config.shortcuts
    guard index >= 0, index < shortcuts.count else { return }

    let shortcut = shortcuts[index]
    guard shortcut.enabled != enabled else { return }

    ConfigManager.shared.config.shortcuts[index].enabled = enabled
    ConfigManager.shared.save()

    guard let appDelegate = NSApp.delegate as? AppDelegate else { return }

    if enabled {
        _ = appDelegate.registerShortcut(at: index)
    } else {
        appDelegate.unregisterShortcut(at: index)
    }

    appDelegate.rebuildMenu()
    NotificationCenter.default.post(name: .iCHSShortcutsDidChange, object: nil)
}

private func triggerShortcut(at index: Int) {
    let shortcuts = ConfigManager.shared.config.shortcuts
    guard index >= 0, index < shortcuts.count else { return }
    guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
    appDelegate.runShortcut(shortcuts[index])
}

// MARK: - Action-based commands

@objc(ASEnableAction)
class ASEnableAction: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let action = directParameter as? String, !action.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Action name is required")
            return nil
        }
        guard let index = findShortcutIndexByAction(action) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with action \"\(action)\"")
            return nil
        }
        applyStateChange(at: index, enabled: true)
        return nil
    }
}

@objc(ASDisableAction)
class ASDisableAction: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let action = directParameter as? String, !action.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Action name is required")
            return nil
        }
        guard let index = findShortcutIndexByAction(action) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with action \"\(action)\"")
            return nil
        }
        applyStateChange(at: index, enabled: false)
        return nil
    }
}

@objc(ASToggleAction)
class ASToggleAction: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let action = directParameter as? String, !action.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Action name is required")
            return nil
        }
        guard let index = findShortcutIndexByAction(action) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with action \"\(action)\"")
            return nil
        }
        let current = ConfigManager.shared.config.shortcuts[index].enabled
        applyStateChange(at: index, enabled: !current)
        return nil
    }
}

@objc(ASTriggerAction)
class ASTriggerAction: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let action = directParameter as? String, !action.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Action name is required")
            return nil
        }
        guard let index = findShortcutIndexByAction(action) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with action \"\(action)\"")
            return nil
        }
        triggerShortcut(at: index)
        return nil
    }
}

// MARK: - ID-based commands

@objc(ASEnableID)
class ASEnableID: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let id = directParameter as? String, !id.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Shortcut ID is required")
            return nil
        }
        guard let index = findShortcutIndexByID(id) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with ID \"\(id)\"")
            return nil
        }
        applyStateChange(at: index, enabled: true)
        return nil
    }
}

@objc(ASDisableID)
class ASDisableID: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let id = directParameter as? String, !id.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Shortcut ID is required")
            return nil
        }
        guard let index = findShortcutIndexByID(id) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with ID \"\(id)\"")
            return nil
        }
        applyStateChange(at: index, enabled: false)
        return nil
    }
}

@objc(ASToggleID)
class ASToggleID: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let id = directParameter as? String, !id.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Shortcut ID is required")
            return nil
        }
        guard let index = findShortcutIndexByID(id) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with ID \"\(id)\"")
            return nil
        }
        let current = ConfigManager.shared.config.shortcuts[index].enabled
        applyStateChange(at: index, enabled: !current)
        return nil
    }
}

@objc(ASTriggerID)
class ASTriggerID: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let id = directParameter as? String, !id.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Shortcut ID is required")
            return nil
        }
        guard let index = findShortcutIndexByID(id) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with ID \"\(id)\"")
            return nil
        }
        triggerShortcut(at: index)
        return nil
    }
}

// MARK: - Shortcut-based commands

@objc(ASEnableShortcut)
class ASEnableShortcut: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let shortcut = directParameter as? String, !shortcut.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Shortcut key combination is required")
            return nil
        }
        guard let index = findShortcutIndexByShortcut(shortcut) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with key combination \"\(shortcut)\"")
            return nil
        }
        applyStateChange(at: index, enabled: true)
        return nil
    }
}

@objc(ASDisableShortcut)
class ASDisableShortcut: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let shortcut = directParameter as? String, !shortcut.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Shortcut key combination is required")
            return nil
        }
        guard let index = findShortcutIndexByShortcut(shortcut) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with key combination \"\(shortcut)\"")
            return nil
        }
        applyStateChange(at: index, enabled: false)
        return nil
    }
}

@objc(ASToggleShortcut)
class ASToggleShortcut: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let shortcut = directParameter as? String, !shortcut.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Shortcut key combination is required")
            return nil
        }
        guard let index = findShortcutIndexByShortcut(shortcut) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with key combination \"\(shortcut)\"")
            return nil
        }
        let current = ConfigManager.shared.config.shortcuts[index].enabled
        applyStateChange(at: index, enabled: !current)
        return nil
    }
}

@objc(ASTriggerShortcut)
class ASTriggerShortcut: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        guard let shortcut = directParameter as? String, !shortcut.isEmpty else {
            reportError(self, number: errASInvalidParam, message: "Shortcut key combination is required")
            return nil
        }
        guard let index = findShortcutIndexByShortcut(shortcut) else {
            reportError(self, number: errASNoSuchObject, message: "No shortcut found with key combination \"\(shortcut)\"")
            return nil
        }
        triggerShortcut(at: index)
        return nil
    }
}

// MARK: - List commands

@objc(ASListShortcuts)
class ASListShortcuts: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let shortcuts = ConfigManager.shared.config.shortcuts
        let lines = shortcuts.map { s in
            let state = s.enabled ? "enabled" : "disabled"
            return "\(s.uid)\t\(state)\t\(s.shortcut)\t\(s.category)\t\(s.action)\t\(s.command)"
        }
        return lines.joined(separator: "\n")
    }
}

@objc(ASListJSONShortcuts)
class ASListJSONShortcuts: NSScriptCommand {
    override func performDefaultImplementation() -> Any? {
        let shortcuts = ConfigManager.shared.config.shortcuts
        let entries: [[String: String]] = shortcuts.map { s in
            [
                "id": s.uid,
                "state": s.enabled ? "enabled" : "disabled",
                "shortcut": s.shortcut,
                "category": s.category,
                "action": s.action,
                "command": s.command,
            ]
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: entries, options: [.sortedKeys])
            return String(data: data, encoding: .utf8)
        } catch {
            return "[]"
        }
    }
}
