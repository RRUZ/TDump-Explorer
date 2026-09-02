//**************************************************************************************************
//
// Unit TDump.Explorer.Tabs
//
// Provides the owner-drawn GDI+ tab strip used by TDump Explorer, including
// configurable palettes, gradients, tab actions, and high-DPI rendering.
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
unit TDump.Explorer.Tabs;

interface

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, System.SysUtils,
  System.UITypes, System.Generics.Collections, Winapi.GDIPOBJ, Vcl.Controls,
  Vcl.Graphics, Vcl.ImgList;

type
  TExplorerTabGradientDirection = (etgdVertical, etgdHorizontal,
    etgdForwardDiagonal, etgdBackwardDiagonal);

  TExplorerTabCustomButtonContent = (etcbcGlyph, etcbcImage);
  TExplorerTabCustomButtonGlyph = (etcbgChevronLeft, etcbgChevronRight,
    etcbgChevronUp, etcbgChevronDown, etcbgPlus, etcbgClose);
  TExplorerTabCustomButton = (etcbLeft, etcbRight);
  TExplorerTabButtonDrawState = (etbdsNormal, etbdsHot, etbdsDisabled);
  TExplorerTabCustomButtonDrawEvent = procedure(Sender: TObject;
    AButton: TExplorerTabCustomButton; ACanvas: TCanvas; const ARect: TRect;
    const AGlyphRect: TRect; AState: TExplorerTabButtonDrawState;
    AGlyphColor: TColor; var AHandled: Boolean) of object;

  TExplorerTabItem = class(TCollectionItem)
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

  TExplorerTabItems = class(TOwnedCollection)
  private
    FOnChanged: TNotifyEvent;
    function GetItem(AIndex: Integer): TExplorerTabItem;
  protected
    procedure Update(Item: TCollectionItem); override;
  public
    constructor Create(AOwner: TPersistent);
    function Add: TExplorerTabItem;
    property Items[AIndex: Integer]: TExplorerTabItem read GetItem; default;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

  TExplorerTabPalette = record
    StripTop, StripBottom, StripBorder, BackgroundTopLine: TColor;
    TabTop, TabBottom, InactiveTop, InactiveBottom: TColor;
    HoverTop, HoverBottom, Accent: TColor;
    Text, InactiveText, CloseHover: TColor;
  end;

  TExplorerTabChangingEvent = procedure(Sender: TObject; ANewIndex: Integer) of object;
  TExplorerTabCloseEvent = procedure(Sender: TObject; AIndex: Integer; var ACanClose: Boolean) of object;
  TExplorerTabBackgroundPaintEvent = procedure(ACanvas: TCanvas;
    const ARect: TRect) of object;
  TExplorerTabPaintEvent = procedure(ACanvas: TCanvas; const ARect: TRect;
    ATabIndex: Integer; ASelected, AHot: Boolean) of object;

  TExplorerTabStrip = class(TCustomControl)
  private
    const
      cDefaultTabHeight = 38;
      cDefaultLeftInset = 8;
      cTabTop = 6;
      cSelectedShoulderWidth = 14;
      cAddButtonWidth = 36;
      cCustomButtonWidth = 28;
      cTextHeight = 12;
      cButtonHoverHalfWidth = 14;
      cButtonHoverHalfHeight = 12;
      cButtonHoverRadius = 6;
      cBaselineOffset = 1;
      cDefaultTrailingReservedSpace = 150;
      cGlyphButtonDisabledAlpha = 72;
      cDefaultCustomButtonGlyphSize = 18;
  private
    FItems: TExplorerTabItems;
    FImages: TCustomImageList;
    FImageChangeLink: TChangeLink;
    FPalette: TExplorerTabPalette;
    FActiveIndex, FHotIndex, FHotCloseIndex, FPressedCloseIndex: Integer;
    FShowAddButton: Boolean;
    FHotAddButton: Boolean;
    FPressedAddButton: Boolean;
    FShowCustomLeftButton: Boolean;
    FShowCustomRightButton: Boolean;
    FTrailingReservedSpace: Integer;
    FHotCustomLeftButton: Boolean;
    FHotCustomRightButton: Boolean;
    FPressedCustomLeftButton: Boolean;
    FPressedCustomRightButton: Boolean;
    FCustomLeftButtonContent: TExplorerTabCustomButtonContent;
    FCustomRightButtonContent: TExplorerTabCustomButtonContent;
    FCustomLeftButtonGlyph: TExplorerTabCustomButtonGlyph;
    FCustomRightButtonGlyph: TExplorerTabCustomButtonGlyph;
    FCustomLeftButtonImageIndex: System.UITypes.TImageIndex;
    FCustomRightButtonImageIndex: System.UITypes.TImageIndex;
    FCustomLeftButtonHint: string;
    FCustomRightButtonHint: string;
    FButtonHoverGlow: Boolean;
    FButtonHoverBackground: Boolean;
    FGlyphButtonNormalColor: TColor;
    FGlyphButtonHotColor: TColor;
    FGlyphButtonDisabledColor: TColor;
    FCustomButtonGlyphSize: Integer;
    FBackgroundGradientDirection: TExplorerTabGradientDirection;
    FTabGradientDirection: TExplorerTabGradientDirection;
    FLeftInset: Integer;
    FTabHeight: Integer;
    FMinTabWidth: Integer;
    FMaxTabWidth: Integer;
    FTabOverlap: Integer;
    FAddButtonSpacing: Integer;
    FFirstVisibleIndex: Integer;
    FHotLeftNavigation: Boolean;
    FHotRightNavigation: Boolean;
    FTabWidthCache: TList<Integer>;
    FTabPositionCache: TList<Integer>;
    FTabWidthCachePPI: Integer;
    FTabWidthCacheValid: Boolean;
    FOnChange: TExplorerTabChangingEvent;
    FOnCloseTab: TExplorerTabCloseEvent;
    FOnAddButtonClick: TNotifyEvent;
    FOnCustomLeftButtonClick: TNotifyEvent;
    FOnCustomRightButtonClick: TNotifyEvent;
    FOnCustomButtonDraw: TExplorerTabCustomButtonDrawEvent;
    FOnBackgroundMouseDown: TMouseEvent;
    FOnBackgroundDblClick: TMouseEvent;
    FOnAfterPaintBackground: TExplorerTabBackgroundPaintEvent;
    FOnAfterPaintTab: TExplorerTabPaintEvent;
    procedure Changed(Sender: TObject);
    procedure EnsureTabWidthCache;
    procedure InvalidateTabWidthCache;
    procedure ImagesChanged(Sender: TObject);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetItems(const AValue: TExplorerTabItems);
    procedure SetPalette(const AValue: TExplorerTabPalette);
    function GetBackgroundGradientStartColor: TColor;
    function GetBackgroundGradientEndColor: TColor;
    procedure SetBackgroundGradientStartColor(const AValue: TColor);
    procedure SetBackgroundGradientEndColor(const AValue: TColor);
    function GetBackgroundTopLineColor: TColor;
    procedure SetBackgroundTopLineColor(const AValue: TColor);
    procedure SetBackgroundGradientDirection(
      const AValue: TExplorerTabGradientDirection);
    procedure SetTabGradientDirection(const AValue: TExplorerTabGradientDirection);
    function GetTabGradientStartColor: TColor;
    function GetTabGradientEndColor: TColor;
    procedure SetTabGradientStartColor(const AValue: TColor);
    procedure SetTabGradientEndColor(const AValue: TColor);
    function GetTabHeight: Integer;
    procedure SetTabHeight(const AValue: Integer);
    procedure SetActiveIndex(const AValue: Integer);
    procedure SetShowAddButton(const AValue: Boolean);
    procedure SetShowCustomLeftButton(const AValue: Boolean);
    procedure SetShowCustomRightButton(const AValue: Boolean);
    procedure SetCustomLeftButtonContent(
      const AValue: TExplorerTabCustomButtonContent);
    procedure SetCustomRightButtonContent(
      const AValue: TExplorerTabCustomButtonContent);
    procedure SetCustomLeftButtonGlyph(
      const AValue: TExplorerTabCustomButtonGlyph);
    procedure SetCustomRightButtonGlyph(
      const AValue: TExplorerTabCustomButtonGlyph);
    procedure SetCustomLeftButtonImageIndex(
      const AValue: System.UITypes.TImageIndex);
    procedure SetCustomRightButtonImageIndex(
      const AValue: System.UITypes.TImageIndex);
    procedure SetTrailingReservedSpace(const AValue: Integer);
    procedure SetButtonHoverGlow(const AValue: Boolean);
    procedure SetButtonHoverBackground(const AValue: Boolean);
    procedure SetGlyphButtonNormalColor(const AValue: TColor);
    procedure SetGlyphButtonHotColor(const AValue: TColor);
    procedure SetGlyphButtonDisabledColor(const AValue: TColor);
    procedure SetCustomButtonGlyphSize(const AValue: Integer);
    procedure SetLeftInset(const AValue: Integer);
    function GetTabRect(AIndex: Integer): TRect;
    function GetCloseRect(AIndex: Integer): TRect;
    function GetAddButtonRect: TRect;
    function GetCustomLeftButtonRect: TRect;
    function GetCustomRightButtonRect: TRect;
    function GetActionButtonsWidth: Integer;
    function GetActionButtonsLeft: Integer;
    function GetActionAreaRect: TRect;
    function GetTabsViewport: TRect;
    function GetAvailableBackgroundRect: TRect;
    function GetLeftNavigationRect: TRect;
    function GetRightNavigationRect: TRect;
    function GetVisibleTabsRight: Integer;
    function IsOverflowing: Boolean;
    function IsAddButtonVisible: Boolean;
    function IsCustomLeftButtonVisible: Boolean;
    function IsCustomRightButtonVisible: Boolean;
    function HasTrailingActionButtons: Boolean;
    function CanNavigateLeft: Boolean;
    function CanNavigateRight: Boolean;
    procedure EnsureActiveTabVisible;
    function ResolveImageIndex(
      AItem: TExplorerTabItem): System.UITypes.TImageIndex;
    function ResolveCustomButtonImageIndex(
      AImageIndex: System.UITypes.TImageIndex): System.UITypes.TImageIndex;
    function ButtonDrawState(AHot: Boolean): TExplorerTabButtonDrawState;
    function GlyphButtonColor(AState: TExplorerTabButtonDrawState): TColor;
    function GetCustomButtonGlyphRect(const ARect: TRect): TRect;
    procedure UpdateCustomButtonHint(const APoint: TPoint);
    function TabAt(const APoint: TPoint): Integer;
    function CloseAt(const APoint: TPoint): Integer;
    procedure DrawTab(ACanvas: TCanvas; AGraphics: TGPGraphics;
      AShape, AStrokePath, AFirstShoulderPath,
      ABaselinePath: TGPGraphicsPath; AInactiveOutlinePen,
      AClosePen, AHotClosePen: TGPPen; AIndex: Integer; ASelected: Boolean);
    procedure DrawNavigationButton(AGraphics: TGPGraphics;
      const ARect: TRect; ALeft, AHot, AEnabled: Boolean);
    procedure DrawButtonGlyph(AGraphics: TGPGraphics; const ARect: TRect;
      AGlyph: TExplorerTabCustomButtonGlyph;
      AState: TExplorerTabButtonDrawState);
    procedure DrawCustomButton(ACanvas: TCanvas; AGraphics: TGPGraphics;
      const ARect: TRect; AButton: TExplorerTabCustomButton;
      AState: TExplorerTabButtonDrawState;
      AContent: TExplorerTabCustomButtonContent;
      AGlyph: TExplorerTabCustomButtonGlyph;
      AImageIndex: System.UITypes.TImageIndex);
  protected
    procedure DoAddButtonClick; virtual;
    procedure DoCustomLeftButtonClick; virtual;
    procedure DoCustomRightButtonClick; virtual;
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
    property Items: TExplorerTabItems read FItems write SetItems;
    property Images: TCustomImageList read FImages write SetImages;
    property Palette: TExplorerTabPalette read FPalette write SetPalette;
    property BackgroundGradientStartColor: TColor
      read GetBackgroundGradientStartColor
      write SetBackgroundGradientStartColor;
    property BackgroundGradientEndColor: TColor
      read GetBackgroundGradientEndColor write SetBackgroundGradientEndColor;
    property BackgroundTopLineColor: TColor read GetBackgroundTopLineColor
      write SetBackgroundTopLineColor;
    property BackgroundGradientDirection: TExplorerTabGradientDirection
      read FBackgroundGradientDirection write SetBackgroundGradientDirection
      default etgdVertical;
    property TabGradientStartColor: TColor read GetTabGradientStartColor
      write SetTabGradientStartColor;
    property TabGradientEndColor: TColor read GetTabGradientEndColor
      write SetTabGradientEndColor;
    property TabGradientDirection: TExplorerTabGradientDirection
      read FTabGradientDirection write SetTabGradientDirection
      default etgdVertical;
    property TabHeight: Integer read GetTabHeight write SetTabHeight
      default cDefaultTabHeight;
    property ActiveIndex: Integer read FActiveIndex write SetActiveIndex default -1;
    property ShowAddButton: Boolean read FShowAddButton write SetShowAddButton default True;
    property ShowCustomLeftButton: Boolean read FShowCustomLeftButton
      write SetShowCustomLeftButton default False;
    property ShowCustomRightButton: Boolean read FShowCustomRightButton
      write SetShowCustomRightButton default True;
    property CustomLeftButtonContent: TExplorerTabCustomButtonContent
      read FCustomLeftButtonContent write SetCustomLeftButtonContent
      default etcbcGlyph;
    property CustomRightButtonContent: TExplorerTabCustomButtonContent
      read FCustomRightButtonContent write SetCustomRightButtonContent
      default etcbcGlyph;
    property CustomLeftButtonGlyph: TExplorerTabCustomButtonGlyph
      read FCustomLeftButtonGlyph write SetCustomLeftButtonGlyph
      default etcbgChevronDown;
    property CustomRightButtonGlyph: TExplorerTabCustomButtonGlyph
      read FCustomRightButtonGlyph write SetCustomRightButtonGlyph
      default etcbgChevronDown;
    property CustomLeftButtonImageIndex: System.UITypes.TImageIndex
      read FCustomLeftButtonImageIndex write SetCustomLeftButtonImageIndex
      default -1;
    property CustomRightButtonImageIndex: System.UITypes.TImageIndex
      read FCustomRightButtonImageIndex write SetCustomRightButtonImageIndex
      default -1;
    property CustomLeftButtonHint: string read FCustomLeftButtonHint
      write FCustomLeftButtonHint;
    property CustomRightButtonHint: string read FCustomRightButtonHint
      write FCustomRightButtonHint;
    property TrailingReservedSpace: Integer read FTrailingReservedSpace
      write SetTrailingReservedSpace default cDefaultTrailingReservedSpace;
    property ButtonHoverGlow: Boolean read FButtonHoverGlow
      write SetButtonHoverGlow default False;
    property ButtonHoverBackground: Boolean read FButtonHoverBackground
      write SetButtonHoverBackground default True;
    property GlyphButtonNormalColor: TColor read FGlyphButtonNormalColor
      write SetGlyphButtonNormalColor;
    property GlyphButtonHotColor: TColor read FGlyphButtonHotColor
      write SetGlyphButtonHotColor;
    property GlyphButtonDisabledColor: TColor read FGlyphButtonDisabledColor
      write SetGlyphButtonDisabledColor;
    property CustomButtonGlyphSize: Integer read FCustomButtonGlyphSize
      write SetCustomButtonGlyphSize default cDefaultCustomButtonGlyphSize;
    property LeftInset: Integer read FLeftInset write SetLeftInset
      default cDefaultLeftInset;
    property OnChange: TExplorerTabChangingEvent read FOnChange write FOnChange;
    property OnCloseTab: TExplorerTabCloseEvent read FOnCloseTab write FOnCloseTab;
    property OnAddButtonClick: TNotifyEvent read FOnAddButtonClick
      write FOnAddButtonClick;
    property OnCustomLeftButtonClick: TNotifyEvent
      read FOnCustomLeftButtonClick write FOnCustomLeftButtonClick;
    property OnCustomRightButtonClick: TNotifyEvent
      read FOnCustomRightButtonClick write FOnCustomRightButtonClick;
    property OnCustomButtonDraw: TExplorerTabCustomButtonDrawEvent
      read FOnCustomButtonDraw write FOnCustomButtonDraw;
    property OnBackgroundMouseDown: TMouseEvent read FOnBackgroundMouseDown
      write FOnBackgroundMouseDown;
    property OnBackgroundDblClick: TMouseEvent read FOnBackgroundDblClick
      write FOnBackgroundDblClick;
    property OnAfterPaintBackground: TExplorerTabBackgroundPaintEvent
      read FOnAfterPaintBackground write FOnAfterPaintBackground;
    property OnAfterPaintTab: TExplorerTabPaintEvent read FOnAfterPaintTab
      write FOnAfterPaintTab;
  end;

