unit TDump.Explorer.Frame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Math,
  System.Generics.Collections, System.StrUtils, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  TDump.Explorer.HighlighterControl, TDump.Explorer.Highlighter, Vcl.ExtCtrls,
  VirtualTrees.BaseAncestorVCL,
  VirtualTrees.BaseTree, VirtualTrees.AncestorVCL, VirtualTrees,
  TDump.Explorer.Parser, TDump.Explorer.TinyParser, Vcl.WinXPanels,
  TDump.Explorer.CrossReferences, TDump.Explorer.RawView;

type
  TTreeDetailKind = (tdkNone, tdkDocumentSummary,
    tdkOldExecutableHeader, tdkPortableExecutableHeader, tdkELFHeader,
    tdkDataDirectories, tdkObjectTable, tdkImportDirectory,
    tdkImportModule, tdkDelayedImportTable, tdkDelayedImportModule,
    tdkExportDirectory, tdkResourceDirectory,
    tdkResource, tdkBorlandSubsection, tdkBorlandSourceFile,
    tdkBorlandAlignSymbolRecord, tdkBorlandGlobalSymbolRecord,
    tdkBorlandGlobalTypeRecord, tdkMachHeader, tdkMachArchitectures,
    tdkMachArchitecture, tdkMachLoadCommands, tdkMachLoadCommand,
    tdkMachSection, tdkMachSymbolTable, tdkELFSectionHeaders,
    tdkELFProgramHeaders, tdkELFSymbolTable, tdkELFDynamicSection,
    tdkELFRelocations, tdkOMFRecords, tdkOMFRecord,
    tdkOMFLibraryMembers, tdkOMFLibraryIndex, tdkRelocations, tdkRelocationBlock, tdkStrings, tdkMachDynamicImports,
    tdkMachIndirectSymbols, tdkMachDynamicSymbolMetadata, tdkArchiveMembers, tdkArchiveSymbols,
    tdkDiagnostics);

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
    GlobalSymbolRecord: TDumpGlobalSymbolRecord;
    GlobalTypeRecord: TDumpGlobalTypeRecord;
    MachArchitecture: TDumpMachArchitecture;
    MachLoadCommand: TDumpMachLoadCommand;
    MachSection: TDumpMachSection;
    ObjectRecord: TDumpObjectRecord;
    RelocationBlock: TDumpRelocationBlock;
    ELFRelocationSectionName: string;
    DetailItemIndex: Integer;
  end;

  TFrame1 = class(TFrame)
    ProgressBar1: TProgressBar;
    Tree: TVirtualStringTree;
    pnCards: TPanel;
    Splitter1: TSplitter;
    cpViews: TCardPanel;
    pnProperties: TPanel;
    pnTop: TPanel;
    tcViews: TTabControl;
    frCrossReferences: TCrossReferencesFrame;
    Splitter2: TSplitter;
    frRawView: TRawViewFrame;
  private
    FDocument: TDumpDocument;
    FSummaryCard: TCard;
    FSummaryControl: THighlighterControl;
    FHighlighterCards: array[TTreeDetailKind] of TCard;
    FHighlighterControls: array[TTreeDetailKind] of THighlighterControl;
    FActiveDetailNode: PVirtualNode;
    function AddTreeNode(AParent: PVirtualNode; const ACaption: string;
      ADetailKind: TTreeDetailKind = tdkNone;
      AHeaderIndex: Integer = -1; AImportModuleIndex: Integer = -1;
      AResource: TDumpResource = nil;
      ABorlandSubsectionIndex: Integer = -1;
      ASourceFile: TDumpSourceFile = nil;
      AAlignSymbolRecord: TDumpAlignSymbolRecord = nil;
      AGlobalSymbolRecord: TDumpGlobalSymbolRecord = nil;
      AGlobalTypeRecord: TDumpGlobalTypeRecord = nil;
      AMachArchitecture: TDumpMachArchitecture = nil;
      AMachLoadCommand: TDumpMachLoadCommand = nil;
      AMachSection: TDumpMachSection = nil;
      AObjectRecord: TDumpObjectRecord = nil;
      ARelocationBlock: TDumpRelocationBlock = nil): PVirtualNode;
    procedure AddAlignSymbolRecordNode(AParent: PVirtualNode;
      ARecord: TDumpAlignSymbolRecord);
    procedure AddResourceNodes(AParent: PVirtualNode;
      const AResources: TObjectList<TDumpResource>);
    function FileKindCaption(AFileKind: TDumpFileKind): string;
    function HasBorlandSymbolTable: Boolean;
    function ResourceCaption(const AResource: TDumpResource): string;
    function EnsureHighlighterDetailControl(
      ADetailKind: TTreeDetailKind): THighlighterControl;
    function HeaderDetailKind(const AHeader: TDumpHeader): TTreeDetailKind;
    procedure ShowHeaderDetails(ADetailKind: TTreeDetailKind; AHeaderIndex: Integer);
    procedure ShowDataDirectoriesDetails;
    procedure ShowObjectTableDetails;
    procedure ShowELFSectionHeadersDetails;
    procedure ShowELFProgramHeadersDetails;
    procedure ShowELFSymbolTableDetails;
    procedure ShowELFDynamicSectionDetails;
    procedure ShowELFRelocationsDetails(const ASectionName: string);
    procedure ShowRelocationsDetails;
    procedure ShowRelocationBlockDetails(ABlock: TDumpRelocationBlock);
    procedure ShowStringsDetails;
    procedure ShowOMFRecordsDetails;
    procedure ShowOMFLibraryMembersDetails;
    procedure ShowOMFLibraryIndexDetails;
    procedure ShowOMFRecordDetails(ARecord: TDumpObjectRecord);
    procedure ShowArchiveMembersDetails;
    procedure ShowArchiveSymbolsDetails;
    procedure ShowImportDirectoryDetails;
    procedure ShowImportModuleDetails(AImportModuleIndex: Integer);
    procedure ShowImportModuleDetail(AImportModule: TDumpImportModule;
      ADetailKind: TTreeDetailKind);
    procedure ShowDelayedImportTableDetails;
    procedure ShowDelayedImportModuleDetails(AImportModuleIndex: Integer);
    procedure ShowExportDirectoryDetails;
    procedure ShowResourceDirectoryDetails;
    procedure ShowResourceDetails(AResource: TDumpResource);
    procedure ShowBorlandSubsectionDetails(ASubsectionIndex: Integer);
    procedure ShowBorlandSourceFileDetails(ASourceFile: TDumpSourceFile);
    procedure ShowBorlandSymbolRecordDetails(ADetailKind: TTreeDetailKind;
      ARecord: TDumpBorlandSymbolRecord);
    procedure ShowBorlandGlobalTypeRecordDetails(
      ARecord: TDumpGlobalTypeRecord);
    procedure ShowMachArchitecturesDetails;
    procedure ShowMachArchitectureDetails(AArchitecture: TDumpMachArchitecture);
    procedure ShowMachLoadCommandsDetails;
    procedure ShowMachLoadCommandDetails(ACommand: TDumpMachLoadCommand);
    procedure ShowMachSectionDetails(ASection: TDumpMachSection);
    procedure ShowMachSymbolTableDetails;
    procedure ShowMachDynamicSymbolsDetails(ADetailKind: TTreeDetailKind);
    procedure ShowMachDynamicSymbolMetadataDetails;
    procedure ShowDiagnosticsDetails;
    procedure UpdateActiveView;
    function DetailControlForNode(ANode: PVirtualNode): THighlighterControl;
    procedure SaveActiveDetailItemIndex;
    procedure RestoreDetailItemIndex(ANode: PVirtualNode);
    procedure ResolveNodeSourceSpan(const AData: PTreeItemData;
      out AStartLine, AEndLine: Integer);
    procedure SyncRawViewToNode(ANode: PVirtualNode);
    procedure RawViewSyncWithSelectedNodeChanged(Sender: TObject);
    procedure ActivateNode(ANode: PVirtualNode);
    procedure TreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure tcViewsChange(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Takes ownership of ADocument.
    procedure PopulateTree(ADocument: TDumpDocument);
    procedure SetProgress(ACompletedLines, ATotalLines: Integer);
    procedure SetStatus(const AStatus: string);
    procedure ShowSummary(const ASummary: string);
  end;

implementation

{$R *.dfm}

function IsBorlandMethodName(const AValue: string): Boolean;
var
  LValue: string;
begin
  LValue := Trim(AValue);
  Result := (LValue <> '') and
    ((LValue[1] = '@') or
     ((Pos('(', LValue) > 1) and
      (LastDelimiter(')', LValue) > Pos('(', LValue))) or
     ContainsText(LValue, '__fastcall') or
     ContainsText(LValue, '__cdecl') or
     ContainsText(LValue, '__stdcall') or
     ContainsText(LValue, '__linkproc'));
end;

function BorlandSymbolCaption(const ARecord: TDumpBorlandSymbolRecord): string;
begin
  Result := ARecord.ResolvedName;
  if Result = '' then
    Result := ARecord.Name;
  if Result = '' then
    Result := ARecord.RecordKind;
  if Result = '' then
    Result := 'Symbol record';
  if (ARecord.RecordKind <> '') and not SameText(Result, ARecord.RecordKind) then
    Result := ARecord.RecordKind + '  ' + Result;
end;

function BorlandTypeCaption(const ARecord: TDumpGlobalTypeRecord): string;
begin
  Result := 'Type ' + ARecord.RawTypeIndex;
  if ARecord.TypeKind <> '' then
    Result := Result + '  ' + ARecord.TypeKind;
  if ARecord.ResolvedName <> '' then
    Result := Result + '  ' + ARecord.ResolvedName
  else if ARecord.Name <> '' then
    Result := Result + '  ' + ARecord.Name;
end;

function PropertyValue(const AProperties: TList<TDumpProperty>;
  const AName: string): string;
begin
  for var LProperty in AProperties do
    if SameText(LProperty.Name, AName) then
      Exit(LProperty.RawValue);
  Result := '';
end;

constructor TFrame1.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSummaryCard := TCard.Create(cpViews);
  FSummaryCard.Parent := cpViews;
  FSummaryCard.Caption := 'Summary';
  FSummaryControl := THighlighterControl.Create(FSummaryCard);
  FSummaryControl.Parent := FSummaryCard;
  FSummaryControl.Align := alClient;
  cpViews.ActiveCard := FSummaryCard;
  Tree.NodeDataSize := SizeOf(TTreeItemData);
  Tree.OnGetText := TreeGetText;
  Tree.OnFreeNode := TreeFreeNode;
  Tree.OnFocusChanged := TreeFocusChanged;
  Tree.OnMouseUp := TreeMouseUp;
  frRawView.OnSyncWithSelectedNodeChanged :=
    RawViewSyncWithSelectedNodeChanged;
  tcViews.OnChange := tcViewsChange;
  tcViews.TabIndex := 0;
  UpdateActiveView;
end;

destructor TFrame1.Destroy;
begin
  frCrossReferences.Clear;
  FDocument.Free;
  inherited;
end;

function TFrame1.AddTreeNode(AParent: PVirtualNode;
  const ACaption: string; ADetailKind: TTreeDetailKind;
  AHeaderIndex, AImportModuleIndex: Integer;
  AResource: TDumpResource;
  ABorlandSubsectionIndex: Integer;
  ASourceFile: TDumpSourceFile;
  AAlignSymbolRecord: TDumpAlignSymbolRecord;
  AGlobalSymbolRecord: TDumpGlobalSymbolRecord;
  AGlobalTypeRecord: TDumpGlobalTypeRecord;
  AMachArchitecture: TDumpMachArchitecture;
  AMachLoadCommand: TDumpMachLoadCommand;
  AMachSection: TDumpMachSection;
  AObjectRecord: TDumpObjectRecord;
  ARelocationBlock: TDumpRelocationBlock): PVirtualNode;
begin
  Result := Tree.AddChild(AParent);
  PTreeItemData(Tree.GetNodeData(Result))^.Caption := ACaption;
  PTreeItemData(Tree.GetNodeData(Result))^.DetailKind := ADetailKind;
  PTreeItemData(Tree.GetNodeData(Result))^.HeaderIndex := AHeaderIndex;
  PTreeItemData(Tree.GetNodeData(Result))^.ImportModuleIndex := AImportModuleIndex;
  PTreeItemData(Tree.GetNodeData(Result))^.Resource := AResource;
  PTreeItemData(Tree.GetNodeData(Result))^.BorlandSubsectionIndex :=
    ABorlandSubsectionIndex;
  PTreeItemData(Tree.GetNodeData(Result))^.SourceFile := ASourceFile;
  PTreeItemData(Tree.GetNodeData(Result))^.AlignSymbolRecord :=
    AAlignSymbolRecord;
  PTreeItemData(Tree.GetNodeData(Result))^.GlobalSymbolRecord :=
    AGlobalSymbolRecord;
  PTreeItemData(Tree.GetNodeData(Result))^.GlobalTypeRecord := AGlobalTypeRecord;
  PTreeItemData(Tree.GetNodeData(Result))^.MachArchitecture := AMachArchitecture;
  PTreeItemData(Tree.GetNodeData(Result))^.MachLoadCommand := AMachLoadCommand;
  PTreeItemData(Tree.GetNodeData(Result))^.MachSection := AMachSection;
  PTreeItemData(Tree.GetNodeData(Result))^.ObjectRecord := AObjectRecord;
  PTreeItemData(Tree.GetNodeData(Result))^.RelocationBlock := ARelocationBlock;
  PTreeItemData(Tree.GetNodeData(Result))^.DetailItemIndex := -1;
end;

procedure TFrame1.AddAlignSymbolRecordNode(AParent: PVirtualNode;
  ARecord: TDumpAlignSymbolRecord);
begin
  var LRecordNode := AddTreeNode(AParent, BorlandSymbolCaption(ARecord),
    tdkBorlandAlignSymbolRecord, -1, -1, nil, -1, nil, ARecord);
  for var LChild in ARecord.ScopeChildren do
    AddAlignSymbolRecordNode(LRecordNode, TDumpAlignSymbolRecord(LChild));
end;

procedure TFrame1.AddResourceNodes(AParent: PVirtualNode;
  const AResources: TObjectList<TDumpResource>);
begin
  for var LResource in AResources do
  begin
    if SameText(LResource.ResourceType, 'Unknown') then
      Continue;
    var LResourceNode := AddTreeNode(AParent, ResourceCaption(LResource),
      tdkResource, -1, -1, LResource);
    AddResourceNodes(LResourceNode, LResource.Children);
  end;
end;

function TFrame1.FileKindCaption(AFileKind: TDumpFileKind): string;
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

function TFrame1.EnsureHighlighterDetailControl(
  ADetailKind: TTreeDetailKind): THighlighterControl;
begin
  if FHighlighterControls[ADetailKind] = nil then
  begin
    var LCard := TCard.Create(cpViews);
    LCard.Parent := cpViews;
    case ADetailKind of
      tdkDataDirectories:
        LCard.Caption := 'Data Directories';
      tdkObjectTable:
        LCard.Caption := 'Object Table';
      tdkImportDirectory:
        LCard.Caption := 'Import Directory';
      tdkImportModule:
        LCard.Caption := 'Import Module';
      tdkDelayedImportTable:
        LCard.Caption := 'Delayed Load Import Table';
      tdkDelayedImportModule:
        LCard.Caption := 'Delayed Import Module';
      tdkExportDirectory:
        LCard.Caption := 'Export Directory';
      tdkResourceDirectory:
        LCard.Caption := 'Resources';
      tdkResource:
        LCard.Caption := 'Resource';
      tdkBorlandSubsection:
        LCard.Caption := 'Borland Subsection';
      tdkBorlandSourceFile:
        LCard.Caption := 'Source File';
      tdkBorlandAlignSymbolRecord:
        LCard.Caption := 'Alignment Symbol';
      tdkBorlandGlobalSymbolRecord:
        LCard.Caption := 'Global Symbol';
      tdkBorlandGlobalTypeRecord:
        LCard.Caption := 'Global Type';
      tdkMachHeader:
        LCard.Caption := 'Mach Header';
      tdkMachArchitectures:
        LCard.Caption := 'FAT Architectures';
      tdkMachArchitecture:
        LCard.Caption := 'FAT Architecture';
      tdkMachLoadCommands:
        LCard.Caption := 'Load Commands';
      tdkMachLoadCommand:
        LCard.Caption := 'Load Command';
      tdkMachSection:
        LCard.Caption := 'Mach Section';
      tdkMachSymbolTable:
        LCard.Caption := 'Symbol Table';
      tdkELFHeader:
        LCard.Caption := 'ELF Header';
      tdkELFSectionHeaders:
        LCard.Caption := 'ELF Section Headers';
      tdkELFProgramHeaders:
        LCard.Caption := 'ELF Program Headers';
      tdkELFSymbolTable:
        LCard.Caption := 'ELF Symbol Table';
      tdkELFDynamicSection:
        LCard.Caption := 'ELF Dynamic Section';
      tdkELFRelocations:
        LCard.Caption := 'ELF Relocations';
      tdkRelocations:
        LCard.Caption := 'Relocations';
      tdkRelocationBlock:
        LCard.Caption := 'Relocation Block';
      tdkStrings:
        LCard.Caption := 'Strings';
      tdkOMFRecords:
        LCard.Caption := 'OMF Records';
      tdkOMFRecord:
        LCard.Caption := 'OMF Record';
      tdkOMFLibraryMembers:
        LCard.Caption := 'OMF Library Members';
      tdkOMFLibraryIndex:
        LCard.Caption := 'OMF Library Index';
      tdkArchiveMembers:
        LCard.Caption := 'AR Archive Members';
      tdkArchiveSymbols:
        LCard.Caption := 'AR Archive Symbols';
      tdkMachDynamicImports:
        LCard.Caption := 'Mach Dynamic Imports';
      tdkMachIndirectSymbols:
        LCard.Caption := 'Mach Indirect Symbols';
      tdkMachDynamicSymbolMetadata:
        LCard.Caption := 'Mach Dynamic Symbol Table';
      tdkDiagnostics:
        LCard.Caption := 'Diagnostics';
    end;
    FHighlighterCards[ADetailKind] := LCard;

    var LControl := THighlighterControl.Create(LCard);
    LControl.Parent := LCard;
    LControl.Align := alClient;
    FHighlighterControls[ADetailKind] := LControl;
  end;
  Result := FHighlighterControls[ADetailKind];
end;

function TFrame1.HeaderDetailKind(
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

function TFrame1.HasBorlandSymbolTable: Boolean;
begin
  Result := FDocument.BorlandSubsections.Count > 0;
  if Result then
    Exit;

  for var LNode in FDocument.Nodes do
    if SameText(LNode.Title, 'Borland 32 bit symbol table') then
      Exit(True);
end;

function TFrame1.ResourceCaption(const AResource: TDumpResource): string;
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

procedure TFrame1.ShowHeaderDetails(ADetailKind: TTreeDetailKind;
  AHeaderIndex: Integer);
begin
  if (FDocument = nil) or (AHeaderIndex < 0) or
    (AHeaderIndex >= FDocument.Headers.Count) then
    Exit;

  var LControl := EnsureHighlighterDetailControl(ADetailKind);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Name', 'Value']);
  var LHeader := FDocument.Headers[AHeaderIndex];
  for var LProperty in LHeader.Properties do
      LControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[ADetailKind];
end;

procedure TFrame1.ShowMachArchitecturesDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkMachArchitectures);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['CPU type', 'CPU subtype', 'File offset']);
    LControl.SetColumnDataTypes([thdtSymbol, thdtSymbol, thdtHexadecimal]);
    for var LArchitecture in FDocument.MachArchitectures do
    begin
      var LOffset := '';
      if LArchitecture.HasOffset then
        LOffset := IntToHex(LArchitecture.Offset, 8);
      LControl.AddColumns([LArchitecture.CPUType, LArchitecture.CPUSubtype,
        LOffset]);
    end;
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkMachArchitectures];
end;

