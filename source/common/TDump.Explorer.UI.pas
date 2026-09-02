//**************************************************************************************************
//
// Unit TDump.Explorer.UI
//
// UI Utils
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.UI;

interface

uses
  Vcl.Graphics, System.Types, System.UITypes, System.Classes, Vcl.Controls,
  Vcl.ExtCtrls, TDump.Explorer.GlassTabs;

type
  TExplorerThemeKind = (thtLight, thtDark);

  TExplorerTheme = record
    const FixedWidthFontName : string = 'Consolas';
    const FixedWidthFontSize = 8;
    const FontName = 'Segoe UI';
    const FontSize = 9;
   public
    // Windows, controls colors
    BackgroundColor: TColor;
    TextColor: TColor;
    InactiveText: TColor;
    SelectionColor: TColor;
    GhostColor: TColor;

    // token colors
    StringLiteralColor: TColor;
    NumberColor: TColor;
    HexadecimalColor: TColor;
    DateTimeColor: TColor;
    SymbolColor: TColor;
    KeywordColor: TColor;
    NamespaceColor: TColor;
    TypeColor: TColor;
    MethodColor: TColor;
    class function DarkTheme: TExplorerTheme; static;
    class function LightTheme: TExplorerTheme; static;
    class function ActiveTheme: TExplorerTheme; static;
  end;

  TEmptyStateDropZone = class(TCustomPanel)
  private
    FBorderColor: TColor;
    procedure SetBorderColor(const AValue: TColor);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Color;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
  end;

procedure DrawRoundedBar(const Canvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor; const Radius: Single = 2.0);
procedure DrawDashedRoundedRectangle(const ACanvas: TCanvas;
  const ARect: TRect; ABorderColor: TColor; ARadius: Integer);
procedure DrawSelectionBar(const Canvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor);
procedure DrawSplitterLine(const ACanvas: TCanvas; const ARect: TRect; AIsVertical: Boolean; AColor: TColor);
function ExplorerTabPalette(const ATheme: TExplorerTheme): TGlassTabPalette;
function IsWindows11: Boolean;
function IsLightThemeActive: Boolean;
function IsWindowsLightTheme: Boolean;
function FormatByteSize(AByteCount: Int64): string;

implementation

uses
  Winapi.Windows, System.Win.Registry, Vcl.GraphUtil, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.SysUtils, Vcl.Themes;

const
  cBorderBlend = 0.82;
  cInactiveTopBlend = 0.97;
  cHoverTopBlend = 0.82;
  cCloseHoverBlend = 0.72;

{ TEmptyStateDropZone }

constructor TEmptyStateDropZone.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BevelOuter := bvNone;
  ParentBackground := False;
  DoubleBuffered := True;
end;

procedure TEmptyStateDropZone.Paint;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  DrawDashedRoundedRectangle(Canvas, ClientRect, FBorderColor,
    ScaleValue(14));
end;

procedure TEmptyStateDropZone.SetBorderColor(const AValue: TColor);
begin
  if FBorderColor = AValue then
    Exit;
  FBorderColor := AValue;
  Invalidate;
end;

function ExplorerTabPalette(const ATheme: TExplorerTheme): TGlassTabPalette;
begin
  Result.StripTop := ATheme.BackgroundColor;
  Result.StripBottom := ATheme.BackgroundColor;
  Result.StripBorder := ColorBlendRGB(ATheme.TextColor,
    ATheme.BackgroundColor, cBorderBlend);
  Result.BackgroundTopLine := ATheme.BackgroundColor;
  Result.TabTop := ATheme.BackgroundColor;
  Result.TabBottom := ATheme.BackgroundColor;
  Result.InactiveTop := ColorBlendRGB(ATheme.TextColor,
    ATheme.BackgroundColor, cInactiveTopBlend);
  Result.InactiveBottom := ATheme.BackgroundColor;
  Result.HoverTop := ColorBlendRGB(ATheme.SelectionColor,
    ATheme.BackgroundColor, cHoverTopBlend);
  Result.HoverBottom := ATheme.BackgroundColor;
  Result.Accent := ATheme.SelectionColor;
  Result.Text := ATheme.TextColor;
  Result.InactiveText := ATheme.InactiveText;
  Result.CloseHover := ColorBlendRGB(ATheme.SelectionColor,
    ATheme.BackgroundColor, cCloseHoverBlend);
end;

function IsWindowsLightTheme: Boolean;
const
  cPersonalizeKey = '\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';
begin
  Result := True;
  with TRegistry.Create(KEY_READ) do
  try
    RootKey := HKEY_CURRENT_USER;
    if OpenKeyReadOnly(cPersonalizeKey) and ValueExists('SystemUsesLightTheme') then
      Result := ReadInteger('SystemUsesLightTheme') <> 0;
  finally
    Free;
  end;
end;


function FormatByteSize(AByteCount: Int64): string;
const
  cUnits: array[0..4] of string = ('B', 'KiB', 'MiB', 'GiB', 'TiB');
