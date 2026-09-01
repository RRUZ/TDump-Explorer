unit TDump.Explorer.LogControl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ControlList, Vcl.WinXCtrls, Vcl.Clipbrd;

type
  TLogEntryType = (letInformation, letSuccess, letWarning, letError, letProfile);

  TLogEntry = record
    Timestamp: TDateTime;
    Message: string;
    EntryType: TLogEntryType;
  end;

  TLogEntryList = TList<TLogEntry>;

  TLogControl = class(TFrame)
    ControlList1: TControlList;
    pnToolbar: TPanel;
    SearchFilterBox: TSearchBox;
    Label1: TLabel;
  private
    var
      FEntries: TLogEntryList;
    procedure ControlList1BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ControlList1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure CopySelectedItemsToClipboard;
    function EntryTypeColor(AEntryType: TLogEntryType): TColor;
    function EntryText(const AEntry: TLogEntry): string;
    function EntryTypeText(AEntryType: TLogEntryType): string;
    procedure UpdateControlList;
    procedure CMStyleChanged(var AMessage: TMessage); message CM_STYLECHANGED;
    procedure ApplyTheme;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Add(const AMessage: string;
      AEntryType: TLogEntryType = letInformation); overload;
    procedure Add(const AEntry: TLogEntry); overload;
    procedure Clear;
    property Entries: TLogEntryList read FEntries;
  end;

implementation

uses
  Vcl.Themes, Vcl.GraphUtil, TDump.Explorer.UI;

{$R *.dfm}

const
  cMaximumRetainedLogEntries = 10000;

constructor TLogControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEntries := TLogEntryList.Create;
  ControlList1.MultiSelect := True;
  ControlList1.OnBeforeDrawItem := ControlList1BeforeDrawItem;
  ControlList1.OnKeyDown := ControlList1KeyDown;
  pnToolbar.Alignment := taLeftJustify;
  UpdateControlList;
  ApplyTheme;
end;

destructor TLogControl.Destroy;
begin
  FEntries.Free;
  inherited;
end;

procedure TLogControl.Add(const AMessage: string; AEntryType: TLogEntryType);
var
  LEntry: TLogEntry;
begin
  LEntry.Timestamp := Now;
  LEntry.Message := AMessage;
  LEntry.EntryType := AEntryType;
  Add(LEntry);
end;

procedure TLogControl.Add(const AEntry: TLogEntry);
var
  LEntry: TLogEntry;
