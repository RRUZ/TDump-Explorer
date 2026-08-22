program TDumpParserConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TDump.Explorer.Parser in '..\source\parser\TDump.Explorer.parser.pas',
  TDump.Explorer.Utils in '..\source\parser\TDump.Explorer.Utils.pas';

procedure DumpHeader(const AHeader: TDumpHeader);
begin
  Writeln('Header: ', AHeader.Name);
  Writeln('Lines: ', AHeader.StartLine, '..', AHeader.EndLine);
  Writeln('Properties: ', AHeader.Properties.Count);

  for var LIndex := 0 to AHeader.Properties.Count - 1 do
  begin
    var LProperty := AHeader.Properties[LIndex];
    Write('  ', LProperty.StartLine:4, '  ', LProperty.Name, ' = ', LProperty.RawValue,
      '  [', ValueKindName(LProperty.ValueKind));
    if LProperty.HasUIntValue then
      Write(', UInt=', LProperty.UIntValue);
    Writeln(']');
  end;
  Writeln;
end;

procedure DumpDataDirectories(const ADocument: TDumpDocument);
begin
  Writeln('PE Data Directories: ', ADocument.DataDirectories.Count);
  for var LIndex := 0 to ADocument.DataDirectories.Count - 1 do
  begin
    var LDirectory := ADocument.DataDirectories[LIndex];
    Writeln('  ', LDirectory.Index:2, '  ', LDirectory.Name:18,
      ' RVA=', LDirectory.RawRVA, ' (', LDirectory.RVA, ')',
      ' Size=', LDirectory.RawSize, ' (', LDirectory.Size, ')');
  end;
  Writeln;
end;

procedure DumpSections(const ADocument: TDumpDocument);
begin
  Writeln('Object Table Sections: ', ADocument.Sections.Count);
  for var LIndex := 0 to ADocument.Sections.Count - 1 do
  begin
    var LSection := ADocument.Sections[LIndex];
    Writeln('  ', LSection.Index:2, '  ', LSection.Name:8,
      ' RVA=', LSection.RVA,
      ' VirtSize=', LSection.VirtualSize,
      ' RawSize=', LSection.RawSize,
      ' RawOffset=', LSection.RawOffset,
      ' Flags=', LSection.FlagsValue, ' ', LSection.FlagsText);
  end;
  Writeln;
end;

procedure DumpImports(const ADocument: TDumpDocument);
begin
  Writeln('Import Modules: ', ADocument.Imports.Count);
  for var LModuleIndex := 0 to ADocument.Imports.Count - 1 do
  begin
    var LModule := ADocument.Imports[LModuleIndex];
    Writeln('  ', LModule.Name, ' (', LModule.Entries.Count, ')');
    for var LImportIndex := 0 to LModule.Entries.Count - 1 do
    begin
      var LImport := LModule.Entries[LImportIndex];
      Write('    ', LImport.Name);
      if LImport.HasHint then
        Write('  hint=', LImport.Hint);
      if LImport.HasOrdinal then
        Write('  ordinal=', LImport.Ordinal);
      Writeln;
    end;
  end;
  Writeln;
end;

procedure DumpExports(const ADocument: TDumpDocument);
begin
  Writeln('Exports: ', ADocument.ExportList.Count);
  for var LIndex := 0 to ADocument.ExportList.Count - 1 do
  begin
    var LExport := ADocument.ExportList[LIndex];
    Write('  ', LExport.Name);
    if LExport.HasRVA then
      Write('  RVA=', LExport.RVA);
    if LExport.HasOrdinal then
      Write('  ordinal=', LExport.Ordinal);
    if LExport.HasHint then
      Write('  hint=', LExport.Hint);
    Writeln;
  end;
  Writeln;
end;

procedure DumpResource(const AResource: TDumpResource; const AIndent: string);
begin
  // Print the typed resource tree reconstructed from TDUMP indentation.
  if AResource.Name <> '' then
    Write(AIndent, AResource.Name)
  else
    Write(AIndent, AResource.ResourceType);
  if AResource.HasId then
    Write(' (', AResource.Id, ')');
  if AResource.HasRVA then
    Write('  RVA=', AResource.RVA);
  if AResource.HasSize then
    Write('  Size=', AResource.Size);
  Writeln;

  for var LIndex := 0 to AResource.Children.Count - 1 do
    DumpResource(AResource.Children[LIndex], AIndent + '  ');
