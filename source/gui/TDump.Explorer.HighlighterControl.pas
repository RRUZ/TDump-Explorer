unit TDump.Explorer.HighlighterControl;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Classes,
  System.Types,
  System.Math,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ControlList,
  Vcl.Clipbrd,
  TDump.Explorer.Highlighter, TDump.Explorer.TinyParser, Vcl.ExtCtrls,
  Vcl.WinXCtrls, Vcl.ComCtrls;

type
  THighlighterControl = class(TFrame)
    ControlList1: TControlList;
    HeaderControl1: THeaderControl;
  private
    const
      CTextPadding = 8;
      CHeaderCaptionMargin = '  ';
    var
      FHighlighter: TTinyHighlighter;
      FItems: TStringList;
      FItemParserModes: TList<Integer>;
      FColumnHeaders: TStringList;
      FColumnDataTypes: array of TTinyHighlightDataType;
      FMeasureBitmap: TBitmap;
      FAutoSizeColumns: Boolean;
      FColumnCount: Integer;
      FColumnWidths: array of Integer;
      FParserMode: TTinyParserMode;
      FThemeKind: TTinyHighlightThemeKind;
      FUpdateDepth: Integer;
      FUpdatePending: Boolean;
    function ColumnCount(const AText: string): Integer;
    function ColumnText(AItemIndex, AColumnIndex: Integer): string;
    function ColumnDataType(AColumnIndex: Integer): TTinyHighlightDataType;
    function ColumnWidth(AColumnIndex: Integer; AAvailableWidth: Integer): Integer;
    procedure ControlList1BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ControlList1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CopySelectedItemsToClipboard;
    procedure ItemsChanged(Sender: TObject);
    procedure SetAutoSizeColumns(const AValue: Boolean);
    procedure SetParserMode(const AValue: TTinyParserMode);
    procedure SetThemeKind(const AValue: TTinyHighlightThemeKind);
    procedure UpdateHeaderControl;
    procedure UpdateColumnWidths;
    procedure UpdateControlList;
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
    procedure EndUpdate;
    procedure SetColumnHeaders(const AColumns: array of string);
    procedure SetColumnDataTypes(
      const ADataTypes: array of TTinyHighlightDataType);
    procedure SetText(const AText: string);
    property Items: TStringList read FItems;
    property AutoSizeColumns: Boolean read FAutoSizeColumns
      write SetAutoSizeColumns default True;
    property ParserMode: TTinyParserMode read FParserMode write SetParserMode;
    property ThemeKind: TTinyHighlightThemeKind read FThemeKind
      write SetThemeKind;
  end;

implementation

