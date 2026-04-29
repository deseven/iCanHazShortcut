import Cocoa
import Carbon

let appName = "iCanHazShortcut"

// MARK: - Menu item target for shortcut execution

class ShortcutMenuItemTarget: NSObject {
    let shortcut: ShortcutConfig
    weak var appDelegate: AppDelegate?

    init(shortcut: ShortcutConfig, appDelegate: AppDelegate) {
        self.shortcut = shortcut
        self.appDelegate = appDelegate
    }

    @objc func execute() {
        appDelegate?.runShortcut(shortcut)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var registeredHotkeyIDs: [HotkeyID] = []
    var menuItemTargets: [ShortcutMenuItemTarget] = []

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Load configuration first thing; if migration was triggered but failed, exit
        if !ConfigManager.shared.load() {
            NSApplication.shared.terminate(nil)
        }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(named: "status_icon")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        buildMenu(menu)
        statusItem.menu = menu

        // Register all shortcuts from config
        registerShortcuts()
    }

    // MARK: - Menu building

    private func buildMenu(_ menu: NSMenu) {
        let config = ConfigManager.shared.config

        if config.populateMenuWithActions {
            // Separate shortcuts into categorized and uncategorized
            var categorized: [String: [ShortcutConfig]] = [:]
            var uncategorized: [ShortcutConfig] = []

            for shortcut in config.shortcuts {
                guard shortcut.enabled && !shortcut.shortcut.isEmpty && !shortcut.command.isEmpty else {
                    continue
                }

                if shortcut.category.isEmpty {
                    uncategorized.append(shortcut)
                } else {
                    categorized[shortcut.category, default: []].append(shortcut)
                }
            }

            // Add category submenus (sorted alphabetically)
            let sortedCategories = categorized.keys.sorted()
            for category in sortedCategories {
                let submenu = NSMenu()
                for shortcut in categorized[category]! {
                    submenu.addItem(createMenuItem(for: shortcut))
                }
                let submenuItem = NSMenuItem(title: category, action: nil, keyEquivalent: "")
                submenuItem.submenu = submenu
                menu.addItem(submenuItem)
            }

            // Add separator between categories and uncategorized (only if both exist)
            if !sortedCategories.isEmpty && !uncategorized.isEmpty {
                menu.addItem(NSMenuItem.separator())
            }

            // Add uncategorized shortcuts
            for shortcut in uncategorized {
                menu.addItem(createMenuItem(for: shortcut))
            }

            // Add separator before Quit
            if !sortedCategories.isEmpty || !uncategorized.isEmpty {
                menu.addItem(NSMenuItem.separator())
            }
        }

        menu.addItem(NSMenuItem(title: "Quit \(appName)", action: #selector(quitClicked), keyEquivalent: "q"))
    }

    private func createMenuItem(for shortcut: ShortcutConfig) -> NSMenuItem {
        let title = shortcut.action.isEmpty ? shortcut.command : shortcut.action

        let target = ShortcutMenuItemTarget(shortcut: shortcut, appDelegate: self)
        menuItemTargets.append(target)

        let menuItem = NSMenuItem(title: title, action: #selector(ShortcutMenuItemTarget.execute), keyEquivalent: "")
        menuItem.target = target

        if ConfigManager.shared.config.showHotkeysInMenu && !shortcut.shortcut.isEmpty {
            if let (keyEquiv, modifiers) = parseKeyEquivalent(from: shortcut.shortcut) {
                menuItem.keyEquivalent = keyEquiv
                menuItem.keyEquivalentModifierMask = modifiers
            }
        }

        return menuItem
    }

    /// Parse a hotkey string (e.g. "⌘⇧G") into an NSMenuItem key equivalent and modifier mask.
    private func parseKeyEquivalent(from hotkeyString: String) -> (String, NSEvent.ModifierFlags)? {
        var modifiers: NSEvent.ModifierFlags = []
        var keyPart = ""

        for char in hotkeyString {
            switch char {
            case "⌘":
                modifiers.insert(.command)
            case "⇧":
                modifiers.insert(.shift)
            case "⌥":
                modifiers.insert(.option)
            case "⌃":
                modifiers.insert(.control)
            default:
                keyPart.append(char)
            }
        }

        guard !keyPart.isEmpty else { return nil }

        // Map special key symbols and names to NSMenuItem key equivalent characters
        let specialKeyEquivalents: [String: String] = [
            "␣":     " ",                                    // Space
            "⎋":     "\u{1b}",                               // Escape
            "↩":     "\r",                                   // Return
            "⌤":     "\r",                                   // Enter
            "⇪":     "\u{1b}",                               // CAPS — no dedicated key equivalent, best effort
            "⤒":     String(UnicodeScalar(NSHomeFunctionKey)!),
            "⤓":     String(UnicodeScalar(NSEndFunctionKey)!),
            "⇞":     String(UnicodeScalar(NSPageUpFunctionKey)!),
            "⇟":     String(UnicodeScalar(NSPageDownFunctionKey)!),
            "⌫":     "\u{8}",                                // Backspace
            "⌦":     String(UnicodeScalar(NSDeleteFunctionKey)!),
            "⇥":     "\t",                                   // Tab
            "Clear":  String(UnicodeScalar(0xF727)!),  // Clear key
            "F1":     String(UnicodeScalar(NSF1FunctionKey)!),
            "F2":     String(UnicodeScalar(NSF2FunctionKey)!),
            "F3":     String(UnicodeScalar(NSF3FunctionKey)!),
            "F4":     String(UnicodeScalar(NSF4FunctionKey)!),
            "F5":     String(UnicodeScalar(NSF5FunctionKey)!),
            "F6":     String(UnicodeScalar(NSF6FunctionKey)!),
            "F7":     String(UnicodeScalar(NSF7FunctionKey)!),
            "F8":     String(UnicodeScalar(NSF8FunctionKey)!),
            "F9":     String(UnicodeScalar(NSF9FunctionKey)!),
            "F10":    String(UnicodeScalar(NSF10FunctionKey)!),
            "F11":    String(UnicodeScalar(NSF11FunctionKey)!),
            "F12":    String(UnicodeScalar(NSF12FunctionKey)!),
            "F13":    String(UnicodeScalar(NSF13FunctionKey)!),
            "F14":    String(UnicodeScalar(NSF14FunctionKey)!),
            "F15":    String(UnicodeScalar(NSF15FunctionKey)!),
            "F16":    String(UnicodeScalar(NSF16FunctionKey)!),
            "F17":    String(UnicodeScalar(NSF17FunctionKey)!),
            "F18":    String(UnicodeScalar(NSF18FunctionKey)!),
            "F19":    String(UnicodeScalar(NSF19FunctionKey)!),
            "F20":    String(UnicodeScalar(NSF20FunctionKey)!),
        ]

        if let keyEquiv = specialKeyEquivalents[keyPart] {
            return (keyEquiv, modifiers)
        }

        // Single printable character (letters, numbers, symbols)
        if keyPart.count == 1, let keyChar = keyPart.first {
            return (String(keyChar).lowercased(), modifiers)
        }

        return nil
    }

    // MARK: - Shortcut registration

    private func registerShortcuts() {
        let config = ConfigManager.shared.config

        for shortcut in config.shortcuts {
            guard shortcut.enabled && !shortcut.shortcut.isEmpty && !shortcut.command.isEmpty else {
                continue
            }

            do {
                let hotkeyID = try GlobalHotkeyManager.shared.register(hotkeyString: shortcut.shortcut) { [weak self] in
                    self?.runShortcut(shortcut)
                }
                registeredHotkeyIDs.append(hotkeyID)
            } catch {
                print("Failed to register hotkey '\(shortcut.shortcut)': \(error)")
            }
        }
    }

    func runShortcut(_ shortcut: ShortcutConfig) {
        let config = ConfigManager.shared.config
        let runner = CommandRunner()

        var command = shortcut.command
        var workdir = shortcut.workdir

        if config.setWorkdirWithCd && !config.shell.isEmpty && !workdir.isEmpty {
            command = "cd \(workdir)\n\(command)"
            workdir = ""
        }

        runner.run(
            test: false,
            workingDirectory: workdir,
            shell: config.shell,
            command: command
        )
    }

    @objc func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
