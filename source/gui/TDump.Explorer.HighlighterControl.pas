//**************************************************************************************************
//
// Unit TDump.Explorer.HighlighterControl
//
// Owner-drawn virtual highlighter control for text and tabular data
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
unit TDump.Explorer.HighlighterControl;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes, System.StrUtils,
  System.Types, System.UITypes, System.Math, System.Generics.Collections,
  System.Generics.Defaults, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ControlList, Vcl.Clipbrd,
  TDump.Explorer.Highlighter, TDump.Explorer.TinyParser, Vcl.ExtCtrls, TDump.Explorer.UI,
  Vcl.WinXCtrls, Vcl.ComCtrls, Vcl.ImgList, Vcl.VirtualImageList,
  TDump.Explorer.Export;

type
  // Supplies rows on demand. Implementations retain only row identifiers and
  // reconstruct text for the item currently requested by TControlList.
  IHighlighterRowProvider = interface
    ['{129B91EA-9AE6-4C92-B908-999797434137}']
    function GetCount: Integer;
    function GetText(AIndex: Integer): string;
    function GetImageName(AIndex: Integer): string;
    function GetParserMode(AIndex: Integer): Integer;
    function GetLineNumber(AIndex: Integer): Integer;
  end;

  THighlighterColumnLayout = class
  public
    SortColumn: Integer;
    SortAscending: Boolean;
    ColumnWidths: TArray<Integer>;
  end;

  THighlighterControl = class(TFrame)
    ControlList1: TControlList;
    HeaderControl1: THeaderControl;
  strict private
    const CTextPadding = 8;
    const CHeaderSortGlyphWidth = 18;
   private
      FHighlighter: TTinyHighlighter;
      FItems: TStringList;
      FItemProvider: IHighlighterRowProvider;
      FItemImageNames: TStringList;
      FItemParserModes: TList<Integer>;
      FColumnHeaders: TStringList;
      FColumnDataTypes: array of TTinyHighlightDataType;
      FColumnParserModes: array of Integer;
      FColumnWidthWeights: array of Integer;
      FUserColumnWidths: array of Integer;
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
      FInactiveItems: TList<Integer>;
      FHighlightedRangeStart: Integer;
      FHighlightedRangeEnd: Integer;
      FLineNumbers: TList<Integer>;
      FFilterText: string;
      FUpdateDepth: Integer;
      FUpdatePending: Boolean;
      FRestoreItemIndex: Integer;
      FRestoreItemIndexPending: Boolean;
      FImages: TCustomImageList;
      FOnItemClick: TNotifyEvent;
      FSortIndexes: TList<Integer>;
      FColumnLayouts: TObjectDictionary<string, THighlighterColumnLayout>;
      FColumnLayoutKey: string;
      FViewLayoutId: string;
      FSortColumn: Integer;
      FSortAscending: Boolean;
      FSortEnabled: Boolean;
      FUpdatingHeader: Boolean;
      FContextPopupEnabled: Boolean;
      FContextPopupMenu: TForm;
      FHeaderPopupMenu: TForm;
      FContextPopupImages: TVirtualImageList;
    procedure AddItem(const AText, AImageName: string; AParserMode: Integer);
    function ItemCount: Integer;
    function ItemText(AItemIndex: Integer): string;
    function ItemParserMode(AItemIndex: Integer): Integer;
    function IsItemHighlighted(AItemIndex: Integer): Boolean;
    function IsItemInactive(AItemIndex: Integer): Boolean;
    procedure SetMatchColor(const AValue: TColor);
    procedure SetImages(const AValue: TCustomImageList);
    function ColumnCount(const AText: string): Integer;
    function ColumnText(AItemIndex, AColumnIndex: Integer): string;
    function SourceItemText(ASourceItemIndex: Integer): string;
    function SourceColumnText(ASourceItemIndex, AColumnIndex: Integer): string;
    function ColumnDataType(AColumnIndex: Integer): TTinyHighlightDataType;
    function ColumnParserMode(AColumnIndex: Integer;
      ADefaultMode: TTinyParserMode): TTinyParserMode;
    function ColumnWidth(AColumnIndex: Integer; AAvailableWidth: Integer): Integer;
    function HeaderSectionWidth(AColumnIndex: Integer): Integer;
    function DisplayLineNumber(AItemIndex: Integer): Integer;
    function SourceItemIndex(AItemIndex: Integer): Integer;
    function HeaderCaption(AColumnIndex: Integer): string;
    function HeaderLayoutKey: string;
    function CompareSourceItems(ALeftSourceIndex,
      ARightSourceIndex: Integer): Integer;
    function CompareColumnValues(const ALeft, ARight: string;
      ADataType: TTinyHighlightDataType): Integer;
    procedure ApplySort;
    procedure LoadColumnLayout;
    procedure SaveColumnLayout;
    procedure DrawFilterMatches(ACanvas: TCanvas; const ARect: TRect;
      const AText: string);
    function LineNumberGutterWidth: Integer;
    procedure ControlList1BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ControlList1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ControlList1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ControlList1Click(Sender: TObject);
    procedure HeaderControlSectionClick(HeaderControl: THeaderControl;
      Section: THeaderSection);
    procedure HeaderControlSectionResize(HeaderControl: THeaderControl;
      Section: THeaderSection);
    procedure HeaderControlDrawSection(HeaderControl: THeaderControl;
      Section: THeaderSection; const ARect: TRect; Pressed: Boolean);
    procedure HeaderControlMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ControlList1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ContextPopupMenuItemClick(Sender: TObject; AItemIndex: Integer);
    procedure HeaderPopupMenuItemClick(Sender: TObject; AItemIndex: Integer);
    procedure ShowContextPopupMenu(const APoint: TPoint);
    procedure ShowHeaderPopupMenu(const APoint: TPoint);
    procedure EnsureContextPopupImages;
    function ExportHeaders: TArray<string>;
    function ExportSelectedItems(AFormat: TDumpExportFormat): string;
    procedure CopySelectedItemsToClipboard(AFormat: TDumpExportFormat);
    procedure ItemsChanged(Sender: TObject);
    procedure SetAutoSizeColumns(const AValue: Boolean);
    procedure SetUseColumnMode(const AValue: Boolean);
    procedure SetShowLineNumbers(const AValue: Boolean);
    procedure SetParserMode(const AValue: TTinyParserMode);
    procedure SetThemeKind(const AValue: TExplorerThemeKind);
    procedure SetUseEndEllipsis(const AValue: Boolean);
    procedure SetHighlightColor(const AValue: TColor);
    procedure SetSortEnabled(const AValue: Boolean);
    procedure UpdateHeaderControl;
    procedure UpdateColumnWidths;
    procedure UpdateControlList;
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure ApplyTheme;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Add(const AText: string); overload;
    procedure Add(const AText, AImageName: string); overload;
    procedure Add(const AText: string; AParserMode: TTinyParserMode); overload;
    procedure AddColumns(const AColumns: array of string); overload;
    procedure AddColumns(const AColumns: array of string;
      AParserMode: TTinyParserMode); overload;
    procedure BeginUpdate;
    procedure Clear;
    procedure ClearHighlightedItems;
    procedure ResetSortOrder;
    procedure AutoAdjustColumnWidths;
    procedure CopyToClipboard; overload;
    procedure CopyToClipboard(AFormat: TDumpExportFormat); overload;
    procedure EndUpdate;
    // Resets the shared detail control for a tabular view.  The next update
    // transaction applies the pending layout, avoiding intermediate redraws.
    procedure PrepareGridPresentation;
    procedure SetColumnHeaders(const AColumns: array of string);
    procedure SetViewLayoutId(const AValue: string);
    procedure SetColumnDataTypes(
      const ADataTypes: array of TTinyHighlightDataType);
    procedure SetColumnParserModes(const AParserModes: array of TTinyParserMode);
    procedure SetColumnWidthWeights(const AWeights: array of Integer);
    procedure SetItemParserMode(AItemIndex: Integer;
      AParserMode: TTinyParserMode);
    procedure SetItemImageName(AItemIndex: Integer; const AImageName: string);
    function ItemImageName(AItemIndex: Integer): string;
    procedure SetLineNumber(AItemIndex, ALineNumber: Integer);
    procedure SetFilterText(const AValue: string);
    procedure SetText(const AText: string);
    procedure SetItemProvider(const AProvider: IHighlighterRowProvider);
    procedure SetHighlightedItems(const AItemIndexes: array of Integer);
    procedure SetInactiveItems(const AItemIndexes: array of Integer);
    procedure SetHighlightedRange(AStartItemIndex, AEndItemIndex: Integer);
    procedure SelectItem(AItemIndex: Integer);
    procedure ScrollItemToTop(AItemIndex: Integer);
    function SelectedItemLineNumber: Integer;
    property Items: TStringList read FItems;
    property Count: Integer read ItemCount;
    property Images: TCustomImageList read FImages write SetImages;
    property OnItemClick: TNotifyEvent read FOnItemClick write FOnItemClick;
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
    property SortEnabled: Boolean read FSortEnabled write SetSortEnabled
      default True;
    property ContextPopupEnabled: Boolean read FContextPopupEnabled
      write FContextPopupEnabled default True;
  end;

