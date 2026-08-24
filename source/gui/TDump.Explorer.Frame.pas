unit TDump.Explorer.Frame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.StrUtils, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  TDump.Explorer.HighlighterControl, TDump.Explorer.Highlighter, Vcl.ExtCtrls,
  VirtualTrees.BaseAncestorVCL,
  VirtualTrees.BaseTree, VirtualTrees.AncestorVCL, VirtualTrees,
  TDump.Explorer.Parser, TDump.Explorer.TinyParser, Vcl.WinXPanels;

type
  TTreeDetailKind = (tdkNone, tdkDocumentSummary,
    tdkOldExecutableHeader, tdkPortableExecutableHeader, tdkELFHeader,
    tdkDataDirectories, tdkObjectTable, tdkImportDirectory,
    tdkImportModule, tdkExportDirectory, tdkResourceDirectory,
    tdkResource, tdkBorlandSubsection, tdkBorlandSourceFile,
    tdkBorlandAlignSymbolRecord, tdkBorlandGlobalSymbolRecord,
    tdkBorlandGlobalTypeRecord, tdkMachHeader, tdkMachArchitectures,
    tdkMachArchitecture, tdkMachLoadCommands, tdkMachLoadCommand,
    tdkMachSection, tdkMachSymbolTable, tdkELFSectionHeaders,
    tdkELFSymbolTable, tdkELFRelocations, tdkOMFRecords, tdkOMFRecord,
    tdkOMFLibraryMembers, tdkRelocations, tdkRelocationBlock, tdkStrings, tdkMachDynamicImports,
    tdkMachIndirectSymbols, tdkDiagnostics);

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
  end;

  TFrame1 = class(TFrame)
    ProgressBar1: TProgressBar;
    HighlighterControl1: THighlighterControl;
    Tree: TVirtualStringTree;
    Panel1: TPanel;
    Splitter1: TSplitter;
    CardPanel1: TCardPanel;
    Card1: TCard;
  private
    FDocument: TDumpDocument;
    FHighlighterCards: array[TTreeDetailKind] of TCard;
    FHighlighterControls: array[TTreeDetailKind] of THighlighterControl;
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
    procedure ShowELFSymbolTableDetails;
    procedure ShowELFRelocationsDetails;
    procedure ShowRelocationsDetails;
    procedure ShowRelocationBlockDetails(ABlock: TDumpRelocationBlock);
    procedure ShowStringsDetails;
    procedure ShowOMFRecordsDetails;
    procedure ShowOMFLibraryMembersDetails;
    procedure ShowOMFRecordDetails(ARecord: TDumpObjectRecord);
    procedure ShowImportDirectoryDetails;
    procedure ShowImportModuleDetails(AImportModuleIndex: Integer);
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
    procedure ShowDiagnosticsDetails;
    procedure ActivateNode(ANode: PVirtualNode);
    procedure TreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure TreeFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex);
    procedure TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure TreeMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
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
  Tree.NodeDataSize := SizeOf(TTreeItemData);
  Tree.OnGetText := TreeGetText;
  Tree.OnFreeNode := TreeFreeNode;
  Tree.OnFocusChanged := TreeFocusChanged;
  Tree.OnMouseUp := TreeMouseUp;
end;

