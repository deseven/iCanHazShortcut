#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

mkdir ~/.purebasic/ > /dev/null 2>&1
echo "
[ToolsInfo]
ToolCount = 2

[Tool_0]
Command = $DIR/inject.sh
Arguments = %EXECUTABLE
WorkingDir = 
MenuItemName = ichs inject
Shortcut = 0
ConfigLine = 
Trigger = 4
Flags = 1
ReloadSource = 0
HideEditor = 0
HideFromMenu = 1
SourceSpecific = 1
Deactivate = 0

[Tool_1]
Command = $DIR/inject.sh
Arguments = %EXECUTABLE
WorkingDir = 
MenuItemName = ichs inject build
Shortcut = 0
ConfigLine = 
Trigger = 7
Flags = 1
ReloadSource = 0
HideEditor = 0
HideFromMenu = 1
SourceSpecific = 1
Deactivate = 0
" > ~/.purebasic/tools.prefs
