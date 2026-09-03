object FrmAbout: TFrmAbout
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'About TDump Explorer'
  ClientHeight = 452
  ClientWidth = 490
  Color = clWindow
  CustomTitleBar.Control = TitleBarPanel1
  CustomTitleBar.Enabled = True
  CustomTitleBar.Height = 2
  CustomTitleBar.SystemHeight = False
  CustomTitleBar.ShowCaption = False
  CustomTitleBar.ShowIcon = False
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
  GlassFrame.Top = 2
  Position = poOwnerFormCenter
  RoundedCorners = rcOn
  StyleElements = [seFont, seClient]
  TextHeight = 15
  object TitleBarPanel1: TTitleBarPanel
    Left = 0
    Top = 0
    Width = 490
    Height = 1
    CustomButtons = <>
    ExplicitWidth = 576
  end
  object pnContent: TPanel
    Left = 0
    Top = 1
    Width = 490
    Height = 393
    Align = alClient
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 1
    StyleElements = [seFont, seBorder]
    ExplicitWidth = 576
    ExplicitHeight = 421
    object lblProduct: TLabel
      Left = 100
      Top = 24
      Width = 310
      Height = 30
      AutoSize = False
      Caption = 'TDump Explorer'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -22
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblDescription: TLabel
      Tag = 1
      Left = 100
      Top = 60
      Width = 304
      Height = 36
      AutoSize = False
      Caption = 
        'Binary and TDUMP report explorer'#13#10'for Delphi, C++ Builder, PE an' +
        'd package analysis.'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      WordWrap = True
    end
    object lblVersionTitle: TLabel
      Tag = 1
      Left = 32
      Top = 112
      Width = 38
      Height = 15
      Caption = 'Version'
    end
    object lblVersion: TLabel
      Left = 32
      Top = 131
      Width = 128
      Height = 22
      AutoSize = False
      Caption = 'Not available'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
    end
    object lblBuildTitle: TLabel
      Tag = 1
      Left = 174
      Top = 112
      Width = 27
      Height = 15
      Caption = 'Build'
    end
    object lblBuild: TLabel
      Left = 174
      Top = 131
      Width = 116
      Height = 22
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblArchitectureTitle: TLabel
      Tag = 1
      Left = 308
      Top = 112
      Width = 65
      Height = 15
      Caption = 'Architecture'
    end
    object lblArchitecture: TLabel
      Left = 308
      Top = 131
      Width = 136
      Height = 22
      AutoSize = False
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -15
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblAuthorTitle: TLabel
      Tag = 1
      Left = 60
      Top = 182
      Width = 124
      Height = 20
      AutoSize = False
      Caption = 'Author'
    end
    object lblAuthor: TLabel
      Left = 192
      Top = 182
      Width = 348
      Height = 20
      AutoSize = False
      Caption = 'Rodrigo Ruz'
    end
    object lblRepositoryTitle: TLabel
      Tag = 1
      Left = 60
      Top = 214
      Width = 124
      Height = 20
      AutoSize = False
      Caption = 'Website / Repository'
    end
    object lblLicenseTitle: TLabel
      Tag = 1
      Left = 60
      Top = 246
      Width = 124
      Height = 20
      AutoSize = False
      Caption = 'License'
    end
    object lblPhosphorTitle: TLabel
      Tag = 1
      Left = 60
      Top = 297
      Width = 124
      Height = 18
      AutoSize = False
      Caption = 'Phosphor Icons'
    end
    object lblVirtualTreeTitle: TLabel
      Tag = 1
      Left = 60
      Top = 333
      Width = 124
      Height = 18
      AutoSize = False
      Caption = 'Virtual Treeview'
    end
    object pbCard: TPaintBox
      Left = 0
      Top = 0
      Width = 490
      Height = 393
      Align = alClient
      OnPaint = CardPaint
      ExplicitTop = -6
      ExplicitWidth = 576
      ExplicitHeight = 421
    end
    object imgApplication: TVirtualImage
      Left = 24
      Top = 32
      Width = 64
      Height = 64
      ImageCollection = DataModule1.ImageCollection1
      ImageWidth = 0
      ImageHeight = 0
      ImageIndex = 109
      ImageName = 'TDumpExplorer_light'
    end
  end
  object pnFooter: TPanel
    Left = 0
    Top = 394
    Width = 490
    Height = 58
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    TabOrder = 2
    StyleElements = [seFont, seBorder]
    ExplicitTop = 422
    ExplicitWidth = 576
    object lblFeedback: TLabel
      Tag = 1
      Left = 22
      Top = 40
      Width = 532
      Height = 16
      AutoSize = False
    end
  end
end
