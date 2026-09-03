//**************************************************************************************************
//
// Unit TDump.Explorer.Frame
//
// Per-document tree, detail, and raw-view coordination
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
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
  System.ImageList, Vcl.ImgList, Vcl.VirtualImageList, TDump.Explorer.UI;

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
    lblDocumentName: TLabel;
    lblSourcePath: TLabel;
    lblFormatCaption: TLabel;
    pnFormatBadge: TPanel;
    lblArchitectureCaption: TLabel;
    pnArchitectureBadge: TPanel;
    lblTimestampCaption: TLabel;
    lblTimestampValue: TLabel;
    lblSizeCaption: TLabel;
    lblSizeValue: TLabel;
    pnDocument: TPanel;
    gpHeader: TGridPanel;
    VirtualImageList1: TVirtualImageList;
    PaintBox1: TPaintBox;
    pnNavigation: TPanel;
    pbNavigation: TPaintBox;
    pbDetails: TPaintBox;
    pbHeader: TPaintBox;
    procedure PaintBox1Paint(Sender: TObject);
    procedure SurfacePaint(Sender: TObject);
    procedure SurfaceResize(Sender: TObject);
  private
    FFormatBadge: TExplorerBadgeLabel;
    FArchitectureBadge: TExplorerBadgeLabel;
    FDocument: TDumpDocument;
    FSummaryCard: TCard;
    FSummaryControl: THighlighterControl;
    FSummaryScroll: TScrollBox;
    FSummaryContent: TPanel;
    FSummaryTitle: TLabel;
    FSummaryDivider: TPaintBox;
    FSummaryCounts: array[0..2] of THighlighterControl;
    FUpdatingSummaryLayout: Boolean;
    FDetailCard: TCard;
    FDetailControl: THighlighterControl;
    FCurrentDetailKind: TTreeDetailKind;
    FHighlighterCards: array[TTreeDetailKind] of TCard;
    FHighlighterControls: array[TTreeDetailKind] of THighlighterControl;
    FActiveDetailNode: PVirtualNode;
    FTreeSelectionFillColor: TColor;
    FTreeSelectionBorderColor: TColor;
    FTreeHighlighter: TTinyHighlighter;
    FSelectingTreeFromRawView: Boolean;
    function TreeTextColor(ADetailKind: TTreeDetailKind): TColor;
    function TreeParserMode(ADetailKind: TTreeDetailKind): TTinyParserMode;
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
    procedure ShowLazyAlignSymbolRecordDetails(
      ASection: TDumpLazyAlignSymbolSection; ARecordIndex: Integer);
    procedure ShowLazyGlobalSymbolRecordDetails(
      ASection: TDumpLazyGlobalSymbolSection; ARecordIndex: Integer);
    procedure ShowLazyGlobalTypeRecordDetails(
      ASection: TDumpLazyGlobalTypeSection; ARecordIndex: Integer);
    procedure ShowBorlandGlobalTypeRecordDetails(
      ARecord: TDumpGlobalTypeRecord);
    procedure ShowMachArchitecturesDetails;
    procedure ShowMachArchitectureDetails(AArchitecture: TDumpMachArchitecture);
    procedure ShowMachLoadCommandsDetails;
    procedure ShowMachLoadCommandDetails(ACommand: TDumpMachLoadCommand);
    procedure ShowMachSectionDetails(ASection: TDumpMachSection);
    procedure ShowMachSymbolTableDetails;
    procedure ShowMachDynamicSymbolsDetails(ADetailKind: TTreeDetailKind);
    procedure ShowMachDynamicSymbolTableDetails;
    procedure ShowMachReportSectionDetails(ADetailKind: TTreeDetailKind);
    procedure ShowDiagnosticsDetails;
    function DetailControlForNode(ANode: PVirtualNode): THighlighterControl;
    procedure SaveActiveDetailItemIndex;
    procedure RestoreDetailItemIndex(ANode: PVirtualNode);
    procedure ResolveNodeSourceSpan(const AData: PTreeItemData;
      out AStartLine, AEndLine: Integer);
    procedure SyncRawViewToNode(ANode: PVirtualNode);
    procedure RawViewSyncWithSelectedNodeChanged(Sender: TObject);
    procedure RawViewSourceLineSelected(Sender: TObject; ASourceLine: Integer);
    function FindTreeNodeForSourceLine(ASourceLine: Integer): PVirtualNode;
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
    procedure TreePaintText(Sender: TBaseVirtualTree;
      const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      TextType: TVSTTextType);
    procedure TreeDrawText(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      const Text: string; const CellRect: TRect; var DefaultDraw: Boolean);
    procedure TreeMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure ApplyTreeTheme;
    procedure ApplyTheme;
    procedure UpdateDocumentIcon;
    procedure UpdateFontSize;
    procedure CreateSummaryView;
    procedure SummaryResize(Sender: TObject);
    procedure SummaryCardChanged(Sender: TObject; PrevCard, NextCard: TCard);
    procedure SummaryDividerPaint(Sender: TObject);
    procedure SummaryIconDraw(Sender: TObject; AIndex: Integer;
      ACanvas: TCanvas; const ARect: TRect; AColor: TColor);
    procedure UpdateSummaryLayout;
    procedure ApplySummaryTheme;
  protected
    procedure SetParent(AParent: TWinControl); override;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    // Takes ownership of ADocument.
    procedure PopulateTree(ADocument: TDumpDocument);
    procedure ShowSummary(const ASummary: string);
  end;

