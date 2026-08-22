program TDumpRelationsConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.StrUtils,
  TDump.Explorer.Parser in '..\source\parser\TDump.Explorer.Parser.pas',
  TDump.Explorer.Relations in '..\source\common\TDump.Explorer.Relations.pas';

procedure Require(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create('Relation check failed: ' + AMessage);
end;

function IsDelayHelperRelation(
  ARelation: TDumpSourceProcedureRelation): Boolean;
begin
  Result := EndsText('delayhlp.cpp', ARelation.SourceFile.Name);
end;

function FindProcedureTypeRelation(AGraph: TDumpRelationGraph;
  AProcedure: TDumpAlignSymbolRecord): TDumpProcedureTypeRelation;
begin
  Result := nil;
  for var LRelation in AGraph.ProcedureTypeRelations do
    if LRelation.ProcedureRecord = AProcedure then
      Exit(LRelation);
end;

function FindProcedureScopeRelation(AGraph: TDumpRelationGraph;
  AProcedure: TDumpAlignSymbolRecord): TDumpProcedureScopeRelation;
begin
  Result := nil;
  for var LRelation in AGraph.ProcedureScopeRelations do
    if LRelation.ProcedureRecord = AProcedure then
      Exit(LRelation);
end;

procedure WriteSourceProcedureRelation(
  ARelation: TDumpSourceProcedureRelation);
begin
  Writeln('  ', ARelation.ProcedureRecord.ResolvedName);
  Writeln('    source: ', ARelation.SourceFile.ResolvedName, ' lines ',
    ARelation.FirstSourceLine, '..', ARelation.LastSourceLine, ' (',
    ARelation.MatchingSourceLineCount, ' address records, ',
    ARelation.DistinctSourceLineCount, ' distinct lines)');
  Writeln('    debug: ', IntToHex(ARelation.ProcedureRecord.Segment, 4), ':',
    IntToHex(ARelation.OverlapStart, 5), '-', IntToHex(ARelation.OverlapEnd, 5));
  Require(ARelation.StartLocation.HasRVA, 'procedure start must resolve to an RVA');
  Writeln('    PE: ', ARelation.StartLocation.Section.Name, ' RVA ',
    IntToHex(ARelation.StartLocation.RVA, 8), ' VA ',
    IntToHex(ARelation.StartLocation.VirtualAddress, 8), ' file ',
    IntToHex(ARelation.StartLocation.FileOffset, 8));
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    var LFixtureName := '..\fixtures\PlainVanilla.Delphi.Package.bpl.tdump';
    if ParamCount > 0 then
      LFixtureName := ParamStr(1);
    LFixtureName := ExpandFileName(LFixtureName);
    Require(FileExists(LFixtureName), 'fixture was not found: ' + LFixtureName);

    var LParser := TDumpParser.Create;
    try
      var LDocument := LParser.ParseFile(LFixtureName);
      try
        var LBuilder := TDumpRelationBuilder.Create;
        try
          var LGraph := LBuilder.Build(LDocument);
          try
            Writeln('TDump relation-layer exercise');
            Writeln('Fixture: ', LFixtureName);
            Writeln('Source-to-procedure relations: ',
              LGraph.SourceProcedureRelations.Count);
            Writeln('Procedure-reference relations: ',
              LGraph.ProcedureReferenceRelations.Count);
            Writeln('Procedure-type relations: ', LGraph.ProcedureTypeRelations.Count);
            Writeln('Export-target relations: ', LGraph.ExportTargetRelations.Count);
            Writeln('Export-alias groups: ', LGraph.ExportAliasGroups.Count);
            Writeln('Procedure-scope relations: ', LGraph.ProcedureScopeRelations.Count);
            Writeln('Data-definition relations: ', LGraph.DataDefinitionRelations.Count);
            Writeln('Resource-location relations: ',
              LGraph.ResourceLocationRelations.Count);
            Writeln;
            Writeln('Export aliases:');
            for var LAliasGroup in LGraph.ExportAliasGroups do
            begin
              Write('  RVA ', IntToHex(LAliasGroup.RVA, 8), ': ');
              for var LIndex := 0 to LAliasGroup.Entries.Count - 1 do
              begin
                if LIndex > 0 then
                  Write(' | ');
                Write(LAliasGroup.Entries[LIndex].Name);
              end;
              Writeln;
            end;
            Writeln('Resource byte locations:');
            for var LResourceRelation in LGraph.ResourceLocationRelations do
              Writeln('  ', LResourceRelation.ResourcePath, ' RVA ',
                IntToHex(LResourceRelation.Location.RVA, 8), ' file ',
                IntToHex(LResourceRelation.Location.FileOffset, 8));
            Writeln;

            var LDelayRelationCount := 0;
            var LDelayReferenceCount := 0;
            for var LRelation in LGraph.SourceProcedureRelations do
              if IsDelayHelperRelation(LRelation) then
              begin
                Inc(LDelayRelationCount);
                WriteSourceProcedureRelation(LRelation);
                var LTypeRelation := FindProcedureTypeRelation(LGraph,
                  LRelation.ProcedureRecord);
                Require((LTypeRelation <> nil) and
                  (LTypeRelation.TypeIndex = $1034) and
                  (LTypeRelation.TypeRecord <> nil),
                  'delay helper procedure must use type 1034');
                var LScopeRelation := FindProcedureScopeRelation(LGraph,
                  LRelation.ProcedureRecord);
                Require((LScopeRelation <> nil) and
                  (LScopeRelation.EndRecord <> nil) and
                  (LScopeRelation.EndRecord.Kind = bsrkEnd),
                  'delay helper procedure must resolve its S_END record');
                if SameText(LRelation.ProcedureRecord.ResolvedName,
                  '@Sysinit@@_delayLoadHelper2$qqrv') then
                begin
                  Require(LRelation.StartLocation.RVA = $1758,
                    'delayLoadHelper2 start RVA must be 00001758');
                  Require(LRelation.StartLocation.VirtualAddress = $401758,
                    'delayLoadHelper2 start VA must be 00401758');
                  Require(LRelation.StartLocation.FileOffset = $B58,
                    'delayLoadHelper2 start file offset must be 00000B58');
                end;
              end;
            for var LReferenceRelation in LGraph.ProcedureReferenceRelations do
              if EndsText('delayLoadHelper2$qqrv',
                LReferenceRelation.ProcedureRecord.ResolvedName) or
                EndsText('_FUnloadDelayLoadedDLL2$qqrv',
                LReferenceRelation.ProcedureRecord.ResolvedName) or
                EndsText('_HrLoadAllImportsForDll$qqrv',
                LReferenceRelation.ProcedureRecord.ResolvedName) then
                Inc(LDelayReferenceCount);

            Require(LDelayRelationCount = 4,
              'delayhlp.cpp must resolve to four procedures');
            Require(LDelayReferenceCount = 3,
              'three delay helper procedures must have global references');
            Require(LGraph.ExportTargetRelations.Count = LDocument.ExportList.Count,
              'every export RVA must create one target relation');
            Require(LGraph.ExportAliasGroups.Count = 3,
              'fixture must expose three exported-RVA alias groups');
            var LProcedureExportCount := 0;
            var LReferenceExportCount := 0;
            for var LExportRelation in LGraph.ExportTargetRelations do
            begin
              Require(LExportRelation.Location.HasRVA,
                'every export target must resolve to PE coordinates');
              if LExportRelation.ProcedureRecord <> nil then
                Inc(LProcedureExportCount);
              if LExportRelation.ProcedureReference <> nil then
                Inc(LReferenceExportCount);
            end;
            Require(LProcedureExportCount = 7,
              'seven export rows must resolve to procedure definitions');
            Require(LReferenceExportCount = 1,
              'one export-only initialization stub must resolve to S_GPROCREF');
            Require(LGraph.DataDefinitionRelations.Count = 6,
              'six SysInit global-data definitions must have global index entries');
            Require(LGraph.ResourceLocationRelations.Count = 4,
              'four resource data leaves must resolve to PE locations');
            for var LResourceRelation in LGraph.ResourceLocationRelations do
            begin
              Require(SameText(LResourceRelation.Location.Section.Name, '.rsrc'),
                'resource leaf must belong to .rsrc');
              Require(LResourceRelation.Location.HasFileOffset,
                'resource leaf must resolve to a raw binary offset');
            end;
            Writeln;
            Writeln('Checks passed: ', LDelayRelationCount,
              ' source/procedure joins and ', LDelayReferenceCount,
              ' global procedure-reference joins for delayhlp.cpp.');
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
    Readln;
  except
    on LException: Exception do
    begin
      Writeln(ErrOutput, LException.ClassName, ': ', LException.Message);
      ExitCode := 1;
    end;
  end;
end.
