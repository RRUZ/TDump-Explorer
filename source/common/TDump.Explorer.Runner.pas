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
  // Owns one TDUMP process result and, when requested, its parsed projection.
  // OutputText combines the tool's standard output and error streams verbatim.
  TDumpRunResult = class
  public
    InputFileName: string;
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
    function Execute(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind; const AOptions: string): TDumpRunResult;
  public
    function Run(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind; const AOptions: string = ''): TDumpRunResult;
    function RunAndParse(const AInputFileName, AToolPath: string;
      AToolKind: TDumpToolKind; const AOptions: string = ''): TDumpRunResult;
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

function TDumpRunner.Execute(const AInputFileName, AToolPath: string;
  AToolKind: TDumpToolKind; const AOptions: string): TDumpRunResult;
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

          var LCommandLine := QuoteCommandLineArgument(Result.ToolPath) +
            ' -ns -q';
          if Result.Options <> '' then
            LCommandLine := LCommandLine + ' ' + Result.Options;
          LCommandLine := LCommandLine + ' ' +
            QuoteCommandLineArgument(Result.InputFileName);

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
    finally
      TFile.Delete(LTemporaryFileName);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function TDumpRunner.Run(const AInputFileName, AToolPath: string;
  AToolKind: TDumpToolKind; const AOptions: string): TDumpRunResult;
begin
  Result := Execute(AInputFileName, AToolPath, AToolKind, AOptions);
end;

function TDumpRunner.RunAndParse(const AInputFileName, AToolPath: string;
  AToolKind: TDumpToolKind; const AOptions: string): TDumpRunResult;
begin
  Result := Run(AInputFileName, AToolPath, AToolKind, AOptions);
  try
    var LParser := TDumpParser.Create;
    try
      Result.Document := LParser.ParseText(Result.OutputText,
        Result.InputFileName);
    finally
      LParser.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
