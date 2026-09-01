program TDumpParserTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  System.StrUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Xml.NUnit,
  TDump.Explorer.TextSource in '..\source\parser\TDump.Explorer.TextSource.pas',
  TDump.Explorer.Parser in '..\source\parser\TDump.Explorer.Parser.pas',
  TDump.Explorer.Relations in '..\source\common\TDump.Explorer.Relations.pas',
  TDump.Explorer.Runner in '..\source\common\TDump.Explorer.Runner.pas';

const
  cGeneratedFixtureDirectory = 'C:\dev\TDump-Explorer\fixtures\generated';
  cTestResultsDirectory = 'C:\dev\TDump-Explorer\tests\test-results';
  cTestResultsFile = cTestResultsDirectory + '\TDumpParserTests.nunit.xml';
  cTurboDumpBannerFixture =
    'C:\dev\TDump-Explorer\fixtures\PlainVanilla.Delphi.Package.bpl.tdump';
  cLargeVCLFixture =
    'C:\dev\TDump-Explorer\fixtures\PlainVanilla.VCL.Application.tdump';

type
  [TestFixture]
  TParserFixture = class
  public
    [Test] procedure ReportRecognition;
    [Test] procedure BinaryFileRecognition;
    [Test] procedure RunnerOptionProfiles;
    [Test] procedure TypedRunnerOptions;
    [Test] procedure DelphiUnitDiagnostics;
    [Test] procedure ShortToolDiagnosticCapture;
    [Test] procedure RawMachHexDump;
    [Test] procedure TurboDumpMetadata;
    [Test] procedure PECoreProjection;
    [Test] procedure SourceSpanProvenance;
    [Test] procedure CompactImports;
    [Test] procedure DelayedLoadImports;
    [Test] procedure CompactExports;
    [Test] procedure Relocations;
    [Test] procedure UnknownFallback;
    [Test] procedure GeneratedFixtureCoverage;
    [Test] procedure GeneratedPECoreProjection;
    [Test] procedure GeneratedCompactProjections;
    [Test] procedure InvalidFixtureFallback;
    [Test] procedure DebugInformationProjection;
    [Test] procedure P2ProjectionsAndMerge;
    [Test] procedure MachRawSyntaxHints;
    [Test] procedure OMFRawSyntaxHints;
    [Test] procedure OMFFixUpAndLEDataProjection;
    [Test] procedure MachReportSections;
    [Test] procedure GeneratedDocumentIntegrity;
    [Test] procedure GeneratedNativeFormatCoverage;
    [Test] procedure GeneratedBorlandDebugCoverage;
    [Test] procedure RelationGraph;
    [Test] procedure ARArchiveProjection;
    [Test] procedure ELFProgramHeadersProjection;
    [Test] procedure LargeReportStructuredProjection;
  end;

procedure Require(ACondition: Boolean; const AMessage: string);
begin
  Assert.IsTrue(ACondition, AMessage);
end;

function ParseGeneratedFixture(const AFileName: string): TDumpDocument;
begin
  var LParser := TDumpParser.Create;
  try
    Result := LParser.ParseFile(TPath.Combine(cGeneratedFixtureDirectory,
      AFileName));
  finally
    LParser.Free;
  end;
end;

procedure RequireGeneratedDocumentIntegrity(const AFileName: string;
  ADocument: TDumpDocument);
begin
  Require(ADocument <> nil, AFileName + ' must produce a document.');
  Require(ADocument.Lines.Count > 0,
    AFileName + ' must retain its physical source lines.');
  Require((ADocument.Runs.Count = 1) and
    (ADocument.PrimaryRun = ADocument.Runs[0]) and
    (ADocument.PrimaryRun.Document = ADocument),
    AFileName + ' must retain one document-owned source run.');
  Require(SameText(ADocument.PrimaryRun.SourceFileName,
    ADocument.SourceFileName),
    AFileName + ' must retain its source file name in the source run.');

  for var LIndex := 0 to ADocument.Lines.Count - 1 do
  begin
    var LLine := ADocument.Lines[LIndex];
    Require((LLine.LineNumber = LIndex + 1) and LLine.SourceSpan.IsValid and
      (LLine.SourceSpan.Run = ADocument.PrimaryRun) and
      (LLine.SourceSpan.StartLine = LIndex + 1) and
      (LLine.SourceSpan.EndLine = LIndex + 1),
      AFileName + ' must retain exact provenance for every source line.');
  end;

  for var LNode in ADocument.Nodes do
    Require(LNode.SourceSpan.IsValid and
      (LNode.SourceSpan.Run = ADocument.PrimaryRun),
      AFileName + ' nodes must retain source-run provenance.');

  for var LHeader in ADocument.Headers do
    Require(LHeader.SourceSpan.IsValid and
      (LHeader.SourceSpan.Run = ADocument.PrimaryRun),
      AFileName + ' headers must retain source-run provenance.');
end;

