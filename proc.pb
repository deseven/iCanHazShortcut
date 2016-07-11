Procedure die()
  End 0
EndProcedure

Procedure initResources()
  Protected imageSize.NSSize
  If FileSize(GetEnvironmentVariable("HOME") + "/.config") = -1
    CreateDirectory(GetEnvironmentVariable("HOME") + "/.config")
  EndIf
  If FileSize(GetEnvironmentVariable("HOME") + "/.config/" + #myName) = -1
    CreateDirectory(GetEnvironmentVariable("HOME") + "/.config/" + #myName)
  EndIf
  LoadFont(#resBigFont,"Courier",18,#PB_Font_Bold)
  If LoadImageEx(#resLogo,GetPathPart(ProgramFilename()) + "../Resources/main.icns") And LoadImageEx(#resAdd,GetPathPart(ProgramFilename()) + "../Resources/add.png") And LoadImageEx(#resDel,GetPathPart(ProgramFilename()) + "../Resources/del.png")
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
    Else
      ResizeImage(#resLogo,64,64,#PB_Image_Smooth)
      ResizeImage(#resIcon,18,18,#PB_Image_Smooth)
      ResizeImage(#resAdd,24,24,#PB_Image_Smooth)
      ResizeImage(#resDel,24,24,#PB_Image_Smooth)
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