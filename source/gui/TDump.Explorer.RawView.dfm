object RawViewFrame: TRawViewFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 240
  DoubleBuffered = True
  Padding.Left = 6
  Padding.Top = 6
  Padding.Right = 6
  Padding.Bottom = 6
  ParentBackground = False
  ParentDoubleBuffered = False
  TabOrder = 0
  DesignSize = (
    640
    240)
  object pbSurface: TPaintBox
    Left = 0
    Top = 0
    Width = 640
    Height = 240
    Anchors = [akLeft, akTop, akRight, akBottom]
    OnPaint = SurfacePaint
  end
  object pnToolbar: TPanel
    Left = 6
    Top = 6
    Width = 628
    Height = 36
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    OnResize = ToolbarResize
    ExplicitLeft = 9
    ExplicitTop = 9
    object Label1: TLabel
      AlignWithMargins = True
      Left = 2
      Top = 0
      Width = 133
      Height = 36
      Margins.Left = 2
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alLeft
      Caption = 'RAW Output (parsed)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      Layout = tlCenter
      ExplicitHeight = 17
    end
    object cbFollowSelection: TCheckBox
      AlignWithMargins = True
      Left = 293
      Top = 0
      Width = 135
      Height = 36
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 0
      Align = alRight
      Caption = 'Follow Selection'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
    object pnSearch: TPanel
      AlignWithMargins = True
      Left = 436
      Top = 4
      Width = 190
      Height = 28
      Margins.Left = 8
      Margins.Top = 4
      Margins.Right = 2
      Margins.Bottom = 4
      Align = alRight
      BevelOuter = bvNone
      ParentBackground = False
      TabOrder = 0
      object pbSearchBorder: TPaintBox
        Left = 0
        Top = 0
        Width = 190
        Height = 28
        Align = alClient
        OnMouseDown = SearchBorderMouseDown
        OnPaint = SearchBorderPaint
      end
      object SearchFilterBox: TSearchBox
        AlignWithMargins = True
        Left = 8
        Top = 5
        Width = 154
        Height = 18
        Margins.Left = 8
        Margins.Top = 5
        Margins.Right = 28
        Margins.Bottom = 5
        Align = alClient
        AutoSize = False
        BorderStyle = bsNone
        TabOrder = 0
        OnEnter = SearchFocusChanged
        OnExit = SearchFocusChanged
        ButtonWidth = 0
      end
    end
  end
end