procedure TFrame1.ShowMachArchitectureDetails(
  AArchitecture: TDumpMachArchitecture);
begin
  if AArchitecture = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkMachArchitecture);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Name', 'Value']);
    LControl.AddColumns(['CPU type', AArchitecture.CPUType]);
    LControl.AddColumns(['CPU subtype', AArchitecture.CPUSubtype]);
    if AArchitecture.HasOffset then
      LControl.AddColumns(['File offset', IntToHex(AArchitecture.Offset, 8)]);
  finally
    LControl.EndUpdate;
  end;
  FHighlighterCards[tdkMachArchitecture].Caption := AArchitecture.CPUType;
  cpViews.ActiveCard := FHighlighterCards[tdkMachArchitecture];
end;

procedure TFrame1.ShowMachLoadCommandsDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkMachLoadCommands);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['#', 'Command', 'Sections']);
    LControl.SetColumnDataTypes([thdtInteger, thdtSymbol, thdtInteger]);
    for var LCommand in FDocument.MachLoadCommands do
      LControl.AddColumns([IntToStr(LCommand.Index), LCommand.Name,
        IntToStr(LCommand.Sections.Count)]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkMachLoadCommands];
end;

procedure TFrame1.ShowMachLoadCommandDetails(ACommand: TDumpMachLoadCommand);
begin
  if ACommand = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkMachLoadCommand);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Name', 'Value']);
    LControl.AddColumns(['Index', IntToStr(ACommand.Index)]);
    LControl.AddColumns(['Command', ACommand.Name]);
    if ACommand.Sections.Count > 0 then
      LControl.AddColumns(['Sections', IntToStr(ACommand.Sections.Count)]);
    for var LProperty in ACommand.Properties do
      LControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    LControl.EndUpdate;
  end;
  FHighlighterCards[tdkMachLoadCommand].Caption := Format('#%d %s',
    [ACommand.Index, ACommand.Name]);
  cpViews.ActiveCard := FHighlighterCards[tdkMachLoadCommand];
end;

procedure TFrame1.ShowMachSectionDetails(ASection: TDumpMachSection);
begin
  if ASection = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkMachSection);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Name', 'Value']);
    for var LProperty in ASection.Properties do
      LControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    LControl.EndUpdate;
  end;
  FHighlighterCards[tdkMachSection].Caption := ASection.Name;
  cpViews.ActiveCard := FHighlighterCards[tdkMachSection];
end;

procedure TFrame1.ShowMachSymbolTableDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkMachSymbolTable);
  LControl.ParserMode := tpmCppBuilderMethod;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Index', 'Type', 'Section', 'Desc', 'Value',
      'Name']);
    LControl.SetColumnDataTypes([thdtInteger, thdtSymbol, thdtSymbol,
      thdtHexadecimal, thdtHexadecimal, thdtAuto]);
    for var LSymbol in FDocument.MachSymbols do
      LControl.AddColumns([IntToStr(LSymbol.Index), LSymbol.TypeCode,
        LSymbol.Section, LSymbol.Description, LSymbol.RawValue, LSymbol.Name]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkMachSymbolTable];
end;

procedure TFrame1.ShowMachDynamicSymbolsDetails(ADetailKind: TTreeDetailKind);
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(ADetailKind);
  LControl.ParserMode := tpmCppBuilderMethod;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Index', 'Name']);
    LControl.SetColumnDataTypes([thdtInteger, thdtAuto]);
    case ADetailKind of
      tdkMachDynamicImports:
        for var LSymbol in FDocument.MachDynamicImports do
          LControl.AddColumns([IntToStr(LSymbol.Index), LSymbol.Name]);
      tdkMachIndirectSymbols:
        for var LSymbol in FDocument.MachIndirectSymbols do
          LControl.AddColumns([IntToStr(LSymbol.Index), LSymbol.Name]);
    end;
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[ADetailKind];
end;

procedure TFrame1.ShowMachDynamicSymbolMetadataDetails;
begin
  if (FDocument = nil) or (FDocument.MachDynamicSymbolTableCommand = nil) then
    Exit;

  var LCommand := FDocument.MachDynamicSymbolTableCommand;
  var LControl := EnsureHighlighterDetailControl(tdkMachDynamicSymbolMetadata);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Property', 'Value']);
    LControl.AddColumns(['Load command', Format('#%d %s',
      [LCommand.Index, LCommand.Name])]);
    LControl.AddColumns(['Dynamic imports',
      FDocument.MachDynamicImports.Count.ToString]);
    LControl.AddColumns(['Indirect symbols',
      FDocument.MachIndirectSymbols.Count.ToString]);
    for var LProperty in LCommand.Properties do
      LControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkMachDynamicSymbolMetadata];
end;

procedure TFrame1.ShowDataDirectoriesDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkDataDirectories);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Name', 'RVA', 'Size']);
    LControl.SetColumnDataTypes([thdtText, thdtHexadecimal, thdtHexadecimal]);
    for var LDirectory in FDocument.DataDirectories do
    begin
      var LRVA := LDirectory.RawRVA;
      if LRVA = '' then
        LRVA := IntToHex(LDirectory.RVA, 8);
      var LSize := LDirectory.RawSize;
      if LSize = '' then
        LSize := IntToHex(LDirectory.Size, 8);
      LControl.AddColumns([LDirectory.Name, LRVA, LSize]);
    end;
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkDataDirectories];
end;

procedure TFrame1.ShowObjectTableDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkObjectTable);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['#', 'Name', 'VirtSize', 'RVA', 'PhysSize',
      'Phys off', 'Flags']);
    LControl.SetColumnDataTypes([thdtHexadecimal, thdtText, thdtHexadecimal,
      thdtHexadecimal, thdtHexadecimal, thdtHexadecimal, thdtSymbol]);
    for var LSection in FDocument.Sections do
      LControl.AddColumns([IntToHex(LSection.Index, 2), LSection.Name,
        IntToHex(LSection.VirtualSize, 8), IntToHex(LSection.RVA, 8),
        IntToHex(LSection.RawSize, 8), IntToHex(LSection.RawOffset, 8),
        LSection.FlagsText]);
    LControl.AddColumns(['Key to section flags:', '', '', '', '', '', '']);
    LControl.AddColumns(['C - code', 'D - discardable', 'E - executable',
      'I - initialized', 'R - readable', 'W - writeable', '']);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkObjectTable];
end;

procedure TFrame1.ShowELFSectionHeadersDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkELFSectionHeaders);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Ndx', 'Name', 'Type', 'Flags', 'Address',
      'Offset', 'Size', 'Link', 'Info', 'Align', 'Entry size']);
    LControl.SetColumnDataTypes([thdtInteger, thdtText, thdtSymbol,
      thdtSymbol, thdtHexadecimal, thdtHexadecimal, thdtHexadecimal,
      thdtHexadecimal, thdtHexadecimal, thdtHexadecimal, thdtHexadecimal]);
    for var LSection in FDocument.Sections do
      LControl.AddColumns([IntToStr(LSection.Index), LSection.Name,
        PropertyValue(LSection.Properties, 'Type'),
        PropertyValue(LSection.Properties, 'Flags'),
        PropertyValue(LSection.Properties, 'Address'),
        PropertyValue(LSection.Properties, 'Offset'),
        PropertyValue(LSection.Properties, 'Size'),
        PropertyValue(LSection.Properties, 'Link'),
        PropertyValue(LSection.Properties, 'Info'),
        PropertyValue(LSection.Properties, 'Align'),
        PropertyValue(LSection.Properties, 'Entry size')]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkELFSectionHeaders];
end;

procedure TFrame1.ShowELFProgramHeadersDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkELFProgramHeaders);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Ndx', 'Type', 'Offset', 'VAddr', 'PAddr',
      'File size', 'Memory size', 'Flags', 'Align']);
    LControl.SetColumnDataTypes([thdtInteger, thdtSymbol, thdtHexadecimal,
      thdtHexadecimal, thdtHexadecimal, thdtHexadecimal, thdtHexadecimal,
      thdtSymbol, thdtHexadecimal]);
    for var LHeader in FDocument.ELFProgramHeaders do
      LControl.AddColumns([IntToStr(LHeader.Index), LHeader.HeaderType,
        LHeader.Offset, LHeader.VirtualAddress, LHeader.PhysicalAddress,
        LHeader.FileSize, LHeader.MemorySize, LHeader.Flags,
        LHeader.Alignment]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkELFProgramHeaders];
end;

procedure TFrame1.ShowELFSymbolTableDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkELFSymbolTable);
  LControl.ParserMode := tpmCppBuilderMethod;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Ndx', 'Name', 'Value', 'Size', 'Type',
      'Bind', 'Other', 'Section']);
    LControl.SetColumnDataTypes([thdtInteger, thdtAuto, thdtHexadecimal,
      thdtHexadecimal, thdtSymbol, thdtSymbol, thdtSymbol, thdtSymbol]);
    for var LSymbol in FDocument.Symbols do
      LControl.AddColumns([PropertyValue(LSymbol.Properties, 'Index'),
        PropertyValue(LSymbol.Properties, 'Name'),
        PropertyValue(LSymbol.Properties, 'Value'),
        PropertyValue(LSymbol.Properties, 'Size'),
        PropertyValue(LSymbol.Properties, 'Type'),
        PropertyValue(LSymbol.Properties, 'Bind'),
        PropertyValue(LSymbol.Properties, 'Other'),
        PropertyValue(LSymbol.Properties, 'Section')]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkELFSymbolTable];
end;

procedure TFrame1.ShowELFDynamicSectionDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkELFDynamicSection);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Ndx', 'Tag', 'Value']);
    LControl.SetColumnDataTypes([thdtInteger, thdtSymbol, thdtHexadecimal]);
    for var LEntry in FDocument.ELFDynamicEntries do
      LControl.AddColumns([LEntry.Index.ToString, LEntry.Tag, LEntry.Value]);
  finally
    LControl.EndUpdate;
  end;
  FHighlighterCards[tdkELFDynamicSection].Caption := Format(
    'ELF Dynamic Section [%d entries]', [FDocument.ELFDynamicEntries.Count]);
  cpViews.ActiveCard := FHighlighterCards[tdkELFDynamicSection];
end;

procedure TFrame1.ShowELFRelocationsDetails(const ASectionName: string);
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkELFRelocations);
  LControl.ParserMode := tpmCppBuilderMethod;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    if ASectionName = '' then
    begin
      var LCounts := TDictionary<string, Integer>.Create;
      try
        for var LRelocation in FDocument.ELFRelocations do
        begin
          var LCount := 0;
          LCounts.TryGetValue(LRelocation.SectionName, LCount);
          LCounts.AddOrSetValue(LRelocation.SectionName, LCount + 1);
        end;
        LControl.SetColumnHeaders(['Section', 'Entries']);
        LControl.SetColumnDataTypes([thdtText, thdtInteger]);
        for var LSectionName in LCounts.Keys do
          LControl.AddColumns([LSectionName,
            LCounts[LSectionName].ToString]);
      finally
        LCounts.Free;
      end;
    end
    else
    begin
      LControl.SetColumnHeaders(['Ndx', 'Type', 'Offset', '(Addend)', 'Value',
        'Symbol', 'Addend', 'Name']);
      LControl.SetColumnDataTypes([thdtInteger, thdtSymbol, thdtHexadecimal,
        thdtHexadecimal, thdtHexadecimal, thdtInteger, thdtHexadecimal,
        thdtAuto]);
      for var LRelocation in FDocument.ELFRelocations do
        if SameText(LRelocation.SectionName, ASectionName) then
          LControl.AddColumns([IntToStr(LRelocation.Index),
            LRelocation.RelocationType, LRelocation.Offset,
            LRelocation.ParenthesizedAddend, LRelocation.Value,
            LRelocation.SymbolIndex, LRelocation.Addend, LRelocation.Name]);
    end;
  finally
    LControl.EndUpdate;
  end;
  if ASectionName = '' then
    FHighlighterCards[tdkELFRelocations].Caption := Format(
      'ELF Relocation Tables [%d entries]', [FDocument.ELFRelocations.Count])
  else
    FHighlighterCards[tdkELFRelocations].Caption :=
      'ELF Relocations ' + ASectionName;
  cpViews.ActiveCard := FHighlighterCards[tdkELFRelocations];
end;

procedure TFrame1.ShowRelocationsDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkRelocations);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Block', 'Page RVA', 'Block size', 'Entries']);
    LControl.SetColumnDataTypes([thdtInteger, thdtHexadecimal,
      thdtHexadecimal, thdtInteger]);
    for var LBlock in FDocument.RelocationBlocks do
      LControl.AddColumns([UIntToStr(LBlock.Index),
        IntToHex(LBlock.PageRVA, 8), IntToHex(LBlock.BlockSize, 8),
        IntToStr(LBlock.Entries.Count)]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkRelocations];
end;

procedure TFrame1.ShowRelocationBlockDetails(ABlock: TDumpRelocationBlock);
begin
  if ABlock = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkRelocationBlock);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Type', 'Offset']);
    LControl.SetColumnDataTypes([thdtSymbol, thdtHexadecimal]);
    for var LRelocation in ABlock.Entries do
    begin
      var LOffset := LRelocation.RawOffset;
      if (LOffset = '') and LRelocation.HasOffset then
        LOffset := IntToHex(LRelocation.Offset, 4);
      LControl.AddColumns([LRelocation.RelocationType, LOffset]);
    end;
  finally
    LControl.EndUpdate;
  end;
  FHighlighterCards[tdkRelocationBlock].Caption := Format(
    'Block #%d: Page RVA = %s, block size = %s', [ABlock.Index,
    IntToHex(ABlock.PageRVA, 8), IntToHex(ABlock.BlockSize, 8)]);
  cpViews.ActiveCard := FHighlighterCards[tdkRelocationBlock];
end;

procedure TFrame1.ShowStringsDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkStrings);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Offset', 'String']);
    LControl.SetColumnDataTypes([thdtInteger, thdtText]);
    for var LEntry in FDocument.Strings do
    begin
      var LOffset := '';
      if LEntry.HasOffset then
        LOffset := UIntToStr(LEntry.Offset);
      LControl.AddColumns([LOffset, LEntry.Value]);
    end;
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkStrings];
end;

procedure TFrame1.ShowOMFRecordsDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkOMFRecords);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Property', 'Value']);
    LControl.SetColumnDataTypes([thdtText, thdtAuto]);
    LControl.AddColumns(['Records', IntToStr(FDocument.ObjectRecords.Count)]);
    if FDocument.ObjectRecords.Count > 0 then
    begin
      var LFirstRecord := FDocument.ObjectRecords[0];
      var LLastRecord := FDocument.ObjectRecords.Last;
      LControl.AddColumns(['First record', LFirstRecord.RawOffset + ' ' +
        LFirstRecord.RecordKind]);
      LControl.AddColumns(['Last record', LLastRecord.RawOffset + ' ' +
        LLastRecord.RecordKind]);
      LControl.AddColumns(['Source lines', Format('%d..%d',
        [LFirstRecord.StartLine, LLastRecord.EndLine])]);
    end;
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkOMFRecords];
end;

procedure TFrame1.ShowOMFLibraryMembersDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkOMFLibraryMembers);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Member', 'Start line', 'End line', 'Lines']);
    LControl.SetColumnDataTypes([thdtText, thdtInteger, thdtInteger,
      thdtInteger]);
    for var LMember in FDocument.LibraryMembers do
      LControl.AddColumns([LMember.Name, IntToStr(LMember.StartLine),
        IntToStr(LMember.EndLine),
        IntToStr(LMember.EndLine - LMember.StartLine + 1)]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkOMFLibraryMembers];
end;

procedure TFrame1.ShowOMFLibraryIndexDetails;
begin
  if (FDocument = nil) or (FDocument.OMFLibraryIndex = nil) then
    Exit;

  var LIndex := FDocument.OMFLibraryIndex;
  var LControl := EnsureHighlighterDetailControl(tdkOMFLibraryIndex);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Property', 'Value']);
    if LIndex.HasFileOffset then
      LControl.AddColumns(['Index file offset', LIndex.RawFileOffset]);
    if LIndex.HasBlockCount then
      LControl.AddColumns(['Index blocks', LIndex.BlockCount.ToString]);
    if LIndex.HasPageSize then
      LControl.AddColumns(['Library page size', LIndex.PageSize.ToString +
        ' bytes']);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkOMFLibraryIndex];
end;

procedure TFrame1.ShowArchiveMembersDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkArchiveMembers);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Index', 'Member', 'Offset', 'Size', 'Mode',
      'UID', 'GID', 'Timestamp']);
    LControl.SetColumnDataTypes([thdtInteger, thdtText, thdtHexadecimal,
      thdtHexadecimal, thdtText, thdtInteger, thdtInteger, thdtText]);
    for var LMember in FDocument.ArchiveMembers do
      LControl.AddColumns([IntToStr(LMember.Index), LMember.Name,
        LMember.RawOffset, LMember.RawSize, LMember.Mode, LMember.UserId,
        LMember.GroupId, LMember.Timestamp]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkArchiveMembers];
