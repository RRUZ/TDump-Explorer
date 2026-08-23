unit TDump.Explorer.Highlighter;

interface

uses
  Winapi.Windows,
  System.Types,
  Vcl.Graphics,
  TDump.Explorer.TinyParser;

type
  TTinyHighlightTheme = record
    BackgroundColor: TColor;
    TextColor: TColor;
    StringColor: TColor;
    NumberColor: TColor;
    HexadecimalColor: TColor;
    DateTimeColor: TColor;
    SymbolColor: TColor;
  end;

  TTinyHighlightThemeKind = (thtLight, thtDark);

  TTinyHighlighter = class
  private
    FParser: TTinyParser;
    function FitText(ACanvas: TCanvas; const AText: string; AMaximumWidth: Integer;
      ATextFormat: TTextFormat): string;
    function TokenColor(ATokenKind: TTinyTokenKind;
      const ATheme: TTinyHighlightTheme): TColor;
  public
    constructor Create;
    destructor Destroy; override;
    class function DarkTheme: TTinyHighlightTheme; static;
    class function LightTheme: TTinyHighlightTheme; static;
    class function Theme(AThemeKind: TTinyHighlightThemeKind): TTinyHighlightTheme;
      static;
    procedure TextRect(ACanvas: TCanvas; const ARect: TRect; AX, AY: Integer;
      const AText: string; const ATheme: TTinyHighlightTheme;
      ATextFormat: TTextFormat = []); overload;
    procedure TextRect(ACanvas: TCanvas; const ARect: TRect; AX, AY: Integer;
      const AText: string; AThemeKind: TTinyHighlightThemeKind;
      ATextFormat: TTextFormat = []); overload;
    procedure TextRect(ACanvas: TCanvas; const ARect: TRect;
      const AText: string; const ATheme: TTinyHighlightTheme;
      ATextFormat: TTextFormat = []); overload;
    procedure TextRect(ACanvas: TCanvas; const ARect: TRect;
      const AText: string; AThemeKind: TTinyHighlightThemeKind;
      ATextFormat: TTextFormat = []); overload;
  end;

implementation

constructor TTinyHighlighter.Create;
begin
  inherited Create;
  FParser := TTinyParser.Create;
end;

destructor TTinyHighlighter.Destroy;
begin
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
  while (Result <> '') and
    (ACanvas.TextWidth(Result + CEllipsis) > AMaximumWidth) do
    Delete(Result, Length(Result), 1);
  Result := Result + CEllipsis;
end;

class function TTinyHighlighter.DarkTheme: TTinyHighlightTheme;
begin
  Result.BackgroundColor := TColor(RGB(31, 34, 40));
  Result.TextColor := TColor(RGB(220, 225, 230));
  Result.StringColor := TColor(RGB(205, 220, 170));
  Result.NumberColor := TColor(RGB(130, 195, 255));
  Result.HexadecimalColor := TColor(RGB(95, 220, 210));
  Result.DateTimeColor := TColor(RGB(205, 155, 255));
  Result.SymbolColor := TColor(RGB(145, 155, 165));
end;

class function TTinyHighlighter.LightTheme: TTinyHighlightTheme;
begin
  Result.BackgroundColor := clWindow;
  Result.TextColor := TColor(RGB(40, 45, 50));
  Result.StringColor := TColor(RGB(85, 110, 40));
  Result.NumberColor := TColor(RGB(20, 85, 175));
  Result.HexadecimalColor := TColor(RGB(0, 120, 115));
  Result.DateTimeColor := TColor(RGB(125, 55, 165));
  Result.SymbolColor := TColor(RGB(110, 110, 110));
end;

class function TTinyHighlighter.Theme(
  AThemeKind: TTinyHighlightThemeKind): TTinyHighlightTheme;
begin
  case AThemeKind of
    thtDark:
      Result := DarkTheme;
  else
    Result := LightTheme;
  end;
end;

procedure TTinyHighlighter.TextRect(ACanvas: TCanvas; const ARect: TRect;
  AX, AY: Integer; const AText: string; const ATheme: TTinyHighlightTheme;
  ATextFormat: TTextFormat);
begin
  var LText := FitText(ACanvas, AText, ARect.Right - AX, ATextFormat);
  var LTokens := FParser.Tokenize(LText);
  var LOriginalFontColor := ACanvas.Font.Color;
  var LOriginalBrushStyle := ACanvas.Brush.Style;
  var LSavedDeviceContext := SaveDC(ACanvas.Handle);
  try
    if not (tfNoClip in ATextFormat) then
      IntersectClipRect(ACanvas.Handle, ARect.Left, ARect.Top, ARect.Right,
        ARect.Bottom);
    ACanvas.Brush.Style := bsClear;
    var LX := AX;
    for var LToken in LTokens do
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
    LTokens.Free;
  end;
end;

procedure TTinyHighlighter.TextRect(ACanvas: TCanvas; const ARect: TRect;
  AX, AY: Integer; const AText: string; AThemeKind: TTinyHighlightThemeKind;
  ATextFormat: TTextFormat);
begin
  TextRect(ACanvas, ARect, AX, AY, AText, Theme(AThemeKind), ATextFormat);
end;

procedure TTinyHighlighter.TextRect(ACanvas: TCanvas; const ARect: TRect;
  const AText: string; const ATheme: TTinyHighlightTheme;
  ATextFormat: TTextFormat);
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
  TextRect(ACanvas, ARect, LX, LY, LText, ATheme, ATextFormat);
end;

procedure TTinyHighlighter.TextRect(ACanvas: TCanvas; const ARect: TRect;
  const AText: string; AThemeKind: TTinyHighlightThemeKind;
  ATextFormat: TTextFormat);
begin
  TextRect(ACanvas, ARect, AText, Theme(AThemeKind), ATextFormat);
end;

function TTinyHighlighter.TokenColor(ATokenKind: TTinyTokenKind;
  const ATheme: TTinyHighlightTheme): TColor;
begin
  case ATokenKind of
    ttkString:
      Result := ATheme.StringColor;
    ttkInteger, ttkFloat:
      Result := ATheme.NumberColor;
    ttkHexadecimal:
      Result := ATheme.HexadecimalColor;
    ttkDate, ttkTime, ttkDateTime:
      Result := ATheme.DateTimeColor;
    ttkSymbol:
      Result := ATheme.SymbolColor;
  else
    Result := ATheme.TextColor;
  end;
end;

end.