begin
  LEntry := AEntry;
  LEntry.Message := StringReplace(LEntry.Message, #13, ' ', [rfReplaceAll]);
  LEntry.Message := StringReplace(LEntry.Message, #10, ' ', [rfReplaceAll]);
  FEntries.Add(LEntry);
  while FEntries.Count > cMaximumRetainedLogEntries do
    FEntries.Delete(0);

  UpdateControlList;
  ControlList1.ItemIndex := FEntries.Count - 1;
end;

procedure TLogControl.ApplyTheme;
begin
  pnToolbar.StyleElements := pnToolbar.StyleElements - [seClient];
  pnToolbar.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
end;

procedure TLogControl.Clear;
begin
  FEntries.Clear;
  UpdateControlList;
end;

procedure TLogControl.CMStyleChanged(var AMessage: TMessage);
begin
  inherited;
  ApplyTheme;
end;

procedure TLogControl.ControlList1BeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
const
  cTextPadding = 8;
  cTimestampColumnWidth = 92;
  cStatusColumnWidth = 78;
var
  LEntry: TLogEntry;
  LTimestampText: string;
  LStatusText: string;
  LTimestampRect: TRect;
  LStatusRect: TRect;
  LMessageRect: TRect;
  LFillColor: TColor;
  LSelected: Boolean;
  LBrushStyle: TBrushStyle;
begin
  if (AIndex < 0) or (AIndex >= FEntries.Count) then
    Exit;

  LSelected := odSelected in AState;
  if LSelected then
  begin
    LFillColor := ColorBlendRGB(TExplorerTheme.ActiveTheme.SelectionColor, TExplorerTheme.ActiveTheme.BackgroundColor, 0.9);
    if IsWindows11 then
      DrawSelectionBar(ACanvas, ARect, LFillColor, TExplorerTheme.ActiveTheme.SelectionColor)
    else
    begin
      ACanvas.Brush.Color := LFillColor;
      ACanvas.FillRect(ARect);

      LFillColor := TExplorerTheme.ActiveTheme.SelectionColor;
      ACanvas.Brush.Color := LFillColor;
      ACanvas.FrameRect(ARect);
    end;
  end
  else if (odHotLight in AState) then
  begin
    LFillColor := ColorBlendRGB(TExplorerTheme.ActiveTheme.SelectionColor, TExplorerTheme.ActiveTheme.BackgroundColor, 0.95);
    ACanvas.Brush.Color := LFillColor;
    ACanvas.FillRect(ARect);
  end;

  LEntry := FEntries[AIndex];
  LTimestampText := FormatDateTime('hh:nn:ss.zzz', LEntry.Timestamp);
  LStatusText := EntryTypeText(LEntry.EntryType);
  LTimestampRect := ARect;
  LTimestampRect.Left := LTimestampRect.Left + cTextPadding;
  LTimestampRect.Right := LTimestampRect.Left + cTimestampColumnWidth;
  LStatusRect := ARect;
  LStatusRect.Left := LTimestampRect.Right;
  LStatusRect.Right := LStatusRect.Left + cStatusColumnWidth;
  LMessageRect := ARect;
  LMessageRect.Left := LStatusRect.Right;
  LMessageRect.Right := LMessageRect.Right - cTextPadding;
  if LMessageRect.Right < LMessageRect.Left then
    LMessageRect.Right := LMessageRect.Left;

  ACanvas.Font.Name := TExplorerTheme.FontName;
  ACanvas.Font.Size := TExplorerTheme.FontSize;
  if LSelected then
    ACanvas.Font.Color := TExplorerTheme.ActiveTheme.SelectionColor
  else
    ACanvas.Font.Color := EntryTypeColor(LEntry.EntryType);

  LBrushStyle := ACanvas.Brush.Style;
  ACanvas.Brush.Style := bsClear;
  try
    ACanvas.TextRect(LTimestampRect, LTimestampText,
      [tfVerticalCenter, tfSingleLine, tfEndEllipsis, tfNoPrefix]);
    ACanvas.TextRect(LStatusRect, LStatusText,
      [tfVerticalCenter, tfSingleLine, tfEndEllipsis, tfNoPrefix]);
    ACanvas.TextRect(LMessageRect, LEntry.Message,
      [tfVerticalCenter, tfSingleLine, tfEndEllipsis, tfNoPrefix]);
  finally
    ACanvas.Brush.Style := LBrushStyle;
  end;
end;

procedure TLogControl.ControlList1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if ssCtrl in Shift then
    case Key of
      Ord('A'):
        begin
          ControlList1.SelectAll;
          Key := 0;
        end;
      Ord('C'):
        begin
          CopySelectedItemsToClipboard;
          Key := 0;
        end;
    end;
end;

procedure TLogControl.CopySelectedItemsToClipboard;
begin
  var LText := TStringBuilder.Create;
  try
    for var LIndex in ControlList1.GetSelectedEnumerator do
    begin
      if LText.Length > 0 then
        LText.AppendLine;
      LText.Append(EntryText(FEntries[LIndex]));
    end;
    if (LText.Length = 0) and (ControlList1.ItemIndex >= 0) and
      (ControlList1.ItemIndex < FEntries.Count) then
      LText.Append(EntryText(FEntries[ControlList1.ItemIndex]));
    if LText.Length > 0 then
      Clipboard.AsText := LText.ToString;
  finally
    LText.Free;
  end;
end;

function TLogControl.EntryTypeColor(AEntryType: TLogEntryType): TColor;
begin
  var LStyle := StyleServices;
  case AEntryType of
    letSuccess:
      Result := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), clWebGreen, 0.5);
    letWarning:
      Result := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), clWebOrange, 0.5);
    letError:
      Result := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), clWebRed, 0.5);
    letProfile:
      Result := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), clWebBlue, 0.5);
  else
    Result := TExplorerTheme.ActiveTheme.TextColor
  end;
end;

function TLogControl.EntryText(const AEntry: TLogEntry): string;
begin
  Result := Format('%s'#9'%s'#9'%s', [
    FormatDateTime('hh:nn:ss.zzz', AEntry.Timestamp),
    EntryTypeText(AEntry.EntryType), AEntry.Message]);
end;

function TLogControl.EntryTypeText(AEntryType: TLogEntryType): string;
begin
  case AEntryType of
    letSuccess:
      Result := 'SUCCESS';
    letWarning:
      Result := 'WARNING';
    letError:
      Result := 'ERROR';
    letProfile:
      Result := 'PROFILE';
  else
    Result := 'INFO';
  end;
end;

procedure TLogControl.UpdateControlList;
begin
  ControlList1.ItemCount := FEntries.Count;
  //pnToolbar.Caption := Format('General activity (%d)', [FEntries.Count]);
  ControlList1.Invalidate;
end;

end.
