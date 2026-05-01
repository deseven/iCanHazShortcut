import Cocoa

// MARK: - Editor Window

private class EditorWindow: NSWindow {
    var onEscape: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        // Escape → cancel
        if event.keyCode == 0x35 {
            onEscape?()
            return
        }
        super.keyDown(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        onEscape?()
    }
}

// MARK: - Example Link Button

/// A borderless button that shows a pointing hand cursor on hover.
private class ExampleLinkButton: NSButton {
    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .pointingHand)
    }
}

class ShortcutEditorWindowController: NSWindowController, NSWindowDelegate {

    // MARK: - Mode

    enum Mode {
        case add
        case edit(configIndex: Int)

        var isEditing: Bool {
            if case .edit = self { return true }
            return false
        }

        var configIndex: Int? {
            if case .edit(let idx) = self { return idx }
            return nil
        }
    }

    // MARK: - Callbacks

    var onSave: (() -> Void)?
    var onClose: (() -> Void)?

    // MARK: - State

    private let mode: Mode
    private let commandRunner = CommandRunner()
    private var testRunSheet: NSWindow?

    // MARK: - Examples

    private static let examples: [(name: String, action: String, command: String)] = [
        ("Open an app",            "Open Finder",            "open -a Finder"),
        ("Make a screenshot",      "Make a screenshot",      "screencapture -i -r -t png \"$HOME/screenshot.png\""),
        ("Say something",          "Say current date",       "say `date \"+Current date is %Y-%m-%d\"`"),
        ("Save clipboard contents", "Save clipboard contents", "pbpaste >> \"$HOME/clipboard.log\""),
        ("Set clipboard contents",  "Set clipboard contents",  "echo \"test\" | pbcopy"),
    ]

    // MARK: - UI Elements

    private let actionField = NSTextField()
    private let categoryField = NSComboBox()
    private let shortcutField = NSTextField()
    private let commandField = NSTextField()
    private let workdirField = NSTextField()
    private var saveButton: NSButton!
    private var cancelButton: NSButton!
    private var testRunButton: NSButton!

    // MARK: - Sizing

    private static let helpPanelWidth: CGFloat = 200
    private static let windowWidth: CGFloat = 740
    private static let windowHeight: CGFloat = 320

    // MARK: - Init

