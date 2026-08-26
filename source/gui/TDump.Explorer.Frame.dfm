object DumpDocumentFrame: TDumpDocumentFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 480
  TabOrder = 0
  object Splitter1: TSplitter
    Left = 250
    Top = 41
    Width = 4
    Height = 331
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitHeight = 476
  end
  object Splitter2: TSplitter
    Left = 0
    Top = 372
    Width = 640
    Height = 4
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 231
    ExplicitWidth = 386
  end
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 476
    Width = 640
    Height = 4
    Align = alBottom
    TabOrder = 0
  end
  object Tree: TVirtualStringTree
    Left = 0
    Top = 41
    Width = 250
    Height = 331
    Align = alLeft
    DefaultNodeHeight = 17
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Segoe UI'
    Font.Style = []
    Header.AutoSizeIndex = 0
    Header.Height = 13
    Header.MainColumn = -1
    ParentFont = False
    SelectionBlendFactor = 255
    StyleElements = [seClient, seBorder]
    TabOrder = 1
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    Columns = <>
  end
  object pnCards: TPanel
    Left = 254
    Top = 41
    Width = 386
    Height = 331
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    object pnProperties: TPanel
      Left = 0
      Top = 0
      Width = 386
      Height = 331
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 0
      object cpViews: TCardPanel
        Left = 0
        Top = 0
        Width = 386
        Height = 331
        Align = alClient
        BevelOuter = bvNone
        Caption = 'cpViews'
        TabOrder = 0
      end
    end
    inline frCrossReferences: TCrossReferencesFrame
      Left = 0
      Top = 0
      Width = 386
      Height = 331
      Align = alClient
      TabOrder = 1
      Visible = False
      ExplicitWidth = 386
      ExplicitHeight = 331
      inherited Splitter1: TSplitter
        Top = 0
        Width = 386
        ExplicitTop = 0
        ExplicitWidth = 386
      end
    end
  end
  object pnTop: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    ExplicitTop = -6
    object VirtualImage1: TVirtualImage
      Left = 8
      Top = 3
      Width = 32
      Height = 32
      ImageCollection = DataModule1.ImageCollection1
      ImageWidth = 0
      ImageHeight = 0
      ImageIndex = 40
      ImageName = 'file-magnifying-glass_dark'
    end
    object tcViews: TTabControl
      Left = 443
      Top = -6
      Width = 246
      Height = 41
      TabOrder = 0
      Tabs.Strings = (
        'Properties View'
        'Cross References')
      TabIndex = 0
      Visible = False
    end
  end
  inline frRawView: TRawViewFrame
    Left = 0
    Top = 376
    Width = 640
    Height = 100
    Align = alBottom
    TabOrder = 4
    ExplicitTop = 376
    ExplicitHeight = 100
    inherited pnToolbar: TPanel
      inherited SearchFilterBox: TSearchBox
        Height = 25
      end
    end
  end
end