implementation

uses
  Winapi.GDIPAPI, System.Math;

function GradientMode(ADirection: TExplorerTabGradientDirection): LinearGradientMode;
begin
  case ADirection of
    etgdHorizontal:
      Result := LinearGradientModeHorizontal;
    etgdForwardDiagonal:
      Result := LinearGradientModeForwardDiagonal;
    etgdBackwardDiagonal:
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

{ TExplorerTabItem }

constructor TExplorerTabItem.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FClosable := True;
  FImageIndex := -1;
end;

procedure TExplorerTabItem.SetCaption(const AValue: string);
begin
  if FCaption <> AValue then begin FCaption := AValue; Changed(False); end;
end;

procedure TExplorerTabItem.SetClosable(const AValue: Boolean);
begin
  if FClosable <> AValue then begin FClosable := AValue; Changed(False); end;
end;

procedure TExplorerTabItem.SetImageIndex(
  const AValue: System.UITypes.TImageIndex);
begin
  if (FImageIndex <> AValue) or (FImageName <> '') then
  begin
    FImageIndex := AValue;
    FImageName := '';
    Changed(False);
  end;
end;

procedure TExplorerTabItem.SetImageName(
  const AValue: System.UITypes.TImageName);
begin
  if (FImageName <> AValue) or (FImageIndex <> -1) then
  begin
    FImageName := AValue;
    FImageIndex := -1;
    Changed(False);
  end;
end;

{ TExplorerTabItems }

constructor TExplorerTabItems.Create(AOwner: TPersistent);
begin
  inherited Create(AOwner, TExplorerTabItem);
end;

function TExplorerTabItems.Add: TExplorerTabItem;
begin
  Result := TExplorerTabItem(inherited Add);
end;

function TExplorerTabItems.GetItem(AIndex: Integer): TExplorerTabItem;
begin
  Result := TExplorerTabItem(inherited Items[AIndex]);
end;

procedure TExplorerTabItems.Update(Item: TCollectionItem);
begin
  inherited;
  if Assigned(FOnChanged) then FOnChanged(Self);
end;

function DefaultPalette: TExplorerTabPalette;
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

{ TExplorerTabStrip }

constructor TExplorerTabStrip.Create(AOwner: TComponent);
const
  cDefaultMinTabWidth = 154;
  cDefaultMaxTabWidth = 224;
  cDefaultTabOverlap = 1;
  cDefaultAddButtonSpacing = 5;
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque, csDoubleClicks];
  DoubleBuffered := True;
  FItems := TExplorerTabItems.Create(Self);
  FItems.OnChanged := Changed;
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImagesChanged;
  FPalette := DefaultPalette;
  FGlyphButtonNormalColor := FPalette.InactiveText;
  FGlyphButtonHotColor := FPalette.Accent;
  FGlyphButtonDisabledColor := BlendColor(FPalette.InactiveText,
    FPalette.StripBottom, cGlyphButtonDisabledAlpha);
  FActiveIndex := -1; FHotIndex := -1; FHotCloseIndex := -1;
  FPressedCloseIndex := -1; FShowAddButton := True;
  FHotAddButton := False;
  FPressedAddButton := False;
  FShowCustomLeftButton := False;
  FShowCustomRightButton := True;
  FTrailingReservedSpace := cDefaultTrailingReservedSpace;
  FHotCustomLeftButton := False;
  FHotCustomRightButton := False;
  FPressedCustomLeftButton := False;
  FPressedCustomRightButton := False;
  FCustomLeftButtonContent := etcbcGlyph;
  FCustomRightButtonContent := etcbcGlyph;
  FCustomLeftButtonGlyph := etcbgChevronDown;
  FCustomRightButtonGlyph := etcbgChevronDown;
  FCustomLeftButtonImageIndex := -1;
  FCustomRightButtonImageIndex := -1;
  FButtonHoverGlow := False;
  FButtonHoverBackground := True;
  FCustomButtonGlyphSize := cDefaultCustomButtonGlyphSize;
  FBackgroundGradientDirection := etgdVertical;
  FTabGradientDirection := etgdVertical;
  FLeftInset := cDefaultLeftInset;
  FTabHeight := cDefaultTabHeight;
  FMinTabWidth := cDefaultMinTabWidth;
  FMaxTabWidth := cDefaultMaxTabWidth;
  FTabOverlap := cDefaultTabOverlap;
  FAddButtonSpacing := cDefaultAddButtonSpacing;
  FFirstVisibleIndex := 0;
  FHotLeftNavigation := False;
  FHotRightNavigation := False;
  FTabWidthCache := TList<Integer>.Create;
  FTabPositionCache := TList<Integer>.Create;
  FTabWidthCacheValid := False;
  ShowHint := True;
  Height := ScaleValue(FTabHeight);
