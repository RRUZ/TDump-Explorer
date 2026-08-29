unit TDump.Explorer.RawView;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.Classes, System.SysUtils, System.Math, System.StrUtils, System.Generics.Collections,
  Vcl.Controls, Vcl.Forms,
  TDump.Explorer.HighlighterControl, TDump.Explorer.Parser, Vcl.ExtCtrls,
  Vcl.StdCtrls, Vcl.WinXCtrls;

type
  TRawViewFrame = class(TFrame)
    pnToolbar: TPanel;
    SearchFilterBox: TSearchBox;
    Label1: TLabel;
    cbFollowSelection: TCheckBox;
  private
    FHighlighterControl: THighlighterControl;
    FSourceLines: TStringList;
    FSourceParserModes: TList<Integer>;
    FVisibleSourceLineIndexes: TList<Integer>;
    FSyncWithSelectedNode: Boolean;
    FOnSyncWithSelectedNodeChanged: TNotifyEvent;
    FLastSourceStartLine: Integer;
    FLastSourceEndLine: Integer;
    procedure ApplyFilter;
    procedure cbFollowSelectionClick(Sender: TObject);
    procedure SearchFilterBoxChange(Sender: TObject);
    procedure SearchFilterBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure SetSyncWithSelectedNode(const AValue: Boolean);
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
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
  end;

implementation

uses
  TDump.Explorer.TinyParser, TDump.Explorer.UI, Vcl.Graphics;

{$R *.dfm}

constructor TRawViewFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSourceLines := TStringList.Create;
  FSourceParserModes := TList<Integer>.Create;
  FVisibleSourceLineIndexes := TList<Integer>.Create;
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
  cbFollowSelection.OnClick := cbFollowSelectionClick;
  SearchFilterBox.OnChange := SearchFilterBoxChange;
  SearchFilterBox.OnKeyDown := SearchFilterBoxKeyDown;
  SetSyncWithSelectedNode(cbFollowSelection.Checked);
  Clear;
  ApplyTheme;
end;

destructor TRawViewFrame.Destroy;
begin
  FVisibleSourceLineIndexes.Free;
  FSourceParserModes.Free;
  FSourceLines.Free;
  FHighlighterControl.Free;
  inherited;
end;

procedure TRawViewFrame.Clear;
begin
  FSourceLines.Clear;
  FSourceParserModes.Clear;
  FVisibleSourceLineIndexes.Clear;
  FLastSourceStartLine := 0;
  FLastSourceEndLine := 0;
  FHighlighterControl.FilterText := '';
  FHighlighterControl.SetText('No TDUMP report is loaded.');
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

  FSourceLines.Text := ADocument.RawText;
  FSourceParserModes.Clear;
  for var LSourceIndex := 0 to FSourceLines.Count - 1 do
    if (LSourceIndex < ADocument.Lines.Count) and
      (ADocument.Lines[LSourceIndex].SourceSpan.SyntaxHint =
        rshCppBuilderMethod) then
      FSourceParserModes.Add(Ord(tpmCppBuilderMethod))
    else
      FSourceParserModes.Add(-1);
  FLastSourceStartLine := 0;
  FLastSourceEndLine := 0;
  ApplyFilter;
end;

procedure TRawViewFrame.ApplyFilter;
begin
  var LFilterText := Trim(SearchFilterBox.Text);
  FVisibleSourceLineIndexes.Clear;
  FHighlighterControl.BeginUpdate;
  try
    FHighlighterControl.Clear;
    FHighlighterControl.FilterText := LFilterText;
    for var LSourceIndex := 0 to FSourceLines.Count - 1 do
      if (LFilterText = '') or ContainsText(FSourceLines[LSourceIndex],
        LFilterText) then
      begin
        if (LSourceIndex < FSourceParserModes.Count) and
          (FSourceParserModes[LSourceIndex] >= 0) then
          FHighlighterControl.Add(FSourceLines[LSourceIndex],
            TTinyParserMode(FSourceParserModes[LSourceIndex]))
        else
          FHighlighterControl.Add(FSourceLines[LSourceIndex]);
        FHighlighterControl.SetLineNumber(FHighlighterControl.Items.Count - 1,
          LSourceIndex);
        FVisibleSourceLineIndexes.Add(LSourceIndex);
      end;
  finally
    FHighlighterControl.EndUpdate;
  end;

  if FSyncWithSelectedNode and (FLastSourceStartLine > 0) then
    ShowLines(FLastSourceStartLine, FLastSourceEndLine);
end;

procedure TRawViewFrame.ApplyTheme;
begin
  pnToolbar.ParentBackground := False;
  pnToolbar.StyleElements := pnToolbar.StyleElements - [seClient];
  pnToolbar.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
  FHighlighterControl.Invalidate;
end;

procedure TRawViewFrame.cbFollowSelectionClick(Sender: TObject);
begin
  SetSyncWithSelectedNode(cbFollowSelection.Checked);
end;

procedure TRawViewFrame.SearchFilterBoxChange(Sender: TObject);
begin
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

  var LFirstSourceIndex := AStartLine - 1;
  var LLastSourceIndex := Max(LFirstSourceIndex, AEndLine - 1);
  var LFirstVisibleIndex := -1;
  var LLastVisibleIndex := -1;
  for var LVisibleIndex := 0 to FVisibleSourceLineIndexes.Count - 1 do
    if (FVisibleSourceLineIndexes[LVisibleIndex] >= LFirstSourceIndex) and
      (FVisibleSourceLineIndexes[LVisibleIndex] <= LLastSourceIndex) then
    begin
      if LFirstVisibleIndex < 0 then
        LFirstVisibleIndex := LVisibleIndex;
      LLastVisibleIndex := LVisibleIndex;
    end;
  if LFirstVisibleIndex < 0 then
  begin
    FHighlighterControl.ClearHighlightedItems;
    Exit;
  end;

  FHighlighterControl.SetHighlightedRange(LFirstVisibleIndex,
    LLastVisibleIndex);
  FHighlighterControl.ScrollItemToTop(LFirstVisibleIndex);
end;

end.
