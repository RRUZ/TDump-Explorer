//**************************************************************************************************
//
// Unit TDump.Explorer.Runner
//
// Executes TDUMP, captures its textual report, and projects it through the
// TDump Explorer parser. A run result owns its parsed document.
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
unit TDump.Explorer.Runner;

interface

uses
  TDump.Explorer.Parser;

function TDumpToolKindFromPath(const AToolPath: string): TDumpToolKind;
function IsTDumpReportFile(const AFileName: string): Boolean;

type
  // Chooses the TDUMP view appropriate for a known input-file family.
  TDumpOptionProfile = (topRaw, topExecutable, topObject, topLibrary,
    topELF, topArchive, topMach, topDelphiUnit);

  TDumpAsciiDisplay = (tadDefault, tad8Bit, tad7Bit);
  TDumpHexOffsetMode = (thomDefault, thomRelative, thomAbsolute);
  TDumpRunnerCancellationCheck = reference to function: Boolean;

  // Typed command-line surface for every TDUMP 6.6.2.0 switch.  String
  // fields contain the suffix accepted by TDUMP (without the leading dash).
  TDumpCommandOptions = record
  public
    ShowHelp: Boolean;
    SuppressCopyright: Boolean;
    AsciiDisplay: TDumpAsciiDisplay;
    DisplayHexadecimal: Boolean;
    HexOffsetMode: TDumpHexOffsetMode;
    HexStartOffset: string;
    VerboseObjectRecords: Boolean;
    RawObjectRecords: Boolean;
    DisableDemangling: Boolean;
    DisplayUnmangledNames: Boolean;
    UnassembleObject: Boolean;
    AllowWildcards: Boolean;
    WildcardQuiet: Boolean;
    WildcardQuietWidth: Integer;
    IncludeDebugTables: string;
    ExcludeDebugTables: string;
    Executable: Boolean;
    DisableExecutableDebugInfo: Boolean;
    DisableExecutableLineNumbers: Boolean;
    DisablePEHeader: Boolean;
    DisableNewExecutable: Boolean;
    ExecutableExportsOnly: Boolean;
    ExecutableExports: string;
    IncludeExecutableTables: string;
    DisableExecutableRelocations: Boolean;
    DisableELFHeaders: Boolean;
    DisableELFSymbolTables: Boolean;
    ExecutableSectionDumpEnabled: Boolean;
    ExecutableSectionDump: string;
    ExecutableImportsOnly: Boolean;
    ExecutableImports: string;
    ExecutableImportModules: string;
    AllExecutableExports: Boolean;
    SortAllExportsByRVA: Boolean;
    DisplayPERelocations: Boolean;
    DisplayStrings: Boolean;
    StringMinimumLength: Integer;
    StringBeginningOffset: string;
    StringEndingOffset: string;
    FormatLongStrings: Boolean;
    CaseSensitiveStringSearch: Boolean;
    UnixStringFormat: Boolean;
    StringSearch: string;
    BeginningOffset: string;
    EndingOffset: string;
    ObjectFile: Boolean;
    DisplayObjectDebugInfo: Boolean;
    IncludeObjectRecords: string;
    ExcludeObjectRecords: string;
    ObjectCRCCheck: Boolean;
    ObjectLibrary: Boolean;
    LibraryImpDefsEnabled: Boolean;
    LibraryImpDefs: string;
    LibraryExpDefsEnabled: Boolean;
    LibraryExpDefs: string;
    ELFMemberDumpEnabled: Boolean;
    ELFMemberDump: string;
    ELFMemberList: Boolean;
    ELFMemberExports: Boolean;
    COFFObject: Boolean;
    MachFile: Boolean;
    DisableStandardInputRedirect: Boolean;
    ListFileName: string;
    class function Default: TDumpCommandOptions; static;
    function ToText: string;
  end;

  // Owns one TDUMP process result and, when requested, its parsed projection.
  // OutputText is materialized only for callers that explicitly request it.
  TDumpRunResult = class
  private
    FOutputFileName: string;
    FOwnsOutputFile: Boolean;
    function GetOutputText: string;
  public
    InputFileName: string;
    ListFileName: string;
    ToolPath: string;
    ToolKind: TDumpToolKind;
    Options: string;
    ExitCode: Cardinal;
    ExecutionMilliseconds: Int64;
    ParsingMilliseconds: Int64;
    Document: TDumpDocument;
    destructor Destroy; override;
    property OutputFileName: string read FOutputFileName;
    property OutputText: string read GetOutputText;
  end;

  // Runs a selected TDUMP executable with redirected output.
  // RunAndParse returns a result that owns both captured text and its document.
  TDumpRunner = class
  private
    FOnCancellationCheck: TDumpRunnerCancellationCheck;
    FOnProgress: TDumpParserProgressEvent;
    function Execute(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind; const AOptions, AListFileName: string):
      TDumpRunResult;
    procedure ParseResult(const AResult: TDumpRunResult;
      AToolKind: TDumpToolKind);
    procedure ParseReportFile(const AResult: TDumpRunResult;
      const AReportFileName: string; ADeleteWhenDone: Boolean;
      AToolKind: TDumpToolKind);
    function IsCancellationRequested: Boolean;
  public
    class function GetOptionProfile(const AInputFileName: string):
      TDumpOptionProfile; static;
    class function GetBestOptions(const AInputFileName: string):
      TDumpCommandOptions; static;
    class function GetBestOptionText(const AInputFileName: string): string;
      static;
    property OnProgress: TDumpParserProgressEvent read FOnProgress
      write FOnProgress;
    // Called on the executing thread. Return True to stop the TDUMP process
    // or parser at its next cancellation check.
    property OnCancellationCheck: TDumpRunnerCancellationCheck
      read FOnCancellationCheck write FOnCancellationCheck;
    // Uses the extension-based default profile.  Use the overload with
    // AOptions to pass any supported TDUMP command-line parameters verbatim.
    function Run(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind): TDumpRunResult; overload;
    function Run(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind; const AOptions: string): TDumpRunResult;
      overload;
    function Run(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind; const AOptions: TDumpCommandOptions):
      TDumpRunResult; overload;
    // Uses the extension-based default profile.  Use the overload with
    // AOptions to pass any supported TDUMP command-line parameters verbatim.
    function RunAndParse(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind): TDumpRunResult; overload;
    function RunAndParse(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind; const AOptions: string): TDumpRunResult;
      overload;
    function RunAndParse(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind; const AOptions: TDumpCommandOptions):
      TDumpRunResult; overload;
    // Parses a pre-generated TDUMP report through the same mapped-source,
    // progress and cancellation path used for TDUMP process output.
    function ParseReport(const AReportFileName: string): TDumpRunResult;
  end;

