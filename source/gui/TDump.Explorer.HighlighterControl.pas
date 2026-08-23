unit TDump.Explorer.HighlighterControl;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,
  System.Types,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.ControlList,
  TDump.Explorer.Highlighter, Vcl.ExtCtrls, Vcl.WinXCtrls;

type
  THighlighterControl = class(TFrame)
    ControlList1: TControlList;
    Panel1: TPanel;
    SearchFilterBox: TSearchBox;
  private
    const
      CTextPadding = 8;
    var
      FHighlighter: TTinyHighlighter;
      FItems: TStringList;
      FThemeKind: TTinyHighlightThemeKind;
    procedure ControlList1BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ItemsChanged(Sender: TObject);
    procedure SetThemeKind(const AValue: TTinyHighlightThemeKind);
    procedure UpdateControlList;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Add(const AText: string);
    procedure Clear;
    procedure SetText(const AText: string);
    property Items: TStringList read FItems;
    property ThemeKind: TTinyHighlightThemeKind read FThemeKind
      write SetThemeKind;
  end;

implementation

uses
  Vcl.Themes, Vcl.GraphUtil, TDump.Explorer.UI;


{$R *.dfm}

constructor THighlighterControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FHighlighter := TTinyHighlighter.Create;
  FItems := TStringList.Create;
  FItems.OnChange := ItemsChanged;
  FThemeKind := thtDark;
  ControlList1.OnBeforeDrawItem := ControlList1BeforeDrawItem;
  UpdateControlList;
end;

destructor THighlighterControl.Destroy;
begin
  FItems.Free;
  FHighlighter.Free;
  inherited;
end;

procedure THighlighterControl.Add(const AText: string);
begin
  FItems.Add(StringReplace(StringReplace(AText, #13, ' ', [rfReplaceAll]),
    #10, ' ', [rfReplaceAll]));
  ControlList1.ItemIndex := FItems.Count - 1;
end;

procedure THighlighterControl.Clear;
begin
  FItems.Clear;
end;

procedure THighlighterControl.SetText(const AText: string);
begin
  FItems.Text := AText;
  if FItems.Count > 0 then
    ControlList1.ItemIndex := 0;
end;

procedure THighlighterControl.ControlList1BeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
var
  LFillColor: TColor;
begin
  if (AIndex < 0) or (AIndex >= FItems.Count) then
    Exit;

  var LStyle := StyleServices;

  if (odSelected in AState) then
  begin
    LFillColor := ColorBlendRGB(LStyle.GetSystemColor(clHighlight), LStyle.GetSystemColor(clWindow), 0.9);
    if IsWindows11 then
      DrawSelectionBar(ACanvas, ARect, LFillColor, LStyle.GetSystemColor(clHighlight))
    else
    begin
      ACanvas.Brush.Color := LFillColor;
      ACanvas.FillRect(ARect);

      LFillColor := LStyle.GetSystemColor(clHighlight);
      ACanvas.Brush.Color := LFillColor;
      ACanvas.FrameRect(ARect);
    end;
  end
  else if (odHotLight in AState) then
  begin
    LFillColor := ColorBlendRGB(LStyle.GetSystemColor(clHighlight), LStyle.GetSystemColor(clWindow), 0.95);
    ACanvas.Brush.Color := LFillColor;
    ACanvas.FillRect(ARect);
  end;


  var LTextRect := ARect;
  InflateRect(LTextRect, -CTextPadding, 0);
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 9;
  FHighlighter.TextRect(ACanvas, LTextRect, FItems[AIndex], FThemeKind,
    [tfLeft, tfVerticalCenter, tfSingleLine, tfEndEllipsis, tfNoPrefix]);
end;

procedure THighlighterControl.ItemsChanged(Sender: TObject);
begin
  UpdateControlList;
end;

procedure THighlighterControl.SetThemeKind(
  const AValue: TTinyHighlightThemeKind);
begin
  if FThemeKind = AValue then
    Exit;
  FThemeKind := AValue;
  ControlList1.Invalidate;
end;

procedure THighlighterControl.UpdateControlList;
begin
  ControlList1.ItemCount := FItems.Count;
  ControlList1.Invalidate;
end;

end.
