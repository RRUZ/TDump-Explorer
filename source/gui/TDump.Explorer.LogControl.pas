unit TDump.Explorer.LogControl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections, System.Math, System.StrUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ControlList, Vcl.WinXCtrls, Vcl.Clipbrd;

type
  TLogEntryType = (letInformation, letSuccess, letWarning, letError, letProfile);

  TLogEntry = record
    Timestamp: TDateTime;
    Message: string;
    EntryType: TLogEntryType;
  end;

  TLogEntryList = TList<TLogEntry>;

  TLogControl = class(TFrame)
    ControlList1: TControlList;
    pnToolbar: TPanel;
    SearchFilterBox: TSearchBox;
    Label1: TLabel;
    lblFilterMatches: TLabel;
    procedure ApplyFilter;
    procedure ControlList1BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ControlList1DblClick(Sender: TObject);
    procedure ControlList1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CopySelectedItemsToClipboard;
    procedure DrawFilterMatches(ACanvas: TCanvas; const ARect: TRect;
      const AText: string);
    function EntryTypeColor(AEntryType: TLogEntryType): TColor;
    function EntryText(const AEntry: TLogEntry): string;
    function EntryTypeText(AEntryType: TLogEntryType): string;
    function VisibleEntryIndex(AIndex: Integer): Integer;
    procedure SearchFilterBoxChange(Sender: TObject);
    procedure UpdateControlList;
    procedure UpdateFilterMatchCount;
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure WMLogFilterItemDblClick(var AMessage: TMessage);
      message WM_USER + $541;
    procedure ApplyTheme;
  private
    FEntries: TLogEntryList;
    FVisibleEntryIndexes: TList<Integer>;
    FUsingFilteredIndexes: Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Add(const AMessage: string;
      AEntryType: TLogEntryType = letInformation); overload;
    procedure Add(const AEntry: TLogEntry); overload;
    procedure Clear;
    property Entries: TLogEntryList read FEntries;
  end;

implementation

uses
  Vcl.Themes, Vcl.GraphUtil, TDump.Explorer.UI;

{$R *.dfm}

const
  cMaximumRetainedLogEntries = 10000;
  cWmLogFilterItemDblClick = WM_USER + $541;

constructor TLogControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEntries := TLogEntryList.Create;
  FVisibleEntryIndexes := TList<Integer>.Create;
  ControlList1.MultiSelect := True;
  ControlList1.OnBeforeDrawItem := ControlList1BeforeDrawItem;
  ControlList1.OnItemDblClick := ControlList1DblClick;
  ControlList1.OnKeyDown := ControlList1KeyDown;
  //SearchFilterBox.TextHint := 'Filter activity log...';
  SearchFilterBox.OnChange := SearchFilterBoxChange;
  pnToolbar.Alignment := taLeftJustify;
  ApplyFilter;
  ApplyTheme;
end;

destructor TLogControl.Destroy;
begin
  FVisibleEntryIndexes.Free;
  FEntries.Free;
  inherited;
end;

procedure TLogControl.Add(const AMessage: string; AEntryType: TLogEntryType);
var
  LEntry: TLogEntry;
begin
  LEntry.Timestamp := Now;
  LEntry.Message := AMessage;
  LEntry.EntryType := AEntryType;
  Add(LEntry);
end;

procedure TLogControl.Add(const AEntry: TLogEntry);
var
  LEntry: TLogEntry;