end;

destructor TExplorerTabStrip.Destroy;
begin
  if Assigned(FImages) then
    FImages.UnRegisterChanges(FImageChangeLink);
  FTabPositionCache.Free;
  FTabWidthCache.Free;
  FImageChangeLink.Free;
  FItems.Free;
  inherited;
end;

procedure TExplorerTabStrip.Changed(Sender: TObject);
begin
  if FActiveIndex >= FItems.Count then
    FActiveIndex := FItems.Count - 1;
  FFirstVisibleIndex := EnsureRange(FFirstVisibleIndex, 0,
    Max(0, FItems.Count - 1));
  InvalidateTabWidthCache;
  Invalidate;
end;

procedure TExplorerTabStrip.EnsureTabWidthCache;
const
  cTabFixedContentWidth = 72;
begin
  if FTabWidthCacheValid and (FTabWidthCachePPI = CurrentPPI) and
    (FTabWidthCache.Count = FItems.Count) then
    Exit;

  FTabWidthCache.Clear;
  FTabPositionCache.Clear;
  FTabPositionCache.Add(0);
  Canvas.Font.Assign(Font);
  Canvas.Font.Name := 'Segoe UI';
  Canvas.Font.Height := -ScaleValue(cTextHeight);
  var LPosition := 0;
  for var LIndex := 0 to FItems.Count - 1 do
  begin
    var LCaptionWidth := Canvas.TextWidth(FItems[LIndex].Caption);
    var LTabWidth := EnsureRange(
      ScaleValue(cTabFixedContentWidth) + LCaptionWidth,
      ScaleValue(FMinTabWidth), ScaleValue(FMaxTabWidth));
    FTabWidthCache.Add(LTabWidth);
    Inc(LPosition, LTabWidth - ScaleValue(FTabOverlap));
    FTabPositionCache.Add(LPosition);
  end;
  FTabWidthCachePPI := CurrentPPI;
  FTabWidthCacheValid := True;
end;

procedure TExplorerTabStrip.InvalidateTabWidthCache;
begin
  FTabWidthCacheValid := False;
end;

procedure TExplorerTabStrip.ImagesChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TExplorerTabStrip.DoAddButtonClick;
begin
  if Assigned(FOnAddButtonClick) then
    FOnAddButtonClick(Self);
end;

procedure TExplorerTabStrip.DoCustomLeftButtonClick;
begin
  if Assigned(FOnCustomLeftButtonClick) then
    FOnCustomLeftButtonClick(Self);
end;

procedure TExplorerTabStrip.DoCustomRightButtonClick;
begin
  if Assigned(FOnCustomRightButtonClick) then
    FOnCustomRightButtonClick(Self);
end;

procedure TExplorerTabStrip.DoAfterPaintBackground(ACanvas: TCanvas;
  const ARect: TRect);
begin
  if Assigned(FOnAfterPaintBackground) then
    FOnAfterPaintBackground(ACanvas, ARect);
end;

procedure TExplorerTabStrip.DoAfterPaintTab(ACanvas: TCanvas;
  const ARect: TRect; ATabIndex: Integer; ASelected, AHot: Boolean);
begin
  if Assigned(FOnAfterPaintTab) then
    FOnAfterPaintTab(ACanvas, ARect, ATabIndex, ASelected, AHot);
end;

procedure TExplorerTabStrip.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImages) then
    Images := nil;
end;

procedure TExplorerTabStrip.SetImages(const AValue: TCustomImageList);
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

procedure TExplorerTabStrip.SetItems(const AValue: TExplorerTabItems);
begin
  FItems.Assign(AValue);
end;

procedure TExplorerTabStrip.SetPalette(const AValue: TExplorerTabPalette);
begin
  FPalette := AValue;
  FGlyphButtonNormalColor := FPalette.InactiveText;
  FGlyphButtonHotColor := FPalette.Accent;
  FGlyphButtonDisabledColor := BlendColor(FPalette.InactiveText,
    FPalette.StripBottom, cGlyphButtonDisabledAlpha);
  Invalidate;
end;

function TExplorerTabStrip.GetBackgroundGradientStartColor: TColor;
begin
  Result := FPalette.StripTop;
end;

function TExplorerTabStrip.GetBackgroundGradientEndColor: TColor;
begin
  Result := FPalette.StripBottom;
end;

procedure TExplorerTabStrip.SetBackgroundGradientStartColor(
  const AValue: TColor);
begin
  if FPalette.StripTop = AValue then
    Exit;
  FPalette.StripTop := AValue;
  Invalidate;
end;

procedure TExplorerTabStrip.SetBackgroundGradientEndColor(
  const AValue: TColor);
begin
  if FPalette.StripBottom = AValue then
    Exit;
  FPalette.StripBottom := AValue;
  Invalidate;
end;

function TExplorerTabStrip.GetBackgroundTopLineColor: TColor;
begin
  Result := FPalette.BackgroundTopLine;
end;

procedure TExplorerTabStrip.SetBackgroundTopLineColor(const AValue: TColor);
begin
  if FPalette.BackgroundTopLine = AValue then
    Exit;
  FPalette.BackgroundTopLine := AValue;
  Invalidate;
end;

procedure TExplorerTabStrip.SetBackgroundGradientDirection(
  const AValue: TExplorerTabGradientDirection);
begin
  if FBackgroundGradientDirection = AValue then
    Exit;
  FBackgroundGradientDirection := AValue;
  Invalidate;
end;

procedure TExplorerTabStrip.SetTabGradientDirection(
  const AValue: TExplorerTabGradientDirection);
begin
  if FTabGradientDirection = AValue then
    Exit;
  FTabGradientDirection := AValue;
  Invalidate;
end;

function TExplorerTabStrip.GetTabGradientStartColor: TColor;
begin
  Result := FPalette.TabTop;
end;

function TExplorerTabStrip.GetTabGradientEndColor: TColor;
begin
  Result := FPalette.TabBottom;
end;

procedure TExplorerTabStrip.SetTabGradientStartColor(const AValue: TColor);
begin
  if FPalette.TabTop = AValue then
    Exit;
  FPalette.TabTop := AValue;
  Invalidate;
end;

procedure TExplorerTabStrip.SetTabGradientEndColor(const AValue: TColor);
begin
  if FPalette.TabBottom = AValue then
    Exit;
  FPalette.TabBottom := AValue;
  Invalidate;
end;

function TExplorerTabStrip.GetTabHeight: Integer;
begin
  Result := FTabHeight;
end;

procedure TExplorerTabStrip.SetTabHeight(const AValue: Integer);
const
  cMinimumTabHeight = 16;
begin
  var LValue := Max(cMinimumTabHeight, AValue);
  if GetTabHeight = LValue then
    Exit;
  FTabHeight := LValue;
  Height := ScaleValue(FTabHeight);
  Invalidate;
end;

procedure TExplorerTabStrip.SetActiveIndex(const AValue: Integer);
begin
  var LIndex := EnsureRange(AValue, -1, FItems.Count - 1);
  if FActiveIndex = LIndex then Exit;
  FActiveIndex := LIndex;
  EnsureActiveTabVisible;
  Invalidate;
  if Assigned(FOnChange) then FOnChange(Self, FActiveIndex);
end;

procedure TExplorerTabStrip.SetShowAddButton(const AValue: Boolean);
begin
  if FShowAddButton = AValue then
    Exit;
  FShowAddButton := AValue;
  if not FShowAddButton then
  begin
    FHotAddButton := False;
    FPressedAddButton := False;
  end;
  EnsureActiveTabVisible;
  Invalidate;
end;

procedure TExplorerTabStrip.SetShowCustomLeftButton(const AValue: Boolean);
begin
  if FShowCustomLeftButton = AValue then
    Exit;
  FShowCustomLeftButton := AValue;
  if not FShowCustomLeftButton then
  begin
    FHotCustomLeftButton := False;
    FPressedCustomLeftButton := False;
  end;
  EnsureActiveTabVisible;
  Invalidate;
end;

procedure TExplorerTabStrip.SetShowCustomRightButton(const AValue: Boolean);
begin
  if FShowCustomRightButton = AValue then
    Exit;
  FShowCustomRightButton := AValue;
  if not FShowCustomRightButton then
  begin
    FHotCustomRightButton := False;
    FPressedCustomRightButton := False;
  end;
  EnsureActiveTabVisible;
  Invalidate;
end;

procedure TExplorerTabStrip.SetCustomLeftButtonContent(
  const AValue: TExplorerTabCustomButtonContent);
begin
  if FCustomLeftButtonContent <> AValue then
  begin
    FCustomLeftButtonContent := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetCustomRightButtonContent(
  const AValue: TExplorerTabCustomButtonContent);
begin
  if FCustomRightButtonContent <> AValue then
  begin
    FCustomRightButtonContent := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetCustomLeftButtonGlyph(
  const AValue: TExplorerTabCustomButtonGlyph);
begin
  if FCustomLeftButtonGlyph <> AValue then
  begin
    FCustomLeftButtonGlyph := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetCustomRightButtonGlyph(
  const AValue: TExplorerTabCustomButtonGlyph);
begin
  if FCustomRightButtonGlyph <> AValue then
  begin
    FCustomRightButtonGlyph := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetCustomLeftButtonImageIndex(
  const AValue: System.UITypes.TImageIndex);
begin
  if FCustomLeftButtonImageIndex <> AValue then
  begin
    FCustomLeftButtonImageIndex := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetCustomRightButtonImageIndex(
  const AValue: System.UITypes.TImageIndex);
