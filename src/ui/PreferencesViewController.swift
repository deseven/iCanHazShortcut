import Cocoa

// MARK: - Preferences View Controller

class PreferencesViewController: NSViewController {

    // MARK: - Shell Controls

    private let noneRadio = NSButton(radioButtonWithTitle: "None", target: nil, action: nil)
    private let defaultRadio = NSButton(radioButtonWithTitle: "Default", target: nil, action: nil)
    private let customRadio = NSButton(radioButtonWithTitle: "Custom", target: nil, action: nil)
    private let customShellField = NSTextField()
    private let defaultDescLabel = NSTextField(labelWithString: "/bin/bash -l")

    // MARK: - Checkbox Controls

    private let showIconCheckbox = NSButton(checkboxWithTitle: "Show icon in status bar", target: nil, action: nil)
    private let startOnLoginCheckbox = NSButton(checkboxWithTitle: "Start on login", target: nil, action: nil)
    private let checkForUpdatesCheckbox = NSButton(checkboxWithTitle: "Check for updates", target: nil, action: nil)
    private let setWorkdirCheckbox = NSButton(checkboxWithTitle: "Set working directory with `cd`", target: nil, action: nil)

    // MARK: - Status Bar Menu Radio Group

    private let iconOnlyRadio = NSButton(radioButtonWithTitle: "Default menu", target: nil, action: nil)
    private let showActionsRadio = NSButton(radioButtonWithTitle: "Menu with actions", target: nil, action: nil)
    private let showActionsWithHotkeysRadio = NSButton(radioButtonWithTitle: "Menu with actions and hotkeys", target: nil, action: nil)

    // MARK: - Layout Constraints (for custom field show/hide)

    private var customFieldBottomConstraint: NSLayoutConstraint!
    private var customRadioBottomConstraint: NSLayoutConstraint!

    // MARK: - State

    private var isUpdatingFromConfig = false

