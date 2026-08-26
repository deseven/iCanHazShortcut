import Foundation
import Testing
@testable import iCanHazShortcut

extension AllTests {
    @MainActor
    @Suite("ConfigMigrator")
    struct ConfigMigratorTests {

        // MARK: - convertShortcutString (old text key names → Unicode symbols)

        @Test("converts Esc to ⎋")
        func convertsEsc() {
            #expect(ConfigMigrator.convertShortcutString("Esc") == "⎋")
            #expect(ConfigMigrator.convertShortcutString("⌥Esc") == "⌥⎋")
        }

        @Test("converts Return/Enter to ↩/⌤")
        func convertsReturnEnter() {
            #expect(ConfigMigrator.convertShortcutString("Return") == "↩")
            #expect(ConfigMigrator.convertShortcutString("Enter") == "⌤")
        }

        @Test("converts CAPS to ⇪")
        func convertsCaps() {
            #expect(ConfigMigrator.convertShortcutString("CAPS") == "⇪")
        }

        @Test("converts navigation keys")
        func convertsNavigation() {
            #expect(ConfigMigrator.convertShortcutString("Home") == "⤒")
            #expect(ConfigMigrator.convertShortcutString("End") == "⤓")
            #expect(ConfigMigrator.convertShortcutString("PgUp") == "⇞")
            #expect(ConfigMigrator.convertShortcutString("PgDown") == "⇟")
        }

        @Test("converts Del/Space/Tab")
        func convertsDelSpaceTab() {
            #expect(ConfigMigrator.convertShortcutString("Del") == "⌫")
            #expect(ConfigMigrator.convertShortcutString("Space") == "␣")
            #expect(ConfigMigrator.convertShortcutString("Tab") == "⇥")
        }

        @Test("leaves F-keys and Clear unchanged")
        func leavesFKeysAndClear() {
            #expect(ConfigMigrator.convertShortcutString("F1") == "F1")
            #expect(ConfigMigrator.convertShortcutString("⌘⇧F19") == "⌘⇧F19")
            #expect(ConfigMigrator.convertShortcutString("Clear") == "Clear")
        }

        @Test("preserves existing modifier symbols")
        func preservesModifiers() {
            #expect(ConfigMigrator.convertShortcutString("⌘⇧Esc") == "⌘⇧⎋")
            #expect(ConfigMigrator.convertShortcutString("⌃⌥Return") == "⌃⌥↩")
        }

        @Test("replacement is case-sensitive")
        func replacementIsCaseSensitive() {
            #expect(ConfigMigrator.convertShortcutString("esc") == "esc")
            #expect(ConfigMigrator.convertShortcutString("ESC") == "ESC")
        }

        @Test("converts multiple keys in one string")
        func convertsMultipleKeys() {
            #expect(ConfigMigrator.convertShortcutString("⌃⌥Del") == "⌃⌥⌫")
            #expect(ConfigMigrator.convertShortcutString("⇧Tab") == "⇧⇥")
            #expect(ConfigMigrator.convertShortcutString("⌘⇧PgUp") == "⌘⇧⇞")
        }

        // MARK: - parseBool

        @Test("parseBool accepts yes/no/true/false/1/0 case-insensitively")
        func parseBoolVariants() {
            #expect(ConfigMigrator.parseBool("yes") == true)
            #expect(ConfigMigrator.parseBool("YES") == true)
            #expect(ConfigMigrator.parseBool("no") == false)
            #expect(ConfigMigrator.parseBool("true") == true)
            #expect(ConfigMigrator.parseBool("False") == false)
            #expect(ConfigMigrator.parseBool("1") == true)
            #expect(ConfigMigrator.parseBool("0") == false)
            #expect(ConfigMigrator.parseBool(nil) == nil)
            #expect(ConfigMigrator.parseBool("maybe") == nil)
            #expect(ConfigMigrator.parseBool("") == nil)
        }

        // MARK: - End-to-end migration (parse INI → apply → save → verify)