begin
  if FCustomRightButtonImageIndex <> AValue then
  begin
    FCustomRightButtonImageIndex := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetTrailingReservedSpace(const AValue: Integer);
begin
  var LValue := Max(0, AValue);
  if FTrailingReservedSpace = LValue then
    Exit;
  FTrailingReservedSpace := LValue;
  EnsureActiveTabVisible;
  Invalidate;
end;

procedure TExplorerTabStrip.SetButtonHoverGlow(const AValue: Boolean);
begin
  if FButtonHoverGlow <> AValue then
  begin
    FButtonHoverGlow := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetButtonHoverBackground(const AValue: Boolean);
begin
  if FButtonHoverBackground <> AValue then
  begin
    FButtonHoverBackground := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetGlyphButtonNormalColor(const AValue: TColor);
begin
  if FGlyphButtonNormalColor <> AValue then
  begin
    FGlyphButtonNormalColor := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetGlyphButtonHotColor(const AValue: TColor);
begin
  if FGlyphButtonHotColor <> AValue then
  begin
    FGlyphButtonHotColor := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetGlyphButtonDisabledColor(const AValue: TColor);
begin
  if FGlyphButtonDisabledColor <> AValue then
  begin
    FGlyphButtonDisabledColor := AValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetCustomButtonGlyphSize(const AValue: Integer);
begin
  var LValue := Max(1, AValue);
  if FCustomButtonGlyphSize <> LValue then
  begin
    FCustomButtonGlyphSize := LValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.SetLeftInset(const AValue: Integer);
begin
  var LValue := Max(0, AValue);
  if FLeftInset <> LValue then
  begin
    FLeftInset := LValue;
    Invalidate;
  end;
end;

