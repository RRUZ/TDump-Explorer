unit TDump.Explorer.CrossReferences;

interface

uses
  System.Classes, System.Generics.Collections, Vcl.Controls, Vcl.ExtCtrls,
  Vcl.Forms,
  TDump.Explorer.HighlighterControl, TDump.Explorer.Parser,
  TDump.Explorer.Relations;

type
  TCrossReferencesFrame = class(TFrame)
    Splitter1: TSplitter;
  private
    FRelationGraph: TDumpRelationGraph;
    FRelationDetails: TList<string>;
    FRelationControl: THighlighterControl;
    FRelationDetailsControl: THighlighterControl;
    procedure AddRelationItem(const ACategory, ASubject, ATarget,
      ADetails: string);
    procedure RelationControlSelectionChanged(Sender: TObject);
    function LocationCaption(const ALocation: TDumpAddressLocation): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure Populate(ADocument: TDumpDocument);
  end;

implementation

uses
  System.SysUtils, TDump.Explorer.TinyParser;

{$R *.dfm}

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

constructor TCrossReferencesFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRelationDetails := TList<string>.Create;

  FRelationControl := THighlighterControl.Create(nil);
  FRelationControl.Parent := Self;
  FRelationControl.Align := alTop;
  FRelationControl.Height := 280;
  FRelationControl.AutoSizeColumns := False;
  FRelationControl.ParserMode := tpmTDumpValues;
  FRelationControl.SetColumnHeaders(['Kind', 'Subject', 'Target']);
  FRelationControl.ControlList1.MultiSelect := False;
  FRelationControl.ControlList1.OnChange := RelationControlSelectionChanged;

  Splitter1.Align := alTop;
  Splitter1.Top := FRelationControl.Height;

  FRelationDetailsControl := THighlighterControl.Create(nil);
  FRelationDetailsControl.Parent := Self;
  FRelationDetailsControl.Align := alClient;
  FRelationDetailsControl.AutoSizeColumns := False;
  FRelationDetailsControl.ParserMode := tpmTDumpValues;
  FRelationDetailsControl.ControlList1.MultiSelect := False;
  Clear;
end;

destructor TCrossReferencesFrame.Destroy;
begin
  FRelationDetailsControl.Free;
  FRelationControl.Free;
  FRelationGraph.Free;
  FRelationDetails.Free;
  inherited;
end;

procedure TCrossReferencesFrame.Clear;
begin
  FRelationControl.BeginUpdate;
  try
    FRelationControl.Clear;
    FRelationControl.SetColumnHeaders(['Kind', 'Subject', 'Target']);
    FRelationDetails.Clear;
    FRelationDetailsControl.Clear;
    FRelationGraph.Free;
    FRelationGraph := nil;
    FRelationDetailsControl.SetText('No TDUMP report is loaded.');
  finally
    FRelationControl.EndUpdate;
  end;
end;

function TCrossReferencesFrame.LocationCaption(
  const ALocation: TDumpAddressLocation): string;
begin
  Result := Format('TDUMP address: %s:%s', [IntToHex(ALocation.Segment, 4),
    IntToHex(ALocation.Offset, 5)]);
  if ALocation.Section <> nil then
    Result := Result + sLineBreak + 'Section: ' + ALocation.Section.Name;
  if ALocation.HasRVA then
    Result := Result + sLineBreak + 'RVA: ' + IntToHex(ALocation.RVA, 8);
  if ALocation.HasVirtualAddress then
    Result := Result + sLineBreak + 'VA: ' + IntToHex(ALocation.VirtualAddress, 8);
  if ALocation.HasFileOffset then
    Result := Result + sLineBreak + 'File offset: ' +
      IntToHex(ALocation.FileOffset, 8)
  else if ALocation.HasRVA then
    Result := Result + sLineBreak + 'File offset: unavailable (virtual-only)';
end;

procedure TCrossReferencesFrame.AddRelationItem(const ACategory, ASubject,
  ATarget, ADetails: string);
begin
  FRelationDetails.Add(ADetails);
  FRelationControl.AddColumns([ACategory, ASubject, ATarget]);
end;

procedure TCrossReferencesFrame.Populate(ADocument: TDumpDocument);
  function EvidenceCaption(AEvidence: TDumpRelationEvidence): string;
  begin
    if AEvidence = reAddressDerived then
      Result := 'Address-derived from TDUMP/PE coordinates'
    else
      Result := 'Explicit TDUMP relation';
  end;

  function TypeCaption(ARelation: TDumpProcedureTypeRelation): string;
  begin
    Result := 'Type ' + IntToHex(ARelation.TypeIndex, 4);
    if ARelation.TypeRecord <> nil then
      Result := BorlandTypeCaption(ARelation.TypeRecord);
  end;

