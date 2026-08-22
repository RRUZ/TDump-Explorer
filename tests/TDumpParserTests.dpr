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
          if LDocument.FileKind = dfCOFFObject then
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
