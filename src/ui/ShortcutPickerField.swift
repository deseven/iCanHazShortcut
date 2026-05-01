import Cocoa

// MARK: - ShortcutPickerFieldDelegate

protocol ShortcutPickerFieldDelegate: AnyObject {
    func shortcutPickerDidChange(_ picker: ShortcutPickerField)
}

// MARK: - ShortcutPickerField

/// A custom view that captures keyboard shortcuts interactively.
/// When the user clicks the field, it enters recording mode and displays
/// modifier symbols as they are held. When a non-modifier key is pressed,
/// the shortcut is registered and displayed in the canonical format
/// (e.g. "⌃⌥⇧⌘T"). A clear button allows resetting the field.
///
/// The produced string is layout-agnostic: key codes are mapped to ANSI
/// key names via the same table used by `GlobalHotkeyManager`.
final class ShortcutPickerField: NSView {

    // MARK: - Public properties

    /// The current hotkey string in canonical format (e.g. "⌘⇧T"), or empty if none.
    var stringValue: String {
        if isPlaceholder { return "" }
        return label.stringValue
    }

    /// Whether a valid shortcut is currently set.
    var hasValue: Bool {
        return !isPlaceholder && !label.stringValue.isEmpty
    }

    /// Whether the field is enabled for interaction.
    var isEnabled: Bool = true {
        didSet {
            clearButton.isEnabled = isEnabled
            updateAppearance()
        }
    }

    weak var pickerDelegate: ShortcutPickerFieldDelegate?

    // MARK: - Private state

    private(set) var isRecording = false
    private var currentModifiers: NSEvent.ModifierFlags = []
    private var previousValue: String = ""
    private var isPlaceholder = false

    // MARK: - Subviews

    private let label = NSTextField(labelWithString: "")
    private let clearButton = NSButton(frame: .zero)

    // MARK: - Constants

    private static let clearButtonWidth: CGFloat = 18
    private static let clearButtonHeight: CGFloat = 18
    private static let horizontalPadding: CGFloat = 7
    private static let clearButtonTrailingPadding: CGFloat = 4

    // MARK: - Init

    override init(frame: NSRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.cornerRadius = 4
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.separatorColor.cgColor
        layer?.backgroundColor = NSColor.textBackgroundColor.cgColor

        // Label
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        label.textColor = .labelColor
        label.alignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)

        // Clear button (×)
        clearButton.bezelStyle = .inline
        clearButton.isBordered = false
        clearButton.imagePosition = .imageOnly
        clearButton.toolTip = "Clear shortcut"
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.contentTintColor = .tertiaryLabelColor
        clearButton.action = #selector(clearClicked(_:))
        clearButton.target = self
        clearButton.isHidden = true

