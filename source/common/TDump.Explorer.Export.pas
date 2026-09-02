//**************************************************************************************************
//
// Unit TDump.Explorer.Export
//
// Text, CSV and JSON export helpers for Explorer views.
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
unit TDump.Explorer.Export;

interface

uses
  System.SysUtils, System.Math;

type
  TDumpExportFormat = (defText, defCsv, defJson, defMarkdown);
  TDumpExportRow = TArray<string>;
  TDumpExportRows = TArray<TDumpExportRow>;

function ExportView(const AHeaders: TArray<string>;
  const ARows: TDumpExportRows; AFormat: TDumpExportFormat): string;

implementation

function CellText(const ARow: TDumpExportRow; AColumnIndex: Integer): string;
begin
  if (AColumnIndex >= 0) and (AColumnIndex < Length(ARow)) then
    Result := ARow[AColumnIndex]
  else
    Result := '';
end;

function ColumnCount(const AHeaders: TArray<string>;
  const ARows: TDumpExportRows): Integer;
begin
  Result := Length(AHeaders);
  for var LRow in ARows do
    Result := Max(Result, Length(LRow));
  Result := Max(1, Result);
end;

function HeaderText(const AHeaders: TArray<string>; AColumnIndex: Integer): string;
begin
  if (AColumnIndex >= 0) and (AColumnIndex < Length(AHeaders)) and
    (AHeaders[AColumnIndex] <> '') then
    Exit(AHeaders[AColumnIndex]);
  if Length(AHeaders) = 0 then
    Exit('Text');
  Result := 'Column ' + IntToStr(AColumnIndex + 1);
end;

function JsonHeaderText(const AHeaders: TArray<string>; AColumnIndex: Integer): string;
var
  LDuplicateCount: Integer;
begin
  Result := HeaderText(AHeaders, AColumnIndex);
  LDuplicateCount := 0;
  for var LPreviousIndex := 0 to AColumnIndex - 1 do
    if SameText(HeaderText(AHeaders, LPreviousIndex), Result) then
      Inc(LDuplicateCount);
  if LDuplicateCount > 0 then
    Result := Result + ' (' + IntToStr(LDuplicateCount + 1) + ')';
end;

