unit TDump.Explorer.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Diagnostics, System.Generics.Collections, System.IOUtils, System.StrUtils,
  System.Threading,
  System.TypInfo, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Winapi.ShellAPI, TDump.Explorer.Finder,
  TDump.Explorer.Parser, TDump.Explorer.Phosphor.Font, TDump.Explorer.Runner,
  TDump.Explorer.Frame, Vcl.ComCtrls, TDump.Explorer.LogControl, Vcl.ExtCtrls;

type
  TAnalysisKind = (akBinary, akReport);

  TAnalysisRequest = class
  public
    FileName: string;
    Kind: TAnalysisKind;
    ParsingStarted: Boolean;
    ReloadRequested: Boolean;
    Discarded: Boolean;
    TabSheet: TTabSheet;
    Frame: TDumpDocumentFrame;
  end;

const
  CWMAnalysisProgress = WM_APP + $241;
  CWMAnalysisCompleted = WM_APP + $242;

type
  TFrmMain = class(TForm)
    PageControl1: TPageControl;
    LogControl1: TLogControl;
    Splitter1: TSplitter;
  private
    FAnalysisId: Integer;
    FAnalysisTask: ITask;
    FActiveRequest: TAnalysisRequest;
    FClosing: Boolean;
    FTDumpAvailable: Boolean;
    FPendingFiles: TQueue<TAnalysisRequest>;
    FPhosphorIcon: TPhosphorIcon;
    procedure BeginAnalysis(ARequest: TAnalysisRequest);
    procedure CheckTDumpAvailability;
    procedure CompleteAnalysis(AAnalysisId: Integer; const ASummary: string;
      ASucceeded: Boolean; AFileSize, ATotalMilliseconds,
      AExecutionMilliseconds, AParsingMilliseconds: Int64;
      AReportLines, ATDumpExitCode, ADiagnosticCount: Integer;
      const ATDumpParameters: string; ADocument: TDumpDocument);
    procedure DrainAnalysisMessages;
    function CreateAnalysisRequest(const AFileName: string;
      AKind: TAnalysisKind): TAnalysisRequest;
    function IsTextFile(const AFileName: string): Boolean;
    procedure PhosphorIconClick(Sender: TObject);
    procedure ProcessDroppedFile(const AFileName: string);
    procedure StartNextAnalysis;
    procedure WMAnalysisCompleted(var AMessage: TMessage);
      message CWMAnalysisCompleted;
    procedure WMAnalysisProgress(var AMessage: TMessage);
      message CWMAnalysisProgress;
    procedure WMDropFiles(var AMessage: TWMDropFiles); message WM_DROPFILES;
  protected
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure OpenInputFile(const AFileName: string);
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

const
  CTextProbeSize = 8192;