end;

procedure DumpResources(const ADocument: TDumpDocument);
begin
  Writeln('Resources: ', ADocument.Resources.Count);
  for var LIndex := 0 to ADocument.Resources.Count - 1 do
    DumpResource(ADocument.Resources[LIndex], '  ');
  Writeln;
end;

procedure DumpRelocations(const ADocument: TDumpDocument);
begin
  Writeln('Relocations: ', ADocument.Relocations.Count);
  var LLimit := ADocument.Relocations.Count;
  if LLimit > 20 then
    LLimit := 20;
  for var LIndex := 0 to LLimit - 1 do
  begin
    var LRelocation := ADocument.Relocations[LIndex];
    Write('  block ', LRelocation.BlockIndex, ' page=',
      IntToHex(LRelocation.PageRVA, 8), ' ', LRelocation.RelocationType);
    if LRelocation.HasOffset then
      Write(' +', IntToHex(LRelocation.Offset, 4));
    Writeln;
  end;
  if LLimit < ADocument.Relocations.Count then
    Writeln('  ... ', ADocument.Relocations.Count - LLimit, ' more entries');
  Writeln;
end;

procedure DumpSectionMetadata(const ATitle: string;
  const AMetadata: TDumpSectionMetadata);
begin
  if AMetadata = nil then
    Exit;
  Writeln(ATitle, ' metadata: ', AMetadata.Properties.Count,
    ' fields  File offset: ', AMetadata.RawFileOffset);
  if AMetadata.HasRootDirectoryCounts then
    Writeln('  Root directory: ', AMetadata.RootNamedEntryCount,
      ' named, ', AMetadata.RootIdEntryCount, ' ID entries');
end;

procedure DumpSymbols(const ADocument: TDumpDocument);
begin
  // Symbols are cross-references to the raw subsection records already shown.
  Writeln('Borland typed-symbol index: ', ADocument.Symbols.Count);
  Writeln;
end;

procedure DumpSymbolSubsections(const ADocument: TDumpDocument);
begin
  Writeln('Borland Symbol SubSection Directory: ', ADocument.SymbolSubsections.Count);
  for var LIndex := 0 to ADocument.SymbolSubsections.Count - 1 do
  begin
    var LSubsection := ADocument.SymbolSubsections[LIndex];
    Writeln('  ModIndex: ', LSubsection.RawModIndex,
      '  FileOffs: ', LSubsection.RawFileOffset,
      '  Size: ', LSubsection.RawSize,
      '  Type: ', LSubsection.SubsectionType);
  end;
  Writeln;
end;

procedure DumpSymbolModules(const ADocument: TDumpDocument);
begin
  Writeln('Borland Symbol Modules: ', ADocument.SymbolModules.Count);
  for var LIndex := 0 to ADocument.SymbolModules.Count - 1 do
  begin
    var LModule := ADocument.SymbolModules[LIndex];
    Writeln('  ModIndex: ', LModule.ModIndex:4,
      '  FileOffs: ', IntToHex(LModule.FileOffset, 5),
      '  sstModule');
    Writeln('    OvlNum: ', IntToHex(LModule.OvlNum, 4),
      '  LibIndex: ', IntToHex(LModule.LibIndex, 4),
      '  SegCount: ', IntToHex(LModule.SegCount, 4),
      '  Time: ', IntToHex(LModule.Time, 4),
      '  Name: ', LModule.Name);
    if LModule.HasNameIndex then
      Writeln('      Name ID: ', LModule.RawNameIndex,
        '  Resolved: ', LModule.ResolvedName);
    for var LSegmentIndex := 0 to LModule.Segments.Count - 1 do
    begin
      var LSegment := LModule.Segments[LSegmentIndex];
      Writeln('    ', LSegment.RawSegment, ':', LSegment.RawStartOffset,
        '-', LSegment.RawEndOffset, '  Flags: ', LSegment.RawFlags);
    end;
  end;
  Writeln;