implementation

uses
  Vcl.GraphUtil, TDump.Explorer.Resources,
  TDump.Explorer.View.ELF, TDump.Explorer.View.Mach,
  TDump.Explorer.View.OMF, TDump.Explorer.View.PE, TDump.Explorer.Phosphor.Font,
  TDump.Explorer.View.Borland, TDump.Explorer.View.Diagnostics;

{$R *.dfm}


procedure TDumpDocumentFrame.ApplyTheme;

   procedure SetLabelColor(ALabel: TLabel; AColor: TColor);
   begin
     ALabel.StyleName := 'Windows';
     ALabel.Font.Color := AColor;
   end;

begin
  if pnNavigation = nil then
    Exit;
  var LTheme := TExplorerTheme.ActiveTheme;
  Color := LTheme.BackgroundColor;
  StyleElements := StyleElements - [seClient];
  for var LPanel in TArray<TPanel>.Create(pnNavigation, pnCards, pnProperties,
    pnFormatBadge, pnArchitectureBadge) do
  begin
    LPanel.StyleElements := LPanel.StyleElements - [seClient];
    LPanel.ParentBackground := False;
    LPanel.Color := LTheme.BackgroundColor;
  end;
  cpViews.StyleElements := cpViews.StyleElements - [seClient];
  cpViews.Color := LTheme.BackgroundColor;
  pnTop.StyleElements := pnTop.StyleElements - [seClient];
  pnTop.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
  pnDocument.StyleElements := pnDocument.StyleElements - [seClient];
  pnDocument.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
  gpHeader.StyleElements := gpHeader.StyleElements - [seClient];
  gpHeader.Color := TExplorerTheme.ActiveTheme.BackgroundColor;

  SetLabelColor(lblSourcePath, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblFormatCaption, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblArchitectureCaption, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblTimestampCaption, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblTimestampValue, TExplorerTheme.ActiveTheme.DateTimeColor);
  SetLabelColor(lblSizeCaption, TExplorerTheme.ActiveTheme.InactiveText);
  SetLabelColor(lblSizeValue, TExplorerTheme.ActiveTheme.NumberColor);
  SetLabelColor(lblDocumentName, LTheme.TextColor);
  if FFormatBadge <> nil then
  begin
    FFormatBadge.ApplyTheme(LTheme);
    // Apply badge-specific colors after the shared theme defaults.
    FFormatBadge.Color := ColorBlendRGB(LTheme.StringLiteralColor, LTheme.BackgroundColor, 0.9);
    FFormatBadge.BorderColor := LTheme.StringLiteralColor;
    FFormatBadge.Font.Color := LTheme.StringLiteralColor;
    FArchitectureBadge.ApplyTheme(LTheme);
    FArchitectureBadge.Color := ColorBlendRGB(LTheme.InactiveText, LTheme.BackgroundColor, 0.9);
    FArchitectureBadge.BorderColor := LTheme.InactiveText;
    FArchitectureBadge.Font.Color := LTheme.InactiveText;
  end;
  pbNavigation.Invalidate;
  pbDetails.Invalidate;
  pbHeader.Invalidate;
  Splitter1.Invalidate;
  Splitter2.Invalidate;
  ApplySummaryTheme;

  UpdateDocumentIcon;
  ApplyTreeTheme;
end;

procedure TDumpDocumentFrame.UpdateDocumentIcon;
begin
  PaintBox1.Invalidate;
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
  Tree.Colors.SelectionTextColor := LTheme.SelectionColor;
  Tree.Colors.UnfocusedColor := LTheme.TextColor;
  Tree.Invalidate;
