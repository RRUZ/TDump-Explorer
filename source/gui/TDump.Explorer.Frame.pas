unit TDump.Explorer.Frame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Math, System.IOUtils, System.Generics.Collections, System.StrUtils,
  System.UITypes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ComCtrls, TDump.Explorer.HighlighterControl, TDump.Explorer.Highlighter,
  Vcl.ExtCtrls, VirtualTrees.Types, VirtualTrees.BaseAncestorVCL, VirtualTrees.BaseTree,
  VirtualTrees.AncestorVCL, VirtualTrees, TDump.Explorer.Parser, TDump.Explorer.TinyParser,
  Vcl.WinXPanels, TDump.Explorer.RawView, TDump.Explorer.View.Shared, Vcl.VirtualImage,
  System.ImageList, Vcl.ImgList, Vcl.VirtualImageList;

type
  TDumpDocumentFrame = class(TFrame)
    Tree: TVirtualStringTree;
    pnCards: TPanel;
    Splitter1: TSplitter;
    cpViews: TCardPanel;
    pnProperties: TPanel;
    pnTop: TPanel;
    Splitter2: TSplitter;
    frRawView: TRawViewFrame;
    VirtualImage1: TVirtualImage;
    lblDocumentName: TLabel;
    lblSourcePath: TLabel;
    lblFormatCaption: TLabel;
    lblFormatValue: TLabel;
    lblArchitectureCaption: TLabel;
    lblArchitectureValue: TLabel;
    lblTimestampCaption: TLabel;
    lblTimestampValue: TLabel;
    lblSizeCaption: TLabel;
    lblSizeValue: TLabel;
    pnDocument: TPanel;
    gpHeader: TGridPanel;
    VirtualImageList1: TVirtualImageList;
  private
    FDocument: TDumpDocument;
    FSummaryCard: TCard;
    FSummaryControl: THighlighterControl;
    FDetailCard: TCard;
    FDetailControl: THighlighterControl;
    FCurrentDetailKind: TTreeDetailKind;
    FHighlighterCards: array[TTreeDetailKind] of TCard;
    FHighlighterControls: array[TTreeDetailKind] of THighlighterControl;
    FActiveDetailNode: PVirtualNode;
    FTreeSelectionFillColor: TColor;
    FTreeSelectionBorderColor: TColor;
    function HeaderFormatCaption: string;
    function HeaderArchitectureCaption: string;
    procedure UpdateDocumentHeader;
    function EnsureHighlighterDetailControl(
      ADetailKind: TTreeDetailKind): THighlighterControl;
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
    procedure ShowBorlandSymbolTableDetails;
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
    procedure TreeGetImageIndex(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Kind: TVTImageKind; Column: TColumnIndex; var Ghosted: Boolean;
      var ImageIndex: System.UITypes.TImageIndex);
    procedure TreeBeforeCellPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      CellPaintMode: TVTCellPaintMode; CellRect: TRect;
      var ContentRect: TRect);
    procedure TreeMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure pnTopResize(Sender: TObject);
    procedure SplitterPaint(Sender: TObject);
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure ApplyTreeTheme;
    procedure ApplyTheme;
  protected
    procedure SetParent(AParent: TWinControl); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Takes ownership of ADocument.
    procedure PopulateTree(ADocument: TDumpDocument);
    procedure ShowSummary(const ASummary: string);
  end;

implementation

uses
  TDump.Explorer.UI, Vcl.GraphUtil, TDump.Explorer.Resources,
  TDump.Explorer.View.ELF, TDump.Explorer.View.Mach,
  TDump.Explorer.View.OMF, TDump.Explorer.View.PE,
  TDump.Explorer.View.Borland, TDump.Explorer.View.Diagnostics;

{$R *.dfm}


procedure TDumpDocumentFrame.ApplyTheme;

   procedure SetLabelColor(ALabel: TLabel; AColor: TColor);
   begin
     ALabel.StyleName := 'Windows';
     ALabel.Font.Color := AColor;
   end;

