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
  Vcl.Themes, TDump.Explorer.HighlighterControl;

type
  TExplorerPopupMenuItemClick = procedure(Sender: TObject;
    AItemIndex: Integer) of object;

  TExplorerPopupMenuForm = class(TForm)
  private
    FMenuItems: THighlighterControl;
    FOnItemClick: TExplorerPopupMenuItemClick;
    procedure MenuItemsClick(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure WMNCHitTest(var AMessage: TWMNCHitTest); message WM_NCHITTEST;
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure ApplyTheme;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    //procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ShowAt(const APoint: TPoint);
    property MenuItems: THighlighterControl read FMenuItems;
    property OnItemClick: TExplorerPopupMenuItemClick read FOnItemClick
      write FOnItemClick;
  end;

implementation

uses
  System.Math, Winapi.Windows, TDump.Explorer.UI, Vcl.Graphics, Vcl.TitleBarCtrls;

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
  inherited CreateNew(AOwner);
  BorderStyle := bsNone;
  BorderIcons := [];
  Caption := '';
  StyleElements := StyleElements - [seClient, seBorder];
  RoundedCorners := rcOn;
  Position := poDesigned;
  PopupMode := pmExplicit;
  DoubleBuffered := True;
  OnDeactivate := FormDeactivate;

  FMenuItems := THighlighterControl.Create(Self);
  FMenuItems.Parent := Self;

  FMenuItems.Margins.Top := 0;
  FMenuItems.Margins.Bottom := 0;
  FMenuItems.Margins.Left := 8;
  FMenuItems.Margins.Right := 8;

  FMenuItems.AlignWithMargins := True;
  FMenuItems.Align := alClient;

  FMenuItems.UseColumnMode := False;
  FMenuItems.AutoSizeColumns := False;
  FMenuItems.ControlList1.ItemHeight := ScaleValue(40);
  FMenuItems.OnItemClick := MenuItemsClick;

  CustomTitleBar.ShowCaption := False;
  CustomTitleBar.SystemHeight := False;
  CustomTitleBar.Height := 4;
  CustomTitleBar.SystemColors := False;

  var LTitleBarPanel := TTitleBarPanel.Create(Self);
  LTitleBarPanel.Parent := Self;
  CustomTitleBar.Enabled := True;
  CustomTitleBar.Control := LTitleBarPanel;

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
  FMenuItems.SetFocus;
end;

procedure TExplorerPopupMenuForm.MenuItemsClick(Sender: TObject);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(Self, FMenuItems.ControlList1.ItemIndex);
  Hide;
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