end;

function TDumpDocumentFrame.TreeTextColor(
  ADetailKind: TTreeDetailKind): TColor;
begin
  var LTheme := TExplorerTheme.ActiveTheme;
  case cTreeDetailKindInfos[ADetailKind].TextColorKind of
    ttckHighlighted:
      Result := LTheme.TextColor;
    ttckMethod:
      Result := LTheme.MethodColor;
    ttckType:
      Result := LTheme.TypeColor;
  else
    Result := LTheme.TextColor;
  end;
end;

function TDumpDocumentFrame.TreeParserMode(
  ADetailKind: TTreeDetailKind): TTinyParserMode;
begin
  case ADetailKind of
    tdkOMFRecord:
      Result := tpmOMFRecord;
  else
    Result := tpmTDumpValues;
  end;
end;

constructor TDumpDocumentFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FTreeHighlighter := TTinyHighlighter.Create;
  SetExplorerFont(Self, TExplorerTheme.FontName, TExplorerTheme.FontSize);

  FFormatBadge := TExplorerBadgeLabel.Create(Self);
  FFormatBadge.Name := 'FormatBadge';
  FFormatBadge.Parent := pnFormatBadge;
  FFormatBadge.Align := alLeft;
  FFormatBadge.ShowHint := True;

  FArchitectureBadge := TExplorerBadgeLabel.Create(Self);
  FArchitectureBadge.Name := 'ArchitectureBadge';
  FArchitectureBadge.Parent := pnArchitectureBadge;
  FArchitectureBadge.Align := alLeft;
  FArchitectureBadge.ShowHint := True;
  SurfaceResize(nil);

  TExplorerSplitterStyle.Create(Splitter1);
  TExplorerSplitterStyle.Create(Splitter2);
  CreateSummaryView;
  cpViews.OnCardChange := SummaryCardChanged;
  cpViews.ActiveCard := FSummaryCard;
  Tree.NodeDataSize := SizeOf(TTreeItemData);
  Tree.OnGetText := TreeGetText;
  Tree.OnGetImageIndex := TreeGetImageIndex;
  Tree.OnFreeNode := TreeFreeNode;
  Tree.OnFocusChanged := TreeFocusChanged;
  Tree.OnBeforeCellPaint := TreeBeforeCellPaint;
  Tree.OnPaintText := TreePaintText;
  Tree.OnDrawText := TreeDrawText;
  Tree.OnMouseUp := TreeMouseUp;
  var LPaintOptions := Tree.TreeOptions.PaintOptions +
    [toAlwaysHideSelection, toHideFocusRect];
  Tree.TreeOptions.PaintOptions := LPaintOptions;
  var LSelectionOptions := Tree.TreeOptions.SelectionOptions + [toFullRowSelect];
  Tree.TreeOptions.SelectionOptions := LSelectionOptions;

  ApplyTheme;

  frRawView.OnSyncWithSelectedNodeChanged := RawViewSyncWithSelectedNodeChanged;
  frRawView.OnSourceLineSelected := RawViewSourceLineSelected;
  UpdateDocumentHeader;
end;

procedure TDumpDocumentFrame.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  ApplyTheme;
end;

destructor TDumpDocumentFrame.Destroy;
begin
  FTreeHighlighter.Free;
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

procedure TDumpDocumentFrame.PaintBox1Paint(Sender: TObject);
var
  LPaintBox: TPaintBox;
  LSourceFileName: string;
  LIconSize: Integer;
  LIconRect: TRect;
begin
  if not (Sender is TPaintBox) then
    Exit;

  LPaintBox := TPaintBox(Sender);
  LPaintBox.Canvas.Brush.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
  LPaintBox.Canvas.FillRect(LPaintBox.ClientRect);
  LIconSize := Min(ScaleValue(32), Min(LPaintBox.ClientWidth,
    LPaintBox.ClientHeight));
  LIconRect := Rect((LPaintBox.ClientWidth - LIconSize) div 2,
    (LPaintBox.ClientHeight - LIconSize) div 2,
    (LPaintBox.ClientWidth + LIconSize) div 2,
    (LPaintBox.ClientHeight + LIconSize) div 2);
  LSourceFileName := '';
  if FDocument <> nil then
    LSourceFileName := FDocument.SourceFileName;
  DrawExplorerDocumentIcon(LPaintBox.Canvas, LSourceFileName, LIconRect,
    TExplorerTheme.ActiveTheme.TextColor);
