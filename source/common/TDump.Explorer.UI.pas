unit TDump.Explorer.UI;

interface

uses
  Vcl.Graphics, System.Types, System.UITypes, System.Classes;

procedure DrawRoundedBar(const ACanvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor);
procedure DrawSelectionBar(const ACanvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor);
function IsWindows11: Boolean;


implementation

uses
  Winapi.Windows, Vcl.GraphUtil, Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SysUtils;


function IsWindows11: Boolean;
begin
  Result := TOSVersion.Check(10) and (TOSVersion.Build >= 22000);
end;

procedure DrawRoundedBar(const ACanvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor);
begin
  var LGPGraphics := TGPGraphics.Create(ACanvas.Handle);
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
      // Inset by 0.5 so a 1px pen sits fully inside the bitmap
      L := LGPRect.X + 0.5;
      T := LGPRect.Y + 0.5;
      R := LGPRect.X + LGPRect.Width  - 0.5;
      B := LGPRect.Y + LGPRect.Height - 0.5;

      var LPath := TGPGraphicsPath.Create;
      try
        // 4 arcs + 4 edges
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

procedure DrawSelectionBar(const ACanvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor);
begin
  if IsWindows11 then
    DrawRoundedBar(ACanvas, ARect, FillColor, BorderColor)
  else
  begin
    ACanvas.Brush.Color := FillColor;
    ACanvas.FillRect(ARect);
    ACanvas.Brush.Color := BorderColor;
    ACanvas.FrameRect(ARect);
  end;
end;

end.
