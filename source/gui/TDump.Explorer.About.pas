//**************************************************************************************************
//
// Unit TDump.Explorer.About
//
// Themed About dialog and runtime application information
//
// https://github.com/RRUZ/TDump-Explorer
//
// Copyright (c) 2026 Rodrigo Ruz V.
// SPDX-License-Identifier: MIT
//
//**************************************************************************************************
unit TDump.Explorer.About;

interface

uses
  Winapi.Messages, System.Classes, Vcl.Controls, Vcl.Forms, Vcl.Graphics,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.TitleBarCtrls, Vcl.ImgList,
  TDump.Explorer.UI, Vcl.Imaging.pngimage, Vcl.VirtualImage;

type
  TFrmAbout = class(TForm)
    TitleBarPanel1: TTitleBarPanel;
    pnContent: TPanel;
    pbCard: TPaintBox;
    lblProduct: TLabel;
    lblDescription: TLabel;
    lblVersionTitle: TLabel;
    lblVersion: TLabel;
    lblBuildTitle: TLabel;
    lblBuild: TLabel;
    lblArchitectureTitle: TLabel;
    lblArchitecture: TLabel;
    lblAuthorTitle: TLabel;
    lblAuthor: TLabel;
    lblRepositoryTitle: TLabel;
    lblLicenseTitle: TLabel;
    lblPhosphorTitle: TLabel;
    lblVirtualTreeTitle: TLabel;
    pnFooter: TPanel;
    lblFeedback: TLabel;
    imgApplication: TVirtualImage;
    procedure CardPaint(Sender: TObject);
  private
    FCopyButton: TSimpleUIButton;
    FCloseButton: TSimpleUIButton;
    FButtonImages: TImageList;
    FRepositoryLink: TSimpleUIButton;
    FPhosphorLink: TSimpleUIButton;
    FVirtualTreeLink: TSimpleUIButton;
    FLicenseBadge: TExplorerBadgeLabel;
    procedure ApplyTheme;
    procedure CreateButtons;
    procedure CreateLicenseBadge;
    procedure FooterResize(Sender: TObject);
    procedure LayoutFooterButtons;
    procedure ConfigureClientDragging;
    procedure ClientAreaMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure LoadApplicationInfo;
    procedure UpdateButtonImages;
    procedure CopyInfoClick(Sender: TObject);
    procedure OpenRepositoryURL(const AURL: string);
    procedure VisitRepositoryClick(Sender: TObject);
    procedure VisitPhosphorClick(Sender: TObject);
    procedure VisitVirtualTreeClick(Sender: TObject);
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
  protected
    procedure DoShow; override;
    procedure DoAfterMonitorDpiChanged(OldDPI, NewDPI: Integer); override;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ScaleForPPI(NewPPI: Integer); override;
  end;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI, System.SysUtils, System.Types,
  System.UITypes, Vcl.Clipbrd, Vcl.GraphUtil, Vcl.Themes,
  TDump.Explorer.Phosphor.Font, TDump.Explorer.Utils, TDump.Explorer.Resources;

{$R *.dfm}

type
  TAboutControlAccess = class(TControl);

const
  cRepositoryURL = 'https://github.com/RRUZ/TDump-Explorer';
  cRepositoryCaption = 'github.com/RRUZ/TDump-Explorer';
  cPhosphorURL = 'https://github.com/phosphor-icons';
  cPhosphorCaption = 'github.com/phosphor-icons';
  cVirtualTreeURL = 'https://github.com/JAM-Software/Virtual-TreeView';
  cVirtualTreeCaption = 'github.com/JAM-Software/Virtual-TreeView';
  cLicenseCaption = 'MIT License';
  // Layout constants are 96-DPI design units, converted once for runtime controls.
  cTitleBarHeight = 2;
  cContentHeight = 374;
  cButtonHeight = 25; // Match the Settings dialog's action buttons.
  cFooterButtonTop = 12;
  cFooterButtonGap = 6;
  cFooterHorizontalMargin = 22;
  cCopyButtonWidth = 104;
  cCloseButtonWidth = 80;
  cDetailControlLeft = 184;
  cPhUser = $E4C2;
  cPhGitHub = $E576;
  cPhScales = $E750;
  cPhCopy = $E1CA;

