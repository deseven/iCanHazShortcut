import Foundation
import Cocoa
import TOML

// MARK: - INI Parser

/// A simple INI file parser that handles the specific format used by the old
/// iCanHazShortcut config. Supports section headers, key=value pairs, BOM,
/// comments (# or ;), and empty values.
class INIParser {
    struct INIFile {
        var sections: [String: [String: String]] = [:]
        /// Preserves the order sections appear in the file
        var sectionOrder: [String] = []
    }

    /// Parse an INI file at the given URL.
    static func parse(fileAt url: URL) throws -> INIFile {
        let content = try String(contentsOf: url, encoding: .utf8)
        return parse(content: content)
    }

    /// Parse an INI-formatted string.
    static func parse(content: String) -> INIFile {
        var result = INIFile()
        var currentSection = ""

        // Strip UTF-8 BOM if present
        var content = content
        if content.hasPrefix("\u{FEFF}") {
            content = String(content.dropFirst())
        }

        for line in content.components(separatedBy: .newlines) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            if trimmed.isEmpty || trimmed.hasPrefix("#") || trimmed.hasPrefix(";") {
                continue
            }

            // Section header: [section_name]
            if trimmed.hasPrefix("[") && trimmed.hasSuffix("]") {
                currentSection = String(trimmed.dropFirst().dropLast())
                    .trimmingCharacters(in: .whitespaces)
                if result.sections[currentSection] == nil {
                    result.sections[currentSection] = [:]
                    result.sectionOrder.append(currentSection)
                }
                continue
            }

            // Key-value pair: key = value (split on first '=' only)
            if let separatorRange = trimmed.range(of: "=", options: .literal) {
                let key = String(trimmed[..<separatorRange.lowerBound])
                    .trimmingCharacters(in: .whitespaces)
                let value = String(trimmed[separatorRange.upperBound...])
                    .trimmingCharacters(in: .whitespaces)

                if result.sections[currentSection] == nil {
                    result.sections[currentSection] = [:]
                    result.sectionOrder.append(currentSection)
                }
                result.sections[currentSection]?[key] = value
            }
        }

        return result
    }
}

// MARK: - Config Migrator

/// Handles migration from the old INI-based config format
/// (`~/.config/iCanHazShortcut/config.ini`) to the new TOML format
/// stored in Application Support.
class ConfigMigrator {

    // MARK: - Old config paths

    /// Path to the old config file: `~/.config/iCanHazShortcut/config.ini`
    static var oldConfigPath: URL {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent(".config/iCanHazShortcut/config.ini")
    }

    /// Path to the old config directory: `~/.config/iCanHazShortcut`
    static var oldConfigDir: URL {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        return homeDir.appendingPathComponent(".config/iCanHazShortcut")
    }

    /// Check whether the old config file exists.
    static func oldConfigExists() -> Bool {
        return FileManager.default.fileExists(atPath: oldConfigPath.path)
    }

    // MARK: - Migration flow (with UI dialogs)

    /// Present the migration choice to the user and handle the outcome.
    /// Returns `true` if the app should continue, `false` if it should exit
    /// (migration failed and the user acknowledged the error).
    static func handleMigration() -> Bool {
        // Temporarily switch to regular mode so dialogs can receive focus
        // (accessory mode apps can't be activated or focused)
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Show migration choice dialog
        let alert = NSAlert()
        alert.messageText = "A config file from the previous version was found in\n\(oldConfigPath.path)"
        alert.informativeText = "Would you like to migrate it to the new version or start from scratch?"
        alert.alertStyle = .informational

        // First button added is the default (rightmost on macOS)
        let migrateButton = alert.addButton(withTitle: "Migrate")
        alert.addButton(withTitle: "Start from scratch")
        migrateButton.keyEquivalent = "\r"

        let response = alert.runModal()

        let result: Bool
        if response == .alertFirstButtonReturn {
            // User chose "Migrate"
            result = performMigration()
        } else {
            // User chose "Start from scratch"
            ConfigManager.shared.isFreshStart = true
            ConfigManager.shared.save()
            result = true
        }

        // Restore accessory mode now that all dialogs are dismissed
        NSApp.setActivationPolicy(.accessory)

        return result
    }

    // MARK: - Internal migration logic

    /// Perform the actual migration: parse old config, apply to new config,
    /// save, verify, and optionally clean up. Returns `true` on success,
    /// `false` if the app should exit.
    private static func performMigration() -> Bool {
        do {
            let shortcutCount = try migrate()

            // Ask about removing old config
            let cleanupAlert = NSAlert()
            cleanupAlert.messageText = "Successfully migrated \(shortcutCount) shortcut\(shortcutCount == 1 ? "" : "s"). Would you like to remove the old config?"
            cleanupAlert.alertStyle = .informational

            let yesButton = cleanupAlert.addButton(withTitle: "Yes")
            cleanupAlert.addButton(withTitle: "No")
            yesButton.keyEquivalent = "\r"

            let cleanupResponse = cleanupAlert.runModal()
            if cleanupResponse == .alertFirstButtonReturn {
                try? removeOldConfig()
            }

            return true
        } catch {
            // Migration failed — show error and signal app exit
            let errorAlert = NSAlert()
            errorAlert.messageText = "Migration failed:\n\(error)"
            errorAlert.alertStyle = .critical
            errorAlert.addButton(withTitle: "OK")
            errorAlert.runModal()
            return false
        }
    }

