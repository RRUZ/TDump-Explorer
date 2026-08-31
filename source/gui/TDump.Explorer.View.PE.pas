//**************************************************************************************************
//
// Unit TDump.Explorer.View.PE
//
// PE detail view population
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.View.PE;

interface

uses
  TDump.Explorer.Parser,
  TDump.Explorer.HighlighterControl;

type
  TPEView = record
    class procedure PopulateDataDirectories(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateObjectTable(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateRelocations(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateRelocationBlock(AControl: THighlighterControl;
      ABlock: TDumpRelocationBlock); static;
    class procedure PopulateStrings(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateImportDirectory(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateImportModule(AControl: THighlighterControl;
      AModule: TDumpImportModule; ADelayed: Boolean); static;
    class procedure PopulateDelayedImportTable(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateExportDirectory(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateResourceDirectory(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateResource(AControl: THighlighterControl;
      AResource: TDumpResource); static;
    class function RelocationBlockCaption(ABlock: TDumpRelocationBlock): string; static;
    class function ImportModuleCaption(AModule: TDumpImportModule): string; static;
    class function ResourceDirectoryCaption(ADocument: TDumpDocument): string; static;
  end;

implementation

uses
  System.SysUtils,
  TDump.Explorer.Highlighter,
  TDump.Explorer.HighlighterProviders,
  TDump.Explorer.TinyParser,
  TDump.Explorer.UI;

class procedure TPEView.PopulateDataDirectories(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Name', 'RVA', 'Size']);
    AControl.SetColumnDataTypes([thdtText, thdtHexadecimal, thdtHexadecimal]);
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.DataDirectories.Count,
      function(AIndex: Integer): string
      begin
        var LDirectory := ADocument.DataDirectories[AIndex];
        var LRVA := LDirectory.RawRVA;
        if LRVA = '' then
          LRVA := IntToHex(LDirectory.RVA, 8);
        var LSize := LDirectory.RawSize;
        if LSize = '' then
          LSize := IntToHex(LDirectory.Size, 8);
        Result := Format('%s'#9'%s'#9'%s', [LDirectory.Name, LRVA, LSize]);
      end));
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TPEView.PopulateObjectTable(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['#', 'Name', 'VirtSize', 'RVA', 'PhysSize',
      'Phys off', 'Flags']);
    AControl.SetColumnDataTypes([thdtHexadecimal, thdtText, thdtHexadecimal,
      thdtHexadecimal, thdtHexadecimal, thdtHexadecimal, thdtSymbol]);
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.Sections.Count + 2,
      function(AIndex: Integer): string
      begin
        if AIndex = ADocument.Sections.Count then
          Exit('Key to section flags:'#9#9#9#9#9#9);
        if AIndex = ADocument.Sections.Count + 1 then
          Exit('C - code'#9'D - discardable'#9'E - executable'#9 +
            'I - initialized'#9'R - readable'#9'W - writeable'#9);
        var LSection := ADocument.Sections[AIndex];
        Result := Format('%s'#9'%s'#9'%s'#9'%s'#9'%s'#9'%s'#9'%s',
          [IntToHex(LSection.Index, 2), LSection.Name,
           IntToHex(LSection.VirtualSize, 8), IntToHex(LSection.RVA, 8),
           IntToHex(LSection.RawSize, 8), IntToHex(LSection.RawOffset, 8),
           LSection.FlagsText]);
      end));
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TPEView.PopulateRelocations(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Block', 'Page RVA', 'Block size', 'Entries']);
    AControl.SetColumnDataTypes([thdtInteger, thdtHexadecimal,
      thdtHexadecimal, thdtInteger]);
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.RelocationBlocks.Count,
      function(AIndex: Integer): string
      begin
        var LBlock := ADocument.RelocationBlocks[AIndex];
        Result := Format('%s'#9'%s'#9'%s'#9'%d',
          [UIntToStr(LBlock.Index), IntToHex(LBlock.PageRVA, 8),
           IntToHex(LBlock.BlockSize, 8), LBlock.Entries.Count]);
      end));
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TPEView.PopulateRelocationBlock(AControl: THighlighterControl;
  ABlock: TDumpRelocationBlock);
const
  RelocationsPerRow = 4;
begin
  if (AControl = nil) or (ABlock = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.UseColumnMode := True;
    AControl.ShowLineNumbers := False;
    AControl.AutoSizeColumns := True;
    AControl.Font.Name := TExplorerTheme.FontName;
    AControl.Font.Size := TExplorerTheme.FontSize;
    AControl.SetColumnDataTypes([
      thdtSymbol, thdtHexadecimal, thdtSymbol, thdtHexadecimal,
      thdtSymbol, thdtHexadecimal, thdtSymbol, thdtHexadecimal]);
    AControl.SetColumnParserModes([
      tpmTDumpValues, tpmTDumpValues, tpmTDumpValues, tpmTDumpValues,
      tpmTDumpValues, tpmTDumpValues, tpmTDumpValues, tpmTDumpValues]);

    var LColumns: TArray<string>;
    SetLength(LColumns, RelocationsPerRow * 2);
    for var LEntryIndex := 0 to ABlock.Entries.Count - 1 do
    begin
      var LRelocation := ABlock.Entries[LEntryIndex];
      var LOffset := LRelocation.RawOffset;
      if (LOffset = '') and LRelocation.HasOffset then
        LOffset := IntToHex(LRelocation.Offset, 4);

      var LColumnIndex := (LEntryIndex mod RelocationsPerRow) * 2;
      LColumns[LColumnIndex] := LRelocation.RelocationType;
      LColumns[LColumnIndex + 1] := LOffset;
      if (LEntryIndex mod RelocationsPerRow) = RelocationsPerRow - 1 then
      begin
        AControl.AddColumns(LColumns);
        LColumns := nil;
        SetLength(LColumns, RelocationsPerRow * 2);
      end;
    end;

    if (ABlock.Entries.Count mod RelocationsPerRow) <> 0 then
      AControl.AddColumns(LColumns);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TPEView.PopulateStrings(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  // Extracted strings often contain Delphi/C++ type and method names.  They
  // are not report values, so render their semantic syntax in the same mode
  // used for demangled symbols.
  AControl.ParserMode := tpmExtractedString;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Offset', 'String']);
    AControl.SetColumnDataTypes([thdtInteger, thdtAuto]);
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.Strings.Count,
      function(AIndex: Integer): string
      begin
        var LEntry := ADocument.Strings[AIndex];
        var LOffset := '';
        if LEntry.HasOffset then
          LOffset := UIntToStr(LEntry.Offset);
        Result := LOffset + #9 + LEntry.Value;
      end));
  finally
    AControl.EndUpdate;
  end;
end;

class function TPEView.ImportModuleCaption(AModule: TDumpImportModule): string;
begin
  Result := AModule.Name;
  if Result = '' then
    Result := 'Unnamed import module';
end;

class procedure TPEView.PopulateImportDirectory(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmCppBuilderMethod;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.UseColumnMode := True;
    AControl.ShowLineNumbers := False;
    AControl.AutoSizeColumns := False;
    AControl.Font.Name := TExplorerTheme.FontName;
    AControl.Font.Size := TExplorerTheme.FontSize;
    AControl.SetColumnHeaders(['Module', 'Imports']);
    AControl.SetColumnDataTypes([thdtSymbol, thdtInteger]);
    AControl.SetColumnParserModes([tpmTDumpValues, tpmTDumpValues]);
    AControl.SetColumnWidthWeights([1, 1]);
    for var LModule in ADocument.Imports do
      AControl.AddColumns([ImportModuleCaption(LModule),
        LModule.Entries.Count.ToString]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TPEView.PopulateImportModule(AControl: THighlighterControl;
  AModule: TDumpImportModule; ADelayed: Boolean);
begin
  if (AControl = nil) or (AModule = nil) then Exit;
  if ADelayed then
  begin
    AControl.ParserMode := tpmTDumpValues;
    AControl.BeginUpdate;
    try
      AControl.Clear;
      AControl.SetColumnHeaders(['Property', 'Value']);
      AControl.SetColumnDataTypes([thdtAuto, thdtHexadecimal]);
      for var LProperty in AModule.Properties do
        AControl.AddColumns([LProperty.Name, LProperty.RawValue]);
      for var LImport in AModule.Entries do
      begin
        var LImportText := Trim(LImport.RawText);
        if LImportText = '' then LImportText := LImport.Name;
        var LFlagStart := LastDelimiter('(', LImportText);
        var LMethodText := LImportText;
        var LFlagsText := '';
        if LFlagStart > 1 then
        begin
          LMethodText := Trim(Copy(LImportText, 1, LFlagStart - 1));
          LFlagsText := Trim(Copy(LImportText, LFlagStart, MaxInt));
        end;
        AControl.AddColumns([LMethodText, LFlagsText], tpmCppBuilderMethod);
      end;
      if AModule.Entries.Count = 0 then
        AControl.AddColumns(['Imports', 'No imported methods.']);
    finally
      AControl.EndUpdate;
    end;
    Exit;
  end;

  AControl.ParserMode := tpmCppBuilderMethod;
  var LText := TStringBuilder.Create;
  try
    for var LProperty in AModule.Properties do
      LText.AppendLine(Format('%-30s %s', [LProperty.Name, LProperty.RawValue]));
    if AModule.Properties.Count > 0 then LText.AppendLine;
    if AModule.Entries.Count = 0 then
      LText.AppendLine('No imported methods.')
    else
      for var LImport in AModule.Entries do
        if Trim(LImport.RawText) <> '' then
          LText.AppendLine(Trim(LImport.RawText))
        else
          LText.AppendLine(LImport.Name);
    AControl.SetText(LText.ToString);
  finally
    LText.Free;
  end;
end;

class procedure TPEView.PopulateDelayedImportTable(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) or
    (ADocument.DelayedImportTable = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.UseColumnMode := True;
    AControl.ShowLineNumbers := False;
    AControl.AutoSizeColumns := False;
    AControl.Font.Name := TExplorerTheme.FontName;
    AControl.Font.Size := TExplorerTheme.FontSize;
    AControl.SetColumnHeaders(['Module', 'Imports']);
    AControl.SetColumnDataTypes([thdtSymbol, thdtInteger]);
    AControl.SetColumnParserModes([tpmTDumpValues, tpmTDumpValues]);
    AControl.SetColumnWidthWeights([1, 1]);
    for var LModule in ADocument.DelayedImportTable.Modules do
      AControl.AddColumns([ImportModuleCaption(LModule),
        LModule.Entries.Count.ToString]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TPEView.PopulateExportDirectory(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmCppBuilderMethod;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['RVA', 'Ord.', 'Hint', 'Name']);
    AControl.SetColumnDataTypes([thdtHexadecimal, thdtInteger,
      thdtHexadecimal, thdtAuto]);
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.ExportList.Count,
      function(AIndex: Integer): string
      begin
        var LExport := ADocument.ExportList[AIndex];
        var LRVA := ''; if LExport.HasRVA then LRVA := IntToHex(LExport.RVA, 8);
        var LOrdinal := ''; if LExport.HasOrdinal then LOrdinal := LExport.Ordinal.ToString;
        var LHint := ''; if LExport.HasHint then LHint := IntToHex(LExport.Hint, 4);
        var LName := LExport.DemangledName;
        if LName = '' then LName := LExport.Name;
        Result := Format('%s'#9'%s'#9'%s'#9'%s',
          [LRVA, LOrdinal, LHint, LName]);
      end));
  finally
    AControl.EndUpdate;
  end;
end;

class function TPEView.ResourceDirectoryCaption(ADocument: TDumpDocument): string;
begin
  Result := 'Resources';
  if (ADocument.ResourceMetadata <> nil) and
    ADocument.ResourceMetadata.HasRootDirectoryCounts then
    Result := Format('Resources [%d named entries, %d ID entries]',
      [ADocument.ResourceMetadata.RootNamedEntryCount,
       ADocument.ResourceMetadata.RootIdEntryCount]);
end;

class procedure TPEView.PopulateResourceDirectory(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Type', 'Name', 'Lang', 'Id']);
    AControl.SetColumnDataTypes([thdtText, thdtText, thdtText, thdtInteger]);
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.Resources.Count,
      function(AIndex: Integer): string
      begin
        var LResource := ADocument.Resources[AIndex];
        var LName := LResource.Name;
        if SameText(LResource.ResourceType, LName) then LName := '';
        var LId := ''; if LResource.HasId then LId := LResource.Id.ToString;
        Result := Format('%s'#9'%s'#9'%s'#9'%s',
          [LResource.ResourceType, LName, LResource.Language, LId]);
      end));
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TPEView.PopulateResource(AControl: THighlighterControl;
  AResource: TDumpResource);
begin
  if (AControl = nil) or (AResource = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Name', 'Value']);
    if AResource.ResourceType <> '' then AControl.AddColumns(['Type', AResource.ResourceType]);
    if (AResource.Name <> '') and not SameText(AResource.Name, AResource.ResourceType) then
      AControl.AddColumns(['Name', AResource.Name]);
    if AResource.HasId then AControl.AddColumns(['Id', AResource.Id.ToString]);
    if AResource.Language <> '' then AControl.AddColumns(['Language', AResource.Language]);
    if AResource.HasDirectoryCounts then
    begin
      AControl.AddColumns(['Named entries', AResource.NamedEntryCount.ToString]);
      AControl.AddColumns(['ID entries', AResource.IdEntryCount.ToString]);
    end;
    if AResource.HasDirectoryOffset then AControl.AddColumns(['Directory offset', IntToHex(AResource.DirectoryOffset, 8)]);
    if AResource.HasDataOffset then AControl.AddColumns(['Offset', IntToHex(AResource.DataOffset, 8)])
    else if AResource.HasRVA then AControl.AddColumns(['RVA', IntToHex(AResource.RVA, 8)]);
    if AResource.HasFileOffset then AControl.AddColumns(['File offset', IntToHex(AResource.FileOffset, 8)]);
    if AResource.HasSize then AControl.AddColumns(['Size', IntToHex(AResource.Size, 8)]);
    if AResource.HasCodePage then AControl.AddColumns(['Code page', IntToHex(AResource.CodePage, 8)]);
    if AResource.HasReserved then AControl.AddColumns(['Reserved', IntToHex(AResource.Reserved, 8)]);
    for var LProperty in AResource.Properties do
      if not SameText(LProperty.Name, 'Type') and not SameText(LProperty.Name, 'Offset') and
        not SameText(LProperty.Name, 'Size') and not SameText(LProperty.Name, 'Code Page') and
        not SameText(LProperty.Name, 'Reserved') then
        AControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    AControl.EndUpdate;
  end;
end;

class function TPEView.RelocationBlockCaption(ABlock: TDumpRelocationBlock): string;
begin
  Result := '';
  if ABlock <> nil then
    Result := Format('Block #%d: Page RVA = %s, block size = %s',
      [ABlock.Index, IntToHex(ABlock.PageRVA, 8), IntToHex(ABlock.BlockSize, 8)]);
end;

end.