constructor TFrmAbout.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  // Keep the card's opaque fill behind the labels regardless of DFM order.
  pbCard.SendToBack;
  Font.Name := TExplorerTheme.FontName;
  CreateLicenseBadge;
  CreateButtons;
  ConfigureClientDragging;
  LoadApplicationInfo;
  ApplyTheme;
  ActiveControl := FCloseButton;
end;

procedure TFrmAbout.CreateButtons;
  function CreateButton(const AName, ACaption: string; AWidth,
    ATabOrder: Integer): TSimpleUIButton;
  begin
    Result := TSimpleUIButton.Create(Self);
    Result.Name := AName;
    Result.Parent := pnFooter;
    Result.SetBounds(0, ScaleValue(cFooterButtonTop), ScaleValue(AWidth),
      ScaleValue(cButtonHeight));
    Result.Anchors := [akTop, akRight];
    Result.ParentFont := True;
    Result.Caption := ACaption;
    Result.TabOrder := ATabOrder;
  end;

  function CreateLink(const AName, ACaption: string; ATabOrder: Integer;
    AOnClick: TNotifyEvent): TSimpleUIButton;
  begin
    Result := TSimpleUIButton.Create(Self);
    Result.Name := AName;
    Result.Parent := pnContent;
    Result.Caption := ACaption;
    Result.ParentFont := True;
    Result.Cursor := crHandPoint;
    Result.TabOrder := ATabOrder;
    Result.OnClick := AOnClick;
  end;
begin
  FButtonImages := TImageList.Create(Self);
  FCopyButton := CreateButton('btnCopyInfo', '&Copy info', cCopyButtonWidth, 0);
  FCopyButton.Images := FButtonImages;
  FCopyButton.ImageIndex := 0;
  FCopyButton.OnClick := CopyInfoClick;
  FCloseButton := CreateButton('btnClose', 'C&lose', cCloseButtonWidth, 1);
  FCloseButton.Default := True;
  FCloseButton.Cancel := True;
  FCloseButton.ModalResult := mrClose;
  pnFooter.OnResize := FooterResize;
  LayoutFooterButtons;
  FRepositoryLink := CreateLink('btnRepositoryLink', cRepositoryCaption, 0,
    VisitRepositoryClick);
  FPhosphorLink := CreateLink('btnPhosphorLink', cPhosphorCaption, 1,
    VisitPhosphorClick);
  FVirtualTreeLink := CreateLink('btnVirtualTreeLink', cVirtualTreeCaption, 2,
    VisitVirtualTreeClick);
end;

procedure TFrmAbout.FooterResize(Sender: TObject);
begin
  LayoutFooterButtons;
end;

procedure TFrmAbout.LayoutFooterButtons;
var
  LRight: Integer;
begin
  if not Assigned(FCopyButton) or not Assigned(FCloseButton) then
    Exit;

  LRight := pnFooter.ClientWidth - ScaleValue(cFooterHorizontalMargin);
  FCloseButton.SetBounds(LRight - ScaleValue(cCloseButtonWidth),
    ScaleValue(cFooterButtonTop), ScaleValue(cCloseButtonWidth),
    ScaleValue(cButtonHeight));
  LRight := FCloseButton.Left - ScaleValue(cFooterButtonGap);
  FCopyButton.SetBounds(LRight - ScaleValue(cCopyButtonWidth),
    ScaleValue(cFooterButtonTop), ScaleValue(cCopyButtonWidth),
    ScaleValue(cButtonHeight));
end;

procedure TFrmAbout.CreateLicenseBadge;
begin
  FLicenseBadge := TExplorerBadgeLabel.Create(Self);
  FLicenseBadge.Parent := pnContent;
  FLicenseBadge.Name := 'lblLicense';
  FLicenseBadge.Caption := cLicenseCaption;
  FLicenseBadge.ParentFont := True;
  FLicenseBadge.SetBounds(ScaleValue(cDetailControlLeft), ScaleValue(243),
    FLicenseBadge.NaturalWidth, ScaleValue(22));
end;

