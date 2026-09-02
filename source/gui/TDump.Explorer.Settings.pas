//**************************************************************************************************
//
// Unit TDump.Explorer.Settings
//
// Settings dialog presentation
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
unit TDump.Explorer.Settings;

interface

uses
  Winapi.Messages,
  System.Classes,
  System.Math,
  System.Types,
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
  TDump.Explorer.Tabs,
  TDump.Explorer.UI,
  Vcl.ControlList;

const
  cWmTDumpSettingsChanged = WM_APP + $243;

type
  TThemeOption = (toSystem, toDark, toLight);

  TSettings = class
  private
    class var FInstance: TSettings;
    class var FSettingsFolderOverride: string;
  private
    FTDumpPath: string;
    FRecentItems: Integer;
    FRecentFiles: TStringList;
    FThemeOption: TThemeOption;
    FShowLogPanel: Boolean;
    FShowRawPanel: Boolean;
    FFollowRawSelection: Boolean;
    procedure SetRecentItems(const AValue: Integer);
    procedure TrimRecentFiles;
    function SettingsFolder: string;
    function SettingsFileName: string;
    constructor Create;
  public
    class function Instance: TSettings; static;
    class procedure SetSettingsFolderOverride(const AValue: string); static;
    destructor Destroy; override;
    procedure Load;
    procedure Save;
    procedure AddRecentItem(const AFileName: string);
    procedure RemoveRecentItem(const AFileName: string);
    procedure ClearRecentItems;
    function RecentItemCount: Integer;
    function RecentItem(AIndex: Integer): string;
    property TDumpPath: string read FTDumpPath write FTDumpPath;
    property RecentItems: Integer read FRecentItems write SetRecentItems;
    property ThemeOption: TThemeOption read FThemeOption write FThemeOption;
    property ShowLogPanel: Boolean read FShowLogPanel write FShowLogPanel;
    property ShowRawPanel: Boolean read FShowRawPanel write FShowRawPanel;
    property FollowRawSelection: Boolean read FFollowRawSelection
      write FFollowRawSelection;
  end;

  TFrmSettings = class(TForm)
    TitleBarPanel1: TTitleBarPanel;
    pnContent: TPanel;
    pnFooter: TPanel;
    lblHint: TLabel;
    lblInformation: TLabel;
    pnlGeneral: TPanel;
    lblGeneral: TLabel;
    lblTDumpPath: TLabel;
    edTDumpPath: TEdit;
    lblRecentItems: TLabel;
    nbRecentItems: TNumberBox;
    pnlAppearance: TPanel;
    lblAppearance: TLabel;
    lblPreferredTheme: TLabel;
    pnlWorkspace: TPanel;
    lblWorkspace: TLabel;
    lblShowLogPanel: TLabel;
    lblShowRawPanel: TLabel;
    lblFollowRawSelection: TLabel;
    swShowLogPanel: TToggleSwitch;
    swShowRawPanel: TToggleSwitch;
    swFollowRawSelection: TToggleSwitch;
    ControlList1: TControlList;
    procedure FormShow(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    FSettingsTabs: TExplorerTabStrip;
    FSettingsTabImages: TVirtualImageList;
    FButtonImages: TVirtualImageList;
    FBrowseButton: TSimpleUIButton;
    FCancelButton: TSimpleUIButton;
    FSaveButton: TSimpleUIButton;
    FSelectedThemeOption: TThemeOption;

    procedure CreateSettingsButtons;
    procedure CreateSettingsTabs;
    procedure SettingsTabsBackgroundMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ControlList1AfterDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ControlList1Change(Sender: TObject);
    procedure ConfigureThemeOptions;
    procedure LoadSettings;
    function SaveSettings: Boolean;
    procedure BroadcastSettingsChanged;
    procedure ApplyTheme;
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
  public
    constructor Create(AOwner: TComponent); override;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShlObj, System.IniFiles, System.SysUtils,
  Vcl.GraphUtil, Vcl.Themes, TDump.Explorer.Resources,
  TDump.Explorer.Phosphor.Font;

{$R *.dfm}

const
  cSettingsTitleBarButtonMargin = 50;
  cSettingsTitleBarHeight = 40;
  cSettingsTabHeight = 38;
  cSettingsTabBorderBlend = 0.82;
  cSettingsTabInactiveTopBlend = 0.97;
  cSettingsTabHoverTopBlend = 0.82;
  cSettingsTabCloseHoverBlend = 0.72;
  cThemeOptionCount = Ord(High(TThemeOption)) - Ord(Low(TThemeOption)) + 1;
  cThemeOptionIconSize = 32;
  cThemeOptionCardMargin = 3;
  cThemeOptionIconTextGap = 4;

  cThemeOptionSystem = Ord(toSystem);
  cThemeOptionDark = Ord(toDark);
  cThemeOptionLight = Ord(toLight);

  cSettingsFolderName = 'TDump-Explorer';
  cSettingsFileName = 'settings.ini';
  cSettingsGeneralSection = 'General';
  cSettingsRecentFilesSection = 'Recent Files';
  cSettingsAppearanceSection = 'Appearance';
  cSettingsWorkspaceSection = 'Workspace';
  cSettingsTDumpPathKey = 'TDumpPath';
  cSettingsRecentItemsKey = 'RecentItems';
  cSettingsRecentFileCountKey = 'Count';
  cSettingsRecentFileKeyPrefix = 'Item';
  cSettingsThemeKey = 'Theme';
  cSettingsShowLogPanelKey = 'ShowLogPanel';
  cSettingsShowRawPanelKey = 'ShowRawPanel';
  cSettingsFollowRawSelectionKey = 'FollowRawSelection';

  cDefaultRecentItems = 10;
  cMinimumRecentItems = 1;
  cMaximumRecentItems = 100;

{ TSettings }

constructor TSettings.Create;
begin
  inherited;
  FTDumpPath := '';
  FRecentItems := cDefaultRecentItems;
  FRecentFiles := TStringList.Create;
  FThemeOption := toSystem;
  FShowLogPanel := True;
  FShowRawPanel := True;
  FFollowRawSelection := True;
end;

destructor TSettings.Destroy;
begin
  FRecentFiles.Free;
  inherited;
end;

class function TSettings.Instance: TSettings;
begin
  if FInstance = nil then
    FInstance := TSettings.Create;
  Result := FInstance;
end;

class procedure TSettings.SetSettingsFolderOverride(const AValue: string);
begin
  FSettingsFolderOverride := ExcludeTrailingPathDelimiter(Trim(AValue));
end;

function TSettings.SettingsFolder: string;
var
  LRoamingAppData: array[0..MAX_PATH] of Char;
begin
  if FSettingsFolderOverride <> '' then
    Exit(FSettingsFolderOverride);
  if Failed(SHGetFolderPath(0, CSIDL_APPDATA, 0, SHGFP_TYPE_CURRENT,
    LRoamingAppData)) then
    raise Exception.Create('Unable to locate the roaming application-data folder.');
  Result := IncludeTrailingPathDelimiter(LRoamingAppData) + cSettingsFolderName;
end;

function TSettings.SettingsFileName: string;
begin
  Result := IncludeTrailingPathDelimiter(SettingsFolder) + cSettingsFileName;
end;

procedure TSettings.SetRecentItems(const AValue: Integer);
begin
  var LRecentItems := EnsureRange(AValue, cMinimumRecentItems,
    cMaximumRecentItems);
  if FRecentItems = LRecentItems then
    Exit;
  FRecentItems := LRecentItems;
  TrimRecentFiles;
end;

procedure TSettings.TrimRecentFiles;
begin
  while FRecentFiles.Count > FRecentItems do
    FRecentFiles.Delete(FRecentFiles.Count - 1);
end;

procedure TSettings.AddRecentItem(const AFileName: string);
begin
  var LFileName := Trim(AFileName);
  if LFileName = '' then
    Exit;

  LFileName := ExpandFileName(LFileName);
  RemoveRecentItem(LFileName);
  FRecentFiles.Insert(0, LFileName);
  TrimRecentFiles;
end;

procedure TSettings.RemoveRecentItem(const AFileName: string);
begin
  for var LIndex := FRecentFiles.Count - 1 downto 0 do
    if SameText(FRecentFiles[LIndex], AFileName) then
      FRecentFiles.Delete(LIndex);
end;

procedure TSettings.ClearRecentItems;
begin
  FRecentFiles.Clear;
end;

function TSettings.RecentItemCount: Integer;
begin
  Result := FRecentFiles.Count;
end;

function TSettings.RecentItem(AIndex: Integer): string;
begin
  Result := FRecentFiles[AIndex];
end;

procedure TSettings.Load;
var
  LIni: TIniFile;
  LFileName: string;
begin
  LFileName := SettingsFileName;
  if not FileExists(LFileName) then
    Exit;

  LIni := TIniFile.Create(LFileName);
  try
    FRecentFiles.Clear;
    FTDumpPath := LIni.ReadString(cSettingsGeneralSection,
      cSettingsTDumpPathKey, FTDumpPath);
    RecentItems := LIni.ReadInteger(cSettingsGeneralSection,
      cSettingsRecentItemsKey, FRecentItems);
    FThemeOption := TThemeOption(EnsureRange(LIni.ReadInteger(
      cSettingsAppearanceSection, cSettingsThemeKey, Ord(FThemeOption)),
      Ord(Low(TThemeOption)), Ord(High(TThemeOption))));
    FShowLogPanel := LIni.ReadBool(cSettingsWorkspaceSection,
      cSettingsShowLogPanelKey, FShowLogPanel);
    FShowRawPanel := LIni.ReadBool(cSettingsWorkspaceSection,
      cSettingsShowRawPanelKey, FShowRawPanel);
    FFollowRawSelection := LIni.ReadBool(cSettingsWorkspaceSection,
      cSettingsFollowRawSelectionKey, FFollowRawSelection);

    var LRecentFileCount := EnsureRange(LIni.ReadInteger(
      cSettingsRecentFilesSection, cSettingsRecentFileCountKey, 0), 0,
      cMaximumRecentItems);
    for var LIndex := 0 to LRecentFileCount - 1 do
    begin
      var LRecentFileName := LIni.ReadString(cSettingsRecentFilesSection,
        cSettingsRecentFileKeyPrefix + LIndex.ToString, '');
      if LRecentFileName <> '' then
        FRecentFiles.Add(LRecentFileName);
    end;
    TrimRecentFiles;
  finally
    LIni.Free;
  end;
end;

procedure TSettings.Save;
var
  LFolder: string;
  LIni: TIniFile;
begin
  LFolder := SettingsFolder;
  if not ForceDirectories(LFolder) then
    RaiseLastOSError;

  LIni := TIniFile.Create(SettingsFileName);
  try
    LIni.WriteString(cSettingsGeneralSection, cSettingsTDumpPathKey, FTDumpPath);
    LIni.WriteInteger(cSettingsGeneralSection, cSettingsRecentItemsKey,
      FRecentItems);
    LIni.EraseSection(cSettingsRecentFilesSection);
    if FRecentFiles.Count > 0 then
    begin
      LIni.WriteInteger(cSettingsRecentFilesSection,
        cSettingsRecentFileCountKey, FRecentFiles.Count);
      for var LIndex := 0 to FRecentFiles.Count - 1 do
        LIni.WriteString(cSettingsRecentFilesSection,
          cSettingsRecentFileKeyPrefix + LIndex.ToString,
          FRecentFiles[LIndex]);
    end;
    LIni.WriteInteger(cSettingsAppearanceSection, cSettingsThemeKey,
      Ord(FThemeOption));
    LIni.WriteBool(cSettingsWorkspaceSection, cSettingsShowLogPanelKey,
      FShowLogPanel);
    LIni.WriteBool(cSettingsWorkspaceSection, cSettingsShowRawPanelKey,
      FShowRawPanel);
    LIni.WriteBool(cSettingsWorkspaceSection, cSettingsFollowRawSelectionKey,
      FFollowRawSelection);
  finally
    LIni.Free;
  end;
end;

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
  LTabPalette: TExplorerTabPalette;
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
  ApplyLabel(lblGeneral, LTheme.TextColor);
  ApplyLabel(lblTDumpPath, LTheme.TextColor);
  ApplyLabel(lblRecentItems, LTheme.TextColor);
  ApplyLabel(lblAppearance, LTheme.TextColor);
  ApplyLabel(lblPreferredTheme, LTheme.InactiveText);
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

  ApplyExplorerThemeToButton(FBrowseButton, LTheme);
  ApplyExplorerThemeToButton(FCancelButton, LTheme);
  ApplyExplorerThemeToButton(FSaveButton, LTheme);
  if Assigned(FBrowseButton) then
    FBrowseButton.ImageName := 'browse_' + LIconSuffix;

  if Assigned(FSettingsTabs) then
  begin
    LTabPalette.StripTop := LTheme.BackgroundColor;
    LTabPalette.StripBottom := LTheme.BackgroundColor;
    LTabPalette.StripBorder := ColorBlendRGB(LTheme.TextColor,
      LTheme.BackgroundColor, cSettingsTabBorderBlend);
    LTabPalette.BackgroundTopLine := LTheme.BackgroundColor;
    LTabPalette.TabTop := LTheme.BackgroundColor;
    LTabPalette.TabBottom := LTheme.BackgroundColor;
    LTabPalette.InactiveTop := ColorBlendRGB(LTheme.TextColor,
      LTheme.BackgroundColor, cSettingsTabInactiveTopBlend);
    LTabPalette.InactiveBottom := LTheme.BackgroundColor;
    LTabPalette.HoverTop := ColorBlendRGB(LTheme.SelectionColor,
      LTheme.BackgroundColor, cSettingsTabHoverTopBlend);
    LTabPalette.HoverBottom := LTheme.BackgroundColor;
    LTabPalette.Accent := LTheme.SelectionColor;
    LTabPalette.Text := LTheme.TextColor;
    LTabPalette.InactiveText := LTheme.InactiveText;
    LTabPalette.CloseHover := ColorBlendRGB(LTheme.SelectionColor,
      LTheme.BackgroundColor, cSettingsTabCloseHoverBlend);
    FSettingsTabs.Palette := LTabPalette;
    if FSettingsTabs.Items.Count > 0 then
      FSettingsTabs.Items[0].ImageName := 'gear_' + LIconSuffix;
  end;

  CustomTitleBar.SystemHeight := False;
  CustomTitleBar.Height := ScaleValue(cSettingsTitleBarHeight);
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
  //TitleBarPanel1.AlphaValue := 255;
  TitleBarPanel1.Invalidate;

  ApplyToggle(swShowLogPanel);
  ApplyToggle(swShowRawPanel);
  ApplyToggle(swFollowRawSelection);
  ControlList1.Color := LTheme.BackgroundColor;
  ControlList1.ItemColor := LTheme.BackgroundColor;
  ControlList1.Invalidate;
end;

procedure TFrmSettings.ConfigureThemeOptions;
begin
  // Keep the component's designer size intact.  Only its virtual items are
  // sized here so three cards always occupy the available row.
  ControlList1.ItemCount := cThemeOptionCount;
  ControlList1.ColumnLayout := cltMultiLeftToRight;
  ControlList1.ItemMargins.Left := 0;
  ControlList1.ItemMargins.Top := 0;
  ControlList1.ItemMargins.Right := 0;
  ControlList1.ItemMargins.Bottom := 0;
  ControlList1.ItemWidth := Max(1, ControlList1.ClientWidth div cThemeOptionCount);
  ControlList1.ItemHeight := Max(1, ControlList1.ClientHeight);
  ControlList1.ItemIndex := Ord(FSelectedThemeOption);
end;

procedure TFrmSettings.LoadSettings;
begin
  TSettings.Instance.Load;
  edTDumpPath.Text := TSettings.Instance.TDumpPath;
  nbRecentItems.Value := EnsureRange(TSettings.Instance.RecentItems,
    Round(nbRecentItems.MinValue), Round(nbRecentItems.MaxValue));
  FSelectedThemeOption := TSettings.Instance.ThemeOption;
  swShowLogPanel.State := if TSettings.Instance.ShowLogPanel then tssOn else tssOff;
  swShowRawPanel.State := if TSettings.Instance.ShowRawPanel then tssOn else tssOff;
  swFollowRawSelection.State := if TSettings.Instance.FollowRawSelection then
    tssOn
  else
    tssOff;
  ConfigureThemeOptions;
end;

function TFrmSettings.SaveSettings: Boolean;
var
  LSettings: TSettings;
  LRecentItems: Integer;
begin
  LSettings := TSettings.Instance;
  LRecentItems := Round(nbRecentItems.Value);
  Result := (LSettings.TDumpPath <> edTDumpPath.Text) or
    (LSettings.RecentItems <> LRecentItems) or
    (LSettings.ThemeOption <> FSelectedThemeOption) or
    (LSettings.ShowLogPanel <> (swShowLogPanel.State = tssOn)) or
    (LSettings.ShowRawPanel <> (swShowRawPanel.State = tssOn)) or
    (LSettings.FollowRawSelection <>
      (swFollowRawSelection.State = tssOn));
  if not Result then
    Exit;

  LSettings.TDumpPath := edTDumpPath.Text;
  LSettings.RecentItems := LRecentItems;
  LSettings.ThemeOption := FSelectedThemeOption;
  LSettings.ShowLogPanel := swShowLogPanel.State = tssOn;
  LSettings.ShowRawPanel := swShowRawPanel.State = tssOn;
  LSettings.FollowRawSelection :=
    swFollowRawSelection.State = tssOn;
  LSettings.Save;
end;

procedure TFrmSettings.BroadcastSettingsChanged;
begin
  for var LIndex := 0 to Screen.FormCount - 1 do
  begin
    var LForm := Screen.Forms[LIndex];
    if LForm.HandleAllocated then
      PostMessage(LForm.Handle, cWmTDumpSettingsChanged, 0, 0);
  end;
end;

procedure TFrmSettings.btnSaveClick(Sender: TObject);
begin
  if SaveSettings then
    BroadcastSettingsChanged;
end;

procedure TFrmSettings.ControlList1AfterDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
const
  cThemeOptionCaptions: array[cThemeOptionSystem..cThemeOptionLight] of string =
    ('System', 'Dark', 'Light');
  cThemeOptionIconCodes: array[cThemeOptionSystem..cThemeOptionLight] of Word =
    ($E32E, $E330, $E472); // monitor, moon, sun
var
  LTheme: TExplorerTheme;
  LCardRect: TRect;
  LTextRect: TRect;
  LIconRect: TRect;
  LIconX: Integer;
  LIconY: Integer;
  LIconSize: Integer;
  LContentHeight: Integer;
  LFillColor: TColor;
  LTextColor: TColor;
  LIconColor: TColor;
begin
  if (AIndex < cThemeOptionSystem) or (AIndex > cThemeOptionLight) then
    Exit;

  LTheme := TExplorerTheme.ActiveTheme;
  LCardRect := ARect;
  InflateRect(LCardRect, -ScaleValue(cThemeOptionCardMargin), -ScaleValue(cThemeOptionCardMargin));
  if (LCardRect.Width <= 0) or (LCardRect.Height <= 0) then
    Exit;

  ACanvas.Brush.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
  ACanvas.FillRect(ARect);
  LTextColor := LTheme.TextColor;
  LIconColor := LTheme.TextColor;
  if (odSelected in AState) then
  begin
    LFillColor := ColorBlendRGB(TExplorerTheme.ActiveTheme.SelectionColor, TExplorerTheme.ActiveTheme.BackgroundColor, 0.9);
    DrawRoundedBar(ACanvas, ARect, LFillColor, TExplorerTheme.ActiveTheme.SelectionColor, 4.0);
    LTextColor := LTheme.SelectionColor;
    LIconColor := LTheme.SelectionColor;
  end
  else if (odHotLight in AState) then
  begin
    LFillColor := ColorBlendRGB(TExplorerTheme.ActiveTheme.SelectionColor, TExplorerTheme.ActiveTheme.BackgroundColor, 0.95);
    ACanvas.Brush.Color := LFillColor;
    ACanvas.FillRect(ARect);
  end;


  ACanvas.Font.Name := TExplorerTheme.FontName;
  ACanvas.Font.Size := TExplorerTheme.FontSize;
  //ACanvas.Font.Style := [fsBold];
  LIconSize := ScaleValue(cThemeOptionIconSize);
  LContentHeight := LIconSize + ScaleValue(cThemeOptionIconTextGap) + ACanvas.TextHeight(cThemeOptionCaptions[AIndex]);
  LIconX := LCardRect.Left + (LCardRect.Width - LIconSize) div 2;
  LIconY := LCardRect.Top + Max(0, (LCardRect.Height - LContentHeight) div 2);
  LIconRect := Rect(LIconX, LIconY, LIconX + LIconSize, LIconY + LIconSize);
  PhosphorFont.DrawIcon(ACanvas.Handle, cThemeOptionIconCodes[AIndex], LIconRect, LIconColor, pfwRegular);

  LTextRect := LCardRect;
  LTextRect.Top := LIconY + LIconSize + ScaleValue(cThemeOptionIconTextGap);
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Color := LTextColor;
  DrawText(ACanvas.Handle, PChar(cThemeOptionCaptions[AIndex]), Length(cThemeOptionCaptions[AIndex]), LTextRect,
    DT_CENTER or DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX);
end;

procedure TFrmSettings.ControlList1Change(Sender: TObject);
begin
  if (ControlList1.ItemIndex < cThemeOptionSystem) or
    (ControlList1.ItemIndex > cThemeOptionLight) then
    Exit;

  FSelectedThemeOption := TThemeOption(ControlList1.ItemIndex);

  ControlList1.Invalidate;
end;

procedure TFrmSettings.CreateSettingsButtons;
begin
  FButtonImages := TVirtualImageList.Create(Self);
  FButtonImages.Width := 16;
  FButtonImages.Height := 16;
  FButtonImages.ImageCollection := DataModule1.ImageCollection1;
  FButtonImages.Add('browse_dark', 'file-magnifying-glass_dark');
  FButtonImages.Add('browse_light', 'file-magnifying-glass_light');

  FBrowseButton := TSimpleUIButton.Create(Self);
  FBrowseButton.Parent := pnlGeneral;
  FBrowseButton.SetBounds(edTDumpPath.Left + edTDumpPath.Width + ScaleValue(6),
    edTDumpPath.Top - ScaleValue(1), ScaleValue(87), ScaleValue(25));
  FBrowseButton.Anchors := [akTop, akRight];
  FBrowseButton.Caption := 'Browse...';
  FBrowseButton.Images := FButtonImages;
  FBrowseButton.ImageName := 'browse_light';
  FBrowseButton.ParentFont := True;
  FBrowseButton.TabOrder := 1;
  nbRecentItems.TabOrder := 2;

  var LButtonWidth := ScaleValue(80);
  var LButtonHeight := ScaleValue(25);
  var LRightMargin := ScaleValue(31);
  var LButtonGap := ScaleValue(6);
  var LButtonTop := ScaleValue(29);

  FCancelButton := TSimpleUIButton.Create(Self);
  FCancelButton.Parent := pnFooter;
  FCancelButton.SetBounds(pnFooter.ClientWidth - LRightMargin -
    (LButtonWidth * 2) - LButtonGap, LButtonTop, LButtonWidth,
    LButtonHeight);
  FCancelButton.Anchors := [akTop, akRight];
  FCancelButton.Cancel := True;
  FCancelButton.Caption := 'Cancel';
  FCancelButton.ModalResult := mrCancel;
  FCancelButton.ParentFont := True;
  FCancelButton.TabOrder := 0;

  FSaveButton := TSimpleUIButton.Create(Self);
  FSaveButton.Parent := pnFooter;
  FSaveButton.SetBounds(pnFooter.ClientWidth - LRightMargin - LButtonWidth,
    LButtonTop, LButtonWidth, LButtonHeight);
  FSaveButton.Anchors := [akTop, akRight];
  FSaveButton.Caption := 'Save';
  FSaveButton.Default := True;
  FSaveButton.ModalResult := mrOk;
  FSaveButton.OnClick := btnSaveClick;
  FSaveButton.ParentFont := True;
  FSaveButton.TabOrder := 1;
end;

procedure TFrmSettings.CreateSettingsTabs;
begin
  TitleBarPanel1.Height := ScaleValue(cSettingsTitleBarHeight);

  FSettingsTabImages := TVirtualImageList.Create(Self);
  FSettingsTabImages.Width := 16;
  FSettingsTabImages.Height := 16;
  FSettingsTabImages.ImageCollection := DataModule1.ImageCollection1;
  FSettingsTabImages.Add('gear_dark', 'gear_dark');
  FSettingsTabImages.Add('gear_light', 'gear_light');

  FSettingsTabs := TExplorerTabStrip.Create(Self);
  FSettingsTabs.Parent := TitleBarPanel1;
  FSettingsTabs.Images := FSettingsTabImages;
  FSettingsTabs.Margins.Left := 0;
  FSettingsTabs.Margins.Top := 0;
  // Match the main window: the reserved area belongs to the native title
  // bar buttons and must never be covered by a tab.
  FSettingsTabs.Margins.Right := ScaleValue(cSettingsTitleBarButtonMargin);
  FSettingsTabs.Margins.Bottom := 0;
  FSettingsTabs.AlignWithMargins := True;
  FSettingsTabs.Align := alBottom;
  // TabHeight is DPI-scaled internally.  Keeping the tab two logical pixels
  // shorter than the 40 px title bar restores the same visible top gap as
  // the main window without stretching the tab itself.
  FSettingsTabs.TabHeight := cSettingsTabHeight;
  FSettingsTabs.Font.Assign(Font);
  FSettingsTabs.ShowAddButton := False;
  FSettingsTabs.ShowCustomRightButton := False;
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
  LoadSettings;
  ControlList1.OnAfterDrawItem := ControlList1AfterDrawItem;
  ControlList1.OnChange := ControlList1Change;
  CreateSettingsButtons;
  CreateSettingsTabs;
  ApplyTheme;
end;

procedure TFrmSettings.FormShow(Sender: TObject);
begin
  Font.Name := TExplorerTheme.FontName;
  Font.Size := TExplorerTheme.FontSize;
  Font.Height := MulDiv(Font.Height, CurrentPPI, Font.PixelsPerInch);
end;

initialization

finalization
  TSettings.FInstance.Free;

end.
