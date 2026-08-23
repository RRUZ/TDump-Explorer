unit TDump.Explorer.Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.IOUtils, System.StrUtils, System.TypInfo, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Winapi.ShellAPI, TDump.Explorer.Finder,
  TDump.Explorer.Parser, TDump.Explorer.Phosphor.Font, TDump.Explorer.Runner,
  Vcl.ComCtrls;

type
  TFrmMain = class(TForm)
    Memo1: TMemo;
    ProgressBar1: TProgressBar;
  private
    FPhosphorIcon: TPhosphorIcon;
    procedure AnalyzeBinaryFile(const AFileName: string);
    procedure AnalyzeReportFile(const AFileName: string);
    function IsTextFile(const AFileName: string): Boolean;
    procedure PhosphorIconClick(Sender: TObject);
    procedure ProcessDroppedFile(const AFileName: string);
    procedure StartParserProgress;
    procedure StopParserProgress;
    procedure ShowDocumentSummary(const ATitle: string;
      const ADocument: TDumpDocument; const ATDumpParameters: string = '');
    procedure UpdateParserProgress(APhase: TDumpParserProgressPhase;
      ACompletedLines, ATotalLines: Integer);
    procedure WMDropFiles(var AMessage: TWMDropFiles); message WM_DROPFILES;
  protected
    procedure CreateWnd; override;
    procedure DestroyWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure OpenInputFile(const AFileName: string);
  end;

var
  FrmMain: TFrmMain;

implementation

{$R *.dfm}

const
  CTextProbeSize = 8192;

procedure TFrmMain.AnalyzeBinaryFile(const AFileName: string);
begin
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
        LRunner.OnProgress :=
          procedure(APhase: TDumpParserProgressPhase; ACompletedLines,
            ATotalLines: Integer)
          begin
            UpdateParserProgress(APhase, ACompletedLines, ATotalLines);
          end;
        StartParserProgress;
        var LRun := LRunner.RunAndParse(AFileName, LToolPath, LToolKind);
        try
          ShowDocumentSummary(Format('TDUMP analysis (exit code %d)',
            [LRun.ExitCode]), LRun.Document, LRun.Options);
        finally
          LRun.Free;
        end;
      finally
        StopParserProgress;
        LRunner.Free;
      end;
    finally
      LInstallations.Free;
    end;
  finally
    LFinder.Free;
  end;
end;

procedure TFrmMain.AnalyzeReportFile(const AFileName: string);
begin
  var LText := TFile.ReadAllText(AFileName, TEncoding.Default);
  if not IsTDumpReport(LText) then
  begin
    Memo1.Lines.Text := Format('%s is text, but it is not a TDUMP report.',
      [AFileName]);
    Exit;
  end;

  var LParser := TDumpParser.Create;
  try
    LParser.OnProgress :=
      procedure(APhase: TDumpParserProgressPhase; ACompletedLines,
        ATotalLines: Integer)
      begin
        UpdateParserProgress(APhase, ACompletedLines, ATotalLines);
      end;
    StartParserProgress;
    var LDocument := LParser.ParseText(LText, AFileName);
    try
      ShowDocumentSummary('TDUMP report parsed', LDocument);
    finally
      LDocument.Free;
    end;
  finally
    StopParserProgress;
    LParser.Free;
  end;
end;

constructor TFrmMain.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
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

procedure TFrmMain.ProcessDroppedFile(const AFileName: string);
begin
  Memo1.Lines.Text := 'Processing: ' + AFileName;
  try
    if IsTDumpBinaryFile(AFileName) or not IsTextFile(AFileName) then
      AnalyzeBinaryFile(AFileName)
    else
      AnalyzeReportFile(AFileName);
  except
    on LException: Exception do
      Memo1.Lines.Text := Format('Unable to process %s'#13#10'%s: %s',
        [AFileName, LException.ClassName, LException.Message]);
  end;
end;

procedure TFrmMain.StartParserProgress;
begin
  ProgressBar1.Min := 0;
  ProgressBar1.Max := 100;
  ProgressBar1.Position := 0;
  ProgressBar1.Update;
