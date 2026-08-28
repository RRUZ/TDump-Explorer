unit TDump.Explorer.HighlighterControl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.StrUtils,
  System.Types, System.UITypes, System.Math, System.Generics.Collections, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ControlList, Vcl.Clipbrd,
  TDump.Explorer.Highlighter, TDump.Explorer.TinyParser, Vcl.ExtCtrls, TDump.Explorer.UI,
  Vcl.WinXCtrls, Vcl.ComCtrls;

type
  THighlighterControl = class(TFrame)
    ControlList1: TControlList;
    HeaderControl1: THeaderControl;
  strict private
    const CTextPadding = 8;
    const CHeaderCaptionMargin = '  ';
   private
      FHighlighter: TTinyHighlighter;
      FItems: TStringList;
      FItemParserModes: TList<Integer>;
      FColumnHeaders: TStringList;
      FColumnDataTypes: array of TTinyHighlightDataType;
      FMeasureBitmap: TBitmap;
      FAutoSizeColumns: Boolean;
      FUseColumnMode: Boolean;
      FShowLineNumbers: Boolean;
      FColumnCount: Integer;
      FColumnWidths: array of Integer;
      FParserMode: TTinyParserMode;
      FThemeKind: TExplorerThemeKind;
      FUseEndEllipsis: Boolean;
      FHighlightColor: TColor;
      FMatchColor: TColor;
      FHighlightedItems: TList<Integer>;
      FLineNumbers: TList<Integer>;
      FFilterText: string;
      FUpdateDepth: Integer;
      FUpdatePending: Boolean;
      FRestoreItemIndex: Integer;
      FRestoreItemIndexPending: Boolean;
    procedure SetMatchColor(const AValue: TColor);
    function ColumnCount(const AText: string): Integer;
    function ColumnText(AItemIndex, AColumnIndex: Integer): string;
    function ColumnDataType(AColumnIndex: Integer): TTinyHighlightDataType;
    function ColumnWidth(AColumnIndex: Integer; AAvailableWidth: Integer): Integer;
    function DisplayLineNumber(AItemIndex: Integer): Integer;
    procedure DrawFilterMatches(ACanvas: TCanvas; const ARect: TRect;
      const AText: string);
    function LineNumberGutterWidth: Integer;
    procedure ControlList1BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ControlList1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CopySelectedItemsToClipboard;
    procedure ItemsChanged(Sender: TObject);
    procedure SetAutoSizeColumns(const AValue: Boolean);
    procedure SetUseColumnMode(const AValue: Boolean);
    procedure SetShowLineNumbers(const AValue: Boolean);
    procedure SetParserMode(const AValue: TTinyParserMode);
    procedure SetThemeKind(const AValue: TExplorerThemeKind);
    procedure SetUseEndEllipsis(const AValue: Boolean);
    procedure SetHighlightColor(const AValue: TColor);
    procedure UpdateHeaderControl;
    procedure UpdateColumnWidths;
    procedure UpdateControlList;
  protected
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Add(const AText: string); overload;
    procedure Add(const AText: string; AParserMode: TTinyParserMode); overload;
    procedure AddColumns(const AColumns: array of string); overload;
    procedure AddColumns(const AColumns: array of string;
      AParserMode: TTinyParserMode); overload;
    procedure BeginUpdate;
    procedure Clear;
    procedure ClearHighlightedItems;
    procedure EndUpdate;
    procedure SetColumnHeaders(const AColumns: array of string);
    procedure SetColumnDataTypes(
      const ADataTypes: array of TTinyHighlightDataType);
    procedure SetItemParserMode(AItemIndex: Integer;
      AParserMode: TTinyParserMode);
    procedure SetLineNumber(AItemIndex, ALineNumber: Integer);
    procedure SetFilterText(const AValue: string);
    procedure SetText(const AText: string);
    procedure SetHighlightedItems(const AItemIndexes: array of Integer);
    procedure SetHighlightedRange(AStartItemIndex, AEndItemIndex: Integer);
    procedure SelectItem(AItemIndex: Integer);
    procedure ScrollItemToTop(AItemIndex: Integer);
    property Items: TStringList read FItems;
    property AutoSizeColumns: Boolean read FAutoSizeColumns
      write SetAutoSizeColumns default True;
    property UseColumnMode: Boolean read FUseColumnMode
      write SetUseColumnMode default True;
    property ShowLineNumbers: Boolean read FShowLineNumbers
      write SetShowLineNumbers default False;
    property ParserMode: TTinyParserMode read FParserMode write SetParserMode;
    property ThemeKind: TExplorerThemeKind read FThemeKind
      write SetThemeKind;
    property UseEndEllipsis: Boolean read FUseEndEllipsis
      write SetUseEndEllipsis default True;
    property HighlightColor: TColor read FHighlightColor write SetHighlightColor;
    property MatchColor: TColor read FMatchColor write SetMatchColor;
    property FilterText: string read FFilterText write SetFilterText;
  end;