implementation

uses
  System.Classes,
  System.Diagnostics,
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows,
  TDump.Explorer.TextSource;

const
  cReportValidationProbeSize = 64 * 1024;

function TDumpToolKindFromPath(const AToolPath: string): TDumpToolKind;
begin
  if SameText(ExtractFileName(AToolPath), 'tdump64.exe') then
    Result := tkTDump64
  else
    Result := tkTDump32;
end;

function IsTDumpReportFile(const AFileName: string): Boolean;
begin
  var LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    var LReadCount := cReportValidationProbeSize;
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

function QuoteCommandLineArgument(const AValue: string): string;
begin
  // Tool and input paths are quoted so fixed paths with spaces are accepted.
  Result := '"' + StringReplace(AValue, '"', '\"', [rfReplaceAll]) + '"';
end;

function TDumpRunner.IsCancellationRequested: Boolean;
begin
  Result := Assigned(FOnCancellationCheck) and FOnCancellationCheck();
end;

procedure RaiseLastError(const AAction: string);
begin
  var LErrorCode := GetLastError;
  raise EOSError.CreateFmt('%s failed (%d): %s', [AAction, LErrorCode,
    SysErrorMessage(LErrorCode)]);
end;

destructor TDumpRunResult.Destroy;
begin
  Document.Free;
  if FOwnsOutputFile and (FOutputFileName <> '') and
    FileExists(FOutputFileName) then
    TFile.Delete(FOutputFileName);
  inherited;
