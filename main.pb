IncludeFile "../pb-osx-globalhotkeys/ghk.pbi"
IncludeFile "const.pb"

EnableExplicit

Define statusBar.i,statusItem.i,i.l
Define application.i = CocoaMessage(0,0,"NSApplication sharedApplication")
Define editExistent.b = #False

IncludeFile "helpers.pb"
IncludeFile "proc.pb"

initResources()
globalHK::Init()
buildMenu()

OpenWindow(#wnd,#PB_Ignore,#PB_Ignore,400,300,#myName,#PB_Window_SystemMenu|#PB_Window_ScreenCentered|#PB_Window_Invisible)
CocoaMessage(0,CocoaMessage(0,WindowID(#wnd),"standardWindowButton:",#NSWindowButtonMinimize),"setHidden:",#YES)
CocoaMessage(0,CocoaMessage(0,WindowID(#wnd),"standardWindowButton:",#NSWindowButtonMaximize),"setHidden:",#YES)
PanelGadget(#gadTabs,5,0,390,300)
CocoaMessage(0,GadgetID(#gadTabs),"setFocusRingType:",1)
AddGadgetItem(#gadTabs,0,"Shortcuts")
ListIconGadget(#gadShortcuts,5,0,360,220,"Shortcut",80)
SetGadgetAttribute(#gadShortcuts,#PB_ListIcon_List,#True)
CocoaMessage(0,GadgetID(#gadShortcuts),"setFocusRingType:",1)
AddGadgetColumn(#gadShortcuts,1,"Action",240)
setListIconColumnJustification(#gadShortcuts,0,2)
ButtonImageGadget(#gadAdd,260,222,36,34,ImageID(#resAdd))
ButtonImageGadget(#gadEdit,296,222,36,34,ImageID(#resEdit))
ButtonImageGadget(#gadDel,332,222,36,34,ImageID(#resDel))
ButtonImageGadget(#gadApply,296,222,36,34,ImageID(#resApply))
ButtonImageGadget(#gadCancel,332,222,36,34,ImageID(#resCancel))
ButtonImageGadget(#gadUp,2,222,36,34,ImageID(#resUp))
ButtonImageGadget(#gadDown,38,222,36,34,ImageID(#resDown))
CocoaMessage(0,GadgetID(#gadAdd),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadEdit),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadDel),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadApply),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadCancel),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadUp),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadDown),"setFocusRingType:",1)
AddGadgetItem(#gadTabs,1,"About")
ImageGadget(#gadLogo,25,0,64,64,ImageID(#resLogo))
TextGadget(#gadNameVer,89,8,270,20,#myName + " " + #myVer,#PB_Text_Center)
SetGadgetFont(#gadNameVer,FontID(#resBigFont))
TextGadget(#gadCopyright,89,28,270,20,"created by deseven, 2016",#PB_Text_Center)
HyperLinkGadget(#gadWebDeveloper,180,43,100,20,"deseven.info",$770000)
SetGadgetColor(#gadWebDeveloper,#PB_Gadget_FrontColor,$bb0000)
EditorGadget(#gadLicense,5,70,360,180,#PB_Editor_ReadOnly|#PB_Editor_WordWrap)
AddGadgetItem(#gadLicense,-1,#LICENSE)
SetActiveGadget(#gadShortcuts)
DisableGadget(#gadEdit,#True) : DisableGadget(#gadDel,#True)
DisableGadget(#gadUp,#True) : DisableGadget(#gadDown,#True)
HideGadget(#gadApply,#True) : HideGadget(#gadCancel,#True)

CloseGadgetList()
StickyWindow(#wnd,#True)

settings()
registerShortcuts()

;If #True
If Not CountGadgetItems(#gadShortcuts)
  CocoaMessage(0,application,"activateIgnoringOtherApps:",#YES)
  HideWindow(#wnd,#False)
EndIf

Repeat
  Define ev = WaitWindowEvent()
  Select ev
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #gadShortcuts
          If EventType() = #PB_EventType_Change
            If GetGadgetState(#gadShortcuts) <> -1
              DisableGadget(#gadEdit,#False) : DisableGadget(#gadDel,#False)
              recalcUpDown()
            Else
              DisableGadget(#gadEdit,#True) : DisableGadget(#gadDel,#True)
              DisableGadget(#gadUp,#True) : DisableGadget(#gadDown,#True)
            EndIf
          EndIf
        Case #gadWebDeveloper
          RunProgram("open","http://deseven.info","")
        Case #gadAdd
          editingMode()
        Case #gadEdit
          editExistent = #True
          editingMode()
          SetGadgetText(#gadShortcutSelector,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),0))
          SetGadgetText(#gadAction,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),1))
        Case #gadDel
          i = GetGadgetState(#gadShortcuts)
          RemoveGadgetItem(#gadShortcuts,i)
          registerShortcuts()
          settings(#True)
          If CountGadgetItems(#gadShortcuts) > i
            SetGadgetState(#gadShortcuts,i)
          Else
            SetGadgetState(#gadShortcuts,CountGadgetItems(#gadShortcuts)-1)
          EndIf
          recalcUpDown()
        Case #gadApply
          If Len(GetGadgetText(#gadShortcutSelector)) > 0 And Len(GetGadgetText(#gadAction)) > 0
            If editExistent
              AddGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts),GetGadgetText(#gadShortcutSelector) + ~"\n" + GetGadgetText(#gadAction))
              RemoveGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts)+1)
              editExistent = #False  
            Else
              AddGadgetItem(#gadShortcuts,-1,GetGadgetText(#gadShortcutSelector) + ~"\n" + GetGadgetText(#gadAction))
            EndIf
            registerShortcuts()
            settings(#True)
            viewingMode()
          Else
            MessageRequester(#myName,"Please define your hotkey and action first.")
          EndIf
        Case #gadCancel
          viewingMode()
        Case #gadUp
          AddGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts)-1,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),0) + ~"\n" + GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),1))
          RemoveGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts)+1)
          SetGadgetState(#gadShortcuts,GetGadgetState(#gadShortcuts)-1)
          registerShortcuts()
          settings(#True)
        Case #gadDown
          AddGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts)+2,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),0) + ~"\n" + GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),1))
          RemoveGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts))
          SetGadgetState(#gadShortcuts,GetGadgetState(#gadShortcuts)+1)
          registerShortcuts()
          settings(#True)
      EndSelect
    Case #PB_Event_CloseWindow
      If IsGadget(#gadShortcutSelectorCap)
        viewingMode()
      EndIf
      HideWindow(#wnd,#True)
    Default
      If ev >= #PB_Event_FirstCustomValue
        Define shortcut.l = ev - #PB_Event_FirstCustomValue
        If CountGadgetItems(#gadShortcuts) => shortcut+1
          ;Debug "running " + GetGadgetItemText(#gadShortcuts,shortcut,1)
          action(GetGadgetItemText(#gadShortcuts,shortcut,1))
        EndIf
      EndIf
  EndSelect
ForEver
; IDE Options = PureBasic 5.42 LTS (MacOS X - x64)
; EnableUnicode
; EnableXP