end;

procedure TFrame1.ShowArchiveSymbolsDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkArchiveSymbols);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Index', 'Symbol', 'Member', 'Offset', 'Size']);
    LControl.SetColumnDataTypes([thdtInteger, thdtText, thdtText,
      thdtHexadecimal, thdtHexadecimal]);
    for var LSymbol in FDocument.ArchiveSymbols do
      LControl.AddColumns([IntToStr(LSymbol.Index), LSymbol.Name,
        LSymbol.MemberName, LSymbol.RawMemberOffset, LSymbol.RawMemberSize]);
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkArchiveSymbols];
end;

procedure TFrame1.ShowOMFRecordDetails(ARecord: TDumpObjectRecord);
begin
  if ARecord = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkOMFRecord);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Property', 'Value']);
    LControl.AddColumns(['Offset', ARecord.RawOffset]);
    LControl.AddColumns(['Record', ARecord.RecordKind]);
    if ARecord.Name <> '' then
      LControl.AddColumns(['Name', ARecord.Name]);
    for var LDetail in ARecord.Details do
      LControl.AddColumns([LDetail.Name, LDetail.RawValue]);
  finally
    LControl.EndUpdate;
  end;
  FHighlighterCards[tdkOMFRecord].Caption := ARecord.RawOffset + ' ' +
    ARecord.RecordKind;
  cpViews.ActiveCard := FHighlighterCards[tdkOMFRecord];
end;

procedure TFrame1.ShowImportDirectoryDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkImportDirectory);
  LControl.ParserMode := tpmCppBuilderMethod;
  var LText := TStringBuilder.Create;
  try
    LText.AppendLine('Import Directory');
    LText.AppendLine(Format('%d module(s)', [FDocument.Imports.Count]));
    LText.AppendLine;
    for var LModuleIndex := 0 to FDocument.Imports.Count - 1 do
    begin
      var LModule := FDocument.Imports[LModuleIndex];
      var LModuleName := LModule.Name;
      if LModuleName = '' then
        LModuleName := 'Unnamed import module';
      LText.AppendLine(Format('%s [%d imported methods]', [LModuleName,
        LModule.Entries.Count]));
    end;
    LControl.SetText(LText.ToString);
  finally
    LText.Free;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkImportDirectory];
end;

procedure TFrame1.ShowImportModuleDetails(AImportModuleIndex: Integer);
begin
  if (FDocument = nil) or (AImportModuleIndex < 0) or
    (AImportModuleIndex >= FDocument.Imports.Count) then
    Exit;

  ShowImportModuleDetail(FDocument.Imports[AImportModuleIndex],
    tdkImportModule);
end;

procedure TFrame1.ShowImportModuleDetail(AImportModule: TDumpImportModule;
  ADetailKind: TTreeDetailKind);
begin
  if AImportModule = nil then
    Exit;

  var LModule := AImportModule;
  var LModuleName := LModule.Name;
  if LModuleName = '' then
    LModuleName := 'Unnamed import module';

  var LControl := EnsureHighlighterDetailControl(ADetailKind);
  FHighlighterCards[ADetailKind].Caption := LModuleName;
  if ADetailKind = tdkDelayedImportModule then
  begin
    LControl.ParserMode := tpmTDumpValues;
    LControl.BeginUpdate;
    try
      LControl.Clear;
      LControl.SetColumnHeaders(['Property', 'Value']);
      LControl.SetColumnDataTypes([thdtAuto, thdtHexadecimal]);
      for var LProperty in LModule.Properties do
        LControl.AddColumns([LProperty.Name, LProperty.RawValue]);
      for var LImport in LModule.Entries do
      begin
        var LImportText := Trim(LImport.RawText);
        if LImportText = '' then
          LImportText := LImport.Name;
        var LFlagStart := LastDelimiter('(', LImportText);
        var LMethodText := LImportText;
        var LFlagsText := '';
        if LFlagStart > 1 then
        begin
          LMethodText := Trim(Copy(LImportText, 1, LFlagStart - 1));
          LFlagsText := Trim(Copy(LImportText, LFlagStart, MaxInt));
        end;
        LControl.AddColumns([LMethodText, LFlagsText], tpmCppBuilderMethod);
      end;
      if LModule.Entries.Count = 0 then
        LControl.AddColumns(['Imports', 'No imported methods.']);
    finally
      LControl.EndUpdate;
    end;
    cpViews.ActiveCard := FHighlighterCards[ADetailKind];
    Exit;
  end;

  LControl.ParserMode := tpmCppBuilderMethod;
  var LText := TStringBuilder.Create;
  try
    for var LProperty in LModule.Properties do
      LText.AppendLine(Format('%-30s %s', [LProperty.Name,
        LProperty.RawValue]));
    if LModule.Properties.Count > 0 then
      LText.AppendLine;
    if LModule.Entries.Count = 0 then
      LText.AppendLine('No imported methods.')
    else
      for var LImport in LModule.Entries do
        if Trim(LImport.RawText) <> '' then
          LText.AppendLine(Trim(LImport.RawText))
        else
          LText.AppendLine(LImport.Name);
    LControl.SetText(LText.ToString);
  finally
    LText.Free;
  end;
  cpViews.ActiveCard := FHighlighterCards[ADetailKind];
end;

procedure TFrame1.ShowDelayedImportTableDetails;
begin
  if (FDocument = nil) or (FDocument.DelayedImportTable = nil) then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkDelayedImportTable);
  LControl.ParserMode := tpmCppBuilderMethod;
  var LText := TStringBuilder.Create;
  try
    LText.AppendLine('Delayed Load Import Table');
    LText.AppendLine(Format('%d module(s)',
      [FDocument.DelayedImportTable.Modules.Count]));
    LText.AppendLine;
    for var LModule in FDocument.DelayedImportTable.Modules do
    begin
      var LModuleName := LModule.Name;
      if LModuleName = '' then
        LModuleName := 'Unnamed delayed import module';
      LText.AppendLine(Format('%s [%d imported methods]', [LModuleName,
        LModule.Entries.Count]));
    end;
    LControl.SetText(LText.ToString);
  finally
    LText.Free;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkDelayedImportTable];
end;

procedure TFrame1.ShowDelayedImportModuleDetails(AImportModuleIndex: Integer);
begin
  if (FDocument = nil) or (FDocument.DelayedImportTable = nil) or
    (AImportModuleIndex < 0) or
    (AImportModuleIndex >= FDocument.DelayedImportTable.Modules.Count) then
    Exit;

  ShowImportModuleDetail(FDocument.DelayedImportTable.Modules[AImportModuleIndex],
    tdkDelayedImportModule);
end;

procedure TFrame1.ShowExportDirectoryDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkExportDirectory);
  LControl.ParserMode := tpmCppBuilderMethod;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['RVA', 'Ord.', 'Hint', 'Name']);
    LControl.SetColumnDataTypes([thdtHexadecimal, thdtInteger,
      thdtHexadecimal, thdtAuto]);
    for var LExport in FDocument.ExportList do
    begin
      var LRVA := '';
      if LExport.HasRVA then
        LRVA := IntToHex(LExport.RVA, 8);
      var LOrdinal := '';
      if LExport.HasOrdinal then
        LOrdinal := LExport.Ordinal.ToString;
      var LHint := '';
      if LExport.HasHint then
        LHint := IntToHex(LExport.Hint, 4);
      var LName := LExport.DemangledName;
      if LName = '' then
        LName := LExport.Name;
      LControl.AddColumns([LRVA, LOrdinal, LHint, LName]);
    end;
  finally
    LControl.EndUpdate;
  end;
  cpViews.ActiveCard := FHighlighterCards[tdkExportDirectory];
end;

procedure TFrame1.ShowResourceDirectoryDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkResourceDirectory);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Type', 'Name', 'Lang', 'Id']);
    LControl.SetColumnDataTypes([thdtText, thdtText, thdtText, thdtInteger]);
    for var LResource in FDocument.Resources do
    begin
      var LType := LResource.ResourceType;
      var LName := LResource.Name;
      if SameText(LType, LName) then
        LName := '';
      var LLanguage := LResource.Language;
      var LId := '';
      if LResource.HasId then
        LId := LResource.Id.ToString;
      LControl.AddColumns([LType, LName, LLanguage, LId]);
    end;
  finally
    LControl.EndUpdate;
  end;

  var LCaption := 'Resources';
  if (FDocument.ResourceMetadata <> nil) and
    FDocument.ResourceMetadata.HasRootDirectoryCounts then
    LCaption := Format('Resources [%d named entries, %d ID entries]',
      [FDocument.ResourceMetadata.RootNamedEntryCount,
       FDocument.ResourceMetadata.RootIdEntryCount]);
  FHighlighterCards[tdkResourceDirectory].Caption := LCaption;
  cpViews.ActiveCard := FHighlighterCards[tdkResourceDirectory];
end;

procedure TFrame1.ShowResourceDetails(AResource: TDumpResource);
begin
  if AResource = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkResource);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Name', 'Value']);
    if AResource.ResourceType <> '' then
      LControl.AddColumns(['Type', AResource.ResourceType]);
    if (AResource.Name <> '') and not SameText(AResource.Name,
      AResource.ResourceType) then
      LControl.AddColumns(['Name', AResource.Name]);
    if AResource.HasId then
      LControl.AddColumns(['Id', AResource.Id.ToString]);
    if AResource.Language <> '' then
      LControl.AddColumns(['Language', AResource.Language]);
    if AResource.HasDirectoryCounts then
    begin
      LControl.AddColumns(['Named entries', AResource.NamedEntryCount.ToString]);
      LControl.AddColumns(['ID entries', AResource.IdEntryCount.ToString]);
    end;
    if AResource.HasDirectoryOffset then
      LControl.AddColumns(['Directory offset',
        IntToHex(AResource.DirectoryOffset, 8)]);
    if AResource.HasDataOffset then
      LControl.AddColumns(['Offset', IntToHex(AResource.DataOffset, 8)])
    else if AResource.HasRVA then
      LControl.AddColumns(['RVA', IntToHex(AResource.RVA, 8)]);
    if AResource.HasFileOffset then
      LControl.AddColumns(['File offset', IntToHex(AResource.FileOffset, 8)]);
    if AResource.HasSize then
      LControl.AddColumns(['Size', IntToHex(AResource.Size, 8)]);
    if AResource.HasCodePage then
      LControl.AddColumns(['Code page', IntToHex(AResource.CodePage, 8)]);
    if AResource.HasReserved then
      LControl.AddColumns(['Reserved', IntToHex(AResource.Reserved, 8)]);
    for var LProperty in AResource.Properties do
      if not SameText(LProperty.Name, 'Type') and
        not SameText(LProperty.Name, 'Offset') and
        not SameText(LProperty.Name, 'Size') and
        not SameText(LProperty.Name, 'Code Page') and
        not SameText(LProperty.Name, 'Reserved') then
        LControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    LControl.EndUpdate;
  end;

  FHighlighterCards[tdkResource].Caption := ResourceCaption(AResource);
  cpViews.ActiveCard := FHighlighterCards[tdkResource];
end;