procedure TExplorerTabStrip.AddTab(const ACaption: string;
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

procedure TExplorerTabStrip.AddTab(const ACaption: string;
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

procedure TExplorerTabStrip.DeleteTab(AIndex: Integer);
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

function TExplorerTabStrip.IsOverflowing: Boolean;
begin
  if FItems.Count = 0 then
    Exit(False);
  EnsureTabWidthCache;
  var LRequiredWidth := ScaleValue(FLeftInset + cSelectedShoulderWidth);
  if IsCustomLeftButtonVisible then
    Inc(LRequiredWidth, ScaleValue(cCustomButtonWidth +
      FAddButtonSpacing - cSelectedShoulderWidth));
  Inc(LRequiredWidth, FTabPositionCache[FItems.Count] +
    ScaleValue(FTabOverlap));
  if HasTrailingActionButtons then
  begin
    Inc(LRequiredWidth, ScaleValue(FAddButtonSpacing));
    Inc(LRequiredWidth, GetActionButtonsWidth);
    Inc(LRequiredWidth, ScaleValue(FTrailingReservedSpace));
  end;
  Result := LRequiredWidth > Width;
end;

function TExplorerTabStrip.GetActionButtonsWidth: Integer;
begin
  Result := 0;
  if FShowAddButton then
    Inc(Result, ScaleValue(cAddButtonWidth));
  if IsCustomRightButtonVisible then
    Inc(Result, ScaleValue(cCustomButtonWidth));
end;

function TExplorerTabStrip.GetActionAreaRect: TRect;
begin
  if not HasTrailingActionButtons then
    Exit(TRect.Empty);
  var LWidth := GetActionButtonsWidth +
    ScaleValue(FTrailingReservedSpace);
  Result := Rect(Max(0, Width - LWidth), 0, Width, Height);
end;

function TExplorerTabStrip.GetActionButtonsLeft: Integer;
const
  cEmptyAddCenterOffset = 14;
  cAddButtonHalfWidth = 18;
begin
  if IsOverflowing then
    Exit(GetRightNavigationRect.Right);
  if FItems.Count = 0 then
  begin
    var LMinimumLeft := 0;
    if IsCustomLeftButtonVisible then
      LMinimumLeft := GetCustomLeftButtonRect.Right +
        ScaleValue(FAddButtonSpacing);
    var LCenterX := ScaleValue(FLeftInset + cEmptyAddCenterOffset);
    Exit(Max(LMinimumLeft, LCenterX - ScaleValue(cAddButtonHalfWidth)));
  end;
  Result := GetTabRect(FItems.Count - 1).Right +
    ScaleValue(FAddButtonSpacing);
end;

function TExplorerTabStrip.GetTabsViewport: TRect;
const
  cNavigationButtonWidth = 40;
begin
  Result := ClientRect;
  if IsOverflowing then
  begin
    var LAvailableRight := Width;
    if HasTrailingActionButtons then
      LAvailableRight := GetActionAreaRect.Left;
    var LButtonWidth := Min(LAvailableRight div 2,
      ScaleValue(cNavigationButtonWidth));
    Result.Left := LButtonWidth;
    Result.Right := Max(Result.Left, LAvailableRight - LButtonWidth);
  end;
  if IsCustomLeftButtonVisible then
    Result.Left := Min(Result.Right,
      Max(Result.Left, GetCustomLeftButtonRect.Right +
        ScaleValue(FAddButtonSpacing - cSelectedShoulderWidth)));
end;

function TExplorerTabStrip.GetAvailableBackgroundRect: TRect;
begin
  var LViewport := GetTabsViewport;
  Result := LViewport;
  if IsOverflowing and HasTrailingActionButtons then
  begin
    var LButtonsRight := 0;
    if IsAddButtonVisible then
      LButtonsRight := GetAddButtonRect.Right;
    if IsCustomRightButtonVisible then
      LButtonsRight := Max(LButtonsRight, GetCustomRightButtonRect.Right);
    Exit(Rect(Min(Width, LButtonsRight), 0, Width, Height));
  end;
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
      Inc(LTabRight, ScaleValue(cSelectedShoulderWidth));
    LContentRight := Max(LContentRight,
      Min(LTabRight, LViewport.Right));
  end;
  if IsCustomRightButtonVisible then
    LContentRight := Max(LContentRight,
      Min(GetCustomRightButtonRect.Right, LViewport.Right));
  if IsAddButtonVisible then
    LContentRight := Max(LContentRight,
      Min(GetAddButtonRect.Right, LViewport.Right));
  Result.Left := Min(Result.Right, LContentRight);
end;

function TExplorerTabStrip.GetLeftNavigationRect: TRect;
const
  cNavigationButtonWidth = 40;
begin
  if not IsOverflowing then
    Exit(TRect.Empty);
  var LAvailableRight := Width;
  if HasTrailingActionButtons then
    LAvailableRight := GetActionAreaRect.Left;
  var LButtonWidth := Min(LAvailableRight div 2,
    ScaleValue(cNavigationButtonWidth));
  Result := Rect(0, ScaleValue(cTabTop), LButtonWidth, Height);
end;

function TExplorerTabStrip.GetRightNavigationRect: TRect;
const
  cNavigationButtonWidth = 40;
  cNavigationControlSpacing = 4;
begin
  if not IsOverflowing then
    Exit(TRect.Empty);
  var LMaximumRight := Width;
  if HasTrailingActionButtons then
    LMaximumRight := GetActionAreaRect.Left;
  var LButtonWidth := Min(LMaximumRight,
    ScaleValue(cNavigationButtonWidth));
  var LLeft := Min(Max(0, LMaximumRight - LButtonWidth),
    GetVisibleTabsRight + ScaleValue(cNavigationControlSpacing));
  Result := Rect(LLeft, ScaleValue(cTabTop),
    LLeft + LButtonWidth, Height);
end;

function TExplorerTabStrip.GetVisibleTabsRight: Integer;
begin
  var LViewport := GetTabsViewport;
  Result := LViewport.Left;
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
      Inc(LTabRight, ScaleValue(cSelectedShoulderWidth));
    Result := Max(Result, Min(LTabRight, LViewport.Right));
  end;
end;

function TExplorerTabStrip.GetTabRect(AIndex: Integer): TRect;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit(TRect.Empty);
  var LFirstIndex := 0;
  var LLeft := ScaleValue(FLeftInset + cSelectedShoulderWidth);
  if IsOverflowing then
  begin
    LFirstIndex := EnsureRange(FFirstVisibleIndex, 0,
      Max(0, FItems.Count - 1));
    if AIndex < LFirstIndex then
      Exit(TRect.Empty);
    var LViewport := GetTabsViewport;
    LLeft := LViewport.Left + ScaleValue(cSelectedShoulderWidth);
  end;
  if IsCustomLeftButtonVisible then
    LLeft := Max(LLeft, GetCustomLeftButtonRect.Right +
      ScaleValue(FAddButtonSpacing));
  EnsureTabWidthCache;
  Inc(LLeft, FTabPositionCache[AIndex] - FTabPositionCache[LFirstIndex]);
  Result := Rect(LLeft, ScaleValue(cTabTop),
    LLeft + FTabWidthCache[AIndex], Height);
end;

function TExplorerTabStrip.GetCloseRect(AIndex: Integer): TRect;
const
  cCloseLeftInset = 30;
  cCloseRightInset = 8;
  cCloseHitHalfHeight = 11;
begin
  var LTab := GetTabRect(AIndex);
  var LCenterY := LTab.Top + LTab.Height div 2;
  Result := Rect(LTab.Right - ScaleValue(cCloseLeftInset),
    LCenterY - ScaleValue(cCloseHitHalfHeight),
    LTab.Right - ScaleValue(cCloseRightInset),
    LCenterY + ScaleValue(cCloseHitHalfHeight));
end;

function TExplorerTabStrip.GetAddButtonRect: TRect;
begin
  var LLeft := GetActionButtonsLeft;
  Result := Rect(LLeft, ScaleValue(cTabTop),
    LLeft + ScaleValue(cAddButtonWidth), Height);
end;

function TExplorerTabStrip.GetCustomLeftButtonRect: TRect;
begin
  if not IsCustomLeftButtonVisible then
    Exit(TRect.Empty);
  var LLeft := ScaleValue(FLeftInset);
  if IsOverflowing then
    LLeft := GetLeftNavigationRect.Right + ScaleValue(FAddButtonSpacing);
  Result := Rect(LLeft, ScaleValue(cTabTop),
    LLeft + ScaleValue(cCustomButtonWidth), Height);
end;

function TExplorerTabStrip.GetCustomRightButtonRect: TRect;
begin
  if not IsCustomRightButtonVisible then
    Exit(TRect.Empty);
  var LLeft := GetActionButtonsLeft;
  if FShowAddButton then
    Inc(LLeft, ScaleValue(cAddButtonWidth));
  Result := Rect(LLeft, ScaleValue(cTabTop),
    LLeft + ScaleValue(cCustomButtonWidth), Height);
end;

function TExplorerTabStrip.IsAddButtonVisible: Boolean;
begin
  Result := FShowAddButton;
end;

function TExplorerTabStrip.IsCustomLeftButtonVisible: Boolean;
begin
  Result := FShowCustomLeftButton;
end;

function TExplorerTabStrip.IsCustomRightButtonVisible: Boolean;
begin
  Result := FShowCustomRightButton;
end;

function TExplorerTabStrip.HasTrailingActionButtons: Boolean;
begin
  Result := FShowAddButton or IsCustomRightButtonVisible;
end;

function TExplorerTabStrip.CanNavigateLeft: Boolean;
begin
  Result := IsOverflowing and (FActiveIndex > 0);
end;

function TExplorerTabStrip.CanNavigateRight: Boolean;
begin
  Result := IsOverflowing and (FActiveIndex >= 0) and
    (FActiveIndex < FItems.Count - 1);
end;

procedure TExplorerTabStrip.EnsureActiveTabVisible;
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
      ScaleValue(cSelectedShoulderWidth);
    if LRequiredRight <= LViewport.Right then
      Break;
    Inc(FFirstVisibleIndex);
  end;

  { Once the active tab fits, backfill complete tabs from the left. This is
    especially important after a resize, deletion, or navigation to the final
    tab: the previous scroll origin may otherwise leave usable space empty. }
  while FFirstVisibleIndex > 0 do
  begin
    Dec(FFirstVisibleIndex);
    var LActiveRect := GetTabRect(FActiveIndex);
    var LRequiredRight := LActiveRect.Right +
      ScaleValue(cSelectedShoulderWidth);
    if LRequiredRight <= LViewport.Right then
      Continue;
    Inc(FFirstVisibleIndex);
    Break;
  end;
end;

function TExplorerTabStrip.ResolveImageIndex(
  AItem: TExplorerTabItem): System.UITypes.TImageIndex;
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

function TExplorerTabStrip.ResolveCustomButtonImageIndex(
  AImageIndex: System.UITypes.TImageIndex): System.UITypes.TImageIndex;
begin
  Result := -1;
  if Assigned(FImages) and (AImageIndex >= 0) and
    (AImageIndex < FImages.Count) then
    Result := AImageIndex;
end;

function TExplorerTabStrip.ButtonDrawState(
  AHot: Boolean): TExplorerTabButtonDrawState;
begin
  if not Enabled then
    Result := etbdsDisabled
  else if AHot then
    Result := etbdsHot
  else
    Result := etbdsNormal;
end;

function TExplorerTabStrip.GlyphButtonColor(
  AState: TExplorerTabButtonDrawState): TColor;
begin
  case AState of
    etbdsHot:
      Result := FGlyphButtonHotColor;
    etbdsDisabled:
      Result := FGlyphButtonDisabledColor;
  else
    Result := FGlyphButtonNormalColor;
  end;
end;

function TExplorerTabStrip.GetCustomButtonGlyphRect(
  const ARect: TRect): TRect;
begin
  var LSize := ScaleValue(FCustomButtonGlyphSize);
  LSize := Min(LSize, Min(ARect.Width, ARect.Height));
  var LCenterX := (ARect.Left + ARect.Right) div 2;
  var LCenterY := (ARect.Top + ARect.Bottom) div 2;
  Result := Rect(LCenterX - LSize div 2, LCenterY - LSize div 2,
    LCenterX - LSize div 2 + LSize, LCenterY - LSize div 2 + LSize);
end;

procedure TExplorerTabStrip.UpdateCustomButtonHint(const APoint: TPoint);
begin
  var LHint := '';
  if IsCustomLeftButtonVisible and
    PtInRect(GetCustomLeftButtonRect, APoint) then
    LHint := FCustomLeftButtonHint
  else if IsCustomRightButtonVisible and
    PtInRect(GetCustomRightButtonRect, APoint) then
    LHint := FCustomRightButtonHint;
  if Hint <> LHint then
    Hint := LHint;
end;

function TExplorerTabStrip.TabAt(const APoint: TPoint): Integer;
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

function TExplorerTabStrip.CloseAt(const APoint: TPoint): Integer;
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

procedure TExplorerTabStrip.DrawTab(ACanvas: TCanvas; AGraphics: TGPGraphics;
  AShape, AStrokePath, AFirstShoulderPath,
  ABaselinePath: TGPGraphicsPath; AInactiveOutlinePen,
  AClosePen, AHotClosePen: TGPPen; AIndex: Integer; ASelected: Boolean);
const
  cSelectedShoulderControlOffset = 5;
  cSelectedShoulderRise = 4;
  cSelectedShoulderHeight = 7;
  cFirstTabShoulderBlendOffset = 2;
  cFirstTabShoulderBottomAlpha = 12;
  cSelectedCornerDiameter = 14;
  cSelectedCornerRadius = 7;
  cInactiveCornerDiameter = 16;
  cInactiveCornerRadius = 8;
  cImageLeftInset = 15;
  cImageTextSpacing = 9;
  cTextLeftInset = 15;
  cTextRightSpacing = 6;
  cTextVerticalOffset = 1;
  cCloseGlyphInset = 7;
  cAccentFadeWidth = 72;
  cBaselineFadeWidth = 64;
  cBaselineFadeMidAlpha = 48;
  cSelectedGlowWidth = 2.0;
  cSelectedOutlineWidth = 1.0;
  cBaselineWidth = 1.0;
var
  LTop: ARGB;
  LBottom: ARGB;
  LTextColor: TColor;
  LCoreColors: array[0..2] of TGPColor;
  LGlowColors: array[0..2] of TGPColor;
  LPositions: array[0..2] of Single;
  LBaselineColors: array[0..5] of TGPColor;
  LBaselinePositions: array[0..5] of Single;
  LFirstShoulderBlendY: Integer;
begin
  var LTab := GetTabRect(AIndex);
  var LIsFirstSelected := ASelected and (AIndex = 0);
  var LLeftShoulder := LTab.Left - ScaleValue(cSelectedShoulderWidth);
  var LBaselineLeft: Integer := 0;
  var LBaselineRight: Integer := Width;
  if IsOverflowing then
  begin
    var LViewport := GetTabsViewport;
    LBaselineLeft := LViewport.Left;
  end;
  var LBaseY: Single := 0;
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

  var LGraphics := AGraphics;
  var LShape := AShape;
  var LStrokePath := AStrokePath;
  var LFirstShoulderPath := AFirstShoulderPath;
  var LBaselinePath := ABaselinePath;
  LShape.Reset;
  LStrokePath.Reset;
  LFirstShoulderPath.Reset;
  LBaselinePath.Reset;
  var LFill := TGPLinearGradientBrush.Create(MakeRect(LTab.Left,
    LTab.Top, LTab.Width, LTab.Height - LTab.Top), LTop, LBottom,
    GradientMode(FTabGradientDirection));
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);

    if ASelected then
    begin
      { The selected tab deliberately has no bottom outline: its two lower
        Bezier shoulders flow into the content plane, like the reference UI. }
      LShape.AddBezier(LTab.Left - ScaleValue(cSelectedShoulderWidth),
        LTab.Bottom,
        LTab.Left - ScaleValue(cSelectedShoulderControlOffset), LTab.Bottom,
        LTab.Left, LTab.Bottom - ScaleValue(cSelectedShoulderRise),
        LTab.Left, LTab.Bottom - ScaleValue(cSelectedShoulderHeight));
      LShape.AddLine(LTab.Left,
        LTab.Bottom - ScaleValue(cSelectedShoulderHeight), LTab.Left,
        LTab.Top + ScaleValue(cSelectedCornerRadius));
      LShape.AddArc(LTab.Left, LTab.Top,
        ScaleValue(cSelectedCornerDiameter),
        ScaleValue(cSelectedCornerDiameter), 180, 90);
      LShape.AddLine(LTab.Left + ScaleValue(cSelectedCornerRadius),
        LTab.Top, LTab.Right - ScaleValue(cSelectedCornerRadius), LTab.Top);
      LShape.AddArc(LTab.Right - ScaleValue(cSelectedCornerDiameter),
        LTab.Top, ScaleValue(cSelectedCornerDiameter),
        ScaleValue(cSelectedCornerDiameter), 270, 90);
      LShape.AddLine(LTab.Right,
        LTab.Top + ScaleValue(cSelectedCornerRadius), LTab.Right,
        LTab.Bottom - ScaleValue(cSelectedShoulderHeight));
      LShape.AddBezier(LTab.Right,
        LTab.Bottom - ScaleValue(cSelectedShoulderHeight), LTab.Right,
        LTab.Bottom - ScaleValue(cSelectedShoulderRise),
        LTab.Right + ScaleValue(cSelectedShoulderControlOffset), LTab.Bottom,
        LTab.Right + ScaleValue(cSelectedShoulderWidth), LTab.Bottom);
      LShape.AddLine(LTab.Right + ScaleValue(cSelectedShoulderWidth),
        LTab.Bottom, LTab.Left - ScaleValue(cSelectedShoulderWidth),
        LTab.Bottom);
      LShape.CloseFigure;

      LBaseY := LTab.Bottom - ScaleValue(cBaselineOffset);
      if LIsFirstSelected then
      begin
        LFirstShoulderBlendY := LTab.Top + LTab.Height div 2 +
          ScaleValue(cFirstTabShoulderBlendOffset);
        LStrokePath.AddLine(LTab.Left, LFirstShoulderBlendY, LTab.Left,
          LTab.Top + ScaleValue(cSelectedCornerRadius));
        LFirstShoulderPath.AddLine(LTab.Left, LFirstShoulderBlendY,
          LTab.Left, LBaseY - ScaleValue(cSelectedShoulderHeight));
        LFirstShoulderPath.AddBezier(LTab.Left,
          LBaseY - ScaleValue(cSelectedShoulderHeight), LTab.Left,
          LBaseY - ScaleValue(cSelectedShoulderRise),
          LTab.Left - ScaleValue(cSelectedShoulderControlOffset), LBaseY,
          LTab.Left - ScaleValue(cSelectedShoulderWidth), LBaseY);
      end
      else
      begin
        LStrokePath.AddBezier(
          LTab.Left - ScaleValue(cSelectedShoulderWidth), LBaseY,
          LTab.Left - ScaleValue(cSelectedShoulderControlOffset), LBaseY,
          LTab.Left, LBaseY - ScaleValue(cSelectedShoulderRise), LTab.Left,
          LBaseY - ScaleValue(cSelectedShoulderHeight));
        LStrokePath.AddLine(LTab.Left,
          LBaseY - ScaleValue(cSelectedShoulderHeight), LTab.Left,
          LTab.Top + ScaleValue(cSelectedCornerRadius));
      end;
      LStrokePath.AddArc(LTab.Left, LTab.Top,
        ScaleValue(cSelectedCornerDiameter),
        ScaleValue(cSelectedCornerDiameter), 180, 90);
      LStrokePath.AddLine(LTab.Left + ScaleValue(cSelectedCornerRadius),
        LTab.Top, LTab.Right - ScaleValue(cSelectedCornerRadius), LTab.Top);
      LStrokePath.AddArc(LTab.Right - ScaleValue(cSelectedCornerDiameter),
        LTab.Top, ScaleValue(cSelectedCornerDiameter),
        ScaleValue(cSelectedCornerDiameter), 270, 90);
      LStrokePath.AddLine(LTab.Right,
        LTab.Top + ScaleValue(cSelectedCornerRadius), LTab.Right,
        LBaseY - ScaleValue(cSelectedShoulderHeight));
      LStrokePath.AddBezier(LTab.Right,
        LBaseY - ScaleValue(cSelectedShoulderHeight), LTab.Right,
        LBaseY - ScaleValue(cSelectedShoulderRise),
        LTab.Right + ScaleValue(cSelectedShoulderControlOffset), LBaseY,
        LTab.Right + ScaleValue(cSelectedShoulderWidth), LBaseY);
      if not LIsFirstSelected and (LLeftShoulder > LBaselineLeft) then
      begin
        LBaselinePath.AddLine(LBaselineLeft, LBaseY,
          LLeftShoulder, LBaseY);
        LBaselinePath.StartFigure;
      end;
      LBaselinePath.AddLine(
        LTab.Right + ScaleValue(cSelectedShoulderWidth), LBaseY,
        LBaselineRight, LBaseY);
    end
    else
    begin
      LShape.AddLine(LTab.Left, LTab.Bottom, LTab.Left,
        LTab.Top + ScaleValue(cInactiveCornerRadius));
      LShape.AddArc(LTab.Left, LTab.Top,
        ScaleValue(cInactiveCornerDiameter),
        ScaleValue(cInactiveCornerDiameter), 180, 90);
      LShape.AddLine(LTab.Left + ScaleValue(cInactiveCornerRadius), LTab.Top,
        LTab.Right - ScaleValue(cInactiveCornerRadius), LTab.Top);
      LShape.AddArc(LTab.Right - ScaleValue(cInactiveCornerDiameter),
        LTab.Top, ScaleValue(cInactiveCornerDiameter),
        ScaleValue(cInactiveCornerDiameter), 270, 90);
      LShape.AddLine(LTab.Right,
        LTab.Top + ScaleValue(cInactiveCornerRadius), LTab.Right,
        LTab.Bottom);
      LShape.AddLine(LTab.Right, LTab.Bottom, LTab.Left, LTab.Bottom);
      LShape.CloseFigure;
      LStrokePath.AddPath(LShape, False);
    end;

    LGraphics.FillPath(LFill, LShape);
    if ASelected then
    begin
      var LGradientStart: Integer := 0;
      var LFadeStart: Integer := Max(LGradientStart, Width - ScaleValue(cAccentFadeWidth));
      var LGradientRect: TGPRect := MakeRect(LGradientStart, 0,
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
          var LBaselineSpan := Max(1, LBaselineRight - LBaselineLeft);
          var LBaselineLeftFadeEnd: Integer := Min(
            LBaselineLeft + ScaleValue(cBaselineFadeWidth),
            Max(LBaselineLeft + 1, LLeftShoulder));
          var LBaselineRightFadeStart: Integer := Max(LBaselineLeftFadeEnd,
            LBaselineRight - ScaleValue(cBaselineFadeWidth));
          LBaselinePositions[0] := 0;
          LBaselinePositions[1] := EnsureRange(
            ((LBaselineLeftFadeEnd - LBaselineLeft) div 2) /
            LBaselineSpan, 0.0, 1.0);
          LBaselinePositions[2] := EnsureRange(
            (LBaselineLeftFadeEnd - LBaselineLeft) /
            LBaselineSpan, 0.0, 1.0);
          LBaselinePositions[3] := EnsureRange(
            (LBaselineRightFadeStart - LBaselineLeft) /
            LBaselineSpan, 0.0, 1.0);
          LBaselinePositions[4] := EnsureRange(
            (LBaselineRightFadeStart - LBaselineLeft +
            (LBaselineRight - LBaselineRightFadeStart) div 2) /
            LBaselineSpan, 0.0, 1.0);
          LBaselinePositions[5] := 1;
          LBaselineColors[0] := ToArgb(FPalette.Accent, 0);
          LBaselineColors[1] := ToArgb(FPalette.Accent,
            cBaselineFadeMidAlpha);
          LBaselineColors[2] := ToArgb(FPalette.Accent);
          LBaselineColors[3] := ToArgb(FPalette.Accent);
          LBaselineColors[4] := ToArgb(FPalette.Accent,
            cBaselineFadeMidAlpha);
          LBaselineColors[5] := ToArgb(FPalette.Accent, 0);

          var LGlowPen := TGPPen.Create(LGlowGradient,
            ScaleValue(cSelectedGlowWidth));
          try
            var LOutlinePen := TGPPen.Create(LAccentGradient,
              ScaleValue(cSelectedOutlineWidth));
            try
              var LBaselineGradient := TGPLinearGradientBrush.Create(
                MakeRect(LBaselineLeft, 0, LBaselineSpan, Height),
                ToArgb(FPalette.Accent, 0), ToArgb(FPalette.Accent, 0),
                LinearGradientModeHorizontal);
              try
                LBaselineGradient.SetInterpolationColors(@LBaselineColors[0],
                  @LBaselinePositions[0], Length(LBaselineColors));
                var LBaselinePen := TGPPen.Create(LBaselineGradient,
                  ScaleValue(cBaselineWidth));
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
                      LTab.Left - ScaleValue(cSelectedShoulderWidth),
                      LFirstShoulderBlendY,
                      ScaleValue(cSelectedShoulderWidth) + 1,
                      Max(1, Round(LBaseY) - LFirstShoulderBlendY + 1));
                    var LFirstShoulderGlow := TGPLinearGradientBrush.Create(
                      LFirstShoulderRect,
                      ToArgb(BlendColor(FPalette.Accent,
                        FPalette.BackgroundTopLine, 34)),
                      ToArgb(FPalette.Accent, 0),
                      LinearGradientModeVertical);
                    try
                      var LFirstShoulderGlowPen := TGPPen.Create(
                        LFirstShoulderGlow, ScaleValue(cSelectedGlowWidth));
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
                          cFirstTabShoulderBottomAlpha),
                        LinearGradientModeVertical);
                    try
                      var LFirstShoulderOutlinePen := TGPPen.Create(
                        LFirstShoulderOutline,
                        ScaleValue(cSelectedOutlineWidth));
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
      LGraphics.DrawPath(AInactiveOutlinePen, LStrokePath);
    end;

    LGraphics.Flush(FlushIntentionSync);
    var LContentCenterY: Integer := LTab.Top + LTab.Height div 2;
    var LTextLeft := LTab.Left + ScaleValue(cTextLeftInset);
    var LImageIndex := ResolveImageIndex(FItems[AIndex]);
    if LImageIndex >= 0 then
    begin
      var LImageLeft := LTab.Left + ScaleValue(cImageLeftInset);
      var LImageTop := LContentCenterY - FImages.Height div 2;
      FImages.Draw(ACanvas, LImageLeft, LImageTop, LImageIndex, Enabled);
      LTextLeft := LImageLeft + FImages.Width +
        ScaleValue(cImageTextSpacing);
    end;

    var LClose: TRect := GetCloseRect(AIndex);
    ACanvas.Brush.Style := bsClear;
    if ASelected then
      ACanvas.Font.Name := 'Segoe UI Semibold'
    else
      ACanvas.Font.Name := 'Segoe UI';
    ACanvas.Font.Height := -ScaleValue(cTextHeight);
    ACanvas.Font.Style := [];
    var LOldBkMode: Integer := SetBkMode(ACanvas.Handle, TRANSPARENT);
    var LOldTextColor: COLORREF := SetTextColor(ACanvas.Handle, ColorToRGB(LTextColor));
    var LTextRect: TRect := Rect(LTextLeft,
      LTab.Top - ScaleValue(cTextVerticalOffset),
      LClose.Left - ScaleValue(cTextRightSpacing),
      LTab.Bottom - ScaleValue(cTextVerticalOffset));
    var LFlags: Cardinal := DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX;
    DrawText(ACanvas.Handle, PChar(FItems[AIndex].Caption), -1, LTextRect, LFlags);
    SetTextColor(ACanvas.Handle, LOldTextColor);
    SetBkMode(ACanvas.Handle, LOldBkMode);

    if FItems[AIndex].Closable then
    begin
      if FHotCloseIndex = AIndex then
      begin
        if FButtonHoverBackground then
        begin
          var LHoverRect: TRect := Rect((LClose.Left + LClose.Right) div 2 -
            ScaleValue(cButtonHoverHalfWidth),
            LContentCenterY - ScaleValue(cButtonHoverHalfHeight),
            (LClose.Left + LClose.Right) div 2 +
            ScaleValue(cButtonHoverHalfWidth),
            LContentCenterY + ScaleValue(cButtonHoverHalfHeight));
          FillRoundedHover(LGraphics, LHoverRect,
            ScaleValue(cButtonHoverRadius),
            FPalette.CloseHover);
        end;
        if FButtonHoverGlow then
          DrawTwoLineGlow(LGraphics,
            LClose.Left + ScaleValue(cCloseGlyphInset),
            LClose.Top + ScaleValue(cCloseGlyphInset),
            LClose.Right - ScaleValue(cCloseGlyphInset),
            LClose.Bottom - ScaleValue(cCloseGlyphInset),
            LClose.Right - ScaleValue(cCloseGlyphInset),
            LClose.Top + ScaleValue(cCloseGlyphInset),
            LClose.Left + ScaleValue(cCloseGlyphInset),
            LClose.Bottom - ScaleValue(cCloseGlyphInset),
            FPalette.Accent, ScaleValue(1.0));
      end;
      var LGlyphPen := AClosePen;
      if FHotCloseIndex = AIndex then
        LGlyphPen := AHotClosePen;
      LGraphics.DrawLine(LGlyphPen,
          LClose.Left + ScaleValue(cCloseGlyphInset),
          LClose.Top + ScaleValue(cCloseGlyphInset),
          LClose.Right - ScaleValue(cCloseGlyphInset),
          LClose.Bottom - ScaleValue(cCloseGlyphInset));
      LGraphics.DrawLine(LGlyphPen,
          LClose.Right - ScaleValue(cCloseGlyphInset),
          LClose.Top + ScaleValue(cCloseGlyphInset),
          LClose.Left + ScaleValue(cCloseGlyphInset),
          LClose.Bottom - ScaleValue(cCloseGlyphInset));
    end;
  finally
    LFill.Free;
  end;
