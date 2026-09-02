//**************************************************************************************************
//
// Unit TDump.Explorer.Highlighter
//
// Highlighter for Tdump Values and C++Builder-style demangled syntax
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************

unit TDump.Explorer.Highlighter;


interface

uses
  Winapi.Windows, System.Types, Vcl.Graphics, TDump.Explorer.TinyParser, TDump.Explorer.UI;

type
  // Allows a table cell to use a declared semantic type instead of relying on
  // lexical inference. thdtAuto preserves the tokenizer's mixed-content mode.
  TTinyHighlightDataType = (thdtAuto, thdtText, thdtStringLiteral,
    thdtInteger, thdtHexadecimal, thdtFloat, thdtDate, thdtTime,
    thdtDateTime, thdtSymbol, thdtMethod);

  TTinyHighlighter = class
  private
    FParser: TTinyParser;
    FTokens: TTinyTokenList;
    function FitText(ACanvas: TCanvas; const AText: string; AMaximumWidth: Integer;
      ATextFormat: TTextFormat): string;
    procedure DrawTokenizedText(ACanvas: TCanvas; const ARect: TRect;
      AX, AY: Integer; const AText, ADisplayedText: string;
      const ATheme: TExplorerTheme; ATextFormat: TTextFormat;
      AParserMode: TTinyParserMode; ADataType: TTinyHighlightDataType);
    function TokenColor(ATokenKind: TTinyTokenKind;
      const ATheme: TExplorerTheme): TColor;
  public
    constructor Create;
    destructor Destroy; override;
    procedure TextRect(ACanvas: TCanvas; const ARect: TRect; AX, AY: Integer;
      const AText: string; const ATheme: TExplorerTheme;
      ATextFormat: TTextFormat = [];
      AParserMode: TTinyParserMode = tpmTDumpValues;
      ADataType: TTinyHighlightDataType = thdtAuto); overload;
    procedure TextRect(ACanvas: TCanvas; const ARect: TRect; AX, AY: Integer;
      const AText: string; AThemeKind: TExplorerThemeKind;
      ATextFormat: TTextFormat = [];
      AParserMode: TTinyParserMode = tpmTDumpValues;
      ADataType: TTinyHighlightDataType = thdtAuto); overload;
    procedure TextRect(ACanvas: TCanvas; const ARect: TRect;
      const AText: string; const ATheme: TExplorerTheme;
      ATextFormat: TTextFormat = [];
      AParserMode: TTinyParserMode = tpmTDumpValues;
      ADataType: TTinyHighlightDataType = thdtAuto); overload;
    procedure TextRect(ACanvas: TCanvas; const ARect: TRect;
      const AText: string; AThemeKind: TExplorerThemeKind;
      ATextFormat: TTextFormat = [];
      AParserMode: TTinyParserMode = tpmTDumpValues;
      ADataType: TTinyHighlightDataType = thdtAuto); overload;
  end;

implementation

uses
  Vcl.Themes;

const
  cTruncationEllipsis = '...';

constructor TTinyHighlighter.Create;
begin
  inherited Create;
  FParser := TTinyParser.Create;
  FTokens := TTinyTokenList.Create;
end;

destructor TTinyHighlighter.Destroy;
begin
  FTokens.Free;
  FParser.Free;
  inherited;
end;

function TTinyHighlighter.FitText(ACanvas: TCanvas; const AText: string;
  AMaximumWidth: Integer; ATextFormat: TTextFormat): string;
const
  cEllipsis = '...';
begin
  Result := AText;
  if (AMaximumWidth <= 0) or (ACanvas.TextWidth(Result) <= AMaximumWidth) or
    not (ATextFormat * [tfEndEllipsis, tfPathEllipsis, tfWordEllipsis] <> []) then
    Exit;

  if ACanvas.TextWidth(cEllipsis) > AMaximumWidth then
  begin
    Result := '';
    Exit;
  end;
  var LLow := 0;
  var LHigh := Length(AText);
  while LLow < LHigh do
  begin
    var LMiddle := LLow + ((LHigh - LLow + 1) div 2);
    if ACanvas.TextWidth(Copy(AText, 1, LMiddle) + cEllipsis) <=
      AMaximumWidth then
      LLow := LMiddle
    else
      LHigh := LMiddle - 1;
  end;
  Result := Copy(AText, 1, LLow) + cEllipsis;
