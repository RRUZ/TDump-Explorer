//**************************************************************************************************
//
// Unit TDump.Explorer.GlassTabs
//
// Provides the owner-drawn GDI+ tab strip used by TDump Explorer, including
// configurable palettes, gradients, tab actions, and high-DPI rendering.
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.GlassTabs;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.UITypes, Vcl.Controls, Vcl.Graphics, Vcl.ImgList;

type
  TGlassGradientDirection = (ggdVertical, ggdHorizontal,
    ggdForwardDiagonal, ggdBackwardDiagonal);

  TGlassTabItem = class(TCollectionItem)
  private
    FCaption: string;
    FClosable: Boolean;
    FImageIndex: System.UITypes.TImageIndex;
    FImageName: System.UITypes.TImageName;
    procedure SetCaption(const AValue: string);
    procedure SetClosable(const AValue: Boolean);
    procedure SetImageIndex(const AValue: System.UITypes.TImageIndex);
    procedure SetImageName(const AValue: System.UITypes.TImageName);
  public
    constructor Create(ACollection: TCollection); override;
  published
    property Caption: string read FCaption write SetCaption;
    property Closable: Boolean read FClosable write SetClosable default True;
    property ImageIndex: System.UITypes.TImageIndex read FImageIndex
      write SetImageIndex default -1;
    property ImageName: System.UITypes.TImageName read FImageName
      write SetImageName;
  end;

  TGlassTabItems = class(TOwnedCollection)
  private
    FOnChanged: TNotifyEvent;
    function GetItem(AIndex: Integer): TGlassTabItem;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TGlassTabItem;
    property Items[AIndex: Integer]: TGlassTabItem read GetItem; default;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  TGlassTabPalette = record
    StripTop, StripBottom, StripBorder, BackgroundTopLine: TColor;
    TabTop, TabBottom, InactiveTop, InactiveBottom: TColor;
    HoverTop, HoverBottom, Accent: TColor;
    Text, InactiveText, CloseHover: TColor;
  end;

  TTabChangingEvent = procedure(Sender: TObject; ANewIndex: Integer) of object;
  TTabCloseEvent = procedure(Sender: TObject; AIndex: Integer; var ACanClose: Boolean) of object;
  TGlassTabBackgroundPaintEvent = procedure(ACanvas: TCanvas;
    const ARect: TRect) of object;
  TGlassTabPaintEvent = procedure(ACanvas: TCanvas; const ARect: TRect;
    ATabIndex: Integer; ASelected, AHot: Boolean) of object;

  TGlassTabStrip = class(TCustomControl)
  private
    const
      CDefaultTabHeight = 38;
      CDefaultLeftInset = 8;
      CTabTop = 6;
      CSelectedShoulderWidth = 14;
      CAddButtonWidth = 36;
      CChevronButtonWidth = 28;
      CTextHeight = 12;
      CButtonHoverHalfWidth = 14;
      CButtonHoverHalfHeight = 12;
      CButtonHoverRadius = 6;
      CBaselineOffset = 1;
  private
    FItems: TGlassTabItems;
    FImages: TCustomImageList;
    FImageChangeLink: TChangeLink;
    FPalette: TGlassTabPalette;
    FActiveIndex, FHotIndex, FHotCloseIndex, FPressedCloseIndex: Integer;
    FShowAddButton: Boolean;
    FHotAddButton: Boolean;
    FPressedAddButton: Boolean;
    FShowChevronButton: Boolean;
    FHotChevronButton: Boolean;
    FPressedChevronButton: Boolean;
    FButtonHoverGlow: Boolean;
    FButtonHoverBackground: Boolean;
    FBackgroundGradientDirection: TGlassGradientDirection;
    FTabGradientDirection: TGlassGradientDirection;
    FLeftInset: Integer;
    FTabHeight: Integer;
    FMinTabWidth: Integer;
    FMaxTabWidth: Integer;
    FTabOverlap: Integer;
    FAddButtonSpacing: Integer;
    FFirstVisibleIndex: Integer;
    FHotLeftNavigation: Boolean;
    FHotRightNavigation: Boolean;
    FOnChange: TTabChangingEvent;
    FOnCloseTab: TTabCloseEvent;
    FOnAddButtonClick: TNotifyEvent;
    FOnChevronButtonClick: TNotifyEvent;
    FOnBackgroundMouseDown: TMouseEvent;
    FOnBackgroundDblClick: TMouseEvent;
    FOnAfterPaintBackground: TGlassTabBackgroundPaintEvent;
    FOnAfterPaintTab: TGlassTabPaintEvent;
    procedure Changed(Sender: TObject);
    procedure ImagesChanged(Sender: TObject);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetItems(const AValue: TGlassTabItems);
    procedure SetPalette(const AValue: TGlassTabPalette);
    function GetBackgroundGradientStartColor: TColor;
    function GetBackgroundGradientEndColor: TColor;
    procedure SetBackgroundGradientStartColor(const AValue: TColor);
    procedure SetBackgroundGradientEndColor(const AValue: TColor);
    function GetBackgroundTopLineColor: TColor;
    procedure SetBackgroundTopLineColor(const AValue: TColor);
    procedure SetBackgroundGradientDirection(
      const AValue: TGlassGradientDirection);
    procedure SetTabGradientDirection(const AValue: TGlassGradientDirection);
    function GetTabGradientStartColor: TColor;
    function GetTabGradientEndColor: TColor;
    procedure SetTabGradientStartColor(const AValue: TColor);
    procedure SetTabGradientEndColor(const AValue: TColor);
    function GetTabHeight: Integer;
    procedure SetTabHeight(const AValue: Integer);
    procedure SetActiveIndex(const AValue: Integer);
    procedure SetShowAddButton(const AValue: Boolean);
    procedure SetShowChevronButton(const AValue: Boolean);
    procedure SetButtonHoverGlow(const AValue: Boolean);
    procedure SetButtonHoverBackground(const AValue: Boolean);
    procedure SetLeftInset(const AValue: Integer);
    function GetTabRect(AIndex: Integer): TRect;
    function GetTabWidth(AIndex: Integer): Integer;
    function GetCloseRect(AIndex: Integer): TRect;
    function GetAddButtonRect: TRect;
    function GetChevronButtonRect: TRect;
    function GetTabsViewport: TRect;
    function GetAvailableBackgroundRect: TRect;
    function GetLeftNavigationRect: TRect;
    function GetRightNavigationRect: TRect;
    function IsOverflowing: Boolean;
    function IsAddButtonVisible: Boolean;
    function IsChevronButtonVisible: Boolean;
    function CanNavigateLeft: Boolean;
    function CanNavigateRight: Boolean;
    procedure EnsureActiveTabVisible;
    function ResolveImageIndex(
      AItem: TGlassTabItem): System.UITypes.TImageIndex;
    function TabAt(const APoint: TPoint): Integer;
    function CloseAt(const APoint: TPoint): Integer;
    procedure DrawTab(ACanvas: TCanvas; AIndex: Integer; ASelected: Boolean);
    procedure DrawNavigationButton(ACanvas: TCanvas; const ARect: TRect;
      ALeft, AHot, AEnabled: Boolean);
    procedure DrawChevronButton(ACanvas: TCanvas; const ARect: TRect;
      AHot: Boolean);
  protected
    procedure DoAddButtonClick; virtual;
    procedure DoChevronButtonClick; virtual;
    procedure DoAfterPaintBackground(ACanvas: TCanvas;
      const ARect: TRect); virtual;
    procedure DoAfterPaintTab(ACanvas: TCanvas; const ARect: TRect;
      ATabIndex: Integer; ASelected, AHot: Boolean); virtual;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure Paint; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AddTab(const ACaption: string;
      AImageIndex: System.UITypes.TImageIndex = -1;
      AClosable: Boolean = True; AActivate: Boolean = True); overload;
    procedure AddTab(const ACaption: string;
      const AImageName: System.UITypes.TImageName;
      AClosable: Boolean = True; AActivate: Boolean = True); overload;
    procedure DeleteTab(AIndex: Integer);
    property TabRect[AIndex: Integer]: TRect read GetTabRect;
    { Source-compatible alias for clients using the original event name. }
    property OnAddTab: TNotifyEvent read FOnAddButtonClick
      write FOnAddButtonClick;
  published
    property Align;
    property Anchors;
    property Constraints;
    property Enabled;
    property Font;
    property PopupMenu;
    property ShowHint;
    property TabStop;
    property Visible;
    property Items: TGlassTabItems read FItems write SetItems;
    property Images: TCustomImageList read FImages write SetImages;
    property Palette: TGlassTabPalette read FPalette write SetPalette;
    property BackgroundGradientStartColor: TColor
      read GetBackgroundGradientStartColor
      write SetBackgroundGradientStartColor;
    property BackgroundGradientEndColor: TColor
      read GetBackgroundGradientEndColor write SetBackgroundGradientEndColor;
    property BackgroundTopLineColor: TColor read GetBackgroundTopLineColor
      write SetBackgroundTopLineColor;
    property BackgroundGradientDirection: TGlassGradientDirection
      read FBackgroundGradientDirection write SetBackgroundGradientDirection
      default ggdVertical;
    property TabGradientStartColor: TColor read GetTabGradientStartColor
      write SetTabGradientStartColor;
    property TabGradientEndColor: TColor read GetTabGradientEndColor
      write SetTabGradientEndColor;
    property TabGradientDirection: TGlassGradientDirection
      read FTabGradientDirection write SetTabGradientDirection
      default ggdVertical;
    property TabHeight: Integer read GetTabHeight write SetTabHeight
      default CDefaultTabHeight;
    property ActiveIndex: Integer read FActiveIndex write SetActiveIndex default -1;
    property ShowAddButton: Boolean read FShowAddButton write SetShowAddButton default True;
    property ShowChevronButton: Boolean read FShowChevronButton
      write SetShowChevronButton default True;
    property ButtonHoverGlow: Boolean read FButtonHoverGlow
      write SetButtonHoverGlow default False;
    property ButtonHoverBackground: Boolean read FButtonHoverBackground
      write SetButtonHoverBackground default True;
    property LeftInset: Integer read FLeftInset write SetLeftInset
      default CDefaultLeftInset;
    property OnChange: TTabChangingEvent read FOnChange write FOnChange;
    property OnCloseTab: TTabCloseEvent read FOnCloseTab write FOnCloseTab;
    property OnAddButtonClick: TNotifyEvent read FOnAddButtonClick
      write FOnAddButtonClick;
    property OnChevronButtonClick: TNotifyEvent read FOnChevronButtonClick
      write FOnChevronButtonClick;
    property OnBackgroundMouseDown: TMouseEvent read FOnBackgroundMouseDown
      write FOnBackgroundMouseDown;
    property OnBackgroundDblClick: TMouseEvent read FOnBackgroundDblClick
      write FOnBackgroundDblClick;
    property OnAfterPaintBackground: TGlassTabBackgroundPaintEvent
      read FOnAfterPaintBackground write FOnAfterPaintBackground;
    property OnAfterPaintTab: TGlassTabPaintEvent read FOnAfterPaintTab
      write FOnAfterPaintTab;
  end;

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ, System.Math;

