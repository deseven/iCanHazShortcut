IncludeFile "../pb-osx-globalhotkeys/ghk.pbi"
IncludeFile "const.pb"

EnableExplicit

Define statusBar.i,statusItem.i,i.l
Define application.i = CocoaMessage(0,0,"NSApplication sharedApplication")
Define workspace.i = CocoaMessage(0,0,"NSWorkspace sharedWorkspace")
Define editExistent.b = #False
Define updateCheckThread.i
Define updateVer.s = #myVer
Define updateDetails.s = ""
Define gadgetState.l
Define testRunResult.testRunResults
Define activeSelector.i = -1
Define previousHotkey.s

IncludeFile "helpers.pb"
IncludeFile "proc.pb"

Define subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asEnableShortcut",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asEnableShortcut(),"v@")
objc_registerClassPair_(subClass)
subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asDisableShortcut",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asDisableShortcut(),"v@")
objc_registerClassPair_(subClass)
subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asToggleShortcut",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asToggleShortcut(),"v@")
objc_registerClassPair_(subClass)
subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asEnableShortcutID",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asEnableShortcutID(),"v@")
objc_registerClassPair_(subClass)
subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asDisableShortcutID",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asDisableShortcutID(),"v@")
objc_registerClassPair_(subClass)
subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asToggleShortcutID",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asToggleShortcutID(),"v@")
objc_registerClassPair_(subClass)
subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asListShortcuts",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asListShortcuts(),"v@")
objc_registerClassPair_(subClass)

initResources()
globalHK::Init()

