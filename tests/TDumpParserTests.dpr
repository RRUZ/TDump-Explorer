program TDumpParserTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.StrUtils,
  TDump.Explorer.Parser in '..\source\parser\TDump.Explorer.Parser.pas',
  TDump.Explorer.Runner in '..\source\common\TDump.Explorer.Runner.pas';

const
  CGeneratedFixtureDirectory = 'C:\dev\TDump-Explorer\fixtures\generated';
  CTurboDumpBannerFixture =
    'C:\dev\TDump-Explorer\fixtures\PlainVanilla.Delphi.Package.bpl.tdump';

procedure Require(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
end;

function ParseGeneratedFixture(const AFileName: string): TDumpDocument;
begin
  var LParser := TDumpParser.Create;
  try
    Result := LParser.ParseFile(TPath.Combine(CGeneratedFixtureDirectory,
      AFileName));
  finally
    LParser.Free;
  end;
end;

procedure TestTDumpReportRecognition;
begin
  var LFixtureFiles := TDirectory.GetFiles(CGeneratedFixtureDirectory,
    '*.tdump', TSearchOption.soAllDirectories);
  Require(Length(LFixtureFiles) > 0,
    'Generated TDUMP fixtures must be available for report recognition.');
  for var LFixtureFileName in LFixtureFiles do
    Require(IsTDumpReport(TFile.ReadAllText(LFixtureFileName,
      TEncoding.Default)), ExtractFileName(LFixtureFileName) +
      ' must be recognized as TDUMP output.');

  Require(not IsTDumpReport('Display of File sample.exe'),
    'A display line without TDUMP payload must not be accepted.');
  Require(not IsTDumpReport('This is an unrelated text file.'),
    'Unrelated text must not be accepted as TDUMP output.');
end;

procedure TestTDumpBinaryFileRecognition;
const
  CSupportedBinaryNames: array[0..19] of string = ('sample.exe', 'sample.dll',
    'sample.bpl', 'sample.dpl', 'sample.ocx', 'sample.cpl', 'sample.scr',
    'sample.com', 'sample.sys', 'sample.obj', 'sample.lib', 'sample.dcu',
    'sample.elf', 'sample.ar', 'sample.o', 'sample.a', 'sample.so',
    'sample.dylib', 'sample.bundle', 'sample.mach');
begin
  for var LFileName in CSupportedBinaryNames do
    Require(IsTDumpBinaryFile(LFileName), LFileName +
      ' must be recognized as a TDUMP binary input.');
  Require(IsTDumpBinaryFile('DCU.System.Win32.DCU'),
    'Known TDUMP binary extensions must be case-insensitive.');
  Require(not IsTDumpBinaryFile('report.tdump'),
    'TDUMP report text must not be classified as binary input.');
  Require(not IsTDumpBinaryFile('notes.txt'),
    'Unrelated text must not be classified as binary input.');
end;

procedure TestRunnerOptionProfiles;
begin
  Require(TDumpRunner.GetBestOptionText('sample.exe') = '-e -ed -ns',
    'PE executables must use the executable profile.');
  Require(TDumpRunner.GetBestOptionText('sample.obj') = '-o -ns',
    'Object files must use the object profile.');
  Require(TDumpRunner.GetBestOptionText('sample.lib') = '-l -ns',
    'OMF libraries must use the library profile.');
  Require(TDumpRunner.GetBestOptionText('sample.elf') = '-e -ns',
    'ELF files must use the executable profile.');
  Require(TDumpRunner.GetBestOptionText('sample.ar') = '-lh -ns',
    'Archive files must list their members.');
  Require(TDumpRunner.GetBestOptionText('Mach.Universal.Rad37.dylib') =
    '-M -ns',
    'Mach binaries must use TDUMP''s Mach profile.');
  Require(TDumpRunner.GetBestOptionText('sample.dcu') = '-ns',
    'Delphi units must let TDUMP select its native DCU reader.');
  Require(TDumpRunner.GetBestOptionText('report.txt') = '-ns',
    'Unknown extensions must preserve TDUMP''s automatic behavior.');
end;

procedure TestTypedRunnerOptions;
begin
  var LOptions := TDumpCommandOptions.Default;
  LOptions.DisplayHexadecimal := True;
  LOptions.HexOffsetMode := thomAbsolute;
  LOptions.HexStartOffset := '0x20';
  LOptions.ExecutableExportsOnly := True;
  LOptions.ExecutableImports := 'KERNEL32';
  LOptions.DisplayStrings := True;
  LOptions.StringMinimumLength := 6;
  LOptions.StringSearch := 'TDUMP';
  LOptions.ELFMemberDumpEnabled := True;
  LOptions.ELFMemberDump := 'member.o';
  Require(LOptions.ToText =
    '-ha=0x20 -ee -em=KERNEL32 -s6=TDUMP -lm=member.o -ns',
    'Typed runner options must preserve TDUMP switch spellings and values.');

  LOptions := TDumpCommandOptions.Default;
  LOptions.AsciiDisplay := tad7Bit;
  LOptions.DisplayHexadecimal := True;
  try
    LOptions.ToText;
    Require(False, 'Conflicting TDUMP display modes must be rejected.');
  except
    on EArgumentException do
      ;
  end;
end;

procedure TestDelphiUnitDiagnostics;
const
  CDCUFixtures: array[0..1] of string = ('DCU.System.Win32.invalid-magic.tdump',
    'DCU.Win32.invalid-magic.tdump');
begin
  for var LFixtureName in CDCUFixtures do
  begin
    var LDocument := ParseGeneratedFixture(LFixtureName);
    try
      Require(LDocument.FileKind = dfDelphiUnit,
        LFixtureName + ' must be classified as a Delphi unit diagnostic.');
      Require((LDocument.Diagnostics.Count = 1) and
        ContainsText(LDocument.Diagnostics[0].RawLine,
          'Unable to read file header'), LFixtureName +
          ' must retain TDUMP''s original DCU header error.');
    finally
      LDocument.Free;
    end;
  end;
end;

procedure TestShortToolDiagnosticCapture;
begin
  const CToolOutput = 'Display of File sample.dcu' + sLineBreak +
    'A TDUMP-specific diagnostic message.';
  var LParser := TDumpParser.Create;
  try
    var LDocument := LParser.ParseText(CToolOutput, 'sample.dcu');
    try
      Require((LDocument.FileKind = dfDelphiUnit) and
        (LDocument.Diagnostics.Count = 1),
        'A short DCU TDUMP result must retain its tool diagnostic.');
      Require(LDocument.Diagnostics[0].RawLine =
        'A TDUMP-specific diagnostic message.',
        'A short TDUMP result must preserve the complete tool message.');
    finally
      LDocument.Free;
    end;
  finally
    LParser.Free;
  end;
end;

procedure TestRawMachHexDump;
begin
  const CMachHexDump =
    'Turbo Dump  Version 6.6.2.0 Copyright (c) Embarcadero Technologies, Inc.' +
    sLineBreak + 'Display of File mach.universal.dylib' + sLineBreak +
    '000000: CA FE BA BE 00 00 00 02  01 00 00 07 00 00 00 03';
  Require(IsTDumpReport(CMachHexDump),
    'A redirected TDUMP Mach hex dump must be recognized as a report.');

  var LParser := TDumpParser.Create;
  try
    var LDocument := LParser.ParseText(CMachHexDump,
      'mach.universal.dylib.txt');
    try
      Require((LDocument.FileKind = dfMach) and
        (LDocument.Architecture = 'Mach FAT binary') and
        (LDocument.Headers.Count = 1) and
        (LDocument.Headers[0].Properties[0].RawValue = 'CAFEBABE'),
        'A raw Mach FAT hex dump must project its format and magic header.');
    finally
      LDocument.Free;
    end;
  finally
    LParser.Free;
  end;
end;

procedure TestTurboDumpMetadata;
begin
  var LParser := TDumpParser.Create;
  try
    var LDocument := LParser.ParseFile(CTurboDumpBannerFixture);
    try
      Require(LDocument.TurboDumpHeader =
        'Turbo Dump  Version 6.6.2.0 Copyright (c) 1988-2022 Embarcadero Technologies, Inc.',
        'The raw Turbo Dump banner must be retained.');
      Require(LDocument.TurboDumpHeaderLine = 1,
        'The Turbo Dump banner source line must be retained.');
      Require(LDocument.ToolVersion = '6.6.2.0',
        'The Turbo Dump version must exclude the copyright text.');
      Require((LDocument.PrimaryRun.TurboDumpHeader = LDocument.TurboDumpHeader) and
        (LDocument.PrimaryRun.ToolVersion = LDocument.ToolVersion),
        'The primary run must retain the Turbo Dump metadata.');
    finally
      LDocument.Free;
    end;
  finally
    LParser.Free;
  end;
end;

procedure TestPECoreProjection;
begin
  var LDocument := ParseGeneratedFixture('Package.Win32.pe-core.tdump');
  try
    Require(LDocument.Headers.Count = 2, 'PE core must project both headers.');
    Require(LDocument.Sections.Count = 10, 'PE core must project ten sections.');
    Require(LDocument.Imports.Count = 2, 'PE core must project two import modules.');
    Require((SameText(LDocument.Imports[0].Name, 'kernel32.dll')) and
      (LDocument.Imports[0].Entries.Count = 11),
      'The kernel32 module must contain only its eleven imported methods.');
    Require((SameText(LDocument.Imports[1].Name, 'rtl370.bpl')) and
      (LDocument.Imports[1].Entries.Count = 9),
      'The rtl370 module must contain only its nine imported methods.');
    Require(LDocument.ExportList.Count = 9, 'PE core must project nine exports.');
    Require(LDocument.Resources.Count = 2, 'PE core must project two resource roots.');
  finally
    LDocument.Free;
  end;
end;

procedure TestSourceSpanProvenance;
begin
  var LDocument := ParseGeneratedFixture('Package.Win32.pe-core.tdump');
  try
    Require(LDocument.Runs.Count = 1,
      'One ParseFile call must create one source run.');
    Require(LDocument.PrimaryRun = LDocument.Runs[0],
      'PrimaryRun must reference the document-owned source run.');
    Require(LDocument.PrimaryRun.Document = LDocument,
      'A source run must retain its owning document.');
    Require(SameText(LDocument.PrimaryRun.SourceFileName,
      LDocument.SourceFileName),
      'A source run must retain the parsed file name.');
    Require(LDocument.Nodes[0].SourceSpan.IsValid and
      (LDocument.Nodes[0].SourceSpan.Run = LDocument.PrimaryRun),
      'Generic nodes must retain a valid span in the primary run.');
    Require(LDocument.ExportList[0].SourceSpan.IsValid and
      (LDocument.ExportList[0].SourceSpan.Run = LDocument.PrimaryRun),
      'Semantic projections must retain a valid span in the primary run.');
    Require(LDocument.Lines[0].SourceSpan.IsValid and
      (LDocument.Lines[0].SourceSpan.StartLine = 1) and
      (LDocument.Lines[0].SourceSpan.EndLine = 1),
      'Lexical lines must retain their exact source span.');
  finally
    LDocument.Free;
  end;
end;

procedure TestCompactImports;
begin
  var LDocument := ParseGeneratedFixture('Dll.Win32.imports.tdump');
  try
    Require(LDocument.Imports.Count > 0, 'Compact imports must create modules.');
    Require(LDocument.Imports[0].Entries.Count > 0,
      'Compact imports must create entries.');
    Require(LDocument.UnsupportedStructures.Count = 0,
      'Valid compact imports must not be marked unsupported.');
    Require(LDocument.Diagnostics.Count = 0,
      'Valid compact imports must not produce diagnostics.');
  finally
    LDocument.Free;
  end;
end;

procedure TestCompactExports;
begin
  var LDocument := ParseGeneratedFixture('Dll.Win32.exports.tdump');
  try
    Require(LDocument.ExportList.Count = 2,
      'Compact exports must preserve both export rows.');
    Require(LDocument.ExportList[0].HasOrdinal,
      'Compact exports must decode an ordinal.');
    Require(LDocument.UnsupportedStructures.Count = 0,
      'Valid compact exports must not be marked unsupported.');
    Require(LDocument.Diagnostics.Count = 0,
      'Valid compact exports must not produce diagnostics.');
  finally
    LDocument.Free;
  end;
end;

procedure TestRelocations;
begin
  var LDocument := ParseGeneratedFixture('VCL.Win32.relocations.tdump');
  try
    Require(LDocument.Relocations.Count > 1000,
      'Relocation fixture must project its relocation entries.');
    Require(LDocument.Relocations[0].HasPageRVA and
      LDocument.Relocations[0].HasOffset,
      'Relocation entries must retain page RVA and relative offset.');
    Require(LDocument.UnsupportedStructures.Count = 0,
      'Valid Win32 relocation blocks must not produce malformed-entry findings.');
  finally
    LDocument.Free;
  end;
  LDocument := ParseGeneratedFixture('VCL.Win64.relocations.tdump');
  try
    Require(LDocument.Relocations.Count > 1000,
      'Win64 relocation fixture must project DIR64 relocation entries.');
    Require(SameText(LDocument.Relocations[0].RelocationType, 'DIR64'),
      'Win64 relocation entries must retain their relocation type.');
    Require(LDocument.UnsupportedStructures.Count = 0,
      'Valid Win64 relocation blocks must not produce malformed-entry findings.');
  finally
    LDocument.Free;
  end;
end;

procedure TestUnknownFallback;
begin
  var LDocument := ParseGeneratedFixture('AR.Library.Win64.invalid-data.tdump');
  try
    Require(LDocument.UnsupportedStructures.Count > 0,
      'Invalid TDUMP input must be split into fallback blocks.');
    Require(LDocument.UnsupportedStructures[0].Node.Kind = nkUnknown,
      'Fallback must use an unknown node.');
    var LCoveredLines: TArray<Boolean>;
    SetLength(LCoveredLines, LDocument.Lines.Count);
    for var LStructure in LDocument.UnsupportedStructures do
      for var LLineNumber := LStructure.Node.StartLine to LStructure.Node.EndLine do
        LCoveredLines[LLineNumber - 1] := True;
    for var LLineNumber := 0 to Length(LCoveredLines) - 1 do
      Require(LCoveredLines[LLineNumber],
        'Fallback blocks must cover every line of an invalid document.');
  finally
    LDocument.Free;
  end;
end;

procedure TestP2ProjectionsAndMerge;
begin
  var LDocument := ParseGeneratedFixture('VCL.Win32.strings.tdump');
  try
    Require((LDocument.Strings.Count > 100) and
      LDocument.Strings[0].HasOffset and
      LDocument.Strings[0].SourceSpan.IsValid,
      'Strings fixture must project typed, provenance-aware string entries.');
  finally
    LDocument.Free;
  end;

  LDocument := ParseGeneratedFixture('OMF.Object.Win32.tdump');
  try
    Require((LDocument.FileKind = dfOMFObject) and
      (LDocument.ObjectRecords.Count > 100) and
      SameText(LDocument.ObjectRecords[0].RecordKind, 'THEADR'),
      'OMF object fixture must project its typed record stream.');
  finally
    LDocument.Free;
  end;

  LDocument := ParseGeneratedFixture('OMF.Library.Win32.tdump');
  try
    Require((LDocument.FileKind = dfOMFLibrary) and
      (LDocument.ObjectRecords.Count > 20) and
      (LDocument.LibraryMembers.Count > 0) and
      (LDocument.LibraryMembers[0].Name <> ''),
      'OMF library fixture must project records and THEADR library members.');
  finally
    LDocument.Free;
  end;

  LDocument := ParseGeneratedFixture('Mach.Universal.Rad37.tdump');
  try
    Require((LDocument.FileKind = dfMach) and
      (LDocument.MachArchitectures.Count = 2) and
      (LDocument.MachLoadCommands.Count > 10) and
      LDocument.MachLoadCommands[0].SourceSpan.IsValid,
      'Mach fixture must project FAT architectures and load commands.');
  finally
    LDocument.Free;
  end;

  LDocument := ParseGeneratedFixture('ELF.Object.Win64.tdump');
  try
    Require((LDocument.FileKind = dfELFObject) and
      (LDocument.Headers.Count = 1) and
      (LDocument.Headers[0].Properties.Count >= 10) and
      (LDocument.Sections.Count = 12) and (LDocument.Symbols.Count >= 10) and
      LDocument.Symbols[0].SourceSpan.IsValid,
      'The real ELF fixture must project its header, sections, and symbols.');
  finally
    LDocument.Free;
  end;

  LDocument := ParseGeneratedFixture('COFF.Object.Win64.MinGW.tdump');
  try
    Require((LDocument.FileKind = dfCOFFObject) and
      (LDocument.Diagnostics.Count > 0),
      'The real COFF fixture must retain TDUMP''s unsupported-machine diagnostic.');
  finally
    LDocument.Free;
  end;

  var LFirst := ParseGeneratedFixture('VCL.Win32.pe-core.tdump');
  var LSecond := ParseGeneratedFixture('VCL.Win64.pe-core.tdump');
  try
    var LMerge := LFirst.MergeWith(LSecond);
    try
      Require((LMerge.Documents.Count = 2) and (LMerge.Runs.Count = 2),
        'A merge must retain both real fixture documents and runs.');
    finally
      LMerge.Free;
    end;
  finally
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TestGeneratedFixtureCoverage;
begin
  var LFixtureFiles := TDirectory.GetFiles(CGeneratedFixtureDirectory,
    '*.tdump', TSearchOption.soAllDirectories);
  Require(Length(LFixtureFiles) > 0, 'Generated fixture corpus must not be empty.');
  for var LFixtureFileName in LFixtureFiles do
  begin
    var LParser := TDumpParser.Create;
    try
      var LDocument := LParser.ParseFile(LFixtureFileName);
      try
        Require(LDocument.Nodes.Count > 1,
          ExtractFileName(LFixtureFileName) +
          ' must create a semantic or explicit fallback node.');
      finally
        LDocument.Free;
      end;
    finally
      LParser.Free;
    end;
  end;
end;

procedure TestGeneratedPECoreProjection;
begin
  var LFixtureFiles := TDirectory.GetFiles(CGeneratedFixtureDirectory,
    '*.pe-core.tdump', TSearchOption.soAllDirectories);
  Require(Length(LFixtureFiles) > 0,
    'Generated PE core fixtures must be available.');
  for var LFixtureFileName in LFixtureFiles do
  begin
    var LParser := TDumpParser.Create;
    try
      var LDocument := LParser.ParseFile(LFixtureFileName);
      try
        Require((LDocument.FileKind = dfPE) and
          (LDocument.Headers.Count = 2) and
          (LDocument.DataDirectories.Count = 16) and
          (LDocument.Sections.Count > 0),
          ExtractFileName(LFixtureFileName) +
          ' must retain the complete P0 PE projection.');
      finally
        LDocument.Free;
      end;
    finally
      LParser.Free;
    end;
  end;
end;

procedure TestGeneratedCompactProjections;
begin
  var LImportFixtures := TDirectory.GetFiles(CGeneratedFixtureDirectory,
    '*.imports.tdump', TSearchOption.soAllDirectories);
  Require(Length(LImportFixtures) > 0,
    'Generated compact-import fixtures must be available.');
  for var LFixtureFileName in LImportFixtures do
  begin
    var LDocument := ParseGeneratedFixture(ExtractFileName(LFixtureFileName));
    try
      Require((LDocument.Imports.Count > 0) and
        (LDocument.Imports[0].Entries.Count > 0) and
        (LDocument.Diagnostics.Count = 0),
        ExtractFileName(LFixtureFileName) +
        ' must project valid compact imports without diagnostics.');
    finally
      LDocument.Free;
    end;
  end;

  var LExportFixtures := TDirectory.GetFiles(CGeneratedFixtureDirectory,
    '*.exports.tdump', TSearchOption.soAllDirectories);
  Require(Length(LExportFixtures) > 0,
    'Generated compact-export fixtures must be available.');
  for var LFixtureFileName in LExportFixtures do
  begin
    var LDocument := ParseGeneratedFixture(ExtractFileName(LFixtureFileName));
    try
      Require((LDocument.ExportList.Count > 0) and
        LDocument.ExportList[0].HasOrdinal and
        (LDocument.Diagnostics.Count = 0),
        ExtractFileName(LFixtureFileName) +
        ' must project valid compact exports without diagnostics.');
    finally
      LDocument.Free;
    end;
  end;
end;

procedure TestInvalidFixtureFallback;
begin
  var LFixtureFiles := TDirectory.GetFiles(CGeneratedFixtureDirectory,
    '*.tdump', TSearchOption.soAllDirectories);
  var LInvalidCount := 0;
  for var LFixtureFileName in LFixtureFiles do
    if Pos('invalid-', LowerCase(ExtractFileName(LFixtureFileName))) > 0 then
    begin
      Inc(LInvalidCount);
      var LParser := TDumpParser.Create;
      try
        var LDocument := LParser.ParseFile(LFixtureFileName);
        try
          if LDocument.FileKind in [dfCOFFObject, dfDelphiUnit] then
            Require(LDocument.Diagnostics.Count > 0,
              ExtractFileName(LFixtureFileName) +
              ' must retain TDUMP''s COFF diagnostic.')
          else
            Require(LDocument.UnsupportedStructures.Count > 0,
              ExtractFileName(LFixtureFileName) +
              ' must explicitly preserve invalid input as unsupported.');
          Require(LDocument.Nodes.Count > 1,
            ExtractFileName(LFixtureFileName) +
            ' must create a bounded diagnostic or fallback node.');
        finally
          LDocument.Free;
        end;
      finally
        LParser.Free;
      end;
    end;
  Require(LInvalidCount > 0, 'Generated invalid fixtures must be available.');
end;

procedure TestDebugInformationProjection;
const
  CDebugFixtures: array[0..1] of string = (
    'Package.Win32.debug.tdump', 'Package.Win64.debug.tdump');
begin
  for var LFixtureName in CDebugFixtures do
  begin
    var LDocument := ParseGeneratedFixture(LFixtureName);
    try
      Require((LDocument.DebugInformation <> nil) and
        (LDocument.DebugInformation.SourceModules.Count > 0) and
        (LDocument.DebugInformation.Methods.Count > 0),
        LFixtureName + ' must create generic debug information and methods.');
      var LMethod := LDocument.DebugInformation.Methods[0];
      Require((LMethod.Symbol <> nil) and (LMethod.Node <> nil) and
        LMethod.SourceSpan.IsValid and
        (LMethod.SourceSpan.Run = LDocument.PrimaryRun),
        LFixtureName +
        ' methods must retain their specialized model and run provenance.');
    finally
      LDocument.Free;
    end;
  end;
end;

begin
  try
    TestTDumpReportRecognition;
    TestTDumpBinaryFileRecognition;
    TestRunnerOptionProfiles;
    TestTypedRunnerOptions;
    TestDelphiUnitDiagnostics;
    TestShortToolDiagnosticCapture;
    TestRawMachHexDump;
    TestTurboDumpMetadata;
    TestPECoreProjection;
    TestSourceSpanProvenance;
    TestCompactImports;
    TestCompactExports;
    TestRelocations;
    TestUnknownFallback;
    TestGeneratedFixtureCoverage;
    TestGeneratedPECoreProjection;
    TestGeneratedCompactProjections;
    TestInvalidFixtureFallback;
    TestDebugInformationProjection;
    TestP2ProjectionsAndMerge;
    Writeln('TDump parser assertions passed.');
  except
    on LException: Exception do
    begin
      Writeln(ErrOutput, LException.Message);
      ExitCode := 1;
    end;
  end;
end.
