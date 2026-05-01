import Cocoa
import Carbon

// MARK: - Hotkey errors

enum HotkeyError: Error, CustomStringConvertible {
    case notInitialized
    case alreadyRegistered
    case registrationFailed(OSStatus)
    case unregistrationFailed(OSStatus)
    case invalidKeyString(String)
    case unknownKey(String)

    var description: String {
        switch self {
        case .notInitialized: return "GlobalHotkeyManager is not initialized"
        case .alreadyRegistered: return "Hotkey is already registered"
        case .registrationFailed(let status): return "RegisterEventHotKey failed with status \(status)"
        case .unregistrationFailed(let status): return "UnregisterEventHotKey failed with status \(status)"
        case .invalidKeyString(let str): return "Invalid hotkey string: \"\(str)\""
        case .unknownKey(let key): return "Unknown key: \"\(key)\""
        }
    }
}

// MARK: - Hotkey identifier

struct HotkeyID: Hashable {
    let signature: FourCharCode
    let id: UInt32
}

// MARK: - Registered hotkey info

private class RegisteredHotkey {
    let hotkeyID: HotkeyID
    let carbonHotKeyID: EventHotKeyID
    let hotKeyRef: EventHotKeyRef
    let keyCode: UInt32
    let modifiers: UInt32
    let handler: () -> Void

    init(hotkeyID: HotkeyID, carbonHotKeyID: EventHotKeyID, hotKeyRef: EventHotKeyRef,
         keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        self.hotkeyID = hotkeyID
        self.carbonHotKeyID = carbonHotKeyID
        self.hotKeyRef = hotKeyRef
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.handler = handler
    }
}

// MARK: - Key code table

/// Layout-agnostic mapping of key characters/names to Carbon virtual key codes.
/// These correspond to physical key positions on the standard Apple keyboard
/// and are independent of the active input source.
private let keyCodes: [String: UInt32] = [
    // Letters
    "A": 0x00, "S": 0x01, "D": 0x02, "F": 0x03, "H": 0x04,
    "G": 0x05, "Z": 0x06, "X": 0x07, "C": 0x08, "V": 0x09,
    "B": 0x0B, "Q": 0x0C, "W": 0x0D, "E": 0x0E, "R": 0x0F,
    "Y": 0x10, "T": 0x11, "O": 0x1F, "U": 0x20, "I": 0x22,
    "P": 0x23, "L": 0x25, "J": 0x26, "K": 0x28, "N": 0x2D,
    "M": 0x2E,

    // Numbers and shifted symbols
    "1": 0x12, "!": 0x12,
    "2": 0x13, "@": 0x13,
    "3": 0x14, "#": 0x14,
    "4": 0x15, "$": 0x15,
    "5": 0x17, "%": 0x17,
    "6": 0x16, "^": 0x16,
    "7": 0x1A, "&": 0x1A,
    "8": 0x1C, "*": 0x1C,
    "9": 0x19, "(": 0x19,
    "0": 0x1D, ")": 0x1D,

    // Punctuation and shifted symbols
    "-": 0x1B, "_": 0x1B,
    "=": 0x18, "+": 0x18,
    "[": 0x21, "{": 0x21,
    "]": 0x1E, "}": 0x1E,
    ";": 0x29, ":": 0x29,
    "'": 0x27, "\"": 0x27,
    "\\": 0x2A, "|": 0x2A,
    ",": 0x2B, "<": 0x2B,
    "/": 0x2C, "?": 0x2C,
    ".": 0x2F, ">": 0x2F,
    "`": 0x32, "~": 0x32,

    // Section sign (Apple keyboard specific)
    "§": 0x0A, "±": 0x0A,

    // Unicode key symbols (canonical display format)
    "␣":  0x31,  // Space
    "⎋":  0x35,  // Escape
    "↩":  0x24,  // Return
    "⌤":  0x4C,  // Enter
    "⇪":  0x39,  // CAPS
    "⤒":  0x73,  // Home
    "⤓":  0x77,  // End
    "⇞":  0x74,  // PgUp
    "⇟":  0x79,  // PgDown
    "⌫":  0x33,  // Backspace / Del
    "⌦":  0x75,  // Forward Delete
    "⇥":  0x30,  // Tab

    // Text key names (for keys without standard Unicode symbols)
    "F1":     0x7A,
    "F2":     0x78,
    "F3":     0x63,
    "F4":     0x76,
    "F5":     0x60,
    "F6":     0x61,
    "F7":     0x62,
    "F8":     0x64,
    "F9":     0x65,
    "F10":    0x6D,
    "F11":    0x67,
    "F12":    0x6F,
    "F13":    0x69,
    "F14":    0x6B,
    "F15":    0x71,
    "F16":    0x6A,
    "F17":    0x40,
    "F18":    0x4F,
    "F19":    0x50,
    "F20":    0x5A,
    "Clear":  0x47,
]

