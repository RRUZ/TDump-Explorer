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

implementation

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
