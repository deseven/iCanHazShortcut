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
; IDE Options = PureBasic 5.42 LTS (MacOS X - x64)
; Folding = -
; EnableUnicode
; EnableXP