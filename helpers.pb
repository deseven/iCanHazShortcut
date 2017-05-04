ImportC "/System/Library/Frameworks/Accelerate.framework/Accelerate"
  vImageUnpremultiplyData_RGBA8888 (*src, *dest, flags) 
EndImport

; concept by Kukulkan (http://forums.purebasic.com/english/viewtopic.php?f=19&t=64057)
Procedure.b enableLoginItem(bundleID.s,state.b)
  Protected loginItemsPath.s = GetHomeDirectory() + "Library/LaunchAgents/"
  Protected loginItemPath.s = loginItemsPath + bundleID + ".plist"
  Protected bundlePathPtr = CocoaMessage(0,CocoaMessage(0,CocoaMessage(0,0,"NSBundle mainBundle"),"bundlePath"),"UTF8String")
  If bundlePathPtr
    Protected bundlePath.s = PeekS(bundlePathPtr,-1,#PB_UTF8)
  Else
    ProcedureReturn #False
  EndIf
  If state
    If FileSize(loginItemsPath) <> -2
      If Not CreateDirectory(loginItemsPath)
        ProcedureReturn #False
      EndIf
    EndIf
    Protected loginItemFile = CreateFile(#PB_Any,loginItemPath)
    If IsFile(loginItemFile)
      Protected loginItemPlist.s = ReplaceString(#loginItemPlist,"{appid}",bundleID)
      loginItemPlist = ReplaceString(loginItemPlist,"{apppath}",bundlePath)
      WriteString(loginItemFile,loginItemPlist,#PB_UTF8)
      CloseFile(loginItemFile)
      RunProgram("launchctl",~"load \"" + loginItemPath + ~"\"","")
    Else
      ProcedureReturn #False
    EndIf
  Else
    If FileSize(loginItemPath) <> -1
      RunProgram("launchctl",~"unload \"" + loginItemPath + ~"\"","")
      If Not DeleteFile(loginItemPath,#PB_FileSystem_Force)
        ProcedureReturn #False
      EndIf
    EndIf
  EndIf
  ProcedureReturn #True
EndProcedure

; code by wilbert (http://www.purebasic.fr/english/viewtopic.php?p=392073#p392073)
Procedure loadImageEx(Image,Filename.s)
  Protected.i Result, Rep, vImg.vImage_Buffer
  Protected Size.NSSize, Point.NSPoint
  CocoaMessage(@Rep, 0, "NSImageRep imageRepWithContentsOfFile:$", @Filename)
  If Rep
    Size\width = CocoaMessage(0, Rep, "pixelsWide")
    Size\height = CocoaMessage(0, Rep, "pixelsHigh")
    If Size\width And Size\height
      CocoaMessage(0, Rep, "setSize:@", @Size)
    Else
      CocoaMessage(@Size, Rep, "size")
    EndIf
    If Size\width And Size\height
      Result = CreateImage(Image, Size\width, Size\height, 32, #PB_Image_Transparent)
      If Result
        If Image = #PB_Any : Image = Result : EndIf
        StartDrawing(ImageOutput(Image))
        CocoaMessage(0, Rep, "drawAtPoint:@", @Point)
        If CocoaMessage(0, Rep, "hasAlpha")
          vImg\data = DrawingBuffer()
          vImg\width = OutputWidth()
          vImg\height = OutputHeight()
          vImg\rowBytes = DrawingBufferPitch()
          vImageUnPremultiplyData_RGBA8888(@vImg, @vImg, 0)
        EndIf
        StopDrawing()
      EndIf
    EndIf
  EndIf  
  ProcedureReturn Result
EndProcedure

; based on wilbert's code (http://www.purebasic.fr/english/viewtopic.php?p=469232#p469232)
Procedure ListIconGadgetHideColumn(gadget.i,index.i,state.b)
  Protected column = CocoaMessage(0,CocoaMessage(0,GadgetID(gadget),"tableColumns"),"objectAtIndex:",index)
  If column
    If state
      CocoaMessage(0,column,"setHidden:",#YES)
    Else
      CocoaMessage(0,column,"setHidden:",#NO)
    EndIf
  EndIf
EndProcedure

Procedure ListIconGadgetColumnTitle(gadget.i,index.i,title.s)
  Protected column = CocoaMessage(0,CocoaMessage(0,GadgetID(gadget),"tableColumns"),"objectAtIndex:",index)
  If column
    If OSVersion() >= #PB_OS_MacOSX_10_10
      CocoaMessage(0,column,"setTitle:$",@title)
    Else
      CocoaMessage(0,CocoaMessage(0,column,"headerCell"),"setStringValue:$",@title)
    EndIf
  EndIf
EndProcedure

; based on Shardik's code (http://www.purebasic.fr/english/viewtopic.php?p=393304#p393304)
Procedure ListIconGadgetColumnToolTip(gadget.i,index.i,toolTip.s)
  Protected column.i
  CocoaMessage(@column,CocoaMessage(0,GadgetID(gadget),"tableColumns"),"objectAtIndex:",index)
  CocoaMessage(0,column,"setHeaderToolTip:$",@toolTip)
EndProcedure

; code by Shardik (http://www.purebasic.fr/english/viewtopic.php?p=393256#p393256)
Procedure setListIconColumnJustification(ListIconID.I,ColumnIndex.I,Alignment.I)
  Protected ColumnHeaderCell.I
  Protected ColumnObject.I
  Protected ColumnObjectArray.I

  ; ----- Justify text of column cells
  CocoaMessage(@ColumnObjectArray, GadgetID(ListIconID), "tableColumns")
  CocoaMessage(@ColumnObject, ColumnObjectArray, "objectAtIndex:", ColumnIndex)
  CocoaMessage(0, CocoaMessage(0, ColumnObject, "dataCell"), "setAlignment:", Alignment)

  ; ----- Justify text of column header
  CocoaMessage(@ColumnHeaderCell, ColumnObject, "headerCell")
  CocoaMessage(0, ColumnHeaderCell, "setAlignment:", Alignment)

  ; ----- Redraw ListIcon contents to see change
  CocoaMessage(0, GadgetID(ListIconID), "reloadData")
EndProcedure

Procedure.f getBackingScaleFactor()
  Define backingScaleFactor.CGFloat = 1.0
  If OSVersion() >= #PB_OS_MacOSX_10_7
    CocoaMessage(@backingScaleFactor,CocoaMessage(0,0,"NSScreen mainScreen"),"backingScaleFactor")
  EndIf
  ProcedureReturn backingScaleFactor
EndProcedure

Procedure MessageRequesterEx(Title.s, Info.s,type.s="'note'",defaultbutton=1,buttonone.s="Ok",buttontwo.s="",buttonthree.s="",buttonfour.s="",buttonfive.s="") ; max 5 buttons
  Protected.i Alert, Frame.NSRect,numberbuttons=0,button
  Shared workspace,application
  ;If FindString("'APPL''caut''note''stop'",type,1)=0 : Debug "no type":EndIf
  Frame\size\width = 300
  Frame\size\height = 24
  Alert = CocoaMessage(0, CocoaMessage(0, 0, "NSAlert new"), "autorelease")
  CocoaMessage(0, Alert, "setMessageText:$", @Title)
  CocoaMessage(0, Alert, "setInformativeText:$", @Info)
  CocoaMessage(0, Alert, "setIcon:", ImageID(#resLogo))
  
  If buttonfive
    CocoaMessage(0, Alert, "addButtonWithTitle:$", @buttonfive) 
    numberbuttons+1
  EndIf
  If buttonfour
    CocoaMessage(0, Alert, "addButtonWithTitle:$", @buttonfour)
    numberbuttons+1
  EndIf
  If buttonthree
    CocoaMessage(0, Alert, "addButtonWithTitle:$", @buttonthree)
    numberbuttons+1
  EndIf
  If buttontwo
    CocoaMessage(0, Alert, "addButtonWithTitle:$", @buttontwo) 
    numberbuttons+1
  EndIf
  CocoaMessage(0, Alert, "addButtonWithTitle:$", @buttonone)
  Button = CocoaMessage(0, CocoaMessage(0, Alert, "buttons"), "objectAtIndex:",numberbuttons-defaultbutton+1)
  CocoaMessage(0, CocoaMessage(0, Alert, "window"), "setDefaultButtonCell:", CocoaMessage(0, Button ,"cell"))
  ProcedureReturn 1001+numberbuttons-CocoaMessage(0, Alert, "runModal")
EndProcedure

Macro viewingMode()
  FreeGadget(#gadShortcutSelectorCap) : FreeGadget(#gadShortcutSelector)
  FreeGadget(#gadActionCap) : FreeGadget(#gadAction) : FreeGadget(#gadActionHelp)
  FreeGadget(#gadActionHelp1) : FreeGadget(#gadActionHelp2) : FreeGadget(#gadActionHelp3)
  FreeGadget(#gadActionHelp4) : FreeGadget(#gadActionHelp5) : FreeGadget(#gadActionHelp6)
  HideGadget(#gadCancel,#True)
  HideGadget(#gadApply,#True)
  HideGadget(#gadTest,#True)
  HideGadget(#gadTestNote,#True)
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
    If CountGadgetItems(#gadShortcuts) > 1
      DisableGadget(#gadDown,#False)
    Else
      DisableGadget(#gadDown,#True)
    EndIf
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
  ButtonGadget(#gadShortcutSelector,70,10,80,20,#pressInvite)
  CocoaMessage(0,GadgetID(#gadShortcutSelector),"setBezelStyle:",10)
  CocoaMessage(0,GadgetID(#gadShortcutSelector),"setFocusRingType:",1)
  TextGadget(#gadActionCap,10,42,60,20,"Action:")
  StringGadget(#gadAction,70,40,290,20,"")
  CocoaMessage(0,GadgetID(#gadAction),"setFocusRingType:",1)
  Define placeholder.s = "input command which will be executed"
  CocoaMessage(0,CocoaMessage(0,GadgetID(#gadAction),"cell"),"setPlaceholderString:$",@placeholder)
  TextGadget(#gadActionHelp,10,70,360,40,~"You can use any command that works in your terminal.\nHere are some examples:")
  HyperLinkGadget(#gadActionHelp1,10,110,120,20,"open an app",$770000)
  SetGadgetColor(#gadActionHelp1,#PB_Gadget_FrontColor,$bb0000)
  HyperLinkGadget(#gadActionHelp2,10,128,120,20,"make a screenshot",$770000)
  SetGadgetColor(#gadActionHelp2,#PB_Gadget_FrontColor,$bb0000)
  HyperLinkGadget(#gadActionHelp3,10,146,120,20,"say current date",$770000)
  SetGadgetColor(#gadActionHelp3,#PB_Gadget_FrontColor,$bb0000)
  HyperLinkGadget(#gadActionHelp4,10,164,160,20,"save clipboard contents",$770000)
  SetGadgetColor(#gadActionHelp4,#PB_Gadget_FrontColor,$bb0000)
  HyperLinkGadget(#gadActionHelp5,10,182,160,20,"set clipboard contents",$770000)
  SetGadgetColor(#gadActionHelp5,#PB_Gadget_FrontColor,$bb0000)
  HyperLinkGadget(#gadActionHelp6,10,200,120,20,"lock screen",$770000)
  SetGadgetColor(#gadActionHelp6,#PB_Gadget_FrontColor,$bb0000)
  HideGadget(#gadTest,#False)
  HideGadget(#gadTestNote,#False)
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

Macro setListStyle()
  If CountGadgetItems(#gadShortcuts)
    ListIconGadgetColumnTitle(#gadShortcuts,0,"⚡")
    ListIconGadgetColumnTitle(#gadShortcuts,1,"⚙")
  Else
    ListIconGadgetColumnTitle(#gadShortcuts,0,"⚡")
  EndIf
  setListIconColumnJustification(#gadShortcuts,0,2)
  setListIconColumnJustification(#gadShortcuts,1,2)
  setListIconColumnJustification(#gadShortcuts,2,2)
  ListIconGadgetColumnToolTip(#gadShortcuts,0,"Enable/disable")
  ListIconGadgetColumnToolTip(#gadShortcuts,1,"Shortcut status")
  ListIconGadgetColumnToolTip(#gadShortcuts,2,"Shortcut")
  ListIconGadgetColumnToolTip(#gadShortcuts,3,"Action to perform")
  ;CocoaMessage(0,GadgetID(#gadShortcuts),"sizeToFit")
  CocoaMessage(0,GadgetID(#gadShortcuts),"sizeLastColumnToFit")
EndMacro

Macro activateSelector(gadget)
  activeSelector = gadget
  If GetGadgetText(activeSelector) <> #pressInvite
    previousHotkey = GetGadgetText(activeSelector)
  EndIf
  CocoaMessage(0,GadgetID(activeSelector),"highlight:",1)
  SetGadgetText(activeSelector,#enterInvite)
EndMacro

Macro deactivateSelector(hotkey = "")
  If activeSelector <> -1
    CocoaMessage(0,GadgetID(activeSelector),"highlight:",0)
    If Len(hotkey)
      SetGadgetText(activeSelector,hotkey)
    ElseIf Len(previousHotkey)
      SetGadgetText(activeSelector,previousHotkey)
    Else
      SetGadgetText(activeSelector,#pressInvite)
    EndIf
    activeSelector = -1
    previousHotkey = ""
  EndIf
EndMacro
; IDE Options = PureBasic 5.60 (MacOS X - x86)
; Folding = ---
; EnableXP
; EnableUnicode