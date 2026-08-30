//**************************************************************************************************
//
// Unit TDump.Explorer.View.Mach
//
// Mach detail view population
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.View.Mach;

interface

uses
  TDump.Explorer.Parser,
  TDump.Explorer.HighlighterControl,
  TDump.Explorer.View.Shared;

type
  TMachView = record
    class procedure PopulateArchitectures(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateArchitecture(AControl: THighlighterControl;
      AArchitecture: TDumpMachArchitecture); static;
    class procedure PopulateLoadCommands(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateLoadCommand(AControl: THighlighterControl;
      ACommand: TDumpMachLoadCommand); static;
    class procedure PopulateSection(AControl: THighlighterControl;
      ASection: TDumpMachSection); static;
    class procedure PopulateSymbolTable(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class procedure PopulateDynamicSymbols(AControl: THighlighterControl;
      ADocument: TDumpDocument; ADetailKind: TTreeDetailKind); static;
    class procedure PopulateDynamicSymbolMetadata(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class function ArchitectureCaption(AArchitecture: TDumpMachArchitecture): string; static;
    class function LoadCommandCaption(ACommand: TDumpMachLoadCommand): string; static;
  end;

implementation

uses
  System.SysUtils,
  TDump.Explorer.Highlighter,
  TDump.Explorer.HighlighterProviders,
  TDump.Explorer.TinyParser;

class function TMachView.ArchitectureCaption(
  AArchitecture: TDumpMachArchitecture): string;
begin
  Result := '';
  if AArchitecture = nil then
    Exit;
  Result := AArchitecture.CPUType;
  if AArchitecture.CPUSubtype <> '' then
    Result := Result + ' (' + AArchitecture.CPUSubtype + ')';
end;

class function TMachView.LoadCommandCaption(
  ACommand: TDumpMachLoadCommand): string;
begin
  Result := '';
  if ACommand <> nil then
    Result := Format('#%d %s', [ACommand.Index, ACommand.Name]);
end;

class procedure TMachView.PopulateArchitectures(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['CPU type', 'CPU subtype', 'File offset']);
    AControl.SetColumnDataTypes([thdtSymbol, thdtSymbol, thdtHexadecimal]);
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.MachArchitectures.Count,
      function(AIndex: Integer): string
      begin
        var LArchitecture := ADocument.MachArchitectures[AIndex];
        var LOffset := '';
        if LArchitecture.HasOffset then
          LOffset := IntToHex(LArchitecture.Offset, 8);
        Result := Format('%s'#9'%s'#9'%s',
          [LArchitecture.CPUType, LArchitecture.CPUSubtype, LOffset]);
      end));
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TMachView.PopulateArchitecture(AControl: THighlighterControl;
  AArchitecture: TDumpMachArchitecture);
begin
  if (AControl = nil) or (AArchitecture = nil) then
    Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Name', 'Value']);
    AControl.AddColumns(['CPU type', AArchitecture.CPUType]);
    AControl.AddColumns(['CPU subtype', AArchitecture.CPUSubtype]);
    if AArchitecture.HasOffset then
      AControl.AddColumns(['File offset', IntToHex(AArchitecture.Offset, 8)]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TMachView.PopulateLoadCommands(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['#', 'Command', 'Sections']);
    AControl.SetColumnDataTypes([thdtInteger, thdtSymbol, thdtInteger]);
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.MachLoadCommands.Count,
      function(AIndex: Integer): string
      begin
        var LCommand := ADocument.MachLoadCommands[AIndex];
        Result := Format('%d'#9'%s'#9'%d',
          [LCommand.Index, LCommand.Name, LCommand.Sections.Count]);
      end));
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TMachView.PopulateLoadCommand(AControl: THighlighterControl;
  ACommand: TDumpMachLoadCommand);
begin
  if (AControl = nil) or (ACommand = nil) then
    Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Name', 'Value']);
    AControl.AddColumns(['Index', IntToStr(ACommand.Index)]);
    AControl.AddColumns(['Command', ACommand.Name]);
    if ACommand.Sections.Count > 0 then
      AControl.AddColumns(['Sections', IntToStr(ACommand.Sections.Count)]);
    for var LProperty in ACommand.Properties do
      AControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TMachView.PopulateSection(AControl: THighlighterControl;
  ASection: TDumpMachSection);
begin
  if (AControl = nil) or (ASection = nil) then
    Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Name', 'Value']);
    for var LProperty in ASection.Properties do
      AControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TMachView.PopulateSymbolTable(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;
  AControl.ParserMode := tpmCppBuilderMethod;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Index', 'Type', 'Section', 'Desc', 'Value',
      'Name']);
    AControl.SetColumnDataTypes([thdtInteger, thdtSymbol, thdtSymbol,
      thdtHexadecimal, thdtHexadecimal, thdtAuto]);
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ADocument.MachSymbols.Count,
      function(AIndex: Integer): string
      begin
        var LSymbol := ADocument.MachSymbols[AIndex];
        Result := Format('%d'#9'%s'#9'%s'#9'%s'#9'%s'#9'%s',
          [LSymbol.Index, LSymbol.TypeCode, LSymbol.Section,
           LSymbol.Description, LSymbol.RawValue, LSymbol.Name]);
      end));
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TMachView.PopulateDynamicSymbols(AControl: THighlighterControl;
  ADocument: TDumpDocument; ADetailKind: TTreeDetailKind);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;
  AControl.ParserMode := tpmCppBuilderMethod;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Index', 'Name']);
    AControl.SetColumnDataTypes([thdtInteger, thdtAuto]);
    var LUseImports := ADetailKind = tdkMachDynamicImports;
    var LCount := ADocument.MachIndirectSymbols.Count;
    if LUseImports then
      LCount := ADocument.MachDynamicImports.Count;
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(LCount,
      function(AIndex: Integer): string
      begin
        var LSymbol: TDumpMachDynamicSymbol;
        if LUseImports then
          LSymbol := ADocument.MachDynamicImports[AIndex]
        else
          LSymbol := ADocument.MachIndirectSymbols[AIndex];
        Result := Format('%d'#9'%s', [LSymbol.Index, LSymbol.Name]);
      end));
  finally
    AControl.EndUpdate;
  end;
end;

class procedure TMachView.PopulateDynamicSymbolMetadata(
  AControl: THighlighterControl; ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) or
    (ADocument.MachDynamicSymbolTableCommand = nil) then
    Exit;
  var LCommand := ADocument.MachDynamicSymbolTableCommand;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Property', 'Value']);
    AControl.AddColumns(['Load command', LoadCommandCaption(LCommand)]);
    AControl.AddColumns(['Dynamic imports',
      ADocument.MachDynamicImports.Count.ToString]);
    AControl.AddColumns(['Indirect symbols',
      ADocument.MachIndirectSymbols.Count.ToString]);
    for var LProperty in LCommand.Properties do
      AControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    AControl.EndUpdate;
  end;
end;

end.
