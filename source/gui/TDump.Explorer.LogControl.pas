unit TDump.Explorer.LogControl;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.ControlList, Vcl.WinXCtrls;

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
    Panel1: TPanel;
    SearchFilterBox: TSearchBox;
  private
    const
      CTextPadding = 8;
      CTimestampColumnWidth = 92;
      CStatusColumnWidth = 78;
    var
      FEntries: TLogEntryList;
    procedure ControlList1BeforeDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    function EntryTypeColor(AEntryType: TLogEntryType): TColor;
    function EntryTypeText(AEntryType: TLogEntryType): string;
    procedure UpdateControlList;
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

constructor TLogControl.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FEntries := TLogEntryList.Create;
  ControlList1.OnBeforeDrawItem := ControlList1BeforeDrawItem;
  Panel1.Alignment := taLeftJustify;
  UpdateControlList;
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

  UpdateControlList;
  ControlList1.ItemIndex := FEntries.Count - 1;
end;

procedure TLogControl.Clear;
begin
  FEntries.Clear;
  UpdateControlList;
end;

procedure TLogControl.ControlList1BeforeDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
var
  LEntry: TLogEntry;
  LTimestampText: string;
  LStatusText: string;
  LTimestampRect: TRect;
  LStatusRect: TRect;
  LMessageRect: TRect;
  LFillColor: TColor;
begin
  if (AIndex < 0) or (AIndex >= FEntries.Count) then
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

  LEntry := FEntries[AIndex];
  LTimestampText := FormatDateTime('hh:nn:ss.zzz', LEntry.Timestamp);
  LStatusText := EntryTypeText(LEntry.EntryType);
  LTimestampRect := ARect;
  LTimestampRect.Left := LTimestampRect.Left + CTextPadding;
  LTimestampRect.Right := LTimestampRect.Left + CTimestampColumnWidth;
  LStatusRect := ARect;
  LStatusRect.Left := LTimestampRect.Right;
  LStatusRect.Right := LStatusRect.Left + CStatusColumnWidth;
  LMessageRect := ARect;
  LMessageRect.Left := LStatusRect.Right;
  LMessageRect.Right := LMessageRect.Right - CTextPadding;
  if LMessageRect.Right < LMessageRect.Left then
    LMessageRect.Right := LMessageRect.Left;

  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := 9;
  {
  if (odSelected in AState) or (odFocused in AState) then
    ACanvas.Font.Color := LStyle.GetSystemColor(clHighlightText)
  else
  }
  ACanvas.Font.Color := EntryTypeColor(LEntry.EntryType);

  ACanvas.Brush.Style := bsClear;
  DrawText(ACanvas.Handle, PChar(LTimestampText), Length(LTimestampText),
    LTimestampRect, DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX);
  DrawText(ACanvas.Handle, PChar(LStatusText), Length(LStatusText),
    LStatusRect, DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX);
  DrawText(ACanvas.Handle, PChar(LEntry.Message), Length(LEntry.Message),
    LMessageRect, DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX);
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
    Result := ColorBlendRGB(LStyle.GetSystemColor(clWindowText), LStyle.GetSystemColor(clWindow), 0.3);
  end;
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
  Panel1.Caption := Format('General activity (%d)', [FEntries.Count]);
  ControlList1.Invalidate;
end;

end.
