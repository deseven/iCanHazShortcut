# iCanHazShortcut
Simple shortcut manager for OS X 10.8 or higher.  
![screenshot](https://eri.deseven.info/scr/PneographEpituberculousPreofficially.png)  

## binaries
Latest binary release can be downloaded [here](https://deseven.info/sys/ichs.dmg).  

## compiling from source
iCHS created in [PB](http://purebasic.com) and depends on [pb-osx-globalhotkeys](https://github.com/deseven/pb-osx-globalhotkeys).  
You also need [node-appdmg](https://github.com/LinusU/node-appdmg) if you want to build dmg.  
1. Obtain the latest LTS version of pbcompiler, install it to ```/Applications```.  
2. Install xcode command line tools by running ```xcode-select --install```.  
3. Clone iCHS repo.  
4. Clone ```pb-osx-globalhotkeys``` module to neighboring directory.  
5. Run the included ```build/build.sh``` script to build the app. If you want codesigning then provide your developer ID as a first argument.  