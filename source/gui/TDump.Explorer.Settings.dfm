object FrmSettings: TFrmSettings
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 448
  ClientWidth = 585
  Color = clWindow
  CustomTitleBar.Control = TitleBarPanel1
  CustomTitleBar.Enabled = True
  CustomTitleBar.Height = 30
  CustomTitleBar.SystemHeight = False
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
  GlassFrame.Top = 30
  Position = poOwnerFormCenter
  RoundedCorners = rcOn
  StyleElements = [seFont, seClient]
  OnShow = FormShow
  TextHeight = 15
  object pnContent: TPanel
    Left = 0
    Top = 29
    Width = 585
    Height = 361
    Align = alClient
    BevelOuter = bvNone
    Color = clWindow
    Padding.Left = 26
    Padding.Top = 20
    Padding.Right = 26
    Padding.Bottom = 20
    ParentBackground = False
    TabOrder = 0
    StyleElements = [seFont, seBorder]
    DesignSize = (
      585
      361)
    object pbCard: TPaintBox
      Left = 0
      Top = 0
      Width = 585
      Height = 360
      Anchors = [akLeft, akTop, akRight, akBottom]
      OnPaint = CardPaint
      ExplicitHeight = 322
    end
    object pnlWorkspace: TPanel
      AlignWithMargins = True
      Left = 26
      Top = 371
      Width = 533
      Height = 2
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 14
      Align = alTop
      BevelOuter = bvNone
      Color = clWindow
      ParentBackground = False
      TabOrder = 2
      Visible = False
      StyleElements = [seFont, seBorder]
      ExplicitTop = 306
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
      Left = 26
      Top = 245
      Width = 533
      Height = 112
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 14
      Align = alTop
      BevelOuter = bvNone
      Color = clWindow
      Constraints.MaxHeight = 112
      Constraints.MinHeight = 112
      ParentBackground = False
      TabOrder = 1
      StyleElements = [seFont, seBorder]
      ExplicitTop = 180
      object lblAppearance: TLabel
        Left = 0
        Top = 0
        Width = 533
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
        Width = 533
        Height = 15
        Align = alTop
        Caption = 'Preferred theme'
        ExplicitWidth = 85
      end
      object ControlList1: TControlList
        AlignWithMargins = True
        Left = 8
        Top = 40
        Width = 517
        Height = 64
        Margins.Left = 8
        Margins.Top = 8
        Margins.Right = 8
        Margins.Bottom = 8
        Align = alClient
        BorderStyle = bsNone
        ItemCount = 3
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
      Left = 26
      Top = 20
      Width = 533
      Height = 205
      Margins.Left = 0
      Margins.Top = 0
      Margins.Right = 0
      Margins.Bottom = 20
      Align = alTop
      BevelOuter = bvNone
      Color = clWindow
      ParentBackground = False
      TabOrder = 0
      StyleElements = [seFont, seBorder]
      DesignSize = (
        533
        205)
      object pbInputBorders: TPaintBox
        Left = 0
        Top = 0
        Width = 533
        Height = 205
        Anchors = [akLeft, akTop, akRight, akBottom]
        OnMouseDown = InputBordersMouseDown
        OnPaint = InputBordersPaint
        ExplicitHeight = 140
      end
      object lblGeneral: TLabel
        Left = 0
        Top = 0
        Width = 533
        Height = 17
        Align = alTop
        Caption = 'General'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -13
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
        ExplicitWidth = 47
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
        Left = 8
        Top = 56
        Width = 422
        Height = 18
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        BevelInner = bvNone
        BevelOuter = bvNone
        BorderStyle = bsNone
        TabOrder = 0
        Text = 'C:\Tools\RADStudio\bin\tdump.exe'
        OnEnter = InputFocusChanged
        OnExit = InputFocusChanged
      end
      object nbRecentItems: TNumberBox
        Left = 8
        Top = 111
        Width = 118
        Height = 18
        AutoSize = False
        BorderStyle = bsNone
        MinValue = 1.000000000000000000
        MaxValue = 100.000000000000000000
        TabOrder = 1
        Value = 10.000000000000000000
        SpinButtonOptions.ButtonWidth = 20
        SpinButtonOptions.Placement = nbspInline
        OnEnter = InputFocusChanged
        OnExit = InputFocusChanged
      end
      object cbRememberWindowPlacement: TCheckBox
        Left = 0
        Top = 152
        Width = 245
        Height = 17
        Caption = 'Remember window size and position'
        TabOrder = 2
      end
      object cbRestorePreviousSession: TCheckBox
        Left = 0
        Top = 175
        Width = 245
        Height = 17
        Caption = 'Restore tabs from previous session'
        TabOrder = 3
      end
    end
  end
  object TitleBarPanel1: TTitleBarPanel
    Left = 0
    Top = 0
    Width = 585
    Height = 29
    CustomButtons = <>
  end
  object pnFooter: TPanel
    Left = 0
    Top = 390
    Width = 585
    Height = 58
    Align = alBottom
    BevelOuter = bvNone
    Color = clWindow
    ParentBackground = False
    TabOrder = 2
    StyleElements = [seFont, seBorder]
    object lblInformation: TLabel
      Left = 26
      Top = 10
      Width = 16
      Height = 25
      Caption = #9432
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -18
      Font.Name = 'Segoe UI Symbol'
      Font.Style = []
      ParentFont = False
    end
    object lblHint: TLabel
      Left = 49
      Top = 17
      Width = 236
      Height = 15
      Caption = 'Changes apply on next open where required.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clGrayText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
  end
end
