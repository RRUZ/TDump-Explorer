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
  Position = poScreenCenter
  StyleElements = [seFont]
  OnCreate = FormCreate
  TextHeight = 15
  object Splitter1: TSplitter
    Left = 0
    Top = 562
    Width = 1072
    Height = 12
    Cursor = crVSplit
    Align = alBottom
    ExplicitTop = 570
  end
  inline LogControl1: TLogControl
    AlignWithMargins = True
    Left = 6
    Top = 574
    Width = 1060
    Height = 127
    Margins.Left = 6
    Margins.Top = 0
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alBottom
    DoubleBuffered = True
    Padding.Left = 6
    Padding.Top = 6
    Padding.Right = 6
    Padding.Bottom = 6
    ParentBackground = False
    ParentDoubleBuffered = False
    TabOrder = 0
    ExplicitLeft = 6
    ExplicitTop = 574
    ExplicitWidth = 1060
    ExplicitHeight = 127
    inherited ControlList1: TControlList
      Width = 1048
      Height = 75
      ExplicitWidth = 1048
      ExplicitHeight = 75
    end
    inherited pnToolbar: TPanel
      Width = 1048
      StyleElements = [seFont, seClient, seBorder]
      ExplicitWidth = 1048
      inherited Label1: TLabel
        Height = 36
        StyleElements = [seFont, seClient, seBorder]
      end
      inherited pnSearch: TPanel
        Left = 856
        StyleElements = [seFont, seClient, seBorder]
        ExplicitLeft = 856
        inherited SearchFilterBox: TSearchBox
          StyleElements = [seFont, seClient, seBorder]
        end
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
    AlignWithMargins = True
    Left = 6
    Top = 45
    Width = 1060
    Height = 517
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 0
    Align = alClient
    BevelOuter = bvNone
    Caption = 'CardPanel1'
    ParentBackground = False
    TabOrder = 2
    StyleElements = [seFont, seBorder]
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
