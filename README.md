# iCanHazShortcut
Simple shortcut manager for OS X 10.8 or higher.  
![screenshot](https://eri.deseven.info/scr/PneographEpituberculousPreofficially.png)  

## binaries
Latest binary release can be downloaded [here](https://github.com/deseven/icanhazshortcut/releases).  

## applescript support
Use `list` command to get the full TSV list of shortcuts and their states.  
Use `enable`, `disable`, `toggle` commands to control state of shortcuts by their names.  
Use `enableID`,  `disableID`, `toggleID` commands to control state of shortcuts by their IDs.  
Here are some examples:  
`tell application "iCanHazShortcut" to list`  
`tell application "iCanHazShortcut" to enable "⇧⌘L"`  
`tell application "iCanHazShortcut" to toggleID 6`  

## compiling from source
iCHS created in [PB](http://purebasic.com) and depends on [pb-osx-globalhotkeys](https://github.com/deseven/pb-osx-globalhotkeys).  
You also need [node-appdmg](https://github.com/LinusU/node-appdmg) if you want to build dmg.  
1. Obtain the latest LTS version of pbcompiler, install it to ```/Applications```.  
2. Install xcode command line tools by running ```xcode-select --install```.  
3. Clone iCHS repo.  
4. Clone ```pb-osx-globalhotkeys``` module to neighboring directory.  
5. Run the included ```build/build.sh``` script to build the app. If you want codesigning then provide your developer ID as a first argument.  