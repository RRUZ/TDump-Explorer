//**************************************************************************************************
//
// Unit TDump.Explorer.View.Shared
//
// Shared view metadata and helpers
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
unit TDump.Explorer.View.Shared;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  VirtualTrees.Types,
  VirtualTrees.BaseAncestorVCL,
  VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL,
  VirtualTrees,
  TDump.Explorer.Parser;

type
  TTreeDetailKind = (tdkNone, tdkDocumentSummary,
    tdkOldExecutableHeader, tdkPortableExecutableHeader, tdkELFHeader,
    tdkDataDirectories, tdkObjectTable, tdkImportDirectory,
    tdkImportModule, tdkDelayedImportTable, tdkDelayedImportModule,
    tdkExportDirectory, tdkResourceDirectory,
    tdkResource, tdkBorlandSymbolTable, tdkBorlandSubsection, tdkBorlandSourceFile,
    tdkBorlandAlignSymbolRecord, tdkBorlandGlobalSymbolRecord,
    tdkBorlandGlobalTypeRecord, tdkMachHeader, tdkMachArchitectures,
    tdkMachArchitecture, tdkMachLoadCommands, tdkMachLoadCommand,
    tdkMachSection, tdkMachSymbolTable, tdkELFSectionHeaders,
    tdkELFProgramHeaders, tdkELFSymbolTable, tdkELFDynamicSection,
    tdkELFRelocations, tdkOMFRecords, tdkOMFRecord,
    tdkOMFLibraryMembers, tdkOMFLibraryIndex, tdkRelocations,
    tdkRelocationBlock, tdkStrings, tdkMachDynamicImports,
    tdkMachIndirectSymbols, tdkMachDynamicSymbolTable,
    tdkMachRebaseInfo, tdkMachBindingInfo, tdkMachWeakBindingInfo,
    tdkMachLazyBindingInfo, tdkMachExports, tdkMachResources, tdkMachRawSymbols,
    tdkArchiveMembers, tdkArchiveSymbols, tdkDiagnostics);

  TTreeTextColorKind = (ttckDefault, ttckHighlighted, ttckMethod, ttckType,
    ttckSyntax);

  TTreeDetailKindInfo = record
    Caption: string;
    ImageName: string;
    TextColorKind: TTreeTextColorKind;
  end;

