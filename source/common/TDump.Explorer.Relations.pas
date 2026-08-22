//**************************************************************************************************
//
// Unit TDump.Explorer.Relations
// unit for TDump Explorer project
// https://github.com/RRUZ/TDump-Explorer
//
// Derived cross-reference layer for TDump Explorer.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.Relations;



// TDump.Explorer.Parser deliberately preserves TDUMP's output as independent
// projections: PE headers, section table, source modules, aligned symbols,
// global symbols, types, exports and resources.  A TDUMP file seldom states
// how all of those projections relate to one another.  This unit builds the
// useful joins without changing, normalizing, or taking ownership of that raw
// parser model.
//
// The graph answers questions which are difficult to answer from a single
// TDUMP subsection, such as: which procedures cover a source range; where an
// exported RVA sits in the PE image; which global index points at a procedure;
// which type describes a procedure; or which raw byte range backs a resource.
//
// A relation is either explicit (both records independently encode the same
// identity) or address-derived (the relationship is inferred by translating a
// segment:offset or RVA through the section table).  Consumers should retain
// that distinction when presenting findings or making further deductions.
//
// Example from PlainVanilla.Delphi.Package.bpl.tdump:
//   Source range: delayhlp.cpp, 0001:00758-00C07
//   Procedure:    _delayLoadHelper2, Address 0001:00758-00A37
//   PE section:   .text, object 1, RVA 00001000, raw file offset 00000400
// The overlapping start therefore resolves as:
//   0001:00758 -> RVA 00001758 -> VA 00401758 -> file offset 00000B58.
// The same source range also overlaps three following procedures, exposing a
// useful compilation-unit-to-code relationship which TDUMP never prints as a
// single direct link.
//
// The graph owns only its relation objects.  Every object referenced by a
// relation remains owned by TDumpDocument, so the document must outlive the
// graph.  Build a fresh graph after reparsing a document.

interface

uses
  System.SysUtils,
  System.Math,
  System.Generics.Collections,
  TDump.Explorer.Parser;