begin
  pnTop.StyleElements := pnTop.StyleElements - [seClient];
  pnTop.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
  pnDocument.StyleElements := pnDocument.StyleElements - [seClient];
  pnDocument.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
  gpHeader.StyleElements := gpHeader.StyleElements - [seClient];
  gpHeader.Color := TExplorerTheme.ActiveTheme.BackgroundColor;

  SetLabelColor(lblSourcePath, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblFormatCaption, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblFormatValue, TExplorerTheme.ActiveTheme.StringLiteralColor);
  SetLabelColor(lblArchitectureCaption, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblArchitectureValue, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblTimestampCaption, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblTimestampValue, TExplorerTheme.ActiveTheme.DateTimeColor);
  SetLabelColor(lblSizeCaption, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblSizeValue, TExplorerTheme.ActiveTheme.NumberColor);

  VirtualImage1.ImageName := 'binary_' + if not IsLightThemeActive then 'dark' else 'light';
  ApplyTreeTheme;
end;

procedure TDumpDocumentFrame.ApplyTreeTheme;
begin
  var LTheme := TExplorerTheme.ActiveTheme;
  FTreeSelectionFillColor := ColorBlendRGB(LTheme.SelectionColor,
    LTheme.BackgroundColor, 0.9);
  FTreeSelectionBorderColor := LTheme.SelectionColor;

  Tree.Color := LTheme.BackgroundColor;
  Tree.Font.Color := LTheme.TextColor;
  Tree.Colors.FocusedSelectionColor := FTreeSelectionFillColor;
  Tree.Colors.FocusedSelectionBorderColor := FTreeSelectionBorderColor;
  Tree.Colors.UnfocusedSelectionColor := FTreeSelectionFillColor;
  Tree.Colors.UnfocusedSelectionBorderColor := FTreeSelectionBorderColor;
  Tree.Colors.SelectionTextColor := LTheme.TextColor;
  Tree.Colors.UnfocusedColor := LTheme.TextColor;
  Tree.Invalidate;
end;

constructor TDumpDocumentFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  Font.Name := TExplorerTheme.FontName;
  Font.Size := TExplorerTheme.FontSize;

  Splitter1.OnPaint := SplitterPaint;
  Splitter2.OnPaint := SplitterPaint;
  FSummaryCard := TCard.Create(cpViews);
  FSummaryCard.Parent := cpViews;
  FSummaryCard.Caption := 'Summary';
  FSummaryControl := THighlighterControl.Create(FSummaryCard);
  FSummaryControl.Parent := FSummaryCard;
  FSummaryControl.Align := alClient;
  cpViews.ActiveCard := FSummaryCard;
  Tree.NodeDataSize := SizeOf(TTreeItemData);
  Tree.OnGetText := TreeGetText;
  Tree.OnGetImageIndex := TreeGetImageIndex;
  Tree.OnFreeNode := TreeFreeNode;
  Tree.OnFocusChanged := TreeFocusChanged;
  Tree.OnBeforeCellPaint := TreeBeforeCellPaint;
  Tree.OnMouseUp := TreeMouseUp;
  var LPaintOptions := Tree.TreeOptions.PaintOptions +
    [toAlwaysHideSelection, toHideFocusRect];
  Tree.TreeOptions.PaintOptions := LPaintOptions;
  var LSelectionOptions := Tree.TreeOptions.SelectionOptions + [toFullRowSelect];
  Tree.TreeOptions.SelectionOptions := LSelectionOptions;

  ApplyTheme;

  frRawView.OnSyncWithSelectedNodeChanged := RawViewSyncWithSelectedNodeChanged;
  pnTop.OnResize := pnTopResize;
  UpdateDocumentHeader;
end;

procedure TDumpDocumentFrame.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  ApplyTheme;
end;

destructor TDumpDocumentFrame.Destroy;
begin
  FDocument.Free;
  inherited;
end;

function TDumpDocumentFrame.HeaderArchitectureCaption: string;
begin
  Result := '';
  if FDocument = nil then
    Exit;

  Result := Trim(FDocument.Architecture);
  if Result <> '' then
    Exit;

  for var LHeader in FDocument.Headers do
  begin
    Result := PropertyValue(LHeader.Properties, 'CPU type');
    if Result = '' then
      Result := PropertyValue(LHeader.Properties, 'Machine');
    if Result <> '' then
      Exit;
  end;
