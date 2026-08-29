//**************************************************************************************************
//
// Unit TDump.Explorer.View.Borland
//
// Borland debug-symbol and package detail view population
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.View.Borland;

interface

uses
  TDump.Explorer.Parser,
  TDump.Explorer.HighlighterControl;

type
  TBorlandView = record
    class procedure PopulateSubsection(AControl: THighlighterControl;
      ADocument: TDumpDocument; ASubsectionIndex: Integer); static;
    class procedure PopulateSymbolRecord(AControl: THighlighterControl;
      ARecord: TDumpBorlandSymbolRecord); static;
    class procedure PopulateGlobalTypeRecord(AControl: THighlighterControl;
      ARecord: TDumpGlobalTypeRecord); static;
    class procedure PopulateSourceFile(AControl: THighlighterControl;
      ASourceFile: TDumpSourceFile); static;
    class function SubsectionCaption(ASubsection: TDumpBorlandSubsection): string; static;
    class function SymbolCaption(ARecord: TDumpBorlandSymbolRecord): string; static;
    class function TypeCaption(ARecord: TDumpGlobalTypeRecord): string; static;
    class function SourceFileCaption(ASourceFile: TDumpSourceFile): string; static;
    class function PackageCaption(const ACaption: string;
      ADocument: TDumpDocument): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.StrUtils,
  TDump.Explorer.Highlighter,
  TDump.Explorer.TinyParser;

class function TBorlandView.PackageCaption(const ACaption: string;
  ADocument: TDumpDocument): string;
begin
  Result := ACaption;
  if (ADocument <> nil) and (ADocument.PackageDescription <> '') then
    Result := Result + ' - ' + ADocument.PackageDescription;
end;

class function TBorlandView.SubsectionCaption(
  ASubsection: TDumpBorlandSubsection): string;
begin
  Result := Format('%s (module %d)', [ASubsection.SubsectionType,
    ASubsection.ModIndex]);
end;

class function TBorlandView.SymbolCaption(
  ARecord: TDumpBorlandSymbolRecord): string;
begin
  Result := BorlandSymbolCaption(ARecord);
end;

class function TBorlandView.TypeCaption(ARecord: TDumpGlobalTypeRecord): string;
begin
  Result := BorlandTypeCaption(ARecord);
end;

class function TBorlandView.SourceFileCaption(ASourceFile: TDumpSourceFile): string;
begin
  Result := ASourceFile.ResolvedName;
  if Result = '' then Result := ASourceFile.Name;
  if Result = '' then Result := 'Source file';
  if ASourceFile.HasNameIndex and (ASourceFile.RawNameIndex <> '') then
    Result := Format('%s [%s]', [Result, ASourceFile.RawNameIndex]);
  if ASourceFile.RawOffset <> '' then
    Result := Result + '  Offset ' + ASourceFile.RawOffset
  else
    Result := Result + '  Offset ' + IntToHex(ASourceFile.Offset, 5);
end;

class procedure TBorlandView.PopulateSubsection(AControl: THighlighterControl;
  ADocument: TDumpDocument; ASubsectionIndex: Integer);
