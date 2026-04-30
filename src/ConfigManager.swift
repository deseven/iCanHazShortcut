import Foundation
import SwiftyJSON

// MARK: - Shortcut Configuration

struct ShortcutConfig {
    var shortcut: String
    var category: String
    var action: String
    var command: String
    var workdir: String
    var enabled: Bool

    static let `default` = ShortcutConfig(
        shortcut: "",
        category: "",
        action: "",
        command: "",
        workdir: "",
        enabled: true
    )

    init(shortcut: String = "", category: String = "", action: String = "",
         command: String = "", workdir: String = "", enabled: Bool = true) {
        self.shortcut = shortcut
        self.category = category
        self.action = action
        self.command = command
        self.workdir = workdir
        self.enabled = enabled
    }

    init(from json: JSON) {
        self.shortcut = json["shortcut"].stringValue
        self.category = json["category"].stringValue
        self.action = json["action"].stringValue
        self.command = json["command"].stringValue
        self.workdir = json["workdir"].stringValue
        self.enabled = json["enabled"].boolValue
    }

    func toJSON() -> JSON {
        var json = JSON()
        json["shortcut"] = JSON(shortcut)
        json["category"] = JSON(category)
        json["action"] = JSON(action)
        json["command"] = JSON(command)
        json["workdir"] = JSON(workdir)
        json["enabled"] = JSON(enabled)
        return json
    }
}

// MARK: - Shortcuts Table Configuration

struct ShortcutsTableConfig {
    var shortcutColumn: Bool
    var actionColumn: Bool
    var commandColumn: Bool
    var workdirColumn: Bool
    var shortcutColumnWidth: Int
    var actionColumnWidth: Int
    var commandColumnWidth: Int
    var workdirColumnWidth: Int

    static let `default` = ShortcutsTableConfig()

    init(shortcutColumn: Bool = true, actionColumn: Bool = true,
         commandColumn: Bool = true, workdirColumn: Bool = true,
         shortcutColumnWidth: Int = 110,
         actionColumnWidth: Int = 150, commandColumnWidth: Int = 280,
         workdirColumnWidth: Int = 120) {
        self.shortcutColumn = shortcutColumn
        self.actionColumn = actionColumn
        self.commandColumn = commandColumn
        self.workdirColumn = workdirColumn
        self.shortcutColumnWidth = shortcutColumnWidth
        self.actionColumnWidth = actionColumnWidth
        self.commandColumnWidth = commandColumnWidth
        self.workdirColumnWidth = workdirColumnWidth
    }

    init(from json: JSON) {
        self.shortcutColumn = json["shortcut_column"].boolValue
        self.actionColumn = json["action_column"].boolValue
        self.commandColumn = json["command_column"].boolValue
        self.workdirColumn = json["workdir_column"].boolValue
        self.shortcutColumnWidth = json["shortcut_column_width"].intValue
        self.actionColumnWidth = json["action_column_width"].intValue
        self.commandColumnWidth = json["command_column_width"].intValue
        self.workdirColumnWidth = json["workdir_column_width"].intValue
    }

    func toJSON() -> JSON {
        var json = JSON()
        json["shortcut_column"] = JSON(shortcutColumn)
        json["action_column"] = JSON(actionColumn)
        json["command_column"] = JSON(commandColumn)
        json["workdir_column"] = JSON(workdirColumn)
        json["shortcut_column_width"] = JSON(shortcutColumnWidth)
        json["action_column_width"] = JSON(actionColumnWidth)
        json["command_column_width"] = JSON(commandColumnWidth)
        json["workdir_column_width"] = JSON(workdirColumnWidth)
        return json
    }
}

// MARK: - Window Configuration

struct WindowConfig {
    var x: Int
    var y: Int
    var width: Int
    var height: Int
    var shortcutsTable: ShortcutsTableConfig

    static let `default` = WindowConfig()

    init(x: Int = -1, y: Int = -1, width: Int = 800, height: Int = 600,
         shortcutsTable: ShortcutsTableConfig = .default) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.shortcutsTable = shortcutsTable
    }

    init(from json: JSON) {
        self.x = json["x"].intValue
        self.y = json["y"].intValue
        self.width = json["width"].intValue
        self.height = json["height"].intValue
        self.shortcutsTable = ShortcutsTableConfig(from: json["shortcuts_table"])
    }

    func toJSON() -> JSON {
        var json = JSON()
        json["x"] = JSON(x)
        json["y"] = JSON(y)
        json["width"] = JSON(width)
        json["height"] = JSON(height)
        json["shortcuts_table"] = shortcutsTable.toJSON()
        return json
    }
}

