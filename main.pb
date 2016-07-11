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
AddGadgetItem(#gadTabs,1,"About")

Repeat
  Select WaitWindowEvent()
    Case #PB_Event_CloseWindow
      HideWindow(#wnd,#True)
  EndSelect
ForEver
; IDE Options = PureBasic 5.42 LTS (MacOS X - x64)
; EnableUnicode
; EnableXP