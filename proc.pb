Procedure die()
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
    For i = 0 To CountGadgetItems(#gadShortcuts)-1
      shortcut = GetGadgetItemText(#gadShortcuts,i,0)
      action = GetGadgetItemText(#gadShortcuts,i,1)
      PreferenceGroup("shortcut" + Str(i+1))
      WritePreferenceString("shortcut",shortcut)
      WritePreferenceString("action",action)
    Next
  Else
    OpenPreferences(path,#PB_Preference_GroupSeparator)
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
  If LoadImageEx(#resLogo,path+"main.icns") And LoadImageEx(#resAdd,path+"add.png") And LoadImageEx(#resDel,path+"del.png") And LoadImageEx(#resOk,path+"ok.png") And LoadImageEx(#resFailed,path+"failed.png")
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
      CocoaMessage(0,ImageID(#resDel),"setSize:@",@ImageSize)
      imageSize\width = 16
      imageSize\height = 16
      CocoaMessage(0,ImageID(#resOk),"setSize:@",@ImageSize)
      CocoaMessage(0,ImageID(#resFailed),"setSize:@",@ImageSize)
    Else
      ResizeImage(#resLogo,64,64,#PB_Image_Smooth)
      ResizeImage(#resIcon,18,18,#PB_Image_Smooth)
      ResizeImage(#resAdd,24,24,#PB_Image_Smooth)
      ResizeImage(#resDel,24,24,#PB_Image_Smooth)
      ResizeImage(#resOk,16,16,#PB_Image_Smooth)
      ResizeImage(#resFailed,16,16,#PB_Image_Smooth)
    EndIf
    CocoaMessage(0,ImageID(#resIcon),"setTemplate:",#True)
  Else
    Debug "failed to load image"
    End 1
  EndIf
EndProcedure

Procedure menuEvents()
  Shared application.i
  Select EventMenu()
    Case #menuAbout
      CocoaMessage(0,application,"activateIgnoringOtherApps:",#YES)
      SetGadgetState(#gadTabs,1)
      SetActiveGadget(#gadCopyright)
      HideWindow(#wnd,#False)
    Case #menuPrefs
      CocoaMessage(0,application,"activateIgnoringOtherApps:",#YES)
      SetGadgetState(#gadTabs,0)
      SetActiveGadget(#gadShortcuts)
      HideWindow(#wnd,#False)
    Case #menuQuit
      die()
  EndSelect
EndProcedure

Procedure buildMenu()
  Shared statusBar.i,statusItem.i
  Protected itemLength.CGFloat = 32
  If Not (statusBar And statusItem)
    statusBar.i = CocoaMessage(0,0,"NSStatusBar systemStatusBar")
    statusItem.i = CocoaMessage(0,CocoaMessage(0,StatusBar,"statusItemWithLength:",#NSSquareStatusBarItemLength),"retain")
  EndIf
  If IsMenu(#menu) : FreeMenu(#menu) : EndIf
  CreatePopupMenu(#menu)
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
  For i = 0 To CountGadgetItems(#gadShortcuts)-1
    Protected shortcut.s = GetGadgetItemText(#gadShortcuts,i,0)
    If globalHK::add(shortcut,#PB_Event_FirstCustomValue + i)
      AddGadgetItem(#gadShortcuts,i,GetGadgetItemText(#gadShortcuts,i,0) + ~"\n" + GetGadgetItemText(#gadShortcuts,i,1),ImageID(#resOk))
    Else
      AddGadgetItem(#gadShortcuts,i,GetGadgetItemText(#gadShortcuts,i,0) + ~"\n" + GetGadgetItemText(#gadShortcuts,i,1),ImageID(#resFailed))
    EndIf
    RemoveGadgetItem(#gadShortcuts,i+1)
  Next
EndProcedure

Procedure action(action.s)
  Protected program.s,params.s
  Protected programEnd.l = FindString(action," ")
  If programEnd
    program = Left(action,programEnd-1)
    params = Mid(action,programEnd+1)
  Else
    program = action
  EndIf
  RunProgram(program,params,"")
EndProcedure

Macro editingMode()
  editingState = #True
  HideGadget(#gadShortcuts,#True)
  OpenGadgetList(#gadTabs,0)
  TextGadget(#gadBg,0,0,400,300,"") ; dirty fix for a strange redraw behavior
  FreeGadget(#gadBg)
  TextGadget(#gadShortcutSelectorCap,10,12,60,20,"Shortcut:")
  ShortcutGadget(#gadShortcutSelector,70,10,80,20,0)
  CocoaMessage(0,GadgetID(#gadShortcutSelector),"setAlignment:",#NSCenterTextAlignment)
  Define placeholder.s = "press keys"
  CocoaMessage(0,CocoaMessage(0,GadgetID(#gadShortcutSelector),"cell"),"setPlaceholderString:$",@placeholder)
  TextGadget(#gadActionCap,10,42,60,20,"Action:")
  StringGadget(#gadAction,70,40,290,20,"")
  CocoaMessage(0,GadgetID(#gadAction),"setFocusRingType:",2)
  placeholder.s = "input command which will be executed"
  CocoaMessage(0,CocoaMessage(0,GadgetID(#gadAction),"cell"),"setPlaceholderString:$",@placeholder)
  TextGadget(#gadActionHelp,10,70,360,150,~"You can use any command that works in your terminal.\nTo launch specific app (for example, Automator) simply enter 'open -a Automator'.\nFor more info and usage options refer to the output of the 'open' command.")
  CloseGadgetList()
EndMacro

Macro viewingMode()
  editingState = #False
  FreeGadget(#gadShortcutSelectorCap) : FreeGadget(#gadShortcutSelector)
  FreeGadget(#gadActionCap) : FreeGadget(#gadAction) : FreeGadget(#gadActionHelp)
  HideGadget(#gadShortcuts,#False)
EndMacro
; IDE Options = PureBasic 5.42 LTS (MacOS X - x64)
; Folding = --
; EnableUnicode
; EnableXP