    private var appDelegate: AppDelegate? {
        NSApplication.shared.delegate as? AppDelegate
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadConfig()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleWindowWillClose),
            name: NSWindow.willCloseNotification,
            object: view.window
        )
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: nil)
        saveConfig()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - UI Setup

    private func setupUI() {
        let container = view

        // ═══════════════════════════════════════════════════════════
        // Left Column — Shell
        // ═══════════════════════════════════════════════════════════

        let shellBox = NSBox()
        shellBox.boxType = .primary
        shellBox.title = "Shell"
        shellBox.titlePosition = .atTop
        shellBox.translatesAutoresizingMaskIntoConstraints = false

        let shellContent = shellBox.contentView!

        // Radio buttons
        for radio in [noneRadio, defaultRadio, customRadio] {
            radio.target = self
            radio.action = #selector(shellSelectionChanged(_:))
            radio.translatesAutoresizingMaskIntoConstraints = false
            shellContent.addSubview(radio)
        }

        // Description under "Default" — shows the actual shell path
        defaultDescLabel.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        defaultDescLabel.textColor = .tertiaryLabelColor
        defaultDescLabel.translatesAutoresizingMaskIntoConstraints = false
        shellContent.addSubview(defaultDescLabel)

        // Custom shell text field
        customShellField.translatesAutoresizingMaskIntoConstraints = false
        customShellField.placeholderString = "/usr/local/bin/fish -l"
        customShellField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        customShellField.usesSingleLineMode = true
        customShellField.lineBreakMode = .byTruncatingTail
        customShellField.target = self
        customShellField.action = #selector(customShellAction(_:))
        customShellField.delegate = self
        shellContent.addSubview(customShellField)

        let pad: CGFloat = 16
        let indent: CGFloat = 24
        let radioSpacing: CGFloat = 14
        let descSpacing: CGFloat = 1
        let fieldSpacing: CGFloat = 6

        // Two alternative bottom constraints — only one active at a time
        customFieldBottomConstraint = shellContent.bottomAnchor.constraint(
            equalTo: customShellField.bottomAnchor, constant: pad
        )
        customRadioBottomConstraint = shellContent.bottomAnchor.constraint(
            equalTo: customRadio.bottomAnchor, constant: pad
        )
        customRadioBottomConstraint.isActive = false

        NSLayoutConstraint.activate([
            // None
            noneRadio.topAnchor.constraint(equalTo: shellContent.topAnchor, constant: pad),
            noneRadio.leadingAnchor.constraint(equalTo: shellContent.leadingAnchor, constant: pad),
            noneRadio.trailingAnchor.constraint(equalTo: shellContent.trailingAnchor, constant: -pad),

            // Default
            defaultRadio.topAnchor.constraint(equalTo: noneRadio.bottomAnchor, constant: radioSpacing),
            defaultRadio.leadingAnchor.constraint(equalTo: shellContent.leadingAnchor, constant: pad),
            defaultRadio.trailingAnchor.constraint(equalTo: shellContent.trailingAnchor, constant: -pad),

            // Default description (indented, monospaced)
            defaultDescLabel.topAnchor.constraint(equalTo: defaultRadio.bottomAnchor, constant: descSpacing),
            defaultDescLabel.leadingAnchor.constraint(equalTo: shellContent.leadingAnchor, constant: pad + indent),

            // Custom
            customRadio.topAnchor.constraint(equalTo: defaultDescLabel.bottomAnchor, constant: radioSpacing),
            customRadio.leadingAnchor.constraint(equalTo: shellContent.leadingAnchor, constant: pad),
            customRadio.trailingAnchor.constraint(equalTo: shellContent.trailingAnchor, constant: -pad),

            // Custom shell field (indented)
            customShellField.topAnchor.constraint(equalTo: customRadio.bottomAnchor, constant: fieldSpacing),
            customShellField.leadingAnchor.constraint(equalTo: shellContent.leadingAnchor, constant: pad + indent),
            customShellField.trailingAnchor.constraint(equalTo: shellContent.trailingAnchor, constant: -pad),

            customFieldBottomConstraint,
        ])

        // ── Note below shell box ──

        let noteLabel = NSTextField(wrappingLabelWithString:
            "• Without shell selection, commands will be executed directly\n" +
            "• Ensure your shell profile (~/.bash_profile, etc) has the correct $PATH set\n" +
            "• Use test run to verify that new shortcuts work"
        )
        noteLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        noteLabel.textColor = .secondaryLabelColor
        noteLabel.translatesAutoresizingMaskIntoConstraints = false

        // ═══════════════════════════════════════════════════════════
        // Right Column — General
        // ═══════════════════════════════════════════════════════════

        let generalBox = NSBox()
        generalBox.boxType = .primary
        generalBox.title = "General"
        generalBox.titlePosition = .atTop
        generalBox.translatesAutoresizingMaskIntoConstraints = false

        let generalContent = generalBox.contentView!

        let checkboxes: [NSButton] = [
            showIconCheckbox,
            startOnLoginCheckbox,
            checkForUpdatesCheckbox,
            setWorkdirCheckbox,
        ]

        for checkbox in checkboxes {
            checkbox.target = self
            checkbox.action = #selector(checkboxChanged(_:))
            checkbox.translatesAutoresizingMaskIntoConstraints = false
            generalContent.addSubview(checkbox)
        }

        // Radio group for status bar menu style (indented under "Show icon in status bar")
        let menuRadios: [NSButton] = [iconOnlyRadio, showActionsRadio, showActionsWithHotkeysRadio]
        for radio in menuRadios {
            radio.target = self
            radio.action = #selector(menuStyleChanged(_:))
            radio.translatesAutoresizingMaskIntoConstraints = false
            generalContent.addSubview(radio)
        }

        // Tooltips
        showIconCheckbox.toolTip = "If hidden, you can reopen settings by launching iCHS again"
        startOnLoginCheckbox.toolTip = "Launch iCHS when you log in to the system"
        checkForUpdatesCheckbox.toolTip = "Enable automatic update checking every 24 hours"
        iconOnlyRadio.toolTip = "Only show the status bar icon with basic menu items"
        showActionsRadio.toolTip = "Show all enabled actions in the status bar menu"
        showActionsWithHotkeysRadio.toolTip = "Show actions with their keyboard shortcuts in the status bar menu"
        setWorkdirCheckbox.toolTip = "Send `cd $workdir` as the first command to the shell"

        let checkboxSpacing: CGFloat = 8
        let menuRadioSpacing: CGFloat = 4
        let radioIndent: CGFloat = pad + 20

        // Checkbox constraints
        var constraints: [NSLayoutConstraint] = []

        constraints.append(showIconCheckbox.topAnchor.constraint(equalTo: generalContent.topAnchor, constant: pad))
        constraints.append(showIconCheckbox.leadingAnchor.constraint(equalTo: generalContent.leadingAnchor, constant: pad))
        constraints.append(showIconCheckbox.trailingAnchor.constraint(equalTo: generalContent.trailingAnchor, constant: -pad))

        // Radio group (indented, tight spacing)
        constraints.append(iconOnlyRadio.topAnchor.constraint(equalTo: showIconCheckbox.bottomAnchor, constant: menuRadioSpacing))
        constraints.append(iconOnlyRadio.leadingAnchor.constraint(equalTo: generalContent.leadingAnchor, constant: radioIndent))
        constraints.append(iconOnlyRadio.trailingAnchor.constraint(equalTo: generalContent.trailingAnchor, constant: -pad))

        constraints.append(showActionsRadio.topAnchor.constraint(equalTo: iconOnlyRadio.bottomAnchor, constant: menuRadioSpacing))
        constraints.append(showActionsRadio.leadingAnchor.constraint(equalTo: generalContent.leadingAnchor, constant: radioIndent))
        constraints.append(showActionsRadio.trailingAnchor.constraint(equalTo: generalContent.trailingAnchor, constant: -pad))

        constraints.append(showActionsWithHotkeysRadio.topAnchor.constraint(equalTo: showActionsRadio.bottomAnchor, constant: menuRadioSpacing))
        constraints.append(showActionsWithHotkeysRadio.leadingAnchor.constraint(equalTo: generalContent.leadingAnchor, constant: radioIndent))
        constraints.append(showActionsWithHotkeysRadio.trailingAnchor.constraint(equalTo: generalContent.trailingAnchor, constant: -pad))

        // Remaining checkboxes after the radio group
        let remainingCheckboxes: [NSButton] = [startOnLoginCheckbox, checkForUpdatesCheckbox, setWorkdirCheckbox]
        for (i, checkbox) in remainingCheckboxes.enumerated() {
            let topAnchor: NSLayoutAnchor = i == 0
                ? showActionsWithHotkeysRadio.bottomAnchor
                : remainingCheckboxes[i - 1].bottomAnchor
            let spacing: CGFloat = i == 0 ? checkboxSpacing : checkboxSpacing
            constraints.append(checkbox.topAnchor.constraint(equalTo: topAnchor, constant: spacing))
            constraints.append(checkbox.leadingAnchor.constraint(equalTo: generalContent.leadingAnchor, constant: pad))
            constraints.append(checkbox.trailingAnchor.constraint(equalTo: generalContent.trailingAnchor, constant: -pad))
        }
        constraints.append(
            setWorkdirCheckbox.bottomAnchor.constraint(equalTo: generalContent.bottomAnchor, constant: -pad)
        )

        NSLayoutConstraint.activate(constraints)

        // ═══════════════════════════════════════════════════════════
        // Main Layout — two columns
        // ═══════════════════════════════════════════════════════════

        container.addSubview(shellBox)
        container.addSubview(noteLabel)
        container.addSubview(generalBox)

        let outerPad: CGFloat = 20
        let columnSpacing: CGFloat = 24
        let rightColumnWidth: CGFloat = 300

        // Shell box wants to be 400px but can shrink; hard cap at 400
        let shellWidth = shellBox.widthAnchor.constraint(equalToConstant: 400)
        shellWidth.priority = .defaultHigh

        NSLayoutConstraint.activate([
            // Left column — shell box
            shellBox.topAnchor.constraint(equalTo: container.topAnchor, constant: outerPad - 5),
            shellBox.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: outerPad),
            shellWidth,
            shellBox.widthAnchor.constraint(lessThanOrEqualToConstant: 400),
            // Prevent overlap with right column
            shellBox.trailingAnchor.constraint(lessThanOrEqualTo: generalBox.leadingAnchor, constant: -columnSpacing),

            // Left column — note
            noteLabel.topAnchor.constraint(equalTo: shellBox.bottomAnchor, constant: 12),
            noteLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: outerPad + 4),
            noteLabel.trailingAnchor.constraint(lessThanOrEqualTo: generalBox.leadingAnchor, constant: -columnSpacing),
            noteLabel.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -outerPad),

            // Right column — general box (anchored after shell box)
            generalBox.topAnchor.constraint(equalTo: container.topAnchor, constant: outerPad - 5),
            generalBox.leadingAnchor.constraint(equalTo: shellBox.trailingAnchor, constant: columnSpacing),
            generalBox.widthAnchor.constraint(equalToConstant: rightColumnWidth),
            generalBox.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -outerPad),
        ])
    }

    // MARK: - Actions

    @objc private func shellSelectionChanged(_ sender: NSButton) {
        updateCustomFieldVisibility()
        saveConfig()
    }

    @objc private func checkboxChanged(_ sender: NSButton) {
        if sender === showIconCheckbox {
            updateMenuRadioGroupState()
            saveConfig()
            if showIconCheckbox.state == .on {
                appDelegate?.showStatusItem()
            } else {
                appDelegate?.hideStatusItem()
            }
        } else {
            saveConfig()
        }
    }

    @objc private func menuStyleChanged(_ sender: NSButton) {
        saveConfig()
        appDelegate?.rebuildMenu()
    }

    @objc private func customShellAction(_ sender: NSTextField) {
        saveConfig()
    }

    @objc private func handleWindowWillClose(_ notification: Notification) {
        saveConfig()
    }

    // MARK: - Config Sync

    private func updateMenuRadioGroupState() {
        let iconVisible = showIconCheckbox.state == .on
        iconOnlyRadio.isEnabled = iconVisible
        showActionsRadio.isEnabled = iconVisible
        showActionsWithHotkeysRadio.isEnabled = iconVisible
    }

    private func updateCustomFieldVisibility() {
        let isCustom = customRadio.state == .on
        customShellField.isHidden = !isCustom
        customShellField.isEnabled = isCustom
        customFieldBottomConstraint.isActive = isCustom
        customRadioBottomConstraint.isActive = !isCustom
    }

    private func loadConfig() {
        isUpdatingFromConfig = true

        let config = ConfigManager.shared.config

        // Determine shell selection from config value
        switch config.shell {
        case "":
            noneRadio.state = .on
        case "/bin/bash -l":
            defaultRadio.state = .on
        default:
            customRadio.state = .on
            customShellField.stringValue = config.shell
        }

        updateCustomFieldVisibility()

        // Checkboxes
        showIconCheckbox.state = config.showIconInStatusbar ? .on : .off
        startOnLoginCheckbox.state = config.startOnLogin ? .on : .off
        checkForUpdatesCheckbox.state = config.checkForUpdates ? .on : .off
        setWorkdirCheckbox.state = config.setWorkdirWithCd ? .on : .off

        // Menu style radio group
        if config.populateMenuWithActions && config.showHotkeysInMenu {
            showActionsWithHotkeysRadio.state = .on
        } else if config.populateMenuWithActions {
            showActionsRadio.state = .on
        } else {
            iconOnlyRadio.state = .on
        }

        updateMenuRadioGroupState()

        isUpdatingFromConfig = false
    }

    private func saveConfig() {
        guard !isUpdatingFromConfig, isViewLoaded else { return }

        // Shell — read from field editor if actively editing
        if noneRadio.state == .on {
            ConfigManager.shared.config.shell = ""
        } else if defaultRadio.state == .on {
            ConfigManager.shared.config.shell = "/bin/bash -l"
        } else {
            if let editor = customShellField.currentEditor() {
                ConfigManager.shared.config.shell = editor.string
            } else {
                ConfigManager.shared.config.shell = customShellField.stringValue
            }
        }

        // Checkboxes
        ConfigManager.shared.config.showIconInStatusbar = showIconCheckbox.state == .on
        ConfigManager.shared.config.startOnLogin = startOnLoginCheckbox.state == .on
        ConfigManager.shared.config.checkForUpdates = checkForUpdatesCheckbox.state == .on
        ConfigManager.shared.config.setWorkdirWithCd = setWorkdirCheckbox.state == .on

        // Menu style radio group
        ConfigManager.shared.config.populateMenuWithActions = showActionsRadio.state == .on || showActionsWithHotkeysRadio.state == .on
        ConfigManager.shared.config.showHotkeysInMenu = showActionsWithHotkeysRadio.state == .on

        ConfigManager.shared.save()
    }
}

// MARK: - NSTextFieldDelegate

extension PreferencesViewController: NSTextFieldDelegate {
    func controlTextDidEndEditing(_ obj: Notification) {
        if let textField = obj.object as? NSTextField, textField === customShellField {
            saveConfig()
        }
    }
}