end;

procedure TFrmMain.StopParserProgress;
begin
  ProgressBar1.Position := ProgressBar1.Max;
  ProgressBar1.Update;
end;

procedure TFrmMain.ShowDocumentSummary(const ATitle: string;
  const ADocument: TDumpDocument; const ATDumpParameters: string);
begin
  Memo1.Lines.BeginUpdate;
  try
    Memo1.Clear;
    Memo1.Lines.Add(ATitle);
    Memo1.Lines.Add('Source: ' + ADocument.SourceFileName);
    if ADocument.TurboDumpHeader <> '' then
      Memo1.Lines.Add('TDUMP header: ' + ADocument.TurboDumpHeader);
    Memo1.Lines.Add('Tool: ' + GetEnumName(TypeInfo(TDumpToolKind),
      Ord(ADocument.ToolKind)));
    if ATDumpParameters <> '' then
      Memo1.Lines.Add('TDUMP parameters: ' + ATDumpParameters);
    if ADocument.ToolVersion <> '' then
      Memo1.Lines.Add('TDUMP version: ' + ADocument.ToolVersion);
    Memo1.Lines.Add('File kind: ' + GetEnumName(TypeInfo(TDumpFileKind),
      Ord(ADocument.FileKind)));
    Memo1.Lines.Add('Architecture: ' + ADocument.Architecture);
    Memo1.Lines.Add(Format('Report lines: %d', [ADocument.Lines.Count]));
    Memo1.Lines.Add('');
    Memo1.Lines.Add(Format('Headers: %d', [ADocument.Headers.Count]));

    for var LHeader in ADocument.Headers do
    begin
      Memo1.Lines.Add(Format('  %s (lines %d..%d)', [LHeader.Name,
        LHeader.StartLine, LHeader.EndLine]));
      for var LPropertyIndex := 0 to LHeader.Properties.Count - 1 do
      begin
        if LPropertyIndex = 12 then
        begin
          Memo1.Lines.Add('    ...');
          Break;
        end;
        var LProperty := LHeader.Properties[LPropertyIndex];
        Memo1.Lines.Add(Format('    %s = %s', [LProperty.Name,
          LProperty.RawValue]));
      end;
    end;

    Memo1.Lines.Add('');
    Memo1.Lines.Add(Format('Sections: %d', [ADocument.Sections.Count]));
    Memo1.Lines.Add(Format('Import modules: %d', [ADocument.Imports.Count]));
    Memo1.Lines.Add(Format('Exports: %d', [ADocument.ExportList.Count]));
    Memo1.Lines.Add(Format('Resources: %d', [ADocument.Resources.Count]));
    Memo1.Lines.Add(Format('Diagnostics: %d', [ADocument.Diagnostics.Count]));
    for var LDiagnosticIndex := 0 to ADocument.Diagnostics.Count - 1 do
    begin
      if LDiagnosticIndex = 12 then
      begin
        Memo1.Lines.Add('  ...');
        Break;
      end;
      var LDiagnostic := ADocument.Diagnostics[LDiagnosticIndex];
      var LDiagnosticText := LDiagnostic.RawLine;
      if LDiagnosticText = '' then
        LDiagnosticText := LDiagnostic.Message;
      Memo1.Lines.Add(Format('  Line %d: %s', [LDiagnostic.LineNumber,
        LDiagnosticText]));
    end;
  finally
    Memo1.Lines.EndUpdate;
  end;
end;

procedure TFrmMain.UpdateParserProgress(APhase: TDumpParserProgressPhase;
  ACompletedLines, ATotalLines: Integer);
begin
  if ATotalLines <= 0 then
    Exit;

  ProgressBar1.Max := ATotalLines;
  var LPosition := ACompletedLines;
  if LPosition < ProgressBar1.Min then
    LPosition := ProgressBar1.Min
  else if LPosition > ProgressBar1.Max then
    LPosition := ProgressBar1.Max;
  ProgressBar1.Position := LPosition;
  ProgressBar1.Update;
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