begin
  var LSize := AByteCount * 1.0;
  var LUnitIndex := 0;
  while (Abs(LSize) >= 1024.0) and (LUnitIndex < High(cUnits)) do
  begin
    LSize := LSize / 1024.0;
    Inc(LUnitIndex);
  end;
  if LUnitIndex = 0 then
    Result := Format('%d %s', [AByteCount, cUnits[LUnitIndex]])
  else
    Result := Format('%.2f %s', [LSize, cUnits[LUnitIndex]]);
end;

function IsLightThemeActive: Boolean;
begin
  Result := ColorIsBright(StyleServices.GetSystemColor(clWindow));
end;

class function TExplorerTheme.DarkTheme: TExplorerTheme;
begin
  var LStyle := StyleServices;
  Result.BackgroundColor := LStyle.GetSystemColor(clWindow);
  Result.TextColor := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), LStyle.GetSystemColor(clWindow), 0.2);
  Result.InactiveText := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), LStyle.GetSystemColor(clWindow), 0.5);
  Result.GhostColor := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), LStyle.GetSystemColor(clWindow), 0.9);
  Result.SelectionColor := LStyle.GetSystemColor(clHighlight);

  Result.StringLiteralColor := TColor(RGB(165, 225, 120));
  Result.NumberColor := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), clWebBlue, 0.5);//TColor(RGB(130, 195, 255));
  Result.HexadecimalColor := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), clWebGreen, 0.5);
  Result.DateTimeColor := TColor(RGB(205, 155, 255));
  Result.SymbolColor := TColor(RGB(145, 155, 165));
  Result.KeywordColor := TColor(RGB(255, 170, 110));
  Result.NamespaceColor := TColor(RGB(135, 190, 250));
  Result.TypeColor := TColor(RGB(130, 220, 205));
  Result.MethodColor := TColor(RGB(245, 205, 125));
end;

class function TExplorerTheme.LightTheme: TExplorerTheme;
begin
  var LStyle := StyleServices;
  Result.BackgroundColor := LStyle.GetSystemColor(clWindow);
  Result.TextColor := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), LStyle.GetSystemColor(clWindow), 0.2);
  Result.InactiveText := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), LStyle.GetSystemColor(clWindow), 0.5);
  Result.GhostColor := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), LStyle.GetSystemColor(clWindow), 0.8);
  Result.SelectionColor := LStyle.GetSystemColor(clHighlight);

  Result.StringLiteralColor := TColor(RGB(35, 125, 70));
  Result.NumberColor := TColor(RGB(20, 85, 175));
  Result.HexadecimalColor := TColor(RGB(0, 120, 115));
  Result.DateTimeColor := TColor(RGB(125, 55, 165));
  Result.SymbolColor := TColor(RGB(110, 110, 110));
  Result.KeywordColor := TColor(RGB(175, 75, 20));
  Result.NamespaceColor := TColor(RGB(30, 85, 175));
  Result.TypeColor := TColor(RGB(0, 115, 105));
  Result.MethodColor := TColor(RGB(145, 95, 15));
end;

class function TExplorerTheme.ActiveTheme: TExplorerTheme;
begin
  var LStyle := StyleServices;
  Result := if ColorIsBright(LStyle.GetSystemColor(clWindow)) then LightTheme else DarkTheme;
end;

function IsWindows11: Boolean;
begin
  Result := TOSVersion.Check(10) and (TOSVersion.Build >= 22000);
end;

procedure DrawRoundedBar(const Canvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor; const Radius: Single = 2.0);
begin
  var LGPGraphics := TGPGraphics.Create(Canvas.Handle);
  var LGPPen: TGPPen := nil;
  var LPath: TGPGraphicsPath := nil;
  var LSolidBrush: TGPSolidBrush := nil;
  try
    LGPGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGPGraphics.SetPixelOffsetMode(PixelOffsetModeHalf); // align 1px strokes
    var LRGBColor := ColorToRGB(BorderColor);
    var LColor := MakeColor(GetRValue(LRGBColor), GetGValue(LRGBColor), GetBValue(LRGBColor));
    LGPPen := TGPPen.Create(LColor, 1.0);
    var d, L, T, R, B: Single;
    var LGPRect := MakeRect(ARect.Left * 1.0, ARect.Top* 1.0, ARect.Width* 1.0, ARect.Height* 1.0);
    d := Radius * 2.0;
    L := LGPRect.X + 0.5;
    T := LGPRect.Y + 0.5;
    R := LGPRect.X + LGPRect.Width  - 0.5;
    B := LGPRect.Y + LGPRect.Height - 0.5;
    LPath := TGPGraphicsPath.Create;
    LPath.AddArc(L, T, d, d, 180, 90); // TL
    LPath.AddLine(L + Radius, T, R - Radius, T);
    LPath.AddArc(R - d, T, d, d, 270, 90); // TR
    LPath.AddLine(R, T + Radius, R, B - Radius);
    LPath.AddArc(R - d, B - d, d, d, 0, 90); // BR
    LPath.AddLine(R-Radius, B, L + Radius, B);
    LPath.AddArc(L, B - d, d, d,  90, 90); // BL
    LPath.AddLine(L, B - Radius, L, T + Radius);
    LPath.CloseFigure;
    LGPGraphics.DrawPath(LGPPen, LPath);
    LRGBColor := ColorToRGB(FillColor);
    LColor := MakeColor(GetRValue(LRGBColor), GetGValue(LRGBColor), GetBValue(LRGBColor));
    LSolidBrush := TGPSolidBrush.Create(LColor);
    LGPGraphics.FillPath(LSolidBrush, LPath);
  finally
    LSolidBrush.Free;
    LPath.Free;
    LGPPen.Free;
    LGPGraphics.Free;
  end;