        // Use a simple × character as the button image
        let clearAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .bold),
            .foregroundColor: NSColor.tertiaryLabelColor,
        ]
        let clearImage = NSAttributedString(string: "×", attributes: clearAttrs)
        clearButton.attributedTitle = clearImage
        clearButton.sizeToFit()

        addSubview(clearButton)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.horizontalPadding),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.trailingAnchor.constraint(lessThanOrEqualTo: clearButton.leadingAnchor, constant: -2),

            clearButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.clearButtonTrailingPadding),
            clearButton.centerYAnchor.constraint(equalTo: centerYAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: Self.clearButtonWidth),
            clearButton.heightAnchor.constraint(equalToConstant: Self.clearButtonHeight),
        ])

        updateAppearance()
    }

    // MARK: - Public methods

    /// Set the hotkey string programmatically (e.g. when editing an existing shortcut).
    func setStringValue(_ value: String) {
        isPlaceholder = false
        label.stringValue = value
        clearButton.isHidden = value.isEmpty
        updateAppearance()
    }

    // MARK: - First responder

    override var acceptsFirstResponder: Bool { isEnabled }

    override var needsPanelToBecomeKey: Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled else { return }
        if window?.firstResponder === self && !isRecording {
            // Already first responder but not recording (e.g. after Escape) — restart recording
            startRecording()
        } else {
            window?.makeFirstResponder(self)
        }
    }

    override func becomeFirstResponder() -> Bool {
        guard isEnabled else { return false }
        let accepted = super.becomeFirstResponder()
        if accepted {
            startRecording()
        }
        return accepted
    }

    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned {
            stopRecording()
        }
        return resigned
    }

    // MARK: - Recording state

    private func startRecording() {
        isRecording = true
        currentModifiers = []
        // Save current value so we can restore on Escape
        previousValue = hasValue ? label.stringValue : ""
        // Clear the display for recording
        showPlaceholder("Press keys…")
        layer?.borderColor = NSColor.controlAccentColor.cgColor
        layer?.backgroundColor = NSColor.controlAccentColor.withAlphaComponent(0.06).cgColor
        clearButton.isHidden = true
    }

    private func stopRecording() {
        isRecording = false
        currentModifiers = []
        // If no new shortcut was recorded, restore the previous value
        if isPlaceholder || label.stringValue.isEmpty {
            if !previousValue.isEmpty {
                isPlaceholder = false
                label.stringValue = previousValue
                label.textColor = .labelColor
            }
        }
        updateAppearance()
    }

    func cancelRecording() {
        isRecording = false
        currentModifiers = []
        // Restore the previous value
        if !previousValue.isEmpty {
            isPlaceholder = false
            label.stringValue = previousValue
            label.textColor = .labelColor
        } else {
            isPlaceholder = false
            label.stringValue = ""
        }
        updateAppearance()
        // Resign first responder so re-clicking can trigger becomeFirstResponder
        window?.makeFirstResponder(nil)
    }

    private func updateAppearance() {
        if !isEnabled {
            layer?.borderColor = NSColor.disabledControlTextColor.cgColor
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            label.textColor = .disabledControlTextColor
            clearButton.isHidden = true
            return
        }
        if hasValue {
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
            label.textColor = .labelColor
            clearButton.isHidden = false
        } else {
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.backgroundColor = NSColor.textBackgroundColor.cgColor
            showPlaceholder("Click to record")
            clearButton.isHidden = true
        }
    }

    // MARK: - Placeholder helper

    /// Display placeholder text in the label with appropriate styling.
    /// We can't use NSTextField.placeholderString because our label is non-editable,
    /// so we simulate it by setting the text directly with placeholder styling.
    private func showPlaceholder(_ text: String) {
        isPlaceholder = true
        label.stringValue = text
        label.textColor = .placeholderTextColor
    }

    // MARK: - Key handling

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        // Escape cancels recording and restores previous value
        if event.keyCode == 0x35 {
            cancelRecording()
            return
        }

        // Tab / Shift-Tab should navigate key view loop, not register as shortcut.
        // Reset to placeholder first so stopRecording() restores the previous value
        // (the current display may show modifier-only text like "⇧" which is not a valid shortcut).
        if event.keyCode == 0x30 {
            showPlaceholder("Press keys…")
            stopRecording()
            super.keyDown(with: event)
            return
        }

        // Return without modifiers cancels recording and resigns first responder;
        // with modifiers (e.g. ⌘↩) it registers as a shortcut
        if event.keyCode == 0x24 && !event.modifierFlags.intersection([.control, .option, .shift, .command]).isEmpty {
            // Fall through to register as shortcut
        } else if event.keyCode == 0x24 {
            stopRecording()
            window?.makeFirstResponder(nil)
            return
        }

        let keyCode = UInt32(event.keyCode)
        let modifiers = event.modifierFlags.intersection([.control, .option, .shift, .command])

        // Check if this is a valid key (known in our table)
        guard GlobalHotkeyManager.hotkeyString(keyCode: keyCode, modifiers: modifiers) != nil else {
            NSSound.beep()
            return
        }

        // Check if the combination is valid (non-F-keys need at least one non-shift modifier)
        guard GlobalHotkeyManager.isValidHotkey(keyCode: keyCode, modifiers: modifiers) else {
            // Show just the key without modifiers as feedback
            if let keyStr = GlobalHotkeyManager.keyString(for: keyCode) {
                isPlaceholder = false
                label.stringValue = keyStr
                label.textColor = .disabledControlTextColor
            }
            return
        }

        // Valid shortcut — register it
        if let hotkeyString = GlobalHotkeyManager.hotkeyString(keyCode: keyCode, modifiers: modifiers) {
            isPlaceholder = false
            label.stringValue = hotkeyString
            label.textColor = .labelColor
            clearButton.isHidden = false
            isRecording = false
            currentModifiers = []
            // Move focus to the next field in the key view loop
            if let next = nextKeyView {
                window?.makeFirstResponder(next)
            } else {
                window?.makeFirstResponder(nil)
            }
            pickerDelegate?.shortcutPickerDidChange(self)
        }
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else {
            super.flagsChanged(with: event)
            return
        }

        currentModifiers = event.modifierFlags.intersection([.control, .option, .shift, .command])

        // Build the modifier-only display string
        var display = ""
        if currentModifiers.contains(.control) { display += "⌃" }
        if currentModifiers.contains(.option)  { display += "⌥" }
        if currentModifiers.contains(.shift)   { display += "⇧" }
        if currentModifiers.contains(.command) { display += "⌘" }

        if display.isEmpty {
            // No modifiers held — show placeholder
            showPlaceholder("Press keys…")
        } else {
            isPlaceholder = false
            label.stringValue = display
            label.textColor = .tertiaryLabelColor
            clearButton.isHidden = true
        }
    }

    // MARK: - Clear button

    @objc private func clearClicked(_ sender: NSButton) {
        isPlaceholder = false
        label.stringValue = ""
        updateAppearance()
        pickerDelegate?.shortcutPickerDidChange(self)
    }

    // MARK: - Cursor

    override func resetCursorRects() {
        // I-beam cursor over the main field area
        let fieldRect = NSRect(x: 0, y: 0, width: bounds.width - Self.clearButtonWidth, height: bounds.height)
        addCursorRect(fieldRect, cursor: .iBeam)

        // Pointing hand cursor over the clear button
        if !clearButton.isHidden {
            let clearRect = NSRect(
                x: bounds.width - Self.clearButtonWidth - Self.clearButtonTrailingPadding,
                y: (bounds.height - Self.clearButtonHeight) / 2,
                width: Self.clearButtonWidth + Self.clearButtonTrailingPadding,
                height: Self.clearButtonHeight
            )
            addCursorRect(clearRect, cursor: .pointingHand)
        }
    }

    // MARK: - Accessibility

    override func accessibilityLabel() -> String? {
        return hasValue ? "Shortcut: \(stringValue)" : "Shortcut picker"
    }

    override func accessibilityRole() -> NSAccessibility.Role? {
        .textField
    }
}