begin
  if (AControl = nil) or (ADocument = nil) or (ASubsectionIndex < 0) or
    (ASubsectionIndex >= ADocument.BorlandSubsections.Count) then Exit;
  var LSubsection := ADocument.BorlandSubsections[ASubsectionIndex];
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    if SameText(LSubsection.SubsectionType, 'sstNames') then
    begin
      AControl.SetColumnHeaders(['Index', 'Name']);
      AControl.SetColumnDataTypes([thdtHexadecimal, thdtAuto]);
      for var LName in ADocument.BorlandNames do
        if IsBorlandMethodName(LName.Value) then
          AControl.AddColumns([LName.RawIndex, LName.Value], tpmCppBuilderMethod)
        else
          AControl.AddColumns([LName.RawIndex, LName.Value]);
      Exit;
    end;
    AControl.SetColumnHeaders(['Name', 'Value']);
    AControl.AddColumns(['Subsection', LSubsection.SubsectionType]);
    AControl.AddColumns(['Module', IntToHex(LSubsection.ModIndex, 4)]);
    AControl.AddColumns(['File offset', IntToHex(LSubsection.FileOffset, 8)]);
    if SameText(LSubsection.SubsectionType, 'sstModule') then
      for var LModule in ADocument.SymbolModules do
        if (LModule.ModIndex = LSubsection.ModIndex) and
          (LModule.FileOffset = LSubsection.FileOffset) then
        begin
          var LName := LModule.ResolvedName; if LName = '' then LName := LModule.Name;
          if LName <> '' then AControl.AddColumns(['Name', LName]);
          AControl.AddColumns(['Overlay', IntToHex(LModule.OvlNum, 4)]);
          AControl.AddColumns(['Library index', IntToHex(LModule.LibIndex, 4)]);
          AControl.AddColumns(['Segments', LModule.Segments.Count.ToString]);
          AControl.AddColumns(['Time', IntToHex(LModule.Time, 4)]);
          Break;
        end
    else if SameText(LSubsection.SubsectionType, 'sstSrcModule') then
      for var LSourceModule in ADocument.SourceModules do
        if (LSourceModule.ModIndex = LSubsection.ModIndex) and
          (LSourceModule.FileOffset = LSubsection.FileOffset) then
        begin
          AControl.AddColumns(['Segment ranges', LSourceModule.SegmentRanges.Count.ToString]);
          for var LRange in LSourceModule.SegmentRanges do
            AControl.AddColumns(['Segment range', Format('%s:%s-%s',
              [LRange.RawSegment, LRange.RawStartOffset, LRange.RawEndOffset])]);
          AControl.AddColumns(['Source files', LSourceModule.SourceFiles.Count.ToString]);
          Break;
        end
    else if SameText(LSubsection.SubsectionType, 'sstAlignSym') then
      for var LAlignSection in ADocument.AlignSymbolSections do
        if (LAlignSection.ModIndex = LSubsection.ModIndex) and
          (LAlignSection.FileOffset = LSubsection.FileOffset) then
        begin
          AControl.AddColumns(['Records', LAlignSection.Records.Count.ToString]);
          AControl.AddColumns(['Symbols', LAlignSection.Symbols.Count.ToString]);
          AControl.AddColumns(['Search records', LAlignSection.Searches.Count.ToString]);
          Break;
        end
    else if SameText(LSubsection.SubsectionType, 'sstGlobalSym') then
      for var LGlobalSymbolSection in ADocument.GlobalSymbolSections do
        if (LGlobalSymbolSection.ModIndex = LSubsection.ModIndex) and
          (LGlobalSymbolSection.FileOffset = LSubsection.FileOffset) then
        begin
          AControl.AddColumns(['Records', LGlobalSymbolSection.Records.Count.ToString]);
          Break;
        end
    else if SameText(LSubsection.SubsectionType, 'sstGlobalTypes') then
      for var LGlobalTypeSection in ADocument.GlobalTypeSections do
        if (LGlobalTypeSection.ModIndex = LSubsection.ModIndex) and
          (LGlobalTypeSection.FileOffset = LSubsection.FileOffset) then
        begin
          AControl.AddColumns(['Declared types', LGlobalTypeSection.TypeCount.ToString]);
          AControl.AddColumns(['Parsed records', LGlobalTypeSection.Records.Count.ToString]);
          Break;
        end;
    if not SameText(LSubsection.SubsectionType, 'sstSrcModule') and
      (LSubsection.Node <> nil) then
      for var LProperty in LSubsection.Node.Properties do
        AControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TBorlandView.PopulateSymbolRecord(AControl: THighlighterControl;
  ARecord: TDumpBorlandSymbolRecord);