end;

procedure DrawDashedRoundedRectangle(const ACanvas: TCanvas;
  const ARect: TRect; ABorderColor: TColor; ARadius: Integer);
var
  LRect: TRect;
  LRadius: Integer;
  LColor: TGPColor;
  LColorRGB: TColor;
  LGraphics: TGPGraphics;
  LPath: TGPGraphicsPath;
  LPen: TGPPen;
  L, T, R, B, D: Single;
  LDashPattern: array[0..1] of Single;
begin
  LRect := ARect;
  InflateRect(LRect, -1, -1);
  if (LRect.Width <= 2) or (LRect.Height <= 2) then
    Exit;

  LRadius := ARadius;
  if LRadius < 1 then
    LRadius := 1;
  if LRadius * 2 > LRect.Width then
    LRadius := LRect.Width div 2;
  if LRadius * 2 > LRect.Height then
    LRadius := LRect.Height div 2;

  LColorRGB := ColorToRGB(ABorderColor);
  LColor := MakeColor(GetRValue(LColorRGB), GetGValue(LColorRGB),
    GetBValue(LColorRGB));
  LGraphics := TGPGraphics.Create(ACanvas.Handle);
  LPen := nil;
  LPath := nil;
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    LPen := TGPPen.Create(LColor, 2.5);
    LDashPattern[0] := 4.0;
    LDashPattern[1] := 2.5;
    LPen.SetDashStyle(DashStyleCustom);
    LPen.SetDashPattern(@LDashPattern[0], Length(LDashPattern));
    LPen.SetDashCap(DashCapFlat);
    LPen.SetLineJoin(LineJoinRound);
    L := LRect.Left + 0.5;
    T := LRect.Top + 0.5;
    R := LRect.Right - 0.5;
    B := LRect.Bottom - 0.5;
    D := LRadius * 2.0;
    LPath := TGPGraphicsPath.Create;
    LPath.AddArc(L, T, D, D, 180, 90);
    LPath.AddLine(L + LRadius, T, R - LRadius, T);
    LPath.AddArc(R - D, T, D, D, 270, 90);
    LPath.AddLine(R, T + LRadius, R, B - LRadius);
    LPath.AddArc(R - D, B - D, D, D, 0, 90);
    LPath.AddLine(R - LRadius, B, L + LRadius, B);
    LPath.AddArc(L, B - D, D, D, 90, 90);
    LPath.AddLine(L, B - LRadius, L, T + LRadius);
    LPath.CloseFigure;
    LGraphics.DrawPath(LPen, LPath);
  finally
    LPath.Free;
    LPen.Free;
    LGraphics.Free;
  end;
end;

procedure DrawSelectionBar(const Canvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor);
begin
  if IsWindows11 then
    DrawRoundedBar(Canvas, ARect, FillColor, BorderColor)
  else
  begin
    Canvas.Brush.Color := FillColor;
    Canvas.FillRect(ARect);
    Canvas.Brush.Color := BorderColor;
    Canvas.FrameRect(ARect);
  end;
end;

procedure DrawSplitterLine(const ACanvas: TCanvas; const ARect: TRect;  AIsVertical: Boolean; AColor: TColor);
begin
  if (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  var LRGBColor := ColorToRGB(AColor);
  var LColor := MakeColor(GetRValue(LRGBColor), GetGValue(LRGBColor),
    GetBValue(LRGBColor));
  var LGraphics := TGPGraphics.Create(ACanvas.Handle);
  var LPen: TGPPen := nil;
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    LPen := TGPPen.Create(LColor, 1.0);
    if AIsVertical then
    begin
      var LCenter := (ARect.Left + ARect.Right) / 2.0;
      LGraphics.DrawLine(LPen, LCenter, ARect.Top, LCenter, ARect.Bottom);
    end
    else
    begin
      var LCenter := (ARect.Top + ARect.Bottom) / 2.0;
      LGraphics.DrawLine(LPen, ARect.Left, LCenter, ARect.Right, LCenter);
    end;
  finally
    LPen.Free;
    LGraphics.Free;
  end;
end;


end.