procedure TFrame1.ShowBorlandSubsectionDetails(ASubsectionIndex: Integer);
begin
  if (FDocument = nil) or (ASubsectionIndex < 0) or
    (ASubsectionIndex >= FDocument.BorlandSubsections.Count) then
    Exit;

  var LSubsection := FDocument.BorlandSubsections[ASubsectionIndex];
  var LControl := EnsureHighlighterDetailControl(tdkBorlandSubsection);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    if SameText(LSubsection.SubsectionType, 'sstNames') then
    begin
      LControl.SetColumnHeaders(['Index', 'Name']);
      LControl.SetColumnDataTypes([thdtHexadecimal, thdtAuto]);
      for var LBorlandName in FDocument.BorlandNames do
        if IsBorlandMethodName(LBorlandName.Value) then
          LControl.AddColumns([LBorlandName.RawIndex, LBorlandName.Value],
            tpmCppBuilderMethod)
        else
          LControl.AddColumns([LBorlandName.RawIndex, LBorlandName.Value]);
    end
    else
    begin
      LControl.SetColumnHeaders(['Name', 'Value']);
      LControl.AddColumns(['Subsection', LSubsection.SubsectionType]);
      LControl.AddColumns(['Module', IntToHex(LSubsection.ModIndex, 4)]);
      LControl.AddColumns(['File offset', IntToHex(LSubsection.FileOffset, 8)]);

    if SameText(LSubsection.SubsectionType, 'sstModule') then
    begin
      for var LModule in FDocument.SymbolModules do
        if (LModule.ModIndex = LSubsection.ModIndex) and
          (LModule.FileOffset = LSubsection.FileOffset) then
        begin
          var LName := LModule.ResolvedName;
          if LName = '' then
            LName := LModule.Name;
          if LName <> '' then
            LControl.AddColumns(['Name', LName]);
          LControl.AddColumns(['Overlay', IntToHex(LModule.OvlNum, 4)]);
          LControl.AddColumns(['Library index', IntToHex(LModule.LibIndex, 4)]);
          LControl.AddColumns(['Segments', LModule.Segments.Count.ToString]);
          LControl.AddColumns(['Time', IntToHex(LModule.Time, 4)]);
          Break;
        end;
    end
    else if SameText(LSubsection.SubsectionType, 'sstSrcModule') then
    begin
      for var LSourceModule in FDocument.SourceModules do
        if (LSourceModule.ModIndex = LSubsection.ModIndex) and
          (LSourceModule.FileOffset = LSubsection.FileOffset) then
        begin
          LControl.AddColumns(['Segment ranges',
            LSourceModule.SegmentRanges.Count.ToString]);
          for var LRange in LSourceModule.SegmentRanges do
            LControl.AddColumns(['Segment range', Format('%s:%s-%s',
              [LRange.RawSegment, LRange.RawStartOffset, LRange.RawEndOffset])]);
          LControl.AddColumns(['Source files',
            LSourceModule.SourceFiles.Count.ToString]);
          Break;
        end;
    end
    else if SameText(LSubsection.SubsectionType, 'sstAlignSym') then
    begin
      for var LAlignSection in FDocument.AlignSymbolSections do
        if (LAlignSection.ModIndex = LSubsection.ModIndex) and
          (LAlignSection.FileOffset = LSubsection.FileOffset) then
        begin
          LControl.AddColumns(['Records', LAlignSection.Records.Count.ToString]);
          LControl.AddColumns(['Symbols', LAlignSection.Symbols.Count.ToString]);
          LControl.AddColumns(['Search records', LAlignSection.Searches.Count.ToString]);
          Break;
        end;
    end
    else if SameText(LSubsection.SubsectionType, 'sstGlobalSym') then
    begin
      for var LSymbolSection in FDocument.GlobalSymbolSections do
        if (LSymbolSection.ModIndex = LSubsection.ModIndex) and
          (LSymbolSection.FileOffset = LSubsection.FileOffset) then
        begin
          LControl.AddColumns(['Records', LSymbolSection.Records.Count.ToString]);
          Break;
        end;
    end
    else if SameText(LSubsection.SubsectionType, 'sstGlobalTypes') then
    begin
      for var LTypeSection in FDocument.GlobalTypeSections do
        if (LTypeSection.ModIndex = LSubsection.ModIndex) and
          (LTypeSection.FileOffset = LSubsection.FileOffset) then
        begin
          LControl.AddColumns(['Declared types', LTypeSection.TypeCount.ToString]);
          LControl.AddColumns(['Parsed records', LTypeSection.Records.Count.ToString]);
          Break;
        end;
    end;
      if not SameText(LSubsection.SubsectionType, 'sstSrcModule') and
        (LSubsection.Node <> nil) then
        for var LProperty in LSubsection.Node.Properties do
          LControl.AddColumns([LProperty.Name, LProperty.RawValue]);
    end;
  finally
    LControl.EndUpdate;
  end;

  FHighlighterCards[tdkBorlandSubsection].Caption := Format('%s (module %d)',
    [LSubsection.SubsectionType, LSubsection.ModIndex]);
  cpViews.ActiveCard := FHighlighterCards[tdkBorlandSubsection];
end;

procedure TFrame1.ShowBorlandSymbolRecordDetails(ADetailKind: TTreeDetailKind;
  ARecord: TDumpBorlandSymbolRecord);
begin
  if ARecord = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(ADetailKind);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Name', 'Value']);
    LControl.AddColumns(['Record kind', ARecord.RecordKind]);
    LControl.AddColumns(['Record offset', ARecord.RawRecordOffset]);
    if ARecord.ResolvedName <> '' then
      LControl.AddColumns(['Name', ARecord.ResolvedName], tpmCppBuilderMethod)
    else if ARecord.Name <> '' then
      LControl.AddColumns(['Name', ARecord.Name], tpmCppBuilderMethod);
    if ARecord.HasNameIndex then
      LControl.AddColumns(['Name index', ARecord.RawNameIndex]);
    if ARecord.HasTypeIndex then
      LControl.AddColumns(['Type index', ARecord.RawTypeIndex]);
    if ARecord.RawSegment <> '' then
      LControl.AddColumns(['Segment', ARecord.RawSegment]);
    if ARecord.HasAddress then
      LControl.AddColumns(['Address', ARecord.RawAddress]);
    if ARecord.HasEndAddress then
      LControl.AddColumns(['End address', ARecord.RawEndAddress]);
    if ARecord.HasScopeOffsets then
    begin
      LControl.AddColumns(['Parent offset', IntToHex(ARecord.ParentOffset, 5)]);
      LControl.AddColumns(['End offset', IntToHex(ARecord.EndOffset, 5)]);
      LControl.AddColumns(['Next offset', IntToHex(ARecord.NextOffset, 5)]);
    end;
    if ARecord.Value <> '' then
      LControl.AddColumns(['Value', ARecord.Value]);
    for var LProperty in ARecord.Properties do
      LControl.AddColumns([LProperty.Name, LProperty.RawValue]);
  finally
    LControl.EndUpdate;
  end;

  FHighlighterCards[ADetailKind].Caption := BorlandSymbolCaption(ARecord);
  cpViews.ActiveCard := FHighlighterCards[ADetailKind];
end;

procedure TFrame1.ShowBorlandGlobalTypeRecordDetails(
  ARecord: TDumpGlobalTypeRecord);
begin
  if ARecord = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkBorlandGlobalTypeRecord);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Name', 'Value']);
    LControl.AddColumns(['Type index', ARecord.RawTypeIndex]);
    LControl.AddColumns(['Record offset', ARecord.RawRecordOffset]);
    LControl.AddColumns(['Kind', ARecord.TypeKind]);
    LControl.AddColumns(['Length', ARecord.RawLength]);
    if ARecord.ResolvedName <> '' then
      LControl.AddColumns(['Name', ARecord.ResolvedName])
    else if ARecord.Name <> '' then
      LControl.AddColumns(['Name', ARecord.Name]);
    if ARecord.HasNameIndex then
      LControl.AddColumns(['Name index', ARecord.RawNameIndex]);
    for var LProperty in ARecord.Properties do
      LControl.AddColumns([LProperty.Name, LProperty.RawValue]);
    for var LDetail in ARecord.Details do
    begin
      if LDetail.TypeText <> '' then
        LControl.AddColumns(['Type', LDetail.TypeText]);
      if LDetail.PointerFlavor <> '' then
        LControl.AddColumns(['Pointer', LDetail.PointerFlavor]);
      if LDetail.PointerType <> '' then
        LControl.AddColumns(['Pointer type', LDetail.PointerType]);
      if LDetail.PointerMode <> '' then
        LControl.AddColumns(['Pointer mode', LDetail.PointerMode]);
      if LDetail.CallingConvention <> '' then
        LControl.AddColumns(['Calling convention', LDetail.CallingConvention]);
      if LDetail.ReturnType <> '' then
        LControl.AddColumns(['Returns', LDetail.ReturnType]);
      for var LProperty in LDetail.Properties do
        LControl.AddColumns([LProperty.Name, LProperty.RawValue]);
    end;
    for var LMember in ARecord.Members do
    begin
      var LMemberName := LMember.ResolvedName;
      if LMemberName = '' then
        LMemberName := LMember.Name;
      if LMemberName = '' then
        LMemberName := 'Member';
      var LMemberValue := '';
      if LMember.RawTypeIndex <> '' then
        LMemberValue := 'Type ' + LMember.RawTypeIndex;
      if LMember.RawOffset <> '' then
      begin
        if LMemberValue <> '' then
          LMemberValue := LMemberValue + '  ';
        LMemberValue := LMemberValue + 'Offset ' + LMember.RawOffset;
      end;
      if LMember.RawValue <> '' then
      begin
        if LMemberValue <> '' then
          LMemberValue := LMemberValue + '  ';
        LMemberValue := LMemberValue + 'Value ' + LMember.RawValue;
      end;
      LControl.AddColumns(['Member ' + LMemberName, LMemberValue]);
    end;
  finally
    LControl.EndUpdate;
  end;

  FHighlighterCards[tdkBorlandGlobalTypeRecord].Caption :=
    BorlandTypeCaption(ARecord);
  cpViews.ActiveCard := FHighlighterCards[tdkBorlandGlobalTypeRecord];
end;

procedure TFrame1.ShowBorlandSourceFileDetails(ASourceFile: TDumpSourceFile);
begin
  if ASourceFile = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkBorlandSourceFile);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Range', 'Line', 'Offset']);
    LControl.SetColumnDataTypes([thdtText, thdtInteger, thdtHexadecimal]);
    for var LRange in ASourceFile.Ranges do
    begin
      var LRangeText := Format('%s:%s-%s', [LRange.RawSegment,
        LRange.RawStartOffset, LRange.RawEndOffset]);
      if LRange.LineNumbers.Count = 0 then
        LControl.AddColumns([LRangeText, '', ''])
      else
        for var LLine in LRange.LineNumbers do
        begin
          var LLineNumber := LLine.RawLineNumber;
          if LLineNumber = '' then
            LLineNumber := LLine.LineNumber.ToString;
          var LOffset := LLine.RawOffset;
          if LOffset = '' then
            LOffset := IntToHex(LLine.Offset, 5);
          LControl.AddColumns([LRangeText, LLineNumber, LOffset]);
          LRangeText := '';
        end;
    end;
  finally
    LControl.EndUpdate;
  end;

  var LName := ASourceFile.ResolvedName;
  if LName = '' then
    LName := ASourceFile.Name;
  if LName = '' then
    LName := 'Source file';
  if ASourceFile.HasNameIndex and (ASourceFile.RawNameIndex <> '') then
    LName := Format('%s [%s]', [LName, ASourceFile.RawNameIndex]);
  if ASourceFile.RawOffset <> '' then
    LName := LName + '  Offset ' + ASourceFile.RawOffset
  else
    LName := LName + '  Offset ' + IntToHex(ASourceFile.Offset, 5);
  FHighlighterCards[tdkBorlandSourceFile].Caption := LName;
  cpViews.ActiveCard := FHighlighterCards[tdkBorlandSourceFile];
end;

procedure TFrame1.ShowDiagnosticsDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkDiagnostics);
  LControl.ParserMode := tpmTDumpValues;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Severity', 'Line', 'Message']);
    LControl.SetColumnDataTypes([thdtText, thdtInteger, thdtText]);
    for var LDiagnostic in FDocument.Diagnostics do
    begin
      var LSeverity := '';
      case LDiagnostic.Severity of
        dsInfo:
          LSeverity := 'Info';
        dsWarning:
          LSeverity := 'Warning';
        dsError:
          LSeverity := 'Error';
      end;
      var LMessage := LDiagnostic.Message;
      if LMessage = '' then
        LMessage := LDiagnostic.RawLine;
      LControl.AddColumns([LSeverity, LDiagnostic.LineNumber.ToString, LMessage]);
    end;
  finally
    LControl.EndUpdate;
  end;
  FHighlighterCards[tdkDiagnostics].Caption := Format('Diagnostics [%d]',
    [FDocument.Diagnostics.Count]);
  cpViews.ActiveCard := FHighlighterCards[tdkDiagnostics];
end;