const
  cTreeDetailKindInfos: array[TTreeDetailKind] of TTreeDetailKindInfo = (
    (Caption: ''; ImageName: ''; TextColorKind: ttckDefault),
    (Caption: ''; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Old Executable Header'; ImageName: 'stack-simple'; TextColorKind: ttckHighlighted),
    (Caption: 'Portable Executable Header'; ImageName: 'stack'; TextColorKind: ttckHighlighted),
    (Caption: 'ELF Header'; ImageName: 'rectangle'; TextColorKind: ttckHighlighted),
    (Caption: 'Data Directories'; ImageName: 'cards'; TextColorKind: ttckHighlighted),
    (Caption: 'Object Table'; ImageName: 'rectangle'; TextColorKind: ttckHighlighted),
    (Caption: 'Import Directory'; ImageName: 'arrow-square-right'; TextColorKind: ttckHighlighted),
    (Caption: 'Import Module'; ImageName: ''; TextColorKind: ttckDefault),
    (Caption: 'Delayed Load Import Table'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Delayed Import Module'; ImageName: ''; TextColorKind: ttckDefault),
    (Caption: 'Export Directory'; ImageName: 'arrow-square-left'; TextColorKind: ttckHighlighted),
    (Caption: 'Resources'; ImageName: 'archive'; TextColorKind: ttckHighlighted),
    (Caption: 'Resource'; ImageName: ''; TextColorKind: ttckDefault),
    (Caption: 'Borland 32-bit Symbol Table'; ImageName: 'package'; TextColorKind: ttckHighlighted),
    (Caption: 'Borland Subsection'; ImageName: 'package'; TextColorKind: ttckHighlighted),
    (Caption: 'Source File'; ImageName: 'file-code'; TextColorKind: ttckDefault),
    (Caption: 'Alignment Symbol'; ImageName: ''; TextColorKind: ttckMethod),
    (Caption: 'Global Symbol'; ImageName: ''; TextColorKind: ttckMethod),
    (Caption: 'Global Type'; ImageName: ''; TextColorKind: ttckType),
    (Caption: 'Mach Header'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'FAT Architectures'; ImageName: 'scan'; TextColorKind: ttckHighlighted),
    (Caption: 'FAT Architecture'; ImageName: 'cpu'; TextColorKind: ttckDefault),
    (Caption: 'Load Commands'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Load Command'; ImageName: ''; TextColorKind: ttckDefault),
    (Caption: 'Mach Section'; ImageName: ''; TextColorKind: ttckDefault),
    (Caption: 'Symbol Table'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'ELF Section Headers'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'ELF Program Headers'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'ELF Symbol Table'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'ELF Dynamic Section'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'ELF Relocations'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'OMF Records'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'OMF Record'; ImageName: ''; TextColorKind: ttckSyntax),
    (Caption: 'OMF Library Members'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'OMF Library Index'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Relocations'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Relocation Block'; ImageName: ''; TextColorKind: ttckDefault),
    (Caption: 'Strings'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Mach Dynamic Imports'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Mach Indirect Symbols'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Mach Dynamic Symbol Table'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Rebase Info'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Binding Info'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Weak Binding Info'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Lazy Binding Info'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Exports'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Resources'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Raw Symbols'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'AR Archive Members'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'AR Archive Symbols'; ImageName: ''; TextColorKind: ttckHighlighted),
    (Caption: 'Diagnostics'; ImageName: 'warning'; TextColorKind: ttckHighlighted));

type
  PTreeItemData = ^TTreeItemData;
  TTreeItemData = record
    Caption: string;
    DetailKind: TTreeDetailKind;
    HeaderIndex: Integer;
    ImportModuleIndex: Integer;
    Resource: TDumpResource;
    BorlandSubsectionIndex: Integer;
    SourceFile: TDumpSourceFile;
    AlignSymbolRecord: TDumpAlignSymbolRecord;
    LazyAlignSymbolSection: TDumpLazyAlignSymbolSection;
    LazyAlignSymbolRecordIndex: Integer;
    LazyGlobalSymbolSection: TDumpLazyGlobalSymbolSection;
    LazyGlobalSymbolRecordIndex: Integer;
    LazyGlobalTypeSection: TDumpLazyGlobalTypeSection;
    LazyGlobalTypeRecordIndex: Integer;
    GlobalSymbolRecord: TDumpGlobalSymbolRecord;
    GlobalTypeRecord: TDumpGlobalTypeRecord;
    MachArchitecture: TDumpMachArchitecture;
    MachLoadCommand: TDumpMachLoadCommand;
    MachSection: TDumpMachSection;
    ObjectRecord: TDumpObjectRecord;
    RelocationBlock: TDumpRelocationBlock;
    ELFRelocationSectionName: string;
    DetailItemIndex: Integer;
    SourceStartLine: Integer;
    SourceEndLine: Integer;
  end;

function PropertyValue(const AProperties: TList<TDumpProperty>;
  const AName: string): string;
function ResourceCaption(const AResource: TDumpResource): string;

type
  TDocumentTreeBuilder = class
  private
    FTree: TVirtualStringTree;
    function AddNode(AParent: PVirtualNode; const ACaption: string;
      ADetailKind: TTreeDetailKind = tdkNone): PVirtualNode;
    procedure AddAlignSymbolRecordNode(AParent: PVirtualNode;
      ARecord: TDumpAlignSymbolRecord);
    procedure AddLazyAlignSymbolRecordNode(AParent: PVirtualNode;
      ADocument: TDumpDocument; ASection: TDumpLazyAlignSymbolSection;
      ARecordIndex: Integer);
    procedure AddLazyGlobalSymbolRecordNode(AParent: PVirtualNode;
      ADocument: TDumpDocument; ASection: TDumpLazyGlobalSymbolSection;
      ARecordIndex: Integer);
    procedure AddLazyGlobalTypeRecordNode(AParent: PVirtualNode;
      ADocument: TDumpDocument; ASection: TDumpLazyGlobalTypeSection;
      ARecordIndex: Integer);
    function LazyAlignSymbolCaption(ADocument: TDumpDocument;
      ASection: TDumpLazyBorlandRecordSection; ARecordIndex: Integer): string;
    function LazyGlobalTypeCaption(ADocument: TDumpDocument;
      ASection: TDumpLazyGlobalTypeSection; ARecordIndex: Integer): string;
    procedure AddResourceNodes(AParent: PVirtualNode;
      const AResources: TObjectList<TDumpResource>);
    function HeaderDetailKind(const AHeader: TDumpHeader): TTreeDetailKind;
    function HasBorlandSymbolTable(ADocument: TDumpDocument): Boolean;
    function ResourceCaption(const AResource: TDumpResource): string;
    procedure CacheSourceSpans(ADocument: TDumpDocument);
    procedure AddPENodes(AParent: PVirtualNode; ADocument: TDumpDocument);
    procedure AddELFNodes(AParent: PVirtualNode; ADocument: TDumpDocument);
    procedure AddOMFNodes(AParent: PVirtualNode; ADocument: TDumpDocument);
    procedure AddMachNodes(AParent: PVirtualNode; ADocument: TDumpDocument);
    procedure AddBorlandNodes(AParent: PVirtualNode;
      ADocument: TDumpDocument);
    procedure AddBorlandChildren(AParent: PVirtualNode;
      ADocument: TDumpDocument; ASubsection: TDumpBorlandSubsection);
    function Build(ADocument: TDumpDocument): PVirtualNode;
  public
    constructor Create(ATree: TVirtualStringTree);
    class function FileKindCaption(AFileKind: TDumpFileKind): string; static;
    class procedure Populate(ATree: TVirtualStringTree;
      ADocument: TDumpDocument); static;
  end;

  TDocumentSourceNavigation = record
    class procedure Resolve(ADocument: TDumpDocument; const AData: PTreeItemData;
      out AStartLine, AEndLine: Integer); static;
  end;

implementation

uses
  System.Math,
  System.StrUtils,
  TDump.Explorer.Highlighter;

constructor TDocumentTreeBuilder.Create(ATree: TVirtualStringTree);
begin
  inherited Create;
  FTree := ATree;
end;

function TDocumentTreeBuilder.AddNode(AParent: PVirtualNode;
  const ACaption: string; ADetailKind: TTreeDetailKind): PVirtualNode;
begin
  Result := FTree.AddChild(AParent);
  var LNodeData := PTreeItemData(FTree.GetNodeData(Result));
  LNodeData^ := Default(TTreeItemData);
  LNodeData.Caption := ACaption;
  LNodeData.DetailKind := ADetailKind;
  LNodeData.HeaderIndex := -1;
  LNodeData.ImportModuleIndex := -1;
  LNodeData.BorlandSubsectionIndex := -1;
  LNodeData.DetailItemIndex := -1;
end;

procedure TDocumentTreeBuilder.AddAlignSymbolRecordNode(AParent: PVirtualNode;
  ARecord: TDumpAlignSymbolRecord);
begin
  var LRecordNode := AddNode(AParent, BorlandSymbolCaption(ARecord),
    tdkBorlandAlignSymbolRecord);
  PTreeItemData(FTree.GetNodeData(LRecordNode))^.AlignSymbolRecord := ARecord;
  for var LChild in ARecord.ScopeChildren do
    AddAlignSymbolRecordNode(LRecordNode, TDumpAlignSymbolRecord(LChild));
end;

function TDocumentTreeBuilder.LazyAlignSymbolCaption(ADocument: TDumpDocument;
  ASection: TDumpLazyBorlandRecordSection; ARecordIndex: Integer): string;
  function LeadingToken(const AText: string): string;
  begin
    Result := Trim(AText);
    var LSeparator := Pos(' ', Result);
    if LSeparator > 0 then
      SetLength(Result, LSeparator - 1);
  end;
begin
  Result := 'Symbol record';
  if (ADocument = nil) or (ADocument.TextSource = nil) or (ASection = nil) or
    (ARecordIndex < 0) or (ARecordIndex >= ASection.Records.Count) then
    Exit;
  var LRecord := ASection.Records[ARecordIndex];
  var LLine := ADocument.TextSource[LRecord.StartLine - 1];
  var LRecordPos := Pos('S_', LLine);
  if LRecordPos > 0 then
    Result := LeadingToken(Copy(LLine, LRecordPos, MaxInt));
  for var LLineIndex := LRecord.StartLine to LRecord.EndLine do
  begin
    LLine := ADocument.TextSource[LLineIndex - 1];
    var LNamePos := Pos('@', LLine);
    if LNamePos > 0 then
      Exit(Result + '  ' + LeadingToken(Copy(LLine, LNamePos, MaxInt)));
  end;
end;

procedure TDocumentTreeBuilder.AddLazyAlignSymbolRecordNode(
  AParent: PVirtualNode; ADocument: TDumpDocument;
  ASection: TDumpLazyAlignSymbolSection; ARecordIndex: Integer);
begin
  if (ASection = nil) or (ARecordIndex < 0) or
    (ARecordIndex >= ASection.Records.Count) then
    Exit;
  var LRecord := ASection.Records[ARecordIndex];
  var LRecordNode := AddNode(AParent,
    LazyAlignSymbolCaption(ADocument, ASection, ARecordIndex),
    tdkBorlandAlignSymbolRecord);
  var LNodeData := PTreeItemData(FTree.GetNodeData(LRecordNode));
  LNodeData.LazyAlignSymbolSection := ASection;
  LNodeData.LazyAlignSymbolRecordIndex := ARecordIndex;
  LNodeData.SourceStartLine := LRecord.StartLine;
  LNodeData.SourceEndLine := LRecord.EndLine;
  var LChildIndex := LRecord.FirstChildIndex;
  while LChildIndex >= 0 do
  begin
    AddLazyAlignSymbolRecordNode(LRecordNode, ADocument, ASection, LChildIndex);
    LChildIndex := ASection.Records[LChildIndex].NextSiblingIndex;
  end;
end;

procedure TDocumentTreeBuilder.AddLazyGlobalSymbolRecordNode(
  AParent: PVirtualNode; ADocument: TDumpDocument;
  ASection: TDumpLazyGlobalSymbolSection; ARecordIndex: Integer);
begin
  if (ASection = nil) or (ARecordIndex < 0) or
    (ARecordIndex >= ASection.Records.Count) then
    Exit;
  var LRecord := ASection.Records[ARecordIndex];
  var LRecordNode := AddNode(AParent,
    LazyAlignSymbolCaption(ADocument, ASection, ARecordIndex),
    tdkBorlandGlobalSymbolRecord);
  var LNodeData := PTreeItemData(FTree.GetNodeData(LRecordNode));
  LNodeData.LazyGlobalSymbolSection := ASection;
  LNodeData.LazyGlobalSymbolRecordIndex := ARecordIndex;
  LNodeData.SourceStartLine := LRecord.StartLine;
  LNodeData.SourceEndLine := LRecord.EndLine;
end;

function TDocumentTreeBuilder.LazyGlobalTypeCaption(ADocument: TDumpDocument;
  ASection: TDumpLazyGlobalTypeSection; ARecordIndex: Integer): string;
begin
  Result := 'Type record';
  if (ADocument = nil) or (ADocument.TextSource = nil) or (ASection = nil) or
    (ARecordIndex < 0) or (ARecordIndex >= ASection.Records.Count) then
    Exit;
  var LLine := Trim(ADocument.TextSource[
    ASection.Records[ARecordIndex].StartLine - 1]);
  var LTypePos := Pos(' Type:', LLine);
  if LTypePos > 0 then
  begin
    var LText := Trim(Copy(LLine, LTypePos + Length(' Type:'), MaxInt));
    var LTypeIndex := Copy(LText, 1, Pos(' ', LText + ' ') - 1);
    Delete(LText, 1, Length(LTypeIndex));
    LText := Trim(LText);
    if StartsText('Len:', LText) then
    begin
      Delete(LText, 1, Length('Len:'));
      LText := Trim(LText);
      var LLength := Copy(LText, 1, Pos(' ', LText + ' ') - 1);
      Delete(LText, 1, Length(LLength));
      LText := Trim(LText);
    end;
    Result := 'Type ' + LTypeIndex;
    if LText <> '' then
      Result := Result + '  ' + Copy(LText, 1, Pos(' ', LText + ' ') - 1);
  end;
end;

procedure TDocumentTreeBuilder.AddLazyGlobalTypeRecordNode(
  AParent: PVirtualNode; ADocument: TDumpDocument;
  ASection: TDumpLazyGlobalTypeSection; ARecordIndex: Integer);
begin
  if (ASection = nil) or (ARecordIndex < 0) or
    (ARecordIndex >= ASection.Records.Count) then
    Exit;
  var LRecord := ASection.Records[ARecordIndex];
  var LRecordNode := AddNode(AParent,
    LazyGlobalTypeCaption(ADocument, ASection, ARecordIndex),
    tdkBorlandGlobalTypeRecord);
  var LNodeData := PTreeItemData(FTree.GetNodeData(LRecordNode));
  LNodeData.LazyGlobalTypeSection := ASection;
  LNodeData.LazyGlobalTypeRecordIndex := ARecordIndex;
  LNodeData.SourceStartLine := LRecord.StartLine;
  LNodeData.SourceEndLine := LRecord.EndLine;
end;

procedure TDocumentTreeBuilder.AddResourceNodes(AParent: PVirtualNode;
  const AResources: TObjectList<TDumpResource>);
begin
  for var LResource in AResources do
  begin
    if SameText(LResource.ResourceType, 'Unknown') then
      Continue;
    var LResourceNode := AddNode(AParent, ResourceCaption(LResource),
      tdkResource);
    PTreeItemData(FTree.GetNodeData(LResourceNode))^.Resource := LResource;
    AddResourceNodes(LResourceNode, LResource.Children);
  end;
end;

function TDocumentTreeBuilder.HeaderDetailKind(
  const AHeader: TDumpHeader): TTreeDetailKind;
begin
  if SameText(AHeader.Name, 'Old Executable Header') then
    Exit(tdkOldExecutableHeader);
  if ContainsText(AHeader.Name, 'Portable Executable') then
    Exit(tdkPortableExecutableHeader);
  if SameText(AHeader.Name, 'Mach Header') then
    Exit(tdkMachHeader);
  if SameText(AHeader.Name, 'ELF Header') then
    Exit(tdkELFHeader);
  Result := tdkNone;
end;

function TDocumentTreeBuilder.HasBorlandSymbolTable(
  ADocument: TDumpDocument): Boolean;
begin
  Result := ADocument.BorlandSubsections.Count > 0;
  if Result then
    Exit;
  for var LNode in ADocument.Nodes do
    if SameText(LNode.Title, 'Borland 32 bit symbol table') then
      Exit(True);
end;

function TDocumentTreeBuilder.ResourceCaption(
  const AResource: TDumpResource): string;
begin
  Result := TDump.Explorer.View.Shared.ResourceCaption(AResource);
end;

class function TDocumentTreeBuilder.FileKindCaption(
  AFileKind: TDumpFileKind): string;
begin
  case AFileKind of
    dfDOS: Result := 'DOS Executable';
    dfNE: Result := 'New Executable';
    dfLE: Result := 'Linear Executable';
    dfPE: Result := 'PE Image';
    dfOMFObject: Result := 'OMF Object';
    dfCOFFObject: Result := 'COFF Object';
    dfOMFLibrary: Result := 'OMF Library';
    dfDelphiUnit: Result := 'Delphi Unit';
    dfELFObject: Result := 'ELF Object';
    dfELFArchive: Result := 'ELF Archive';
    dfARArchive: Result := 'AR Archive';
    dfMach: Result := 'Mach Image';
    dfRawHex: Result := 'Hex Dump';
    dfASCII: Result := 'ASCII Text';
  else
    Result := 'TDUMP Document';
  end;
end;

class procedure TDocumentTreeBuilder.Populate(ATree: TVirtualStringTree;
  ADocument: TDumpDocument);
begin
  if ATree = nil then
    Exit;
  var LBuilder: TDocumentTreeBuilder := nil;
  ATree.BeginUpdate;
  try
    ATree.Clear;
    if ADocument = nil then
      Exit;
    LBuilder := TDocumentTreeBuilder.Create(ATree);
    var LRootNode := LBuilder.Build(ADocument);
    LBuilder.CacheSourceSpans(ADocument);
    ATree.Expanded[LRootNode] := True;
  finally
    LBuilder.Free;
    ATree.EndUpdate;
  end;
end;

procedure TDocumentTreeBuilder.CacheSourceSpans(ADocument: TDumpDocument);
begin
  var LNode := FTree.GetFirst;
  while LNode <> nil do
  begin
    var LData := PTreeItemData(FTree.GetNodeData(LNode));
    // Lazy Borland nodes already carry compact source spans.  Do not pass
    // those fields directly as out parameters: Delphi clears out arguments
    // before Resolve can use them as the lazy fallback.
    var LStartLine := LData.SourceStartLine;
    var LEndLine := LData.SourceEndLine;
    TDocumentSourceNavigation.Resolve(ADocument, LData, LStartLine, LEndLine);
    LData.SourceStartLine := LStartLine;
    LData.SourceEndLine := LEndLine;
    LNode := FTree.GetNext(LNode);
  end;
end;

function TDocumentTreeBuilder.Build(ADocument: TDumpDocument): PVirtualNode;
begin
  Result := AddNode(nil, FileKindCaption(ADocument.FileKind), tdkDocumentSummary);

  for var LHeaderIndex := 0 to ADocument.Headers.Count - 1 do
  begin
    var LHeader := ADocument.Headers[LHeaderIndex];
    if LHeader.Properties.Count > 0 then
    begin
      var LHeaderNode := AddNode(Result, LHeader.Name, HeaderDetailKind(LHeader));
      PTreeItemData(FTree.GetNodeData(LHeaderNode))^.HeaderIndex := LHeaderIndex;
    end;
  end;

  if ADocument.DataDirectories.Count > 0 then
    AddNode(Result, Format('Data Directories [%d]', [ADocument.DataDirectories.Count]),
      tdkDataDirectories);
  if ADocument.Sections.Count > 0 then
    if ADocument.FileKind = dfELFObject then
      AddNode(Result, Format('Section Headers [%d]', [ADocument.Sections.Count]),
        tdkELFSectionHeaders)
    else
      AddNode(Result, Format('Object Table [%d]', [ADocument.Sections.Count]),
        tdkObjectTable);
  AddPENodes(Result, ADocument);
  AddELFNodes(Result, ADocument);
  AddOMFNodes(Result, ADocument);
  AddMachNodes(Result, ADocument);
  AddBorlandNodes(Result, ADocument);
  if ADocument.Diagnostics.Count > 0 then
    AddNode(Result, Format('Diagnostics [%d]', [ADocument.Diagnostics.Count]),
      tdkDiagnostics);
end;

procedure TDocumentTreeBuilder.AddPENodes(AParent: PVirtualNode;
  ADocument: TDumpDocument);
begin
  if (ADocument.Imports.Count > 0) or (ADocument.DelayedImportTable <> nil) then
  begin
    var LImportsNode := AddNode(AParent,
      Format('Import Directory [%d modules]', [ADocument.Imports.Count]),
      tdkImportDirectory);
    for var LModuleIndex := 0 to ADocument.Imports.Count - 1 do
    begin
      var LModule := ADocument.Imports[LModuleIndex];
      var LCaption := LModule.Name;
      if LCaption = '' then
        LCaption := 'Unnamed import module';
      var LModuleNode := AddNode(LImportsNode, LCaption, tdkImportModule);
      PTreeItemData(FTree.GetNodeData(LModuleNode))^.ImportModuleIndex :=
        LModuleIndex;
    end;
    if ADocument.DelayedImportTable <> nil then
    begin
      var LDelayedNode := AddNode(LImportsNode, Format(
        'Delayed Load Import Table [%d modules]',
        [ADocument.DelayedImportTable.Modules.Count]), tdkDelayedImportTable);
      for var LModuleIndex := 0 to ADocument.DelayedImportTable.Modules.Count - 1 do
      begin
        var LModule := ADocument.DelayedImportTable.Modules[LModuleIndex];
        var LCaption := LModule.Name;
        if LCaption = '' then
          LCaption := 'Unnamed delayed import module';
        var LModuleNode := AddNode(LDelayedNode, LCaption, tdkDelayedImportModule);
        PTreeItemData(FTree.GetNodeData(LModuleNode))^.ImportModuleIndex :=
          LModuleIndex;
      end;
    end;
  end;

  if ADocument.ExportList.Count > 0 then
    AddNode(AParent, Format('Export Directory [%d symbols]',
      [ADocument.ExportList.Count]), tdkExportDirectory);
  if ADocument.Resources.Count > 0 then
  begin
    var LResourcesNode := AddNode(AParent, Format('Resource Directory [%d entries]',
      [ADocument.Resources.Count]), tdkResourceDirectory);
    AddResourceNodes(LResourcesNode, ADocument.Resources);
  end;
  if ADocument.RelocationBlocks.Count > 0 then
  begin
    var LRelocationsNode := AddNode(AParent, Format('Relocations [%d blocks]',
      [ADocument.RelocationBlocks.Count]), tdkRelocations);
    for var LBlock in ADocument.RelocationBlocks do
    begin
      var LBlockNode := AddNode(LRelocationsNode, Format(
        'Block #%d: Page RVA = %s, block size = %s', [LBlock.Index,
        IntToHex(LBlock.PageRVA, 8), IntToHex(LBlock.BlockSize, 8)]),
        tdkRelocationBlock);
      PTreeItemData(FTree.GetNodeData(LBlockNode))^.RelocationBlock := LBlock;
    end;
  end
  else if ADocument.Relocations.Count > 0 then
    AddNode(AParent, Format('Relocations [%d]', [ADocument.Relocations.Count]),
      tdkRelocations);
  if ADocument.Strings.Count > 0 then
    AddNode(AParent, Format('Strings [%d]', [ADocument.Strings.Count]),
      tdkStrings);
end;

procedure TDocumentTreeBuilder.AddELFNodes(AParent: PVirtualNode;
  ADocument: TDumpDocument);
var
  LSectionEntryCount: Integer;
begin
  if (ADocument.FileKind = dfELFObject) and (ADocument.Symbols.Count > 0) then
    AddNode(AParent, Format('Symbol Table [%d symbols]',
      [ADocument.Symbols.Count]), tdkELFSymbolTable);
  if ADocument.ELFProgramHeaders.Count > 0 then
    AddNode(AParent, Format('Program Headers [%d]',
      [ADocument.ELFProgramHeaders.Count]), tdkELFProgramHeaders);
  if ADocument.ELFDynamicEntries.Count > 0 then
    AddNode(AParent, Format('Dynamic Section [%d entries]',
      [ADocument.ELFDynamicEntries.Count]), tdkELFDynamicSection);
  if ADocument.ELFRelocations.Count = 0 then
    Exit;

  var LRelocationsNode := AddNode(AParent, Format('Relocations [%d entries]',
    [ADocument.ELFRelocations.Count]), tdkELFRelocations);
  var LSectionCounts := TDictionary<string, Integer>.Create;
  try
    var LSectionOrder := TList<string>.Create;
    try
      for var LRelocation in ADocument.ELFRelocations do
      begin
        var LEntryCount := 0;
        if not LSectionCounts.TryGetValue(LRelocation.SectionName, LEntryCount) then
          LSectionOrder.Add(LRelocation.SectionName);
        LSectionCounts.AddOrSetValue(LRelocation.SectionName, LEntryCount + 1);
      end;
      for var LSectionName in LSectionOrder do
      begin
        LSectionCounts.TryGetValue(LSectionName, LSectionEntryCount);
        var LSectionNode := AddNode(LRelocationsNode,
          Format('%s [%d entries]', [LSectionName, LSectionEntryCount]),
          tdkELFRelocations);
        PTreeItemData(FTree.GetNodeData(LSectionNode))^
          .ELFRelocationSectionName := LSectionName;
      end;
    finally
      LSectionOrder.Free;
    end;
  finally
    LSectionCounts.Free;
  end;
end;

procedure TDocumentTreeBuilder.AddOMFNodes(AParent: PVirtualNode;
  ADocument: TDumpDocument);
begin
  if ADocument.ObjectRecords.Count > 0 then
  begin
    var LRecordsNode := AddNode(AParent, Format('OMF Records [%d]',
      [ADocument.ObjectRecords.Count]), tdkOMFRecords);
    for var LRecord in ADocument.ObjectRecords do
    begin
      var LCaption := LRecord.RawOffset + ' ' + LRecord.RecordKind;
      if LRecord.Name <> '' then
        LCaption := LCaption + '  ' + LRecord.Name;
      var LRecordNode := AddNode(LRecordsNode, LCaption, tdkOMFRecord);
      PTreeItemData(FTree.GetNodeData(LRecordNode))^.ObjectRecord := LRecord;
    end;
  end;
  if ADocument.LibraryMembers.Count > 0 then
    AddNode(AParent, Format('Library Members [%d]',
      [ADocument.LibraryMembers.Count]), tdkOMFLibraryMembers);
  if ADocument.OMFLibraryIndex <> nil then
    AddNode(AParent, 'Library Index', tdkOMFLibraryIndex);
  if ADocument.ArchiveMembers.Count > 0 then
    AddNode(AParent, Format('Archive Members [%d]',
      [ADocument.ArchiveMembers.Count]), tdkArchiveMembers);
  if ADocument.ArchiveSymbols.Count > 0 then
    AddNode(AParent, Format('Archive Symbols [%d]',
      [ADocument.ArchiveSymbols.Count]), tdkArchiveSymbols);
end;

procedure TDocumentTreeBuilder.AddMachNodes(AParent: PVirtualNode;
  ADocument: TDumpDocument);
begin
  if ADocument.MachArchitectures.Count > 0 then
  begin
    var LArchitecturesNode := AddNode(AParent, Format('FAT Architectures [%d]',
      [ADocument.MachArchitectures.Count]), tdkMachArchitectures);
    for var LArchitecture in ADocument.MachArchitectures do
    begin
      var LCaption := LArchitecture.CPUType;
      if LArchitecture.CPUSubtype <> '' then
        LCaption := LCaption + ' (' + LArchitecture.CPUSubtype + ')';
      var LArchitectureNode := AddNode(LArchitecturesNode, LCaption,
        tdkMachArchitecture);
      PTreeItemData(FTree.GetNodeData(LArchitectureNode))^.MachArchitecture :=
        LArchitecture;
    end;
  end;
  if ADocument.MachLoadCommands.Count > 0 then
  begin
    var LCommandsNode := AddNode(AParent, Format('Load Commands [%d]',
      [ADocument.MachLoadCommands.Count]), tdkMachLoadCommands);
    for var LCommand in ADocument.MachLoadCommands do
    begin
      var LCommandNode := AddNode(LCommandsNode,
        Format('#%d %s', [LCommand.Index, LCommand.Name]), tdkMachLoadCommand);
      PTreeItemData(FTree.GetNodeData(LCommandNode))^.MachLoadCommand := LCommand;
      for var LSection in LCommand.Sections do
      begin
        var LCaption := LSection.Name;
        if LSection.SegmentName <> '' then
          LCaption := LCaption + ' (' + LSection.SegmentName + ')';
        var LSectionNode := AddNode(LCommandNode, LCaption, tdkMachSection);
        PTreeItemData(FTree.GetNodeData(LSectionNode))^.MachSection := LSection;
      end;
    end;
  end;
  if ADocument.MachSymbols.Count > 0 then
    AddNode(AParent, Format('Symbol Table [%d symbols]',
      [ADocument.MachSymbols.Count]), tdkMachSymbolTable);
  if ADocument.MachDynamicSymbolTable <> nil then
  begin
    var LDynamicNode := AddNode(AParent, 'Dynamic Symbol Table',
      tdkMachDynamicSymbolTable);
    var LNodeData := PTreeItemData(FTree.GetNodeData(LDynamicNode));
    LNodeData.SourceStartLine := ADocument.MachDynamicSymbolTable.StartLine;
    LNodeData.SourceEndLine := ADocument.MachDynamicSymbolTable.EndLine;
    if ADocument.MachDynamicImports.Count > 0 then
      AddNode(LDynamicNode, Format('Dynamic Imports [%d symbols]',
        [ADocument.MachDynamicImports.Count]), tdkMachDynamicImports);
    if ADocument.MachIndirectSymbols.Count > 0 then
      AddNode(LDynamicNode, Format('Indirect Symbols [%d symbols]',
        [ADocument.MachIndirectSymbols.Count]), tdkMachIndirectSymbols);
  end
  else
  begin
    if ADocument.MachDynamicImports.Count > 0 then
      AddNode(AParent, Format('Dynamic Imports [%d symbols]',
        [ADocument.MachDynamicImports.Count]), tdkMachDynamicImports);
    if ADocument.MachIndirectSymbols.Count > 0 then
      AddNode(AParent, Format('Indirect Symbols [%d symbols]',
        [ADocument.MachIndirectSymbols.Count]), tdkMachIndirectSymbols);
  end;
  if ADocument.MachRebaseInfo <> nil then
  begin
    var LRebaseNode := AddNode(AParent, Format('Rebase Info [%d opcodes]',
      [ADocument.MachRebaseInfo.ItemCount]), tdkMachRebaseInfo);
    var LNodeData := PTreeItemData(FTree.GetNodeData(LRebaseNode));
    LNodeData.SourceStartLine := ADocument.MachRebaseInfo.StartLine;
    LNodeData.SourceEndLine := ADocument.MachRebaseInfo.EndLine;
  end;
  if ADocument.MachBindingInfo <> nil then
  begin
    var LBindingNode := AddNode(AParent, Format('Binding Info [%d lines]',
      [ADocument.MachBindingInfo.ItemCount]), tdkMachBindingInfo);
    var LNodeData := PTreeItemData(FTree.GetNodeData(LBindingNode));
    LNodeData.SourceStartLine := ADocument.MachBindingInfo.StartLine;
    LNodeData.SourceEndLine := ADocument.MachBindingInfo.EndLine;
  end;
  if ADocument.MachWeakBindingInfo <> nil then
  begin
    var LWeakBindingNode := AddNode(AParent, Format('Weak Binding Info [%d lines]',
      [ADocument.MachWeakBindingInfo.ItemCount]), tdkMachWeakBindingInfo);
    var LNodeData := PTreeItemData(FTree.GetNodeData(LWeakBindingNode));
    LNodeData.SourceStartLine := ADocument.MachWeakBindingInfo.StartLine;
    LNodeData.SourceEndLine := ADocument.MachWeakBindingInfo.EndLine;
  end;
  if ADocument.MachLazyBindingInfo <> nil then
  begin
    var LLazyBindingNode := AddNode(AParent, Format('Lazy Binding Info [%d lines]',
      [ADocument.MachLazyBindingInfo.ItemCount]), tdkMachLazyBindingInfo);
    var LNodeData := PTreeItemData(FTree.GetNodeData(LLazyBindingNode));
    LNodeData.SourceStartLine := ADocument.MachLazyBindingInfo.StartLine;
    LNodeData.SourceEndLine := ADocument.MachLazyBindingInfo.EndLine;
  end;
  if ADocument.MachExports <> nil then
  begin
    var LExportsNode := AddNode(AParent, Format('Exports [%d lines]',
      [ADocument.MachExports.ItemCount]), tdkMachExports);
    var LNodeData := PTreeItemData(FTree.GetNodeData(LExportsNode));
    LNodeData.SourceStartLine := ADocument.MachExports.StartLine;
    LNodeData.SourceEndLine := ADocument.MachExports.EndLine;
  end;
  if ADocument.MachResources <> nil then
  begin
    var LResourcesNode := AddNode(AParent, Format('Resources [%d entries]',
      [ADocument.MachResources.ItemCount]), tdkMachResources);
    var LNodeData := PTreeItemData(FTree.GetNodeData(LResourcesNode));
    LNodeData.SourceStartLine := ADocument.MachResources.StartLine;
    LNodeData.SourceEndLine := ADocument.MachResources.EndLine;
  end;
  if ADocument.MachRawSymbols <> nil then
  begin
    var LRawSymbolsNode := AddNode(AParent, Format('Raw Symbols [%d entries]',
      [ADocument.MachRawSymbols.ItemCount]), tdkMachRawSymbols);
    var LNodeData := PTreeItemData(FTree.GetNodeData(LRawSymbolsNode));
    LNodeData.SourceStartLine := ADocument.MachRawSymbols.StartLine;
    LNodeData.SourceEndLine := ADocument.MachRawSymbols.EndLine;
  end;
end;

procedure TDocumentTreeBuilder.AddBorlandNodes(AParent: PVirtualNode;
  ADocument: TDumpDocument);
begin
  if not HasBorlandSymbolTable(ADocument) then
    Exit;
  var LBorlandNode := AddNode(AParent, Format(
    'Borland 32-bit Symbol Table [%d subsections]',
    [ADocument.BorlandSubsections.Count]), tdkBorlandSymbolTable);
  for var LIndex := 0 to ADocument.BorlandSubsections.Count - 1 do
  begin
    var LSubsection := ADocument.BorlandSubsections[LIndex];
    var LCaption := LSubsection.SubsectionType;
    if LCaption = '' then
      LCaption := 'Subsection';
    var LSubsectionNode := AddNode(LBorlandNode,
      Format('%s (module %d)', [LCaption, LSubsection.ModIndex]),
      tdkBorlandSubsection);
    PTreeItemData(FTree.GetNodeData(LSubsectionNode))^.BorlandSubsectionIndex :=
      LIndex;
    AddBorlandChildren(LSubsectionNode, ADocument, LSubsection);
  end;
end;

procedure TDocumentTreeBuilder.AddBorlandChildren(AParent: PVirtualNode;
  ADocument: TDumpDocument; ASubsection: TDumpBorlandSubsection);
begin
  if SameText(ASubsection.SubsectionType, 'sstSrcModule') then
    for var LSourceModule in ADocument.SourceModules do
      if (LSourceModule.ModIndex = ASubsection.ModIndex) and
        (LSourceModule.FileOffset = ASubsection.FileOffset) then
        for var LSourceFile in LSourceModule.SourceFiles do
        begin
          var LCaption := LSourceFile.ResolvedName;
          if LCaption = '' then
            LCaption := LSourceFile.Name;
          if LCaption = '' then
            LCaption := 'Source file';
          var LSourceNode := AddNode(AParent, LCaption, tdkBorlandSourceFile);
          PTreeItemData(FTree.GetNodeData(LSourceNode))^.SourceFile := LSourceFile;
        end;

  if SameText(ASubsection.SubsectionType, 'sstAlignSym') then
    for var LSection in ADocument.AlignSymbolSections do
      if (LSection.ModIndex = ASubsection.ModIndex) and
        (LSection.FileOffset = ASubsection.FileOffset) then
        for var LRecord in LSection.Records do
          if LRecord.ScopeParent = nil then
            AddAlignSymbolRecordNode(AParent, LRecord);

  if SameText(ASubsection.SubsectionType, 'sstAlignSym') then
    for var LSection in ADocument.LazyAlignSymbolSections do
      if (LSection.ModIndex = ASubsection.ModIndex) and
        (LSection.FileOffset = ASubsection.FileOffset) then
        for var LRecordIndex := 0 to LSection.Records.Count - 1 do
          if LSection.Records[LRecordIndex].ParentIndex < 0 then
            AddLazyAlignSymbolRecordNode(AParent, ADocument, LSection,
              LRecordIndex);

  if SameText(ASubsection.SubsectionType, 'sstGlobalSym') then
    for var LSection in ADocument.GlobalSymbolSections do
      if (LSection.ModIndex = ASubsection.ModIndex) and
        (LSection.FileOffset = ASubsection.FileOffset) then
        for var LRecord in LSection.Records do
        begin
          var LRecordNode := AddNode(AParent, BorlandSymbolCaption(LRecord),
            tdkBorlandGlobalSymbolRecord);
          PTreeItemData(FTree.GetNodeData(LRecordNode))^.GlobalSymbolRecord :=
            LRecord;
        end;

  if SameText(ASubsection.SubsectionType, 'sstGlobalSym') then
    for var LSection in ADocument.LazyGlobalSymbolSections do
      if (LSection.ModIndex = ASubsection.ModIndex) and
        (LSection.FileOffset = ASubsection.FileOffset) then
        for var LRecordIndex := 0 to LSection.Records.Count - 1 do
          AddLazyGlobalSymbolRecordNode(AParent, ADocument, LSection,
            LRecordIndex);

  if SameText(ASubsection.SubsectionType, 'sstGlobalTypes') then
    for var LSection in ADocument.GlobalTypeSections do
      if (LSection.ModIndex = ASubsection.ModIndex) and
        (LSection.FileOffset = ASubsection.FileOffset) then
        for var LRecord in LSection.Records do
        begin
          var LRecordNode := AddNode(AParent, BorlandTypeCaption(LRecord),
            tdkBorlandGlobalTypeRecord);
          PTreeItemData(FTree.GetNodeData(LRecordNode))^.GlobalTypeRecord :=
            LRecord;
        end;

  if SameText(ASubsection.SubsectionType, 'sstGlobalTypes') then
    for var LSection in ADocument.LazyGlobalTypeSections do
      if (LSection.ModIndex = ASubsection.ModIndex) and
        (LSection.FileOffset = ASubsection.FileOffset) then
        for var LRecordIndex := 0 to LSection.Records.Count - 1 do
          AddLazyGlobalTypeRecordNode(AParent, ADocument, LSection,
            LRecordIndex);
end;

class procedure TDocumentSourceNavigation.Resolve(ADocument: TDumpDocument;
  const AData: PTreeItemData; out AStartLine, AEndLine: Integer);
  procedure UseSpan(AStart, AEnd: Integer);
  begin
    if AStart < 1 then
      Exit;
    AStartLine := AStart;
    AEndLine := Max(AStart, AEnd);
  end;

  procedure ExtendRange(var AFirstLine, ALastLine: Integer;
    AStart, AEnd: Integer);
  begin
    if AStart < 1 then
      Exit;
    AFirstLine := Min(AFirstLine, AStart);
    ALastLine := Max(ALastLine, Max(AStart, AEnd));
  end;

  procedure UseNodeKind(AKind: TDumpNodeKind);
    procedure Collect(ANode: TDumpNode; var AFirstLine, ALastLine: Integer);
    begin
      if ANode.Kind = AKind then
        ExtendRange(AFirstLine, ALastLine, ANode.StartLine, ANode.EndLine);
      for var LChild in ANode.Children do
        Collect(LChild, AFirstLine, ALastLine);
    end;
  begin
    var LFirstLine := MaxInt;
    var LLastLine := 0;
    for var LNode in ADocument.Nodes do
      Collect(LNode, LFirstLine, LLastLine);
    if LFirstLine <> MaxInt then
      UseSpan(LFirstLine, LLastLine);
  end;

  procedure UseRangeOfObjectRecords;
  begin
    var LFirstLine := MaxInt;
    var LLastLine := 0;
    for var LRecord in ADocument.ObjectRecords do
      ExtendRange(LFirstLine, LLastLine, LRecord.StartLine, LRecord.EndLine);
    UseSpan(LFirstLine, LLastLine);
  end;

  procedure ResolveRemainingKinds;
  begin
    case AData.DetailKind of
      tdkMachArchitecture:
        if AData.MachArchitecture <> nil then
          UseSpan(AData.MachArchitecture.StartLine, AData.MachArchitecture.EndLine);
      tdkMachLoadCommand:
        if AData.MachLoadCommand <> nil then
          UseSpan(AData.MachLoadCommand.StartLine, AData.MachLoadCommand.EndLine);
      tdkMachSection:
        if AData.MachSection <> nil then
          UseSpan(AData.MachSection.StartLine, AData.MachSection.EndLine);
      tdkMachArchitectures:
        begin
          var LFirst := MaxInt; var LLast := 0;
          for var LItem in ADocument.MachArchitectures do
            ExtendRange(LFirst, LLast, LItem.StartLine, LItem.EndLine);
          UseSpan(LFirst, LLast);
        end;
      tdkMachLoadCommands:
        begin
          var LFirst := MaxInt; var LLast := 0;
          for var LItem in ADocument.MachLoadCommands do
            ExtendRange(LFirst, LLast, LItem.StartLine, LItem.EndLine);
          UseSpan(LFirst, LLast);
        end;
      tdkMachSymbolTable:
        begin
          var LFirst := MaxInt; var LLast := 0;
          for var LItem in ADocument.MachSymbols do
            ExtendRange(LFirst, LLast, LItem.StartLine, LItem.EndLine);
          UseSpan(LFirst, LLast);
        end;
      tdkMachDynamicImports:
        begin
          var LFirst := MaxInt; var LLast := 0;
          for var LItem in ADocument.MachDynamicImports do
            ExtendRange(LFirst, LLast, LItem.StartLine, LItem.EndLine);
          UseSpan(LFirst, LLast);
        end;
      tdkMachIndirectSymbols:
        begin
          var LFirst := MaxInt; var LLast := 0;
          for var LItem in ADocument.MachIndirectSymbols do
            ExtendRange(LFirst, LLast, LItem.StartLine, LItem.EndLine);
          UseSpan(LFirst, LLast);
        end;
      tdkELFSymbolTable:
        begin
          var LFirst := MaxInt; var LLast := 0;
          for var LItem in ADocument.Symbols do
            ExtendRange(LFirst, LLast, LItem.StartLine, LItem.StartLine);
          UseSpan(LFirst, LLast);
        end;
      tdkELFDynamicSection:
        begin
          var LFirst := MaxInt; var LLast := 0;
          for var LItem in ADocument.ELFDynamicEntries do
            ExtendRange(LFirst, LLast, LItem.StartLine, LItem.EndLine);
          UseSpan(LFirst, LLast);
        end;
      tdkDiagnostics:
        begin
          var LFirst := MaxInt; var LLast := 0;
          for var LItem in ADocument.Diagnostics do
            ExtendRange(LFirst, LLast, LItem.LineNumber, LItem.LineNumber);
          UseSpan(LFirst, LLast);
        end;
    end;
  end;

begin
  AStartLine := 0;
  AEndLine := 0;
  if (ADocument = nil) or (AData = nil) then
    Exit;
  if AData.SourceStartLine > 0 then
  begin
    AStartLine := AData.SourceStartLine;
    AEndLine := Max(AStartLine, AData.SourceEndLine);
    Exit;
  end;
  case AData.DetailKind of
    tdkDocumentSummary:
      UseSpan(1, ADocument.Lines.Count);
    tdkOldExecutableHeader, tdkPortableExecutableHeader, tdkELFHeader,
    tdkMachHeader:
      if (AData.HeaderIndex >= 0) and
        (AData.HeaderIndex < ADocument.Headers.Count) then
        UseSpan(ADocument.Headers[AData.HeaderIndex].StartLine,
          ADocument.Headers[AData.HeaderIndex].EndLine)
      else
        UseNodeKind(nkHeader);
    tdkDataDirectories:
      if ADocument.DataDirectories.Count = 0 then
        UseNodeKind(nkDataDirectory)
      else
      begin
        var LFirst := MaxInt; var LLast := 0;
        for var LItem in ADocument.DataDirectories do
          ExtendRange(LFirst, LLast, LItem.StartLine, LItem.StartLine);
        UseSpan(LFirst, LLast);
      end;
    tdkObjectTable, tdkELFSectionHeaders:
      UseNodeKind(nkSections);
    tdkELFProgramHeaders:
      if ADocument.ELFProgramHeaders.Count = 0 then
        UseNodeKind(nkSections)
      else
      begin
        var LFirst := MaxInt; var LLast := 0;
        for var LItem in ADocument.ELFProgramHeaders do
          ExtendRange(LFirst, LLast, LItem.StartLine, LItem.EndLine);
        UseSpan(LFirst, LLast);
      end;
    tdkImportDirectory:
      if ADocument.ImportMetadata <> nil then
        UseSpan(ADocument.ImportMetadata.StartLine, ADocument.ImportMetadata.EndLine)
      else
        UseNodeKind(nkImports);
    tdkImportModule:
      if (AData.ImportModuleIndex >= 0) and
        (AData.ImportModuleIndex < ADocument.Imports.Count) then
        UseSpan(ADocument.Imports[AData.ImportModuleIndex].StartLine,
          ADocument.Imports[AData.ImportModuleIndex].EndLine)
      else
        UseNodeKind(nkImports);
    tdkDelayedImportTable:
      if ADocument.DelayedImportTable <> nil then
        UseSpan(ADocument.DelayedImportTable.StartLine,
          ADocument.DelayedImportTable.EndLine)
      else
        UseNodeKind(nkDelayedImports);
    tdkDelayedImportModule:
      if (ADocument.DelayedImportTable <> nil) and
        (AData.ImportModuleIndex >= 0) and
        (AData.ImportModuleIndex < ADocument.DelayedImportTable.Modules.Count) then
        UseSpan(ADocument.DelayedImportTable.Modules[AData.ImportModuleIndex].StartLine,
          ADocument.DelayedImportTable.Modules[AData.ImportModuleIndex].EndLine)
      else
        UseNodeKind(nkDelayedImports);
    tdkExportDirectory:
      if ADocument.ExportMetadata <> nil then
        UseSpan(ADocument.ExportMetadata.StartLine, ADocument.ExportMetadata.EndLine)
      else
        UseNodeKind(nkExports);
    tdkResourceDirectory:
      if ADocument.ResourceMetadata <> nil then
        UseSpan(ADocument.ResourceMetadata.StartLine,
          ADocument.ResourceMetadata.EndLine)
      else
        UseNodeKind(nkResources);
    tdkResource:
      if AData.Resource <> nil then
        UseSpan(AData.Resource.StartLine, AData.Resource.EndLine);
    tdkRelocations:
      if ADocument.RelocationBlocks.Count = 0 then
        UseNodeKind(nkRelocations)
      else
      begin
        var LFirst := MaxInt; var LLast := 0;
        for var LItem in ADocument.RelocationBlocks do
          ExtendRange(LFirst, LLast, LItem.StartLine, LItem.EndLine);
        UseSpan(LFirst, LLast);
      end;
    tdkELFRelocations:
      if ADocument.ELFRelocations.Count = 0 then
        UseNodeKind(nkRelocations)
      else
      begin
        var LFirst := MaxInt; var LLast := 0;
        for var LItem in ADocument.ELFRelocations do
          if (AData.ELFRelocationSectionName = '') or
            SameText(AData.ELFRelocationSectionName, LItem.SectionName) then
            ExtendRange(LFirst, LLast, LItem.StartLine, LItem.EndLine);
        UseSpan(LFirst, LLast);
      end;
    tdkRelocationBlock:
      if AData.RelocationBlock <> nil then
        UseSpan(AData.RelocationBlock.StartLine, AData.RelocationBlock.EndLine);
    tdkStrings:
      if ADocument.Strings.Count = 0 then
        UseNodeKind(nkStrings)
      else
      begin
        var LFirst := MaxInt; var LLast := 0;
        for var LItem in ADocument.Strings do
          ExtendRange(LFirst, LLast, LItem.StartLine, LItem.StartLine);
        UseSpan(LFirst, LLast);
      end;
    tdkOMFRecords, tdkOMFRecord:
      if AData.ObjectRecord <> nil then
        UseSpan(AData.ObjectRecord.StartLine, AData.ObjectRecord.EndLine)
      else if ADocument.ObjectRecords.Count > 0 then
        UseRangeOfObjectRecords
      else
        UseNodeKind(nkObjectRecord);
    tdkOMFLibraryMembers:
      begin
        var LFirst := MaxInt; var LLast := 0;
        for var LItem in ADocument.LibraryMembers do
          ExtendRange(LFirst, LLast, LItem.StartLine, LItem.StartLine);
        if LFirst = MaxInt then UseNodeKind(nkLibrary) else UseSpan(LFirst, LLast);
      end;
    tdkOMFLibraryIndex:
      if ADocument.OMFLibraryIndex <> nil then
        UseSpan(ADocument.OMFLibraryIndex.StartLine, ADocument.OMFLibraryIndex.EndLine)
      else
        UseNodeKind(nkLibrary);
    tdkArchiveMembers:
      begin
        var LFirst := MaxInt; var LLast := 0;
        for var LItem in ADocument.ArchiveMembers do
          ExtendRange(LFirst, LLast, LItem.StartLine, LItem.StartLine);
        if LFirst = MaxInt then UseNodeKind(nkLibrary) else UseSpan(LFirst, LLast);
      end;
    tdkArchiveSymbols:
      begin
        var LFirst := MaxInt; var LLast := 0;
        for var LItem in ADocument.ArchiveSymbols do
          ExtendRange(LFirst, LLast, LItem.StartLine, LItem.StartLine);
        if LFirst = MaxInt then UseNodeKind(nkLibrary) else UseSpan(LFirst, LLast);
      end;
    tdkBorlandSymbolTable:
      UseNodeKind(nkSymbols);
    tdkBorlandSubsection:
      if (AData.BorlandSubsectionIndex >= 0) and
        (AData.BorlandSubsectionIndex < ADocument.BorlandSubsections.Count) then
        UseSpan(ADocument.BorlandSubsections[AData.BorlandSubsectionIndex].StartLine,
          ADocument.BorlandSubsections[AData.BorlandSubsectionIndex].EndLine)
      else
        UseNodeKind(nkDebug);
    tdkBorlandSourceFile:
      if AData.SourceFile <> nil then
        UseSpan(AData.SourceFile.StartLine, AData.SourceFile.StartLine);
    tdkBorlandAlignSymbolRecord:
      if AData.AlignSymbolRecord <> nil then
        UseSpan(AData.AlignSymbolRecord.StartLine, AData.AlignSymbolRecord.EndLine)
      else if (AData.SourceStartLine > 0) and (AData.SourceEndLine >= AData.SourceStartLine) then
        UseSpan(AData.SourceStartLine, AData.SourceEndLine);
      tdkBorlandGlobalSymbolRecord:
        if AData.GlobalSymbolRecord <> nil then
          UseSpan(AData.GlobalSymbolRecord.StartLine, AData.GlobalSymbolRecord.EndLine)
        else if (AData.SourceStartLine > 0) and
          (AData.SourceEndLine >= AData.SourceStartLine) then
          UseSpan(AData.SourceStartLine, AData.SourceEndLine);
      tdkBorlandGlobalTypeRecord:
        if AData.GlobalTypeRecord <> nil then
          UseSpan(AData.GlobalTypeRecord.StartLine, AData.GlobalTypeRecord.EndLine)
        else if (AData.SourceStartLine > 0) and
          (AData.SourceEndLine >= AData.SourceStartLine) then
          UseSpan(AData.SourceStartLine, AData.SourceEndLine);
  else
    ResolveRemainingKinds;
  end;
end;

function PropertyValue(const AProperties: TList<TDumpProperty>;
  const AName: string): string;
begin
  for var LProperty in AProperties do
    if SameText(LProperty.Name, AName) then
      Exit(LProperty.RawValue);
  Result := '';
end;

function ResourceCaption(const AResource: TDumpResource): string;
begin
  Result := AResource.Name;
  if Result = '' then
    Result := AResource.ResourceType;
  if (Result = '') and AResource.HasId then
    Result := Format('Resource %d', [AResource.Id]);
  if Result = '' then
    Result := 'Resource';
  if AResource.Language <> '' then
    Result := Result + ' (' + AResource.Language + ')';
end;

end.