implementation

uses
  Vcl.Themes, Vcl.GraphUtil, TDump.Explorer.PopupMenu,
  TDump.Explorer.Resources;

{$R *.dfm}

constructor THighlighterControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHighlighter := TTinyHighlighter.Create;
  FItems := TStringList.Create;
  FItems.OnChange := ItemsChanged;
  FItemImageNames := TStringList.Create;
  FItemParserModes := TList<Integer>.Create;
  FColumnHeaders := TStringList.Create;
  FSortIndexes := TList<Integer>.Create;
  FColumnLayouts := TObjectDictionary<string, THighlighterColumnLayout>.Create([
    doOwnsValues]);
  FMeasureBitmap := TBitmap.Create;
  FHighlightedItems := TList<Integer>.Create;
  FInactiveItems := TList<Integer>.Create;
  FHighlightedRangeStart := -1;
  FHighlightedRangeEnd := -1;
  FLineNumbers := TList<Integer>.Create;
  FAutoSizeColumns := True;
  FUseColumnMode := True;
  FShowLineNumbers := False;
  FColumnCount := 1;
  FParserMode := tpmTDumpValues;
  FThemeKind := thtDark;
  FUseEndEllipsis := True;
  FSortColumn := -1;
  FSortAscending := True;
  FSortEnabled := True;
  FContextPopupEnabled := True;

  ApplyTheme;

  HeaderControl1.Align := alTop;
  // hsButtons adds HDS_BUTTONS, which is required for the native header to
  // issue the section-click notifications used for sorting.
  HeaderControl1.Style := hsButtons;
  HeaderControl1.Visible := False;
  HeaderControl1.NoSizing := False;
  HeaderControl1.OnSectionClick := HeaderControlSectionClick;
  HeaderControl1.OnSectionResize := HeaderControlSectionResize;
  HeaderControl1.OnDrawSection := HeaderControlDrawSection;
  HeaderControl1.OnMouseUp := HeaderControlMouseUp;
  ControlList1.MultiSelect := True;
  ControlList1.OnBeforeDrawItem := ControlList1BeforeDrawItem;
  ControlList1.OnKeyDown := ControlList1KeyDown;
  ControlList1.OnKeyUp := ControlList1KeyUp;
  ControlList1.OnClick := ControlList1Click;
  ControlList1.OnMouseUp := ControlList1MouseUp;
  UpdateControlList;
end;

destructor THighlighterControl.Destroy;
begin
  FContextPopupMenu.Free;
  FHeaderPopupMenu.Free;
  FContextPopupImages.Free;
  FMeasureBitmap.Free;
  FItemImageNames.Free;
  FItemParserModes.Free;
  FLineNumbers.Free;
  FInactiveItems.Free;
  FHighlightedItems.Free;
  FColumnHeaders.Free;
  FColumnLayouts.Free;
  FSortIndexes.Free;
  FItems.Free;
  FHighlighter.Free;
  inherited;
end;

procedure THighlighterControl.EnsureContextPopupImages;
begin
  if Assigned(FContextPopupImages) or not Assigned(DataModule1) then
    Exit;

  FContextPopupImages := TVirtualImageList.Create(Self);
  FContextPopupImages.Width := ScaleValue(16);
  FContextPopupImages.Height := ScaleValue(16);
  FContextPopupImages.ImageCollection := DataModule1.ImageCollection1;
  FContextPopupImages.Add('file-text_dark', 'file-text_dark');
  FContextPopupImages.Add('file-text_light', 'file-text_light');
  FContextPopupImages.Add('file-csv_dark', 'file-csv_dark');
  FContextPopupImages.Add('file-csv_light', 'file-csv_light');
  FContextPopupImages.Add('file-code_dark', 'file-code_dark');
  FContextPopupImages.Add('file-code_light', 'file-code_light');
  FContextPopupImages.Add('file-md_dark', 'file-md_dark');
  FContextPopupImages.Add('file-md_light', 'file-md_light');
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
  Result := SourceColumnText(SourceItemIndex(AItemIndex), AColumnIndex);
end;

function THighlighterControl.SourceColumnText(ASourceItemIndex,
  AColumnIndex: Integer): string;
begin
  Result := '';
  if (ASourceItemIndex < 0) or (ASourceItemIndex >= ItemCount) or
    (AColumnIndex < 0) then
    Exit;

  var LText := SourceItemText(ASourceItemIndex);
  if not FUseColumnMode then
  begin
    if AColumnIndex = 0 then
      Result := LText;
    Exit;
  end;

  var LStartIndex := 1;
  var LColumn := 0;
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

function THighlighterControl.ColumnParserMode(AColumnIndex: Integer;
  ADefaultMode: TTinyParserMode): TTinyParserMode;