function EscapeCsv(const AValue: string): string;
begin
  Result := AValue;
  if (Pos(',', Result) > 0) or (Pos('"', Result) > 0) or
    (Pos(#13, Result) > 0) or (Pos(#10, Result) > 0) then
    Result := '"' + StringReplace(Result, '"', '""', [rfReplaceAll]) + '"';
end;

function EscapeJson(const AValue: string): string;
begin
  Result := '"';
  for var LCharacter in AValue do
    case LCharacter of
      '"': Result := Result + '\"';
      '\': Result := Result + '\\';
      #8: Result := Result + '\b';
      #9: Result := Result + '\t';
      #10: Result := Result + '\n';
      #12: Result := Result + '\f';
      #13: Result := Result + '\r';
    else
      if Ord(LCharacter) < $20 then
        Result := Result + '\u' + IntToHex(Ord(LCharacter), 4)
      else
        Result := Result + LCharacter;
    end;
  Result := Result + '"';
end;

function EscapeText(const AValue: string): string;
begin
  Result := StringReplace(AValue, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '\r\n', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '\r', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '\n', [rfReplaceAll]);
  Result := StringReplace(Result, #9, '\t', [rfReplaceAll]);
end;

function EscapeMarkdown(const AValue: string): string;
begin
  Result := StringReplace(AValue, '\', '\\', [rfReplaceAll]);
  Result := StringReplace(Result, #13#10, '<br>', [rfReplaceAll]);
  Result := StringReplace(Result, #13, '<br>', [rfReplaceAll]);
  Result := StringReplace(Result, #10, '<br>', [rfReplaceAll]);
  Result := StringReplace(Result, '|', '\|', [rfReplaceAll]);
end;

function ExportText(const AHeaders: TArray<string>;
  const ARows: TDumpExportRows; AColumnCount: Integer): string;
var
  LText: TStringBuilder;
  LCells: TArray<string>;
begin
  LText := TStringBuilder.Create;
  try
    SetLength(LCells, AColumnCount);
    for var LColumnIndex := 0 to AColumnCount - 1 do
      LCells[LColumnIndex] := EscapeText(HeaderText(AHeaders, LColumnIndex));
    LText.AppendLine(string.Join(#9, LCells));

    for var LRow in ARows do
    begin
      SetLength(LCells, AColumnCount);
      for var LColumnIndex := 0 to AColumnCount - 1 do
        LCells[LColumnIndex] := EscapeText(CellText(LRow, LColumnIndex));
      LText.AppendLine(string.Join(#9, LCells));
    end;
    Result := LText.ToString.TrimRight([#13, #10]);
  finally
    LText.Free;
  end;
end;

function ExportCsv(const AHeaders: TArray<string>;
  const ARows: TDumpExportRows; AColumnCount: Integer): string;
var
  LText: TStringBuilder;
  LCells: TArray<string>;
begin
  LText := TStringBuilder.Create;
  try
    SetLength(LCells, AColumnCount);
    for var LColumnIndex := 0 to AColumnCount - 1 do
      LCells[LColumnIndex] := EscapeCsv(HeaderText(AHeaders, LColumnIndex));
    LText.AppendLine(string.Join(',', LCells));

    for var LRow in ARows do
    begin
      SetLength(LCells, AColumnCount);
      for var LColumnIndex := 0 to AColumnCount - 1 do
        LCells[LColumnIndex] := EscapeCsv(CellText(LRow, LColumnIndex));
      LText.AppendLine(string.Join(',', LCells));
    end;
    Result := LText.ToString.TrimRight([#13, #10]);
  finally
    LText.Free;
  end;
end;

function ExportMarkdown(const AHeaders: TArray<string>;
  const ARows: TDumpExportRows; AColumnCount: Integer): string;
var
  LText: TStringBuilder;
begin
  LText := TStringBuilder.Create;
  try
    LText.Append('|');
    for var LColumnIndex := 0 to AColumnCount - 1 do
      LText.Append(' ').Append(EscapeMarkdown(HeaderText(AHeaders,
        LColumnIndex))).Append(' |');
    LText.AppendLine;

    LText.Append('|');
    for var LColumnIndex := 0 to AColumnCount - 1 do
      LText.Append(' --- |');
    LText.AppendLine;

    for var LRow in ARows do
    begin
      LText.Append('|');
      for var LColumnIndex := 0 to AColumnCount - 1 do
        LText.Append(' ').Append(EscapeMarkdown(CellText(LRow,
          LColumnIndex))).Append(' |');
      LText.AppendLine;
    end;
    Result := LText.ToString.TrimRight([#13, #10]);
  finally
    LText.Free;
  end;
end;

function ExportJson(const AHeaders: TArray<string>;
  const ARows: TDumpExportRows; AColumnCount: Integer): string;
var
  LText: TStringBuilder;
begin
  LText := TStringBuilder.Create;
  try
    LText.Append('[');
    for var LRowIndex := 0 to High(ARows) do
    begin
      if LRowIndex > 0 then
        LText.Append(',');
      LText.AppendLine;
      LText.Append('  {');
      for var LColumnIndex := 0 to AColumnCount - 1 do
      begin
        if LColumnIndex > 0 then
          LText.Append(',');
        LText.AppendLine;
        LText.Append('    ').Append(EscapeJson(JsonHeaderText(AHeaders,
          LColumnIndex))).Append(': ').Append(EscapeJson(CellText(
          ARows[LRowIndex], LColumnIndex)));
      end;
      LText.AppendLine;
      LText.Append('  }');
    end;
    if Length(ARows) > 0 then
      LText.AppendLine;
    LText.Append(']');
    Result := LText.ToString;
  finally
    LText.Free;
  end;
end;

function ExportView(const AHeaders: TArray<string>;
  const ARows: TDumpExportRows; AFormat: TDumpExportFormat): string;
var
  LColumnCount: Integer;
begin
  LColumnCount := ColumnCount(AHeaders, ARows);
  case AFormat of
    defText: Result := ExportText(AHeaders, ARows, LColumnCount);
    defCsv: Result := ExportCsv(AHeaders, ARows, LColumnCount);
    defJson: Result := ExportJson(AHeaders, ARows, LColumnCount);
    defMarkdown: Result := ExportMarkdown(AHeaders, ARows, LColumnCount);
  end;
end;

end.