destructor TFrame1.Destroy;
begin
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
    var LCard := TCard.Create(CardPanel1);
    LCard.Parent := CardPanel1;
    case ADetailKind of
      tdkDataDirectories:
        LCard.Caption := 'Data Directories';
      tdkObjectTable:
        LCard.Caption := 'Object Table';
      tdkImportDirectory:
        LCard.Caption := 'Import Directory';
      tdkImportModule:
        LCard.Caption := 'Import Module';
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
      tdkELFSymbolTable:
        LCard.Caption := 'ELF Symbol Table';
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
      tdkMachDynamicImports:
        LCard.Caption := 'Mach Dynamic Imports';
      tdkMachIndirectSymbols:
        LCard.Caption := 'Mach Indirect Symbols';
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
  CardPanel1.ActiveCard := FHighlighterCards[ADetailKind];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkMachArchitectures];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkMachArchitecture];
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
    for var LCommand in FDocument.MachLoadCommands do
      LControl.AddColumns([IntToStr(LCommand.Index), LCommand.Name,
        IntToStr(LCommand.Sections.Count)]);
  finally
    LControl.EndUpdate;
  end;
  CardPanel1.ActiveCard := FHighlighterCards[tdkMachLoadCommands];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkMachLoadCommand];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkMachSection];
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
    for var LSymbol in FDocument.MachSymbols do
      LControl.AddColumns([IntToStr(LSymbol.Index), LSymbol.TypeCode,
        LSymbol.Section, LSymbol.Description, LSymbol.RawValue, LSymbol.Name]);
  finally
    LControl.EndUpdate;
  end;
  CardPanel1.ActiveCard := FHighlighterCards[tdkMachSymbolTable];
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
  CardPanel1.ActiveCard := FHighlighterCards[ADetailKind];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkDataDirectories];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkObjectTable];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkELFSectionHeaders];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkELFSymbolTable];
end;

procedure TFrame1.ShowELFRelocationsDetails;
begin
  if FDocument = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkELFRelocations);
  LControl.ParserMode := tpmCppBuilderMethod;
  LControl.BeginUpdate;
  try
    LControl.Clear;
    LControl.SetColumnHeaders(['Section', 'Ndx', 'Type', 'Offset', '(Addend)',
      'Value', 'Symbol', 'Addend', 'Name']);
    LControl.SetColumnDataTypes([thdtText, thdtInteger, thdtSymbol,
      thdtHexadecimal, thdtHexadecimal, thdtHexadecimal, thdtInteger,
      thdtHexadecimal, thdtAuto]);
    for var LRelocation in FDocument.ELFRelocations do
      LControl.AddColumns([LRelocation.SectionName, IntToStr(LRelocation.Index),
        LRelocation.RelocationType, LRelocation.Offset,
        LRelocation.ParenthesizedAddend, LRelocation.Value,
        LRelocation.SymbolIndex, LRelocation.Addend, LRelocation.Name]);
  finally
    LControl.EndUpdate;
  end;
  CardPanel1.ActiveCard := FHighlighterCards[tdkELFRelocations];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkRelocations];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkRelocationBlock];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkStrings];
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
    LControl.SetColumnHeaders(['Offset', 'Record', 'Details', 'Lines']);
    LControl.SetColumnDataTypes([thdtHexadecimal, thdtSymbol, thdtAuto,
      thdtInteger]);
    for var LRecord in FDocument.ObjectRecords do
      LControl.AddColumns([LRecord.RawOffset, LRecord.RecordKind, LRecord.Name,
        IntToStr(LRecord.EndLine - LRecord.StartLine + 1)]);
  finally
    LControl.EndUpdate;
  end;
  CardPanel1.ActiveCard := FHighlighterCards[tdkOMFRecords];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkOMFLibraryMembers];
end;

procedure TFrame1.ShowOMFRecordDetails(ARecord: TDumpObjectRecord);
begin
  if ARecord = nil then
    Exit;

  var LControl := EnsureHighlighterDetailControl(tdkOMFRecord);
  LControl.ParserMode := tpmTDumpValues;
  LControl.SetText(ARecord.RawText);
  FHighlighterCards[tdkOMFRecord].Caption := ARecord.RawOffset + ' ' +
    ARecord.RecordKind;
  CardPanel1.ActiveCard := FHighlighterCards[tdkOMFRecord];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkImportDirectory];
end;