end;

function TDumpRunResult.GetOutputText: string;
begin
  if (FOutputFileName = '') or not FileExists(FOutputFileName) then
    Exit('');
  Result := TFile.ReadAllText(FOutputFileName, TEncoding.Default);
end;

procedure CheckReportFileSize(const AFileName: string);
begin
  var LSize := TFile.GetSize(AFileName);
  if LSize > cMaxTDumpReportSize then
    raise ERangeError.CreateFmt('TDUMP output exceeds the %d MiB size limit: %s',
      [cMaxTDumpReportSize div (1024 * 1024), AFileName]);
end;

function CombineReportFiles(const AFirstFileName,
  ASecondFileName: string): string;
const
  cLineBreak: array[0..1] of Byte = (13, 10);
begin
  var LCombinedSize := TFile.GetSize(AFirstFileName) +
    TFile.GetSize(ASecondFileName) + 2;
  if LCombinedSize > cMaxTDumpReportSize then
    raise ERangeError.CreateFmt('Combined TDUMP output exceeds the %d MiB size limit.',
      [cMaxTDumpReportSize div (1024 * 1024)]);

  Result := TPath.GetTempFileName;
  try
    var LOutput := TFileStream.Create(Result, fmCreate or fmShareDenyWrite);
    var LFirstInput: TFileStream := nil;
    var LSecondInput: TFileStream := nil;
    try
      LFirstInput := TFileStream.Create(AFirstFileName,
        fmOpenRead or fmShareDenyNone);
      LOutput.CopyFrom(LFirstInput, 0);
      LOutput.WriteBuffer(cLineBreak, SizeOf(cLineBreak));
      LSecondInput := TFileStream.Create(ASecondFileName,
        fmOpenRead or fmShareDenyNone);
      LOutput.CopyFrom(LSecondInput, 0);
    finally
      LSecondInput.Free;
      LFirstInput.Free;
      LOutput.Free;
    end;
  except
    if FileExists(Result) then
      TFile.Delete(Result);
    raise;
  end;
end;

class function TDumpCommandOptions.Default: TDumpCommandOptions;
begin
  Result := System.Default(TDumpCommandOptions);
  Result.DisableStandardInputRedirect := True;
end;

function TDumpCommandOptions.ToText: string;
  procedure AddOption(const AOption: string);
  begin
    if AOption = '' then
      Exit;
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + AOption;
  end;
