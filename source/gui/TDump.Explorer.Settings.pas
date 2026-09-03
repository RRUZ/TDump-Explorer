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
    FRememberWindowPlacement: Boolean;
    FRestorePreviousSession: Boolean;
    FHasWindowBounds: Boolean;
    FWindowBounds: TRect;
    FLastSessionFiles: TStringList;
    FLastSessionActiveIndex: Integer;
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
    procedure ClearLastSessionFiles;
    procedure AddLastSessionFile(const AFileName: string);
    function LastSessionFileCount: Integer;
    function LastSessionFile(AIndex: Integer): string;
    procedure SetWindowBounds(const AValue: TRect);
    procedure ClearWindowBounds;
    function RecentItemCount: Integer;
    function RecentItem(AIndex: Integer): string;
    property TDumpPath: string read FTDumpPath write FTDumpPath;
    property RecentItems: Integer read FRecentItems write SetRecentItems;
    property ThemeOption: TThemeOption read FThemeOption write FThemeOption;
    property ShowLogPanel: Boolean read FShowLogPanel write FShowLogPanel;
    property ShowRawPanel: Boolean read FShowRawPanel write FShowRawPanel;
    property FollowRawSelection: Boolean read FFollowRawSelection
      write FFollowRawSelection;
    property RememberWindowPlacement: Boolean read FRememberWindowPlacement
      write FRememberWindowPlacement;
    property RestorePreviousSession: Boolean read FRestorePreviousSession
      write FRestorePreviousSession;
    property HasWindowBounds: Boolean read FHasWindowBounds;
    property WindowBounds: TRect read FWindowBounds;
    property LastSessionActiveIndex: Integer read FLastSessionActiveIndex
      write FLastSessionActiveIndex;
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
    pbCard: TPaintBox;
    pbInputBorders: TPaintBox;
    cbRememberWindowPlacement: TCheckBox;
    cbRestorePreviousSession: TCheckBox;
    procedure CardPaint(Sender: TObject);
    procedure InputBordersPaint(Sender: TObject);
    procedure InputFocusChanged(Sender: TObject);
    procedure InputBordersMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    //FSettingsTabs: TExplorerTabStrip;
    //FSettingsTabImages: TVirtualImageList;
    FButtonImages: TVirtualImageList;
    FBrowseButton: TSimpleUIButton;
    FCancelButton: TSimpleUIButton;
    FSaveButton: TSimpleUIButton;
    FSelectedThemeOption: TThemeOption;

    procedure CreateSettingsButtons;
    procedure UpdateSettingsLayout;
    function InputBorderRect(AInput: TWinControl): TRect;
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
  protected
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    procedure DoAfterMonitorDpiChanged(OldDPI, NewDPI: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ScaleForPPI(NewPPI: Integer); override;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShlObj, System.IniFiles, System.SysUtils,
  Vcl.GraphUtil, Vcl.Themes, TDump.Explorer.Resources,
  TDump.Explorer.Phosphor.Font;

{$R *.dfm}

const
  cSettingsTitleBarButtonMargin = 50;
  cSettingsTitleBarHeight = 30;
  cSettingsTabHeight = 38;
  cSettingsTabBorderBlend = 0.82;
  cSettingsTabInactiveTopBlend = 0.97;
  cSettingsTabHoverTopBlend = 0.82;
  cSettingsTabCloseHoverBlend = 0.72;
  cThemeOptionCount = Ord(High(TThemeOption)) - Ord(Low(TThemeOption)) + 1;
  cThemeOptionIconSize = 28;
  cThemeOptionCardMargin = 4;
  cThemeOptionIconTextGap = 4;
  // All geometry is authored at 96 DPI, like the About dialog.
  cSettingsCardBorderBlend = 0.87;
  cSettingsInputBorderBlend = 0.78;
  cSettingsInputPaddingX = 8;
  cSettingsInputPaddingY = 4;

  cThemeOptionSystem = Ord(toSystem);
  cThemeOptionDark = Ord(toDark);
  cThemeOptionLight = Ord(toLight);

  cSettingsFolderName = 'TDump-Explorer';
  cSettingsFileName = 'settings.ini';
  cSettingsGeneralSection = 'General';
  cSettingsRecentFilesSection = 'Recent Files';
  cSettingsAppearanceSection = 'Appearance';
  cSettingsWorkspaceSection = 'Workspace';
  cSettingsWindowSection = 'Window';
  cSettingsSessionSection = 'Session';
  cSettingsTDumpPathKey = 'TDumpPath';
  cSettingsRecentItemsKey = 'RecentItems';
  cSettingsRecentFileCountKey = 'Count';
  cSettingsRecentFileKeyPrefix = 'Item';
  cSettingsThemeKey = 'Theme';
  cSettingsShowLogPanelKey = 'ShowLogPanel';
  cSettingsShowRawPanelKey = 'ShowRawPanel';
  cSettingsFollowRawSelectionKey = 'FollowRawSelection';
  cSettingsRememberWindowPlacementKey = 'RememberWindowPlacement';
  cSettingsRestorePreviousSessionKey = 'RestorePreviousSession';
  cSettingsWindowBoundsValidKey = 'BoundsValid';
  cSettingsWindowLeftKey = 'Left';
  cSettingsWindowTopKey = 'Top';
  cSettingsWindowWidthKey = 'Width';
  cSettingsWindowHeightKey = 'Height';
  cSettingsSessionFileCountKey = 'FileCount';
  cSettingsSessionFileKeyPrefix = 'File';
  cSettingsSessionActiveIndexKey = 'ActiveIndex';

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
  FRememberWindowPlacement := True;
  FRestorePreviousSession := True;
  FLastSessionFiles := TStringList.Create;
  FLastSessionActiveIndex := 0;
end;

destructor TSettings.Destroy;
begin
  FRecentFiles.Free;
  FLastSessionFiles.Free;
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

procedure TSettings.ClearLastSessionFiles;
begin
  FLastSessionFiles.Clear;
  FLastSessionActiveIndex := 0;
end;

procedure TSettings.AddLastSessionFile(const AFileName: string);
var
  LFileName: string;
begin
  LFileName := Trim(AFileName);
  if LFileName = '' then
    Exit;
  LFileName := ExpandFileName(LFileName);
  for var LIndex := 0 to FLastSessionFiles.Count - 1 do
    if SameText(FLastSessionFiles[LIndex], LFileName) then
      Exit;
  FLastSessionFiles.Add(LFileName);
end;

function TSettings.LastSessionFileCount: Integer;
begin
  Result := FLastSessionFiles.Count;
end;

function TSettings.LastSessionFile(AIndex: Integer): string;
begin
  Result := FLastSessionFiles[AIndex];
end;

procedure TSettings.SetWindowBounds(const AValue: TRect);
begin
  FWindowBounds := AValue;
  FHasWindowBounds := (AValue.Width > 0) and (AValue.Height > 0);
end;

procedure TSettings.ClearWindowBounds;
begin
  FHasWindowBounds := False;
  FWindowBounds := Rect(0, 0, 0, 0);
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
    FRememberWindowPlacement := LIni.ReadBool(cSettingsWorkspaceSection,
      cSettingsRememberWindowPlacementKey, FRememberWindowPlacement);
    FRestorePreviousSession := LIni.ReadBool(cSettingsWorkspaceSection,
      cSettingsRestorePreviousSessionKey, FRestorePreviousSession);
    FHasWindowBounds := LIni.ReadBool(cSettingsWindowSection,
      cSettingsWindowBoundsValidKey, False);
    if FHasWindowBounds then
    begin
      FWindowBounds.Left := LIni.ReadInteger(cSettingsWindowSection,
        cSettingsWindowLeftKey, 0);
      FWindowBounds.Top := LIni.ReadInteger(cSettingsWindowSection,
        cSettingsWindowTopKey, 0);
      FWindowBounds.Width := LIni.ReadInteger(cSettingsWindowSection,
        cSettingsWindowWidthKey, 0);
      FWindowBounds.Height := LIni.ReadInteger(cSettingsWindowSection,
        cSettingsWindowHeightKey, 0);
      if (FWindowBounds.Width <= 0) or (FWindowBounds.Height <= 0) then
        ClearWindowBounds;
    end;

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

    FLastSessionFiles.Clear;
    var LSessionFileCount := EnsureRange(LIni.ReadInteger(
      cSettingsSessionSection, cSettingsSessionFileCountKey, 0), 0,
      cMaximumRecentItems);
    for var LIndex := 0 to LSessionFileCount - 1 do
    begin
      var LSessionFileName := LIni.ReadString(cSettingsSessionSection,
        cSettingsSessionFileKeyPrefix + LIndex.ToString, '');
      if LSessionFileName <> '' then
        AddLastSessionFile(LSessionFileName);
    end;
    FLastSessionActiveIndex := EnsureRange(LIni.ReadInteger(
      cSettingsSessionSection, cSettingsSessionActiveIndexKey, 0), 0,
      Max(0, FLastSessionFiles.Count - 1));
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
    LIni.WriteBool(cSettingsWorkspaceSection,
      cSettingsRememberWindowPlacementKey, FRememberWindowPlacement);
    LIni.WriteBool(cSettingsWorkspaceSection,
      cSettingsRestorePreviousSessionKey, FRestorePreviousSession);
    LIni.WriteBool(cSettingsWindowSection, cSettingsWindowBoundsValidKey,
      FHasWindowBounds);
    if FHasWindowBounds then
    begin
      LIni.WriteInteger(cSettingsWindowSection, cSettingsWindowLeftKey,
        FWindowBounds.Left);
      LIni.WriteInteger(cSettingsWindowSection, cSettingsWindowTopKey,
        FWindowBounds.Top);
      LIni.WriteInteger(cSettingsWindowSection, cSettingsWindowWidthKey,
        FWindowBounds.Width);
      LIni.WriteInteger(cSettingsWindowSection, cSettingsWindowHeightKey,
        FWindowBounds.Height);
    end;
    LIni.EraseSection(cSettingsSessionSection);
    if FLastSessionFiles.Count > 0 then
    begin
      LIni.WriteInteger(cSettingsSessionSection,
        cSettingsSessionFileCountKey, FLastSessionFiles.Count);
      for var LIndex := 0 to FLastSessionFiles.Count - 1 do
        LIni.WriteString(cSettingsSessionSection,
          cSettingsSessionFileKeyPrefix + LIndex.ToString,
          FLastSessionFiles[LIndex]);
      LIni.WriteInteger(cSettingsSessionSection,
        cSettingsSessionActiveIndexKey, EnsureRange(FLastSessionActiveIndex,
        0, FLastSessionFiles.Count - 1));
    end;
  finally
    LIni.Free;
  end;
end;

{ TFrmSettings }

function TFrmSettings.InputBorderRect(AInput: TWinControl): TRect;
begin
  Result := AInput.BoundsRect;
  InflateRect(Result, ScaleValue(cSettingsInputPaddingX),
    ScaleValue(cSettingsInputPaddingY));
end;

procedure TFrmSettings.CardPaint(Sender: TObject);
begin
  var LTheme := TExplorerTheme.ActiveTheme;
  var LBorder := ColorBlendRGB(LTheme.TextColor, LTheme.BackgroundColor,
    cSettingsCardBorderBlend);
  DrawAntialiasedRoundedRectangle(pbCard.Canvas,
    Rect(ScaleValue(12), ScaleValue(8), pbCard.Width - ScaleValue(12),
      pbCard.Height - ScaleValue(8)), LTheme.BackgroundColor, LBorder,
    ScaleValue(10), 1);
  var LDividerY := pnlAppearance.Top - ScaleValue(10);
  pbCard.Canvas.Pen.Color := LBorder;
  pbCard.Canvas.MoveTo(ScaleValue(26), LDividerY);
  pbCard.Canvas.LineTo(pbCard.Width - ScaleValue(26), LDividerY);
end;

procedure TFrmSettings.InputBordersPaint(Sender: TObject);
  procedure DrawInput(AInput: TWinControl);
  begin
    var LTheme := TExplorerTheme.ActiveTheme;
    var LBorder := if AInput.Focused then LTheme.SelectionColor else
      ColorBlendRGB(LTheme.TextColor, LTheme.BackgroundColor,
        cSettingsInputBorderBlend);
    DrawAntialiasedRoundedRectangle(pbInputBorders.Canvas,
      InputBorderRect(AInput), clNone, LBorder, ScaleValue(2), 1);
  end;
begin
  DrawInput(edTDumpPath);
  DrawInput(nbRecentItems);
end;

procedure TFrmSettings.InputFocusChanged(Sender: TObject);
begin
  pbInputBorders.Invalidate;
end;

procedure TFrmSettings.InputBordersMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  if InputBorderRect(edTDumpPath).Contains(Point(X, Y)) then
    edTDumpPath.SetFocus
  else if InputBorderRect(nbRecentItems).Contains(Point(X, Y)) then
    nbRecentItems.SetFocus;
end;

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

begin
  if not Assigned(pnContent) then
    Exit;
  // Anchor emphasized fonts to their DFM heights to avoid cumulative
  // rounding when moving repeatedly between fractional DPI scales.
  for var LHeading in TArray<TLabel>.Create(lblGeneral, lblAppearance, lblWorkspace) do
    SetExplorerFontHeight(LHeading, -13);
  SetExplorerFontHeight(lblInformation, -18);
  var LTheme := TExplorerTheme.ActiveTheme;
  // Icon suffixes describe the surface they are intended for.  On a light
  // form use the visible light-UI glyphs, and vice versa.
  var LIconSuffix := if IsLightThemeActive then 'light' else 'dark';

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
  for var LCheckBox in TArray<TCheckBox>.Create(cbRememberWindowPlacement,
    cbRestorePreviousSession) do
  begin
    // Native Windows checkbox captions ignore Font.Color under visual styles.
    // Use the app style for the glyph/background and our palette for the text.
    LCheckBox.StyleName := '';
    LCheckBox.StyleElements := LCheckBox.StyleElements - [seFont];
    LCheckBox.Font.Color := LTheme.TextColor;
  end;
  ApplyLabel(lblInformation, LTheme.InactiveText);
  ApplyLabel(lblHint, LTheme.InactiveText);

  // We own these controls' colors and outer frames. Keep the native edit
  // path so a VCL style hook cannot repaint their borderless non-client area.
  edTDumpPath.StyleName := 'Windows';
  nbRecentItems.StyleName := 'Windows';
  edTDumpPath.Color := LTheme.BackgroundColor;
  edTDumpPath.Font.Color := LTheme.TextColor;
  nbRecentItems.Color := LTheme.BackgroundColor;
  nbRecentItems.Font.Color := LTheme.TextColor;
  nbRecentItems.SpinButtonOptions.ArrowColor := LTheme.TextColor;
  nbRecentItems.SpinButtonOptions.ArrowHotColor := LTheme.SelectionColor;
  nbRecentItems.SpinButtonOptions.ArrowPressedColor := LTheme.SelectionColor;
  nbRecentItems.SpinButtonOptions.ArrowDisabledColor := LTheme.InactiveText;

  ApplyExplorerThemeToButton(FBrowseButton, LTheme);
  ApplyExplorerThemeToButton(FCancelButton, LTheme);
  if Assigned(FSaveButton) then
  begin
    var LPalette := ExplorerButtonPalette(LTheme);
    LPalette.Background := LTheme.SelectionColor;
    LPalette.Border := LTheme.SelectionColor;
    LPalette.HotBackground := ColorBlendRGB(LTheme.SelectionColor,
      LTheme.BackgroundColor, 0.15);
    LPalette.PressedBackground := ColorBlendRGB(LTheme.SelectionColor,
      LTheme.BackgroundColor, 0.28);
    LPalette.Text := StyleServices.GetSystemColor(clHighlightText);
    LPalette.HotText := LPalette.Text;
    LPalette.PressedText := LPalette.Text;
    LPalette.FocusedBorder := LTheme.TextColor;
    FSaveButton.ApplyPalette(LPalette);
  end;
  if Assigned(FBrowseButton) then
    FBrowseButton.ImageName := 'browse_' + LIconSuffix;
      {
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
      }
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
  CustomTitleBar.InactiveForegroundColor := LTheme.InactiveText;
  CustomTitleBar.ButtonBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ButtonForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonHoverBackgroundColor := ColorBlendRGB(
    LTheme.SelectionColor, LTheme.BackgroundColor, 0.82);
  CustomTitleBar.ButtonHoverForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonPressedBackgroundColor := LTheme.SelectionColor;
  CustomTitleBar.ButtonPressedForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonInactiveBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ButtonInactiveForegroundColor := LTheme.InactiveText;
  //TitleBarPanel1.AlphaValue := 255;
  TitleBarPanel1.Invalidate;

  ApplyToggle(swShowLogPanel);
  ApplyToggle(swShowRawPanel);
  ApplyToggle(swFollowRawSelection);
  ControlList1.Color := LTheme.BackgroundColor;
  ControlList1.ItemColor := LTheme.BackgroundColor;
  ControlList1.Invalidate;
  pbCard.Invalidate;
  pbInputBorders.Invalidate;
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
  cbRememberWindowPlacement.Checked :=
    TSettings.Instance.RememberWindowPlacement;
  cbRestorePreviousSession.Checked := TSettings.Instance.RestorePreviousSession;
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
      (swFollowRawSelection.State = tssOn)) or
    (LSettings.RememberWindowPlacement <> cbRememberWindowPlacement.Checked) or
    (LSettings.RestorePreviousSession <> cbRestorePreviousSession.Checked);
  if not Result then
    Exit;

  LSettings.TDumpPath := edTDumpPath.Text;
  LSettings.RecentItems := LRecentItems;
  LSettings.ThemeOption := FSelectedThemeOption;
  LSettings.ShowLogPanel := swShowLogPanel.State = tssOn;
  LSettings.ShowRawPanel := swShowRawPanel.State = tssOn;
  LSettings.FollowRawSelection :=
    swFollowRawSelection.State = tssOn;
  LSettings.RememberWindowPlacement := cbRememberWindowPlacement.Checked;
  LSettings.RestorePreviousSession := cbRestorePreviousSession.Checked;
  if not LSettings.RememberWindowPlacement then
    LSettings.ClearWindowBounds;
  if not LSettings.RestorePreviousSession then
    LSettings.ClearLastSessionFiles;
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

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := LTheme.BackgroundColor;
  ACanvas.FillRect(ARect);
  LFillColor := LTheme.BackgroundColor;
  var LBorderColor := ColorBlendRGB(LTheme.TextColor, LTheme.BackgroundColor,
    cSettingsCardBorderBlend);
  LTextColor := LTheme.TextColor;
  LIconColor := LTheme.TextColor;
  if (odSelected in AState) then
  begin
    LFillColor := ColorBlendRGB(LTheme.SelectionColor, LTheme.BackgroundColor, 0.9);
    LBorderColor := LTheme.SelectionColor;
    LTextColor := LTheme.SelectionColor;
    LIconColor := LTheme.SelectionColor;
  end
  else if (odHotLight in AState) then
  begin
    LFillColor := ColorBlendRGB(LTheme.SelectionColor, LTheme.BackgroundColor, 0.95);
    LBorderColor := ColorBlendRGB(LTheme.SelectionColor, LTheme.BackgroundColor, 0.5);
  end;

  var LRect := ARect;
  InflateRect(LRect, -ScaleValue(cThemeOptionCardMargin), 0);
  DrawAntialiasedRoundedRectangle(ACanvas, LRect, LFillColor, LBorderColor, ScaleValue(2), 1);

  ACanvas.Font.Assign(ControlList1.Font);
  ACanvas.Font.Name := TExplorerTheme.FontName;
  //ACanvas.Font.Style := [fsBold];
  LIconSize := ScaleValue(cThemeOptionIconSize);
  LContentHeight := LIconSize + ScaleValue(cThemeOptionIconTextGap) + ACanvas.TextHeight(cThemeOptionCaptions[AIndex]);
  LIconX := LCardRect.Left + (LCardRect.Width - LIconSize) div 2;
  LIconY := LCardRect.Top + Max(0, (LCardRect.Height - LContentHeight) div 2);
  LIconRect := Rect(LIconX, LIconY, LIconX + LIconSize, LIconY + LIconSize);
  PhosphorFont.DrawIcon(ACanvas.Handle, cThemeOptionIconCodes[AIndex], LIconRect, LIconColor, pfwThin);

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
  FButtonImages.Width := ScaleValue(16);
  FButtonImages.Height := ScaleValue(16);
  FButtonImages.ImageCollection := DataModule1.ImageCollection1;
  FButtonImages.Add('browse_dark', 'file-magnifying-glass_dark');
  FButtonImages.Add('browse_light', 'file-magnifying-glass_light');

  FBrowseButton := TSimpleUIButton.Create(Self);
  FBrowseButton.Name := 'btnBrowse';
  FBrowseButton.Parent := pnlGeneral;
  FBrowseButton.Anchors := [akTop, akRight];
  FBrowseButton.Caption := 'Browse...';
  FBrowseButton.Images := FButtonImages;
  FBrowseButton.ImageName := 'browse_light';
  FBrowseButton.ParentFont := True;
  FBrowseButton.TabOrder := 1;
  nbRecentItems.TabOrder := 2;

  FCancelButton := TSimpleUIButton.Create(Self);
  FCancelButton.Name := 'btnCancel';
  FCancelButton.Parent := pnFooter;
  FCancelButton.Anchors := [akTop, akRight];
  FCancelButton.Cancel := True;
  FCancelButton.Caption := 'Cancel';
  FCancelButton.ModalResult := mrCancel;
  FCancelButton.ParentFont := True;
  FCancelButton.TabOrder := 0;

  FSaveButton := TSimpleUIButton.Create(Self);
  FSaveButton.Name := 'btnSave';
  FSaveButton.Parent := pnFooter;
  FSaveButton.Anchors := [akTop, akRight];
  FSaveButton.Caption := 'Save';
  FSaveButton.Default := True;
  FSaveButton.ModalResult := mrOk;
  FSaveButton.OnClick := btnSaveClick;
  FSaveButton.ParentFont := True;
  FSaveButton.TabOrder := 1;
  UpdateSettingsLayout;
