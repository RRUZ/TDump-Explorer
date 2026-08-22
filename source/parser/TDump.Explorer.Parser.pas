//**************************************************************************************************
//
// Unit TDump.Explorer.Parser
// unit for TDump Explorer project
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.Parser;

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.Classes,
  System.Generics.Collections;

type
  TDumpToolKind = (tkUnknown, tkTDump32, tkTDump64);
  TDumpFileKind = (dfUnknown, dfDOS, dfNE, dfLE, dfPE, dfOMFObject,
    dfCOFFObject, dfOMFLibrary, dfELFObject, dfELFArchive, dfMach, dfRawHex,
    dfASCII);
  TDumpNodeKind = (nkDocument, nkHeader, nkDataDirectory, nkSections,
    nkImports, nkExports, nkResources, nkRelocations, nkDebug, nkSymbols,
    nkLines, nkLibrary, nkLibraryMember, nkObjectRecord, nkStrings,
    nkDisassembly, nkHexDump, nkUnknown);
  TDumpValueKind = (vkUnknown, vkText, vkUInt, vkAddress, vkRVA, vkFileOffset,
    vkOrdinal, vkSize);
  TDumpDiagnosticSeverity = (dsInfo, dsWarning, dsError);
  TDumpParserProgressPhase = (ppPreparing, ppLineCatalog, ppSemanticModel,
    ppBorlandSymbols, ppComplete);
  TDumpUnsupportedStructureKind = (uskUnknownHeading, uskUnknownSection,
    uskHeaderLine, uskDataDirectoryRow, uskObjectTableRow,
    uskImportSectionLine, uskImportEntry);
  TDumpSymbolKind = (skUnknown, skFunction, skData, skType, skConstant,
    skReference);
  TDumpBorlandSymbolRecordKind = (bsrkUnknown, bsrkSearch, bsrkProcedure,
    bsrkBasePointerLocal, bsrkRegisterLocal, bsrkOptimizedLocal, bsrkEnd,
    bsrkGlobalData, bsrkLocalData, bsrkProcedureReference, bsrkConstant,
    bsrkUserType, bsrkCompile, bsrkNamespace, bsrkUses, bsrkUsing);
  TDumpLineKind = (tlkBlank, tlkMetadata, tlkHeader, tlkDataDirectory,
    tlkSection, tlkImport, tlkExport, tlkResource, tlkBorlandSubsection,
    tlkBorlandRecord, tlkBorlandDetail, tlkGlobalType, tlkGlobalTypeDetail,
    tlkNameEntry, tlkSeparator, tlkHeaderDetail, tlkDataDirectoryDetail,
    tlkObjectTable, tlkObjectTableDetail, tlkImportDetail, tlkExportDetail,
    tlkResourceDetail, tlkModuleDetail, tlkSourceModuleDetail,
    tlkGlobalSymbolDetail, tlkText, tlkUnknown);

  TDumpGlobalTypeRecord = class;
  TDumpGlobalTypeMember = class;
  TDumpGlobalTypeDetail = class;
  TDumpLine = class;
  TDumpNode = class;

  // Reports parser progress in source-line units for long-running consumers.
  // The callback is optional and receives only throttled, monotonic updates.
  TDumpParserProgressEvent = reference to procedure(
    APhase: TDumpParserProgressPhase; ACompletedLines, ATotalLines: Integer);

  // Represents one named TDUMP value in both raw and normalized forms.
  // StartLine lets callers trace the projection back to the original input.
  TDumpProperty = record
    Name: string;
    RawValue: string;
    ValueKind: TDumpValueKind;
    UIntValue: UInt64;
    HasUIntValue: Boolean;
    TextValue: string;
    StartLine: Integer;
  end;

  // Describes a parser observation without discarding the original source line.
  // Diagnostics are intentionally separate from unsupported-structure findings.
  TDumpDiagnostic = record
    Severity: TDumpDiagnosticSeverity;
    LineNumber: Integer;
    Message: string;
    RawLine: string;
  end;

  // Represents input with no supported semantic model yet.
  // SourceLine and Node retain navigation to document-owned lossless content.
  TDumpUnsupportedStructure = class
  public
    Kind: TDumpUnsupportedStructureKind;
    Description: string;
    SourceLine: TDumpLine;
    Node: TDumpNode;
  end;

  // Provides the typed lexical projection of one physical source line.
  // RawText remains document-owned; this model stores tokens and properties only.
  TDumpLine = class
  public
    LineNumber: Integer;
    Indent: Integer;
    Kind: TDumpLineKind;
    Tokens: TList<string>;
    Properties: TList<TDumpProperty>;
    constructor Create;
    destructor Destroy; override;
  end;

  // Identifies one entry in the Borland subsection directory.
  // Both normalized offsets and their original hexadecimal text are retained.
  TDumpSymbolSubsection = record
    ModIndex: Integer;
    FileOffset: UInt64;
    Size: UInt64;
    SubsectionType: string;
    RawModIndex: string;
    RawFileOffset: string;
    RawSize: string;
    StartLine: Integer;
  end;

  // Describes one segment range belonging to an sstModule record.
  // The raw fields preserve TDUMP's original numeric representation.
  TDumpSymbolModuleSegment = record
    Segment: UInt64;
    StartOffset: UInt64;
    EndOffset: UInt64;
    Flags: UInt64;
    RawSegment: string;
    RawStartOffset: string;
    RawEndOffset: string;
    RawFlags: string;
    StartLine: Integer;
  end;

  // Maps a source line number to a generated-code offset within a range.
  // It is used by sstSrcModule source-file and source-range projections.
  TDumpSourceLineInfo = record
    LineNumber: Integer;
    Offset: UInt64;
    RawLineNumber: string;
    RawOffset: string;
    StartLine: Integer;
  end;

  // Represents one PE data-directory row with its RVA and size.
  // Raw values allow callers to retain the dump's formatting and ambiguity.
  TDumpDataDirectory = record
    Index: Integer;
    Name: string;
    RVA: UInt64;
    Size: UInt64;
    RawRVA: string;
    RawSize: string;
    StartLine: Integer;
  end;

  // Forms the generic, hierarchical TDUMP document tree.
  // Specialized models reference nodes while nodes own child structure and raw text.
  TDumpNode = class
  public
    Kind: TDumpNodeKind;
    Title: string;
    StartLine: Integer;
    EndLine: Integer;
    Properties: TList<TDumpProperty>;
    Children: TObjectList<TDumpNode>;
    RawText: string;
    constructor Create;
    destructor Destroy; override;
  end;

  // Groups parsed properties for one executable-header region.
  // The line span identifies the header's exact location in the TDUMP source.
  TDumpHeader = class
  public
    Name: string;
    Properties: TList<TDumpProperty>;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Represents one PE object-table section with layout and flag metadata.
  // Properties preserve additional TDUMP fields that do not have dedicated members.
  TDumpSection = class
  public
    Index: Integer;
    Name: string;
    RVA: UInt64;
    VirtualSize: UInt64;
    RawOffset: UInt64;
    RawSize: UInt64;
    FlagsValue: UInt64;
    FlagsText: string;
    Properties: TList<TDumpProperty>;
    StartLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Represents one imported symbol, by name or ordinal, from a module.
  // It retains parsed addressing data and the original TDUMP row text.
  TDumpImport = class
  public
    Name: string;
    Ordinal: UInt64;
    HasOrdinal: Boolean;
    Hint: UInt64;
    HasHint: Boolean;
    RVA: UInt64;
    HasRVA: Boolean;
    Address: UInt64;
    HasAddress: Boolean;
    MangledName: string;
    DemangledName: string;
    RawText: string;
    StartLine: Integer;
  end;

  // Owns all import entries emitted for one imported module.
  // The source span covers the module heading and its associated rows.
  TDumpImportModule = class
  public
    Name: string;
    Entries: TObjectList<TDumpImport>;
    Properties: TList<TDumpProperty>;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Represents one exported symbol with ordinal, hint, RVA, or forwarding data.
  // Properties and RawText retain output not covered by the normalized fields.
  TDumpExport = class
  public
    Name: string;
    Ordinal: UInt64;
    HasOrdinal: Boolean;
    Hint: UInt64;
    HasHint: Boolean;
    RVA: UInt64;
    HasRVA: Boolean;
    ForwardedTo: string;
    MangledName: string;
    DemangledName: string;
    Properties: TList<TDumpProperty>;
    RawText: string;
    StartLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Holds the non-row metadata shared by PE Section: reports.
  // Import, export, and resource section projections each reference one instance.
  TDumpSectionMetadata = class
  public
    Name: string;
    FileOffset: UInt64;
    RawFileOffset: string;
    HasFileOffset: Boolean;
    RootNamedEntryCount: UInt64;
    RootIdEntryCount: UInt64;
    HasRootDirectoryCounts: Boolean;
    Properties: TList<TDumpProperty>;
    Node: TDumpNode;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Models one resource directory or leaf while preserving its hierarchy.
  // Directory counts and data metadata are present only when TDUMP emits them.
  TDumpResource = class
  public
    Name: string;
    ResourceType: string;
    Id: UInt64;
    HasId: Boolean;
    Language: string;
    RawLanguage: string;
    RVA: UInt64;
    HasRVA: Boolean;
    FileOffset: UInt64;
    HasFileOffset: Boolean;
    Size: UInt64;
    HasSize: Boolean;
    DirectoryOffset: UInt64;
    HasDirectoryOffset: Boolean;
    NamedEntryCount: UInt64;
    IdEntryCount: UInt64;
    HasDirectoryCounts: Boolean;
    DataOffset: UInt64;
    HasDataOffset: Boolean;
    CodePage: UInt64;
    HasCodePage: Boolean;
    Reserved: UInt64;
    HasReserved: Boolean;
    Properties: TList<TDumpProperty>;
    Children: TObjectList<TDumpResource>;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Represents a normalized symbol projected from a Borland S_* record.
  // It supplies a compact document-level view alongside the detailed record models.
  TDumpSymbol = class
  public
    Name: string;
    MangledName: string;
    DemangledName: string;
    Kind: TDumpSymbolKind;
    Address: UInt64;
    HasAddress: Boolean;
    SectionName: string;
    RecordKind: string;
    Properties: TList<TDumpProperty>;
    RawText: string;
    StartLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Models an sstModule body and its declared segment ranges.
  // Name-table resolution is retained separately from the original name index.
  TDumpSymbolModule = class
  public
    ModIndex: Integer;
    FileOffset: UInt64;
    OvlNum: UInt64;
    LibIndex: UInt64;
    SegCount: UInt64;
    Time: UInt64;
    Name: string;
    NameIndex: UInt64;
    RawNameIndex: string;
    HasNameIndex: Boolean;
    ResolvedName: string;
    Properties: TList<TDumpProperty>;
    Segments: TList<TDumpSymbolModuleSegment>;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Represents a segment/address range used by Borland source debug information.
  // LineNumbers maps the range back to source lines where TDUMP provides them.
  TDumpSourceRange = class
  public
    Segment: UInt64;
    StartOffset: UInt64;
    EndOffset: UInt64;
    RawSegment: string;
    RawStartOffset: string;
    RawEndOffset: string;
    LineNumbers: TList<TDumpSourceLineInfo>;
    StartLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Models one source file within an sstSrcModule subsection.
  // Its ranges and optional name-table resolution remain linked to source records.
  TDumpSourceFile = class
  public
    Name: string;
    NameIndex: UInt64;
    RawNameIndex: string;
    HasNameIndex: Boolean;
    ResolvedName: string;
    Offset: UInt64;
    RawOffset: string;
    Ranges: TObjectList<TDumpSourceRange>;
    StartLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Owns source-file and segment-range data from one sstSrcModule body.
  // ModIndex and FileOffset link it to the Borland subsection directory.
  TDumpSourceModule = class
  public
    ModIndex: Integer;
    FileOffset: UInt64;
    SegmentRanges: TObjectList<TDumpSourceRange>;
    SourceFiles: TObjectList<TDumpSourceFile>;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Captures S_SSEARCH lookup metadata for an alignment-symbol subsection.
  // It references the generic node rather than duplicating the original record text.
  TDumpSymbolSearch = class
  public
    RecordOffset: UInt64;
    RawRecordOffset: string;
    Segment: UInt64;
    RawSegment: string;
    Address: UInt64;
    RawAddress: string;
    CodeSymbols: UInt64;
    RawCodeSymbols: string;
    DataSymbols: UInt64;
    RawDataSymbols: string;
    FirstData: UInt64;
    RawFirstData: string;
    Node: TDumpNode;
    StartLine: Integer;
  end;

  // Stores decoded fields for one Borland S_* record.
  // The associated node remains the raw-text owner and scope links avoid duplication.
  TDumpBorlandSymbolRecord = class
  public
    RecordOffset: UInt64;
    RawRecordOffset: string;
    RecordKind: string;
    Kind: TDumpBorlandSymbolRecordKind;
    TypeIndex: UInt64;
    RawTypeIndex: string;
    HasTypeIndex: Boolean;
    TypeRecord: TDumpGlobalTypeRecord;
    Name: string;
    NameIndex: UInt64;
    RawNameIndex: string;
    HasNameIndex: Boolean;
    ResolvedName: string;
    NameIndices: TList<UInt64>;
    ResolvedNames: TList<string>;
    Segment: UInt64;
    RawSegment: string;
    Address: UInt64;
    RawAddress: string;
    HasAddress: Boolean;
    EndAddress: UInt64;
    RawEndAddress: string;
    HasEndAddress: Boolean;
    ParentOffset: UInt64;
    EndOffset: UInt64;
    NextOffset: UInt64;
    HasScopeOffsets: Boolean;
    Value: string;
    Properties: TList<TDumpProperty>;
    Node: TDumpNode;
    ScopeParent: TDumpBorlandSymbolRecord;
    ScopeChildren: TList<TDumpBorlandSymbolRecord>;
    HeaderLine: TDumpLine;
    DetailLines: TList<TDumpLine>;
    ScopeDepth: Integer;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Marks a Borland symbol record owned by an sstAlignSym subsection.
  // Its base class supplies the common decoded fields and source relationships.
  TDumpAlignSymbolRecord = class(TDumpBorlandSymbolRecord)
  end;

  // Marks a Borland symbol record owned by an sstGlobalSym subsection.
  // Its base class supplies the common decoded fields while the node owns raw text.
  TDumpGlobalSymbolRecord = class(TDumpBorlandSymbolRecord)
  end;

  // Groups global Borland symbols and their section-level counters or hashes.
  // The generic node retains the full subsection body for lossless navigation.
  TDumpGlobalSymbolSection = class
  public
    Node: TDumpNode;
    ModIndex: Integer;
    FileOffset: UInt64;
    Records: TObjectList<TDumpGlobalSymbolRecord>;
    Properties: TList<TDumpProperty>;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Indexes an sstGlobalTypes type block while its node owns the original text.
  TDumpGlobalTypeMemberKind = (gtmkMember, gtmkEnumerator);

  // Categorizes a continuation row belonging to an sstGlobalTypes record.
  // The value distinguishes layout, pointer, procedure, and member detail rows.
  TDumpGlobalTypeDetailKind = (gtdkUnknown, gtdkPointerAttributes,
    gtdkPointerTarget, gtdkProcedureSignature, gtdkProcedureParameters,
    gtdkArgumentType, gtdkAggregateLayout, gtdkArrayLayout,
    gtdkSubrangeLayout, gtdkStringLayout, gtdkNamedType, gtdkMember);

  // Decodes one non-blank sstGlobalTypes continuation row.
  // It links to the source line and keeps typed properties without copying raw text.
  TDumpGlobalTypeDetail = class
  public
    Kind: TDumpGlobalTypeDetailKind;
    SourceLine: TDumpLine;
    Properties: TList<TDumpProperty>;
    TypeText: string;
    TypeIndex: UInt64;
    HasTypeIndex: Boolean;
    RelatedTypeText: string;
    RelatedTypeIndex: UInt64;
    HasRelatedTypeIndex: Boolean;
    CallingConvention: string;
    ReturnType: string;
    PointerFlavor: string;
    PointerType: string;
    PointerMode: string;
    constructor Create;
    destructor Destroy; override;
  end;

  // Represents a FIELDLIST MEMBER or ENUMERATE row in the global type table.
  // Type/name references are retained in raw and resolved forms where available.
  TDumpGlobalTypeMember = class
  public
    Kind: TDumpGlobalTypeMemberKind;
    TypeIndex: UInt64;
    RawTypeIndex: string;
    HasTypeIndex: Boolean;
    Offset: UInt64;
    RawOffset: string;
    HasOffset: Boolean;
    Value: UInt64;
    RawValue: string;
    HasValue: Boolean;
    Access: string;
    Name: string;
    NameIndex: UInt64;
    RawNameIndex: string;
    HasNameIndex: Boolean;
    ResolvedName: string;
    SourceLine: TDumpLine;
  end;

  // Models one sstGlobalTypes block, including references, details, and members.
  // HeaderLine and DetailLines identify the exact lossless source span.
  TDumpGlobalTypeRecord = class
  public
    RecordOffset: UInt64;
    RawRecordOffset: string;
    TypeIndex: UInt64;
    RawTypeIndex: string;
    Length: UInt64;
    RawLength: string;
    TypeKind: string;
    Name: string;
    NameIndex: UInt64;
    RawNameIndex: string;
    HasNameIndex: Boolean;
    ResolvedName: string;
    Properties: TList<TDumpProperty>;
    ReferencedTypeIndices: TList<UInt64>;
    ReferencedTypes: TList<TDumpGlobalTypeRecord>;
    Members: TObjectList<TDumpGlobalTypeMember>;
    Details: TObjectList<TDumpGlobalTypeDetail>;
    HeaderLine: TDumpLine;
    DetailLines: TList<TDumpLine>;
    Node: TDumpNode;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Owns all global type records from a single sstGlobalTypes subsection.
  // TypeCount records the subsection's declared count independently of parsed rows.
  TDumpGlobalTypeSection = class
  public
    Node: TDumpNode;
    ModIndex: Integer;
    FileOffset: UInt64;
    TypeCount: UInt64;
    RawTypeCount: string;
    Records: TObjectList<TDumpGlobalTypeRecord>;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Groups symbols, searches, and S_* records from one sstAlignSym subsection.
  // The specialized collections provide both compact and detailed symbol access.
  TDumpAlignSymbolSection = class
  public
    ModIndex: Integer;
    FileOffset: UInt64;
    Symbols: TList<TDumpSymbol>;
    Searches: TList<TDumpSymbolSearch>;
    Records: TObjectList<TDumpAlignSymbolRecord>;
    StartLine: Integer;
    EndLine: Integer;
    constructor Create;
    destructor Destroy; override;
  end;

  // Provides a common projection for every observed Borland sst* subsection body.
  // Node and source lines keep the generic hierarchy available for future models.
  TDumpBorlandSubsection = class
  public
    ModIndex: Integer;
    FileOffset: UInt64;
    SubsectionType: string;
    Node: TDumpNode;
    StartLine: Integer;
    EndLine: Integer;
  end;

  // Stores one index/value pair from the shared Borland sstNames table.
  // Other models resolve their name indexes through the document lookup dictionary.
  TDumpBorlandName = record
    Index: UInt64;
    RawIndex: string;
    Value: string;
    StartLine: Integer;
  end;

  // Owns the complete parsed TDUMP result and its lossless original text.
  // Specialized collections project supported data while diagnostics report tolerance issues.
  TDumpDocument = class
  public
    SourceFileName: string;
    ToolKind: TDumpToolKind;
    ToolVersion: string;
    CommandLine: string;
    FileKind: TDumpFileKind;
    Architecture: string;
    RawText: string;
    Lines: TObjectList<TDumpLine>;
    Headers: TObjectList<TDumpHeader>;
    DataDirectories: TList<TDumpDataDirectory>;
    Sections: TObjectList<TDumpSection>;
    Imports: TObjectList<TDumpImportModule>;
    ExportList: TObjectList<TDumpExport>;
    ImportMetadata: TDumpSectionMetadata;
    ExportMetadata: TDumpSectionMetadata;
    ResourceMetadata: TDumpSectionMetadata;
    Resources: TObjectList<TDumpResource>;
    Symbols: TObjectList<TDumpSymbol>;
    SymbolSubsections: TList<TDumpSymbolSubsection>;
    SymbolModules: TObjectList<TDumpSymbolModule>;
    SourceModules: TObjectList<TDumpSourceModule>;
    AlignSymbolSections: TObjectList<TDumpAlignSymbolSection>;
    SymbolSearches: TObjectList<TDumpSymbolSearch>;
    GlobalSymbolSections: TObjectList<TDumpGlobalSymbolSection>;
    GlobalTypeSections: TObjectList<TDumpGlobalTypeSection>;
    BorlandSubsections: TObjectList<TDumpBorlandSubsection>;
    BorlandNames: TList<TDumpBorlandName>;
    BorlandNameLookup: TDictionary<UInt64, string>;
    Nodes: TObjectList<TDumpNode>;
    Diagnostics: TList<TDumpDiagnostic>;
    UnsupportedStructures: TObjectList<TDumpUnsupportedStructure>;
    constructor Create;
    destructor Destroy; override;
  end;

  // Parses TDUMP text into a lossless document plus typed semantic projections.
  // Individual malformed rows remain recoverable through diagnostics and generic models.
  TDumpParser = class
  private
    FLines: TStringList;
    FDocument: TDumpDocument;
    FOnProgress: TDumpParserProgressEvent;
    FLastProgressPhase: TDumpParserProgressPhase;
    FLastProgressLine: Integer;
    function AddNode(AKind: TDumpNodeKind; const ATitle: string;
      AStartLine, AEndLine: Integer): TDumpNode;
    procedure AddDiagnostic(ASeverity: TDumpDiagnosticSeverity;
      ALineNumber: Integer; const AMessage, ARawLine: string);
    procedure AddUnsupportedStructure(AKind: TDumpUnsupportedStructureKind;
      ALineNumber: Integer; const ADescription: string);
    procedure DetectUnsupportedStructures;
    procedure ReportProgress(APhase: TDumpParserProgressPhase;
      ACompletedLines: Integer);
    procedure ParseMetadata;
    procedure ParseOldExecutableHeader;
    procedure ParsePortableExecutableHeader;
    procedure ParseObjectTable;
    procedure ParseImportSection;
    procedure ParseExportSection;
    procedure ParseResourceSection;
    procedure ParseBorlandSymbolTable;
    procedure BuildLineCatalog;
    function ClassifyTDumpLine(const ALine: string): TDumpLineKind;
    function IsKnownTopLevelHeading(const ALine: string): Boolean;
    function TryParsePropertyLine(const ALine: string; ALineNumber: Integer;
      out AProperty: TDumpProperty): Boolean;
    function TryParseDataDirectoryLine(const ALine: string; ALineNumber: Integer;
      AIndex: Integer; out ADirectory: TDumpDataDirectory; out AProperty: TDumpProperty): Boolean;
    function TryParseObjectTableLine(const ALine: string; ALineNumber: Integer;
      out ASection: TDumpSection; out AProperty: TDumpProperty): Boolean;
    function TryParseImportLine(const ALine: string; ALineNumber: Integer;
      out AImport: TDumpImport): Boolean;
    function TryParseExportLine(const ALine: string; ALineNumber: Integer;
      out AExport: TDumpExport): Boolean;
    function TryParseResourceLine(const ALine: string; ALineNumber: Integer;
      out AIndent: Integer; out AResource: TDumpResource): Boolean;
    function TryParseBorlandSymbolLine(const ARecordKind, ALine: string;
      ALineNumber: Integer; out ASymbol: TDumpSymbol): Boolean;
    function TryParseBorlandSymbolSearchLine(const ALine: string;
      ALineNumber: Integer; out ASearch: TDumpSymbolSearch): Boolean;
    function TryParseBorlandGlobalTypeLine(const ALine: string;
      ALineNumber: Integer; out ATypeRecord: TDumpGlobalTypeRecord): Boolean;
    procedure ParseBorlandSymbolRecordDetails(
      ARecord: TDumpBorlandSymbolRecord; const ALine: string;
      ALineNumber: Integer);
    procedure ParseBorlandGlobalTypeDetails(AGlobalType: TDumpGlobalTypeRecord;
      const ALine: string; ALineNumber: Integer);
    procedure ResolveBorlandReferences;
    function TryParseBorlandSubsectionDirectoryLine(const ALine: string;
      ALineNumber: Integer; out ASubsection: TDumpSymbolSubsection): Boolean;
    function TryParseBorlandSubsectionHeader(const ALine: string;
      out AModIndex: Integer; out AFileOffset: UInt64;
      out ASubsectionType: string): Boolean;
    function TryParseBorlandModuleSegmentLine(const ALine: string;
      ALineNumber: Integer; out ASegment: TDumpSymbolModuleSegment): Boolean;
    function TryParseBorlandSourceRangeLine(const ALine: string;
      ALineNumber: Integer; out ARange: TDumpSourceRange): Boolean;
    function TryParseBorlandSourceFileLine(const ALine: string;
      ALineNumber: Integer; out ASourceFile: TDumpSourceFile): Boolean;
    procedure AddBorlandSourceLinePairs(const ALine: string; ALineNumber: Integer;
      ARange: TDumpSourceRange);
    function BorlandSymbolKind(const ARecordKind: string): TDumpSymbolKind;
    function BorlandSymbolRecordKind(
      const ARecordKind: string): TDumpBorlandSymbolRecordKind;
    function TryParseUIntToken(const AToken: string; out AValue: UInt64): Boolean;
    function TryParseHexUIntToken(const AToken: string; out AValue: UInt64): Boolean;
    function PropertyValueKind(const AName: string): TDumpValueKind;
  public
    constructor Create;
    destructor Destroy; override;
    property OnProgress: TDumpParserProgressEvent read FOnProgress
      write FOnProgress;
    function ParseText(const AText: string; const ASourceFileName: string = ''): TDumpDocument;
    function ParseFile(const AFileName: string): TDumpDocument;
  end;

