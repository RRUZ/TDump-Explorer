object FrmSettings: TFrmSettings
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 551
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
    Height = 514
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
    object pnFooter: TPanel
      Left = 20
      Top = 450
      Width = 545
      Height = 50
      Align = alBottom
      BevelOuter = bvNone
      Color = clWindow
      ParentBackground = False
      TabOrder = 3
      StyleElements = [seFont, seBorder]
      DesignSize = (
        545
        50)
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
        Top = 3
        Width = 72
        Height = 17
        Caption = 'Appearance'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblPreferredTheme: TLabel
        Left = 0
        Top = 26
        Width = 85
        Height = 15
        Caption = 'Preferred theme'
      end
      object pnlSystemTheme: TPanel
        AlignWithMargins = True
        Left = 0
        Top = 50
        Width = 160
        Height = 56
        Margins.Left = 0
        Margins.Top = 50
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alLeft
        BevelOuter = bvNone
        Color = clWindow
        ParentBackground = False
        TabOrder = 0
        StyleElements = [seFont, seBorder]
        ExplicitLeft = 2
        object imgSystemTheme: TVirtualImage
          AlignWithMargins = True
          Left = 0
          Top = 30
          Width = 30
          Height = 26
          Margins.Left = 0
          Margins.Top = 30
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alLeft
          ImageCollection = DataModule1.ImageCollection1
          ImageWidth = 24
          ImageHeight = 24
          ImageIndex = 18
          ImageName = 'cpu_dark'
          ExplicitTop = 24
        end
        object lblSystemTheme: TLabel
          Left = 45
          Top = 30
          Width = 38
          Height = 15
          Caption = 'System'
        end
        object rbSystemTheme: TRadioButton
          AlignWithMargins = True
          Left = 140
          Top = 20
          Width = 20
          Height = 36
          Margins.Left = 0
          Margins.Top = 20
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alRight
          TabOrder = 0
        end
      end
      object pnlLightTheme: TPanel
        AlignWithMargins = True
        Left = 160
        Top = 50
        Width = 160
        Height = 56
        Margins.Left = 0
        Margins.Top = 50
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alLeft
        BevelOuter = bvNone
        Color = clWindow
        ParentBackground = False
        TabOrder = 1
        StyleElements = [seFont, seBorder]
        object imgLightTheme: TVirtualImage
          AlignWithMargins = True
          Left = 0
          Top = 30
          Width = 30
          Height = 26
          Margins.Left = 0
          Margins.Top = 30
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alLeft
          ImageCollection = DataModule1.ImageCollection1
          ImageWidth = 24
          ImageHeight = 24
          ImageIndex = 100
          ImageName = 'sun_dark'
          ExplicitLeft = 14
          ExplicitTop = 24
          ExplicitHeight = 30
        end
        object lblLightTheme: TLabel
          Left = 82
          Top = 30
          Width = 27
          Height = 15
          Caption = 'Light'
        end
        object rbLightTheme: TRadioButton
          AlignWithMargins = True
          Left = 140
          Top = 20
          Width = 20
          Height = 36
          Margins.Left = 0
          Margins.Top = 20
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alRight
          Checked = True
          TabOrder = 0
          TabStop = True
        end
      end
      object pnlDarkTheme: TPanel
        AlignWithMargins = True
        Left = 320
        Top = 50
        Width = 160
        Height = 56
        Margins.Left = 0
        Margins.Top = 50
        Margins.Right = 0
        Margins.Bottom = 0
        Align = alLeft
        BevelOuter = bvNone
        Color = clWindow
        ParentBackground = False
        TabOrder = 2
        StyleElements = [seFont, seBorder]
        object imgDarkTheme: TVirtualImage
          AlignWithMargins = True
          Left = 0
          Top = 30
          Width = 30
          Height = 26
          Margins.Left = 0
          Margins.Top = 30
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alLeft
          ImageCollection = DataModule1.ImageCollection1
          ImageWidth = 24
          ImageHeight = 24
          ImageIndex = 98
          ImageName = 'moon_dark'
          ExplicitLeft = 30
          ExplicitTop = 24
          ExplicitHeight = 30
        end
        object lblDarkTheme: TLabel
          Left = 82
          Top = 30
          Width = 24
          Height = 15
          Caption = 'Dark'
        end
        object rbDarkTheme: TRadioButton
          AlignWithMargins = True
          Left = 140
          Top = 20
          Width = 20
          Height = 36
          Margins.Left = 0
          Margins.Top = 20
          Margins.Right = 0
          Margins.Bottom = 0
          Align = alRight
          TabOrder = 0
        end
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
    ExplicitTop = -6
  end
end
