import Carbon
import Cocoa
import Testing
@testable import iCanHazShortcut

extension AllTests {
    @Suite("GlobalHotkeyManager validation")
    struct GlobalHotkeyValidationTests {

        // MARK: - isValidHotkeyString

        @Test("accepts modifier+key combinations")
        func acceptsModifierCombos() {
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌘G") == true)
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌘⇧G") == true)
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌥⌘F") == true)
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌃⌥⌘⇧1") == true)
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌘⇧␣") == true)      // Space
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌃⌥F19") == true)
            #expect(GlobalHotkeyManager.isValidHotkeyString("⇧Clear") == true)
        }

        @Test("rejects empty string")
        func rejectsEmpty() {
            #expect(GlobalHotkeyManager.isValidHotkeyString("") == false)
        }

        @Test("rejects strings with no key part")
        func rejectsNoKey() {
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌘") == false)
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌘⇧") == false)
        }

        @Test("rejects unknown keys")
        func rejectsUnknownKey() {
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌘X") == true)   // X is known
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌘Ü") == false)  // Ü is not in table
        }

        @Test("allows F-keys without modifiers")
        func allowsFKeysWithoutModifiers() {
            #expect(GlobalHotkeyManager.isValidHotkeyString("F13") == true)
            #expect(GlobalHotkeyManager.isValidHotkeyString("F20") == true)
        }

        @Test("rejects bare letter without modifier")
        func rejectsBareLetter() {
            #expect(GlobalHotkeyManager.isValidHotkeyString("G") == false)
        }

        @Test("rejects shift-only letter (typing conflict)")
        func rejectsShiftOnlyLetter() {
            #expect(GlobalHotkeyManager.isValidHotkeyString("⇧G") == false)
        }

        @Test("allows shift-only for non-typing keys")
        func allowsShiftOnlyNonTyping() {
            #expect(GlobalHotkeyManager.isValidHotkeyString("⇧F5") == true)
            #expect(GlobalHotkeyManager.isValidHotkeyString("⇧↑") == true)
        }

        @Test("allows shift-only special keys")
        func allowsShiftOnlySpecial() {
            #expect(GlobalHotkeyManager.isValidHotkeyString("⇧⎋") == true)
            #expect(GlobalHotkeyManager.isValidHotkeyString("⇧⌫") == true)
        }

        @Test("allows any combo with at least one non-shift modifier")
        func allowsNonShiftModifierCombo() {
            #expect(GlobalHotkeyManager.isValidHotkeyString("⌃⇧G") == true)
        }

        // MARK: - isValidHotkey (key code + modifier flags)

        @Test("validates by key code and modifiers")
        func validatesByKeyCode() {
            // Letter G (0x05) with command → valid
            #expect(GlobalHotkeyManager.isValidHotkey(keyCode: 0x05, modifiers: [.command]) == true)
            // Letter G with no modifiers → invalid
            #expect(GlobalHotkeyManager.isValidHotkey(keyCode: 0x05, modifiers: []) == false)
            // F13 (0x69) with no modifiers → valid (F-key)
            #expect(GlobalHotkeyManager.isValidHotkey(keyCode: 0x69, modifiers: []) == true)
            // Unknown key code → invalid
            #expect(GlobalHotkeyManager.isValidHotkey(keyCode: 0x7F, modifiers: [.command]) == false)
            // Shift-only letter → invalid
            #expect(GlobalHotkeyManager.isValidHotkey(keyCode: 0x05, modifiers: [.shift]) == false)
            // Shift-only F-key → valid
            #expect(GlobalHotkeyManager.isValidHotkey(keyCode: 0x69, modifiers: [.shift]) == true)
            // Non-shift modifier combo → valid
            #expect(GlobalHotkeyManager.isValidHotkey(keyCode: 0x05, modifiers: [.command, .shift]) == true)
        }

        // MARK: - hotkeyString / keyString (canonical representation)

        @Test("builds canonical hotkey strings")
        func buildsCanonicalString() {
            // Modifiers emit in canonical order: control, option, shift, command
            #expect(GlobalHotkeyManager.hotkeyString(keyCode: 0x05, modifiers: [.command, .shift]) == "⇧⌘G")
            #expect(GlobalHotkeyManager.hotkeyString(keyCode: 0x05, modifiers: [.command]) == "⌘G")
            #expect(GlobalHotkeyManager.hotkeyString(keyCode: 0x31, modifiers: [.control, .option, .shift, .command]) == "⌃⌥⇧⌘␣")
            #expect(GlobalHotkeyManager.hotkeyString(keyCode: 0x69, modifiers: []) == "F13")
            #expect(GlobalHotkeyManager.hotkeyString(keyCode: 0x7F, modifiers: [.command]) == nil)
        }

        @Test("key string lookup")
        func keyStringLookup() {
            #expect(GlobalHotkeyManager.keyString(for: 0x00) == "A")
            #expect(GlobalHotkeyManager.keyString(for: 0x35) == "⎋")
            #expect(GlobalHotkeyManager.keyString(for: 0x7F) == nil)
        }

        // MARK: - fourCharCode / carbonFlags utility

        @Test("fourCharCode")
        func fourCharCode() {
            #expect(GlobalHotkeyManager.fourCharCode(from: "ichs") == 0x69636873)
        }

        @Test("carbonFlags maps modifiers")
        func carbonFlags() {
            #expect(GlobalHotkeyManager.carbonFlags(from: []) == 0)
            #expect(GlobalHotkeyManager.carbonFlags(from: [.command]) == UInt32(cmdKey))
            #expect(GlobalHotkeyManager.carbonFlags(from: [.command, .shift]) == UInt32(cmdKey) | UInt32(shiftKey))
        }
    }
}