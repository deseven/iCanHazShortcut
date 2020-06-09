ProcedureC asListShortcuts(command.i)
  Protected i
  Protected answerString.s
  For i = 0 To CountGadgetItems(#gadShortcuts)-1
    Protected shortcut.s = GetGadgetItemText(#gadShortcuts,i,0)
    Protected state.s
    If GetGadgetItemState(#gadShortcuts,i) >= #PB_ListIcon_Checked
      state = "1"
    Else
      state = "0"
    EndIf
    Protected action.s = GetGadgetItemText(#gadShortcuts,i,1)
    Protected cmd.s = GetGadgetItemText(#gadShortcuts,i,2)
    answerString + Str(i+1) + ~"\t" + state + ~"\t" + shortcut + ~"\t" + action + ~"\t" + cmd + ~"\n"
  Next
  Protected answer = CocoaMessage(0,0,"NSString stringWithString:$",@answerString)
  ProcedureReturn answer
EndProcedure

ProcedureC asEnableShortcutID(command.i)
  Protected argument.i = CocoaMessage(0,command,"evaluatedArguments")
  If argument
    Protected number = CocoaMessage(0,CocoaMessage(0,argument,"valueForKey:$",@""),"intValue")
    If number
      PostEvent(#evEnableShortcutID,0,0,0,number)
    EndIf
  EndIf
EndProcedure

ProcedureC asDisableShortcutID(command.i)
  Protected argument.i = CocoaMessage(0,command,"evaluatedArguments")
  If argument
    Protected number = CocoaMessage(0,CocoaMessage(0,argument,"valueForKey:$",@""),"intValue")
    If number
      PostEvent(#evDisableShortcutID,0,0,0,number)
    EndIf
  EndIf
EndProcedure

ProcedureC asToggleShortcutID(command.i)
  Protected argument.i = CocoaMessage(0,command,"evaluatedArguments")
  If argument
    Protected number = CocoaMessage(0,CocoaMessage(0,argument,"valueForKey:$",@""),"intValue")
    If number
      PostEvent(#evToggleShortcutID,0,0,0,number)
    EndIf
  EndIf
EndProcedure

ProcedureC asEnableShortcut(command.i)
  Static shortcut.s = ""
  Protected argument.i = CocoaMessage(0,command,"evaluatedArguments")
  If argument
    Protected string = CocoaMessage(0,CocoaMessage(0,argument,"valueForKey:$",@""),"UTF8String")
    If string
      shortcut = PeekS(string,-1,#PB_UTF8)
      If Len(shortcut)
        PostEvent(#evEnableShortcut,0,0,0,@shortcut)
      EndIf
    EndIf
  EndIf
EndProcedure

ProcedureC asDisableShortcut(command.i)
  Static shortcut.s = ""
  Protected argument.i = CocoaMessage(0,command,"evaluatedArguments")
  If argument
    Protected string = CocoaMessage(0,CocoaMessage(0,argument,"valueForKey:$",@""),"UTF8String")
    If string
      shortcut = PeekS(string,-1,#PB_UTF8)
      If Len(shortcut)
        PostEvent(#evDisableShortcut,0,0,0,@shortcut)
      EndIf
    EndIf
  EndIf
EndProcedure

ProcedureC asToggleShortcut(command.i)
  Static shortcut.s = ""
  Protected argument.i = CocoaMessage(0,command,"evaluatedArguments")
  If argument
    Protected string = CocoaMessage(0,CocoaMessage(0,argument,"valueForKey:$",@""),"UTF8String")
    If string
      shortcut = PeekS(string,-1,#PB_UTF8)
      If Len(shortcut)
        PostEvent(#evToggleShortcut,0,0,0,@shortcut)
      EndIf
    EndIf
  EndIf
EndProcedure

ProcedureC asEnableAction(command.i)
  Static action.s = ""
  Protected argument.i = CocoaMessage(0,command,"evaluatedArguments")
  If argument
    Protected string = CocoaMessage(0,CocoaMessage(0,argument,"valueForKey:$",@""),"UTF8String")
    If string
      action = PeekS(string,-1,#PB_UTF8)
      If Len(action)
        PostEvent(#evEnableAction,0,0,0,@action)
      EndIf
    EndIf
  EndIf
EndProcedure

ProcedureC asDisableAction(command.i)
  Static action.s = ""
  Protected argument.i = CocoaMessage(0,command,"evaluatedArguments")
  If argument
    Protected string = CocoaMessage(0,CocoaMessage(0,argument,"valueForKey:$",@""),"UTF8String")
    If string
      action = PeekS(string,-1,#PB_UTF8)
      If Len(action)
        PostEvent(#evDisableAction,0,0,0,@action)
      EndIf
    EndIf
  EndIf
EndProcedure

ProcedureC asToggleAction(command.i)
  Static action.s = ""
  Protected argument.i = CocoaMessage(0,command,"evaluatedArguments")
  If argument
    Protected string = CocoaMessage(0,CocoaMessage(0,argument,"valueForKey:$",@""),"UTF8String")
    If string
      action = PeekS(string,-1,#PB_UTF8)
      If Len(action)
        PostEvent(#evToggleAction,0,0,0,@action)
      EndIf
    EndIf
  EndIf
EndProcedure

Define subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asEnableShortcut",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asEnableShortcut(),"v@")
objc_registerClassPair_(subClass)
subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asDisableShortcut",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asDisableShortcut(),"v@")
objc_registerClassPair_(subClass)
subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asToggleShortcut",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asToggleShortcut(),"v@")
objc_registerClassPair_(subClass)

subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asEnableAction",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asEnableAction(),"v@")
objc_registerClassPair_(subClass)
subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asDisableAction",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asDisableAction(),"v@")
objc_registerClassPair_(subClass)
subClass = objc_allocateClassPair_(objc_getClass_("NSScriptCommand"),"asToggleAction",0)
class_addMethod_(subClass,sel_registerName_("performDefaultImplementation"),@asToggleAction(),"v@")
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