end;

procedure TFrmSettings.UpdateSettingsLayout;
begin
  if not Assigned(FSaveButton) then
    Exit;
  // Native and styled title bars reserve different client heights. Keep the
  // complete Appearance panel above the card's bottom inset in either style.
  var LRequiredHeight := pnlAppearance.BoundsRect.Bottom + pnContent.Padding.Bottom;
  if pnContent.ClientHeight < LRequiredHeight then
    ClientHeight := ClientHeight + LRequiredHeight - pnContent.ClientHeight;
  // Use the actual scaled panel bounds, not stale designer anchor distances.
  pbCard.SetBounds(0, 0, pnContent.ClientWidth, pnContent.ClientHeight);
  pbInputBorders.SetBounds(0, 0, pnlGeneral.ClientWidth, pnlGeneral.ClientHeight);
  // Derive the edit width from the scaled panel to avoid cumulative rounding
  // pushing Browse beyond the right edge at fractional display scales.
  edTDumpPath.Width := Max(1, pnlGeneral.ClientWidth - edTDumpPath.Left -
    ScaleValue(cSettingsInputPaddingX) - ScaleValue(8) - ScaleValue(87));
  var LPathRect := InputBorderRect(edTDumpPath);
  var LButtonHeight := ScaleValue(25);
  FBrowseButton.SetBounds(LPathRect.Right + ScaleValue(8),
    LPathRect.Top + (LPathRect.Height - LButtonHeight) div 2,
    ScaleValue(87), LButtonHeight);
  var LButtonWidth := ScaleValue(80);
  var LRightMargin := ScaleValue(22);
  var LButtonGap := ScaleValue(6);
  var LButtonTop := ScaleValue(12);
  FCancelButton.SetBounds(pnFooter.ClientWidth - LRightMargin -
    (LButtonWidth * 2) - LButtonGap, LButtonTop, LButtonWidth, LButtonHeight);
  FSaveButton.SetBounds(pnFooter.ClientWidth - LRightMargin - LButtonWidth,
    LButtonTop, LButtonWidth, LButtonHeight);
  FButtonImages.SetSize(ScaleValue(16), ScaleValue(16));
  ConfigureThemeOptions;
  pbCard.Invalidate;
  pbInputBorders.Invalidate;