end;

procedure DumpSourceModules(const ADocument: TDumpDocument);
begin
  Writeln('Borland Source Modules: ', ADocument.SourceModules.Count);
  for var LIndex := 0 to ADocument.SourceModules.Count - 1 do
  begin
    var LModule := ADocument.SourceModules[LIndex];
    Writeln('  ModIndex: ', LModule.ModIndex:4,
      '  FileOffs: ', IntToHex(LModule.FileOffset, 5), '  sstSrcModule');
    Writeln('    Segment ranges: ', LModule.SegmentRanges.Count);
    for var LRangeIndex := 0 to LModule.SegmentRanges.Count - 1 do
    begin
      var LRange := LModule.SegmentRanges[LRangeIndex];
      Writeln('      ', LRange.RawSegment, ':', LRange.RawStartOffset,
        '-', LRange.RawEndOffset);
    end;
    Writeln('    Source files: ', LModule.SourceFiles.Count);
    for var LFileIndex := 0 to LModule.SourceFiles.Count - 1 do
    begin
      var LSourceFile := LModule.SourceFiles[LFileIndex];
      Writeln('      File: ', LSourceFile.Name, '  Offset: ', LSourceFile.RawOffset);
      if LSourceFile.HasNameIndex then
        Writeln('        Name ID: ', LSourceFile.RawNameIndex,
          '  Resolved: ', LSourceFile.ResolvedName);
      for var LRangeIndex := 0 to LSourceFile.Ranges.Count - 1 do
      begin
        var LRange := LSourceFile.Ranges[LRangeIndex];
        Writeln('        Range: ', LRange.RawSegment, ':', LRange.RawStartOffset,
          '-', LRange.RawEndOffset);
        Write('          Line numbers:');
        for var LLineIndex := 0 to LRange.LineNumbers.Count - 1 do
        begin
          var LLineInfo := LRange.LineNumbers[LLineIndex];
          if (LLineIndex mod 4) = 0 then
            Writeln;
          Write('          ', LLineInfo.RawLineNumber, ':', LLineInfo.RawOffset, '  ');
        end;
        Writeln;
      end;
    end;
  end;
  Writeln;
end;

procedure DumpAlignSymbolSections(const ADocument: TDumpDocument);
begin
  Writeln('Borland Align Symbol Sections: ', ADocument.AlignSymbolSections.Count);
  for var LIndex := 0 to ADocument.AlignSymbolSections.Count - 1 do
  begin
    var LSection := ADocument.AlignSymbolSections[LIndex];
    Writeln('  ModIndex: ', LSection.ModIndex:4,
      '  FileOffs: ', IntToHex(LSection.FileOffset, 5),
      '  sstAlignSym  Symbols: ', LSection.Symbols.Count);
    Writeln('    Records: ', LSection.Records.Count,
      '  Search records: ', LSection.Searches.Count);
    var LScopeRootCount := 0;
    for var LRecord in LSection.Records do
      if (LRecord.Kind = bsrkProcedure) and (LRecord.ScopeParent = nil) then
        Inc(LScopeRootCount);
    Writeln('    Procedure scope roots: ', LScopeRootCount);
    for var LRecordIndex := 0 to LSection.Records.Count - 1 do
    begin
      var LRecord := LSection.Records[LRecordIndex];
      Writeln('    Record lines: ', LRecord.StartLine, '..', LRecord.EndLine);
      // The record node is the authoritative lossless source for this content.
      Writeln('      ', StringReplace(LRecord.Node.RawText, sLineBreak,
        sLineBreak + '      ', [rfReplaceAll]));
    end;
  end;
  Writeln;
end;

