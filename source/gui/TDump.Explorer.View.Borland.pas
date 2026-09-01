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
    class procedure PopulateSymbolTable(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateSubsection(AControl: THighlighterControl;
      ADocument: TDumpDocument; ASubsectionIndex: Integer); static;
    class procedure PopulateSymbolRecord(AControl: THighlighterControl;
      ARecord: TDumpBorlandSymbolRecord); static;
    class procedure PopulateLazyAlignSymbolRecord(AControl: THighlighterControl;
      ADocument: TDumpDocument; ASection: TDumpLazyBorlandRecordSection;
      ARecordIndex: Integer); static;
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
  TDump.Explorer.TinyParser,
  TDump.Explorer.UI;

function BorlandSourceLine(ADocument: TDumpDocument;
  ALineNumber: Integer): string;
begin
  Result := '';
  if (ADocument = nil) or (ADocument.TextSource = nil) or
    (ALineNumber < 1) or (ALineNumber > ADocument.TextSource.LineCount) then
    Exit;
  Result := ADocument.TextSource[ALineNumber - 1];
end;

function BorlandValueForLabel(const ALine, ALabel: string): string;
const
  cLabels: array[0..15] of string = ('OvlNum:', 'LibIndex:', 'SegCount:',
    'Time:', 'Name:', 'cbSymbols:', 'cNamespaces:', 'cUDTs:', 'cOthers:',
    'Total:', 'SymHash:', 'cbSymHash:', 'AddrHash:', 'cbAddrHash:',
    'Number of types:', 'Flags:');
var
  LStart: Integer;
  LEnd: Integer;
  LCandidate: Integer;
  LKnownLabel: string;
begin
  Result := '';
  LStart := Pos(ALabel, ALine);
  if LStart = 0 then
    Exit;
  Inc(LStart, Length(ALabel));
  LEnd := Length(ALine) + 1;
  for LKnownLabel in cLabels do
  begin
    LCandidate := PosEx(LKnownLabel, ALine, LStart);
    if (LCandidate > 0) and (LCandidate < LEnd) then
      LEnd := LCandidate;
  end;
  Result := Trim(Copy(ALine, LStart, LEnd - LStart));
end;

function BorlandNameWithoutIndex(const AValue: string): string;
var
  LOpenBracket: Integer;
  LCloseBracket: Integer;
begin
  Result := Trim(AValue);
  LOpenBracket := LastDelimiter('[', Result);
  LCloseBracket := LastDelimiter(']', Result);
  if (LOpenBracket > 0) and (LCloseBracket > LOpenBracket) then
    Result := Trim(Copy(Result, 1, LOpenBracket - 1));
end;

procedure AddSourceBackedModuleDetails(AControl: THighlighterControl;
  ADocument: TDumpDocument; ASubsection: TDumpBorlandSubsection);
var
  LLineNumber: Integer;
  LLine: string;
  LName: string;
  LOverlay: string;
  LLibraryIndex: string;
  LTime: string;
  LHasHeader: Boolean;
  LSegmentCount: Integer;
  LSegments: TArray<string>;
begin
  if (AControl = nil) or (ASubsection = nil) then
    Exit;
  LName := '';
  LOverlay := '';
  LLibraryIndex := '';
  LTime := '';
  LHasHeader := False;
  LSegmentCount := 0;
  for LLineNumber := ASubsection.StartLine + 1 to ASubsection.EndLine do
  begin
    LLine := Trim(BorlandSourceLine(ADocument, LLineNumber));
    if StartsText('OvlNum:', LLine) then
    begin
      LHasHeader := True;
      LName := BorlandNameWithoutIndex(BorlandValueForLabel(LLine, 'Name:'));
      LOverlay := BorlandValueForLabel(LLine, 'OvlNum:');
      LLibraryIndex := BorlandValueForLabel(LLine, 'LibIndex:');
      LTime := BorlandValueForLabel(LLine, 'Time:');
    end
    else if (Pos(':', LLine) > 0) and (Pos('-', LLine) > 0) and
      (Pos('Flags:', LLine) > 0) then
    begin
      Inc(LSegmentCount);
      SetLength(LSegments, Length(LSegments) + 1);
      LSegments[High(LSegments)] := LLine;
    end;
  end;
  if LHasHeader then
  begin
    if LName <> '' then
      AControl.AddColumns(['Name', LName]);
    AControl.AddColumns(['Overlay', LOverlay]);
    AControl.AddColumns(['Library index', LLibraryIndex]);
    AControl.AddColumns(['Segments', LSegmentCount.ToString]);
    AControl.AddColumns(['Time', LTime]);
    for var LSegment in LSegments do
      AControl.AddColumns(['Segment', LSegment]);
  end;
end;

procedure AddSourceBackedGlobalSymbolDetails(AControl: THighlighterControl;
  ADocument: TDumpDocument; ASubsection: TDumpBorlandSubsection);
var
  LLineNumber: Integer;
  LLine: string;
  LRecordCount: Integer;
begin
  LRecordCount := 0;
  for var LSection in ADocument.LazyGlobalSymbolSections do
    if (LSection.ModIndex = ASubsection.ModIndex) and
      (LSection.FileOffset = ASubsection.FileOffset) then
    begin
      LRecordCount := LSection.Records.Count;
      Break;
    end;
  for LLineNumber := ASubsection.StartLine + 1 to ASubsection.EndLine do
  begin
    if LLineNumber > ASubsection.StartLine + 3 then
      Break;
    LLine := Trim(BorlandSourceLine(ADocument, LLineNumber));
    if StartsText('cbSymbols:', LLine) then
    begin
      AControl.AddColumns(['Symbol bytes', BorlandValueForLabel(LLine,
        'cbSymbols:')]);
      AControl.AddColumns(['Namespaces', BorlandValueForLabel(LLine,
        'cNamespaces:')]);
      AControl.AddColumns(['UDTs', BorlandValueForLabel(LLine, 'cUDTs:')]);
      AControl.AddColumns(['Others', BorlandValueForLabel(LLine, 'cOthers:')]);
      AControl.AddColumns(['Total', BorlandValueForLabel(LLine, 'Total:')]);
    end
    else if StartsText('SymHash:', LLine) then
      AControl.AddColumns(['Symbol hash', BorlandValueForLabel(LLine,
        'SymHash:')]);
  end;
  AControl.AddColumns(['Records', LRecordCount.ToString]);
end;

procedure AddSourceBackedGlobalTypeDetails(AControl: THighlighterControl;
  ADocument: TDumpDocument; ASubsection: TDumpBorlandSubsection);
var
  LLineNumber: Integer;
  LLine: string;
  LRecordCount: Integer;
begin
  LRecordCount := 0;
  for var LSection in ADocument.LazyGlobalTypeSections do
    if (LSection.ModIndex = ASubsection.ModIndex) and
      (LSection.FileOffset = ASubsection.FileOffset) then
    begin
      LRecordCount := LSection.Records.Count;
      Break;
    end;
  for LLineNumber := ASubsection.StartLine + 1 to ASubsection.EndLine do
  begin
    if LLineNumber > ASubsection.StartLine + 2 then
      Break;
    LLine := Trim(BorlandSourceLine(ADocument, LLineNumber));
    if StartsText('Number of types:', LLine) then
      AControl.AddColumns(['Declared types', BorlandValueForLabel(LLine,
        'Number of types:')]);
  end;
  AControl.AddColumns(['Parsed records', LRecordCount.ToString]);
end;

procedure AddSourceBackedNames(AControl: THighlighterControl;
  ADocument: TDumpDocument; ASubsection: TDumpBorlandSubsection);
var
  LLineNumber: Integer;
  LLine: string;
  LColon: Integer;
  LIndexText: string;
  LIndex: Integer;
begin
  for LLineNumber := ASubsection.StartLine + 1 to ASubsection.EndLine do
  begin
    LLine := Trim(BorlandSourceLine(ADocument, LLineNumber));
    LColon := Pos(':', LLine);
    if LColon <= 1 then
      Continue;
    LIndexText := Trim(Copy(LLine, 1, LColon - 1));
    if not TryStrToInt('$' + LIndexText, LIndex) then
      Continue;
    var LName := Trim(Copy(LLine, LColon + 1, MaxInt));
    if IsBorlandMethodName(LName) then
      AControl.AddColumns([LIndexText, LName], tpmCppBuilderMethod)
    else
      AControl.AddColumns([LIndexText, LName]);
  end;
end;

procedure AddLazyAlignSymbolSummary(AControl: THighlighterControl;
  ADocument: TDumpDocument; ASubsection: TDumpBorlandSubsection);
begin
  for var LSection in ADocument.LazyAlignSymbolSections do
    if (LSection.ModIndex = ASubsection.ModIndex) and
      (LSection.FileOffset = ASubsection.FileOffset) then
    begin
      var LSearchCount := 0;
      for var LRecord in LSection.Records do
        if LRecord.Kind = bsrkSearch then
          Inc(LSearchCount);
      AControl.AddColumns(['Records', LSection.Records.Count.ToString]);
      AControl.AddColumns(['Search records', LSearchCount.ToString]);
      Exit;
    end;
end;

procedure AddSourceBackedProperties(AControl: THighlighterControl;
  ADocument: TDumpDocument; ASubsection: TDumpBorlandSubsection);
var
  LLineNumber: Integer;
  LLine: string;
  LColon: Integer;
begin
  for LLineNumber := ASubsection.StartLine + 1 to ASubsection.EndLine do
  begin
    LLine := Trim(BorlandSourceLine(ADocument, LLineNumber));
    LColon := Pos(':', LLine);
    if (LColon > 1) and (Pos(' S_', LLine) = 0) then
      AControl.AddColumns([Trim(Copy(LLine, 1, LColon - 1)),
        Trim(Copy(LLine, LColon + 1, MaxInt))]);
  end;
end;

class procedure TBorlandView.PopulateSymbolTable(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;

  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Module', 'File offset', 'Size', 'Type']);
    AControl.SetColumnDataTypes([thdtHexadecimal, thdtHexadecimal,
      thdtHexadecimal, thdtText]);
    for var LSubsection in ADocument.SymbolSubsections do
    begin
      var LModule := LSubsection.RawModIndex;
      if LModule = '' then
        LModule := IntToHex(LSubsection.ModIndex, 4);
      var LFileOffset := LSubsection.RawFileOffset;
      if LFileOffset = '' then
        LFileOffset := IntToHex(LSubsection.FileOffset, 8);
      var LSize := LSubsection.RawSize;
      if LSize = '' then
        LSize := IntToHex(LSubsection.Size, 6);
      AControl.AddColumns([LModule, LFileOffset, LSize,
        LSubsection.SubsectionType]);
    end;
  finally
    AControl.EndUpdate;
  end;
end;

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
    AControl.UseColumnMode := True;
    AControl.AutoSizeColumns := True;
    AControl.ShowLineNumbers := False;
    if SameText(LSubsection.SubsectionType, 'sstNames') then
    begin
      AControl.SetColumnHeaders(['Index', 'Name']);
      AControl.SetColumnDataTypes([thdtHexadecimal, thdtAuto]);
      if ADocument.BorlandLazyRecords then
        AddSourceBackedNames(AControl, ADocument, LSubsection)
      else
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
          for var LSegment in LModule.Segments do
            AControl.AddColumns(['Segment', Format('%s:%s-%s  Flags: %s',
              [LSegment.RawSegment, LSegment.RawStartOffset,
               LSegment.RawEndOffset, LSegment.RawFlags])]);
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
    if ADocument.BorlandLazyRecords then
    begin
      if SameText(LSubsection.SubsectionType, 'sstModule') then
        AddSourceBackedModuleDetails(AControl, ADocument, LSubsection)
      else if SameText(LSubsection.SubsectionType, 'sstAlignSym') then
        AddLazyAlignSymbolSummary(AControl, ADocument, LSubsection)
      else if SameText(LSubsection.SubsectionType, 'sstGlobalSym') then
        AddSourceBackedGlobalSymbolDetails(AControl, ADocument, LSubsection)
      else if SameText(LSubsection.SubsectionType, 'sstGlobalTypes') then
        AddSourceBackedGlobalTypeDetails(AControl, ADocument, LSubsection)
      else if not SameText(LSubsection.SubsectionType, 'sstSrcModule') then
        AddSourceBackedProperties(AControl, ADocument, LSubsection);
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

class procedure TBorlandView.PopulateLazyAlignSymbolRecord(
  AControl: THighlighterControl; ADocument: TDumpDocument;
  ASection: TDumpLazyBorlandRecordSection; ARecordIndex: Integer);
  function TakeToken(var AText: string): string;
  begin
    AText := Trim(AText);
    var LSeparator := Pos(' ', AText);
    if LSeparator = 0 then
    begin
      Result := AText;
      AText := '';
    end
    else
    begin
      Result := Copy(AText, 1, LSeparator - 1);
      Delete(AText, 1, LSeparator);
      AText := Trim(AText);
    end;
  end;
  procedure AddLine(const ALine: string);
  begin
    var LText := Trim(ALine);
    if LText = '' then
      Exit;
    var LTypePos := Pos(' Type:', LText);
    if LTypePos > 1 then
    begin
      AControl.AddColumns(['Record offset', Trim(Copy(LText, 1,
        LTypePos - 1))]);
      var LTypeText := Trim(Copy(LText, LTypePos + Length(' Type:'), MaxInt));
      AControl.AddColumns(['Type index', TakeToken(LTypeText)]);
      if StartsText('Len:', LTypeText) then
      begin
        Delete(LTypeText, 1, Length('Len:'));
        LTypeText := Trim(LTypeText);
        AControl.AddColumns(['Length', TakeToken(LTypeText)]);
      end;
      if LTypeText <> '' then
        AControl.AddColumns(['Kind', TakeToken(LTypeText)]);
      Exit;
    end;
    var LRecordPos := Pos('S_', LText);
    if LRecordPos > 1 then
    begin
      AControl.AddColumns(['Record offset', Trim(Copy(LText, 1, LRecordPos - 1))]);
      AControl.AddColumns(['Record kind', Trim(Copy(LText, LRecordPos, MaxInt))]);
      Exit;
    end;
    var LNamePos := Pos('@', LText);
    if LNamePos > 0 then
    begin
      AControl.AddColumns(['Name', Trim(Copy(LText, LNamePos, MaxInt))],
        tpmCppBuilderMethod);
      Exit;
    end;
    var LColonPos := Pos(':', LText);
    if LColonPos > 1 then
      AControl.AddColumns([Trim(Copy(LText, 1, LColonPos - 1)),
        Trim(Copy(LText, LColonPos + 1, MaxInt))])
    else
      AControl.AddColumns(['Data', LText]);
  end;
begin
  if (AControl = nil) or (ADocument = nil) or (ADocument.TextSource = nil) or
    (ASection = nil) or (ARecordIndex < 0) or
    (ARecordIndex >= ASection.Records.Count) then
    Exit;
  var LRecord := ASection.Records[ARecordIndex];
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Name', 'Value']);
    for var LLineNumber := LRecord.StartLine to LRecord.EndLine do
      AddLine(ADocument.TextSource[LLineNumber - 1]);
  finally
    AControl.EndUpdate;
  end;
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
