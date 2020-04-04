; main
#myName = "iCanHazShortcut"
#myVer = "1.1.0"
#cfgVer = "2"
#myID = "info.deseven.icanhazshortcut"

; update params
#updateCheckUrl = "http://deseven.info/sys/ichs.ver"
#updateDownloadUrl = "http://deseven.info/sys/ichs.dmg"
#updateCheckInterval = 1440

#pressInvite = "press to set"
#enterInvite = "enter keys"

#linkColor = $ff8000
#linkColorHighlighted = $ba520f

; structures
Structure testRunResults
  aborted.b
  exitCode.i
  stdout.s
  stderr.s
EndStructure

; enums
Enumeration main
  #wnd
  #wndSheet
  #menu
  #menuQuit
  #menuShortcuts
  #menuPrefs
  #menuUpdateCheck
  #menuAbout
  #menuCustom
EndEnumeration

Enumeration gadgets
  #gadTabs
  #gadShortcuts
  #gadAdd
  #gadEdit
  #gadDel
  #gadTest
  #gadTestNote
  #gadApply
  #gadCancel
  #gadUp
  #gadDown
  #gadLogo
  #gadNameVer
  #gadCopyright
  #gadWebDeveloper
  #gadCopyrightIcon
  #gadWebDesigner
  #gadLicense
  #gadBg
  #gadShortcutSelector
  #gadAction
  #gadCommand
  #gadWorkdir
  #gadShortcutSelectorCap
  #gadActionCap
  #gadCommandCap
  #gadWorkdirCap
  #gadActionHelpFrame
  #gadActionHelp
  #gadActionHelp1
  #gadActionHelp2
  #gadActionHelp3
  #gadActionHelp4
  #gadActionHelp5
  #gadActionHelp6
  #gadPrefShell
  #gadPrefShellDefault
  #gadPrefShellCap
  #gadPrefShellNote
  #gadPrefStatusBar
  #gadPrefPopulateMenu
  #gadPrefShowHtk
  #gadPrefFrame
  #gadPrefAutostart
  #gadPrefCheckUpdate
  #gadTestProgress
  #gadTestAbort
EndEnumeration

Enumeration resources
  #resNormalFont
  #resBigFont
  #resIcon
  #resLogo
  #resAdd
  #resEdit
  #resDel
  #resTest
  #resApply
  #resCancel
  #resUp
  #resDown
  #resOk
  #resDisabled
  #resFailed
  #resFont
EndEnumeration

Enumeration globalEvents #PB_Event_FirstCustomValue + 10000
  #evUpdateArrival
  #evNoUpdateFound
  #evDisableShortcut
  #evEnableShortcut
  #evToggleShortcut
  #evDisableShortcutID
  #evEnableShortcutID
  #evToggleShortcutID
  #evUpdateConfig
EndEnumeration

#NSSquareStatusBarItemLength = -2
#NSWindowButtonMinimize = 1
#NSWindowButtonMaximize = 2
#NSAlphaShiftKeyMask = 1 << 16
#NSShiftKeyMask      = 1 << 17
#NSControlKeyMask    = 1 << 18
#NSAlternateKeyMask  = 1 << 19
#NSCommandKeyMask    = 1 << 20
;#NSFunctionKeyMask   = 1 << 24

#hide = #False
#show = #True

#errorMsg = "Something went wrong, please try to reinstall this tool or contact the developer.\nStep: "
#backupMsg = ~"Hello! Looks like you are updating from an older config version. Just in case something goes wrong your old config file has been saved as:\n\n"
#LICENSE = ~"This is free and unencumbered software released into the public domain.\n\nAnyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.\n\nIn jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.\n\nTHE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.\n\nFor more information, please refer to <http://unlicense.org>"

Dim keys.s($FF)
keys($00) = "A"
keys($01) = "S"
keys($02) = "D"
keys($03) = "F"
keys($04) = "H"
keys($05) = "G"
keys($06) = "Z"
keys($07) = "X"
keys($08) = "C"
keys($09) = "V"
keys($0B) = "B"
keys($0C) = "Q"
keys($0D) = "W"
keys($0E) = "E"
keys($0F) = "R"
keys($10) = "Y"
keys($11) = "T"
keys($12) = "1"
keys($13) = "2"
keys($14) = "3"
keys($15) = "4"
keys($16) = "6"
keys($17) = "5"
keys($18) = "="
keys($19) = "9"
keys($1A) = "7"
keys($1B) = "-"
keys($1C) = "8"
keys($1D) = "0"
keys($1E) = "]"
keys($1F) = "O"
keys($20) = "U"
keys($21) = "["
keys($22) = "I"
keys($23) = "P"
keys($25) = "L"
keys($26) = "J"
keys($27) = "'"
keys($28) = "K"
keys($29) = ";"
keys($2A) = ""
keys($2B) = ","
keys($2C) = "/"
keys($2D) = "N"
keys($2E) = "M"
keys($2F) = "."
keys($32) = "`"
keys($24) = "↩"
keys($30) = "Tab"
keys($31) = "Space"
keys($35) = "⎋"
keys($39) = "CAPS"
keys($7A) = "F1"
keys($78) = "F2"
keys($63) = "F3"
keys($76) = "F4"
keys($60) = "F5"
keys($61) = "F6"
keys($62) = "F7"
keys($64) = "F8"
keys($65) = "F9"
keys($6D) = "F10"
keys($67) = "F11"
keys($6F) = "F12"
keys($69) = "F13"
keys($6B) = "F14"
keys($71) = "F15"
keys($6A) = "F16"
keys($40) = "F17"
keys($4F) = "F18"
keys($50) = "F19"
keys($5A) = "F20"
keys($73) = "Home"
keys($77) = "End"
keys($74) = "PgUp"
keys($79) = "PgDown"
keys($0A) = "§"
keys($33) = "Del"

#loginItemPlist = ~"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n" +
~"<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n" +
~"<plist version=\"1.0\">\n" +
~"<dict>\n" +
~"\t<key>Label</key>\n" +
~"\t<string>{appid}</string>\n" +
~"\t<key>ProgramArguments</key>\n" +
~"\t<array>\n" +
~"\t\t<string>/usr/bin/open</string>\n" +
~"\t\t<string>{apppath}</string>\n" +
~"\t</array>\n" +
~"\t<key>RunAtLoad</key>\n" +
~"\t<true/>\n" +
~"\t<key>KeepAlive</key>\n" +
~"\t<false/>\n" +
~"\t<key>LimitLoadToSessionType</key>\n" +
~"\t<string>Aqua</string></dict>\n" +
~"</plist>"