function GradientMode(ADirection: TGlassGradientDirection): LinearGradientMode;
begin
  case ADirection of
    ggdHorizontal:
      Result := LinearGradientModeHorizontal;
    ggdForwardDiagonal:
      Result := LinearGradientModeForwardDiagonal;
    ggdBackwardDiagonal:
      Result := LinearGradientModeBackwardDiagonal;
  else
    Result := LinearGradientModeVertical;
  end;
end;

function ToArgb(AColor: TColor): ARGB; overload;
begin
  var LColor := ColorToRGB(AColor);
  Result := MakeColor(255, GetRValue(LColor), GetGValue(LColor), GetBValue(LColor));
end;

function C(ARed, AGreen, ABlue: Byte): TColor;
begin
  Result := RGB(ARed, AGreen, ABlue);
end;

function ToArgb(AColor: TColor; AAlpha: Byte): ARGB; overload;
begin
  var LColor := ColorToRGB(AColor);
  Result := MakeColor(AAlpha, GetRValue(LColor), GetGValue(LColor), GetBValue(LColor));
end;

function Pick(ACondition: Boolean; ATrue, AFalse: ARGB): ARGB;
begin
  if ACondition then Result := ATrue else Result := AFalse;
end;

function BlendColor(AForeground, ABackground: TColor; AAlpha: Byte): TColor;
begin
  var LFore := ColorToRGB(AForeground);
  var LBack := ColorToRGB(ABackground);
  Result := RGB(
    (GetRValue(LFore) * AAlpha + GetRValue(LBack) * (255 - AAlpha)) div 255,
    (GetGValue(LFore) * AAlpha + GetGValue(LBack) * (255 - AAlpha)) div 255,
    (GetBValue(LFore) * AAlpha + GetBValue(LBack) * (255 - AAlpha)) div 255);
end;

procedure DrawTwoLineGlow(AGraphics: TGPGraphics;
  AX1, AY1, AX2, AY2, BX1, BY1, BX2, BY2: Single;
  AAccent: TColor; AScale: Single);
begin
  var LOuter := TGPPen.Create(ToArgb(AAccent, 24), 5.0 * AScale);
  try
    var LInner := TGPPen.Create(ToArgb(AAccent, 76), 2.8 * AScale);
    try
      LOuter.SetStartCap(LineCapRound);
      LOuter.SetEndCap(LineCapRound);
      LInner.SetStartCap(LineCapRound);
      LInner.SetEndCap(LineCapRound);
      AGraphics.DrawLine(LOuter, AX1, AY1, AX2, AY2);
      AGraphics.DrawLine(LOuter, BX1, BY1, BX2, BY2);
      AGraphics.DrawLine(LInner, AX1, AY1, AX2, AY2);
      AGraphics.DrawLine(LInner, BX1, BY1, BX2, BY2);
    finally
      LInner.Free;
    end;
  finally
    LOuter.Free;
  end;
end;

procedure FillRoundedHover(AGraphics: TGPGraphics; const ABounds: TRect;
  ARadius: Integer; AColor: TColor);
begin
  var LDiameter := ARadius * 2;
  var LPath := TGPGraphicsPath.Create;
  try
    var LBrush := TGPSolidBrush.Create(ToArgb(AColor, 238));
    try
      LPath.AddArc(ABounds.Left, ABounds.Top, LDiameter, LDiameter, 180, 90);
      LPath.AddLine(ABounds.Left + ARadius, ABounds.Top,
        ABounds.Right - ARadius, ABounds.Top);
      LPath.AddArc(ABounds.Right - LDiameter, ABounds.Top,
        LDiameter, LDiameter, 270, 90);
      LPath.AddLine(ABounds.Right, ABounds.Top + ARadius,
        ABounds.Right, ABounds.Bottom - ARadius);
      LPath.AddArc(ABounds.Right - LDiameter, ABounds.Bottom - LDiameter,
        LDiameter, LDiameter, 0, 90);
      LPath.AddLine(ABounds.Right - ARadius, ABounds.Bottom,
        ABounds.Left + ARadius, ABounds.Bottom);
      LPath.AddArc(ABounds.Left, ABounds.Bottom - LDiameter,
        LDiameter, LDiameter, 90, 90);
      LPath.AddLine(ABounds.Left, ABounds.Bottom - ARadius,
        ABounds.Left, ABounds.Top + ARadius);
      LPath.CloseFigure;
      AGraphics.FillPath(LBrush, LPath);
    finally
      LBrush.Free;
    end;
  finally
    LPath.Free;
  end;
end;

{ TGlassTabItem }

constructor TGlassTabItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FClosable := True;
  FImageIndex := -1;
end;

procedure TGlassTabItem.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then begin FCaption := AValue; Changed(False); end;
end;

procedure TGlassTabItem.SetClosable(const AValue: Boolean);
begin
  if FClosable <> AValue then begin FClosable := AValue; Changed(False); end;
end;

procedure TGlassTabItem.SetImageIndex(
  const AValue: System.UITypes.TImageIndex);
begin
  if (FImageIndex <> AValue) or (FImageName <> '') then
  begin
    FImageIndex := AValue;
    FImageName := '';
    Changed(False);
  end;
end;

procedure TGlassTabItem.SetImageName(
  const AValue: System.UITypes.TImageName);
begin
  if (FImageName <> AValue) or (FImageIndex <> -1) then
  begin
    FImageName := AValue;
    FImageIndex := -1;
    Changed(False);
  end;
end;

{ TGlassTabItems }

constructor TGlassTabItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TGlassTabItem);
end;

function TGlassTabItems.Add: TGlassTabItem;
begin
  Result := TGlassTabItem(inherited Add);
end;

function TGlassTabItems.GetItem(AIndex: Integer): TGlassTabItem;
begin
  Result := TGlassTabItem(inherited Items[AIndex]);
end;

procedure TGlassTabItems.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

function DefaultPalette: TGlassTabPalette;
begin
  Result.StripTop := C(23, 31, 43);
  Result.StripBottom := C(12, 18, 27);
  Result.StripBorder := C(39, 51, 67);
  Result.BackgroundTopLine := Result.StripBorder;
  Result.TabTop := C(25, 35, 49);
  Result.TabBottom := C(15, 23, 33);
  Result.InactiveTop := C(18, 27, 39);
  Result.InactiveBottom := C(13, 20, 30);
  Result.HoverTop := C(29, 43, 60);
  Result.HoverBottom := C(18, 30, 43);
  Result.Accent := C(54, 119, 255);
  Result.Text := C(244, 247, 252);
  Result.InactiveText := C(166, 178, 195);
  Result.CloseHover := C(47, 65, 88);
end;

{ TGlassTabStrip }

constructor TGlassTabStrip.Create(AOwner: TComponent);
const
  CDefaultMinTabWidth = 154;
  CDefaultMaxTabWidth = 224;
  CDefaultTabOverlap = 1;
  CDefaultAddButtonSpacing = 5;
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque, csDoubleClicks];
  DoubleBuffered := True;
  FItems := TGlassTabItems.Create(Self);
  FItems.OnChanged := Changed;
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImagesChanged;
  FPalette := DefaultPalette;
  FActiveIndex := -1; FHotIndex := -1; FHotCloseIndex := -1;
  FPressedCloseIndex := -1; FShowAddButton := True;
  FHotAddButton := False;
  FPressedAddButton := False;
  FShowChevronButton := True;
  FHotChevronButton := False;
  FPressedChevronButton := False;
  FButtonHoverGlow := False;
  FButtonHoverBackground := True;
  FBackgroundGradientDirection := ggdVertical;
  FTabGradientDirection := ggdVertical;
  FLeftInset := CDefaultLeftInset;
  FTabHeight := CDefaultTabHeight;
  FMinTabWidth := CDefaultMinTabWidth;
  FMaxTabWidth := CDefaultMaxTabWidth;
  FTabOverlap := CDefaultTabOverlap;
  FAddButtonSpacing := CDefaultAddButtonSpacing;
  FFirstVisibleIndex := 0;
  FHotLeftNavigation := False;
  FHotRightNavigation := False;
  Height := ScaleValue(FTabHeight);
