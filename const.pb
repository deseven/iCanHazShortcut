; main
#myName = "iCanHazShortcut"
#myVer = "0.4.3"

; update params
#updateCheckUrl = "http://deseven.info/sys/ichs.ver"
#updateDownloadUrl = "http://deseven.info/sys/ichs.zip"
#updateCheckInterval = 1440

; enums
Enumeration main
  #wnd
  #menu
  #menuQuit
  #menuShortcuts
  #menuPrefs
  #menuAbout
  #menuCustom
EndEnumeration

Enumeration gadgets
  #gadTabs
  #gadShortcuts
  #gadAdd
  #gadEdit
  #gadDel
  #gadApply
  #gadCancel
  #gadUp
  #gadDown
  #gadLogo
  #gadNameVer
  #gadCopyright
  #gadWebDeveloper
  #gadLicense
  #gadBg
  #gadShortcutSelector
  #gadAction
  #gadShortcutSelectorCap
  #gadActionCap
  #gadActionHelp
  #gadPrefShell
  #gadPrefShellCap
  #gadPrefPopulateMenu
  #gadPrefShowHtk
  #gadPrefFrame
  #gadPrefCheckUpdate
EndEnumeration

Enumeration resources
  #resBigFont
  #resIcon
  #resLogo
  #resAdd
  #resEdit
  #resDel
  #resApply
  #resCancel
  #resUp
  #resDown
  #resOk
  #resFailed
  #resFont
EndEnumeration

Enumeration globalEvents #PB_Event_FirstCustomValue + 10000
  #evUpdateArrival
EndEnumeration

#NSSquareStatusBarItemLength = -2
#NSWindowButtonMinimize = 1
#NSWindowButtonMaximize = 2
#NSAlphaShiftKeyMask = 1 << 16
#NSShiftKeyMask      = 1 << 17
#NSControlKeyMask    = 1 << 18
#NSAlternateKeyMask  = 1 << 19
#NSCommandKeyMask    = 1 << 20

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
; IDE Options = PureBasic 5.42 LTS (MacOS X - x64)
; EnableUnicode
; EnableXP