begin
  LEntry := AEntry;
  LEntry.Message := StringReplace(LEntry.Message, #13, ' ', [rfReplaceAll]);
  LEntry.Message := StringReplace(LEntry.Message, #10, ' ', [rfReplaceAll]);
  FEntries.Add(LEntry);
  while FEntries.Count > cMaximumRetainedLogEntries do
    FEntries.Delete(0);

  ApplyFilter;
  if not FUsingFilteredIndexes or
    ((FVisibleEntryIndexes.Count > 0) and
     (FVisibleEntryIndexes.Last = FEntries.Count - 1)) then
    ControlList1.ItemIndex := ControlList1.ItemCount - 1;
end;

procedure TLogControl.ApplyTheme;
begin
  var LTheme := TExplorerTheme.ActiveTheme;
  pnToolbar.StyleElements := pnToolbar.StyleElements - [seClient];
  pnToolbar.Color := LTheme.BackgroundColor;
  SearchFilterBox.Font.Color := LTheme.TextColor;
  lblFilterMatches.Font.Color := LTheme.InactiveText;
end;

procedure TLogControl.Clear;
begin
  FEntries.Clear;
  ApplyFilter;
end;

procedure TLogControl.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  ApplyTheme;
end;

procedure TLogControl.ControlList1BeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
const
  cTextPadding = 8;
  cTimestampColumnWidth = 92;
  cStatusColumnWidth = 78;
var
  LEntryIndex: Integer;
  LEntry: TLogEntry;
  LTimestampText: string;
  LStatusText: string;
  LTimestampRect: TRect;
  LStatusRect: TRect;
  LMessageRect: TRect;
  LFillColor: TColor;
  LSelected: Boolean;
  LBrushStyle: TBrushStyle;
begin
  LEntryIndex := VisibleEntryIndex(AIndex);
  if LEntryIndex < 0 then
    Exit;

  LSelected := odSelected in AState;
  if LSelected then
  begin
    LFillColor := ColorBlendRGB(TExplorerTheme.ActiveTheme.SelectionColor, TExplorerTheme.ActiveTheme.BackgroundColor, 0.9);
    if IsWindows11 then
      DrawSelectionBar(ACanvas, ARect, LFillColor, TExplorerTheme.ActiveTheme.SelectionColor)
    else
    begin
      ACanvas.Brush.Color := LFillColor;
      ACanvas.FillRect(ARect);

      LFillColor := TExplorerTheme.ActiveTheme.SelectionColor;
      ACanvas.Brush.Color := LFillColor;
      ACanvas.FrameRect(ARect);
    end;
  end
  else if (odHotLight in AState) then
  begin
    LFillColor := ColorBlendRGB(TExplorerTheme.ActiveTheme.SelectionColor, TExplorerTheme.ActiveTheme.BackgroundColor, 0.95);
    ACanvas.Brush.Color := LFillColor;
    ACanvas.FillRect(ARect);
  end;

  LEntry := FEntries[LEntryIndex];
  LTimestampText := FormatDateTime('hh:nn:ss.zzz', LEntry.Timestamp);
  LStatusText := EntryTypeText(LEntry.EntryType);
  LTimestampRect := ARect;
  LTimestampRect.Left := LTimestampRect.Left + cTextPadding;
  LTimestampRect.Right := LTimestampRect.Left + cTimestampColumnWidth;
  LStatusRect := ARect;
  LStatusRect.Left := LTimestampRect.Right;
  LStatusRect.Right := LStatusRect.Left + cStatusColumnWidth;
  LMessageRect := ARect;
  LMessageRect.Left := LStatusRect.Right;
  LMessageRect.Right := LMessageRect.Right - cTextPadding;
  if LMessageRect.Right < LMessageRect.Left then
    LMessageRect.Right := LMessageRect.Left;

  ACanvas.Font.Name := TExplorerTheme.FontName;
  ACanvas.Font.Size := TExplorerTheme.FontSize;
  if LSelected then
    ACanvas.Font.Color := TExplorerTheme.ActiveTheme.SelectionColor
  else
    ACanvas.Font.Color := EntryTypeColor(LEntry.EntryType);

  LBrushStyle := ACanvas.Brush.Style;
  ACanvas.Brush.Style := bsClear;
  try
    ACanvas.TextRect(LTimestampRect, LTimestampText,
      [tfVerticalCenter, tfSingleLine, tfEndEllipsis, tfNoPrefix]);
    ACanvas.TextRect(LStatusRect, LStatusText,
      [tfVerticalCenter, tfSingleLine, tfEndEllipsis, tfNoPrefix]);
    ACanvas.TextRect(LMessageRect, LEntry.Message,
      [tfVerticalCenter, tfSingleLine, tfEndEllipsis, tfNoPrefix]);
    DrawFilterMatches(ACanvas, LTimestampRect, LTimestampText);
    DrawFilterMatches(ACanvas, LStatusRect, LStatusText);
    DrawFilterMatches(ACanvas, LMessageRect, LEntry.Message);
  finally
    ACanvas.Brush.Style := LBrushStyle;
  end;
end;

procedure TLogControl.ControlList1DblClick(Sender: TObject);
begin
  PostMessage(Handle, cWmLogFilterItemDblClick, 0, 0);
end;

procedure TLogControl.WMLogFilterItemDblClick(var AMessage: TMessage);
begin
  if not FUsingFilteredIndexes then
    Exit;

  var LEntryIndex := VisibleEntryIndex(ControlList1.ItemIndex);
  if LEntryIndex < 0 then
    Exit;

  SearchFilterBox.Text := '';
  ControlList1.ItemIndex := LEntryIndex;
end;

procedure TLogControl.ControlList1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ssCtrl in Shift then
    case Key of
      Ord('A'):
        begin
          ControlList1.SelectAll;
          Key := 0;
        end;
      Ord('C'):
        begin
          CopySelectedItemsToClipboard;
          Key := 0;
        end;
    end;
end;

procedure TLogControl.CopySelectedItemsToClipboard;
begin
  var LText := TStringBuilder.Create;
  try
    for var LIndex in ControlList1.GetSelectedEnumerator do
    begin
      if LText.Length > 0 then
        LText.AppendLine;
      var LEntryIndex := VisibleEntryIndex(LIndex);
      if LEntryIndex >= 0 then
        LText.Append(EntryText(FEntries[LEntryIndex]));
    end;
    var LItemEntryIndex := VisibleEntryIndex(ControlList1.ItemIndex);
    if (LText.Length = 0) and (LItemEntryIndex >= 0) then
      LText.Append(EntryText(FEntries[LItemEntryIndex]));
    if LText.Length > 0 then
      Clipboard.AsText := LText.ToString;
  finally
    LText.Free;
  end;
end;

procedure TLogControl.DrawFilterMatches(ACanvas: TCanvas; const ARect: TRect;
  const AText: string);
begin
  var LFilterText := Trim(SearchFilterBox.Text);
  if LFilterText = '' then
    Exit;

  var LUpperText := UpperCase(AText);
  var LUpperFilter := UpperCase(LFilterText);
  var LSearchIndex := 1;
  var LMatchIndex := PosEx(LUpperFilter, LUpperText, LSearchIndex);
  if LMatchIndex = 0 then
    Exit;

  var LOriginalPenColor := ACanvas.Pen.Color;
  var LOriginalPenWidth := ACanvas.Pen.Width;
  try
    ACanvas.Pen.Color := TExplorerTheme.ActiveTheme.TypeColor;
    ACanvas.Pen.Width := 1;
    while LMatchIndex > 0 do
    begin
      var LLeft := ARect.Left + ACanvas.TextWidth(Copy(AText, 1,
        LMatchIndex - 1));
      var LRight := LLeft + ACanvas.TextWidth(Copy(AText, LMatchIndex,
        Length(LFilterText)));
      if LLeft < ARect.Right then
      begin
        LRight := Min(LRight, ARect.Right);
        var LY := ARect.Top + ((ARect.Height + ACanvas.TextHeight(AText)) div 2);
        ACanvas.MoveTo(LLeft, LY);
        ACanvas.LineTo(LRight, LY);
      end;
      LSearchIndex := LMatchIndex + Length(LFilterText);
      LMatchIndex := PosEx(LUpperFilter, LUpperText, LSearchIndex);
    end;
  finally
    ACanvas.Pen.Color := LOriginalPenColor;
    ACanvas.Pen.Width := LOriginalPenWidth;
  end;
end;

function TLogControl.EntryTypeColor(AEntryType: TLogEntryType): TColor;
begin
  var LStyle := StyleServices;
  case AEntryType of
    letSuccess:
      Result := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), clWebGreen, 0.5);
    letWarning:
      Result := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), clWebOrange, 0.5);
    letError:
      Result := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), clWebRed, 0.5);
    letProfile:
      Result := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), clWebBlue, 0.5);
  else
    Result := TExplorerTheme.ActiveTheme.TextColor
  end;