uses
  Vcl.Themes, Vcl.GraphUtil, TDump.Explorer.UI;


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
  FAutoSizeColumns := True;
  FColumnCount := 1;
  FParserMode := tpmTDumpValues;
  FThemeKind := thtDark;
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
      LText.Append(StringReplace(StringReplace(AColumns[LColumnIndex], #13,
        ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]));
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
      LText.Append(StringReplace(StringReplace(AColumns[LColumnIndex], #13,
        ' ', [rfReplaceAll]), #10, ' ', [rfReplaceAll]));
    end;
    Add(LText.ToString, AParserMode);
  finally
    LText.Free;
  end;
end;

function THighlighterControl.ColumnCount(const AText: string): Integer;
begin
  Result := 1;
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

function THighlighterControl.ColumnWidth(AColumnIndex,
  AAvailableWidth: Integer): Integer;
begin
  if FAutoSizeColumns and (AColumnIndex >= 0) and
    (AColumnIndex < Length(FColumnWidths)) then
    Exit(FColumnWidths[AColumnIndex]);
  Result := AAvailableWidth div FColumnCount;
end;

procedure THighlighterControl.Add(const AText: string);
begin
  FItems.BeginUpdate;
  try
    FItems.Add(StringReplace(StringReplace(AText, #13, ' ', [rfReplaceAll]),
      #10, ' ', [rfReplaceAll]));
    FItemParserModes.Add(-1);
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
  FColumnHeaders.Clear;
  SetLength(FColumnDataTypes, 0);
  UpdateControlList;
end;

procedure THighlighterControl.BeginUpdate;
begin
  Inc(FUpdateDepth);
end;

procedure THighlighterControl.EndUpdate;
begin
  if FUpdateDepth = 0 then
    Exit;

  Dec(FUpdateDepth);
  if (FUpdateDepth = 0) and FUpdatePending then
    UpdateControlList;
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
  FColumnHeaders.Clear;
  SetLength(FColumnDataTypes, 0);
  FItems.BeginUpdate;
  try
    FItems.Text := AText;
    FItemParserModes.Clear;
    for var LItemIndex := 0 to FItems.Count - 1 do
      FItemParserModes.Add(-1);
  finally
    FItems.EndUpdate;
  end;
  if FItems.Count > 0 then
    ControlList1.ItemIndex := 0;
end;

procedure THighlighterControl.ControlList1BeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
var
  LFillColor: TColor;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit;

  var LStyle := StyleServices;

  if (odSelected in AState) then
  begin
    LFillColor := ColorBlendRGB(LStyle.GetSystemColor(clHighlight), LStyle.GetSystemColor(clWindow), 0.9);
    if IsWindows11 then
      DrawSelectionBar(ACanvas, ARect, LFillColor, LStyle.GetSystemColor(clHighlight))
    else
    begin
      ACanvas.Brush.Color := LFillColor;
      ACanvas.FillRect(ARect);

      LFillColor := LStyle.GetSystemColor(clHighlight);
      ACanvas.Brush.Color := LFillColor;
      ACanvas.FrameRect(ARect);
    end;
  end
  else if (odHotLight in AState) then
  begin
    LFillColor := ColorBlendRGB(LStyle.GetSystemColor(clHighlight), LStyle.GetSystemColor(clWindow), 0.95);
    ACanvas.Brush.Color := LFillColor;
    ACanvas.FillRect(ARect);
  end;


  var LTextRect := ARect;
  InflateRect(LTextRect, -CTextPadding, 0);
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 9;
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
    FHighlighter.TextRect(ACanvas, LColumnRect,
      ColumnText(AIndex, LColumnIndex), FThemeKind,
      [tfLeft, tfVerticalCenter, tfSingleLine, tfEndEllipsis, tfNoPrefix],
      LParserMode, ColumnDataType(LColumnIndex));
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

procedure THighlighterControl.SetAutoSizeColumns(const AValue: Boolean);
begin
  if FAutoSizeColumns = AValue then
    Exit;
  FAutoSizeColumns := AValue;
  UpdateControlList;
end;

procedure THighlighterControl.SetThemeKind(
  const AValue: TTinyHighlightThemeKind);
begin
  if FThemeKind = AValue then
    Exit;
  FThemeKind := AValue;
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

  FMeasureBitmap.Canvas.Font.Name := 'Segoe UI';
  FMeasureBitmap.Canvas.Font.Size := 9;
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

  var LRequiresUpdate := HeaderControl1.Sections.Count <> FColumnHeaders.Count;
  if not LRequiresUpdate then
    for var LColumnIndex := 0 to FColumnHeaders.Count - 1 do
      if (HeaderControl1.Sections[LColumnIndex].Text <> FColumnHeaders[LColumnIndex]) or
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
    HeaderControl1.Sections.Clear;
    for var LColumnIndex := 0 to FColumnHeaders.Count - 1 do
    begin
      var LSection := HeaderControl1.Sections.Add;
      LSection.Text := CHeaderCaptionMargin + FColumnHeaders[LColumnIndex];
      LSection.Width := ColumnWidth(LColumnIndex, HeaderControl1.ClientWidth);
      LSection.Style := hsText;
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
  UpdateColumnWidths;
  UpdateHeaderControl;
  ControlList1.ItemCount := FItems.Count;
  ControlList1.Invalidate;
end;

end.
