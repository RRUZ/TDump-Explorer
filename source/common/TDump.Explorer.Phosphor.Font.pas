//**************************************************************************************************
//
// Unit TDump.Explorer.Phosphor.Font
//
// Phosphor font support
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
unit TDump.Explorer.Phosphor.Font;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Graphics;

type
  TPhosphorFontWeight = (pfwThin, pfwLight, pfwRegular, pfwBold, pfwFill,
    pfwDuotone);

  TPhosphorFont = class
  private
    FFontCollections: array[TPhosphorFontWeight] of TObject;
    FFontData: array[TPhosphorFontWeight] of TBytes;
    FFontHandles: array[TPhosphorFontWeight] of THandle;
    procedure LoadFont(AWeight: TPhosphorFontWeight);
  public
    constructor Create;
    destructor Destroy; override;
    procedure DrawIcon(ADC: HDC; ACode: Word; const ADestRect: TRect;
      AColor: TColor; AWeight: TPhosphorFontWeight = pfwRegular);
    function GetIconCodes(AWeight: TPhosphorFontWeight = pfwRegular): TArray<Word>;
  end;

  TPhosphorIcon = class(TCustomControl)
  private
    FIconCode: Word;
    FIconColor: TColor;
    FWeight: TPhosphorFontWeight;
    procedure SetIconCode(const AValue: Word);
    procedure SetIconColor(const AValue: TColor);
    procedure SetWeight(const AValue: TPhosphorFontWeight);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    property Color;
    property IconCode: Word read FIconCode write SetIconCode default $E67C;
    property IconColor: TColor read FIconColor write SetIconColor default clHighlight;
    property Weight: TPhosphorFontWeight read FWeight write SetWeight default pfwRegular;
    property OnClick;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

const
  cPhTreeStructure = $E67C;
  cPhBinary = $EE60;
  cPhBug = $E5F4;
  cPhCube = $E1DA;
  cPhDatabase = $E1DE;
  cPhClockCounterClockwise = $E1A0;
  cPhFileMagnifyingGlass = $E238;
  cPhMagnifyingGlass = $E30C;
  cPhTerminal = $E47E;

var
  PhosphorFont: TPhosphorFont;

implementation

uses
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ;

{$R TDump.Explorer.Phosphor.Font.res}

const
  cResourceNames: array[TPhosphorFontWeight] of string = (
    'PHOSPHOR_THIN', 'PHOSPHOR_LIGHT', 'PHOSPHOR_REGULAR', 'PHOSPHOR_BOLD',
    'PHOSPHOR_FILL', 'PHOSPHOR_DUOTONE');
  cFontNames: array[TPhosphorFontWeight] of string = (
    'Phosphor-Thin', 'Phosphor-Light', 'Phosphor', 'Phosphor-Bold',
    'Phosphor-Fill', 'Phosphor-Duotone');

{ TPhosphorFont }

constructor TPhosphorFont.Create;
begin
  inherited Create;
  for var LWeight := Low(TPhosphorFontWeight) to High(TPhosphorFontWeight) do
    LoadFont(LWeight);
end;

destructor TPhosphorFont.Destroy;
begin
  for var LWeight := Low(TPhosphorFontWeight) to High(TPhosphorFontWeight) do
  begin
    FFontCollections[LWeight].Free;
    if FFontHandles[LWeight] <> 0 then
      RemoveFontMemResourceEx(FFontHandles[LWeight]);
  end;
  inherited;
end;

procedure TPhosphorFont.LoadFont(AWeight: TPhosphorFontWeight);
begin
  var LStream := TResourceStream.Create(HInstance, cResourceNames[AWeight],
    RT_RCDATA);
  try
    SetLength(FFontData[AWeight], LStream.Size);
    LStream.ReadBuffer(FFontData[AWeight][0], LStream.Size);
  finally
    LStream.Free;
  end;

  var LFontCount: Cardinal := 0;
  FFontHandles[AWeight] := AddFontMemResourceEx(@FFontData[AWeight][0],
    Length(FFontData[AWeight]), nil, @LFontCount);
  if FFontHandles[AWeight] = 0 then
    RaiseLastOSError;

  var LCollection: TGPPrivateFontCollection := nil;
  try
    LCollection := TGPPrivateFontCollection.Create;
    var LStatus := LCollection.AddMemoryFont(@FFontData[AWeight][0],
      Length(FFontData[AWeight]));
    if LStatus <> Status.Ok then
      RaiseLastOSError;
    FFontCollections[AWeight] := LCollection;
    LCollection := nil;
  finally
    LCollection.Free;
  end;
end;