        @Test
        func fullMigrateRoundTrip() throws {
            let tempDir = try makeTempConfigDir()
            defer {
                ConfigManager.configDirectoryOverride = nil
                ConfigMigrator.oldConfigPathOverride = nil
                ConfigManager.shared.config = AppConfig.default
                try? FileManager.default.removeItem(at: tempDir)
            }

            let ini = """
            [main]
            shell = /bin/zsh
            populate_menu_with_actions = no
            start_on_login = yes
            show_icon_in_statusbar = no
            check_for_updates = no
            set_workdir_with_cd = no

            [shortcut1]
            shortcut = ⌘⇧G
            action = lock screen
            command = pmset displaysleepnow
            enabled = yes

            [shortcut2]
            shortcut = ⌃⌥Return
            action = open terminal
            command = open -a Terminal
            enabled = no
            """

            let iniURL = tempDir.appendingPathComponent("config.ini")
            try ini.write(to: iniURL, atomically: true, encoding: .utf8)

            ConfigMigrator.oldConfigPathOverride = iniURL
            ConfigManager.configDirectoryOverride = tempDir

            let count = try ConfigMigrator.migrate()

            #expect(count == 2)

            let config = ConfigManager.shared.config
            #expect(config.shell == "/bin/zsh")
            #expect(config.populateMenuWithActions == false)
            #expect(config.startOnLogin == true)
            #expect(config.showIconInStatusbar == false)
            #expect(config.checkForUpdates == false)
            #expect(config.setWorkdirWithCd == false)

            #expect(config.shortcuts.count == 2)
            let first = config.shortcuts[0]
            #expect(first.shortcut == "⌘⇧G")
            #expect(first.action == "lock screen")
            #expect(first.command == "pmset displaysleepnow")
            #expect(first.enabled == true)

            let second = config.shortcuts[1]
            // "Return" is converted to "↩" by convertShortcutString during migration
            #expect(second.shortcut == "⌃⌥↩")
            #expect(second.action == "open terminal")
            #expect(second.command == "open -a Terminal")
            #expect(second.enabled == false)

            // Verify written config parses
            let written = try String(
                contentsOf: ConfigManager.shared.configFilePath, encoding: .utf8)
            #expect(written.contains("shell"))
        }

        @Test
        func migrateThrowsOnMissingMainSection() throws {
            let tempDir = try makeTempConfigDir()
            defer {
                ConfigManager.configDirectoryOverride = nil
                ConfigMigrator.oldConfigPathOverride = nil
                ConfigManager.shared.config = AppConfig.default
                try? FileManager.default.removeItem(at: tempDir)
            }

            let ini = """
            [shortcut1]
            shortcut = ⌘⇧G
            action = lock screen
            """

            let iniURL = tempDir.appendingPathComponent("config.ini")
            try ini.write(to: iniURL, atomically: true, encoding: .utf8)

            ConfigMigrator.oldConfigPathOverride = iniURL
            ConfigManager.configDirectoryOverride = tempDir

            #expect(throws: MigrationError.self) {
                _ = try ConfigMigrator.migrate()
            }
        }

        @Test
        func migrateConvertsLegacyKeyNames() throws {
            let tempDir = try makeTempConfigDir()
            defer {
                ConfigManager.configDirectoryOverride = nil
                ConfigMigrator.oldConfigPathOverride = nil
                ConfigManager.shared.config = AppConfig.default
                try? FileManager.default.removeItem(at: tempDir)
            }

            // Old config uses text key names in shortcuts
            let ini = """
            [main]
            shell = /bin/zsh

            [shortcut1]
            shortcut = ⌘⇧Esc
            action = escape
            command = echo hi
            enabled = yes
            """

            let iniURL = tempDir.appendingPathComponent("config.ini")
            try ini.write(to: iniURL, atomically: true, encoding: .utf8)

            ConfigMigrator.oldConfigPathOverride = iniURL
            ConfigManager.configDirectoryOverride = tempDir

            _ = try ConfigMigrator.migrate()

            let shortcuts = ConfigManager.shared.config.shortcuts
            #expect(shortcuts.count == 1)
            #expect(shortcuts[0].shortcut == "⌘⇧⎋")
        }
    }
}

/// Create a unique temp directory for a test, cleaned up by the caller.
private func makeTempConfigDir() throws -> URL {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("iCHS-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}