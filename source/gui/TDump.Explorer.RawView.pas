unit TDump.Explorer.RawView;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Classes, System.SysUtils, System.Math, System.StrUtils,
  System.Generics.Collections, System.Threading, System.SyncObjs,
  Vcl.Controls, Vcl.Forms,
  TDump.Explorer.HighlighterControl, TDump.Explorer.Parser, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.WinXCtrls;

const
  cWmRawFilterReady = WM_USER + $541;
  cWmRawFilterItemDblClick = WM_USER + $542;

type
  TRawViewSourceLineSelectedEvent = procedure(Sender: TObject;
    ASourceLine: Integer) of object;

  TRawViewFrame = class(TFrame)
    pnToolbar: TPanel;
    SearchFilterBox: TSearchBox;
    Label1: TLabel;
    lblFilterMatches: TLabel;
    cbFollowSelection: TCheckBox;
  private
    FHighlighterControl: THighlighterControl;
    FDocument: TDumpDocument;
    FRowProvider: IHighlighterRowProvider;
    FVisibleSourceLineIndexes: TList<Integer>;
    FUsingFilteredIndexes: Boolean;
    FFilterTimer: TTimer;
    FFilterTask: ITask;
    FFilterGeneration: Integer;
    FSyncWithSelectedNode: Boolean;
    FOnSyncWithSelectedNodeChanged: TNotifyEvent;
    FOnSourceLineSelected: TRawViewSourceLineSelectedEvent;
    FLastSourceStartLine: Integer;
    FLastSourceEndLine: Integer;
    procedure ApplyFilter;
    procedure ApplyFilteredIndexes(const AFilterText: string;
      const AIndexes: TArray<Integer>; AGeneration: Integer;
      ADocument: TDumpDocument);
    procedure BeginFilterTask(const AFilterText: string);
    procedure CancelFilterTask(AWait: Boolean);
    procedure DisplayFullSource;
    function FindFirstVisibleIndexAtOrAfter(ASourceIndex: Integer): Integer;
    function FindLastVisibleIndexAtOrBefore(ASourceIndex: Integer): Integer;
    procedure cbFollowSelectionClick(Sender: TObject);
    procedure HighlighterControlItemClick(Sender: TObject);
    procedure HighlighterControlItemDblClick(Sender: TObject);
    procedure SearchFilterBoxChange(Sender: TObject);
    procedure FilterTimerTimer(Sender: TObject);
    procedure SearchFilterBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SetSyncWithSelectedNode(const AValue: Boolean);
    procedure UpdateFilterMatchCount(AFiltering: Boolean = False);
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure WMRawFilterReady(var AMessage: TMessage);
      message cWmRawFilterReady;
    procedure WMRawFilterItemDblClick(var AMessage: TMessage);
      message cWmRawFilterItemDblClick;
    procedure ApplyTheme;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure Populate(ADocument: TDumpDocument);
    procedure ShowLines(AStartLine, AEndLine: Integer);
  published
    property SyncWithSelectedNode: Boolean read FSyncWithSelectedNode
      write SetSyncWithSelectedNode default True;
    property OnSyncWithSelectedNodeChanged: TNotifyEvent
      read FOnSyncWithSelectedNodeChanged write FOnSyncWithSelectedNodeChanged;
    property OnSourceLineSelected: TRawViewSourceLineSelectedEvent
      read FOnSourceLineSelected write FOnSourceLineSelected;
  end;

implementation

uses
  TDump.Explorer.TinyParser, TDump.Explorer.UI,
  TDump.Explorer.HighlighterProviders, Vcl.Graphics;

{$R *.dfm}

type
  TRawFilterResult = class
  public
    FilterText: string;
    Indexes: TArray<Integer>;
    Generation: Integer;
    Document: TDumpDocument;
  end;

