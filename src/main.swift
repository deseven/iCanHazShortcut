import Cocoa

let appName = "iCanHazShortcut"

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(named: "status_icon")
            button.image?.isTemplate = true
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Quit \(appName)", action: #selector(quitClicked), keyEquivalent: "q"))
        statusItem.menu = menu
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