OpenWindow(#wnd,#PB_Ignore,#PB_Ignore,0,0,#myName,#PB_Window_SystemMenu|#PB_Window_ScreenCentered)
CocoaMessage(0,CocoaMessage(0,WindowID(#wnd),"standardWindowButton:",#NSWindowButtonMinimize),"setHidden:",#YES)
CocoaMessage(0,CocoaMessage(0,WindowID(#wnd),"standardWindowButton:",#NSWindowButtonMaximize),"setHidden:",#YES)
PanelGadget(#gadTabs,5,0,390,300)
CocoaMessage(0,GadgetID(#gadTabs),"setFocusRingType:",1)

AddGadgetItem(#gadTabs,0,"Shortcuts")
ListIconGadget(#gadShortcuts,5,0,360,220,"Shortcut",80,#PB_ListIcon_CheckBoxes)
SetGadgetAttribute(#gadShortcuts,#PB_ListIcon_List,#True)
CocoaMessage(0,GadgetID(#gadShortcuts),"setFocusRingType:",1)
AddGadgetColumn(#gadShortcuts,2,"Action",1)
AddGadgetColumn(#gadShortcuts,3,"Workdir",1)
ListIconGadgetHideColumn(#gadShortcuts,3,#True)
CocoaMessage(0,GadgetID(#gadShortcuts),"sizeLastColumnToFit")
ButtonImageGadget(#gadAdd,260,222,36,34,ImageID(#resAdd))
ButtonImageGadget(#gadEdit,296,222,36,34,ImageID(#resEdit))
ButtonImageGadget(#gadDel,332,222,36,34,ImageID(#resDel))
ButtonImageGadget(#gadTest,260,222,36,34,ImageID(#resTest))
ButtonImageGadget(#gadApply,296,222,36,34,ImageID(#resApply))
ButtonImageGadget(#gadCancel,332,222,36,34,ImageID(#resCancel))
ButtonImageGadget(#gadUp,2,222,36,34,ImageID(#resUp))
ButtonImageGadget(#gadDown,38,222,36,34,ImageID(#resDown))
TextGadget(#gadTestNote,10,230,244,20,"Don't forget to do a test run -->",#PB_Text_Right)
CocoaMessage(0,GadgetID(#gadAdd),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadEdit),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadDel),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadApply),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadCancel),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadUp),"setFocusRingType:",1)
CocoaMessage(0,GadgetID(#gadDown),"setFocusRingType:",1)

AddGadgetItem(#gadTabs,1,"Preferences")
TextGadget(#gadPrefShellCap,10,12,60,20,"Shell:")
ComboBoxGadget(#gadPrefShell,70,10,110,20)
buildShellList()
TextGadget(#gadPrefShellNote,10,45,170,200,~"Keep in mind that you have to set a correct $PATH variable in your shell config (~/.bashrc or ~/.zshrc, etc).\n\nYou can use the test run functionality when you create new shortcut to check if everything works fine.")
CocoaMessage(0,GadgetID(#gadPrefShell),"setFocusRingType:",1)
FrameGadget(#gadPrefFrame,180,0,180,250,"")
CheckBoxGadget(#gadPrefStatusBar,190,10,160,20,"Show icon in status bar")
CocoaMessage(0,GadgetID(#gadPrefStatusBar),"setFocusRingType:",1)
CheckBoxGadget(#gadPrefAutostart,190,35,160,20,"Start on login")
CocoaMessage(0,GadgetID(#gadPrefAutostart),"setFocusRingType:",1)
CheckBoxGadget(#gadPrefCheckUpdate,190,60,160,20,"Check for updates")
CocoaMessage(0,GadgetID(#gadPrefCheckUpdate),"setFocusRingType:",1)
CheckBoxGadget(#gadPrefPopulateMenu,190,85,160,20,"Show actions in menu")
CocoaMessage(0,GadgetID(#gadPrefPopulateMenu),"setFocusRingType:",1)
CheckBoxGadget(#gadPrefShowHtk,190,110,160,20,"Show hotkeys in menu")
CocoaMessage(0,GadgetID(#gadPrefShowHtk),"setFocusRingType:",1)

AddGadgetItem(#gadTabs,2,"About")
ImageGadget(#gadLogo,25,5,64,64,ImageID(#resLogo))
TextGadget(#gadNameVer,89,8,270,20,#myName + " " + #myVer,#PB_Text_Center)
SetGadgetFont(#gadNameVer,FontID(#resBigFont))
TextGadget(#gadCopyright,159,28,70,20,"created by")
HyperLinkGadget(#gadWebDeveloper,219,30,100,20,"deseven",$770000)
TextGadget(#gadCopyrightIcon,159,42,70,20,"icons by")
HyperLinkGadget(#gadWebDesigner,206,44,100,20,"denboroda",$770000)
SetGadgetColor(#gadWebDeveloper,#PB_Gadget_FrontColor,$bb0000)
SetGadgetColor(#gadWebDesigner,#PB_Gadget_FrontColor,$bb0000)
EditorGadget(#gadLicense,5,70,360,180,#PB_Editor_ReadOnly|#PB_Editor_WordWrap)
AddGadgetItem(#gadLicense,-1,#LICENSE)
SetActiveGadget(#gadShortcuts)
DisableGadget(#gadEdit,#True) : DisableGadget(#gadDel,#True)
DisableGadget(#gadUp,#True) : DisableGadget(#gadDown,#True)
HideGadget(#gadTest,#True) : HideGadget(#gadApply,#True) : HideGadget(#gadCancel,#True) : HideGadget(#gadTestNote,#True)

GadgetToolTip(#gadAdd,"Add new shortcut")
GadgetToolTip(#gadEdit,"Edit selected shortcut")
GadgetToolTip(#gadDel,"Delete selected shortcut")
GadgetToolTip(#gadApply,"Apply changes")
GadgetToolTip(#gadCancel,"Cancel")
GadgetToolTip(#gadTest,"Perform a test run")
GadgetToolTip(#gadUp,"Move selected gadget up")
GadgetToolTip(#gadDown,"Move selected gadget down")

CloseGadgetList()
StickyWindow(#wnd,#True)

settings()
registerShortcuts()

;If #True
If Not CountGadgetItems(#gadShortcuts)
  wndState(#show)
Else
  wndState(#hide)
EndIf

ResizeWindow(#wnd,WindowX(#wnd)-200,WindowY(#wnd),400,300)

If GetGadgetState(#gadPrefCheckUpdate) = #PB_Checkbox_Checked
  updateCheckThread = CreateThread(@checkUpdateAsync(),#updateCheckInterval*60*1000)
EndIf

Define class = CocoaMessage(0,WindowID(#wnd),"class")
Define selector = sel_registerName_("performKeyEquivalent:") 
class_addMethod_(class,selector,@keyHandler(),"v@:@")
selector = sel_registerName_("flagsChanged:") 
class_addMethod_(class,selector,@keyHandler(),"v@:@")

Repeat
  Define ev = WaitWindowEvent(200)
  Select ev
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #gadShortcuts
          Select EventType() 
            Case #PB_EventType_Change
              If GetGadgetState(#gadShortcuts) <> -1
                DisableGadget(#gadEdit,#False) : DisableGadget(#gadDel,#False)
                recalcUpDown()
                registerShortcuts()
                settings(#True)
              Else
                DisableGadget(#gadEdit,#True) : DisableGadget(#gadDel,#True)
                DisableGadget(#gadUp,#True) : DisableGadget(#gadDown,#True)
              EndIf
            Case #PB_EventType_LeftDoubleClick
              If GetGadgetState(#gadShortcuts) <> -1
                editingExistentMode()
              EndIf
          EndSelect
        Case #gadWebDeveloper
          RunProgram("open","http://deseven.info","")
        Case #gadWebDesigner
          RunProgram("open","https://dribbble.com/denboroda","")
        Case #gadAdd
          editingMode()
        Case #gadEdit
          editingExistentMode()
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
        Case #gadTest
          If Len(GetGadgetText(#gadAction))
            testRun(GetGadgetText(#gadAction))
            Define testRunMessage.s = "Action: " + GetGadgetText(#gadAction) + ~"\n" +
                                      "Shell: " + GetGadgetText(#gadPrefShell) + ~"\n" + 
                                      "Exit code: " + Str(testRunResult\exitCode) + ~"\n\n"
            If Len(testRunResult\stdout)
              testRunMessage + ~"[stdout]\n" + testRunResult\stdout + ~"\n\n"
            EndIf
            If Len(testRunResult\stderr)
              testRunMessage + ~"[stderr]\n" + testRunResult\stderr + ~"\n\n"
            EndIf
            If testRunResult\timeouted
              testRunMessage + ~"There were no output for at least 5 seconds so the program has been killed!\nIf that's intended just ignore it."
            ElseIf testRunResult\exitCode = -1
              testRunMessage + "Failed to run!"
            Else
              testRunMessage + "Action executed successfully!"
            EndIf
            MessageRequester(#myName + " - test run",testRunMessage)
          Else
            MessageRequester(#myName,"Please define your action first.")
          EndIf
        Case #gadApply
          If Len(GetGadgetText(#gadShortcutSelector)) > 0 And Len(GetGadgetText(#gadAction)) > 0 And GetGadgetText(#gadShortcutSelector) <> #pressInvite And GetGadgetText(#gadShortcutSelector) <> #enterInvite
            If editExistent
              gadgetState = GetGadgetItemState(#gadShortcuts,GetGadgetState(#gadShortcuts)) - #PB_ListIcon_Selected
              AddGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts),GetGadgetText(#gadShortcutSelector) + ~"\n" + GetGadgetText(#gadAction))
              If gadgetState = #PB_ListIcon_Checked
                SetGadgetItemState(#gadShortcuts,GetGadgetState(#gadShortcuts),gadgetState + #PB_ListIcon_Selected)
              EndIf
              RemoveGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts)+1)
              editExistent = #False
            Else
              AddGadgetItem(#gadShortcuts,-1,GetGadgetText(#gadShortcutSelector) + ~"\n" + GetGadgetText(#gadAction))
              SetGadgetItemState(#gadShortcuts,CountGadgetItems(#gadShortcuts)-1,#PB_ListIcon_Checked)
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
          gadgetState = GetGadgetItemState(#gadShortcuts,GetGadgetState(#gadShortcuts)) - #PB_ListIcon_Selected
          AddGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts)-1,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),0) + ~"\n" + GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),1))
          RemoveGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts)+1)
          SetGadgetState(#gadShortcuts,GetGadgetState(#gadShortcuts)-1)
          If gadgetState = #PB_ListIcon_Checked
            SetGadgetItemState(#gadShortcuts,GetGadgetState(#gadShortcuts),#PB_ListIcon_Checked + #PB_ListIcon_Selected)
          EndIf
          registerShortcuts()
          settings(#True)
        Case #gadDown
          gadgetState = GetGadgetItemState(#gadShortcuts,GetGadgetState(#gadShortcuts)) - #PB_ListIcon_Selected
          AddGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts)+2,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),0) + ~"\n" + GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),1))
          RemoveGadgetItem(#gadShortcuts,GetGadgetState(#gadShortcuts))
          SetGadgetState(#gadShortcuts,GetGadgetState(#gadShortcuts)+1)
          If gadgetState = #PB_ListIcon_Checked
            SetGadgetItemState(#gadShortcuts,GetGadgetState(#gadShortcuts),#PB_ListIcon_Checked + #PB_ListIcon_Selected)
          EndIf
          registerShortcuts()
          settings(#True)
        Case #gadShortcutSelector
          activateSelector(#gadShortcutSelector)
        Case #gadPrefPopulateMenu
          settings(#True) : registerShortcuts()
          If GetGadgetState(#gadPrefPopulateMenu) = #PB_Checkbox_Checked
            DisableGadget(#gadPrefShowHtk,#False)
          Else
            DisableGadget(#gadPrefShowHtk,#True)
          EndIf
        Case #gadPrefShowHtk
          settings(#True) : registerShortcuts()
        Case #gadPrefShell
          If EventType() = #PB_EventType_Change : settings(#True) : EndIf
        Case #gadPrefAutostart
          If GetGadgetState(#gadPrefAutostart) = #PB_Checkbox_Checked
            If Not enableLoginItem(#myID,#True)
              SetGadgetState(#gadPrefAutostart,#PB_Checkbox_Unchecked)
              MessageRequester(#myName,#errorMsg + "applying autostart")
            Else
              settings(#True)
            EndIf
          Else
            If Not enableLoginItem(#myID,#False)
              SetGadgetState(#gadPrefAutostart,#PB_Checkbox_Checked)
              MessageRequester(#myName,#errorMsg + "disabling autostart")
            Else
              settings(#True)
            EndIf
          EndIf
        Case #gadPrefCheckUpdate
          settings(#True)
          If GetGadgetState(#gadPrefCheckUpdate) = #PB_Checkbox_Checked
            If Not IsThread(updateCheckThread)
              updateCheckThread = CreateThread(@checkUpdateAsync(),#updateCheckInterval*60*1000)
            EndIf
          Else
            If IsThread(updateCheckThread)
              KillThread(updateCheckThread)
            EndIf
          EndIf
        Case #gadPrefStatusBar
          settings(#True)
          buildMenu()
        Case #gadActionHelp1
          SetGadgetText(#gadAction,~"open -a Finder")
        Case #gadActionHelp2
          SetGadgetText(#gadAction,~"screencapture -i -r -t png \"$HOME/screenshot.png\"")
        Case #gadActionHelp3
          SetGadgetText(#gadAction,~"say `date \"+Current date is %Y-%m-%d\"`")
        Case #gadActionHelp4
          SetGadgetText(#gadAction,~"pbpaste >> \"$HOME/clipboard.log\"")
        Case #gadActionHelp5
          SetGadgetText(#gadAction,~"echo \"test\" | pbcopy")
        Case #gadActionHelp6
          SetGadgetText(#gadAction,~"pmset displaysleepnow")
      EndSelect
    Case #PB_Event_LeftClick
      deactivateSelector()
    Case #PB_Event_CloseWindow
      If IsGadget(#gadShortcutSelectorCap)
        viewingMode()
      EndIf
      wndState(#hide)
    Case #evUpdateArrival
      wndState(#True)
      Select MessageRequesterEx(#myName + ", new version is available!","Found new version " + updateVer + ~"\n\nChangelog:\n" + updateDetails + ~"\n\nDo you want to download it?","note",1,"Download new version","Remind me later","Skip this version")
        Case 1
          RunProgram("open",#updateDownloadUrl,"")
          die()
        Case 2
          updateVer = #myVer
      EndSelect
      wndState(#False)
      settings(#True)
    Case #evDisableShortcut
      If EventData()
        Define shortcut.s = PeekS(EventData())
        For i = 0 To CountGadgetItems(#gadShortcuts)-1
          If GetGadgetItemText(#gadShortcuts,i,0) = shortcut
            SetGadgetItemState(#gadShortcuts,i,0)
            registerShortcuts()
            settings(#True)
            Break
          EndIf
        Next
      EndIf
    Case #evEnableShortcut
      If EventData()
        Define shortcut.s = PeekS(EventData())
        For i = 0 To CountGadgetItems(#gadShortcuts)-1
          If GetGadgetItemText(#gadShortcuts,i,0) = shortcut
            SetGadgetItemState(#gadShortcuts,i,#PB_ListIcon_Checked)
            registerShortcuts()
            settings(#True)
            Break
          EndIf
        Next
      EndIf
    Case #evToggleShortcut
      If EventData()
        Define shortcut.s = PeekS(EventData())
        For i = 0 To CountGadgetItems(#gadShortcuts)-1
          If GetGadgetItemText(#gadShortcuts,i,0) = shortcut
            If GetGadgetItemState(#gadShortcuts,i) >= #PB_ListIcon_Checked
              PostEvent(#evDisableShortcutID,0,0,0,i+1)
            Else
              PostEvent(#evEnableShortcutID,0,0,0,i+1)
            EndIf
            Break
          EndIf
        Next
      EndIf
    Case #evDisableShortcutID
      If EventData() And CountGadgetItems(#gadShortcuts) >= EventData()
        SetGadgetItemState(#gadShortcuts,EventData()-1,0)
        registerShortcuts()
        settings(#True)
      EndIf
    Case #evEnableShortcutID
      If EventData() And CountGadgetItems(#gadShortcuts) >= EventData()
        SetGadgetItemState(#gadShortcuts,EventData()-1,#PB_ListIcon_Checked)
        registerShortcuts()
        settings(#True)
      EndIf
    Case #evToggleShortcutID
      If EventData() And CountGadgetItems(#gadShortcuts) >= EventData()
        If GetGadgetItemState(#gadShortcuts,EventData()-1) >= #PB_ListIcon_Checked
          PostEvent(#evDisableShortcutID,0,0,0,EventData())
        Else
          PostEvent(#evEnableShortcutID,0,0,0,EventData())
        EndIf
      EndIf
  EndSelect
ForEver

die()
; IDE Options = PureBasic 5.44 LTS (MacOS X - x86)
; EnableUnicode
; EnableXP