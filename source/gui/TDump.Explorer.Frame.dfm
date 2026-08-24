object Frame1: TFrame1
  Left = 0
  Top = 0
  Width = 640
  Height = 480
  TabOrder = 0
  object Splitter1: TSplitter
    Left = 250
    Top = 0
    Width = 4
    Height = 476
    ExplicitLeft = 0
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
    Top = 0
    Width = 250
    Height = 476
    Align = alLeft
    Header.AutoSizeIndex = 0
    Header.Height = 15
    Header.MainColumn = -1
    TabOrder = 1
    Touch.InteractiveGestures = [igPan, igPressAndTap]
    Touch.InteractiveGestureOptions = [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough]
    ExplicitLeft = -116
    ExplicitTop = -6
    Columns = <>
  end
  object Panel1: TPanel
    Left = 254
    Top = 0
    Width = 386
    Height = 476
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    ExplicitLeft = 250
    ExplicitWidth = 390
    object CardPanel1: TCardPanel
      Left = 0
      Top = 0
      Width = 386
      Height = 476
      Align = alClient
      ActiveCard = Card1
      Caption = 'CardPanel1'
      TabOrder = 0
      ExplicitLeft = 4
      object Card1: TCard
        Left = 1
        Top = 1
        Width = 384
        Height = 474
        Caption = 'Card1'
        CardIndex = 0
        TabOrder = 0
        inline HighlighterControl1: THighlighterControl
          Left = 0
          Top = 0
          Width = 384
          Height = 474
          Align = alClient
          TabOrder = 0
          ExplicitWidth = 384
          ExplicitHeight = 474
          inherited ControlList1: TControlList
            Width = 384
            Height = 474
            ExplicitTop = 0
            ExplicitWidth = 384
            ExplicitHeight = 474
          end
        end
      end
    end
  end
end