constructor TRawViewFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FVisibleSourceLineIndexes := TList<Integer>.Create;
  FFilterTimer := TTimer.Create(Self);
  FFilterTimer.Enabled := False;
  FFilterTimer.Interval := 250;
  FFilterTimer.OnTimer := FilterTimerTimer;
  FHighlighterControl := THighlighterControl.Create(nil);
  FHighlighterControl.Parent := Self;
  FHighlighterControl.Align := alClient;
  FHighlighterControl.AutoSizeColumns := False;
  FHighlighterControl.UseColumnMode := False;
  FHighlighterControl.ShowLineNumbers := True;
  FHighlighterControl.UseEndEllipsis := False;
  FHighlighterControl.ParserMode := tpmTDumpValues;
  FHighlighterControl.Font.Name := TExplorerTheme.FixedWidthFontName;
  FHighlighterControl.Font.Size := TExplorerTheme.FixedWidthFontSize;
  FHighlighterControl.ControlList1.MultiSelect := True;
  FHighlighterControl.OnItemClick := HighlighterControlItemClick;
  FHighlighterControl.ControlList1.OnItemDblClick := HighlighterControlItemDblClick;
  cbFollowSelection.OnClick := cbFollowSelectionClick;
  //SearchFilterBox.TextHint := 'Filter raw TDUMP...';
  SearchFilterBox.OnChange := SearchFilterBoxChange;
  SearchFilterBox.OnKeyDown := SearchFilterBoxKeyDown;
  SetSyncWithSelectedNode(cbFollowSelection.Checked);
  Clear;
  ApplyTheme;
end;

destructor TRawViewFrame.Destroy;
begin
  CancelFilterTask(True);
  var LMessage: TMsg;
  while PeekMessage(LMessage, Handle, cWmRawFilterReady,
    cWmRawFilterReady, PM_REMOVE) do
    TObject(LMessage.lParam).Free;
  FHighlighterControl.SetItemProvider(nil);
  FRowProvider := nil;
  FDocument := nil;
  FVisibleSourceLineIndexes.Free;
  FHighlighterControl.Free;
  inherited;
end;

procedure TRawViewFrame.Clear;
begin
  CancelFilterTask(True);
  FHighlighterControl.SetItemProvider(nil);
  FRowProvider := nil;
  FDocument := nil;
  FVisibleSourceLineIndexes.Clear;
  FUsingFilteredIndexes := False;
  FLastSourceStartLine := 0;
  FLastSourceEndLine := 0;
  FHighlighterControl.FilterText := '';
  FHighlighterControl.SetText('No TDUMP report is loaded.');
  UpdateFilterMatchCount;
end;

procedure TRawViewFrame.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  ApplyTheme;
end;

procedure TRawViewFrame.Populate(ADocument: TDumpDocument);
begin
  if ADocument = nil then
  begin
    Clear;
    Exit;
  end;

  FDocument := ADocument;
  FLastSourceStartLine := 0;
  FLastSourceEndLine := 0;
  ApplyFilter;
end;

procedure TRawViewFrame.ApplyFilter;
begin
  if (FDocument = nil) or (FDocument.TextSource = nil) then
  begin
    UpdateFilterMatchCount;
    Exit;
  end;
  var LFilterText := Trim(SearchFilterBox.Text);
  if LFilterText = '' then
  begin
    CancelFilterTask(False);
    DisplayFullSource
  end
  else
  begin
    UpdateFilterMatchCount(True);
    BeginFilterTask(LFilterText);
  end;

  if FSyncWithSelectedNode and (FLastSourceStartLine > 0) then
    ShowLines(FLastSourceStartLine, FLastSourceEndLine);
end;

procedure TRawViewFrame.ApplyFilteredIndexes(const AFilterText: string;
  const AIndexes: TArray<Integer>; AGeneration: Integer;
  ADocument: TDumpDocument);
begin
  if (AGeneration <> TInterlocked.CompareExchange(FFilterGeneration, 0, 0)) or
    (ADocument <> FDocument) then
    Exit;

  FHighlighterControl.BeginUpdate;
  try
    FHighlighterControl.Clear;
    FVisibleSourceLineIndexes.Clear;
    FVisibleSourceLineIndexes.AddRange(AIndexes);
    FUsingFilteredIndexes := True;
    FHighlighterControl.FilterText := AFilterText;
    FRowProvider := TDocumentLineRowProvider.CreateIndexes(FDocument,
      FVisibleSourceLineIndexes);
    FHighlighterControl.SetItemProvider(FRowProvider);
  finally
    FHighlighterControl.EndUpdate;
  end;
  UpdateFilterMatchCount;
  if FSyncWithSelectedNode and (FLastSourceStartLine > 0) then
    ShowLines(FLastSourceStartLine, FLastSourceEndLine);
end;