function GetExecutableVersion(const AFileName: string): string;
begin
  var LHandle: DWORD := 0;
  var LVersionInfoSize := GetFileVersionInfoSize(PChar(AFileName), LHandle);
  if LVersionInfoSize = 0 then
    Exit('');

  var LVersionInfo: TBytes;
  SetLength(LVersionInfo, LVersionInfoSize);
  if not GetFileVersionInfo(PChar(AFileName), 0, LVersionInfoSize,
    @LVersionInfo[0]) then
    Exit('');

  var LVersionData: Pointer := nil;
  var LVersionDataLength: UINT := 0;
  if not VerQueryValue(@LVersionInfo[0], PChar('\'), LVersionData,
    LVersionDataLength) or (LVersionDataLength < SizeOf(TVSFixedFileInfo)) then
    Exit('');

  var LVersionInfoData := PVSFixedFileInfo(LVersionData);
  Result := Format('%d.%d.%d.%d', [
    HiWord(LVersionInfoData.dwFileVersionMS),
    LoWord(LVersionInfoData.dwFileVersionMS),
    HiWord(LVersionInfoData.dwFileVersionLS),
    LoWord(LVersionInfoData.dwFileVersionLS)]);
end;

function CaptureProcessOutput(const AExecutableFileName, AParameters: string): string;
const
  CBufferSize = 4096;
var
  LSecurityAttributes: TSecurityAttributes;
  LReadPipe: THandle;
  LWritePipe: THandle;
  LStartupInfo: TStartupInfo;
  LProcessInfo: TProcessInformation;
  LCommandLine: string;
  LBuffer: TBytes;
  LAvailable: DWORD;
  LBytesRead: DWORD;
  LBytesToRead: DWORD;
  LWaitResult: DWORD;
begin
  LReadPipe := 0;
  LWritePipe := 0;
  ZeroMemory(@LSecurityAttributes, SizeOf(LSecurityAttributes));
  LSecurityAttributes.nLength := SizeOf(LSecurityAttributes);
  LSecurityAttributes.bInheritHandle := True;
  if not CreatePipe(LReadPipe, LWritePipe, @LSecurityAttributes, 0) then
    Exit('');

  try
    if not SetHandleInformation(LReadPipe, HANDLE_FLAG_INHERIT, 0) then
      Exit('');

    ZeroMemory(@LStartupInfo, SizeOf(LStartupInfo));
    LStartupInfo.cb := SizeOf(LStartupInfo);
    LStartupInfo.dwFlags := STARTF_USESHOWWINDOW or STARTF_USESTDHANDLES;
    LStartupInfo.wShowWindow := SW_HIDE;
    LStartupInfo.hStdInput := GetStdHandle(STD_INPUT_HANDLE);
    LStartupInfo.hStdOutput := LWritePipe;
    LStartupInfo.hStdError := LWritePipe;

    LCommandLine := Format('"%s" %s', [AExecutableFileName, AParameters]);
    UniqueString(LCommandLine);
    ZeroMemory(@LProcessInfo, SizeOf(LProcessInfo));
    if not CreateProcess(nil, PChar(LCommandLine), nil, nil, True,
      CREATE_NO_WINDOW, nil, PChar(ExtractFileDir(AExecutableFileName)),
      LStartupInfo, LProcessInfo) then
      Exit('');

    try
      CloseHandle(LWritePipe);
      LWritePipe := 0;
      SetLength(LBuffer, CBufferSize);
      repeat
        while PeekNamedPipe(LReadPipe, nil, 0, nil, @LAvailable, nil) and
          (LAvailable > 0) do
        begin
          LBytesToRead := LAvailable;
          if LBytesToRead > CBufferSize then
            LBytesToRead := CBufferSize;
          if not ReadFile(LReadPipe, LBuffer[0], LBytesToRead, LBytesRead, nil) or
            (LBytesRead = 0) then
            Break;
          Result := Result + TEncoding.Default.GetString(LBuffer, 0, LBytesRead);
        end;
        LWaitResult := WaitForSingleObject(LProcessInfo.hProcess, 10);
      until LWaitResult <> WAIT_TIMEOUT;

      while PeekNamedPipe(LReadPipe, nil, 0, nil, @LAvailable, nil) and
        (LAvailable > 0) do
      begin
        LBytesToRead := LAvailable;
        if LBytesToRead > CBufferSize then
          LBytesToRead := CBufferSize;
        if not ReadFile(LReadPipe, LBuffer[0], LBytesToRead, LBytesRead, nil) or
          (LBytesRead = 0) then
          Break;
        Result := Result + TEncoding.Default.GetString(LBuffer, 0, LBytesRead);
      end;
    finally
      CloseHandle(LProcessInfo.hThread);
      CloseHandle(LProcessInfo.hProcess);
    end;
  finally
    if LWritePipe <> 0 then
      CloseHandle(LWritePipe);
    if LReadPipe <> 0 then
      CloseHandle(LReadPipe);
  end;
end;

function GetTDumpVersion(const AFileName: string): string;
begin
  var LOutput := CaptureProcessOutput(AFileName, '-?');
  var LVersionMarker := Pos('Version ', LOutput);
  if LVersionMarker > 0 then
  begin
    Inc(LVersionMarker, Length('Version '));
    var LVersionEnd := LVersionMarker;
    while (LVersionEnd <= Length(LOutput)) and
      CharInSet(LOutput[LVersionEnd], ['0'..'9', '.']) do
      Inc(LVersionEnd);
    Result := Copy(LOutput, LVersionMarker, LVersionEnd - LVersionMarker);
  end;

  if Result = '' then
    Result := GetExecutableVersion(AFileName);
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

function FormatFileSize(AFileSize: Int64): string;
begin
  if AFileSize >= 1024 * 1024 then
    Result := Format('%.2f MiB', [AFileSize / (1024 * 1024)])
  else if AFileSize >= 1024 then
    Result := Format('%.2f KiB', [AFileSize / 1024])
  else
    Result := Format('%d bytes', [AFileSize]);
end;

function FormatProfile(AFileSize, ATotalMilliseconds, AExecutionMilliseconds,
  AParsingMilliseconds: Int64; AReportLines: Integer): string;
begin
  var LSpeed := 'n/a';
  if (AReportLines > 0) and (AParsingMilliseconds > 0) then
    LSpeed := Format('%s lines/s', [FormatFloat('#,##0',
      AReportLines * 1000.0 / AParsingMilliseconds)]);
  Result := Format('Profile: size %s | total %.3f s | TDUMP %.3f s | parse %.3f s | %s lines | %s',
    [FormatFileSize(AFileSize), ATotalMilliseconds / 1000.0,
      AExecutionMilliseconds / 1000.0, AParsingMilliseconds / 1000.0,
      FormatFloat('#,##0', AReportLines), LSpeed]);
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

function BuildBinaryAnalysis(const AFileName: string; AWindowHandle: HWND;
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
  var LFinder := TDumpFinder.Create;
  try
    var LInstallations := LFinder.Find;
    try
      var LInstallation := LFinder.FindDefault(LInstallations);
      if LInstallation = nil then
        raise Exception.Create('No installed TDUMP or TDUMP64 executable was found.');

      var LToolKind := tkTDump32;
      var LToolPath := LInstallation.TDumpPath;
      if LInstallation.HasTDump64 then
      begin
        LToolKind := tkTDump64;
        LToolPath := LInstallation.TDump64Path;
      end;

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
        var LRun := LRunner.RunAndParse(AFileName, LToolPath, LToolKind);
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
    finally
      LInstallations.Free;
    end;
  finally
    LFinder.Free;
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
  var LText := TFile.ReadAllText(AFileName, TEncoding.Default);
  if not IsTDumpReport(LText) then
  begin
    Result := Format('%s is text, but it is not a TDUMP report.',
      [AFileName]);
    Exit;
  end;

  var LParser := TDumpParser.Create;
  try
    LParser.OnProgress :=
      procedure(APhase: TDumpParserProgressPhase; ACompletedLines,
        ATotalLines: Integer)
      begin
        CheckCurrentTaskCancellation;
        PostAnalysisProgress(AWindowHandle, AAnalysisId, APhase,
          ACompletedLines, ATotalLines);
      end;
    var LParseStopwatch := TStopwatch.StartNew;
    ADocument := LParser.ParseText(LText, AFileName);
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

constructor TFrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPendingFiles := TQueue<TAnalysisRequest>.Create;
  CheckTDumpAvailability;
  {
  FPhosphorIcon := TPhosphorIcon.Create(Self);
  FPhosphorIcon.Parent := Self;
  FPhosphorIcon.Align := alClient;
  FPhosphorIcon.IconCode := ph_tree_structure;
  FPhosphorIcon.IconColor := clHighlight;
  FPhosphorIcon.Weight := pfwRegular;
  FPhosphorIcon.OnClick := PhosphorIconClick;
  }
end;

procedure TFrmMain.CheckTDumpAvailability;
begin
  FTDumpAvailable := False;
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

        var LToolPath := LInstallation.TDumpPath;
        if LInstallation.HasTDump64 then
          LToolPath := LInstallation.TDump64Path;
        FTDumpAvailable := FileExists(LToolPath);
        if not FTDumpAvailable then
        begin
          LogControl1.Add('TDUMP was not found.', letError);
          Exit;
        end;
        var LMessage := 'TDUMP available: ' + LToolPath;
        var LVersion := GetTDumpVersion(LToolPath);
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
  FActiveRequest := ARequest;
  Inc(FAnalysisId);
  var LAnalysisId := FAnalysisId;
  var LInputFileName := ARequest.FileName;
  var LKind := ARequest.Kind;
  var LWindowHandle := Handle;
  ARequest.Frame.SetStatus('Running: ' + LInputFileName);
  LogControl1.Add('Running: ' + LInputFileName);
  FAnalysisTask := TTask.Run(
    procedure
    begin
      var LDocument: TDumpDocument := nil;
      try
        var LSummary := '';
        var LFileSize := TFile.GetSize(LInputFileName);
        var LExecutionMilliseconds: Int64 := 0;
        var LParsingMilliseconds: Int64 := 0;
        var LReportLines := 0;
        var LTdumpExitCode := 0;
        var LDiagnosticCount := 0;
        var LTdumpParameters := '';
        var LTotalStopwatch := TStopwatch.StartNew;
        case LKind of
          akBinary:
            LSummary := BuildBinaryAnalysis(LInputFileName, LWindowHandle,
              LAnalysisId, LExecutionMilliseconds, LParsingMilliseconds,
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
          LDocument.Free;
          PostAnalysisCompletion(LWindowHandle, LAnalysisId, False,
            Format('Unable to process %s'#13#10'%s: %s', [LInputFileName,
              LException.ClassName, LException.Message]), 0, 0, 0, 0, 0,
            0, 0, '', nil);
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
  if FActiveRequest.ReloadRequested then
  begin
    ADocument.Free;
    var LFileName := FActiveRequest.FileName;
    LogControl1.Add('Reloading: ' + LFileName, letWarning);
    FActiveRequest.TabSheet.Free;
    FActiveRequest.Free;
    FActiveRequest := nil;
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
    LogControl1.Add('Failed: ' + FActiveRequest.FileName, letError);
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
    FActiveRequest.Frame.PopulateTree(ADocument);
    ADocument := nil;
  end;
  ADocument.Free;
  FActiveRequest.Frame.ShowSummary(ASummary);
  FActiveRequest.Free;
  FActiveRequest := nil;
  StartNextAnalysis;
end;

destructor TFrmMain.Destroy;
begin
  FClosing := True;
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
  inherited;
end;

procedure TFrmMain.DrainAnalysisMessages;
begin
  var LMessage: TMsg;
  while PeekMessage(LMessage, Handle, CWMAnalysisProgress,
    CWMAnalysisCompleted, PM_REMOVE) do
    DispatchMessage(LMessage);
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

procedure TFrmMain.PhosphorIconClick(Sender: TObject);
begin
  if FPhosphorIcon.Weight = pfwRegular then
  begin
    FPhosphorIcon.Weight := pfwDuotone;
    Caption := 'TDump Explorer - Phosphor Duotone';
  end
  else
  begin
    FPhosphorIcon.Weight := pfwRegular;
    Caption := 'TDump Explorer - Phosphor Regular';
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
  Result.TabSheet := TTabSheet.Create(PageControl1);
  Result.TabSheet.PageControl := PageControl1;
  Result.TabSheet.Hint := AFileName;
  Result.TabSheet.Caption := ExtractFileName(AFileName);
  if Result.TabSheet.Caption = '' then
    Result.TabSheet.Caption := AFileName;
  Result.Frame := TDumpDocumentFrame.Create(Result.TabSheet);
  Result.Frame.Parent := Result.TabSheet;
  Result.Frame.Align := alClient;
  Result.Frame.SetStatus('Opening: ' + AFileName);
  PageControl1.ActivePage := Result.TabSheet;
end;

procedure TFrmMain.ProcessDroppedFile(const AFileName: string);
begin
  var LExpandedFileName := ExpandFileName(AFileName);
  var LKind: TAnalysisKind;
  try
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
      var LText := TFile.ReadAllText(LExpandedFileName, TEncoding.Default);
      if not IsTDumpReport(LText) then
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

  if (FActiveRequest <> nil) and SameText(FActiveRequest.FileName,
    LExpandedFileName) then
  begin
    if not FActiveRequest.ReloadRequested then
    begin
      FActiveRequest.ReloadRequested := True;
      FActiveRequest.Frame.SetStatus('Reloading: ' + LExpandedFileName);
      LogControl1.Add('Reload requested: ' + LExpandedFileName, letWarning);
      FAnalysisTask.Cancel;
      if FAnalysisTask.Status = TTaskStatus.Canceled then
        CompleteAnalysis(FAnalysisId, '', False, 0, 0, 0, 0, 0, 0, 0, '', nil);
    end;
    Exit;
  end;

  for var LPendingRequest in FPendingFiles do
    if SameText(LPendingRequest.FileName, LExpandedFileName) then
    begin
      LPendingRequest.Discarded := True;
      LPendingRequest.TabSheet.Free;
    end;
  for var LPageIndex := PageControl1.PageCount - 1 downto 0 do
    if SameText(PageControl1.Pages[LPageIndex].Hint, LExpandedFileName) then
      PageControl1.Pages[LPageIndex].Free;

  var LRequest := CreateAnalysisRequest(LExpandedFileName, LKind);
  LogControl1.Add('Opening: ' + LExpandedFileName);

  if FAnalysisTask <> nil then
  begin
    FPendingFiles.Enqueue(LRequest);
    LRequest.Frame.SetStatus('Queued: ' + LExpandedFileName);
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
      LRequest.Free;
      Continue;
    end;
    BeginAnalysis(LRequest);
    Exit;
  end;
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
      (FActiveRequest <> nil) then
    begin
      if not FActiveRequest.ParsingStarted then
      begin
        FActiveRequest.ParsingStarted := True;
        LogControl1.Add('Parsing: ' + FActiveRequest.FileName);
      end;
      FActiveRequest.Frame.SetProgress(LUpdate.CompletedLines,
        LUpdate.TotalLines);
    end;
  finally
    LUpdate.Free;
  end;
end;

procedure TFrmMain.WMDropFiles(var AMessage: TWMDropFiles);
begin
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
    DragFinish(AMessage.Drop);
  end;
end;

end.
