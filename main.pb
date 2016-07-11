IncludeFile "../pb-osx-globalhotkeys/ghk.pbi"
IncludeFile "const.pb"

EnableExplicit

Define statusBar.i,statusItem.i
Define application.i = CocoaMessage(0,0,"NSApplication sharedApplication")

IncludeFile "proc.pb"

initResources()
globalHK::Init()
buildMenu()

OpenWindow(#wnd,#PB_Ignore,#PB_Ignore,400,300,#myName,#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_Invisible)
CocoaMessage(0,CocoaMessage(0,WindowID(#wnd),"standardWindowButton:",1),"setHidden:",#YES)
CocoaMessage(0,CocoaMessage(0,WindowID(#wnd),"standardWindowButton:",2),"setHidden:",#YES)
PanelGadget(#gadTabs,5,0,390,300)
AddGadgetItem(#gadTabs,0,"Shortcuts")
ListIconGadget(#gadShortcuts,5,0,360,220,"Shortcut",60)
AddGadgetColumn(#gadShortcuts,1,"Action",290)
ButtonImageGadget(#gadAdd,296,222,36,34,ImageID(#resAdd))
ButtonImageGadget(#gadDel,332,222,36,34,ImageID(#resDel))
AddGadgetItem(#gadTabs,1,"About")
ImageGadget(#gadLogo,25,0,64,64,ImageID(#resLogo))
TextGadget(#gadNameVer,89,8,270,20,#myName + " " + #myVer,#PB_Text_Center)
SetGadgetFont(#gadNameVer,FontID(#resBigFont))
TextGadget(#gadCopyright,89,28,270,20,"created by deseven, 2016",#PB_Text_Center)
HyperLinkGadget(#gadWebDeveloper,180,43,100,20,"deseven.info",$770000)
SetGadgetColor(#gadWebDeveloper,#PB_Gadget_FrontColor,$bb0000)
BindGadgetEvent(#gadWebDeveloper,@gadgetEvents())
EditorGadget(#gadLicense,5,70,360,180,#PB_Editor_ReadOnly|#PB_Editor_WordWrap)
AddGadgetItem(#gadLicense,-1,#LICENSE)
SetActiveGadget(#gadShortcuts)
StickyWindow(#wnd,#True)

CocoaMessage(0,application,"activateIgnoringOtherApps:",#YES)
HideWindow(#wnd,#False)

Repeat
  Select WaitWindowEvent()
    Case #PB_Event_CloseWindow
      HideWindow(#wnd,#True)
  EndSelect
ForEver
; IDE Options = PureBasic 5.42 LTS (MacOS X - x64)
; EnableUnicode
; EnableXP