begin
  Result := ADefaultMode;
  if (AColumnIndex >= 0) and (AColumnIndex < Length(FColumnParserModes)) and
    (FColumnParserModes[AColumnIndex] >= 0) then
    Result := TTinyParserMode(FColumnParserModes[AColumnIndex]);
end;

function THighlighterControl.DisplayLineNumber(AItemIndex: Integer): Integer;
begin
  AItemIndex := SourceItemIndex(AItemIndex);
  if FItemProvider <> nil then
    Exit(FItemProvider.GetLineNumber(AItemIndex));
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
  if (AColumnIndex >= 0) and (AColumnIndex < Length(FUserColumnWidths)) and
    (FUserColumnWidths[AColumnIndex] > 0) then
    Exit(FUserColumnWidths[AColumnIndex]);
  if FAutoSizeColumns and (AColumnIndex >= 0) and
    (AColumnIndex < Length(FColumnWidths)) then
    Exit(FColumnWidths[AColumnIndex]);
  if (Length(FColumnWidthWeights) = FColumnCount) and
    (AColumnIndex >= 0) and (AColumnIndex < FColumnCount) then
  begin
    var LTotalWeight := 0;
    for var LWeight in FColumnWidthWeights do
      Inc(LTotalWeight, LWeight);
    if LTotalWeight > 0 then
      Exit((AAvailableWidth * FColumnWidthWeights[AColumnIndex]) div
        LTotalWeight);
  end;
  Result := AAvailableWidth div FColumnCount;
end;

function THighlighterControl.HeaderSectionWidth(AColumnIndex: Integer): Integer;
begin
  var LAvailableWidth := ControlList1.ClientWidth;
  if LAvailableWidth <= 0 then
    LAvailableWidth := HeaderControl1.ClientWidth;
  Result := ColumnWidth(AColumnIndex, LAvailableWidth);
  if AColumnIndex <> FColumnHeaders.Count - 1 then
    Exit;

  var LUsedWidth := 0;
  for var LColumnIndex := 0 to AColumnIndex - 1 do
    Inc(LUsedWidth, ColumnWidth(LColumnIndex, LAvailableWidth));
  Result := Max(Result, LAvailableWidth - LUsedWidth);
end;

function THighlighterControl.LineNumberGutterWidth: Integer;
begin
  Result := 0;
  if not FShowLineNumbers then
    Exit;
  FMeasureBitmap.Canvas.Font.Assign(Font);
  Result := FMeasureBitmap.Canvas.TextWidth('00000000:') + (CTextPadding * 2);
end;

function THighlighterControl.SourceItemIndex(AItemIndex: Integer): Integer;
begin
  Result := AItemIndex;
  if (AItemIndex >= 0) and (AItemIndex < FSortIndexes.Count) and
    (FSortIndexes.Count = ItemCount) then
    Result := FSortIndexes[AItemIndex];
end;

function THighlighterControl.HeaderCaption(AColumnIndex: Integer): string;
begin
  Result := FColumnHeaders[AColumnIndex];
end;

function THighlighterControl.HeaderLayoutKey: string;
begin
  Result := FViewLayoutId;
  if Result = '' then
    Result := 'headers';
  for var LColumnIndex := 0 to FColumnHeaders.Count - 1 do
  begin
    Result := Result + #31;
    Result := Result + FColumnHeaders[LColumnIndex];
  end;
end;

function THighlighterControl.CompareColumnValues(const ALeft, ARight: string;
  ADataType: TTinyHighlightDataType): Integer;
var
  LLeftInteger: Int64;
  LRightInteger: Int64;
  LLeftHexadecimal: UInt64;
  LRightHexadecimal: UInt64;
  LLeftFloat: Extended;
  LRightFloat: Extended;
  LLeftDateTime: TDateTime;
  LRightDateTime: TDateTime;
  function CompareInt64(ALeftValue, ARightValue: Int64): Integer;
  begin
    if ALeftValue < ARightValue then
      Exit(-1);
    if ALeftValue > ARightValue then
      Exit(1);
    Result := 0;
  end;
  function CompareUInt64(ALeftValue, ARightValue: UInt64): Integer;
  begin
    if ALeftValue < ARightValue then
      Exit(-1);
    if ALeftValue > ARightValue then
      Exit(1);
    Result := 0;
  end;
  function CompareExtended(ALeftValue, ARightValue: Extended): Integer;
  begin
    if ALeftValue < ARightValue then
      Exit(-1);
    if ALeftValue > ARightValue then
      Exit(1);
    Result := 0;
  end;
  function TryParseHex(const AText: string; out AValue: UInt64): Boolean;
  begin
    var LValue := Trim(AText);
    if StartsText('0x', LValue) then
      Delete(LValue, 1, 2)
    else if StartsText('$', LValue) then
      Delete(LValue, 1, 1);
    if EndsText('h', LValue) then
      Delete(LValue, Length(LValue), 1);
    Result := (LValue <> '') and TryStrToUInt64('$' + LValue, AValue);
  end;
begin
  case ADataType of
    thdtInteger:
      begin
        if TryStrToInt64(Trim(ALeft), LLeftInteger) and
          TryStrToInt64(Trim(ARight), LRightInteger) then
          Exit(CompareInt64(LLeftInteger, LRightInteger));
      end;
    thdtHexadecimal:
      begin
        if TryParseHex(ALeft, LLeftHexadecimal) and
          TryParseHex(ARight, LRightHexadecimal) then
          Exit(CompareUInt64(LLeftHexadecimal, LRightHexadecimal));
      end;
    thdtFloat:
      begin
        if TryStrToFloat(Trim(ALeft), LLeftFloat) and
          TryStrToFloat(Trim(ARight), LRightFloat) then
          Exit(CompareExtended(LLeftFloat, LRightFloat));
      end;
    thdtDate, thdtTime, thdtDateTime:
      begin
        if TryStrToDateTime(Trim(ALeft), LLeftDateTime) and
          TryStrToDateTime(Trim(ARight), LRightDateTime) then
          Exit(CompareExtended(LLeftDateTime, LRightDateTime));
      end;
  end;
  Result := CompareText(ALeft, ARight);
end;

function THighlighterControl.CompareSourceItems(ALeftSourceIndex,
  ARightSourceIndex: Integer): Integer;
begin
  Result := CompareColumnValues(SourceColumnText(ALeftSourceIndex,
    FSortColumn), SourceColumnText(ARightSourceIndex, FSortColumn),
    ColumnDataType(FSortColumn));
  if not FSortAscending then
    Result := -Result;
  // Keep equal values in their source order so sort transitions are stable.
  if Result = 0 then
    Result := ALeftSourceIndex - ARightSourceIndex;
end;