end;

procedure TExplorerTabStrip.DrawNavigationButton(AGraphics: TGPGraphics;
  const ARect: TRect; ALeft, AHot, AEnabled: Boolean);
const
  cNavigationGlyphHalfWidth = 3;
  cNavigationGlyphHalfHeight = 5;
  cNavigationLineWidth = 1.5;
var
  LState: TExplorerTabButtonDrawState;
  LX1: Single;
  LY1: Single;
  LX2: Single;
  LY2: Single;
  LX3: Single;
  LY3: Single;
begin
  var LGraphics := AGraphics;
  LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
  LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);

    if not AEnabled then
      LState := etbdsDisabled
    else
      LState := ButtonDrawState(AHot);

    var LCenterX := (ARect.Left + ARect.Right) div 2;
    var LCenterY := (ARect.Top + ARect.Bottom) div 2;
    if ALeft then
    begin
      LX1 := LCenterX + ScaleValue(cNavigationGlyphHalfWidth);
      LY1 := LCenterY - ScaleValue(cNavigationGlyphHalfHeight);
      LX2 := LCenterX - ScaleValue(cNavigationGlyphHalfWidth);
      LY2 := LCenterY;
      LX3 := LX1;
      LY3 := LCenterY + ScaleValue(cNavigationGlyphHalfHeight);
    end
    else
    begin
      LX1 := LCenterX - ScaleValue(cNavigationGlyphHalfWidth);
      LY1 := LCenterY - ScaleValue(cNavigationGlyphHalfHeight);
      LX2 := LCenterX + ScaleValue(cNavigationGlyphHalfWidth);
      LY2 := LCenterY;
      LX3 := LX1;
      LY3 := LCenterY + ScaleValue(cNavigationGlyphHalfHeight);
    end;

    if LState = etbdsHot then
    begin
      if FButtonHoverBackground then
      begin
        var LHoverRect := Rect(
          LCenterX - ScaleValue(cButtonHoverHalfWidth),
          LCenterY - ScaleValue(cButtonHoverHalfHeight),
          LCenterX + ScaleValue(cButtonHoverHalfWidth),
          LCenterY + ScaleValue(cButtonHoverHalfHeight));
        FillRoundedHover(LGraphics, LHoverRect,
          ScaleValue(cButtonHoverRadius), FPalette.CloseHover);
      end;
      if FButtonHoverGlow then
        DrawTwoLineGlow(LGraphics, LX1, LY1, LX2, LY2,
          LX2, LY2, LX3, LY3, FPalette.Accent, ScaleValue(1.0));
    end;

    var LColor := GlyphButtonColor(LState);
    var LChevronPen := TGPPen.Create(ToArgb(LColor),
      ScaleValue(cNavigationLineWidth));
    try
      LChevronPen.SetStartCap(LineCapRound);
      LChevronPen.SetEndCap(LineCapRound);
      LChevronPen.SetLineJoin(LineJoinRound);
      LGraphics.DrawLine(LChevronPen, LX1, LY1, LX2, LY2);
      LGraphics.DrawLine(LChevronPen, LX2, LY2, LX3, LY3);
    finally
      LChevronPen.Free;
    end;
