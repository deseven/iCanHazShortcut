import Cocoa

// MARK: - Main Window Controller

class MainWindowController: NSWindowController, NSWindowDelegate {

    enum Tab: Int {
        case shortcuts = 0
        case preferences = 1
        case about = 2
    }

    private let tabViewController: TabViewController

    /// Called when the window is closed; the owner should release this controller.
    var onWindowClosed: (() -> Void)?

    // Shortcuts tab is the only resizable tab
    private static let shortcutsMinSize = NSSize(width: 600, height: 400)
    private static let shortcutsMaxSize = NSSize(width: 1280, height: 720)

    // Fixed sizes for non-resizable tabs
    private static let preferencesSize = NSSize(width: 780, height: 340)
    private static let aboutSize = NSSize(width: 720, height: 420)

    // Saved frame for the shortcuts tab (restored when switching back)
    private var shortcutsFrame: NSRect?
    // Track previous tab to know when we're leaving shortcuts
    private var previousTab: Tab = .shortcuts

    init() {
        let windowConfig = ConfigManager.shared.config.window

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: CGFloat(windowConfig.width), height: CGFloat(windowConfig.height)),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )

        tabViewController = TabViewController()
        tabViewController.tabStyle = .toolbar

        // Shortcuts tab
        let shortcutsItem = NSTabViewItem(identifier: "shortcuts")
        shortcutsItem.label = "Shortcuts"
        shortcutsItem.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Shortcuts")
        shortcutsItem.viewController = ShortcutsViewController()

        // Preferences tab
        let preferencesItem = NSTabViewItem(identifier: "preferences")
        preferencesItem.label = "Preferences"
        preferencesItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "Preferences")
        preferencesItem.viewController = PreferencesViewController()

        // About tab
        let aboutItem = NSTabViewItem(identifier: "about")
        aboutItem.label = "About"
        aboutItem.image = NSImage(systemSymbolName: "info.circle", accessibilityDescription: "About")
        aboutItem.viewController = AboutViewController()

        tabViewController.addTabViewItem(shortcutsItem)
        tabViewController.addTabViewItem(preferencesItem)
        tabViewController.addTabViewItem(aboutItem)

        window.contentViewController = tabViewController
        window.isReleasedWhenClosed = false
        window.title = ConfigManager.appName
        window.minSize = Self.shortcutsMinSize
        window.maxSize = Self.shortcutsMaxSize

        // Hide minimize and zoom buttons (only show close button)
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        super.init(window: window)

        window.delegate = self
        tabViewController.onTabChanged = { [weak self] in
            guard let self else { return }
            self.applyWindowConstraints(for: self.currentTab())
        }

        // Position and size: center if x or y is -1, otherwise restore full frame from config
        if windowConfig.x == -1 || windowConfig.y == -1 {
            window.setContentSize(NSSize(width: CGFloat(windowConfig.width), height: CGFloat(windowConfig.height)))
            window.center()
        } else {
            window.setFrame(
                NSRect(x: CGFloat(windowConfig.x), y: CGFloat(windowConfig.y),
                       width: CGFloat(windowConfig.width), height: CGFloat(windowConfig.height)),
                display: true
            )
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func selectTab(_ tab: Tab) {
        tabViewController.selectedTabViewItemIndex = tab.rawValue
    }

    /// Returns the view controller for the given tab.
    func viewController(for tab: Tab) -> NSViewController? {
        return tabViewController.tabViewItems[tab.rawValue].viewController
    }

    func showWindow(tab: Tab) {
        // If a sheet is attached (e.g. shortcut editor or test run),
        // just activate the window without switching tabs
        if let window = window, window.attachedSheet != nil {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        selectTab(tab)
        window?.makeKeyAndOrderFront(nil)
    }

    // MARK: - Tab-aware window sizing

    private func currentTab() -> Tab {
        return Tab(rawValue: tabViewController.selectedTabViewItemIndex) ?? .shortcuts
    }

    private func applyWindowConstraints(for tab: Tab) {
        guard let window = window else { return }

        // Save shortcuts frame only when leaving the shortcuts tab
        if previousTab == .shortcuts && tab != .shortcuts {
            shortcutsFrame = window.frame
        }

        switch tab {
        case .shortcuts:
            window.minSize = Self.shortcutsMinSize
            window.maxSize = Self.shortcutsMaxSize
            window.standardWindowButton(.zoomButton)?.isHidden = true

            // Restore saved shortcuts frame if available
            if let savedFrame = shortcutsFrame {
                window.setFrame(savedFrame, display: true, animate: true)
            }

        case .preferences:
            let fixedSize = Self.preferencesSize
            window.standardWindowButton(.zoomButton)?.isHidden = true

            // Center the fixed-size window at the same position
            let currentFrame = window.frame
            let newWidth = fixedSize.width
            let newHeight = fixedSize.height
            let newX = currentFrame.midX - newWidth / 2
            let newY = currentFrame.midY - newHeight / 2
            window.setFrame(NSRect(x: newX, y: newY, width: newWidth, height: newHeight), display: true, animate: true)

        case .about:
            let fixedSize = Self.aboutSize
            window.standardWindowButton(.zoomButton)?.isHidden = true

            let currentFrame = window.frame
            let newWidth = fixedSize.width
            let newHeight = fixedSize.height
            let newX = currentFrame.midX - newWidth / 2
            let newY = currentFrame.midY - newHeight / 2
            window.setFrame(NSRect(x: newX, y: newY, width: newWidth, height: newHeight), display: true, animate: true)
        }

        previousTab = tab
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Always save position; only save dimensions on shortcuts tab
        saveWindowFrame(dimensions: currentTab() == .shortcuts)
        // Return to accessory mode when the window is closed
        NSApp.setActivationPolicy(.accessory)
        // Notify owner to release this controller (deferred to avoid
        // deallocating the delegate while it's still executing)
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.onWindowClosed?()
        }
    }

    func windowDidMove(_ notification: Notification) {
        // Always save position; only save dimensions on shortcuts tab
        saveWindowFrame(dimensions: currentTab() == .shortcuts)
    }

    func windowDidResize(_ notification: Notification) {
        if currentTab() == .shortcuts {
            saveWindowFrame()
        }
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        let tab = currentTab()
        switch tab {
        case .preferences:
            return Self.preferencesSize
        case .about:
            return Self.aboutSize
        default:
            return frameSize
        }
    }

    // MARK: - Config persistence

    private func saveWindowFrame(dimensions: Bool = true) {
        guard let window = window else { return }
        let frame = window.frame
        ConfigManager.shared.config.window.x = Int(frame.origin.x)
        ConfigManager.shared.config.window.y = Int(frame.origin.y)
        if dimensions {
            ConfigManager.shared.config.window.width = Int(frame.width)
            ConfigManager.shared.config.window.height = Int(frame.height)
        }
        ConfigManager.shared.save()
    }
}

// MARK: - Tab View Controller

/// Custom NSTabViewController that notifies when the selected tab changes.
private class TabViewController: NSTabViewController {
    var onTabChanged: (() -> Void)?

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        onTabChanged?()
    }
}

// MARK: - Placeholder View Controller

/// Simple placeholder view controller for tabs that haven't been fully implemented yet.
private class PlaceholderViewController: NSViewController {

    init(label: String) {
        super.init(nibName: nil, bundle: nil)

        let textField = NSTextField(labelWithString: label)
        textField.font = NSFont.systemFont(ofSize: 20, weight: .medium)
        textField.textColor = .tertiaryLabelColor
        textField.alignment = .center

        view = NSView()
        view.addSubview(textField)
        textField.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            textField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            textField.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
