import Cocoa
import Carbon

// MARK: - Hotkey errors

enum HotkeyError: Error, CustomStringConvertible {
    case notInitialized
    case alreadyRegistered
    case registrationFailed(OSStatus)
    case unregistrationFailed(OSStatus)
    case invalidKeyString(String)
    case keyCodeNotFound(Character)

    var description: String {
        switch self {
        case .notInitialized: return "GlobalHotkeyManager is not initialized"
        case .alreadyRegistered: return "Hotkey is already registered"
        case .registrationFailed(let status): return "RegisterEventHotKey failed with status \(status)"
        case .unregistrationFailed(let status): return "UnregisterEventHotKey failed with status \(status)"
        case .invalidKeyString(let str): return "Invalid hotkey string: \"\(str)\""
        case .keyCodeNotFound(let char): return "Could not resolve key code for character \"\(char)\""
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

// MARK: - Named key codes

/// Mapping of key names (Unicode symbols and text) to Carbon virtual key codes.
/// Unicode symbols are the canonical format; text names are kept for keys that
/// have no standard Unicode representation (F-keys, Clear, etc.).
private let namedKeyCodes: [String: UInt32] = [
    // Unicode symbols (canonical)
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

    // Text names (for keys without standard Unicode symbols)
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
    /// The key portion can be:
    /// - A single printable character resolved via UCKeyTranslate (e.g. "G", "1")
    /// - A Unicode key symbol from `namedKeyCodes` (e.g. "⎋", "↩", "␣")
    /// - A text key name from `namedKeyCodes` (e.g. "F19", "Clear")
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

        // Try named key lookup first (Unicode symbols and text names like F19, Clear)
        if let keyCode = namedKeyCodes[keyPart] {
            return try register(keyCode: keyCode, modifiers: modifiers, handler: handler)
        }

        // Fall back to UCKeyTranslate for single printable characters
        guard keyPart.count == 1, let keyChar = keyPart.first else {
            throw HotkeyError.invalidKeyString(hotkeyString)
        }

        guard let keyCode = Self.keyCode(for: keyChar) else {
            throw HotkeyError.keyCodeNotFound(keyChar)
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

    // MARK: - Key code resolution via UCKeyTranslate

    /// Resolve a character to a Carbon virtual key code using the current keyboard layout.
    /// This is locale-aware and does not rely on hardcoded tables.
    static func keyCode(for char: Character) -> UInt32? {
        let inputSource = TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue()
        guard let layoutData = TISGetInputSourceProperty(inputSource, kTISPropertyUnicodeKeyLayoutData) else {
            return nil
        }
        let keyboardLayout = Unmanaged<CFData>.fromOpaque(layoutData).takeUnretainedValue() as Data

        return keyboardLayout.withUnsafeBytes { (rawPtr: UnsafeRawBufferPointer) in
            guard let basePtr = rawPtr.baseAddress else { return nil as UInt32? }
            let ucKeyboard = basePtr.assumingMemoryBound(to: UCKeyboardLayout.self)

            let unicodeScalars = String(char).unicodeScalars
            guard let targetScalar = unicodeScalars.first else { return nil as UInt32? }
            let targetChar = targetScalar.value

            var deadKeyState: UInt32 = 0
            var maxStringLength: Int = 4
            var actualStringLength: Int = 0
            var unicodeString = [UniChar](repeating: 0, count: maxStringLength)

            // Try key codes 0-127
            for keyCode in 0..<128 {
                deadKeyState = 0
                maxStringLength = 4
                actualStringLength = 0

                let status = UCKeyTranslate(
                    ucKeyboard,
                    UInt16(keyCode),
                    UInt16(kUCKeyActionDisplay),
                    0, // No modifiers for base character lookup
                    UInt32(LMGetKbdType()),
                    0, // kUCKeyTranslateNoDeadKeysBit
                    &deadKeyState,
                    maxStringLength,
                    &actualStringLength,
                    &unicodeString
                )

                if status == noErr && actualStringLength > 0 {
                    let producedScalar = Int(unicodeString[0])
                    if producedScalar == targetChar {
                        return UInt32(keyCode)
                    }
                }
            }

            return nil as UInt32?
        }
    }

    // MARK: - Validation

    /// Validate that a hotkey string conforms to the expected Unicode representation.
    /// A valid string must contain at least one modifier symbol (⌘⇧⌥⌃) followed by
    /// a single key character or a named key (e.g. F1, ⎋, ↩).
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

        // Named keys (F1-F20, ⎋, ↩, etc.) are valid with or without modifiers
        if namedKeyCodes[keyPart] != nil {
            return true
        }

        // Single printable characters require at least one modifier
        if keyPart.count == 1 {
            return !modifiers.isEmpty
        }

        return false
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
