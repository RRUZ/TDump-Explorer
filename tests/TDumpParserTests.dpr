program TDumpParserTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  TDump.Explorer.Parser in '..\source\parser\TDump.Explorer.Parser.pas';

const
  CGeneratedFixtureDirectory = 'C:\dev\TDump-Explorer\fixtures\generated';

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

procedure TestPECoreProjection;
begin
  var LDocument := ParseGeneratedFixture('Package.Win32.pe-core.tdump');
  try
    Require(LDocument.Headers.Count = 2, 'PE core must project both headers.');
    Require(LDocument.Sections.Count = 10, 'PE core must project ten sections.');
    Require(LDocument.Imports.Count = 2, 'PE core must project two import modules.');
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

procedure TestTDumpDialectAliases;
const
  CTDump32Text =
    'Turbo Dump Version 8.0' + sLineBreak +
    'Display of File sample32.exe' + sLineBreak + sLineBreak +
    'Old Executable Header' + sLineBreak +
    'DOS File Size: 0040h' + sLineBreak + sLineBreak +
    'Portable Executable (PE) File' + sLineBreak +
    'CPU type: I386' + sLineBreak +
    'Name                   RVA       Size' + sLineBreak +
    'Exports                00002000  00000020' + sLineBreak +
    'Imports                00003000  00000040' + sLineBreak + sLineBreak +
    'Object table:' + sLineBreak +
    '#   Name              VirtSize    RVA     PhysSize  Phys off  Flags' + sLineBreak +
    '01  .text             00001000  00001000  00000200  00000400  60000020 [CER]' + sLineBreak +
    '02  .data             00000200  00003000  00000200  00000600  C0000040 [IRW]' + sLineBreak +
    'Section: Import';
  CTDump64Text =
    'TDUMP64 Version 8.0' + sLineBreak +
    'Display of File sample64.exe' + sLineBreak + sLineBreak +
    'MZ Header' + sLineBreak +
    'DOS File Size: 0040h' + sLineBreak + sLineBreak +
    'PE Header' + sLineBreak +
    'CPU type: AMD64' + sLineBreak +
    'Directory Name RVA Size' + sLineBreak +
    'Exports 00002000 00000020' + sLineBreak +
    'Imports 00003000 00000040' + sLineBreak + sLineBreak +
    'Section Headers' + sLineBreak +
    'Index Name Virtual Size RVA Raw Size Raw Offset Characteristics' + sLineBreak +
    '01 .text 00001000 00001000 00000200 00000400 60000020 [CER]' + sLineBreak +
    '02 .data 00000200 00003000 00000200 00000600 C0000040 [IRW]' + sLineBreak +
    'Section: Import';
begin
  var LParser := TDumpParser.Create;
  try
    var LDump32 := LParser.ParseText(CTDump32Text);
    try
      Require(LDump32.ToolKind = tkTDump32,
        'Turbo Dump banner must identify the TDUMP dialect.');
      Require(LDump32.ToolVersion = '8.0',
        'TDUMP banner version must be retained.');
      Require((LDump32.Headers.Count = 2) and
        (LDump32.DataDirectories.Count = 2) and (LDump32.Sections.Count = 2),
        'Canonical TDUMP P0 headings must project both headers, directories, and sections.');
    finally
      LDump32.Free;
    end;

    var LDump64 := LParser.ParseText(CTDump64Text);
    try
      Require(LDump64.ToolKind = tkTDump64,
        'TDUMP64 banner must identify the TDUMP64 dialect.');
      Require(LDump64.ToolVersion = '8.0',
        'TDUMP64 banner version must be retained.');
      Require((LDump64.Headers.Count = 2) and
        (LDump64.DataDirectories.Count = 2) and (LDump64.Sections.Count = 2),
        'TDUMP64 aliases must project the same P0 structure as TDUMP.');
      Require(SameText(LDump64.Architecture, 'AMD64'),
        'Target architecture must remain independent from tool dialect.');
    finally
      LDump64.Free;
    end;
  finally
    LParser.Free;
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

  var LParser := TDumpParser.Create;
  try
    LDocument := LParser.ParseText('ELF Header' + sLineBreak +
      'Class: ELF64' + sLineBreak + 'Machine: AArch64');
    try
      Require((LDocument.FileKind = dfELFObject) and
        (LDocument.Headers.Count = 1) and
        (LDocument.Headers[0].Properties.Count = 2),
        'An explicit ELF header must create a typed minimal ELF projection.');
    finally
      LDocument.Free;
    end;

    var LFirst := LParser.ParseText('TDUMP Version 1' + sLineBreak +
      'Old Executable Header', 'same-input.tdump');
    var LSecond := LParser.ParseText('TDUMP64 Version 1' + sLineBreak +
      'MZ Header', 'same-input.tdump');
    try
      var LMerge := LFirst.MergeWith(LSecond);
      try
        Require((LMerge.Documents.Count = 2) and (LMerge.Runs.Count = 2) and
          (LMerge.Conflicts.Count > 0),
          'A merge must retain both runs and report conflicting same-source text.');
      finally
        LMerge.Free;
      end;
    finally
      LSecond.Free;
      LFirst.Free;
    end;
  finally
    LParser.Free;
  end;
