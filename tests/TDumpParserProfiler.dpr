program TDumpParserProfiler;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  Winapi.PsAPI,
  System.SysUtils,
  System.Diagnostics,
  System.IOUtils,
  System.Math,
  TDump.Explorer.TextSource in '..\source\parser\TDump.Explorer.TextSource.pas',
  TDump.Explorer.Parser in '..\source\parser\TDump.Explorer.parser.pas';

type
  TFixtureProfile = record
    FileName: string;
    SizeBytes: Int64;
    LineCount: Integer;
    DiagnosticCount: Integer;
    RelocationCount: Integer;
    UnsupportedStructureCount: Integer;
    UnsupportedStructures: TArray<string>;
    TotalMilliseconds: Double;
    PeakPrivateBytes: UInt64;
    RetainedPrivateBytes: UInt64;
  end;

function CurrentPrivateBytes: UInt64;
begin
  var LCounters: TProcessMemoryCountersEx;
  ZeroMemory(@LCounters, SizeOf(LCounters));
  LCounters.cb := SizeOf(LCounters);
  if not GetProcessMemoryInfo(GetCurrentProcess,
    PPROCESS_MEMORY_COUNTERS(@LCounters), SizeOf(LCounters)) then
    RaiseLastOSError;
  Result := LCounters.PrivateUsage;
end;

function ProgressPhaseName(APhase: TDumpParserProgressPhase): string;
begin
  case APhase of
    ppPreparing: Result := 'Preparing';
    ppLineCatalog: Result := 'Cataloging lines';
    ppSemanticModel: Result := 'Projecting models';
    ppBorlandSymbols: Result := 'Parsing Borland symbols';
    ppComplete: Result := 'Complete';
  else
    Result := 'Unknown';
  end;
end;

function ParseIterationCount(const AText: string): Integer;
begin
  Result := 1;
  if not TryStrToInt(AText, Result) or (Result < 1) then
    raise EConvertError.CreateFmt('Iteration count must be a positive integer: %s',
      [AText]);
end;

function ProfileFixture(const AFileName: string;
  AIterations: Integer): TFixtureProfile;
begin
  Result.FileName := AFileName;
  Result.SizeBytes := TFile.GetSize(AFileName);
  for var LIteration := 1 to AIterations do
  begin
    var LBaselinePrivateBytes := CurrentPrivateBytes;
    var LPeakPrivateBytes := LBaselinePrivateBytes;
    var LParser := TDumpParser.Create;
    try
      var LShowProgress := False;
      var LProgressWritten := False;
      var LLastProgressPhase := ppComplete;
      var LLastPercent := -1;
      LParser.OnProgress :=
        procedure(APhase: TDumpParserProgressPhase; ACompletedLines,
          ATotalLines: Integer)
        begin
          LPeakPrivateBytes := Max(LPeakPrivateBytes, CurrentPrivateBytes);
          LShowProgress := ATotalLines >= 100000;
          if not LShowProgress then
            Exit;
          var LPercent := 0;
          if ATotalLines > 0 then
            LPercent := ACompletedLines * 100 div ATotalLines;
          if (APhase = LLastProgressPhase) and
            ((LPercent div 10) = (LLastPercent div 10)) then
            Exit;
          if not LProgressWritten then
          begin
            Writeln('  Parsing ', ExtractFileName(AFileName), ' (run ',
              LIteration, ' of ', AIterations, ')');
            LProgressWritten := True;
          end;
          Write(#13, '    ', ProgressPhaseName(APhase), ': ', LPercent:3,
            '%', StringOfChar(' ', 32));
          LLastProgressPhase := APhase;
          LLastPercent := LPercent;
        end;
      var LStopwatch := TStopwatch.StartNew;
      var LDocument := LParser.ParseFile(AFileName);
      LStopwatch.Stop;
      var LRetainedPrivateBytes := CurrentPrivateBytes;
      LPeakPrivateBytes := Max(LPeakPrivateBytes, LRetainedPrivateBytes);
      if LPeakPrivateBytes > LBaselinePrivateBytes then
        Result.PeakPrivateBytes := Max(Result.PeakPrivateBytes,
          LPeakPrivateBytes - LBaselinePrivateBytes);
      if LRetainedPrivateBytes > LBaselinePrivateBytes then
        Result.RetainedPrivateBytes := Max(Result.RetainedPrivateBytes,
          LRetainedPrivateBytes - LBaselinePrivateBytes);
      if LProgressWritten then
        Writeln;
      Result.TotalMilliseconds := Result.TotalMilliseconds +
        LStopwatch.Elapsed.TotalMilliseconds;
      if LIteration = 1 then
      begin
        Result.LineCount := LDocument.Lines.Count;
        Result.DiagnosticCount := LDocument.Diagnostics.Count;
        Result.RelocationCount := LDocument.Relocations.Count;
        Result.UnsupportedStructureCount := LDocument.UnsupportedStructures.Count;
        var LSampleCount := Result.UnsupportedStructureCount;
        if LSampleCount > 10 then
          LSampleCount := 10;
        SetLength(Result.UnsupportedStructures, LSampleCount);
        for var LIndex := 0 to LSampleCount - 1 do
        begin
          var LStructure := LDocument.UnsupportedStructures[LIndex];
          Result.UnsupportedStructures[LIndex] := 'line ' +
            LStructure.SourceLine.LineNumber.ToString + ': ' +
            LStructure.Description;
        end;
      end;
      LDocument.Free;
    finally
      LParser.Free;
    end;
  end;