procedure THighlighterControl.ApplySort;
begin
  FSortIndexes.Clear;
  if not FSortEnabled or (FSortColumn < 0) or
    (FSortColumn >= FColumnHeaders.Count) then
    Exit;

  for var LSourceIndex := 0 to ItemCount - 1 do
    FSortIndexes.Add(LSourceIndex);
  FSortIndexes.Sort(TComparer<Integer>.Construct(
    function(const ALeft, ARight: Integer): Integer
    begin
      Result := CompareSourceItems(ALeft, ARight);
    end));
end;

procedure THighlighterControl.LoadColumnLayout;
var
  LLayout: THighlighterColumnLayout;
begin
  FColumnLayoutKey := HeaderLayoutKey;
  FSortColumn := -1;
  FSortAscending := True;
  SetLength(FUserColumnWidths, FColumnHeaders.Count);
  FSortIndexes.Clear;
  if (FColumnLayoutKey = '') or not FColumnLayouts.TryGetValue(
    FColumnLayoutKey, LLayout) then
    Exit;

  if (LLayout.SortColumn >= 0) and
    (LLayout.SortColumn < FColumnHeaders.Count) then
  begin
    FSortColumn := LLayout.SortColumn;
    FSortAscending := LLayout.SortAscending;
  end;
  if Length(LLayout.ColumnWidths) = FColumnHeaders.Count then
    FUserColumnWidths := Copy(LLayout.ColumnWidths);
end;

procedure THighlighterControl.SaveColumnLayout;
var
  LLayout: THighlighterColumnLayout;
begin
  if FColumnLayoutKey = '' then
    Exit;
  if not FColumnLayouts.TryGetValue(FColumnLayoutKey, LLayout) then
  begin
    LLayout := THighlighterColumnLayout.Create;
    FColumnLayouts.Add(FColumnLayoutKey, LLayout);
  end;
  LLayout.SortColumn := FSortColumn;
  LLayout.SortAscending := FSortAscending;
  LLayout.ColumnWidths := Copy(FUserColumnWidths);
end;

procedure THighlighterControl.AddItem(const AText, AImageName: string;
  AParserMode: Integer);