end;

procedure TDumpDocumentFrame.SurfacePaint(Sender: TObject);
begin
  var LPaintBox := TPaintBox(Sender);
  DrawExplorerSurface(LPaintBox.Canvas, LPaintBox.ClientRect, ScaleFactor);
end;

procedure TDumpDocumentFrame.SurfaceResize(Sender: TObject);
begin
  // Inline-frame streaming and DPI changes can both change the design-time
  // anchor distances. Keep the decoration tied to the actual pane bounds.
  if pbNavigation <> nil then
    pbNavigation.SetBounds(0, 0, pnNavigation.ClientWidth, pnNavigation.ClientHeight);
  if pbDetails <> nil then
    pbDetails.SetBounds(0, 0, pnCards.ClientWidth, pnCards.ClientHeight);
  if pbHeader <> nil then
    pbHeader.SetBounds(0, 0, pnTop.ClientWidth, pnTop.ClientHeight);
end;

procedure TDumpDocumentFrame.UpdateDocumentHeader;
var
  LSourceFileName: string;
begin
  if FDocument = nil then
  begin
    lblDocumentName.Caption := '';
    lblSourcePath.Caption := '';
    FFormatBadge.Caption := '';
    FFormatBadge.Visible := False;
    FArchitectureBadge.Caption := '';
    FArchitectureBadge.Visible := False;
    lblTimestampValue.Caption := '';
    lblSizeValue.Caption := '';
    UpdateDocumentIcon;
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
  lblDocumentName.Hint := lblDocumentName.Caption;
  lblDocumentName.ShowHint := True;
  lblSourcePath.Hint := LSourceFileName;
  lblSourcePath.ShowHint := True;
  FFormatBadge.Caption := HeaderFormatCaption;
  FFormatBadge.Hint := FFormatBadge.Caption;
  FFormatBadge.Visible := FFormatBadge.Caption <> '';
  FArchitectureBadge.Caption := HeaderArchitectureCaption;
  FArchitectureBadge.Hint := FArchitectureBadge.Caption;
  FArchitectureBadge.Visible := FArchitectureBadge.Caption <> '';

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
  UpdateDocumentIcon;
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
  FDetailControl.SetViewLayoutId('detail:' + IntToStr(Ord(ADetailKind)));
  FDetailControl.PrepareGridPresentation;
  // sstModule overrides this in TBorlandView.  Every other reused detail view
  // starts from the normal UI font so its presentation cannot leak across nodes.
  if ADetailKind <> tdkBorlandSubsection then
  begin
    SetExplorerFont(FDetailControl, TExplorerTheme.FontName,
      TExplorerTheme.FontSize);
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

procedure TDumpDocumentFrame.ShowMachDynamicSymbolTableDetails;
begin
  if (FDocument = nil) or (FDocument.MachDynamicSymbolTable = nil) then
    Exit;
  TMachView.PopulateReportSection(
    EnsureHighlighterDetailControl(tdkMachDynamicSymbolTable), FDocument,
    FDocument.MachDynamicSymbolTable, tdkMachDynamicSymbolTable);
  cpViews.ActiveCard := FHighlighterCards[tdkMachDynamicSymbolTable];
end;

procedure TDumpDocumentFrame.ShowMachReportSectionDetails(
  ADetailKind: TTreeDetailKind);
var
  LSection: TDumpMachReportSection;
begin
  if FDocument = nil then
    Exit;
  case ADetailKind of
    tdkMachRebaseInfo: LSection := FDocument.MachRebaseInfo;
    tdkMachBindingInfo: LSection := FDocument.MachBindingInfo;
    tdkMachWeakBindingInfo: LSection := FDocument.MachWeakBindingInfo;
    tdkMachLazyBindingInfo: LSection := FDocument.MachLazyBindingInfo;
    tdkMachExports: LSection := FDocument.MachExports;
    tdkMachResources: LSection := FDocument.MachResources;
    tdkMachRawSymbols: LSection := FDocument.MachRawSymbols;
  else
    Exit;
  end;
  if LSection = nil then
    Exit;
  TMachView.PopulateReportSection(EnsureHighlighterDetailControl(ADetailKind),
    FDocument, LSection, ADetailKind);
  cpViews.ActiveCard := FHighlighterCards[ADetailKind];
end;

procedure TDumpDocumentFrame.ShowLazyAlignSymbolRecordDetails(
  ASection: TDumpLazyAlignSymbolSection; ARecordIndex: Integer);