begin
  if (AsciiDisplay <> tadDefault) and (DisplayHexadecimal or
    (HexOffsetMode <> thomDefault) or (HexStartOffset <> '')) then
    raise EArgumentException.Create(
      'TDUMP ASCII and hexadecimal display modes cannot be used together.');
  if Ord(Executable) + Ord(ObjectFile) + Ord(ObjectLibrary) +
    Ord(COFFObject) + Ord(MachFile) > 1 then
    raise EArgumentException.Create(
      'Only one TDUMP input-file display mode can be forced at a time.');

  if ShowHelp then
    AddOption('-?');
  if SuppressCopyright then
    AddOption('-q');
  case AsciiDisplay of
    tad8Bit: AddOption('-a');
    tad7Bit: AddOption('-a7');
  end;
  if DisplayHexadecimal or (HexOffsetMode <> thomDefault) or
    (HexStartOffset <> '') then
  begin
    var LHexOption := '-h';
    case HexOffsetMode of
      thomRelative: LHexOption := LHexOption + 'r';
      thomAbsolute: LHexOption := LHexOption + 'a';
    end;
    if HexStartOffset <> '' then
      LHexOption := LHexOption + '=' + HexStartOffset;
    AddOption(LHexOption);
  end;
  if VerboseObjectRecords then
    AddOption('-v');
  if RawObjectRecords then
    AddOption('-r');
  if DisableDemangling then
    AddOption('-m');
  if DisplayUnmangledNames then
    AddOption('-um');
  if UnassembleObject then
    AddOption('-ua');
  if AllowWildcards then
    AddOption('-w');
  if WildcardQuiet then
  begin
    var LWildcardOption := '-wq';
    if WildcardQuietWidth > 0 then
      LWildcardOption := LWildcardOption + WildcardQuietWidth.ToString;
    AddOption(LWildcardOption);
  end;
  if IncludeDebugTables <> '' then
    AddOption('-i' + IncludeDebugTables);
  if ExcludeDebugTables <> '' then
    AddOption('-x' + ExcludeDebugTables);
  if Executable then
    AddOption('-e');
  if DisableExecutableDebugInfo then
    AddOption('-ed');
  if DisableExecutableLineNumbers then
    AddOption('-el');
  if DisablePEHeader then
    AddOption('-ep');
  if DisableNewExecutable then
    AddOption('-ex');
  if ExecutableExportsOnly or (ExecutableExports <> '') then
  begin
    var LExportsOption := '-ee';
    if ExecutableExports <> '' then
      LExportsOption := LExportsOption + '=' + ExecutableExports;
    AddOption(LExportsOption);
  end;
  if IncludeExecutableTables <> '' then
    AddOption('-ei' + IncludeExecutableTables);
  if DisableExecutableRelocations then
    AddOption('-er');
  if DisableELFHeaders then
    AddOption('-eh');
  if DisableELFSymbolTables then
    AddOption('-et');
  if ExecutableSectionDumpEnabled or (ExecutableSectionDump <> '') then
  begin
    var LSectionOption := '-es';
    if ExecutableSectionDump <> '' then
      LSectionOption := LSectionOption + '=' + ExecutableSectionDump;
    AddOption(LSectionOption);
  end;
  if ExecutableImportsOnly or (ExecutableImports <> '') then
  begin
    var LImportsOption := '-em';
    if ExecutableImports <> '' then
      LImportsOption := LImportsOption + '=' + ExecutableImports;
    AddOption(LImportsOption);
  end;
  if ExecutableImportModules <> '' then
    AddOption('-em.' + ExecutableImportModules);
  if AllExecutableExports then
  begin
    var LExportOption := '-ea';
    if SortAllExportsByRVA then
      LExportOption := LExportOption + ':v';
    AddOption(LExportOption);
  end;
  if DisplayPERelocations then
    AddOption('-R');
  if DisplayStrings or (StringMinimumLength > 0) or (StringBeginningOffset <> '') or
    (StringEndingOffset <> '') or FormatLongStrings or
    CaseSensitiveStringSearch or UnixStringFormat or (StringSearch <> '') then
  begin
    var LStringOption := '-s';
    if StringMinimumLength > 0 then
      LStringOption := LStringOption + StringMinimumLength.ToString;
    if StringBeginningOffset <> '' then
      LStringOption := LStringOption + 'b' + StringBeginningOffset;
    if StringEndingOffset <> '' then
      LStringOption := LStringOption + 'e' + StringEndingOffset;
    if FormatLongStrings then
      LStringOption := LStringOption + 'f';
    if CaseSensitiveStringSearch then
      LStringOption := LStringOption + 's';
    if UnixStringFormat then
      LStringOption := LStringOption + 'u';
    if StringSearch <> '' then
      LStringOption := LStringOption + '=' + StringSearch;
    AddOption(LStringOption);
  end;
  if BeginningOffset <> '' then
    AddOption('-b' + BeginningOffset);
  if EndingOffset <> '' then
    AddOption('-t' + EndingOffset);
  if ObjectFile then
    AddOption('-o');
  if DisplayObjectDebugInfo then
    AddOption('-d');
  if IncludeObjectRecords <> '' then
    AddOption('-oi' + IncludeObjectRecords);
  if ExcludeObjectRecords <> '' then
    AddOption('-ox' + ExcludeObjectRecords);
  if ObjectCRCCheck then
    AddOption('-oc');
  if ObjectLibrary then
    AddOption('-l');
  if LibraryImpDefsEnabled or (LibraryImpDefs <> '') then
  begin
    var LImpDefOption := '-li';
    if LibraryImpDefs <> '' then
      LImpDefOption := LImpDefOption + '=' + LibraryImpDefs;
    AddOption(LImpDefOption);
  end;
  if LibraryExpDefsEnabled or (LibraryExpDefs <> '') then
  begin
    var LExpDefOption := '-le';
    if LibraryExpDefs <> '' then
      LExpDefOption := LExpDefOption + '=' + LibraryExpDefs;
    AddOption(LExpDefOption);
  end;
  if ELFMemberDumpEnabled or (ELFMemberDump <> '') then
  begin
    var LMemberOption := '-lm';
    if ELFMemberDump <> '' then
      LMemberOption := LMemberOption + '=' + ELFMemberDump;
    AddOption(LMemberOption);
  end;
  if ELFMemberList then
    AddOption('-lh');
  if ELFMemberExports then
    AddOption('-lt');
  if COFFObject then
    AddOption('-C');
  if MachFile then
    AddOption('-M');
  if DisableStandardInputRedirect then
    AddOption('-ns');
