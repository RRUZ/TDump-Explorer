//**************************************************************************************************
//
// Unit TDump.Explorer.PopupMenu
//
// Modern highlighter-based popup menu
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.PopupMenu;

interface

uses
  Winapi.Messages, System.Classes, System.Types, Vcl.Controls, Vcl.Forms,
  Vcl.Themes, Vcl.TitleBarCtrls, TDump.Explorer.HighlighterControl;

type
  TExplorerPopupMenuItemClick = procedure(Sender: TObject;
    AItemIndex: Integer) of object;

  TExplorerPopupMenuForm = class(TForm)
  published
    MenuItemsControl: THighlighterControl;
    TitleBarPanel1: TTitleBarPanel;
    procedure FormDeactivate(Sender: TObject);
  private
    FOnItemClick: TExplorerPopupMenuItemClick;
    procedure MenuItemsClick(Sender: TObject);
    procedure WMNCHitTest(var AMessage: TWMNCHitTest); message WM_NCHITTEST;
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure ApplyTheme;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    //procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ShowAt(const APoint: TPoint);
    property MenuItems: THighlighterControl read MenuItemsControl;
    property OnItemClick: TExplorerPopupMenuItemClick read FOnItemClick
      write FOnItemClick;
  end;

implementation

uses
  System.Math, Winapi.Windows, TDump.Explorer.UI, Vcl.Graphics;

{$R *.dfm}

procedure TExplorerPopupMenuForm.ApplyTheme;
begin
  CustomTitleBar.BackgroundColor := TExplorerTheme.ActiveTheme.BackgroundColor;
  CustomTitleBar.InactiveBackgroundColor := TExplorerTheme.ActiveTheme.BackgroundColor;
end;

procedure TExplorerPopupMenuForm.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  ApplyTheme;
end;

constructor TExplorerPopupMenuForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  // These settings are not published by THighlighterControl, so they cannot
  // be streamed from the DFM.  The visual frame itself and its static layout
  // are design-time components.
  MenuItemsControl.UseColumnMode := False;
  MenuItemsControl.AutoSizeColumns := False;
  MenuItemsControl.ControlList1.ItemHeight := ScaleValue(40);
  MenuItemsControl.OnItemClick := MenuItemsClick;

  ApplyTheme;
end;

procedure TExplorerPopupMenuForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := Params.Style or WS_SIZEBOX;
end;

procedure TExplorerPopupMenuForm.ShowAt(const APoint: TPoint);
begin
  ClientWidth := ScaleValue(256);
  ClientHeight := ScaleValue(130);
  var LPopupWidth := Width;
  var LPopupHeight := Height;
  var LWorkArea := Screen.WorkAreaRect;
  // The chevron click point is its centre.  Start the popup at that button
  // instead of right-aligning it to the pointer, which could place it outside
  // the owner window when the tabs are near the left edge.
  var LLeft := EnsureRange(APoint.X - ScaleValue(14),
    LWorkArea.Left, LWorkArea.Right - LPopupWidth);
  var LTop := EnsureRange(APoint.Y + ScaleValue(22), LWorkArea.Top,
    LWorkArea.Bottom - LPopupHeight);
  SetBounds(LLeft, LTop, LPopupWidth, LPopupHeight);
  Show;
  BringToFront;
  MenuItemsControl.SetFocus;
end;

procedure TExplorerPopupMenuForm.MenuItemsClick(Sender: TObject);
begin
  Hide;
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, MenuItemsControl.ControlList1.ItemIndex);
end;

procedure TExplorerPopupMenuForm.FormDeactivate(Sender: TObject);
begin
  Hide;
end;

procedure TExplorerPopupMenuForm.WMNCHitTest(var AMessage: TWMNCHitTest);
begin
  inherited;
  // The shadow-capable thick frame is visual only; popup menus are not
  // resizable or draggable.
  AMessage.Result := HTCLIENT;
end;

end.