end;

procedure TTinyHighlighter.DrawTokenizedText(ACanvas: TCanvas;
  const ARect: TRect; AX, AY: Integer; const AText, ADisplayedText: string;
  const ATheme: TExplorerTheme; ATextFormat: TTextFormat;
  AParserMode: TTinyParserMode; ADataType: TTinyHighlightDataType);
var
  LWholeTextToken: TTinyToken;
begin
  var LVisibleLength := Length(AText);
  var LHasEllipsis := (ADisplayedText <> AText) and
    (Length(ADisplayedText) >= Length(cTruncationEllipsis)) and
    (Copy(ADisplayedText,
      Length(ADisplayedText) - Length(cTruncationEllipsis) + 1,
      Length(cTruncationEllipsis)) = cTruncationEllipsis);
  if LHasEllipsis then
    LVisibleLength := Length(ADisplayedText) - Length(cTruncationEllipsis)
  else if ADisplayedText <> AText then
    LVisibleLength := Length(ADisplayedText);

  FTokens.Clear;
  if ADataType = thdtAuto then
    // Parse the complete source before applying display ellipsis.  Truncating
    // an Itanium name first can remove its terminating E and change its token
    // kinds depending on the width of the current view.
    FParser.Tokenize(AText, AParserMode, FTokens)
  else
  begin
    LWholeTextToken.StartIndex := 1;
    LWholeTextToken.Length := Length(AText);
    LWholeTextToken.Text := AText;
    case ADataType of
      thdtStringLiteral: LWholeTextToken.Kind := ttkStringLiteral;
      thdtInteger: LWholeTextToken.Kind := ttkInteger;
      thdtHexadecimal: LWholeTextToken.Kind := ttkHexadecimal;
      thdtFloat: LWholeTextToken.Kind := ttkFloat;
      thdtDate: LWholeTextToken.Kind := ttkDate;
      thdtTime: LWholeTextToken.Kind := ttkTime;
      thdtDateTime: LWholeTextToken.Kind := ttkDateTime;
      thdtSymbol: LWholeTextToken.Kind := ttkSymbol;
      thdtMethod: LWholeTextToken.Kind := ttkMethodName;
    else
      LWholeTextToken.Kind := ttkString;
    end;
    FTokens.Add(LWholeTextToken);
  end;
  var LOriginalFontColor := ACanvas.Font.Color;
  var LOriginalBrushStyle := ACanvas.Brush.Style;
  var LSavedDeviceContext := SaveDC(ACanvas.Handle);
  try
    if not (tfNoClip in ATextFormat) then
      IntersectClipRect(ACanvas.Handle, ARect.Left, ARect.Top, ARect.Right,
        ARect.Bottom);
    ACanvas.Brush.Style := bsClear;
    var LX := AX;
    var LConsumedLength := 0;
    for var LToken in FTokens do
    begin
      if LConsumedLength >= LVisibleLength then
        Break;
      var LTokenText := LToken.Text;
      if Length(LTokenText) > LVisibleLength - LConsumedLength then
        LTokenText := Copy(LTokenText, 1, LVisibleLength - LConsumedLength);
      ACanvas.Font.Color := TokenColor(LToken.Kind, ATheme);
      ACanvas.TextOut(LX, AY, LTokenText);
      Inc(LX, ACanvas.TextWidth(LTokenText));
      Inc(LConsumedLength, Length(LToken.Text));
    end;
    if LHasEllipsis then
    begin
      ACanvas.Font.Color := ATheme.TextColor;
      ACanvas.TextOut(LX, AY, cTruncationEllipsis);
    end;
  finally
    if LSavedDeviceContext <> 0 then
      RestoreDC(ACanvas.Handle, LSavedDeviceContext);
    ACanvas.Font.Color := LOriginalFontColor;
    ACanvas.Brush.Style := LOriginalBrushStyle;
  end;
