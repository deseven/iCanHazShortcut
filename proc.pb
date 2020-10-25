﻿Declare checkUpdateAsync(interval.i)

Procedure die()
  Shared updateCheckThread.i
  If IsThread(updateCheckThread)
    KillThread(updateCheckThread)
  EndIf
  End 0
EndProcedure

Procedure wndState(show.b)
  Shared application.i
  If Not show
    CocoaMessage(0, application, "setActivationPolicy:", #NSApplicationActivationPolicyAccessory)
    CocoaMessage(0,application,"hide:")
  Else
    ;CocoaMessage(0,GadgetID(#gadShortcuts),"sizeLastColumnToFit")
    ;CocoaMessage(0,application,"activateIgnoringOtherApps:",#YES)
    ;CocoaMessage(0,WindowID(#wnd),"makeKeyAndOrderFront:")
    CocoaMessage(0, application, "setActivationPolicy:", #NSApplicationActivationPolicyRegular)
    CocoaMessage(0,application,"unhide:")
  EndIf
EndProcedure

Procedure settings(save.b = #False)
  Protected shortcut.s,action.s,command.s,workdir.s,i.l
  Shared updateVer.s
  Shared setWorkdirWithCD.b
  Shared wndW,wndH,wndX,wndY
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
    WritePreferenceString("config version",#cfgVer)
    If updateVer <> #myVer
      WritePreferenceString("skip update",updateVer)
    EndIf
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
    If GetGadgetState(#gadPrefAutostart) = #PB_Checkbox_Checked
      WritePreferenceString("start_on_login","yes")
    Else
      WritePreferenceString("start_on_login","no")
    EndIf
    If GetGadgetState(#gadPrefStatusBar) = #PB_Checkbox_Checked
      WritePreferenceString("show_icon_in_statusbar","yes")
    Else
      WritePreferenceString("show_icon_in_statusbar","no")
    EndIf
    If GetGadgetState(#gadPrefSetWorkdirCD) = #PB_Checkbox_Checked
      WritePreferenceString("set_workdir_with_cd","yes")
    Else
      WritePreferenceString("set_workdir_with_cd","no")
    EndIf
    WritePreferenceInteger("window_x",wndX)
    WritePreferenceInteger("window_y",wndY)
    WritePreferenceInteger("window_width",wndW)
    WritePreferenceInteger("window_height",wndH)
    For i = 0 To CountGadgetItems(#gadShortcuts)-1
      shortcut = GetGadgetItemText(#gadShortcuts,i,0)
      action = GetGadgetItemText(#gadShortcuts,i,1)
      command = GetGadgetItemText(#gadShortcuts,i,2)
      workdir = GetGadgetItemText(#gadShortcuts,i,3)
      PreferenceGroup("shortcut" + Str(i+1))
      WritePreferenceString("shortcut",shortcut)
      WritePreferenceString("action",action)
      WritePreferenceString("command",command)
      WritePreferenceString("workdir",workdir)
      If GetGadgetItemState(#gadShortcuts,i) >= #PB_ListIcon_Checked
        WritePreferenceString("enabled","yes")
      Else
        WritePreferenceString("enabled","no")
      EndIf
    Next
  Else
    OpenPreferences(path,#PB_Preference_GroupSeparator)
    PreferenceGroup("main")
    If FileSize(path) > 0 And ReadPreferenceString("config version","unknown") <> #cfgVer
      If CopyFile(path,path + ".bak")
        MessageRequester(#myName,#backupMsg + path + ".bak")
        PostEvent(#evUpdateConfig)
      EndIf
    EndIf
    updateVer = ReadPreferenceString("skip update",#myVer)
    Protected legacyShell.s = ReadPreferenceString("shell","/bin/bash -l")
    ; compatibility with older configs
    Select legacyShell
      Case "sh","csh","tcsh","bash","zsh","ksh"
        legacyShell = "/bin/" + legacyShell + " -l"
      Case "no shell"
        legacyShell = ""
    EndSelect
    SetGadgetText(#gadPrefShell,legacyShell)
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
    If ReadPreferenceString("start_on_login","no") = "yes"
      SetGadgetState(#gadPrefAutostart,#PB_Checkbox_Checked)
    Else
      SetGadgetState(#gadPrefAutostart,#PB_Checkbox_Unchecked)
    EndIf
    If ReadPreferenceString("show_icon_in_statusbar","yes") = "yes"
      SetGadgetState(#gadPrefStatusBar,#PB_Checkbox_Checked)
    Else
      SetGadgetState(#gadPrefStatusBar,#PB_Checkbox_Unchecked)
    EndIf
    If ReadPreferenceString("set_workdir_with_cd","no") = "yes"
      SetGadgetState(#gadPrefSetWorkdirCD,#PB_Checkbox_Checked)
      setWorkdirWithCD = #True
    Else
      SetGadgetState(#gadPrefSetWorkdirCD,#PB_Checkbox_Unchecked)
      setWorkdirWithCD = #False
    EndIf
    wndX = ReadPreferenceInteger("window_x",#PB_Ignore)
    wndY = ReadPreferenceInteger("window_y",#PB_Ignore)
    wndW = ReadPreferenceInteger("window_width",600)
    wndH = ReadPreferenceInteger("window_height",300)
    ExaminePreferenceGroups()
    i = 0
    While NextPreferenceGroup()
      If FindString(PreferenceGroupName(),"shortcut") = 1
        shortcut = ReadPreferenceString("shortcut","")
        action = ReadPreferenceString("action","")
        command = ReadPreferenceString("command","")
        workdir = ReadPreferenceString("workdir","")
        If Not Len(command) And Len(action)
          command = action
          action = ""
        EndIf
        If Len(command) And Len(shortcut)
          AddGadgetItem(#gadShortcuts,-1,shortcut + ~"\n" + action + ~"\n" + command + ~"\n" + workdir)
          If ReadPreferenceString("enabled","yes") = "yes"
            SetGadgetItemState(#gadShortcuts,i,#PB_ListIcon_Checked)
          EndIf
        EndIf
        i + 1
      EndIf
    Wend
  EndIf
  ClosePreferences()
EndProcedure

Procedure initResources()
  Protected imageSize.NSSize
  Protected path.s = GetPathPart(ProgramFilename()) + "../Resources/"
  LoadFont(#resNormalFont,"Lucida Grande",12)
  LoadFont(#resBigFont,"Courier",18,#PB_Font_Bold)
  If LoadImageEx(#resLogo,path+"main.icns") And
     LoadImageEx(#resAdd,path+"plus-circle.png") And
     LoadImageEx(#resEdit,path+"edit-circle.png") And
     LoadImageEx(#resDel,path+"minus-circle.png") And
     LoadImageEx(#resTest,path+"test-circle.png") And
     LoadImageEx(#resApply,path+"apply-circle.png") And
     LoadImageEx(#resCancel,path+"cancel-circle.png") And
     LoadImageEx(#resOk,path+"on.png") And
     LoadImageEx(#resDisabled,path+"off.png") And
     LoadImageEx(#resFailed,path+"on-failed.png") And
     LoadImageEx(#resUp,path+"arrow-up-circle.png") And
     LoadImageEx(#resDown,path+"arrow-down-circle.png")
    If getBackingScaleFactor() >= 2.0
      If Not LoadImageEx(#resIcon,path+"status_icon@2x.png") : End 1 : EndIf
      imageSize\width = 20
      imageSize\height = 20
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
      CocoaMessage(0,ImageID(#resTest),"setSize:@",@ImageSize)
      imageSize\width = 16
      imageSize\height = 16
      CocoaMessage(0,ImageID(#resOk),"setSize:@",@ImageSize)
      CocoaMessage(0,ImageID(#resDisabled),"setSize:@",@ImageSize)
      CocoaMessage(0,ImageID(#resFailed),"setSize:@",@ImageSize)
    Else
      If Not LoadImageEx(#resIcon,path+"status_icon.png") : End 1 : EndIf
      ResizeImage(#resLogo,64,64,#PB_Image_Smooth)
      ResizeImage(#resAdd,24,24,#PB_Image_Smooth)
      ResizeImage(#resEdit,24,24,#PB_Image_Smooth)
      ResizeImage(#resDel,24,24,#PB_Image_Smooth)
      ResizeImage(#resApply,24,24,#PB_Image_Smooth)
      ResizeImage(#resCancel,24,24,#PB_Image_Smooth)
      ResizeImage(#resUp,24,24,#PB_Image_Smooth)
      ResizeImage(#resDown,24,24,#PB_Image_Smooth)
      ResizeImage(#resTest,24,24,#PB_Image_Smooth)
      ResizeImage(#resOk,16,16,#PB_Image_Smooth)
      ResizeImage(#resDisabled,16,16,#PB_Image_Smooth)
      ResizeImage(#resFailed,16,16,#PB_Image_Smooth)
    EndIf
    CocoaMessage(0,ImageID(#resIcon),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resAdd),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resEdit),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resDel),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resApply),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resCancel),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resUp),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resDown),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resTest),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resOk),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resDisabled),"setTemplate:",#True)
    CocoaMessage(0,ImageID(#resFailed),"setTemplate:",#True)
  Else
    Debug "failed to load image"
    End 1
  EndIf
EndProcedure

Procedure.s handleWorkdir(workdir.s)
  ; probably the safest way to expand tilde
  ; https://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash
  If Left(workdir,1) = "~"
    workdir = ReplaceString(workdir,"~",GetEnvironmentVariable("HOME"),0,1,1)
  EndIf
  If FindString(workdir,"$")
    
  EndIf
  ProcedureReturn workdir
EndProcedure

Procedure action(command.s,workdir.s)
  Protected shell.s = GetGadgetText(#gadPrefShell)
  Protected program.s,params.s
  Shared setWorkdirWithCD.b
  workdir = handleWorkdir(workdir)
  
  If shell = ""
    Protected programEnd.l = FindString(command," ")
    If programEnd
      program = Left(command,programEnd-1)
      params = Mid(command,programEnd+1)
    Else
      program = command
    EndIf
    ;Debug "running '" + program + "' with '" + params + "'"
    nativeAction(program,params,workdir)
    ;RunProgram(program,params,workdir)
  Else
    Protected shellEnd.l = FindString(shell," ")
    If shellEnd
      params = Mid(shell,shellEnd+1)
      shell = Left(shell,shellEnd-1)
    EndIf
    If setWorkdirWithCD
      command = ~"cd \"" + workdir + ~"\"\n" + command
    EndIf
    ;Debug "running '" + shell + "' with '" + command + "'"
    nativeAction(shell,params,workdir,command)
    ;Protected pid = RunProgram(shell,params,workdir,#PB_Program_Write|#PB_Program_Open)
    ;If IsProgram(pid)
    ;  If setWorkdirWithCD
    ;    WriteProgramStringN(pid,"cd " + workdir)
    ;  EndIf
    ;  WriteProgramString(pid,command)
    ;EndIf
    ;CloseProgram(pid)
  EndIf
EndProcedure

Procedure testRun(command.s,workdir.s)
  Protected tool.i,out.s,error.s,errString.s
  Protected bytes,oldBytes
  Protected *buf
  Protected ev.i
  Shared application.i
  Shared testRunResult.testRunResults
  Shared setWorkdirWithCD.b
  testRunResult\aborted = #False
  testRunResult\exitCode = 0
  OpenWindow(#wndSheet,0,0,140,80,"",#PB_Window_SystemMenu|#PB_Window_Invisible)
  ButtonGadget(#gadTestAbort,20,40,100,30,"Abort")
  ProgressBarGadget(#gadTestProgress,65,15,0,0,0,0)
  CocoaMessage(0,GadgetID(#gadTestProgress),"setIndeterminate:",#YES)
  CocoaMessage(0,GadgetID(#gadTestProgress),"setStyle:",1)
  CocoaMessage(0,GadgetID(#gadTestProgress),"setControlSize:",1)
  CocoaMessage(0,GadgetID(#gadTestProgress),"sizeToFit")
  CocoaMessage(0,GadgetID(#gadTestProgress),"startAnimation:",#nil)
  CocoaMessage(0,application,"beginSheet:",WindowID(#wndSheet),"modalForWindow:",WindowID(#wnd),"modalDelegate:",#nil,"didEndSelector:",0,"contextInfo:",0)
  
  Protected shell.s = GetGadgetText(#gadPrefShell)
  Protected program.s,params.s
  workdir = handleWorkdir(workdir)
  
  If shell = ""
    Protected programEnd.l = FindString(command," ")
    If programEnd
      program = Left(command,programEnd-1)
      params = Mid(command,programEnd+1)
    Else
      program = command
    EndIf
    tool = RunProgram(program,params,workdir,#PB_Program_Open|#PB_Program_Read|#PB_Program_Error|#PB_Program_Hide)
  Else
    Protected shellEnd.l = FindString(shell," ")
    If shellEnd
      params = Mid(shell,shellEnd+1)
      shell = Left(shell,shellEnd-1)
    EndIf
    tool = RunProgram(shell,params,workdir,#PB_Program_Open|#PB_Program_Read|#PB_Program_Write|#PB_Program_Error|#PB_Program_Hide)
  EndIf
  If tool
    If shell
      If setWorkdirWithCD
        WriteProgramStringN(tool,"cd " + workdir)
      EndIf
      WriteProgramString(tool,command)
      WriteProgramData(tool,#PB_Program_Eof,0)
    EndIf
    While ProgramRunning(tool)
      bytes = AvailableProgramOutput(tool)
      If bytes
        If Not *buf
          *buf = AllocateMemory(bytes)
        Else
          *buf = ReAllocateMemory(*buf,oldBytes+bytes)
        EndIf
        ReadProgramData(tool,*buf+oldBytes,bytes)
        oldBytes = MemorySize(*buf)
      EndIf
      Repeat
        errString.s = ReadProgramError(tool)
        If Len(errString)
          error + errString + ~"\n"
        Else
          Break
        EndIf
      ForEver
      ev = WaitWindowEvent(10)
      If ev = #PB_Event_Gadget And EventGadget() = #gadTestAbort
        testRunResult\aborted = #True
        testRunResult\exitCode = -1
        KillProgram(tool)
        Break
      EndIf
    Wend
    Repeat
      Protected i.i
      errString.s = ReadProgramError(tool)
      If Len(errString)
        error + errString + ~"\n"
      Else
        i + 1
        If i >= 1000
          Break
        EndIf
      EndIf
    ForEver
    If *buf
      out = PeekS(*buf,MemorySize(*buf),#PB_UTF8|#PB_ByteLength)
      FreeMemory(*buf)
    EndIf
    If Not testRunResult\aborted
      testRunResult\exitCode = ProgramExitCode(tool)
    EndIf
    CloseProgram(tool)
  Else
    testRunResult\exitCode = -1
  EndIf
  testRunResult\stderr = error
  testRunResult\stdout = out
  CocoaMessage(0,application,"endSheet:",WindowID(#wndSheet))
  CocoaMessage(0,GadgetID(#gadTestProgress),"stopAnimation:",#nil)
  CocoaMessage(0,WindowID(#wndSheet),"orderOut:",#nil)
  While WindowEvent() : Wend
  CloseWindow(#wndSheet)
EndProcedure

Procedure menuEvents()
  Shared application.i
  Select EventMenu()
    Case #menuShortcuts
      SetGadgetState(#gadTabs,0)
      SetActiveGadget(#gadShortcuts)
      wndState(#show)
      setListStyle()
    Case #menuPrefs
      SetGadgetState(#gadTabs,1)
      wndState(#show)
    Case #menuUpdateCheck
      CreateThread(@checkUpdateAsync(),0)
    Case #menuAbout
      SetGadgetState(#gadTabs,2)
      SetActiveGadget(#gadCopyright)
      wndState(#show)
    Case #menuQuit
      die()
  EndSelect
EndProcedure

Procedure shortcutEvents()
  If EventData() >= 0
    If CountGadgetItems(#gadShortcuts) => EventData()+1
      action(GetGadgetItemText(#gadShortcuts,EventData(),2),GetGadgetItemText(#gadShortcuts,EventData(),3))
    EndIf
  EndIf
EndProcedure

Procedure shortcutMenuEvents()
  If EventType() = #PB_EventType_LeftClick
    If CountGadgetItems(#gadShortcuts) => EventMenu()-#menuCustom+1
      action(GetGadgetItemText(#gadShortcuts,EventMenu()-#menuCustom,2),GetGadgetItemText(#gadShortcuts,EventMenu()-#menuCustom,3))
    EndIf
  EndIf
EndProcedure

Procedure buildMenu()
  Shared statusBar.i,statusItem.i
  Protected itemLength.CGFloat = 24
  Protected i.l
  If GetGadgetState(#gadPrefStatusBar) = #PB_Checkbox_Checked
    If Not statusBar
      statusBar.i = CocoaMessage(0,0,"NSStatusBar systemStatusBar")
    EndIf
    If Not statusItem
      statusItem.i = CocoaMessage(0,CocoaMessage(0,statusBar,"statusItemWithLength:",#NSSquareStatusBarItemLength),"retain")
    EndIf
    If IsMenu(#menu) : FreeMenu(#menu) : EndIf
    CreatePopupMenu(#menu)
    For i = 0 To 1000            ; temporary solution
      UnbindMenuEvent(#menu,i,@shortcutMenuEvents())
    Next
    If GetGadgetState(#gadPrefPopulateMenu) = #PB_Checkbox_Checked And CountGadgetItems(#gadShortcuts)
      For i = 0 To CountGadgetItems(#gadShortcuts)-1
        If GetGadgetItemState(#gadShortcuts,i) >= #PB_ListIcon_Checked
          If GetGadgetState(#gadPrefShowHtk) = #PB_Checkbox_Checked
            If Len(GetGadgetItemText(#gadShortcuts,i,1))
              MenuItem(#menuCustom+i,"[" + GetGadgetItemText(#gadShortcuts,i,0) + "] " + GetGadgetItemText(#gadShortcuts,i,1))
            Else
              MenuItem(#menuCustom+i,"[" + GetGadgetItemText(#gadShortcuts,i,0) + "] " + GetGadgetItemText(#gadShortcuts,i,2))
            EndIf
          Else
            If Len(GetGadgetItemText(#gadShortcuts,i,1))
              MenuItem(#menuCustom+i,GetGadgetItemText(#gadShortcuts,i,1))
            Else
              MenuItem(#menuCustom+i,GetGadgetItemText(#gadShortcuts,i,2))
            EndIf
          EndIf
          BindMenuEvent(#menu,#menuCustom+i,@shortcutMenuEvents())
        EndIf
      Next
      MenuBar()
    EndIf
    MenuItem(#menuShortcuts,"Shortcuts...")
    BindMenuEvent(#menu,#menuShortcuts,@menuEvents())
    MenuItem(#menuPrefs,"Preferences...")
    BindMenuEvent(#menu,#menuPrefs,@menuEvents())
    MenuItem(#menuUpdateCheck,"Check for updates")
    BindMenuEvent(#menu,#menuUpdateCheck,@menuEvents())
    MenuItem(#menuAbout,"About")
    BindMenuEvent(#menu,#menuAbout,@menuEvents())
    MenuBar()
    MenuItem(#menuQuit,"Quit")
    BindMenuEvent(#menu,#menuQuit,@menuEvents())
    CocoaMessage(0,statusItem,"setHighlightMode:",@"YES")
    CocoaMessage(0,statusItem,"setLength:@",@itemLength)
    CocoaMessage(0,statusItem,"setImage:",ImageID(#resIcon))
    CocoaMessage(0,statusItem,"setMenu:",CocoaMessage(0,MenuID(#menu),"firstObject"))
  Else
    If IsMenu(#menu)
      For i = 0 To 1000            ; temporary solution
        UnbindMenuEvent(#menu,i,@shortcutMenuEvents())
      Next
      FreeMenu(#menu)
    EndIf
    If statusItem
      CocoaMessage(0,statusBar,"removeStatusItem:",statusItem) : statusItem = 0
    EndIf
  EndIf
EndProcedure

Procedure registerShortcuts()
  Protected i.l
  globalHK::remove("",0,#True) ; unregistering all to be on the safe side
  For i = 0 To 1000            ; temporary solution
    UnbindEvent(#PB_Event_FirstCustomValue+i,@shortcutEvents())
  Next
  For i = 0 To CountGadgetItems(#gadShortcuts)-1
    Protected shortcut.s = GetGadgetItemText(#gadShortcuts,i,0)
    If GetGadgetItemState(#gadShortcuts,i) >= #PB_ListIcon_Checked
      If globalHK::add(shortcut,#PB_Event_FirstCustomValue + i,#PB_Ignore,#PB_Ignore,#PB_Ignore,i)
        BindEvent(#PB_Event_FirstCustomValue + i,@shortcutEvents())
        SetGadgetItemImage(#gadShortcuts,i,ImageID(#resOk))
      Else
        SetGadgetItemImage(#gadShortcuts,i,ImageID(#resFailed))
      EndIf
    Else
      SetGadgetItemImage(#gadShortcuts,i,ImageID(#resDisabled))
    EndIf
  Next
  buildMenu()
  setListStyle()
EndProcedure

Procedure checkUpdateAsync(interval.i)
  Shared updateVer.s,updateDetails.s
  Protected *buf,i,strCount
  Protected Dim strings.s(1)
  If Not InitNetwork() : ProcedureReturn : EndIf
  ;CompilerIf Not #PB_Compiler_Debugger
    Delay(interval)
  ;CompilerEndIf
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
        If newVer <> updateVer And newVer <> #myVer
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
    If interval > 0
      Delay(interval)
    Else
      PostEvent(#evNoUpdateFound)
      ProcedureReturn
    EndIf
  ForEver
EndProcedure

ProcedureC keyHandler(sender,sel,event)
  Shared activeSelector
  Shared previousHotkey
  Shared keys()
  Shared singleWL.s()
  Protected result = #YES  
  Protected currentHtk.s
  Static currentMod.s
  Protected fnPressed.b
  If event
    Select CocoaMessage(0,event,"type")
      Case #NSKeyDown
        Define keyCode = CocoaMessage(0,event,"keyCode")
        If keyCode <= $FF
          If Len(keys(keyCode))
            currentHtk + keys(keyCode)
          EndIf
        EndIf
      Case #NSFlagsChanged
        currentMod = ""
        Protected modifierFlags = CocoaMessage(0, event, "modifierFlags")
        If modifierFlags & #NSShiftKeyMask     : currentMod + "⇧" : EndIf
        If modifierFlags & #NSControlKeyMask   : currentMod + "⌃" : EndIf
        If modifierFlags & #NSAlternateKeyMask : currentMod + "⌥" : EndIf
        If modifierFlags & #NSCommandKeyMask   : currentMod + "⌘" : EndIf
        If modifierFlags & #NSFunctionKeyMask  : fnPressed = #True : EndIf
    EndSelect
    If activeSelector <> -1 And IsGadget(#gadShortcutSelector)
      If Len(currentMod) = 0 And currentHtk = "⎋"
        deactivateSelector()
      ElseIf Len(currentMod) = 0 And singleWL(currentHtk)
        deactivateSelector(currentHtk)
      ElseIf Len(currentMod) And Len(currentHtk)
        deactivateSelector(currentMod + currentHtk)
      ElseIf Len(currentMod)
        SetGadgetText(#gadShortcutSelector,currentMod + currentHtk)
      ElseIf fnPressed
        ; do nothing and wait for full hotkey
      Else
        deactivateSelector()
        SetGadgetText(#gadShortcutSelector,#pressInvite)
      EndIf
    Else
      result = #NO
    EndIf
  EndIf
  ProcedureReturn result
EndProcedure

ProcedureC windowHandler()
  Protected w.i = WindowWidth(#wnd)
  Protected h.i = WindowHeight(#wnd)
  Protected i.i
  ResizeGadget(#gadTabs,#PB_Ignore,#PB_Ignore,w-10,h)

  ; Shortcuts
  ResizeGadget(#gadShortcuts,#PB_Ignore,#PB_Ignore,w-40,h-80)
  ResizeGadget(#gadAdd,w-140,h-78,#PB_Ignore,#PB_Ignore)
  ResizeGadget(#gadEdit,w-104,h-78,#PB_Ignore,#PB_Ignore)
  ResizeGadget(#gadDel,w-68,h-78,#PB_Ignore,#PB_Ignore)
  ResizeGadget(#gadTest,w-140,h-78,#PB_Ignore,#PB_Ignore)
  ResizeGadget(#gadTestNote,w-390,h-70,#PB_Ignore,#PB_Ignore)
  ResizeGadget(#gadApply,w-104,h-78,#PB_Ignore,#PB_Ignore)
  ResizeGadget(#gadCancel,w-68,h-78,#PB_Ignore,#PB_Ignore)
  ResizeGadget(#gadUp,#PB_Ignore,h-78,#PB_Ignore,#PB_Ignore)
  ResizeGadget(#gadDown,#PB_Ignore,h-78,#PB_Ignore,#PB_Ignore)

  ; Shortcut editor
  If IsGadget(#gadActionHelpFrame) : ResizeGadget(#gadActionHelpFrame,w-300,#PB_Ignore,#PB_Ignore,h-80) : EndIf
  If IsGadget(#gadActionHelp) : ResizeGadget(#gadActionHelp,w-290,#PB_Ignore,#PB_Ignore,#PB_Ignore) : EndIf
  For i = #gadActionHelp1 To #gadActionHelp6
    If IsGadget(i) : ResizeGadget(i,w-290,#PB_Ignore,#PB_Ignore,#PB_Ignore) : EndIf
  Next
  If IsGadget(#gadAction) : ResizeGadget(#gadAction,#PB_Ignore,#PB_Ignore,limitVal(w-390,400),#PB_Ignore) : EndIf
  If IsGadget(#gadCommand) : ResizeGadget(#gadCommand,#PB_Ignore,#PB_Ignore,w-390,#PB_Ignore) : EndIf
  If IsGadget(#gadWorkdir) : ResizeGadget(#gadWorkdir,#PB_Ignore,#PB_Ignore,limitVal(w-390,400),#PB_Ignore) : EndIf

  ; Preferences
  ResizeGadget(#gadPrefFrame,w-220,#PB_Ignore,#PB_Ignore,h-50)
  For i = #gadPrefStatusBar To #gadPrefSetWorkdirCD
    ResizeGadget(i,w-210,#PB_Ignore,#PB_Ignore,#PB_Ignore)
  Next

  ; About
  ResizeGadget(#gadLicense,#PB_Ignore,#PB_Ignore,w-240,h-55)
EndProcedure