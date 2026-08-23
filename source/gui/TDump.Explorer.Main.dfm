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
  object PageControl1: TPageControl
    AlignWithMargins = True
    Left = 4
    Top = 4
    Width = 682
    Height = 308
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alClient
    TabHeight = 28
    TabOrder = 0
    ExplicitHeight = 333
  end
  inline LogControl1: TLogControl
    AlignWithMargins = True
    Left = 4
    Top = 320
    Width = 682
    Height = 199
    Margins.Left = 4
    Margins.Top = 4
    Margins.Right = 4
    Margins.Bottom = 0
    Align = alBottom
    TabOrder = 1
    ExplicitLeft = 4
    ExplicitTop = 320
    ExplicitWidth = 682
    ExplicitHeight = 199
    inherited ControlList1: TControlList
      Width = 682
      Height = 158
      ExplicitWidth = 680
      ExplicitHeight = 70
    end
    inherited Panel1: TPanel
      Width = 682
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 680
    end
  end
end
