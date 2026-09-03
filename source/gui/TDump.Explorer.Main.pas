//**************************************************************************************************
//
// Unit TDump.Explorer.Main
//
// Main-window input queue, TDUMP execution, and document-tab orchestration
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
unit TDump.Explorer.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Math,
  System.UITypes,
  System.Diagnostics, System.Generics.Collections, System.IOUtils, System.StrUtils,
  System.Threading,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Winapi.ShellAPI, TDump.Explorer.Finder,
  TDump.Explorer.Parser, TDump.Explorer.Phosphor.Font, TDump.Explorer.Runner,
  TDump.Explorer.TextSource, TDump.Explorer.Settings, TDump.Explorer.About,
  TDump.Explorer.Frame, Vcl.ComCtrls, TDump.Explorer.LogControl, Vcl.ExtCtrls,
  Vcl.TitleBarCtrls, Vcl.WinXPanels, Vcl.VirtualImageList,
  TDump.Explorer.Tabs, TDump.Explorer.PopupMenu, TDump.Explorer.UI,
  Vcl.AppEvnts;

type
  TAnalysisKind = (akBinary, akReport);

  TAnalysisRequest = class
  public
    FileName: string;
    Kind: TAnalysisKind;
    ParsingStarted: Boolean;
    ReloadRequested: Boolean;
    Discarded: Boolean;
    ActivateTabWhenComplete: Boolean;
  end;

const
  cWMAnalysisProgress = WM_APP + $241;
  cWMAnalysisCompleted = WM_APP + $242;