end;

class function TDumpRunner.GetOptionProfile(const AInputFileName: string):
  TDumpOptionProfile;
begin
  var LExtension := LowerCase(ExtractFileExt(AInputFileName));
  if (LExtension = '.exe') or (LExtension = '.dll') or
    (LExtension = '.bpl') or (LExtension = '.dpl') then
    Exit(topExecutable);
  if (LExtension = '.obj') or (LExtension = '.o') then
    Exit(topObject);
  if LExtension = '.lib' then
    Exit(topLibrary);
  if (LExtension = '.elf') or (LExtension = '.so') then
    Exit(topELF);
  if (LExtension = '.ar') or (LExtension = '.a') then
    Exit(topArchive);
  if (LExtension = '.dylib') or (LExtension = '.bundle') or
    (LExtension = '.mach') then
    Exit(topMach);
  if LExtension = '.dcu' then
    Exit(topDelphiUnit);
  Result := topRaw;
end;

class function TDumpRunner.GetBestOptions(const AInputFileName: string):
  TDumpCommandOptions;
begin
  Result := TDumpCommandOptions.Default;
  case GetOptionProfile(AInputFileName) of
    topExecutable:
      begin
        Result.Executable := True;
        Result.DisableExecutableDebugInfo := True;
      end;
    topObject:
      Result.ObjectFile := True;
    topLibrary:
      Result.ObjectLibrary := True;
    topELF:
      Result.Executable := True;
    topArchive:
      begin
        // -lh applies only to ELF libraries; AR archives use TDUMP's default dump.
      end;
    topMach:
      Result.MachFile := True;
  end;
end;

class function TDumpRunner.GetBestOptionText(const AInputFileName: string): string;
begin
  Result := GetBestOptions(AInputFileName).ToText;
end;

function TDumpRunner.Execute(const AInputFileName, AToolPath: string;
  AToolKind: TDumpToolKind; const AOptions, AListFileName: string):
  TDumpRunResult;