    init(mode: Mode) {
        self.mode = mode

        let window = EditorWindow(
            contentRect: NSRect(x: 0, y: 0, width: Self.windowWidth, height: Self.windowHeight),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = mode.isEditing ? "Edit Shortcut" : "Add Shortcut"
        window.isReleasedWhenClosed = false
        window.minSize = NSSize(width: Self.windowWidth, height: Self.windowHeight)
        window.maxSize = NSSize(width: Self.windowWidth, height: Self.windowHeight)
        window.isExcludedFromWindowsMenu = true

        super.init(window: window)
        window.delegate = self

        // Wire Escape on the custom window
        window.onEscape = { [weak self] in self?.cancelClicked(nil) }

        setupUI()
        populateFields()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Presentation

    func showOnParent(_ parentWindow: NSWindow) {
        window?.initialFirstResponder = shortcutField
        parentWindow.beginSheet(window!) { [weak self] _ in
            self?.onClose?()
        }
    }

    func closeEditor() {
        if let window = window, let parent = window.parent {
            parent.endSheet(window)
        } else {
            window?.close()
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        let helpPadding: CGFloat = 16
        let sidePadding: CGFloat = 24

        // ── Vertical separator (created early so it can be referenced by help panel constraints) ──

        let separator = NSBox()
        separator.boxType = .separator
        separator.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(separator)

        // ── Help panel (left side) ──

        let headerLabel = NSTextField(wrappingLabelWithString: "You can use any command that works in your terminal.\n\nHere are some examples:")
        headerLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        headerLabel.textColor = .secondaryLabelColor
        headerLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(headerLabel)

        var helpConstraints: [NSLayoutConstraint] = [
            headerLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            headerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: helpPadding),
            headerLabel.widthAnchor.constraint(equalToConstant: Self.helpPanelWidth - helpPadding),
        ]

        var previousHelpAnchor: NSLayoutYAxisAnchor = headerLabel.bottomAnchor

        for (index, example) in Self.examples.enumerated() {
            let linkButton = ExampleLinkButton(title: example.name, target: self, action: #selector(exampleClicked(_:)))
            linkButton.isBordered = false
            linkButton.bezelStyle = .inline
            linkButton.translatesAutoresizingMaskIntoConstraints = false
            linkButton.tag = index

            let attrs: [NSAttributedString.Key: Any] = [
                .foregroundColor: NSColor.linkColor,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
            ]
            linkButton.attributedTitle = NSAttributedString(string: example.name, attributes: attrs)

            contentView.addSubview(linkButton)

            let topConstant: CGFloat = index == 0 ? 12 : 4
            helpConstraints += [
                linkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: helpPadding),
                linkButton.topAnchor.constraint(equalTo: previousHelpAnchor, constant: topConstant),
            ]
            previousHelpAnchor = linkButton.bottomAnchor
        }

        // ── "After finishing..." text ──

        let afterLabel = NSTextField(wrappingLabelWithString: "After finishing setting up the shortcut, you can do a test run by pressing the Test Run button in the bottom left.")
        afterLabel.font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        afterLabel.textColor = .tertiaryLabelColor
        afterLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(afterLabel)

        helpConstraints += [
            afterLabel.topAnchor.constraint(equalTo: previousHelpAnchor, constant: 16),
            afterLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: helpPadding),
            afterLabel.trailingAnchor.constraint(lessThanOrEqualTo: separator.leadingAnchor, constant: -8),
        ]

        // ── Test Run button (bottom left of help panel) ──

        testRunButton = makeIconButton(imageName: "bx-play-circle-alt", toolTip: "Test Run")
        testRunButton.target = self
        testRunButton.action = #selector(testRunClicked(_:))
        contentView.addSubview(testRunButton)

        helpConstraints += [
            testRunButton.leadingAnchor.constraint(equalTo: separator.trailingAnchor, constant: sidePadding),
            testRunButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
        ]

        helpConstraints += [
            separator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Self.helpPanelWidth),
            separator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            separator.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
        ]

        NSLayoutConstraint.activate(helpConstraints)

        // ── Form fields (right side) ──

        let fieldDefs: [(label: String, placeholder: String, field: NSTextField, required: Bool)] = [
            ("Action",             "e.g. Open Terminal",   actionField,   false),
            ("Category",           "e.g. Apps",            categoryField, false),
            ("Shortcut",           "e.g. ⌘⇧T",            shortcutField, true),
            ("Command",            "e.g. open -a Terminal", commandField,  true),
            ("Working Directory",  "e.g. ~/Projects",      workdirField,  false),
        ]

        let labelWidth: CGFloat = 130
        let fieldHeight: CGFloat = 24
        let rowSpacing: CGFloat = 16
        let hSpacing: CGFloat = 8
        let topPadding: CGFloat = 24

        var constraints: [NSLayoutConstraint] = []
        var previousBottom: NSLayoutYAxisAnchor = contentView.topAnchor

        for (index, def) in fieldDefs.enumerated() {
            let labelText = def.required ? "\(def.label) *" : def.label
            let label = NSTextField(labelWithString: labelText)
            label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            label.textColor = def.required ? .labelColor : .secondaryLabelColor
            label.alignment = .right
            label.translatesAutoresizingMaskIntoConstraints = false

            let field = def.field
            field.translatesAutoresizingMaskIntoConstraints = false
            field.placeholderString = def.placeholder
            field.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
            field.usesSingleLineMode = true
            field.lineBreakMode = .byTruncatingTail
            field.bezelStyle = .roundedBezel
            field.delegate = self

            contentView.addSubview(label)
            contentView.addSubview(field)

            let topConstant: CGFloat = index == 0 ? topPadding : rowSpacing

            constraints += [
                label.leadingAnchor.constraint(equalTo: separator.trailingAnchor, constant: sidePadding),
                label.widthAnchor.constraint(equalToConstant: labelWidth),
                label.lastBaselineAnchor.constraint(equalTo: field.lastBaselineAnchor),

                field.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: hSpacing),
                field.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -sidePadding),
                field.heightAnchor.constraint(equalToConstant: fieldHeight),
                field.topAnchor.constraint(equalTo: previousBottom, constant: topConstant),
            ]