procedure TRawViewFrame.BeginFilterTask(const AFilterText: string);
begin
  CancelFilterTask(True);
  var LGeneration := TInterlocked.Increment(FFilterGeneration);
  var LDocument := FDocument;
  FFilterTask := TTask.Run(
    procedure
    begin
      var LIndexes := TList<Integer>.Create;
      try
        for var LSourceIndex := 0 to LDocument.TextSource.LineCount - 1 do
        begin
          if (LSourceIndex and $FF = 0) and
            (LGeneration <> TInterlocked.CompareExchange(
              FFilterGeneration, 0, 0)) then
            Exit;
          if ContainsText(LDocument.TextSource[LSourceIndex], AFilterText) then
            LIndexes.Add(LSourceIndex);
        end;
        if LGeneration <> TInterlocked.CompareExchange(
          FFilterGeneration, 0, 0) then
          Exit;
        var LResult := TRawFilterResult.Create;
        LResult.FilterText := AFilterText;
        LResult.Indexes := LIndexes.ToArray;
        LResult.Generation := LGeneration;
        LResult.Document := LDocument;
        if not PostMessage(Handle, cWmRawFilterReady, 0,
          LPARAM(LResult)) then
          LResult.Free;
      finally
        LIndexes.Free;
      end;
    end);
end;

procedure TRawViewFrame.WMRawFilterReady(var AMessage: TMessage);
begin
  var LResult := TRawFilterResult(AMessage.LParam);
  try
    ApplyFilteredIndexes(LResult.FilterText, LResult.Indexes,
      LResult.Generation, LResult.Document);
  finally
    LResult.Free;
  end;
end;

procedure TRawViewFrame.CancelFilterTask(AWait: Boolean);
begin
  FFilterTimer.Enabled := False;
  TInterlocked.Increment(FFilterGeneration);
  if AWait and (FFilterTask <> nil) then
  begin
    FFilterTask.Wait;
    FFilterTask := nil;
  end;
end;

procedure TRawViewFrame.DisplayFullSource;
begin
  FVisibleSourceLineIndexes.Clear;
  FUsingFilteredIndexes := False;
  FHighlighterControl.BeginUpdate;
  try
    FHighlighterControl.Clear;
    FHighlighterControl.FilterText := '';
    FRowProvider := TDocumentLineRowProvider.CreateRange(FDocument, 0,
      FDocument.TextSource.LineCount);
    FHighlighterControl.SetItemProvider(FRowProvider);
  finally
    FHighlighterControl.EndUpdate;
  end;
  UpdateFilterMatchCount;
end;

function TRawViewFrame.FindFirstVisibleIndexAtOrAfter(
  ASourceIndex: Integer): Integer;
begin
  Result := -1;
  var LLow := 0;
  var LHigh := FVisibleSourceLineIndexes.Count - 1;
  while LLow <= LHigh do
  begin
    var LMiddle := LLow + ((LHigh - LLow) div 2);
    if FVisibleSourceLineIndexes[LMiddle] >= ASourceIndex then
    begin
      Result := LMiddle;
      LHigh := LMiddle - 1;
    end
    else
      LLow := LMiddle + 1;
  end;
end;

function TRawViewFrame.FindLastVisibleIndexAtOrBefore(
  ASourceIndex: Integer): Integer;
begin
  Result := -1;
  var LLow := 0;
  var LHigh := FVisibleSourceLineIndexes.Count - 1;
  while LLow <= LHigh do
  begin
    var LMiddle := LLow + ((LHigh - LLow) div 2);
    if FVisibleSourceLineIndexes[LMiddle] <= ASourceIndex then
    begin
      Result := LMiddle;
      LLow := LMiddle + 1;
    end
    else
      LHigh := LMiddle - 1;
  end;
end;

procedure TRawViewFrame.ApplyTheme;
begin
  var LTheme := TExplorerTheme.ActiveTheme;
  pnToolbar.ParentBackground := False;
  pnToolbar.StyleElements := pnToolbar.StyleElements - [seClient];
  pnToolbar.Color := LTheme.BackgroundColor;
  SearchFilterBox.Font.Color := LTheme.TextColor;
  lblFilterMatches.Font.Color := LTheme.InactiveText;
  FHighlighterControl.Invalidate;
end;

procedure TRawViewFrame.UpdateFilterMatchCount(AFiltering: Boolean);
begin
  if (FDocument = nil) or (FDocument.TextSource = nil) then
  begin
    lblFilterMatches.Caption := '0 matches';
    Exit;
  end;

  var LTotalLines := FDocument.TextSource.LineCount;
  if Trim(SearchFilterBox.Text) = '' then
    lblFilterMatches.Caption := Format('%s lines', [FormatFloat('#,##0',
      LTotalLines)])
  else if AFiltering then
    lblFilterMatches.Caption := 'Filtering...'
  else
    lblFilterMatches.Caption := Format('%s / %s matches', [
      FormatFloat('#,##0', FVisibleSourceLineIndexes.Count),
      FormatFloat('#,##0', LTotalLines)]);
