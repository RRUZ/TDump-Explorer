//**************************************************************************************************
//
// Unit TDump.Explorer.Settings
//
// Settings dialog presentation
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.Settings;

interface

uses
  Winapi.Messages,
  System.Classes,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.NumberBox,
  Vcl.StdCtrls,
  Vcl.VirtualImage,
  Vcl.VirtualImageList,
  Vcl.WinXCtrls,
  Vcl.TitleBarCtrls,
  TDump.Explorer.GlassTabs;

type
  TFrmSettings = class(TForm)
    TitleBarPanel1: TTitleBarPanel;
    pnContent: TPanel;
    pnFooter: TPanel;
    lblHint: TLabel;
    lblInformation: TLabel;
    btnCancel: TButton;
    btnSave: TButton;
    pnlGeneral: TPanel;
    lblGeneral: TLabel;
    lblTDumpPath: TLabel;
    edTDumpPath: TEdit;
    btnBrowse: TButton;
    lblRecentItems: TLabel;
    nbRecentItems: TNumberBox;
    pnlAppearance: TPanel;
    lblAppearance: TLabel;
    lblPreferredTheme: TLabel;
    pnlSystemTheme: TPanel;
    pnlLightTheme: TPanel;
    pnlDarkTheme: TPanel;
    imgSystemTheme: TVirtualImage;
    imgLightTheme: TVirtualImage;
    imgDarkTheme: TVirtualImage;
    lblSystemTheme: TLabel;
    lblLightTheme: TLabel;
    lblDarkTheme: TLabel;
    rbSystemTheme: TRadioButton;
    rbLightTheme: TRadioButton;
    rbDarkTheme: TRadioButton;
    pnlWorkspace: TPanel;
    lblWorkspace: TLabel;
    lblShowLogPanel: TLabel;
    lblShowRawPanel: TLabel;
    lblFollowRawSelection: TLabel;
    swShowLogPanel: TToggleSwitch;
    swShowRawPanel: TToggleSwitch;
    swFollowRawSelection: TToggleSwitch;
    procedure FormShow(Sender: TObject);
  private
    FSettingsTabs: TGlassTabStrip;
    FSettingsTabImages: TVirtualImageList;

    procedure CreateSettingsTabs;
    procedure SettingsTabsBackgroundMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ApplyTheme;
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  Winapi.Windows, Vcl.GraphUtil, TDump.Explorer.Resources, TDump.Explorer.UI;

{$R *.dfm}

const
  CSettingsTitleBarButtonMargin = 50;
  CSettingsTitleBarHeight = 40;
  CSettingsTabHeight = 38;
  CSettingsTabBorderBlend = 0.82;
  CSettingsTabInactiveTopBlend = 0.97;
  CSettingsTabHoverTopBlend = 0.82;
  CSettingsTabCloseHoverBlend = 0.72;

{ TFrmSettings }

procedure TFrmSettings.ApplyTheme;
  procedure ApplyLabel(ALabel: TLabel; AColor: TColor);
  begin
    ALabel.StyleName := 'Windows';
    ALabel.Font.Color := AColor;
  end;

  procedure ApplyToggle(AToggle: TToggleSwitch);
  begin
    AToggle.Color := TExplorerTheme.ActiveTheme.SelectionColor;
    AToggle.FrameColor := TExplorerTheme.ActiveTheme.SelectionColor;
    AToggle.ThumbColor := clWhite;
    AToggle.Font.Color := TExplorerTheme.ActiveTheme.TextColor;
  end;

var
  LTheme: TExplorerTheme;
  LIconSuffix: string;
  LTabPalette: TGlassTabPalette;
