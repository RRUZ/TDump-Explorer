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
  TDump.Explorer.TinyParser;

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
    for var LDirectory in ADocument.DataDirectories do
    begin
      var LRVA := LDirectory.RawRVA;
      if LRVA = '' then
        LRVA := IntToHex(LDirectory.RVA, 8);
      var LSize := LDirectory.RawSize;
      if LSize = '' then
        LSize := IntToHex(LDirectory.Size, 8);
      AControl.AddColumns([LDirectory.Name, LRVA, LSize]);
    end;
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
    for var LSection in ADocument.Sections do
      AControl.AddColumns([IntToHex(LSection.Index, 2), LSection.Name,
        IntToHex(LSection.VirtualSize, 8), IntToHex(LSection.RVA, 8),
        IntToHex(LSection.RawSize, 8), IntToHex(LSection.RawOffset, 8),
        LSection.FlagsText]);
    AControl.AddColumns(['Key to section flags:', '', '', '', '', '', '']);
    AControl.AddColumns(['C - code', 'D - discardable', 'E - executable',
      'I - initialized', 'R - readable', 'W - writeable', '']);
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
    for var LBlock in ADocument.RelocationBlocks do
      AControl.AddColumns([UIntToStr(LBlock.Index), IntToHex(LBlock.PageRVA, 8),
        IntToHex(LBlock.BlockSize, 8), IntToStr(LBlock.Entries.Count)]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TPEView.PopulateRelocationBlock(AControl: THighlighterControl;
  ABlock: TDumpRelocationBlock);
begin
  if (AControl = nil) or (ABlock = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Type', 'Offset']);
    AControl.SetColumnDataTypes([thdtSymbol, thdtHexadecimal]);
    for var LRelocation in ABlock.Entries do
    begin
      var LOffset := LRelocation.RawOffset;
      if (LOffset = '') and LRelocation.HasOffset then
        LOffset := IntToHex(LRelocation.Offset, 4);
      AControl.AddColumns([LRelocation.RelocationType, LOffset]);
    end;
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TPEView.PopulateStrings(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Offset', 'String']);
    AControl.SetColumnDataTypes([thdtInteger, thdtText]);
    for var LEntry in ADocument.Strings do
    begin
      var LOffset := '';
      if LEntry.HasOffset then
        LOffset := UIntToStr(LEntry.Offset);
      AControl.AddColumns([LOffset, LEntry.Value]);
    end;
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
  var LText := TStringBuilder.Create;
  try
    LText.AppendLine('Import Directory');
    LText.AppendLine(Format('%d module(s)', [ADocument.Imports.Count]));
    LText.AppendLine;
    for var LModule in ADocument.Imports do
      LText.AppendLine(Format('%s [%d imported methods]',
        [ImportModuleCaption(LModule), LModule.Entries.Count]));
    AControl.SetText(LText.ToString);
  finally
    LText.Free;
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
  AControl.ParserMode := tpmCppBuilderMethod;
  var LText := TStringBuilder.Create;
  try
    LText.AppendLine('Delayed Load Import Table');
    LText.AppendLine(Format('%d module(s)',
      [ADocument.DelayedImportTable.Modules.Count]));
    LText.AppendLine;
    for var LModule in ADocument.DelayedImportTable.Modules do
      LText.AppendLine(Format('%s [%d imported methods]',
        [ImportModuleCaption(LModule), LModule.Entries.Count]));
    AControl.SetText(LText.ToString);
  finally
    LText.Free;
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
    for var LExport in ADocument.ExportList do
    begin
      var LRVA := ''; if LExport.HasRVA then LRVA := IntToHex(LExport.RVA, 8);
      var LOrdinal := ''; if LExport.HasOrdinal then LOrdinal := LExport.Ordinal.ToString;
      var LHint := ''; if LExport.HasHint then LHint := IntToHex(LExport.Hint, 4);
      var LName := LExport.DemangledName;
      if LName = '' then LName := LExport.Name;
      AControl.AddColumns([LRVA, LOrdinal, LHint, LName]);
    end;
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
    for var LResource in ADocument.Resources do
    begin
      var LName := LResource.Name;
      if SameText(LResource.ResourceType, LName) then LName := '';
      var LId := ''; if LResource.HasId then LId := LResource.Id.ToString;
      AControl.AddColumns([LResource.ResourceType, LName, LResource.Language, LId]);
    end;
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
