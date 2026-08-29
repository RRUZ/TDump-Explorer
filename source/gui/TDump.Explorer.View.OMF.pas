//**************************************************************************************************
//
// Unit TDump.Explorer.View.OMF
//
// OMF and archive detail view population
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.View.OMF;

interface

uses
  TDump.Explorer.Parser,
  TDump.Explorer.HighlighterControl;

type
  TOMFView = record
    class procedure PopulateRecords(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateLibraryMembers(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateLibraryIndex(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateRecord(AControl: THighlighterControl;
      ARecord: TDumpObjectRecord); static;
    class procedure PopulateArchiveMembers(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateArchiveSymbols(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class function RecordCaption(ARecord: TDumpObjectRecord): string; static;
  end;

implementation

uses
  System.SysUtils,
  TDump.Explorer.Highlighter,
  TDump.Explorer.TinyParser;

class procedure TOMFView.PopulateRecords(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Property', 'Value']);
    AControl.SetColumnDataTypes([thdtText, thdtAuto]);
    AControl.AddColumns(['Records', IntToStr(ADocument.ObjectRecords.Count)]);
    if ADocument.ObjectRecords.Count > 0 then
    begin
      var LFirst := ADocument.ObjectRecords[0];
      var LLast := ADocument.ObjectRecords.Last;
      AControl.AddColumns(['First record', RecordCaption(LFirst)]);
      AControl.AddColumns(['Last record', RecordCaption(LLast)]);
      AControl.AddColumns(['Source lines', Format('%d..%d',
        [LFirst.StartLine, LLast.EndLine])]);
    end;
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TOMFView.PopulateLibraryMembers(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Member', 'Start line', 'End line', 'Lines']);
    AControl.SetColumnDataTypes([thdtText, thdtInteger, thdtInteger, thdtInteger]);
    for var LMember in ADocument.LibraryMembers do
      AControl.AddColumns([LMember.Name, IntToStr(LMember.StartLine),
        IntToStr(LMember.EndLine), IntToStr(LMember.EndLine - LMember.StartLine + 1)]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TOMFView.PopulateLibraryIndex(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) or (ADocument.OMFLibraryIndex = nil) then Exit;
  var LIndex := ADocument.OMFLibraryIndex;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Property', 'Value']);
    if LIndex.HasFileOffset then AControl.AddColumns(['Index file offset', LIndex.RawFileOffset]);
    if LIndex.HasBlockCount then AControl.AddColumns(['Index blocks', LIndex.BlockCount.ToString]);
    if LIndex.HasPageSize then AControl.AddColumns(['Library page size', LIndex.PageSize.ToString + ' bytes']);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TOMFView.PopulateRecord(AControl: THighlighterControl;
  ARecord: TDumpObjectRecord);
begin
  if (AControl = nil) or (ARecord = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Property', 'Value']);
    AControl.AddColumns(['Offset', ARecord.RawOffset]);
    AControl.AddColumns(['Record', ARecord.RecordKind]);
    if ARecord.Name <> '' then AControl.AddColumns(['Name', ARecord.Name]);
    for var LDetail in ARecord.Details do
      AControl.AddColumns([LDetail.Name, LDetail.RawValue]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TOMFView.PopulateArchiveMembers(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Index', 'Member', 'Offset', 'Size', 'Mode', 'UID', 'GID', 'Timestamp']);
    AControl.SetColumnDataTypes([thdtInteger, thdtText, thdtHexadecimal, thdtHexadecimal, thdtText, thdtInteger, thdtInteger, thdtText]);
    for var LMember in ADocument.ArchiveMembers do
      AControl.AddColumns([IntToStr(LMember.Index), LMember.Name, LMember.RawOffset,
        LMember.RawSize, LMember.Mode, LMember.UserId, LMember.GroupId, LMember.Timestamp]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TOMFView.PopulateArchiveSymbols(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Index', 'Symbol', 'Member', 'Offset', 'Size']);
    AControl.SetColumnDataTypes([thdtInteger, thdtText, thdtText, thdtHexadecimal, thdtHexadecimal]);
    for var LSymbol in ADocument.ArchiveSymbols do
      AControl.AddColumns([IntToStr(LSymbol.Index), LSymbol.Name, LSymbol.MemberName,
        LSymbol.RawMemberOffset, LSymbol.RawMemberSize]);
  finally
    AControl.EndUpdate;
  end;
end;

class function TOMFView.RecordCaption(ARecord: TDumpObjectRecord): string;
begin
  Result := '';
  if ARecord <> nil then
    Result := ARecord.RawOffset + ' ' + ARecord.RecordKind;
end;

end.