begin
  if (FDocument = nil) or (ASection = nil) then
    Exit;
  TBorlandView.PopulateLazyAlignSymbolRecord(
    EnsureHighlighterDetailControl(tdkBorlandAlignSymbolRecord), FDocument,
    ASection, ARecordIndex);
  FHighlighterCards[tdkBorlandAlignSymbolRecord].Caption := 'Symbol record';
  cpViews.ActiveCard := FHighlighterCards[tdkBorlandAlignSymbolRecord];
end;

procedure TDumpDocumentFrame.ShowLazyGlobalSymbolRecordDetails(
  ASection: TDumpLazyGlobalSymbolSection; ARecordIndex: Integer);
begin
  if (FDocument = nil) or (ASection = nil) then
    Exit;
  TBorlandView.PopulateLazyAlignSymbolRecord(
    EnsureHighlighterDetailControl(tdkBorlandGlobalSymbolRecord), FDocument,
    ASection, ARecordIndex);
  FHighlighterCards[tdkBorlandGlobalSymbolRecord].Caption := 'Symbol record';
  cpViews.ActiveCard := FHighlighterCards[tdkBorlandGlobalSymbolRecord];
end;

procedure TDumpDocumentFrame.ShowLazyGlobalTypeRecordDetails(
  ASection: TDumpLazyGlobalTypeSection; ARecordIndex: Integer);
begin
  if (FDocument = nil) or (ASection = nil) then
    Exit;
  TBorlandView.PopulateLazyAlignSymbolRecord(
    EnsureHighlighterDetailControl(tdkBorlandGlobalTypeRecord), FDocument,
    ASection, ARecordIndex);
  FHighlighterCards[tdkBorlandGlobalTypeRecord].Caption := 'Type record';
  cpViews.ActiveCard := FHighlighterCards[tdkBorlandGlobalTypeRecord];
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
  var LLines := TStringList.Create;
  try
    LLines.Text := ASummary;
    FSummaryTitle.Caption := '';
    FSummaryControl.BeginUpdate;
    try
      FSummaryControl.Clear;
      if LLines.Count > 0 then
        FSummaryTitle.Caption := LLines[0];
      // Keep the runner's metadata (including actual TDUMP switches) intact.
      // The blank line separates that metadata from the legacy count list.
      for var LIndex := 1 to LLines.Count - 1 do
      begin
        if LLines[LIndex] = '' then
          Break;
        FSummaryControl.Add(LLines[LIndex]);
      end;
    finally
      FSummaryControl.EndUpdate;
    end;
  finally
    LLines.Free;
  end;
  FSummaryTitle.Hint := FSummaryTitle.Caption;
  for var LCounts in FSummaryCounts do
    LCounts.Clear;
  if FDocument <> nil then
  begin
    FSummaryCounts[0].Add('Headers: ' + IntToStr(FDocument.Headers.Count), IntToStr(cPhFileText));
    FSummaryCounts[0].Add('Sections: ' + IntToStr(FDocument.Sections.Count), IntToStr(cPhStack));
    FSummaryCounts[0].Add('Import modules: ' + IntToStr(FDocument.Imports.Count), IntToStr(cPhSignIn));
    FSummaryCounts[1].Add('Exports: ' + IntToStr(FDocument.ExportList.Count), IntToStr(cPhArrowSquareOut));
    FSummaryCounts[1].Add('Resources: ' + IntToStr(FDocument.Resources.Count), IntToStr(cPhTable));
    FSummaryCounts[2].Add('Diagnostics: ' + IntToStr(FDocument.Diagnostics.Count), IntToStr(cPhPulse));
  end;
  UpdateSummaryLayout;
  for var LCounts in FSummaryCounts do
  begin
    LCounts.ControlList1.ClearSelection;
    LCounts.ControlList1.ItemIndex := -1;
  end;
end;

procedure TDumpDocumentFrame.CreateSummaryView;

  function CreateList(const AName: string): THighlighterControl;
  begin
    Result := THighlighterControl.Create(FSummaryContent);
    Result.Name := AName;
    Result.Parent := FSummaryContent;
    Result.ParentFont := True;
    Result.UseColumnMode := False;
    Result.AutoSizeColumns := False;
    Result.SortEnabled := False;
  end;