begin
  if not FileExists(AInputFileName) then
    raise EFOpenError.CreateFmt('TDUMP input file was not found: %s',
      [AInputFileName]);
  if not FileExists(AToolPath) then
    raise EFOpenError.CreateFmt('TDUMP executable was not found: %s',
      [AToolPath]);

  Result := TDumpRunResult.Create;
  try
    Result.InputFileName := ExpandFileName(AInputFileName);
    if AListFileName <> '' then
      Result.ListFileName := ExpandFileName(AListFileName);
    Result.ToolPath := ExpandFileName(AToolPath);
    Result.ToolKind := AToolKind;
    Result.Options := Trim(AOptions);

    Result.FOutputFileName := TPath.GetTempFileName;
    Result.FOwnsOutputFile := True;
    var LOutputStream := TFileStream.Create(Result.FOutputFileName,
         fmCreate or fmShareDenyWrite);
      try
        var LInputHandle := CreateFile('NUL', GENERIC_READ,
          FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING,
          FILE_ATTRIBUTE_NORMAL, 0);
        if LInputHandle = INVALID_HANDLE_VALUE then
          RaiseLastError('Opening NUL for TDUMP input');
        try
          if not SetHandleInformation(LOutputStream.Handle, HANDLE_FLAG_INHERIT,
            HANDLE_FLAG_INHERIT) then
            RaiseLastError('Making TDUMP output handle inheritable');
          if not SetHandleInformation(LInputHandle, HANDLE_FLAG_INHERIT,
            HANDLE_FLAG_INHERIT) then
            RaiseLastError('Making TDUMP input handle inheritable');

          var LCommandLine := QuoteCommandLineArgument(Result.ToolPath);
          if Result.Options <> '' then
            LCommandLine := LCommandLine + ' ' + Result.Options;
          LCommandLine := LCommandLine + ' ' +
            QuoteCommandLineArgument(Result.InputFileName);
          if Result.ListFileName <> '' then
            LCommandLine := LCommandLine + ' ' +
              QuoteCommandLineArgument(Result.ListFileName);

          var LStartupInfo: TStartupInfo;
          ZeroMemory(@LStartupInfo, SizeOf(LStartupInfo));
          LStartupInfo.cb := SizeOf(LStartupInfo);
          LStartupInfo.dwFlags := STARTF_USESTDHANDLES;
          LStartupInfo.hStdInput := LInputHandle;
          LStartupInfo.hStdOutput := LOutputStream.Handle;
          LStartupInfo.hStdError := LOutputStream.Handle;

          var LProcessInformation: TProcessInformation;
          ZeroMemory(@LProcessInformation, SizeOf(LProcessInformation));
          if not CreateProcess(nil, PChar(LCommandLine), nil, nil, True,
            CREATE_NO_WINDOW, nil, nil, LStartupInfo, LProcessInformation) then
            RaiseLastError('Starting TDUMP');
          var LExecutionStopwatch := TStopwatch.StartNew;
          try
            while True do
            begin
              if IsCancellationRequested then
              begin
                TerminateProcess(LProcessInformation.hProcess, ERROR_CANCELLED);
                WaitForSingleObject(LProcessInformation.hProcess, INFINITE);
                raise EAbort.Create('TDUMP analysis was cancelled.');
              end;
              case WaitForSingleObject(LProcessInformation.hProcess, 50) of
                WAIT_OBJECT_0:
                  Break;
                WAIT_FAILED:
                  RaiseLastError('Waiting for TDUMP');
              end;
            end;
            if not GetExitCodeProcess(LProcessInformation.hProcess, Result.ExitCode) then
              RaiseLastError('Reading the TDUMP exit code');
          finally
            LExecutionStopwatch.Stop;
            Result.ExecutionMilliseconds := LExecutionStopwatch.ElapsedMilliseconds;
            CloseHandle(LProcessInformation.hThread);
            CloseHandle(LProcessInformation.hProcess);
          end;
        finally
          CloseHandle(LInputHandle);
        end;
      finally
        LOutputStream.Free;
      end;

      CheckReportFileSize(Result.FOutputFileName);
      if (Result.ListFileName <> '') and FileExists(Result.ListFileName) then
      begin
        var LCombinedFileName := CombineReportFiles(Result.ListFileName,
          Result.FOutputFileName);
        TFile.Delete(Result.FOutputFileName);
        Result.FOutputFileName := LCombinedFileName;
      end;
  except
    Result.Free;
    raise;
  end;
end;

function TDumpRunner.Run(const AInputFileName, AToolPath: string;
  AToolKind: TDumpToolKind): TDumpRunResult;
begin
  Result := Execute(AInputFileName, AToolPath, AToolKind,
    GetBestOptionText(AInputFileName), '');