implementation

uses
  Vcl.Themes, Vcl.GraphUtil;

{$R *.dfm}

constructor THighlighterControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHighlighter := TTinyHighlighter.Create;
  FItems := TStringList.Create;
  FItems.OnChange := ItemsChanged;
  FItemParserModes := TList<Integer>.Create;
  FColumnHeaders := TStringList.Create;
  FMeasureBitmap := TBitmap.Create;
  FHighlightedItems := TList<Integer>.Create;
  FLineNumbers := TList<Integer>.Create;
  FAutoSizeColumns := True;
  FUseColumnMode := True;
  FShowLineNumbers := False;
  FColumnCount := 1;
  FParserMode := tpmTDumpValues;
  FThemeKind := thtDark;
  FUseEndEllipsis := True;

  FHighlightColor := ColorBlendRGB(clWhite, TExplorerTheme.ActiveTheme.BackgroundColor, 0.95);
  FMatchColor := TExplorerTheme.ActiveTheme.TypeColor;
  HeaderControl1.Align := alTop;
  HeaderControl1.Visible := False;
  ControlList1.MultiSelect := True;
  ControlList1.OnBeforeDrawItem := ControlList1BeforeDrawItem;
  ControlList1.OnKeyDown := ControlList1KeyDown;
  UpdateControlList;
end;

destructor THighlighterControl.Destroy;
begin
  FMeasureBitmap.Free;
  FItemParserModes.Free;
  FLineNumbers.Free;
  FHighlightedItems.Free;
  FColumnHeaders.Free;
  FItems.Free;
  FHighlighter.Free;
  inherited;
end;