procedure TFrame1.PopulateTree(ADocument: TDumpDocument);
begin
  if FDocument <> ADocument then
  begin
    frCrossReferences.Clear;
    FDocument.Free;
    FDocument := ADocument;
  end;
  if FDocument = nil then
    Exit;

  cpViews.ActiveCard := FSummaryCard;
  frRawView.Populate(FDocument);
  frCrossReferences.Populate(FDocument);
  Tree.BeginUpdate;
  try
    FActiveDetailNode := nil;
    Tree.Clear;
    var LRootNode := AddTreeNode(nil, FileKindCaption(FDocument.FileKind),
      tdkDocumentSummary);

    for var LHeaderIndex := 0 to FDocument.Headers.Count - 1 do
    begin
      var LHeader := FDocument.Headers[LHeaderIndex];
      if LHeader.Properties.Count > 0 then
        AddTreeNode(LRootNode, LHeader.Name, HeaderDetailKind(LHeader),
          LHeaderIndex);
    end;

    if FDocument.DataDirectories.Count > 0 then
      AddTreeNode(LRootNode, Format('Data Directories [%d]',
        [FDocument.DataDirectories.Count]), tdkDataDirectories);
    if FDocument.Sections.Count > 0 then
      if FDocument.FileKind = dfELFObject then
        AddTreeNode(LRootNode, Format('Section Headers [%d]',
          [FDocument.Sections.Count]), tdkELFSectionHeaders)
      else
        AddTreeNode(LRootNode, Format('Object Table [%d]',
          [FDocument.Sections.Count]), tdkObjectTable);
    if (FDocument.Imports.Count > 0) or
      (FDocument.DelayedImportTable <> nil) then
    begin
      var LImportsNode := AddTreeNode(LRootNode,
        Format('Import Directory [%d modules]', [FDocument.Imports.Count]),
        tdkImportDirectory);
      for var LModuleIndex := 0 to FDocument.Imports.Count - 1 do
      begin
        var LModule := FDocument.Imports[LModuleIndex];
        var LModuleCaption := LModule.Name;
        if LModuleCaption = '' then
          LModuleCaption := 'Unnamed import module';
        AddTreeNode(LImportsNode, LModuleCaption, tdkImportModule, -1,
          LModuleIndex);
      end;
      if FDocument.DelayedImportTable <> nil then
      begin
        var LDelayedImportsNode := AddTreeNode(LImportsNode,
          Format('Delayed Load Import Table [%d modules]',
            [FDocument.DelayedImportTable.Modules.Count]),
          tdkDelayedImportTable);
        for var LModuleIndex := 0 to
          FDocument.DelayedImportTable.Modules.Count - 1 do
        begin
          var LModule := FDocument.DelayedImportTable.Modules[LModuleIndex];
          var LModuleCaption := LModule.Name;
          if LModuleCaption = '' then
            LModuleCaption := 'Unnamed delayed import module';
          AddTreeNode(LDelayedImportsNode, LModuleCaption,
            tdkDelayedImportModule, -1, LModuleIndex);
        end;
      end;
    end;

    if FDocument.ExportList.Count > 0 then
      AddTreeNode(LRootNode, Format('Export Directory [%d symbols]',
        [FDocument.ExportList.Count]), tdkExportDirectory);
    if FDocument.Resources.Count > 0 then
    begin
      var LResourcesNode := AddTreeNode(LRootNode,
        Format('Resource Directory [%d entries]', [FDocument.Resources.Count]),
        tdkResourceDirectory);
      AddResourceNodes(LResourcesNode, FDocument.Resources);
    end;
    if FDocument.RelocationBlocks.Count > 0 then
    begin
      var LRelocationsNode := AddTreeNode(LRootNode, Format('Relocations [%d blocks]',
        [FDocument.RelocationBlocks.Count]), tdkRelocations);
      for var LBlock in FDocument.RelocationBlocks do
        AddTreeNode(LRelocationsNode, Format(
          'Block #%d: Page RVA = %s, block size = %s', [LBlock.Index,
          IntToHex(LBlock.PageRVA, 8), IntToHex(LBlock.BlockSize, 8)]),
          tdkRelocationBlock, -1, -1, nil, -1, nil, nil, nil, nil, nil,
          nil, nil, nil, LBlock);
    end
    else if FDocument.Relocations.Count > 0 then
      AddTreeNode(LRootNode, Format('Relocations [%d]',
        [FDocument.Relocations.Count]), tdkRelocations);
    if FDocument.Strings.Count > 0 then
      AddTreeNode(LRootNode, Format('Strings [%d]', [FDocument.Strings.Count]),
        tdkStrings);

    if (FDocument.FileKind = dfELFObject) and (FDocument.Symbols.Count > 0) then
      AddTreeNode(LRootNode, Format('Symbol Table [%d symbols]',
        [FDocument.Symbols.Count]), tdkELFSymbolTable);
    if FDocument.ELFProgramHeaders.Count > 0 then
      AddTreeNode(LRootNode, Format('Program Headers [%d]',
        [FDocument.ELFProgramHeaders.Count]), tdkELFProgramHeaders);
    if FDocument.ELFDynamicEntries.Count > 0 then
      AddTreeNode(LRootNode, Format('Dynamic Section [%d entries]',
        [FDocument.ELFDynamicEntries.Count]), tdkELFDynamicSection);
    if FDocument.ELFRelocations.Count > 0 then
    begin
      var LRelocationsNode := AddTreeNode(LRootNode, Format(
        'Relocations [%d entries]', [FDocument.ELFRelocations.Count]),
        tdkELFRelocations);
      var LSections := TList<string>.Create;
      try
        for var LRelocation in FDocument.ELFRelocations do
          if LSections.IndexOf(LRelocation.SectionName) < 0 then
            LSections.Add(LRelocation.SectionName);
        for var LSectionName in LSections do
        begin
          var LEntryCount := 0;
          for var LRelocation in FDocument.ELFRelocations do
            if SameText(LRelocation.SectionName, LSectionName) then
              Inc(LEntryCount);
          var LSectionNode := AddTreeNode(LRelocationsNode, Format('%s [%d entries]',
            [LSectionName, LEntryCount]), tdkELFRelocations);
          PTreeItemData(Tree.GetNodeData(LSectionNode))^.ELFRelocationSectionName :=
            LSectionName;
        end;
      finally
        LSections.Free;
      end;
    end;

    if FDocument.ObjectRecords.Count > 0 then
    begin
      var LRecordsNode := AddTreeNode(LRootNode,
        Format('OMF Records [%d]', [FDocument.ObjectRecords.Count]),
        tdkOMFRecords);
      for var LRecord in FDocument.ObjectRecords do
      begin
        var LRecordCaption := LRecord.RawOffset + ' ' + LRecord.RecordKind;
        if LRecord.Name <> '' then
          LRecordCaption := LRecordCaption + '  ' + LRecord.Name;
        AddTreeNode(LRecordsNode, LRecordCaption, tdkOMFRecord, -1, -1, nil,
          -1, nil, nil, nil, nil, nil, nil, nil, LRecord);
      end;
    end;
    if FDocument.LibraryMembers.Count > 0 then
      AddTreeNode(LRootNode, Format('Library Members [%d]',
        [FDocument.LibraryMembers.Count]), tdkOMFLibraryMembers);
    if FDocument.OMFLibraryIndex <> nil then
      AddTreeNode(LRootNode, 'Library Index', tdkOMFLibraryIndex);

    if FDocument.ArchiveMembers.Count > 0 then
      AddTreeNode(LRootNode, Format('Archive Members [%d]',
        [FDocument.ArchiveMembers.Count]), tdkArchiveMembers);
    if FDocument.ArchiveSymbols.Count > 0 then
      AddTreeNode(LRootNode, Format('Archive Symbols [%d]',
        [FDocument.ArchiveSymbols.Count]), tdkArchiveSymbols);

    if FDocument.MachArchitectures.Count > 0 then
    begin
      var LArchitecturesNode := AddTreeNode(LRootNode,
        Format('FAT Architectures [%d]', [FDocument.MachArchitectures.Count]),
        tdkMachArchitectures);
      for var LArchitecture in FDocument.MachArchitectures do
      begin
        var LArchitectureCaption := LArchitecture.CPUType;
        if LArchitecture.CPUSubtype <> '' then
          LArchitectureCaption := LArchitectureCaption + ' (' +
            LArchitecture.CPUSubtype + ')';
        AddTreeNode(LArchitecturesNode, LArchitectureCaption,
          tdkMachArchitecture, -1, -1, nil, -1, nil, nil, nil, nil,
          LArchitecture);
      end;
    end;

    if FDocument.MachLoadCommands.Count > 0 then
    begin
      var LLoadCommandsNode := AddTreeNode(LRootNode,
        Format('Load Commands [%d]', [FDocument.MachLoadCommands.Count]),
        tdkMachLoadCommands);
      for var LCommand in FDocument.MachLoadCommands do
      begin
        var LCommandNode := AddTreeNode(LLoadCommandsNode,
          Format('#%d %s', [LCommand.Index, LCommand.Name]),
          tdkMachLoadCommand, -1, -1, nil, -1, nil, nil, nil, nil, nil,
          LCommand);
        for var LSection in LCommand.Sections do
        begin
          var LSectionCaption := LSection.Name;
          if LSection.SegmentName <> '' then
            LSectionCaption := LSectionCaption + ' (' + LSection.SegmentName + ')';
          AddTreeNode(LCommandNode, LSectionCaption, tdkMachSection, -1, -1,
            nil, -1, nil, nil, nil, nil, nil, nil, LSection);
        end;
      end;
    end;

    if FDocument.MachSymbols.Count > 0 then
      AddTreeNode(LRootNode, Format('Symbol Table [%d symbols]',
        [FDocument.MachSymbols.Count]), tdkMachSymbolTable);
    if FDocument.MachDynamicSymbolTableCommand <> nil then
    begin
      var LDynamicSymbolsNode := AddTreeNode(LRootNode, 'Dynamic Symbol Table');
      AddTreeNode(LDynamicSymbolsNode, 'Metadata',
        tdkMachDynamicSymbolMetadata);
      if FDocument.MachDynamicImports.Count > 0 then
        AddTreeNode(LDynamicSymbolsNode, Format('Dynamic Imports [%d symbols]',
          [FDocument.MachDynamicImports.Count]), tdkMachDynamicImports);
      if FDocument.MachIndirectSymbols.Count > 0 then
        AddTreeNode(LDynamicSymbolsNode, Format('Indirect Symbols [%d symbols]',
          [FDocument.MachIndirectSymbols.Count]), tdkMachIndirectSymbols);
    end
    else
    begin
      if FDocument.MachDynamicImports.Count > 0 then
        AddTreeNode(LRootNode, Format('Dynamic Imports [%d symbols]',
          [FDocument.MachDynamicImports.Count]), tdkMachDynamicImports);
      if FDocument.MachIndirectSymbols.Count > 0 then
        AddTreeNode(LRootNode, Format('Indirect Symbols [%d symbols]',
          [FDocument.MachIndirectSymbols.Count]), tdkMachIndirectSymbols);
    end;

    if HasBorlandSymbolTable then
    begin
      var LBorlandNode := AddTreeNode(LRootNode,
        Format('Borland 32-bit Symbol Table [%d subsections]',
          [FDocument.BorlandSubsections.Count]));
      for var LSubsectionIndex := 0 to FDocument.BorlandSubsections.Count - 1 do
      begin
        var LSubsection := FDocument.BorlandSubsections[LSubsectionIndex];
        var LSubsectionCaption := LSubsection.SubsectionType;
        if LSubsectionCaption = '' then
          LSubsectionCaption := 'Subsection';
        var LSubsectionNode := AddTreeNode(LBorlandNode, Format('%s (module %d)',
          [LSubsectionCaption, LSubsection.ModIndex]), tdkBorlandSubsection,
          -1, -1, nil, LSubsectionIndex);
        if SameText(LSubsection.SubsectionType, 'sstSrcModule') then
          for var LSourceModule in FDocument.SourceModules do
            if (LSourceModule.ModIndex = LSubsection.ModIndex) and
              (LSourceModule.FileOffset = LSubsection.FileOffset) then
              for var LSourceFile in LSourceModule.SourceFiles do
              begin
                var LSourceFileCaption := LSourceFile.ResolvedName;
                if LSourceFileCaption = '' then
                  LSourceFileCaption := LSourceFile.Name;
                if LSourceFileCaption = '' then
                  LSourceFileCaption := 'Source file';
                AddTreeNode(LSubsectionNode, LSourceFileCaption,
                  tdkBorlandSourceFile, -1, -1, nil, -1, LSourceFile);
              end;
        if SameText(LSubsection.SubsectionType, 'sstAlignSym') then
          for var LAlignSection in FDocument.AlignSymbolSections do
            if (LAlignSection.ModIndex = LSubsection.ModIndex) and
              (LAlignSection.FileOffset = LSubsection.FileOffset) then
              for var LAlignRecord in LAlignSection.Records do
                if LAlignRecord.ScopeParent = nil then
                  AddAlignSymbolRecordNode(LSubsectionNode, LAlignRecord);
        if SameText(LSubsection.SubsectionType, 'sstGlobalSym') then
          for var LGlobalSymbolSection in FDocument.GlobalSymbolSections do
            if (LGlobalSymbolSection.ModIndex = LSubsection.ModIndex) and
              (LGlobalSymbolSection.FileOffset = LSubsection.FileOffset) then
              for var LGlobalSymbolRecord in LGlobalSymbolSection.Records do
                AddTreeNode(LSubsectionNode,
                  BorlandSymbolCaption(LGlobalSymbolRecord),
                  tdkBorlandGlobalSymbolRecord, -1, -1, nil, -1, nil, nil,
                  LGlobalSymbolRecord);
        if SameText(LSubsection.SubsectionType, 'sstGlobalTypes') then
          for var LGlobalTypeSection in FDocument.GlobalTypeSections do
            if (LGlobalTypeSection.ModIndex = LSubsection.ModIndex) and
              (LGlobalTypeSection.FileOffset = LSubsection.FileOffset) then
              for var LGlobalTypeRecord in LGlobalTypeSection.Records do
                AddTreeNode(LSubsectionNode, BorlandTypeCaption(LGlobalTypeRecord),
                  tdkBorlandGlobalTypeRecord, -1, -1, nil, -1, nil, nil, nil,
                  LGlobalTypeRecord);
      end;
    end;
    if FDocument.Diagnostics.Count > 0 then
      AddTreeNode(LRootNode, Format('Diagnostics [%d]',
        [FDocument.Diagnostics.Count]), tdkDiagnostics);

    Tree.Expanded[LRootNode] := True;
  finally
    Tree.EndUpdate;
  end;
