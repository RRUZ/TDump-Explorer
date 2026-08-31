unit TDump.Explorer.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.UITypes,
  System.Diagnostics, System.Generics.Collections, System.IOUtils, System.StrUtils,
  System.Threading,
  System.TypInfo, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Winapi.ShellAPI, TDump.Explorer.Finder,
  TDump.Explorer.Parser, TDump.Explorer.Phosphor.Font, TDump.Explorer.Runner,
  TDump.Explorer.TextSource,
  TDump.Explorer.Frame, Vcl.ComCtrls, TDump.Explorer.LogControl, Vcl.ExtCtrls,
  Vcl.TitleBarCtrls, Vcl.WinXPanels, Vcl.VirtualImageList,
  TDump.Explorer.GlassTabs, TDump.Explorer.PopupMenu, Vcl.AppEvnts;

type
  TAnalysisKind = (akBinary, akReport);

  TAnalysisRequest = class
  public
    FileName: string;
    Kind: TAnalysisKind;
    ParsingStarted: Boolean;
    ReloadRequested: Boolean;
    Discarded: Boolean;
  end;

  TEmptyStateDropZone = class(TCustomPanel)
  private
    FBorderColor: TColor;
    procedure SetBorderColor(const AValue: TColor);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
  end;

const
  CWMAnalysisProgress = WM_APP + $241;
  CWMAnalysisCompleted = WM_APP + $242;

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
    FTabs: TGlassTabStrip;
    FTabImages: TVirtualImageList;
    FExplorerPopupMenu: TExplorerPopupMenuForm;
    FExplorerPopupImages: TVirtualImageList;
    FDocumentStagingPanel: TCardPanel;
    FDeferredTabActivationTimer: TTimer;
    FPendingDocumentCards: TList<TCard>;
    FDeferredDocumentCard: TCard;
    FProgressTotalFiles: Integer;
    FProgressCompletedFiles: Integer;
    FCurrentFileProgress: Integer;
    FRestoreAlphaBlend: Boolean;
    procedure ApplyTheme;
    procedure ApplyExplorerPopupMenuTheme;
    procedure ApplyEmptyStateTheme;
    procedure AddAnalysisProgressItem;
    procedure AdvanceAnalysisProgress;
    procedure BeginAnalysis(ARequest: TAnalysisRequest);
    procedure CardsChanged(Sender: TObject; PrevCard, NextCard: TCard);
    procedure CheckTDumpAvailability;
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
    procedure DeferredTabActivationTimer(Sender: TObject);
    procedure DrainAnalysisMessages;
    function HasPendingAnalysis: Boolean;
    function IsPendingDocumentCard(ACard: TCard): Boolean;
    function CreateAnalysisRequest(const AFileName: string;
      AKind: TAnalysisKind): TAnalysisRequest;
    procedure CreateTabs;
    procedure CreateEmptyState;
    function DocumentTabImageName: System.UITypes.TImageName;
    function IsTextFile(const AFileName: string): Boolean;
    procedure ProcessDroppedFile(const AFileName: string);
    procedure RemoveDocumentCard(ACard: TCard; ADeleteTab: Boolean);
    procedure ResetAnalysisProgress;
    procedure SetAnalysisProgress(ACompletedLines, ATotalLines: Integer);
    procedure SchedulePendingDocumentActivation;
    procedure SplitterPaint(Sender: TObject);
    procedure StartNextAnalysis;
    procedure PopupMenuAboutClick(Sender: TObject);
    procedure PopupMenuChangeThemeClick(Sender: TObject);
    procedure ExplorerPopupMenuItemClick(Sender: TObject; AItemIndex: Integer);
    procedure InitializeExplorerPopupMenuImages;
    procedure PopulateExplorerPopupMenu;
    procedure PopupMenuSettingsClick(Sender: TObject);
    procedure TabsAddButtonClick(Sender: TObject);
    procedure TabsAfterPaintBackground(ACanvas: TCanvas;
      const ARect: TRect);
    procedure TabsBackgroundMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TabsBackgroundDblClick(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TabsChanged(Sender: TObject; ANewIndex: Integer);
    procedure TabsChevronButtonClick(Sender: TObject);
    procedure UpdateOverallProgress;
    procedure UpdateEmptyState;
    procedure TabsClosing(Sender: TObject; AIndex: Integer;
      var ACanClose: Boolean);
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure WMAnalysisCompleted(var AMessage: TMessage);
      message CWMAnalysisCompleted;
    procedure WMAnalysisProgress(var AMessage: TMessage);
      message CWMAnalysisProgress;
    procedure WMDropFiles(var AMessage: TWMDropFiles); message WM_DROPFILES;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure InitializeTabImages;
    procedure OpenInputFile(const AFileName: string);
  end;

var
  FrmMain: TFrmMain;

implementation

uses
  TDump.Explorer.UI, TDump.Explorer.Utils, TDump.Explorer.Resources,
  TDump.Explorer.Settings, Vcl.GraphUtil, Vcl.Menus, Vcl.Themes;

{$R *.dfm}

const
  CTextProbeSize = 8192;
  CReportValidationProbeSize = 64 * 1024;
  CTitleBarHeight = 40;
  CTitleBarButtonMargin = 150;
  CTabIconSize = 16;
  CCaptionFontSize = 11;
  CBorderBlend = 0.82;
  CInactiveTopBlend = 0.97;
  CHoverTopBlend = 0.82;
  CInactiveTextBlend = 0.35;
  CCloseHoverBlend = 0.72;

{ TEmptyStateDropZone }

constructor TEmptyStateDropZone.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  ParentBackground := False;
  DoubleBuffered := True;
end;

procedure TEmptyStateDropZone.Paint;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  DrawDashedRoundedRectangle(Canvas, ClientRect, FBorderColor,
    ScaleValue(14));
end;

procedure TEmptyStateDropZone.SetBorderColor(const AValue: TColor);
begin
  if FBorderColor = AValue then
    Exit;
  FBorderColor := AValue;
  Invalidate;
end;

function DescribeCard(ACard: TCard): string;
begin
  if ACard = nil then
    Exit('(none)');
  Result := Format('"%s" index=%d visible=%s', [ACard.Caption,
    ACard.CardIndex, BoolToStr(ACard.Visible, True)]);
end;

function IsTDumpReportFile(const AFileName: string): Boolean;
begin
  var LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    var LReadCount := CReportValidationProbeSize;
    if LStream.Size < LReadCount then
      LReadCount := Integer(LStream.Size);
    if LReadCount <= 0 then
      Exit(False);
    var LBytes: TBytes;
    SetLength(LBytes, LReadCount);
    LStream.ReadBuffer(LBytes[0], LReadCount);
    Result := IsTDumpReport(TEncoding.Default.GetString(LBytes));
  finally
    LStream.Free;
  end;
end;

function ExplorerTabPalette(const ATheme: TExplorerTheme): TGlassTabPalette;
begin
  Result.StripTop := ATheme.BackgroundColor;
  Result.StripBottom := ATheme.BackgroundColor;
  Result.StripBorder := ColorBlendRGB(ATheme.TextColor, ATheme.BackgroundColor, CBorderBlend);
  Result.BackgroundTopLine := ATheme.BackgroundColor;
  Result.TabTop := ATheme.BackgroundColor;
  Result.TabBottom := ATheme.BackgroundColor;
  Result.InactiveTop := ColorBlendRGB(ATheme.TextColor,  ATheme.BackgroundColor, CInactiveTopBlend);
  Result.InactiveBottom := ATheme.BackgroundColor;
  Result.HoverTop := ColorBlendRGB(ATheme.SelectionColor,  ATheme.BackgroundColor, CHoverTopBlend);
  Result.HoverBottom := ATheme.BackgroundColor;
  Result.Accent := ATheme.SelectionColor;

  Result.Text := ATheme.TextColor;
  Result.InactiveText := ATheme.InactiveText;

  Result.CloseHover := ColorBlendRGB(ATheme.SelectionColor, ATheme.BackgroundColor, CCloseHoverBlend);
end;

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

function BuildDocumentSummary(const ATitle: string;
  const ADocument: TDumpDocument; const ATDumpParameters: string = ''): string;
begin
  var LLines := TStringList.Create;
  try
    LLines.Add(ATitle);
    LLines.Add('Source: ' + ADocument.SourceFileName);
    if ADocument.TurboDumpHeader <> '' then
      LLines.Add('TDUMP header: ' + ADocument.TurboDumpHeader);
    LLines.Add('Tool: ' + GetEnumName(TypeInfo(TDumpToolKind),
      Ord(ADocument.ToolKind)));
    if ATDumpParameters <> '' then
      LLines.Add('TDUMP parameters: ' + ATDumpParameters);
    if ADocument.ToolVersion <> '' then
      LLines.Add('TDUMP version: ' + ADocument.ToolVersion);
    LLines.Add('File kind: ' + GetEnumName(TypeInfo(TDumpFileKind),
      Ord(ADocument.FileKind)));
    LLines.Add('Architecture: ' + ADocument.Architecture);
    LLines.Add(Format('Report lines: %d', [ADocument.Lines.Count]));
    LLines.Add('');
    LLines.Add(Format('Headers: %d', [ADocument.Headers.Count]));
    LLines.Add(Format('Sections: %d', [ADocument.Sections.Count]));
    LLines.Add(Format('Import modules: %d', [ADocument.Imports.Count]));
    LLines.Add(Format('Exports: %d', [ADocument.ExportList.Count]));
    LLines.Add(Format('Resources: %d', [ADocument.Resources.Count]));
    LLines.Add(Format('Diagnostics: %d', [ADocument.Diagnostics.Count]));
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

function FormatProfile(AFileSize, ATotalMilliseconds, AExecutionMilliseconds,
  AParsingMilliseconds: Int64; AReportLines: Integer): string;
begin
  var LSpeed := 'n/a';
  if (AReportLines > 0) and (AParsingMilliseconds > 0) then
    LSpeed := Format('%s lines/s', [FormatFloat('#,##0',
      AReportLines * 1000.0 / AParsingMilliseconds)]);
  Result := Format('Profile: size %s | total %.3f s | TDUMP %.3f s | parse %.3f s | %s lines | %s',
    [FormatByteSize(AFileSize), ATotalMilliseconds / 1000.0,
      AExecutionMilliseconds / 1000.0, AParsingMilliseconds / 1000.0,
      FormatFloat('#,##0', AReportLines), LSpeed]);
end;

function ParserProgressPhaseName(AValue: TDumpParserProgressPhase): string;
begin
  Result := GetEnumName(TypeInfo(TDumpParserProgressPhase), Ord(AValue));
end;

procedure PostAnalysisProgress(AWindowHandle: HWND; AAnalysisId: Integer;
  APhase: TDumpParserProgressPhase; ACompletedLines, ATotalLines: Integer);
begin
  var LUpdate := TAnalysisProgressUpdate.Create;
  LUpdate.AnalysisId := AAnalysisId;
  LUpdate.Phase := APhase;
  LUpdate.CompletedLines := ACompletedLines;
  LUpdate.TotalLines := ATotalLines;
  if not PostMessage(AWindowHandle, CWMAnalysisProgress, 0,
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
  if not PostMessage(AWindowHandle, CWMAnalysisCompleted, 0,
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
  if TFile.GetSize(AFileName) > CMaxTDumpReportSize then
  begin
    Result := Format('%s exceeds the 100 MB file limit.', [AFileName]);
    Exit;
  end;
  if not IsTDumpReportFile(AFileName) then
  begin
    Result := Format('%s is text, but it is not a TDUMP report.',
      [AFileName]);
    Exit;
  end;

  var LLastPhase := ppPreparing;
  var LLastCompletedLines := 0;
  var LLastTotalLines := 0;
  var LParser := TDumpParser.Create;
  try
    LParser.OnProgress :=
      procedure(APhase: TDumpParserProgressPhase; ACompletedLines,
        ATotalLines: Integer)
      begin
        LLastPhase := APhase;
        LLastCompletedLines := ACompletedLines;
        LLastTotalLines := ATotalLines;
        CheckCurrentTaskCancellation;
        PostAnalysisProgress(AWindowHandle, AAnalysisId, APhase,
          ACompletedLines, ATotalLines);
      end;
    var LParseStopwatch := TStopwatch.StartNew;
    try
      ADocument := LParser.ParseFile(AFileName);
    except
      on LException: Exception do
      begin
        LParseStopwatch.Stop;
        AParsingMilliseconds := LParseStopwatch.ElapsedMilliseconds;
        raise Exception.CreateFmt('%s: %s (parser phase %s, line %d of %d)',
          [LException.ClassName, LException.Message,
            ParserProgressPhaseName(LLastPhase), LLastCompletedLines,
            LLastTotalLines]);
      end;
    end;
    try
      LParseStopwatch.Stop;
      AParsingMilliseconds := LParseStopwatch.ElapsedMilliseconds;
      AReportLines := ADocument.Lines.Count;
      ADiagnosticCount := ADocument.Diagnostics.Count;
      Result := BuildDocumentSummary('TDUMP report parsed', ADocument);
    except
      ADocument.Free;
      ADocument := nil;
      raise;
    end;
  finally
    LParser.Free;
  end;
end;

procedure TFrmMain.ApplyTheme;
begin
  EnableImmersiveDarkMode(not IsLightThemeActive);

  var LTheme := TExplorerTheme.ActiveTheme;
  var LPalette := ExplorerTabPalette(LTheme);
  Color := LTheme.BackgroundColor;
  CardPanel1.Color := LTheme.BackgroundColor;
  FTabs.Palette := LPalette;
  FTabs.BackgroundGradientDirection := ggdVertical;
  FTabs.TabGradientDirection := ggdVertical;
  var LImageName := DocumentTabImageName;
  for var LIndex := 0 to FTabs.Items.Count - 1 do
    FTabs.Items[LIndex].ImageName := LImageName;

  CustomTitleBar.SystemHeight := False;
  CustomTitleBar.Height := ScaleValue(CTitleBarHeight);
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
begin
  if not Assigned(FExplorerPopupMenu) then
    Exit;

  var LTheme := TExplorerTheme.ActiveTheme;
  FExplorerPopupMenu.Color := LTheme.BackgroundColor;
  //FExplorerPopupMenu.CustomTitleBar.BackgroundColor := LTheme.BackgroundColor;
  //FExplorerPopupMenu.CustomTitleBar.InactiveBackgroundColor := LTheme.BackgroundColor;
  FExplorerPopupMenu.MenuItems.ControlList1.BorderStyle := bsNone;
  FExplorerPopupMenu.MenuItems.Color := LTheme.BackgroundColor;
  FExplorerPopupMenu.MenuItems.HighlightColor := ColorBlendRGB(
    LTheme.SelectionColor, LTheme.BackgroundColor, 0.95);
end;

procedure TFrmMain.ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
begin
  if FRestoreAlphaBlend then
  begin
    FRestoreAlphaBlend := False;
    AlphaBlend := False;
  end;
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

procedure TFrmMain.CreateTabs;
begin
  FTabImages := TVirtualImageList.Create(Self);
  FTabImages.Width := CTabIconSize;
  FTabImages.Height := CTabIconSize;

  FTabs := TGlassTabStrip.Create(Self);
  FTabs.Parent := TitleBarPanel1;
  FTabs.Images := FTabImages;
  FTabs.Margins.Left := 0;
  FTabs.Margins.Top := 0;
  FTabs.Margins.Right := ScaleValue(CTitleBarButtonMargin);
  FTabs.Margins.Bottom := 0;
  FTabs.AlignWithMargins := True;
  FTabs.Align := alBottom;
  FTabs.TabHeight := CTitleBarHeight;
  FTabs.Font.Assign(Font);
  FTabs.ShowAddButton := True;
  FTabs.ShowChevronButton := True;
  FTabs.OnAddButtonClick := TabsAddButtonClick;
  FTabs.OnChevronButtonClick := TabsChevronButtonClick;
  FTabs.OnChange := TabsChanged;
  FTabs.OnCloseTab := TabsClosing;
  FTabs.OnBackgroundMouseDown := TabsBackgroundMouseDown;
  FTabs.OnBackgroundDblClick := TabsBackgroundDblClick;
  FTabs.OnAfterPaintBackground := TabsAfterPaintBackground;
  FTabs.SendToBack;

  TitleBarPanel1.Height := ScaleValue(CTitleBarHeight);
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
  FPhosphorIcon.IconCode := ph_binary;
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

function TFrmMain.DocumentTabImageName: System.UITypes.TImageName;
begin
  if ColorIsBright(TExplorerTheme.ActiveTheme.BackgroundColor) then
    Result := 'binary_light'
  else
    Result := 'binary_dark';
end;

procedure TFrmMain.InitializeTabImages;
begin
  if not Assigned(DataModule1) or not Assigned(FTabImages) then
    Exit;
  FTabImages.Clear;
  FTabImages.ImageCollection := DataModule1.ImageCollection1;
  FTabImages.Add('binary_dark', 'binary_dark');
  FTabImages.Add('binary_light', 'binary_light');
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

procedure TFrmMain.PopupMenuChangeThemeClick(Sender: TObject);
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
  FExplorerPopupImages.ImageCollection := DataModule1.ImageCollection1;
  FExplorerPopupImages.Add('gear_dark', 'gear_dark');
  FExplorerPopupImages.Add('gear_light', 'gear_light');

  FExplorerPopupImages.Add('moon_dark', 'moon_dark');
  FExplorerPopupImages.Add('moon_light', 'moon_light');
  FExplorerPopupImages.Add('sun_dark', 'sun_dark');
  FExplorerPopupImages.Add('sun_light', 'sun_light');

  FExplorerPopupImages.Add('file-dashed_dark', 'file-dashed_dark');
  FExplorerPopupImages.Add('file-dashed_light', 'file-dashed_light');
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
    LMenuItems.Add('Settings', 'gear' + LIconSuffix);

    if IsLightThemeActive  then
      LMenuItems.Add('Dark Theme', 'moon_light')
    else
      LMenuItems.Add('Light Theme', 'sun_dark');

    LMenuItems.Add('About', 'file-dashed' + LIconSuffix);
  finally
    LMenuItems.EndUpdate;
  end;
end;

procedure TFrmMain.PopupMenuAboutClick(Sender: TObject);
begin
  // About action stub.
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
        for var LFileName in LOpenDialog.Files do
          ProcessDroppedFile(LFileName);
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
    ACanvas.Font.Height := -ScaleValue(CCaptionFontSize);
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

procedure TFrmMain.TabsChevronButtonClick(Sender: TObject);
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

procedure TFrmMain.TabsClosing(Sender: TObject; AIndex: Integer;
  var ACanClose: Boolean);
begin
  ACanClose := (AIndex >= 0) and (AIndex < CardPanel1.CardCount);
  if not ACanClose then
    Exit;
  RemoveDocumentCard(CardPanel1.Cards[AIndex], False);
end;

constructor TFrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Splitter1.OnPaint := SplitterPaint;
  FPendingFiles := TQueue<TAnalysisRequest>.Create;
  FPendingDocumentCards := TList<TCard>.Create;
  FDocumentStagingPanel := TCardPanel.Create(Self);
  FDocumentStagingPanel.Visible := False;
  FDocumentStagingPanel.SetBounds(-1, -1, 1, 1);
  FDocumentStagingPanel.Parent := Self;
  CreateTabs;
  CreateEmptyState;
  UpdateEmptyState;
  FDeferredTabActivationTimer := TTimer.Create(Self);
  FDeferredTabActivationTimer.Interval := 100;
  FDeferredTabActivationTimer.Enabled := False;
  FDeferredTabActivationTimer.OnTimer := DeferredTabActivationTimer;
  CompleteAnalysisProgress;
  CheckTDumpAvailability;
end;

procedure TFrmMain.SplitterPaint(Sender: TObject);
begin
  if not (Sender is TSplitter) then
    Exit;

  var LSplitter := TSplitter(Sender);
  LSplitter.Canvas.Brush.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
  LSplitter.Canvas.FillRect(LSplitter.ClientRect);
  DrawSplitterLine(LSplitter.Canvas, LSplitter.ClientRect,
    LSplitter.Align in [alLeft, alRight], TExplorerTheme.ActiveTheme.GhostColor);
end;

procedure TFrmMain.CheckTDumpAvailability;
begin
  FTDumpAvailable := False;
  FTDumpToolPath := '';
  FTDumpToolKind := tkTDump32;
  LogControl1.Add('Checking TDUMP availability...');
  try
    var LFinder := TDumpFinder.Create;
    try
      var LInstallations := LFinder.Find;
      try
        var LInstallation := LFinder.FindDefault(LInstallations);
        if LInstallation = nil then
        begin
          LogControl1.Add('TDUMP was not found.', letError);
          Exit;
        end;

        FTDumpToolPath := LInstallation.TDumpPath;
        if LInstallation.HasTDump64 then
        begin
          FTDumpToolPath := LInstallation.TDump64Path;
          FTDumpToolKind := tkTDump64;
        end;
        FTDumpAvailable := FileExists(FTDumpToolPath);
        if not FTDumpAvailable then
        begin
          LogControl1.Add('TDUMP was not found.', letError);
          Exit;
        end;
        var LMessage := 'TDUMP available: ' + FTDumpToolPath;
        var LVersion := GetTDumpVersion(FTDumpToolPath);
        if LVersion <> '' then
          LMessage := LMessage + ' (version ' + LVersion + ')';
        if LInstallation.StudioVersion <> '' then
          LMessage := LMessage + ' [RAD Studio ' +
            LInstallation.StudioVersion + ']';
        LogControl1.Add(LMessage, letSuccess);
      finally
        LInstallations.Free;
      end;
    finally
      LFinder.Free;
    end;
  except
    on LException: Exception do
      LogControl1.Add(Format('Unable to check TDUMP availability: %s',
        [LException.Message]), letError);
  end;
end;

procedure TFrmMain.BeginAnalysis(ARequest: TAnalysisRequest);
begin
  FActiveRequest := ARequest;  Inc(FAnalysisId);
  var LAnalysisId := FAnalysisId;
  var LInputFileName := ARequest.FileName;
  var LKind := ARequest.Kind;
  var LToolPath := FTDumpToolPath;
  var LToolKind := FTDumpToolKind;
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
    ProcessDroppedFile(LFileName);
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
    CreateDocumentTab(FActiveRequest.FileName, ASummary, ADocument);
  ADocument.Free;
  AdvanceAnalysisProgress;
  FActiveRequest.Free;
  FActiveRequest := nil;
  if not HasPendingAnalysis then
    SchedulePendingDocumentActivation;
  CompleteAnalysisProgress;
  StartNextAnalysis;
end;

destructor TFrmMain.Destroy;
begin
  FClosing := True;
  if Assigned(FDeferredTabActivationTimer) then
    FDeferredTabActivationTimer.Enabled := False;
  CardPanel1.OnCardChange := nil;
  if FAnalysisTask <> nil then
  begin
    FAnalysisTask.Cancel;
    FAnalysisTask.Wait;
    FAnalysisTask := nil;
  end;
  DrainAnalysisMessages;
  FActiveRequest.Free;
  while FPendingFiles.Count > 0 do
    FPendingFiles.Dequeue.Free;
  FPendingFiles.Free;
  FPendingDocumentCards.Free;
  inherited;
end;

procedure TFrmMain.DrainAnalysisMessages;
begin
  var LMessage: TMsg;
  while PeekMessage(LMessage, Handle, CWMAnalysisProgress,
    CWMAnalysisCompleted, PM_REMOVE) do
    DispatchMessage(LMessage);
end;

procedure TFrmMain.FormShow(Sender: TObject);
begin
  Font.Name := TExplorerTheme.FontName;
  Font.Size := TExplorerTheme.FontSize;
  Font.Height := MulDiv(Font.Height, CurrentPPI, Font.PixelsPerInch);
end;

procedure TFrmMain.CreateWnd;
begin
  inherited CreateWnd;
  DragAcceptFiles(Handle, True);
end;

procedure TFrmMain.DestroyWnd;
begin
  DragAcceptFiles(Handle, False);
  inherited DestroyWnd;
end;

function TFrmMain.IsTextFile(const AFileName: string): Boolean;
begin
  var LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    var LReadCount := CTextProbeSize;
    if LStream.Size < LReadCount then
      LReadCount := Integer(LStream.Size);
    if LReadCount = 0 then
      Exit(True);

    var LBytes: TBytes;
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

procedure TFrmMain.OpenInputFile(const AFileName: string);
begin
  ProcessDroppedFile(AFileName);
end;

function TFrmMain.CreateAnalysisRequest(const AFileName: string;
  AKind: TAnalysisKind): TAnalysisRequest;
begin
  Result := TAnalysisRequest.Create;
  Result.FileName := AFileName;
  Result.Kind := AKind;
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
    for var LCard in FPendingDocumentCards do
      FTabs.AddTab(LCard.Caption, DocumentTabImageName, True, False);
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
  //SendMessage(CardPanel1.Handle, WM_SETREDRAW, 0, 0);
  try
    for var LCard in FPendingDocumentCards do
    begin
      LCard.Parent := CardPanel1;
      LCard.Visible := False;
    end;
    if Assigned(LPreviousCard) and (LPreviousCard.Parent = CardPanel1) then
      CardPanel1.ActiveCard := LPreviousCard;
  finally
    //SendMessage(CardPanel1.Handle, WM_SETREDRAW, 1, 0);
    CardPanel1.Invalidate;
  end;
end;

procedure TFrmMain.DeferredTabActivationTimer(Sender: TObject);
begin
  FDeferredTabActivationTimer.Enabled := False;
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

procedure TFrmMain.AddAnalysisProgressItem;
begin
  Inc(FProgressTotalFiles);
  UpdateOverallProgress;
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

procedure TFrmMain.SchedulePendingDocumentActivation;
begin
  if FPendingDocumentCards.Count = 0 then
    Exit;
  FDeferredDocumentCard := FPendingDocumentCards.Last;
  AddPendingDocumentTabs;
  FDeferredTabActivationTimer.Enabled := False;
  FDeferredTabActivationTimer.Enabled := True;
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
    (FPendingDocumentCards.Count = 0);
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

procedure TFrmMain.ProcessDroppedFile(const AFileName: string);
begin
  var LExpandedFileName := ExpandFileName(AFileName);
  var LKind: TAnalysisKind;
  try
    if TFile.GetSize(LExpandedFileName) > CMaxTDumpReportSize then
    begin
      LogControl1.Add(Format('%s exceeds the 100 MB file limit.',
        [LExpandedFileName]), letWarning);
      Exit;
    end;
    if IsTDumpBinaryFile(LExpandedFileName) or
      not IsTextFile(LExpandedFileName) then
    begin
      if not FTDumpAvailable then
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

  var LRequest := CreateAnalysisRequest(LExpandedFileName, LKind);
  if (FAnalysisTask = nil) and (FActiveRequest = nil) and
    (FPendingFiles.Count = 0) then
    ResetAnalysisProgress;
  AddAnalysisProgressItem;
  LogControl1.Add('Opening: ' + LExpandedFileName);

  if FAnalysisTask <> nil then
  begin
    FPendingFiles.Enqueue(LRequest);
    LogControl1.Add('Queued: ' + LExpandedFileName);
    Exit;
  end;

  BeginAnalysis(LRequest);
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
      for var LIndex := 0 to LFileCount - 1 do
      begin
        var LFileNameLength := DragQueryFile(AMessage.Drop, LIndex, nil, 0);
        var LFileName := StringOfChar(#0, LFileNameLength + 1);
        DragQueryFile(AMessage.Drop, LIndex, PChar(LFileName),
          Length(LFileName));
        SetLength(LFileName, LFileNameLength);
        ProcessDroppedFile(LFileName);
      end;
    finally
      //CardPanel1.UnlockDrawing;
    end;
  finally
    DragFinish(AMessage.Drop);
  end;
end;

end.
