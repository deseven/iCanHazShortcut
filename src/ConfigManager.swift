import Foundation
import TOML

// MARK: - Shortcut Configuration

struct ShortcutConfig: Codable {
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
}

// MARK: - Shortcuts Table Configuration

struct ShortcutsTableConfig: Codable {
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

    enum CodingKeys: String, CodingKey {
        case shortcutColumn = "shortcut_column"
        case actionColumn = "action_column"
        case commandColumn = "command_column"
        case workdirColumn = "workdir_column"
        case shortcutColumnWidth = "shortcut_column_width"
        case actionColumnWidth = "action_column_width"
        case commandColumnWidth = "command_column_width"
        case workdirColumnWidth = "workdir_column_width"
    }
}

// MARK: - Window Configuration

struct WindowConfig: Codable {
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

    enum CodingKeys: String, CodingKey {
        case x, y, width, height
        case shortcutsTable = "shortcuts_table"
    }
}

// MARK: - App Configuration

struct AppConfig: Codable {
    static let defaultShell = "/bin/zsh -l"

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

    init(configVersion: Int = 3, shell: String = AppConfig.defaultShell,
         populateMenuWithActions: Bool = true, showHotkeysInMenu: Bool = true,
         checkForUpdates: Bool = true, startOnLogin: Bool = false,
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

    enum CodingKeys: String, CodingKey {
        case configVersion = "config_version"
        case shell
        case populateMenuWithActions = "populate_menu_with_actions"
        case showHotkeysInMenu = "show_hotkeys_in_menu"
        case checkForUpdates = "check_for_updates"
        case startOnLogin = "start_on_login"
        case showIconInStatusbar = "show_icon_in_statusbar"
        case setWorkdirWithCd = "set_workdir_with_cd"
        case window, shortcuts
    }
}

// MARK: - Config Manager

class ConfigManager {
    static let shared = ConfigManager()

    static let appName = "iCanHazShortcut"
    static let appShortName = "iCHS"
    static let appTag = "ichs"
    static let configFileName = "\(appTag)-config.toml"

    var config: AppConfig

    /// Set to `true` when a fresh default config was written without any
    /// prior config existing (first launch) or when the user chose
    /// "Start from scratch" during migration.
    var isFreshStart: Bool = false

    private init() {
        config = AppConfig.default
    }

    // MARK: - Path Helpers

    var configDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(Self.appName)
    }

    var configFilePath: URL {
        return configDirectory.appendingPathComponent(Self.configFileName)
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
                // Fresh start: no old config, no new config
                isFreshStart = true
                save()
            }
            return true
        }

        // Load existing config
        do {
            let content = try String(contentsOf: configFilePath, encoding: .utf8)
            let decoder = TOMLDecoder()
            config = try decoder.decode(AppConfig.self, from: content)
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
            let encoder = TOMLEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(config)
            try data.write(to: configFilePath, options: .atomic)
        } catch {
            print("Failed to save config: \(error)")
        }
    }
}
