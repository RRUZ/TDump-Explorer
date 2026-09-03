//**************************************************************************************************
//
// Unit TDump.Explorer.View.OMF
//
// OMF and archive detail view population
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
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
    class procedure PopulateFixUp32(AControl: THighlighterControl;
      ARecord: TDumpObjectRecord); static;
    class procedure PopulateLEData(AControl: THighlighterControl;
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
  TDump.Explorer.HighlighterProviders,
  TDump.Explorer.TinyParser,
  TDump.Explorer.UI;

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
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.LibraryMembers.Count,
      function(AIndex: Integer): string
      begin
        var LMember := ADocument.LibraryMembers[AIndex];
        Result := Format('%s'#9'%d'#9'%d'#9'%d', [LMember.Name,
          LMember.StartLine, LMember.EndLine,
          LMember.EndLine - LMember.StartLine + 1]);
      end));
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
    AControl.SetColumnDataTypes([thdtText, thdtAuto]);
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
  if SameText(ARecord.RecordKind, 'FIXU32') and
    (ARecord.FixUps.Count > 0) then
  begin
    PopulateFixUp32(AControl, ARecord);
    Exit;
  end;
  if SameText(ARecord.RecordKind, 'LEDATA') and
    (ARecord.HexDataRows.Count > 0) then
  begin
    PopulateLEData(AControl, ARecord);
    Exit;
  end;

  SetExplorerFont(AControl, TExplorerTheme.FontName, TExplorerTheme.FontSize);
  AControl.HeaderControl1.ParentFont := False;
  SetExplorerFont(AControl.HeaderControl1, TExplorerTheme.FontName, TExplorerTheme.FontSize);
  AControl.AutoSizeColumns := True;
  AControl.UseColumnMode := True;
  AControl.ShowLineNumbers := False;
  AControl.ParserMode := tpmOMFRecord;
    AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Property', 'Value']);
    AControl.SetColumnDataTypes([thdtAuto, thdtAuto]);
    AControl.AddColumns(['Offset', ARecord.RawOffset]);
    AControl.AddColumns(['Record', ARecord.RecordKind]);
    if ARecord.Name <> '' then AControl.AddColumns(['Name', ARecord.Name]);
    for var LDetail in ARecord.Details do
      AControl.AddColumns([LDetail.Name, LDetail.RawValue]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TOMFView.PopulateFixUp32(AControl: THighlighterControl;
  ARecord: TDumpObjectRecord);
begin
  if (AControl = nil) or (ARecord = nil) then Exit;
  SetExplorerFont(AControl, TExplorerTheme.FontName, TExplorerTheme.FontSize);
  AControl.HeaderControl1.ParentFont := False;
  SetExplorerFont(AControl.HeaderControl1, TExplorerTheme.FontName, TExplorerTheme.FontSize);
  AControl.ParserMode := tpmOMFRecord;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.PrepareGridPresentation;
    AControl.SetColumnHeaders(['FixUp', 'Mode', 'Loc', 'Frame', 'Target']);
    AControl.SetColumnDataTypes([thdtHexadecimal, thdtText, thdtText,
      thdtSymbol, thdtAuto]);
    AControl.SetColumnParserModes([tpmTDumpValues, tpmOMFRecord,
      tpmOMFRecord, tpmOMFRecord, tpmOMFRecord]);
    AControl.SetColumnWidthWeights([2, 2, 3, 3, 8]);
    AControl.AutoSizeColumns := False;
    for var LFixUp in ARecord.FixUps do
      AControl.AddColumns([LFixUp.RawFixUp, LFixUp.Mode, LFixUp.Location,
        LFixUp.Frame, LFixUp.Target]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TOMFView.PopulateLEData(AControl: THighlighterControl;
  ARecord: TDumpObjectRecord);
begin
  if (AControl = nil) or (ARecord = nil) then Exit;
  SetExplorerFont(AControl, TExplorerTheme.FixedWidthFontName, TExplorerTheme.FixedWidthFontSize);
  AControl.HeaderControl1.ParentFont := False;
  SetExplorerFont(AControl.HeaderControl1, TExplorerTheme.FontName, TExplorerTheme.FontSize);
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.PrepareGridPresentation;
    AControl.SetColumnHeaders(['Offset', 'Bytes', 'ASCII']);
    AControl.SetColumnDataTypes([thdtHexadecimal, thdtHexadecimal, thdtText]);
    AControl.SetColumnParserModes([tpmTDumpValues, tpmTDumpValues,
      tpmTDumpValues]);
    AControl.SetColumnWidthWeights([1, 5, 5]);
    AControl.AutoSizeColumns := False;
    for var LDataRow in ARecord.HexDataRows do
      AControl.AddColumns([LDataRow.RawOffset, LDataRow.Bytes, LDataRow.ASCII]);
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
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.ArchiveMembers.Count,
      function(AIndex: Integer): string
      begin
        var LMember := ADocument.ArchiveMembers[AIndex];
        Result := Format('%d'#9'%s'#9'%s'#9'%s'#9'%s'#9'%s'#9'%s'#9'%s',
          [LMember.Index, LMember.Name, LMember.RawOffset, LMember.RawSize,
           LMember.Mode, LMember.UserId, LMember.GroupId, LMember.Timestamp]);
      end));
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
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.ArchiveSymbols.Count,
      function(AIndex: Integer): string
      begin
        var LSymbol := ADocument.ArchiveSymbols[AIndex];
        Result := Format('%d'#9'%s'#9'%s'#9'%s'#9'%s', [LSymbol.Index,
          LSymbol.Name, LSymbol.MemberName, LSymbol.RawMemberOffset,
          LSymbol.RawMemberSize]);
      end));
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