procedure DumpGlobalSymbolSections(const ADocument: TDumpDocument);
begin
  Writeln('Borland Global Symbol Sections: ', ADocument.GlobalSymbolSections.Count);
  for var LIndex := 0 to ADocument.GlobalSymbolSections.Count - 1 do
  begin
    var LSection := ADocument.GlobalSymbolSections[LIndex];
    Writeln('  sstGlobalSym records: ', LSection.Records.Count);
    Writeln('    Header fields: ', LSection.Properties.Count);
    Writeln('    ', StringReplace(LSection.Node.RawText, sLineBreak,
      sLineBreak + '    ', [rfReplaceAll]));
    for var LRecordIndex := 0 to LSection.Records.Count - 1 do
    begin
      var LRecord := LSection.Records[LRecordIndex];
      Writeln('    Record lines: ', LRecord.StartLine, '..', LRecord.EndLine);
      Writeln('      ', StringReplace(LRecord.Node.RawText, sLineBreak,
        sLineBreak + '      ', [rfReplaceAll]));
    end;
  end;
  Writeln;
end;

procedure DumpGlobalTypeSections(const ADocument: TDumpDocument);
begin
  Writeln('Borland Global Type Sections: ', ADocument.GlobalTypeSections.Count);
  for var LIndex := 0 to ADocument.GlobalTypeSections.Count - 1 do
  begin
    var LSection := ADocument.GlobalTypeSections[LIndex];
    Writeln('  sstGlobalTypes records: ', LSection.Records.Count);
    Writeln('    ', StringReplace(LSection.Node.RawText, sLineBreak,
      sLineBreak + '    ', [rfReplaceAll]));
    for var LRecordIndex := 0 to LSection.Records.Count - 1 do
    begin
      var LRecord := LSection.Records[LRecordIndex];
      Writeln('    Record lines: ', LRecord.StartLine, '..', LRecord.EndLine,
        '  Type references: ', LRecord.ReferencedTypes.Count,
        '  Members: ', LRecord.Members.Count,
        '  Details: ', LRecord.Details.Count);
      if LRecord.ResolvedName <> '' then
        Writeln('      Name ID ', LRecord.RawNameIndex, ': ', LRecord.ResolvedName);
      Writeln('      ', StringReplace(LRecord.Node.RawText, sLineBreak,
        sLineBreak + '      ', [rfReplaceAll]));
    end;
  end;
  Writeln;
end;

procedure DumpBorlandNames(const ADocument: TDumpDocument);
begin
  Writeln('Borland Names: ', ADocument.BorlandNames.Count);
  for var LIndex := 0 to ADocument.BorlandNames.Count - 1 do
  begin
    var LBorlandName := ADocument.BorlandNames[LIndex];
    Writeln('  ', LBorlandName.RawIndex, ': ', LBorlandName.Value);
  end;
  Writeln;
end;

