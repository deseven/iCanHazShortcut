import Foundation
import Testing
@testable import iCanHazShortcut

extension AllTests {
    @Suite("INIParser")
    struct INIParserTests {

        // MARK: - Basic parsing

        @Test("parses sections and key-value pairs")
        func parsesSectionsAndPairs() {
            let ini = INIParser.parse(content: """
            [main]
            shell = /bin/zsh
            populate_menu_with_actions = yes

            [shortcut1]
            shortcut = ⌘⇧G
            action = lock screen
            """)

            #expect(ini.sections["main"]?["shell"] == "/bin/zsh")
            #expect(ini.sections["main"]?["populate_menu_with_actions"] == "yes")
            #expect(ini.sections["shortcut1"]?["shortcut"] == "⌘⇧G")
            #expect(ini.sections["shortcut1"]?["action"] == "lock screen")
        }

        @Test("preserves section order")
        func preservesSectionOrder() {
            let ini = INIParser.parse(content: """
            [b]
            x = 1
            [a]
            y = 2
            [main]
            z = 3
            """)

            #expect(ini.sectionOrder == ["b", "a", "main"])
        }

        @Test("trims whitespace around keys and values")
        func trimsWhitespace() {
            let ini = INIParser.parse(content: """
            [main]
                shell        =    /bin/bash -l   
            """)

            #expect(ini.sections["main"]?["shell"] == "/bin/bash -l")
        }

        @Test("skips comments and blank lines")
        func skipsCommentsAndBlankLines() {
            let ini = INIParser.parse(content: """
            # leading comment

            ; semicolon comment
            [main]
            # inline section comment
            shell = /bin/zsh
            ; inline pair comment
            start_on_login = no
            """)

            #expect(ini.sections["main"]?["shell"] == "/bin/zsh")
            #expect(ini.sections["main"]?["start_on_login"] == "no")
        }

        @Test("strips UTF-8 BOM")
        func stripsBOM() {
            let content = "\u{FEFF}[main]\nshell = /bin/zsh\n"
            let ini = INIParser.parse(content: content)
            #expect(ini.sections["main"]?["shell"] == "/bin/zsh")
        }

        @Test("handles empty values")
        func handlesEmptyValues() {
            let ini = INIParser.parse(content: """
            [main]
            shell =
            """)

            #expect(ini.sections["main"]?["shell"] == "")
        }

        @Test("splits on first '=' only")
        func splitsOnFirstEquals() {
            let ini = INIParser.parse(content: """
            [main]
            command = echo a=b=c
            """)

            #expect(ini.sections["main"]?["command"] == "echo a=b=c")
        }

        @Test("handles CRLF line endings")
        func handlesCRLF() {
            let ini = INIParser.parse(content: "[main]\r\nshell = /bin/zsh\r\n")
            #expect(ini.sections["main"]?["shell"] == "/bin/zsh")
        }

        @Test("key-value pairs before any section go into empty section")
        func pairsBeforeSection() {
            let ini = INIParser.parse(content: "shell = /bin/zsh\n")
            #expect(ini.sections[""]?["shell"] == "/bin/zsh")
        }

        @Test("duplicate sections merge")
        func duplicateSectionsMerge() {
            let ini = INIParser.parse(content: """
            [main]
            a = 1
            [main]
            b = 2
            """)

            #expect(ini.sections["main"]?["a"] == "1")
            #expect(ini.sections["main"]?["b"] == "2")
            #expect(ini.sectionOrder == ["main"])
        }

        @Test("section header with spaces inside brackets trims them")
        func sectionHeaderTrimsInnerSpace() {
            let ini = INIParser.parse(content: "[ shortcut 1 ]\nx = 1\n")
            #expect(ini.sections["shortcut 1"]?["x"] == "1")
        }
    }
}