type
  // States the confidence source of a relation, not a strength ranking.
  // reExplicit means matching parser fields identify the same entity.
  // reAddressDerived means compatible address coordinates made the join.
  TDumpRelationEvidence = (reExplicit, reAddressDerived);

  // Normalizes a Borland segment:offset pair into PE coordinates.
  //
  // Segment is the TDUMP/CodeView object ordinal and Offset is relative to that
  // object.  Section, RVA and VirtualAddress are available only when the pair
  // belongs to a PE section.  FileOffset is intentionally unavailable for the
  // virtual-only tail of a section (for example, uninitialized data).
  TDumpAddressLocation = record
    Segment: UInt64;                  // Original TDUMP object/segment ordinal.
    Offset: UInt64;                   // Byte offset relative to Segment.
    Section: TDumpSection;            // Non-owning matching PE section, if any.
    RVA: UInt64;                      // Section RVA plus Offset when HasRVA.
    HasRVA: Boolean;
    VirtualAddress: UInt64;           // ImageBase plus RVA when present in TDUMP.
    HasVirtualAddress: Boolean;
    FileOffset: UInt64;               // Raw-file byte position when raw-backed.
    HasFileOffset: Boolean;
  end;

  // Links a source-file interval to an S_GPROC32 record whose code overlaps it.
  // A source range can span several procedures and a procedure can participate
  // in several source ranges, so this is intentionally a many-to-many relation.
  // It retains coverage statistics but does not copy source text.
  //
  // Sample relation from the BPL fixture:
  //   File: C:\Projects\Ganymede\tp\runtime\rtl\sys\delayhlp.cpp [004]
  //   Range: 0001:00758-00C07
  //   Procedure Address: 0001:00758-00A37 (_delayLoadHelper2)
  //   Overlap: 0001:00758-00A37, source lines 223 and 231.
  TDumpSourceProcedureRelation = class
  public
    SourceModule: TDumpSourceModule;              // Owning source-module context.
    SourceFile: TDumpSourceFile;                  // File that declares SourceRange.
    SourceRange: TDumpSourceRange;                // Original TDUMP range.
    ProcedureRecord: TDumpAlignSymbolRecord;      // Overlapping S_GPROC32 record.
    OverlapStart: UInt64;                          // Inclusive segment-relative start.
    OverlapEnd: UInt64;                            // Inclusive segment-relative end.
    StartLocation: TDumpAddressLocation;
    EndLocation: TDumpAddressLocation;
    MatchingSourceLineCount: Integer;             // Matching entries, duplicates kept.
    DistinctSourceLineCount: Integer;             // Unique physical source-line values.
    FirstSourceLine: Integer;                     // Zero when no matching line entry.
    LastSourceLine: Integer;                      // Zero when no matching line entry.
    Evidence: TDumpRelationEvidence;
  end;

  // Links an S_GPROCREF entry in sstGlobalSym back to its S_GPROC32 definition.
  // The shared segment:offset is the procedure entry address, rather than an
  // arbitrary interior instruction address.
  // Fixture sample (sstGlobalSym @041B7):
  //   S_GPROCREF type: 1034  0001:00758  @_delayLoadHelper2...
  // joins S_GPROC32 @03A53:
  //   0001:00758-00A37  @_delayLoadHelper2...
  TDumpProcedureReferenceRelation = class
  public
    ProcedureRecord: TDumpAlignSymbolRecord;
    ReferenceRecord: TDumpGlobalSymbolRecord;
    Evidence: TDumpRelationEvidence;
  end;

  // Resolves the Type: field of an S_GPROC32 Debug row to sstGlobalTypes.
  // The relation reads the lossless record node because that field is distinct
  // from the procedure's generated-code range.
  // Fixture sample: _delayLoadHelper2's Debug row says "Type: 1034".  The
  // global Type 1034 record says "PROCEDURE, near fastcall returns void,
  // Params: 0000", enriching the raw procedure symbol with its signature.
  // The relation remains present with TypeRecord=nil if a partial dump omits
  // the matching sstGlobalTypes record.
  TDumpProcedureTypeRelation = class
  public
    ProcedureRecord: TDumpAlignSymbolRecord;
    TypeIndex: UInt64;                           // Raw type index named by S_GPROC32.
    TypeRecord: TDumpGlobalTypeRecord;           // Nil if TDUMP omitted its type record.
    Evidence: TDumpRelationEvidence;
  end;

  // Connects an exported RVA to its PE location and, where TDUMP exposes one,
  // to the defining procedure or a global procedure-reference entry.  An export
  // can validly point to a thunk or data, so both symbol fields may be nil.
  // Example: an export at RVA 00001D98 becomes segment 0001:offset 00000D98
  // when .text starts at RVA 00001000. If this is the same procedure-entry
  // address as a symbol record, ProcedureRecord is populated; otherwise a
  // matching S_GPROCREF is used as a secondary declaration.
  TDumpExportTargetRelation = class
  public
    ExportEntry: TDumpExport;                    // The original Export List row.
    Location: TDumpAddressLocation;              // Translation of ExportEntry.RVA.
    ProcedureRecord: TDumpAlignSymbolRecord;     // Exact procedure-entry match, if any.
    ProcedureReference: TDumpGlobalSymbolRecord; // Fallback global procedure reference.
    Evidence: TDumpRelationEvidence;
  end;

  // Groups every export row that aliases the same implementation RVA.  Groups
  // exist only for duplicate RVAs; a unique export does not need a group.
  // Entries are non-owning references to the document's export collection.
  // Fixture example: RVA 00001D98 has both the decorated PackageLoad linkproc
  // name and the public Initialize export name.
  TDumpExportAliasGroup = class
  public
    RVA: UInt64;                    // Address shared by all listed export rows.
    Entries: TList<TDumpExport>;    // Non-owning aliases in document export order.
    constructor Create;
    destructor Destroy; override;
  end;

  // Resolves the relative End and Next record offsets on an S_GPROC32 record.
  // EndRecord normally identifies the lexical scope terminator; NextRecord
  // identifies the following sibling record.  Both target records belong to
  // the same sstAlignSym subsection.
  // Fixture sample: _delayLoadHelper2 sits in the sstAlignSym subsection with
  // FileOffs 02D44 and says End: 00D60, Next: 00D64. The resolved records are
  // therefore 03AA4 (S_END) and 03AA8 (the next S_GPROC32), respectively.
  TDumpProcedureScopeRelation = class
  public
    ProcedureRecord: TDumpAlignSymbolRecord;
    AlignSection: TDumpAlignSymbolSection;       // Subsection containing all targets.
    EndRecord: TDumpAlignSymbolRecord;            // Nil when End cannot be resolved.
    NextRecord: TDumpAlignSymbolRecord;           // Nil when Next cannot be resolved.
    Evidence: TDumpRelationEvidence;
  end;

  // Connects the sstAlignSym definition of global storage to the matching
  // sstGlobalSym index entry at the same segment:offset and display name.  The
  // two symbol subsections serve different purposes: definition versus index.
  // A match requires all three stable keys: global-data kind, segment:offset,
  // and resolved display name. Fixture sample: S_GDATA32 @03C53 and @040D3
  // both identify bool8 0004:00000 @Sysinit@ModuleIsLib, connecting its code
  // subsection definition to its sstGlobalSym lookup entry.
  TDumpDataDefinitionRelation = class
  public
    DefinitionRecord: TDumpAlignSymbolRecord;
    GlobalRecord: TDumpGlobalSymbolRecord;
    Location: TDumpAddressLocation;
    Evidence: TDumpRelationEvidence;
  end;

  // Maps a resource data RVA to the owning PE section and, when raw-backed,
  // to the byte offset that can be read from the original binary.  ResourcePath
  // retains the hierarchy because resource names alone are not necessarily unique.
  // Fixture example: RCData / PACKAGEINFO at RVA 00009158 maps through .rsrc
  // to raw file offset 00002158, allowing a binary viewer to read its bytes.
  TDumpResourceLocationRelation = class
  public
    Resource: TDumpResource;          // Resource-node that owns the data RVA.
    ResourcePath: string;             // Human-readable type/name/id hierarchy.
    Location: TDumpAddressLocation;
    Evidence: TDumpRelationEvidence;
  end;

  // Owns only derived relation records; every referenced parser model remains
  // owned by TDumpDocument and must outlive this graph.  Its public lists are
  // exposed for read/enumeration; callers must not free or retain their items
  // after destroying the graph.
  TDumpRelationGraph = class
  private
    FDocument: TDumpDocument;
    FSourceProcedureRelations: TObjectList<TDumpSourceProcedureRelation>;
    FProcedureReferenceRelations: TObjectList<TDumpProcedureReferenceRelation>;
    FProcedureTypeRelations: TObjectList<TDumpProcedureTypeRelation>;
    FExportTargetRelations: TObjectList<TDumpExportTargetRelation>;
    FExportAliasGroups: TObjectList<TDumpExportAliasGroup>;
    FProcedureScopeRelations: TObjectList<TDumpProcedureScopeRelation>;
    FDataDefinitionRelations: TObjectList<TDumpDataDefinitionRelation>;
    FResourceLocationRelations: TObjectList<TDumpResourceLocationRelation>;
    FImageBase: UInt64;
    FHasImageBase: Boolean;
    // Finds a PE section by TDUMP object ordinal, validating the virtual extent.
    function FindSectionForSegment(ASegment, AOffset: UInt64): TDumpSection;
  public
    constructor Create(ADocument: TDumpDocument);
    destructor Destroy; override;
  // Translates a segment-relative address.  False leaves only Segment/Offset set.
    // For example, in the BPL fixture 0001:00758 yields .text/RVA 00001758;
    // a valid BSS address may yield an RVA but deliberately no FileOffset.
    function TryResolveAddress(ASegment, AOffset: UInt64;
      out ALocation: TDumpAddressLocation): Boolean;
  // Translates an RVA by finding its containing section.  False means no match.
    // Example: RVA 00009158 identifies the resource-section location above.
    function TryResolveRVA(ARVA: UInt64; out ALocation: TDumpAddressLocation): Boolean;
    property Document: TDumpDocument read FDocument;
    property ImageBase: UInt64 read FImageBase;
    property HasImageBase: Boolean read FHasImageBase;
    property SourceProcedureRelations: TObjectList<TDumpSourceProcedureRelation>
      read FSourceProcedureRelations;
    property ProcedureReferenceRelations: TObjectList<TDumpProcedureReferenceRelation>
      read FProcedureReferenceRelations;
    property ProcedureTypeRelations: TObjectList<TDumpProcedureTypeRelation>
      read FProcedureTypeRelations;
    property ExportTargetRelations: TObjectList<TDumpExportTargetRelation>
      read FExportTargetRelations;
    property ExportAliasGroups: TObjectList<TDumpExportAliasGroup>
      read FExportAliasGroups;
    property ProcedureScopeRelations: TObjectList<TDumpProcedureScopeRelation>
      read FProcedureScopeRelations;
    property DataDefinitionRelations: TObjectList<TDumpDataDefinitionRelation>
      read FDataDefinitionRelations;
    property ResourceLocationRelations: TObjectList<TDumpResourceLocationRelation>
      read FResourceLocationRelations;
  end;

  // Builds non-owning, repeatable joins across source, symbol, PE, type, export
  // and resource data.  Build never alters ADocument and returns a graph even
  // for an empty document; the graph then simply contains no relations.
  TDumpRelationBuilder = class
  private
    // Each builder contributes one independent relation family to AGraph.
    procedure BuildSourceProcedureRelations(AGraph: TDumpRelationGraph);
    procedure BuildProcedureReferenceRelations(AGraph: TDumpRelationGraph);
    procedure BuildProcedureTypeRelations(AGraph: TDumpRelationGraph);
    procedure BuildExportRelations(AGraph: TDumpRelationGraph);
    procedure BuildProcedureScopeRelations(AGraph: TDumpRelationGraph);
    procedure BuildDataDefinitionRelations(AGraph: TDumpRelationGraph);
    procedure BuildResourceLocationRelations(AGraph: TDumpRelationGraph);
  public
    function Build(ADocument: TDumpDocument): TDumpRelationGraph;
  end;