procedure DumpDebugInformation(const ADocument: TDumpDocument);
begin
  if ADocument.DebugInformation = nil then
  begin
    Writeln('Debug information: none');
    Writeln;
    Exit;
  end;
  Writeln('Debug source modules: ',
    ADocument.DebugInformation.SourceModules.Count);
  Writeln('Normalized methods: ', ADocument.DebugInformation.Methods.Count);
  var LLimit := ADocument.DebugInformation.Methods.Count;
  if LLimit > 20 then
    LLimit := 20;
  for var LIndex := 0 to LLimit - 1 do
  begin
    var LMethod := ADocument.DebugInformation.Methods[LIndex];
    Write('  ', LMethod.Name, ' @ ', LMethod.Address,
      ' lines ', LMethod.SourceSpan.StartLine, '..', LMethod.SourceSpan.EndLine);
    if LMethod.SourceFileName <> '' then
      Write('  ', LMethod.SourceFileName);
    if LMethod.HasSourceLine then
      Write(':', LMethod.SourceLine);
    Writeln;
  end;
  if LLimit < ADocument.DebugInformation.Methods.Count then
    Writeln('  ... ', ADocument.DebugInformation.Methods.Count - LLimit,
      ' more method(s)');
  Writeln;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    var LFileName: string;
    if ParamCount > 0 then
      LFileName := ParamStr(1)
    else
      LFileName := '..\fixtures\PlainVanilla.Delphi.Package.bpl.tdump';

    var LParser := TDumpParser.Create;
    try
      var LDocument := LParser.ParseFile(LFileName);
      try
        Writeln('Source: ', LDocument.SourceFileName);
        Writeln('TDUMP version: ', LDocument.ToolVersion);
        Writeln('Raw lines: ', RawLineCount(LDocument.RawText));
        Writeln('Typed source lines: ', LDocument.Lines.Count);
        var LUnclassifiedLineCount := 0;
        for var LLine in LDocument.Lines do
          if (LLine.Kind = tlkText) or (LLine.Kind = tlkUnknown) then
            Inc(LUnclassifiedLineCount);
        Writeln('Unclassified typed lines: ', LUnclassifiedLineCount);
        Writeln('Generic nodes: ', LDocument.Nodes.Count);
        Writeln('Headers: ', LDocument.Headers.Count);
        Writeln('Sections: ', LDocument.Sections.Count);
        Writeln('Import modules: ', LDocument.Imports.Count);
        Writeln('Exports: ', LDocument.ExportList.Count);
        Writeln('Resources: ', LDocument.Resources.Count);
        Writeln('Relocations: ', LDocument.Relocations.Count);
        Writeln('Strings: ', LDocument.Strings.Count);
        Writeln('Object records: ', LDocument.ObjectRecords.Count);
        Writeln('Library members: ', LDocument.LibraryMembers.Count);
        Writeln('Mach architectures: ', LDocument.MachArchitectures.Count);
        Writeln('Mach load commands: ', LDocument.MachLoadCommands.Count);
        Writeln('Symbol subsections: ', LDocument.SymbolSubsections.Count);
        Writeln('Symbol modules: ', LDocument.SymbolModules.Count);
        Writeln('Source modules: ', LDocument.SourceModules.Count);
        Writeln('Align symbol sections: ', LDocument.AlignSymbolSections.Count);
        Writeln('Symbol searches: ', LDocument.SymbolSearches.Count);
        Writeln('Global symbol sections: ', LDocument.GlobalSymbolSections.Count);
        Writeln('Global type sections: ', LDocument.GlobalTypeSections.Count);
        Writeln('Borland subsections: ', LDocument.BorlandSubsections.Count);
        Writeln('Borland names: ', LDocument.BorlandNames.Count);
        Writeln('Borland name resolver entries: ', LDocument.BorlandNameLookup.Count);
        Writeln('Symbols: ', LDocument.Symbols.Count);
        if LDocument.DebugInformation <> nil then
          Writeln('Normalized methods: ', LDocument.DebugInformation.Methods.Count)
        else
          Writeln('Normalized methods: 0');
        Writeln;

        for var LIndex := 0 to LDocument.Headers.Count - 1 do
          DumpHeader(LDocument.Headers[LIndex]);

        DumpDataDirectories(LDocument);
        DumpSections(LDocument);
        DumpSectionMetadata('Import', LDocument.ImportMetadata);
        DumpImports(LDocument);
        DumpSectionMetadata('Export', LDocument.ExportMetadata);
        DumpExports(LDocument);
        DumpSectionMetadata('Resource', LDocument.ResourceMetadata);
        DumpResources(LDocument);
        DumpRelocations(LDocument);
        DumpSymbolSubsections(LDocument);
        DumpSymbolModules(LDocument);
        DumpSourceModules(LDocument);
        DumpAlignSymbolSections(LDocument);
        DumpGlobalSymbolSections(LDocument);
        DumpGlobalTypeSections(LDocument);
        DumpBorlandNames(LDocument);
        DumpSymbols(LDocument);
        DumpDebugInformation(LDocument);

        if LDocument.Diagnostics.Count > 0 then
        begin
          Writeln('Diagnostics: ', LDocument.Diagnostics.Count);
          for var LIndex := 0 to LDocument.Diagnostics.Count - 1 do
          begin
            var LDiagnostic := LDocument.Diagnostics[LIndex];
            Writeln('  ', DiagnosticSeverityName(LDiagnostic.Severity), ' line ',
              LDiagnostic.LineNumber, ': ', LDiagnostic.Message);
          end;
        end;
      finally
        LDocument.Free;
      end;
    finally
      LParser.Free;
    end;

    readln;
  except
    on LException: Exception do
    begin
      Writeln(LException.ClassName, ': ', LException.Message);
      ExitCode := 1;
    end;
  end;
end.