end;

destructor TGlassTabStrip.Destroy;
begin
  if Assigned(FImages) then
    FImages.UnRegisterChanges(FImageChangeLink);
  FImageChangeLink.Free;
  FItems.Free;
  inherited;
end;

procedure TGlassTabStrip.Changed(Sender: TObject);
begin
  if FActiveIndex >= FItems.Count then
    FActiveIndex := FItems.Count - 1;
  FFirstVisibleIndex := EnsureRange(FFirstVisibleIndex, 0,
    Max(0, FItems.Count - 1));
  Invalidate;
end;

procedure TGlassTabStrip.ImagesChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TGlassTabStrip.DoAddButtonClick;
begin
  if Assigned(FOnAddButtonClick) then
    FOnAddButtonClick(Self);
end;

procedure TGlassTabStrip.DoChevronButtonClick;
begin
  if Assigned(FOnChevronButtonClick) then
    FOnChevronButtonClick(Self);
end;

procedure TGlassTabStrip.DoAfterPaintBackground(ACanvas: TCanvas;
  const ARect: TRect);
begin
  if Assigned(FOnAfterPaintBackground) then
    FOnAfterPaintBackground(ACanvas, ARect);
end;

procedure TGlassTabStrip.DoAfterPaintTab(ACanvas: TCanvas;
  const ARect: TRect; ATabIndex: Integer; ASelected, AHot: Boolean);
begin
  if Assigned(FOnAfterPaintTab) then
    FOnAfterPaintTab(ACanvas, ARect, ATabIndex, ASelected, AHot);
end;

procedure TGlassTabStrip.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImages) then
    Images := nil;
end;

procedure TGlassTabStrip.SetImages(const AValue: TCustomImageList);
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

procedure TGlassTabStrip.SetItems(const AValue: TGlassTabItems);
begin
  FItems.Assign(AValue);
end;

procedure TGlassTabStrip.SetPalette(const AValue: TGlassTabPalette);
begin
  FPalette := AValue;
  Invalidate;
end;

function TGlassTabStrip.GetBackgroundGradientStartColor: TColor;
begin
  Result := FPalette.StripTop;
end;

function TGlassTabStrip.GetBackgroundGradientEndColor: TColor;
begin
  Result := FPalette.StripBottom;
end;

procedure TGlassTabStrip.SetBackgroundGradientStartColor(
  const AValue: TColor);
begin
  if FPalette.StripTop = AValue then
    Exit;
  FPalette.StripTop := AValue;
  Invalidate;
end;

procedure TGlassTabStrip.SetBackgroundGradientEndColor(
  const AValue: TColor);
begin
  if FPalette.StripBottom = AValue then
    Exit;
  FPalette.StripBottom := AValue;
  Invalidate;
end;

function TGlassTabStrip.GetBackgroundTopLineColor: TColor;
begin
  Result := FPalette.BackgroundTopLine;
end;

procedure TGlassTabStrip.SetBackgroundTopLineColor(const AValue: TColor);
begin
  if FPalette.BackgroundTopLine = AValue then
    Exit;
  FPalette.BackgroundTopLine := AValue;
  Invalidate;
end;

procedure TGlassTabStrip.SetBackgroundGradientDirection(
  const AValue: TGlassGradientDirection);
begin
  if FBackgroundGradientDirection = AValue then
    Exit;
  FBackgroundGradientDirection := AValue;
  Invalidate;
end;

procedure TGlassTabStrip.SetTabGradientDirection(
  const AValue: TGlassGradientDirection);
begin
  if FTabGradientDirection = AValue then
    Exit;
  FTabGradientDirection := AValue;
  Invalidate;
end;

function TGlassTabStrip.GetTabGradientStartColor: TColor;
begin
  Result := FPalette.TabTop;
end;

function TGlassTabStrip.GetTabGradientEndColor: TColor;
begin
  Result := FPalette.TabBottom;
end;

procedure TGlassTabStrip.SetTabGradientStartColor(const AValue: TColor);
begin
  if FPalette.TabTop = AValue then
    Exit;
  FPalette.TabTop := AValue;
  Invalidate;
end;

procedure TGlassTabStrip.SetTabGradientEndColor(const AValue: TColor);
begin
  if FPalette.TabBottom = AValue then
    Exit;
  FPalette.TabBottom := AValue;
  Invalidate;
end;

function TGlassTabStrip.GetTabHeight: Integer;
begin
  Result := FTabHeight;
end;

procedure TGlassTabStrip.SetTabHeight(const AValue: Integer);
const
  CMinimumTabHeight = 16;
begin
  var LValue := Max(CMinimumTabHeight, AValue);
  if GetTabHeight = LValue then
    Exit;
  FTabHeight := LValue;
  Height := ScaleValue(FTabHeight);
  Invalidate;
end;

procedure TGlassTabStrip.SetActiveIndex(const AValue: Integer);
begin
  var LIndex := EnsureRange(AValue, -1, FItems.Count - 1);
  if FActiveIndex = LIndex then Exit;
  FActiveIndex := LIndex;
  EnsureActiveTabVisible;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self, FActiveIndex);
end;

procedure TGlassTabStrip.SetShowAddButton(const AValue: Boolean);
begin
  if FShowAddButton = AValue then
    Exit;
  FShowAddButton := AValue;
  if not FShowAddButton then
  begin
    FHotAddButton := False;
    FPressedAddButton := False;
    FHotChevronButton := False;
    FPressedChevronButton := False;
  end;
  EnsureActiveTabVisible;
  Invalidate;
end;

procedure TGlassTabStrip.SetShowChevronButton(const AValue: Boolean);
begin
  if FShowChevronButton = AValue then
    Exit;
  FShowChevronButton := AValue;
  if not FShowChevronButton then
  begin
    FHotChevronButton := False;
    FPressedChevronButton := False;
  end;
  EnsureActiveTabVisible;
  Invalidate;
end;

procedure TGlassTabStrip.SetButtonHoverGlow(const AValue: Boolean);
begin
  if FButtonHoverGlow <> AValue then
  begin
    FButtonHoverGlow := AValue;
    Invalidate;
  end;
end;

procedure TGlassTabStrip.SetButtonHoverBackground(const AValue: Boolean);
begin
  if FButtonHoverBackground <> AValue then
  begin
    FButtonHoverBackground := AValue;
    Invalidate;
  end;
end;

procedure TGlassTabStrip.SetLeftInset(const AValue: Integer);
begin
  var LValue := Max(0, AValue);
  if FLeftInset <> LValue then
  begin
    FLeftInset := LValue;
    Invalidate;
  end;
end;

procedure TGlassTabStrip.AddTab(const ACaption: string;
  AImageIndex: System.UITypes.TImageIndex; AClosable, AActivate: Boolean);
begin
  var LItem := FItems.Add;
  LItem.Caption := ACaption;
  LItem.ImageIndex := AImageIndex;
  LItem.Closable := AClosable;
  if AActivate then
    ActiveIndex := LItem.Index
  else
    Invalidate;
end;

procedure TGlassTabStrip.AddTab(const ACaption: string;
  const AImageName: System.UITypes.TImageName; AClosable, AActivate: Boolean);
begin
  var LItem := FItems.Add;
  LItem.Caption := ACaption;
  LItem.ImageName := AImageName;
  LItem.Closable := AClosable;
  if AActivate then
    ActiveIndex := LItem.Index
  else
    Invalidate;
end;

procedure TGlassTabStrip.DeleteTab(AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then Exit;
  FItems.Delete(AIndex);
  if FItems.Count = 0 then FActiveIndex := -1
  else if FActiveIndex >= FItems.Count then FActiveIndex := FItems.Count - 1;
  FFirstVisibleIndex := EnsureRange(FFirstVisibleIndex, 0,
    Max(0, FItems.Count - 1));
  EnsureActiveTabVisible;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self, FActiveIndex);
end;

function TGlassTabStrip.GetTabWidth(AIndex: Integer): Integer;
const
  CTabFixedContentWidth = 72;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit(0);
  Canvas.Font.Assign(Font);
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Height := -ScaleValue(CTextHeight);
  var LCaptionWidth := Canvas.TextWidth(FItems[AIndex].Caption);
  Result := EnsureRange(
    ScaleValue(CTabFixedContentWidth) + LCaptionWidth,
    ScaleValue(FMinTabWidth), ScaleValue(FMaxTabWidth));
end;

function TGlassTabStrip.IsOverflowing: Boolean;
begin
  if FItems.Count = 0 then
    Exit(False);
  var LRequiredWidth := ScaleValue(FLeftInset + CSelectedShoulderWidth);
  for var LIndex := 0 to FItems.Count - 1 do
  begin
    Inc(LRequiredWidth, GetTabWidth(LIndex));
    if LIndex < FItems.Count - 1 then
      Dec(LRequiredWidth, ScaleValue(FTabOverlap));
  end;
  if FShowAddButton then
  begin
    Inc(LRequiredWidth, ScaleValue(FAddButtonSpacing + CAddButtonWidth));
    if FShowChevronButton then
      Inc(LRequiredWidth, ScaleValue(CChevronButtonWidth));
  end;
  Result := LRequiredWidth > Width;
