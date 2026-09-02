//**************************************************************************************************
//
// Unit TDump.Explorer.UI
//
// UI Utils
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
unit TDump.Explorer.UI;

interface

uses
  Winapi.Messages, Vcl.Graphics, System.Types, System.UITypes, System.Classes,
  Vcl.Controls, Vcl.ExtCtrls, Vcl.Forms, Vcl.ImgList,
  TDump.Explorer.Tabs;

type
  TExplorerThemeKind = (thtLight, thtDark);
  TExplorerChevronDirection = (ecdUp, ecdDown);
  TSimpleUIButtonImagePosition = (buipLeft, buipRight, buipTop, buipBottom);

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

  TSimpleUIButtonPalette = record
    Background: TColor;
    HotBackground: TColor;
    PressedBackground: TColor;
    DisabledBackground: TColor;
    Border: TColor;
    HotBorder: TColor;
    PressedBorder: TColor;
    FocusedBorder: TColor;
    DisabledBorder: TColor;
    Text: TColor;
    HotText: TColor;
    PressedText: TColor;
    DisabledText: TColor;
  end;

  TSimpleUIButton = class(TCustomControl)
  private
    FBackgroundColor: TColor;
    FHotBackgroundColor: TColor;
    FPressedBackgroundColor: TColor;
    FDisabledBackgroundColor: TColor;
    FBorderColor: TColor;
    FHotBorderColor: TColor;
    FPressedBorderColor: TColor;
    FFocusedBorderColor: TColor;
    FDisabledBorderColor: TColor;
    FTextColor: TColor;
    FHotTextColor: TColor;
    FPressedTextColor: TColor;
    FDisabledTextColor: TColor;
    FBorderWidth: Single;
    FCornerRadius: Integer;
    FContentPadding: Integer;
    FImageSpacing: Integer;
    FImages: TCustomImageList;
    FImageChangeLink: TChangeLink;
    FImageIndex: System.UITypes.TImageIndex;
    FImageName: System.UITypes.TImageName;
    FImagePosition: TSimpleUIButtonImagePosition;
    FHot: Boolean;
    FPressed: Boolean;
    FKeyboardPressed: Boolean;
    FActive: Boolean;
    FDefault: Boolean;
    FCancel: Boolean;
    FModalResult: TModalResult;
    procedure CMCancelMode(var AMessage: TCMCancelMode); message CM_CANCELMODE;
    procedure CMDialogChar(var AMessage: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMDialogKey(var AMessage: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMEnabledChanged(var AMessage: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFocusChanged(var AMessage: TCMFocusChanged); message CM_FOCUSCHANGED;
    procedure CMMouseEnter(var AMessage: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMessage: TMessage); message CM_MOUSELEAVE;
    procedure CMTextChanged(var AMessage: TMessage); message CM_TEXTCHANGED;
    procedure WMEraseBkgnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure ImagesChanged(Sender: TObject);
    function ResolveImageIndex: System.UITypes.TImageIndex;
    procedure SetBackgroundColor(const AValue: TColor);
    procedure SetBorderColor(const AValue: TColor);
    procedure SetBorderWidth(const AValue: Single);
    procedure SetCancel(const AValue: Boolean);
    procedure SetContentPadding(const AValue: Integer);
    procedure SetCornerRadius(const AValue: Integer);
    procedure SetDefault(const AValue: Boolean);
    procedure SetDisabledBackgroundColor(const AValue: TColor);
    procedure SetDisabledBorderColor(const AValue: TColor);
    procedure SetDisabledTextColor(const AValue: TColor);
    procedure SetFocusedBorderColor(const AValue: TColor);
    procedure SetHotBackgroundColor(const AValue: TColor);
    procedure SetHotBorderColor(const AValue: TColor);
    procedure SetHotTextColor(const AValue: TColor);
    procedure SetImageIndex(const AValue: System.UITypes.TImageIndex);
    procedure SetImageName(const AValue: System.UITypes.TImageName);
    procedure SetImagePosition(const AValue: TSimpleUIButtonImagePosition);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetImageSpacing(const AValue: Integer);
    procedure SetPressedBackgroundColor(const AValue: TColor);
    procedure SetPressedBorderColor(const AValue: TColor);
    procedure SetPressedTextColor(const AValue: TColor);
    procedure SetTextColor(const AValue: TColor);
  protected
    procedure KeyDown(var AKey: Word; AShift: TShiftState); override;
    procedure KeyUp(var AKey: Word; AShift: TShiftState); override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState;
      X, Y: Integer); override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ApplyPalette(const APalette: TSimpleUIButtonPalette);
    procedure Click; override;
  published
    property Action;
    property Align;
    property Anchors;
    property BackgroundColor: TColor read FBackgroundColor
      write SetBackgroundColor;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
    property BorderWidth: Single read FBorderWidth write SetBorderWidth;
    property Cancel: Boolean read FCancel write SetCancel default False;
    property Caption;
    property Constraints;
    property ContentPadding: Integer read FContentPadding
      write SetContentPadding;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius;
    property Cursor;
    property Default: Boolean read FDefault write SetDefault default False;
    property DisabledBackgroundColor: TColor read FDisabledBackgroundColor
      write SetDisabledBackgroundColor;
    property DisabledBorderColor: TColor read FDisabledBorderColor
      write SetDisabledBorderColor;
    property DisabledTextColor: TColor read FDisabledTextColor
      write SetDisabledTextColor;
    property Enabled;
    property FocusedBorderColor: TColor read FFocusedBorderColor
      write SetFocusedBorderColor;
    property Font;
    property Height;
    property Hint;
    property HotBackgroundColor: TColor read FHotBackgroundColor
      write SetHotBackgroundColor;
    property HotBorderColor: TColor read FHotBorderColor
      write SetHotBorderColor;
    property HotTextColor: TColor read FHotTextColor write SetHotTextColor;
    property ImageIndex: System.UITypes.TImageIndex read FImageIndex
      write SetImageIndex;
    property ImageName: System.UITypes.TImageName read FImageName
      write SetImageName;
    property ImagePosition: TSimpleUIButtonImagePosition read FImagePosition
      write SetImagePosition default buipLeft;
    property Images: TCustomImageList read FImages write SetImages;
    property ImageSpacing: Integer read FImageSpacing write SetImageSpacing;
    property ModalResult: TModalResult read FModalResult write FModalResult
      default mrNone;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property PressedBackgroundColor: TColor read FPressedBackgroundColor
      write SetPressedBackgroundColor;
    property PressedBorderColor: TColor read FPressedBorderColor
      write SetPressedBorderColor;
    property PressedTextColor: TColor read FPressedTextColor
      write SetPressedTextColor;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property TextColor: TColor read FTextColor write SetTextColor;
    property Visible;
    property Width;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
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
procedure DrawAntialiasedRoundedRectangle(const ACanvas: TCanvas;
  const ARect: TRect; AFillColor, ABorderColor: TColor; ARadius,
  ABorderWidth: Single);
procedure DrawDashedRoundedRectangle(const ACanvas: TCanvas;
  const ARect: TRect; ABorderColor: TColor; ARadius: Integer);
procedure DrawSelectionBar(const Canvas: TCanvas; const ARect: TRect; FillColor, BorderColor: TColor);
procedure DrawSplitterLine(const ACanvas: TCanvas; const ARect: TRect; AIsVertical: Boolean; AColor: TColor);
procedure DrawExplorerChevron(const ACanvas: TCanvas; const ACenter: TPoint;
  AColor: TColor; ADirection: TExplorerChevronDirection;
  ADeviceScale: Single = 1.0);
function ExplorerTabPalette(const ATheme: TExplorerTheme): TExplorerTabPalette;
function ExplorerButtonPalette(
  const ATheme: TExplorerTheme): TSimpleUIButtonPalette;
procedure ApplyExplorerThemeToButton(AButton: TSimpleUIButton;
  const ATheme: TExplorerTheme);
function IsWindows11: Boolean;
function IsLightThemeActive: Boolean;
function IsWindowsLightTheme: Boolean;
function FormatByteSize(AByteCount: Int64): string;

implementation

uses
  Winapi.Windows, System.Win.Registry, Vcl.GraphUtil, Winapi.GDIPAPI, Winapi.GDIPOBJ,
  System.Math, System.SysUtils, Vcl.Themes;

const
  cBorderBlend = 0.82;
  cInactiveTopBlend = 0.97;
  cHoverTopBlend = 0.82;
  cCloseHoverBlend = 0.72;

function ColorToGPColor(AColor: TColor): TGPColor;
begin
  var LColor := ColorToRGB(AColor);
  Result := MakeColor(255, GetRValue(LColor), GetGValue(LColor),
    GetBValue(LColor));
end;

function CreateRoundedRectanglePath(const ARect: TRect;
  ARadius: Single): TGPGraphicsPath;
begin
  Result := TGPGraphicsPath.Create;
  var LLeft := ARect.Left + 0.5;
  var LTop := ARect.Top + 0.5;
  var LRight := ARect.Right - 0.5;
  var LBottom := ARect.Bottom - 0.5;
  var LRadius := EnsureRange(ARadius, 0.0,
    Min((LRight - LLeft) / 2.0, (LBottom - LTop) / 2.0));
  if LRadius <= 0.0 then
  begin
    Result.AddRectangle(MakeRect(LLeft, LTop, LRight - LLeft,
      LBottom - LTop));
    Exit;
  end;

  var LDiameter := LRadius * 2.0;
  Result.AddArc(LLeft, LTop, LDiameter, LDiameter, 180, 90);
  Result.AddLine(LLeft + LRadius, LTop, LRight - LRadius, LTop);
  Result.AddArc(LRight - LDiameter, LTop, LDiameter, LDiameter, 270, 90);
  Result.AddLine(LRight, LTop + LRadius, LRight, LBottom - LRadius);
  Result.AddArc(LRight - LDiameter, LBottom - LDiameter, LDiameter,
    LDiameter, 0, 90);
  Result.AddLine(LRight - LRadius, LBottom, LLeft + LRadius, LBottom);
  Result.AddArc(LLeft, LBottom - LDiameter, LDiameter, LDiameter, 90, 90);
  Result.AddLine(LLeft, LBottom - LRadius, LLeft, LTop + LRadius);
  Result.CloseFigure;
end;

{ TSimpleUIButton }

constructor TSimpleUIButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csClickEvents, csCaptureMouse,
    csDoubleClicks, csOpaque];
  DoubleBuffered := True;
  ParentColor := True;
  TabStop := True;
  SetBounds(0, 0, 80, 25);
  FBackgroundColor := clBtnFace;
  FHotBackgroundColor := clBtnHighlight;
  FPressedBackgroundColor := clBtnShadow;
  FDisabledBackgroundColor := clBtnFace;
  FBorderColor := clBtnShadow;
  FHotBorderColor := clHighlight;
  FPressedBorderColor := clHighlight;
  FFocusedBorderColor := clHighlight;
  FDisabledBorderColor := clBtnShadow;
  FTextColor := clBtnText;
  FHotTextColor := clBtnText;
  FPressedTextColor := clBtnText;
  FDisabledTextColor := clGrayText;
  FBorderWidth := 1.0;
  FCornerRadius := 4;
  FContentPadding := 8;
  FImageSpacing := 6;
  FImageIndex := -1;
  FImagePosition := buipLeft;
  FModalResult := mrNone;
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImagesChanged;
end;

destructor TSimpleUIButton.Destroy;
begin
  Images := nil;
  FImageChangeLink.Free;
  inherited;
end;

procedure TSimpleUIButton.ApplyPalette(
  const APalette: TSimpleUIButtonPalette);
begin
  FBackgroundColor := APalette.Background;
  FHotBackgroundColor := APalette.HotBackground;
  FPressedBackgroundColor := APalette.PressedBackground;
  FDisabledBackgroundColor := APalette.DisabledBackground;
  FBorderColor := APalette.Border;
  FHotBorderColor := APalette.HotBorder;
  FPressedBorderColor := APalette.PressedBorder;
  FFocusedBorderColor := APalette.FocusedBorder;
  FDisabledBorderColor := APalette.DisabledBorder;
  FTextColor := APalette.Text;
  FHotTextColor := APalette.HotText;
  FPressedTextColor := APalette.PressedText;
  FDisabledTextColor := APalette.DisabledText;
  Invalidate;
end;

procedure TSimpleUIButton.Click;
begin
  var LForm := GetParentForm(Self);
  if Assigned(LForm) then
    LForm.ModalResult := FModalResult;
  inherited;
end;

procedure TSimpleUIButton.CMCancelMode(var AMessage: TCMCancelMode);
begin
  inherited;
  if AMessage.Sender <> Self then
  begin
    FPressed := False;
    FKeyboardPressed := False;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.CMDialogChar(var AMessage: TCMDialogChar);
begin
  if IsAccel(AMessage.CharCode, Caption) and CanFocus then
  begin
    Click;
    AMessage.Result := 1;
  end
  else
    inherited;
end;

procedure TSimpleUIButton.CMDialogKey(var AMessage: TCMDialogKey);
begin
  if ((((AMessage.CharCode = VK_RETURN) and FActive) or
    ((AMessage.CharCode = VK_ESCAPE) and FCancel)) and
    (KeyDataToShiftState(AMessage.KeyData) = []) and CanFocus) then
  begin
    Click;
    AMessage.Result := 1;
  end
  else
    inherited;
end;

procedure TSimpleUIButton.CMEnabledChanged(var AMessage: TMessage);
begin
  inherited;
  FPressed := False;
  FKeyboardPressed := False;
  Invalidate;
end;

procedure TSimpleUIButton.CMFocusChanged(var AMessage: TCMFocusChanged);
begin
  if AMessage.Sender is TSimpleUIButton then
    FActive := AMessage.Sender = Self
  else
    FActive := FDefault;
  inherited;
  Invalidate;
end;

procedure TSimpleUIButton.CMMouseEnter(var AMessage: TMessage);
begin
  inherited;
  FHot := True;
  Invalidate;
end;

procedure TSimpleUIButton.CMMouseLeave(var AMessage: TMessage);
begin
  inherited;
  FHot := False;
  Invalidate;
end;

procedure TSimpleUIButton.CMTextChanged(var AMessage: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TSimpleUIButton.ImagesChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TSimpleUIButton.KeyDown(var AKey: Word; AShift: TShiftState);
begin
  inherited;
  if Enabled and (AKey = VK_SPACE) and not FKeyboardPressed then
  begin
    FKeyboardPressed := True;
    Invalidate;
    AKey := 0;
  end;
end;

procedure TSimpleUIButton.KeyUp(var AKey: Word; AShift: TShiftState);
begin
  inherited;
  if FKeyboardPressed and (AKey = VK_SPACE) then
  begin
    FKeyboardPressed := False;
    Invalidate;
    Click;
    AKey := 0;
  end;
end;

procedure TSimpleUIButton.MouseDown(AButton: TMouseButton;
  AShift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Enabled and (AButton = mbLeft) then
  begin
    if CanFocus then
      SetFocus;
    FPressed := True;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.MouseUp(AButton: TMouseButton; AShift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if AButton = mbLeft then
  begin
    FPressed := False;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImages) then
    Images := nil;
end;

procedure TSimpleUIButton.Paint;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then
    Exit;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  var LBackgroundColor := FBackgroundColor;
  var LBorderColor := FBorderColor;
  var LTextColor := FTextColor;
  if not Enabled then
  begin
    LBackgroundColor := FDisabledBackgroundColor;
    LBorderColor := FDisabledBorderColor;
    LTextColor := FDisabledTextColor;
  end
  else if FPressed or FKeyboardPressed then
  begin
    LBackgroundColor := FPressedBackgroundColor;
    LBorderColor := FPressedBorderColor;
    LTextColor := FPressedTextColor;
  end
  else if FHot then
  begin
    LBackgroundColor := FHotBackgroundColor;
    LBorderColor := FHotBorderColor;
    LTextColor := FHotTextColor;
  end;
  if Focused and Enabled then
    LBorderColor := FFocusedBorderColor;

  DrawAntialiasedRoundedRectangle(Canvas, ClientRect, LBackgroundColor,
    LBorderColor, ScaleValue(FCornerRadius),
    ScaleValue(Round(FBorderWidth * 10.0)) / 10.0);

  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := LTextColor;
  var LContentRect := ClientRect;
  InflateRect(LContentRect, -ScaleValue(FContentPadding), 0);
  if (LContentRect.Width <= 0) or (LContentRect.Height <= 0) then
    Exit;

  var LImageIndex := ResolveImageIndex;
  var LHasImage := LImageIndex >= 0;
  var LHasText := Caption <> '';
  var LImageWidth := 0;
  var LImageHeight := 0;
  if LHasImage then
  begin
    LImageWidth := FImages.Width;
    LImageHeight := FImages.Height;
  end;
  var LSpacing := 0;
  if LHasImage and LHasText then
    LSpacing := ScaleValue(FImageSpacing);

  var LTextMeasureRect := Rect(0, 0, 0, 0);
  if LHasText then
    DrawText(Canvas.Handle, PChar(Caption), Length(Caption),
      LTextMeasureRect, DT_CALCRECT or DT_SINGLELINE);
  var LTextWidth := LTextMeasureRect.Width;
  var LTextHeight := LTextMeasureRect.Height;
  var LImageRect := TRect.Empty;
  var LTextRect := TRect.Empty;

  if FImagePosition in [buipLeft, buipRight] then
  begin
    var LAvailableTextWidth := Max(0, LContentRect.Width - LImageWidth -
      LSpacing);
    LTextWidth := Min(LTextWidth, LAvailableTextWidth);
    var LGroupWidth := LImageWidth + LSpacing + LTextWidth;
    var LLeft := LContentRect.Left + Max(0,
      (LContentRect.Width - LGroupWidth) div 2);
    var LImageTop := LContentRect.Top +
      (LContentRect.Height - LImageHeight) div 2;
    if FImagePosition = buipLeft then
    begin
      LImageRect := Rect(LLeft, LImageTop, LLeft + LImageWidth,
        LImageTop + LImageHeight);
      LTextRect := Rect(LImageRect.Right + LSpacing, LContentRect.Top,
        LImageRect.Right + LSpacing + LTextWidth, LContentRect.Bottom);
    end
    else
    begin
      LTextRect := Rect(LLeft, LContentRect.Top, LLeft + LTextWidth,
        LContentRect.Bottom);
      LImageRect := Rect(LTextRect.Right + LSpacing, LImageTop,
        LTextRect.Right + LSpacing + LImageWidth,
        LImageTop + LImageHeight);
    end;
  end
  else
  begin
    var LAvailableTextHeight := Max(0, LContentRect.Height - LImageHeight -
      LSpacing);
    LTextHeight := Min(LTextHeight, LAvailableTextHeight);
    var LGroupHeight := LImageHeight + LSpacing + LTextHeight;
    var LTop := LContentRect.Top + Max(0,
      (LContentRect.Height - LGroupHeight) div 2);
    var LImageLeft := LContentRect.Left +
      (LContentRect.Width - LImageWidth) div 2;
    if FImagePosition = buipTop then
    begin
      LImageRect := Rect(LImageLeft, LTop, LImageLeft + LImageWidth,
        LTop + LImageHeight);
      LTextRect := Rect(LContentRect.Left, LImageRect.Bottom + LSpacing,
        LContentRect.Right, LImageRect.Bottom + LSpacing + LTextHeight);
    end
    else
    begin
      LTextRect := Rect(LContentRect.Left, LTop, LContentRect.Right,
        LTop + LTextHeight);
      LImageRect := Rect(LImageLeft, LTextRect.Bottom + LSpacing,
        LImageLeft + LImageWidth,
        LTextRect.Bottom + LSpacing + LImageHeight);
    end;
  end;

  if LHasImage then
    FImages.Draw(Canvas, LImageRect.Left, LImageRect.Top, LImageIndex,
      Enabled);
  if LHasText then
    DrawText(Canvas.Handle, PChar(Caption), Length(Caption), LTextRect,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
end;

function TSimpleUIButton.ResolveImageIndex: System.UITypes.TImageIndex;
begin
  Result := -1;
  if not Assigned(FImages) then
    Exit;
  var LImageName := FImageName;
  Result := FImageIndex;
  FImages.CheckIndexAndName(Result, LImageName);
  if (Result < 0) or (Result >= FImages.Count) then
    Result := -1;
end;

procedure TSimpleUIButton.SetBackgroundColor(const AValue: TColor);
begin
  if FBackgroundColor <> AValue then
  begin
    FBackgroundColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetBorderColor(const AValue: TColor);
begin
  if FBorderColor <> AValue then
  begin
    FBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetBorderWidth(const AValue: Single);
begin
  var LValue := Max(0.0, AValue);
  if not SameValue(FBorderWidth, LValue) then
  begin
    FBorderWidth := LValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetCancel(const AValue: Boolean);
begin
  FCancel := AValue;
end;

procedure TSimpleUIButton.SetContentPadding(const AValue: Integer);
begin
  var LValue := Max(0, AValue);
  if FContentPadding <> LValue then
  begin
    FContentPadding := LValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetCornerRadius(const AValue: Integer);
begin
  var LValue := Max(0, AValue);
  if FCornerRadius <> LValue then
  begin
    FCornerRadius := LValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetDefault(const AValue: Boolean);
begin
  if FDefault <> AValue then
  begin
    FDefault := AValue;
    FActive := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetDisabledBackgroundColor(const AValue: TColor);
begin
  if FDisabledBackgroundColor <> AValue then
  begin
    FDisabledBackgroundColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetDisabledBorderColor(const AValue: TColor);
begin
  if FDisabledBorderColor <> AValue then
  begin
    FDisabledBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetDisabledTextColor(const AValue: TColor);
begin
  if FDisabledTextColor <> AValue then
  begin
    FDisabledTextColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetFocusedBorderColor(const AValue: TColor);
begin
  if FFocusedBorderColor <> AValue then
  begin
    FFocusedBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetHotBackgroundColor(const AValue: TColor);
begin
  if FHotBackgroundColor <> AValue then
  begin
    FHotBackgroundColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetHotBorderColor(const AValue: TColor);
begin
  if FHotBorderColor <> AValue then
  begin
    FHotBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetHotTextColor(const AValue: TColor);
begin
  if FHotTextColor <> AValue then
  begin
    FHotTextColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetImageIndex(
  const AValue: System.UITypes.TImageIndex);
begin
  if (FImageIndex <> AValue) or (FImageName <> '') then
  begin
    FImageIndex := AValue;
    FImageName := '';
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetImageName(
  const AValue: System.UITypes.TImageName);
begin
  if (FImageName <> AValue) or (FImageIndex <> -1) then
  begin
    FImageName := AValue;
    FImageIndex := -1;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetImagePosition(
  const AValue: TSimpleUIButtonImagePosition);
begin
  if FImagePosition <> AValue then
  begin
    FImagePosition := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetImages(const AValue: TCustomImageList);
begin
  if FImages = AValue then
    Exit;
  if Assigned(FImages) then
  begin
    FImages.UnRegisterChanges(FImageChangeLink);
    FImages.RemoveFreeNotification(Self);
  end;
  FImages := AValue;
  if Assigned(FImages) then
  begin
    FImages.RegisterChanges(FImageChangeLink);
    FImages.FreeNotification(Self);
  end;
  Invalidate;
end;

procedure TSimpleUIButton.SetImageSpacing(const AValue: Integer);
begin
  var LValue := Max(0, AValue);
  if FImageSpacing <> LValue then
  begin
    FImageSpacing := LValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetPressedBackgroundColor(const AValue: TColor);
begin
  if FPressedBackgroundColor <> AValue then
  begin
    FPressedBackgroundColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetPressedBorderColor(const AValue: TColor);
begin
  if FPressedBorderColor <> AValue then
  begin
    FPressedBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetPressedTextColor(const AValue: TColor);
begin
  if FPressedTextColor <> AValue then
  begin
    FPressedTextColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetTextColor(const AValue: TColor);
begin
  if FTextColor <> AValue then
  begin
    FTextColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
begin
  AMessage.Result := 1;
end;

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

function ExplorerTabPalette(const ATheme: TExplorerTheme): TExplorerTabPalette;
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

function ExplorerButtonPalette(
  const ATheme: TExplorerTheme): TSimpleUIButtonPalette;
const
  cButtonBackgroundBlend = 0.94;
  cButtonHotBackgroundBlend = 0.88;
  cButtonPressedBackgroundBlend = 0.74;
  cButtonDisabledBackgroundBlend = 0.98;
  cButtonBorderBlend = 0.78;
begin
  Result.Background := ColorBlendRGB(ATheme.TextColor,
    ATheme.BackgroundColor, cButtonBackgroundBlend);
  Result.HotBackground := ColorBlendRGB(ATheme.SelectionColor,
    ATheme.BackgroundColor, cButtonHotBackgroundBlend);
  Result.PressedBackground := ColorBlendRGB(ATheme.SelectionColor,
    ATheme.BackgroundColor, cButtonPressedBackgroundBlend);
  Result.DisabledBackground := ColorBlendRGB(ATheme.TextColor,
    ATheme.BackgroundColor, cButtonDisabledBackgroundBlend);
  Result.Border := ColorBlendRGB(ATheme.TextColor,
    ATheme.BackgroundColor, cButtonBorderBlend);
  Result.HotBorder := ATheme.SelectionColor;
  Result.PressedBorder := ATheme.SelectionColor;
  Result.FocusedBorder := ATheme.SelectionColor;
  Result.DisabledBorder := ATheme.GhostColor;
  Result.Text := ATheme.TextColor;
  Result.HotText := ATheme.TextColor;
  Result.PressedText := ATheme.TextColor;
  Result.DisabledText := ATheme.InactiveText;
end;

procedure ApplyExplorerThemeToButton(AButton: TSimpleUIButton;
  const ATheme: TExplorerTheme);
begin
  if not Assigned(AButton) then
    Exit;
  AButton.ApplyPalette(ExplorerButtonPalette(ATheme));
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

procedure DrawAntialiasedRoundedRectangle(const ACanvas: TCanvas;
  const ARect: TRect; AFillColor, ABorderColor: TColor; ARadius,
  ABorderWidth: Single);
begin
  if (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  var LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    var LPath := CreateRoundedRectanglePath(ARect, ARadius);
    try
      if AFillColor <> clNone then
      begin
        var LBrush := TGPSolidBrush.Create(ColorToGPColor(AFillColor));
        try
          LGraphics.FillPath(LBrush, LPath);
        finally
          LBrush.Free;
        end;
      end;
      if (ABorderColor <> clNone) and (ABorderWidth > 0.0) then
      begin
        var LPen := TGPPen.Create(ColorToGPColor(ABorderColor),
          ABorderWidth);
        try
          LPen.SetLineJoin(LineJoinRound);
          LGraphics.DrawPath(LPen, LPath);
        finally
          LPen.Free;
        end;
      end;
    finally
      LPath.Free;
    end;
  finally
    LGraphics.Free;
  end;
end;

procedure DrawRoundedBar(const Canvas: TCanvas; const ARect: TRect;
  FillColor, BorderColor: TColor; const Radius: Single = 2.0);
begin
  DrawAntialiasedRoundedRectangle(Canvas, ARect, FillColor, BorderColor,
    Radius, 1.0);
end;

procedure DrawDashedRoundedRectangle(const ACanvas: TCanvas;
  const ARect: TRect; ABorderColor: TColor; ARadius: Integer);
var
  LDashPattern: array[0..1] of Single;
begin
  var LRect := ARect;
  InflateRect(LRect, -1, -1);
  if (LRect.Width <= 2) or (LRect.Height <= 2) then
    Exit;

  var LRadius := ARadius;
  if LRadius < 1 then
    LRadius := 1;
  if LRadius * 2 > LRect.Width then
    LRadius := LRect.Width div 2;
  if LRadius * 2 > LRect.Height then
    LRadius := LRect.Height div 2;

  var LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    var LPen := TGPPen.Create(ColorToGPColor(ABorderColor), 2.5);
    try
      LDashPattern[0] := 4.0;
      LDashPattern[1] := 2.5;
      LPen.SetDashStyle(DashStyleCustom);
      LPen.SetDashPattern(@LDashPattern[0], Length(LDashPattern));
      LPen.SetDashCap(DashCapFlat);
      LPen.SetLineJoin(LineJoinRound);
      var LPath := CreateRoundedRectanglePath(LRect, LRadius);
      try
        LGraphics.DrawPath(LPen, LPath);
      finally
        LPath.Free;
      end;
    finally
      LPen.Free;
    end;
  finally
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
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    var LPen := TGPPen.Create(LColor, 1.0);
    try
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
    end;
  finally
    LGraphics.Free;
  end;
end;

procedure DrawExplorerChevron(const ACanvas: TCanvas; const ACenter: TPoint;
  AColor: TColor; ADirection: TExplorerChevronDirection;
  ADeviceScale: Single);
begin
  var LRGBColor: TColor := ColorToRGB(AColor);
  var LColor: TGPColor := MakeColor(255, GetRValue(LRGBColor), GetGValue(LRGBColor),
    GetBValue(LRGBColor));
  var LHalfWidth: Single := 3.0 * ADeviceScale;
  var LHalfHeight: Single := 2.0 * ADeviceScale;
  var LGraphics: TGPGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    var LPen := TGPPen.Create(LColor, 1.6 * ADeviceScale);
    try
      LPen.SetLineJoin(LineJoinRound);
      LPen.SetStartCap(LineCapRound);
      LPen.SetEndCap(LineCapRound);
      case ADirection of
        ecdUp:
          begin
            LGraphics.DrawLine(LPen, ACenter.X - LHalfWidth,
              ACenter.Y + (LHalfHeight / 2), ACenter.X,
              ACenter.Y - LHalfHeight);
            LGraphics.DrawLine(LPen, ACenter.X, ACenter.Y - LHalfHeight,
              ACenter.X + LHalfWidth, ACenter.Y + (LHalfHeight / 2));
          end;
        ecdDown:
          begin
            LGraphics.DrawLine(LPen, ACenter.X - LHalfWidth,
              ACenter.Y - (LHalfHeight / 2), ACenter.X,
              ACenter.Y + LHalfHeight);
            LGraphics.DrawLine(LPen, ACenter.X, ACenter.Y + LHalfHeight,
              ACenter.X + LHalfWidth, ACenter.Y - (LHalfHeight / 2));
          end;
      end;
    finally
      LPen.Free;
    end;
  finally
    LGraphics.Free;
  end;
end;


end.