    /// Parse the old INI config and apply it to `ConfigManager.shared.config`.
    /// Saves the new config and verifies it was written correctly.
    /// Returns the number of shortcuts migrated.
    static func migrate() throws -> Int {
        let ini = try INIParser.parse(fileAt: oldConfigPath)

        // Parse [main] section
        guard let main = ini.sections["main"] else {
            throw MigrationError.parseError("Missing [main] section")
        }

        var config = AppConfig()

        // Global settings
        config.shell = main["shell"] ?? config.shell
        config.populateMenuWithActions = parseBool(main["populate_menu_with_actions"]) ?? config.populateMenuWithActions
        config.showHotkeysInMenu = parseBool(main["show_hotkeys_in_menu"]) ?? config.showHotkeysInMenu
        config.checkForUpdates = parseBool(main["check_for_updates"]) ?? config.checkForUpdates
        config.startOnLogin = parseBool(main["start_on_login"]) ?? config.startOnLogin
        config.showIconInStatusbar = parseBool(main["show_icon_in_statusbar"]) ?? config.showIconInStatusbar
        config.setWorkdirWithCd = parseBool(main["set_workdir_with_cd"]) ?? config.setWorkdirWithCd

        // Window settings
        config.window.x = Int(main["window_x"] ?? "-1") ?? -1
        config.window.y = Int(main["window_y"] ?? "-1") ?? -1
        config.window.width = Int(main["window_width"] ?? "800") ?? 800
        config.window.height = Int(main["window_height"] ?? "600") ?? 600

        // Shortcuts table column visibility
        config.window.shortcutsTable.shortcutColumn = parseBool(main["shortcut_column_enabled"]) ?? config.window.shortcutsTable.shortcutColumn
        config.window.shortcutsTable.actionColumn = parseBool(main["action_column_enabled"]) ?? config.window.shortcutsTable.actionColumn
        config.window.shortcutsTable.commandColumn = parseBool(main["command_column_enabled"]) ?? config.window.shortcutsTable.commandColumn
        config.window.shortcutsTable.workdirColumn = parseBool(main["workdir_column_enabled"]) ?? config.window.shortcutsTable.workdirColumn

        // Shortcuts table column widths
        config.window.shortcutsTable.shortcutColumnWidth = Int(main["shortcut_column_width"] ?? "110") ?? 110
        config.window.shortcutsTable.actionColumnWidth = Int(main["action_column_width"] ?? "150") ?? 150
        config.window.shortcutsTable.commandColumnWidth = Int(main["command_column_width"] ?? "280") ?? 280
        config.window.shortcutsTable.workdirColumnWidth = Int(main["workdir_column_width"] ?? "120") ?? 120

        // Parse shortcut sections (preserving order from the INI file)
        var shortcuts: [ShortcutConfig] = []
        for sectionName in ini.sectionOrder {
            if sectionName.hasPrefix("shortcut"), let section = ini.sections[sectionName] {
                var shortcut = ShortcutConfig()
                shortcut.shortcut = convertShortcutString(section["shortcut"] ?? "")
                shortcut.category = ""  // category didn't exist in old version
                shortcut.action = section["action"] ?? ""
                shortcut.command = section["command"] ?? ""
                shortcut.workdir = section["workdir"] ?? ""
                shortcut.enabled = parseBool(section["enabled"]) ?? true
                shortcuts.append(shortcut)
            }
        }
        config.shortcuts = shortcuts

        // Apply to ConfigManager
        ConfigManager.shared.config = config

        // Save the new config
        ConfigManager.shared.save()

        // Verify the save was successful
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: ConfigManager.shared.configFilePath.path) {
            throw MigrationError.saveError("Config file was not written")
        }

        // Read back and verify it parses correctly
        do {
            let content = try String(contentsOf: ConfigManager.shared.configFilePath, encoding: .utf8)
            let decoder = TOMLDecoder()
            _ = try decoder.decode(AppConfig.self, from: content)
        } catch {
            throw MigrationError.saveError("Saved config could not be read back: \(error.localizedDescription)")
        }

        return shortcuts.count
    }

    /// Recursively remove the old config directory `~/.config/iCanHazShortcut`.
    static func removeOldConfig() throws {
        try FileManager.default.removeItem(at: oldConfigDir)
    }

    // MARK: - Helpers

    /// Mapping of old text key names to their Unicode equivalents.
    /// Keys without Unicode symbols (F-keys, Clear) are left as-is.
    private static let keyNameToUnicode: [String: String] = [
        "Esc":    "⎋",
        "Return": "↩",
        "Enter":  "⌤",
        "CAPS":   "⇪",
        "Home":   "⤒",
        "End":    "⤓",
        "PgUp":   "⇞",
        "PgDown": "⇟",
        "Del":    "⌫",
        "Space":  "␣",
        "Tab":    "⇥",
    ]

    /// Convert old text key names in a shortcut string to Unicode symbols.
    /// Modifier symbols (⌘⇧⌥⌃) are preserved as-is. Text key names that have
    /// no Unicode equivalent (F1–F20, Clear) are left unchanged.
    private static func convertShortcutString(_ shortcut: String) -> String {
        var result = shortcut
        for (name, symbol) in keyNameToUnicode {
            result = result.replacingOccurrences(of: name, with: symbol)
        }
        return result
    }

    /// Parse a boolean string value from the old INI format.
    /// Supports: yes/no, true/false, 1/0 (case-insensitive).
    private static func parseBool(_ value: String?) -> Bool? {
        guard let value = value?.lowercased() else { return nil }
        switch value {
        case "yes", "true", "1":  return true
        case "no", "false", "0":  return false
        default:                  return nil
        }
    }
}

// MARK: - Migration Errors

enum MigrationError: Error, CustomStringConvertible {
    case parseError(String)
    case saveError(String)

    var description: String {
        switch self {
        case .parseError(let msg): return "Failed to parse config: \(msg)"
        case .saveError(let msg):  return "Failed to save config: \(msg)"
        }
    }
}
