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
    Header.AutoSizeIndex = 0
    Header.Height = 15
    Header.MainColumn = -1
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
    object VirtualImage1: TVirtualImage
      AlignWithMargins = True
      Left = 8
      Top = 8
      Width = 32
      Height = 44
      Margins.Left = 8
      Margins.Top = 8
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alLeft
      ImageCollection = DataModule1.ImageCollection1
      ImageWidth = 0
      ImageHeight = 0
      ImageIndex = 36
      ImageName = 'file-dashed_dark'
      ExplicitTop = 3
      ExplicitHeight = 32
    end
    object pnDocument: TPanel
      AlignWithMargins = True
      Left = 48
      Top = 0
      Width = 584
      Height = 52
      Margins.Left = 8
      Margins.Top = 0
      Margins.Right = 8
      Margins.Bottom = 0
      Align = alClient
      BevelOuter = bvNone
      DoubleBuffered = False
      ParentBackground = False
      ParentDoubleBuffered = False
      TabOrder = 0
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
        ExplicitTop = 0
      end
      inherited SearchFilterBox: TSearchBox
        Left = 883
        Top = 2
        Height = 28
        Margins.Top = 2
        Margins.Bottom = 2
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
end
