object RawViewFrame: TRawViewFrame
  Left = 0
  Top = 0
  Width = 640
  Height = 240
  ParentBackground = False
  TabOrder = 0
  object pnToolbar: TPanel
    Left = 0
    Top = 0
    Width = 640
    Height = 41
    Align = alTop
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 0
    object Label1: TLabel
      Left = 8
      Top = 9
      Width = 133
      Height = 17
      Caption = 'RAW Output (parsed)'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object SearchFilterBox: TSearchBox
      AlignWithMargins = True
      Left = 467
      Top = 8
      Width = 169
      Height = 25
      Margins.Left = 4
      Margins.Top = 8
      Margins.Right = 4
      Margins.Bottom = 8
      Align = alRight
      TabOrder = 0
      ExplicitHeight = 23
    end
    object cbFollowSelection: TCheckBox
      Left = 320
      Top = 0
      Width = 143
      Height = 41
      Align = alRight
      Caption = 'Follow Selection'
      Checked = True
      State = cbChecked
      TabOrder = 1
    end
  end
end