procedure TFrmAbout.ConfigureClientDragging;
begin
  OnMouseDown := ClientAreaMouseDown;
  // Route passive client surfaces to native window movement. Do not attach
  // this handler to buttons or repository links: they must stay clickable.
  for var LIndex := 0 to ComponentCount - 1 do
    if (Components[LIndex] is TPanel) or
      (Components[LIndex] is TPaintBox) or
      (Components[LIndex] is TImage) or
      (Components[LIndex] is TCustomLabel) then
      TAboutControlAccess(Components[LIndex]).OnMouseDown := ClientAreaMouseDown;
end;

procedure TFrmAbout.ClientAreaMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  ReleaseCapture;
  SendMessage(Handle, WM_NCLBUTTONDOWN, HTCAPTION, 0);
end;

procedure TFrmAbout.LoadApplicationInfo;
begin
  // The separate .rc resource is authoritative, not the IDE version fields.
  lblVersion.Caption := GetExecutableVersion(Application.ExeName);
  if lblVersion.Caption = '' then
    lblVersion.Caption := 'Not available';
  lblVersion.Hint := lblVersion.Caption;
  {$IFDEF DEBUG}
  lblBuild.Caption := 'Debug';
  {$ELSEIF Defined(RELEASE)}
  lblBuild.Caption := 'Release';
  {$ELSE}
  lblBuild.Caption := 'Custom';
  {$ENDIF}
  lblArchitecture.Caption := Format('%d-bit', [SizeOf(Pointer) * 8]);
end;

procedure TFrmAbout.UpdateButtonImages;
  procedure SizeLink(ALink: TSimpleUIButton; ACanvas: TCanvas; ATop: Integer);
  begin
    ACanvas.Font.Assign(ALink.Font);
    ALink.SetBounds(ScaleValue(cDetailControlLeft), ScaleValue(ATop),
      ACanvas.TextWidth(ALink.Caption) + ScaleValue(16), ScaleValue(28));
  end;
begin
  if not Assigned(FButtonImages) then
    Exit;
  var LTheme := TExplorerTheme.ActiveTheme;
  FButtonImages.Clear;
  FButtonImages.SetSize(ScaleValue(16), ScaleValue(16));
  var LBitmap := Vcl.Graphics.TBitmap.Create;
  try
    LBitmap.SetSize(FButtonImages.Width, FButtonImages.Height);
    var LRect := Rect(0, 0, LBitmap.Width, LBitmap.Height);
    LBitmap.Canvas.Brush.Color := LTheme.BackgroundColor;
    LBitmap.Canvas.FillRect(LRect);
    PhosphorFont.DrawIcon(LBitmap.Canvas.Handle, cPhCopy, LRect,
      LTheme.TextColor);
    FButtonImages.AddMasked(LBitmap, LTheme.BackgroundColor);
    SizeLink(FRepositoryLink, LBitmap.Canvas, 208);
    SizeLink(FPhosphorLink, LBitmap.Canvas, 291);
    SizeLink(FVirtualTreeLink, LBitmap.Canvas, 327);
  finally
    LBitmap.Free;
  end;
end;

