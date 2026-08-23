//**************************************************************************************************
//
// Unit TDump.Explorer.Runner
//
// Executes TDUMP, captures its textual report, and projects it through the
// TDump Explorer parser. A run result owns its parsed document.
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.Runner;

interface

uses
  TDump.Explorer.Parser;

type
  // Chooses the TDUMP view appropriate for a known input-file family.
  TDumpOptionProfile = (topRaw, topExecutable, topObject, topLibrary,
    topELF, topArchive, topMach, topDelphiUnit);

  TDumpAsciiDisplay = (tadDefault, tad8Bit, tad7Bit);
  TDumpHexOffsetMode = (thomDefault, thomRelative, thomAbsolute);

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
  // OutputText combines the tool's standard output and error streams verbatim.
  TDumpRunResult = class
  public
    InputFileName: string;
    ListFileName: string;
    ToolPath: string;
    ToolKind: TDumpToolKind;
    Options: string;
    ExitCode: Cardinal;
    OutputText: string;
    Document: TDumpDocument;
    destructor Destroy; override;
  end;

  // Runs a selected TDUMP executable with redirected output.
  // RunAndParse returns a result that owns both captured text and its document.
  TDumpRunner = class
  private
    FOnProgress: TDumpParserProgressEvent;
    function Execute(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind; const AOptions, AListFileName: string):
      TDumpRunResult;
    procedure ParseResult(const AResult: TDumpRunResult;
      AToolKind: TDumpToolKind);
  public
    class function GetOptionProfile(const AInputFileName: string):
      TDumpOptionProfile; static;
    class function GetBestOptions(const AInputFileName: string):
      TDumpCommandOptions; static;
    class function GetBestOptionText(const AInputFileName: string): string;
      static;
    property OnProgress: TDumpParserProgressEvent read FOnProgress
      write FOnProgress;
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
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  Winapi.Windows;

function QuoteCommandLineArgument(const AValue: string): string;
begin
  // Tool and input paths are quoted so fixed paths with spaces are accepted.
  Result := '"' + StringReplace(AValue, '"', '\"', [rfReplaceAll]) + '"';
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
  inherited;
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
      Result.ELFMemberList := True;
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

    var LTemporaryFileName := TPath.GetTempFileName;
    try
      var LOutputStream := TFileStream.Create(LTemporaryFileName,
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
          try
            if WaitForSingleObject(LProcessInformation.hProcess, INFINITE) =
              WAIT_FAILED then
              RaiseLastError('Waiting for TDUMP');
            if not GetExitCodeProcess(LProcessInformation.hProcess,
              Result.ExitCode) then
              RaiseLastError('Reading the TDUMP exit code');
          finally
            CloseHandle(LProcessInformation.hThread);
            CloseHandle(LProcessInformation.hProcess);
          end;
        finally
          CloseHandle(LInputHandle);
        end;
      finally
        LOutputStream.Free;
      end;

      Result.OutputText := TFile.ReadAllText(LTemporaryFileName,
        TEncoding.Default);
      if (Result.ListFileName <> '') and FileExists(Result.ListFileName) then
      begin
        var LListOutputText := TFile.ReadAllText(Result.ListFileName,
          TEncoding.Default);
        if Result.OutputText <> '' then
          Result.OutputText := LListOutputText + sLineBreak + Result.OutputText
        else
          Result.OutputText := LListOutputText;
      end;
    finally
      TFile.Delete(LTemporaryFileName);
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
  var LParser := TDumpParser.Create;
  try
    LParser.OnProgress := FOnProgress;
    AResult.Document := LParser.ParseText(AResult.OutputText,
      AResult.InputFileName);
    if AResult.Document.ToolKind = tkUnknown then
    begin
      AResult.Document.ToolKind := AToolKind;
      AResult.Document.PrimaryRun.ToolKind := AToolKind;
    end;
  finally
    LParser.Free;
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
