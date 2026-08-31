object FrmMain: TFrmMain
  Left = 0
  Top = 0
  Caption = 'TDump Explorer'
  ClientHeight = 711
  ClientWidth = 1072
  Color = clBtnFace
  CustomTitleBar.Control = TitleBarPanel1
  CustomTitleBar.Enabled = True
  CustomTitleBar.Height = 40
  CustomTitleBar.SystemHeight = False
  CustomTitleBar.SystemColors = False
  CustomTitleBar.BackgroundColor = clWhite
  CustomTitleBar.ForegroundColor = 65793
  CustomTitleBar.InactiveBackgroundColor = clWhite
  CustomTitleBar.InactiveForegroundColor = 10066329
  CustomTitleBar.ButtonForegroundColor = 65793
  CustomTitleBar.ButtonBackgroundColor = clWhite
  CustomTitleBar.ButtonHoverForegroundColor = 65793
  CustomTitleBar.ButtonHoverBackgroundColor = 16053492
  CustomTitleBar.ButtonPressedForegroundColor = 65793
  CustomTitleBar.ButtonPressedBackgroundColor = 15395562
  CustomTitleBar.ButtonInactiveForegroundColor = 10066329
  CustomTitleBar.ButtonInactiveBackgroundColor = clWhite
  Constraints.MinHeight = 600
  Constraints.MinWidth = 950
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  GlassFrame.Enabled = True
  GlassFrame.Top = 40
  Position = poDesktopCenter
  StyleElements = [seFont, seClient]
  OnShow = FormShow
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 0
    Top = 572
    Width = 1072
    Height = 4
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 581
  end
  inline LogControl1: TLogControl
    AlignWithMargins = True
    Left = 4
    Top = 576
    Width = 1064
    Height = 127
    Margins.Left = 4
    Margins.Top = 0
    Margins.Right = 4
    Margins.Bottom = 4
    Align = alBottom
    TabOrder = 0
    ExplicitLeft = 4
    ExplicitTop = 576
    ExplicitWidth = 1064
    ExplicitHeight = 127
    inherited ControlList1: TControlList
      Width = 1064
      Height = 95
      ExplicitWidth = 1064
      ExplicitHeight = 95
    end
    inherited pnToolbar: TPanel
      Width = 1064
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 1064
      inherited Label1: TLabel
        Height = 32
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited SearchFilterBox: TSearchBox
        Left = 891
        Height = 24
        StyleElements = [seFont, seClient, seBorder]
        ExplicitLeft = 891
      end
    end
  end
  object TitleBarPanel1: TTitleBarPanel
    Left = 0
    Top = 0
    Width = 1072
    Height = 39
    CustomButtons = <>
  end
  object CardPanel1: TCardPanel
    Left = 0
    Top = 39
    Width = 1072
    Height = 533
    Align = alClient
    BevelOuter = bvNone
    Caption = 'CardPanel1'
    ParentBackground = False
    TabOrder = 2
  end
  object ProgressBar1: TProgressBar
    Left = 0
    Top = 707
    Width = 1072
    Height = 4
    Align = alBottom
    TabOrder = 3
    Visible = False
  end
  object ApplicationEvents1: TApplicationEvents
    OnIdle = ApplicationEvents1Idle
    Left = 528
    Top = 344
  end
end