end;

function TGlassTabStrip.GetTabsViewport: TRect;
const
  CNavigationButtonWidth = 40;
begin
  Result := ClientRect;
  if not IsOverflowing then
    Exit;
  var LButtonWidth := Min(Width div 2,
    ScaleValue(CNavigationButtonWidth));
  Result.Left := LButtonWidth;
  Result.Right := Max(Result.Left, Width - LButtonWidth);
end;

function TGlassTabStrip.GetAvailableBackgroundRect: TRect;
begin
  var LViewport := GetTabsViewport;
  Result := LViewport;
  var LContentRight := LViewport.Left;
  var LFirstIndex := 0;
  if IsOverflowing then
    LFirstIndex := FFirstVisibleIndex;
  for var LIndex := LFirstIndex to FItems.Count - 1 do
  begin
    var LTabRect := GetTabRect(LIndex);
    if LTabRect.Left >= LViewport.Right then
      Break;
    var LTabRight := LTabRect.Right;
    if LIndex = FActiveIndex then
      Inc(LTabRight, ScaleValue(CSelectedShoulderWidth));
    LContentRight := Max(LContentRight,
      Min(LTabRight, LViewport.Right));
  end;
  if IsChevronButtonVisible then
    LContentRight := Max(LContentRight,
      Min(GetChevronButtonRect.Right, LViewport.Right))
  else if IsAddButtonVisible then
    LContentRight := Max(LContentRight,
      Min(GetAddButtonRect.Right, LViewport.Right));
  Result.Left := Min(Result.Right, LContentRight);
end;

function TGlassTabStrip.GetLeftNavigationRect: TRect;
begin
  if not IsOverflowing then
    Exit(TRect.Empty);
  var LViewport := GetTabsViewport;
  Result := Rect(0, 0, LViewport.Left, Height);
end;

function TGlassTabStrip.GetRightNavigationRect: TRect;
begin
  if not IsOverflowing then
    Exit(TRect.Empty);
  var LViewport := GetTabsViewport;
  Result := Rect(LViewport.Right, 0, Width, Height);
end;

function TGlassTabStrip.GetTabRect(AIndex: Integer): TRect;
const
  CNavigationTabSpacing = 10;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit(TRect.Empty);
  var LFirstIndex := 0;
  var LLeft := ScaleValue(FLeftInset + CSelectedShoulderWidth);
  if IsOverflowing then
  begin
    LFirstIndex := EnsureRange(FFirstVisibleIndex, 0,
      Max(0, FItems.Count - 1));
    if AIndex < LFirstIndex then
      Exit(TRect.Empty);
    var LViewport := GetTabsViewport;
    var LNavigationCenterX := LViewport.Left div 2;
    LLeft := LNavigationCenterX +
      ScaleValue(CButtonHoverHalfWidth + CNavigationTabSpacing);
  end;
  for var LIndex := LFirstIndex to AIndex - 1 do
    Inc(LLeft, GetTabWidth(LIndex) - ScaleValue(FTabOverlap));
  Result := Rect(LLeft, ScaleValue(CTabTop),
    LLeft + GetTabWidth(AIndex), Height);
end;

function TGlassTabStrip.GetCloseRect(AIndex: Integer): TRect;
const
  CCloseLeftInset = 30;
  CCloseRightInset = 8;
  CCloseHitHalfHeight = 11;
begin
  var LTab := GetTabRect(AIndex);
  var LCenterY := LTab.Top + LTab.Height div 2;
  Result := Rect(LTab.Right - ScaleValue(CCloseLeftInset),
    LCenterY - ScaleValue(CCloseHitHalfHeight),
    LTab.Right - ScaleValue(CCloseRightInset),
    LCenterY + ScaleValue(CCloseHitHalfHeight));
end;

function TGlassTabStrip.GetAddButtonRect: TRect;
const
  CEmptyAddCenterOffset = 14;
  CAddButtonHalfWidth = 18;
begin
  if FItems.Count = 0 then
  begin
    var LCenterX := ScaleValue(FLeftInset + CEmptyAddCenterOffset);
    Exit(Rect(Max(0, LCenterX - ScaleValue(CAddButtonHalfWidth)),
      ScaleValue(CTabTop), LCenterX + ScaleValue(CAddButtonHalfWidth),
      Height));
  end;
  var LLast := GetTabRect(FItems.Count - 1);
  var LLeft := LLast.Right + ScaleValue(FAddButtonSpacing);
  Result := Rect(LLeft, LLast.Top,
    LLeft + ScaleValue(CAddButtonWidth), LLast.Bottom);
end;

function TGlassTabStrip.GetChevronButtonRect: TRect;
begin
  var LAddRect := GetAddButtonRect;
  Result := Rect(LAddRect.Right, LAddRect.Top,
    LAddRect.Right + ScaleValue(CChevronButtonWidth), LAddRect.Bottom);
end;

function TGlassTabStrip.IsAddButtonVisible: Boolean;
begin
  Result := FShowAddButton;
  if not Result or not IsOverflowing then
    Exit;
  var LAddRect := GetAddButtonRect;
  var LViewport := GetTabsViewport;
  var LRequiredRight := LAddRect.Right;
  if FShowChevronButton then
    LRequiredRight := GetChevronButtonRect.Right;
  Result := (LAddRect.Left >= LViewport.Left) and
    (LRequiredRight <= LViewport.Right);
end;

function TGlassTabStrip.IsChevronButtonVisible: Boolean;
begin
  Result := FShowChevronButton and IsAddButtonVisible;
end;

function TGlassTabStrip.CanNavigateLeft: Boolean;
begin
  Result := IsOverflowing and (FActiveIndex > 0);
end;

function TGlassTabStrip.CanNavigateRight: Boolean;
begin
  Result := IsOverflowing and (FActiveIndex >= 0) and
    (FActiveIndex < FItems.Count - 1);
end;

procedure TGlassTabStrip.EnsureActiveTabVisible;
begin
  if not IsOverflowing then
  begin
    FFirstVisibleIndex := 0;
    Exit;
  end;
  if FActiveIndex < 0 then
  begin
    FFirstVisibleIndex := 0;
    Exit;
  end;
  FFirstVisibleIndex := EnsureRange(FFirstVisibleIndex, 0,
    FActiveIndex);
  if FActiveIndex < FFirstVisibleIndex then
    FFirstVisibleIndex := FActiveIndex;
  var LViewport := GetTabsViewport;
  while FFirstVisibleIndex < FActiveIndex do
  begin
    var LActiveRect := GetTabRect(FActiveIndex);
    var LRequiredRight := LActiveRect.Right +
      ScaleValue(CSelectedShoulderWidth);
    if FShowAddButton and (FActiveIndex = FItems.Count - 1) then
    begin
      if FShowChevronButton then
        LRequiredRight := Max(LRequiredRight, GetChevronButtonRect.Right)
      else
        LRequiredRight := Max(LRequiredRight, GetAddButtonRect.Right);
    end;
    if LRequiredRight <= LViewport.Right then
      Break;
    Inc(FFirstVisibleIndex);
  end;
end;

function TGlassTabStrip.ResolveImageIndex(
  AItem: TGlassTabItem): System.UITypes.TImageIndex;
begin
  Result := -1;
  if not Assigned(FImages) or not Assigned(AItem) then
    Exit;
  var LImageName := AItem.ImageName;
  Result := AItem.ImageIndex;
  FImages.CheckIndexAndName(Result, LImageName);
  if (Result < 0) or (Result >= FImages.Count) then
    Result := -1;
end;

function TGlassTabStrip.TabAt(const APoint: TPoint): Integer;
begin
  var LViewport := GetTabsViewport;
  if IsOverflowing and not PtInRect(LViewport, APoint) then
    Exit(-1);
  var LFirstIndex := 0;
  if IsOverflowing then
    LFirstIndex := FFirstVisibleIndex;
  for var LIndex := LFirstIndex to FItems.Count - 1 do
  begin
    var LTabRect := GetTabRect(LIndex);
    if LTabRect.Left >= LViewport.Right then
      Break;
    if PtInRect(LTabRect, APoint) then
      Exit(LIndex);
  end;
  Result := -1;
end;

function TGlassTabStrip.CloseAt(const APoint: TPoint): Integer;
begin
  var LViewport := GetTabsViewport;
  if IsOverflowing and not PtInRect(LViewport, APoint) then
    Exit(-1);
  var LFirstIndex := 0;
  if IsOverflowing then
    LFirstIndex := FFirstVisibleIndex;
  for var LIndex := LFirstIndex to FItems.Count - 1 do
  begin
    var LTabRect := GetTabRect(LIndex);
    if LTabRect.Left >= LViewport.Right then
      Break;
    if FItems[LIndex].Closable and
      PtInRect(GetCloseRect(LIndex), APoint) then
      Exit(LIndex);
  end;
  Result := -1;
end;

procedure TGlassTabStrip.DrawTab(ACanvas: TCanvas; AIndex: Integer;
  ASelected: Boolean);
