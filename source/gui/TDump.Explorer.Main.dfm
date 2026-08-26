object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'TDump Explorer'
  ClientHeight = 519
  ClientWidth = 690
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poDesktopCenter
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 0
    Top = 385
    Width = 690
    Height = 3
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 0
    ExplicitWidth = 316
  end
  object PageControl1: TPageControl
    AlignWithMargins = True
    Left = 4
    Top = 4
    Width = 682
    Height = 377
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alClient
    TabHeight = 28
    TabOrder = 0
    ExplicitWidth = 680
    ExplicitHeight = 369
  end
  inline LogControl1: TLogControl
    AlignWithMargins = True
    Left = 4
    Top = 392
    Width = 682
    Height = 127
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 0
    Align = alBottom
    TabOrder = 1
    ExplicitLeft = 4
    ExplicitTop = 384
    ExplicitWidth = 680
    ExplicitHeight = 127
    inherited ControlList1: TControlList
      Width = 682
      Height = 86
      ExplicitWidth = 680
      ExplicitHeight = 86
    end
    inherited pnToolbar: TPanel
      Width = 682
      ExplicitWidth = 680
      inherited SearchFilterBox: TSearchBox
        Left = 509
        Height = 25
        ExplicitLeft = 507
      end
    end
  end
end