// MARK: - GlobalHotkeyManager

class GlobalHotkeyManager {
    static let shared = GlobalHotkeyManager()

    /// FourCharCode signature used for all hotkey IDs registered by this manager
    let signature: FourCharCode

    private var registeredHotkeys: [HotkeyID: RegisteredHotkey] = [:]
    private var nextID: UInt32 = 1
    private var eventHandlerRef: EventHandlerRef?
    private var initialized = false

    private init(signature: FourCharCode = fourCharCode(from: "ichs")) {
        self.signature = signature
    }

    // MARK: - Public API

    /// Initialize the Carbon event handler. Must be called before registering hotkeys.
    /// This is called automatically on first registration, but you can call it explicitly.
    func initialize() throws {
        guard !initialized else { return }

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        // We need a stable reference to `self` inside the closure.
        // Use Unmanaged to pass self as userData.
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { (nextHandler: EventHandlerCallRef?, theEvent: EventRef?, userData: UnsafeMutableRawPointer?) -> OSStatus in
                guard let userData = userData else { return OSStatus(eventNotHandledErr) }
                guard let theEvent = theEvent else { return OSStatus(eventNotHandledErr) }

                let manager = Unmanaged<GlobalHotkeyManager>.fromOpaque(userData).takeUnretainedValue()

                var hkCom = EventHotKeyID()
                let paramStatus = GetEventParameter(
                    theEvent,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &hkCom
                )

                if paramStatus == noErr {
                    let hotkeyID = HotkeyID(signature: hkCom.signature, id: hkCom.id)
                    manager.handleHotkey(hotkeyID: hotkeyID)
                }

                return noErr
            },
            1,
            &eventType,
            selfPtr,
            &eventHandlerRef
        )

        if status != noErr {
            throw HotkeyError.registrationFailed(status)
        }

