object FrmSettings: TFrmSettings
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 598
  ClientWidth = 585
  Color = clWindow
  CustomTitleBar.Control = TitleBarPanel1
  CustomTitleBar.Enabled = True
  CustomTitleBar.Height = 38
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
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  GlassFrame.Enabled = True
  GlassFrame.Top = 38
  Position = poScreenCenter
  RoundedCorners = rcOn
  StyleElements = [seFont, seClient]
  OnShow = FormShow
  TextHeight = 15
  object pnContent: TPanel
    Left = 0
    Top = 37
    Width = 585
    Height = 561
    Align = alClient
    BevelOuter = bvNone
    Color = clWindow
    Padding.Left = 20
    Padding.Top = 14
    Padding.Right = 20
    Padding.Bottom = 14
    ParentBackground = False
    TabOrder = 0
    StyleElements = [seFont, seBorder]
    ExplicitHeight = 523
    object pnFooter: TPanel
      Left = 20
      Top = 459
      Width = 545
      Height = 88
      Align = alClient
      BevelOuter = bvNone
      Color = clWindow
      ParentBackground = False
      TabOrder = 3
      StyleElements = [seFont, seBorder]
      ExplicitHeight = 50
      DesignSize = (
        545
        88)
      object lblInformation: TLabel
        Left = 0
        Top = 6
        Width = 17
        Height = 28
        Caption = #9432
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -20
        Font.Name = 'Segoe UI Symbol'
        Font.Style = []
        ParentFont = False
      end
      object lblHint: TLabel
        Left = 34
        Top = 15
        Width = 263
        Height = 17
        Caption = 'Changes apply on next open where required.'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGrayText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object btnSave: TButton
        Left = 463
        Top = 13
        Width = 80
        Height = 25
        Anchors = [akTop, akRight]
        Caption = 'Save'
        Default = True
        ModalResult = 1
        TabOrder = 1
      end
      object btnCancel: TButton
        Left = 377
        Top = 13
        Width = 80
        Height = 25
        Anchors = [akTop, akRight]
        Cancel = True
        Caption = 'Cancel'
        ModalResult = 2
        TabOrder = 0
      end
    end
    object pnlWorkspace: TPanel
      AlignWithMargins = True
      Left = 20
      Top = 279
      Width = 545
      Height = 166
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 14
      Align = alTop
      BevelOuter = bvNone
      Color = clWindow
      ParentBackground = False
      TabOrder = 2
      StyleElements = [seFont, seBorder]
      object lblWorkspace: TLabel
        Left = 0
        Top = 18
        Width = 121
        Height = 17
        Caption = 'Panels / Workspace'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblShowLogPanel: TLabel
        Left = 0
        Top = 56
        Width = 84
        Height = 15
        Caption = 'Show Log panel'
      end
      object lblShowRawPanel: TLabel
        Left = 0
        Top = 91
        Width = 117
        Height = 15
        Caption = 'Show RAW View panel'
      end
      object lblFollowRawSelection: TLabel
        Left = 0
        Top = 126
        Width = 154
        Height = 15
        Caption = 'Follow selection in RAW View'
      end
      object swShowLogPanel: TToggleSwitch
        Left = 380
        Top = 40
        Width = 75
        Height = 24
        State = tssOn
        SwitchHeight = 24
        SwitchWidth = 52
        TabOrder = 0
        ThumbWidth = 20
      end
      object swShowRawPanel: TToggleSwitch
        Left = 380
        Top = 75
        Width = 75
        Height = 24
        State = tssOn
        SwitchHeight = 24
        SwitchWidth = 52
        TabOrder = 1
        ThumbWidth = 20
      end
      object swFollowRawSelection: TToggleSwitch
        Left = 380
        Top = 110
        Width = 75
        Height = 24
        State = tssOn
        SwitchHeight = 24
        SwitchWidth = 52
        TabOrder = 2
        ThumbWidth = 20
      end
    end
    object pnlAppearance: TPanel
      AlignWithMargins = True
      Left = 20
      Top = 159
      Width = 545
      Height = 106
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 14
      Align = alTop
      BevelOuter = bvNone
      Color = clWindow
      ParentBackground = False
      TabOrder = 1
      StyleElements = [seFont, seBorder]
      object lblAppearance: TLabel
        Left = 0
        Top = 0
        Width = 545
        Height = 17
        Align = alTop
        Caption = 'Appearance'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        ExplicitWidth = 72
      end
      object lblPreferredTheme: TLabel
        Left = 0
        Top = 17
        Width = 545
        Height = 15
        Align = alTop
        Caption = 'Preferred theme'
        ExplicitWidth = 85
      end
      object ControlList1: TControlList
        Left = 0
        Top = 32
        Width = 545
        Height = 74
        Align = alClient
        BorderStyle = bsNone
        ItemCount = 5
        ItemWidth = 50
        ItemMargins.Left = 0
        ItemMargins.Top = 0
        ItemMargins.Right = 0
        ItemMargins.Bottom = 0
        ColumnLayout = cltMultiLeftToRight
        ParentColor = False
        TabOrder = 0
      end
    end
    object pnlGeneral: TPanel
      AlignWithMargins = True
      Left = 20
      Top = 14
      Width = 545
      Height = 131
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 14
      Align = alTop
      BevelOuter = bvNone
      Color = clWindow
      ParentBackground = False
      TabOrder = 0
      StyleElements = [seFont, seBorder]
      object lblGeneral: TLabel
        Left = 0
        Top = -3
        Width = 47
        Height = 17
        Caption = 'General'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblTDumpPath: TLabel
        Left = 0
        Top = 31
        Width = 127
        Height = 15
        Caption = 'TDUMP executable path'
      end
      object lblRecentItems: TLabel
        Left = 0
        Top = 86
        Width = 118
        Height = 15
        Caption = 'Recent files max items'
      end
      object edTDumpPath: TEdit
        Left = 0
        Top = 52
        Width = 441
        Height = 23
        TabOrder = 0
        Text = 'C:\Tools\RADStudio\bin\tdump.exe'
      end
      object btnBrowse: TButton
        Left = 447
        Top = 51
        Width = 87
        Height = 25
        Caption = 'Browse...'
        TabOrder = 1
      end
      object nbRecentItems: TNumberBox
        Left = 0
        Top = 106
        Width = 118
        Height = 23
        MinValue = 1.000000000000000000
        MaxValue = 100.000000000000000000
        TabOrder = 2
        Value = 10.000000000000000000
        SpinButtonOptions.ButtonWidth = 20
        SpinButtonOptions.Placement = nbspInline
      end
    end
  end
  object TitleBarPanel1: TTitleBarPanel
    Left = 0
    Top = 0
    Width = 585
    Height = 37
    CustomButtons = <>
  end
end
