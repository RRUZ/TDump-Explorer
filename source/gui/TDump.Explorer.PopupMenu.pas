//**************************************************************************************************
//
// Unit TDump.Explorer.PopupMenu
//
// Modern highlighter-based popup menu
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
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
  TExplorerPopupMenuShortcut = procedure(Sender: TObject;
    AShortcut: Char) of object;

  TExplorerPopupMenuForm = class(TForm)
  published
    MenuItemsControl: THighlighterControl;
    TitleBarPanel1: TTitleBarPanel;
    procedure FormDeactivate(Sender: TObject);
  private
    FOnItemClick: TExplorerPopupMenuItemClick;
    FOnShortcut: TExplorerPopupMenuShortcut;
    procedure MenuItemsClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure WMNCHitTest(var AMessage: TWMNCHitTest); message WM_NCHITTEST;
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure ApplyTheme;
    procedure AdjustSizeToContent;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    //procedure CreateWnd; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ShowAt(const APoint: TPoint);
    property MenuItems: THighlighterControl read MenuItemsControl;
    property OnItemClick: TExplorerPopupMenuItemClick read FOnItemClick
      write FOnItemClick;
    property OnShortcut: TExplorerPopupMenuShortcut read FOnShortcut
      write FOnShortcut;
  end;

implementation

uses
  System.Math, Winapi.Windows, TDump.Explorer.UI, Vcl.Graphics;

{$R *.dfm}

procedure TExplorerPopupMenuForm.ApplyTheme;
begin
  var LTheme := TExplorerTheme.ActiveTheme;
  Color := LTheme.BackgroundColor;
  MenuItemsControl.Color := LTheme.BackgroundColor;
  MenuItemsControl.ControlList1.Color := LTheme.BackgroundColor;
  CustomTitleBar.BackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.InactiveBackgroundColor := LTheme.BackgroundColor;
end;

procedure TExplorerPopupMenuForm.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  ApplyTheme;
end;

constructor TExplorerPopupMenuForm.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  GlassFrame.Enabled := False;

  // These settings are not published by THighlighterControl, so they cannot
  // be streamed from the DFM.  The visual frame itself and its static layout
  // are design-time components.
  MenuItemsControl.UseColumnMode := False;
  MenuItemsControl.AutoSizeColumns := False;
  MenuItemsControl.ControlList1.ItemHeight := ScaleValue(40);
  MenuItemsControl.OnItemClick := MenuItemsClick;
  KeyPreview := True;
  OnKeyDown := FormKeyDown;

  ApplyTheme;
end;

procedure TExplorerPopupMenuForm.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := Params.Style and not WS_SIZEBOX;
end;

procedure TExplorerPopupMenuForm.AdjustSizeToContent;
begin
  var LMeasureBitmap := TBitmap.Create;
  try
    LMeasureBitmap.Canvas.Font.Assign(MenuItemsControl.Font);
    var LContentWidth := 0;
    for var LIndex := 0 to MenuItemsControl.Count - 1 do
    begin
      var LItemWidth := LMeasureBitmap.Canvas.TextWidth(
        MenuItemsControl.Items[LIndex]) + ScaleValue(16);
      if Assigned(MenuItemsControl.Images) and
        (MenuItemsControl.ItemImageName(LIndex) <> '') and
        (MenuItemsControl.Images.GetIndexByName(
          MenuItemsControl.ItemImageName(LIndex)) >= 0) then
        Inc(LItemWidth, MenuItemsControl.Images.Width + ScaleValue(8));
      LContentWidth := Max(LContentWidth, LItemWidth);
    end;

    ClientWidth := Max(ScaleValue(96), LContentWidth +
      MenuItemsControl.Margins.Left + MenuItemsControl.Margins.Right);

    var LItemCount := Max(1, MenuItemsControl.Count);
    var LItemHeight := MenuItemsControl.ControlList1.ItemHeight +
      MenuItemsControl.ControlList1.ItemMargins.Top +
      MenuItemsControl.ControlList1.ItemMargins.Bottom;
    ClientHeight := TitleBarPanel1.Height + MenuItemsControl.Margins.Top +
      MenuItemsControl.Margins.Bottom + (LItemCount * LItemHeight) +
      ScaleValue(8);
  finally
    LMeasureBitmap.Free;
  end;
end;

procedure TExplorerPopupMenuForm.ShowAt(const APoint: TPoint);
begin
  AdjustSizeToContent;
  var LPopupWidth := Width;
  var LPopupHeight := Height;
  var LWorkArea := Screen.WorkAreaRect;
  LPopupWidth := Min(LPopupWidth, LWorkArea.Width);
  LPopupHeight := Min(LPopupHeight, LWorkArea.Height);
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

procedure TExplorerPopupMenuForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  LShortcut: Char;
begin
  if not (ssAlt in Shift) then
    Exit;

  if Key in [Ord('1')..Ord('9')] then
    LShortcut := Char(Key)
  else if Key in [VK_NUMPAD1..VK_NUMPAD9] then
    LShortcut := Chr(Ord('1') + Key - VK_NUMPAD1)
  else if Key in [Ord('A')..Ord('Z')] then
    LShortcut := Char(Key)
  else
    Exit;

  if Assigned(FOnShortcut) then
    FOnShortcut(Self, LShortcut);
  Key := 0;
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