begin
  FSummaryCard := TCard.Create(cpViews);
  FSummaryCard.Parent := cpViews;
  FSummaryCard.Caption := 'Summary';
  FSummaryScroll := TScrollBox.Create(FSummaryCard);
  FSummaryScroll.Name := 'SummaryScroll';
  FSummaryScroll.Parent := FSummaryCard;
  FSummaryScroll.Align := alClient;
  FSummaryScroll.BorderStyle := bsNone;
  FSummaryScroll.HorzScrollBar.Visible := False;
  FSummaryScroll.VertScrollBar.Tracking := True;
  FSummaryScroll.ParentFont := True;
  FSummaryContent := TPanel.Create(FSummaryScroll);
  FSummaryContent.Name := 'SummaryContent';
  FSummaryContent.Caption := '';
  FSummaryContent.Parent := FSummaryScroll;
  FSummaryContent.Align := alTop;
  FSummaryContent.BevelOuter := bvNone;
  FSummaryContent.ParentBackground := False;
  FSummaryContent.ParentFont := True;
  FSummaryTitle := TLabel.Create(FSummaryContent);
  FSummaryTitle.Name := 'SummaryTitle';
  FSummaryTitle.Parent := FSummaryContent;
  FSummaryTitle.AutoSize := False;
  FSummaryTitle.Layout := tlCenter;
  FSummaryTitle.EllipsisPosition := epEndEllipsis;
  FSummaryTitle.ShowHint := True;
  FSummaryControl := CreateList('SummaryMetadata');
  FSummaryDivider := TPaintBox.Create(FSummaryContent);
  FSummaryDivider.OnPaint := SummaryDividerPaint;
  FSummaryDivider.Parent := FSummaryContent;
  for var LIndex := 0 to High(FSummaryCounts) do
  begin
    FSummaryCounts[LIndex] := CreateList('SummaryCounts' + IntToStr(LIndex));
    FSummaryCounts[LIndex].OnDrawItemIcon := SummaryIconDraw;
    FSummaryCounts[LIndex].CustomIconSize := 20;
  end;
  FSummaryContent.OnResize := SummaryResize;
  FSummaryScroll.OnResize := SummaryResize;
end;

procedure TDumpDocumentFrame.ApplySummaryTheme;
begin
  if FSummaryScroll = nil then
    Exit;
  var LTheme := TExplorerTheme.ActiveTheme;
  FSummaryScroll.StyleElements := FSummaryScroll.StyleElements - [seClient];
  FSummaryScroll.Color := LTheme.BackgroundColor;
  FSummaryContent.StyleElements := FSummaryContent.StyleElements - [seClient];
  FSummaryContent.Color := LTheme.BackgroundColor;
  FSummaryTitle.StyleElements := FSummaryTitle.StyleElements - [seFont];
  FSummaryTitle.Font.Assign(Font);
  FSummaryTitle.Font.Style := [fsBold];
  FSummaryTitle.Font.Color := LTheme.TextColor;
  FSummaryControl.ControlList1.Color := LTheme.BackgroundColor;
  for var LCounts in FSummaryCounts do
    LCounts.ControlList1.Color := LTheme.BackgroundColor;
  FSummaryDivider.Invalidate;
  UpdateSummaryLayout;
end;

procedure TDumpDocumentFrame.SummaryIconDraw(Sender: TObject; AIndex: Integer;
  ACanvas: TCanvas; const ARect: TRect; AColor: TColor);
begin
  var LIconCode := StrToIntDef(THighlighterControl(Sender).ItemImageName(AIndex), 0);
  if LIconCode <> 0 then
    PhosphorFont.DrawIcon(ACanvas.Handle, LIconCode, ARect, AColor, pfwLight);
end;

procedure TDumpDocumentFrame.SummaryDividerPaint(Sender: TObject);
begin
  var LTheme := TExplorerTheme.ActiveTheme;
  FSummaryDivider.Canvas.Brush.Color := ColorBlendRGB(LTheme.TextColor,
    LTheme.BackgroundColor, 0.87);
  FSummaryDivider.Canvas.FillRect(FSummaryDivider.ClientRect);
end;

procedure TDumpDocumentFrame.SummaryResize(Sender: TObject);
begin
  UpdateSummaryLayout;
end;

procedure TDumpDocumentFrame.SummaryCardChanged(Sender: TObject;
  PrevCard, NextCard: TCard);
begin
  UpdateSummaryLayout;
end;

procedure TDumpDocumentFrame.UpdateSummaryLayout;
var
  LWidth: Integer;