end;

procedure WriteProfile(const AProfile: TFixtureProfile; AIterations: Integer);
begin
  var LAverageMilliseconds := AProfile.TotalMilliseconds / AIterations;
  var LSeconds := AProfile.TotalMilliseconds / 1000.0;
  var LMebibytes := AProfile.SizeBytes * AIterations / (1024.0 * 1024.0);
  var LThroughput := 0.0;
  if LSeconds > 0.0 then
    LThroughput := LMebibytes / LSeconds;
  Writeln(ExtractFileName(AProfile.FileName), ': ', AProfile.LineCount,
    ' lines, ', AIterations, ' runs, total ', FormatFloat('0.000',
    AProfile.TotalMilliseconds), ' ms, average ', FormatFloat('0.000',
    LAverageMilliseconds), ' ms, ', FormatFloat('0.000', LThroughput),
    ' MiB/s, relocations ', AProfile.RelocationCount, ', diagnostics ',
    AProfile.DiagnosticCount, ', unsupported ',
    AProfile.UnsupportedStructureCount);
  Writeln('  Memory delta: peak ', FormatFloat('0.00',
    AProfile.PeakPrivateBytes / (1024.0 * 1024.0)), ' MiB, retained ',
    FormatFloat('0.00', AProfile.RetainedPrivateBytes / (1024.0 * 1024.0)),
    ' MiB (mapped report pages excluded from private bytes)');
  for var LStructure in AProfile.UnsupportedStructures do
    Writeln('  Unsupported ', LStructure);
  if Length(AProfile.UnsupportedStructures) < AProfile.UnsupportedStructureCount then
    Writeln('  ... ', AProfile.UnsupportedStructureCount -
      Length(AProfile.UnsupportedStructures), ' more unsupported block(s)');
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    var LFixtureDirectory := TPath.Combine(ExtractFilePath(ParamStr(0)),
      '..\fixtures\generated');
    if ParamCount >= 1 then
      LFixtureDirectory := ExpandFileName(ParamStr(1));
    var LIterations := 1;
    if ParamCount >= 2 then
      LIterations := ParseIterationCount(ParamStr(2));
    var LFiles: TArray<string>;
    if TFile.Exists(LFixtureDirectory) then
      LFiles := [LFixtureDirectory]
    else if TDirectory.Exists(LFixtureDirectory) then
      LFiles := TDirectory.GetFiles(LFixtureDirectory, '*.tdump',
        TSearchOption.soAllDirectories)
    else
      raise EDirectoryNotFoundException.CreateFmt(
        'Fixture file or directory was not found: %s', [LFixtureDirectory]);
    if Length(LFiles) = 0 then
      raise Exception.CreateFmt('No *.tdump fixtures found under: %s',
        [LFixtureDirectory]);

    Writeln('TDump parser performance profile');
    Writeln('Fixture directory: ', LFixtureDirectory);
    Writeln('Iterations per fixture: ', LIterations);
    Writeln;

    var LTotalBytes: Int64 := 0;
    var LTotalMilliseconds := 0.0;
    for var LFileName in LFiles do
    begin
      var LProfile := ProfileFixture(LFileName, LIterations);
      WriteProfile(LProfile, LIterations);
      Inc(LTotalBytes, LProfile.SizeBytes);
      LTotalMilliseconds := LTotalMilliseconds + LProfile.TotalMilliseconds;
    end;

    var LTotalSeconds := LTotalMilliseconds / 1000.0;
    var LTotalMebibytes := LTotalBytes * LIterations / (1024.0 * 1024.0);
    var LTotalThroughput := 0.0;
    if LTotalSeconds > 0.0 then
      LTotalThroughput := LTotalMebibytes / LTotalSeconds;
    Writeln;
    Writeln('Aggregate: ', Length(LFiles), ' fixture(s), ', LIterations,
      ' runs each, total ', FormatFloat('0.000', LTotalMilliseconds),
      ' ms, ', FormatFloat('0.000', LTotalThroughput), ' MiB/s');
    Readln;
  except
    on E: Exception do
    begin
      Writeln(ErrOutput, E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