procedure TFrmAbout.ApplyTheme;
begin
  if not Assigned(pnContent) then
    Exit;
  var LTheme := TExplorerTheme.ActiveTheme;
  Color := LTheme.BackgroundColor;
  pnContent.Color := Color;
  pnFooter.Color := Color;
  //pnTitle.Color := Color;
  for var LIndex := 0 to ComponentCount - 1 do
    if Components[LIndex] is TLabel then
    begin
      var LLabel := TLabel(Components[LIndex]);
      LLabel.StyleName := 'Windows';
      LLabel.Font.Name := TExplorerTheme.FontName;
      LLabel.Font.Color := LTheme.TextColor;
      if LLabel.Tag = 1 then
        LLabel.Font.Color := LTheme.InactiveText;
    end
    else if Components[LIndex] is TExplorerBadgeLabel then
      TExplorerBadgeLabel(Components[LIndex]).ApplyTheme(LTheme);
  var LLinkPalette := ExplorerButtonPalette(LTheme);
  LLinkPalette.Background := Color;
  LLinkPalette.Border := Color;
  LLinkPalette.Text := LTheme.SelectionColor;
  LLinkPalette.HotText := LTheme.SelectionColor;
  LLinkPalette.PressedText := LTheme.SelectionColor;
  if Assigned(FRepositoryLink) then
    FRepositoryLink.ApplyPalette(LLinkPalette);
  if Assigned(FPhosphorLink) then
    FPhosphorLink.ApplyPalette(LLinkPalette);
  if Assigned(FVirtualTreeLink) then
    FVirtualTreeLink.ApplyPalette(LLinkPalette);
  ApplyExplorerThemeToButton(FCopyButton, LTheme);
  if Assigned(FCloseButton) then
  begin
    var LPalette := ExplorerButtonPalette(LTheme);
    LPalette.Background := LTheme.SelectionColor;
    LPalette.Border := LTheme.SelectionColor;
    LPalette.HotBackground := ColorBlendRGB(LTheme.SelectionColor,
      LTheme.BackgroundColor, 0.15);
    LPalette.PressedBackground := ColorBlendRGB(LTheme.SelectionColor,
      LTheme.BackgroundColor, 0.28);
    // Use the active style's highlighted-text color for accent contrast.
    LPalette.Text := StyleServices.GetSystemColor(clHighlightText);
    LPalette.HotText := LPalette.Text;
    LPalette.PressedText := LPalette.Text;
    LPalette.FocusedBorder := LTheme.TextColor;
    FCloseButton.ApplyPalette(LPalette);
  end;
  CustomTitleBar.SystemHeight := False;
  CustomTitleBar.Height := ScaleValue(cTitleBarHeight);
  CustomTitleBar.SystemColors := False;
  CustomTitleBar.StyleColors := False;
  CustomTitleBar.SystemButtons := False;
  CustomTitleBar.ShowIcon := False;
  CustomTitleBar.ShowCaption := False;
  CustomTitleBar.BackgroundColor := Color;
  CustomTitleBar.ForegroundColor := LTheme.TextColor;
  CustomTitleBar.InactiveBackgroundColor := Color;
  CustomTitleBar.InactiveForegroundColor := LTheme.InactiveText;
  CustomTitleBar.ButtonBackgroundColor := Color;
  CustomTitleBar.ButtonForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonHoverBackgroundColor := ColorBlendRGB(
    LTheme.SelectionColor, Color, 0.82);
  CustomTitleBar.ButtonHoverForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonPressedBackgroundColor := LTheme.SelectionColor;
  CustomTitleBar.ButtonPressedForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonInactiveBackgroundColor := Color;
  CustomTitleBar.ButtonInactiveForegroundColor := LTheme.InactiveText;

  if IsLightThemeActive then
    imgApplication.ImageName := 'TDumpExplorer_light'
  else
    imgApplication.ImageName := 'TDumpExplorer_dark';

  UpdateButtonImages;
  Invalidate;
  TitleBarPanel1.Invalidate;
  pbCard.Invalidate;
end;

procedure TFrmAbout.CardPaint(Sender: TObject);
const
  cHorizontalDividers: array[0..1] of Integer = (166, 276);
  cVerticalDividers: array[0..1] of Integer = (156, 290);

  function ScaledRect(ALeft, ATop, ARight, ABottom: Integer): TRect;
  begin
    Result := Rect(ScaleValue(ALeft), ScaleValue(ATop), ScaleValue(ARight),
      ScaleValue(ABottom));
  end;
begin
  var LTheme := TExplorerTheme.ActiveTheme;
  var LCanvas := pbCard.Canvas;
  var LBorder := ColorBlendRGB(LTheme.TextColor, LTheme.BackgroundColor, 0.87);
  DrawAntialiasedRoundedRectangle(LCanvas,
    Rect(ScaleValue(12), ScaleValue(8), pbCard.Width - ScaleValue(12),
      pbCard.Height - ScaleValue(8)), LTheme.BackgroundColor, LBorder,
    ScaleValue(10), 1);
  LCanvas.Pen.Color := LBorder;
  for var LTop in cHorizontalDividers do
  begin
    LCanvas.MoveTo(ScaleValue(26), ScaleValue(LTop));
    LCanvas.LineTo(pbCard.Width - ScaleValue(26), ScaleValue(LTop));
  end;
  for var LLeft in cVerticalDividers do
  begin
    LCanvas.MoveTo(ScaleValue(LLeft), ScaleValue(112));
    LCanvas.LineTo(ScaleValue(LLeft), ScaleValue(150));
  end;
  PhosphorFont.DrawIcon(LCanvas.Handle, cPhUser, ScaledRect(32, 180, 52, 200),
    LTheme.InactiveText);
  PhosphorFont.DrawIcon(LCanvas.Handle, cPhGitHub, ScaledRect(32, 212, 52, 232),
    LTheme.InactiveText);
  PhosphorFont.DrawIcon(LCanvas.Handle, cPhScales, ScaledRect(32, 244, 52, 264),
    LTheme.InactiveText);
  PhosphorFont.DrawIcon(LCanvas.Handle, cPhGitHub, ScaledRect(32, 294, 52, 314),
    LTheme.InactiveText);
  PhosphorFont.DrawIcon(LCanvas.Handle, cPhGitHub, ScaledRect(32, 330, 52, 350),
    LTheme.InactiveText);