const
  CSelectedShoulderControlOffset = 5;
  CSelectedShoulderRise = 4;
  CSelectedShoulderHeight = 7;
  CFirstTabShoulderBlendOffset = 2;
  CFirstTabShoulderBottomAlpha = 12;
  CSelectedCornerDiameter = 14;
  CSelectedCornerRadius = 7;
  CInactiveCornerDiameter = 16;
  CInactiveCornerRadius = 8;
  CImageLeftInset = 15;
  CImageTextSpacing = 9;
  CTextLeftInset = 15;
  CTextRightSpacing = 6;
  CTextVerticalOffset = 1;
  CCloseGlyphInset = 7;
  CAccentFadeWidth = 72;
  CBaselineLeftFadeWidth = 64;
  CBaselineRightFadeWidth = 128;
  CBaselineLeftFadeMidAlpha = 48;
  CBaselineRightFadeMidAlpha = 72;
  CSelectedGlowWidth = 2.0;
  CSelectedOutlineWidth = 1.0;
  CBaselineWidth = 1.0;
  CInactiveOutlineWidth = 1.0;
  CCloseLineWidth = 1.25;
begin
  var LClose, LHoverRect: TRect;
  var LTextRect: TRect;
  var LTop, LBottom: ARGB;
  var LTextColor: TColor;
  var LCloseColor: TColor;
  var LOldBkMode: Integer;
  var LOldTextColor: COLORREF;
  var LFlags: Cardinal;
  var LContentCenterY: Integer;
  var LGradientStart, LFadeStart: Integer;
  var LGradientRect: TGPRect;
  var LCoreColors, LGlowColors: array[0..2] of TGPColor;
  var LPositions: array[0..2] of Single;
  var LBaselineColors: array[0..5] of TGPColor;
  var LBaselinePositions: array[0..5] of Single;
  var LBaselineLeftFadeEnd, LBaselineRightFadeStart: Integer;
  var LFirstShoulderBlendY: Integer;
  var LBaseY: Single;
  var LTab := GetTabRect(AIndex);
  var LIsFirstSelected := ASelected and (AIndex = 0);
  LBaseY := 0;
  if LTab.Left >= Width then
    Exit;

  if ASelected then
  begin
    LTop := ToArgb(FPalette.TabTop);
    LBottom := ToArgb(FPalette.TabBottom);
    LTextColor := FPalette.Text;
  end
  else if FHotIndex = AIndex then
  begin
    LTop := ToArgb(FPalette.HoverTop);
    LBottom := ToArgb(FPalette.HoverBottom);
    LTextColor := FPalette.Text;
  end
  else
  begin
    LTop := ToArgb(FPalette.InactiveTop);
    LBottom := ToArgb(FPalette.InactiveBottom);
    LTextColor := FPalette.InactiveText;
  end;

  var LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    var LShape := TGPGraphicsPath.Create;
    try
      var LStrokePath := TGPGraphicsPath.Create;
      try
        var LFirstShoulderPath := TGPGraphicsPath.Create;
        try
          var LBaselinePath := TGPGraphicsPath.Create;
          try
            var LFill := TGPLinearGradientBrush.Create(MakeRect(LTab.Left,
              LTab.Top, LTab.Width, LTab.Height - LTab.Top), LTop, LBottom,
              GradientMode(FTabGradientDirection));
            try
              LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);

    if ASelected then
    begin
      { The selected tab deliberately has no bottom outline: its two lower
        Bezier shoulders flow into the content plane, like the reference UI. }
      LShape.AddBezier(LTab.Left - ScaleValue(CSelectedShoulderWidth),
        LTab.Bottom,
        LTab.Left - ScaleValue(CSelectedShoulderControlOffset), LTab.Bottom,
        LTab.Left, LTab.Bottom - ScaleValue(CSelectedShoulderRise),
        LTab.Left, LTab.Bottom - ScaleValue(CSelectedShoulderHeight));
      LShape.AddLine(LTab.Left,
        LTab.Bottom - ScaleValue(CSelectedShoulderHeight), LTab.Left,
        LTab.Top + ScaleValue(CSelectedCornerRadius));
      LShape.AddArc(LTab.Left, LTab.Top,
        ScaleValue(CSelectedCornerDiameter),
        ScaleValue(CSelectedCornerDiameter), 180, 90);
      LShape.AddLine(LTab.Left + ScaleValue(CSelectedCornerRadius),
        LTab.Top, LTab.Right - ScaleValue(CSelectedCornerRadius), LTab.Top);
      LShape.AddArc(LTab.Right - ScaleValue(CSelectedCornerDiameter),
        LTab.Top, ScaleValue(CSelectedCornerDiameter),
        ScaleValue(CSelectedCornerDiameter), 270, 90);
      LShape.AddLine(LTab.Right,
        LTab.Top + ScaleValue(CSelectedCornerRadius), LTab.Right,
        LTab.Bottom - ScaleValue(CSelectedShoulderHeight));
      LShape.AddBezier(LTab.Right,
        LTab.Bottom - ScaleValue(CSelectedShoulderHeight), LTab.Right,
        LTab.Bottom - ScaleValue(CSelectedShoulderRise),
        LTab.Right + ScaleValue(CSelectedShoulderControlOffset), LTab.Bottom,
        LTab.Right + ScaleValue(CSelectedShoulderWidth), LTab.Bottom);
      LShape.AddLine(LTab.Right + ScaleValue(CSelectedShoulderWidth),
        LTab.Bottom, LTab.Left - ScaleValue(CSelectedShoulderWidth),
        LTab.Bottom);
      LShape.CloseFigure;

      LBaseY := LTab.Bottom - ScaleValue(CBaselineOffset);
      if LIsFirstSelected then
      begin
        LFirstShoulderBlendY := LTab.Top + LTab.Height div 2 +
          ScaleValue(CFirstTabShoulderBlendOffset);
        LStrokePath.AddLine(LTab.Left, LFirstShoulderBlendY, LTab.Left,
          LTab.Top + ScaleValue(CSelectedCornerRadius));
        LFirstShoulderPath.AddLine(LTab.Left, LFirstShoulderBlendY,
          LTab.Left, LBaseY - ScaleValue(CSelectedShoulderHeight));
        LFirstShoulderPath.AddBezier(LTab.Left,
          LBaseY - ScaleValue(CSelectedShoulderHeight), LTab.Left,
          LBaseY - ScaleValue(CSelectedShoulderRise),
          LTab.Left - ScaleValue(CSelectedShoulderControlOffset), LBaseY,
          LTab.Left - ScaleValue(CSelectedShoulderWidth), LBaseY);
      end
      else
      begin
        LStrokePath.AddBezier(
          LTab.Left - ScaleValue(CSelectedShoulderWidth), LBaseY,
          LTab.Left - ScaleValue(CSelectedShoulderControlOffset), LBaseY,
          LTab.Left, LBaseY - ScaleValue(CSelectedShoulderRise), LTab.Left,
          LBaseY - ScaleValue(CSelectedShoulderHeight));
        LStrokePath.AddLine(LTab.Left,
          LBaseY - ScaleValue(CSelectedShoulderHeight), LTab.Left,
          LTab.Top + ScaleValue(CSelectedCornerRadius));
      end;
      LStrokePath.AddArc(LTab.Left, LTab.Top,
        ScaleValue(CSelectedCornerDiameter),
        ScaleValue(CSelectedCornerDiameter), 180, 90);
      LStrokePath.AddLine(LTab.Left + ScaleValue(CSelectedCornerRadius),
        LTab.Top, LTab.Right - ScaleValue(CSelectedCornerRadius), LTab.Top);
      LStrokePath.AddArc(LTab.Right - ScaleValue(CSelectedCornerDiameter),
        LTab.Top, ScaleValue(CSelectedCornerDiameter),
        ScaleValue(CSelectedCornerDiameter), 270, 90);
      LStrokePath.AddLine(LTab.Right,
        LTab.Top + ScaleValue(CSelectedCornerRadius), LTab.Right,
        LBaseY - ScaleValue(CSelectedShoulderHeight));
      LStrokePath.AddBezier(LTab.Right,
        LBaseY - ScaleValue(CSelectedShoulderHeight), LTab.Right,
        LBaseY - ScaleValue(CSelectedShoulderRise),
        LTab.Right + ScaleValue(CSelectedShoulderControlOffset), LBaseY,
        LTab.Right + ScaleValue(CSelectedShoulderWidth), LBaseY);
      if not LIsFirstSelected then
      begin
        LBaselinePath.AddLine(0, LBaseY,
          LTab.Left - ScaleValue(CSelectedShoulderWidth), LBaseY);
        LBaselinePath.StartFigure;
      end;
      LBaselinePath.AddLine(
        LTab.Right + ScaleValue(CSelectedShoulderWidth), LBaseY,
        Width, LBaseY);
    end
    else
    begin
      LShape.AddLine(LTab.Left, LTab.Bottom, LTab.Left,
        LTab.Top + ScaleValue(CInactiveCornerRadius));
      LShape.AddArc(LTab.Left, LTab.Top,
        ScaleValue(CInactiveCornerDiameter),
        ScaleValue(CInactiveCornerDiameter), 180, 90);
      LShape.AddLine(LTab.Left + ScaleValue(CInactiveCornerRadius), LTab.Top,
        LTab.Right - ScaleValue(CInactiveCornerRadius), LTab.Top);
      LShape.AddArc(LTab.Right - ScaleValue(CInactiveCornerDiameter),
        LTab.Top, ScaleValue(CInactiveCornerDiameter),
        ScaleValue(CInactiveCornerDiameter), 270, 90);
      LShape.AddLine(LTab.Right,
        LTab.Top + ScaleValue(CInactiveCornerRadius), LTab.Right,
        LTab.Bottom);
      LShape.AddLine(LTab.Right, LTab.Bottom, LTab.Left, LTab.Bottom);
      LShape.CloseFigure;
      LStrokePath.AddPath(LShape, False);
    end;

    LGraphics.FillPath(LFill, LShape);
    if ASelected then
    begin
      LGradientStart := 0;
      LFadeStart := Max(LGradientStart, Width - ScaleValue(CAccentFadeWidth));
      LGradientRect := MakeRect(LGradientStart, 0,
        Max(1, Width - LGradientStart), Height);
      var LAccentGradient := TGPLinearGradientBrush.Create(LGradientRect,
        ToArgb(FPalette.Accent), ToArgb(FPalette.BackgroundTopLine),
        LinearGradientModeHorizontal);
      try
        var LGlowGradient := TGPLinearGradientBrush.Create(LGradientRect,
          ToArgb(BlendColor(FPalette.Accent, FPalette.BackgroundTopLine, 34)),
          ToArgb(FPalette.BackgroundTopLine), LinearGradientModeHorizontal);
        try
          LPositions[0] := 0;
          LPositions[1] := EnsureRange(
            (LFadeStart - LGradientStart) / Max(1, Width - LGradientStart),
            0.0, 1.0);
          LPositions[2] := 1;
          LCoreColors[0] := ToArgb(FPalette.Accent);
          LCoreColors[1] := ToArgb(FPalette.Accent);
          LCoreColors[2] := ToArgb(FPalette.BackgroundTopLine);
          LGlowColors[0] := ToArgb(BlendColor(FPalette.Accent,
            FPalette.BackgroundTopLine, 34));
          LGlowColors[1] := LGlowColors[0];
          LGlowColors[2] := ToArgb(FPalette.BackgroundTopLine);
          LAccentGradient.SetInterpolationColors(@LCoreColors[0],
            @LPositions[0], Length(LCoreColors));
          LGlowGradient.SetInterpolationColors(@LGlowColors[0],
            @LPositions[0], Length(LGlowColors));

          { The baseline uses alpha rather than a solid endpoint color. The
            underlying strip gradient therefore remains the exact blend color
            at both control edges, regardless of gradient direction or theme. }
          { Reach full accent precisely where the baseline meets the selected
            tab's lower-left shoulder. This keeps short first-tab segments from
            joining the shoulder while they are still semi-transparent. }
          LBaselineLeftFadeEnd := Min(ScaleValue(CBaselineLeftFadeWidth),
            Max(1, LTab.Left - ScaleValue(CSelectedShoulderWidth)));
          LBaselineRightFadeStart := Max(LBaselineLeftFadeEnd,
            Width - ScaleValue(CBaselineRightFadeWidth));
          LBaselinePositions[0] := 0;
          LBaselinePositions[1] := EnsureRange(
            (LBaselineLeftFadeEnd div 2) / Max(1, Width), 0.0, 1.0);
          LBaselinePositions[2] := EnsureRange(
            LBaselineLeftFadeEnd / Max(1, Width), 0.0, 1.0);
          LBaselinePositions[3] := EnsureRange(
            LBaselineRightFadeStart / Max(1, Width), 0.0, 1.0);
          LBaselinePositions[4] := EnsureRange(
            (LBaselineRightFadeStart +
            (Width - LBaselineRightFadeStart) div 2) / Max(1, Width),
            0.0, 1.0);
          LBaselinePositions[5] := 1;
          LBaselineColors[0] := ToArgb(FPalette.Accent, 0);
          LBaselineColors[1] := ToArgb(FPalette.Accent,
            CBaselineLeftFadeMidAlpha);
          LBaselineColors[2] := ToArgb(FPalette.Accent);
          LBaselineColors[3] := ToArgb(FPalette.Accent);
          LBaselineColors[4] := ToArgb(FPalette.Accent,
            CBaselineRightFadeMidAlpha);
          LBaselineColors[5] := ToArgb(FPalette.Accent, 0);

          var LGlowPen := TGPPen.Create(LGlowGradient,
            ScaleValue(CSelectedGlowWidth));
          try
            var LOutlinePen := TGPPen.Create(LAccentGradient,
              ScaleValue(CSelectedOutlineWidth));
            try
              var LBaselineGradient := TGPLinearGradientBrush.Create(
                MakeRect(0, 0, Max(1, Width), Height),
                ToArgb(FPalette.Accent, 0), ToArgb(FPalette.Accent, 0),
                LinearGradientModeHorizontal);
              try
                LBaselineGradient.SetInterpolationColors(@LBaselineColors[0],
                  @LBaselinePositions[0], Length(LBaselineColors));
                var LBaselinePen := TGPPen.Create(LBaselineGradient,
                  ScaleValue(CBaselineWidth));
                try
                  if LIsFirstSelected then
                    LGlowPen.SetStartCap(LineCapFlat)
                  else
                    LGlowPen.SetStartCap(LineCapRound);
                  LGlowPen.SetEndCap(LineCapFlat);
                  LGlowPen.SetLineJoin(LineJoinRound);
                  if LIsFirstSelected then
                    LOutlinePen.SetStartCap(LineCapFlat)
                  else
                    LOutlinePen.SetStartCap(LineCapRound);
                  LOutlinePen.SetEndCap(LineCapFlat);
                  LOutlinePen.SetLineJoin(LineJoinRound);
                  LBaselinePen.SetStartCap(LineCapFlat);
                  LBaselinePen.SetEndCap(LineCapFlat);
                  LGraphics.DrawPath(LGlowPen, LStrokePath);
                  LGraphics.DrawPath(LOutlinePen, LStrokePath);
                  if LIsFirstSelected then
                  begin
                    var LFirstShoulderRect := MakeRect(
                      LTab.Left - ScaleValue(CSelectedShoulderWidth),
                      LFirstShoulderBlendY,
                      ScaleValue(CSelectedShoulderWidth) + 1,
                      Max(1, Round(LBaseY) - LFirstShoulderBlendY + 1));
                    var LFirstShoulderGlow := TGPLinearGradientBrush.Create(
                      LFirstShoulderRect,
                      ToArgb(BlendColor(FPalette.Accent,
                        FPalette.BackgroundTopLine, 34)),
                      ToArgb(FPalette.Accent, 0),
                      LinearGradientModeVertical);
                    try
                      var LFirstShoulderGlowPen := TGPPen.Create(
                        LFirstShoulderGlow, ScaleValue(CSelectedGlowWidth));
                      try
                        LFirstShoulderGlowPen.SetStartCap(LineCapFlat);
                        LFirstShoulderGlowPen.SetEndCap(LineCapFlat);
                        LFirstShoulderGlowPen.SetLineJoin(LineJoinRound);
                        LGraphics.DrawPath(LFirstShoulderGlowPen,
                          LFirstShoulderPath);
                      finally
                        LFirstShoulderGlowPen.Free;
                      end;
                    finally
                      LFirstShoulderGlow.Free;
                    end;
                    var LFirstShoulderOutline :=
                      TGPLinearGradientBrush.Create(LFirstShoulderRect,
                        ToArgb(FPalette.Accent),
                        ToArgb(FPalette.Accent,
                          CFirstTabShoulderBottomAlpha),
                        LinearGradientModeVertical);
                    try
                      var LFirstShoulderOutlinePen := TGPPen.Create(
                        LFirstShoulderOutline,
                        ScaleValue(CSelectedOutlineWidth));
                      try
                        LFirstShoulderOutlinePen.SetStartCap(LineCapFlat);
                        LFirstShoulderOutlinePen.SetEndCap(LineCapFlat);
                        LFirstShoulderOutlinePen.SetLineJoin(LineJoinRound);
                        LGraphics.DrawPath(LFirstShoulderOutlinePen,
                          LFirstShoulderPath);
                      finally
                        LFirstShoulderOutlinePen.Free;
                      end;
                    finally
                      LFirstShoulderOutline.Free;
                    end;
                  end;
                  LGraphics.DrawPath(LBaselinePen, LBaselinePath);
                finally
                  LBaselinePen.Free;
                end;
              finally
                LBaselineGradient.Free;
              end;
            finally
              LOutlinePen.Free;
            end;
          finally
            LGlowPen.Free;
          end;
        finally
          LGlowGradient.Free;
        end;
      finally
        LAccentGradient.Free;
      end;
    end
    else
    begin
      var LInactiveOutlinePen := TGPPen.Create(
        ToArgb(FPalette.StripBorder, 180),
        ScaleValue(CInactiveOutlineWidth));
      try
        LGraphics.DrawPath(LInactiveOutlinePen, LStrokePath);
      finally
        LInactiveOutlinePen.Free;
      end;
    end;

    LContentCenterY := LTab.Top + LTab.Height div 2;
    var LTextLeft := LTab.Left + ScaleValue(CTextLeftInset);
    var LImageIndex := ResolveImageIndex(FItems[AIndex]);
    if LImageIndex >= 0 then
    begin
      LGraphics.Flush(FlushIntentionSync);
      var LImageLeft := LTab.Left + ScaleValue(CImageLeftInset);
      var LImageTop := LContentCenterY - FImages.Height div 2;
      FImages.Draw(ACanvas, LImageLeft, LImageTop, LImageIndex, Enabled);
      LTextLeft := LImageLeft + FImages.Width +
        ScaleValue(CImageTextSpacing);
    end;

    LClose := GetCloseRect(AIndex);
    ACanvas.Brush.Style := bsClear;
    if ASelected then
      ACanvas.Font.Name := 'Segoe UI Semibold'
    else
      ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Font.Height := -ScaleValue(CTextHeight);
    ACanvas.Font.Style := [];
    LOldBkMode := SetBkMode(ACanvas.Handle, TRANSPARENT);
    LOldTextColor := SetTextColor(ACanvas.Handle, ColorToRGB(LTextColor));
    LTextRect := Rect(LTextLeft,
      LTab.Top - ScaleValue(CTextVerticalOffset),
      LClose.Left - ScaleValue(CTextRightSpacing),
      LTab.Bottom - ScaleValue(CTextVerticalOffset));
    LFlags := DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX;
    DrawText(ACanvas.Handle, PChar(FItems[AIndex].Caption), -1, LTextRect, LFlags);
    SetTextColor(ACanvas.Handle, LOldTextColor);
    SetBkMode(ACanvas.Handle, LOldBkMode);

    if FItems[AIndex].Closable then
    begin
      if FHotCloseIndex = AIndex then
      begin
        if FButtonHoverBackground then
        begin
          LHoverRect := Rect((LClose.Left + LClose.Right) div 2 -
            ScaleValue(CButtonHoverHalfWidth),
            LContentCenterY - ScaleValue(CButtonHoverHalfHeight),
            (LClose.Left + LClose.Right) div 2 +
            ScaleValue(CButtonHoverHalfWidth),
            LContentCenterY + ScaleValue(CButtonHoverHalfHeight));
          FillRoundedHover(LGraphics, LHoverRect,
            ScaleValue(CButtonHoverRadius),
            FPalette.CloseHover);
        end;
        if FButtonHoverGlow then
          DrawTwoLineGlow(LGraphics,
            LClose.Left + ScaleValue(CCloseGlyphInset),
            LClose.Top + ScaleValue(CCloseGlyphInset),
            LClose.Right - ScaleValue(CCloseGlyphInset),
            LClose.Bottom - ScaleValue(CCloseGlyphInset),
            LClose.Right - ScaleValue(CCloseGlyphInset),
            LClose.Top + ScaleValue(CCloseGlyphInset),
            LClose.Left + ScaleValue(CCloseGlyphInset),
            LClose.Bottom - ScaleValue(CCloseGlyphInset),
            FPalette.Accent, ScaleValue(1.0));
      end;
      if FHotCloseIndex = AIndex then
        LCloseColor := FPalette.Accent
      else
        LCloseColor := FPalette.InactiveText;
      var LClosePen := TGPPen.Create(ToArgb(LCloseColor),
        ScaleValue(CCloseLineWidth));
      try
        LClosePen.SetStartCap(LineCapRound);
        LClosePen.SetEndCap(LineCapRound);
        LGraphics.DrawLine(LClosePen,
          LClose.Left + ScaleValue(CCloseGlyphInset),
          LClose.Top + ScaleValue(CCloseGlyphInset),
          LClose.Right - ScaleValue(CCloseGlyphInset),
          LClose.Bottom - ScaleValue(CCloseGlyphInset));
        LGraphics.DrawLine(LClosePen,
          LClose.Right - ScaleValue(CCloseGlyphInset),
          LClose.Top + ScaleValue(CCloseGlyphInset),
          LClose.Left + ScaleValue(CCloseGlyphInset),
          LClose.Bottom - ScaleValue(CCloseGlyphInset));
      finally
        LClosePen.Free;
      end;
    end;
            finally
              LFill.Free;
            end;
          finally
            LBaselinePath.Free;
          end;
        finally
          LFirstShoulderPath.Free;
        end;
      finally
        LStrokePath.Free;
      end;
    finally
      LShape.Free;
    end;
  finally
    LGraphics.Free;
  end;