end;

procedure TFrmSettings.CreateSettingsTabs;
begin
  TitleBarPanel1.Height := ScaleValue(cSettingsTitleBarHeight);
  {
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
  }
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
  UpdateSettingsLayout;
end;

constructor TFrmSettings.Create(AOwner: TComponent);
begin
  inherited;
  pbCard.SendToBack;
  pbInputBorders.SendToBack;
  Font.Name := TExplorerTheme.FontName;
  LoadSettings;
  ControlList1.OnAfterDrawItem := ControlList1AfterDrawItem;
  ControlList1.OnChange := ControlList1Change;
  CreateSettingsButtons;
  CreateSettingsTabs;
  ApplyTheme;
end;

procedure TFrmSettings.FormShow(Sender: TObject);
begin
  UpdateSettingsLayout;
  ApplyTheme;
  edTDumpPath.SetFocus;
  edTDumpPath.SelStart := Length(edTDumpPath.Text);
  edTDumpPath.SelLength := 0;
end;

procedure TFrmSettings.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;
  if Assigned(FSaveButton) then
  begin
    UpdateSettingsLayout;
    ApplyTheme;
  end;
end;

procedure TFrmSettings.ScaleForPPI(NewPPI: Integer);
begin
  inherited;
  if Assigned(FSaveButton) then
  begin
    UpdateSettingsLayout;
    ApplyTheme;
  end;
end;

procedure TFrmSettings.DoAfterMonitorDpiChanged(OldDPI, NewDPI: Integer);
begin
  inherited;
  UpdateSettingsLayout;
  ApplyTheme;
end;

initialization

finalization
  TSettings.FInstance.Free;

end.