end;

procedure TFrmAbout.CopyInfoClick(Sender: TObject);
begin
  try
    Clipboard.AsText := 'TDump Explorer' + sLineBreak +
      'Version: ' + lblVersion.Caption + sLineBreak +
      'Build: ' + lblBuild.Caption + sLineBreak +
      'Architecture: ' + lblArchitecture.Caption + sLineBreak +
      'Author: ' + lblAuthor.Caption + sLineBreak +
      'License: ' + FLicenseBadge.Caption + sLineBreak +
      'Repository: ' + cRepositoryURL + sLineBreak +
      'Third-party libraries:' + sLineBreak +
      'Phosphor Icons: ' + cPhosphorURL + sLineBreak +
      'Virtual Treeview: ' + cVirtualTreeURL + sLineBreak +
      'Binary analysis requires TDUMP; saved reports open directly.';
    lblFeedback.Caption := 'Application info copied.';
  except
    on E: Exception do
      lblFeedback.Caption := 'Clipboard unavailable. Please try again.';
  end;
end;

procedure TFrmAbout.OpenRepositoryURL(const AURL: string);
begin
  if NativeInt(ShellExecute(Handle, 'open', PChar(AURL), nil, nil,
    SW_SHOWNORMAL)) <= 32 then
    lblFeedback.Caption := 'Could not open GitHub in your browser.'
  else
    lblFeedback.Caption := '';
end;

procedure TFrmAbout.VisitRepositoryClick(Sender: TObject);
begin
  OpenRepositoryURL(cRepositoryURL);
end;

procedure TFrmAbout.VisitPhosphorClick(Sender: TObject);
begin
  OpenRepositoryURL(cPhosphorURL);
end;

procedure TFrmAbout.VisitVirtualTreeClick(Sender: TObject);
begin
  OpenRepositoryURL(cVirtualTreeURL);
end;

procedure TFrmAbout.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  ApplyTheme;
end;

procedure TFrmAbout.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;
  if Assigned(FCloseButton) then
  begin
    LayoutFooterButtons;
    ApplyTheme;
  end;
end;

procedure TFrmAbout.ScaleForPPI(NewPPI: Integer);
begin
  inherited;
  // VCL's DPI path bypasses ChangeScale on the form. Measure links only
  // after the inherited font and child-control scaling has completed.
  if Assigned(FCloseButton) then
  begin
    LayoutFooterButtons;
    ApplyTheme;
  end;
end;

procedure TFrmAbout.DoAfterMonitorDpiChanged(OldDPI, NewDPI: Integer);
begin
  inherited;
  if Assigned(FCloseButton) then
  begin
    LayoutFooterButtons;
    ApplyTheme;
  end;
end;

procedure TFrmAbout.DoShow;
var
  LWindowRect: TRect;
begin
  inherited;
  // Use actual window bounds: VCL custom-caption client metrics differ from
  // the native ones when this dialog first becomes visible.
  var LHeightDelta := ScaleValue(cContentHeight) - pnContent.Height;
  if (LHeightDelta <> 0) and GetWindowRect(Handle, LWindowRect) then
    SetWindowPos(Handle, 0, 0, 0, LWindowRect.Width,
      LWindowRect.Height + LHeightDelta,
      SWP_NOMOVE or SWP_NOZORDER or SWP_NOACTIVATE);
end;

end.