end;

procedure TGlassTabStrip.DrawNavigationButton(ACanvas: TCanvas;
  const ARect: TRect; ALeft, AHot, AEnabled: Boolean);
const
  CNavigationGlyphHalfWidth = 3;
  CNavigationGlyphHalfHeight = 5;
  CNavigationLineWidth = 1.5;
  CNavigationDisabledAlpha = 72;
begin
  var LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    var LBackground := TGPLinearGradientBrush.Create(
      MakeRect(0, 0, Width, Height), ToArgb(FPalette.StripTop),
      ToArgb(FPalette.StripBottom),
      GradientMode(FBackgroundGradientDirection));
    try
      LGraphics.FillRectangle(LBackground, ARect.Left, ARect.Top,
        ARect.Width, Max(0, ARect.Height - ScaleValue(CBaselineOffset)));
    finally
      LBackground.Free;
    end;

    var LCenterX := (ARect.Left + ARect.Right) div 2;
    var LCenterY := (ARect.Top + ARect.Bottom) div 2;
    var LX1, LY1, LX2, LY2, LX3, LY3: Single;
    if ALeft then
    begin
      LX1 := LCenterX + ScaleValue(CNavigationGlyphHalfWidth);
      LY1 := LCenterY - ScaleValue(CNavigationGlyphHalfHeight);
      LX2 := LCenterX - ScaleValue(CNavigationGlyphHalfWidth);
      LY2 := LCenterY;
      LX3 := LX1;
      LY3 := LCenterY + ScaleValue(CNavigationGlyphHalfHeight);
    end
    else
    begin
      LX1 := LCenterX - ScaleValue(CNavigationGlyphHalfWidth);
      LY1 := LCenterY - ScaleValue(CNavigationGlyphHalfHeight);
      LX2 := LCenterX + ScaleValue(CNavigationGlyphHalfWidth);
      LY2 := LCenterY;
      LX3 := LX1;
      LY3 := LCenterY + ScaleValue(CNavigationGlyphHalfHeight);
    end;

    if AHot and AEnabled then
    begin
      if FButtonHoverBackground then
      begin
        var LHoverRect := Rect(
          LCenterX - ScaleValue(CButtonHoverHalfWidth),
          LCenterY - ScaleValue(CButtonHoverHalfHeight),
          LCenterX + ScaleValue(CButtonHoverHalfWidth),
          LCenterY + ScaleValue(CButtonHoverHalfHeight));
        FillRoundedHover(LGraphics, LHoverRect,
          ScaleValue(CButtonHoverRadius), FPalette.CloseHover);
      end;
      if FButtonHoverGlow then
        DrawTwoLineGlow(LGraphics, LX1, LY1, LX2, LY2,
          LX2, LY2, LX3, LY3, FPalette.Accent, ScaleValue(1.0));
    end;

    var LColor: TColor;
    if not AEnabled then
      LColor := BlendColor(FPalette.InactiveText, FPalette.StripBottom,
        CNavigationDisabledAlpha)
    else if AHot then
      LColor := FPalette.Accent
    else
      LColor := FPalette.InactiveText;
    var LChevronPen := TGPPen.Create(ToArgb(LColor),
      ScaleValue(CNavigationLineWidth));
    try
      LChevronPen.SetStartCap(LineCapRound);
      LChevronPen.SetEndCap(LineCapRound);
      LChevronPen.SetLineJoin(LineJoinRound);
      LGraphics.DrawLine(LChevronPen, LX1, LY1, LX2, LY2);
      LGraphics.DrawLine(LChevronPen, LX2, LY2, LX3, LY3);
    finally
      LChevronPen.Free;
    end;
  finally
    LGraphics.Free;
  end;
