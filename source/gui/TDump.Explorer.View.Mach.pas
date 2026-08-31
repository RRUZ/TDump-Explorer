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
    class procedure PopulateReportSection(AControl: THighlighterControl;
      ADocument: TDumpDocument; ASection: TDumpMachReportSection;
      ADetailKind: TTreeDetailKind); static;
    class function ArchitectureCaption(AArchitecture: TDumpMachArchitecture): string; static;
    class function LoadCommandCaption(ACommand: TDumpMachLoadCommand): string; static;
  end;

implementation

uses
  System.SysUtils,
  TDump.Explorer.Highlighter,
  TDump.Explorer.HighlighterProviders,
  TDump.Explorer.TinyParser;

function FirstMachReportField(var AText: string): string;
var
  LIndex: Integer;
begin
  AText := Trim(AText);
  LIndex := 1;
  while (LIndex <= Length(AText)) and not CharInSet(AText[LIndex], [' ', #9]) do
    Inc(LIndex);
  Result := Copy(AText, 1, LIndex - 1);
  Delete(AText, 1, LIndex - 1);
  AText := Trim(AText);
end;

function MachPropertyColumns(const ALine: string): string;
var
  LIndex: Integer;
  LLine: string;
begin
  LLine := Trim(ALine);
  for LIndex := 1 to Length(LLine) - 1 do
    if CharInSet(LLine[LIndex], [' ', #9]) and
      CharInSet(LLine[LIndex + 1], [' ', #9]) then
      Exit(Trim(Copy(LLine, 1, LIndex - 1)) + #9 +
        Trim(Copy(LLine, LIndex + 1, MaxInt)));
  Result := LLine + #9;
end;

function MachRebaseColumns(const ALine: string): string;
var
  LColon: Integer;
  LLine: string;
begin
  LLine := Trim(ALine);
  LColon := Pos(':', LLine);
  if LColon > 0 then
    Result := Trim(Copy(LLine, 1, LColon - 1)) + #9 +
      Trim(Copy(LLine, LColon + 1, MaxInt))
  else
    Result := LLine + #9;
end;

function MachRawSymbolColumns(const ALine: string): string;
var
  LWork: string;
begin
  LWork := ALine;
  Result := FirstMachReportField(LWork) + #9 + FirstMachReportField(LWork) +
    #9 + FirstMachReportField(LWork) + #9 + FirstMachReportField(LWork);
end;

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

class procedure TMachView.PopulateReportSection(AControl: THighlighterControl;
  ADocument: TDumpDocument; ASection: TDumpMachReportSection;
  ADetailKind: TTreeDetailKind);
begin
  if (AControl = nil) or (ADocument = nil) or (ASection = nil) or
    (ADocument.TextSource = nil) then
    Exit;
  if ADetailKind in [tdkMachDynamicSymbolTable, tdkMachBindingInfo,
    tdkMachWeakBindingInfo, tdkMachLazyBindingInfo, tdkMachExports,
    tdkMachRawSymbols] then
    AControl.ParserMode := tpmMachLinker
  else
    AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    case ADetailKind of
      tdkMachRebaseInfo:
        begin
          AControl.SetColumnHeaders(['Opcode', 'Operand']);
          AControl.SetColumnDataTypes([thdtSymbol, thdtAuto]);
        end;
      tdkMachResources:
        AControl.SetColumnHeaders(['Property', 'Value']);
      tdkMachRawSymbols:
        begin
          AControl.SetColumnHeaders(['#', 'Name Offset', 'Data Offset', 'Size']);
          AControl.SetColumnDataTypes([thdtInteger, thdtHexadecimal,
            thdtHexadecimal, thdtHexadecimal]);
        end;
    else
      begin
        AControl.SetColumnHeaders(['Instruction']);
        // The Mach report sections are source-backed text, not a fixed text
        // field.  Keep the detail view on the same semantic tokenizer as Raw
        // Output so linker symbols (including _ZN and _NS names) render the
        // same way in both directions.
        AControl.SetColumnDataTypes([thdtAuto]);
      end;
    end;
    AControl.SetItemProvider(TCallbackHighlighterRowProvider.Create(
      ASection.ItemCount,
      function(AIndex: Integer): string
      begin
        var LSourceLine := ADocument.TextSource[
          ASection.ItemStartLine - 1 + AIndex];
        case ADetailKind of
          tdkMachRebaseInfo: Result := MachRebaseColumns(LSourceLine);
          tdkMachResources: Result := MachPropertyColumns(LSourceLine);
          tdkMachRawSymbols: Result := MachRawSymbolColumns(LSourceLine);
        else
          Result := LSourceLine;
        end;
      end,
      nil, nil,
      function(AIndex: Integer): Integer
      begin
        Result := ASection.ItemStartLine - 1 + AIndex;
      end));
  finally
    AControl.EndUpdate;
  end;
end;

end.