end;

procedure TTinyHighlighter.TextRect(ACanvas: TCanvas; const ARect: TRect;
  AX, AY: Integer; const AText: string; const ATheme: TExplorerTheme;
  ATextFormat: TTextFormat; AParserMode: TTinyParserMode;
  ADataType: TTinyHighlightDataType);
begin
  DrawTokenizedText(ACanvas, ARect, AX, AY, AText,
    FitText(ACanvas, AText, ARect.Right - AX, ATextFormat), ATheme,
    ATextFormat, AParserMode, ADataType);
end;

procedure TTinyHighlighter.TextRect(ACanvas: TCanvas; const ARect: TRect;
  AX, AY: Integer; const AText: string; AThemeKind: TExplorerThemeKind;
  ATextFormat: TTextFormat; AParserMode: TTinyParserMode;
  ADataType: TTinyHighlightDataType);
begin
  TextRect(ACanvas, ARect, AX, AY, AText, TExplorerTheme.ActiveTheme, ATextFormat,
    AParserMode, ADataType);
end;

procedure TTinyHighlighter.TextRect(ACanvas: TCanvas; const ARect: TRect;
  const AText: string; const ATheme: TExplorerTheme;
  ATextFormat: TTextFormat; AParserMode: TTinyParserMode;
  ADataType: TTinyHighlightDataType);
begin
  var LDisplayedText := FitText(ACanvas, AText, ARect.Width, ATextFormat);
  var LX := ARect.Left;
  if tfRight in ATextFormat then
    LX := ARect.Right - ACanvas.TextWidth(LDisplayedText)
  else if tfCenter in ATextFormat then
    LX := ARect.Left + ((ARect.Width - ACanvas.TextWidth(LDisplayedText)) div 2);
  var LY := ARect.Top;
  if tfBottom in ATextFormat then
    LY := ARect.Bottom - ACanvas.TextHeight(LDisplayedText)
  else if tfVerticalCenter in ATextFormat then
    LY := ARect.Top + ((ARect.Height - ACanvas.TextHeight(LDisplayedText)) div 2);
  DrawTokenizedText(ACanvas, ARect, LX, LY, AText, LDisplayedText, ATheme,
    ATextFormat, AParserMode, ADataType);
end;

procedure TTinyHighlighter.TextRect(ACanvas: TCanvas; const ARect: TRect;
  const AText: string; AThemeKind: TExplorerThemeKind;
  ATextFormat: TTextFormat; AParserMode: TTinyParserMode;
  ADataType: TTinyHighlightDataType);
begin
  TextRect(ACanvas, ARect, AText, TExplorerTheme.ActiveTheme, ATextFormat, AParserMode, ADataType);
end;

function TTinyHighlighter.TokenColor(ATokenKind: TTinyTokenKind;
  const ATheme: TExplorerTheme): TColor;
begin
  case ATokenKind of
    ttkString:
      Result := ATheme.TextColor;
    ttkStringLiteral:
      Result := ATheme.StringLiteralColor;
    ttkInteger, ttkFloat:
      Result := ATheme.NumberColor;
    ttkHexadecimal:
      Result := ATheme.HexadecimalColor;
    ttkDate, ttkTime, ttkDateTime:
      Result := ATheme.DateTimeColor;
    ttkSymbol, ttkMangledSignature:
      Result := ATheme.SymbolColor;
    ttkKeyword:
      Result := ATheme.KeywordColor;
    ttkNamespace:
      Result := ATheme.NamespaceColor;
    ttkTypeName:
      Result := ATheme.TypeColor;
    ttkMethodName:
      Result := ATheme.MethodColor;
  else
    Result := ATheme.TextColor;
  end;
end;

end.