procedure TPhosphorFont.DrawIcon(ADC: HDC; ACode: Word;
  const ADestRect: TRect; AColor: TColor; AWeight: TPhosphorFontWeight);
begin
  var LGraphics := TGPGraphics.Create(ADC);
  try
    LGraphics.SetTextRenderingHint(TextRenderingHintAntiAliasGridFit);
    var LFont := TGPFont.Create(cFontNames[AWeight], ADestRect.Height,
      FontStyleRegular, UnitPixel,
      TGPPrivateFontCollection(FFontCollections[AWeight]));
    try
      var LColor := ColorToRGB(AColor);
      var LBrush := TGPSolidBrush.Create(MakeColor(255, GetRValue(LColor),
        GetGValue(LColor), GetBValue(LColor)));
      try
        var LRect := MakeRect(ADestRect.Left * 1.0, ADestRect.Top * 1.0,
          ADestRect.Width * 1.0, ADestRect.Height * 1.0);
        var LStringFormat := TGPStringFormat.Create;
        try
          LStringFormat.SetAlignment(StringAlignmentCenter);
          LStringFormat.SetLineAlignment(StringAlignmentCenter);
          var LText: string := Char(ACode);
          LGraphics.DrawString(LText, -1, LFont, LRect, LStringFormat, LBrush);
        finally
          LStringFormat.Free;
        end;
      finally
        LBrush.Free;
      end;
    finally
      LFont.Free;
    end;
  finally
    LGraphics.Free;
  end;
end;

function TPhosphorFont.GetIconCodes(
  AWeight: TPhosphorFontWeight): TArray<Word>;
const
  cPrivateUseFirst = $E000;
  cPrivateUseLast = $F8FF;
var
  LCharacters: TArray<WideChar>;
  LGlyphIndexes: TArray<Word>;
begin
  var LDC := GetDC(0);
  if LDC = 0 then
    RaiseLastOSError;
  var LFont: HFONT := 0;
  var LOldFont: HGDIOBJ := 0;
  try
    LFont := CreateFont(32, 0, 0, 0, FW_NORMAL, 0, 0, 0,
      DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
      ANTIALIASED_QUALITY, DEFAULT_PITCH, PChar(cFontNames[AWeight]));
    if LFont = 0 then
      RaiseLastOSError;
    LOldFont := SelectObject(LDC, LFont);
    var LCharacterCount := cPrivateUseLast - cPrivateUseFirst + 1;
    SetLength(LCharacters, LCharacterCount);
    SetLength(LGlyphIndexes, LCharacterCount);
    for var LIndex := 0 to LCharacterCount - 1 do
      LCharacters[LIndex] := WideChar(cPrivateUseFirst + LIndex);
    if GetGlyphIndicesW(LDC, PWideChar(@LCharacters[0]), LCharacterCount,
      @LGlyphIndexes[0], GGI_MARK_NONEXISTING_GLYPHS) = GDI_ERROR then
      RaiseLastOSError;

    SetLength(Result, LCharacterCount);
    var LResultIndex := 0;
    for var LIndex := 0 to LCharacterCount - 1 do
      if LGlyphIndexes[LIndex] <> $FFFF then
      begin
        Result[LResultIndex] := Word(LCharacters[LIndex]);
        Inc(LResultIndex);
      end;
    SetLength(Result, LResultIndex);
  finally
    if LOldFont <> 0 then
      SelectObject(LDC, LOldFont);
    if LFont <> 0 then
      DeleteObject(LFont);
    ReleaseDC(0, LDC);
  end;
end;

{ TPhosphorIcon }

constructor TPhosphorIcon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Cursor := crHandPoint;
  FIconCode := cPhTreeStructure;
  FIconColor := clHighlight;
  FWeight := pfwRegular;
  Color := clBtnFace;
end;

procedure TPhosphorIcon.Paint;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  PhosphorFont.DrawIcon(Canvas.Handle, FIconCode, ClientRect, FIconColor, FWeight);
end;

procedure TPhosphorIcon.SetIconCode(const AValue: Word);
begin
  if FIconCode <> AValue then
  begin
    FIconCode := AValue;
    Invalidate;
  end;
end;

procedure TPhosphorIcon.SetIconColor(const AValue: TColor);
begin
  if FIconColor <> AValue then
  begin
    FIconColor := AValue;
    Invalidate;
  end;
end;

procedure TPhosphorIcon.SetWeight(const AValue: TPhosphorFontWeight);
begin
  if FWeight <> AValue then
  begin
    FWeight := AValue;
    Invalidate;
  end;
end;

initialization
  PhosphorFont := TPhosphorFont.Create;

finalization
  PhosphorFont.Free;

end.