end;

procedure TFrame1.SetProgress(ACompletedLines, ATotalLines: Integer);
begin
  if ATotalLines <= 0 then
    Exit;

  ProgressBar1.Max := ATotalLines;
  var LPosition := ACompletedLines;
  if LPosition < ProgressBar1.Min then
    LPosition := ProgressBar1.Min
  else if LPosition > ProgressBar1.Max then
    LPosition := ProgressBar1.Max;
  ProgressBar1.Position := LPosition;
  ProgressBar1.Update;
end;

procedure TFrame1.SetStatus(const AStatus: string);
begin
  FSummaryControl.SetText(AStatus);
  ProgressBar1.Min := 0;
  ProgressBar1.Max := 100;
  ProgressBar1.Position := 0;
  ProgressBar1.Update;
end;

procedure TFrame1.ShowSummary(const ASummary: string);
begin
  FSummaryControl.SetText(ASummary);
  ProgressBar1.Position := ProgressBar1.Max;
  ProgressBar1.Update;
end;

procedure TFrame1.UpdateActiveView;
begin
  var LPropertiesView := tcViews.TabIndex = 0;
  var LCrossReferencesView := tcViews.TabIndex = 1;

  Tree.Visible := LPropertiesView;
  Splitter1.Visible := LPropertiesView;
  pnProperties.Visible := LPropertiesView;
  frCrossReferences.Visible := LCrossReferencesView;

  case tcViews.TabIndex of
    0: pnProperties.BringToFront;
    1: frCrossReferences.BringToFront;
  end;
end;

function TFrame1.DetailControlForNode(
  ANode: PVirtualNode): THighlighterControl;
begin
  Result := nil;
  if ANode = nil then
    Exit;

  var LNodeData := PTreeItemData(Tree.GetNodeData(ANode));
  if LNodeData = nil then
    Exit;
  if LNodeData.DetailKind = tdkDocumentSummary then
    Result := FSummaryControl
  else if LNodeData.DetailKind <> tdkNone then
    Result := FHighlighterControls[LNodeData.DetailKind];
end;

procedure TFrame1.SaveActiveDetailItemIndex;
begin
  if FActiveDetailNode = nil then
    Exit;

  var LControl := DetailControlForNode(FActiveDetailNode);
  if LControl <> nil then
    PTreeItemData(Tree.GetNodeData(FActiveDetailNode))^.DetailItemIndex :=
      LControl.ControlList1.ItemIndex;
end;

procedure TFrame1.RestoreDetailItemIndex(ANode: PVirtualNode);
begin
  var LControl := DetailControlForNode(ANode);
  if LControl = nil then
    Exit;

  var LItemIndex := PTreeItemData(Tree.GetNodeData(ANode))^.DetailItemIndex;
  if LItemIndex < 0 then
    LItemIndex := 0;
  LControl.SelectItem(LItemIndex);
end;

procedure TFrame1.ResolveNodeSourceSpan(const AData: PTreeItemData;
  out AStartLine, AEndLine: Integer);
  procedure UseSpan(AStart, AEnd: Integer);
  begin
    if AStart < 1 then
      Exit;
    AStartLine := AStart;
    AEndLine := AEnd;
    if AEndLine < AStartLine then
      AEndLine := AStartLine;
  end;

  procedure ExtendRange(var AFirstLine, ALastLine: Integer;
    AStartLine, AEndLine: Integer);
  begin
    if AStartLine < 1 then
      Exit;
    AFirstLine := Min(AFirstLine, AStartLine);
    ALastLine := Max(ALastLine, Max(AStartLine, AEndLine));
  end;

  procedure UseDocumentNodeKind(AKind: TDumpNodeKind);
    procedure CollectNodeRange(ANode: TDumpNode; var AFirstLine,
      ALastLine: Integer);
    begin
      if ANode.Kind = AKind then
        ExtendRange(AFirstLine, ALastLine, ANode.StartLine, ANode.EndLine);
      for var LChild in ANode.Children do
        CollectNodeRange(LChild, AFirstLine, ALastLine);
    end;
  begin
    if FDocument = nil then
      Exit;
    var LFirstLine := MaxInt;
    var LLastLine := 0;
    for var LNode in FDocument.Nodes do
      CollectNodeRange(LNode, LFirstLine, LLastLine);
    if LFirstLine <> MaxInt then
      UseSpan(LFirstLine, LLastLine);
  end;