end;

function TDumpRunner.Run(const AInputFileName, AToolPath: string;
  AToolKind: TDumpToolKind; const AOptions: string): TDumpRunResult;
begin
  Result := Execute(AInputFileName, AToolPath, AToolKind, AOptions, '');
end;

function TDumpRunner.Run(const AInputFileName, AToolPath: string;
  AToolKind: TDumpToolKind; const AOptions: TDumpCommandOptions):
  TDumpRunResult;
begin
  Result := Execute(AInputFileName, AToolPath, AToolKind, AOptions.ToText,
    AOptions.ListFileName);
end;

procedure TDumpRunner.ParseResult(const AResult: TDumpRunResult;
  AToolKind: TDumpToolKind);
begin
  ParseReportFile(AResult, AResult.FOutputFileName, True, AToolKind);
end;

procedure TDumpRunner.ParseReportFile(const AResult: TDumpRunResult;
  const AReportFileName: string; ADeleteWhenDone: Boolean;
  AToolKind: TDumpToolKind);
begin
  var LParseStopwatch := TStopwatch.StartNew;
  var LParser := TDumpParser.Create;
  try
    LParser.OnProgress :=
      procedure(APhase: TDumpParserProgressPhase; ACompletedLines,
        ATotalLines: Integer)
      begin
        if IsCancellationRequested then
          raise EAbort.Create('TDUMP parsing was cancelled.');
        if Assigned(FOnProgress) then
          FOnProgress(APhase, ACompletedLines, ATotalLines);
      end;
    var LSource := TDumpMappedTextSource.Create(AReportFileName,
      ADeleteWhenDone);
    if ADeleteWhenDone then
      AResult.FOwnsOutputFile := False;
    try
      AResult.Document := LParser.ParseSource(LSource, AResult.InputFileName);
      LSource := nil;
    finally
      LSource.Free;
    end;
    if AResult.Document.ToolKind = tkUnknown then
    begin
      AResult.Document.ToolKind := AToolKind;
      AResult.Document.PrimaryRun.ToolKind := AToolKind;
    end;
  finally
    LParseStopwatch.Stop;
    AResult.ParsingMilliseconds := LParseStopwatch.ElapsedMilliseconds;
    LParser.Free;
  end;
end;

function TDumpRunner.ParseReport(
  const AReportFileName: string): TDumpRunResult;
begin
  if TFile.GetSize(AReportFileName) > CMaxTDumpReportSize then
    raise Exception.CreateFmt('%s exceeds the 100 MB file limit.',
      [AReportFileName]);
  if not IsTDumpReportFile(AReportFileName) then
    raise Exception.CreateFmt('%s is text, but it is not a TDUMP report.',
      [AReportFileName]);

  Result := TDumpRunResult.Create;
  try
    Result.InputFileName := AReportFileName;
    ParseReportFile(Result, AReportFileName, False, tkUnknown);
  except
    Result.Free;
    raise;
  end;
end;

function TDumpRunner.RunAndParse(const AInputFileName, AToolPath: string;
  AToolKind: TDumpToolKind): TDumpRunResult;
begin
  Result := RunAndParse(AInputFileName, AToolPath, AToolKind,
    GetBestOptions(AInputFileName));
end;

function TDumpRunner.RunAndParse(const AInputFileName, AToolPath: string;
  AToolKind: TDumpToolKind; const AOptions: string): TDumpRunResult;
begin
  Result := Run(AInputFileName, AToolPath, AToolKind, AOptions);
  try
    ParseResult(Result, AToolKind);
  except
    Result.Free;
    raise;
  end;
end;

function TDumpRunner.RunAndParse(const AInputFileName, AToolPath: string;
  AToolKind: TDumpToolKind; const AOptions: TDumpCommandOptions):
  TDumpRunResult;
begin
  Result := Run(AInputFileName, AToolPath, AToolKind, AOptions);
  try
    ParseResult(Result, AToolKind);
  except
    Result.Free;
    raise;
  end;
end;

end.
