object DumpDocumentFrame: TDumpDocumentFrame
  Left = 0
  Top = 0
  Width = 1056
  Height = 655
  DoubleBuffered = True
  ParentBackground = False
  ParentDoubleBuffered = False
  TabOrder = 0
  object Splitter1: TSplitter
    Left = 297
    Top = 52
    Width = 4
    Height = 499
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitHeight = 476
  end
  object Splitter2: TSplitter
    Left = 0
    Top = 551
    Width = 1056
    Height = 4
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 231
    ExplicitWidth = 386
  end
  object Tree: TVirtualStringTree
    Left = 0
    Top = 52
    Width = 297
    Height = 499
    Align = alLeft
    BorderStyle = bsNone
    DragOperations = []
    Header.AutoSizeIndex = 0
    Header.Height = 15
    Header.MainColumn = -1
    Images = VirtualImageList1
    SelectionBlendFactor = 255
    StyleElements = [seClient, seBorder]
    TabOrder = 0
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <>
  end
  object pnCards: TPanel
    Left = 301
    Top = 52
    Width = 755
    Height = 499
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object pnProperties: TPanel
      Left = 0
      Top = 0
      Width = 755
      Height = 499
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 0
      object cpViews: TCardPanel
        Left = 0
        Top = 0
        Width = 755
        Height = 499
        Align = alClient
        BevelOuter = bvNone
        Caption = 'cpViews'
        TabOrder = 0
      end
    end
  end
  object pnTop: TPanel
    Left = 0
    Top = 0
    Width = 1056
    Height = 52
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 3
    object PaintBox1: TPaintBox
      AlignWithMargins = True
      Left = 8
      Top = 8
      Width = 36
      Height = 44
      Margins.Left = 8
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alLeft
      OnPaint = PaintBox1Paint
      ExplicitLeft = 0
    end
    object pnDocument: TPanel
      AlignWithMargins = True
      Left = 48
      Top = 0
      Width = 584
      Height = 52
      Margins.Left = 4
      Margins.Top = 0
      Margins.Right = 8
      Margins.Bottom = 0
      Align = alClient
      BevelOuter = bvNone
      DoubleBuffered = False
      ParentBackground = False
      ParentDoubleBuffered = False
      TabOrder = 0
      ExplicitLeft = 58
      ExplicitWidth = 574
      object lblDocumentName: TLabel
        Left = 0
        Top = 0
        Width = 584
        Height = 27
        Margins.Left = 0
        Margins.Top = 4
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alClient
        AutoSize = False
        Caption = 'Document'
        Layout = tlBottom
        ExplicitLeft = 8
        ExplicitTop = -3
        ExplicitWidth = 377
      end
      object lblSourcePath: TLabel
        Left = 0
        Top = 27
        Width = 584
        Height = 25
        Align = alBottom
        AutoSize = False
        Caption = 'Source path'
        EllipsisPosition = epPathEllipsis
        ExplicitLeft = 5
        ExplicitTop = 30
        ExplicitWidth = 377
      end
    end
    object gpHeader: TGridPanel
      AlignWithMargins = True
      Left = 648
      Top = 0
      Width = 400
      Height = 52
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 8
      Margins.Bottom = 0
      Align = alRight
      BevelOuter = bvNone
      ColumnCollection = <
        item
          SizeStyle = ssAbsolute
          Value = 50.000000000000000000
        end
        item
          SizeStyle = ssAbsolute
          Value = 100.000000000000000000
        end
        item
          SizeStyle = ssAbsolute
          Value = 150.000000000000000000
        end
        item
          SizeStyle = ssAbsolute
          Value = 100.000000000000000000
        end>
      ControlCollection = <
        item
          Column = 0
          Control = lblFormatCaption
          Row = 0
        end
        item
          Column = 0
          Control = lblFormatValue
          Row = 1
        end
        item
          Column = 1
          Control = lblArchitectureCaption
          Row = 0
        end
        item
          Column = 2
          Control = lblTimestampCaption
          Row = 0
        end
        item
          Column = 3
          Control = lblSizeCaption
          Row = 0
        end
        item
          Column = 1
          Control = lblArchitectureValue
          Row = 1
        end
        item
          Column = 2
          Control = lblTimestampValue
          Row = 1
        end
        item
          Column = 3
          Control = lblSizeValue
          Row = 1
        end>
      ParentBackground = False
      RowCollection = <
        item
          Value = 50.000000000000000000
        end
        item
          Value = 50.000000000000000000
        end>
      TabOrder = 1
      object lblFormatCaption: TLabel
        Left = 0
        Top = 0
        Width = 50
        Height = 26
        Align = alClient
        AutoSize = False
        Caption = 'Format'
        Layout = tlBottom
        ExplicitLeft = -3
        ExplicitTop = -3
        ExplicitWidth = 152
      end
      object lblFormatValue: TLabel
        AlignWithMargins = True
        Left = 0
        Top = 28
        Width = 50
        Height = 24
        Margins.Left = 0
        Margins.Top = 2
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alClient
        AutoSize = False
        Caption = ' '
        ExplicitLeft = -3
        ExplicitTop = 25
        ExplicitWidth = 152
      end
      object lblArchitectureCaption: TLabel
        Left = 50
        Top = 0
        Width = 100
        Height = 26
        Align = alClient
        AutoSize = False
        Caption = 'Architecture'
        Layout = tlBottom
        ExplicitLeft = 539
        ExplicitTop = 62
        ExplicitWidth = 153
        ExplicitHeight = 18
      end
      object lblTimestampCaption: TLabel
        Left = 150
        Top = 0
        Width = 150
        Height = 26
        Align = alClient
        AutoSize = False
        Caption = 'Time Date Stamp'
        Layout = tlBottom
        ExplicitLeft = 301
        ExplicitTop = -3
        ExplicitWidth = 151
        ExplicitHeight = 32
      end
      object lblSizeCaption: TLabel
        Left = 300
        Top = 0
        Width = 100
        Height = 26
        Align = alClient
        AutoSize = False
        Caption = 'Size'
        Layout = tlBottom
        ExplicitLeft = 458
        ExplicitTop = -3
        ExplicitWidth = 152
      end
      object lblArchitectureValue: TLabel
        AlignWithMargins = True
        Left = 50
        Top = 28
        Width = 100
        Height = 24
        Margins.Left = 0
        Margins.Top = 2
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alClient
        AutoSize = False
        Caption = ' '
        ExplicitLeft = 545
        ExplicitTop = 82
        ExplicitWidth = 153
        ExplicitHeight = 20
      end
      object lblTimestampValue: TLabel
        AlignWithMargins = True
        Left = 150
        Top = 28
        Width = 150
        Height = 24
        Margins.Left = 0
        Margins.Top = 2
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alClient
        AutoSize = False
        Caption = ' '
        ExplicitLeft = 698
        ExplicitTop = 82
        ExplicitWidth = 153
        ExplicitHeight = 20
      end
      object lblSizeValue: TLabel
        AlignWithMargins = True
        Left = 300
        Top = 28
        Width = 100
        Height = 24
        Margins.Left = 0
        Margins.Top = 2
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alClient
        AutoSize = False
        Caption = ' '
        ExplicitLeft = 600
        ExplicitTop = 34
        ExplicitWidth = 153
        ExplicitHeight = 20
      end
    end
  end
  inline frRawView: TRawViewFrame
    Left = 0
    Top = 555
    Width = 1056
    Height = 100
    Align = alBottom
    DoubleBuffered = True
    ParentBackground = False
    ParentDoubleBuffered = False
    TabOrder = 2
    ExplicitTop = 555
    ExplicitWidth = 1056
    ExplicitHeight = 100
    inherited pnToolbar: TPanel
      Width = 1056
      Height = 32
      StyleElements = [seFont, seBorder]
      ExplicitWidth = 1056
      ExplicitHeight = 32
      inherited Label1: TLabel
        AlignWithMargins = True
        Top = 0
        Height = 32
        Margins.Left = 8
        Margins.Top = 0
        Margins.Right = 8
        Margins.Bottom = 0
        Align = alLeft
        Layout = tlCenter
        StyleElements = [seFont, seClient, seBorder]
        ExplicitTop = 0
      end
      inherited lblFilterMatches: TLabel
        Left = 666
        Height = 32
        ExplicitLeft = 666
      end
      inherited SearchFilterBox: TSearchBox
        Left = 883
        Top = 2
        Height = 28
        Margins.Top = 2
        Margins.Bottom = 2
        StyleElements = [seFont, seClient, seBorder]
        ExplicitLeft = 883
        ExplicitTop = 2
      end
      inherited cbFollowSelection: TCheckBox
        Left = 736
        Height = 32
        ExplicitLeft = 736
        ExplicitHeight = 32
      end
    end
  end
  object VirtualImageList1: TVirtualImageList
    Images = <
      item
        CollectionIndex = 0
        CollectionName = 'archive_dark'
        Name = 'archive_dark'
      end
      item
        CollectionIndex = 1
        CollectionName = 'archive_light'
        Name = 'archive_light'
      end
      item
        CollectionIndex = 2
        CollectionName = 'arrow-square-down_dark'
        Name = 'arrow-square-down_dark'
      end
      item
        CollectionIndex = 3
        CollectionName = 'arrow-square-down_light'
        Name = 'arrow-square-down_light'
      end
      item
        CollectionIndex = 4
        CollectionName = 'arrow-square-left_dark'
        Name = 'arrow-square-left_dark'
      end
      item
        CollectionIndex = 5
        CollectionName = 'arrow-square-left_light'
        Name = 'arrow-square-left_light'
      end
      item
        CollectionIndex = 6
        CollectionName = 'arrow-square-right_dark'
        Name = 'arrow-square-right_dark'
      end
      item
        CollectionIndex = 7
        CollectionName = 'arrow-square-right_light'
        Name = 'arrow-square-right_light'
      end
      item
        CollectionIndex = 8
        CollectionName = 'arrow-square-up_dark'
        Name = 'arrow-square-up_dark'
      end
      item
        CollectionIndex = 9
        CollectionName = 'arrow-square-up_light'
        Name = 'arrow-square-up_light'
      end
      item
        CollectionIndex = 10
        CollectionName = 'binary_dark'
        Name = 'binary_dark'
      end
      item
        CollectionIndex = 11
        CollectionName = 'binary_light'
        Name = 'binary_light'
      end
      item
        CollectionIndex = 12
        CollectionName = 'binoculars_dark'
        Name = 'binoculars_dark'
      end
      item
        CollectionIndex = 13
        CollectionName = 'binoculars_light'
        Name = 'binoculars_light'
      end
      item
        CollectionIndex = 14
        CollectionName = 'box-arrow-down_dark'
        Name = 'box-arrow-down_dark'
      end
      item
        CollectionIndex = 15
        CollectionName = 'box-arrow-down_light'
        Name = 'box-arrow-down_light'
      end
      item
        CollectionIndex = 16
        CollectionName = 'cards_dark'
        Name = 'cards_dark'
      end
      item
        CollectionIndex = 17
        CollectionName = 'cards_light'
        Name = 'cards_light'
      end
      item
        CollectionIndex = 18
        CollectionName = 'cpu_dark'
        Name = 'cpu_dark'
      end
      item
        CollectionIndex = 19
        CollectionName = 'cpu_light'
        Name = 'cpu_light'
      end
      item
        CollectionIndex = 20
        CollectionName = 'cube_dark'
        Name = 'cube_dark'
      end
      item
        CollectionIndex = 21
        CollectionName = 'cube_light'
        Name = 'cube_light'
      end
      item
        CollectionIndex = 22
        CollectionName = 'download_dark'
        Name = 'download_dark'
      end
      item
        CollectionIndex = 23
        CollectionName = 'download_light'
        Name = 'download_light'
      end
      item
        CollectionIndex = 24
        CollectionName = 'download-simple_dark'
        Name = 'download-simple_dark'
      end
      item
        CollectionIndex = 25
        CollectionName = 'download-simple_light'
        Name = 'download-simple_light'
      end
      item
        CollectionIndex = 26
        CollectionName = 'file_dark'
        Name = 'file_dark'
      end
      item
        CollectionIndex = 27
        CollectionName = 'file_light'
        Name = 'file_light'
      end
      item
        CollectionIndex = 28
        CollectionName = 'file-archive_dark'
        Name = 'file-archive_dark'
      end
      item
        CollectionIndex = 29
        CollectionName = 'file-archive_light'
        Name = 'file-archive_light'
      end
      item
        CollectionIndex = 30
        CollectionName = 'file-arrow-down_dark'
        Name = 'file-arrow-down_dark'
      end
      item
        CollectionIndex = 31
        CollectionName = 'file-arrow-down_light'
        Name = 'file-arrow-down_light'
      end
      item
        CollectionIndex = 32
        CollectionName = 'file-arrow-up_dark'
        Name = 'file-arrow-up_dark'
      end
      item
        CollectionIndex = 33
        CollectionName = 'file-arrow-up_light'
        Name = 'file-arrow-up_light'
      end
      item
        CollectionIndex = 34
        CollectionName = 'file-code_dark'
        Name = 'file-code_dark'
      end
      item
        CollectionIndex = 35
        CollectionName = 'file-code_light'
        Name = 'file-code_light'
      end
      item
        CollectionIndex = 36
        CollectionName = 'file-dashed_dark'
        Name = 'file-dashed_dark'
      end
      item
        CollectionIndex = 37
        CollectionName = 'file-dashed_light'
        Name = 'file-dashed_light'
      end
      item
        CollectionIndex = 38
        CollectionName = 'file-doc_dark'
        Name = 'file-doc_dark'
      end
      item
        CollectionIndex = 39
        CollectionName = 'file-doc_light'
        Name = 'file-doc_light'
      end
      item
        CollectionIndex = 40
        CollectionName = 'file-magnifying-glass_dark'
        Name = 'file-magnifying-glass_dark'
      end
      item
        CollectionIndex = 41
        CollectionName = 'file-magnifying-glass_light'
        Name = 'file-magnifying-glass_light'
      end
      item
        CollectionIndex = 42
        CollectionName = 'file-text_dark'
        Name = 'file-text_dark'
      end
      item
        CollectionIndex = 43
        CollectionName = 'file-text_light'
        Name = 'file-text_light'
      end
      item
        CollectionIndex = 44
        CollectionName = 'film-script_dark'
        Name = 'film-script_dark'
      end
      item
        CollectionIndex = 45
        CollectionName = 'film-script_light'
        Name = 'film-script_light'
      end
      item
        CollectionIndex = 46
        CollectionName = 'funnel_dark'
        Name = 'funnel_dark'
      end
      item
        CollectionIndex = 47
        CollectionName = 'funnel_light'
        Name = 'funnel_light'
      end
      item
        CollectionIndex = 48
        CollectionName = 'funnel-x_dark'
        Name = 'funnel-x_dark'
      end
      item
        CollectionIndex = 49
        CollectionName = 'funnel-x_light'
        Name = 'funnel-x_light'
      end
      item
        CollectionIndex = 50
        CollectionName = 'gear_dark'
        Name = 'gear_dark'
      end
      item
        CollectionIndex = 51
        CollectionName = 'gear_light'
        Name = 'gear_light'
      end
      item
        CollectionIndex = 52
        CollectionName = 'package_dark'
        Name = 'package_dark'
      end
      item
        CollectionIndex = 53
        CollectionName = 'package_light'
        Name = 'package_light'
      end
      item
        CollectionIndex = 54
        CollectionName = 'pulse_dark'
        Name = 'pulse_dark'
      end
      item
        CollectionIndex = 55
        CollectionName = 'pulse_light'
        Name = 'pulse_light'
      end
      item
        CollectionIndex = 56
        CollectionName = 'rectangle_dark'
        Name = 'rectangle_dark'
      end
      item
        CollectionIndex = 57
        CollectionName = 'rectangle_light'
        Name = 'rectangle_light'
      end
      item
        CollectionIndex = 58
        CollectionName = 'rectangle-dashed_dark'
        Name = 'rectangle-dashed_dark'
      end
      item
        CollectionIndex = 59
        CollectionName = 'rectangle-dashed_light'
        Name = 'rectangle-dashed_light'
      end
      item
        CollectionIndex = 60
        CollectionName = 'resize_dark'
        Name = 'resize_dark'
      end
      item
        CollectionIndex = 61
        CollectionName = 'resize_light'
        Name = 'resize_light'
      end
      item
        CollectionIndex = 62
        CollectionName = 'scan_dark'
        Name = 'scan_dark'
      end
      item
        CollectionIndex = 63
        CollectionName = 'scan_light'
        Name = 'scan_light'
      end
      item
        CollectionIndex = 64
        CollectionName = 'screwdriver_dark'
        Name = 'screwdriver_dark'
      end
      item
        CollectionIndex = 65
        CollectionName = 'screwdriver_light'
        Name = 'screwdriver_light'
      end
      item
        CollectionIndex = 66
        CollectionName = 'selection_dark'
        Name = 'selection_dark'
      end
      item
        CollectionIndex = 67
        CollectionName = 'selection_light'
        Name = 'selection_light'
      end
      item
        CollectionIndex = 68
        CollectionName = 'selection-all_dark'
        Name = 'selection-all_dark'
      end
      item
        CollectionIndex = 69
        CollectionName = 'selection-all_light'
        Name = 'selection-all_light'
      end
      item
        CollectionIndex = 70
        CollectionName = 'selection-background_dark'
        Name = 'selection-background_dark'
      end
      item
        CollectionIndex = 71
        CollectionName = 'selection-background_light'
        Name = 'selection-background_light'
      end
      item
        CollectionIndex = 72
        CollectionName = 'selection-foreground_dark'
        Name = 'selection-foreground_dark'
      end
      item
        CollectionIndex = 73
        CollectionName = 'selection-foreground_light'
        Name = 'selection-foreground_light'
      end
      item
        CollectionIndex = 74
        CollectionName = 'selection-inverse_dark'
        Name = 'selection-inverse_dark'
      end
      item
        CollectionIndex = 75
        CollectionName = 'selection-inverse_light'
        Name = 'selection-inverse_light'
      end
      item
        CollectionIndex = 76
        CollectionName = 'selection-plus_dark'
        Name = 'selection-plus_dark'
      end
      item
        CollectionIndex = 77
        CollectionName = 'selection-plus_light'
        Name = 'selection-plus_light'
      end
      item
        CollectionIndex = 78
        CollectionName = 'selection-slash_dark'
        Name = 'selection-slash_dark'
      end
      item
        CollectionIndex = 79
        CollectionName = 'selection-slash_light'
        Name = 'selection-slash_light'
      end
      item
        CollectionIndex = 80
        CollectionName = 'stack_dark'
        Name = 'stack_dark'
      end
      item
        CollectionIndex = 81
        CollectionName = 'stack_light'
        Name = 'stack_light'
      end
      item
        CollectionIndex = 82
        CollectionName = 'stack-minus_dark'
        Name = 'stack-minus_dark'
      end
      item
        CollectionIndex = 83
        CollectionName = 'stack-minus_light'
        Name = 'stack-minus_light'
      end
      item
        CollectionIndex = 84
        CollectionName = 'stack-plus_dark'
        Name = 'stack-plus_dark'
      end
      item
        CollectionIndex = 85
        CollectionName = 'stack-plus_light'
        Name = 'stack-plus_light'
      end
      item
        CollectionIndex = 86
        CollectionName = 'stack-simple_dark'
        Name = 'stack-simple_dark'
      end
      item
        CollectionIndex = 87
        CollectionName = 'stack-simple_light'
        Name = 'stack-simple_light'
      end
      item
        CollectionIndex = 88
        CollectionName = 'tray-arrow-down_dark'
        Name = 'tray-arrow-down_dark'
      end
      item
        CollectionIndex = 89
        CollectionName = 'tray-arrow-down_light'
        Name = 'tray-arrow-down_light'
      end
      item
        CollectionIndex = 90
        CollectionName = 'upload_dark'
        Name = 'upload_dark'
      end
      item
        CollectionIndex = 91
        CollectionName = 'upload_light'
        Name = 'upload_light'
      end
      item
        CollectionIndex = 92
        CollectionName = 'upload-simple_dark'
        Name = 'upload-simple_dark'
      end
      item
        CollectionIndex = 93
        CollectionName = 'upload-simple_light'
        Name = 'upload-simple_light'
      end
      item
        CollectionIndex = 94
        CollectionName = 'warning_dark'
        Name = 'warning_dark'
      end
      item
        CollectionIndex = 95
        CollectionName = 'warning_light'
        Name = 'warning_light'
      end
      item
        CollectionIndex = 96
        CollectionName = 'warning-octagon_dark'
        Name = 'warning-octagon_dark'
      end
      item
        CollectionIndex = 97
        CollectionName = 'warning-octagon_light'
        Name = 'warning-octagon_light'
      end>
    ImageCollection = DataModule1.ImageCollection1
    Left = 512
    Top = 312
  end
end
