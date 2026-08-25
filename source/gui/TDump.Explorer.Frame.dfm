object Frame1: TFrame1
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
    Header.AutoSizeIndex = 0
    Header.Height = 15
    Header.MainColumn = -1
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
    Visible = False
    object tcViews: TTabControl
      Left = 0
      Top = 0
      Width = 640
      Height = 41
      Align = alClient
      TabOrder = 0
      Tabs.Strings = (
        'Properties View'
        'Cross References')
      TabIndex = 0
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
