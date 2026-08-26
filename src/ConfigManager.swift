import AppKit
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
         commandColumn: Bool = true, workdirColumn: Bool = false,
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
    static let defaultShell = "/bin/bash -l"

    var configVersion: Int
    var shell: String
    var populateMenuWithActions: Bool
    var showHotkeysInMenu: Bool
    var checkForUpdates: Bool
    var startOnLogin: Bool
    var showIconInStatusbar: Bool
    var setWorkdirWithCd: Bool
    var skippedUpdate: String?
    var window: WindowConfig
    var shortcuts: [ShortcutConfig]

    static let `default` = AppConfig()

    init(configVersion: Int = 3, shell: String = AppConfig.defaultShell,
         populateMenuWithActions: Bool = true, showHotkeysInMenu: Bool = true,
         checkForUpdates: Bool = true, startOnLogin: Bool = false,
         showIconInStatusbar: Bool = true, setWorkdirWithCd: Bool = true,
         skippedUpdate: String? = nil,
         window: WindowConfig = .default, shortcuts: [ShortcutConfig] = []) {
        self.configVersion = configVersion
        self.shell = shell
        self.populateMenuWithActions = populateMenuWithActions
        self.showHotkeysInMenu = showHotkeysInMenu
        self.checkForUpdates = checkForUpdates
        self.startOnLogin = startOnLogin
        self.showIconInStatusbar = showIconInStatusbar
        self.setWorkdirWithCd = setWorkdirWithCd
        self.skippedUpdate = skippedUpdate
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
        case skippedUpdate = "skipped_update"
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
    static let maxBackups = 30

    /// All config access and mutation is UI-driven (buttons, menus, AppleScript)
    /// and runs on the main thread. Value semantics make concurrent reads safe,
    /// but read-modify-write cycles from background threads could lose updates —
    /// this invariant is enforced by `assertMainThread()` in mutation paths.
    var config: AppConfig

    /// Set to `true` when a fresh default config was written without any
    /// prior config existing (first launch) or when the user chose
    /// "Start from scratch" during migration.
    var isFreshStart: Bool = false

    private init() {
        config = AppConfig.default
    }

    /// Guard against accidental config mutation from background threads.
    /// Fires in debug builds only.
    private func assertMainThread() {
        assert(Thread.isMainThread, "ConfigManager must only be used from the main thread")
    }

    // MARK: - Path Helpers

    /// Override for the config directory. Used exclusively by unit tests to
    /// isolate the config in a temp directory; always `nil` in the app.
    static var configDirectoryOverride: URL?

    var configDirectory: URL {
        if let override = Self.configDirectoryOverride {
            return override
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(Self.appName)
    }

    var configFilePath: URL {
        return configDirectory.appendingPathComponent(Self.configFileName)
    }

    var backupsDirectory: URL {
        return configDirectory.appendingPathComponent("backups")
    }

    // MARK: - Load / Save

    /// Load the configuration.
    /// - Returns: `.ok` on success, `.migrationFailed` if a migration was
    ///   attempted but failed (the caller should terminate the app), or
    ///   `.loadFailed` if an existing config could not be read.
    enum LoadResult {
        case ok
        case migrationFailed
        case loadFailed
    }

    func load() -> LoadResult {
        assertMainThread()
        let fileManager = FileManager.default

        // Ensure config directory exists
        if !fileManager.fileExists(atPath: configDirectory.path) {
            do {
                try fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true)
            } catch {
                Log.error("Failed to create config directory: \(error)")
                return .loadFailed
            }
        }

        // If config file doesn't exist, check for old config to migrate
        if !fileManager.fileExists(atPath: configFilePath.path) {
            if ConfigMigrator.oldConfigExists() {
                return ConfigMigrator.handleMigration() ? .ok : .migrationFailed
            } else {
                // Fresh start: no old config, no new config
                isFreshStart = true
                save()
                Log.info("new config created")
            }
            return .ok
        }

        // Load existing config
        do {
            let content = try String(contentsOf: configFilePath, encoding: .utf8)
            let decoder = TOMLDecoder()
            config = try decoder.decode(AppConfig.self, from: content)
            Log.info("config loaded: \(config.shortcuts.count) shortcut(s)")
        } catch {
            Log.error("Failed to load config: \(error)")
            return .loadFailed
        }

        return .ok
    }

    /// Save the configuration. Returns `false` if the config could not be written.
    /// On failure the error is logged and — unless `showAlertOnError` is disabled —
    /// presented to the user in a modal alert.
    @discardableResult
    func save(showAlertOnError: Bool = true) -> Bool {
        assertMainThread()
        let fileManager = FileManager.default

        // Ensure config directory exists
        if !fileManager.fileExists(atPath: configDirectory.path) {
            do {
                try fileManager.createDirectory(at: configDirectory, withIntermediateDirectories: true)
            } catch {
                Log.error("Failed to create config directory: \(error)")
                showSaveErrorAlert(error, showAlertOnError: showAlertOnError)
                return false
            }
        }

        do {
            let encoder = TOMLEncoder()
            encoder.outputFormatting = .sortedKeys
            let data = try encoder.encode(config)
            try data.write(to: configFilePath, options: .atomic)
            Log.info("config saved")
            return true
        } catch {
            Log.error("Failed to save config: \(error)")
            showSaveErrorAlert(error, showAlertOnError: showAlertOnError)
            return false
        }
    }

    /// Present a modal error dialog for a failed save.
    private func showSaveErrorAlert(_ error: Error, showAlertOnError: Bool) {
        guard showAlertOnError else { return }
        let alert = NSAlert()
        alert.messageText = "Failed to save config"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .critical
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    // MARK: - Backup

    /// Create a timestamped backup of the current config file, then prune
    /// old backups so only the last `maxBackups` are retained.
    func backupConfig() {
        assertMainThread()
        let fileManager = FileManager.default

        // Only back up if a config file already exists
        guard fileManager.fileExists(atPath: configFilePath.path) else { return }

        // Ensure backups directory exists
        do {
            try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        } catch {
            Log.error("Failed to create backups directory: \(error)")
            return
        }

        // Build timestamped file name: ichs-config-yyyymmdd-hhiiss.toml
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let timestamp = formatter.string(from: now)
        let backupFileName = "\(Self.appTag)-config-\(timestamp).toml"
        let backupPath = backupsDirectory.appendingPathComponent(backupFileName)

        // Skip if a backup with this timestamp already exists (e.g. multiple saves within the same second)
        guard !fileManager.fileExists(atPath: backupPath.path) else { return }

        do {
            try fileManager.copyItem(at: configFilePath, to: backupPath)
            Log.info("backup created: \(backupFileName)")
        } catch {
            Log.error("Failed to create config backup: \(error)")
            return
        }

        pruneBackups()
    }

    /// Remove the oldest backups, keeping only the last `maxBackups`.
    private func pruneBackups() {
        let fileManager = FileManager.default

        let backupFiles: [URL]
        do {
            backupFiles = try fileManager.contentsOfDirectory(at: backupsDirectory, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.pathExtension == "toml" && $0.lastPathComponent.hasPrefix("\(Self.appTag)-config-") }
        } catch {
            Log.error("Failed to list backup files: \(error)")
            return
        }

        guard backupFiles.count > Self.maxBackups else { return }

        // Sort by name descending (newest first, since names contain timestamps)
        let sorted = backupFiles.sorted { $0.lastPathComponent > $1.lastPathComponent }
        let toDelete = sorted.dropFirst(Self.maxBackups)

        for file in toDelete {
            do {
                try fileManager.removeItem(at: file)
            } catch {
                Log.error("Failed to delete old backup \(file.lastPathComponent): \(error)")
            }
        }
    }
}