end;

procedure TExplorerTabStrip.DrawButtonGlyph(AGraphics: TGPGraphics;
  const ARect: TRect; AGlyph: TExplorerTabCustomButtonGlyph;
  AState: TExplorerTabButtonDrawState);
const
  cChevronGlyphHalfWidth = 4;
  { Preserve the compact chevron geometry used by the original drop-down
    button: its 4 x 2 shape deliberately reads differently from the larger
    plus and close glyphs. }
  cChevronGlyphHalfHeight = 2;
  cPlusGlyphHalfSize = 5;
  cCloseGlyphHalfSize = 4;
  cGlyphLineWidth = 1.35;
var
  LX1: Single;
  LY1: Single;
  LX2: Single;
  LY2: Single;
  LX3: Single;
  LY3: Single;
begin
  var LGraphics := AGraphics;
  LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
  LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
  var LCenterX := (ARect.Left + ARect.Right) div 2;
  var LCenterY := (ARect.Top + ARect.Bottom) div 2;
  case AGlyph of
    etcbgChevronLeft:
      begin
        LX1 := LCenterX + ScaleValue(cChevronGlyphHalfWidth);
        LY1 := LCenterY - ScaleValue(cChevronGlyphHalfHeight);
        LX2 := LCenterX - ScaleValue(cChevronGlyphHalfWidth);
        LY2 := LCenterY;
        LX3 := LX1;
        LY3 := LCenterY + ScaleValue(cChevronGlyphHalfHeight);
      end;
    etcbgChevronRight:
      begin
        LX1 := LCenterX - ScaleValue(cChevronGlyphHalfWidth);
        LY1 := LCenterY - ScaleValue(cChevronGlyphHalfHeight);
        LX2 := LCenterX + ScaleValue(cChevronGlyphHalfWidth);
        LY2 := LCenterY;
        LX3 := LX1;
        LY3 := LCenterY + ScaleValue(cChevronGlyphHalfHeight);
      end;
    etcbgChevronUp:
      begin
        LX1 := LCenterX - ScaleValue(cChevronGlyphHalfWidth);
        LY1 := LCenterY + ScaleValue(cChevronGlyphHalfHeight);
        LX2 := LCenterX;
        LY2 := LCenterY - ScaleValue(cChevronGlyphHalfHeight);
        LX3 := LCenterX + ScaleValue(cChevronGlyphHalfWidth);
        LY3 := LY1;
      end;
    etcbgPlus:
      begin
        LX1 := LCenterX - ScaleValue(cPlusGlyphHalfSize);
        LY1 := LCenterY;
        LX2 := LCenterX + ScaleValue(cPlusGlyphHalfSize);
        LY2 := LCenterY;
        LX3 := LCenterX;
        LY3 := LCenterY - ScaleValue(cPlusGlyphHalfSize);
      end;
    etcbgClose:
      begin
        LX1 := LCenterX - ScaleValue(cCloseGlyphHalfSize);
        LY1 := LCenterY - ScaleValue(cCloseGlyphHalfSize);
        LX2 := LCenterX + ScaleValue(cCloseGlyphHalfSize);
        LY2 := LCenterY + ScaleValue(cCloseGlyphHalfSize);
        LX3 := LCenterX + ScaleValue(cCloseGlyphHalfSize);
        LY3 := LCenterY - ScaleValue(cCloseGlyphHalfSize);
      end;
  else
    begin
      LX1 := LCenterX - ScaleValue(cChevronGlyphHalfWidth);
      LY1 := LCenterY - ScaleValue(cChevronGlyphHalfHeight);
      LX2 := LCenterX;
      LY2 := LCenterY + ScaleValue(cChevronGlyphHalfHeight);
      LX3 := LCenterX + ScaleValue(cChevronGlyphHalfWidth);
      LY3 := LY1;
    end;
  end;

  if AState = etbdsHot then
  begin
    if FButtonHoverBackground then
    begin
      var LHoverRect := Rect(
        LCenterX - ScaleValue(cButtonHoverHalfWidth),
        LCenterY - ScaleValue(cButtonHoverHalfHeight),
        LCenterX + ScaleValue(cButtonHoverHalfWidth),
        LCenterY + ScaleValue(cButtonHoverHalfHeight));
      FillRoundedHover(LGraphics, LHoverRect,
        ScaleValue(cButtonHoverRadius), FPalette.CloseHover);
    end;
    if FButtonHoverGlow then
    begin
      if AGlyph = etcbgPlus then
        DrawTwoLineGlow(LGraphics, LX1, LY1, LX2, LY2, LX3, LY3,
          LX3, LCenterY + ScaleValue(cPlusGlyphHalfSize), FPalette.Accent,
          ScaleValue(1.0))
      else if AGlyph = etcbgClose then
        DrawTwoLineGlow(LGraphics, LX1, LY1, LX2, LY2, LX3, LY3,
          LCenterX - ScaleValue(cCloseGlyphHalfSize),
          LCenterY + ScaleValue(cCloseGlyphHalfSize), FPalette.Accent,
          ScaleValue(1.0))
      else
        DrawTwoLineGlow(LGraphics, LX1, LY1, LX2, LY2, LX2, LY2, LX3,
          LY3, FPalette.Accent, ScaleValue(1.0));
    end;
  end;

  var LColor := GlyphButtonColor(AState);
  var LGlyphPen := TGPPen.Create(ToArgb(LColor),
    ScaleValue(cGlyphLineWidth));
  try
    LGlyphPen.SetStartCap(LineCapRound);
    LGlyphPen.SetEndCap(LineCapRound);
    LGlyphPen.SetLineJoin(LineJoinRound);
    LGraphics.DrawLine(LGlyphPen, LX1, LY1, LX2, LY2);
    if AGlyph = etcbgPlus then
      LGraphics.DrawLine(LGlyphPen, LX3, LY3, LX3,
        LCenterY + ScaleValue(cPlusGlyphHalfSize))
    else if AGlyph = etcbgClose then
      LGraphics.DrawLine(LGlyphPen, LX3, LY3,
        LCenterX - ScaleValue(cCloseGlyphHalfSize),
        LCenterY + ScaleValue(cCloseGlyphHalfSize))
    else
      LGraphics.DrawLine(LGlyphPen, LX2, LY2, LX3, LY3);
  finally
    LGlyphPen.Free;
  end;
end;