end;

function TLogControl.EntryText(const AEntry: TLogEntry): string;
begin
  Result := Format('%s'#9'%s'#9'%s', [
    FormatDateTime('hh:nn:ss.zzz', AEntry.Timestamp),
    EntryTypeText(AEntry.EntryType), AEntry.Message]);
end;

function TLogControl.EntryTypeText(AEntryType: TLogEntryType): string;
begin
  case AEntryType of
    letSuccess:
      Result := 'SUCCESS';
    letWarning:
      Result := 'WARNING';
    letError:
      Result := 'ERROR';
    letProfile:
      Result := 'PROFILE';
  else
    Result := 'INFO';
  end;
end;

procedure TLogControl.ApplyFilter;
begin
  var LFilterText := Trim(SearchFilterBox.Text);
  FVisibleEntryIndexes.Clear;
  FUsingFilteredIndexes := LFilterText <> '';
  if FUsingFilteredIndexes then
    for var LIndex := 0 to FEntries.Count - 1 do
      if ContainsText(EntryText(FEntries[LIndex]), LFilterText) then
        FVisibleEntryIndexes.Add(LIndex);
  UpdateFilterMatchCount;
  UpdateControlList;
end;

procedure TLogControl.SearchFilterBoxChange(Sender: TObject);
begin
  ApplyFilter;
end;

procedure TLogControl.UpdateControlList;
begin
  if FUsingFilteredIndexes then
    ControlList1.ItemCount := FVisibleEntryIndexes.Count
  else
    ControlList1.ItemCount := FEntries.Count;
  //pnToolbar.Caption := Format('General activity (%d)', [FEntries.Count]);
  ControlList1.Invalidate;
end;

procedure TLogControl.UpdateFilterMatchCount;
begin
  if Trim(SearchFilterBox.Text) = '' then
    lblFilterMatches.Caption := Format('%s entries', [FormatFloat('#,##0',
      FEntries.Count)])
  else
    lblFilterMatches.Caption := Format('%s / %s matches', [
      FormatFloat('#,##0', FVisibleEntryIndexes.Count),
      FormatFloat('#,##0', FEntries.Count)]);
end;

function TLogControl.VisibleEntryIndex(AIndex: Integer): Integer;
begin
  Result := -1;
  if FUsingFilteredIndexes then
  begin
    if (AIndex >= 0) and (AIndex < FVisibleEntryIndexes.Count) then
      Result := FVisibleEntryIndexes[AIndex];
  end
  else if (AIndex >= 0) and (AIndex < FEntries.Count) then
    Result := AIndex;
end;

end.