// MARK: - App Configuration

struct AppConfig {
    var configVersion: Int
    var shell: String
    var populateMenuWithActions: Bool
    var showHotkeysInMenu: Bool
    var checkForUpdates: Bool
    var startOnLogin: Bool
    var showIconInStatusbar: Bool
    var setWorkdirWithCd: Bool
    var window: WindowConfig
    var shortcuts: [ShortcutConfig]

    static let `default` = AppConfig()

    init(configVersion: Int = 3, shell: String = "/bin/bash -l",
         populateMenuWithActions: Bool = true, showHotkeysInMenu: Bool = true,
         checkForUpdates: Bool = true, startOnLogin: Bool = true,
         showIconInStatusbar: Bool = true, setWorkdirWithCd: Bool = true,
         window: WindowConfig = .default, shortcuts: [ShortcutConfig] = []) {
        self.configVersion = configVersion
        self.shell = shell
        self.populateMenuWithActions = populateMenuWithActions
        self.showHotkeysInMenu = showHotkeysInMenu
        self.checkForUpdates = checkForUpdates
        self.startOnLogin = startOnLogin
        self.showIconInStatusbar = showIconInStatusbar
        self.setWorkdirWithCd = setWorkdirWithCd
        self.window = window
        self.shortcuts = shortcuts
    }

    init(from json: JSON) {
        self.configVersion = json["config_version"].intValue
        self.shell = json["shell"].stringValue
        self.populateMenuWithActions = json["populate_menu_with_actions"].boolValue
        self.showHotkeysInMenu = json["show_hotkeys_in_menu"].boolValue
        self.checkForUpdates = json["check_for_updates"].boolValue
        self.startOnLogin = json["start_on_login"].boolValue
        self.showIconInStatusbar = json["show_icon_in_statusbar"].boolValue
        self.setWorkdirWithCd = json["set_workdir_with_cd"].boolValue
        self.window = WindowConfig(from: json["window"])
        self.shortcuts = json["shortcuts"].arrayValue.map { ShortcutConfig(from: $0) }
    }

    func toJSON() -> JSON {
        var json = JSON()
        json["config_version"] = JSON(configVersion)
        json["shell"] = JSON(shell)
        json["populate_menu_with_actions"] = JSON(populateMenuWithActions)
        json["show_hotkeys_in_menu"] = JSON(showHotkeysInMenu)
        json["check_for_updates"] = JSON(checkForUpdates)
        json["start_on_login"] = JSON(startOnLogin)
        json["show_icon_in_statusbar"] = JSON(showIconInStatusbar)
        json["set_workdir_with_cd"] = JSON(setWorkdirWithCd)
        json["window"] = window.toJSON()
        json["shortcuts"] = JSON(shortcuts.map { $0.toJSON().object })
        return json
    }
}

// MARK: - Config Manager

class ConfigManager {
    static let shared = ConfigManager()

    private let appName = "iCanHazShortcut"
    private let configFileName = "ichs-config.json"

    var config: AppConfig

    private init() {
        config = AppConfig.default
    }

    // MARK: - Path Helpers

    var configDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(appName)
    }

    var configFilePath: URL {
        return configDirectory.appendingPathComponent(configFileName)
    }

    // MARK: - Load / Save

    /// Load the configuration. Returns `false` if a migration was attempted
    /// but failed — the caller should terminate the app in that case.
    func load() -> Bool {
        let fileManager = FileManager.default

        // Ensure config directory exists
        if !fileManager.fileExists(atPath: configDirectory.path) {
            do {
                try fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create config directory: \(error)")
                return true
            }
        }

        // If config file doesn't exist, check for old config to migrate
        if !fileManager.fileExists(atPath: configFilePath.path) {
            if ConfigMigrator.oldConfigExists() {
                return ConfigMigrator.handleMigration()
            } else {
                save()
            }
            return true
        }

        // Load existing config
        do {
            let data = try Data(contentsOf: configFilePath)
            let json = try JSON(data: data)
            config = AppConfig(from: json)
        } catch {
            print("Failed to load config: \(error)")
        }

        return true
    }

    func save() {
        let fileManager = FileManager.default

        // Ensure config directory exists
        if !fileManager.fileExists(atPath: configDirectory.path) {
            do {
                try fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true)
            } catch {
                print("Failed to create config directory: \(error)")
                return
            }
        }

        do {
            let json = config.toJSON()
            let rawData = try json.rawData(options: .prettyPrinted)
            try rawData.write(to: configFilePath, options: .atomic)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