procedure TExplorerTabStrip.DrawCustomButton(ACanvas: TCanvas;
  AGraphics: TGPGraphics; const ARect: TRect;
  AButton: TExplorerTabCustomButton; AState: TExplorerTabButtonDrawState;
  AContent: TExplorerTabCustomButtonContent;
  AGlyph: TExplorerTabCustomButtonGlyph;
  AImageIndex: System.UITypes.TImageIndex);
begin
  var LCenterX := (ARect.Left + ARect.Right) div 2;
  var LCenterY := (ARect.Top + ARect.Bottom) div 2;
  if (AState = etbdsHot) and FButtonHoverBackground then
  begin
    var LHoverRect := Rect(
      LCenterX - ScaleValue(cButtonHoverHalfWidth),
      LCenterY - ScaleValue(cButtonHoverHalfHeight),
      LCenterX + ScaleValue(cButtonHoverHalfWidth),
      LCenterY + ScaleValue(cButtonHoverHalfHeight));
    FillRoundedHover(AGraphics, LHoverRect, ScaleValue(cButtonHoverRadius),
      FPalette.CloseHover);
  end;

  AGraphics.Flush(FlushIntentionSync);
  var LHandled := False;
  if Assigned(FOnCustomButtonDraw) then
    FOnCustomButtonDraw(Self, AButton, ACanvas, ARect,
      GetCustomButtonGlyphRect(ARect), AState, GlyphButtonColor(AState),
      LHandled);
  if LHandled then
    Exit;

  var LImageIndex := -1;
  if AContent = etcbcImage then
    LImageIndex := ResolveCustomButtonImageIndex(AImageIndex);
  if LImageIndex < 0 then
  begin
    DrawButtonGlyph(AGraphics, ARect, AGlyph, AState);
    Exit;
  end;

  FImages.Draw(ACanvas, LCenterX - FImages.Width div 2,
    LCenterY - FImages.Height div 2, LImageIndex, AState <> etbdsDisabled);
end;

procedure TExplorerTabStrip.Paint;
const
  cInactiveOutlineWidth = 1.0;
  cCloseLineWidth = 1.25;
begin
  { Draw directly to VCL's double-buffered paint surface. Rendering into a
    second TBitmap here softens ClearType and path edges on scaled displays. }
  var LGraphics := TGPGraphics.Create(Canvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    var LBack := TGPLinearGradientBrush.Create(MakeRect(0, 0, Width, Height),
      ToArgb(FPalette.StripTop), ToArgb(FPalette.StripBottom),
      GradientMode(FBackgroundGradientDirection));
    try
      LGraphics.FillRectangle(LBack, 0, 0, Width, Height);
    finally
      LBack.Free;
    end;

    EnsureActiveTabVisible;
    LGraphics.Flush(FlushIntentionSync);
    DoAfterPaintBackground(Canvas, GetAvailableBackgroundRect);
    var LViewport := GetTabsViewport;
    var LFirstIndex := 0;
    if IsOverflowing then
      LFirstIndex := FFirstVisibleIndex;
    var LSavedDC := SaveDC(Canvas.Handle);
    try
      var LTabClipRegion := CreateRectRgn(LViewport.Left, LViewport.Top,
        LViewport.Right, LViewport.Bottom);
      try
        var LBaselineClipRegion := CreateRectRgn(LViewport.Left,
          Max(0, Height - ScaleValue(2)), Width, Height);
        try
          CombineRgn(LTabClipRegion, LTabClipRegion, LBaselineClipRegion,
            RGN_OR);
          ExtSelectClipRgn(Canvas.Handle, LTabClipRegion, RGN_AND);
        finally
          DeleteObject(LBaselineClipRegion);
        end;

        { One graphics context and one set of mutable paths serve every visible
          tab. The paths are reset by DrawTab before the next geometry is built. }
        var LTabGraphics := TGPGraphics.Create(Canvas.Handle);
        try
          var LShape := TGPGraphicsPath.Create;
          try
            var LStrokePath := TGPGraphicsPath.Create;
            try
              var LFirstShoulderPath := TGPGraphicsPath.Create;
              try
                var LBaselinePath := TGPGraphicsPath.Create;
                try
                  var LInactiveOutlinePen := TGPPen.Create(
                    ToArgb(FPalette.StripBorder, 180),
                    ScaleValue(cInactiveOutlineWidth));
                  try
                    var LClosePen := TGPPen.Create(ToArgb(FPalette.InactiveText),
                      ScaleValue(cCloseLineWidth));
                    try
                      var LHotClosePen := TGPPen.Create(ToArgb(FPalette.Accent),
                        ScaleValue(cCloseLineWidth));
                      try
                        LTabGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
                        LTabGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
                        LClosePen.SetStartCap(LineCapRound);
                        LClosePen.SetEndCap(LineCapRound);
                        LHotClosePen.SetStartCap(LineCapRound);
                        LHotClosePen.SetEndCap(LineCapRound);
                        for var LIndex := LFirstIndex to FItems.Count - 1 do
                        begin
                          var LTabRect := GetTabRect(LIndex);
                          if LTabRect.Left >= LViewport.Right then
                            Break;
                          if LIndex <> FActiveIndex then
                          begin
                            DrawTab(Canvas, LTabGraphics, LShape, LStrokePath,
                              LFirstShoulderPath, LBaselinePath, LInactiveOutlinePen,
                              LClosePen, LHotClosePen, LIndex, False);
                            LTabGraphics.Flush(FlushIntentionSync);
                            DoAfterPaintTab(Canvas, LTabRect, LIndex, False,
                              LIndex = FHotIndex);
                          end;
                        end;
                        if FActiveIndex >= 0 then
                        begin
                          DrawTab(Canvas, LTabGraphics, LShape, LStrokePath,
                            LFirstShoulderPath, LBaselinePath, LInactiveOutlinePen,
                            LClosePen, LHotClosePen, FActiveIndex, True);
                          LTabGraphics.Flush(FlushIntentionSync);
                          DoAfterPaintTab(Canvas, GetTabRect(FActiveIndex), FActiveIndex,
                            True, FActiveIndex = FHotIndex);
                        end;
                      finally
                        LHotClosePen.Free;
                      end;
                    finally
                      LClosePen.Free;
                    end;
                  finally
                    LInactiveOutlinePen.Free;
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
          LTabGraphics.Free;
        end;
      finally
        DeleteObject(LTabClipRegion);
      end;
    finally
      RestoreDC(Canvas.Handle, LSavedDC);
    end;

    if IsAddButtonVisible then
      DrawButtonGlyph(LGraphics, GetAddButtonRect, etcbgPlus,
        ButtonDrawState(FHotAddButton));

    if IsCustomLeftButtonVisible then
      DrawCustomButton(Canvas, LGraphics, GetCustomLeftButtonRect,
        etcbLeft, ButtonDrawState(FHotCustomLeftButton),
        FCustomLeftButtonContent,
        FCustomLeftButtonGlyph, FCustomLeftButtonImageIndex);
    if IsCustomRightButtonVisible then
      DrawCustomButton(Canvas, LGraphics, GetCustomRightButtonRect,
        etcbRight, ButtonDrawState(FHotCustomRightButton),
        FCustomRightButtonContent,
        FCustomRightButtonGlyph, FCustomRightButtonImageIndex);

    if IsOverflowing then
    begin
      DrawNavigationButton(LGraphics, GetLeftNavigationRect, True,
        FHotLeftNavigation, CanNavigateLeft);
      DrawNavigationButton(LGraphics, GetRightNavigationRect, False,
        FHotRightNavigation, CanNavigateRight);
    end;
  finally
    LGraphics.Free;
  end;
end;

procedure TExplorerTabStrip.MouseDown(Button: TMouseButton; Shift: TShiftState;
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
  if IsCustomLeftButtonVisible and
    PtInRect(GetCustomLeftButtonRect, LPoint) then
  begin
    FPressedCustomLeftButton := True;
    Invalidate;
    Exit;
  end;
  if IsCustomRightButtonVisible and
    PtInRect(GetCustomRightButtonRect, LPoint) then
  begin
    FPressedCustomRightButton := True;
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

procedure TExplorerTabStrip.MouseMove(Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  var LPoint := Point(X, Y);
  var LTab := TabAt(LPoint);
  var LClose := CloseAt(LPoint);
  var LHotAdd := IsAddButtonVisible and
    PtInRect(GetAddButtonRect, LPoint);
  var LHotCustomLeft := IsCustomLeftButtonVisible and
    PtInRect(GetCustomLeftButtonRect, LPoint);
  var LHotCustomRight := IsCustomRightButtonVisible and
    PtInRect(GetCustomRightButtonRect, LPoint);
  var LHotLeft := CanNavigateLeft and
    PtInRect(GetLeftNavigationRect, LPoint);
  var LHotRight := CanNavigateRight and
    PtInRect(GetRightNavigationRect, LPoint);
  if (LTab <> FHotIndex) or (LClose <> FHotCloseIndex) or
    (LHotAdd <> FHotAddButton) or
    (LHotCustomLeft <> FHotCustomLeftButton) or
    (LHotCustomRight <> FHotCustomRightButton) or
    (LHotLeft <> FHotLeftNavigation) or
    (LHotRight <> FHotRightNavigation) then
  begin
    FHotIndex := LTab;
    FHotCloseIndex := LClose;
    FHotAddButton := LHotAdd;
    FHotCustomLeftButton := LHotCustomLeft;
    FHotCustomRightButton := LHotCustomRight;
    FHotLeftNavigation := LHotLeft;
    FHotRightNavigation := LHotRight;
    Invalidate;
  end;
  UpdateCustomButtonHint(LPoint);
end;

procedure TExplorerTabStrip.MouseUp(Button: TMouseButton; Shift: TShiftState;
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
  if FPressedCustomLeftButton then
  begin
    FPressedCustomLeftButton := False;
    Invalidate;
    if IsCustomLeftButtonVisible and
      PtInRect(GetCustomLeftButtonRect, LPoint) then
      DoCustomLeftButtonClick;
    Exit;
  end;
  if FPressedCustomRightButton then
  begin
    FPressedCustomRightButton := False;
    Invalidate;
    if IsCustomRightButtonVisible and
      PtInRect(GetCustomRightButtonRect, LPoint) then
      DoCustomRightButtonClick;
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

procedure TExplorerTabStrip.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FHotIndex := -1;
  FHotCloseIndex := -1;
  FHotAddButton := False;
  FHotCustomLeftButton := False;
  FHotCustomRightButton := False;
  Hint := '';
  FHotLeftNavigation := False;
  FHotRightNavigation := False;
  FPressedCloseIndex := -1;
  Invalidate;
end;

end.