begin
  if (FSummaryContent = nil) or (FSummaryCounts[2] = nil) or
    FUpdatingSummaryLayout then
    Exit;
  FUpdatingSummaryLayout := True;
  try
    var LInset := ScaleValue(8);
    LWidth := Max(1, FSummaryContent.ClientWidth);
    FSummaryTitle.SetBounds(LInset, ScaleValue(2),
      Max(1, LWidth - 2 * LInset), ScaleValue(24));
    FSummaryControl.ControlList1.ItemHeight := ScaleValue(24);
    FSummaryControl.SetBounds(0, FSummaryTitle.BoundsRect.Bottom,
      LWidth, FSummaryControl.Count * FSummaryControl.ControlList1.ItemHeight);
    var LDividerTop := FSummaryControl.BoundsRect.Bottom + LInset;
    FSummaryDivider.SetBounds(LInset, LDividerTop,
      Max(1, LWidth - 2 * LInset), Max(1, ScaleValue(1)));
    var LTop := FSummaryDivider.BoundsRect.Bottom + LInset;
    var LColumns := EnsureRange(LWidth div ScaleValue(190), 1, 3);
    var LColumnWidth := LWidth div LColumns;
    var LRowHeight := 0;
    for var LIndex := 0 to High(FSummaryCounts) do
    begin
      if (LIndex > 0) and (LIndex mod LColumns = 0) then
      begin
        Inc(LTop, LRowHeight);
        LRowHeight := 0;
      end;
      var LCounts := FSummaryCounts[LIndex];
      LCounts.ControlList1.ItemHeight := ScaleValue(28);
      var LHeight := LCounts.Count * LCounts.ControlList1.ItemHeight;
      LCounts.SetBounds((LIndex mod LColumns) * LColumnWidth, LTop,
        LColumnWidth, LHeight);
      LRowHeight := Max(LRowHeight, LHeight);
    end;
    // Keep the count footer at its natural height. Extra pane height belongs
    // above the divider; metadata row heights and short-window scrolling stay
    // unchanged. The rounded outer card fills the same area as navigation.
    var LNaturalHeight := LTop + LRowHeight + LInset;
    var LExtraHeight := Max(0, FSummaryScroll.ClientHeight - LNaturalHeight);
    FSummaryControl.Height := FSummaryControl.Height + LExtraHeight;
    FSummaryDivider.Top := FSummaryDivider.Top + LExtraHeight;
    for var LCounts in FSummaryCounts do
      LCounts.Top := LCounts.Top + LExtraHeight;
    FSummaryContent.Height := LNaturalHeight + LExtraHeight;
  finally
    FUpdatingSummaryLayout := False;
  end;
  // Showing the outer scrollbar can reduce the aligned content width while
  // layout is guarded. Reflow once more at that actual client width.
  if LWidth <> FSummaryContent.ClientWidth then
    UpdateSummaryLayout;
end;

procedure TDumpDocumentFrame.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;
  UpdateSummaryLayout;
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

procedure TDumpDocumentFrame.UpdateFontSize;

 procedure FixFontForHighDPI(AControl: TControl);
 begin
   SetExplorerFont(AControl, TExplorerTheme.FontName, TExplorerTheme.FontSize);
 end;

begin
  SetExplorerFont(Self, TExplorerTheme.FontName, TExplorerTheme.FontSize);
  FixFontForHighDPI(Tree);
  FixFontForHighDPI(lblFormatCaption);
  FixFontForHighDPI(FFormatBadge);
  FixFontForHighDPI(lblArchitectureCaption);
  FixFontForHighDPI(FArchitectureBadge);
  FixFontForHighDPI(lblTimestampCaption);
  FixFontForHighDPI(lblTimestampValue);

  FixFontForHighDPI(lblSizeCaption);
  FixFontForHighDPI(lblSizeValue);
  FixFontForHighDPI(lblDocumentName);
  FixFontForHighDPI(lblSourcePath);
end;

procedure TDumpDocumentFrame.SetParent(AParent: TWinControl);
begin
  inherited;
  if Parent <> nil then
  begin
    UpdateFontSize;
    ApplySummaryTheme;
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
var
  LStartLine: Integer;
  LEndLine: Integer;
begin
  if FSelectingTreeFromRawView then
    Exit;
  if ANode = nil then
  begin
    frRawView.ShowLines(1, 1);
    Exit;
  end;

  var LNodeData := PTreeItemData(Tree.GetNodeData(ANode));
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

function TDumpDocumentFrame.FindTreeNodeForSourceLine(
  ASourceLine: Integer): PVirtualNode;