        initialized = true
    }

    /// Register a global hotkey using a Carbon key code and Cocoa modifier flags.
    /// - Parameters:
    ///   - keyCode: Carbon virtual key code (e.g. `kVK_ANSI_G`)
    ///   - modifiers: Cocoa modifier flags (e.g. `[.command, .shift]`)
    ///   - handler: Closure to call when the hotkey is pressed
    /// - Returns: A `HotkeyID` that can be used to unregister the hotkey
    @discardableResult
    func register(keyCode: UInt32, modifiers: NSEvent.ModifierFlags, handler: @escaping () -> Void) throws -> HotkeyID {
        try initialize()

        let id = nextID
        nextID += 1

        let carbonModifiers = Self.carbonFlags(from: modifiers)
        let hotkeyID = HotkeyID(signature: signature, id: id)
        let carbonHotKeyID = EventHotKeyID(signature: signature, id: id)
        var hotKeyRef: EventHotKeyRef?

        let status = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            carbonHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )

        if status != noErr {
            throw HotkeyError.registrationFailed(status)
        }

        guard let ref = hotKeyRef else {
            throw HotkeyError.registrationFailed(-1)
        }

        registeredHotkeys[hotkeyID] = RegisteredHotkey(
            hotkeyID: hotkeyID,
            carbonHotKeyID: carbonHotKeyID,
            hotKeyRef: ref,
            keyCode: keyCode,
            modifiers: carbonModifiers,
            handler: handler
        )

        return hotkeyID
    }

    /// Register a global hotkey using a string representation.
    /// Supports Unicode modifier symbols: ⌘ (cmd), ⇧ (shift), ⌥ (option), ⌃ (control)
    /// The key portion is resolved via a layout-agnostic hardcoded table, so hotkeys
    /// work regardless of the active keyboard input source.
    /// - Parameters:
    ///   - hotkeyString: String like "⌘⇧G", "⌃⌥F19", or "⇧Clear"
    ///   - handler: Closure to call when the hotkey is pressed
    /// - Returns: A `HotkeyID` that can be used to unregister the hotkey
    @discardableResult
    func register(hotkeyString: String, handler: @escaping () -> Void) throws -> HotkeyID {
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

        guard !keyPart.isEmpty else {
            throw HotkeyError.invalidKeyString(hotkeyString)
        }

        // Look up the key in the layout-agnostic table
        guard let keyCode = keyCodes[keyPart] else {
            throw HotkeyError.unknownKey(keyPart)
        }

        return try register(keyCode: keyCode, modifiers: modifiers, handler: handler)
    }

    /// Unregister a previously registered hotkey.
    func unregister(_ hotkeyID: HotkeyID) throws {
        guard let entry = registeredHotkeys[hotkeyID] else { return }

        let status = UnregisterEventHotKey(entry.hotKeyRef)
        if status != noErr {
            throw HotkeyError.unregistrationFailed(status)
        }

        registeredHotkeys.removeValue(forKey: hotkeyID)
    }

    /// Unregister all registered hotkeys.
    func unregisterAll() {
        for (_, entry) in registeredHotkeys {
            UnregisterEventHotKey(entry.hotKeyRef)
        }
        registeredHotkeys.removeAll()
    }

    // MARK: - Internal

    private func handleHotkey(hotkeyID: HotkeyID) {
        if let entry = registeredHotkeys[hotkeyID] {
            entry.handler()
        }
    }

    // MARK: - Modifier conversion

    /// Convert Cocoa modifier flags to Carbon modifier flags.
    static func carbonFlags(from cocoaFlags: NSEvent.ModifierFlags) -> UInt32 {
        var flags: UInt32 = 0
        if cocoaFlags.contains(.command)  { flags |= UInt32(cmdKey) }
        if cocoaFlags.contains(.shift)    { flags |= UInt32(shiftKey) }
        if cocoaFlags.contains(.option)   { flags |= UInt32(optionKey) }
        if cocoaFlags.contains(.control)  { flags |= UInt32(controlKey) }
        if cocoaFlags.contains(.capsLock) { flags |= UInt32(alphaLock) }
        return flags
    }

    // MARK: - Validation

    /// Validate that a hotkey string conforms to the expected Unicode representation.
    /// A valid string must contain at least one modifier symbol (⌘⇧⌥⌃) followed by
    /// a key that exists in the layout-agnostic key code table.
    static func isValidHotkeyString(_ string: String) -> Bool {
        guard !string.isEmpty else { return false }

        var modifiers: NSEvent.ModifierFlags = []
        var keyPart = ""

        for char in string {
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

        // Must have a key part
        guard !keyPart.isEmpty else { return false }

        // Key must exist in the key code table
        guard keyCodes[keyPart] != nil else { return false }

        // Named keys (F1-F20, ⎋, ↩, etc.) are valid with or without modifiers
        if keyPart.count > 1 {
            return true
        }

        // Single printable characters require at least one modifier
        return !modifiers.isEmpty
    }

    // MARK: - Utility

    /// Convert a 4-character ASCII string to a FourCharCode (OSType).
    static func fourCharCode(from string: String) -> FourCharCode {
        var result: FourCharCode = 0
        for char in string.utf8 {
            result = (result << 8) | FourCharCode(char)
        }
        return result
    }
}