end;

procedure TGlassTabStrip.DrawChevronButton(ACanvas: TCanvas;
  const ARect: TRect; AHot: Boolean);
const
  CChevronGlyphHalfWidth = 4;
  CChevronGlyphHalfHeight = 2;
  CChevronLineWidth = 1.35;
begin
  var LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    var LCenterX := (ARect.Left + ARect.Right) div 2;
    var LCenterY := (ARect.Top + ARect.Bottom) div 2;
    var LX1 := LCenterX - ScaleValue(CChevronGlyphHalfWidth);
    var LY1 := LCenterY - ScaleValue(CChevronGlyphHalfHeight);
    var LX2 := LCenterX;
    var LY2 := LCenterY + ScaleValue(CChevronGlyphHalfHeight);
    var LX3 := LCenterX + ScaleValue(CChevronGlyphHalfWidth);
    var LY3 := LY1;

    if AHot then
    begin
      if FButtonHoverBackground then
      begin
        var LHoverRect := Rect(
          LCenterX - ScaleValue(CButtonHoverHalfWidth),
          LCenterY - ScaleValue(CButtonHoverHalfHeight),
          LCenterX + ScaleValue(CButtonHoverHalfWidth),
          LCenterY + ScaleValue(CButtonHoverHalfHeight));
        FillRoundedHover(LGraphics, LHoverRect,
          ScaleValue(CButtonHoverRadius), FPalette.CloseHover);
      end;
      if FButtonHoverGlow then
        DrawTwoLineGlow(LGraphics, LX1, LY1, LX2, LY2,
          LX2, LY2, LX3, LY3, FPalette.Accent, ScaleValue(1.0));
    end;

    var LColor := FPalette.InactiveText;
    if AHot then
      LColor := FPalette.Accent;
    var LChevronPen := TGPPen.Create(ToArgb(LColor),
      ScaleValue(CChevronLineWidth));
    try
      LChevronPen.SetStartCap(LineCapRound);
      LChevronPen.SetEndCap(LineCapRound);
      LChevronPen.SetLineJoin(LineJoinRound);
      LGraphics.DrawLine(LChevronPen, LX1, LY1, LX2, LY2);
      LGraphics.DrawLine(LChevronPen, LX2, LY2, LX3, LY3);
    finally
      LChevronPen.Free;
    end;
  finally
    LGraphics.Free;
  end;
