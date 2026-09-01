//**************************************************************************************************
//
// Unit TDump.Explorer.Utils
// unit for TDump Explorer project
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.Utils;

interface

uses
  System.SysUtils,
  TDump.Explorer.Parser;

function ValueKindName(AKind: TDumpValueKind): string;
function DiagnosticSeverityName(ASeverity: TDumpDiagnosticSeverity): string;
function SymbolKindName(AKind: TDumpSymbolKind): string;
function RawLineCount(const S: string): Integer;
function GetTDumpVersion(const AFileName: string): string;
function GetExecutableVersion(const AFileName: string): string;
function CaptureProcessOutput(const AExecutableFileName, AParameters: string): string;

implementation

uses
 Winapi.Windows;

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
  cBufferSize = 4096;
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
      SetLength(LBuffer, cBufferSize);
      repeat
        while PeekNamedPipe(LReadPipe, nil, 0, nil, @LAvailable, nil) and
          (LAvailable > 0) do
        begin
          LBytesToRead := LAvailable;
          if LBytesToRead > cBufferSize then
            LBytesToRead := cBufferSize;
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
        if LBytesToRead > cBufferSize then
          LBytesToRead := cBufferSize;
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


function ValueKindName(AKind: TDumpValueKind): string;
begin
  case AKind of
    vkText: Result := 'Text';
    vkUInt: Result := 'UInt';
    vkAddress: Result := 'Address';
    vkRVA: Result := 'RVA';
    vkFileOffset: Result := 'FileOffset';
    vkOrdinal: Result := 'Ordinal';
    vkSize: Result := 'Size';
  else
    Result := 'Unknown';
  end;
end;

function DiagnosticSeverityName(ASeverity: TDumpDiagnosticSeverity): string;
begin
  case ASeverity of
    dsInfo: Result := 'Info';
    dsWarning: Result := 'Warning';
    dsError: Result := 'Error';
  else
    Result := 'Unknown';
  end;
end;

function SymbolKindName(AKind: TDumpSymbolKind): string;
begin
  case AKind of
    skFunction: Result := 'Function';
    skData: Result := 'Data';
    skType: Result := 'Type';
    skConstant: Result := 'Constant';
    skReference: Result := 'Reference';
  else
    Result := 'Unknown';
  end;
end;

function RawLineCount(const S: string): Integer;
begin
  if S = '' then
    Exit(0);

  // Count physical lines without treating a final line terminator as content.
  Result := 1;
  for var LIndex := 1 to Length(S) do
    if S[LIndex] = #10 then
      Inc(Result);
  if S[Length(S)] = #10 then
    Dec(Result);
end;

end.