begin
  Result := nil;
  if ASourceLine <= 0 then
    Exit;

  var LBestSpan := MaxInt;
  var LNode := Tree.GetFirst;
  while LNode <> nil do
  begin
    var LData := PTreeItemData(Tree.GetNodeData(LNode));
    if (LData <> nil) and (LData.SourceStartLine > 0) and
      (ASourceLine >= LData.SourceStartLine) and
      (ASourceLine <= LData.SourceEndLine) then
    begin
      var LSpan := LData.SourceEndLine - LData.SourceStartLine;
      if LSpan < LBestSpan then
      begin
        Result := LNode;
        LBestSpan := LSpan;
      end;
    end;
    LNode := Tree.GetNext(LNode);
  end;
end;

procedure TDumpDocumentFrame.RawViewSourceLineSelected(Sender: TObject;
  ASourceLine: Integer);
begin
  if not frRawView.SyncWithSelectedNode or FSelectingTreeFromRawView then
    Exit;

  var LNode := FindTreeNodeForSourceLine(ASourceLine);
  if (LNode = nil) or (LNode = FActiveDetailNode) then
    Exit;

  FSelectingTreeFromRawView := True;
  try
    // Let VirtualTreeView expand the ancestor chain.  Walking Parent manually
    // reaches its hidden root node and is unsafe for this tree implementation.
    Tree.IsVisible[LNode] := True;
    Tree.ClearSelection;
    Tree.FocusedNode := LNode;
    Tree.Selected[LNode] := True;
  finally
    FSelectingTreeFromRawView := False;
  end;
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
      if LNodeData.LazyAlignSymbolSection <> nil then
        ShowLazyAlignSymbolRecordDetails(LNodeData.LazyAlignSymbolSection,
          LNodeData.LazyAlignSymbolRecordIndex)
      else
        ShowBorlandSymbolRecordDetails(tdkBorlandAlignSymbolRecord,
          LNodeData.AlignSymbolRecord);
    tdkBorlandGlobalSymbolRecord:
      if LNodeData.LazyGlobalSymbolSection <> nil then
        ShowLazyGlobalSymbolRecordDetails(LNodeData.LazyGlobalSymbolSection,
          LNodeData.LazyGlobalSymbolRecordIndex)
      else
        ShowBorlandSymbolRecordDetails(tdkBorlandGlobalSymbolRecord,
          LNodeData.GlobalSymbolRecord);
    tdkBorlandGlobalTypeRecord:
      if LNodeData.LazyGlobalTypeSection <> nil then
        ShowLazyGlobalTypeRecordDetails(LNodeData.LazyGlobalTypeSection,
          LNodeData.LazyGlobalTypeRecordIndex)
      else
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
    tdkMachDynamicSymbolTable:
      ShowMachDynamicSymbolTableDetails;
    tdkMachRebaseInfo, tdkMachBindingInfo, tdkMachWeakBindingInfo,
    tdkMachLazyBindingInfo, tdkMachExports, tdkMachResources, tdkMachRawSymbols:
      ShowMachReportSectionDetails(LNodeData.DetailKind);
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
  if Node = nil then
    Exit;

  if Sender.Selected[Node] and (CellRect.Width > 0) and
    (CellRect.Height > 0) then
    DrawSelectionBar(TargetCanvas, CellRect, FTreeSelectionFillColor,
      FTreeSelectionBorderColor);
end;

procedure TDumpDocumentFrame.TreePaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
begin
  if Node = nil then
    Exit;

  if Sender.Selected[Node] then
    TargetCanvas.Font.Color := TExplorerTheme.ActiveTheme.SelectionColor
  else
    TargetCanvas.Font.Color := TreeTextColor(
      PTreeItemData(Sender.GetNodeData(Node))^.DetailKind);
end;

procedure TDumpDocumentFrame.TreeDrawText(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  const Text: string; const CellRect: TRect; var DefaultDraw: Boolean);
begin
  if (Node = nil) or Sender.Selected[Node] then
    Exit;

  var LNodeData := PTreeItemData(Sender.GetNodeData(Node));
  if (LNodeData = nil) or
    not (cTreeDetailKindInfos[LNodeData.DetailKind].TextColorKind in
      [ttckMethod, ttckType, ttckSyntax]) then
    Exit;

  DefaultDraw := False;
  FTreeHighlighter.TextRect(TargetCanvas, CellRect, Text,
    TExplorerTheme.ActiveTheme, [tfVerticalCenter],
    TreeParserMode(LNodeData.DetailKind));
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