end;

procedure TestUnknownBlockFallback;
begin
  var LParser := TDumpParser.Create;
  try
    var LDocument := LParser.ParseText('Section: Future Data' + sLineBreak +
      '  Future row' + sLineBreak + 'Section:             Import');
    try
      Require(LDocument.UnsupportedStructures.Count = 1,
        'An unknown section inside a recognized report must produce one fallback block.');
      var LUnknownNode := LDocument.UnsupportedStructures[0].Node;
      Require((LUnknownNode.StartLine = 1) and (LUnknownNode.EndLine = 2),
        'Fallback block must cover only the unknown section lines.');
      Require(Pos('Future row', LUnknownNode.RawText) > 0,
        'Fallback block must preserve its own raw text.');
      Require(LDocument.Imports.Count = 0,
        'The following known empty import section must remain independently recognized.');
    finally
      LDocument.Free;
    end;
  finally
    LParser.Free;
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
          Require(LDocument.UnsupportedStructures.Count > 0,
            ExtractFileName(LFixtureFileName) +
            ' must explicitly preserve invalid input as unsupported.');
          Require(LDocument.Nodes.Count > 1,
            ExtractFileName(LFixtureFileName) +
            ' must create bounded fallback nodes for invalid input.');
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

procedure TestOrdinalOnlyAndMalformedCases;
begin
  var LParser := TDumpParser.Create;
  try
    var LDocument := LParser.ParseText('EXPORT ord:0002');
    try
      Require((LDocument.ExportList.Count = 1) and
        LDocument.ExportList[0].HasOrdinal and
        (LDocument.ExportList[0].Name = '') and
        (LDocument.Diagnostics.Count = 0),
        'An ordinal-only compact export must remain a valid export.');
    finally
      LDocument.Free;
    end;

    LDocument := LParser.ParseText('IMPORT: malformed');
    try
      Require((LDocument.Imports.Count = 0) and
        (LDocument.Diagnostics.Count = 1) and
        (LDocument.UnsupportedStructures.Count = 1),
        'A malformed compact import must produce one recoverable finding.');
    finally
      LDocument.Free;
    end;

    LDocument := LParser.ParseText('TDUMP64 Version 8.0' + sLineBreak +
      'PE Header' + sLineBreak + 'CPU type: AMD64');
    try
      Require((LDocument.ToolKind = tkTDump64) and
        (LDocument.Headers.Count = 1) and
        SameText(LDocument.Architecture, 'AMD64'),
        'A truncated TDUMP64 PE header must retain its available P0 projection.');
    finally
      LDocument.Free;
    end;
  finally
    LParser.Free;
  end;
end;

procedure TestAmbiguousNumberStaysRaw;
begin
  var LParser := TDumpParser.Create;
  try
    var LDocument := LParser.ParseText('Old Executable Header' + sLineBreak +
      'Counter: 10');
    try
      Require(LDocument.Headers.Count = 1, 'Synthetic header must be recognized.');
      Require(LDocument.Headers[0].Properties.Count = 1,
        'Synthetic property must be retained.');
      Require(not LDocument.Headers[0].Properties[0].HasUIntValue,
        'Ambiguous bare number must remain raw.');
    finally
      LDocument.Free;
    end;
  finally
    LParser.Free;
  end;
end;

begin
  try
    TestPECoreProjection;
    TestSourceSpanProvenance;
    TestTDumpDialectAliases;
    TestCompactImports;
    TestCompactExports;
    TestRelocations;
    TestUnknownFallback;
    TestUnknownBlockFallback;
    TestGeneratedFixtureCoverage;
    TestGeneratedPECoreProjection;
    TestGeneratedCompactProjections;
    TestInvalidFixtureFallback;
    TestDebugInformationProjection;
    TestOrdinalOnlyAndMalformedCases;
    TestP2ProjectionsAndMerge;
    TestAmbiguousNumberStaysRaw;
    Writeln('TDump parser assertions passed.');
  except
    on LException: Exception do
    begin
      Writeln(ErrOutput, LException.Message);
      ExitCode := 1;
    end;
  end;
end.