end;

procedure TRawViewFrame.cbFollowSelectionClick(Sender: TObject);
begin
  SetSyncWithSelectedNode(cbFollowSelection.Checked);
end;

procedure TRawViewFrame.HighlighterControlItemClick(Sender: TObject);
begin
  if not FSyncWithSelectedNode or (FDocument = nil) or
    (FDocument.TextSource = nil) or not Assigned(FOnSourceLineSelected) then
    Exit;

  var LSourceIndex := FHighlighterControl.SelectedItemLineNumber;
  if (LSourceIndex < 0) or (LSourceIndex >= FDocument.TextSource.LineCount) then
    Exit;
  // Tree source spans are one-based; the raw provider exposes the mapped
  // zero-based source index used by its line-number gutter.
  FOnSourceLineSelected(Self, LSourceIndex + 1);
end;

procedure TRawViewFrame.HighlighterControlItemDblClick(Sender: TObject);
begin
  PostMessage(Handle, cWmRawFilterItemDblClick, 0, 0);
end;

procedure TRawViewFrame.WMRawFilterItemDblClick(var AMessage: TMessage);
begin
  if not FUsingFilteredIndexes or (FDocument = nil) or
    (FDocument.TextSource = nil) then
    Exit;

  var LSourceIndex := FHighlighterControl.SelectedItemLineNumber;
  if (LSourceIndex < 0) or (LSourceIndex >= FDocument.TextSource.LineCount) then
    Exit;

  SearchFilterBox.Text := '';
  FFilterTimer.Enabled := False;
  DisplayFullSource;
  FHighlighterControl.SelectItem(LSourceIndex);
  FHighlighterControl.ScrollItemToTop(LSourceIndex);
end;

procedure TRawViewFrame.SearchFilterBoxChange(Sender: TObject);
begin
  CancelFilterTask(False);
  FFilterTimer.Enabled := True;
end;

procedure TRawViewFrame.FilterTimerTimer(Sender: TObject);
begin
  FFilterTimer.Enabled := False;
  ApplyFilter;
end;

procedure TRawViewFrame.SearchFilterBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Shift = []) and (Key in [VK_UP, VK_DOWN]) then
  begin
    FHighlighterControl.ControlList1.Perform(WM_KEYDOWN, Key, 0);
    Key := 0;
  end;
end;

procedure TRawViewFrame.SetSyncWithSelectedNode(const AValue: Boolean);
begin
  if FSyncWithSelectedNode = AValue then
    Exit;
  FSyncWithSelectedNode := AValue;
  cbFollowSelection.Checked := AValue;
  if not FSyncWithSelectedNode then
    FHighlighterControl.ClearHighlightedItems;
  if Assigned(FOnSyncWithSelectedNodeChanged) then
    FOnSyncWithSelectedNodeChanged(Self);
end;

procedure TRawViewFrame.ShowLines(AStartLine, AEndLine: Integer);
begin
  FLastSourceStartLine := AStartLine;
  FLastSourceEndLine := AEndLine;
  if not FSyncWithSelectedNode then
    Exit;
  if (FDocument = nil) or (FDocument.TextSource = nil) then
    Exit;

  var LFirstSourceIndex := AStartLine - 1;
  var LLastSourceIndex := Max(LFirstSourceIndex, AEndLine - 1);
  var LFirstVisibleIndex: Integer;
  var LLastVisibleIndex: Integer;
  if FUsingFilteredIndexes then
  begin
    LFirstVisibleIndex := FindFirstVisibleIndexAtOrAfter(LFirstSourceIndex);
    LLastVisibleIndex := FindLastVisibleIndexAtOrBefore(LLastSourceIndex);
  end
  else
  begin
    LFirstVisibleIndex := EnsureRange(LFirstSourceIndex, 0,
      Max(0, FDocument.TextSource.LineCount - 1));
    LLastVisibleIndex := EnsureRange(LLastSourceIndex, LFirstVisibleIndex,
      Max(0, FDocument.TextSource.LineCount - 1));
  end;
  if LFirstVisibleIndex < 0 then
  begin
    FHighlighterControl.ClearHighlightedItems;
    Exit;
  end;
  if LLastVisibleIndex < LFirstVisibleIndex then
  begin
    FHighlighterControl.ClearHighlightedItems;
    Exit;
  end;

  FHighlighterControl.SetHighlightedRange(LFirstVisibleIndex,
    LLastVisibleIndex);
  FHighlighterControl.ScrollItemToTop(LFirstVisibleIndex);
end;

end.
