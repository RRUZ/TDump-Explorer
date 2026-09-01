//**************************************************************************************************
//
// Unit TDump.Explorer.TextSource
//
// Indexed, read-only text sources for TDUMP reports.
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.TextSource;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Generics.Collections;

const
  cMaxTDumpReportSize: Int64 = 100 * 1024 * 1024;

type
  // Provides indexed access without requiring callers to own individual lines.
  TDumpTextSource = class abstract
  protected
    function GetLine(AIndex: Integer): string; virtual; abstract;
    function GetLineCount: Integer; virtual; abstract;
    function GetText: string; virtual; abstract;
  public
    property Count: Integer read GetLineCount;
    property LineCount: Integer read GetLineCount;
    property Lines[AIndex: Integer]: string read GetLine; default;
    property Text: string read GetText;
  end;

  // Keeps an existing Unicode string by reference and indexes its line starts.
  TDumpStringTextSource = class(TDumpTextSource)
  private
    FText: string;
    FLineStarts: TList<Cardinal>;
    procedure BuildLineIndex;
  protected
    function GetLine(AIndex: Integer): string; override;
    function GetLineCount: Integer; override;
    function GetText: string; override;
  public
    constructor Create(const AText: string);
    destructor Destroy; override;
  end;

  // Maps a report read-only and retains only one 32-bit start offset per line.
  TDumpMappedTextSource = class(TDumpTextSource)
  private
    FFileName: string;
    FDeleteOnDestroy: Boolean;
    FFileHandle: THandle;
    FMappingHandle: THandle;
    FView: PByte;
    FSize: Cardinal;
    FLineStarts: TList<Cardinal>;
    procedure BuildLineIndex;
  protected
    function GetLine(AIndex: Integer): string; override;
    function GetLineCount: Integer; override;
    function GetText: string; override;
  public
    constructor Create(const AFileName: string;
      ADeleteOnDestroy: Boolean = False);
    destructor Destroy; override;
  end;

implementation

uses
  System.IOUtils;

procedure CheckLineIndex(AIndex, ACount: Integer);
begin
  if (AIndex < 0) or (AIndex >= ACount) then
    raise EArgumentOutOfRangeException.CreateFmt(
      'Line index %d is outside the valid range 0..%d.', [AIndex, ACount - 1]);
end;

{ TDumpStringTextSource }

constructor TDumpStringTextSource.Create(const AText: string);
begin
  inherited Create;
  FText := AText;
  FLineStarts := TList<Cardinal>.Create;
  BuildLineIndex;
end;

destructor TDumpStringTextSource.Destroy;
begin
  FLineStarts.Free;
  inherited;
end;