procedure THighlighterControl.AddColumns(const AColumns: array of string);
begin
  var LText := TStringBuilder.Create;
  try
    for var LColumnIndex := 0 to High(AColumns) do
    begin
      if LColumnIndex > 0 then
        LText.Append(#9);
      LText.Append(StringReplace(StringReplace(StringReplace(AColumns[LColumnIndex],
        #13, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]), #9, ' ',
        [rfReplaceAll]));
    end;
    Add(LText.ToString);
  finally
    LText.Free;
  end;
end;

procedure THighlighterControl.AddColumns(const AColumns: array of string;
  AParserMode: TTinyParserMode);
begin
  var LText := TStringBuilder.Create;
  try
    for var LColumnIndex := 0 to High(AColumns) do
    begin
      if LColumnIndex > 0 then
        LText.Append(#9);
      LText.Append(StringReplace(StringReplace(StringReplace(AColumns[LColumnIndex],
        #13, ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]), #9, ' ',
        [rfReplaceAll]));
    end;
    Add(LText.ToString, AParserMode);
  finally
    LText.Free;
  end;
end;

function THighlighterControl.ColumnCount(const AText: string): Integer;
begin
  Result := 1;
  if not FUseColumnMode then
    Exit;
  for var LCharacter in AText do
    if LCharacter = #9 then
      Inc(Result);
end;

function THighlighterControl.ColumnText(AItemIndex,
  AColumnIndex: Integer): string;
begin
  Result := '';
  if (AItemIndex < 0) or (AItemIndex >= FItems.Count) or
    (AColumnIndex < 0) then
    Exit;

  if not FUseColumnMode then
  begin
    if AColumnIndex = 0 then
      Result := FItems[AItemIndex];
    Exit;
  end;

  var LStartIndex := 1;
  var LColumn := 0;
  var LText := FItems[AItemIndex];
  for var LIndex := 1 to Length(LText) + 1 do
    if (LIndex > Length(LText)) or (LText[LIndex] = #9) then
    begin
      if LColumn = AColumnIndex then
        Exit(Copy(LText, LStartIndex, LIndex - LStartIndex));
      Inc(LColumn);
      LStartIndex := LIndex + 1;
    end;
end;

function THighlighterControl.ColumnDataType(
  AColumnIndex: Integer): TTinyHighlightDataType;
begin
  if (AColumnIndex >= 0) and (AColumnIndex < Length(FColumnDataTypes)) then
    Exit(FColumnDataTypes[AColumnIndex]);
  Result := thdtAuto;
end;

function THighlighterControl.DisplayLineNumber(AItemIndex: Integer): Integer;
begin
  if (AItemIndex >= 0) and (AItemIndex < FLineNumbers.Count) and
    (FLineNumbers[AItemIndex] >= 0) then
    Exit(FLineNumbers[AItemIndex]);
  Result := AItemIndex;
end;

procedure THighlighterControl.DrawFilterMatches(ACanvas: TCanvas;
  const ARect: TRect; const AText: string);
begin
  if FFilterText = '' then
    Exit;

  var LUpperText := UpperCase(AText);
  var LUpperFilter := UpperCase(FFilterText);
  var LSearchIndex := 1;
  var LMatchIndex := PosEx(LUpperFilter, LUpperText, LSearchIndex);
  if LMatchIndex = 0 then
    Exit;

  var LOriginalPenColor := ACanvas.Pen.Color;
  var LOriginalPenWidth := ACanvas.Pen.Width;
  try
    ACanvas.Pen.Color := FMatchColor;
    ACanvas.Pen.Width := 1;
    while LMatchIndex > 0 do
    begin
      var LLeft := ARect.Left + ACanvas.TextWidth(Copy(AText, 1,
        LMatchIndex - 1));
      var LRight := LLeft + ACanvas.TextWidth(Copy(AText, LMatchIndex,
        Length(FFilterText)));
      if LLeft < ARect.Right then
      begin
        LRight := Min(LRight, ARect.Right);
        var LY := ARect.Top + ((ARect.Height + ACanvas.TextHeight(AText)) div 2);
        ACanvas.MoveTo(LLeft, LY);
        ACanvas.LineTo(LRight, LY);
      end;
      LSearchIndex := LMatchIndex + Length(FFilterText);
      LMatchIndex := PosEx(LUpperFilter, LUpperText, LSearchIndex);
    end;
  finally
    ACanvas.Pen.Color := LOriginalPenColor;
    ACanvas.Pen.Width := LOriginalPenWidth;
  end;
end;

function THighlighterControl.ColumnWidth(AColumnIndex,
  AAvailableWidth: Integer): Integer;
begin
  if FAutoSizeColumns and (AColumnIndex >= 0) and
    (AColumnIndex < Length(FColumnWidths)) then
    Exit(FColumnWidths[AColumnIndex]);
  Result := AAvailableWidth div FColumnCount;
end;

function THighlighterControl.LineNumberGutterWidth: Integer;
begin
  Result := 0;
  if not FShowLineNumbers then
    Exit;
  FMeasureBitmap.Canvas.Font.Assign(Font);
  Result := FMeasureBitmap.Canvas.TextWidth('00000000:') + (CTextPadding * 2);
end;

procedure THighlighterControl.Add(const AText: string);
begin
  FItems.BeginUpdate;
  try
    FItems.Add(StringReplace(StringReplace(AText, #13, ' ', [rfReplaceAll]),
      #10, ' ', [rfReplaceAll]));
    FItemParserModes.Add(-1);
    FLineNumbers.Add(-1);
  finally
    FItems.EndUpdate;
  end;
  if FItems.Count = 1 then
    ControlList1.ItemIndex := 0;
end;

procedure THighlighterControl.Add(const AText: string;
  AParserMode: TTinyParserMode);
begin
  FItems.BeginUpdate;
  try
    FItems.Add(StringReplace(StringReplace(AText, #13, ' ', [rfReplaceAll]),
      #10, ' ', [rfReplaceAll]));
    FItemParserModes.Add(Ord(AParserMode));
    FLineNumbers.Add(-1);
  finally
    FItems.EndUpdate;
  end;
  if FItems.Count = 1 then
    ControlList1.ItemIndex := 0;
end;

procedure THighlighterControl.Clear;
begin
  ControlList1.ItemIndex := -1;
  FItems.Clear;
  FItemParserModes.Clear;
  FLineNumbers.Clear;
  FColumnHeaders.Clear;
  SetLength(FColumnDataTypes, 0);
  UpdateControlList;
end;

procedure THighlighterControl.BeginUpdate;
begin
  if FUpdateDepth = 0 then
  begin
    FRestoreItemIndex := ControlList1.ItemIndex;
    FRestoreItemIndexPending := True;
  end;
  Inc(FUpdateDepth);
end;

procedure THighlighterControl.EndUpdate;
begin
  if FUpdateDepth = 0 then
    Exit;

  Dec(FUpdateDepth);
  if FUpdateDepth <> 0 then
    Exit;

  if FUpdatePending then
    UpdateControlList;
  if FRestoreItemIndexPending then
  begin
    if FItems.Count = 0 then
      ControlList1.ItemIndex := -1
    else if FRestoreItemIndex >= 0 then
      ControlList1.ItemIndex := Min(FRestoreItemIndex, FItems.Count - 1)
    else if ControlList1.ItemIndex < 0 then
      ControlList1.ItemIndex := 0;
    FRestoreItemIndexPending := False;
  end;
end;

procedure THighlighterControl.SetColumnHeaders(const AColumns: array of string);
begin
  FColumnHeaders.Clear;
  for var LColumn in AColumns do
    FColumnHeaders.Add(StringReplace(StringReplace(LColumn, #13, ' ',
      [rfReplaceAll]), #10, ' ', [rfReplaceAll]));
  SetLength(FColumnDataTypes, FColumnHeaders.Count);
  for var LColumnIndex := 0 to High(FColumnDataTypes) do
    FColumnDataTypes[LColumnIndex] := thdtAuto;
  UpdateControlList;
end;

procedure THighlighterControl.SetColumnDataTypes(
  const ADataTypes: array of TTinyHighlightDataType);
begin
  SetLength(FColumnDataTypes, FColumnHeaders.Count);
  for var LColumnIndex := 0 to High(FColumnDataTypes) do
  begin
    if LColumnIndex <= High(ADataTypes) then
      FColumnDataTypes[LColumnIndex] := ADataTypes[LColumnIndex]
    else
      FColumnDataTypes[LColumnIndex] := thdtAuto;
  end;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetText(const AText: string);
begin
  var LPreviousItemIndex := ControlList1.ItemIndex;
  ClearHighlightedItems;
  FColumnHeaders.Clear;
  SetLength(FColumnDataTypes, 0);
  FItems.BeginUpdate;
  try
    FItems.Text := AText;
    FItemParserModes.Clear;
    FLineNumbers.Clear;
    for var LItemIndex := 0 to FItems.Count - 1 do
    begin
      FItemParserModes.Add(-1);
      FLineNumbers.Add(-1);
    end;
  finally
    FItems.EndUpdate;
  end;
  if FItems.Count > 0 then
  begin
    if LPreviousItemIndex >= 0 then
      ControlList1.ItemIndex := Min(LPreviousItemIndex, FItems.Count - 1)
    else
      ControlList1.ItemIndex := 0;
  end;
end;

procedure THighlighterControl.SetItemParserMode(AItemIndex: Integer;
  AParserMode: TTinyParserMode);
begin
  if (AItemIndex < 0) or (AItemIndex >= FItemParserModes.Count) or
    (FItemParserModes[AItemIndex] = Ord(AParserMode)) then
    Exit;
  FItemParserModes[AItemIndex] := Ord(AParserMode);
  if FUpdateDepth > 0 then
    FUpdatePending := True
  else
    ControlList1.Invalidate;
end;

procedure THighlighterControl.SetLineNumber(AItemIndex, ALineNumber: Integer);
begin
  if (AItemIndex < 0) or (AItemIndex >= FLineNumbers.Count) or
    (FLineNumbers[AItemIndex] = ALineNumber) then
    Exit;
  FLineNumbers[AItemIndex] := ALineNumber;
  if FShowLineNumbers then
    ControlList1.Invalidate;
end;

procedure THighlighterControl.SetMatchColor(const AValue: TColor);
begin
  if FMatchColor = AValue then
    Exit;
  FMatchColor := AValue;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetFilterText(const AValue: string);
begin
  var LFilterText := Trim(AValue);
  if FFilterText = LFilterText then
    Exit;
  FFilterText := LFilterText;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.ClearHighlightedItems;
begin
  if FHighlightedItems.Count = 0 then
    Exit;
  FHighlightedItems.Clear;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetHighlightedItems(
  const AItemIndexes: array of Integer);
begin
  FHighlightedItems.Clear;
  for var LItemIndex in AItemIndexes do
    if (LItemIndex >= 0) and (LItemIndex < FItems.Count) and
      not FHighlightedItems.Contains(LItemIndex) then
      FHighlightedItems.Add(LItemIndex);
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetHighlightedRange(AStartItemIndex,
  AEndItemIndex: Integer);
begin
  FHighlightedItems.Clear;
  AStartItemIndex := Max(0, AStartItemIndex);
  AEndItemIndex := Min(FItems.Count - 1, AEndItemIndex);
  if AEndItemIndex < AStartItemIndex then
  begin
    ControlList1.Invalidate;
    Exit;
  end;

  for var LItemIndex := AStartItemIndex to AEndItemIndex do
    FHighlightedItems.Add(LItemIndex);
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SelectItem(AItemIndex: Integer);
begin
  if FItems.Count = 0 then
    ControlList1.ItemIndex := -1
  else
    ControlList1.ItemIndex := EnsureRange(AItemIndex, 0, FItems.Count - 1);
end;

procedure THighlighterControl.ScrollItemToTop(AItemIndex: Integer);
var
  LScrollInfo: TScrollInfo;
begin
  if (AItemIndex < 0) or (AItemIndex >= FItems.Count) then
    Exit;

  ControlList1.ItemIndex := AItemIndex;
  if not ControlList1.HandleAllocated then
    Exit;

  ZeroMemory(@LScrollInfo, SizeOf(LScrollInfo));
  LScrollInfo.cbSize := SizeOf(LScrollInfo);
  LScrollInfo.fMask := SIF_POS;
  LScrollInfo.nPos := AItemIndex * (ControlList1.ItemHeight +
    ControlList1.ItemMargins.Top + ControlList1.ItemMargins.Bottom);
  SetScrollInfo(ControlList1.Handle, SB_VERT, LScrollInfo, True);
  ControlList1.Perform(WM_VSCROLL,
    MakeWParam(SB_THUMBPOSITION, 0), 0);
end;

procedure THighlighterControl.ControlList1BeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
var
  LFillColor: TColor;
  LTextFormat: TTextFormat;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit;

  if FHighlightedItems.Contains(AIndex) then
  begin
    var LMarkerRect := ARect;
    //LMarkerRect.Right := Min(LMarkerRect.Right, LMarkerRect.Left + 3);
    ACanvas.Brush.Color := FHighlightColor;
    ACanvas.FillRect(LMarkerRect);
  end;

  if (odSelected in AState) then
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

  var LTextRect := ARect;
  InflateRect(LTextRect, -CTextPadding, 0);
  ACanvas.Font.Name := Font.Name;//TExplorerTheme.FontName;
  ACanvas.Font.Size := Font.Size;//TExplorerTheme.FontSize;
  if FShowLineNumbers then
  begin
    var LGutterWidth := LineNumberGutterWidth;
    var LGutterRect := ARect;
    LGutterRect.Right := Min(LGutterRect.Right, LGutterRect.Left + LGutterWidth);
    InflateRect(LGutterRect, -CTextPadding, 0);
    FHighlighter.TextRect(ACanvas, LGutterRect, IntToHex(DisplayLineNumber(AIndex), 8) + ':',
      FThemeKind, [tfRight, tfVerticalCenter, tfSingleLine, tfNoPrefix], tpmTDumpValues, thdtHexadecimal);
    LTextRect.Left := Min(LTextRect.Right, LTextRect.Left + LGutterWidth);
  end;
  var LLeft := LTextRect.Left;
  for var LColumnIndex := 0 to FColumnCount - 1 do
  begin
    var LColumnRect := LTextRect;
    LColumnRect.Left := LLeft;
    LColumnRect.Right := LLeft + ColumnWidth(LColumnIndex, LTextRect.Width);
    if LColumnIndex = FColumnCount - 1 then
      LColumnRect.Right := LTextRect.Right;
    if LColumnRect.Left >= LTextRect.Right then
      Break;
    var LParserMode := FParserMode;
    if (AIndex < FItemParserModes.Count) and
      (FItemParserModes[AIndex] >= 0) then
      LParserMode := TTinyParserMode(FItemParserModes[AIndex]);
    LTextFormat := [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix];
    if FUseEndEllipsis then
      Include(LTextFormat, tfEndEllipsis);
    FHighlighter.TextRect(ACanvas, LColumnRect, ColumnText(AIndex, LColumnIndex), FThemeKind, LTextFormat,
      LParserMode, ColumnDataType(LColumnIndex));
    DrawFilterMatches(ACanvas, LColumnRect, ColumnText(AIndex, LColumnIndex));
    LLeft := LColumnRect.Right;
  end;
end;

procedure THighlighterControl.ControlList1KeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
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

procedure THighlighterControl.CopySelectedItemsToClipboard;
begin
  var LText := TStringBuilder.Create;
  try
    for var LIndex in ControlList1.GetSelectedEnumerator do
    begin
      if LText.Length > 0 then
        LText.AppendLine;
      LText.Append(FItems[LIndex]);
    end;
    if (LText.Length = 0) and (ControlList1.ItemIndex >= 0) and
      (ControlList1.ItemIndex < FItems.Count) then
      LText.Append(FItems[ControlList1.ItemIndex]);
    if LText.Length > 0 then
      Clipboard.AsText := LText.ToString;
  finally
    LText.Free;
  end;
end;

procedure THighlighterControl.ItemsChanged(Sender: TObject);
begin
  UpdateControlList;
end;

procedure THighlighterControl.Resize;
begin
  inherited;
  if FItems <> nil then
    UpdateControlList;
end;

procedure THighlighterControl.SetAutoSizeColumns(const AValue: Boolean);
begin
  if FAutoSizeColumns = AValue then
    Exit;
  FAutoSizeColumns := AValue;
  UpdateControlList;
end;

procedure THighlighterControl.SetUseColumnMode(const AValue: Boolean);
begin
  if FUseColumnMode = AValue then
    Exit;
  FUseColumnMode := AValue;
  UpdateControlList;
end;

procedure THighlighterControl.SetShowLineNumbers(const AValue: Boolean);
begin
  if FShowLineNumbers = AValue then
    Exit;
  FShowLineNumbers := AValue;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetThemeKind(
  const AValue: TExplorerThemeKind);
begin
  if FThemeKind = AValue then
    Exit;
  FThemeKind := AValue;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetUseEndEllipsis(const AValue: Boolean);
begin
  if FUseEndEllipsis = AValue then
    Exit;
  FUseEndEllipsis := AValue;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetHighlightColor(const AValue: TColor);
begin
  if FHighlightColor = AValue then
    Exit;
  FHighlightColor := AValue;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetParserMode(const AValue: TTinyParserMode);
begin
  if FParserMode = AValue then
    Exit;
  FParserMode := AValue;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.UpdateColumnWidths;
begin
  FColumnCount := Max(1, FColumnHeaders.Count);
  for var LItem in FItems do
    FColumnCount := Max(FColumnCount, ColumnCount(LItem));

  SetLength(FColumnWidths, FColumnCount);
  if not FAutoSizeColumns then
    Exit;

  FMeasureBitmap.Canvas.Font.Name := Font.Name;//TExplorerTheme.FontName;
  FMeasureBitmap.Canvas.Font.Size := Font.Size;//TExplorerTheme.FontSize;
  for var LColumnIndex := 0 to FColumnCount - 1 do
  begin
    var LWidth := CTextPadding * 2;
    if LColumnIndex < FColumnHeaders.Count then
      LWidth := Max(LWidth, FMeasureBitmap.Canvas.TextWidth(
        FColumnHeaders[LColumnIndex]) + (CTextPadding * 2));
    for var LItemIndex := 0 to FItems.Count - 1 do
      LWidth := Max(LWidth, FMeasureBitmap.Canvas.TextWidth(
        ColumnText(LItemIndex, LColumnIndex)) + (CTextPadding * 2));
    FColumnWidths[LColumnIndex] := LWidth;
  end;
end;

procedure THighlighterControl.UpdateHeaderControl;
begin
  if FColumnHeaders.Count = 0 then
  begin
    HeaderControl1.Visible := False;
    Exit;
  end;

  var LSectionCountChanged := HeaderControl1.Sections.Count <>
    FColumnHeaders.Count;
  var LRequiresUpdate := LSectionCountChanged;
  if not LRequiresUpdate then
    for var LColumnIndex := 0 to FColumnHeaders.Count - 1 do
      if (HeaderControl1.Sections[LColumnIndex].Text <>
        CHeaderCaptionMargin + FColumnHeaders[LColumnIndex]) or
        (HeaderControl1.Sections[LColumnIndex].Width <>
          ColumnWidth(LColumnIndex, HeaderControl1.ClientWidth)) then
      begin
        LRequiresUpdate := True;
        Break;
      end;

  if not LRequiresUpdate then
  begin
    HeaderControl1.Visible := True;
    Exit;
  end;

  HeaderControl1.Perform(WM_SETREDRAW, 0, 0);
  try
    HeaderControl1.Visible := True;
    if LSectionCountChanged then
    begin
      HeaderControl1.Sections.Clear;
      for var LColumnIndex := 0 to FColumnHeaders.Count - 1 do
      begin
        var LSection := HeaderControl1.Sections.Add;
        LSection.Style := hsText;
      end;
    end;
    for var LColumnIndex := 0 to FColumnHeaders.Count - 1 do
    begin
      var LSection := HeaderControl1.Sections[LColumnIndex];
      LSection.Text := CHeaderCaptionMargin + FColumnHeaders[LColumnIndex];
      LSection.Width := ColumnWidth(LColumnIndex, HeaderControl1.ClientWidth);
    end;
  finally
    HeaderControl1.Perform(WM_SETREDRAW, 1, 0);
    HeaderControl1.Invalidate;
  end;
end;

procedure THighlighterControl.UpdateControlList;
begin
  if FUpdateDepth > 0 then
  begin
    FUpdatePending := True;
    Exit;
  end;

  FUpdatePending := False;
  while FItemParserModes.Count < FItems.Count do
    FItemParserModes.Add(-1);
  while FItemParserModes.Count > FItems.Count do
    FItemParserModes.Delete(FItemParserModes.Count - 1);
  while FLineNumbers.Count < FItems.Count do
    FLineNumbers.Add(-1);
  while FLineNumbers.Count > FItems.Count do
    FLineNumbers.Delete(FLineNumbers.Count - 1);
  UpdateColumnWidths;
  UpdateHeaderControl;
  ControlList1.ItemCount := FItems.Count;
  ControlList1.Invalidate;
end;

end.
