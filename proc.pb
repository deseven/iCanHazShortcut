Procedure die()
  Shared updateCheckThread.i
  If IsThread(updateCheckThread)
    KillThread(updateCheckThread)
  EndIf
  End 0
EndProcedure

Procedure settings(save.b = #False)
  Protected shortcut.s,action.s,i.l
  If FileSize(GetEnvironmentVariable("HOME") + "/.config") = -1
    CreateDirectory(GetEnvironmentVariable("HOME") + "/.config")
  EndIf
  If FileSize(GetEnvironmentVariable("HOME") + "/.config/" + #myName) = -1
    CreateDirectory(GetEnvironmentVariable("HOME") + "/.config/" + #myName)
  EndIf
  Protected path.s = GetEnvironmentVariable("HOME") + "/.config/" + #myName + "/config.ini"
  If save
    CreatePreferences(path,#PB_Preference_GroupSeparator)
    PreferenceGroup("main")
    WritePreferenceString("shell",GetGadgetText(#gadPrefShell))
    If GetGadgetState(#gadPrefPopulateMenu) = #PB_Checkbox_Checked
      WritePreferenceString("populate_menu_with_actions","yes")
    Else
      WritePreferenceString("populate_menu_with_actions","no")
    EndIf
    If GetGadgetState(#gadPrefShowHtk) = #PB_Checkbox_Checked
      WritePreferenceString("show_hotkeys_in_menu","yes")
    Else
      WritePreferenceString("show_hotkeys_in_menu","no")
    EndIf
    If GetGadgetState(#gadPrefCheckUpdate) = #PB_Checkbox_Checked
      WritePreferenceString("check_for_updates","yes")
    Else
      WritePreferenceString("check_for_updates","no")
    EndIf
    For i = 0 To CountGadgetItems(#gadShortcuts)-1
      shortcut = GetGadgetItemText(#gadShortcuts,i,0)
      action = GetGadgetItemText(#gadShortcuts,i,1)
      PreferenceGroup("shortcut" + Str(i+1))
      WritePreferenceString("shortcut",shortcut)
      WritePreferenceString("action",action)
    Next
  Else
    OpenPreferences(path,#PB_Preference_GroupSeparator)
    PreferenceGroup("main")
    SetGadgetText(#gadPrefShell,ReadPreferenceString("shell","bash"))
    If ReadPreferenceString("populate_menu_with_actions","yes") = "yes"
      SetGadgetState(#gadPrefPopulateMenu,#PB_Checkbox_Checked)
      DisableGadget(#gadPrefShowHtk,#False)
    Else
      SetGadgetState(#gadPrefPopulateMenu,#PB_Checkbox_Unchecked)
      DisableGadget(#gadPrefShowHtk,#True)
    EndIf
    If ReadPreferenceString("show_hotkeys_in_menu","yes") = "yes"
      SetGadgetState(#gadPrefShowHtk,#PB_Checkbox_Checked)
    Else
      SetGadgetState(#gadPrefShowHtk,#PB_Checkbox_Unchecked)
    EndIf
    If ReadPreferenceString("check_for_updates","yes") = "yes"
      SetGadgetState(#gadPrefCheckUpdate,#PB_Checkbox_Checked)
    Else
      SetGadgetState(#gadPrefCheckUpdate,#PB_Checkbox_Unchecked)
    EndIf
    ExaminePreferenceGroups()
    While NextPreferenceGroup()
      If FindString(PreferenceGroupName(),"shortcut") = 1
        shortcut = ReadPreferenceString("shortcut","")
        action = ReadPreferenceString("action","")
        If Len(action) And Len(shortcut)
          AddGadgetItem(#gadShortcuts,-1,shortcut + ~"\n" + action)
        EndIf
      EndIf
    Wend
  EndIf
  ClosePreferences()
EndProcedure

Procedure initResources()
  Protected imageSize.NSSize
  Protected path.s = GetPathPart(ProgramFilename()) + "../Resources/"
  LoadFont(#resBigFont,"Courier",18,#PB_Font_Bold)
  If LoadImageEx(#resLogo,path+"main.icns") And LoadImageEx(#resAdd,path+"add.png") And LoadImageEx(#resEdit,path+"edit.png") And LoadImageEx(#resDel,path+"del.png") And LoadImageEx(#resApply,path+"apply.png") And LoadImageEx(#resCancel,path+"cancel.png") And LoadImageEx(#resOk,path+"ok.png") And LoadImageEx(#resFailed,path+"failed.png") And LoadImageEx(#resUp,path+"up.png") And LoadImageEx(#resDown,path+"down.png")
    CopyImage(#resLogo,#resIcon)
    If getBackingScaleFactor() >= 2.0
      ResizeImage(#resIcon,36,36,#PB_Image_Smooth)
      imageSize\width = 18
      imageSize\height = 18
      CocoaMessage(0,ImageID(#resIcon),"setSize:@",@ImageSize)
      ResizeImage(#resLogo,128,128,#PB_Image_Smooth)
      imageSize\width = 64
      imageSize\height = 64
      CocoaMessage(0,ImageID(#resLogo),"setSize:@",@ImageSize)
      imageSize\width = 24
      imageSize\height = 24
      CocoaMessage(0,ImageID(#resAdd),"setSize:@",@ImageSize)
      CocoaMessage(0,ImageID(#resEdit),"setSize:@",@ImageSize)
      CocoaMessage(0,ImageID(#resDel),"setSize:@",@ImageSize)
      CocoaMessage(0,ImageID(#resApply),"setSize:@",@ImageSize)
      CocoaMessage(0,ImageID(#resCancel),"setSize:@",@ImageSize)
      CocoaMessage(0,ImageID(#resUp),"setSize:@",@ImageSize)
      CocoaMessage(0,ImageID(#resDown),"setSize:@",@ImageSize)
      imageSize\width = 16
      imageSize\height = 16
      CocoaMessage(0,ImageID(#resOk),"setSize:@",@ImageSize)
      CocoaMessage(0,ImageID(#resFailed),"setSize:@",@ImageSize)
    Else
      ResizeImage(#resLogo,64,64,#PB_Image_Smooth)
      ResizeImage(#resIcon,18,18,#PB_Image_Smooth)
      ResizeImage(#resAdd,24,24,#PB_Image_Smooth)
      ResizeImage(#resEdit,24,24,#PB_Image_Smooth)
      ResizeImage(#resDel,24,24,#PB_Image_Smooth)
      ResizeImage(#resApply,24,24,#PB_Image_Smooth)
      ResizeImage(#resCancel,24,24,#PB_Image_Smooth)
      ResizeImage(#resUp,24,24,#PB_Image_Smooth)
      ResizeImage(#resDown,24,24,#PB_Image_Smooth)
      ResizeImage(#resOk,16,16,#PB_Image_Smooth)
      ResizeImage(#resFailed,16,16,#PB_Image_Smooth)
    EndIf
    CocoaMessage(0,ImageID(#resIcon),"setTemplate:",#True)
  Else
    Debug "failed to load image"
    End 1
  EndIf
EndProcedure

Procedure action(action.s)
  Protected shell.s = GetGadgetText(#gadPrefShell)
  If shell = "no shell"
    Protected program.s,params.s
    Protected programEnd.l = FindString(action," ")
    If programEnd
      program = Left(action,programEnd-1)
      params = Mid(action,programEnd+1)
    Else
      program = action
    EndIf
    ;Debug "running '" + program + "' with '" + params + "'"
    RunProgram(program,params,"")
  Else
    shell = "/bin/" + shell
    ;Debug "running '" + shell + "' with '" + action + "'"
    Protected pid = RunProgram(shell,"","",#PB_Program_Write|#PB_Program_Open)
    If IsProgram(pid)
      WriteProgramString(pid,action)
    EndIf
    CloseProgram(pid)
  EndIf
EndProcedure

Procedure menuEvents()
  Shared application.i
  Select EventMenu()
    Case #menuAbout
      CocoaMessage(0,application,"activateIgnoringOtherApps:",#YES)
      SetGadgetState(#gadTabs,2)
      SetActiveGadget(#gadCopyright)
      HideWindow(#wnd,#False)
    Case #menuShortcuts
      CocoaMessage(0,application,"activateIgnoringOtherApps:",#YES)
      SetGadgetState(#gadTabs,0)
      SetActiveGadget(#gadShortcuts)
      HideWindow(#wnd,#False)
    Case #menuPrefs
      CocoaMessage(0,application,"activateIgnoringOtherApps:",#YES)
      SetGadgetState(#gadTabs,1)
      HideWindow(#wnd,#False)
    Case #menuQuit
      die()
    Default
      PostEvent(#PB_Event_FirstCustomValue+EventMenu()-#menuCustom)
  EndSelect
EndProcedure

Procedure shortcutEvents()
  If EventData() >= 0
    If CountGadgetItems(#gadShortcuts) => EventData()+1
      action(GetGadgetItemText(#gadShortcuts,EventData(),1))
    EndIf
  EndIf
EndProcedure

Procedure buildMenu()
  Shared statusBar.i,statusItem.i
  Protected itemLength.CGFloat = 32
  Protected i.l
  If Not (statusBar And statusItem)
    statusBar.i = CocoaMessage(0,0,"NSStatusBar systemStatusBar")
    statusItem.i = CocoaMessage(0,CocoaMessage(0,StatusBar,"statusItemWithLength:",#NSSquareStatusBarItemLength),"retain")
  EndIf
  If IsMenu(#menu) : FreeMenu(#menu) : EndIf
  CreatePopupMenu(#menu)
  If GetGadgetState(#gadPrefPopulateMenu) = #PB_Checkbox_Checked And CountGadgetItems(#gadShortcuts)
    For i = 0 To CountGadgetItems(#gadShortcuts)-1 
      If GetGadgetState(#gadPrefShowHtk) = #PB_Checkbox_Checked
        MenuItem(#menuCustom+i,"[" + GetGadgetItemText(#gadShortcuts,i,0) + "] " + GetGadgetItemText(#gadShortcuts,i,1))
      Else
        MenuItem(#menuCustom+i,GetGadgetItemText(#gadShortcuts,i,1))
      EndIf
      BindMenuEvent(#menu,#menuCustom+i,@menuEvents())
    Next
    MenuBar()
  EndIf
  MenuItem(#menuShortcuts,"Shortcuts...")
  BindMenuEvent(#menu,#menuShortcuts,@menuEvents())
  MenuItem(#menuPrefs,"Preferences...")
  BindMenuEvent(#menu,#menuPrefs,@menuEvents())
  MenuItem(#menuAbout,"About")
  BindMenuEvent(#menu,#menuAbout,@menuEvents())
  MenuBar()
  MenuItem(#menuQuit,"Quit")
  BindMenuEvent(#menu,#menuQuit,@menuEvents())
  CocoaMessage(0,StatusItem,"setHighlightMode:",@"YES")
  CocoaMessage(0,StatusItem,"setLength:@",@itemLength)
  CocoaMessage(0,StatusItem,"setImage:",ImageID(#resIcon))
  CocoaMessage(0,StatusItem,"setMenu:",CocoaMessage(0,MenuID(#menu),"firstObject"))
EndProcedure

Procedure registerShortcuts()
  Protected i.l
  globalHK::remove("",0,#True) ; unregistering all to be on the safe side
  For i = 0 To 1000            ; temporary solution
    UnbindEvent(#PB_Event_FirstCustomValue+i,@shortcutEvents())
  Next
  For i = 0 To CountGadgetItems(#gadShortcuts)-1
    Protected shortcut.s = GetGadgetItemText(#gadShortcuts,i,0)
    If globalHK::add(shortcut,#PB_Event_FirstCustomValue + i,#PB_Ignore,#PB_Ignore,#PB_Ignore,i)
      BindEvent(#PB_Event_FirstCustomValue + i,@shortcutEvents())
      AddGadgetItem(#gadShortcuts,i,GetGadgetItemText(#gadShortcuts,i,0) + ~"\n" + GetGadgetItemText(#gadShortcuts,i,1),ImageID(#resOk))
    Else
      AddGadgetItem(#gadShortcuts,i,GetGadgetItemText(#gadShortcuts,i,0) + ~"\n" + GetGadgetItemText(#gadShortcuts,i,1),ImageID(#resFailed))
    EndIf
    RemoveGadgetItem(#gadShortcuts,i+1)
  Next
  buildMenu()
EndProcedure

Procedure checkUpdateAsync(interval.i)
  Shared updateVer.s,updateDetails.s
  Protected *buf,i,strCount
  Protected Dim strings.s(1)
  If Not InitNetwork() : ProcedureReturn : EndIf
  Repeat
    *buf = ReceiveHTTPMemory(#updateCheckUrl)
    If *buf
      Protected size.i = MemorySize(*buf)
      Protected update.s = PeekS(*buf,size,#PB_UTF8)
      FreeMemory(*buf)
      strCount = CountString(update,Chr(10))
      Protected Dim strings.s(strCount)
      For i = 0 To strCount
        strings(i) = StringField(update,i+1,Chr(10))
      Next
      For i = 0 To strCount
        strings(i) = Trim(strings(i))
      Next
      If FindString(strings(0),#myName) = 1
        Protected newVer.s = StringField(strings(0),2," ")
        If newVer <> updateVer
          updateVer = newVer
          updateDetails = ""
          For i = 1 To strCount
            If Len(strings(i)) > 0
              updateDetails + strings(i) + Chr(10)
            EndIf
          Next
          FreeArray(strings())
          PostEvent(#evUpdateArrival)
        EndIf
      EndIf
    EndIf
    If interval > 0 : Delay(interval) : Else : ProcedureReturn : EndIf
  ForEver
EndProcedure

Macro editingMode()
  HideGadget(#gadShortcuts,#True)
  HideGadget(#gadAdd,#True)
  HideGadget(#gadEdit,#True)
  HideGadget(#gadDel,#True)
  HideGadget(#gadUp,#True)
  HideGadget(#gadDown,#True)
  OpenGadgetList(#gadTabs,0)
  TextGadget(#gadBg,0,0,400,300,"") ; dirty fix for a strange redraw behavior
  FreeGadget(#gadBg)
  TextGadget(#gadShortcutSelectorCap,10,12,60,20,"Shortcut:")
  StringGadget(#gadShortcutSelector,70,10,80,20,"")
  CocoaMessage(0,GadgetID(#gadShortcutSelector),"setFocusRingType:",1)
  CocoaMessage(0,GadgetID(#gadShortcutSelector),"setAlignment:",#NSCenterTextAlignment)
  Define placeholder.s = "press keys"
  CocoaMessage(0,CocoaMessage(0,GadgetID(#gadShortcutSelector),"cell"),"setPlaceholderString:$",@placeholder)
  TextGadget(#gadActionCap,10,42,60,20,"Action:")
  StringGadget(#gadAction,70,40,290,20,"")
  CocoaMessage(0,GadgetID(#gadAction),"setFocusRingType:",1)
  placeholder.s = "input command which will be executed"
  CocoaMessage(0,CocoaMessage(0,GadgetID(#gadAction),"cell"),"setPlaceholderString:$",@placeholder)
  TextGadget(#gadActionHelp,10,70,360,150,~"You can use any command that works in your terminal.\nTo launch specific app (for example, Automator) simply enter 'open -a Automator'.\nFor more info and usage options refer to the output of the 'open' command.")
  HideGadget(#gadApply,#False)
  HideGadget(#gadCancel,#False)
  CloseGadgetList()
EndMacro

Macro editingExistentMode()
  editExistent = #True
  editingMode()
  SetGadgetText(#gadShortcutSelector,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),0))
  SetGadgetText(#gadAction,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),1))
EndMacro

Macro viewingMode()
  FreeGadget(#gadShortcutSelectorCap) : FreeGadget(#gadShortcutSelector)
  FreeGadget(#gadActionCap) : FreeGadget(#gadAction) : FreeGadget(#gadActionHelp)
  HideGadget(#gadCancel,#True)
  HideGadget(#gadApply,#True)
  TextGadget(#gadBg,0,0,400,300,"") ; dirty fix for a strange redraw behavior
  FreeGadget(#gadBg)
  HideGadget(#gadShortcuts,#False)
  HideGadget(#gadAdd,#False)
  HideGadget(#gadEdit,#False)
  HideGadget(#gadDel,#False)
  HideGadget(#gadUp,#False)
  HideGadget(#gadDown,#False)
  SetGadgetState(#gadShortcuts,-1)
EndMacro

Macro recalcUpDown()
  If GetGadgetState(#gadShortcuts) = 0
    DisableGadget(#gadUp,#True)
    DisableGadget(#gadDown,#False)
  ElseIf GetGadgetState(#gadShortcuts) + 1 = CountGadgetItems(#gadShortcuts)
    DisableGadget(#gadUp,#False)
    DisableGadget(#gadDown,#True)
  Else
    DisableGadget(#gadUp,#False)
    DisableGadget(#gadDown,#False)
  EndIf
EndMacro

Macro buildShellList()
  AddGadgetItem(#gadPrefShell,-1,"no shell")
  ExamineDirectory(0,"/bin","*sh")
  While NextDirectoryEntry(0)
    AddGadgetItem(#gadPrefShell,-1,DirectoryEntryName(0))
  Wend
  FinishDirectory(0)
EndMacro
; IDE Options = PureBasic 5.42 LTS (MacOS X - x64)
; Folding = ---
; EnableUnicode
; EnableXP