procedure TFrame1.ShowImportModuleDetails(AImportModuleIndex: Integer);
begin
  if (FDocument = nil) or (AImportModuleIndex < 0) or
    (AImportModuleIndex >= FDocument.Imports.Count) then
    Exit;

  var LModule := FDocument.Imports[AImportModuleIndex];
  var LModuleName := LModule.Name;
  if LModuleName = '' then
    LModuleName := 'Unnamed import module';

  var LControl := EnsureHighlighterDetailControl(tdkImportModule);
  LControl.ParserMode := tpmCppBuilderMethod;
  FHighlighterCards[tdkImportModule].Caption := LModuleName;
  var LText := TStringBuilder.Create;
  try
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkImportModule];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkExportDirectory];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkResourceDirectory];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkResource];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkBorlandSubsection];
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
  CardPanel1.ActiveCard := FHighlighterCards[ADetailKind];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkBorlandGlobalTypeRecord];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkBorlandSourceFile];
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
  CardPanel1.ActiveCard := FHighlighterCards[tdkDiagnostics];
end;

procedure TFrame1.PopulateTree(ADocument: TDumpDocument);
begin
  if FDocument <> ADocument then
  begin
    FDocument.Free;
    FDocument := ADocument;
  end;
  if FDocument = nil then
    Exit;

  CardPanel1.ActiveCard := Card1;
  Tree.BeginUpdate;
  try
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
    if FDocument.Imports.Count > 0 then
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
    if FDocument.ELFRelocations.Count > 0 then
      AddTreeNode(LRootNode, Format('Relocations [%d]',
        [FDocument.ELFRelocations.Count]), tdkELFRelocations);

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
    if FDocument.MachDynamicImports.Count > 0 then
      AddTreeNode(LRootNode, Format('Dynamic Imports [%d symbols]',
        [FDocument.MachDynamicImports.Count]), tdkMachDynamicImports);
    if FDocument.MachIndirectSymbols.Count > 0 then
      AddTreeNode(LRootNode, Format('Indirect Symbols [%d symbols]',
        [FDocument.MachIndirectSymbols.Count]), tdkMachIndirectSymbols);

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
  HighlighterControl1.SetText(AStatus);
  ProgressBar1.Min := 0;
  ProgressBar1.Max := 100;
  ProgressBar1.Position := 0;
  ProgressBar1.Update;
end;

procedure TFrame1.ShowSummary(const ASummary: string);
begin
  HighlighterControl1.SetText(ASummary);
  ProgressBar1.Position := ProgressBar1.Max;
  ProgressBar1.Update;
end;

procedure TFrame1.ActivateNode(ANode: PVirtualNode);
begin
  if ANode = nil then
  begin
    CardPanel1.ActiveCard := Card1;
    Exit;
  end;

  var LNodeData := PTreeItemData(Tree.GetNodeData(ANode));
  case LNodeData.DetailKind of
    tdkDocumentSummary:
      CardPanel1.ActiveCard := Card1;
    tdkOldExecutableHeader, tdkPortableExecutableHeader, tdkMachHeader,
    tdkELFHeader:
      ShowHeaderDetails(LNodeData.DetailKind, LNodeData.HeaderIndex);
    tdkDataDirectories:
      ShowDataDirectoriesDetails;
    tdkObjectTable:
      ShowObjectTableDetails;
    tdkELFSectionHeaders:
      ShowELFSectionHeadersDetails;
    tdkELFSymbolTable:
      ShowELFSymbolTableDetails;
    tdkELFRelocations:
      ShowELFRelocationsDetails;
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
    tdkOMFRecord:
      ShowOMFRecordDetails(LNodeData.ObjectRecord);
    tdkImportDirectory:
      ShowImportDirectoryDetails;
    tdkImportModule:
      ShowImportModuleDetails(LNodeData.ImportModuleIndex);
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
    tdkDiagnostics:
      ShowDiagnosticsDetails;
  else
    CardPanel1.ActiveCard := Card1;
  end;
end;

procedure TFrame1.TreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
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

end.