type
  TFrmMain = class(TForm)
    LogControl1: TLogControl;
    Splitter1: TSplitter;
    TitleBarPanel1: TTitleBarPanel;
    CardPanel1: TCardPanel;
    ProgressBar1: TProgressBar;
    ApplicationEvents1: TApplicationEvents;
    procedure FormShow(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure FormCreate(Sender: TObject);
  private
    FAnalysisId: Integer;
    FAnalysisTask: ITask;
    FActiveRequest: TAnalysisRequest;
    FClosing: Boolean;
    FTDumpAvailable: Boolean;
    FTDumpToolPath: string;
    FTDumpToolKind: TDumpToolKind;
    FPendingFiles: TQueue<TAnalysisRequest>;
    FPhosphorIcon: TPhosphorIcon;
    FEmptyStateHost: TPanel;
    FEmptyStateDropZone: TEmptyStateDropZone;
    FEmptyStateLayout: TGridPanel;
    FEmptyStateIconHost: TGridPanel;
    FEmptyStateTitle: TLabel;
    FEmptyStateMessage: TLabel;
    FEmptyStateHint: TLabel;
    FTabs: TExplorerTabStrip;
    FTabImages: TVirtualImageList;
    FExplorerPopupMenu: TExplorerPopupMenuForm;
    FExplorerPopupImages: TVirtualImageList;
    FRecentFilesPopupMenu: TExplorerPopupMenuForm;
    FRecentFilesPopupFiles: TStringList;
    FDocumentStagingPanel: TCardPanel;
    FPendingDocumentCards: TList<TCard>;
    FPendingActivationCard: TCard;
    FDeferredDocumentCard: TCard;
    FProgressTotalFiles: Integer;
    FProgressCompletedFiles: Integer;
    FCurrentFileProgress: Integer;
    FRestoreAlphaBlend: Boolean;
    FRestoringPreviousSession: Boolean;
    procedure SyncActiveTheme;
    procedure ToggleActiveTheme;
    procedure ApplyTheme;
    procedure ApplyExplorerPopupMenuTheme;
    procedure ApplyEmptyStateTheme;
    procedure AddAnalysisProgressItem;
    procedure AddRecentFile(const AFileName: string);
    procedure AddOpenDocumentFilesToRecentItems;
    procedure SaveApplicationSession;
    procedure RestorePreviousSessionTabs;
    procedure RestoreWindowPlacement;
    procedure AdvanceAnalysisProgress;
    procedure BeginAnalysis(ARequest: TAnalysisRequest);
    procedure CardsChanged(Sender: TObject; PrevCard, NextCard: TCard);
    procedure CheckTDumpAvailability;
    function EnsureTDumpAvailable: Boolean;
    procedure CompleteAnalysis(AAnalysisId: Integer; const ASummary: string;
      ASucceeded: Boolean; AFileSize, ATotalMilliseconds,
      AExecutionMilliseconds, AParsingMilliseconds: Int64;
      AReportLines, ATDumpExitCode, ADiagnosticCount: Integer;
      const ATDumpParameters: string; ADocument: TDumpDocument);
    procedure CompleteAnalysisProgress;
    procedure CreateDocumentTab(const AFileName, ASummary: string;
      var ADocument: TDumpDocument);
    procedure AddPendingDocumentTabs;
    procedure AttachPendingDocumentCards;
    procedure ActivateDeferredDocumentTab;
    procedure DrainAnalysisMessages;
    function HasPendingAnalysis: Boolean;
    function IsPendingDocumentCard(ACard: TCard): Boolean;
    function IsDocumentOpen(const AFileName: string): Boolean;
    function CreateAnalysisRequest(const AFileName: string;
      AKind: TAnalysisKind; AActivateTabWhenComplete: Boolean): TAnalysisRequest;
    procedure CreateTabs;
    procedure CreateEmptyState;
    function DocumentTabImageName(const AFileName: string): System.UITypes.TImageName;
    function IsTextFile(const AFileName: string): Boolean;
    function ProcessDroppedFile(const AFileName: string;
      AActivateTabWhenComplete: Boolean = False): Boolean;
    function CanAutoActivateInitialDocument: Boolean;
    procedure RemoveDocumentCard(ACard: TCard; ADeleteTab: Boolean);
    procedure ResetAnalysisProgress;
    procedure SetAnalysisProgress(ACompletedLines, ATotalLines: Integer);
    procedure FinalizePendingDocumentTabs;
    procedure SplitterPaint(Sender: TObject);
    procedure StartNextAnalysis;
    procedure PopupMenuAboutClick(Sender: TObject);
    procedure PopupMenuChangeThemeClick(Sender: TObject);
    procedure ExplorerPopupMenuItemClick(Sender: TObject; AItemIndex: Integer);
    procedure InitializeExplorerPopupMenuImages;
    procedure PopulateExplorerPopupMenu;
    procedure PopulateRecentFilesPopupMenu;
    procedure DrawRecentFileIcon(Sender: TObject; AIndex: Integer;
      ACanvas: TCanvas; const ARect: TRect; AColor: TColor);
    procedure PopupMenuSettingsClick(Sender: TObject);
    procedure RecentFilesPopupMenuItemClick(Sender: TObject;
      AItemIndex: Integer);
    procedure RecentFilesPopupMenuShortcut(Sender: TObject; AShortcut: Char);
    function RecentFileShortcutCaption(AIndex: Integer): string;
    function RecentFileShortcutIndex(AShortcut: Char): Integer;
    procedure TabsAddButtonClick(Sender: TObject);
    procedure TabsAfterPaintBackground(ACanvas: TCanvas;
      const ARect: TRect);
    procedure TabsBackgroundMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TabsBackgroundDblClick(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TabsChanged(Sender: TObject; ANewIndex: Integer);
    procedure TabsCustomButtonDraw(Sender: TObject;
      AButton: TExplorerTabCustomButton; ACanvas: TCanvas; const ARect,
      AGlyphRect: TRect; AState: TExplorerTabButtonDrawState;
      AGlyphColor: TColor; var AHandled: Boolean);
    procedure TabsCustomLeftButtonClick(Sender: TObject);
    procedure TabsCustomRightButtonClick(Sender: TObject);
    procedure UpdateOverallProgress;
    procedure UpdateEmptyState;
    procedure TabsClosing(Sender: TObject; AIndex: Integer;
      var ACanClose: Boolean);
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure WMAnalysisCompleted(var AMessage: TMessage);
      message cWMAnalysisCompleted;
    procedure WMAnalysisProgress(var AMessage: TMessage);
      message cWMAnalysisProgress;
    procedure WMSettingsChanged(var AMessage: TMessage);  message cWmTDumpSettingsChanged;
    procedure WMDropFiles(var AMessage: TWMDropFiles); message WM_DROPFILES;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure InitializeTabImages;
    procedure OpenInputFile(const AFileName: string;
      AActivateTabWhenComplete: Boolean);
  end;

var
  FrmMain: TFrmMain;

implementation

uses
  TDump.Explorer.Utils, TDump.Explorer.Resources,
  Vcl.GraphUtil, Vcl.Menus, Vcl.Themes;

{$R *.dfm}

const
  cTextProbeSize = 8192;
  cTitleBarHeight = 40;
  cTitleBarButtonMargin = 150;
  cTabIconSize = 16;
  cCaptionFontSize = 11;

type
  TAnalysisProgressUpdate = class
  public
    AnalysisId: Integer;
    Phase: TDumpParserProgressPhase;
    CompletedLines: Integer;
    TotalLines: Integer;
  end;

  TAnalysisCompletion = class
  public
    AnalysisId: Integer;
    Succeeded: Boolean;
    Summary: string;
    FileSize: Int64;
    TotalMilliseconds: Int64;
    ExecutionMilliseconds: Int64;
    ParsingMilliseconds: Int64;
    ReportLines: Integer;
    TDumpExitCode: Integer;
    DiagnosticCount: Integer;
    TDumpParameters: string;
    Document: TDumpDocument;
    destructor Destroy; override;
  end;

destructor TAnalysisCompletion.Destroy;
begin
  Document.Free;
  inherited;
end;

procedure CheckCurrentTaskCancellation;
begin
  var LTask := TTask.CurrentTask;
  if LTask <> nil then
    LTask.CheckCanceled;
end;

function IsCurrentTaskCancellationRequested: Boolean;
begin
  try
    CheckCurrentTaskCancellation;
    Result := False;
  except
    on EOperationCancelled do
      Result := True;
  end;
end;

procedure PostAnalysisProgress(AWindowHandle: HWND; AAnalysisId: Integer;
  APhase: TDumpParserProgressPhase; ACompletedLines, ATotalLines: Integer);
begin
  var LUpdate := TAnalysisProgressUpdate.Create;
  LUpdate.AnalysisId := AAnalysisId;
  LUpdate.Phase := APhase;
  LUpdate.CompletedLines := ACompletedLines;
  LUpdate.TotalLines := ATotalLines;
  if not PostMessage(AWindowHandle, cWMAnalysisProgress, 0,
    LPARAM(LUpdate)) then
    LUpdate.Free;
end;

procedure PostAnalysisCompletion(AWindowHandle: HWND; AAnalysisId: Integer;
  ASucceeded: Boolean; const ASummary: string; AFileSize,
  ATotalMilliseconds, AExecutionMilliseconds, AParsingMilliseconds: Int64;
  AReportLines, ATDumpExitCode, ADiagnosticCount: Integer;
  const ATDumpParameters: string; ADocument: TDumpDocument);
begin
  var LCompletion := TAnalysisCompletion.Create;
  LCompletion.AnalysisId := AAnalysisId;
  LCompletion.Succeeded := ASucceeded;
  LCompletion.Summary := ASummary;
  LCompletion.FileSize := AFileSize;
  LCompletion.TotalMilliseconds := ATotalMilliseconds;
  LCompletion.ExecutionMilliseconds := AExecutionMilliseconds;
  LCompletion.ParsingMilliseconds := AParsingMilliseconds;
  LCompletion.ReportLines := AReportLines;
  LCompletion.TDumpExitCode := ATDumpExitCode;
  LCompletion.DiagnosticCount := ADiagnosticCount;
  LCompletion.TDumpParameters := ATDumpParameters;
  LCompletion.Document := ADocument;
  if not PostMessage(AWindowHandle, cWMAnalysisCompleted, 0,
    LPARAM(LCompletion)) then
    LCompletion.Free;
end;

function BuildBinaryAnalysis(const AFileName, AToolPath: string;
  AToolKind: TDumpToolKind; AWindowHandle: HWND; AAnalysisId: Integer;
  out AExecutionMilliseconds,
  AParsingMilliseconds: Int64;
  out AReportLines, ATDumpExitCode, ADiagnosticCount: Integer;
  out ATDumpParameters: string; out ADocument: TDumpDocument): string;
begin
  AExecutionMilliseconds := 0;
  AParsingMilliseconds := 0;
  AReportLines := 0;
  ATDumpExitCode := 0;
  ADiagnosticCount := 0;
  ATDumpParameters := '';
  ADocument := nil;
  if (AToolPath = '') or not FileExists(AToolPath) then
    raise Exception.Create('No installed TDUMP or TDUMP64 executable was found.');

  var LRunner := TDumpRunner.Create;
  try
    LRunner.OnCancellationCheck := IsCurrentTaskCancellationRequested;
    LRunner.OnProgress :=
      procedure(APhase: TDumpParserProgressPhase; ACompletedLines,
        ATotalLines: Integer)
      begin
        PostAnalysisProgress(AWindowHandle, AAnalysisId, APhase,
          ACompletedLines, ATotalLines);
      end;
    var LRun := LRunner.RunAndParse(AFileName, AToolPath, AToolKind);
    try
      AExecutionMilliseconds := LRun.ExecutionMilliseconds;
      AParsingMilliseconds := LRun.ParsingMilliseconds;
      AReportLines := LRun.Document.Lines.Count;
      ATDumpExitCode := LRun.ExitCode;
      ADiagnosticCount := LRun.Document.Diagnostics.Count;
      ATDumpParameters := LRun.Options;
      Result := BuildDocumentSummary(Format('TDUMP analysis (exit code %d)',
        [LRun.ExitCode]), LRun.Document, LRun.Options);
      ADocument := LRun.Document;
      LRun.Document := nil;
    finally
      LRun.Free;
    end;
  finally
    LRunner.Free;
  end;
end;

function BuildReportAnalysis(const AFileName: string; AWindowHandle: HWND;
  AAnalysisId: Integer; out AExecutionMilliseconds,
  AParsingMilliseconds: Int64;
  out AReportLines, ATDumpExitCode, ADiagnosticCount: Integer;
  out ATDumpParameters: string; out ADocument: TDumpDocument): string;
begin
  AExecutionMilliseconds := 0;
  AParsingMilliseconds := 0;
  AReportLines := 0;
  ATDumpExitCode := 0;
  ADiagnosticCount := 0;
  ATDumpParameters := '';
  ADocument := nil;
  var LLastPhase := ppPreparing;
  var LLastCompletedLines := 0;
  var LLastTotalLines := 0;
  var LRunner := TDumpRunner.Create;
  try
    LRunner.OnCancellationCheck := IsCurrentTaskCancellationRequested;
    LRunner.OnProgress :=
      procedure(APhase: TDumpParserProgressPhase; ACompletedLines,
        ATotalLines: Integer)
      begin
        LLastPhase := APhase;
        LLastCompletedLines := ACompletedLines;
        LLastTotalLines := ATotalLines;
        PostAnalysisProgress(AWindowHandle, AAnalysisId, APhase,
          ACompletedLines, ATotalLines);
      end;
    try
      var LRun := LRunner.ParseReport(AFileName);
      try
        AExecutionMilliseconds := LRun.ExecutionMilliseconds;
        AParsingMilliseconds := LRun.ParsingMilliseconds;
        AReportLines := LRun.Document.Lines.Count;
        ATDumpExitCode := LRun.ExitCode;
        ADiagnosticCount := LRun.Document.Diagnostics.Count;
        ATDumpParameters := LRun.Options;
        Result := BuildDocumentSummary('TDUMP report parsed', LRun.Document);
        ADocument := LRun.Document;
        LRun.Document := nil;
      finally
        LRun.Free;
      end;
    except
      on LException: Exception do
        raise Exception.CreateFmt('%s: %s (parser phase %s, line %d of %d)',
          [LException.ClassName, LException.Message,
            ParserProgressPhaseName(LLastPhase), LLastCompletedLines,
            LLastTotalLines]);
    end;
  finally
    LRunner.Free;
  end;
end;

procedure TFrmMain.ApplyTheme;
begin
  EnableImmersiveDarkMode(not IsLightThemeActive);

  var LTheme := TExplorerTheme.ActiveTheme;
  var LPalette := ExplorerTabPalette(LTheme);
  Color := LTheme.BackgroundColor;
  CardPanel1.Color := LTheme.BackgroundColor;
  LogControl1.ApplyTheme;
  Splitter1.Invalidate;
  FTabs.Palette := LPalette;
  FTabs.BackgroundGradientDirection := etgdVertical;
  FTabs.TabGradientDirection := etgdVertical;
  for var LIndex := 0 to Min(FTabs.Items.Count, CardPanel1.CardCount) - 1 do
    FTabs.Items[LIndex].ImageName := DocumentTabImageName(CardPanel1.Cards[LIndex].Hint);

  CustomTitleBar.SystemHeight := False;
  CustomTitleBar.Height := ScaleValue(cTitleBarHeight);
  CustomTitleBar.SystemColors := False;
  CustomTitleBar.StyleColors := False;
  CustomTitleBar.SystemButtons := False;
  CustomTitleBar.ShowCaption := True;
  CustomTitleBar.ShowIcon := True;
  CustomTitleBar.Enabled := True;
  CustomTitleBar.BackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ForegroundColor := LTheme.TextColor;
  CustomTitleBar.InactiveBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.InactiveForegroundColor := LPalette.InactiveText;
  CustomTitleBar.ButtonBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ButtonForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonHoverBackgroundColor := LPalette.HoverTop;
  CustomTitleBar.ButtonHoverForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonPressedBackgroundColor := LTheme.SelectionColor;
  CustomTitleBar.ButtonPressedForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonInactiveBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ButtonInactiveForegroundColor := LPalette.InactiveText;

  TitleBarPanel1.AlphaValue := 255;
  TitleBarPanel1.Invalidate;
  ApplyEmptyStateTheme;
  ApplyExplorerPopupMenuTheme;
end;

procedure TFrmMain.ApplyExplorerPopupMenuTheme;
  procedure ApplyTo(APopupMenu: TExplorerPopupMenuForm);
  begin
    if not Assigned(APopupMenu) then
      Exit;

    var LTheme := TExplorerTheme.ActiveTheme;
    APopupMenu.Color := LTheme.BackgroundColor;
    APopupMenu.MenuItems.ControlList1.BorderStyle := bsNone;
    APopupMenu.MenuItems.Color := LTheme.BackgroundColor;
    APopupMenu.MenuItems.HighlightColor := ColorBlendRGB(
      LTheme.SelectionColor, LTheme.BackgroundColor, 0.95);
  end;
begin
  ApplyTo(FExplorerPopupMenu);
  ApplyTo(FRecentFilesPopupMenu);
end;

procedure TFrmMain.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
begin
  if FRestoreAlphaBlend then
  begin
    FRestoreAlphaBlend := False;
    AlphaBlend := False;
  end;
  if not FClosing then
    ActivateDeferredDocumentTab;
end;

procedure TFrmMain.ApplyEmptyStateTheme;
begin
  if not Assigned(FEmptyStateHost) then
    Exit;

  var LTheme := TExplorerTheme.ActiveTheme;
  FEmptyStateHost.Color := LTheme.BackgroundColor;
  FEmptyStateDropZone.Color := LTheme.BackgroundColor;
  FEmptyStateDropZone.BorderColor := ColorBlendRGB(LTheme.SelectionColor, LTheme.BackgroundColor, 0.65);
  FEmptyStateLayout.Color := LTheme.BackgroundColor;
  FEmptyStateIconHost.Color := LTheme.BackgroundColor;
  FPhosphorIcon.Color := LTheme.BackgroundColor;
  FPhosphorIcon.IconColor := LTheme.SelectionColor;
  FEmptyStateTitle.Font.Color := LTheme.TextColor;
  FEmptyStateMessage.Font.Color := LTheme.InactiveText;
  FEmptyStateHint.Font.Color := LTheme.InactiveText;
end;

procedure TFrmMain.CardsChanged(Sender: TObject; PrevCard, NextCard: TCard);
begin
  if not Assigned(FTabs) then
    Exit;
  if IsPendingDocumentCard(NextCard) then
    Exit;
  if Assigned(NextCard) then
    FTabs.ActiveIndex := NextCard.CardIndex
  else
    FTabs.ActiveIndex := -1;
end;

procedure TFrmMain.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  if Assigned(FTabs) then
    ApplyTheme;
end;

procedure TFrmMain.SyncActiveTheme;
begin
  if (TSettings.Instance.ThemeOption = toLight) and not IsLightThemeActive then
    ToggleActiveTheme
  else if (TSettings.Instance.ThemeOption = toDark) and IsLightThemeActive then
    ToggleActiveTheme
  else if (TSettings.Instance.ThemeOption = toSystem) then
  begin
     if IsWindowsLightTheme <> IsLightThemeActive then
       ToggleActiveTheme;
  end;
end;

procedure TFrmMain.WMSettingsChanged(var AMessage: TMessage);
begin
  SyncActiveTheme;
  CheckTDumpAvailability;
end;

procedure TFrmMain.CreateTabs;
begin
  FTabImages := TVirtualImageList.Create(Self);
  FTabImages.Width := cTabIconSize;
  FTabImages.Height := cTabIconSize;

  FTabs := TExplorerTabStrip.Create(Self);
  FTabs.Parent := TitleBarPanel1;
  FTabs.Images := FTabImages;
  FTabs.Margins.Left := 0;
  FTabs.Margins.Top := 0;
  FTabs.Margins.Right := ScaleValue(cTitleBarButtonMargin);
  FTabs.Margins.Bottom := 0;
  FTabs.AlignWithMargins := True;
  FTabs.Align := alBottom;
  FTabs.TabHeight := cTitleBarHeight;
  FTabs.Font.Assign(Font);
  FTabs.ShowAddButton := True;
  FTabs.ShowCustomLeftButton := True;
  FTabs.ShowCustomRightButton := True;
  FTabs.CustomLeftButtonHint := 'Explorer menu';
  FTabs.CustomRightButtonHint := 'Recent files';
  FTabs.OnAddButtonClick := TabsAddButtonClick;
  FTabs.OnCustomButtonDraw := TabsCustomButtonDraw;
  FTabs.OnCustomLeftButtonClick := TabsCustomLeftButtonClick;
  FTabs.OnCustomRightButtonClick := TabsCustomRightButtonClick;
  FTabs.OnChange := TabsChanged;
  FTabs.OnCloseTab := TabsClosing;
  FTabs.OnBackgroundMouseDown := TabsBackgroundMouseDown;
  FTabs.OnBackgroundDblClick := TabsBackgroundDblClick;
  FTabs.OnAfterPaintBackground := TabsAfterPaintBackground;
  FTabs.SendToBack;

  TitleBarPanel1.Height := ScaleValue(cTitleBarHeight);
  CardPanel1.Caption := '';
  CardPanel1.OnCardChange := CardsChanged;
  ApplyTheme;
end;

procedure TFrmMain.CreateEmptyState;
var
  LIconColumn: TColumnItem;
  LIconRow: TRowItem;
  LColumn: TColumnItem;
  LRow: TRowItem;
begin
  FEmptyStateHost := TPanel.Create(Self);
  FEmptyStateHost.Parent := Self;
  FEmptyStateHost.Align := alClient;
  FEmptyStateHost.BevelOuter := bvNone;
  FEmptyStateHost.ParentBackground := False;
  FEmptyStateHost.StyleElements := FEmptyStateHost.StyleElements - [seClient];
  FEmptyStateHost.Visible := False;

  FEmptyStateDropZone := TEmptyStateDropZone.Create(Self);
  FEmptyStateDropZone.Parent := FEmptyStateHost;
  FEmptyStateDropZone.AlignWithMargins := True;
  FEmptyStateDropZone.Margins.Left := ScaleValue(144);
  FEmptyStateDropZone.Margins.Top := ScaleValue(96);
  FEmptyStateDropZone.Margins.Right := ScaleValue(144);
  FEmptyStateDropZone.Margins.Bottom := ScaleValue(56);
  FEmptyStateDropZone.Align := alClient;
  FEmptyStateDropZone.StyleElements := FEmptyStateDropZone.StyleElements - [seClient];

  FEmptyStateLayout := TGridPanel.Create(Self);
  FEmptyStateLayout.Parent := FEmptyStateDropZone;
  FEmptyStateLayout.AlignWithMargins := True;
  FEmptyStateLayout.Margins.Left := ScaleValue(2);
  FEmptyStateLayout.Margins.Top := ScaleValue(2);
  FEmptyStateLayout.Margins.Right := ScaleValue(2);
  FEmptyStateLayout.Margins.Bottom := ScaleValue(2);
  FEmptyStateLayout.Align := alClient;
  FEmptyStateLayout.BevelOuter := bvNone;
  FEmptyStateLayout.ParentBackground := False;
  FEmptyStateLayout.StyleElements := FEmptyStateLayout.StyleElements - [seClient];
  FEmptyStateLayout.ColumnCollection.Clear;
  LColumn := FEmptyStateLayout.ColumnCollection.Add;
  LColumn.SizeStyle := ssPercent;
  LColumn.Value := 100;
  FEmptyStateLayout.RowCollection.Clear;

  LRow := FEmptyStateLayout.RowCollection.Add;
  LRow.SizeStyle := ssPercent;
  LRow.Value := 31;
  LRow := FEmptyStateLayout.RowCollection.Add;
  LRow.SizeStyle := ssPercent;
  LRow.Value := 25;
  LRow := FEmptyStateLayout.RowCollection.Add;
  LRow.SizeStyle := ssPercent;
  LRow.Value := 3;
  LRow := FEmptyStateLayout.RowCollection.Add;
  LRow.SizeStyle := ssPercent;
  LRow.Value := 9;
  LRow := FEmptyStateLayout.RowCollection.Add;
  LRow.SizeStyle := ssPercent;
  LRow.Value := 3;
  LRow := FEmptyStateLayout.RowCollection.Add;
  LRow.SizeStyle := ssPercent;
  LRow.Value := 7;
  LRow := FEmptyStateLayout.RowCollection.Add;
  LRow.SizeStyle := ssPercent;
  LRow.Value := 2;
  LRow := FEmptyStateLayout.RowCollection.Add;
  LRow.SizeStyle := ssPercent;
  LRow.Value := 6;
  LRow := FEmptyStateLayout.RowCollection.Add;
  LRow.SizeStyle := ssPercent;
  LRow.Value := 14;

  FEmptyStateIconHost := TGridPanel.Create(Self);
  FEmptyStateIconHost.Align := alClient;
  FEmptyStateIconHost.BevelOuter := bvNone;
  FEmptyStateIconHost.ParentBackground := False;
  FEmptyStateIconHost.StyleElements := FEmptyStateIconHost.StyleElements - [seClient];
  FEmptyStateIconHost.ColumnCollection.Clear;
  LIconColumn := FEmptyStateIconHost.ColumnCollection.Add;
  LIconColumn.SizeStyle := ssPercent;
  LIconColumn.Value := 40;
  LIconColumn := FEmptyStateIconHost.ColumnCollection.Add;
  LIconColumn.SizeStyle := ssPercent;
  LIconColumn.Value := 20;
  LIconColumn := FEmptyStateIconHost.ColumnCollection.Add;
  LIconColumn.SizeStyle := ssPercent;
  LIconColumn.Value := 40;
  FEmptyStateIconHost.RowCollection.Clear;
  LIconRow := FEmptyStateIconHost.RowCollection.Add;
  LIconRow.SizeStyle := ssPercent;
  LIconRow.Value := 100;
  FEmptyStateLayout.ControlCollection.AddControl(FEmptyStateIconHost, 0, 1);

  FPhosphorIcon := TPhosphorIcon.Create(Self);
  FPhosphorIcon.Align := alClient;
  FPhosphorIcon.StyleElements := FPhosphorIcon.StyleElements - [seClient];
  FPhosphorIcon.IconCode := cPhBinary;
  FPhosphorIcon.Weight := pfwRegular;
  FEmptyStateIconHost.ControlCollection.AddControl(FPhosphorIcon, 1, 0);

  FEmptyStateTitle := TLabel.Create(Self);
  FEmptyStateTitle.Align := alClient;
  FEmptyStateTitle.AutoSize := False;
  FEmptyStateTitle.Alignment := taCenter;
  FEmptyStateTitle.Layout := tlCenter;
  FEmptyStateTitle.ParentFont := False;
  FEmptyStateTitle.StyleName := 'Windows';
  FEmptyStateTitle.Font.Assign(Font);
  FEmptyStateTitle.Font.Size := TExplorerTheme.FontSize + 4;
  FEmptyStateTitle.Font.Style := [fsBold];
  FEmptyStateTitle.Caption := 'Drag && drop a report or binary';
  FEmptyStateLayout.ControlCollection.AddControl(FEmptyStateTitle, 0, 3);

  FEmptyStateMessage := TLabel.Create(Self);
  FEmptyStateMessage.Align := alClient;
  FEmptyStateMessage.AutoSize := False;
  FEmptyStateMessage.Alignment := taCenter;
  FEmptyStateMessage.Layout := tlCenter;
  FEmptyStateMessage.ParentFont := False;
  FEmptyStateMessage.StyleName := 'Windows';
  FEmptyStateMessage.Font.Assign(Font);
  FEmptyStateMessage.Font.Size := TExplorerTheme.FontSize;
  FEmptyStateMessage.Caption :=
    'Open a .tdump report, DLL, EXE, BPL, or other supported binary to start exploring.';
  FEmptyStateLayout.ControlCollection.AddControl(FEmptyStateMessage, 0, 5);

  FEmptyStateHint := TLabel.Create(Self);
  FEmptyStateHint.Align := alClient;
  FEmptyStateHint.AutoSize := False;
  FEmptyStateHint.Alignment := taCenter;
  FEmptyStateHint.Layout := tlCenter;
  FEmptyStateHint.ParentFont := False;
  FEmptyStateHint.StyleName := 'Windows';
  FEmptyStateHint.Font.Assign(Font);
  FEmptyStateHint.Font.Size := TExplorerTheme.FontSize;
  FEmptyStateHint.Caption := 'You can also use the + button to open a file.';
  FEmptyStateLayout.ControlCollection.AddControl(FEmptyStateHint, 0, 7);

  ApplyEmptyStateTheme;
end;

function TFrmMain.DocumentTabImageName(
  const AFileName: string): System.UITypes.TImageName;
begin
  var LBaseName := ExplorerDocumentIconName(AFileName);
  if IsLightThemeActive then
    Result := LBaseName + '_light'
  else
    Result := LBaseName + '_dark';
end;

procedure TFrmMain.InitializeTabImages;
begin
  if not Assigned(DataModule1) or not Assigned(FTabImages) then
    Exit;
  FTabImages.Clear;
  FTabImages.ImageCollection := DataModule1.ImageCollection1;
  FTabImages.Add('binary_dark', 'binary_dark');
  FTabImages.Add('binary_light', 'binary_light');
  FTabImages.Add('file-text_dark', 'file-text_dark');
  FTabImages.Add('file-text_light', 'file-text_light');
end;

procedure TFrmMain.RemoveDocumentCard(ACard: TCard; ADeleteTab: Boolean);
begin
  if not Assigned(ACard) then
    Exit;
  CardPanel1.LockDrawing;
  try
    FPendingDocumentCards.Remove(ACard);
    if FDeferredDocumentCard = ACard then
      FDeferredDocumentCard := nil;
    var LCardIndex := ACard.CardIndex;
    var LActiveCard := CardPanel1.ActiveCard;
    ACard.Free;
    if Assigned(LActiveCard) and (LActiveCard <> ACard) then
      CardPanel1.ActiveCard := LActiveCard;
    if ADeleteTab and Assigned(FTabs) and
      (LCardIndex >= 0) and (LCardIndex < FTabs.Items.Count) then
      FTabs.DeleteTab(LCardIndex);
  finally
    CardPanel1.UnlockDrawing;
  end;
  UpdateEmptyState;
end;

procedure TFrmMain.PopupMenuSettingsClick(Sender: TObject);
begin
  var LSettingsForm := TFrmSettings.Create(Self);
  try
    LSettingsForm.ShowModal;
  finally
    LSettingsForm.Free;
  end;
end;


procedure TFrmMain.ToggleActiveTheme;
begin
  AlphaBlendValue := 0;
  AlphaBlend := True;
  try
    if IsLightThemeActive then
      TStyleManager.SetStyle('Glow')
    else
      TStyleManager.SetStyle('Windows');
  finally
    FRestoreAlphaBlend := True;
    UnlockDrawing;
  end;
end;

procedure TFrmMain.PopupMenuChangeThemeClick(Sender: TObject);
begin
  ToggleActiveTheme;
  if IsLightThemeActive and (TSettings.Instance.ThemeOption <> toLight) then
  begin
    TSettings.Instance.ThemeOption := toLight;
    TSettings.Instance.Save;
  end
  else if not IsLightThemeActive and (TSettings.Instance.ThemeOption <> toDark) then
  begin
    TSettings.Instance.ThemeOption := toDark;
    TSettings.Instance.Save;
  end;
end;

procedure TFrmMain.ExplorerPopupMenuItemClick(Sender: TObject;
  AItemIndex: Integer);
begin
  case AItemIndex of
    0: PopupMenuSettingsClick(Self);
    1: PopupMenuChangeThemeClick(Self);
    2: PopupMenuAboutClick(Self);
  end;
end;

procedure TFrmMain.InitializeExplorerPopupMenuImages;
begin
  if not Assigned(DataModule1) or not Assigned(FExplorerPopupImages) then
    Exit;

  FExplorerPopupImages.Clear;
  FExplorerPopupImages.Width := ScaleValue(24);
  FExplorerPopupImages.Height := ScaleValue(24);

  FExplorerPopupImages.ImageCollection := DataModule1.ImageCollection1;
  FExplorerPopupImages.Add('gear_dark', 'gear_dark');
  FExplorerPopupImages.Add('gear_light', 'gear_light');

  FExplorerPopupImages.Add('moon_dark', 'moon_dark');
  FExplorerPopupImages.Add('moon_light', 'moon_light');
  FExplorerPopupImages.Add('sun_dark', 'sun_dark');
  FExplorerPopupImages.Add('sun_light', 'sun_light');

  FExplorerPopupImages.Add('TDumpExplorer_dark', 'TDumpExplorer_dark');
  FExplorerPopupImages.Add('TDumpExplorer_light', 'TDumpExplorer_light');
end;

procedure TFrmMain.PopulateExplorerPopupMenu;
begin
  if not Assigned(FExplorerPopupMenu) then
    Exit;

  var LIconSuffix := '_dark';
  if IsLightThemeActive then
    LIconSuffix := '_light';

  var LMenuItems := FExplorerPopupMenu.MenuItems;
  LMenuItems.BeginUpdate;
  try
    LMenuItems.Clear;
    LMenuItems.Add('Settings...', 'gear' + LIconSuffix);

    if IsLightThemeActive  then
      LMenuItems.Add('Toggle to Dark Theme', 'moon_light')
    else
      LMenuItems.Add('Toggle to Light Theme', 'sun_dark');

    LMenuItems.Add('About TDump Explorer', 'TDumpExplorer' + LIconSuffix);
  finally
    LMenuItems.EndUpdate;
  end;
end;

procedure TFrmMain.PopulateRecentFilesPopupMenu;
begin
  if not Assigned(FRecentFilesPopupMenu) then
    Exit;

  var LInactiveItems := TList<Integer>.Create;
  try
    var LMenuItems := FRecentFilesPopupMenu.MenuItems;
    LMenuItems.BeginUpdate;
    try
      LMenuItems.ControlList1.ItemHeight := Round(32 * LMenuItems.ScaleFactor);
      LMenuItems.Clear;
      FRecentFilesPopupFiles.Clear;
      for var LIndex := 0 to TSettings.Instance.RecentItemCount - 1 do
      begin
        var LFileName := TSettings.Instance.RecentItem(LIndex);
        if IsDocumentOpen(LFileName) then
          Continue;
        var LVisibleIndex := FRecentFilesPopupFiles.Count;
        FRecentFilesPopupFiles.Add(LFileName);
        LMenuItems.Add(Format('%s  %s', [
          RecentFileShortcutCaption(LVisibleIndex), LFileName]),
          ExplorerDocumentIconName(LFileName));
        if not FileExists(LFileName) then
          LInactiveItems.Add(LVisibleIndex);
      end;
      if LMenuItems.Count = 0 then
      begin
        LMenuItems.Add('No recent files');
        LInactiveItems.Add(0);
      end;
    finally
      LMenuItems.EndUpdate;
    end;
    LMenuItems.SetInactiveItems(LInactiveItems.ToArray);
  finally
    LInactiveItems.Free;
  end;
end;

procedure TFrmMain.DrawRecentFileIcon(Sender: TObject; AIndex: Integer;
  ACanvas: TCanvas; const ARect: TRect; AColor: TColor);
begin
  if (AIndex < 0) or (AIndex >= FRecentFilesPopupFiles.Count) then
    Exit;
  DrawExplorerDocumentIcon(ACanvas, FRecentFilesPopupFiles[AIndex], ARect, AColor);
end;

procedure TFrmMain.RecentFilesPopupMenuItemClick(Sender: TObject;
  AItemIndex: Integer);
begin
  if (AItemIndex < 0) or
    (AItemIndex >= FRecentFilesPopupFiles.Count) then
    Exit;

  var LFileName := FRecentFilesPopupFiles[AItemIndex];
  if not FileExists(LFileName) then
  begin
    TSettings.Instance.RemoveRecentItem(LFileName);
    TSettings.Instance.Save;
    Exit;
  end;
  OpenInputFile(LFileName, True);
end;

function TFrmMain.RecentFileShortcutCaption(AIndex: Integer): string;
begin
  if AIndex < 9 then
    Exit((AIndex + 1).ToString);
  if AIndex < 35 then
    Exit(Chr(Ord('A') + AIndex - 9));
  Result := '';
end;

function TFrmMain.RecentFileShortcutIndex(AShortcut: Char): Integer;
begin
  AShortcut := UpCase(AShortcut);
  if CharInSet(AShortcut, ['1'..'9']) then
    Exit(Ord(AShortcut) - Ord('1'));
  if CharInSet(AShortcut, ['A'..'Z']) then
    Exit(9 + Ord(AShortcut) - Ord('A'));
  Result := -1;
end;

procedure TFrmMain.RecentFilesPopupMenuShortcut(Sender: TObject;
  AShortcut: Char);
begin
  var LIndex := RecentFileShortcutIndex(AShortcut);
  if (LIndex < 0) or (LIndex >= FRecentFilesPopupFiles.Count) then
    Exit;
  FRecentFilesPopupMenu.Hide;
  RecentFilesPopupMenuItemClick(Self, LIndex);
end;

procedure TFrmMain.PopupMenuAboutClick(Sender: TObject);
begin
  var LAboutForm := TFrmAbout.Create(Self);
  try
    LAboutForm.ShowModal;
  finally
    LAboutForm.Free;
  end;
end;

procedure TFrmMain.TabsAddButtonClick(Sender: TObject);
begin
  var LOpenDialog := TOpenDialog.Create(Self);
  try
    LOpenDialog.Title := 'Open executable or TDUMP report';
    LOpenDialog.Filter := 'Supported files|*.exe;*.dll;*.bpl;*.dcp;*.obj;*.lib;'
      + '*.tdump;*.txt|All files|*.*';
    LOpenDialog.Options := [ofAllowMultiSelect, ofFileMustExist,
      ofPathMustExist, ofEnableSizing];
    //CardPanel1.LockDrawing;
    try
      if LOpenDialog.Execute then
      begin
        // Multi-file opens retain the current tab.  With no document yet,
        // nominate only the first accepted item for activation.
        var LActivateNextAcceptedTab := (LOpenDialog.Files.Count = 1) or
          CanAutoActivateInitialDocument;
        for var LFileName in LOpenDialog.Files do
          if ProcessDroppedFile(LFileName, LActivateNextAcceptedTab) then
            LActivateNextAcceptedTab := False;
      end;
    finally
      //CardPanel1.UnlockDrawing;
    end;
  finally
    LOpenDialog.Free;
  end;
end;

procedure TFrmMain.TabsAfterPaintBackground(ACanvas: TCanvas;
  const ARect: TRect);
begin
  var LOriginalFont := TFont.Create;
  try
    LOriginalFont.Assign(ACanvas.Font);
    ACanvas.Font.Assign(Font);
    ACanvas.Font.Name := TExplorerTheme.FontName;
    ACanvas.Font.Height := -ScaleValue(cCaptionFontSize);
    ACanvas.Font.Style := [];
    ACanvas.Font.Color := FTabs.Palette.InactiveText;
    var LOldBackgroundMode := SetBkMode(ACanvas.Handle, TRANSPARENT);
    try
      var LTextRect := ARect;
      DrawText(ACanvas.Handle, PChar(Caption), -1, LTextRect,
        DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
        DT_NOPREFIX);
    finally
      SetBkMode(ACanvas.Handle, LOldBackgroundMode);
    end;
  finally
    ACanvas.Font.Assign(LOriginalFont);
    LOriginalFont.Free;
  end;
end;

procedure TFrmMain.TabsBackgroundMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  ReleaseCapture;
  SendMessage(Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
end;

procedure TFrmMain.TabsBackgroundDblClick(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  if WindowState = wsMaximized then
    WindowState := wsNormal
  else if biMaximize in BorderIcons then
    WindowState := wsMaximized;
end;

procedure TFrmMain.TabsChanged(Sender: TObject; ANewIndex: Integer);
begin
  if (ANewIndex >= 0) and (ANewIndex < CardPanel1.CardCount) and
    (CardPanel1.ActiveCardIndex <> ANewIndex) then
  begin
    CardPanel1.LockDrawing;
    try
      CardPanel1.Cards[ANewIndex].Visible := True;
      CardPanel1.ActiveCardIndex := ANewIndex;
    finally
      CardPanel1.UnLockDrawing;
    end;
  end;
end;

procedure TFrmMain.TabsCustomButtonDraw(Sender: TObject;
  AButton: TExplorerTabCustomButton; ACanvas: TCanvas; const ARect,
  AGlyphRect: TRect; AState: TExplorerTabButtonDrawState;
  AGlyphColor: TColor; var AHandled: Boolean);
begin
  AHandled := False;
  if AButton <> etcbRight then
    Exit;

  PhosphorFont.DrawIcon(ACanvas.Handle, cPhClockCounterClockwise,
    AGlyphRect, AGlyphColor, pfwRegular);
  AHandled := True;
end;

procedure TFrmMain.TabsCustomLeftButtonClick(Sender: TObject);
begin
  if FExplorerPopupMenu = nil then
  begin
    FExplorerPopupMenu := TExplorerPopupMenuForm.Create(Self);
    FExplorerPopupImages := TVirtualImageList.Create(Self);
    InitializeExplorerPopupMenuImages;
    FExplorerPopupMenu.MenuItems.Images := FExplorerPopupImages;
    FExplorerPopupMenu.OnItemClick := ExplorerPopupMenuItemClick;
  end;
  ApplyExplorerPopupMenuTheme;
  PopulateExplorerPopupMenu;
  FExplorerPopupMenu.ShowAt(Mouse.CursorPos);
end;

procedure TFrmMain.TabsCustomRightButtonClick(Sender: TObject);
begin
  if FRecentFilesPopupMenu = nil then
  begin
    FRecentFilesPopupMenu := TExplorerPopupMenuForm.Create(Self);
    FRecentFilesPopupMenu.MenuItems.OnDrawItemIcon := DrawRecentFileIcon;
    FRecentFilesPopupMenu.MenuItems.CustomIconSize := 24;
    FRecentFilesPopupMenu.OnItemClick := RecentFilesPopupMenuItemClick;
    FRecentFilesPopupMenu.OnShortcut := RecentFilesPopupMenuShortcut;
  end;
  ApplyExplorerPopupMenuTheme;
  PopulateRecentFilesPopupMenu;
  FRecentFilesPopupMenu.ShowAt(Mouse.CursorPos);
end;

procedure TFrmMain.TabsClosing(Sender: TObject; AIndex: Integer;
  var ACanClose: Boolean);
begin
  ACanClose := (AIndex >= 0) and (AIndex < CardPanel1.CardCount);
  if not ACanClose then
    Exit;
  AddRecentFile(CardPanel1.Cards[AIndex].Hint);
  RemoveDocumentCard(CardPanel1.Cards[AIndex], False);
end;

constructor TFrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Splitter1.OnPaint := SplitterPaint;
  FPendingFiles := TQueue<TAnalysisRequest>.Create;
  FPendingDocumentCards := TList<TCard>.Create;
  FRecentFilesPopupFiles := TStringList.Create;
  FDocumentStagingPanel := TCardPanel.Create(Self);
  FDocumentStagingPanel.Visible := False;
  FDocumentStagingPanel.SetBounds(-1, -1, 1, 1);
  FDocumentStagingPanel.Parent := Self;
  CreateTabs;
  CreateEmptyState;
  UpdateEmptyState;
  CompleteAnalysisProgress;
end;

procedure TFrmMain.SplitterPaint(Sender: TObject);
begin
  if not (Sender is TSplitter) then
    Exit;

  var LSplitter := TSplitter(Sender);
  DrawExplorerSplitter(LSplitter.Canvas, LSplitter.ClientRect,
    LSplitter.Align in [alLeft, alRight], ScaleFactor);
end;

procedure TFrmMain.CheckTDumpAvailability;
begin
  FTDumpAvailable := False;
  FTDumpToolPath := '';
  FTDumpToolKind := tkTDump32;
  var LConfiguredPath := Trim(TSettings.Instance.TDumpPath);
  if LConfiguredPath <> '' then
  begin
    LConfiguredPath := ExpandFileName(LConfiguredPath);
    if FileExists(LConfiguredPath) then
    begin
      FTDumpToolPath := LConfiguredPath;
      FTDumpToolKind := TDumpToolKindFromPath(FTDumpToolPath);
      FTDumpAvailable := True;
      if not SameText(TSettings.Instance.TDumpPath, FTDumpToolPath) then
      begin
        TSettings.Instance.TDumpPath := FTDumpToolPath;
        TSettings.Instance.Save;
      end;
      var LConfiguredMessage := 'TDUMP path from settings: ' +
        FTDumpToolPath;
      var LConfiguredVersion := GetTDumpVersion(FTDumpToolPath);
      if LConfiguredVersion <> '' then
        LConfiguredMessage := LConfiguredMessage + ' (version ' +
          LConfiguredVersion + ')';
      LogControl1.Add(LConfiguredMessage, letSuccess);
      Exit;
    end;
    LogControl1.Add('Configured TDUMP path is invalid: ' + LConfiguredPath +
      '. Searching for the best installed candidate...', letWarning);
  end
  else
    LogControl1.Add('TDUMP path is not configured. Searching for the best ' +
      'installed candidate...');
  try
    var LFinder := TDumpFinder.Create;
    try
      var LStudioVersion := '';
      FTDumpAvailable := LFinder.FindDefaultTool(FTDumpToolPath,
        LStudioVersion);
      if not FTDumpAvailable then
      begin
        LogControl1.Add('TDUMP was not found.', letError);
        Exit;
      end;
      FTDumpToolKind := TDumpToolKindFromPath(FTDumpToolPath);
      TSettings.Instance.TDumpPath := FTDumpToolPath;
      TSettings.Instance.Save;
      var LMessage := 'TDUMP path discovered and saved: ' + FTDumpToolPath;
      var LVersion := GetTDumpVersion(FTDumpToolPath);
      if LVersion <> '' then
        LMessage := LMessage + ' (version ' + LVersion + ')';
      if LStudioVersion <> '' then
        LMessage := LMessage + ' [RAD Studio ' + LStudioVersion + ']';
      LogControl1.Add(LMessage, letSuccess);
    finally
      LFinder.Free;
    end;
  except
    on LException: Exception do
      LogControl1.Add(Format('Unable to check TDUMP availability: %s',
        [LException.Message]), letError);
  end;
end;

function TFrmMain.EnsureTDumpAvailable: Boolean;
var
  LConfiguredPath: string;
begin
  LConfiguredPath := Trim(TSettings.Instance.TDumpPath);
  if (not FTDumpAvailable) or not SameText(FTDumpToolPath, LConfiguredPath) or
    not FileExists(LConfiguredPath) then
    CheckTDumpAvailability;
  Result := FTDumpAvailable and
    SameText(FTDumpToolPath, Trim(TSettings.Instance.TDumpPath)) and
    FileExists(TSettings.Instance.TDumpPath);
end;

procedure TFrmMain.BeginAnalysis(ARequest: TAnalysisRequest);
begin
  FActiveRequest := ARequest;  Inc(FAnalysisId);
  var LAnalysisId := FAnalysisId;
  var LInputFileName := ARequest.FileName;
  var LKind := ARequest.Kind;
  var LToolPath := TSettings.Instance.TDumpPath;
  var LToolKind := TDumpToolKindFromPath(LToolPath);
  var LWindowHandle := Handle;
  FCurrentFileProgress := 0;
  UpdateOverallProgress;
  LogControl1.Add('Running: ' + LInputFileName);
  FAnalysisTask := TTask.Run(
    procedure
    begin
      var LDocument: TDumpDocument := nil;
      var LFileSize: Int64 := 0;
      var LExecutionMilliseconds: Int64 := 0;
      var LParsingMilliseconds: Int64 := 0;
      var LReportLines := 0;
      var LTdumpExitCode := 0;
      var LDiagnosticCount := 0;
      var LTdumpParameters := '';
      var LTotalStopwatch := TStopwatch.StartNew;
      try
        var LSummary := '';
        LFileSize := TFile.GetSize(LInputFileName);
        case LKind of
          akBinary:
            LSummary := BuildBinaryAnalysis(LInputFileName, LToolPath,
              LToolKind, LWindowHandle, LAnalysisId, LExecutionMilliseconds,
              LParsingMilliseconds,
              LReportLines, LTdumpExitCode, LDiagnosticCount,
              LTdumpParameters, LDocument);
          akReport:
            LSummary := BuildReportAnalysis(LInputFileName, LWindowHandle,
              LAnalysisId, LExecutionMilliseconds, LParsingMilliseconds,
              LReportLines, LTdumpExitCode, LDiagnosticCount,
              LTdumpParameters, LDocument);
        end;
        LTotalStopwatch.Stop;
        PostAnalysisCompletion(LWindowHandle, LAnalysisId, True, LSummary,
          LFileSize, LTotalStopwatch.ElapsedMilliseconds,
          LExecutionMilliseconds, LParsingMilliseconds, LReportLines,
          LTdumpExitCode, LDiagnosticCount, LTdumpParameters, LDocument);
        LDocument := nil;
      except
        on LException: Exception do
        begin
          LTotalStopwatch.Stop;
          LDocument.Free;
          PostAnalysisCompletion(LWindowHandle, LAnalysisId, False,
            Format('Unable to process %s'#13#10'%s: %s', [LInputFileName,
              LException.ClassName, LException.Message]), LFileSize,
            LTotalStopwatch.ElapsedMilliseconds, LExecutionMilliseconds,
            LParsingMilliseconds, LReportLines, LTdumpExitCode,
            LDiagnosticCount, LTdumpParameters, nil);
        end;
      end;
    end);
end;

procedure TFrmMain.CompleteAnalysis(AAnalysisId: Integer;
  const ASummary: string; ASucceeded: Boolean; AFileSize,
  ATotalMilliseconds, AExecutionMilliseconds, AParsingMilliseconds: Int64;
  AReportLines, ATDumpExitCode, ADiagnosticCount: Integer;
  const ATDumpParameters: string; ADocument: TDumpDocument);
begin
  if FClosing or (AAnalysisId <> FAnalysisId) then
  begin
    ADocument.Free;
    Exit;
  end;

  FAnalysisTask := nil;
  if not Assigned(FActiveRequest) then
  begin
    ADocument.Free;
    CompleteAnalysisProgress;
    Exit;
  end;

  if FActiveRequest.Discarded then
  begin
    ADocument.Free;
    AdvanceAnalysisProgress;
    FActiveRequest.Free;
    FActiveRequest := nil;
    CompleteAnalysisProgress;
    StartNextAnalysis;
    Exit;
  end;

  if FActiveRequest.ReloadRequested then
  begin
    ADocument.Free;
    var LFileName := FActiveRequest.FileName;
    LogControl1.Add('Reloading: ' + LFileName, letWarning);
    AdvanceAnalysisProgress;
    FActiveRequest.Free;
    FActiveRequest := nil;
    CompleteAnalysisProgress;
    ProcessDroppedFile(LFileName, False);
    Exit;
  end;

  if FActiveRequest.Kind = akBinary then
  begin
    var LTDumpParameters := ATDumpParameters;
    if LTDumpParameters = '' then
      LTDumpParameters := '(none)';
    LogControl1.Add('TDUMP parameters: ' + LTDumpParameters);
  end
  else
    LogControl1.Add('TDUMP parameters: unavailable (pre-generated report)');
  if not ASucceeded then
  begin
    LogControl1.Add('Failed: ' + FActiveRequest.FileName, letError);
    LogControl1.Add('Error details: ' + StringReplace(ASummary, #13#10,
      ' | ', [rfReplaceAll]), letError);
  end;
  if ASucceeded and (FActiveRequest.Kind = akBinary) then
  begin
    if ATDumpExitCode <> 0 then
      LogControl1.Add(Format('TDUMP failed (exit code %d): %s',
        [ATDumpExitCode, FActiveRequest.FileName]), letError)
    else if ADiagnosticCount > 0 then
      LogControl1.Add(Format('TDUMP completed with %d diagnostic(s): %s',
        [ADiagnosticCount, FActiveRequest.FileName]), letWarning)
    else
      LogControl1.Add('TDUMP completed successfully: ' +
        FActiveRequest.FileName, letSuccess);
  end
  else if ASucceeded then
    LogControl1.Add('Completed: ' + FActiveRequest.FileName, letSuccess);
  LogControl1.Add(FormatProfile(AFileSize, ATotalMilliseconds,
    AExecutionMilliseconds, AParsingMilliseconds, AReportLines), letProfile);
  if ASucceeded and (ADocument <> nil) then
  begin
    CreateDocumentTab(FActiveRequest.FileName, ASummary, ADocument);
    if FActiveRequest.ActivateTabWhenComplete then
      FPendingActivationCard := FPendingDocumentCards.Last;
  end;
  ADocument.Free;
  AdvanceAnalysisProgress;
  FActiveRequest.Free;
  FActiveRequest := nil;
  if not HasPendingAnalysis then
    FinalizePendingDocumentTabs;
  CompleteAnalysisProgress;
  StartNextAnalysis;
end;

destructor TFrmMain.Destroy;
begin
  FClosing := True;
  CardPanel1.OnCardChange := nil;
  if FAnalysisTask <> nil then
  begin
    FAnalysisTask.Cancel;
    FAnalysisTask.Wait;
    FAnalysisTask := nil;
  end;
  DrainAnalysisMessages;
  AddOpenDocumentFilesToRecentItems;
  SaveApplicationSession;
  FActiveRequest.Free;
  while FPendingFiles.Count > 0 do
    FPendingFiles.Dequeue.Free;
  FPendingFiles.Free;
  FPendingDocumentCards.Free;
  FRecentFilesPopupFiles.Free;
  inherited;
end;

procedure TFrmMain.DrainAnalysisMessages;
var
  LMessage: TMsg;
begin
  while PeekMessage(LMessage, Handle, cWMAnalysisProgress,
    cWMAnalysisCompleted, PM_REMOVE) do
    DispatchMessage(LMessage);
end;

procedure TFrmMain.FormCreate(Sender: TObject);
begin
  TStyleManager.SystemHooks :=  TStyleManager.SystemHooks - [shDialogs];
  TSettings.Instance.Load;
  SyncActiveTheme;
  CheckTDumpAvailability;
  RestorePreviousSessionTabs;
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin
  Font.Name := TExplorerTheme.FontName;
  Font.Size := TExplorerTheme.FontSize;
  Font.Height := MulDiv(Font.Height, CurrentPPI, Font.PixelsPerInch);
end;

procedure TFrmMain.RestoreWindowPlacement;
var
  LBounds: TRect;
  LIntersection: TRect;
  LWorkArea: TRect;
  LMonitor: TMonitor;
  LWidth: Integer;
  LHeight: Integer;
  LIsVisible: Boolean;
begin
  var LSettings := TSettings.Instance;
  if not LSettings.RememberWindowPlacement or not LSettings.HasWindowBounds then
    Exit;

  LBounds := LSettings.WindowBounds;
  LIsVisible := False;
  for var LMonitorIndex := 0 to Screen.MonitorCount - 1 do
    if IntersectRect(LIntersection, LBounds,
      Screen.Monitors[LMonitorIndex].WorkareaRect) and
      (LIntersection.Width > 0) and (LIntersection.Height > 0) then
    begin
      LIsVisible := True;
      Break;
    end;
  if not LIsVisible then
    Exit;

  LMonitor := Screen.MonitorFromRect(LBounds, mdNearest);
  LWorkArea := LMonitor.WorkareaRect;
  LWidth := Min(Max(LBounds.Width, Constraints.MinWidth), LWorkArea.Width);
  LHeight := Min(Max(LBounds.Height, Constraints.MinHeight), LWorkArea.Height);
  SetBounds(EnsureRange(LBounds.Left, LWorkArea.Left,
    LWorkArea.Right - LWidth), EnsureRange(LBounds.Top, LWorkArea.Top,
    LWorkArea.Bottom - LHeight), LWidth, LHeight);
end;

procedure TFrmMain.RestorePreviousSessionTabs;
var
  LPreferredFileName: string;
  LRestoredAny: Boolean;
begin
  var LSettings := TSettings.Instance;
  if not LSettings.RestorePreviousSession or
    (LSettings.LastSessionFileCount = 0) then
    Exit;

  FRestoringPreviousSession := True;
  LRestoredAny := False;
  if (LSettings.LastSessionActiveIndex >= 0) and
    (LSettings.LastSessionActiveIndex < LSettings.LastSessionFileCount) then
    LPreferredFileName := LSettings.LastSessionFile(
      LSettings.LastSessionActiveIndex);
  for var LIndex := 0 to LSettings.LastSessionFileCount - 1 do
  begin
    var LFileName := LSettings.LastSessionFile(LIndex);
    if not FileExists(LFileName) then
      Continue;
    if ProcessDroppedFile(LFileName,
      SameText(LFileName, LPreferredFileName)) then
      LRestoredAny := True;
  end;
  if not LRestoredAny then
    FRestoringPreviousSession := False;
  UpdateEmptyState;
end;

procedure TFrmMain.CreateWnd;
begin
  inherited CreateWnd;
  RestoreWindowPlacement;
  DragAcceptFiles(Handle, True);
end;

procedure TFrmMain.DestroyWnd;
begin
  DragAcceptFiles(Handle, False);
  inherited DestroyWnd;
end;

function TFrmMain.IsTextFile(const AFileName: string): Boolean;
var
  LBytes: TBytes;
begin
  var LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    var LReadCount := cTextProbeSize;
    if LStream.Size < LReadCount then
      LReadCount := Integer(LStream.Size);
    if LReadCount = 0 then
      Exit(True);

    SetLength(LBytes, LReadCount);
    LStream.ReadBuffer(LBytes[0], LReadCount);
    if ((LReadCount >= 2) and (LBytes[0] = $FF) and (LBytes[1] = $FE)) or
      ((LReadCount >= 2) and (LBytes[0] = $FE) and (LBytes[1] = $FF)) then
      Exit(True);

    for var LByte in LBytes do
      if LByte = 0 then
        Exit(False);
    Result := True;
  finally
    LStream.Free;
  end;
end;

procedure TFrmMain.OpenInputFile(const AFileName: string;
  AActivateTabWhenComplete: Boolean);
begin
  ProcessDroppedFile(AFileName, AActivateTabWhenComplete);
end;

function TFrmMain.CreateAnalysisRequest(const AFileName: string;
  AKind: TAnalysisKind; AActivateTabWhenComplete: Boolean): TAnalysisRequest;
begin
  Result := TAnalysisRequest.Create;
  Result.FileName := AFileName;
  Result.Kind := AKind;
  Result.ActivateTabWhenComplete := AActivateTabWhenComplete;
end;

procedure TFrmMain.CreateDocumentTab(const AFileName, ASummary: string;
  var ADocument: TDumpDocument);
begin
  if ADocument = nil then
    Exit;
  FDocumentStagingPanel.LockDrawing;
  try
    var LCard := TCard.Create(FDocumentStagingPanel);
    FPendingDocumentCards.Add(LCard);
    LCard.Visible := False;
    LCard.Parent := FDocumentStagingPanel;
    LCard.Hint := AFileName;
    LCard.Caption := ExtractFileName(AFileName);
    if LCard.Caption = '' then
      LCard.Caption := AFileName;

    var LFrame := TDumpDocumentFrame.Create(LCard);
    LFrame.Parent := LCard;
    LFrame.Align := alClient;
    LFrame.PopulateTree(ADocument);
    ADocument := nil;
    LFrame.ShowSummary(ASummary);
  finally
    FDocumentStagingPanel.UnlockDrawing;
  end;
end;

procedure TFrmMain.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  //with Params do
  //  ExStyle := ExStyle or WS_EX_LAYERED;
end;

procedure TFrmMain.AddPendingDocumentTabs;
begin
  AttachPendingDocumentCards;
  try
   FTabs.LockDrawing;
   try
    for var LCard in FPendingDocumentCards do
      FTabs.AddTab(LCard.Caption, DocumentTabImageName(LCard.Hint), True, False);
   finally
     FTabs.UnlockDrawing;
   end;
  finally
    FTabs.Invalidate;
  end;
  FPendingDocumentCards.Clear;
end;

procedure TFrmMain.AttachPendingDocumentCards;
begin
  if FPendingDocumentCards.Count = 0 then
    Exit;
  UpdateEmptyState;
  var LPreviousCard := CardPanel1.ActiveCard;
  // TCardPanel activates every TCard while it is being inserted.  Keep both
  // the panel and each incoming card from painting those transient states.
  CardPanel1.LockDrawing;
  try
    for var LCard in FPendingDocumentCards do
    begin
      LCard.LockDrawing;
      try
        LCard.Parent := CardPanel1;
        LCard.Visible := False;
      finally
        LCard.UnlockDrawing;
      end;
    end;
    if Assigned(LPreviousCard) and (LPreviousCard.Parent = CardPanel1) then
      CardPanel1.ActiveCard := LPreviousCard;
  finally
    CardPanel1.UnlockDrawing;
  end;
end;

procedure TFrmMain.ActivateDeferredDocumentTab;
begin
  var LCard := FDeferredDocumentCard;
  FDeferredDocumentCard := nil;
  if (LCard = nil) or (LCard.Parent <> CardPanel1) then
    Exit;
  LCard.Visible := True;
  FTabs.ActiveIndex := LCard.CardIndex;
end;

function TFrmMain.HasPendingAnalysis: Boolean;
begin
  for var LRequest in FPendingFiles do
    if not LRequest.Discarded then
      Exit(True);
  Result := False;
end;

function TFrmMain.IsPendingDocumentCard(ACard: TCard): Boolean;
begin
  Result := FPendingDocumentCards.Contains(ACard);
end;

function TFrmMain.IsDocumentOpen(const AFileName: string): Boolean;
begin
  for var LIndex := 0 to CardPanel1.CardCount - 1 do
    if SameText(CardPanel1.Cards[LIndex].Hint, AFileName) then
      Exit(True);
  for var LCard in FPendingDocumentCards do
    if SameText(LCard.Hint, AFileName) then
      Exit(True);
  if Assigned(FActiveRequest) and not FActiveRequest.Discarded and
    SameText(FActiveRequest.FileName, AFileName) then
    Exit(True);
  for var LRequest in FPendingFiles do
    if not LRequest.Discarded and SameText(LRequest.FileName, AFileName) then
      Exit(True);
  Result := False;
end;

procedure TFrmMain.AddAnalysisProgressItem;
begin
  Inc(FProgressTotalFiles);
  UpdateOverallProgress;
end;

procedure TFrmMain.AddRecentFile(const AFileName: string);
begin
  if AFileName = '' then
    Exit;
  TSettings.Instance.AddRecentItem(AFileName);
  TSettings.Instance.Save;
end;

procedure TFrmMain.AddOpenDocumentFilesToRecentItems;
begin
  var LAddedItems := False;
  for var LIndex := 0 to CardPanel1.CardCount - 1 do
  begin
    var LFileName := CardPanel1.Cards[LIndex].Hint;
    if LFileName <> '' then
    begin
      TSettings.Instance.AddRecentItem(LFileName);
      LAddedItems := True;
    end;
  end;
  for var LCard in FPendingDocumentCards do
    if LCard.Hint <> '' then
    begin
      TSettings.Instance.AddRecentItem(LCard.Hint);
      LAddedItems := True;
    end;
  if LAddedItems then
    TSettings.Instance.Save;
end;

procedure TFrmMain.SaveApplicationSession;
var
  LSettings: TSettings;
begin
  LSettings := TSettings.Instance;
  if LSettings.RememberWindowPlacement and (WindowState = wsNormal) then
    LSettings.SetWindowBounds(BoundsRect)
  else if not LSettings.RememberWindowPlacement then
    LSettings.ClearWindowBounds;

  LSettings.ClearLastSessionFiles;
  if LSettings.RestorePreviousSession then
  begin
    for var LIndex := 0 to CardPanel1.CardCount - 1 do
      if CardPanel1.Cards[LIndex].Hint <> '' then
        LSettings.AddLastSessionFile(CardPanel1.Cards[LIndex].Hint);
    LSettings.LastSessionActiveIndex := Max(0, CardPanel1.ActiveCardIndex);
  end;
  LSettings.Save;
end;

procedure TFrmMain.AdvanceAnalysisProgress;
begin
  if FProgressCompletedFiles < FProgressTotalFiles then
    Inc(FProgressCompletedFiles);
  FCurrentFileProgress := 0;
  UpdateOverallProgress;
end;

procedure TFrmMain.ResetAnalysisProgress;
begin
  FProgressTotalFiles := 0;
  FProgressCompletedFiles := 0;
  FCurrentFileProgress := 0;
  ProgressBar1.Min := 0;
  ProgressBar1.Max := 1000;
  ProgressBar1.Position := 0;
  ProgressBar1.Visible := True;
end;

procedure TFrmMain.SetAnalysisProgress(ACompletedLines, ATotalLines: Integer);
begin
  if ATotalLines > 0 then
    FCurrentFileProgress := MulDiv(ACompletedLines, 1000, ATotalLines)
  else
    FCurrentFileProgress := 0;
  if FCurrentFileProgress < 0 then
    FCurrentFileProgress := 0
  else if FCurrentFileProgress > 1000 then
    FCurrentFileProgress := 1000;
  UpdateOverallProgress;
end;

procedure TFrmMain.FinalizePendingDocumentTabs;
begin
  if FPendingDocumentCards.Count = 0 then
  begin
    FRestoringPreviousSession := False;
    Exit;
  end;
  if FRestoringPreviousSession and (FPendingActivationCard = nil) then
    FPendingActivationCard := FPendingDocumentCards.First;
  FDeferredDocumentCard := FPendingActivationCard;
  FPendingActivationCard := nil;
  AddPendingDocumentTabs;
  FRestoringPreviousSession := False;
end;

procedure TFrmMain.CompleteAnalysisProgress;
begin
  if HasPendingAnalysis then
  begin
    UpdateOverallProgress;
    Exit;
  end;
  FCurrentFileProgress := 0;
  ProgressBar1.Position := ProgressBar1.Max;
  ProgressBar1.Visible := False;
end;

procedure TFrmMain.UpdateOverallProgress;
begin
  if FProgressTotalFiles <= 0 then
    Exit;

  ProgressBar1.Min := 0;
  ProgressBar1.Max := FProgressTotalFiles * 1000;
  var LPosition := FProgressCompletedFiles * 1000 + FCurrentFileProgress;
  if LPosition < ProgressBar1.Min then
    LPosition := ProgressBar1.Min
  else if LPosition > ProgressBar1.Max then
    LPosition := ProgressBar1.Max;
  ProgressBar1.Position := LPosition;
  ProgressBar1.Visible := True;
end;

procedure TFrmMain.UpdateEmptyState;
var
  LShowEmptyState: Boolean;
begin
  if not Assigned(FEmptyStateHost) then
    Exit;

  LShowEmptyState := (CardPanel1.CardCount = 0) and
    (FPendingDocumentCards.Count = 0) and not Assigned(FActiveRequest) and
    not HasPendingAnalysis;
  if FEmptyStateHost.Visible = LShowEmptyState then
    Exit;

  if LShowEmptyState then
  begin
    CardPanel1.Visible := False;
    FEmptyStateHost.Visible := True;
  end
  else
  begin
    FEmptyStateHost.Visible := False;
    CardPanel1.Visible := True;
  end;
end;

function TFrmMain.CanAutoActivateInitialDocument: Boolean;
begin
  Result := (CardPanel1.CardCount = 0) and
    (FPendingDocumentCards.Count = 0) and
    not Assigned(FActiveRequest) and not HasPendingAnalysis;
end;

function TFrmMain.ProcessDroppedFile(const AFileName: string;
  AActivateTabWhenComplete: Boolean): Boolean;
var
  LKind: TAnalysisKind;
begin
  Result := False;
  var LExpandedFileName := ExpandFileName(AFileName);
  try
    if TFile.GetSize(LExpandedFileName) > cMaxTDumpReportSize then
    begin
      LogControl1.Add(Format('%s exceeds the 100 MB file limit.',
        [LExpandedFileName]), letWarning);
      Exit;
    end;
    if IsTDumpBinaryFile(LExpandedFileName) or
      not IsTextFile(LExpandedFileName) then
    begin
      if not EnsureTDumpAvailable then
      begin
        LogControl1.Add(Format('TDUMP is unavailable; cannot open binary file: %s',
          [LExpandedFileName]), letError);
        Exit;
      end;
      LKind := akBinary;
    end
    else
    begin
      if not IsTDumpReportFile(LExpandedFileName) then
      begin
        LogControl1.Add(Format('%s is text, but it is not a TDUMP report.',
          [LExpandedFileName]), letWarning);
        Exit;
      end;
      LKind := akReport;
    end;
  except
    on LException: Exception do
    begin
      LogControl1.Add(Format('Unable to process %s: %s', [LExpandedFileName,
        LException.Message]), letError);
      Exit;
    end;
  end;

  if Assigned(FActiveRequest) and not FActiveRequest.Discarded and
    SameText(FActiveRequest.FileName, LExpandedFileName) then
  begin
    if not FActiveRequest.ReloadRequested then
    begin
      FActiveRequest.ReloadRequested := True;
      LogControl1.Add('Reload requested: ' + LExpandedFileName, letWarning);
      FAnalysisTask.Cancel;
      if FAnalysisTask.Status = TTaskStatus.Canceled then
        CompleteAnalysis(FAnalysisId, '', False, 0, 0, 0, 0, 0, 0, 0, '', nil);
    end;
    Exit;
  end;

  for var LPendingRequest in FPendingFiles do
    if SameText(LPendingRequest.FileName, LExpandedFileName) then
      LPendingRequest.Discarded := True;
  for var LCardIndex := CardPanel1.CardCount - 1 downto 0 do
    if SameText(CardPanel1.Cards[LCardIndex].Hint, LExpandedFileName) then
      RemoveDocumentCard(CardPanel1.Cards[LCardIndex], True);

  var LRequest := CreateAnalysisRequest(LExpandedFileName, LKind,
    AActivateTabWhenComplete);
  if (FAnalysisTask = nil) and (FActiveRequest = nil) and
    (FPendingFiles.Count = 0) then
    ResetAnalysisProgress;
  AddAnalysisProgressItem;
  LogControl1.Add('Opening: ' + LExpandedFileName);

  if FAnalysisTask <> nil then
  begin
    FPendingFiles.Enqueue(LRequest);
    LogControl1.Add('Queued: ' + LExpandedFileName);
    Result := True;
    Exit;
  end;

  BeginAnalysis(LRequest);
  Result := True;
end;

procedure TFrmMain.StartNextAnalysis;
begin
  if FClosing or (FAnalysisTask <> nil) then
    Exit;
  while FPendingFiles.Count > 0 do
  begin
    var LRequest := FPendingFiles.Dequeue;
    if LRequest.Discarded then
    begin
      AdvanceAnalysisProgress;
      LRequest.Free;
      Continue;
    end;
    BeginAnalysis(LRequest);
    Exit;
  end;
  CompleteAnalysisProgress;
end;


procedure TFrmMain.WMAnalysisCompleted(var AMessage: TMessage);
begin
  var LCompletion := TAnalysisCompletion(AMessage.LParam);
  try
    var LDocument := LCompletion.Document;
    LCompletion.Document := nil;
    CompleteAnalysis(LCompletion.AnalysisId, LCompletion.Summary,
      LCompletion.Succeeded, LCompletion.FileSize,
      LCompletion.TotalMilliseconds, LCompletion.ExecutionMilliseconds,
      LCompletion.ParsingMilliseconds, LCompletion.ReportLines,
      LCompletion.TDumpExitCode, LCompletion.DiagnosticCount,
      LCompletion.TDumpParameters, LDocument);
  finally
    LCompletion.Free;
  end;
end;

procedure TFrmMain.WMAnalysisProgress(var AMessage: TMessage);
begin
  var LUpdate := TAnalysisProgressUpdate(AMessage.LParam);
  try
    if not FClosing and (LUpdate.AnalysisId = FAnalysisId) and
      Assigned(FActiveRequest) and not FActiveRequest.Discarded then
    begin
      if not FActiveRequest.ParsingStarted then
      begin
        FActiveRequest.ParsingStarted := True;
        LogControl1.Add('Parsing: ' + FActiveRequest.FileName);
      end;
      SetAnalysisProgress(LUpdate.CompletedLines, LUpdate.TotalLines);
    end;
  finally
    LUpdate.Free;
  end;
end;

procedure TFrmMain.WMDropFiles(var AMessage: TWMDropFiles);
begin
  try
    //CardPanel1.LockDrawing;
    try
      var LFileCount := DragQueryFile(AMessage.Drop, $FFFFFFFF, nil, 0);
      // Multi-file drops retain the current tab.  With no document yet,
      // nominate only the first accepted item for activation.
      var LActivateNextAcceptedTab := (LFileCount = 1) or
        CanAutoActivateInitialDocument;
      for var LIndex := 0 to LFileCount - 1 do
      begin
        var LFileNameLength := DragQueryFile(AMessage.Drop, LIndex, nil, 0);
        var LFileName := StringOfChar(#0, LFileNameLength + 1);
        DragQueryFile(AMessage.Drop, LIndex, PChar(LFileName),
          Length(LFileName));
        SetLength(LFileName, LFileNameLength);
        if ProcessDroppedFile(LFileName, LActivateNextAcceptedTab) then
          LActivateNextAcceptedTab := False;
      end;
    finally
      //CardPanel1.UnlockDrawing;
    end;
  finally
    DragFinish(AMessage.Drop);
  end;
end;

end.