end;

function TDumpDocumentFrame.HeaderFormatCaption: string;
begin
  if FDocument = nil then
    Exit('');

  case FDocument.FileKind of
    dfPE:
      Result := 'PE';
    dfELFObject:
      Result := 'ELF';
    dfMach:
      Result := 'Mach-O';
  else
    Result := TDocumentTreeBuilder.FileKindCaption(FDocument.FileKind);
  end;
end;

procedure TDumpDocumentFrame.pnTopResize(Sender: TObject);
begin
end;

procedure TDumpDocumentFrame.SplitterPaint(Sender: TObject);
begin
  if not (Sender is TSplitter) then
    Exit;

  var LSplitter := TSplitter(Sender);
  LSplitter.Canvas.Brush.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
  LSplitter.Canvas.FillRect(LSplitter.ClientRect);
  DrawSplitterLine(LSplitter.Canvas, LSplitter.ClientRect,
    LSplitter.Align in [alLeft, alRight], TExplorerTheme.ActiveTheme.GhostColor);
end;

procedure TDumpDocumentFrame.UpdateDocumentHeader;
var
  LSourceFileName: string;
begin
  if FDocument = nil then
  begin
    lblDocumentName.Caption := '';
    lblSourcePath.Caption := '';
    lblFormatValue.Caption := '';
    lblArchitectureValue.Caption := '';
    lblTimestampValue.Caption := '';
    lblSizeValue.Caption := '';
    Exit;
  end;

  LSourceFileName := FDocument.SourceFileName;
  lblDocumentName.Caption := ExtractFileName(LSourceFileName);
  if lblDocumentName.Caption = '' then
    lblDocumentName.Caption := TDocumentTreeBuilder.FileKindCaption(
      FDocument.FileKind);
  lblDocumentName.Caption := TBorlandView.PackageCaption(
    lblDocumentName.Caption, FDocument);
  lblSourcePath.Caption := LSourceFileName;
  lblFormatValue.Caption := HeaderFormatCaption;
  lblArchitectureValue.Caption := HeaderArchitectureCaption;

  if FileExists(LSourceFileName) then
  begin
    lblTimestampValue.Caption := FormatDateTime('yyyy-mm-dd hh:nn:ss',
      TFile.GetLastWriteTime(LSourceFileName));
    lblSizeValue.Caption := FormatByteSize(TFile.GetSize(LSourceFileName));
  end
  else
  begin
    lblTimestampValue.Caption := '';
    lblSizeValue.Caption := '';
  end;
end;

function TDumpDocumentFrame.EnsureHighlighterDetailControl(
  ADetailKind: TTreeDetailKind): THighlighterControl;
begin
  if FDetailControl = nil then
  begin
    FDetailCard := TCard.Create(cpViews);
    FDetailCard.Parent := cpViews;
    FDetailControl := THighlighterControl.Create(FDetailCard);
    FDetailControl.Parent := FDetailCard;
    FDetailControl.Align := alClient;
  end;
  if FCurrentDetailKind <> ADetailKind then
  begin
    if FCurrentDetailKind <> tdkNone then
    begin
      FHighlighterCards[FCurrentDetailKind] := nil;
      FHighlighterControls[FCurrentDetailKind] := nil;
    end;
    FCurrentDetailKind := ADetailKind;
    FDetailCard.Caption := cTreeDetailKindInfos[ADetailKind].Caption;
    FHighlighterCards[ADetailKind] := FDetailCard;
    FHighlighterControls[ADetailKind] := FDetailControl;
  end;
  Result := FDetailControl;
end;