begin
  LTheme := TExplorerTheme.ActiveTheme;
  // Icon suffixes describe the surface they are intended for.  On a light
  // form use the visible light-UI glyphs, and vice versa.
  LIconSuffix := if IsLightThemeActive then 'light' else 'dark';

  Color := LTheme.BackgroundColor;
  pnContent.Color := LTheme.BackgroundColor;
  pnFooter.Color := LTheme.BackgroundColor;

  pnlGeneral.Color := LTheme.BackgroundColor;
  pnlAppearance.Color := LTheme.BackgroundColor;
  pnlWorkspace.Color := LTheme.BackgroundColor;
  pnlSystemTheme.Color := LTheme.BackgroundColor;
  pnlLightTheme.Color := LTheme.BackgroundColor;
  pnlDarkTheme.Color := LTheme.BackgroundColor;

  ApplyLabel(lblGeneral, LTheme.TextColor);
  ApplyLabel(lblTDumpPath, LTheme.TextColor);
  ApplyLabel(lblRecentItems, LTheme.TextColor);
  ApplyLabel(lblAppearance, LTheme.TextColor);
  ApplyLabel(lblPreferredTheme, LTheme.InactiveText);
  ApplyLabel(lblSystemTheme, LTheme.TextColor);
  ApplyLabel(lblLightTheme, LTheme.SelectionColor);
  ApplyLabel(lblDarkTheme, LTheme.TextColor);
  ApplyLabel(lblWorkspace, LTheme.TextColor);
  ApplyLabel(lblShowLogPanel, LTheme.TextColor);
  ApplyLabel(lblShowRawPanel, LTheme.TextColor);
  ApplyLabel(lblFollowRawSelection, LTheme.TextColor);
  ApplyLabel(lblInformation, LTheme.InactiveText);
  ApplyLabel(lblHint, LTheme.InactiveText);

  edTDumpPath.Color := LTheme.BackgroundColor;
  edTDumpPath.Font.Color := LTheme.TextColor;
  nbRecentItems.Color := LTheme.BackgroundColor;
  nbRecentItems.Font.Color := LTheme.TextColor;

  imgSystemTheme.ImageName := 'cpu_' + LIconSuffix;
  imgLightTheme.ImageName := 'sun_' + LIconSuffix;
  imgDarkTheme.ImageName := 'moon_' + LIconSuffix;

  if Assigned(FSettingsTabs) then
  begin
    LTabPalette.StripTop := LTheme.BackgroundColor;
    LTabPalette.StripBottom := LTheme.BackgroundColor;
    LTabPalette.StripBorder := ColorBlendRGB(LTheme.TextColor,
      LTheme.BackgroundColor, CSettingsTabBorderBlend);
    LTabPalette.BackgroundTopLine := LTheme.BackgroundColor;
    LTabPalette.TabTop := LTheme.BackgroundColor;
    LTabPalette.TabBottom := LTheme.BackgroundColor;
    LTabPalette.InactiveTop := ColorBlendRGB(LTheme.TextColor,
      LTheme.BackgroundColor, CSettingsTabInactiveTopBlend);
    LTabPalette.InactiveBottom := LTheme.BackgroundColor;
    LTabPalette.HoverTop := ColorBlendRGB(LTheme.SelectionColor,
      LTheme.BackgroundColor, CSettingsTabHoverTopBlend);
    LTabPalette.HoverBottom := LTheme.BackgroundColor;
    LTabPalette.Accent := LTheme.SelectionColor;
    LTabPalette.Text := LTheme.TextColor;
    LTabPalette.InactiveText := LTheme.InactiveText;
    LTabPalette.CloseHover := ColorBlendRGB(LTheme.SelectionColor,
      LTheme.BackgroundColor, CSettingsTabCloseHoverBlend);
    FSettingsTabs.Palette := LTabPalette;
    if FSettingsTabs.Items.Count > 0 then
      FSettingsTabs.Items[0].ImageName := 'gear_' + LIconSuffix;
  end;

  CustomTitleBar.SystemHeight := False;
  CustomTitleBar.Height := ScaleValue(CSettingsTitleBarHeight);
  CustomTitleBar.SystemColors := False;
  CustomTitleBar.StyleColors := False;
  CustomTitleBar.SystemButtons := False;
  // Match the main window's left-hand icon reservation so the first tab
  // begins after the title-bar gap rather than at the window edge.
  CustomTitleBar.ShowIcon := True;
  CustomTitleBar.Enabled := True;
  CustomTitleBar.BackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ForegroundColor := LTheme.TextColor;
  CustomTitleBar.InactiveBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.InactiveForegroundColor := LTabPalette.InactiveText;
  CustomTitleBar.ButtonBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ButtonForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonHoverBackgroundColor := LTabPalette.HoverTop;
  CustomTitleBar.ButtonHoverForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonPressedBackgroundColor := LTheme.SelectionColor;
  CustomTitleBar.ButtonPressedForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonInactiveBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ButtonInactiveForegroundColor := LTabPalette.InactiveText;
  TitleBarPanel1.AlphaValue := 255;
  TitleBarPanel1.Invalidate;

  ApplyToggle(swShowLogPanel);
  ApplyToggle(swShowRawPanel);
  ApplyToggle(swFollowRawSelection);
end;

procedure TFrmSettings.CreateSettingsTabs;
begin
  TitleBarPanel1.Height := ScaleValue(CSettingsTitleBarHeight);

  FSettingsTabImages := TVirtualImageList.Create(Self);
  FSettingsTabImages.Width := 16;
  FSettingsTabImages.Height := 16;
  FSettingsTabImages.ImageCollection := DataModule1.ImageCollection1;
  FSettingsTabImages.Add('gear_dark', 'gear_dark');
  FSettingsTabImages.Add('gear_light', 'gear_light');

  FSettingsTabs := TGlassTabStrip.Create(Self);
  FSettingsTabs.Parent := TitleBarPanel1;
  FSettingsTabs.Images := FSettingsTabImages;
  FSettingsTabs.Margins.Left := 0;
  FSettingsTabs.Margins.Top := 0;
  // Match the main window: the reserved area belongs to the native title
  // bar buttons and must never be covered by a tab.
  FSettingsTabs.Margins.Right := ScaleValue(CSettingsTitleBarButtonMargin);
  FSettingsTabs.Margins.Bottom := 0;
  FSettingsTabs.AlignWithMargins := True;
  FSettingsTabs.Align := alBottom;
  // TabHeight is DPI-scaled internally.  Keeping the tab two logical pixels
  // shorter than the 40 px title bar restores the same visible top gap as
  // the main window without stretching the tab itself.
  FSettingsTabs.TabHeight := CSettingsTabHeight;
  FSettingsTabs.Font.Assign(Font);
  FSettingsTabs.ShowAddButton := False;
  FSettingsTabs.ShowChevronButton := False;
  FSettingsTabs.OnBackgroundMouseDown := SettingsTabsBackgroundMouseDown;
  FSettingsTabs.AddTab('Settings', 'gear_light', False, True);
  FSettingsTabs.SendToBack;
end;

procedure TFrmSettings.SettingsTabsBackgroundMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  ReleaseCapture;
  SendMessage(Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
end;

procedure TFrmSettings.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  ApplyTheme;
end;

constructor TFrmSettings.Create(AOwner: TComponent);
begin
  inherited;
  CreateSettingsTabs;
  ApplyTheme;
end;

procedure TFrmSettings.FormShow(Sender: TObject);
begin
  Font.Name := TExplorerTheme.FontName;
  Font.Size := TExplorerTheme.FontSize;
  Font.Height := MulDiv(Font.Height, CurrentPPI, Font.PixelsPerInch);
end;

end.
