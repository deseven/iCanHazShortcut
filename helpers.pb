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

Procedure.i limitVal(value.i,max.i)
  If value > max
    ProcedureReturn max
  EndIf
  ProcedureReturn value
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

Procedure nativeAction(path.s,args.s,workdir.s = "",stdin.s = "")
  Protected i
  Protected argsArray
  If args
    Protected arg.s = StringField(args,1," ")
    If arg
      argsArray = CocoaMessage(0,0,"NSArray arrayWithObject:$",@arg)
      If CountString(args," ") > 0
        For i = 2 To CountString(args," ") + 1
          arg = StringField(args,i," ")
          If arg
            argsArray = CocoaMessage(0,argsArray,"arrayByAddingObject:$",@arg)
          EndIf
        Next
      EndIf
    EndIf
  EndIf
  Protected task = CocoaMessage(0,CocoaMessage(0,0,"NSTask alloc"),"init")
  
  CocoaMessage(0,task,"setLaunchPath:$",@path)
  
  If argsArray
    CocoaMessage(0,task,"setArguments:",argsArray)
  EndIf
  
  If workdir
    CocoaMessage(0,task,"setCurrentDirectoryPath:$",@workdir)
  EndIf
  
  If stdin
    Protected writePipe = CocoaMessage(0,0,"NSPipe pipe")
    Protected writeHandle = CocoaMessage(0,writePipe,"fileHandleForWriting")
    CocoaMessage(0,task,"setStandardInput:",writePipe)
    Protected string = CocoaMessage(0,0,"NSString stringWithString:$",@stdin)
    Protected stringData = CocoaMessage(0,string,"dataUsingEncoding:",#NSUTF8StringEncoding)
  EndIf
  
  CocoaMessage(0,task,"launch")
  
  If stdin
    CocoaMessage(0,writeHandle,"writeData:",stringData)
    CocoaMessage(0,writeHandle,"closeFile")
  EndIf
  
  CocoaMessage(0,task,"release")
EndProcedure

Macro viewingMode()
  editExistent = #False
  FreeGadget(#gadShortcutSelectorCap) : FreeGadget(#gadShortcutSelector)
  FreeGadget(#gadCommandCap) : FreeGadget(#gadCommand)
  FreeGadget(#gadWorkdirCap) : FreeGadget(#gadWorkdir)
  FreeGadget(#gadActionCap) : FreeGadget(#gadAction)
  FreeGadget(#gadActionHelpFrame) : FreeGadget(#gadActionHelp)
  FreeGadget(#gadActionHelp1) : FreeGadget(#gadActionHelp2) : FreeGadget(#gadActionHelp3)
  FreeGadget(#gadActionHelp4) : FreeGadget(#gadActionHelp5) : FreeGadget(#gadActionHelp6)
  HideGadget(#gadCancel,#True)
  HideGadget(#gadApply,#True)
  HideGadget(#gadTest,#True)
  HideGadget(#gadTestNote,#True)
  TextGadget(#gadBg,0,0,590,300,"") ; dirty fix for a strange redraw behavior
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

Macro editingMode()
  HideGadget(#gadShortcuts,#True)
  HideGadget(#gadAdd,#True)
  HideGadget(#gadEdit,#True)
  HideGadget(#gadDel,#True)
  HideGadget(#gadUp,#True)
  HideGadget(#gadDown,#True)
  OpenGadgetList(#gadTabs,0)
  ;TextGadget(#gadBg,0,0,WindowWidth(#wnd)-10,WindowHeight(#wnd),"") ; dirty fix for a strange redraw behavior
  ;FreeGadget(#gadBg)
  TextGadget(#gadShortcutSelectorCap,10,12,70,20,"Shortcut:")
  ButtonGadget(#gadShortcutSelector,80,10,80,20,#pressInvite)
  CocoaMessage(0,GadgetID(#gadShortcutSelector),"setBezelStyle:",10)
  CocoaMessage(0,GadgetID(#gadShortcutSelector),"setFocusRingType:",1)
  TextGadget(#gadActionCap,10,42,70,20,"Action:")
  StringGadget(#gadAction,80,40,210,20,"")
  CocoaMessage(0,GadgetID(#gadAction),"setFocusRingType:",1)
  TextGadget(#gadCommandCap,10,72,70,20,"Command:")
  StringGadget(#gadCommand,80,70,210,20,"")
  CocoaMessage(0,GadgetID(#gadCommand),"setFocusRingType:",1)
  TextGadget(#gadWorkdirCap,10,102,70,20,"Workdir:")
  StringGadget(#gadWorkdir,80,100,210,20,"")
  CocoaMessage(0,GadgetID(#gadWorkdir),"setFocusRingType:",1)
  Define placeholderAction.s = "human-friendly name (optional)"
  CocoaMessage(0,CocoaMessage(0,GadgetID(#gadAction),"cell"),"setPlaceholderString:$",@placeholderAction)
  Define placeholderCommand.s = "command to execute"
  CocoaMessage(0,CocoaMessage(0,GadgetID(#gadCommand),"cell"),"setPlaceholderString:$",@placeholderCommand)
  Define placeholderWorkdir.s = "working directory (optional)"
  CocoaMessage(0,CocoaMessage(0,GadgetID(#gadWorkdir),"cell"),"setPlaceholderString:$",@placeholderWorkdir)
  FrameGadget(#gadActionHelpFrame,300,0,260,220,"")
  TextGadget(#gadActionHelp,310,10,250,40,~"You can use any command that works in your terminal. Here are some examples:")
  HyperLinkGadget(#gadActionHelp1,310,50,120,20,"open an app",#linkColorHighlighted)
  SetGadgetColor(#gadActionHelp1,#PB_Gadget_FrontColor,#linkColor)
  HyperLinkGadget(#gadActionHelp2,310,68,120,20,"make a screenshot",#linkColorHighlighted)
  SetGadgetColor(#gadActionHelp2,#PB_Gadget_FrontColor,#linkColor)
  HyperLinkGadget(#gadActionHelp3,310,86,120,20,"say current date",#linkColorHighlighted)
  SetGadgetColor(#gadActionHelp3,#PB_Gadget_FrontColor,#linkColor)
  HyperLinkGadget(#gadActionHelp4,310,104,160,20,"save clipboard contents",#linkColorHighlighted)
  SetGadgetColor(#gadActionHelp4,#PB_Gadget_FrontColor,#linkColor)
  HyperLinkGadget(#gadActionHelp5,310,122,160,20,"set clipboard contents",#linkColorHighlighted)
  SetGadgetColor(#gadActionHelp5,#PB_Gadget_FrontColor,#linkColor)
  HyperLinkGadget(#gadActionHelp6,310,140,120,20,"lock screen",#linkColorHighlighted)
  SetGadgetColor(#gadActionHelp6,#PB_Gadget_FrontColor,#linkColor)
  HideGadget(#gadTest,#False)
  HideGadget(#gadTestNote,#False)
  HideGadget(#gadApply,#False)
  HideGadget(#gadCancel,#False)
  CloseGadgetList()
  CocoaMessage(0,GadgetID(#gadAction),"setNextKeyView:",GadgetID(#gadCommand))
  CocoaMessage(0,GadgetID(#gadCommand),"setNextKeyView:",GadgetID(#gadWorkdir))
  CocoaMessage(0,GadgetID(#gadWorkdir),"setNextKeyView:",GadgetID(#gadAction))
  PostEvent(#PB_Event_SizeWindow)
EndMacro

Macro editingExistentMode()
  editExistent = #True
  editingMode()
  SetGadgetText(#gadShortcutSelector,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),0))
  SetGadgetText(#gadAction,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),1))
  SetGadgetText(#gadCommand,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),2))
  SetGadgetText(#gadWorkdir,GetGadgetItemText(#gadShortcuts,GetGadgetState(#gadShortcuts),3))
EndMacro

Macro setListStyle()
  setListIconColumnJustification(#gadShortcuts,0,2)
  setListIconColumnJustification(#gadShortcuts,1,2)
  setListIconColumnJustification(#gadShortcuts,2,2)
  ListIconGadgetColumnToolTip(#gadShortcuts,0,"Enable/disable")
  ListIconGadgetColumnToolTip(#gadShortcuts,1,"Shortcut status")
  ListIconGadgetColumnToolTip(#gadShortcuts,2,"Shortcut")
  ListIconGadgetColumnToolTip(#gadShortcuts,3,"Action name")
  ListIconGadgetColumnToolTip(#gadShortcuts,4,"Command to execute")
  ;CocoaMessage(0,GadgetID(#gadShortcuts),"sizeToFit")
  ;CocoaMessage(0,GadgetID(#gadShortcuts),"sizeLastColumnToFit")
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

Macro setColumnsState()
  If GetMenuItemState(#columnMenu,#columnMenuShortcut)
    ListIconGadgetHideColumn(#gadShortcuts,2,#False)
  Else
    ListIconGadgetHideColumn(#gadShortcuts,2,#True)
  EndIf
  If GetMenuItemState(#columnMenu,#columnMenuAction)
    ListIconGadgetHideColumn(#gadShortcuts,3,#False)
  Else
    ListIconGadgetHideColumn(#gadShortcuts,3,#True)
  EndIf
  If GetMenuItemState(#columnMenu,#columnMenuCommand)
    ListIconGadgetHideColumn(#gadShortcuts,4,#False)
  Else
    ListIconGadgetHideColumn(#gadShortcuts,4,#True)
  EndIf
  If GetMenuItemState(#columnMenu,#columnMenuWorkdir)
    ListIconGadgetHideColumn(#gadShortcuts,5,#False)
  Else
    ListIconGadgetHideColumn(#gadShortcuts,5,#True)
  EndIf
EndMacro

Macro ToggleMenuItemState(Menu,MenuItem)
  If GetMenuItemState(Menu,MenuItem)
    SetMenuItemState(Menu,MenuItem,#False)
  Else
    SetMenuItemState(Menu,MenuItem,#True)
  EndIf
EndMacro