procedure TestTDumpReportRecognition;
begin
  var LFixtureFiles := TDirectory.GetFiles(cGeneratedFixtureDirectory,
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
  cSupportedBinaryNames: array[0..19] of string = ('sample.exe', 'sample.dll',
    'sample.bpl', 'sample.dpl', 'sample.ocx', 'sample.cpl', 'sample.scr',
    'sample.com', 'sample.sys', 'sample.obj', 'sample.lib', 'sample.dcu',
    'sample.elf', 'sample.ar', 'sample.o', 'sample.a', 'sample.so',
    'sample.dylib', 'sample.bundle', 'sample.mach');
begin
  for var LFileName in cSupportedBinaryNames do
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
  Require(TDumpRunner.GetBestOptionText('sample.ar') = '-ns',
    'AR archives must use TDUMP''s default archive dump.');
  Require(TDumpRunner.GetBestOptionText('sample.a') = '-ns',
    'Unix .a archives must not receive ELF-only TDUMP switches.');
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
  cDCUFixtures: array[0..1] of string = ('DCU.System.Win32.invalid-magic.tdump',
    'DCU.Win32.invalid-magic.tdump');
begin
  for var LFixtureName in cDCUFixtures do
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
    var LDocument := LParser.ParseFile(cTurboDumpBannerFixture);
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
    Require((LDocument.RelocationBlocks.Count > 0) and
      (LDocument.RelocationBlocks[0].Entries.Count > 0) and
      LDocument.RelocationBlocks[0].SourceSpan.IsValid,
      'Relocation fixture must group entries under source-backed Fixup Table blocks.');
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
    Require((LDocument.RelocationBlocks.Count > 0) and
      (LDocument.RelocationBlocks[0].Entries.Count > 0),
      'Win64 relocation fixture must group PTR/DIR64 entries by Fixup Table block.');
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
      SameText(LDocument.ObjectRecords[0].RecordKind, 'THEADR') and
      SameText(LDocument.ObjectRecords[0].Name, 'System.pas') and
      ContainsText(LDocument.ObjectRecords[0].RawText, 'THEADR') and
      (LDocument.ObjectRecords[1].Details.Count > 0) and
      SameText(LDocument.ObjectRecords[1].Details[0].Name, 'Translator'),
      Format('OMF object fixture must project typed record-body details ' +
        '(record 1: %s, details: %d, first detail: %s).',
        [LDocument.ObjectRecords[1].RecordKind,
         LDocument.ObjectRecords[1].Details.Count,
         IfThen(LDocument.ObjectRecords[1].Details.Count > 0,
           LDocument.ObjectRecords[1].Details[0].Name, '<none>')]));
  finally
    LDocument.Free;
  end;

  LDocument := ParseGeneratedFixture('OMF.Library.Win32.tdump');
  try
    Require(LDocument.FileKind = dfOMFLibrary,
      'OMF library fixture must retain its library classification.');
    Require(LDocument.ObjectRecords.Count > 20,
      'OMF library fixture must project its record stream.');
    Require((LDocument.LibraryMembers.Count > 0) and
      (LDocument.LibraryMembers[0].Name <> ''),
      'OMF library fixture must project named members.');
    Require(LDocument.OMFLibraryIndex <> nil,
      'OMF library fixture must project its MSLIBR index.');
    Require(LDocument.OMFLibraryIndex.HasFileOffset,
      'OMF library index must retain its file offset.');
    Require(LDocument.OMFLibraryIndex.HasBlockCount,
      'OMF library index must retain its block count.');
    Require(LDocument.OMFLibraryIndex.HasPageSize,
      'OMF library index must retain its page size.');
  finally
    LDocument.Free;
  end;

  LDocument := ParseGeneratedFixture('Mach.Universal.Rad23.tdump');
  try
    Require(LDocument.FileKind = dfMach, 'Mach fixture must be classified as Mach.');
    Require(LDocument.MachArchitectures.Count = 2,
      'Mach fixture must project its two FAT architectures.');
    Require((LDocument.Headers.Count > 0) and
      SameText(LDocument.Headers[0].Name, 'Mach Header') and
      (LDocument.Headers[0].Properties.Count >= 6),
      'Mach fixture must project the Mach header properties.');
    Require(LDocument.MachLoadCommands.Count > 10,
      'Mach fixture must project its load commands.');
    Require((LDocument.MachLoadCommands[0].Sections.Count > 0) and
      (LDocument.MachLoadCommands[0].Sections[0].Properties.Count > 0),
      'Mach fixture must project segment sections and their properties.');
    Require(SameText(LDocument.MachLoadCommands.Last.Name, 'LC_DATA_IN_CODE') and
      (LDocument.MachLoadCommands.Last.Properties.Count = 0),
      'The Mach Symbol Table must not be captured as LC_DATA_IN_CODE data.');
    Require((LDocument.MachSymbols.Count > 1000) and
      (LDocument.MachSymbols[0].Name <> '') and
      LDocument.MachSymbols[0].SourceSpan.IsValid,
      'Mach fixture must project its Symbol Table as typed symbol rows.');
    Require((LDocument.MachDynamicImports.Count > 100) and
      (LDocument.MachIndirectSymbols.Count > 100) and
      LDocument.MachDynamicImports[0].SourceSpan.IsValid and
      LDocument.MachIndirectSymbols[0].SourceSpan.IsValid,
      'Mach fixture must project Dynamic Symbol Table imports and indirect symbols.');
    Require((LDocument.MachDynamicSymbolTableCommand <> nil) and
      SameText(LDocument.MachDynamicSymbolTableCommand.Name, 'LC_DYSYMTAB') and
      (LDocument.MachDynamicSymbolTableCommand.Properties.Count > 0),
      'Mach fixture must retain LC_DYSYMTAB metadata separately from its rows.');
    Require(LDocument.MachLoadCommands[0].SourceSpan.IsValid,
      'Mach load commands must preserve their source spans.');
  finally
    LDocument.Free;
  end;

  LDocument := ParseGeneratedFixture('ELF.Object.Win64.tdump');
  try
    Require((LDocument.FileKind = dfELFObject) and
      (LDocument.Headers.Count = 1) and
      (LDocument.Headers[0].Properties.Count >= 10) and
      (LDocument.Sections.Count = 12) and (LDocument.Symbols.Count = 13) and
      (LDocument.ELFRelocations.Count = 29) and
      LDocument.Symbols[0].SourceSpan.IsValid and
      LDocument.ELFRelocations[0].SourceSpan.IsValid,
      'The real ELF fixture must project its header, sections, symbols, and relocations.');
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
  var LFixtureFiles := TDirectory.GetFiles(cGeneratedFixtureDirectory,
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
  var LFixtureFiles := TDirectory.GetFiles(cGeneratedFixtureDirectory,
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
  var LImportFixtures := TDirectory.GetFiles(cGeneratedFixtureDirectory,
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

  var LExportFixtures := TDirectory.GetFiles(cGeneratedFixtureDirectory,
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
  var LFixtureFiles := TDirectory.GetFiles(cGeneratedFixtureDirectory,
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
  cDebugFixtures: array[0..1] of string = (
    'Package.Win32.debug.tdump', 'Package.Win64.debug.tdump');
begin
  for var LFixtureName in cDebugFixtures do
  begin
    var LDocument := ParseGeneratedFixture(LFixtureName);
    try
      Require((LDocument.DebugInformation <> nil) and
        (LDocument.DebugInformation.SourceModules.Count > 0) and
        (LDocument.DebugInformation.Methods.Count > 0),
        LFixtureName + ' must create generic debug information and methods.');
      var LMethod := LDocument.DebugInformation.Methods[0];
      Require((LMethod.Symbol <> nil) and
        LMethod.SourceSpan.IsValid and
        (LMethod.SourceSpan.Run = LDocument.PrimaryRun),
        LFixtureName +
        ' methods must retain their specialized model and run provenance.');
    finally
      LDocument.Free;
    end;
  end;
end;

procedure TestGeneratedDocumentIntegrity;
begin
  var LFixtureFiles := TDirectory.GetFiles(cGeneratedFixtureDirectory,
    '*.tdump', TSearchOption.soAllDirectories);
  Require(Length(LFixtureFiles) >= 30,
    'The generated TDUMP fixture corpus must remain comprehensive.');

  for var LFixtureFileName in LFixtureFiles do
  begin
    var LFixtureName := ExtractFileName(LFixtureFileName);
    Require(IsTDumpReport(TFile.ReadAllText(LFixtureFileName,
      TEncoding.Default)), LFixtureName + ' must be recognized as TDUMP output.');
    var LDocument := ParseGeneratedFixture(LFixtureName);
    try
      RequireGeneratedDocumentIntegrity(LFixtureName, LDocument);
    finally
      LDocument.Free;
    end;
  end;
end;

procedure TestGeneratedNativeFormatCoverage;
const
  cNativeFixtures: array[0..4] of string = ('OMF.Object.Win32.tdump',
    'OMF.Library.Win32.tdump', 'ELF.Object.Win64.tdump',
    'Mach.Universal.Rad23.tdump', 'Mach.Universal.Rad37.tdump');
  cExpectedKinds: array[0..4] of TDumpFileKind = (dfOMFObject, dfOMFLibrary,
    dfELFObject, dfMach, dfMach);
begin
  for var LIndex := Low(cNativeFixtures) to High(cNativeFixtures) do
  begin
    var LFixtureName := cNativeFixtures[LIndex];
    var LDocument := ParseGeneratedFixture(LFixtureName);
    try
      Require(LDocument.FileKind = cExpectedKinds[LIndex],
        LFixtureName + ' must retain its native format classification.');
      RequireGeneratedDocumentIntegrity(LFixtureName, LDocument);

      case LDocument.FileKind of
        dfOMFObject:
          Require((LDocument.ObjectRecords.Count > 100) and
            LDocument.ObjectRecords[0].SourceSpan.IsValid,
            LFixtureName + ' must project its OMF record stream.');
        dfOMFLibrary:
          Require((LDocument.ObjectRecords.Count > 20) and
            (LDocument.LibraryMembers.Count > 0) and
            LDocument.LibraryMembers[0].SourceSpan.IsValid,
            LFixtureName + ' must project OMF members and their records.');
        dfELFObject:
          Require((LDocument.Headers.Count > 0) and
            (LDocument.Sections.Count > 0) and (LDocument.Symbols.Count > 0) and
            (LDocument.ELFRelocations.Count > 0) and
            LDocument.ELFRelocations[0].SourceSpan.IsValid,
            LFixtureName + ' must project ELF headers, sections, symbols, and relocations.');
        dfMach:
          Require((LDocument.Headers.Count > 0) and
            (LDocument.MachArchitectures.Count > 0) and
            (LDocument.MachLoadCommands.Count > 0) and
            (LDocument.MachSymbols.Count > 0) and
            LDocument.MachSymbols[0].SourceSpan.IsValid,
            LFixtureName + ' must project Mach architectures, commands, and symbols.');
      end;
    finally
      LDocument.Free;
    end;
  end;
end;

procedure TestGeneratedBorlandDebugCoverage;
const
  cDebugFixtures: array[0..2] of string = (
    'PlainVanilla.Delphi.Package.bpl.tdump', 'Package.Win32.debug.tdump',
    'Package.Win64.debug.tdump');
begin
  for var LFixtureName in cDebugFixtures do
  begin
    var LDocument := ParseGeneratedFixture(LFixtureName);
    try
      Require((LDocument.BorlandSubsections.Count > 0) and
        (LDocument.BorlandNames.Count > 0) and (LDocument.Symbols.Count > 0) and
        (LDocument.DebugInformation <> nil) and
        (LDocument.DebugInformation.SourceModules.Count > 0) and
        (LDocument.DebugInformation.Methods.Count > 0),
        LFixtureName + ' must project Borland subsections, names, symbols, and methods.');
      Require(LDocument.DebugInformation.Methods[0].SourceSpan.IsValid and
        (LDocument.DebugInformation.Methods[0].SourceSpan.Run =
          LDocument.PrimaryRun),
        LFixtureName + ' debug methods must retain source-run provenance.');
    finally
      LDocument.Free;
    end;
  end;
end;

procedure TestMachRawSyntaxHints;
begin
  var LDocument := ParseGeneratedFixture('Mach.Universal.Rad37.tdump');
  try
    Require(LDocument.MachSymbols.Count > 1000,
      'The Mach Rad37 fixture must provide Symbol Table rows for raw rendering.');
    for var LSymbol in LDocument.MachSymbols do
    begin
      Require(LSymbol.SourceSpan.SyntaxHint = rshMachLinker,
        'Every Mach Symbol Table row must request Mach linker syntax.');
      Require(LDocument.Lines[LSymbol.StartLine - 1].SourceSpan.SyntaxHint =
        rshMachLinker,
        'Each Mach Symbol Table source line must retain its raw syntax hint.');
    end;
    Require(LDocument.MachDynamicImports.Count > 1000,
      'The Mach Rad37 fixture must provide dynamic-import rows for raw rendering.');
    for var LSymbol in LDocument.MachDynamicImports do
    begin
      Require(LSymbol.SourceSpan.SyntaxHint = rshMachLinker,
        'Every Mach dynamic-import row must request Mach linker syntax.');
      Require(LDocument.Lines[LSymbol.StartLine - 1].SourceSpan.SyntaxHint =
        rshMachLinker,
        'Each Mach dynamic-import source line must retain its raw syntax hint.');
    end;
    Require(LDocument.MachIndirectSymbols.Count > 100,
      'The Mach Rad37 fixture must provide indirect-symbol rows for raw rendering.');
    for var LSymbol in LDocument.MachIndirectSymbols do
    begin
      Require(LSymbol.SourceSpan.SyntaxHint = rshMachLinker,
        'Every Mach indirect-symbol row must request Mach linker syntax.');
      Require(LDocument.Lines[LSymbol.StartLine - 1].SourceSpan.SyntaxHint =
        rshMachLinker,
        'Each Mach indirect-symbol source line must retain its raw syntax hint.');
    end;
  finally
    LDocument.Free;
  end;
end;

procedure TestOMFRawSyntaxHints;
  function SyntaxHintForRecordLine(ARecord: TDumpObjectRecord;
    ALineNumber: Integer): TDumpRawSyntaxHint;
  begin
    Result := rshOMFRecord;
    for var LDataRow in ARecord.HexDataRows do
      if LDataRow.StartLine = ALineNumber then
        Exit(rshOMFLEData);
  end;
begin
  var LDocument := ParseGeneratedFixture('OMF.Object.Win32.tdump');
  try
    Require(LDocument.ObjectRecords.Count > 1000,
      'The OMF fixture must provide record rows for raw rendering.');
    for var LRecord in LDocument.ObjectRecords do
    begin
      Require(LRecord.SourceSpan.SyntaxHint = rshOMFRecord,
        'Every OMF record must request OMF record syntax.');
      for var LLineNumber := LRecord.StartLine to LRecord.EndLine do
        Require(LDocument.Lines[LLineNumber - 1].SourceSpan.SyntaxHint =
          SyntaxHintForRecordLine(LRecord, LLineNumber),
          'Every OMF record source line must retain its raw syntax hint.');
    end;
  finally
    LDocument.Free;
  end;
end;

procedure TestOMFFixUpAndLEDataProjection;
begin
  var LDocument := ParseGeneratedFixture('OMF.Object.Win32.tdump');
  try
    var LFixUpRecord: TDumpObjectRecord := nil;
    var LLEDataRecord: TDumpObjectRecord := nil;
    for var LRecord in LDocument.ObjectRecords do
    begin
      if (LFixUpRecord = nil) and SameText(LRecord.RawOffset, '00FE6E') then
        LFixUpRecord := LRecord;
      if (LLEDataRecord = nil) and SameText(LRecord.RawOffset, '015638') then
        LLEDataRecord := LRecord;
    end;
    Require((LFixUpRecord <> nil) and (LFixUpRecord.FixUps.Count = 2) and
      (LFixUpRecord.FixUps[0].RawFixUp = '024') and
      SameText(LFixUpRecord.FixUps[0].Mode, 'Seg') and
      SameText(LFixUpRecord.FixUps[0].Location, 'Offset32') and
      SameText(LFixUpRecord.FixUps[0].Frame, 'TARGET') and
      ContainsText(LFixUpRecord.FixUps[0].Target,
        'System::DefaultRandom32()'),
      'FIXU32 rows must project typed FixUp, mode, location, frame, and target fields.');
    Require((LLEDataRecord <> nil) and (LLEDataRecord.HexDataRows.Count = 11) and
      (LLEDataRecord.HexDataRows[0].RawOffset = '0000') and
      ContainsText(LLEDataRecord.HexDataRows[0].Bytes,
        '04 00 00 00 0E 0F 54 4D') and
      (LLEDataRecord.HexDataRows[0].ASCII = '......TMonitorSu') and
      (LDocument.Lines[LLEDataRecord.HexDataRows[0].StartLine - 1].
        SourceSpan.SyntaxHint = rshOMFLEData),
      'LEDATA rows must retain their offset, hexadecimal bytes, and ASCII columns.');
  finally
    LDocument.Free;
  end;
end;

procedure TestMachReportSections;
var
  LDocument: TDumpDocument;
  procedure RequireMachSymbolSyntaxHints(ASection: TDumpMachReportSection;
    const ASectionCaption: string);
  begin
    Require(ASection <> nil,
      ASectionCaption + ' must exist before its raw syntax hints are checked.');
    for var LLineIndex := ASection.ItemStartLine to ASection.EndLine do
      Require(LDocument.Lines[LLineIndex - 1].SourceSpan.SyntaxHint =
        rshMachLinker,
        ASectionCaption + ' must keep its semantic linker-name syntax in Raw Output.');
  end;
begin
  LDocument := ParseGeneratedFixture('Mach.Universal.Rad37.tdump');
  try
    Require((LDocument.MachRebaseInfo <> nil) and
      (LDocument.MachRebaseInfo.StartLine = 5216) and
      (LDocument.MachRebaseInfo.EndLine = 6855) and
      (LDocument.MachRebaseInfo.ItemCount = 1639) and
      LDocument.MachRebaseInfo.SourceSpan.IsValid,
      'Mach Rebase Info must preserve its complete source-backed opcode range.');
    Require((LDocument.MachBindingInfo <> nil) and
      (LDocument.MachBindingInfo.StartLine = 6857) and
      (LDocument.MachBindingInfo.EndLine = 15045) and
      (LDocument.MachBindingInfo.ItemCount > 0) and
      LDocument.MachBindingInfo.SourceSpan.IsValid and
      (LDocument.MachWeakBindingInfo <> nil) and
      (LDocument.MachWeakBindingInfo.StartLine = 15047) and
      (LDocument.MachWeakBindingInfo.ItemCount > 0) and
      LDocument.MachWeakBindingInfo.SourceSpan.IsValid and
      (LDocument.MachLazyBindingInfo <> nil) and
      (LDocument.MachLazyBindingInfo.StartLine = 27335) and
      (LDocument.MachLazyBindingInfo.ItemCount > 0) and
      LDocument.MachLazyBindingInfo.SourceSpan.IsValid and
      (LDocument.MachExports <> nil) and
      (LDocument.MachExports.StartLine = 27468) and
      (LDocument.MachExports.ItemCount > 0) and
      LDocument.MachExports.SourceSpan.IsValid,
      'Mach binding and export blocks must each retain a source-backed structure.');
    Require((LDocument.MachDynamicSymbolTable <> nil) and
      (LDocument.MachDynamicSymbolTable.StartLine = 2734) and
      (LDocument.MachDynamicSymbolTable.EndLine = 5214) and
      LDocument.MachDynamicSymbolTable.SourceSpan.IsValid,
      'Mach Dynamic Symbol Table must retain its TDUMP report block, separately from LC_DYSYMTAB.');
    RequireMachSymbolSyntaxHints(LDocument.MachDynamicSymbolTable,
      'Mach Dynamic Symbol Table');
    RequireMachSymbolSyntaxHints(LDocument.MachBindingInfo,
      'Mach Binding Info');
    RequireMachSymbolSyntaxHints(LDocument.MachWeakBindingInfo,
      'Mach Weak Binding Info');
    RequireMachSymbolSyntaxHints(LDocument.MachLazyBindingInfo,
      'Mach Lazy Binding Info');
    RequireMachSymbolSyntaxHints(LDocument.MachExports,
      'Mach Exports');
    Require((LDocument.MachResources <> nil) and
      (LDocument.MachResources.StartLine = 28513) and
      (LDocument.MachResources.ItemCount = 4) and
      LDocument.MachResources.SourceSpan.IsValid,
      'Mach Resources must retain its property block and source provenance.');
    Require((LDocument.MachRawSymbols <> nil) and
      (LDocument.MachRawSymbols.StartLine = 28519) and
      (LDocument.MachRawSymbols.ItemCount > 68000) and
      LDocument.MachRawSymbols.SourceSpan.IsValid,
      'Mach Raw Symbols must remain a source-backed section instead of a lost report tail.');
    RequireMachSymbolSyntaxHints(LDocument.MachRawSymbols, 'Mach Raw Symbols');
  finally
    LDocument.Free;
  end;
end;

procedure TestLargeReportStructuredProjection;
begin
  Require(TFile.Exists(cLargeVCLFixture),
    'The large VCL regression fixture must be available.');
  var LParser := TDumpParser.Create;
  try
    var LDocument := LParser.ParseFile(cLargeVCLFixture);
    try
      Require(LDocument.TextSource <> nil,
        'File parsing must retain an indexed text source.');
      Require(LDocument.Lines.Count = LDocument.TextSource.LineCount,
        'The line catalog must be a view over the indexed source.');
      Require(LDocument.Lines.Count = 1052806,
        'The large fixture line count must remain stable.');
      Require(LDocument.BorlandSubsections.Count = 312,
        'The large fixture must retain every Borland subsection.');
      Require(LDocument.BorlandLazyRecords,
        'The large fixture must use the source-backed Borland projection.');
      Require((LDocument.LazyAlignSymbolSections.Count > 0) and
        (LDocument.LazyAlignSymbolSections[0].Records.Count > 0),
        'Large reports must retain source-backed sstAlignSym record indexes.');
      Require((LDocument.LazyGlobalSymbolSections.Count > 0) and
        (LDocument.LazyGlobalSymbolSections[0].Records.Count > 0),
        'Large reports must retain source-backed sstGlobalSym record indexes.');
      Require((LDocument.LazyGlobalTypeSections.Count > 0) and
        (LDocument.LazyGlobalTypeSections[0].Records.Count > 0),
        'Large reports must retain source-backed sstGlobalTypes record indexes.');
      Require(LDocument.SourceModules.Count > 0,
        'Large reports must retain sstSrcModule projections for source-file navigation.');
      var LSourceFileCount := 0;
      for var LSourceModule in LDocument.SourceModules do
        Inc(LSourceFileCount, LSourceModule.SourceFiles.Count);
      Require(LSourceFileCount > 0,
        'Large sstSrcModule projections must retain their source-file children.');
      Require((LDocument.SymbolModules.Count = 0) and
        (LDocument.BorlandNames.Count = 0) and
        (LDocument.GlobalSymbolSections.Count = 0) and
        (LDocument.GlobalTypeSections.Count = 0),
        'The lazy projection must not retain full Borland subsection models.');

      var LHasModuleBody := False;
      var LHasModuleSegmentFlags := False;
      var LHasGlobalSymbolBody := False;
      var LHasGlobalTypeBody := False;
      var LHasNamesBody := False;
      for var LSubsection in LDocument.BorlandSubsections do
      begin
        if LSubsection.StartLine >= LDocument.TextSource.LineCount then
          Continue;
        var LFirstBodyLine := LDocument.TextSource[LSubsection.StartLine];
        if SameText(LSubsection.SubsectionType, 'sstModule') then
        begin
          LHasModuleBody := LHasModuleBody or
            ContainsText(LFirstBodyLine, 'OvlNum:');
          for var LLineNumber := LSubsection.StartLine + 1 to
            LSubsection.EndLine do
            if ContainsText(LDocument.TextSource[LLineNumber - 1], 'Flags:') then
            begin
              LHasModuleSegmentFlags := True;
              Break;
            end;
        end
        else if SameText(LSubsection.SubsectionType, 'sstGlobalSym') then
          LHasGlobalSymbolBody := LHasGlobalSymbolBody or
            ContainsText(LFirstBodyLine, 'cbSymbols:')
        else if SameText(LSubsection.SubsectionType, 'sstGlobalTypes') then
          LHasGlobalTypeBody := LHasGlobalTypeBody or
            ContainsText(LFirstBodyLine, 'Number of types:')
        else if SameText(LSubsection.SubsectionType, 'sstNames') then
          LHasNamesBody := LHasNamesBody or (Pos(':', LFirstBodyLine) > 0);
      end;
      Require(LHasModuleBody and LHasModuleSegmentFlags and
        LHasGlobalSymbolBody and LHasGlobalTypeBody and LHasNamesBody,
        'Every lazy Borland detail section must retain an addressable source body.');
    finally
      LDocument.Free;
    end;
  finally
    LParser.Free;
  end;
end;

procedure TestDelayedLoadImports;
begin
  var LDocument := ParseGeneratedFixture('Dll.Win32.imports.tdump');
  try
    Require((LDocument.Imports.Count = 4) and
      SameText(LDocument.Imports[3].Name, 'advapi32.dll') and
      (LDocument.Imports[3].Entries.Count = 3),
      'Regular imports must end with the three advapi32 methods, before delayed imports.');
    Require(LDocument.DelayedImportTable <> nil,
      'The Delayed Load Import Table must have its own typed projection.');
    Require((LDocument.DelayedImportTable.Modules.Count = 3) and
      SameText(LDocument.DelayedImportTable.Modules[0].Name, 'kernel32.dll') and
      SameText(LDocument.DelayedImportTable.Modules[1].Name, 'user32.dll') and
      SameText(LDocument.DelayedImportTable.Modules[2].Name, 'kernel32.dll'),
      'Delayed import descriptors must remain distinct and in report order.');
    Require((LDocument.DelayedImportTable.Modules[0].Properties.Count = 7) and
      SameText(LDocument.DelayedImportTable.Modules[0].Properties[0].Name,
      'Attributes') and
      (LDocument.DelayedImportTable.Modules[2].Properties.Count = 7),
      'Each delayed import descriptor must retain its seven metadata properties.');
    for var LProperty in LDocument.DelayedImportTable.Modules[0].Properties do
      Require(LDocument.Lines[LProperty.StartLine - 1].SourceSpan.SyntaxHint =
        rshPEImportProperty,
        'Delayed import property rows must retain PE address syntax for RAW output.');
    Require(LDocument.DelayedImportTable.SourceSpan.IsValid and
      (LDocument.DelayedImportTable.SourceSpan.Run = LDocument.PrimaryRun) and
      LDocument.DelayedImportTable.Modules[0].SourceSpan.IsValid and
      (LDocument.DelayedImportTable.Modules[0].Entries.Count = 1),
      'Delayed imports must retain provenance and their descriptor entries.');
    Require((LDocument.UnsupportedStructures.Count = 0) and
      (LDocument.Diagnostics.Count = 0),
      'The generated delayed-load import report must parse without fallback warnings.');
  finally
    LDocument.Free;
  end;
end;

procedure TestRelationGraph;
begin
  var LParser := TDumpParser.Create;
  try
    var LDocument := LParser.ParseFile(cTurboDumpBannerFixture);
    try
      var LBuilder := TDumpRelationBuilder.Create;
      try
        var LGraph := LBuilder.Build(LDocument);
        try
          Require((LGraph.SourceProcedureRelations.Count = 32) and
            (LGraph.ProcedureReferenceRelations.Count = 11) and
            (LGraph.ProcedureTypeRelations.Count = 35) and
            (LGraph.ExportTargetRelations.Count = 9) and
            (LGraph.ExportAliasGroups.Count = 3) and
            (LGraph.ProcedureScopeRelations.Count = 35) and
            (LGraph.DataDefinitionRelations.Count = 6) and
            (LGraph.ResourceLocationRelations.Count = 4),
            'The package fixture must retain its complete relation graph.');

          var LDelayProcedure: TDumpAlignSymbolRecord := nil;
          for var LRelation in LGraph.SourceProcedureRelations do
            if EndsText('delayLoadHelper2$qqrv',
              LRelation.ProcedureRecord.ResolvedName) then
            begin
              LDelayProcedure := LRelation.ProcedureRecord;
              Require(EndsText('delayhlp.cpp', LRelation.SourceFile.Name) and
                (LRelation.FirstSourceLine = 223) and
                (LRelation.LastSourceLine = 420) and
                (LRelation.StartLocation.RVA = $1758) and
                (LRelation.StartLocation.VirtualAddress = $401758) and
                (LRelation.StartLocation.FileOffset = $B58),
                'delayLoadHelper2 must retain its source and PE coordinates.');
              Break;
            end;
          Require(LDelayProcedure <> nil,
            'delayLoadHelper2 must be linked to its source range.');

          var LDelayTypeFound := False;
          var LDelayScopeFound := False;
          for var LTypeRelation in LGraph.ProcedureTypeRelations do
            if LTypeRelation.ProcedureRecord = LDelayProcedure then
            begin
              LDelayTypeFound := (LTypeRelation.TypeIndex = $1034) and
                (LTypeRelation.TypeRecord <> nil);
              Break;
            end;
          for var LScopeRelation in LGraph.ProcedureScopeRelations do
            if LScopeRelation.ProcedureRecord = LDelayProcedure then
            begin
              LDelayScopeFound := (LScopeRelation.EndRecord <> nil) and
                (LScopeRelation.EndRecord.Kind = bsrkEnd);
              Break;
            end;
          Require(LDelayTypeFound and LDelayScopeFound,
            'delayLoadHelper2 must retain its type and lexical-scope links.');

          var LProcedureExportCount := 0;
          var LReferenceExportCount := 0;
          for var LRelation in LGraph.ExportTargetRelations do
          begin
            Require(LRelation.Location.HasRVA,
              'Every package export must resolve to PE coordinates.');
            if LRelation.ProcedureRecord <> nil then
              Inc(LProcedureExportCount);
            if LRelation.ProcedureReference <> nil then
              Inc(LReferenceExportCount);
          end;
          Require((LProcedureExportCount = 7) and (LReferenceExportCount = 1),
            'Package exports must preserve direct and reference-only targets.');

          for var LRelation in LGraph.ResourceLocationRelations do
            Require((LRelation.Location.Section <> nil) and
              SameText(LRelation.Location.Section.Name, '.rsrc') and
              LRelation.Location.HasFileOffset,
              'Every package resource leaf must resolve to raw .rsrc bytes.');

          var LBssDataFound := False;
          for var LRelation in LGraph.DataDefinitionRelations do
            if EndsText('ModuleIsLib', LRelation.DefinitionRecord.ResolvedName) then
            begin
              LBssDataFound := (LRelation.Location.Section <> nil) and
                SameText(LRelation.Location.Section.Name, '.bss') and
                LRelation.Location.HasRVA and
                not LRelation.Location.HasFileOffset;
              Break;
            end;
          Require(LBssDataFound,
            'BSS global data must resolve virtually without a raw-file offset.');
        finally
          LGraph.Free;
        end;
      finally
        LBuilder.Free;
      end;
    finally
      LDocument.Free;
    end;
  finally
    LParser.Free;
  end;
end;

procedure TestARArchiveProjection;
const
  cARArchiveText =
    'Turbo Dump  Version 6.6.2.0 Copyright (c) Embarcadero Technologies, Inc.' +
    sLineBreak + 'Display of File sqlite.a' + sLineBreak + sLineBreak +
    'Ar 32-bit unix archive file' + sLineBreak + sLineBreak +
    '------------ Member Headers -----------' + sLineBreak +
    'ndx   member       offs      size      mode      uid   gid   time' +
    sLineBreak +
    '0     sqlite3.o    153A      2798      0         0     0     Sep 12 13:41:00 2012' +
    sLineBreak + sLineBreak +
    '------------ Symbols ----------- (2 entries)' + sLineBreak +
    'ndx   name' + sLineBreak +
    '---------------------------------------------------' + sLineBreak +
    'member #0    sqlite3.o    offs=153A      size=2798' + sLineBreak +
    '---------------------------------------------------' + sLineBreak +
    '0     sqlite3_aggregate_context' + sLineBreak +
    '1     sqlite3_aggregate_count';
begin
  Require(IsTDumpReport(cARArchiveText),
    'A TDUMP AR archive report must be recognized as report text.');
  var LParser := TDumpParser.Create;
  try
    var LDocument := LParser.ParseText(cARArchiveText, 'sqlite.a');
    try
      Require((LDocument.FileKind = dfARArchive) and
        (LDocument.ArchiveMembers.Count = 1) and
        (LDocument.ArchiveSymbols.Count = 2),
        'An AR archive report must project member headers and symbols.');
      Require((LDocument.ArchiveMembers[0].Name = 'sqlite3.o') and
        LDocument.ArchiveMembers[0].HasOffset and
        (LDocument.ArchiveMembers[0].Offset = $153A) and
        LDocument.ArchiveMembers[0].HasSize and
        (LDocument.ArchiveMembers[0].Size = $2798),
        'AR member metadata must preserve hexadecimal offset and size values.');
      Require((LDocument.ArchiveSymbols[0].Name =
        'sqlite3_aggregate_context') and
        (LDocument.ArchiveSymbols[0].MemberName = 'sqlite3.o') and
        LDocument.ArchiveSymbols[0].SourceSpan.IsValid and
        (LDocument.Diagnostics.Count = 0) and
        (LDocument.UnsupportedStructures.Count = 0),
        'AR symbols must retain their member association and source provenance.');
    finally
      LDocument.Free;
    end;
  finally
    LParser.Free;
  end;
end;

procedure TestELFProgramHeadersProjection;
begin
  var LDocument := ParseGeneratedFixture(
    'ELF.SharedLibrary.InterBase15.program-headers.tdump');
  try
    var LDynamicRelocationCount := 0;
    var LProcedureLinkageRelocationCount := 0;
    var LHasRelocationSyntaxHint := False;
    for var LRelocation in LDocument.ELFRelocations do
      if SameText(LRelocation.SectionName, '.rela.dyn') then
        Inc(LDynamicRelocationCount)
      else if SameText(LRelocation.SectionName, '.rela.plt') then
      begin
        Inc(LProcedureLinkageRelocationCount);
        LHasRelocationSyntaxHint := LHasRelocationSyntaxHint or
          (LRelocation.SourceSpan.SyntaxHint = rshELFRelocation);
      end;
    Require((LDocument.FileKind = dfELFObject) and
      (LDocument.ELFProgramHeaders.Count = 7) and
      SameText(LDocument.ELFProgramHeaders[0].HeaderType, 'LOAD') and
      LDocument.ELFProgramHeaders[0].SourceSpan.IsValid and
      (LDocument.ELFDynamicEntries.Count = 31) and
      SameText(LDocument.ELFDynamicEntries[0].Tag, 'NEEDED') and
      LDocument.ELFDynamicEntries[0].SourceSpan.IsValid and
      (LDynamicRelocationCount = 27667) and
      (LProcedureLinkageRelocationCount = 5788) and
      LHasRelocationSyntaxHint and
      (LDocument.Diagnostics.Count = 1) and
      (LDocument.Diagnostics[0].Severity = dsWarning) and
      (LDocument.Diagnostics[0].LineNumber = 82) and
      (LDocument.Diagnostics[0].Message =
        'target section index for relocations (sh_info) is 0') and
      (LDocument.Diagnostics[0].RawLine =
        'Warning: target section index for relocations (sh_info) is 0'),
      'The real InterBase ELF shared-library fixture must retain program headers, dynamic entries, and relocation-table sections.');
  finally
    LDocument.Free;
  end;
end;

procedure TParserFixture.ReportRecognition;
begin
  TestTDumpReportRecognition;
end;

procedure TParserFixture.BinaryFileRecognition;
begin
  TestTDumpBinaryFileRecognition;
end;

procedure TParserFixture.RunnerOptionProfiles;
begin
  TestRunnerOptionProfiles;
end;

procedure TParserFixture.TypedRunnerOptions;
begin
  TestTypedRunnerOptions;
end;

procedure TParserFixture.DelphiUnitDiagnostics;
begin
  TestDelphiUnitDiagnostics;
end;

procedure TParserFixture.ShortToolDiagnosticCapture;
begin
  TestShortToolDiagnosticCapture;
end;

procedure TParserFixture.RawMachHexDump;
begin
  TestRawMachHexDump;
end;

procedure TParserFixture.TurboDumpMetadata;
begin
  TestTurboDumpMetadata;
end;

procedure TParserFixture.PECoreProjection;
begin
  TestPECoreProjection;
end;

procedure TParserFixture.SourceSpanProvenance;
begin
  TestSourceSpanProvenance;
end;

procedure TParserFixture.CompactImports;
begin
  TestCompactImports;
end;

procedure TParserFixture.DelayedLoadImports;
begin
  TestDelayedLoadImports;
end;

procedure TParserFixture.CompactExports;
begin
  TestCompactExports;
end;

procedure TParserFixture.Relocations;
begin
  TestRelocations;
end;

procedure TParserFixture.UnknownFallback;
begin
  TestUnknownFallback;
end;

procedure TParserFixture.GeneratedFixtureCoverage;
begin
  TestGeneratedFixtureCoverage;
end;

procedure TParserFixture.GeneratedPECoreProjection;
begin
  TestGeneratedPECoreProjection;
end;

procedure TParserFixture.GeneratedCompactProjections;
begin
  TestGeneratedCompactProjections;
end;

procedure TParserFixture.InvalidFixtureFallback;
begin
  TestInvalidFixtureFallback;
end;

procedure TParserFixture.DebugInformationProjection;
begin
  TestDebugInformationProjection;
end;

procedure TParserFixture.P2ProjectionsAndMerge;
begin
  TestP2ProjectionsAndMerge;
end;

procedure TParserFixture.MachRawSyntaxHints;
begin
  TestMachRawSyntaxHints;
end;

procedure TParserFixture.OMFRawSyntaxHints;
begin
  TestOMFRawSyntaxHints;
end;

procedure TParserFixture.OMFFixUpAndLEDataProjection;
begin
  TestOMFFixUpAndLEDataProjection;
end;

procedure TParserFixture.MachReportSections;
begin
  TestMachReportSections;
end;

procedure TParserFixture.GeneratedDocumentIntegrity;
begin
  TestGeneratedDocumentIntegrity;
end;

procedure TParserFixture.GeneratedNativeFormatCoverage;
begin
  TestGeneratedNativeFormatCoverage;
end;

procedure TParserFixture.GeneratedBorlandDebugCoverage;
begin
  TestGeneratedBorlandDebugCoverage;
end;

procedure TParserFixture.RelationGraph;
begin
  TestRelationGraph;
end;

procedure TParserFixture.ARArchiveProjection;
begin
  TestARArchiveProjection;
end;

procedure TParserFixture.ELFProgramHeadersProjection;
begin
  TestELFProgramHeadersProjection;
end;

procedure TParserFixture.LargeReportStructuredProjection;
begin
  TestLargeReportStructuredProjection;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  TDUnitX.RegisterTestFixture(TParserFixture);
  var LRunner := TDUnitX.CreateRunner;
  LRunner.UseRTTI := False;
  LRunner.FailsOnNoAsserts := True;
  ForceDirectories(cTestResultsDirectory);
  LRunner.AddLogger(TDUnitXXMLNUnitFileLogger.Create(cTestResultsFile));
  var LResults := LRunner.Execute;
  if not LResults.AllPassed then
    ExitCode := EXIT_ERRORS;
end.