implementation

const
  SOldExecutableHeader = 'Old Executable Header';
  SPortableExecutableHeader = 'Portable Executable (PE) File';
  SGlobalSymbolHeaderLabels: array[0..8] of string = ('cbSymbols:',
    'cNamespaces:', 'cUDTs:', 'cOthers:', 'Total:', 'SymHash:',
    'cbSymHash:', 'AddrHash:', 'cbAddrHash:');

// Keep token parsing independent of TDUMP's whitespace-aligned columns.
function NormalizeLineBreaks(const S: string): string;
begin
  Result := StringReplace(S, #13#10, #10, [rfReplaceAll]);
  Result := StringReplace(Result, #13, #10, [rfReplaceAll]);
end;

function TrimRightWhitespace(const S: string): string;
begin
  Result := S;
  while (Result <> '') and CharInSet(Result[Length(Result)], [#9, #10, #13, ' ']) do
    Delete(Result, Length(Result), 1);
end;

function LastToken(var S: string): string;
begin
  var LIndex: Integer;
  S := TrimRight(S);
  LIndex := Length(S);
  while (LIndex > 0) and not CharInSet(S[LIndex], [' ', #9]) do
    Dec(LIndex);
  Result := Copy(S, LIndex + 1, MaxInt);
  S := TrimRight(Copy(S, 1, LIndex));
end;

function FirstToken(var S: string): string;
begin
  var LIndex: Integer;
  S := TrimLeft(S);
  LIndex := 1;
  while (LIndex <= Length(S)) and not CharInSet(S[LIndex], [' ', #9]) do
    Inc(LIndex);
  Result := Copy(S, 1, LIndex - 1);
  S := TrimLeft(Copy(S, LIndex, MaxInt));
end;

function StartsWithText(const S, Prefix: string): Boolean;
begin
  Result := SameText(Copy(S, 1, Length(Prefix)), Prefix);
end;

procedure AppendNodeRawLine(const ANode: TDumpNode; const ALine: string);
begin
  if ANode.RawText <> '' then
    ANode.RawText := ANode.RawText + sLineBreak;
  ANode.RawText := ANode.RawText + ALine;
end;

function ValueForLabel(const ALine, ALabel: string): string;
begin
  var LLabelPos := Pos(ALabel, ALine);
  if LLabelPos = 0 then
    Exit('');
  var LValueText := Copy(ALine, LLabelPos + Length(ALabel), MaxInt);
  Result := FirstToken(LValueText);
end;

{ TDumpNode }

constructor TDumpNode.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
  Children := TObjectList<TDumpNode>.Create(True);
end;

destructor TDumpNode.Destroy;
begin
  Children.Free;
  Properties.Free;
  inherited;
end;

{ TDumpLine }

constructor TDumpLine.Create;
begin
  inherited Create;
  Tokens := TList<string>.Create;
  Properties := TList<TDumpProperty>.Create;
end;

destructor TDumpLine.Destroy;
begin
  Properties.Free;
  Tokens.Free;
  inherited;
end;

{ TDumpHeader }

constructor TDumpHeader.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
end;

destructor TDumpHeader.Destroy;
begin
  Properties.Free;
  inherited;
end;

{ TDumpSection }

constructor TDumpSection.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
end;

destructor TDumpSection.Destroy;
begin
  Properties.Free;
  inherited;
end;

{ TDumpImportModule }

constructor TDumpImportModule.Create;
begin
  inherited Create;
  Entries := TObjectList<TDumpImport>.Create(True);
  Properties := TList<TDumpProperty>.Create;
end;

destructor TDumpImportModule.Destroy;
begin
  Properties.Free;
  Entries.Free;
  inherited;
end;

{ TDumpExport }

constructor TDumpExport.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
end;

destructor TDumpExport.Destroy;
begin
  Properties.Free;
  inherited;
end;

{ TDumpSectionMetadata }

constructor TDumpSectionMetadata.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
end;

destructor TDumpSectionMetadata.Destroy;
begin
  Properties.Free;
  inherited;
end;

{ TDumpResource }

constructor TDumpResource.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
  Children := TObjectList<TDumpResource>.Create(True);
end;

destructor TDumpResource.Destroy;
begin
  Children.Free;
  Properties.Free;
  inherited;
end;

{ TDumpSymbol }

constructor TDumpSymbol.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
end;

destructor TDumpSymbol.Destroy;
begin
  Properties.Free;
  inherited;
end;

{ TDumpSymbolModule }

constructor TDumpSymbolModule.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
  Segments := TList<TDumpSymbolModuleSegment>.Create;
end;

destructor TDumpSymbolModule.Destroy;
begin
  Segments.Free;
  Properties.Free;
  inherited;
end;

{ TDumpSourceRange }

constructor TDumpSourceRange.Create;
begin
  inherited Create;
  LineNumbers := TList<TDumpSourceLineInfo>.Create;
end;

destructor TDumpSourceRange.Destroy;
begin
  LineNumbers.Free;
  inherited;
end;

{ TDumpSourceFile }

constructor TDumpSourceFile.Create;
begin
  inherited Create;
  Ranges := TObjectList<TDumpSourceRange>.Create(True);
end;

destructor TDumpSourceFile.Destroy;
begin
  Ranges.Free;
  inherited;
end;

{ TDumpSourceModule }

constructor TDumpSourceModule.Create;
begin
  inherited Create;
  SegmentRanges := TObjectList<TDumpSourceRange>.Create(True);
  SourceFiles := TObjectList<TDumpSourceFile>.Create(True);
end;

destructor TDumpSourceModule.Destroy;
begin
  SourceFiles.Free;
  SegmentRanges.Free;
  inherited;
end;

{ TDumpBorlandSymbolRecord }

constructor TDumpBorlandSymbolRecord.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
  ScopeChildren := TList<TDumpBorlandSymbolRecord>.Create;
  NameIndices := TList<UInt64>.Create;
  ResolvedNames := TList<string>.Create;
  DetailLines := TList<TDumpLine>.Create;
end;

destructor TDumpBorlandSymbolRecord.Destroy;
begin
  ScopeChildren.Free;
  ResolvedNames.Free;
  NameIndices.Free;
  DetailLines.Free;
  Properties.Free;
  inherited;
end;

{ TDumpGlobalSymbolSection }

constructor TDumpGlobalSymbolSection.Create;
begin
  inherited Create;
  Records := TObjectList<TDumpGlobalSymbolRecord>.Create(True);
  Properties := TList<TDumpProperty>.Create;
end;

destructor TDumpGlobalSymbolSection.Destroy;
begin
  Properties.Free;
  Records.Free;
  inherited;
end;

{ TDumpGlobalTypeDetail }

constructor TDumpGlobalTypeDetail.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
end;

destructor TDumpGlobalTypeDetail.Destroy;
begin
  Properties.Free;
  inherited;
end;

{ TDumpGlobalTypeRecord }

constructor TDumpGlobalTypeRecord.Create;
begin
  inherited Create;
  Properties := TList<TDumpProperty>.Create;
  ReferencedTypeIndices := TList<UInt64>.Create;
  ReferencedTypes := TList<TDumpGlobalTypeRecord>.Create;
  Members := TObjectList<TDumpGlobalTypeMember>.Create(True);
  Details := TObjectList<TDumpGlobalTypeDetail>.Create(True);
  DetailLines := TList<TDumpLine>.Create;
end;

destructor TDumpGlobalTypeRecord.Destroy;
begin
  ReferencedTypes.Free;
  ReferencedTypeIndices.Free;
  Details.Free;
  Members.Free;
  DetailLines.Free;
  Properties.Free;
  inherited;
end;

{ TDumpGlobalTypeSection }

constructor TDumpGlobalTypeSection.Create;
begin
  inherited Create;
  Records := TObjectList<TDumpGlobalTypeRecord>.Create(True);
end;

destructor TDumpGlobalTypeSection.Destroy;
begin
  Records.Free;
  inherited;
end;

{ TDumpAlignSymbolSection }

constructor TDumpAlignSymbolSection.Create;
begin
  inherited Create;
  Symbols := TList<TDumpSymbol>.Create;
  Searches := TList<TDumpSymbolSearch>.Create;
  Records := TObjectList<TDumpAlignSymbolRecord>.Create(True);
end;

destructor TDumpAlignSymbolSection.Destroy;
begin
  Records.Free;
  Searches.Free;
  Symbols.Free;
  inherited;
end;

{ TDumpDocument }

constructor TDumpDocument.Create;
begin
  inherited Create;
  ToolKind := tkUnknown;
  FileKind := dfUnknown;
  Lines := TObjectList<TDumpLine>.Create(True);
  Headers := TObjectList<TDumpHeader>.Create(True);
  DataDirectories := TList<TDumpDataDirectory>.Create;
  Sections := TObjectList<TDumpSection>.Create(True);
  Imports := TObjectList<TDumpImportModule>.Create(True);
  ExportList := TObjectList<TDumpExport>.Create(True);
  ImportMetadata := nil;
  ExportMetadata := nil;
  ResourceMetadata := nil;
  Resources := TObjectList<TDumpResource>.Create(True);
  Symbols := TObjectList<TDumpSymbol>.Create(True);
  SymbolSubsections := TList<TDumpSymbolSubsection>.Create;
  SymbolModules := TObjectList<TDumpSymbolModule>.Create(True);
  SourceModules := TObjectList<TDumpSourceModule>.Create(True);
  AlignSymbolSections := TObjectList<TDumpAlignSymbolSection>.Create(True);
  SymbolSearches := TObjectList<TDumpSymbolSearch>.Create(True);
  GlobalSymbolSections := TObjectList<TDumpGlobalSymbolSection>.Create(True);
  GlobalTypeSections := TObjectList<TDumpGlobalTypeSection>.Create(True);
  BorlandSubsections := TObjectList<TDumpBorlandSubsection>.Create(True);
  BorlandNames := TList<TDumpBorlandName>.Create;
  BorlandNameLookup := TDictionary<UInt64, string>.Create;
  Nodes := TObjectList<TDumpNode>.Create(True);
  Diagnostics := TList<TDumpDiagnostic>.Create;
  UnsupportedStructures := TObjectList<TDumpUnsupportedStructure>.Create(True);
end;

destructor TDumpDocument.Destroy;
begin
  UnsupportedStructures.Free;
  Diagnostics.Free;
  Nodes.Free;
  Lines.Free;
  BorlandNameLookup.Free;
  BorlandNames.Free;
  BorlandSubsections.Free;
  GlobalTypeSections.Free;
  GlobalSymbolSections.Free;
  SymbolSearches.Free;
  AlignSymbolSections.Free;
  SourceModules.Free;
  SymbolModules.Free;
  SymbolSubsections.Free;
  Symbols.Free;
  Resources.Free;
  ResourceMetadata.Free;
  ExportMetadata.Free;
  ImportMetadata.Free;
  ExportList.Free;
  Imports.Free;
  Sections.Free;
  DataDirectories.Free;
  Headers.Free;
  inherited;
end;

{ TDumpParser }

constructor TDumpParser.Create;
begin
  inherited Create;
  FLines := TStringList.Create;
end;

destructor TDumpParser.Destroy;
begin
  FLines.Free;
  inherited;
end;

function TDumpParser.ParseFile(const AFileName: string): TDumpDocument;
begin
  var LText: string;
  var LBytes: TBytes;
  var LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
  try
    SetLength(LBytes, LStream.Size);
    if Length(LBytes) > 0 then
      LStream.ReadBuffer(LBytes[0], Length(LBytes));
  finally
    LStream.Free;
  end;
  LText := TEncoding.Default.GetString(LBytes);
  Result := ParseText(LText, AFileName);
end;

function TDumpParser.ClassifyTDumpLine(const ALine: string): TDumpLineKind;
begin
  var LTrimmed := Trim(ALine);
  if LTrimmed = '' then
    Exit(tlkBlank);
  if StartsWithText(LTrimmed, '---') or StartsWithText(LTrimmed, '***') then
    Exit(tlkSeparator);
  if StartsWithText(LTrimmed, 'Turbo Dump') then
    Exit(tlkMetadata);
  if StartsWithText(LTrimmed, 'Data directory') then
    Exit(tlkDataDirectory);
  if StartsWithText(LTrimmed, 'Object table') then
    Exit(tlkObjectTable);
  if StartsWithText(LTrimmed, 'ModIndex:') then
    Exit(tlkBorlandSubsection);
  if StartsWithText(LTrimmed, 'SubSection Directory') then
    Exit(tlkBorlandSubsection);
  if (Pos(' S_', LTrimmed) > 0) and (Length(LTrimmed) > 5) then
    Exit(tlkBorlandRecord);
  if (Pos(' Type:', LTrimmed) > 0) and (Pos(' Len:', LTrimmed) > 0) then
    Exit(tlkGlobalType);
  if StartsWithText(LTrimmed, 'Type:') or StartsWithText(LTrimmed, 'MEMBER') or
    StartsWithText(LTrimmed, 'ENUMERATE') or StartsWithText(LTrimmed, 'Points to:') then
    Exit(tlkGlobalTypeDetail);
  if (Length(LTrimmed) > 5) and (LTrimmed[5] = ':') then
  begin
    var LNameIndex: UInt64;
    if TryParseHexUIntToken(Copy(LTrimmed, 1, 4), LNameIndex) then
      Exit(tlkNameEntry);
  end;
  if StartsWithText(LTrimmed, 'Section:') then
    Exit(tlkSection);
  if StartsWithText(LTrimmed, 'Imports from ') then
    Exit(tlkImport);
  if StartsWithText(LTrimmed, 'Exports from ') then
    Exit(tlkExport);
  if StartsWithText(LTrimmed, 'type:') or (Pos('named entries', LTrimmed) > 0) then
    Exit(tlkResource);
  if SameText(LTrimmed, SOldExecutableHeader) or
    SameText(LTrimmed, SPortableExecutableHeader) then
    Exit(tlkHeader);
  Result := tlkText;
end;

procedure TDumpParser.BuildLineCatalog;
begin
  var LContextKind := tlkHeaderDetail;
  var LInBorlandTable := False;
  for var LIndex := 0 to FLines.Count - 1 do
  begin
    var LLine := TDumpLine.Create;
    LLine.LineNumber := LIndex + 1;
    while (LLine.Indent < Length(FLines[LIndex])) and
      CharInSet(FLines[LIndex][LLine.Indent + 1], [' ', #9]) do
      Inc(LLine.Indent);
    LLine.Kind := ClassifyTDumpLine(FLines[LIndex]);
    var LTrimmed := Trim(FLines[LIndex]);
    if LLine.Kind = tlkSection then
    begin
      LInBorlandTable := Pos('Borland 32 bit symbol table', LTrimmed) > 0;
      if Pos('Import', LTrimmed) > 0 then
        LContextKind := tlkImportDetail
      else if Pos('Export', LTrimmed) > 0 then
        LContextKind := tlkExportDetail
      else if Pos('Resource', LTrimmed) > 0 then
        LContextKind := tlkResourceDetail
      else if LInBorlandTable then
        LContextKind := tlkBorlandDetail
      else
        LContextKind := tlkHeaderDetail;
    end
    else if LLine.Kind = tlkDataDirectory then
      LContextKind := tlkDataDirectoryDetail
    else if LLine.Kind = tlkObjectTable then
      LContextKind := tlkObjectTableDetail
    else if LLine.Kind = tlkBorlandSubsection then
    begin
      if Pos('sstGlobalTypes', LTrimmed) > 0 then
        LContextKind := tlkGlobalTypeDetail
      else if Pos('sstSrcModule', LTrimmed) > 0 then
        LContextKind := tlkSourceModuleDetail
      else if Pos('sstModule', LTrimmed) > 0 then
        LContextKind := tlkModuleDetail
      else if Pos('sstGlobalSym', LTrimmed) > 0 then
        LContextKind := tlkGlobalSymbolDetail
      else
        LContextKind := tlkBorlandDetail;
    end
    else if (LLine.Kind = tlkText) and LInBorlandTable then
      LLine.Kind := LContextKind
    else if LLine.Kind = tlkText then
      LLine.Kind := LContextKind;
    var LTokenText := Trim(FLines[LIndex]);
    while LTokenText <> '' do
      LLine.Tokens.Add(FirstToken(LTokenText));
    var LProperty: TDumpProperty;
    if TryParsePropertyLine(FLines[LIndex], LLine.LineNumber, LProperty) then
      LLine.Properties.Add(LProperty);
    FDocument.Lines.Add(LLine);
    if Assigned(FOnProgress) then
      ReportProgress(ppLineCatalog, LIndex + 1);
  end;
end;

function TDumpParser.ParseText(const AText: string;
  const ASourceFileName: string): TDumpDocument;
begin
  FDocument := TDumpDocument.Create;
  try
    FDocument.SourceFileName := ASourceFileName;
    FDocument.RawText := AText;
    FLastProgressPhase := ppComplete;
    FLastProgressLine := -1;

    FLines.Text := NormalizeLineBreaks(AText);
    for var LIndex := 0 to FLines.Count - 1 do
      FLines[LIndex] := TrimRightWhitespace(FLines[LIndex]);

    AddNode(nkDocument, 'TDUMP output', 1, FLines.Count).RawText := AText;
    ReportProgress(ppPreparing, 0);
    BuildLineCatalog;

    ReportProgress(ppSemanticModel, 0);
    ParseMetadata;
    ParseOldExecutableHeader;
    ParsePortableExecutableHeader;
    ParseObjectTable;
    ParseImportSection;
    ParseExportSection;
    ParseResourceSection;
    ParseBorlandSymbolTable;
    DetectUnsupportedStructures;
    ReportProgress(ppComplete, FLines.Count);

    Result := FDocument;
    FDocument := nil;
  finally
    FDocument.Free;
  end;
end;

function TDumpParser.AddNode(AKind: TDumpNodeKind; const ATitle: string;
  AStartLine, AEndLine: Integer): TDumpNode;
begin
  Result := TDumpNode.Create;
  Result.Kind := AKind;
  Result.Title := ATitle;
  Result.StartLine := AStartLine;
  Result.EndLine := AEndLine;
  FDocument.Nodes.Add(Result);
end;

procedure TDumpParser.AddDiagnostic(ASeverity: TDumpDiagnosticSeverity;
  ALineNumber: Integer; const AMessage, ARawLine: string);
begin
  var LDiagnostic: TDumpDiagnostic;
  LDiagnostic.Severity := ASeverity;
  LDiagnostic.LineNumber := ALineNumber;
  LDiagnostic.Message := AMessage;
  LDiagnostic.RawLine := ARawLine;
  FDocument.Diagnostics.Add(LDiagnostic);
end;

procedure TDumpParser.ReportProgress(APhase: TDumpParserProgressPhase;
  ACompletedLines: Integer);
begin
  if not Assigned(FOnProgress) then
    Exit;

  var LTotalLines := FLines.Count;
  var LInterval := LTotalLines div 100;
  if LInterval < 1 then
    LInterval := 1;
  if (APhase = FLastProgressPhase) and (ACompletedLines <> LTotalLines) and
    (ACompletedLines <> 0) and
    (ACompletedLines - FLastProgressLine < LInterval) then
    Exit;

  FOnProgress(APhase, ACompletedLines, LTotalLines);
  FLastProgressPhase := APhase;
  FLastProgressLine := ACompletedLines;
end;

procedure TDumpParser.AddUnsupportedStructure(
  AKind: TDumpUnsupportedStructureKind; ALineNumber: Integer;
  const ADescription: string);
begin
  if (ALineNumber < 1) or (ALineNumber > FDocument.Lines.Count) then
    Exit;
  for var LExisting in FDocument.UnsupportedStructures do
    if (LExisting.Kind = AKind) and
      (LExisting.SourceLine.LineNumber = ALineNumber) then
      Exit;

  var LStructure := TDumpUnsupportedStructure.Create;
  LStructure.Kind := AKind;
  LStructure.Description := ADescription;
  LStructure.SourceLine := FDocument.Lines[ALineNumber - 1];
  LStructure.Node := AddNode(nkUnknown, ADescription, ALineNumber, ALineNumber);
  FDocument.UnsupportedStructures.Add(LStructure);
end;

procedure TDumpParser.DetectUnsupportedStructures;
begin
  for var LIndex := 0 to FLines.Count - 1 do
  begin
    var LLine := Trim(FLines[LIndex]);
    if StartsWithText(LLine, 'Section:') then
    begin
      var LSectionName := Trim(Copy(LLine, Length('Section:') + 1, MaxInt));
      if not SameText(LSectionName, 'Import') and
        not SameText(LSectionName, 'Exports') and
        not SameText(LSectionName, 'Resources') and
        not SameText(LSectionName, 'Borland 32 bit symbol table') then
        AddUnsupportedStructure(uskUnknownSection, LIndex + 1,
          'Unsupported TDUMP section: ' + LSectionName);
    end
    else if SameText(LLine, 'New Executable (NE) File') or
      SameText(LLine, 'Linear Executable (LE) File') then
      AddUnsupportedStructure(uskUnknownHeading, LIndex + 1,
        'Unsupported TDUMP file-header format: ' + LLine);
  end;
end;

procedure TDumpParser.ParseMetadata;
begin
  var LLine: string;
  var LVersionPos: Integer;
  var LDisplayPrefix := 'Display of File ';
  if FLines.Count = 0 then
    Exit;

  LLine := FLines[0];
  if Pos('Turbo Dump', LLine) > 0 then
  begin
    FDocument.ToolKind := tkTDump32;
    LVersionPos := Pos('Version', LLine);
    if LVersionPos > 0 then
      FDocument.ToolVersion := Trim(Copy(LLine, LVersionPos + Length('Version'), MaxInt));
  end;

  if FLines.Count > 1 then
  begin
    LLine := Trim(FLines[1]);
    if StartsWithText(LLine, LDisplayPrefix) then
      FDocument.CommandLine := LLine;
  end;
end;

procedure TDumpParser.ParseOldExecutableHeader;
begin
  var LHeaderStart := -1;
  for var LIndex := 0 to FLines.Count - 1 do
    if SameText(Trim(FLines[LIndex]), SOldExecutableHeader) then
    begin
      LHeaderStart := LIndex;
      Break;
    end;

  if LHeaderStart < 0 then
  begin
    AddDiagnostic(dsInfo, 0, 'Old Executable Header section was not found.', '');
    Exit;
  end;

  var LHeaderEnd := FLines.Count - 1;
  for var LIndex := LHeaderStart + 1 to FLines.Count - 1 do
    if IsKnownTopLevelHeading(FLines[LIndex]) then
    begin
      LHeaderEnd := LIndex - 1;
      Break;
    end;

  var LHeader := TDumpHeader.Create;
  LHeader.Name := SOldExecutableHeader;
  LHeader.StartLine := LHeaderStart + 1;
  LHeader.EndLine := LHeaderEnd + 1;
  FDocument.Headers.Add(LHeader);
  if FDocument.FileKind = dfUnknown then
    FDocument.FileKind := dfDOS;

  var LNode := AddNode(nkHeader, SOldExecutableHeader, LHeader.StartLine, LHeader.EndLine);
  var LRaw := TStringBuilder.Create;
  try
    for var LIndex := LHeaderStart to LHeaderEnd do
    begin
      if LRaw.Length > 0 then
        LRaw.AppendLine;
      LRaw.Append(FLines[LIndex]);
      var LLine := FLines[LIndex];
      if (LIndex = LHeaderStart) or (Trim(LLine) = '') then
        Continue;
      var LProperty: TDumpProperty;
      if TryParsePropertyLine(LLine, LIndex + 1, LProperty) then
      begin
        LHeader.Properties.Add(LProperty);
        LNode.Properties.Add(LProperty);
      end
      else
      begin
        AddUnsupportedStructure(uskHeaderLine, LIndex + 1,
          'Unsupported Old Executable Header line.');
        AddDiagnostic(dsWarning, LIndex + 1, 'Unrecognized Old Executable Header line.', LLine);
      end;
    end;
    LNode.RawText := LRaw.ToString;
  finally
    LRaw.Free;
  end;
end;

procedure TDumpParser.ParsePortableExecutableHeader;
begin
  var LHeaderStart := -1;
  for var LIndex := 0 to FLines.Count - 1 do
    if SameText(Trim(FLines[LIndex]), SPortableExecutableHeader) then
    begin
      LHeaderStart := LIndex;
      Break;
    end;
  if LHeaderStart < 0 then
    Exit;

  var LHeaderEnd := FLines.Count - 1;
  for var LIndex := LHeaderStart + 1 to FLines.Count - 1 do
    if SameText(Trim(FLines[LIndex]), 'Object table:') or
      StartsWithText(Trim(FLines[LIndex]), 'Section:') then
    begin
      LHeaderEnd := LIndex - 1;
      Break;
    end;

  var LHeader := TDumpHeader.Create;
  LHeader.Name := SPortableExecutableHeader;
  LHeader.StartLine := LHeaderStart + 1;
  LHeader.EndLine := LHeaderEnd + 1;
  FDocument.Headers.Add(LHeader);
  FDocument.FileKind := dfPE;

  var LHeaderNode := AddNode(nkHeader, SPortableExecutableHeader,
    LHeader.StartLine, LHeader.EndLine);
  var LDirectoryNode: TDumpNode := nil;
  var LInDirectoryTable := False;
  var LDirectoryIndex := 0;
  var LRaw := TStringBuilder.Create;
  try
    for var LIndex := LHeaderStart to LHeaderEnd do
    begin
      if LRaw.Length > 0 then
        LRaw.AppendLine;
      LRaw.Append(FLines[LIndex]);
      var LLine := FLines[LIndex];
      if (LIndex = LHeaderStart) or (Trim(LLine) = '') then
        Continue;

      if SameText(Trim(LLine), 'Name                   RVA       Size') then
      begin
        LInDirectoryTable := True;
        LDirectoryNode := AddNode(nkDataDirectory, 'PE Data Directory',
          LIndex + 1, LHeaderEnd + 1);
        Continue;
      end;

      if LInDirectoryTable then
      begin
        if (Trim(LLine) = '') or (Pos('----', LLine) > 0) then
          Continue;
        var LDirectory: TDumpDataDirectory;
        var LProperty: TDumpProperty;
        if TryParseDataDirectoryLine(LLine, LIndex + 1, LDirectoryIndex,
          LDirectory, LProperty) then
        begin
          FDocument.DataDirectories.Add(LDirectory);
          if LDirectoryNode <> nil then
            LDirectoryNode.Properties.Add(LProperty);
          Inc(LDirectoryIndex);
        end
        else
        begin
          AddUnsupportedStructure(uskDataDirectoryRow, LIndex + 1,
            'Unsupported PE data-directory row.');
          AddDiagnostic(dsWarning, LIndex + 1,
            'Unrecognized PE data directory row.', LLine);
        end;
        Continue;
      end;

      var LProperty: TDumpProperty;
      if TryParsePropertyLine(LLine, LIndex + 1, LProperty) then
      begin
        LHeader.Properties.Add(LProperty);
        LHeaderNode.Properties.Add(LProperty);
        if SameText(LProperty.Name, 'CPU type') then
          FDocument.Architecture := LProperty.RawValue;
      end
      else
      begin
        AddUnsupportedStructure(uskHeaderLine, LIndex + 1,
          'Unsupported Portable Executable Header line.');
        AddDiagnostic(dsWarning, LIndex + 1,
          'Unrecognized Portable Executable header line.', LLine);
      end;
    end;
    LHeaderNode.RawText := LRaw.ToString;
    if LDirectoryNode <> nil then
      LDirectoryNode.RawText := LRaw.ToString;
  finally
    LRaw.Free;
  end;
end;

procedure TDumpParser.ParseObjectTable;
begin
  var LTableStart := -1;
  for var LIndex := 0 to FLines.Count - 1 do
    if SameText(Trim(FLines[LIndex]), 'Object table:') then
    begin
      LTableStart := LIndex;
      Break;
    end;
  if LTableStart < 0 then
    Exit;

  var LTableEnd := FLines.Count - 1;
  for var LIndex := LTableStart + 1 to FLines.Count - 1 do
    if StartsWithText(Trim(FLines[LIndex]), 'Section:') then
    begin
      LTableEnd := LIndex - 1;
      Break;
    end;

  var LNode := AddNode(nkSections, 'Object table', LTableStart + 1,
    LTableEnd + 1);
  var LRaw := TStringBuilder.Create;
  try
    for var LIndex := LTableStart to LTableEnd do
    begin
      if LRaw.Length > 0 then
        LRaw.AppendLine;
      LRaw.Append(FLines[LIndex]);
      var LLine := FLines[LIndex];
      if (LIndex = LTableStart) or (Trim(LLine) = '') or
        (Pos('----', LLine) > 0) or (Pos('****', Trim(LLine)) > 0) or
        StartsWithText(Trim(LLine), '#') or
        StartsWithText(Trim(LLine), 'Key to section flags:') or
        ((Length(Trim(LLine)) >= 3) and (Trim(LLine)[2] = '-')) then
        Continue;
      if StartsWithText(Trim(LLine), 'C -') or
        StartsWithText(Trim(LLine), 'D -') or
        StartsWithText(Trim(LLine), 'E -') or
        StartsWithText(Trim(LLine), 'I -') or
        StartsWithText(Trim(LLine), 'R -') or
        StartsWithText(Trim(LLine), 'W -') then
        Continue;

      var LSection: TDumpSection;
      var LProperty: TDumpProperty;
      if TryParseObjectTableLine(LLine, LIndex + 1, LSection, LProperty) then
      begin
        FDocument.Sections.Add(LSection);
        LNode.Properties.Add(LProperty);
      end
      else
      begin
        AddUnsupportedStructure(uskObjectTableRow, LIndex + 1,
          'Unsupported object-table row.');
        AddDiagnostic(dsWarning, LIndex + 1, 'Unrecognized object table row.',
          LLine);
      end;
    end;
    LNode.RawText := LRaw.ToString;
  finally
    LRaw.Free;
  end;
end;

procedure TDumpParser.ParseImportSection;
begin
  var LSectionStart := -1;
  for var LIndex := 0 to FLines.Count - 1 do
    if SameText(Trim(FLines[LIndex]), 'Section:             Import') then
    begin
      LSectionStart := LIndex;
      Break;
    end;
  if LSectionStart < 0 then
    Exit;

  var LSectionEnd := FLines.Count - 1;
  for var LIndex := LSectionStart + 1 to FLines.Count - 1 do
    if StartsWithText(Trim(FLines[LIndex]), 'Section:') and
      (LIndex > LSectionStart) then
    begin
      LSectionEnd := LIndex - 1;
      Break;
    end;

  var LNode := AddNode(nkImports, 'Section: Import', LSectionStart + 1,
    LSectionEnd + 1);
  FDocument.ImportMetadata := TDumpSectionMetadata.Create;
  FDocument.ImportMetadata.Name := 'Import';
  FDocument.ImportMetadata.Node := LNode;
  FDocument.ImportMetadata.StartLine := LSectionStart + 1;
  FDocument.ImportMetadata.EndLine := LSectionEnd + 1;
  var LCurrentModule: TDumpImportModule := nil;
  var LModuleNode: TDumpNode := nil;
  var LRaw := TStringBuilder.Create;
  try
    for var LIndex := LSectionStart to LSectionEnd do
    begin
      if LRaw.Length > 0 then
        LRaw.AppendLine;
      LRaw.Append(FLines[LIndex]);
      var LLine := FLines[LIndex];
      var LTrimmed := Trim(LLine);
      if (LIndex = LSectionStart) or (LTrimmed = '') or
        (Pos('****', LTrimmed) > 0) then
        Continue;

      if StartsWithText(LTrimmed, 'Imports from ') then
      begin
        var LModuleName := Trim(Copy(LTrimmed, Length('Imports from ') + 1,
          MaxInt));
        LCurrentModule := TDumpImportModule.Create;
        LCurrentModule.Name := LModuleName;
        LCurrentModule.StartLine := LIndex + 1;
        LCurrentModule.EndLine := LSectionEnd + 1;
        FDocument.Imports.Add(LCurrentModule);
        LModuleNode := TDumpNode.Create;
        LModuleNode.Kind := nkImports;
        LModuleNode.Title := LModuleName;
        LModuleNode.StartLine := LIndex + 1;
        LModuleNode.EndLine := LSectionEnd + 1;
        LNode.Children.Add(LModuleNode);
        Continue;
      end;

      if LCurrentModule = nil then
      begin
        var LProperty: TDumpProperty;
        if TryParsePropertyLine(LLine, LIndex + 1, LProperty) then
        begin
          LNode.Properties.Add(LProperty);
          FDocument.ImportMetadata.Properties.Add(LProperty);
          if SameText(LProperty.Name, 'File Offset') then
          begin
            var LFileOffsetText := LProperty.RawValue;
            FDocument.ImportMetadata.RawFileOffset := FirstToken(LFileOffsetText);
            FDocument.ImportMetadata.HasFileOffset := TryParseHexUIntToken(
              FDocument.ImportMetadata.RawFileOffset,
              FDocument.ImportMetadata.FileOffset);
          end;
        end
        else
        begin
          AddUnsupportedStructure(uskImportSectionLine, LIndex + 1,
            'Unsupported import-section line.');
          AddDiagnostic(dsWarning, LIndex + 1, 'Unrecognized import section line.',
            LLine);
        end;
        Continue;
      end;

      var LImport: TDumpImport;
      if TryParseImportLine(LLine, LIndex + 1, LImport) then
      begin
        LCurrentModule.Entries.Add(LImport);
        if LModuleNode <> nil then
        begin
          var LProperty: TDumpProperty;
          LProperty.Name := LImport.Name;
          LProperty.RawValue := LImport.RawText;
          LProperty.ValueKind := vkText;
          LProperty.UIntValue := 0;
          LProperty.HasUIntValue := False;
          LProperty.TextValue := LImport.Name;
          LProperty.StartLine := LImport.StartLine;
          LModuleNode.Properties.Add(LProperty);
        end;
      end
      else
      begin
        AddUnsupportedStructure(uskImportEntry, LIndex + 1,
          'Unsupported import entry.');
        AddDiagnostic(dsWarning, LIndex + 1, 'Unrecognized import entry.', LLine);
      end;
    end;
    LNode.RawText := LRaw.ToString;
  finally
    LRaw.Free;
  end;
end;

procedure TDumpParser.ParseExportSection;
begin
  var LSectionStart := -1;
  for var LIndex := 0 to FLines.Count - 1 do
    if StartsWithText(Trim(FLines[LIndex]), 'Section:') and
      SameText(Trim(Copy(Trim(FLines[LIndex]), Length('Section:') + 1, MaxInt)), 'Exports') then
    begin
      LSectionStart := LIndex;
      Break;
    end;
  if LSectionStart < 0 then
    Exit;

  var LSectionEnd := FLines.Count - 1;
  for var LIndex := LSectionStart + 1 to FLines.Count - 1 do
    if StartsWithText(Trim(FLines[LIndex]), 'Section:') then
    begin
      LSectionEnd := LIndex - 1;
      Break;
    end;

  // Preserve the entire section while projecting recognizable export rows.
  var LNode := AddNode(nkExports, 'Section: Exports', LSectionStart + 1, LSectionEnd + 1);
  FDocument.ExportMetadata := TDumpSectionMetadata.Create;
  FDocument.ExportMetadata.Name := 'Exports';
  FDocument.ExportMetadata.Node := LNode;
  FDocument.ExportMetadata.StartLine := LSectionStart + 1;
  FDocument.ExportMetadata.EndLine := LSectionEnd + 1;
  var LRaw := TStringBuilder.Create;
  try
    for var LIndex := LSectionStart to LSectionEnd do
    begin
      if LRaw.Length > 0 then
        LRaw.AppendLine;
      LRaw.Append(FLines[LIndex]);

      var LLine := FLines[LIndex];
      var LTrimmed := Trim(LLine);
      var LMetadataProperty: TDumpProperty;
      if TryParsePropertyLine(LLine, LIndex + 1, LMetadataProperty) then
      begin
        FDocument.ExportMetadata.Properties.Add(LMetadataProperty);
        if SameText(LMetadataProperty.Name, 'File Offset') then
        begin
          var LFileOffsetText := LMetadataProperty.RawValue;
          FDocument.ExportMetadata.RawFileOffset := FirstToken(LFileOffsetText);
          FDocument.ExportMetadata.HasFileOffset := TryParseHexUIntToken(
            FDocument.ExportMetadata.RawFileOffset,
            FDocument.ExportMetadata.FileOffset);
        end;
      end;
      if (LIndex = LSectionStart) or (LTrimmed = '') or
        (Pos('****', LTrimmed) > 0) or (Pos('----', LTrimmed) > 0) or
        StartsWithText(LTrimmed, 'Exports from ') or
        StartsWithText(LTrimmed, 'Sorted by ') or
        StartsWithText(LTrimmed, 'RVA ') or
        (Pos('exported name(s)', LowerCase(LTrimmed)) > 0) then
        Continue;

      var LExport: TDumpExport;
      if TryParseExportLine(LLine, LIndex + 1, LExport) then
      begin
        FDocument.ExportList.Add(LExport);

        var LProperty: TDumpProperty;
        LProperty.Name := LExport.Name;
        LProperty.RawValue := LExport.RawText;
        LProperty.ValueKind := vkRVA;
        LProperty.UIntValue := LExport.RVA;
        LProperty.HasUIntValue := LExport.HasRVA;
        LProperty.TextValue := LExport.Name;
        LProperty.StartLine := LExport.StartLine;
        LNode.Properties.Add(LProperty);
      end;
    end;
    LNode.RawText := LRaw.ToString;
  finally
    LRaw.Free;
  end;
end;

procedure TDumpParser.ParseResourceSection;
begin
  var LSectionStart := -1;
  for var LIndex := 0 to FLines.Count - 1 do
    if StartsWithText(Trim(FLines[LIndex]), 'Section:') and
      SameText(Trim(Copy(Trim(FLines[LIndex]), Length('Section:') + 1, MaxInt)), 'Resources') then
    begin
      LSectionStart := LIndex;
      Break;
    end;
  if LSectionStart < 0 then
    Exit;

  var LSectionEnd := FLines.Count - 1;
  var LStartedResources := False;
  for var LIndex := LSectionStart + 1 to FLines.Count - 1 do
  begin
    var LTrimmed := Trim(FLines[LIndex]);
    if StartsWithText(LTrimmed, 'Section:') then
    begin
      LSectionEnd := LIndex - 1;
      Break;
    end;
    if SameText(LTrimmed, 'Resources:') then
      LStartedResources := True
    else if LStartedResources and (LTrimmed <> '') then
    begin
      var LHasLeadingIndent := CharInSet(FLines[LIndex][1], [' ', #9]);
      if not LHasLeadingIndent and not StartsWithText(LTrimmed, 'type:') and
        not StartsWithText(LTrimmed, 'Type ') and not StartsWithText(LTrimmed, '[') and
        not StartsWithText(LTrimmed, '-') then
      begin
        LSectionEnd := LIndex - 1;
        Break;
      end;
    end;
  end;

  // Resource indentation describes the hierarchy emitted by TDUMP.
  var LNode := AddNode(nkResources, 'Section: Resources', LSectionStart + 1, LSectionEnd + 1);
  FDocument.ResourceMetadata := TDumpSectionMetadata.Create;
  FDocument.ResourceMetadata.Name := 'Resources';
  FDocument.ResourceMetadata.Node := LNode;
  FDocument.ResourceMetadata.StartLine := LSectionStart + 1;
  FDocument.ResourceMetadata.EndLine := LSectionEnd + 1;
  var LRaw := TStringBuilder.Create;
  var LResourceStack := TList<TDumpResource>.Create;
  var LNodeStack := TList<TDumpNode>.Create;
  var LIndentStack := TList<Integer>.Create;
  try
    for var LIndex := LSectionStart to LSectionEnd do
    begin
      if LRaw.Length > 0 then
        LRaw.AppendLine;
      LRaw.Append(FLines[LIndex]);

      var LLine := FLines[LIndex];
      var LTrimmed := Trim(LLine);
      var LIndent: Integer;
      var LResource: TDumpResource;
      var LProperty: TDumpProperty;
      var LMetadataProperty: TDumpProperty;
      if TryParsePropertyLine(LLine, LIndex + 1, LMetadataProperty) then
      begin
        FDocument.ResourceMetadata.Properties.Add(LMetadataProperty);
        if SameText(LMetadataProperty.Name, 'File Offset') then
        begin
          var LFileOffsetText := LMetadataProperty.RawValue;
          FDocument.ResourceMetadata.RawFileOffset := FirstToken(LFileOffsetText);
          FDocument.ResourceMetadata.HasFileOffset := TryParseHexUIntToken(
            FDocument.ResourceMetadata.RawFileOffset,
            FDocument.ResourceMetadata.FileOffset);
        end;
      end;
      if TryParseResourceLine(LLine, LIndex + 1, LIndent, LResource) then
      begin
        while (LIndentStack.Count > 0) and (LIndent <= LIndentStack.Last) do
        begin
          LResourceStack.Last.EndLine := LIndex;
          LResourceStack.Delete(LResourceStack.Count - 1);
          LNodeStack.Delete(LNodeStack.Count - 1);
          LIndentStack.Delete(LIndentStack.Count - 1);
        end;

        var LResourceNode := TDumpNode.Create;
        LResourceNode.Kind := nkResources;
        LResourceNode.Title := LResource.Name;
        LResourceNode.StartLine := LIndex + 1;
        LResourceNode.EndLine := LIndex + 1;
        LResourceNode.RawText := LLine;
        for var LPropertyIndex := 0 to LResource.Properties.Count - 1 do
          LResourceNode.Properties.Add(LResource.Properties[LPropertyIndex]);
        if LResourceStack.Count = 0 then
        begin
          FDocument.Resources.Add(LResource);
          LNode.Children.Add(LResourceNode);
        end
        else
        begin
          LResourceStack.Last.Children.Add(LResource);
          LNodeStack.Last.Children.Add(LResourceNode);
        end;
        LResourceStack.Add(LResource);
        LNodeStack.Add(LResourceNode);
        LIndentStack.Add(LIndent);
        Continue;
      end;

      if StartsWithText(LTrimmed, '[') and
        (Pos('named entries', LTrimmed) > 0) and (Pos('ID entries', LTrimmed) > 0) then
      begin
        var LCountsText := Copy(LTrimmed, 2, MaxInt);
        var LNamedText := FirstToken(LCountsText);
        var LCommaPos := Pos(',', LCountsText);
        if LCommaPos > 0 then
          LCountsText := Trim(Copy(LCountsText, LCommaPos + 1, MaxInt));
        var LIdText := FirstToken(LCountsText);
        var LNamedCount: UInt64;
        var LIdCount: UInt64;
        if TryParseUIntToken(LNamedText, LNamedCount) and
          TryParseUIntToken(LIdText, LIdCount) then
        begin
          if LResourceStack.Count > 0 then
          begin
            LResourceStack.Last.NamedEntryCount := LNamedCount;
            LResourceStack.Last.IdEntryCount := LIdCount;
            LResourceStack.Last.HasDirectoryCounts := True;
          end
          else
          begin
            FDocument.ResourceMetadata.RootNamedEntryCount := LNamedCount;
            FDocument.ResourceMetadata.RootIdEntryCount := LIdCount;
            FDocument.ResourceMetadata.HasRootDirectoryCounts := True;
          end;
        end;
        Continue;
      end;

      if (LResourceStack.Count = 0) or not TryParsePropertyLine(LLine, LIndex + 1, LProperty) then
        Continue;

      LResourceStack.Last.Properties.Add(LProperty);
      LResourceStack.Last.EndLine := LIndex + 1;
      LNodeStack.Last.Properties.Add(LProperty);
      LNodeStack.Last.EndLine := LIndex + 1;
      if SameText(LProperty.Name, 'Size') and LProperty.HasUIntValue then
      begin
        LResourceStack.Last.Size := LProperty.UIntValue;
        LResourceStack.Last.HasSize := True;
      end
      else if SameText(LProperty.Name, 'Offset') and LProperty.HasUIntValue then
      begin
        LResourceStack.Last.RVA := LProperty.UIntValue;
        LResourceStack.Last.HasRVA := True;
        LResourceStack.Last.DataOffset := LProperty.UIntValue;
        LResourceStack.Last.HasDataOffset := True;
        if SameText(LResourceStack.Last.ResourceType, 'Unknown') and
          LResourceStack.Last.HasId then
        begin
          LResourceStack.Last.RawLanguage := IntToStr(LResourceStack.Last.Id);
          LResourceStack.Last.Language := LResourceStack.Last.RawLanguage;
        end;
      end
      else if SameText(LProperty.Name, 'Code Page') and LProperty.HasUIntValue then
      begin
        LResourceStack.Last.CodePage := LProperty.UIntValue;
        LResourceStack.Last.HasCodePage := True;
      end
      else if SameText(LProperty.Name, 'Reserved') and LProperty.HasUIntValue then
      begin
        LResourceStack.Last.Reserved := LProperty.UIntValue;
        LResourceStack.Last.HasReserved := True;
      end;
    end;
    while LResourceStack.Count > 0 do
    begin
      LResourceStack.Last.EndLine := LSectionEnd + 1;
      LResourceStack.Delete(LResourceStack.Count - 1);
      LIndentStack.Delete(LIndentStack.Count - 1);
    end;
    LNode.RawText := LRaw.ToString;
  finally
    LIndentStack.Free;
    LNodeStack.Free;
    LResourceStack.Free;
    LRaw.Free;
  end;
end;

procedure TDumpParser.ParseBorlandSymbolTable;
begin
  var LTableStart := -1;
  for var LIndex := 0 to FLines.Count - 1 do
    if SameText(Trim(FLines[LIndex]), 'Borland 32 bit symbol table') then
    begin
      LTableStart := LIndex;
      Break;
    end;
  if LTableStart < 0 then
    Exit;

  var LTableEnd := FLines.Count - 1;
  // TDUMP emits the Borland subsections through the end of these fixtures.
  var LTableNode := AddNode(nkSymbols, 'Borland 32 bit symbol table',
    LTableStart + 1, LTableEnd + 1);
  var LDirectoryNode: TDumpNode := nil;
  var LCurrentSubsection: TDumpNode := nil;
  var LCurrentRecord: TDumpNode := nil;
  var LCurrentRecordKind := '';
  var LCurrentRecordHasSymbol := False;
  var LInSubsectionDirectory := False;
  var LCurrentModule: TDumpSymbolModule := nil;
  var LCurrentSourceModule: TDumpSourceModule := nil;
  var LCurrentSourceFile: TDumpSourceFile := nil;
  var LCurrentSourceRange: TDumpSourceRange := nil;
  var LReadingSourceLines := False;
  var LCurrentAlignSection: TDumpAlignSymbolSection := nil;
  var LCurrentAlignRecord: TDumpAlignSymbolRecord := nil;
  var LCurrentGlobalSymbolSection: TDumpGlobalSymbolSection := nil;
  var LCurrentGlobalSymbolRecord: TDumpGlobalSymbolRecord := nil;
  var LCurrentGlobalTypeSection: TDumpGlobalTypeSection := nil;
  var LCurrentGlobalTypeRecord: TDumpGlobalTypeRecord := nil;
  var LCurrentBorlandSubsection: TDumpBorlandSubsection := nil;
  var LAlignScopeStack := TList<TDumpAlignSymbolRecord>.Create;
  try
    for var LIndex := LTableStart to LTableEnd do
    begin
      var LLine := FLines[LIndex];
      var LTrimmed := Trim(LLine);
      var LProperty: TDumpProperty;
      var LSymbol: TDumpSymbol;
      var LSymbolSearch: TDumpSymbolSearch;
      var LSourceFile: TDumpSourceFile;
      var LSourceRange: TDumpSourceRange;
      AppendNodeRawLine(LTableNode, LLine);
      if Assigned(FOnProgress) then
        ReportProgress(ppBorlandSymbols, LIndex + 1);

      if LIndex = LTableStart then
        Continue;

      if StartsWithText(LTrimmed, 'SubSection Directory') then
      begin
        if LCurrentRecord <> nil then
          LCurrentRecord.EndLine := LIndex;
        if LCurrentAlignRecord <> nil then
          LCurrentAlignRecord.EndLine := LIndex;
        if LCurrentGlobalSymbolRecord <> nil then
          LCurrentGlobalSymbolRecord.EndLine := LIndex;
        if LCurrentGlobalTypeRecord <> nil then
          LCurrentGlobalTypeRecord.EndLine := LIndex;
        if LCurrentSubsection <> nil then
          LCurrentSubsection.EndLine := LIndex;

        LCurrentSubsection := TDumpNode.Create;
        LCurrentSubsection.Kind := nkSymbols;
        LCurrentSubsection.Title := 'SubSection Directory';
        LCurrentSubsection.StartLine := LIndex + 1;
        LCurrentSubsection.EndLine := LIndex + 1;
        LCurrentSubsection.RawText := LLine;
        LTableNode.Children.Add(LCurrentSubsection);
        LDirectoryNode := LCurrentSubsection;
        LCurrentRecord := nil;
        LCurrentAlignRecord := nil;
        LAlignScopeStack.Clear;
        LCurrentGlobalSymbolRecord := nil;
        LCurrentGlobalTypeRecord := nil;
        LCurrentRecordKind := '';
        LInSubsectionDirectory := True;
        Continue;
      end;

      if LInSubsectionDirectory and StartsWithText(LTrimmed, '--------------------------------') then
      begin
        AppendNodeRawLine(LDirectoryNode, LLine);
        LDirectoryNode.EndLine := LIndex + 1;
        LCurrentSubsection := nil;
        LCurrentRecord := nil;
        LInSubsectionDirectory := False;
        Continue;
      end;

      if LInSubsectionDirectory and StartsWithText(LTrimmed, 'ModIndex:') then
      begin
        AppendNodeRawLine(LDirectoryNode, LLine);
        LDirectoryNode.EndLine := LIndex + 1;
        var LSubsection: TDumpSymbolSubsection;
        if TryParseBorlandSubsectionDirectoryLine(LLine, LIndex + 1, LSubsection) then
        begin
          FDocument.SymbolSubsections.Add(LSubsection);
          var LDirectoryEntryNode := TDumpNode.Create;
          LDirectoryEntryNode.Kind := nkSymbols;
          LDirectoryEntryNode.Title := LSubsection.SubsectionType;
          LDirectoryEntryNode.StartLine := LIndex + 1;
          LDirectoryEntryNode.EndLine := LIndex + 1;
          LDirectoryEntryNode.RawText := LLine;
          LProperty.Name := 'Subsection';
          LProperty.RawValue := LLine;
          LProperty.ValueKind := vkText;
          LProperty.UIntValue := LSubsection.FileOffset;
          LProperty.HasUIntValue := True;
          LProperty.TextValue := LSubsection.SubsectionType;
          LProperty.StartLine := LSubsection.StartLine;
          LDirectoryEntryNode.Properties.Add(LProperty);
          LDirectoryNode.Children.Add(LDirectoryEntryNode);
        end;
        Continue;
      end;

      if StartsWithText(LTrimmed, 'ModIndex:') and (Pos(' sst', LTrimmed) > 0) then
      begin
        if LCurrentRecord <> nil then
          LCurrentRecord.EndLine := LIndex;
        if LCurrentAlignRecord <> nil then
          LCurrentAlignRecord.EndLine := LIndex;
        if LCurrentGlobalSymbolRecord <> nil then
          LCurrentGlobalSymbolRecord.EndLine := LIndex;
        if LCurrentGlobalTypeRecord <> nil then
          LCurrentGlobalTypeRecord.EndLine := LIndex;
        if LCurrentSubsection <> nil then
          LCurrentSubsection.EndLine := LIndex;
        if LCurrentModule <> nil then
          LCurrentModule.EndLine := LIndex;
        if LCurrentSourceModule <> nil then
          LCurrentSourceModule.EndLine := LIndex;
        if LCurrentAlignSection <> nil then
          LCurrentAlignSection.EndLine := LIndex;
        if LCurrentGlobalSymbolSection <> nil then
          LCurrentGlobalSymbolSection.EndLine := LIndex;
        if LCurrentGlobalTypeSection <> nil then
          LCurrentGlobalTypeSection.EndLine := LIndex;
        if LCurrentBorlandSubsection <> nil then
          LCurrentBorlandSubsection.EndLine := LIndex;

        var LSubsectionModIndex: Integer;
        var LSubsectionFileOffset: UInt64;
        var LSubsectionType: string;
        if not TryParseBorlandSubsectionHeader(LLine, LSubsectionModIndex,
          LSubsectionFileOffset, LSubsectionType) then
          Continue;
        LCurrentSubsection := TDumpNode.Create;
        LCurrentSubsection.Kind := nkSymbols;
        LCurrentSubsection.Title := LSubsectionType;
        LCurrentSubsection.StartLine := LIndex + 1;
        LCurrentSubsection.EndLine := LIndex + 1;
        LCurrentSubsection.RawText := LLine;
        LTableNode.Children.Add(LCurrentSubsection);

        LCurrentBorlandSubsection := TDumpBorlandSubsection.Create;
        LCurrentBorlandSubsection.ModIndex := LSubsectionModIndex;
        LCurrentBorlandSubsection.FileOffset := LSubsectionFileOffset;
        LCurrentBorlandSubsection.SubsectionType := LSubsectionType;
        LCurrentBorlandSubsection.Node := LCurrentSubsection;
        LCurrentBorlandSubsection.StartLine := LIndex + 1;
        LCurrentBorlandSubsection.EndLine := LIndex + 1;
        FDocument.BorlandSubsections.Add(LCurrentBorlandSubsection);

        if TryParsePropertyLine(LLine, LIndex + 1, LProperty) then
          LCurrentSubsection.Properties.Add(LProperty);
        LCurrentRecord := nil;
        LCurrentAlignRecord := nil;
        LAlignScopeStack.Clear;
        LCurrentGlobalSymbolRecord := nil;
        LCurrentGlobalTypeRecord := nil;
        LCurrentRecordKind := '';
        LInSubsectionDirectory := False;
        LCurrentModule := nil;
        LCurrentSourceModule := nil;
        LCurrentSourceFile := nil;
        LCurrentSourceRange := nil;
        LReadingSourceLines := False;
        LCurrentAlignSection := nil;
        LCurrentGlobalSymbolSection := nil;
        LCurrentGlobalTypeSection := nil;
        if SameText(LSubsectionType, 'sstModule') then
        begin
          LCurrentModule := TDumpSymbolModule.Create;
          LCurrentModule.ModIndex := LSubsectionModIndex;
          LCurrentModule.FileOffset := LSubsectionFileOffset;
          LCurrentModule.StartLine := LIndex + 1;
          LCurrentModule.EndLine := LIndex + 1;
          FDocument.SymbolModules.Add(LCurrentModule);
        end;
        if SameText(LSubsectionType, 'sstSrcModule') then
        begin
          LCurrentSourceModule := TDumpSourceModule.Create;
          LCurrentSourceModule.ModIndex := LSubsectionModIndex;
          LCurrentSourceModule.FileOffset := LSubsectionFileOffset;
          LCurrentSourceModule.StartLine := LIndex + 1;
          LCurrentSourceModule.EndLine := LIndex + 1;
          FDocument.SourceModules.Add(LCurrentSourceModule);
        end;
        if SameText(LSubsectionType, 'sstAlignSym') then
        begin
          LAlignScopeStack.Clear;
          LCurrentAlignSection := TDumpAlignSymbolSection.Create;
          LCurrentAlignSection.ModIndex := LSubsectionModIndex;
          LCurrentAlignSection.FileOffset := LSubsectionFileOffset;
          LCurrentAlignSection.StartLine := LIndex + 1;
          LCurrentAlignSection.EndLine := LIndex + 1;
          FDocument.AlignSymbolSections.Add(LCurrentAlignSection);
        end;
        if SameText(LSubsectionType, 'sstGlobalSym') then
        begin
          LCurrentGlobalSymbolSection := TDumpGlobalSymbolSection.Create;
          LCurrentGlobalSymbolSection.Node := LCurrentSubsection;
          LCurrentGlobalSymbolSection.ModIndex := LSubsectionModIndex;
          LCurrentGlobalSymbolSection.FileOffset := LSubsectionFileOffset;
          LCurrentGlobalSymbolSection.StartLine := LIndex + 1;
          LCurrentGlobalSymbolSection.EndLine := LIndex + 1;
          FDocument.GlobalSymbolSections.Add(LCurrentGlobalSymbolSection);
        end;
        if SameText(LSubsectionType, 'sstGlobalTypes') then
        begin
          LCurrentGlobalTypeSection := TDumpGlobalTypeSection.Create;
          LCurrentGlobalTypeSection.Node := LCurrentSubsection;
          LCurrentGlobalTypeSection.ModIndex := LSubsectionModIndex;
          LCurrentGlobalTypeSection.FileOffset := LSubsectionFileOffset;
          LCurrentGlobalTypeSection.StartLine := LIndex + 1;
          LCurrentGlobalTypeSection.EndLine := LIndex + 1;
          FDocument.GlobalTypeSections.Add(LCurrentGlobalTypeSection);
        end;
        Continue;
      end;

      if LCurrentModule <> nil then
      begin
        if StartsWithText(LTrimmed, 'OvlNum:') then
        begin
          var LValue: UInt64;
          LCurrentModule.Name := ValueForLabel(LLine, 'Name:');
          var LNameOpenBracket := LastDelimiter('[', LCurrentModule.Name);
          var LNameCloseBracket := LastDelimiter(']', LCurrentModule.Name);
          if (LNameOpenBracket > 0) and (LNameCloseBracket > LNameOpenBracket) then
          begin
            LCurrentModule.RawNameIndex := Copy(LCurrentModule.Name,
              LNameOpenBracket + 1, LNameCloseBracket - LNameOpenBracket - 1);
            LCurrentModule.HasNameIndex := TryParseHexUIntToken(
              LCurrentModule.RawNameIndex, LCurrentModule.NameIndex);
            LCurrentModule.Name := Trim(Copy(LCurrentModule.Name, 1,
              LNameOpenBracket - 1));
          end;
          if TryParseHexUIntToken(ValueForLabel(LLine, 'OvlNum:'), LValue) then
            LCurrentModule.OvlNum := LValue;
          if TryParseHexUIntToken(ValueForLabel(LLine, 'LibIndex:'), LValue) then
            LCurrentModule.LibIndex := LValue;
          if TryParseHexUIntToken(ValueForLabel(LLine, 'SegCount:'), LValue) then
            LCurrentModule.SegCount := LValue;
          if TryParseHexUIntToken(ValueForLabel(LLine, 'Time:'), LValue) then
            LCurrentModule.Time := LValue;
          if TryParsePropertyLine(LLine, LIndex + 1, LProperty) then
            LCurrentModule.Properties.Add(LProperty);
        end;

        var LModuleSegment: TDumpSymbolModuleSegment;
        if TryParseBorlandModuleSegmentLine(LLine, LIndex + 1, LModuleSegment) then
          LCurrentModule.Segments.Add(LModuleSegment);
        LCurrentModule.EndLine := LIndex + 1;
      end;

      if LCurrentSourceModule <> nil then
      begin
        LCurrentSourceModule.EndLine := LIndex + 1;
        if StartsWithText(LTrimmed, 'File:') then
        begin
          if TryParseBorlandSourceFileLine(LLine, LIndex + 1, LSourceFile) then
          begin
            LCurrentSourceModule.SourceFiles.Add(LSourceFile);
            LCurrentSourceFile := LSourceFile;
            LCurrentSourceRange := nil;
          end;
          LReadingSourceLines := False;
        end
        else if StartsWithText(LTrimmed, 'Range:') and (LCurrentSourceFile <> nil) then
        begin
          if TryParseBorlandSourceRangeLine(LLine, LIndex + 1, LSourceRange) then
          begin
            LCurrentSourceFile.Ranges.Add(LSourceRange);
            LCurrentSourceRange := LSourceRange;
          end;
          LReadingSourceLines := False;
        end
        else if SameText(LTrimmed, 'Line numbers:') then
          LReadingSourceLines := True
        else if (LCurrentSourceFile = nil) and
          TryParseBorlandSourceRangeLine(LLine, LIndex + 1, LSourceRange) then
          LCurrentSourceModule.SegmentRanges.Add(LSourceRange)
        else if LReadingSourceLines and (LCurrentSourceRange <> nil) then
          AddBorlandSourceLinePairs(LLine, LIndex + 1, LCurrentSourceRange);
      end;

      if (LCurrentBorlandSubsection <> nil) and
        SameText(LCurrentBorlandSubsection.SubsectionType, 'sstNames') then
      begin
        var LColonPos := Pos(':', LTrimmed);
        if LColonPos > 0 then
        begin
          var LNameIndexText := Trim(Copy(LTrimmed, 1, LColonPos - 1));
          var LNameIndex: UInt64;
          if TryParseHexUIntToken(LNameIndexText, LNameIndex) then
          begin
            var LBorlandName: TDumpBorlandName;
            LBorlandName.Index := LNameIndex;
            LBorlandName.RawIndex := LNameIndexText;
            LBorlandName.Value := Trim(Copy(LTrimmed, LColonPos + 1, MaxInt));
            LBorlandName.StartLine := LIndex + 1;
            FDocument.BorlandNames.Add(LBorlandName);
            FDocument.BorlandNameLookup.AddOrSetValue(LNameIndex,
              LBorlandName.Value);
          end;
        end;
      end;

      if LCurrentGlobalSymbolSection <> nil then
      begin
        LCurrentGlobalSymbolSection.EndLine := LIndex + 1;
        if StartsWithText(LTrimmed, 'cbSymbols:') or
          StartsWithText(LTrimmed, 'SymHash:') then
        begin
          for var LLabel in SGlobalSymbolHeaderLabels do
          begin
            var LRawValue := ValueForLabel(LLine, LLabel);
            if LRawValue = '' then
              Continue;
            var LGlobalProperty: TDumpProperty;
            LGlobalProperty.Name := Copy(LLabel, 1, Length(LLabel) - 1);
            LGlobalProperty.RawValue := LRawValue;
            LGlobalProperty.ValueKind := vkUInt;
            LGlobalProperty.HasUIntValue := TryParseHexUIntToken(LRawValue,
              LGlobalProperty.UIntValue);
            LGlobalProperty.TextValue := LRawValue;
            LGlobalProperty.StartLine := LIndex + 1;
            LCurrentGlobalSymbolSection.Properties.Add(LGlobalProperty);
            if not LGlobalProperty.HasUIntValue then
              AddDiagnostic(dsWarning, LIndex + 1,
                'Malformed sstGlobalSym counter value.', LLine);
          end;
        end;
      end;

      if LCurrentGlobalTypeSection <> nil then
      begin
        LCurrentGlobalTypeSection.EndLine := LIndex + 1;
        if StartsWithText(LTrimmed, 'Number of types:') then
        begin
          LCurrentGlobalTypeSection.RawTypeCount :=
            ValueForLabel(LLine, 'Number of types:');
          TryParseHexUIntToken(LCurrentGlobalTypeSection.RawTypeCount,
            LCurrentGlobalTypeSection.TypeCount);
        end;

        var LGlobalTypeRecord: TDumpGlobalTypeRecord;
        if TryParseBorlandGlobalTypeLine(LLine, LIndex + 1, LGlobalTypeRecord) then
        begin
          if LCurrentRecord <> nil then
            LCurrentRecord.EndLine := LIndex;
          if LCurrentGlobalTypeRecord <> nil then
            LCurrentGlobalTypeRecord.EndLine := LIndex;

          LCurrentRecord := TDumpNode.Create;
          LCurrentRecord.Kind := nkSymbols;
          LCurrentRecord.Title := 'Type ' + LGlobalTypeRecord.RawTypeIndex +
            ' ' + LGlobalTypeRecord.TypeKind;
          LCurrentRecord.StartLine := LIndex + 1;
          LCurrentRecord.EndLine := LIndex + 1;
          LCurrentRecord.RawText := LLine;
          LCurrentSubsection.Children.Add(LCurrentRecord);

          LGlobalTypeRecord.Node := LCurrentRecord;
          LGlobalTypeRecord.HeaderLine := FDocument.Lines[LIndex];
          LGlobalTypeRecord.DetailLines.Add(LGlobalTypeRecord.HeaderLine);
          LCurrentGlobalTypeSection.Records.Add(LGlobalTypeRecord);
          LCurrentGlobalTypeRecord := LGlobalTypeRecord;
          ParseBorlandGlobalTypeDetails(LCurrentGlobalTypeRecord, LLine,
            LIndex + 1);
          LCurrentRecordKind := '';
          LCurrentRecordHasSymbol := False;
          Continue;
        end;
      end;

      var LRecordPos := Pos('S_', LTrimmed);
      var LIsRecord := False;
      if LRecordPos > 1 then
      begin
        var LRecordOffsetText := Trim(Copy(LTrimmed, 1, LRecordPos - 1));
        var LRecordOffset: UInt64;
        LIsRecord := TryParseHexUIntToken(LRecordOffsetText, LRecordOffset);
      end;
      if LIsRecord then
      begin
        if LCurrentRecord <> nil then
          LCurrentRecord.EndLine := LIndex;
        if LCurrentAlignRecord <> nil then
          LCurrentAlignRecord.EndLine := LIndex;
        if LCurrentGlobalSymbolRecord <> nil then
          LCurrentGlobalSymbolRecord.EndLine := LIndex;

        var LRecordText := Copy(LTrimmed, LRecordPos, MaxInt);
        var LRecordKind := FirstToken(LRecordText);
        var LRecordOffsetText := Trim(Copy(LTrimmed, 1, LRecordPos - 1));
        LCurrentRecord := TDumpNode.Create;
        LCurrentRecord.Kind := nkSymbols;
        LCurrentRecord.Title := LRecordKind;
        LCurrentRecord.StartLine := LIndex + 1;
        LCurrentRecord.EndLine := LIndex + 1;
        LCurrentRecord.RawText := LLine;
        if LCurrentSubsection <> nil then
          LCurrentSubsection.Children.Add(LCurrentRecord)
        else
          LTableNode.Children.Add(LCurrentRecord);

        LCurrentAlignRecord := nil;
        if LCurrentAlignSection <> nil then
        begin
          LCurrentAlignRecord := TDumpAlignSymbolRecord.Create;
          LCurrentAlignRecord.RawRecordOffset := LRecordOffsetText;
          TryParseHexUIntToken(LRecordOffsetText,
            LCurrentAlignRecord.RecordOffset);
          LCurrentAlignRecord.RecordKind := LRecordKind;
          LCurrentAlignRecord.Node := LCurrentRecord;
          LCurrentAlignRecord.HeaderLine := FDocument.Lines[LIndex];
          LCurrentAlignRecord.DetailLines.Add(LCurrentAlignRecord.HeaderLine);
          LCurrentAlignRecord.StartLine := LIndex + 1;
          LCurrentAlignRecord.EndLine := LIndex + 1;
          LCurrentAlignSection.Records.Add(LCurrentAlignRecord);
          ParseBorlandSymbolRecordDetails(LCurrentAlignRecord, LLine,
            LIndex + 1);
          if LAlignScopeStack.Count > 0 then
          begin
            LCurrentAlignRecord.ScopeParent := LAlignScopeStack.Last;
            LCurrentAlignRecord.ScopeParent.ScopeChildren.Add(LCurrentAlignRecord);
            LCurrentAlignRecord.ScopeDepth := LAlignScopeStack.Count;
          end;
          if LCurrentAlignRecord.Kind = bsrkProcedure then
            LAlignScopeStack.Add(LCurrentAlignRecord)
          else if (LCurrentAlignRecord.Kind = bsrkEnd) and
            (LAlignScopeStack.Count > 0) then
            LAlignScopeStack.Delete(LAlignScopeStack.Count - 1);
        end;

        LCurrentGlobalSymbolRecord := nil;
        if LCurrentGlobalSymbolSection <> nil then
        begin
          LCurrentGlobalSymbolRecord := TDumpGlobalSymbolRecord.Create;
          LCurrentGlobalSymbolRecord.RawRecordOffset := LRecordOffsetText;
          TryParseHexUIntToken(LRecordOffsetText,
            LCurrentGlobalSymbolRecord.RecordOffset);
          LCurrentGlobalSymbolRecord.RecordKind := LRecordKind;
          LCurrentGlobalSymbolRecord.Node := LCurrentRecord;
          LCurrentGlobalSymbolRecord.HeaderLine := FDocument.Lines[LIndex];
          LCurrentGlobalSymbolRecord.DetailLines.Add(
            LCurrentGlobalSymbolRecord.HeaderLine);
          LCurrentGlobalSymbolRecord.StartLine := LIndex + 1;
          LCurrentGlobalSymbolRecord.EndLine := LIndex + 1;
          LCurrentGlobalSymbolSection.Records.Add(LCurrentGlobalSymbolRecord);
          ParseBorlandSymbolRecordDetails(LCurrentGlobalSymbolRecord, LLine,
            LIndex + 1);
        end;

        LCurrentRecordKind := LRecordKind;
        LCurrentRecordHasSymbol := TryParseBorlandSymbolLine(LRecordKind, LLine,
          LIndex + 1, LSymbol);
        if LCurrentRecordHasSymbol then
        begin
          FDocument.Symbols.Add(LSymbol);
          if LCurrentAlignSection <> nil then
            LCurrentAlignSection.Symbols.Add(LSymbol);
          LProperty.Name := LSymbol.Name;
          LProperty.RawValue := LSymbol.RawText;
          LProperty.ValueKind := vkAddress;
          LProperty.UIntValue := LSymbol.Address;
          LProperty.HasUIntValue := LSymbol.HasAddress;
          LProperty.TextValue := LSymbol.Name;
          LProperty.StartLine := LSymbol.StartLine;
          LCurrentRecord.Properties.Add(LProperty);
        end;
        if TryParseBorlandSymbolSearchLine(LLine, LIndex + 1, LSymbolSearch) then
        begin
          LSymbolSearch.Node := LCurrentRecord;
          FDocument.SymbolSearches.Add(LSymbolSearch);
          if LCurrentAlignSection <> nil then
            LCurrentAlignSection.Searches.Add(LSymbolSearch);
        end;
        Continue;
      end;

      if LCurrentRecord <> nil then
      begin
        AppendNodeRawLine(LCurrentRecord, LLine);
        LCurrentRecord.EndLine := LIndex + 1;
        if LCurrentGlobalSymbolRecord <> nil then
          LCurrentGlobalSymbolRecord.EndLine := LIndex + 1;
        if LCurrentGlobalTypeRecord <> nil then
          LCurrentGlobalTypeRecord.EndLine := LIndex + 1;
        if LCurrentAlignRecord <> nil then
        begin
          LCurrentAlignRecord.DetailLines.Add(FDocument.Lines[LIndex]);
          ParseBorlandSymbolRecordDetails(LCurrentAlignRecord, LLine,
            LIndex + 1);
        end;
        if LCurrentGlobalSymbolRecord <> nil then
        begin
          LCurrentGlobalSymbolRecord.DetailLines.Add(FDocument.Lines[LIndex]);
          ParseBorlandSymbolRecordDetails(LCurrentGlobalSymbolRecord, LLine,
            LIndex + 1);
        end;
        if LCurrentGlobalTypeRecord <> nil then
        begin
          LCurrentGlobalTypeRecord.DetailLines.Add(FDocument.Lines[LIndex]);
          ParseBorlandGlobalTypeDetails(LCurrentGlobalTypeRecord, LLine,
            LIndex + 1);
        end;
        if TryParsePropertyLine(LLine, LIndex + 1, LProperty) then
          LCurrentRecord.Properties.Add(LProperty);
        if not LCurrentRecordHasSymbol and TryParseBorlandSymbolLine(
          LCurrentRecordKind, LLine, LIndex + 1, LSymbol) then
        begin
          FDocument.Symbols.Add(LSymbol);
          if LCurrentAlignSection <> nil then
            LCurrentAlignSection.Symbols.Add(LSymbol);
          LCurrentRecordHasSymbol := True;
          LProperty.Name := LSymbol.Name;
          LProperty.RawValue := LSymbol.RawText;
          LProperty.ValueKind := vkAddress;
          LProperty.UIntValue := LSymbol.Address;
          LProperty.HasUIntValue := LSymbol.HasAddress;
          LProperty.TextValue := LSymbol.Name;
          LProperty.StartLine := LSymbol.StartLine;
          LCurrentRecord.Properties.Add(LProperty);
        end;
        Continue;
      end;

      if LCurrentSubsection <> nil then
      begin
        AppendNodeRawLine(LCurrentSubsection, LLine);
        LCurrentSubsection.EndLine := LIndex + 1;
        if TryParsePropertyLine(LLine, LIndex + 1, LProperty) then
          LCurrentSubsection.Properties.Add(LProperty);
      end;
    end;
  finally
    LAlignScopeStack.Free;
    if LCurrentRecord <> nil then
      LCurrentRecord.EndLine := LTableEnd + 1;
    if LCurrentAlignRecord <> nil then
      LCurrentAlignRecord.EndLine := LTableEnd + 1;
    if LCurrentGlobalSymbolRecord <> nil then
      LCurrentGlobalSymbolRecord.EndLine := LTableEnd + 1;
    if LCurrentGlobalTypeRecord <> nil then
      LCurrentGlobalTypeRecord.EndLine := LTableEnd + 1;
    if LCurrentSubsection <> nil then
      LCurrentSubsection.EndLine := LTableEnd + 1;
    if LCurrentModule <> nil then
      LCurrentModule.EndLine := LTableEnd + 1;
    if LCurrentSourceModule <> nil then
      LCurrentSourceModule.EndLine := LTableEnd + 1;
    if LCurrentAlignSection <> nil then
      LCurrentAlignSection.EndLine := LTableEnd + 1;
    if LCurrentGlobalSymbolSection <> nil then
      LCurrentGlobalSymbolSection.EndLine := LTableEnd + 1;
    if LCurrentGlobalTypeSection <> nil then
      LCurrentGlobalTypeSection.EndLine := LTableEnd + 1;
    if LCurrentBorlandSubsection <> nil then
      LCurrentBorlandSubsection.EndLine := LTableEnd + 1;
  end;
  ResolveBorlandReferences;
end;

function TDumpParser.IsKnownTopLevelHeading(const ALine: string): Boolean;
begin
  var LLine := Trim(ALine);
  Result := SameText(LLine, SPortableExecutableHeader) or
    SameText(LLine, 'New Executable (NE) File') or
    SameText(LLine, 'Linear Executable (LE) File') or
    SameText(LLine, 'Object table:') or SameText(LLine, 'Resources:') or
    StartsWithText(LLine, 'Section:');
end;

function TDumpParser.TryParsePropertyLine(const ALine: string;
  ALineNumber: Integer; out AProperty: TDumpProperty): Boolean;
  function LooksLikeValueStart(AIndex: Integer): Boolean;
  begin
    var LChar := ALine[AIndex];
    Result := CharInSet(ALine[AIndex - 1], [' ', #9]) and
      CharInSet(LChar, ['0'..'9', 'A'..'F', 'a'..'f', '?']);
  end;

begin
  var LStartValue := 0;
  var LSpacePos: Integer;
  var LColonPos: Integer;
  var LNameText: string;
  var LRawValue: string;
  var LFirst: string;
  var LValue: UInt64;
  FillChar(AProperty, SizeOf(AProperty), 0);
  Result := False;
  LColonPos := Pos(':', ALine);
  if (LColonPos > 1) and (ALine[LColonPos - 1] <> ' ') and
    (Pos('(', Copy(ALine, 1, LColonPos - 1)) = 0) then
  begin
    LNameText := Trim(Copy(ALine, 1, LColonPos - 1));
    LRawValue := Trim(Copy(ALine, LColonPos + 1, MaxInt));
  end
  else
  begin
    for var LIndex := 2 to Length(ALine) do
      if LooksLikeValueStart(LIndex) and CharInSet(ALine[LIndex - 1], [' ', #9]) and
        ((LIndex <= 2) or CharInSet(ALine[LIndex - 2], [' ', #9])) then
      begin
        LStartValue := LIndex;
        Break;
      end;
    if LStartValue = 0 then
      Exit;
    LNameText := Trim(Copy(ALine, 1, LStartValue - 1));
    LRawValue := Trim(Copy(ALine, LStartValue, MaxInt));
  end;

  if (LNameText = '') or (LRawValue = '') then
    Exit;

  LFirst := LRawValue;
  LSpacePos := Pos(' ', LFirst);
  if LSpacePos > 0 then
    LFirst := Copy(LFirst, 1, LSpacePos - 1);

  AProperty.Name := LNameText;
  AProperty.RawValue := LRawValue;
  AProperty.TextValue := LRawValue;
  AProperty.StartLine := ALineNumber;
  AProperty.ValueKind := PropertyValueKind(LNameText);

  if ((Pos('flags', LowerCase(LNameText)) > 0) and TryParseHexUIntToken(LFirst, LValue)) or
    TryParseUIntToken(LFirst, LValue) then
  begin
    AProperty.UIntValue := LValue;
    AProperty.HasUIntValue := True;
    if AProperty.ValueKind = vkUnknown then
      AProperty.ValueKind := vkUInt;
  end
  else
    AProperty.HasUIntValue := False;
  Result := True;
end;

function TDumpParser.TryParseDataDirectoryLine(const ALine: string;
  ALineNumber: Integer; AIndex: Integer; out ADirectory: TDumpDataDirectory;
  out AProperty: TDumpProperty): Boolean;
begin
  var LWork: string;
  var LRawSize: string;
  var LRawRVA: string;
  var LName: string;
  var LRVAValue: UInt64;
  var LSizeValue: UInt64;
  FillChar(ADirectory, SizeOf(ADirectory), 0);
  FillChar(AProperty, SizeOf(AProperty), 0);
  Result := False;
  LWork := Trim(ALine);
  LRawSize := LastToken(LWork);
  LRawRVA := LastToken(LWork);
  LName := Trim(LWork);
  if (LName = '') or (LRawRVA = '') or (LRawSize = '') then
    Exit;
  if not TryParseHexUIntToken(LRawRVA, LRVAValue) then
    Exit;
  if not TryParseHexUIntToken(LRawSize, LSizeValue) then
    Exit;

  ADirectory.Index := AIndex;
  ADirectory.Name := LName;
  ADirectory.RVA := LRVAValue;
  ADirectory.Size := LSizeValue;
  ADirectory.RawRVA := LRawRVA;
  ADirectory.RawSize := LRawSize;
  ADirectory.StartLine := ALineNumber;

  AProperty.Name := LName;
  AProperty.RawValue := LRawRVA + ' ' + LRawSize;
  AProperty.TextValue := AProperty.RawValue;
  AProperty.ValueKind := vkRVA;
  AProperty.UIntValue := LRVAValue;
  AProperty.HasUIntValue := True;
  AProperty.StartLine := ALineNumber;
  Result := True;
end;

function TDumpParser.TryParseObjectTableLine(const ALine: string;
  ALineNumber: Integer; out ASection: TDumpSection;
  out AProperty: TDumpProperty): Boolean;
begin
  var LWork: string;
  var LToken: string;
  var LFlagsToken: string;
  var LValue: UInt64;
  ASection := nil;
  FillChar(AProperty, SizeOf(AProperty), 0);
  Result := False;
  LWork := Trim(ALine);

  ASection := TDumpSection.Create;
  try
    LToken := FirstToken(LWork);
    if not TryParseHexUIntToken(LToken, LValue) then
      Exit;
    ASection.Index := LValue;

    ASection.Name := FirstToken(LWork);
    if ASection.Name = '' then
      Exit;

    LToken := FirstToken(LWork);
    if not TryParseHexUIntToken(LToken, ASection.VirtualSize) then
      Exit;
    LToken := FirstToken(LWork);
    if not TryParseHexUIntToken(LToken, ASection.RVA) then
      Exit;
    LToken := FirstToken(LWork);
    if not TryParseHexUIntToken(LToken, ASection.RawSize) then
      Exit;
    LToken := FirstToken(LWork);
    if not TryParseHexUIntToken(LToken, ASection.RawOffset) then
      Exit;
    LFlagsToken := FirstToken(LWork);
    if not TryParseHexUIntToken(LFlagsToken, ASection.FlagsValue) then
      Exit;
    ASection.FlagsText := Trim(LWork);
    ASection.StartLine := ALineNumber;

    AProperty.Name := ASection.Name;
    AProperty.RawValue := ALine;
    AProperty.TextValue := ASection.FlagsText;
    AProperty.ValueKind := vkRVA;
    AProperty.UIntValue := ASection.RVA;
    AProperty.HasUIntValue := True;
    AProperty.StartLine := ALineNumber;

    Result := True;
  finally
    if not Result then
      ASection.Free;
  end;
end;

function TDumpParser.TryParseImportLine(const ALine: string;
  ALineNumber: Integer; out AImport: TDumpImport): Boolean;
begin
  var LText: string;
  var LHintText: string;
  var LClosePos: Integer;
  var LValue: UInt64;
  AImport := nil;
  LText := Trim(ALine);
  Result := False;
  if LText = '' then
    Exit;

  AImport := TDumpImport.Create;
  try
    AImport.RawText := ALine;
    AImport.StartLine := ALineNumber;

    if StartsWithText(LText, '(hint =') then
    begin
      LClosePos := Pos(')', LText);
      if LClosePos > 0 then
      begin
        LHintText := Trim(Copy(LText, Length('(hint =') + 1, LClosePos - Length('(hint =') - 1));
        if TryParseHexUIntToken(LHintText, LValue) then
        begin
          AImport.Hint := LValue;
          AImport.HasHint := True;
        end;
        LText := Trim(Copy(LText, LClosePos + 1, MaxInt));
      end;
    end;

    if StartsWithText(LowerCase(LText), 'ordinal ') then
    begin
      LHintText := Trim(Copy(LText, Length('ordinal ') + 1, MaxInt));
      if TryParseUIntToken(LHintText, LValue) then
      begin
        AImport.Ordinal := LValue;
        AImport.HasOrdinal := True;
      end;
      AImport.Name := LText;
    end
    else
      AImport.Name := LText;

    AImport.MangledName := AImport.Name;
    Result := AImport.Name <> '';
  finally
    if not Result then
      AImport.Free;
  end;
end;

function TDumpParser.TryParseExportLine(const ALine: string;
  ALineNumber: Integer; out AExport: TDumpExport): Boolean;
begin
  AExport := nil;
  Result := False;
  var LText := Trim(ALine);
  if LText = '' then
    Exit(False);

  AExport := TDumpExport.Create;
  try
    AExport.RawText := ALine;
    AExport.StartLine := ALineNumber;

    var LToken := FirstToken(LText);
    if not TryParseHexUIntToken(LToken, AExport.RVA) then
      Exit(False);
    AExport.HasRVA := True;

    LToken := FirstToken(LText);
    if TryParseUIntToken(LToken, AExport.Ordinal) then
      AExport.HasOrdinal := True;

    LToken := FirstToken(LText);
    if TryParseHexUIntToken(LToken, AExport.Hint) then
      AExport.HasHint := True;

    AExport.Name := LText;
    AExport.MangledName := AExport.Name;
    Result := AExport.Name <> '';
  finally
    if not Result then
      AExport.Free;
  end;
end;

function TDumpParser.TryParseResourceLine(const ALine: string;
  ALineNumber: Integer; out AIndent: Integer;
  out AResource: TDumpResource): Boolean;
begin
  AIndent := 0;
  AResource := nil;
  Result := False;
  while (AIndent < Length(ALine)) and CharInSet(ALine[AIndent + 1], [' ', #9]) do
    Inc(AIndent);

  var LText := Trim(ALine);
  if LText = '' then
    Exit;

  if StartsWithText(LText, 'type:') then
  begin
    Delete(LText, 1, Length('type:'));
    LText := Trim(LText);
    var LOpenParen := Pos('(', LText);
    if LOpenParen = 0 then
      Exit;
    var LCloseParen := Pos(')', Copy(LText, LOpenParen + 1, MaxInt));
    if LCloseParen = 0 then
      Exit;
    LCloseParen := LCloseParen + LOpenParen;

    AResource := TDumpResource.Create;
    try
      AResource.ResourceType := Trim(Copy(LText, 1, LOpenParen - 1));
      AResource.Name := AResource.ResourceType;
      var LIdText := Trim(Copy(LText, LOpenParen + 1, LCloseParen - LOpenParen - 1));
      AResource.HasId := TryParseUIntToken(LIdText, AResource.Id);
      AResource.StartLine := ALineNumber;
      AResource.EndLine := ALineNumber;
      var LDirectoryAtPos := Pos('@', LText);
      if LDirectoryAtPos > 0 then
      begin
        var LDirectoryOffsetText := Copy(LText, LDirectoryAtPos + 1, MaxInt);
        var LDirectoryOffsetEnd := Pos(')', LDirectoryOffsetText);
        if LDirectoryOffsetEnd > 0 then
          LDirectoryOffsetText := Copy(LDirectoryOffsetText, 1,
            LDirectoryOffsetEnd - 1);
        AResource.HasDirectoryOffset := TryParseHexUIntToken(
          Trim(LDirectoryOffsetText), AResource.DirectoryOffset);
      end;

      var LProperty: TDumpProperty;
      LProperty.Name := 'Type';
      LProperty.RawValue := AResource.ResourceType + ' (' + LIdText + ')';
      LProperty.ValueKind := vkText;
      LProperty.UIntValue := AResource.Id;
      LProperty.HasUIntValue := AResource.HasId;
      LProperty.TextValue := AResource.ResourceType;
      LProperty.StartLine := ALineNumber;
      AResource.Properties.Add(LProperty);
      Result := AResource.ResourceType <> '';
    finally
      if not Result then
        AResource.Free;
    end;
    Exit;
  end;

  // BPL resources can use named directory entries instead of a "type:" row.
  var LOpenParen := Pos('(', LText);
  if LOpenParen = 0 then
    Exit;
  var LName := Trim(Copy(LText, 1, LOpenParen - 1));
  if (LName = '') or (LName[1] = '[') or (Pos(':', LName) > 0) then
    Exit;

  AResource := TDumpResource.Create;
  try
    AResource.Name := LName;
    AResource.ResourceType := 'Named resource directory';
    AResource.StartLine := ALineNumber;
    AResource.EndLine := ALineNumber;
    var LDirectoryAtPos := Pos('@', LText);
    if LDirectoryAtPos > 0 then
    begin
      var LDirectoryOffsetText := Copy(LText, LDirectoryAtPos + 1, MaxInt);
      var LDirectoryOffsetEnd := Pos(')', LDirectoryOffsetText);
      if LDirectoryOffsetEnd > 0 then
        LDirectoryOffsetText := Copy(LDirectoryOffsetText, 1,
          LDirectoryOffsetEnd - 1);
      AResource.HasDirectoryOffset := TryParseHexUIntToken(
        Trim(LDirectoryOffsetText), AResource.DirectoryOffset);
    end;

    var LProperty: TDumpProperty;
    LProperty.Name := 'Directory metadata';
    LProperty.RawValue := Trim(Copy(LText, LOpenParen, MaxInt));
    LProperty.ValueKind := vkText;
    LProperty.UIntValue := 0;
    LProperty.HasUIntValue := False;
    LProperty.TextValue := LProperty.RawValue;
    LProperty.StartLine := ALineNumber;
    AResource.Properties.Add(LProperty);
    Result := True;
  finally
    if not Result then
      AResource.Free;
  end;
end;

function TDumpParser.TryParseBorlandSymbolLine(const ARecordKind, ALine: string;
  ALineNumber: Integer; out ASymbol: TDumpSymbol): Boolean;
begin
  ASymbol := nil;
  Result := False;
  var LKind := BorlandSymbolKind(ARecordKind);
  if LKind = skUnknown then
    Exit;

  var LText := Trim(ALine);
  var LSearchStart := 1;
  while LSearchStart <= Length(LText) do
  begin
    var LColonPos := PosEx(':', LText, LSearchStart);
    if LColonPos = 0 then
      Exit;

    var LBeforeColon := Copy(LText, 1, LColonPos - 1);
    var LSectionText := LastToken(LBeforeColon);
    var LAfterColon := Copy(LText, LColonPos + 1, MaxInt);
    var LAddressText := FirstToken(LAfterColon);
    var LRangePos := Pos('-', LAddressText);
    if LRangePos > 0 then
      LAddressText := Copy(LAddressText, 1, LRangePos - 1);

    var LSectionValue: UInt64;
    var LAddressValue: UInt64;
    if TryParseHexUIntToken(LSectionText, LSectionValue) and
      TryParseHexUIntToken(LAddressText, LAddressValue) then
    begin
      var LName := Trim(LAfterColon);
      if StartsWithText(LName, 'Name:') then
        LName := Trim(Copy(LName, Length('Name:') + 1, MaxInt));
      var LNameEnd := Pos(' [', LName);
      if LNameEnd > 0 then
        LName := Trim(Copy(LName, 1, LNameEnd - 1));
      if LName = '' then
        Exit;

      ASymbol := TDumpSymbol.Create;
      ASymbol.Name := LName;
      ASymbol.MangledName := LName;
      ASymbol.Kind := LKind;
      ASymbol.Address := LAddressValue;
      ASymbol.HasAddress := True;
      ASymbol.SectionName := LSectionText;
      ASymbol.RecordKind := ARecordKind;
      ASymbol.RawText := ALine;
      ASymbol.StartLine := ALineNumber;

      var LProperty: TDumpProperty;
      LProperty.Name := 'Address';
      LProperty.RawValue := LSectionText + ':' + LAddressText;
      LProperty.ValueKind := vkAddress;
      LProperty.UIntValue := LAddressValue;
      LProperty.HasUIntValue := True;
      LProperty.TextValue := LProperty.RawValue;
      LProperty.StartLine := ALineNumber;
      ASymbol.Properties.Add(LProperty);
      Result := True;
      Exit;
    end;
    LSearchStart := LColonPos + 1;
  end;
end;

function TDumpParser.TryParseBorlandSymbolSearchLine(const ALine: string;
  ALineNumber: Integer; out ASearch: TDumpSymbolSearch): Boolean;
  function ValueAfterLabel(const ALabel: string): string;
  begin
    var LLabelPos := Pos(ALabel, ALine);
    if LLabelPos = 0 then
      Exit('');
    var LValueText := Copy(ALine, LLabelPos + Length(ALabel), MaxInt);
    Result := FirstToken(LValueText);
  end;

begin
  ASearch := nil;
  Result := False;
  var LRecordPos := Pos('S_SSEARCH', ALine);
  if LRecordPos = 0 then
    Exit;

  var LPrefix := Trim(Copy(ALine, 1, LRecordPos - 1));
  var LRecordOffsetText := FirstToken(LPrefix);
  var LLocationText := Trim(Copy(ALine, LRecordPos + Length('S_SSEARCH'), MaxInt));
  var LLocationColonPos := Pos(':', LLocationText);
  if LLocationColonPos = 0 then
    Exit;
  var LSegmentSource := Copy(LLocationText, 1, LLocationColonPos - 1);
  var LSegmentText := LastToken(LSegmentSource);
  var LAddressSource := Copy(LLocationText, LLocationColonPos + 1, MaxInt);
  var LAddressText := FirstToken(LAddressSource);
  var LCodeSymbolsText := ValueAfterLabel('CodeSyms:');
  var LDataSymbolsText := ValueAfterLabel('DataSyms');
  var LFirstDataText := ValueAfterLabel('FirstData:');
  if (LRecordOffsetText = '') or (LSegmentText = '') or (LAddressText = '') or
    (LCodeSymbolsText = '') or (LDataSymbolsText = '') or (LFirstDataText = '') then
    Exit;

  ASearch := TDumpSymbolSearch.Create;
  try
    var LRecordOffset: UInt64;
    var LSegment: UInt64;
    var LAddress: UInt64;
    var LCodeSymbols: UInt64;
    var LDataSymbols: UInt64;
    var LFirstData: UInt64;
    if not TryParseHexUIntToken(LRecordOffsetText, LRecordOffset) or
      not TryParseHexUIntToken(LSegmentText, LSegment) or
      not TryParseHexUIntToken(LAddressText, LAddress) or
      not TryParseHexUIntToken(LCodeSymbolsText, LCodeSymbols) or
      not TryParseHexUIntToken(LDataSymbolsText, LDataSymbols) or
      not TryParseHexUIntToken(LFirstDataText, LFirstData) then
      Exit;
    ASearch.RecordOffset := LRecordOffset;
    ASearch.Segment := LSegment;
    ASearch.Address := LAddress;
    ASearch.CodeSymbols := LCodeSymbols;
    ASearch.DataSymbols := LDataSymbols;
    ASearch.FirstData := LFirstData;
    ASearch.RawRecordOffset := LRecordOffsetText;
    ASearch.RawSegment := LSegmentText;
    ASearch.RawAddress := LAddressText;
    ASearch.RawCodeSymbols := LCodeSymbolsText;
    ASearch.RawDataSymbols := LDataSymbolsText;
    ASearch.RawFirstData := LFirstDataText;
    ASearch.StartLine := ALineNumber;
    Result := True;
  finally
    if not Result then
      ASearch.Free;
  end;
end;

function TDumpParser.TryParseBorlandGlobalTypeLine(const ALine: string;
  ALineNumber: Integer; out ATypeRecord: TDumpGlobalTypeRecord): Boolean;
begin
  ATypeRecord := nil;
  Result := False;
  var LTypeLabelPos := Pos('Type:', ALine);
  var LLengthLabelPos := Pos('Len:', ALine);
  if (LTypeLabelPos = 0) or (LLengthLabelPos = 0) then
    Exit;

  var LPrefix := Trim(Copy(ALine, 1, LTypeLabelPos - 1));
  var LRecordOffsetText := FirstToken(LPrefix);
  var LTypeIndexText := ValueForLabel(ALine, 'Type:');
  var LLengthText := ValueForLabel(ALine, 'Len:');
  var LKindSource := Copy(ALine, LLengthLabelPos + Length('Len:'), MaxInt);
  FirstToken(LKindSource);
  var LTypeKind := FirstToken(LKindSource);
  if (LRecordOffsetText = '') or (LTypeIndexText = '') or (LLengthText = '') or
    (LTypeKind = '') then
    Exit;

  var LRecordOffset: UInt64;
  var LTypeIndex: UInt64;
  var LLength: UInt64;
  if not TryParseHexUIntToken(LRecordOffsetText, LRecordOffset) or
    not TryParseHexUIntToken(LTypeIndexText, LTypeIndex) or
    not TryParseHexUIntToken(LLengthText, LLength) then
    Exit;

  ATypeRecord := TDumpGlobalTypeRecord.Create;
  ATypeRecord.RecordOffset := LRecordOffset;
  ATypeRecord.RawRecordOffset := LRecordOffsetText;
  ATypeRecord.TypeIndex := LTypeIndex;
  ATypeRecord.RawTypeIndex := LTypeIndexText;
  ATypeRecord.Length := LLength;
  ATypeRecord.RawLength := LLengthText;
  ATypeRecord.TypeKind := LTypeKind;
  ATypeRecord.StartLine := ALineNumber;
  ATypeRecord.EndLine := ALineNumber;
  Result := True;
end;

procedure TDumpParser.ParseBorlandSymbolRecordDetails(
  ARecord: TDumpBorlandSymbolRecord; const ALine: string;
  ALineNumber: Integer);
  procedure AddProperty(const AName, ARawValue: string);
  begin
    if ARawValue = '' then
      Exit;
    var LProperty: TDumpProperty;
    LProperty.Name := AName;
    LProperty.RawValue := ARawValue;
    LProperty.ValueKind := PropertyValueKind(AName);
    LProperty.HasUIntValue := TryParseHexUIntToken(ARawValue, LProperty.UIntValue);
    LProperty.TextValue := ARawValue;
    LProperty.StartLine := ALineNumber;
    ARecord.Properties.Add(LProperty);
  end;

  procedure ReadTypeIndex;
  begin
    var LTypeText := ValueForLabel(ALine, 'Type:');
    if LTypeText = '' then
      LTypeText := ValueForLabel(ALine, 'type:');
    if TryParseHexUIntToken(LTypeText, ARecord.TypeIndex) then
    begin
      ARecord.RawTypeIndex := LTypeText;
      ARecord.HasTypeIndex := True;
      AddProperty('Type', LTypeText);
    end;
  end;

  procedure ReadNameReference;
  begin
    var LCloseBracket := LastDelimiter(']', ALine);
    var LOpenBracket := LastDelimiter('[', ALine);
    if (LOpenBracket = 0) or (LCloseBracket <= LOpenBracket) then
      Exit;
    var LNameIndexText := Copy(ALine, LOpenBracket + 1,
      LCloseBracket - LOpenBracket - 1);
    if TryParseHexUIntToken(LNameIndexText, ARecord.NameIndex) then
    begin
      ARecord.RawNameIndex := LNameIndexText;
      ARecord.HasNameIndex := True;
      AddProperty('Name index', LNameIndexText);
      if ARecord.NameIndices.IndexOf(ARecord.NameIndex) < 0 then
        ARecord.NameIndices.Add(ARecord.NameIndex);
    end;

    if ARecord.Name = '' then
    begin
      var LNamePrefix := Trim(Copy(ALine, 1, LOpenBracket - 1));
      if Pos('Name ', LNamePrefix) > 0 then
        LNamePrefix := Trim(Copy(LNamePrefix, Pos('Name ', LNamePrefix) +
          Length('Name '), MaxInt));
      ARecord.Name := LastToken(LNamePrefix);
    end;
  end;

  procedure ReadAddress;
  begin
    var LText := Trim(ALine);
    var LSearchStart := 1;
    while LSearchStart <= Length(LText) do
    begin
      var LColonPos := PosEx(':', LText, LSearchStart);
      if LColonPos = 0 then
        Exit;
      var LBeforeColon := Copy(LText, 1, LColonPos - 1);
      var LSegmentText := LastToken(LBeforeColon);
      var LAfterColon := Copy(LText, LColonPos + 1, MaxInt);
      var LRangeText := FirstToken(LAfterColon);
      var LDashPos := Pos('-', LRangeText);
      var LAddressText := LRangeText;
      var LEndAddressText := '';
      if LDashPos > 0 then
      begin
        LAddressText := Copy(LRangeText, 1, LDashPos - 1);
        LEndAddressText := Copy(LRangeText, LDashPos + 1, MaxInt);
      end;
      var LSegment: UInt64;
      var LAddress: UInt64;
      if TryParseHexUIntToken(LSegmentText, LSegment) and
        TryParseHexUIntToken(LAddressText, LAddress) then
      begin
        ARecord.Segment := LSegment;
        ARecord.RawSegment := LSegmentText;
        ARecord.Address := LAddress;
        ARecord.RawAddress := LAddressText;
        ARecord.HasAddress := True;
        if TryParseHexUIntToken(LEndAddressText, ARecord.EndAddress) then
        begin
          ARecord.RawEndAddress := LEndAddressText;
          ARecord.HasEndAddress := True;
        end;
        AddProperty('Address', LSegmentText + ':' + LRangeText);
        if (ARecord.Name = '') and (LAfterColon <> '') then
        begin
          var LNameEnd := Pos(' [', LAfterColon);
          if LNameEnd > 0 then
            ARecord.Name := Trim(Copy(LAfterColon, 1, LNameEnd - 1));
        end;
        Exit;
      end;
      LSearchStart := LColonPos + 1;
    end;
  end;

begin
  ARecord.Kind := BorlandSymbolRecordKind(ARecord.RecordKind);
  var LProperty: TDumpProperty;
  if TryParsePropertyLine(ALine, ALineNumber, LProperty) then
    ARecord.Properties.Add(LProperty);
  ReadTypeIndex;
  ReadNameReference;
  ReadAddress;

  var LParentText := ValueForLabel(ALine, 'Parent:');
  var LEndText := ValueForLabel(ALine, 'End:');
  var LNextText := ValueForLabel(ALine, 'Next:');
  if TryParseHexUIntToken(LParentText, ARecord.ParentOffset) and
    TryParseHexUIntToken(LEndText, ARecord.EndOffset) and
    TryParseHexUIntToken(LNextText, ARecord.NextOffset) then
  begin
    ARecord.HasScopeOffsets := True;
    AddProperty('Parent', LParentText);
    AddProperty('End', LEndText);
    AddProperty('Next', LNextText);
  end;

  var LLinkerName := ValueForLabel(ALine, 'Linker name:');
  if LLinkerName <> '' then
  begin
    ARecord.Name := LLinkerName.Trim(['''']);
    AddProperty('Linker name', LLinkerName);
  end;
  var LValue := ValueForLabel(ALine, 'Value:');
  if LValue <> '' then
  begin
    ARecord.Value := LValue;
    AddProperty('Value', LValue);
  end;
  AddProperty('Machine', ValueForLabel(ALine, 'machine:'));
  AddProperty('Language', ValueForLabel(ALine, 'language:'));
  AddProperty('Namespace', ValueForLabel(ALine, 'Namespace:'));
  AddProperty('Unit', ValueForLabel(ALine, 'Unit:'));
  AddProperty('Register', ValueForLabel(ALine, 'Register:'));
  AddProperty('Start', ValueForLabel(ALine, 'Start:'));
  AddProperty('Length', ValueForLabel(ALine, 'Len:'));
end;

procedure TDumpParser.ParseBorlandGlobalTypeDetails(
  AGlobalType: TDumpGlobalTypeRecord; const ALine: string;
  ALineNumber: Integer);
  procedure AddDetailProperty(ADetail: TDumpGlobalTypeDetail;
    const AName, ARawValue: string);
  begin
    if ARawValue = '' then
      Exit;
    var LProperty: TDumpProperty;
    LProperty.Name := AName;
    LProperty.RawValue := ARawValue;
    LProperty.ValueKind := PropertyValueKind(AName);
    LProperty.HasUIntValue := TryParseHexUIntToken(ARawValue,
      LProperty.UIntValue);
    LProperty.TextValue := ARawValue;
    LProperty.StartLine := ALineNumber;
    ADetail.Properties.Add(LProperty);
  end;

  procedure ReadDetailType(const AText: string; out ARawType: string;
    out ATypeIndex: UInt64; out AHasTypeIndex: Boolean);
  begin
    ARawType := AText;
    AHasTypeIndex := TryParseHexUIntToken(ARawType, ATypeIndex);
  end;

  procedure AddTypeReference(const AText: string);
  begin
    var LTypeIndex: UInt64;
    if TryParseHexUIntToken(AText, LTypeIndex) and
      (LTypeIndex <> AGlobalType.TypeIndex) and
      (AGlobalType.ReferencedTypeIndices.IndexOf(LTypeIndex) < 0) then
      AGlobalType.ReferencedTypeIndices.Add(LTypeIndex);
  end;

begin
  var LProperty: TDumpProperty;
  if TryParsePropertyLine(ALine, ALineNumber, LProperty) then
    AGlobalType.Properties.Add(LProperty);

  var LTrimmed := Trim(ALine);
  if (LTrimmed = '') or ((Pos(' Type:', LTrimmed) > 0) and
    (Pos(' Len:', LTrimmed) > 0)) then
    Exit;

  // Every non-blank type continuation receives a semantic detail object.
  var LDetail := TDumpGlobalTypeDetail.Create;
  LDetail.SourceLine := FDocument.Lines[ALineNumber - 1];
  if StartsWithText(LTrimmed, 'MEMBER') or
    StartsWithText(LTrimmed, 'ENUMERATE') then
    LDetail.Kind := gtdkMember
  else if Pos('PtrType:', LTrimmed) > 0 then
    LDetail.Kind := gtdkPointerAttributes
  else if StartsWithText(LTrimmed, 'Points to:') then
    LDetail.Kind := gtdkPointerTarget
  else if StartsWithText(LTrimmed, 'near ') then
    LDetail.Kind := gtdkProcedureSignature
  else if StartsWithText(LTrimmed, 'Params:') then
    LDetail.Kind := gtdkProcedureParameters
  else if StartsWithText(LTrimmed, 'Type:') then
    LDetail.Kind := gtdkArgumentType
  else if StartsWithText(LTrimmed, 'Fields:') or
    StartsWithText(LTrimmed, 'Containing Class:') or
    StartsWithText(LTrimmed, 'Derivation list:') or
    StartsWithText(LTrimmed, 'Packed:') or StartsWithText(LTrimmed, 'Is nested:') or
    StartsWithText(LTrimmed, 'Casting methods:') then
    LDetail.Kind := gtdkAggregateLayout
  else if SameText(AGlobalType.TypeKind, 'PARRAY') then
    LDetail.Kind := gtdkArrayLayout
  else if SameText(AGlobalType.TypeKind, 'SUBRANGE') then
    LDetail.Kind := gtdkSubrangeLayout
  else if SameText(AGlobalType.TypeKind, 'PSTRING') or
    SameText(AGlobalType.TypeKind, 'USTRING') then
    LDetail.Kind := gtdkStringLayout
  else if StartsWithText(LTrimmed, 'Name:') then
    LDetail.Kind := gtdkNamedType;

  if StartsWithText(LTrimmed, 'Type:') then
    ReadDetailType(ValueForLabel(ALine, 'Type:'), LDetail.TypeText,
      LDetail.TypeIndex, LDetail.HasTypeIndex)
  else if StartsWithText(LTrimmed, 'Points to:') then
    ReadDetailType(ValueForLabel(ALine, 'Points to:'), LDetail.RelatedTypeText,
      LDetail.RelatedTypeIndex, LDetail.HasRelatedTypeIndex);
  if Pos('PtrType:', LTrimmed) > 0 then
  begin
    LDetail.PointerFlavor := FirstToken(LTrimmed);
    LDetail.PointerType := ValueForLabel(ALine, 'PtrType:');
    LDetail.PointerMode := ValueForLabel(ALine, 'PtrMode:');
  end;
  if StartsWithText(LTrimmed, 'near ') then
  begin
    LDetail.CallingConvention := FirstToken(LTrimmed);
    var LReturnsPos := Pos(' returns ', LTrimmed);
    if LReturnsPos > 0 then
      LDetail.ReturnType := Trim(Copy(LTrimmed, LReturnsPos + 9, MaxInt));
  end;
  AddDetailProperty(LDetail, 'Type', ValueForLabel(ALine, 'Type:'));
  AddDetailProperty(LDetail, 'Points to', ValueForLabel(ALine, 'Points to:'));
  AddDetailProperty(LDetail, 'Params', ValueForLabel(ALine, 'Params:'));
  AddDetailProperty(LDetail, 'ArgList', ValueForLabel(ALine, 'ArgList:'));
  AddDetailProperty(LDetail, 'Fields', ValueForLabel(ALine, 'Fields:'));
  AddDetailProperty(LDetail, 'FieldIdx', ValueForLabel(ALine, 'FieldIdx:'));
  AddDetailProperty(LDetail, 'Indexed by', ValueForLabel(ALine, 'Indexed by:'));
  AddDetailProperty(LDetail, 'Size', ValueForLabel(ALine, 'Size:'));
  AddDetailProperty(LDetail, 'Elements', ValueForLabel(ALine, 'Elements:'));
  AddDetailProperty(LDetail, 'Low', ValueForLabel(ALine, 'Low:'));
  AddDetailProperty(LDetail, 'High', ValueForLabel(ALine, 'High:'));
  AddDetailProperty(LDetail, 'Name', ValueForLabel(ALine, 'Name:'));
  AGlobalType.Details.Add(LDetail);

  if StartsWithText(LTrimmed, 'MEMBER') or
    StartsWithText(LTrimmed, 'ENUMERATE') then
  begin
    var LMember := TDumpGlobalTypeMember.Create;
    if StartsWithText(LTrimmed, 'MEMBER') then
      LMember.Kind := gtmkMember
    else
      LMember.Kind := gtmkEnumerator;
    LMember.SourceLine := FDocument.Lines[ALineNumber - 1];
    LMember.RawTypeIndex := ValueForLabel(ALine, 'Type:');
    LMember.HasTypeIndex := TryParseHexUIntToken(LMember.RawTypeIndex,
      LMember.TypeIndex);
    LMember.RawOffset := ValueForLabel(ALine, 'Offs:');
    LMember.HasOffset := TryParseHexUIntToken(LMember.RawOffset,
      LMember.Offset);
    LMember.RawValue := ValueForLabel(ALine, 'Value:');
    LMember.HasValue := TryParseHexUIntToken(LMember.RawValue,
      LMember.Value);
    LMember.Access := ValueForLabel(ALine, 'Access:');
    var LCloseBracket := LastDelimiter(']', ALine);
    var LOpenBracket := LastDelimiter('[', ALine);
    if (LOpenBracket > 0) and (LCloseBracket > LOpenBracket) then
    begin
      LMember.RawNameIndex := Copy(ALine, LOpenBracket + 1,
        LCloseBracket - LOpenBracket - 1);
      LMember.HasNameIndex := TryParseHexUIntToken(LMember.RawNameIndex,
        LMember.NameIndex);
      var LNameText := Copy(ALine, 1, LOpenBracket - 1);
      var LNameLabelPos := Pos('Name:', LNameText);
      if LNameLabelPos > 0 then
        LMember.Name := Trim(Copy(LNameText, LNameLabelPos + Length('Name:'),
          MaxInt));
    end;
    if LMember.HasTypeIndex then
      AddTypeReference(LMember.RawTypeIndex);
    AGlobalType.Members.Add(LMember);
    Exit;
  end;

  AddTypeReference(ValueForLabel(ALine, 'Points to:'));
  AddTypeReference(ValueForLabel(ALine, 'ArgList:'));
  AddTypeReference(ValueForLabel(ALine, 'FieldIdx:'));
  AddTypeReference(ValueForLabel(ALine, 'Fields:'));
  AddTypeReference(ValueForLabel(ALine, 'Indexed by:'));
  AddTypeReference(ValueForLabel(ALine, 'Class:'));
  if StartsWithText(Trim(ALine), 'Type:') then
    AddTypeReference(ValueForLabel(ALine, 'Type:'));
  if StartsWithText(Trim(ALine), 'MEMBER') then
    AddTypeReference(ValueForLabel(ALine, 'Type:'));

  var LCloseBracket := LastDelimiter(']', ALine);
  var LOpenBracket := LastDelimiter('[', ALine);
  if (LOpenBracket > 0) and (LCloseBracket > LOpenBracket) then
  begin
    var LNameIndexText := Copy(ALine, LOpenBracket + 1,
      LCloseBracket - LOpenBracket - 1);
    if TryParseHexUIntToken(LNameIndexText, AGlobalType.NameIndex) then
    begin
      AGlobalType.RawNameIndex := LNameIndexText;
      AGlobalType.HasNameIndex := True;
      var LNamePrefix := Trim(Copy(ALine, 1, LOpenBracket - 1));
      var LNameLabelPos := Pos('Name:', LNamePrefix);
      if LNameLabelPos > 0 then
        AGlobalType.Name := Trim(Copy(LNamePrefix, LNameLabelPos +
          Length('Name:'), MaxInt));
    end;
  end;
end;

procedure TDumpParser.ResolveBorlandReferences;
begin
  var LTypeLookup := TDictionary<UInt64, TDumpGlobalTypeRecord>.Create;
  try
    for var LSection in FDocument.GlobalTypeSections do
      for var LTypeRecord in LSection.Records do
        LTypeLookup.AddOrSetValue(LTypeRecord.TypeIndex, LTypeRecord);

    for var LSection in FDocument.AlignSymbolSections do
      for var LRecord in LSection.Records do
      begin
        if LRecord.HasNameIndex then
          FDocument.BorlandNameLookup.TryGetValue(LRecord.NameIndex,
            LRecord.ResolvedName);
        for var LNameIndex in LRecord.NameIndices do
        begin
          var LResolvedName: string;
          if FDocument.BorlandNameLookup.TryGetValue(LNameIndex, LResolvedName) then
            LRecord.ResolvedNames.Add(LResolvedName);
        end;
        if LRecord.HasTypeIndex then
          LTypeLookup.TryGetValue(LRecord.TypeIndex, LRecord.TypeRecord);
      end;
    for var LSection in FDocument.GlobalSymbolSections do
      for var LRecord in LSection.Records do
      begin
        if LRecord.HasNameIndex then
          FDocument.BorlandNameLookup.TryGetValue(LRecord.NameIndex,
            LRecord.ResolvedName);
        for var LNameIndex in LRecord.NameIndices do
        begin
          var LResolvedName: string;
          if FDocument.BorlandNameLookup.TryGetValue(LNameIndex, LResolvedName) then
            LRecord.ResolvedNames.Add(LResolvedName);
        end;
        if LRecord.HasTypeIndex then
          LTypeLookup.TryGetValue(LRecord.TypeIndex, LRecord.TypeRecord);
      end;
    for var LSection in FDocument.GlobalTypeSections do
      for var LTypeRecord in LSection.Records do
      begin
        if LTypeRecord.HasNameIndex then
          FDocument.BorlandNameLookup.TryGetValue(LTypeRecord.NameIndex,
            LTypeRecord.ResolvedName);
        for var LTypeIndex in LTypeRecord.ReferencedTypeIndices do
        begin
          var LReferencedType: TDumpGlobalTypeRecord;
          if LTypeLookup.TryGetValue(LTypeIndex, LReferencedType) then
            LTypeRecord.ReferencedTypes.Add(LReferencedType);
        end;
        for var LMember in LTypeRecord.Members do
          if LMember.HasNameIndex then
            FDocument.BorlandNameLookup.TryGetValue(LMember.NameIndex,
              LMember.ResolvedName);
      end;
    for var LModule in FDocument.SymbolModules do
      if LModule.HasNameIndex then
        FDocument.BorlandNameLookup.TryGetValue(LModule.NameIndex,
          LModule.ResolvedName);
    for var LSourceModule in FDocument.SourceModules do
      for var LSourceFile in LSourceModule.SourceFiles do
        if LSourceFile.HasNameIndex then
          FDocument.BorlandNameLookup.TryGetValue(LSourceFile.NameIndex,
            LSourceFile.ResolvedName);
  finally
    LTypeLookup.Free;
  end;
end;

function TDumpParser.BorlandSymbolKind(const ARecordKind: string): TDumpSymbolKind;
begin
  if SameText(ARecordKind, 'S_GPROC32') then
    Result := skFunction
  else if SameText(ARecordKind, 'S_GPROCREF') then
    Result := skReference
  else if SameText(ARecordKind, 'S_GDATA32') or SameText(ARecordKind, 'S_LDATA32') then
    Result := skData
  else if SameText(ARecordKind, 'S_UDT') then
    Result := skType
  else if SameText(ARecordKind, 'S_PCONSTANT') then
    Result := skConstant
  else
    Result := skUnknown;
end;

function TDumpParser.BorlandSymbolRecordKind(
  const ARecordKind: string): TDumpBorlandSymbolRecordKind;
begin
  if SameText(ARecordKind, 'S_SSEARCH') then
    Result := bsrkSearch
  else if SameText(ARecordKind, 'S_GPROC32') then
    Result := bsrkProcedure
  else if SameText(ARecordKind, 'S_BPREL32') then
    Result := bsrkBasePointerLocal
  else if SameText(ARecordKind, 'S_REGISTER') then
    Result := bsrkRegisterLocal
  else if SameText(ARecordKind, 'S_OPTVAR32') then
    Result := bsrkOptimizedLocal
  else if SameText(ARecordKind, 'S_END') then
    Result := bsrkEnd
  else if SameText(ARecordKind, 'S_GDATA32') then
    Result := bsrkGlobalData
  else if SameText(ARecordKind, 'S_LDATA32') then
    Result := bsrkLocalData
  else if SameText(ARecordKind, 'S_GPROCREF') then
    Result := bsrkProcedureReference
  else if SameText(ARecordKind, 'S_PCONSTANT') then
    Result := bsrkConstant
  else if SameText(ARecordKind, 'S_UDT') then
    Result := bsrkUserType
  else if SameText(ARecordKind, 'S_COMPILE') then
    Result := bsrkCompile
  else if SameText(ARecordKind, 'S_NAMESPACE') then
    Result := bsrkNamespace
  else if SameText(ARecordKind, 'S_USES') then
    Result := bsrkUses
  else if SameText(ARecordKind, 'S_USING') then
    Result := bsrkUsing
  else
    Result := bsrkUnknown;
end;

function TDumpParser.TryParseBorlandSubsectionDirectoryLine(const ALine: string;
  ALineNumber: Integer; out ASubsection: TDumpSymbolSubsection): Boolean;
  function ValueForLabel(const ALabel: string): string;
  begin
    var LLabelPos := Pos(ALabel, ALine);
    if LLabelPos = 0 then
      Exit('');
    var LValueText := Copy(ALine, LLabelPos + Length(ALabel), MaxInt);
    Result := FirstToken(LValueText);
  end;

begin
  FillChar(ASubsection, SizeOf(ASubsection), 0);
  Result := False;
  ASubsection.RawModIndex := ValueForLabel('ModIndex:');
  ASubsection.RawFileOffset := ValueForLabel('FileOffs:');
  ASubsection.RawSize := ValueForLabel('Size:');
  ASubsection.SubsectionType := ValueForLabel('Type:');
  if (ASubsection.RawModIndex = '') or (ASubsection.RawFileOffset = '') or
    (ASubsection.RawSize = '') or (ASubsection.SubsectionType = '') then
    Exit;

  var LModIndex: UInt64;
  if not TryParseHexUIntToken(ASubsection.RawModIndex, LModIndex) then
    Exit;
  if not TryParseHexUIntToken(ASubsection.RawFileOffset, ASubsection.FileOffset) then
    Exit;
  if not TryParseHexUIntToken(ASubsection.RawSize, ASubsection.Size) then
    Exit;

  ASubsection.ModIndex := LModIndex;
  ASubsection.StartLine := ALineNumber;
  Result := True;
end;

function TDumpParser.TryParseBorlandSubsectionHeader(const ALine: string;
  out AModIndex: Integer; out AFileOffset: UInt64;
  out ASubsectionType: string): Boolean;
begin
  AModIndex := 0;
  AFileOffset := 0;
  ASubsectionType := '';
  var LModIndexText := ValueForLabel(ALine, 'ModIndex:');
  var LFileOffsetText := ValueForLabel(ALine, 'FileOffs:');
  var LWork := Trim(ALine);
  ASubsectionType := LastToken(LWork);
  if not StartsWithText(ASubsectionType, 'sst') then
    Exit(False);

  var LModIndex: UInt64;
  Result := TryParseHexUIntToken(LModIndexText, LModIndex) and
    TryParseHexUIntToken(LFileOffsetText, AFileOffset);
  if Result then
    AModIndex := LModIndex;
end;

function TDumpParser.TryParseBorlandModuleSegmentLine(const ALine: string;
  ALineNumber: Integer; out ASegment: TDumpSymbolModuleSegment): Boolean;
begin
  FillChar(ASegment, SizeOf(ASegment), 0);
  Result := False;
  var LText := Trim(ALine);
  var LColonPos := Pos(':', LText);
  if LColonPos = 0 then
    Exit;

  ASegment.RawSegment := Trim(Copy(LText, 1, LColonPos - 1));
  var LAfterColon := Copy(LText, LColonPos + 1, MaxInt);
  var LRangeText := FirstToken(LAfterColon);
  var LDashPos := Pos('-', LRangeText);
  if LDashPos = 0 then
    Exit;
  ASegment.RawStartOffset := Copy(LRangeText, 1, LDashPos - 1);
  ASegment.RawEndOffset := Copy(LRangeText, LDashPos + 1, MaxInt);
  ASegment.RawFlags := ValueForLabel(LText, 'Flags:');
  if ASegment.RawFlags = '' then
    Exit;

  Result := TryParseHexUIntToken(ASegment.RawSegment, ASegment.Segment) and
    TryParseHexUIntToken(ASegment.RawStartOffset, ASegment.StartOffset) and
    TryParseHexUIntToken(ASegment.RawEndOffset, ASegment.EndOffset) and
    TryParseHexUIntToken(ASegment.RawFlags, ASegment.Flags);
  if Result then
    ASegment.StartLine := ALineNumber;
end;

function TDumpParser.TryParseBorlandSourceRangeLine(const ALine: string;
  ALineNumber: Integer; out ARange: TDumpSourceRange): Boolean;
begin
  ARange := nil;
  Result := False;
  var LText := Trim(ALine);
  if StartsWithText(LText, 'Range:') then
    LText := Trim(Copy(LText, Length('Range:') + 1, MaxInt));
  var LColonPos := Pos(':', LText);
  if LColonPos = 0 then
    Exit;

  var LSegmentText := Trim(Copy(LText, 1, LColonPos - 1));
  var LAfterColon := Copy(LText, LColonPos + 1, MaxInt);
  var LRangeText := FirstToken(LAfterColon);
  var LDashPos := Pos('-', LRangeText);
  if LDashPos = 0 then
    Exit;
  var LStartText := Copy(LRangeText, 1, LDashPos - 1);
  var LEndText := Copy(LRangeText, LDashPos + 1, MaxInt);

  ARange := TDumpSourceRange.Create;
  try
    Result := TryParseHexUIntToken(LSegmentText, ARange.Segment) and
      TryParseHexUIntToken(LStartText, ARange.StartOffset) and
      TryParseHexUIntToken(LEndText, ARange.EndOffset);
    if not Result then
      Exit;
    ARange.RawSegment := LSegmentText;
    ARange.RawStartOffset := LStartText;
    ARange.RawEndOffset := LEndText;
    ARange.StartLine := ALineNumber;
  finally
    if not Result then
      ARange.Free;
  end;
end;

function TDumpParser.TryParseBorlandSourceFileLine(const ALine: string;
  ALineNumber: Integer; out ASourceFile: TDumpSourceFile): Boolean;
begin
  ASourceFile := nil;
  Result := False;
  var LText := Trim(ALine);
  if not StartsWithText(LText, 'File:') then
    Exit;
  Delete(LText, 1, Length('File:'));
  LText := Trim(LText);
  var LOffsetPos := Pos('Offset:', LText);
  if LOffsetPos = 0 then
    Exit;
  var LNameText := Trim(Copy(LText, 1, LOffsetPos - 1));
  var LNameEnd := Pos(' [', LNameText);
  if LNameEnd > 0 then
    LNameText := Trim(Copy(LNameText, 1, LNameEnd - 1));
  var LOffsetText := ValueForLabel(LText, 'Offset:');
  var LOffsetValue: UInt64;
  if (LNameText = '') or not TryParseHexUIntToken(LOffsetText, LOffsetValue) then
    Exit;

  ASourceFile := TDumpSourceFile.Create;
  ASourceFile.Name := LNameText;
  var LNameOpenBracket := LastDelimiter('[', LText);
  var LNameCloseBracket := LastDelimiter(']', LText);
  if (LNameOpenBracket > 0) and (LNameCloseBracket > LNameOpenBracket) and
    (LNameOpenBracket < LOffsetPos) then
  begin
    ASourceFile.RawNameIndex := Copy(LText, LNameOpenBracket + 1,
      LNameCloseBracket - LNameOpenBracket - 1);
    ASourceFile.HasNameIndex := TryParseHexUIntToken(
      ASourceFile.RawNameIndex, ASourceFile.NameIndex);
  end;
  ASourceFile.Offset := LOffsetValue;
  ASourceFile.RawOffset := LOffsetText;
  ASourceFile.StartLine := ALineNumber;
  Result := True;
end;

procedure TDumpParser.AddBorlandSourceLinePairs(const ALine: string;
  ALineNumber: Integer; ARange: TDumpSourceRange);
begin
  var LText := Trim(ALine);
  var LSearchStart := 1;
  while LSearchStart <= Length(LText) do
  begin
    var LColonPos := PosEx(':', LText, LSearchStart);
    if LColonPos = 0 then
      Exit;
    var LLeftStart := LColonPos - 1;
    while (LLeftStart >= LSearchStart) and CharInSet(LText[LLeftStart], ['0'..'9']) do
      Dec(LLeftStart);
    Inc(LLeftStart);
    var LRightEnd := LColonPos + 1;
    while (LRightEnd <= Length(LText)) and
      CharInSet(LText[LRightEnd], ['0'..'9', 'A'..'F', 'a'..'f']) do
      Inc(LRightEnd);

    var LLineText := Copy(LText, LLeftStart, LColonPos - LLeftStart);
    var LOffsetText := Copy(LText, LColonPos + 1, LRightEnd - LColonPos - 1);
    var LSourceLine: TDumpSourceLineInfo;
    if TryStrToInt(LLineText, LSourceLine.LineNumber) and
      TryParseHexUIntToken(LOffsetText, LSourceLine.Offset) then
    begin
      LSourceLine.RawLineNumber := LLineText;
      LSourceLine.RawOffset := LOffsetText;
      LSourceLine.StartLine := ALineNumber;
      ARange.LineNumbers.Add(LSourceLine);
    end;
    LSearchStart := LRightEnd + 1;
  end;
end;

function TDumpParser.TryParseUIntToken(const AToken: string;
  out AValue: UInt64): Boolean;
begin
  var LToken: string;
  var LBase: Integer;
  var LDigit: Integer;
  AValue := 0;
  LToken := Trim(AToken);
  Result := False;
  if (LToken = '') or (Pos('?', LToken) > 0) or (Pos(':', LToken) > 0) or
    (Pos('/', LToken) > 0) then
    Exit;

  LBase := 10;
  if (Length(LToken) > 1) and SameText(Copy(LToken, Length(LToken), 1), 'h') then
  begin
    LBase := 16;
    Delete(LToken, Length(LToken), 1);
  end
  else if (Length(LToken) > 2) and SameText(Copy(LToken, 1, 2), '0x') then
  begin
    LBase := 16;
    Delete(LToken, 1, 2);
  end
  else if (Length(LToken) > 1) and (LToken[1] = '0') then
    LBase := 16
  else
    for var LIndex := 1 to Length(LToken) do
      if CharInSet(LToken[LIndex], ['A'..'F', 'a'..'f']) then
      begin
        LBase := 16;
        Break;
      end;

  if LToken = '' then
    Exit;
  for var LIndex := 1 to Length(LToken) do
  begin
    var LChar := LToken[LIndex];
    if CharInSet(LChar, ['0'..'9']) then
      LDigit := Ord(LChar) - Ord('0')
    else if CharInSet(LChar, ['A'..'F']) then
      LDigit := Ord(LChar) - Ord('A') + 10
    else if CharInSet(LChar, ['a'..'f']) then
      LDigit := Ord(LChar) - Ord('a') + 10
    else
      Exit;
    if LDigit >= LBase then
      Exit;
    // Reject oversized tokens before the checked UInt64 multiply can overflow.
    if AValue > (High(UInt64) - UInt64(LDigit)) div UInt64(LBase) then
      Exit;
    AValue := (AValue * UInt64(LBase)) + UInt64(LDigit);
  end;
  Result := True;
end;

function TDumpParser.TryParseHexUIntToken(const AToken: string;
  out AValue: UInt64): Boolean;
begin
  var LToken: string;
  var LDigit: Integer;
  AValue := 0;
  LToken := Trim(AToken);
  Result := False;
  if (LToken = '') or (Pos('?', LToken) > 0) or (Pos(':', LToken) > 0) or
    (Pos('/', LToken) > 0) then
    Exit;
  if (Length(LToken) > 1) and SameText(Copy(LToken, Length(LToken), 1), 'h') then
    Delete(LToken, Length(LToken), 1)
  else if (Length(LToken) > 2) and SameText(Copy(LToken, 1, 2), '0x') then
    Delete(LToken, 1, 2);
  if LToken = '' then
    Exit;
  for var LIndex := 1 to Length(LToken) do
  begin
    var LChar := LToken[LIndex];
    if CharInSet(LChar, ['0'..'9']) then
      LDigit := Ord(LChar) - Ord('0')
    else if CharInSet(LChar, ['A'..'F']) then
      LDigit := Ord(LChar) - Ord('A') + 10
    else if CharInSet(LChar, ['a'..'f']) then
      LDigit := Ord(LChar) - Ord('a') + 10
    else
      Exit;
    // Reject oversized hexadecimal tokens before the checked multiply.
    if AValue > (High(UInt64) - UInt64(LDigit)) div UInt64(16) then
      Exit;
    AValue := (AValue * UInt64(16)) + UInt64(LDigit);
  end;
  Result := True;
end;

function TDumpParser.PropertyValueKind(const AName: string): TDumpValueKind;
begin
  var LName := LowerCase(AName);
  if Pos('rva', LName) > 0 then
    Result := vkRVA
  else if Pos('file offset', LName) > 0 then
    Result := vkFileOffset
  else if Pos('address', LName) > 0 then
    Result := vkAddress
  else if Pos('size', LName) > 0 then
    Result := vkSize
  else if Pos('checksum', LName) > 0 then
    Result := vkUInt
  else if Pos('entry point', LName) > 0 then
    Result := vkAddress
  else if Pos('segment', LName) > 0 then
    Result := vkAddress
  else if Pos('ordinal', LName) > 0 then
    Result := vkOrdinal
  else if Pos('overlay', LName) > 0 then
    Result := vkOrdinal
  else
    Result := vkUnknown;
end;

end.