procedure TDumpStringTextSource.BuildLineIndex;
begin
  if FText = '' then
    Exit;
  FLineStarts.Add(0);
  var LIndex := 1;
  while LIndex <= Length(FText) do
  begin
    if FText[LIndex] = #13 then
    begin
      Inc(LIndex);
      if (LIndex <= Length(FText)) and (FText[LIndex] = #10) then
        Inc(LIndex);
      if LIndex <= Length(FText) then
        FLineStarts.Add(LIndex - 1);
      Continue;
    end;
    if FText[LIndex] = #10 then
    begin
      Inc(LIndex);
      if LIndex <= Length(FText) then
        FLineStarts.Add(LIndex - 1);
      Continue;
    end;
    Inc(LIndex);
  end;
  FLineStarts.TrimExcess;
end;

function TDumpStringTextSource.GetLine(AIndex: Integer): string;
begin
  CheckLineIndex(AIndex, FLineStarts.Count);
  var LStart := Integer(FLineStarts[AIndex]) + 1;
  var LAfterEnd := Length(FText) + 1;
  if AIndex + 1 < FLineStarts.Count then
    LAfterEnd := Integer(FLineStarts[AIndex + 1]) + 1;
  var LEnd := LAfterEnd - 1;
  while (LEnd >= LStart) and CharInSet(FText[LEnd], [#10, #13]) do
    Dec(LEnd);
  while (LEnd >= LStart) and CharInSet(FText[LEnd], [' ', #9]) do
    Dec(LEnd);
  Result := Copy(FText, LStart, LEnd - LStart + 1);
end;

function TDumpStringTextSource.GetLineCount: Integer;
begin
  Result := FLineStarts.Count;
end;

function TDumpStringTextSource.GetText: string;
begin
  Result := FText;
end;

{ TDumpMappedTextSource }

constructor TDumpMappedTextSource.Create(const AFileName: string;
  ADeleteOnDestroy: Boolean);
begin
  inherited Create;
  FFileName := AFileName;
  FDeleteOnDestroy := ADeleteOnDestroy;
  FFileHandle := INVALID_HANDLE_VALUE;
  FMappingHandle := 0;
  FView := nil;
  FLineStarts := TList<Cardinal>.Create;
  try
    FFileHandle := CreateFile(PChar(AFileName), GENERIC_READ,
      FILE_SHARE_READ, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
    if FFileHandle = INVALID_HANDLE_VALUE then
      RaiseLastOSError;
    var LHighSize: DWORD := 0;
    var LLowSize := GetFileSize(FFileHandle, @LHighSize);
    if (LLowSize = INVALID_FILE_SIZE) and (GetLastError <> NO_ERROR) then
      RaiseLastOSError;
    var LSize := (UInt64(LHighSize) shl 32) or LLowSize;
    if LSize > UInt64(cMaxTDumpReportSize) then
      raise ERangeError.CreateFmt('Report exceeds the %d MiB size limit: %s',
        [cMaxTDumpReportSize div (1024 * 1024), AFileName]);
    FSize := Cardinal(LSize);
    if FSize > 0 then
    begin
      FMappingHandle := CreateFileMapping(FFileHandle, nil, PAGE_READONLY,
        0, 0, nil);
      if FMappingHandle = 0 then
        RaiseLastOSError;
      FView := MapViewOfFile(FMappingHandle, FILE_MAP_READ, 0, 0, 0);
      if FView = nil then
        RaiseLastOSError;
    end;
    BuildLineIndex;
  except
    Free;
    raise;
  end;
end;

destructor TDumpMappedTextSource.Destroy;
begin
  FLineStarts.Free;
  if FView <> nil then
    UnmapViewOfFile(FView);
  if FMappingHandle <> 0 then
    CloseHandle(FMappingHandle);
  if FFileHandle <> INVALID_HANDLE_VALUE then
    CloseHandle(FFileHandle);
  if FDeleteOnDestroy and (FFileName <> '') and FileExists(FFileName) then
    TFile.Delete(FFileName);
  inherited;
end;

procedure TDumpMappedTextSource.BuildLineIndex;
begin
  if FSize = 0 then
    Exit;
  FLineStarts.Add(0);
  var LIndex: Cardinal := 0;
  while LIndex < FSize do
  begin
    if PByte(NativeUInt(FView) + LIndex)^ = 13 then
    begin
      Inc(LIndex);
      if (LIndex < FSize) and
        (PByte(NativeUInt(FView) + LIndex)^ = 10) then
        Inc(LIndex);
      if LIndex < FSize then
        FLineStarts.Add(LIndex);
      Continue;
    end;
    if PByte(NativeUInt(FView) + LIndex)^ = 10 then
    begin
      Inc(LIndex);
      if LIndex < FSize then
        FLineStarts.Add(LIndex);
      Continue;
    end;
    Inc(LIndex);
  end;
  FLineStarts.TrimExcess;
end;

function TDumpMappedTextSource.GetLine(AIndex: Integer): string;
begin
  CheckLineIndex(AIndex, FLineStarts.Count);
  var LStart := FLineStarts[AIndex];
  var LAfterEnd := FSize;
  if AIndex + 1 < FLineStarts.Count then
    LAfterEnd := FLineStarts[AIndex + 1];
  while (LAfterEnd > LStart) and
    (PByte(NativeUInt(FView) + LAfterEnd - 1)^ in [10, 13]) do
    Dec(LAfterEnd);
  while (LAfterEnd > LStart) and
    (PByte(NativeUInt(FView) + LAfterEnd - 1)^ in [9, 32]) do
    Dec(LAfterEnd);
  var LByteCount := Integer(LAfterEnd - LStart);
  if LByteCount = 0 then
    Exit('');
  var LCharacterCount := MultiByteToWideChar(CP_ACP, 0,
    PAnsiChar(NativeUInt(FView) + LStart), LByteCount, nil, 0);
  if LCharacterCount = 0 then
    RaiseLastOSError;
  SetLength(Result, LCharacterCount);
  if MultiByteToWideChar(CP_ACP, 0,
    PAnsiChar(NativeUInt(FView) + LStart), LByteCount, PChar(Result),
    LCharacterCount) = 0 then
    RaiseLastOSError;
end;

function TDumpMappedTextSource.GetLineCount: Integer;
begin
  Result := FLineStarts.Count;
end;

function TDumpMappedTextSource.GetText: string;
begin
  if FSize = 0 then
    Exit('');
  var LAnsi: RawByteString;
  SetString(LAnsi, PAnsiChar(FView), FSize);
  Result := string(LAnsi);
end;

end.