            previousBottom = field.bottomAnchor
        }

        // ── Configure category combo box ──

        categoryField.isEditable = true
        categoryField.completes = true
        categoryField.numberOfVisibleItems = 8
        categoryField.addItems(withObjectValues: Self.collectExistingCategories())

        // ── Save & Cancel buttons ──

        saveButton = makeIconButton(imageName: "bx-check-circle", toolTip: "Save (↩)")
        cancelButton = makeIconButton(imageName: "bx-x-circle", toolTip: "Cancel (⎋)")

        saveButton.target = self
        saveButton.action = #selector(saveClicked(_:))
        cancelButton.target = self
        cancelButton.action = #selector(cancelClicked(_:))

        let buttonStack = NSStackView()
        buttonStack.orientation = .horizontal
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.addView(saveButton, in: .center)
        buttonStack.addView(cancelButton, in: .center)

        contentView.addSubview(buttonStack)

        constraints += [
            buttonStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -sidePadding),
            buttonStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            buttonStack.topAnchor.constraint(greaterThanOrEqualTo: previousBottom, constant: 8),
        ]

        NSLayoutConstraint.activate(constraints)

        // ── Key view loop (Tab order) ──

        actionField.nextKeyView = categoryField
        categoryField.nextKeyView = shortcutField
        shortcutField.nextKeyView = commandField
        commandField.nextKeyView = workdirField
        workdirField.nextKeyView = saveButton
        saveButton.nextKeyView = cancelButton
        cancelButton.nextKeyView = actionField
    }

    private func makeIconButton(imageName: String, toolTip: String) -> NSButton {
        let button = NSButton(frame: .zero)
        let originalImage = NSImage(named: imageName)
        let image = (originalImage?.copy() as? NSImage) ?? originalImage!
        image.isTemplate = true
        image.size = NSSize(width: 24, height: 24)
        button.image = image
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.toolTip = toolTip
        button.contentTintColor = .labelColor
        button.bezelStyle = .inline
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }

    private func populateFields() {
        guard let configIndex = mode.configIndex else { return }
        guard configIndex >= 0 && configIndex < ConfigManager.shared.config.shortcuts.count else { return }

        let shortcut = ConfigManager.shared.config.shortcuts[configIndex]
        actionField.stringValue = shortcut.action
        categoryField.stringValue = shortcut.category
        shortcutField.stringValue = shortcut.shortcut
        commandField.stringValue = shortcut.command
        workdirField.stringValue = shortcut.workdir
    }

    // MARK: - Actions

    @objc private func exampleClicked(_ sender: NSButton) {
        let index = sender.tag
        guard index >= 0 && index < Self.examples.count else { return }
        let example = Self.examples[index]
        actionField.stringValue = example.action
        commandField.stringValue = example.command
    }

    @objc private func saveClicked(_ sender: NSButton?) {
        let shortcutText = shortcutField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let commandText = commandField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate shortcut
        if shortcutText.isEmpty {
            showValidationAlert(message: "Shortcut is required.", informativeText: "Please enter a keyboard shortcut.")
            return
        }

        if !GlobalHotkeyManager.isValidHotkeyString(shortcutText) {
            showValidationAlert(
                message: "Invalid shortcut format.",
                informativeText: "Use Unicode modifier symbols (⌘⇧⌥⌃) followed by a key (e.g. ⌘⇧T, ⌃⌥F12). Special keys like F1-F20 can be used without modifiers."
            )
            return
        }

        // Validate command
        if commandText.isEmpty {
            showValidationAlert(message: "Command is required.", informativeText: "Please enter a command to execute.")
            return
        }

        let newShortcut = ShortcutConfig(
            shortcut: shortcutText,
            category: categoryField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            action: actionField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            command: commandText,
            workdir: workdirField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines),
            enabled: true
        )

        if let configIndex = mode.configIndex {
            // Editing existing shortcut
            let oldShortcut = ConfigManager.shared.config.shortcuts[configIndex]
            var updatedShortcut = newShortcut
            updatedShortcut.enabled = oldShortcut.enabled

            if oldShortcut.category == newShortcut.category {
                // Same category — update in place
                ConfigManager.shared.config.shortcuts[configIndex] = updatedShortcut
            } else {
                // Category changed — remove and re-insert at end of new category
                ConfigManager.shared.config.shortcuts.remove(at: configIndex)
                appendShortcutToCategory(updatedShortcut)
            }
        } else {
            // Adding new shortcut
            appendShortcutToCategory(newShortcut)
        }

        onSave?()
        closeEditor()
    }

    @objc private func cancelClicked(_ sender: NSButton?) {
        closeEditor()
    }

    // MARK: - Test Run

    @objc private func testRunClicked(_ sender: NSButton) {
        let commandText = commandField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validate command — same check as save
        if commandText.isEmpty {
            showValidationAlert(message: "Command is required.", informativeText: "Please enter a command to execute.")
            return
        }

        // Disable form elements while running
        setFormEnabled(false)

        // Show progress sheet
        showTestRunProgressSheet()

        let shell = ConfigManager.shared.config.shell
        let workdir = workdirField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        commandRunner.run(
            test: true,
            workingDirectory: workdir,
            shell: shell,
            command: commandText
        ) { [weak self] result in
            guard let self else { return }
            self.closeTestRunSheet()
            self.showTestRunResultSheet(result: result, command: commandText, shell: shell)
        }
    }

    @objc private func stopTestRunClicked(_ sender: NSButton) {
        commandRunner.kill()
        closeTestRunSheet()
        setFormEnabled(true)
    }

    @objc private func dismissTestRunClicked(_ sender: NSButton) {
        closeTestRunSheet()
        setFormEnabled(true)
    }

    // MARK: - Test Run Sheet

    private func showTestRunProgressSheet() {
        let sheet = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 300, height: 80),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        sheet.title = "Test Run"
        sheet.isReleasedWhenClosed = false

        let contentView = sheet.contentView!

        let indicator = NSProgressIndicator()
        indicator.style = .spinning
        indicator.controlSize = .regular
        indicator.isIndeterminate = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimation(nil)

        let label = NSTextField(labelWithString: "Running command…")
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        label.textColor = .secondaryLabelColor
        label.translatesAutoresizingMaskIntoConstraints = false

        let stopBtn = makeIconButton(imageName: "bx-stop-circle", toolTip: "Stop")
        stopBtn.target = self
        stopBtn.action = #selector(stopTestRunClicked(_:))

        contentView.addSubview(indicator)
        contentView.addSubview(label)
        contentView.addSubview(stopBtn)

        NSLayoutConstraint.activate([
            indicator.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            indicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            label.leadingAnchor.constraint(equalTo: indicator.trailingAnchor, constant: 12),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            stopBtn.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stopBtn.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        ])

        testRunSheet = sheet
        window?.beginSheet(sheet)
    }

    private func showTestRunResultSheet(result: CommandResult, command: String, shell: String) {
        let sheetWidth: CGFloat = 600
        let pad: CGFloat = 16
        let hSpacing: CGFloat = 8
        let outputViewHeight: CGFloat = 120

        let sheet = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: sheetWidth, height: 100),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        sheet.title = "Test Run"
        sheet.isReleasedWhenClosed = false
        // Prevent window from expanding beyond fixed width
        sheet.minSize = NSSize(width: sheetWidth, height: 100)
        sheet.maxSize = NSSize(width: sheetWidth, height: 800)

        let contentView = sheet.contentView!

        // ── Header info ──

        let shellDisplay = shell.isEmpty ? "none" : shell

        let shellLabel = NSTextField(labelWithString: "Shell:")
        shellLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        shellLabel.translatesAutoresizingMaskIntoConstraints = false

        let shellValue = NSTextField(labelWithString: shellDisplay)
        shellValue.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        shellValue.textColor = .secondaryLabelColor
        shellValue.lineBreakMode = .byTruncatingTail
        shellValue.translatesAutoresizingMaskIntoConstraints = false

        let commandLabel = NSTextField(labelWithString: "Command:")
        commandLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        commandLabel.translatesAutoresizingMaskIntoConstraints = false

        // Truncate command display to 100 characters
        let commandDisplay = command.count > 100 ? String(command.prefix(100)) + "..." : command
        let commandValue = NSTextField(labelWithString: commandDisplay)
        commandValue.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        commandValue.textColor = .secondaryLabelColor
        commandValue.lineBreakMode = .byTruncatingTail
        commandValue.translatesAutoresizingMaskIntoConstraints = false

        let exitCodeLabel = NSTextField(labelWithString: "Exit code:")
        exitCodeLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        exitCodeLabel.translatesAutoresizingMaskIntoConstraints = false

        let exitCodeValue = NSTextField(labelWithString: "\(result.exitCode)")
        exitCodeValue.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        exitCodeValue.textColor = result.exitCode == 0 ? .systemGreen : .systemRed
        exitCodeValue.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(shellLabel)
        contentView.addSubview(shellValue)
        contentView.addSubview(commandLabel)
        contentView.addSubview(commandValue)
        contentView.addSubview(exitCodeLabel)
        contentView.addSubview(exitCodeValue)

        // ── Output text views ──

        var previousBottom: NSLayoutYAxisAnchor = exitCodeValue.bottomAnchor
        let labelWidth: CGFloat = 80

        // Calculate fixed text width for word wrapping
        let textWidth = sheetWidth - pad * 2 - labelWidth - hSpacing - 20 // 20 for scrollbar/bezel

        // Helper to create a scrollable read-only text view with a header label
        func addOutputSection(title: String, content: String, to parent: NSView, below anchor: NSLayoutYAxisAnchor) -> NSLayoutYAxisAnchor {
            let headerLabel = NSTextField(labelWithString: title)
            headerLabel.font = NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium)
            headerLabel.translatesAutoresizingMaskIntoConstraints = false

            let scrollView = NSTextView.scrollableTextView()
            scrollView.borderType = .bezelBorder
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true
            scrollView.translatesAutoresizingMaskIntoConstraints = false

            // Set explicit frame for scroll view to ensure fixed width
            let scrollViewWidth = textWidth + 12 // +12 for inset and border
            scrollView.frame = NSRect(x: 0, y: 0, width: scrollViewWidth, height: outputViewHeight)

            if let textView = scrollView.documentView as? NSTextView {
                textView.isEditable = false
                textView.isSelectable = true
                textView.isRichText = false
                textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
                textView.textColor = .textColor
                textView.backgroundColor = .textBackgroundColor
                textView.drawsBackground = true
                textView.isAutomaticQuoteSubstitutionEnabled = false
                textView.isAutomaticDashSubstitutionEnabled = false
                textView.isAutomaticTextReplacementEnabled = false
                textView.isAutomaticSpellingCorrectionEnabled = false
                textView.isContinuousSpellCheckingEnabled = false
                textView.isGrammarCheckingEnabled = false
                textView.isHorizontallyResizable = false
                textView.isVerticallyResizable = true
                // Fixed width for word wrapping
                textView.textContainer?.widthTracksTextView = false
                textView.textContainer?.containerSize = NSSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude)
                textView.textContainerInset = NSSize(width: 6, height: 6)
                textView.string = content
                // Force layout with the fixed width
                textView.sizeToFit()
            }

            parent.addSubview(headerLabel)
            parent.addSubview(scrollView)

            NSLayoutConstraint.activate([
                headerLabel.topAnchor.constraint(equalTo: anchor, constant: pad),
                headerLabel.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: pad),
                headerLabel.widthAnchor.constraint(equalToConstant: labelWidth),

                scrollView.topAnchor.constraint(equalTo: anchor, constant: pad),
                scrollView.leadingAnchor.constraint(equalTo: headerLabel.trailingAnchor, constant: hSpacing),
                scrollView.widthAnchor.constraint(equalToConstant: scrollViewWidth),
                scrollView.heightAnchor.constraint(equalToConstant: outputViewHeight),
            ])

            return scrollView.bottomAnchor
        }

        if !result.stdout.isEmpty {
            previousBottom = addOutputSection(title: "STDOUT:", content: result.stdout, to: contentView, below: previousBottom)
        }

        if !result.stderr.isEmpty {
            previousBottom = addOutputSection(title: "STDERR:", content: result.stderr, to: contentView, below: previousBottom)
        }

        // ── Dismiss button ──

        let dismissBtn = makeIconButton(imageName: "bx-check-circle", toolTip: "OK")
        dismissBtn.target = self
        dismissBtn.action = #selector(dismissTestRunClicked(_:))
        contentView.addSubview(dismissBtn)

        NSLayoutConstraint.activate([
            // Header rows
            shellLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: pad),
            shellLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            shellLabel.widthAnchor.constraint(equalToConstant: labelWidth),

            shellValue.centerYAnchor.constraint(equalTo: shellLabel.centerYAnchor),
            shellValue.leadingAnchor.constraint(equalTo: shellLabel.trailingAnchor, constant: hSpacing),
            shellValue.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),

            commandLabel.topAnchor.constraint(equalTo: shellLabel.bottomAnchor, constant: hSpacing),
            commandLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            commandLabel.widthAnchor.constraint(equalToConstant: labelWidth),

            commandValue.centerYAnchor.constraint(equalTo: commandLabel.centerYAnchor),
            commandValue.leadingAnchor.constraint(equalTo: commandLabel.trailingAnchor, constant: hSpacing),
            commandValue.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -pad),

            exitCodeLabel.topAnchor.constraint(equalTo: commandLabel.bottomAnchor, constant: hSpacing),
            exitCodeLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: pad),
            exitCodeLabel.widthAnchor.constraint(equalToConstant: labelWidth),

            exitCodeValue.centerYAnchor.constraint(equalTo: exitCodeLabel.centerYAnchor),
            exitCodeValue.leadingAnchor.constraint(equalTo: exitCodeLabel.trailingAnchor, constant: hSpacing),

            // Dismiss button
            dismissBtn.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            dismissBtn.topAnchor.constraint(equalTo: previousBottom, constant: pad),
            dismissBtn.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -pad),
        ])

        // Auto-size the sheet to fit content - set fixed width first to ensure text wraps
        contentView.frame = NSRect(x: 0, y: 0, width: sheetWidth, height: 1000)
        contentView.layoutSubtreeIfNeeded()
        let fittingSize = contentView.fittingSize
        sheet.setFrame(NSRect(x: 0, y: 0, width: sheetWidth, height: fittingSize.height), display: false)

        testRunSheet = sheet
        window?.beginSheet(sheet)
    }

    private func closeTestRunSheet() {
        guard let sheet = testRunSheet else { return }
        window?.endSheet(sheet)
        testRunSheet = nil
    }

    // MARK: - Form Enable/Disable

    private func setFormEnabled(_ enabled: Bool) {
        actionField.isEnabled = enabled
        categoryField.isEnabled = enabled
        shortcutField.isEnabled = enabled
        commandField.isEnabled = enabled
        workdirField.isEnabled = enabled
        saveButton.isEnabled = enabled
        cancelButton.isEnabled = enabled
        testRunButton.isEnabled = enabled
    }

    // MARK: - Helpers

    /// Insert a shortcut at the end of its category in the config array.
    /// Uncategorized shortcuts are always appended at the very end.
    private func appendShortcutToCategory(_ shortcut: ShortcutConfig) {
        var shortcuts = ConfigManager.shared.config.shortcuts
        let category = shortcut.category

        if category.isEmpty {
            // Uncategorized — always at the end
            shortcuts.append(shortcut)
        } else {
            // Find the last shortcut with this category
            var lastInCategory = -1
            for (i, s) in shortcuts.enumerated() {
                if s.category == category {
                    lastInCategory = i
                }
            }

            if lastInCategory >= 0 {
                shortcuts.insert(shortcut, at: lastInCategory + 1)
            } else {
                // Category doesn't exist yet — insert before the first uncategorized shortcut
                var insertAt = shortcuts.count
                for (i, s) in shortcuts.enumerated() {
                    if s.category.isEmpty {
                        insertAt = i
                        break
                    }
                }
                shortcuts.insert(shortcut, at: insertAt)
            }
        }

        ConfigManager.shared.config.shortcuts = shortcuts
    }

    /// Collect unique non-empty category names from all existing shortcuts.
    private static func collectExistingCategories() -> [String] {
        let categories = Set(ConfigManager.shared.config.shortcuts.map { $0.category }.filter { !$0.isEmpty })
        return categories.sorted()
    }

    private func showValidationAlert(message: String, informativeText: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = informativeText
        alert.addButton(withTitle: "OK")
        alert.alertStyle = .warning
        alert.beginSheetModal(for: window!)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Sheet lifecycle is handled by beginSheet/endSheet callbacks
    }
}

// MARK: - NSTextFieldDelegate

extension ShortcutEditorWindowController: NSTextFieldDelegate {
    /// Intercept Return/Enter in text fields to trigger save instead of the default
    /// field editor behavior (which would just select all text).
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) ||
           commandSelector == #selector(NSResponder.insertNewlineIgnoringFieldEditor(_:)) {
            saveClicked(nil)
            return true
        }
        return false
    }
}
