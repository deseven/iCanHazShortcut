ImportC "/System/Library/Frameworks/Accelerate.framework/Accelerate"
  vImageUnpremultiplyData_RGBA8888 (*src, *dest, flags) 
EndImport

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

Procedure.f getBackingScaleFactor()
  Define backingScaleFactor.CGFloat = 1.0
  If OSVersion() >= #PB_OS_MacOSX_10_7
    CocoaMessage(@backingScaleFactor,CocoaMessage(0,0,"NSScreen mainScreen"),"backingScaleFactor")
  EndIf
  ProcedureReturn backingScaleFactor
EndProcedure

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
  ;LoadFont(#resFont,#wndFont,#wndFontSize)
  ;LoadFont(#resFontMono,#wndFontMono,#wndFontMonoSize)
  If LoadImageEx(#resLogo,GetPathPart(ProgramFilename()) + "../Resources/main.icns")
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
    Else
      ResizeImage(#resLogo,64,64,#PB_Image_Smooth)
      ResizeImage(#resIcon,18,18,#PB_Image_Smooth)
    EndIf
    CocoaMessage(0,ImageID(#resIcon),"setTemplate:",#True)
  Else
    Debug "failed to load image"
  EndIf
EndProcedure

Procedure menuActions()
  Shared application.i
  Select EventMenu()
    Case #menuAbout
      CocoaMessage(0,application,"activateIgnoringOtherApps:",#YES)
      SetGadgetState(#gadTabs,1)
      HideWindow(#wnd,#False)
    Case #menuPrefs
      CocoaMessage(0,application,"activateIgnoringOtherApps:",#YES)
      SetGadgetState(#gadTabs,0)
      HideWindow(#wnd,#False)
    Case #menuQuit
      die()
  EndSelect
EndProcedure

Procedure buildMenu()
  Shared statusBar.i,statusItem.i
  Protected itemLength.CGFloat = 32
  If Not (statusBar And statusItem)
    StatusBar.i = CocoaMessage(0,0,"NSStatusBar systemStatusBar")
    StatusItem.i = CocoaMessage(0,CocoaMessage(0,StatusBar,"statusItemWithLength:",#NSSquareStatusBarItemLength),"retain")
  EndIf
  If IsMenu(#menu) : FreeMenu(#menu) : EndIf
  CreatePopupMenu(#menu)
  MenuItem(#menuPrefs,"Preferences...")
  BindMenuEvent(#menu,#menuPrefs,@menuActions())
  MenuItem(#menuAbout,"About")
  BindMenuEvent(#menu,#menuAbout,@menuActions())
  MenuBar()
  MenuItem(#menuQuit,"Quit")
  BindMenuEvent(#menu,#menuQuit,@menuActions())
  CocoaMessage(0,StatusItem,"setHighlightMode:",@"YES")
  CocoaMessage(0,StatusItem,"setLength:@",@itemLength)
  CocoaMessage(0,StatusItem,"setImage:",ImageID(#resIcon))
  CocoaMessage(0,StatusItem,"setMenu:",CocoaMessage(0,MenuID(#menu),"firstObject"))
EndProcedure
; IDE Options = PureBasic 5.42 LTS (MacOS X - x64)
; Folding = --
; EnableUnicode
; EnableXP