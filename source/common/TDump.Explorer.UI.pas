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
  Vcl.Graphics, System.Types, System.UITypes, System.Classes;

type
  TExplorerThemeKind = (thtLight, thtDark);

  TExplorerTheme = record
    BackgroundColor: TColor;
    TextColor: TColor;

    StringLiteralColor: TColor;
    NumberColor: TColor;
    HexadecimalColor: TColor;
    DateTimeColor: TColor;
    SymbolColor: TColor;
    KeywordColor: TColor;
    NamespaceColor: TColor;
    TypeColor: TColor;
    MethodColor: TColor;

    SelectionColor: TColor;
    class function DarkTheme: TExplorerTheme; static;
    class function LightTheme: TExplorerTheme; static;
    class function ActiveTheme: TExplorerTheme; static;
  end;

procedure DrawRoundedBar(const Canvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor);
procedure DrawSelectionBar(const Canvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor);
function IsWindows11: Boolean;

implementation

uses
  Winapi.Windows, Vcl.GraphUtil, Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SysUtils, Vcl.Themes;

class function TExplorerTheme.DarkTheme: TExplorerTheme;
begin
  var LStyle := StyleServices;
  Result.BackgroundColor := LStyle.GetSystemColor(clWindow);
  Result.TextColor := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), LStyle.GetSystemColor(clWindow), 0.3);
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
  Result.TextColor := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), LStyle.GetSystemColor(clWindow), 0.3);
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

procedure DrawRoundedBar(const Canvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor);
begin
  var LGPGraphics := TGPGraphics.Create(Canvas.Handle);
  try
    LGPGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGPGraphics.SetPixelOffsetMode(PixelOffsetModeHalf); // align 1px strokes
    var LRGBColor := ColorToRGB(BorderColor);
    var LColor := MakeColor(GetRValue(LRGBColor), GetGValue(LRGBColor), GetBValue(LRGBColor));
    var LGPPen := TGPPen.Create(LColor, 1.0);
    try
      const Radius: Single = 2.0;
      var d, L, T, R, B: Single;
      var LGPRect := MakeRect(ARect.Left * 1.0, ARect.Top* 1.0, ARect.Width* 1.0, ARect.Height* 1.0);
      d := Radius * 2.0;
      L := LGPRect.X + 0.5;
      T := LGPRect.Y + 0.5;
      R := LGPRect.X + LGPRect.Width  - 0.5;
      B := LGPRect.Y + LGPRect.Height - 0.5;
      var LPath := TGPGraphicsPath.Create;
      try
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
        var LSolidBush := TGPSolidBrush.Create(LColor);
        try
          LGPGraphics.FillPath(LSolidBush, LPath);
        finally
          LSolidBush.Free;
        end;
      finally
        LPath.Free;
      end;
    finally
      LGPPen.Free;
    end;
  finally
    LGPGraphics.Free;
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


end.
