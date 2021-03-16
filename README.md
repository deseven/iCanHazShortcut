# iCanHazShortcut
Simple shortcut manager for macOS 10.8 or higher. It lets you execute any command that works in your terminal by pressing a combination of keyboard keys. No rocket science involved!  
![screenshot](https://d7.wtf/SchesisDodecaneCunarder.png)  
[![Mac Informer Editor's pick award](https://img.informer.com/awards/mi-award-epick4.png)](https:////macdownload.informer.com/icanhazshortcut/)  

## binaries
Latest **stable** release can be downloaded in [Releases section](https://github.com/deseven/icanhazshortcut/releases). You can also install it using Homebrew Cask, just run `brew install icanhazshortcut`.  
Latest **unstable** build compiled from `master` branch can be downloaded [here](https://d7.wtf/s/ichs-dev.zip) (please don't use it unless you desperately need some functionality that's not available in stable release or want to help with testing).

## help & support
If you found a bug, have a suggestion or some question, feel free to [create issue](https://github.com/deseven/icanhazshortcut/issues/new) in this repo.  
There is also Telegram group you can join - https://t.me/icanhazshortcut

## applescript
Use `list` command to get the full TSV list of shortcuts and their states.  
Use `enable`, `disable`, `toggle` commands to control state of shortcuts by their shortcut names.  
Use `enableAction`, `disableAction`, `toggleAction` commands to control state of shortcuts by their action names.  
Use `enableID`,  `disableID`, `toggleID` commands to control state of shortcuts by their IDs.  
Here are some examples:  
`tell application "iCanHazShortcut" to list`  
`tell application "iCanHazShortcut" to enable "⇧⌘L"`  
`tell application "iCanHazShortcut" to disableAction "lock screen"`  
`tell application "iCanHazShortcut" to toggleID 6`  

## compiling from source
iCHS created in [PB](http://purebasic.com) and depends on [pb-macos-globalhotkeys](https://github.com/deseven/pb-macos-globalhotkeys).  
You also need [node-appdmg](https://github.com/LinusU/node-appdmg) if you want to build dmg.  
1. Obtain the latest LTS version of pbcompiler, install it to ```/Applications```.  
2. Install xcode command line tools by running ```xcode-select --install```.  
3. Clone iCHS repo.  
4. Clone ```pb-macos-globalhotkeys``` module to neighboring directory.  
5. Run the included ```build/build.sh``` script to build the app. If you want codesigning then provide your developer ID as a first argument.  
