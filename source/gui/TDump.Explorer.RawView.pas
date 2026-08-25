unit TDump.Explorer.RawView;

interface

uses
  System.Classes, System.Math, Vcl.Controls, Vcl.Forms,
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
    FSyncWithSelectedNode: Boolean;
    FOnSyncWithSelectedNodeChanged: TNotifyEvent;
    procedure cbFollowSelectionClick(Sender: TObject);
    procedure SetSyncWithSelectedNode(const AValue: Boolean);
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
  TDump.Explorer.TinyParser;

{$R *.dfm}

constructor TRawViewFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHighlighterControl := THighlighterControl.Create(nil);
  FHighlighterControl.Parent := Self;
  FHighlighterControl.Align := alClient;
  FHighlighterControl.AutoSizeColumns := False;
  FHighlighterControl.UseColumnMode := False;
  FHighlighterControl.ShowLineNumbers := True;
  FHighlighterControl.UseEndEllipsis := False;
  FHighlighterControl.ParserMode := tpmTDumpValues;
  FHighlighterControl.Font.Name := 'Consolas';
  FHighlighterControl.Font.Size := 8;
  FHighlighterControl.ControlList1.MultiSelect := True;
  cbFollowSelection.OnClick := cbFollowSelectionClick;
  SetSyncWithSelectedNode(cbFollowSelection.Checked);
  Clear;
end;

destructor TRawViewFrame.Destroy;
begin
  FHighlighterControl.Free;
  inherited;
end;

procedure TRawViewFrame.Clear;
begin
  FHighlighterControl.SetText('No TDUMP report is loaded.');
end;

procedure TRawViewFrame.Populate(ADocument: TDumpDocument);
begin
  if ADocument = nil then
  begin
    Clear;
    Exit;
  end;

  FHighlighterControl.BeginUpdate;
  try
    FHighlighterControl.SetText(ADocument.RawText);
    for var LItemIndex := 0 to Min(FHighlighterControl.Items.Count,
      ADocument.Lines.Count) - 1 do
      if ADocument.Lines[LItemIndex].SourceSpan.SyntaxHint =
        rshCppBuilderMethod then
        FHighlighterControl.SetItemParserMode(LItemIndex, tpmCppBuilderMethod);
  finally
    FHighlighterControl.EndUpdate;
  end;
end;

procedure TRawViewFrame.cbFollowSelectionClick(Sender: TObject);
begin
  SetSyncWithSelectedNode(cbFollowSelection.Checked);
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
  if not FSyncWithSelectedNode then
    Exit;

  var LItemIndex := AStartLine - 1;
  if (LItemIndex < 0) or (LItemIndex >= FHighlighterControl.Items.Count) then
    Exit;

  var LLastItemIndex := Min(AEndLine - 1, FHighlighterControl.Items.Count - 1);
  if LLastItemIndex < LItemIndex then
    LLastItemIndex := LItemIndex;
  FHighlighterControl.SetHighlightedRange(LItemIndex, LLastItemIndex);
  FHighlighterControl.ScrollItemToTop(LItemIndex);
end;

end.