implementation

// TDUMP emits numeric identity fields in hexadecimal, sometimes with spacing.
// Centralizing this conversion keeps all address and type joins consistent.
function TryParseHexValue(const AText: string; out AValue: UInt64): Boolean;
begin
  Result := TryStrToUInt64('$' + Trim(AText), AValue);
end;

// Extracts the procedure's primary generated-code interval.  It purposely
// selects Address rather than Debug: Address: the latter describes source debug
// coverage and can omit prologue/epilogue instructions.
function TryGetProcedureCodeRange(ARecord: TDumpAlignSymbolRecord;
  out ASegment, AStartOffset, AEndOffset: UInt64): Boolean;
begin
  Result := False;
  if ARecord = nil then
    Exit;

  // Parse the first address range from the procedure record.  TDUMP emits this
  // before its Debug: range, which is a narrower source-coverage interval.
  for var LProperty in ARecord.Properties do
    if SameText(LProperty.Name, 'Address') then
    begin
      var LColonPos := Pos(':', LProperty.RawValue);
      var LDashPos := Pos('-', LProperty.RawValue);
      if (LColonPos = 0) or (LDashPos <= LColonPos) then
        Continue;
      var LSegmentText := Copy(LProperty.RawValue, 1, LColonPos - 1);
      var LStartText := Copy(LProperty.RawValue, LColonPos + 1,
        LDashPos - LColonPos - 1);
      var LEndText := Copy(LProperty.RawValue, LDashPos + 1, MaxInt);
      if TryParseHexValue(LSegmentText, ASegment) and
        TryParseHexValue(LStartText, AStartOffset) and
        TryParseHexValue(LEndText, AEndOffset) then
        Exit(True);
    end;