procedure TDumpDocumentFrame.ShowHeaderDetails(ADetailKind: TTreeDetailKind;
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

procedure TDumpDocumentFrame.ShowMachArchitecturesDetails;
begin
  if FDocument = nil then
    Exit;
  TMachView.PopulateArchitectures(
    EnsureHighlighterDetailControl(tdkMachArchitectures), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkMachArchitectures];
end;

procedure TDumpDocumentFrame.ShowMachArchitectureDetails(
  AArchitecture: TDumpMachArchitecture);
begin
  if AArchitecture = nil then
    Exit;
  TMachView.PopulateArchitecture(
    EnsureHighlighterDetailControl(tdkMachArchitecture), AArchitecture);
  FHighlighterCards[tdkMachArchitecture].Caption := AArchitecture.CPUType;
  cpViews.ActiveCard := FHighlighterCards[tdkMachArchitecture];
end;

procedure TDumpDocumentFrame.ShowMachLoadCommandsDetails;
begin
  if FDocument = nil then
    Exit;
  TMachView.PopulateLoadCommands(
    EnsureHighlighterDetailControl(tdkMachLoadCommands), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkMachLoadCommands];
end;

procedure TDumpDocumentFrame.ShowMachLoadCommandDetails(ACommand: TDumpMachLoadCommand);
begin
  if ACommand = nil then
    Exit;
  TMachView.PopulateLoadCommand(
    EnsureHighlighterDetailControl(tdkMachLoadCommand), ACommand);
  FHighlighterCards[tdkMachLoadCommand].Caption :=
    TMachView.LoadCommandCaption(ACommand);
  cpViews.ActiveCard := FHighlighterCards[tdkMachLoadCommand];
end;

procedure TDumpDocumentFrame.ShowMachSectionDetails(ASection: TDumpMachSection);
begin
  if ASection = nil then
    Exit;
  TMachView.PopulateSection(EnsureHighlighterDetailControl(tdkMachSection),
    ASection);
  FHighlighterCards[tdkMachSection].Caption := ASection.Name;
  cpViews.ActiveCard := FHighlighterCards[tdkMachSection];
end;

procedure TDumpDocumentFrame.ShowMachSymbolTableDetails;
begin
  if FDocument = nil then
    Exit;
  TMachView.PopulateSymbolTable(
    EnsureHighlighterDetailControl(tdkMachSymbolTable), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkMachSymbolTable];
end;

procedure TDumpDocumentFrame.ShowMachDynamicSymbolsDetails(ADetailKind: TTreeDetailKind);
begin
  if FDocument = nil then
    Exit;
  TMachView.PopulateDynamicSymbols(EnsureHighlighterDetailControl(ADetailKind),
    FDocument, ADetailKind);
  cpViews.ActiveCard := FHighlighterCards[ADetailKind];
end;

procedure TDumpDocumentFrame.ShowMachDynamicSymbolMetadataDetails;
begin
  if (FDocument = nil) or (FDocument.MachDynamicSymbolTableCommand = nil) then
    Exit;
  TMachView.PopulateDynamicSymbolMetadata(
    EnsureHighlighterDetailControl(tdkMachDynamicSymbolMetadata), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkMachDynamicSymbolMetadata];
end;

procedure TDumpDocumentFrame.ShowDataDirectoriesDetails;
begin
  if FDocument = nil then
    Exit;
  TPEView.PopulateDataDirectories(
    EnsureHighlighterDetailControl(tdkDataDirectories), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkDataDirectories];
end;

procedure TDumpDocumentFrame.ShowObjectTableDetails;
begin
  if FDocument = nil then
    Exit;
  TPEView.PopulateObjectTable(EnsureHighlighterDetailControl(tdkObjectTable),
    FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkObjectTable];
end;

procedure TDumpDocumentFrame.ShowELFSectionHeadersDetails;
begin
  if FDocument = nil then
    Exit;
  TELFView.PopulateSectionHeaders(
    EnsureHighlighterDetailControl(tdkELFSectionHeaders), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkELFSectionHeaders];
end;

procedure TDumpDocumentFrame.ShowELFProgramHeadersDetails;
begin
  if FDocument = nil then
    Exit;
  TELFView.PopulateProgramHeaders(
    EnsureHighlighterDetailControl(tdkELFProgramHeaders), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkELFProgramHeaders];
end;

procedure TDumpDocumentFrame.ShowELFSymbolTableDetails;
begin
  if FDocument = nil then
    Exit;
  TELFView.PopulateSymbolTable(
    EnsureHighlighterDetailControl(tdkELFSymbolTable), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkELFSymbolTable];
end;

procedure TDumpDocumentFrame.ShowELFDynamicSectionDetails;
begin
  if FDocument = nil then
    Exit;
  TELFView.PopulateDynamicSection(
    EnsureHighlighterDetailControl(tdkELFDynamicSection), FDocument);
  FHighlighterCards[tdkELFDynamicSection].Caption :=
    TELFView.DynamicSectionCaption(FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkELFDynamicSection];
end;

procedure TDumpDocumentFrame.ShowELFRelocationsDetails(const ASectionName: string);
begin
  if FDocument = nil then
    Exit;
  TELFView.PopulateRelocations(EnsureHighlighterDetailControl(tdkELFRelocations),
    FDocument, ASectionName);
  FHighlighterCards[tdkELFRelocations].Caption :=
    TELFView.RelocationsCaption(FDocument, ASectionName);
  cpViews.ActiveCard := FHighlighterCards[tdkELFRelocations];
end;

procedure TDumpDocumentFrame.ShowRelocationsDetails;
begin
  if FDocument = nil then
    Exit;
  TPEView.PopulateRelocations(EnsureHighlighterDetailControl(tdkRelocations),
    FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkRelocations];
end;

procedure TDumpDocumentFrame.ShowRelocationBlockDetails(ABlock: TDumpRelocationBlock);
begin
  if ABlock = nil then
    Exit;
  TPEView.PopulateRelocationBlock(
    EnsureHighlighterDetailControl(tdkRelocationBlock), ABlock);
  FHighlighterCards[tdkRelocationBlock].Caption :=
    TPEView.RelocationBlockCaption(ABlock);
  cpViews.ActiveCard := FHighlighterCards[tdkRelocationBlock];
end;

procedure TDumpDocumentFrame.ShowStringsDetails;
begin
  if FDocument = nil then
    Exit;
  TPEView.PopulateStrings(EnsureHighlighterDetailControl(tdkStrings),
    FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkStrings];
end;

procedure TDumpDocumentFrame.ShowOMFRecordsDetails;
begin
  if FDocument = nil then
    Exit;
  TOMFView.PopulateRecords(EnsureHighlighterDetailControl(tdkOMFRecords),
    FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkOMFRecords];
end;

procedure TDumpDocumentFrame.ShowOMFLibraryMembersDetails;
begin
  if FDocument = nil then
    Exit;
  TOMFView.PopulateLibraryMembers(
    EnsureHighlighterDetailControl(tdkOMFLibraryMembers), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkOMFLibraryMembers];
end;

procedure TDumpDocumentFrame.ShowOMFLibraryIndexDetails;
begin
  if (FDocument = nil) or (FDocument.OMFLibraryIndex = nil) then
    Exit;
  TOMFView.PopulateLibraryIndex(
    EnsureHighlighterDetailControl(tdkOMFLibraryIndex), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkOMFLibraryIndex];
end;

procedure TDumpDocumentFrame.ShowArchiveMembersDetails;
begin
  if FDocument = nil then
    Exit;
  TOMFView.PopulateArchiveMembers(
    EnsureHighlighterDetailControl(tdkArchiveMembers), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkArchiveMembers];
end;

procedure TDumpDocumentFrame.ShowArchiveSymbolsDetails;
begin
  if FDocument = nil then
    Exit;
  TOMFView.PopulateArchiveSymbols(
    EnsureHighlighterDetailControl(tdkArchiveSymbols), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkArchiveSymbols];
end;

procedure TDumpDocumentFrame.ShowOMFRecordDetails(ARecord: TDumpObjectRecord);
begin
  if ARecord = nil then
    Exit;
  TOMFView.PopulateRecord(EnsureHighlighterDetailControl(tdkOMFRecord),
    ARecord);
  FHighlighterCards[tdkOMFRecord].Caption := TOMFView.RecordCaption(ARecord);
  cpViews.ActiveCard := FHighlighterCards[tdkOMFRecord];
end;

procedure TDumpDocumentFrame.ShowImportDirectoryDetails;
begin
  if FDocument = nil then
    Exit;
  TPEView.PopulateImportDirectory(
    EnsureHighlighterDetailControl(tdkImportDirectory), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkImportDirectory];
end;

procedure TDumpDocumentFrame.ShowImportModuleDetails(AImportModuleIndex: Integer);
begin
  if (FDocument = nil) or (AImportModuleIndex < 0) or
    (AImportModuleIndex >= FDocument.Imports.Count) then
    Exit;
  ShowImportModuleDetail(FDocument.Imports[AImportModuleIndex], tdkImportModule);
end;

procedure TDumpDocumentFrame.ShowImportModuleDetail(AImportModule: TDumpImportModule;
  ADetailKind: TTreeDetailKind);
begin
  if AImportModule = nil then
    Exit;
  TPEView.PopulateImportModule(EnsureHighlighterDetailControl(ADetailKind),
    AImportModule, ADetailKind = tdkDelayedImportModule);
  FHighlighterCards[ADetailKind].Caption :=
    TPEView.ImportModuleCaption(AImportModule);
  cpViews.ActiveCard := FHighlighterCards[ADetailKind];
end;

procedure TDumpDocumentFrame.ShowDelayedImportTableDetails;
begin
  if (FDocument = nil) or (FDocument.DelayedImportTable = nil) then
    Exit;
  TPEView.PopulateDelayedImportTable(
    EnsureHighlighterDetailControl(tdkDelayedImportTable), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkDelayedImportTable];
end;

procedure TDumpDocumentFrame.ShowDelayedImportModuleDetails(
  AImportModuleIndex: Integer);
begin
  if (FDocument = nil) or (FDocument.DelayedImportTable = nil) or
    (AImportModuleIndex < 0) or
    (AImportModuleIndex >= FDocument.DelayedImportTable.Modules.Count) then
    Exit;
  ShowImportModuleDetail(FDocument.DelayedImportTable.Modules[AImportModuleIndex],
    tdkDelayedImportModule);
end;

procedure TDumpDocumentFrame.ShowExportDirectoryDetails;
begin
  if FDocument = nil then
    Exit;
  TPEView.PopulateExportDirectory(
    EnsureHighlighterDetailControl(tdkExportDirectory), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkExportDirectory];
end;

procedure TDumpDocumentFrame.ShowResourceDirectoryDetails;
begin
  if FDocument = nil then
    Exit;
  TPEView.PopulateResourceDirectory(
    EnsureHighlighterDetailControl(tdkResourceDirectory), FDocument);
  FHighlighterCards[tdkResourceDirectory].Caption :=
    TPEView.ResourceDirectoryCaption(FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkResourceDirectory];
end;

procedure TDumpDocumentFrame.ShowResourceDetails(AResource: TDumpResource);
begin
  if AResource = nil then
    Exit;
  TPEView.PopulateResource(EnsureHighlighterDetailControl(tdkResource),
    AResource);
  FHighlighterCards[tdkResource].Caption := ResourceCaption(AResource);
  cpViews.ActiveCard := FHighlighterCards[tdkResource];
end;

procedure TDumpDocumentFrame.ShowBorlandSubsectionDetails(
  ASubsectionIndex: Integer);
begin
  if (FDocument = nil) or (ASubsectionIndex < 0) or
    (ASubsectionIndex >= FDocument.BorlandSubsections.Count) then
    Exit;
  var LSubsection := FDocument.BorlandSubsections[ASubsectionIndex];
  TBorlandView.PopulateSubsection(
    EnsureHighlighterDetailControl(tdkBorlandSubsection), FDocument,
    ASubsectionIndex);
  FHighlighterCards[tdkBorlandSubsection].Caption :=
    TBorlandView.SubsectionCaption(LSubsection);
  cpViews.ActiveCard := FHighlighterCards[tdkBorlandSubsection];
end;

procedure TDumpDocumentFrame.ShowBorlandSymbolTableDetails;
begin
  if FDocument = nil then
    Exit;
  TBorlandView.PopulateSymbolTable(
    EnsureHighlighterDetailControl(tdkBorlandSymbolTable), FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkBorlandSymbolTable];
end;

procedure TDumpDocumentFrame.ShowBorlandSymbolRecordDetails(
  ADetailKind: TTreeDetailKind; ARecord: TDumpBorlandSymbolRecord);
begin
  if ARecord = nil then
    Exit;
  TBorlandView.PopulateSymbolRecord(EnsureHighlighterDetailControl(ADetailKind),
    ARecord);
  FHighlighterCards[ADetailKind].Caption := TBorlandView.SymbolCaption(ARecord);
  cpViews.ActiveCard := FHighlighterCards[ADetailKind];
end;

procedure TDumpDocumentFrame.ShowBorlandGlobalTypeRecordDetails(
  ARecord: TDumpGlobalTypeRecord);
begin
  if ARecord = nil then
    Exit;
  TBorlandView.PopulateGlobalTypeRecord(
    EnsureHighlighterDetailControl(tdkBorlandGlobalTypeRecord), ARecord);
  FHighlighterCards[tdkBorlandGlobalTypeRecord].Caption :=
    TBorlandView.TypeCaption(ARecord);
  cpViews.ActiveCard := FHighlighterCards[tdkBorlandGlobalTypeRecord];
end;

procedure TDumpDocumentFrame.ShowBorlandSourceFileDetails(
  ASourceFile: TDumpSourceFile);
begin
  if ASourceFile = nil then
    Exit;
  TBorlandView.PopulateSourceFile(
    EnsureHighlighterDetailControl(tdkBorlandSourceFile), ASourceFile);
  FHighlighterCards[tdkBorlandSourceFile].Caption :=
    TBorlandView.SourceFileCaption(ASourceFile);
  cpViews.ActiveCard := FHighlighterCards[tdkBorlandSourceFile];
end;

procedure TDumpDocumentFrame.ShowDiagnosticsDetails;
begin
  if FDocument = nil then
    Exit;
  TDiagnosticsView.Populate(EnsureHighlighterDetailControl(tdkDiagnostics),
    FDocument);
  FHighlighterCards[tdkDiagnostics].Caption :=
    TDiagnosticsView.Caption(FDocument);
  cpViews.ActiveCard := FHighlighterCards[tdkDiagnostics];
end;

procedure TDumpDocumentFrame.PopulateTree(ADocument: TDumpDocument);
begin
  if FDocument <> ADocument then
  begin
    FDocument.Free;
    FDocument := ADocument;
  end;
  if FDocument = nil then
  begin
    UpdateDocumentHeader;
    Exit;
  end;

  UpdateDocumentHeader;
  cpViews.ActiveCard := FSummaryCard;
  frRawView.Populate(FDocument);
  FActiveDetailNode := nil;
  TDocumentTreeBuilder.Populate(Tree, FDocument);
end;

procedure TDumpDocumentFrame.ShowSummary(const ASummary: string);
begin
  FSummaryControl.SetText(ASummary);
end;

function TDumpDocumentFrame.DetailControlForNode(
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

procedure TDumpDocumentFrame.SaveActiveDetailItemIndex;
begin
  if FActiveDetailNode = nil then
    Exit;

  var LControl := DetailControlForNode(FActiveDetailNode);
  if LControl <> nil then
    PTreeItemData(Tree.GetNodeData(FActiveDetailNode))^.DetailItemIndex :=
      LControl.ControlList1.ItemIndex;
end;

type
  TControlClass =  class(TControl);

procedure TDumpDocumentFrame.SetParent(AParent: TWinControl);

 procedure FixFontForHighDPI(AControl: TControl);
 begin
   TControlClass(AControl).Font.Name := TExplorerTheme.FontName;
   TControlClass(AControl).Font.Size := TExplorerTheme.FontSize;
   TControlClass(AControl).Font.Height := MulDiv(TControlClass(AControl).Font.Height, CurrentPPI, TControlClass(AControl).Font.PixelsPerInch);
 end;

begin
  inherited;
  if Parent <> nil then
  begin
    Font.Name := TExplorerTheme.FontName;
    Font.Size := TExplorerTheme.FontSize;
    Font.Height := MulDiv(Font.Height, CurrentPPI, Font.PixelsPerInch);
    FixFontForHighDPI(Tree);
    FixFontForHighDPI(lblFormatCaption);
    FixFontForHighDPI(lblFormatValue);
    FixFontForHighDPI(lblArchitectureCaption);
    FixFontForHighDPI(lblArchitectureValue);
    FixFontForHighDPI(lblTimestampCaption);
    FixFontForHighDPI(lblTimestampValue);

    FixFontForHighDPI(lblSizeCaption);
    FixFontForHighDPI(lblSizeValue);
    FixFontForHighDPI(lblDocumentName);
    FixFontForHighDPI(lblSourcePath);
  end;
end;

procedure TDumpDocumentFrame.RestoreDetailItemIndex(ANode: PVirtualNode);
begin
  var LControl := DetailControlForNode(ANode);
  if LControl = nil then
    Exit;

  var LItemIndex := PTreeItemData(Tree.GetNodeData(ANode))^.DetailItemIndex;
  if LItemIndex < 0 then
    LItemIndex := 0;
  LControl.SelectItem(LItemIndex);
end;

procedure TDumpDocumentFrame.ResolveNodeSourceSpan(
  const AData: PTreeItemData; out AStartLine, AEndLine: Integer);
begin
  TDocumentSourceNavigation.Resolve(FDocument, AData, AStartLine, AEndLine);
end;

procedure TDumpDocumentFrame.SyncRawViewToNode(ANode: PVirtualNode);
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

procedure TDumpDocumentFrame.RawViewSyncWithSelectedNodeChanged(Sender: TObject);
begin
  if not frRawView.SyncWithSelectedNode then
    Exit;

  var LSelectedNode := FActiveDetailNode;
  if LSelectedNode = nil then
    LSelectedNode := Tree.FocusedNode;
  if LSelectedNode <> nil then
    SyncRawViewToNode(LSelectedNode);
end;

procedure TDumpDocumentFrame.ActivateNode(ANode: PVirtualNode);
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
    tdkBorlandSymbolTable:
      ShowBorlandSymbolTableDetails;
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

procedure TDumpDocumentFrame.TreeFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if FActiveDetailNode = Node then
    FActiveDetailNode := nil;
  Finalize(PTreeItemData(Sender.GetNodeData(Node))^);
end;

procedure TDumpDocumentFrame.TreeGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
  Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  CellText := PTreeItemData(Sender.GetNodeData(Node))^.Caption;
end;

procedure TDumpDocumentFrame.TreeGetImageIndex(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Kind: TVTImageKind; Column: TColumnIndex;
  var Ghosted: Boolean; var ImageIndex: System.UITypes.TImageIndex);
begin
  ImageIndex := -1;
  if (Node = nil) or not (Kind in [ikNormal, ikSelected]) then
    Exit;

  var LNodeData := PTreeItemData(Sender.GetNodeData(Node));
  if LNodeData = nil then
    Exit;
  var LImageName := cTreeDetailKindInfos[LNodeData.DetailKind].ImageName;
  if LImageName = '' then
    Exit;
  if IsLightThemeActive then
    LImageName := LImageName + '_light'
  else
    LImageName := LImageName + '_dark';
  ImageIndex := VirtualImageList1.GetIndexByName(LImageName);
end;

procedure TDumpDocumentFrame.TreeBeforeCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect;
  var ContentRect: TRect);
begin
  if CellPaintMode <> cpmPaint then
    Exit;
  if not Sender.Selected[Node] then
    Exit;
  if (CellRect.Width <= 0) or (CellRect.Height <= 0) then
    Exit;

  DrawSelectionBar(TargetCanvas, CellRect, FTreeSelectionFillColor,
    FTreeSelectionBorderColor);
end;

procedure TDumpDocumentFrame.TreeFocusChanged(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex);
begin
  ActivateNode(Node);
end;

procedure TDumpDocumentFrame.TreeMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;

  ActivateNode(Tree.GetNodeAt(X, Y));
end;

end.