begin
  if (AControl = nil) or (ARecord = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear; AControl.SetColumnHeaders(['Name', 'Value']);
    AControl.AddColumns(['Record kind', ARecord.RecordKind]);
    AControl.AddColumns(['Record offset', ARecord.RawRecordOffset]);
    if ARecord.ResolvedName <> '' then AControl.AddColumns(['Name', ARecord.ResolvedName], tpmCppBuilderMethod)
    else if ARecord.Name <> '' then AControl.AddColumns(['Name', ARecord.Name], tpmCppBuilderMethod);
    if ARecord.HasNameIndex then AControl.AddColumns(['Name index', ARecord.RawNameIndex]);
    if ARecord.HasTypeIndex then AControl.AddColumns(['Type index', ARecord.RawTypeIndex]);
    if ARecord.RawSegment <> '' then AControl.AddColumns(['Segment', ARecord.RawSegment]);
    if ARecord.HasAddress then AControl.AddColumns(['Address', ARecord.RawAddress]);
    if ARecord.HasEndAddress then AControl.AddColumns(['End address', ARecord.RawEndAddress]);
    if ARecord.HasScopeOffsets then
    begin
      AControl.AddColumns(['Parent offset', IntToHex(ARecord.ParentOffset, 5)]);
      AControl.AddColumns(['End offset', IntToHex(ARecord.EndOffset, 5)]);
      AControl.AddColumns(['Next offset', IntToHex(ARecord.NextOffset, 5)]);
    end;
    if ARecord.Value <> '' then AControl.AddColumns(['Value', ARecord.Value]);
    for var LProperty in ARecord.Properties do AControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally AControl.EndUpdate; end;
end;

class procedure TBorlandView.PopulateGlobalTypeRecord(AControl: THighlighterControl;
  ARecord: TDumpGlobalTypeRecord);
begin
  if (AControl = nil) or (ARecord = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear; AControl.SetColumnHeaders(['Name', 'Value']);
    AControl.AddColumns(['Type index', ARecord.RawTypeIndex]);
    AControl.AddColumns(['Record offset', ARecord.RawRecordOffset]);
    AControl.AddColumns(['Kind', ARecord.TypeKind]);
    AControl.AddColumns(['Length', ARecord.RawLength]);
    if ARecord.ResolvedName <> '' then AControl.AddColumns(['Name', ARecord.ResolvedName])
    else if ARecord.Name <> '' then AControl.AddColumns(['Name', ARecord.Name]);
    if ARecord.HasNameIndex then AControl.AddColumns(['Name index', ARecord.RawNameIndex]);
    for var LProperty in ARecord.Properties do AControl.AddColumns([LProperty.Name, LProperty.RawValue]);
    for var LDetail in ARecord.Details do
    begin
      if LDetail.TypeText <> '' then AControl.AddColumns(['Type', LDetail.TypeText]);
      if LDetail.PointerFlavor <> '' then AControl.AddColumns(['Pointer', LDetail.PointerFlavor]);
      if LDetail.PointerType <> '' then AControl.AddColumns(['Pointer type', LDetail.PointerType]);
      if LDetail.PointerMode <> '' then AControl.AddColumns(['Pointer mode', LDetail.PointerMode]);
      if LDetail.CallingConvention <> '' then AControl.AddColumns(['Calling convention', LDetail.CallingConvention]);
      if LDetail.ReturnType <> '' then AControl.AddColumns(['Returns', LDetail.ReturnType]);
      for var LProperty in LDetail.Properties do AControl.AddColumns([LProperty.Name, LProperty.RawValue]);
    end;
    for var LMember in ARecord.Members do
    begin
      var LName := LMember.ResolvedName; if LName = '' then LName := LMember.Name;
      if LName = '' then LName := 'Member';
      var LValue := '';
      if LMember.RawTypeIndex <> '' then LValue := 'Type ' + LMember.RawTypeIndex;
      if LMember.RawOffset <> '' then LValue := Trim(LValue + '  Offset ' + LMember.RawOffset);
      if LMember.RawValue <> '' then LValue := Trim(LValue + '  Value ' + LMember.RawValue);
      AControl.AddColumns(['Member ' + LName, LValue]);
    end;
  finally AControl.EndUpdate; end;
end;

class procedure TBorlandView.PopulateSourceFile(AControl: THighlighterControl;
  ASourceFile: TDumpSourceFile);
begin
  if (AControl = nil) or (ASourceFile = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear; AControl.SetColumnHeaders(['Range', 'Line', 'Offset']);
    AControl.SetColumnDataTypes([thdtText, thdtInteger, thdtHexadecimal]);
    for var LRange in ASourceFile.Ranges do
    begin
      var LRangeText := Format('%s:%s-%s', [LRange.RawSegment,
        LRange.RawStartOffset, LRange.RawEndOffset]);
      if LRange.LineNumbers.Count = 0 then AControl.AddColumns([LRangeText, '', ''])
      else for var LLine in LRange.LineNumbers do
      begin
        var LNumber := LLine.RawLineNumber; if LNumber = '' then LNumber := LLine.LineNumber.ToString;
        var LOffset := LLine.RawOffset; if LOffset = '' then LOffset := IntToHex(LLine.Offset, 5);
        AControl.AddColumns([LRangeText, LNumber, LOffset]); LRangeText := '';
      end;
    end;
  finally AControl.EndUpdate; end;
end;

end.
