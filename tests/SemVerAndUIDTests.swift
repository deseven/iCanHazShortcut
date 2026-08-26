import Foundation
import Testing
@testable import iCanHazShortcut

extension AllTests {
    @Suite("SemVer")
    struct SemVerTests {

        @Test("parses major.minor.patch")
        func parsesFull() {
            let v = SemVer("2.1.3")
            #expect(v.major == 2)
            #expect(v.minor == 1)
            #expect(v.patch == 3)
        }

        @Test("parses partial version strings")
        func parsesPartial() {
            #expect(SemVer("2") == SemVer("2.0.0"))
            #expect(SemVer("2.1") == SemVer("2.1.0"))
            #expect(SemVer("") == SemVer("0.0.0"))
        }

        @Test("compares correctly")
        func compares() {
            #expect(SemVer("2.0.0") > SemVer("1.9.9"))
            #expect(SemVer("2.1.0") > SemVer("2.0.9"))
            #expect(SemVer("2.0.1") > SemVer("2.0.0"))
            #expect(SemVer("1.0.0") < SemVer("2.0.0"))
            #expect(SemVer("1.0.0") == SemVer("1.0.0"))
            #expect(SemVer("1.0.1") > SemVer("1.0.0"))
        }

        @Test("non-numeric segments stop parsing")
        func ignoresNonNumeric() {
            // SemVer.init splits on "." and compactMaps Int; "1.2.3-beta"
            // yields [1,2,3]? No — "3-beta" isn't an Int, so it becomes [1,2].
            #expect(SemVer("1.2.3-beta").major == 1)
            #expect(SemVer("1.2.3-beta").minor == 2)
            #expect(SemVer("1.2.3-beta").patch == 0)
            #expect(SemVer("v1.0.0").major == 0)  // "v1" isn't numeric
        }

        @Test("sorts releases")
        func sorts() {
            let versions = ["1.9.9", "2.0.0", "1.10.0", "0.5.0"].map(SemVer.init)
            let sorted = versions.sorted()
            #expect(sorted.map(\.major) == [0, 1, 1, 2])
            #expect(sorted.map(\.minor) == [5, 9, 10, 0])
        }
    }

    @Suite("ShortcutConfig uid")
    struct ShortcutConfigUIDTests {

        @Test("uid is stable for same action+command")
        func uidStable() {
            let a = ShortcutConfig(shortcut: "⌘G", action: "lock screen", command: "pmset displaysleepnow")
            let b = ShortcutConfig(shortcut: "⌘H", action: "lock screen", command: "pmset displaysleepnow")
            #expect(a.uid == b.uid)
        }

        @Test("uid differs for different commands")
        func uidDiffersOnCommand() {
            let a = ShortcutConfig(shortcut: "⌘G", action: "lock screen", command: "pmset displaysleepnow")
            let b = ShortcutConfig(shortcut: "⌘G", action: "lock screen", command: "echo nope")
            #expect(a.uid != b.uid)
        }

        @Test("uid differs for different actions")
        func uidDiffersOnAction() {
            let a = ShortcutConfig(shortcut: "⌘G", action: "lock", command: "pmset")
            let b = ShortcutConfig(shortcut: "⌘G", action: "unlock", command: "pmset")
            #expect(a.uid != b.uid)
        }

        @Test("uid is 10 hex chars, lowercase")
        func uidFormat() {
            let s = ShortcutConfig(shortcut: "⌘G", action: "lock screen", command: "pmset displaysleepnow")
            #expect(s.uid.count == 10)
            // uid is a hex digest; digits or a-f lowercase
            #expect(s.uid.allSatisfy { $0.isHexDigit })
            #expect(s.uid == s.uid.lowercased())
        }

        @Test("uid ignores shortcut and workdir")
        func uidIgnoresShortcutAndWorkdir() {
            let a = ShortcutConfig(shortcut: "⌘⇧G", action: "x", command: "y", workdir: "/a")
            let b = ShortcutConfig(shortcut: "⌘H", action: "x", command: "y", workdir: "/b")
            #expect(a.uid == b.uid)
        }
    }
}