begin
  FItemProvider := nil;
  FItems.BeginUpdate;
  try
    FItems.Add(StringReplace(StringReplace(AText, #13, ' ', [rfReplaceAll]),
      #10, ' ', [rfReplaceAll]));
    FItemImageNames.Add(AImageName);
    FItemParserModes.Add(AParserMode);
    FLineNumbers.Add(-1);
  finally
    FItems.EndUpdate;
  end;
  if FItems.Count = 1 then
    ControlList1.ItemIndex := 0;
end;

function THighlighterControl.ItemCount: Integer;
begin
  if FItemProvider <> nil then
    Exit(FItemProvider.GetCount);
  Result := FItems.Count;
end;

function THighlighterControl.ItemText(AItemIndex: Integer): string;
begin
  Result := SourceItemText(SourceItemIndex(AItemIndex));
end;

function THighlighterControl.SourceItemText(ASourceItemIndex: Integer): string;
begin
  if FItemProvider <> nil then
    Exit(FItemProvider.GetText(ASourceItemIndex));
  Result := FItems[ASourceItemIndex];
end;

function THighlighterControl.ItemParserMode(AItemIndex: Integer): Integer;
begin
  AItemIndex := SourceItemIndex(AItemIndex);
  if FItemProvider <> nil then
    Exit(FItemProvider.GetParserMode(AItemIndex));
  if (AItemIndex >= 0) and (AItemIndex < FItemParserModes.Count) then
    Exit(FItemParserModes[AItemIndex]);
  Result := -1;
end;

procedure THighlighterControl.ApplyTheme;
begin
  FHighlightColor := ColorBlendRGB(clWhite, TExplorerTheme.ActiveTheme.BackgroundColor, 0.95);
  FMatchColor := TExplorerTheme.ActiveTheme.TypeColor;
end;

procedure THighlighterControl.Add(const AText: string);
begin
  AddItem(AText, '', -1);
end;

procedure THighlighterControl.Add(const AText, AImageName: string);
begin
  AddItem(AText, AImageName, -1);
end;

procedure THighlighterControl.Add(const AText: string;
  AParserMode: TTinyParserMode);
begin
  AddItem(AText, '', Ord(AParserMode));
end;

procedure THighlighterControl.Clear;
begin
  SaveColumnLayout;
  ControlList1.ItemIndex := -1;
  FItemProvider := nil;
  FItems.Clear;
  FItemImageNames.Clear;
  FItemParserModes.Clear;
  FLineNumbers.Clear;
  FInactiveItems.Clear;
  FColumnHeaders.Clear;
  FSortIndexes.Clear;
  FColumnLayoutKey := '';
  FSortColumn := -1;
  FSortAscending := True;
  SetLength(FColumnDataTypes, 0);
  SetLength(FColumnParserModes, 0);
  SetLength(FColumnWidthWeights, 0);
  SetLength(FUserColumnWidths, 0);
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
    if ItemCount = 0 then
      ControlList1.ItemIndex := -1
    else if FRestoreItemIndex >= 0 then
      ControlList1.ItemIndex := Min(FRestoreItemIndex, ItemCount - 1)
    else if ControlList1.ItemIndex < 0 then
      ControlList1.ItemIndex := 0;
    FRestoreItemIndexPending := False;
  end;
end;

procedure THighlighterControl.PrepareGridPresentation;
begin
  if FUseColumnMode and FAutoSizeColumns and not FShowLineNumbers then
    Exit;

  FUseColumnMode := True;
  FAutoSizeColumns := True;
  FShowLineNumbers := False;
  FUpdatePending := True;
end;

procedure THighlighterControl.SetColumnHeaders(const AColumns: array of string);
begin
  SaveColumnLayout;
  FColumnHeaders.Clear;
  for var LColumn in AColumns do
    FColumnHeaders.Add(StringReplace(StringReplace(LColumn, #13, ' ',
      [rfReplaceAll]), #10, ' ', [rfReplaceAll]));
  SetLength(FColumnDataTypes, FColumnHeaders.Count);
  SetLength(FColumnParserModes, FColumnHeaders.Count);
  SetLength(FColumnWidthWeights, 0);
  for var LColumnIndex := 0 to High(FColumnDataTypes) do
  begin
    FColumnDataTypes[LColumnIndex] := if LColumnIndex = 0 then thdtText
      else thdtAuto;
    FColumnParserModes[LColumnIndex] := -1;
  end;
  LoadColumnLayout;
  UpdateControlList;
end;

procedure THighlighterControl.SetColumnDataTypes(
  const ADataTypes: array of TTinyHighlightDataType);
begin
  SetLength(FColumnDataTypes, Max(FColumnHeaders.Count, Length(ADataTypes)));
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
  SaveColumnLayout;
  FItemProvider := nil;
  var LPreviousItemIndex := ControlList1.ItemIndex;
  ClearHighlightedItems;
  FInactiveItems.Clear;
  FColumnHeaders.Clear;
  FSortIndexes.Clear;
  FColumnLayoutKey := '';
  FSortColumn := -1;
  FSortAscending := True;
  SetLength(FColumnDataTypes, 0);
  SetLength(FColumnParserModes, 0);
  SetLength(FColumnWidthWeights, 0);
  SetLength(FUserColumnWidths, 0);
  FItems.BeginUpdate;
  try
    FItems.Text := AText;
    FItemImageNames.Clear;
    FItemParserModes.Clear;
    FLineNumbers.Clear;
    for var LItemIndex := 0 to FItems.Count - 1 do
    begin
      FItemParserModes.Add(-1);
      FItemImageNames.Add('');
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

procedure THighlighterControl.SetItemProvider(
  const AProvider: IHighlighterRowProvider);
begin
  FItemProvider := AProvider;
  ClearHighlightedItems;
  UpdateControlList;
  if ItemCount = 0 then
    ControlList1.ItemIndex := -1
  else
    ControlList1.ItemIndex := 0;
end;

function THighlighterControl.ItemImageName(AItemIndex: Integer): string;
begin
  AItemIndex := SourceItemIndex(AItemIndex);
  if FItemProvider <> nil then
    Exit(FItemProvider.GetImageName(AItemIndex));
  Result := '';
  if (AItemIndex >= 0) and (AItemIndex < FItemImageNames.Count) then
    Result := FItemImageNames[AItemIndex];
end;

procedure THighlighterControl.SetItemImageName(AItemIndex: Integer;
  const AImageName: string);
begin
  if (AItemIndex < 0) or (AItemIndex >= FItemImageNames.Count) or
    SameText(FItemImageNames[AItemIndex], AImageName) then
    Exit;
  FItemImageNames[AItemIndex] := AImageName;
  ControlList1.Invalidate;
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
  if (FHighlightedItems.Count = 0) and (FHighlightedRangeStart < 0) then
    Exit;
  FHighlightedItems.Clear;
  FHighlightedRangeStart := -1;
  FHighlightedRangeEnd := -1;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetColumnParserModes(
  const AParserModes: array of TTinyParserMode);
begin
  SetLength(FColumnParserModes, Max(FColumnHeaders.Count,
    Length(AParserModes)));
  for var LColumnIndex := 0 to High(FColumnParserModes) do
    if LColumnIndex <= High(AParserModes) then
      FColumnParserModes[LColumnIndex] := Ord(AParserModes[LColumnIndex])
    else
      FColumnParserModes[LColumnIndex] := -1;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetColumnWidthWeights(
  const AWeights: array of Integer);
begin
  SetLength(FColumnWidthWeights, Max(FColumnHeaders.Count, Length(AWeights)));
  for var LColumnIndex := 0 to High(FColumnWidthWeights) do
    if LColumnIndex <= High(AWeights) then
      FColumnWidthWeights[LColumnIndex] := Max(0, AWeights[LColumnIndex])
    else
      FColumnWidthWeights[LColumnIndex] := 0;
  UpdateControlList;
end;

function THighlighterControl.IsItemHighlighted(AItemIndex: Integer): Boolean;
begin
  if (FHighlightedRangeStart >= 0) and
    (AItemIndex >= FHighlightedRangeStart) and
    (AItemIndex <= FHighlightedRangeEnd) then
    Exit(True);

  var LLow := 0;
  var LHigh := FHighlightedItems.Count - 1;
  while LLow <= LHigh do
  begin
    var LMiddle := LLow + ((LHigh - LLow) div 2);
    if FHighlightedItems[LMiddle] = AItemIndex then
      Exit(True);
    if FHighlightedItems[LMiddle] < AItemIndex then
      LLow := LMiddle + 1
    else
      LHigh := LMiddle - 1;
  end;
  Result := False;
end;

function THighlighterControl.IsItemInactive(AItemIndex: Integer): Boolean;
begin
  Result := FInactiveItems.Contains(AItemIndex);
end;

procedure THighlighterControl.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  ApplyTheme;
end;

procedure THighlighterControl.SetHighlightedItems(
  const AItemIndexes: array of Integer);
begin
  FHighlightedItems.Clear;
  FHighlightedRangeStart := -1;
  FHighlightedRangeEnd := -1;
  var LUniqueItems := TDictionary<Integer, Byte>.Create;
  try
  for var LItemIndex in AItemIndexes do
    if (LItemIndex >= 0) and (LItemIndex < ItemCount) and
      not LUniqueItems.ContainsKey(LItemIndex) then
    begin
      LUniqueItems.Add(LItemIndex, 0);
      FHighlightedItems.Add(LItemIndex);
    end;
  finally
    LUniqueItems.Free;
  end;
  FHighlightedItems.Sort;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetInactiveItems(
  const AItemIndexes: array of Integer);
begin
  FInactiveItems.Clear;
  for var LItemIndex in AItemIndexes do
    if (LItemIndex >= 0) and (LItemIndex < ItemCount) and
      not FInactiveItems.Contains(LItemIndex) then
      FInactiveItems.Add(LItemIndex);
  FInactiveItems.Sort;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SetHighlightedRange(AStartItemIndex,
  AEndItemIndex: Integer);
begin
  FHighlightedItems.Clear;
  FHighlightedRangeStart := -1;
  FHighlightedRangeEnd := -1;
  AStartItemIndex := Max(0, AStartItemIndex);
  AEndItemIndex := Min(ItemCount - 1, AEndItemIndex);
  if AEndItemIndex < AStartItemIndex then
  begin
    ControlList1.Invalidate;
    Exit;
  end;

  FHighlightedRangeStart := AStartItemIndex;
  FHighlightedRangeEnd := AEndItemIndex;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.SelectItem(AItemIndex: Integer);
begin
  if ItemCount = 0 then
    ControlList1.ItemIndex := -1
  else
    ControlList1.ItemIndex := EnsureRange(AItemIndex, 0, ItemCount - 1);
end;

function THighlighterControl.SelectedItemLineNumber: Integer;
begin
  Result := -1;
  if (ControlList1.ItemIndex < 0) or
    (ControlList1.ItemIndex >= ItemCount) then
    Exit;
  Result := DisplayLineNumber(ControlList1.ItemIndex);
end;

procedure THighlighterControl.ScrollItemToTop(AItemIndex: Integer);
var
  LScrollInfo: TScrollInfo;
begin
  if (AItemIndex < 0) or (AItemIndex >= ItemCount) then
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
  LSelected: Boolean;
  LBrushStyle: TBrushStyle;
begin
  if (AIndex < 0) or (AIndex >= ItemCount) then
    Exit;

  LSelected := odSelected in AState;

  if IsItemHighlighted(AIndex) then
  begin
    var LMarkerRect := ARect;
    //LMarkerRect.Right := Min(LMarkerRect.Right, LMarkerRect.Left + 3);
    ACanvas.Brush.Color := FHighlightColor;
    ACanvas.FillRect(LMarkerRect);
  end;

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

  var LTextRect := ARect;
  InflateRect(LTextRect, -CTextPadding, 0);
  ACanvas.Font.Name := Font.Name;
  ACanvas.Font.Size := Font.Size;
  LBrushStyle := ACanvas.Brush.Style;
  if LSelected then
    ACanvas.Brush.Style := bsClear;

  if FShowLineNumbers then
  begin
    var LGutterWidth := LineNumberGutterWidth;
    var LGutterRect := ARect;
    LGutterRect.Right := Min(LGutterRect.Right, LGutterRect.Left + LGutterWidth);
    InflateRect(LGutterRect, -CTextPadding, 0);
    if LSelected then
    begin
      ACanvas.Font.Color := TExplorerTheme.ActiveTheme.SelectionColor;
      var LGutterText := IntToHex(DisplayLineNumber(AIndex), 8) + ':';
      ACanvas.TextRect(LGutterRect, LGutterText,
        [tfRight, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
    end
    else
      FHighlighter.TextRect(ACanvas, LGutterRect,
        IntToHex(DisplayLineNumber(AIndex), 8) + ':', FThemeKind,
        [tfRight, tfVerticalCenter, tfSingleLine, tfNoPrefix],
        tpmTDumpValues, thdtHexadecimal);
    LTextRect.Left := Min(LTextRect.Right, LTextRect.Left + LGutterWidth);
  end;

  if FImages <> nil then
  begin
    var LImageName := ItemImageName(AIndex);
    if LImageName <> '' then
    begin
      var LImageIndex := FImages.GetIndexByName(LImageName);
      if LImageIndex >= 0 then
      begin
        var LImageY := LTextRect.Top +
          Max(0, (LTextRect.Height - FImages.Height) div 2);
        FImages.Draw(ACanvas, LTextRect.Left, LImageY, LImageIndex, True);
        LTextRect.Left := Min(LTextRect.Right, LTextRect.Left +
          FImages.Width + CTextPadding);
      end;
    end;
  end;

  if IsItemInactive(AIndex) and not LSelected then
  begin
    ACanvas.Font.Color := TExplorerTheme.ActiveTheme.InactiveText;
    var LInactiveLeft := LTextRect.Left;
    for var LColumnIndex := 0 to FColumnCount - 1 do
    begin
      var LInactiveRect := LTextRect;
      LInactiveRect.Left := LInactiveLeft;
      LInactiveRect.Right := LInactiveRect.Left +
        ColumnWidth(LColumnIndex, LTextRect.Width);
      if LColumnIndex = FColumnCount - 1 then
        LInactiveRect.Right := LTextRect.Right;
      if LInactiveRect.Left >= LTextRect.Right then
        Break;
      var LInactiveFormat: TTextFormat := [tfLeft, tfVerticalCenter,
        tfSingleLine, tfNoPrefix];
      if FUseEndEllipsis then
        Include(LInactiveFormat, tfEndEllipsis);
      var LInactiveText := ColumnText(AIndex, LColumnIndex);
      ACanvas.TextRect(LInactiveRect, LInactiveText, LInactiveFormat);
      LInactiveLeft := LInactiveRect.Right;
    end;
    Exit;
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
    var LItemParserMode := ItemParserMode(AIndex);
    if LItemParserMode >= 0 then
      LParserMode := TTinyParserMode(LItemParserMode);
    LParserMode := ColumnParserMode(LColumnIndex, LParserMode);
    LTextFormat := [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix];
    if FUseEndEllipsis then
      Include(LTextFormat, tfEndEllipsis);
    var LColumnText := ColumnText(AIndex, LColumnIndex);
    if LSelected then
    begin
      ACanvas.Font.Color := TExplorerTheme.ActiveTheme.SelectionColor;
      ACanvas.TextRect(LColumnRect, LColumnText, LTextFormat);
    end
    else
    begin
      FHighlighter.TextRect(ACanvas, LColumnRect, LColumnText, FThemeKind,
        LTextFormat, LParserMode, ColumnDataType(LColumnIndex));
      DrawFilterMatches(ACanvas, LColumnRect, LColumnText);
    end;
    LLeft := LColumnRect.Right;
  end;
  ACanvas.Brush.Style := LBrushStyle;
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
          CopySelectedItemsToClipboard(defText);
          Key := 0;
        end;
    end;
end;

procedure THighlighterControl.ControlList1KeyUp(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (Key in [VK_UP, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT]) and
    (ControlList1.ItemIndex >= 0) and Assigned(FOnItemClick) then
    FOnItemClick(Self);
end;

procedure THighlighterControl.ControlList1Click(Sender: TObject);
begin
  if (ControlList1.ItemIndex >= 0) and Assigned(FOnItemClick) then
    FOnItemClick(Self);
end;

procedure THighlighterControl.HeaderControlSectionClick(
  HeaderControl: THeaderControl; Section: THeaderSection);
var
  LSelectedSourceIndex: Integer;
begin
  if not FSortEnabled or (Section = nil) or
    (Section.Index < 0) or (Section.Index >= FColumnHeaders.Count) then
    Exit;

  LSelectedSourceIndex := SourceItemIndex(ControlList1.ItemIndex);
  if FSortColumn = Section.Index then
    FSortAscending := not FSortAscending
  else
  begin
    FSortColumn := Section.Index;
    FSortAscending := True;
  end;
  SaveColumnLayout;
  UpdateControlList;

  if LSelectedSourceIndex >= 0 then
    for var LDisplayIndex := 0 to FSortIndexes.Count - 1 do
      if FSortIndexes[LDisplayIndex] = LSelectedSourceIndex then
      begin
        ControlList1.ItemIndex := LDisplayIndex;
        Break;
      end;
end;

procedure THighlighterControl.HeaderControlSectionResize(
  HeaderControl: THeaderControl; Section: THeaderSection);
begin
  if FUpdatingHeader or (Section = nil) or (Section.Index < 0) or
    (Section.Index >= FColumnHeaders.Count) then
    Exit;

  if Length(FUserColumnWidths) <> FColumnHeaders.Count then
    SetLength(FUserColumnWidths, FColumnHeaders.Count);
  FUserColumnWidths[Section.Index] := Max(CTextPadding * 4, Section.Width);
  SaveColumnLayout;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.ResetSortOrder;
begin
  if (FSortColumn < 0) and (FSortIndexes.Count = 0) then
    Exit;
  FSortColumn := -1;
  FSortAscending := True;
  FSortIndexes.Clear;
  SaveColumnLayout;
  UpdateControlList;
end;

procedure THighlighterControl.AutoAdjustColumnWidths;
begin
  if FColumnHeaders.Count = 0 then
    Exit;
  SetLength(FUserColumnWidths, FColumnHeaders.Count);
  for var LColumnIndex := 0 to High(FUserColumnWidths) do
    FUserColumnWidths[LColumnIndex] := 0;
  SaveColumnLayout;
  UpdateControlList;
end;

procedure THighlighterControl.CopyToClipboard;
begin
  CopyToClipboard(defText);
end;

procedure THighlighterControl.CopyToClipboard(AFormat: TDumpExportFormat);
begin
  CopySelectedItemsToClipboard(AFormat);
end;

procedure THighlighterControl.HeaderControlDrawSection(
  HeaderControl: THeaderControl; Section: THeaderSection; const ARect: TRect;
  Pressed: Boolean);
var
  LTheme: TExplorerTheme;
  LTextRect: TRect;
  LChevronCenter: TPoint;
  LChevronDirection: TExplorerChevronDirection;
  LTextFormat: TTextFormat;
  LHeaderText: string;
  LOriginalBrushStyle: TBrushStyle;
begin
  LTheme := TExplorerTheme.ActiveTheme;
  HeaderControl.Canvas.Brush.Color := LTheme.BackgroundColor;
  HeaderControl.Canvas.FillRect(ARect);

  HeaderControl.Canvas.Pen.Color := ColorBlendRGB(LTheme.TextColor,
    LTheme.BackgroundColor, 0.88);
  HeaderControl.Canvas.MoveTo(ARect.Right - 1, ARect.Top);
  HeaderControl.Canvas.LineTo(ARect.Right - 1, ARect.Bottom);

  LTextRect := ARect;
  InflateRect(LTextRect, -CTextPadding, 0);
  if FSortEnabled and (Section.Index = FSortColumn) then
    Dec(LTextRect.Right, ScaleValue(CHeaderSortGlyphWidth));
  HeaderControl.Canvas.Font.Assign(HeaderControl.Font);
  HeaderControl.Canvas.Font.Color := LTheme.TextColor;
  LTextFormat := [tfLeft, tfVerticalCenter, tfSingleLine, tfEndEllipsis,
    tfNoPrefix];
  LHeaderText := HeaderCaption(Section.Index);
  LOriginalBrushStyle := HeaderControl.Canvas.Brush.Style;
  try
    HeaderControl.Canvas.Brush.Style := bsClear;
    HeaderControl.Canvas.TextRect(LTextRect, LHeaderText, LTextFormat);
  finally
    HeaderControl.Canvas.Brush.Style := LOriginalBrushStyle;
  end;

  if not FSortEnabled or (Section.Index <> FSortColumn) then
    Exit;

  LChevronCenter.X := Min(LTextRect.Right - ScaleValue(4),
    LTextRect.Left + HeaderControl.Canvas.TextWidth(LHeaderText) +
      ScaleValue(12));
  LChevronCenter.Y := (ARect.Top + ARect.Bottom) div 2;
  LChevronDirection := if FSortAscending then ecdUp else ecdDown;
  DrawExplorerChevron(HeaderControl.Canvas, LChevronCenter,
    LTheme.SelectionColor, LChevronDirection, CurrentPPI / 96.0);
end;

procedure THighlighterControl.ControlList1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  LPoint: TPoint;
begin
  if (Button <> mbRight) or not FContextPopupEnabled then
    Exit;

  GetCursorPos(LPoint);
  ShowContextPopupMenu(LPoint);
end;

procedure THighlighterControl.HeaderControlMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button <> mbRight) or not FContextPopupEnabled or
    not HeaderControl1.Visible then
    Exit;

  ShowHeaderPopupMenu(HeaderControl1.ClientToScreen(Point(X, Y)));
end;

procedure THighlighterControl.ContextPopupMenuItemClick(Sender: TObject;
  AItemIndex: Integer);
begin
  case AItemIndex of
    0: CopyToClipboard(defText);
    1: CopyToClipboard(defCsv);
    2: CopyToClipboard(defJson);
    3: CopyToClipboard(defMarkdown);
  end;
end;

procedure THighlighterControl.HeaderPopupMenuItemClick(Sender: TObject;
  AItemIndex: Integer);
begin
  case AItemIndex of
    0: ResetSortOrder;
    1: AutoAdjustColumnWidths;
  end;
end;

procedure THighlighterControl.ShowContextPopupMenu(const APoint: TPoint);
var
  LPopupMenu: TExplorerPopupMenuForm;
  LIconSuffix: string;
begin
  if FContextPopupMenu = nil then
  begin
    LPopupMenu := TExplorerPopupMenuForm.Create(Self);
    LPopupMenu.MenuItems.ContextPopupEnabled := False;
    LPopupMenu.OnItemClick := ContextPopupMenuItemClick;
    FContextPopupMenu := LPopupMenu;
  end
  else
    LPopupMenu := TExplorerPopupMenuForm(FContextPopupMenu);

  EnsureContextPopupImages;
  LPopupMenu.MenuItems.Images := FContextPopupImages;
  LIconSuffix := if IsLightThemeActive then '_light' else '_dark';
  LPopupMenu.MenuItems.Clear;
  LPopupMenu.MenuItems.Add('Copy to clipboard as TEXT',
    'file-text' + LIconSuffix);
  LPopupMenu.MenuItems.Add('Copy to clipboard as CSV',
    'file-csv' + LIconSuffix);
  LPopupMenu.MenuItems.Add('Copy to clipboard as JSON',
    'file-code' + LIconSuffix);
  LPopupMenu.MenuItems.Add('Copy to clipboard as MD',
    'file-md' + LIconSuffix);
  LPopupMenu.ShowAt(APoint);
end;

procedure THighlighterControl.ShowHeaderPopupMenu(const APoint: TPoint);
var
  LPopupMenu: TExplorerPopupMenuForm;
begin
  if FHeaderPopupMenu = nil then
  begin
    LPopupMenu := TExplorerPopupMenuForm.Create(Self);
    LPopupMenu.MenuItems.ContextPopupEnabled := False;
    LPopupMenu.OnItemClick := HeaderPopupMenuItemClick;
    FHeaderPopupMenu := LPopupMenu;
  end
  else
    LPopupMenu := TExplorerPopupMenuForm(FHeaderPopupMenu);

  LPopupMenu.MenuItems.Images := nil;
  LPopupMenu.MenuItems.Clear;
  LPopupMenu.MenuItems.Add('Reset sort order');
  LPopupMenu.MenuItems.Add('Auto adjust column widths');
  LPopupMenu.ShowAt(APoint);
end;

function THighlighterControl.ExportHeaders: TArray<string>;
begin
  if not HeaderControl1.Visible then
    Exit;
  SetLength(Result, FColumnHeaders.Count);
  for var LColumnIndex := 0 to FColumnHeaders.Count - 1 do
    Result[LColumnIndex] := FColumnHeaders[LColumnIndex];
end;

function THighlighterControl.ExportSelectedItems(
  AFormat: TDumpExportFormat): string;
var
  LHeaders: TArray<string>;
  LRows: TDumpExportRows;
  LSelectedIndexes: TList<Integer>;
  LColumnCount: Integer;
begin
  LHeaders := ExportHeaders;
  LColumnCount := Max(1, Length(LHeaders));
  LSelectedIndexes := TList<Integer>.Create;
  try
    for var LIndex in ControlList1.GetSelectedEnumerator do
      LSelectedIndexes.Add(LIndex);
    if (LSelectedIndexes.Count = 0) and
      (ControlList1.ItemIndex >= 0) and
      (ControlList1.ItemIndex < ItemCount) then
      LSelectedIndexes.Add(ControlList1.ItemIndex);

    SetLength(LRows, LSelectedIndexes.Count);
    for var LRowIndex := 0 to LSelectedIndexes.Count - 1 do
    begin
      var LItemIndex := LSelectedIndexes[LRowIndex];
      SetLength(LRows[LRowIndex], LColumnCount);
      for var LColumnIndex := 0 to LColumnCount - 1 do
      begin
        if Length(LHeaders) = 0 then
          LRows[LRowIndex][LColumnIndex] := ItemText(LItemIndex)
        else
          LRows[LRowIndex][LColumnIndex] := ColumnText(LItemIndex,
            LColumnIndex);
      end;
    end;
    Result := ExportView(LHeaders, LRows, AFormat);
  finally
    LSelectedIndexes.Free;
  end;
end;

procedure THighlighterControl.CopySelectedItemsToClipboard(
  AFormat: TDumpExportFormat);
begin
  var LText := ExportSelectedItems(AFormat);
  if LText <> '' then
    Clipboard.AsText := LText;
end;

procedure THighlighterControl.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImages) then
    FImages := nil;
end;

procedure THighlighterControl.ItemsChanged(Sender: TObject);
begin
  FItemProvider := nil;
  UpdateControlList;
end;

procedure THighlighterControl.Resize;
begin
  inherited;
  if FItems <> nil then
    UpdateControlList;
end;

procedure THighlighterControl.SetImages(const AValue: TCustomImageList);
begin
  if FImages = AValue then
    Exit;
  if FImages <> nil then
    FImages.RemoveFreeNotification(Self);
  FImages := AValue;
  if FImages <> nil then
    FImages.FreeNotification(Self);
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

procedure THighlighterControl.SetSortEnabled(const AValue: Boolean);
begin
  if FSortEnabled = AValue then
    Exit;
  FSortEnabled := AValue;
  if not FSortEnabled then
    FSortIndexes.Clear;
  UpdateControlList;
end;

procedure THighlighterControl.SetViewLayoutId(const AValue: string);
begin
  if FViewLayoutId = AValue then
    Exit;
  SaveColumnLayout;
  FViewLayoutId := AValue;
  FColumnLayoutKey := '';
  FSortColumn := -1;
  FSortAscending := True;
  FSortIndexes.Clear;
  SetLength(FUserColumnWidths, 0);
end;

procedure THighlighterControl.SetParserMode(const AValue: TTinyParserMode);
begin
  if FParserMode = AValue then
    Exit;
  FParserMode := AValue;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.UpdateColumnWidths;
var
  LCaptionWidths: TArray<Integer>;
begin
  FColumnCount := Max(1, FColumnHeaders.Count);
  if FUseColumnMode then
    for var LItemIndex := 0 to Min(ItemCount, 10000) - 1 do
      FColumnCount := Max(FColumnCount, ColumnCount(ItemText(LItemIndex)));

  SetLength(FColumnWidths, FColumnCount);
  if not FAutoSizeColumns then
    Exit;

  SetLength(LCaptionWidths, FColumnCount);
  FMeasureBitmap.Canvas.Font.Assign(HeaderControl1.Font);
  for var LColumnIndex := 0 to FColumnHeaders.Count - 1 do
    LCaptionWidths[LColumnIndex] := FMeasureBitmap.Canvas.TextWidth(
      HeaderCaption(LColumnIndex)) +
      (CTextPadding * 2) + ScaleValue(CHeaderSortGlyphWidth);

  FMeasureBitmap.Canvas.Font.Assign(Font);
  for var LColumnIndex := 0 to FColumnCount - 1 do
  begin
    var LWidth := CTextPadding * 2;
    if LColumnIndex < Length(LCaptionWidths) then
      LWidth := Max(LWidth, LCaptionWidths[LColumnIndex]);
    for var LItemIndex := 0 to Min(ItemCount, 10000) - 1 do
    begin
      var LItemWidth := FMeasureBitmap.Canvas.TextWidth(
        ColumnText(LItemIndex, LColumnIndex)) + (CTextPadding * 2);
      if (LColumnIndex = 0) and (FImages <> nil) and
        (FImages.GetIndexByName(ItemImageName(LItemIndex)) >= 0) then
        Inc(LItemWidth, FImages.Width + CTextPadding);
      LWidth := Max(LWidth, LItemWidth);
    end;
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
        HeaderCaption(LColumnIndex)) or
        (HeaderControl1.Sections[LColumnIndex].Width <>
          HeaderSectionWidth(LColumnIndex)) then
      begin
        LRequiresUpdate := True;
        Break;
      end;

  if not LRequiresUpdate then
  begin
    HeaderControl1.Visible := True;
    Exit;
  end;

  FUpdatingHeader := True;
  HeaderControl1.Perform(WM_SETREDRAW, 0, 0);
  try
    HeaderControl1.Visible := True;
    if LSectionCountChanged then
    begin
      HeaderControl1.Sections.Clear;
      for var LColumnIndex := 0 to FColumnHeaders.Count - 1 do
      begin
        var LSection := HeaderControl1.Sections.Add;
        LSection.Style := hsOwnerDraw;
      end;
    end;
    for var LColumnIndex := 0 to FColumnHeaders.Count - 1 do
    begin
      var LSection := HeaderControl1.Sections[LColumnIndex];
      LSection.Text := HeaderCaption(LColumnIndex);
      LSection.Width := HeaderSectionWidth(LColumnIndex);
    end;
  finally
    HeaderControl1.Perform(WM_SETREDRAW, 1, 0);
    FUpdatingHeader := False;
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

  // Frames are created before their parent is assigned.  TControlList cannot
  // calculate item metrics without a parent window, so defer the first visual
  // update until the normal parent-assignment resize arrives.
  if Parent = nil then
  begin
    FUpdatePending := True;
    Exit;
  end;

  FUpdatePending := False;
  if FItemProvider = nil then
  begin
    while FItemParserModes.Count < FItems.Count do
      FItemParserModes.Add(-1);
    while FItemParserModes.Count > FItems.Count do
      FItemParserModes.Delete(FItemParserModes.Count - 1);
    while FItemImageNames.Count < FItems.Count do
      FItemImageNames.Add('');
    while FItemImageNames.Count > FItems.Count do
      FItemImageNames.Delete(FItemImageNames.Count - 1);
    while FLineNumbers.Count < FItems.Count do
      FLineNumbers.Add(-1);
    while FLineNumbers.Count > FItems.Count do
      FLineNumbers.Delete(FLineNumbers.Count - 1);
  end;
  ApplySort;
  UpdateColumnWidths;
  UpdateHeaderControl;
  ControlList1.ItemCount := ItemCount;
  ControlList1.Invalidate;
end;

end.
