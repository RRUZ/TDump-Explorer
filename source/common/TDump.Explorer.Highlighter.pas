//**************************************************************************************************
//
// Unit TDump.Explorer.Highlighter
//
// Highlighter for Tdump Values and C++Builder-style demangled syntax
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
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
  CEllipsis = '...';
begin
  Result := AText;
  if (AMaximumWidth <= 0) or (ACanvas.TextWidth(Result) <= AMaximumWidth) or
    not (ATextFormat * [tfEndEllipsis, tfPathEllipsis, tfWordEllipsis] <> []) then
    Exit;

  if ACanvas.TextWidth(CEllipsis) > AMaximumWidth then
  begin
    Result := '';
    Exit;
  end;
  var LLow := 0;
  var LHigh := Length(AText);
  while LLow < LHigh do
  begin
    var LMiddle := LLow + ((LHigh - LLow + 1) div 2);
    if ACanvas.TextWidth(Copy(AText, 1, LMiddle) + CEllipsis) <=
      AMaximumWidth then
      LLow := LMiddle
    else
      LHigh := LMiddle - 1;
  end;
  Result := Copy(AText, 1, LLow) + CEllipsis;
end;

procedure TTinyHighlighter.TextRect(ACanvas: TCanvas; const ARect: TRect;
  AX, AY: Integer; const AText: string; const ATheme: TExplorerTheme;
  ATextFormat: TTextFormat; AParserMode: TTinyParserMode;
  ADataType: TTinyHighlightDataType);
begin
  var LText := FitText(ACanvas, AText, ARect.Right - AX, ATextFormat);
  FTokens.Clear;
  if ADataType = thdtAuto then
    FParser.Tokenize(LText, AParserMode, FTokens)
  else
  begin
    var LToken: TTinyToken;
    LToken.StartIndex := 1;
    LToken.Length := Length(LText);
    LToken.Text := LText;
    case ADataType of
      thdtStringLiteral: LToken.Kind := ttkStringLiteral;
      thdtInteger: LToken.Kind := ttkInteger;
      thdtHexadecimal: LToken.Kind := ttkHexadecimal;
      thdtFloat: LToken.Kind := ttkFloat;
      thdtDate: LToken.Kind := ttkDate;
      thdtTime: LToken.Kind := ttkTime;
      thdtDateTime: LToken.Kind := ttkDateTime;
      thdtSymbol: LToken.Kind := ttkSymbol;
      thdtMethod: LToken.Kind := ttkMethodName;
    else
      LToken.Kind := ttkString;
    end;
    FTokens.Add(LToken);
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
    for var LToken in FTokens do
    begin
      ACanvas.Font.Color := TokenColor(LToken.Kind, ATheme);
      ACanvas.TextOut(LX, AY, LToken.Text);
      Inc(LX, ACanvas.TextWidth(LToken.Text));
    end;
  finally
    if LSavedDeviceContext <> 0 then
      RestoreDC(ACanvas.Handle, LSavedDeviceContext);
    ACanvas.Font.Color := LOriginalFontColor;
    ACanvas.Brush.Style := LOriginalBrushStyle;
  end;
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
  var LText := FitText(ACanvas, AText, ARect.Width, ATextFormat);
  var LX := ARect.Left;
  if tfRight in ATextFormat then
    LX := ARect.Right - ACanvas.TextWidth(LText)
  else if tfCenter in ATextFormat then
    LX := ARect.Left + ((ARect.Width - ACanvas.TextWidth(LText)) div 2);
  var LY := ARect.Top;
  if tfBottom in ATextFormat then
    LY := ARect.Bottom - ACanvas.TextHeight(LText)
  else if tfVerticalCenter in ATextFormat then
    LY := ARect.Top + ((ARect.Height - ACanvas.TextHeight(LText)) div 2);
  TextRect(ACanvas, ARect, LX, LY, LText, ATheme, ATextFormat, AParserMode, ADataType);
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