begin
  AStartLine := 0;
  AEndLine := 0;
  if (AData = nil) or (FDocument = nil) then
    Exit;

  case AData.DetailKind of
    tdkDocumentSummary:
      UseSpan(1, FDocument.Lines.Count);
    tdkOldExecutableHeader, tdkPortableExecutableHeader, tdkELFHeader,
    tdkMachHeader:
      if (AData.HeaderIndex >= 0) and
         (AData.HeaderIndex < FDocument.Headers.Count) then
        UseSpan(FDocument.Headers[AData.HeaderIndex].StartLine,
          FDocument.Headers[AData.HeaderIndex].EndLine)
      else
        UseDocumentNodeKind(nkHeader);
    tdkDataDirectories:
      if FDocument.DataDirectories.Count > 0 then
      begin
        var LFirstLine := MaxInt;
        var LLastLine := 0;
        for var LDirectory in FDocument.DataDirectories do
          ExtendRange(LFirstLine, LLastLine, LDirectory.StartLine,
            LDirectory.StartLine);
        UseSpan(LFirstLine, LLastLine);
      end
      else
        UseDocumentNodeKind(nkDataDirectory);
    tdkObjectTable, tdkELFSectionHeaders:
      UseDocumentNodeKind(nkSections);
    tdkELFProgramHeaders:
      if FDocument.ELFProgramHeaders.Count > 0 then
      begin
        var LFirstLine := MaxInt;
        var LLastLine := 0;
        for var LHeader in FDocument.ELFProgramHeaders do
          ExtendRange(LFirstLine, LLastLine, LHeader.StartLine,
            LHeader.EndLine);
        UseSpan(LFirstLine, LLastLine);
      end
      else
        UseDocumentNodeKind(nkSections);
    tdkImportDirectory:
      if FDocument.ImportMetadata <> nil then
        UseSpan(FDocument.ImportMetadata.StartLine,
          FDocument.ImportMetadata.EndLine)
      else
        UseDocumentNodeKind(nkImports);
    tdkImportModule:
      if (AData.ImportModuleIndex >= 0) and
         (AData.ImportModuleIndex < FDocument.Imports.Count) then
        UseSpan(FDocument.Imports[AData.ImportModuleIndex].StartLine,
          FDocument.Imports[AData.ImportModuleIndex].EndLine)
      else
        UseDocumentNodeKind(nkImports);
    tdkDelayedImportTable:
      if FDocument.DelayedImportTable <> nil then
        UseSpan(FDocument.DelayedImportTable.StartLine,
          FDocument.DelayedImportTable.EndLine)
      else
        UseDocumentNodeKind(nkDelayedImports);
    tdkDelayedImportModule:
      if (FDocument.DelayedImportTable <> nil) and
        (AData.ImportModuleIndex >= 0) and
        (AData.ImportModuleIndex < FDocument.DelayedImportTable.Modules.Count) then
        UseSpan(FDocument.DelayedImportTable.Modules[AData.ImportModuleIndex].StartLine,
          FDocument.DelayedImportTable.Modules[AData.ImportModuleIndex].EndLine)
      else
        UseDocumentNodeKind(nkDelayedImports);
    tdkExportDirectory:
      if FDocument.ExportMetadata <> nil then
        UseSpan(FDocument.ExportMetadata.StartLine,
          FDocument.ExportMetadata.EndLine)
      else
        UseDocumentNodeKind(nkExports);
    tdkResourceDirectory:
      if FDocument.ResourceMetadata <> nil then
        UseSpan(FDocument.ResourceMetadata.StartLine,
          FDocument.ResourceMetadata.EndLine)
      else
        UseDocumentNodeKind(nkResources);
    tdkResource:
      if AData.Resource <> nil then
        UseSpan(AData.Resource.StartLine, AData.Resource.EndLine);
    tdkRelocations:
      if FDocument.RelocationBlocks.Count > 0 then
      begin
        var LFirstLine := MaxInt;
        var LLastLine := 0;
        for var LBlock in FDocument.RelocationBlocks do
          ExtendRange(LFirstLine, LLastLine, LBlock.StartLine, LBlock.EndLine);
        UseSpan(LFirstLine, LLastLine);
      end
      else
        UseDocumentNodeKind(nkRelocations);
    tdkELFRelocations:
      if FDocument.ELFRelocations.Count > 0 then
      begin
        var LFirstLine := MaxInt;
        var LLastLine := 0;
        for var LRelocation in FDocument.ELFRelocations do
          if (AData.ELFRelocationSectionName = '') or
            SameText(AData.ELFRelocationSectionName, LRelocation.SectionName) then
            ExtendRange(LFirstLine, LLastLine, LRelocation.StartLine,
              LRelocation.EndLine);
        UseSpan(LFirstLine, LLastLine);
      end
      else
        UseDocumentNodeKind(nkRelocations);
    tdkRelocationBlock:
      if AData.RelocationBlock <> nil then
        UseSpan(AData.RelocationBlock.StartLine, AData.RelocationBlock.EndLine);
    tdkStrings:
      if FDocument.Strings.Count > 0 then
      begin
        var LFirstLine := MaxInt;
        var LLastLine := 0;
        for var LString in FDocument.Strings do
          ExtendRange(LFirstLine, LLastLine, LString.StartLine,
            LString.StartLine);
        UseSpan(LFirstLine, LLastLine);
      end
      else
        UseDocumentNodeKind(nkStrings);
    tdkOMFRecords, tdkOMFRecord:
      if AData.ObjectRecord <> nil then
        UseSpan(AData.ObjectRecord.StartLine, AData.ObjectRecord.EndLine)
      else if FDocument.ObjectRecords.Count > 0 then
      begin
        var LFirstLine := MaxInt;
        var LLastLine := 0;
        for var LRecord in FDocument.ObjectRecords do
          ExtendRange(LFirstLine, LLastLine, LRecord.StartLine, LRecord.EndLine);
        UseSpan(LFirstLine, LLastLine);
      end
      else
        UseDocumentNodeKind(nkObjectRecord);
    tdkOMFLibraryMembers:
      if FDocument.LibraryMembers.Count > 0 then
      begin
        var LFirstLine := MaxInt;
        var LLastLine := 0;
        for var LMember in FDocument.LibraryMembers do
        begin
          LFirstLine := Min(LFirstLine, LMember.StartLine);
          LLastLine := Max(LLastLine, LMember.StartLine);
        end;
        UseSpan(LFirstLine, LLastLine);
      end
      else
        UseDocumentNodeKind(nkLibrary);
    tdkOMFLibraryIndex:
      if FDocument.OMFLibraryIndex <> nil then
        UseSpan(FDocument.OMFLibraryIndex.StartLine,
          FDocument.OMFLibraryIndex.EndLine)
      else
        UseDocumentNodeKind(nkLibrary);
    tdkArchiveMembers:
      if FDocument.ArchiveMembers.Count > 0 then
      begin
        var LFirstLine := MaxInt;
        var LLastLine := 0;
        for var LMember in FDocument.ArchiveMembers do
        begin
          LFirstLine := Min(LFirstLine, LMember.StartLine);
          LLastLine := Max(LLastLine, LMember.StartLine);
        end;
        UseSpan(LFirstLine, LLastLine);
      end
      else
        UseDocumentNodeKind(nkLibrary);
    tdkArchiveSymbols:
      if FDocument.ArchiveSymbols.Count > 0 then
      begin
        var LFirstLine := MaxInt;
        var LLastLine := 0;
        for var LSymbol in FDocument.ArchiveSymbols do
        begin
          LFirstLine := Min(LFirstLine, LSymbol.StartLine);
          LLastLine := Max(LLastLine, LSymbol.StartLine);
        end;
        UseSpan(LFirstLine, LLastLine);
      end
      else
        UseDocumentNodeKind(nkLibrary);
    tdkBorlandSubsection:
      if (AData.BorlandSubsectionIndex >= 0) and
         (AData.BorlandSubsectionIndex < FDocument.BorlandSubsections.Count) then
        UseSpan(FDocument.BorlandSubsections[AData.BorlandSubsectionIndex].StartLine,
          FDocument.BorlandSubsections[AData.BorlandSubsectionIndex].EndLine)
      else
        UseDocumentNodeKind(nkDebug);
    tdkBorlandSourceFile:
      if AData.SourceFile <> nil then
        UseSpan(AData.SourceFile.StartLine, AData.SourceFile.StartLine);
    tdkBorlandAlignSymbolRecord:
      if AData.AlignSymbolRecord <> nil then
        UseSpan(AData.AlignSymbolRecord.StartLine, AData.AlignSymbolRecord.EndLine);
    tdkBorlandGlobalSymbolRecord:
      if AData.GlobalSymbolRecord <> nil then
        UseSpan(AData.GlobalSymbolRecord.StartLine, AData.GlobalSymbolRecord.EndLine);
    tdkBorlandGlobalTypeRecord:
      if AData.GlobalTypeRecord <> nil then
        UseSpan(AData.GlobalTypeRecord.StartLine, AData.GlobalTypeRecord.EndLine);
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
      if FDocument.MachArchitectures.Count > 0 then
      begin
        var LFirstLine := MaxInt; var LLastLine := 0;
        for var LArchitecture in FDocument.MachArchitectures do
          ExtendRange(LFirstLine, LLastLine, LArchitecture.StartLine,
            LArchitecture.EndLine);
        UseSpan(LFirstLine, LLastLine);
      end;
    tdkMachLoadCommands:
      if FDocument.MachLoadCommands.Count > 0 then
      begin
        var LFirstLine := MaxInt; var LLastLine := 0;
        for var LCommand in FDocument.MachLoadCommands do
          ExtendRange(LFirstLine, LLastLine, LCommand.StartLine, LCommand.EndLine);
        UseSpan(LFirstLine, LLastLine);
      end;
    tdkMachSymbolTable:
      if FDocument.MachSymbols.Count > 0 then
      begin
        var LFirstLine := MaxInt; var LLastLine := 0;
        for var LSymbol in FDocument.MachSymbols do
          ExtendRange(LFirstLine, LLastLine, LSymbol.StartLine, LSymbol.EndLine);
        UseSpan(LFirstLine, LLastLine);
      end;
    tdkMachDynamicImports:
      if FDocument.MachDynamicImports.Count > 0 then
      begin
        var LFirstLine := MaxInt; var LLastLine := 0;
        for var LSymbol in FDocument.MachDynamicImports do
          ExtendRange(LFirstLine, LLastLine, LSymbol.StartLine, LSymbol.EndLine);
        UseSpan(LFirstLine, LLastLine);
      end;
    tdkMachIndirectSymbols:
      if FDocument.MachIndirectSymbols.Count > 0 then
      begin
        var LFirstLine := MaxInt; var LLastLine := 0;
        for var LSymbol in FDocument.MachIndirectSymbols do
          ExtendRange(LFirstLine, LLastLine, LSymbol.StartLine, LSymbol.EndLine);
        UseSpan(LFirstLine, LLastLine);
      end;
    tdkMachDynamicSymbolMetadata:
      if FDocument.MachDynamicSymbolTableCommand <> nil then
        UseSpan(FDocument.MachDynamicSymbolTableCommand.StartLine,
          FDocument.MachDynamicSymbolTableCommand.EndLine);
    tdkELFSymbolTable:
      if FDocument.Symbols.Count > 0 then
      begin
        var LFirstLine := MaxInt; var LLastLine := 0;
        for var LSymbol in FDocument.Symbols do
          ExtendRange(LFirstLine, LLastLine, LSymbol.StartLine, LSymbol.StartLine);
        UseSpan(LFirstLine, LLastLine);
      end;
    tdkELFDynamicSection:
      if FDocument.ELFDynamicEntries.Count > 0 then
      begin
        var LFirstLine := MaxInt; var LLastLine := 0;
        for var LEntry in FDocument.ELFDynamicEntries do
          ExtendRange(LFirstLine, LLastLine, LEntry.StartLine, LEntry.EndLine);
        UseSpan(LFirstLine, LLastLine);
      end;
    tdkDiagnostics:
      begin
        var LFirstLine := MaxInt; var LLastLine := 0;
        for var LDiagnostic in FDocument.Diagnostics do
          ExtendRange(LFirstLine, LLastLine, LDiagnostic.LineNumber,
            LDiagnostic.LineNumber);
        UseSpan(LFirstLine, LLastLine);
      end;
  end;
end;

procedure TFrame1.SyncRawViewToNode(ANode: PVirtualNode);
begin
  if ANode = nil then
  begin
    frRawView.ShowLines(1, 1);
    Exit;
  end;

  var LNodeData := PTreeItemData(Tree.GetNodeData(ANode));
  var LStartLine: Integer;
  var LEndLine: Integer;
  ResolveNodeSourceSpan(LNodeData, LStartLine, LEndLine);
  frRawView.ShowLines(LStartLine, LEndLine);
end;

procedure TFrame1.RawViewSyncWithSelectedNodeChanged(Sender: TObject);
begin
  if not frRawView.SyncWithSelectedNode then
    Exit;

  var LSelectedNode := FActiveDetailNode;
  if LSelectedNode = nil then
    LSelectedNode := Tree.FocusedNode;
  if LSelectedNode <> nil then
    SyncRawViewToNode(LSelectedNode);
end;

procedure TFrame1.ActivateNode(ANode: PVirtualNode);
begin
  SaveActiveDetailItemIndex;
  if ANode = nil then
  begin
    cpViews.ActiveCard := FSummaryCard;
    FActiveDetailNode := nil;
    SyncRawViewToNode(nil);
    Exit;
  end;

  var LNodeData := PTreeItemData(Tree.GetNodeData(ANode));
  case LNodeData.DetailKind of
    tdkDocumentSummary:
      cpViews.ActiveCard := FSummaryCard;
    tdkOldExecutableHeader, tdkPortableExecutableHeader, tdkMachHeader,
    tdkELFHeader:
      ShowHeaderDetails(LNodeData.DetailKind, LNodeData.HeaderIndex);
    tdkDataDirectories:
      ShowDataDirectoriesDetails;
    tdkObjectTable:
      ShowObjectTableDetails;
    tdkELFSectionHeaders:
      ShowELFSectionHeadersDetails;
    tdkELFProgramHeaders:
      ShowELFProgramHeadersDetails;
    tdkELFSymbolTable:
      ShowELFSymbolTableDetails;
    tdkELFDynamicSection:
      ShowELFDynamicSectionDetails;
    tdkELFRelocations:
      ShowELFRelocationsDetails(LNodeData.ELFRelocationSectionName);
    tdkRelocations:
      ShowRelocationsDetails;
    tdkRelocationBlock:
      ShowRelocationBlockDetails(LNodeData.RelocationBlock);
    tdkStrings:
      ShowStringsDetails;
    tdkOMFRecords:
      ShowOMFRecordsDetails;
    tdkOMFLibraryMembers:
      ShowOMFLibraryMembersDetails;
    tdkOMFLibraryIndex:
      ShowOMFLibraryIndexDetails;
    tdkOMFRecord:
      ShowOMFRecordDetails(LNodeData.ObjectRecord);
    tdkArchiveMembers:
      ShowArchiveMembersDetails;
    tdkArchiveSymbols:
      ShowArchiveSymbolsDetails;
    tdkImportDirectory:
      ShowImportDirectoryDetails;
    tdkImportModule:
      ShowImportModuleDetails(LNodeData.ImportModuleIndex);
    tdkDelayedImportTable:
      ShowDelayedImportTableDetails;
    tdkDelayedImportModule:
      ShowDelayedImportModuleDetails(LNodeData.ImportModuleIndex);
    tdkExportDirectory:
      ShowExportDirectoryDetails;
    tdkResourceDirectory:
      ShowResourceDirectoryDetails;
    tdkResource:
      ShowResourceDetails(LNodeData.Resource);
    tdkBorlandSubsection:
      ShowBorlandSubsectionDetails(LNodeData.BorlandSubsectionIndex);
    tdkBorlandSourceFile:
      ShowBorlandSourceFileDetails(LNodeData.SourceFile);
    tdkBorlandAlignSymbolRecord:
      ShowBorlandSymbolRecordDetails(tdkBorlandAlignSymbolRecord,
        LNodeData.AlignSymbolRecord);
    tdkBorlandGlobalSymbolRecord:
      ShowBorlandSymbolRecordDetails(tdkBorlandGlobalSymbolRecord,
        LNodeData.GlobalSymbolRecord);
    tdkBorlandGlobalTypeRecord:
      ShowBorlandGlobalTypeRecordDetails(LNodeData.GlobalTypeRecord);
    tdkMachArchitectures:
      ShowMachArchitecturesDetails;
    tdkMachArchitecture:
      ShowMachArchitectureDetails(LNodeData.MachArchitecture);
    tdkMachLoadCommands:
      ShowMachLoadCommandsDetails;
    tdkMachLoadCommand:
      ShowMachLoadCommandDetails(LNodeData.MachLoadCommand);
    tdkMachSection:
      ShowMachSectionDetails(LNodeData.MachSection);
    tdkMachSymbolTable:
      ShowMachSymbolTableDetails;
    tdkMachDynamicImports, tdkMachIndirectSymbols:
      ShowMachDynamicSymbolsDetails(LNodeData.DetailKind);
    tdkMachDynamicSymbolMetadata:
      ShowMachDynamicSymbolMetadataDetails;
    tdkDiagnostics:
      ShowDiagnosticsDetails;
  else
    cpViews.ActiveCard := FSummaryCard;
  end;
  RestoreDetailItemIndex(ANode);
  FActiveDetailNode := ANode;
  SyncRawViewToNode(ANode);
end;

procedure TFrame1.TreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if FActiveDetailNode = Node then
    FActiveDetailNode := nil;
  Finalize(PTreeItemData(Sender.GetNodeData(Node))^);
end;

procedure TFrame1.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  CellText := PTreeItemData(Sender.GetNodeData(Node))^.Caption;
end;

procedure TFrame1.TreeFocusChanged(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex);
begin
  ActivateNode(Node);
end;

procedure TFrame1.TreeMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  ActivateNode(Tree.GetNodeAt(X, Y));
end;

procedure TFrame1.tcViewsChange(Sender: TObject);
begin
  UpdateActiveView;
end;

end.