begin
  Clear;
  if ADocument = nil then
    Exit;

  FRelationControl.BeginUpdate;
  try
    var LBuilder := TDumpRelationBuilder.Create;
    try
      FRelationGraph := LBuilder.Build(ADocument);
    finally
      LBuilder.Free;
    end;

    for var LRelation in FRelationGraph.SourceProcedureRelations do
    begin
      var LSourceName := LRelation.SourceFile.ResolvedName;
      if LSourceName = '' then
        LSourceName := LRelation.SourceFile.Name;
      AddRelationItem('Source procedure', LSourceName,
        BorlandSymbolCaption(LRelation.ProcedureRecord),
        'Evidence: ' + EvidenceCaption(LRelation.Evidence) + sLineBreak +
        'Source lines: ' + LRelation.FirstSourceLine.ToString + '..' +
          LRelation.LastSourceLine.ToString + sLineBreak +
        'Overlap: ' + IntToHex(LRelation.OverlapStart, 5) + '..' +
          IntToHex(LRelation.OverlapEnd, 5) + sLineBreak +
        LocationCaption(LRelation.StartLocation));
    end;

    for var LRelation in FRelationGraph.ProcedureReferenceRelations do
      AddRelationItem('Procedure reference',
        BorlandSymbolCaption(LRelation.ReferenceRecord),
        BorlandSymbolCaption(LRelation.ProcedureRecord),
        'Evidence: ' + EvidenceCaption(LRelation.Evidence) + sLineBreak +
        'Reference record: ' + LRelation.ReferenceRecord.RawRecordOffset);

    for var LRelation in FRelationGraph.ProcedureTypeRelations do
      AddRelationItem('Procedure type',
        BorlandSymbolCaption(LRelation.ProcedureRecord), TypeCaption(LRelation),
        'Evidence: ' + EvidenceCaption(LRelation.Evidence) + sLineBreak +
        'Procedure: ' + BorlandSymbolCaption(LRelation.ProcedureRecord) +
          sLineBreak + 'Type index: ' + IntToHex(LRelation.TypeIndex, 4));

    for var LRelation in FRelationGraph.ExportTargetRelations do
    begin
      var LTarget := 'No symbol target';
      if LRelation.ProcedureRecord <> nil then
        LTarget := BorlandSymbolCaption(LRelation.ProcedureRecord)
      else if LRelation.ProcedureReference <> nil then
        LTarget := BorlandSymbolCaption(LRelation.ProcedureReference);
      AddRelationItem('Export target', LRelation.ExportEntry.Name, LTarget,
        'Evidence: ' + EvidenceCaption(LRelation.Evidence) + sLineBreak +
        'Ordinal: ' + LRelation.ExportEntry.Ordinal.ToString + sLineBreak +
        LocationCaption(LRelation.Location));
    end;

    for var LGroup in FRelationGraph.ExportAliasGroups do
    begin
      var LAliases := TStringBuilder.Create;
      try
        for var LExport in LGroup.Entries do
        begin
          if LAliases.Length > 0 then
            LAliases.Append(', ');
          LAliases.Append(LExport.Name);
        end;
        AddRelationItem('Export aliases', 'RVA ' + IntToHex(LGroup.RVA, 8),
          LAliases.ToString, 'Exports sharing this RVA:' + sLineBreak +
          LAliases.ToString);
      finally
        LAliases.Free;
      end;
    end;

    for var LRelation in FRelationGraph.ProcedureScopeRelations do
    begin
      var LTarget := 'Unresolved S_END';
      if LRelation.EndRecord <> nil then
        LTarget := BorlandSymbolCaption(LRelation.EndRecord);
      AddRelationItem('Procedure scope',
        BorlandSymbolCaption(LRelation.ProcedureRecord), LTarget,
        'Evidence: ' + EvidenceCaption(LRelation.Evidence) + sLineBreak +
        'End record: ' + LTarget);
    end;

    for var LRelation in FRelationGraph.DataDefinitionRelations do
      AddRelationItem('Global data',
        BorlandSymbolCaption(LRelation.DefinitionRecord),
        BorlandSymbolCaption(LRelation.GlobalRecord),
        'Evidence: ' + EvidenceCaption(LRelation.Evidence) + sLineBreak +
        LocationCaption(LRelation.Location));

    for var LRelation in FRelationGraph.ResourceLocationRelations do
    begin
      var LTarget := 'Unresolved section';
      if LRelation.Location.Section <> nil then
        LTarget := LRelation.Location.Section.Name;
      AddRelationItem('Resource location', LRelation.ResourcePath, LTarget,
        'Evidence: ' + EvidenceCaption(LRelation.Evidence) + sLineBreak +
        LocationCaption(LRelation.Location));
    end;
  finally
    FRelationControl.EndUpdate;
  end;

  if FRelationControl.Items.Count = 0 then
    FRelationDetailsControl.SetText(
      'This report does not contain any resolved cross references.')
  else
  begin
    FRelationControl.ControlList1.ItemIndex := 0;
    RelationControlSelectionChanged(nil);
  end;
end;

procedure TCrossReferencesFrame.RelationControlSelectionChanged(Sender: TObject);
begin
  var LIndex := FRelationControl.ControlList1.ItemIndex;
  if (LIndex >= 0) and (LIndex < FRelationDetails.Count) then
    FRelationDetailsControl.SetText(FRelationDetails[LIndex]);
end;

end.
