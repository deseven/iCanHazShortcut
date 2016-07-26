ImportC "/System/Library/Frameworks/Accelerate.framework/Accelerate"
  vImageUnpremultiplyData_RGBA8888 (*src, *dest, flags) 
EndImport

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

Macro viewingMode()
  FreeGadget(#gadShortcutSelectorCap) : FreeGadget(#gadShortcutSelector)
  FreeGadget(#gadActionCap) : FreeGadget(#gadAction) : FreeGadget(#gadActionHelp)
  FreeGadget(#gadActionHelp1) : FreeGadget(#gadActionHelp2) : FreeGadget(#gadActionHelp3)
  FreeGadget(#gadActionHelp4) : FreeGadget(#gadActionHelp5) : FreeGadget(#gadActionHelp6)
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
; IDE Options = PureBasic 5.42 LTS (MacOS X - x64)
; Folding = ---
; EnableUnicode
; EnableXP