end;

// Reads Type: from the lossless S_GPROC32 node.  The parser's structured
// procedure fields do not otherwise model this debug-only type annotation.
function TryGetProcedureTypeIndex(ARecord: TDumpAlignSymbolRecord;
  out ATypeIndex: UInt64): Boolean;
begin
  Result := False;
  if (ARecord = nil) or (ARecord.Node = nil) then
    Exit;
  var LTypePos := Pos('Type:', ARecord.Node.RawText);
  if LTypePos = 0 then
    Exit;
  var LTypeText := Trim(Copy(ARecord.Node.RawText, LTypePos + Length('Type:'),
    MaxInt));
  var LSeparatorPos := 1;
  while (LSeparatorPos <= Length(LTypeText)) and
    not CharInSet(LTypeText[LSeparatorPos], [#9, #10, #13, ' ']) do
    Inc(LSeparatorPos);
  LTypeText := Copy(LTypeText, 1, LSeparatorPos - 1);
  Result := TryParseHexValue(LTypeText, ATypeIndex);
end;

// Finds the global type definition that shares the exact CodeView type index.
function FindGlobalTypeRecord(ADocument: TDumpDocument;
  ATypeIndex: UInt64): TDumpGlobalTypeRecord;
begin
  Result := nil;
  for var LSection in ADocument.GlobalTypeSections do
    for var LRecord in LSection.Records do
      if LRecord.TypeIndex = ATypeIndex then
        Exit(LRecord);
end;

// Prefers TDUMP's resolved demangled name.  The fallback keeps joins available
// when a record carries only its original symbol spelling.
function RecordDisplayName(ARecord: TDumpBorlandSymbolRecord): string;
begin
  Result := ARecord.ResolvedName;
  if Result = '' then
    Result := ARecord.Name;
end;

// Looks for a procedure whose entry point exactly equals the supplied address.
// It does not use range containment: an export to an interior address is not a
// trustworthy declaration that the procedure itself is exported.
function FindProcedureForAddress(ADocument: TDumpDocument; ASegment,
  AOffset: UInt64): TDumpAlignSymbolRecord;
begin
  Result := nil;
  for var LAlignSection in ADocument.AlignSymbolSections do
    for var LRecord in LAlignSection.Records do
    begin
      var LSegment: UInt64;
      var LStartOffset: UInt64;
      var LEndOffset: UInt64;
      if (LRecord.Kind = bsrkProcedure) and
        TryGetProcedureCodeRange(LRecord, LSegment, LStartOffset, LEndOffset) and
        (LSegment = ASegment) and (LStartOffset = AOffset) then
        Exit(LRecord);
    end;
end;

// Fallback when an export has no aligned-symbol procedure definition but does
// have a matching global procedure-reference record.
function FindProcedureReferenceForAddress(ADocument: TDumpDocument; ASegment,
  AOffset: UInt64): TDumpGlobalSymbolRecord;
begin
  Result := nil;
  for var LGlobalSection in ADocument.GlobalSymbolSections do
    for var LRecord in LGlobalSection.Records do
      if (LRecord.Kind = bsrkProcedureReference) and LRecord.HasAddress and
        (LRecord.Segment = ASegment) and (LRecord.Address = AOffset) then
        Exit(LRecord);
end;

// sstAlignSym scope offsets are relative to their subsection's file offset;
// Find the parser record at that absolute TDUMP record position.
function FindAlignRecordAtOffset(ASection: TDumpAlignSymbolSection;
  ARecordOffset: UInt64): TDumpAlignSymbolRecord;
begin
  Result := nil;
  for var LRecord in ASection.Records do
    if LRecord.RecordOffset = ARecordOffset then
      Exit(LRecord);
end;

// Recursively flattens the resource tree only for nodes with a data RVA.  The
// path is retained so consumers can distinguish same-named sibling resources.
procedure AddResourceLocationRelations(AGraph: TDumpRelationGraph;
  AResource: TDumpResource; const AParentPath: string);
begin
  var LCaption := AResource.Name;
  if LCaption = '' then
    LCaption := AResource.ResourceType;
  if AResource.HasId then
    LCaption := LCaption + ' (' + AResource.Id.ToString + ')';
  var LPath := LCaption;
  if AParentPath <> '' then
    LPath := AParentPath + ' / ' + LPath;
  if AResource.HasRVA then
  begin
    var LRelation := TDumpResourceLocationRelation.Create;
    LRelation.Resource := AResource;
    LRelation.ResourcePath := LPath;
    if AGraph.TryResolveRVA(AResource.RVA, LRelation.Location) then
      LRelation.Evidence := reAddressDerived
    else
      LRelation.Evidence := reExplicit;
    AGraph.ResourceLocationRelations.Add(LRelation);
  end;
  for var LChild in AResource.Children do
    AddResourceLocationRelations(AGraph, LChild, LPath);
end;

{ TDumpRelationGraph }

constructor TDumpRelationGraph.Create(ADocument: TDumpDocument);
begin
  inherited Create;
  // The lists own only relation wrappers.  Their parser-model members remain
  // borrowed references, making graph construction inexpensive and lossless.
  FDocument := ADocument;
  FSourceProcedureRelations := TObjectList<TDumpSourceProcedureRelation>.Create(True);
  FProcedureReferenceRelations := TObjectList<TDumpProcedureReferenceRelation>.Create(True);
  FProcedureTypeRelations := TObjectList<TDumpProcedureTypeRelation>.Create(True);
  FExportTargetRelations := TObjectList<TDumpExportTargetRelation>.Create(True);
  FExportAliasGroups := TObjectList<TDumpExportAliasGroup>.Create(True);
  FProcedureScopeRelations := TObjectList<TDumpProcedureScopeRelation>.Create(True);
  FDataDefinitionRelations := TObjectList<TDumpDataDefinitionRelation>.Create(True);
  FResourceLocationRelations := TObjectList<TDumpResourceLocationRelation>.Create(True);

  // Image base is optional in a TDUMP.  Keep the availability flag separate so
  // address zero is not confused with a missing PE optional-header value.
  if FDocument = nil then
    Exit;
  for var LHeader in FDocument.Headers do
    for var LProperty in LHeader.Properties do
      if SameText(Trim(LProperty.Name), 'Image base') and LProperty.HasUIntValue then
      begin
        FImageBase := LProperty.UIntValue;
        FHasImageBase := True;
        Exit;
      end;
end;

destructor TDumpRelationGraph.Destroy;
begin
  // Free in reverse construction order.  No parser-document member is freed.
  FResourceLocationRelations.Free;
  FDataDefinitionRelations.Free;
  FProcedureScopeRelations.Free;
  FExportAliasGroups.Free;
  FExportTargetRelations.Free;
  FProcedureTypeRelations.Free;
  FProcedureReferenceRelations.Free;
  FSourceProcedureRelations.Free;
  inherited;
end;

function TDumpRelationGraph.FindSectionForSegment(ASegment,
  AOffset: UInt64): TDumpSection;
begin
  Result := nil;
  if (FDocument = nil) or (ASegment > High(Integer)) then
    Exit;

  // Borland's 32-bit records in this fixture use the PE object ordinal as segment.
  // Requiring the offset to fit the virtual extent prevents an accidental ordinal-only join.
  for var LSection in FDocument.Sections do
    if (LSection.Index = Integer(ASegment)) and
      (AOffset < LSection.VirtualSize) then
      Exit(LSection);
end;

function TDumpRelationGraph.TryResolveAddress(ASegment, AOffset: UInt64;
  out ALocation: TDumpAddressLocation): Boolean;
begin
  FillChar(ALocation, SizeOf(ALocation), 0);
  ALocation.Segment := ASegment;
  ALocation.Offset := AOffset;
  // A segment number alone is insufficient: the offset must be mapped inside
  // the section's virtual image.  This rejects malformed or stale debug data.
  ALocation.Section := FindSectionForSegment(ASegment, AOffset);
  Result := ALocation.Section <> nil;
  if not Result then
    Exit;

  ALocation.RVA := ALocation.Section.RVA + AOffset;
  ALocation.HasRVA := True;
  if FHasImageBase then
  begin
    ALocation.VirtualAddress := FImageBase + ALocation.RVA;
    ALocation.HasVirtualAddress := True;
  end;
  // A PE section can occupy more memory than bytes in the file.  Only the raw
  // prefix has a binary file position; the rest is loader-created memory.
  if AOffset < ALocation.Section.RawSize then
  begin
    ALocation.FileOffset := ALocation.Section.RawOffset + AOffset;
    ALocation.HasFileOffset := True;
  end;
end;

function TDumpRelationGraph.TryResolveRVA(ARVA: UInt64;
  out ALocation: TDumpAddressLocation): Boolean;
begin
  FillChar(ALocation, SizeOf(ALocation), 0);
  Result := False;
  if FDocument = nil then
    Exit;
  // Use virtual size, not raw size, so callers can still locate BSS-style RVAs.
  for var LSection in FDocument.Sections do
    if (ARVA >= LSection.RVA) and (ARVA - LSection.RVA < LSection.VirtualSize) then
      Exit(TryResolveAddress(LSection.Index, ARVA - LSection.RVA, ALocation));
end;

{ TDumpExportAliasGroup }

constructor TDumpExportAliasGroup.Create;
begin
  inherited Create;
  Entries := TList<TDumpExport>.Create;
end;

destructor TDumpExportAliasGroup.Destroy;
begin
  Entries.Free;
  inherited;
end;

{ TDumpRelationBuilder }

function TDumpRelationBuilder.Build(ADocument: TDumpDocument): TDumpRelationGraph;
begin
  Result := TDumpRelationGraph.Create(ADocument);
  try
    if ADocument <> nil then
    begin
      // These passes deliberately have no ordering dependency.  Keeping them
      // separate makes each inference family independently testable and lets
      // later versions add relations without changing parser semantics.
      BuildSourceProcedureRelations(Result);
      BuildProcedureReferenceRelations(Result);
      BuildProcedureTypeRelations(Result);
      BuildExportRelations(Result);
      BuildProcedureScopeRelations(Result);
      BuildDataDefinitionRelations(Result);
      BuildResourceLocationRelations(Result);
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TDumpRelationBuilder.BuildSourceProcedureRelations(
  AGraph: TDumpRelationGraph);
begin
  // ModIndex first limits matching to the source module that owns the aligned
  // symbol subsection.  Segment/range overlap then creates the actual join.
  for var LSourceModule in AGraph.Document.SourceModules do
    for var LSourceFile in LSourceModule.SourceFiles do
      for var LSourceRange in LSourceFile.Ranges do
        for var LAlignSection in AGraph.Document.AlignSymbolSections do
          if LAlignSection.ModIndex = LSourceModule.ModIndex then
            for var LRecord in LAlignSection.Records do
              begin
                var LProcedureSegment: UInt64;
                var LProcedureStart: UInt64;
                var LProcedureEnd: UInt64;
                if (LRecord.Kind <> bsrkProcedure) or
                  not TryGetProcedureCodeRange(LRecord, LProcedureSegment,
                    LProcedureStart, LProcedureEnd) or
                  (LProcedureSegment <> LSourceRange.Segment) or
                  (LProcedureStart > LSourceRange.EndOffset) or
                  (LProcedureEnd < LSourceRange.StartOffset) then
                  Continue;
                // Ranges use inclusive TDUMP offsets.  Retain their intersection
                // so callers can show the exact portion of code explained by a
                // source-file range rather than the complete procedure extent.
                var LRelation := TDumpSourceProcedureRelation.Create;
                LRelation.SourceModule := LSourceModule;
                LRelation.SourceFile := LSourceFile;
                LRelation.SourceRange := LSourceRange;
                LRelation.ProcedureRecord := LRecord;
                LRelation.OverlapStart := Max(LProcedureStart,
                  LSourceRange.StartOffset);
                LRelation.OverlapEnd := Min(LProcedureEnd,
                  LSourceRange.EndOffset);
                AGraph.TryResolveAddress(LProcedureSegment, LRelation.OverlapStart,
                  LRelation.StartLocation);
                AGraph.TryResolveAddress(LProcedureSegment, LRelation.OverlapEnd,
                  LRelation.EndLocation);
                LRelation.Evidence := reAddressDerived;

                // TDUMP can list the same physical line more than once (for
                // branches or compiler-generated code); report both counts.
                var LSeenLines := TDictionary<Integer, Byte>.Create;
                try
                  for var LSourceLine in LSourceRange.LineNumbers do
                    if (LSourceLine.Offset >= LRelation.OverlapStart) and
                      (LSourceLine.Offset <= LRelation.OverlapEnd) then
                    begin
                      Inc(LRelation.MatchingSourceLineCount);
                      LSeenLines.TryAdd(LSourceLine.LineNumber, 0);
                      if (LRelation.FirstSourceLine = 0) or
                        (LSourceLine.LineNumber < LRelation.FirstSourceLine) then
                        LRelation.FirstSourceLine := LSourceLine.LineNumber;
                      if LSourceLine.LineNumber > LRelation.LastSourceLine then
                        LRelation.LastSourceLine := LSourceLine.LineNumber;
                    end;
                  LRelation.DistinctSourceLineCount := LSeenLines.Count;
                finally
                  LSeenLines.Free;
                end;
                AGraph.SourceProcedureRelations.Add(LRelation);
              end;
end;

procedure TDumpRelationBuilder.BuildProcedureReferenceRelations(
  AGraph: TDumpRelationGraph);
begin
  // A GPROCREF indexes a definition by its exact entry address.  Do not match
  // an interior address merely because it lies within the procedure range.
  for var LGlobalSection in AGraph.Document.GlobalSymbolSections do
    for var LReference in LGlobalSection.Records do
      if (LReference.Kind = bsrkProcedureReference) and LReference.HasAddress then
        for var LAlignSection in AGraph.Document.AlignSymbolSections do
          for var LProcedure in LAlignSection.Records do
            begin
              var LProcedureSegment: UInt64;
              var LProcedureStart: UInt64;
              var LProcedureEnd: UInt64;
              if (LProcedure.Kind <> bsrkProcedure) or
                not TryGetProcedureCodeRange(LProcedure, LProcedureSegment,
                  LProcedureStart, LProcedureEnd) or
                (LProcedureSegment <> LReference.Segment) or
                (LProcedureStart <> LReference.Address) then
                Continue;
              var LRelation := TDumpProcedureReferenceRelation.Create;
              LRelation.ProcedureRecord := LProcedure;
              LRelation.ReferenceRecord := LReference;
              LRelation.Evidence := reExplicit;
              AGraph.ProcedureReferenceRelations.Add(LRelation);
              Break;
            end;
end;

procedure TDumpRelationBuilder.BuildProcedureTypeRelations(
  AGraph: TDumpRelationGraph);
begin
  // Preserve a relation even if a matching global type record is absent: the
  // procedure's declared numeric type index is still valuable diagnostic data.
  for var LAlignSection in AGraph.Document.AlignSymbolSections do
    for var LProcedure in LAlignSection.Records do
    begin
      var LTypeIndex: UInt64;
      if (LProcedure.Kind <> bsrkProcedure) or
        not TryGetProcedureTypeIndex(LProcedure, LTypeIndex) then
        Continue;
        var LRelation := TDumpProcedureTypeRelation.Create;
        LRelation.ProcedureRecord := LProcedure;
        LRelation.TypeIndex := LTypeIndex;
        LRelation.TypeRecord := FindGlobalTypeRecord(AGraph.Document, LTypeIndex);
        LRelation.Evidence := reExplicit;
        AGraph.ProcedureTypeRelations.Add(LRelation);
    end;
end;

procedure TDumpRelationBuilder.BuildExportRelations(AGraph: TDumpRelationGraph);
begin
  // One target relation is produced per RVA-bearing export, even if its RVA
  // cannot be placed in a section.  This preserves incomplete TDUMP evidence.
  for var LExport in AGraph.Document.ExportList do
    if LExport.HasRVA then
    begin
      var LRelation := TDumpExportTargetRelation.Create;
      LRelation.ExportEntry := LExport;
      if AGraph.TryResolveRVA(LExport.RVA, LRelation.Location) then
      begin
        LRelation.ProcedureRecord := FindProcedureForAddress(AGraph.Document,
          LRelation.Location.Segment, LRelation.Location.Offset);
        if LRelation.ProcedureRecord = nil then
          LRelation.ProcedureReference := FindProcedureReferenceForAddress(
            AGraph.Document, LRelation.Location.Segment, LRelation.Location.Offset);
        LRelation.Evidence := reAddressDerived;
      end
      else
        LRelation.Evidence := reExplicit;
      AGraph.ExportTargetRelations.Add(LRelation);

      // Alias groups expose alternate public names for one implementation RVA.
      // Build them only for duplicates to keep the graph compact and meaningful.
      var LAliasGroup: TDumpExportAliasGroup := nil;
      for var LExistingGroup in AGraph.ExportAliasGroups do
        if LExistingGroup.RVA = LExport.RVA then
        begin
          LAliasGroup := LExistingGroup;
          Break;
        end;
      if LAliasGroup = nil then
      begin
        var LMatchCount := 0;
        for var LCandidate in AGraph.Document.ExportList do
          if LCandidate.HasRVA and (LCandidate.RVA = LExport.RVA) then
            Inc(LMatchCount);
        if LMatchCount > 1 then
        begin
          LAliasGroup := TDumpExportAliasGroup.Create;
          LAliasGroup.RVA := LExport.RVA;
          AGraph.ExportAliasGroups.Add(LAliasGroup);
        end;
      end;
      if LAliasGroup <> nil then
        LAliasGroup.Entries.Add(LExport);
    end;
end;

procedure TDumpRelationBuilder.BuildProcedureScopeRelations(
  AGraph: TDumpRelationGraph);
begin
  // EndOffset and NextOffset are stored relative to the subsection file base,
  // whereas parser RecordOffset is absolute within the TDUMP symbol stream.
  for var LAlignSection in AGraph.Document.AlignSymbolSections do
    for var LProcedure in LAlignSection.Records do
      if (LProcedure.Kind = bsrkProcedure) and LProcedure.HasScopeOffsets then
      begin
        var LRelation := TDumpProcedureScopeRelation.Create;
        LRelation.ProcedureRecord := LProcedure;
        LRelation.AlignSection := LAlignSection;
        if LProcedure.EndOffset <> 0 then
          LRelation.EndRecord := FindAlignRecordAtOffset(LAlignSection,
            LAlignSection.FileOffset + LProcedure.EndOffset);
        if LProcedure.NextOffset <> 0 then
          LRelation.NextRecord := FindAlignRecordAtOffset(LAlignSection,
            LAlignSection.FileOffset + LProcedure.NextOffset);
        // Keep a partial scope relation: truncated TDUMP output may expose only
        // one target, and that surviving structural edge remains useful.
        if (LRelation.EndRecord <> nil) or (LRelation.NextRecord <> nil) then
        begin
          LRelation.Evidence := reExplicit;
          AGraph.ProcedureScopeRelations.Add(LRelation);
        end
        else
          LRelation.Free;
      end;
end;

procedure TDumpRelationBuilder.BuildDataDefinitionRelations(
  AGraph: TDumpRelationGraph);
begin
  // Address alone can collide in imperfect dumps.  Requiring the display name
  // as well avoids tying unrelated storage records to the global-symbol index.
  for var LAlignSection in AGraph.Document.AlignSymbolSections do
    for var LDefinition in LAlignSection.Records do
      if (LDefinition.Kind = bsrkGlobalData) and LDefinition.HasAddress then
        for var LGlobalSection in AGraph.Document.GlobalSymbolSections do
          for var LGlobalRecord in LGlobalSection.Records do
            if (LGlobalRecord.Kind = bsrkGlobalData) and LGlobalRecord.HasAddress and
              (LGlobalRecord.Segment = LDefinition.Segment) and
              (LGlobalRecord.Address = LDefinition.Address) and
              SameText(RecordDisplayName(LGlobalRecord),
                RecordDisplayName(LDefinition)) then
            begin
              var LRelation := TDumpDataDefinitionRelation.Create;
              LRelation.DefinitionRecord := LDefinition;
              LRelation.GlobalRecord := LGlobalRecord;
              AGraph.TryResolveAddress(LDefinition.Segment, LDefinition.Address,
                LRelation.Location);
              LRelation.Evidence := reExplicit;
              AGraph.DataDefinitionRelations.Add(LRelation);
              Break;
            end;
end;

procedure TDumpRelationBuilder.BuildResourceLocationRelations(
  AGraph: TDumpRelationGraph);
begin
  // The resource tree contains containers as well as data leaves; the recursive
  // helper emits only the nodes that actually declare an RVA.
  for var LResource in AGraph.Document.Resources do
    AddResourceLocationRelations(AGraph, LResource, '');
end;

end.
