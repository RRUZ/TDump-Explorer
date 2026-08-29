//**************************************************************************************************
//
// Unit TDump.Explorer.View.ELF
//
// ELF detail view population
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.View.ELF;

interface

uses
  TDump.Explorer.Parser,
  TDump.Explorer.HighlighterControl;

type
  TELFView = record
    class procedure PopulateSectionHeaders(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateProgramHeaders(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateSymbolTable(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateDynamicSection(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateRelocations(AControl: THighlighterControl;
      ADocument: TDumpDocument; const ASectionName: string); static;
    class function DynamicSectionCaption(ADocument: TDumpDocument): string; static;
    class function RelocationsCaption(ADocument: TDumpDocument;
      const ASectionName: string): string; static;
  end;

implementation

uses
  System.SysUtils,
  System.Generics.Collections,
  TDump.Explorer.Highlighter,
  TDump.Explorer.TinyParser,
  TDump.Explorer.View.Shared;

class function TELFView.DynamicSectionCaption(ADocument: TDumpDocument): string;
begin
  Result := Format('ELF Dynamic Section [%d entries]',
    [ADocument.ELFDynamicEntries.Count]);
end;

class procedure TELFView.PopulateSectionHeaders(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Ndx', 'Name', 'Type', 'Flags', 'Address',
      'Offset', 'Size', 'Link', 'Info', 'Align', 'Entry size']);
    AControl.SetColumnDataTypes([thdtInteger, thdtText, thdtSymbol,
      thdtSymbol, thdtHexadecimal, thdtHexadecimal, thdtHexadecimal,
      thdtHexadecimal, thdtHexadecimal, thdtHexadecimal, thdtHexadecimal]);
    for var LSection in ADocument.Sections do
      AControl.AddColumns([IntToStr(LSection.Index), LSection.Name,
        PropertyValue(LSection.Properties, 'Type'),
        PropertyValue(LSection.Properties, 'Flags'),
        PropertyValue(LSection.Properties, 'Address'),
        PropertyValue(LSection.Properties, 'Offset'),
        PropertyValue(LSection.Properties, 'Size'),
        PropertyValue(LSection.Properties, 'Link'),
        PropertyValue(LSection.Properties, 'Info'),
        PropertyValue(LSection.Properties, 'Align'),
        PropertyValue(LSection.Properties, 'Entry size')]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TELFView.PopulateProgramHeaders(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Ndx', 'Type', 'Offset', 'VAddr', 'PAddr',
      'File size', 'Memory size', 'Flags', 'Align']);
    AControl.SetColumnDataTypes([thdtInteger, thdtSymbol, thdtHexadecimal,
      thdtHexadecimal, thdtHexadecimal, thdtHexadecimal, thdtHexadecimal,
      thdtSymbol, thdtHexadecimal]);
    for var LHeader in ADocument.ELFProgramHeaders do
      AControl.AddColumns([IntToStr(LHeader.Index), LHeader.HeaderType,
        LHeader.Offset, LHeader.VirtualAddress, LHeader.PhysicalAddress,
        LHeader.FileSize, LHeader.MemorySize, LHeader.Flags,
        LHeader.Alignment]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TELFView.PopulateSymbolTable(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;
  AControl.ParserMode := tpmCppBuilderMethod;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Ndx', 'Name', 'Value', 'Size', 'Type',
      'Bind', 'Other', 'Section']);
    AControl.SetColumnDataTypes([thdtInteger, thdtAuto, thdtHexadecimal,
      thdtHexadecimal, thdtSymbol, thdtSymbol, thdtSymbol, thdtSymbol]);
    for var LSymbol in ADocument.Symbols do
      AControl.AddColumns([PropertyValue(LSymbol.Properties, 'Index'),
        PropertyValue(LSymbol.Properties, 'Name'),
        PropertyValue(LSymbol.Properties, 'Value'),
        PropertyValue(LSymbol.Properties, 'Size'),
        PropertyValue(LSymbol.Properties, 'Type'),
        PropertyValue(LSymbol.Properties, 'Bind'),
        PropertyValue(LSymbol.Properties, 'Other'),
        PropertyValue(LSymbol.Properties, 'Section')]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TELFView.PopulateDynamicSection(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Ndx', 'Tag', 'Value']);
    AControl.SetColumnDataTypes([thdtInteger, thdtSymbol, thdtHexadecimal]);
    for var LEntry in ADocument.ELFDynamicEntries do
      AControl.AddColumns([LEntry.Index.ToString, LEntry.Tag, LEntry.Value]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TELFView.PopulateRelocations(AControl: THighlighterControl;
  ADocument: TDumpDocument; const ASectionName: string);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;
  AControl.ParserMode := tpmCppBuilderMethod;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    if ASectionName = '' then
    begin
      var LCounts := TDictionary<string, Integer>.Create;
      try
        for var LRelocation in ADocument.ELFRelocations do
        begin
          var LCount := 0;
          LCounts.TryGetValue(LRelocation.SectionName, LCount);
          LCounts.AddOrSetValue(LRelocation.SectionName, LCount + 1);
        end;
        AControl.SetColumnHeaders(['Section', 'Entries']);
        AControl.SetColumnDataTypes([thdtText, thdtInteger]);
        for var LSectionName in LCounts.Keys do
          AControl.AddColumns([LSectionName, LCounts[LSectionName].ToString]);
      finally
        LCounts.Free;
      end;
    end
    else
    begin
      AControl.SetColumnHeaders(['Ndx', 'Type', 'Offset', '(Addend)', 'Value',
        'Symbol', 'Addend', 'Name']);
      AControl.SetColumnDataTypes([thdtInteger, thdtSymbol, thdtHexadecimal,
        thdtHexadecimal, thdtHexadecimal, thdtInteger, thdtHexadecimal,
        thdtAuto]);
      for var LRelocation in ADocument.ELFRelocations do
        if SameText(LRelocation.SectionName, ASectionName) then
          AControl.AddColumns([IntToStr(LRelocation.Index),
            LRelocation.RelocationType, LRelocation.Offset,
            LRelocation.ParenthesizedAddend, LRelocation.Value,
            LRelocation.SymbolIndex, LRelocation.Addend, LRelocation.Name]);
    end;
  finally
    AControl.EndUpdate;
  end;
end;

class function TELFView.RelocationsCaption(ADocument: TDumpDocument;
  const ASectionName: string): string;
begin
  if ASectionName = '' then
    Result := Format('ELF Relocation Tables [%d entries]',
      [ADocument.ELFRelocations.Count])
  else
    Result := 'ELF Relocations ' + ASectionName;
end;

end.