end;

procedure TGlassTabStrip.Paint;
const
  CPlusGlyphHalfSize = 5;
  CPlusHotLineWidth = 1.45;
  CPlusLineWidth = 1.35;
begin
  { Draw directly to VCL's double-buffered paint surface. Rendering into a
    second TBitmap here softens ClearType and path edges on scaled displays. }
  var LGraphics := TGPGraphics.Create(Canvas.Handle);
  try
    var LBack := TGPLinearGradientBrush.Create(MakeRect(0, 0, Width, Height),
      ToArgb(FPalette.StripTop), ToArgb(FPalette.StripBottom),
      GradientMode(FBackgroundGradientDirection));
    try
      LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
      LGraphics.FillRectangle(LBack, 0, 0, Width, Height);
    finally
      LBack.Free;
    end;
  finally
    LGraphics.Free;
  end;
  EnsureActiveTabVisible;
  DoAfterPaintBackground(Canvas, GetAvailableBackgroundRect);
  var LViewport := GetTabsViewport;
  var LFirstIndex := 0;
  if IsOverflowing then
    LFirstIndex := FFirstVisibleIndex;
  for var LIndex := LFirstIndex to FItems.Count - 1 do
  begin
    var LTabRect := GetTabRect(LIndex);
    if LTabRect.Left >= LViewport.Right then
      Break;
    if LIndex <> FActiveIndex then
    begin
      DrawTab(Canvas, LIndex, False);
      DoAfterPaintTab(Canvas, LTabRect, LIndex, False,
        LIndex = FHotIndex);
    end;
  end;
  if FActiveIndex >= 0 then
  begin
    DrawTab(Canvas, FActiveIndex, True);
    DoAfterPaintTab(Canvas, GetTabRect(FActiveIndex), FActiveIndex, True,
      FActiveIndex = FHotIndex);
  end;

  if IsAddButtonVisible then
  begin
    var LAdd := GetAddButtonRect;
    LGraphics := TGPGraphics.Create(Canvas.Handle);
    try
      var LPlusPen: TGPPen;
      if FHotAddButton then
        LPlusPen := TGPPen.Create(ToArgb(FPalette.Accent),
          ScaleValue(CPlusHotLineWidth))
      else
        LPlusPen := TGPPen.Create(ToArgb(FPalette.InactiveText),
          ScaleValue(CPlusLineWidth));
      try
        LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
        LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
        var LCenterX := (LAdd.Left + LAdd.Right) div 2;
        var LCenterY := (LAdd.Top + LAdd.Bottom) div 2;
        if FHotAddButton then
        begin
          if FButtonHoverBackground then
          begin
            var LHoverRect := Rect(
              LCenterX - ScaleValue(CButtonHoverHalfWidth),
              LCenterY - ScaleValue(CButtonHoverHalfHeight),
              LCenterX + ScaleValue(CButtonHoverHalfWidth),
              LCenterY + ScaleValue(CButtonHoverHalfHeight));
            FillRoundedHover(LGraphics, LHoverRect,
              ScaleValue(CButtonHoverRadius),
              FPalette.CloseHover);
          end;
          if FButtonHoverGlow then
            DrawTwoLineGlow(LGraphics,
              LCenterX - ScaleValue(CPlusGlyphHalfSize), LCenterY,
              LCenterX + ScaleValue(CPlusGlyphHalfSize), LCenterY,
              LCenterX, LCenterY - ScaleValue(CPlusGlyphHalfSize),
              LCenterX, LCenterY + ScaleValue(CPlusGlyphHalfSize),
              FPalette.Accent, ScaleValue(1.0));
        end;
        LPlusPen.SetStartCap(LineCapRound);
        LPlusPen.SetEndCap(LineCapRound);
        LGraphics.DrawLine(LPlusPen,
          LCenterX - ScaleValue(CPlusGlyphHalfSize), LCenterY,
          LCenterX + ScaleValue(CPlusGlyphHalfSize), LCenterY);
        LGraphics.DrawLine(LPlusPen, LCenterX,
          LCenterY - ScaleValue(CPlusGlyphHalfSize), LCenterX,
          LCenterY + ScaleValue(CPlusGlyphHalfSize));
      finally
        LPlusPen.Free;
      end;
    finally
      LGraphics.Free;
    end;
  end;

  if IsChevronButtonVisible then
    DrawChevronButton(Canvas, GetChevronButtonRect, FHotChevronButton);

  if IsOverflowing then
  begin
    DrawNavigationButton(Canvas, GetLeftNavigationRect, True,
      FHotLeftNavigation, CanNavigateLeft);
    DrawNavigationButton(Canvas, GetRightNavigationRect, False,
      FHotRightNavigation, CanNavigateRight);
  end;
end;

procedure TGlassTabStrip.MouseDown(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if Button <> mbLeft then Exit;
  var LPoint := Point(X, Y);
  if IsOverflowing then
  begin
    if PtInRect(GetLeftNavigationRect, LPoint) then
    begin
      if CanNavigateLeft then
        ActiveIndex := FActiveIndex - 1;
      Exit;
    end;
    if PtInRect(GetRightNavigationRect, LPoint) then
    begin
      if CanNavigateRight then
        ActiveIndex := FActiveIndex + 1;
      Exit;
    end;
  end;
  var LClose := CloseAt(LPoint);
  if LClose >= 0 then
  begin
    FPressedCloseIndex := LClose;
    Invalidate;
    Exit;
  end;
  if IsAddButtonVisible and PtInRect(GetAddButtonRect, LPoint) then
  begin
    FPressedAddButton := True;
    Invalidate;
    Exit;
  end;
  if IsChevronButtonVisible and PtInRect(GetChevronButtonRect, LPoint) then
  begin
    FPressedChevronButton := True;
    Invalidate;
    Exit;
  end;
  var LTab := TabAt(LPoint);
  if LTab >= 0 then
  begin
    ActiveIndex := LTab;
    Exit;
  end;
  if ssDouble in Shift then
  begin
    if Assigned(FOnBackgroundDblClick) then
      FOnBackgroundDblClick(Self, Button, Shift, X, Y);
    Exit;
  end;
  if Assigned(FOnBackgroundMouseDown) then
    FOnBackgroundMouseDown(Self, Button, Shift, X, Y);
end;

procedure TGlassTabStrip.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  var LPoint := Point(X, Y);
  var LTab := TabAt(LPoint);
  var LClose := CloseAt(LPoint);
  var LHotAdd := IsAddButtonVisible and
    PtInRect(GetAddButtonRect, LPoint);
  var LHotChevron := IsChevronButtonVisible and
    PtInRect(GetChevronButtonRect, LPoint);
  var LHotLeft := CanNavigateLeft and
    PtInRect(GetLeftNavigationRect, LPoint);
  var LHotRight := CanNavigateRight and
    PtInRect(GetRightNavigationRect, LPoint);
  if (LTab <> FHotIndex) or (LClose <> FHotCloseIndex) or
    (LHotAdd <> FHotAddButton) or
    (LHotChevron <> FHotChevronButton) or
    (LHotLeft <> FHotLeftNavigation) or
    (LHotRight <> FHotRightNavigation) then
  begin
    FHotIndex := LTab;
    FHotCloseIndex := LClose;
    FHotAddButton := LHotAdd;
    FHotChevronButton := LHotChevron;
    FHotLeftNavigation := LHotLeft;
    FHotRightNavigation := LHotRight;
    Invalidate;
  end;
end;

procedure TGlassTabStrip.MouseUp(Button: TMouseButton; Shift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if Button <> mbLeft then Exit;
  var LPoint := Point(X, Y);
  if FPressedAddButton then
  begin
    FPressedAddButton := False;
    Invalidate;
    if IsAddButtonVisible and PtInRect(GetAddButtonRect, LPoint) then
      DoAddButtonClick;
    Exit;
  end;
  if FPressedChevronButton then
  begin
    FPressedChevronButton := False;
    Invalidate;
    if IsChevronButtonVisible and
      PtInRect(GetChevronButtonRect, LPoint) then
      DoChevronButtonClick;
    Exit;
  end;
  var LClose := CloseAt(LPoint);
  if (FPressedCloseIndex >= 0) and (FPressedCloseIndex = LClose) then begin
    var LCanClose := True;
    if Assigned(FOnCloseTab) then FOnCloseTab(Self, LClose, LCanClose);
    if LCanClose then DeleteTab(LClose);
  end;
  FPressedCloseIndex := -1; Invalidate;
end;

procedure TGlassTabStrip.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FHotIndex := -1;
  FHotCloseIndex := -1;
  FHotAddButton := False;
  FHotChevronButton := False;
  FHotLeftNavigation := False;
  FHotRightNavigation := False;
  FPressedCloseIndex := -1;
  Invalidate;
end;

end.
