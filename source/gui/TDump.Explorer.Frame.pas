unit TDump.Explorer.Frame;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  TDump.Explorer.HighlighterControl;

type
  TFrame1 = class(TFrame)
    ProgressBar1: TProgressBar;
    HighlighterControl1: THighlighterControl;
  private
  public
    procedure SetProgress(ACompletedLines, ATotalLines: Integer);
    procedure SetStatus(const AStatus: string);
    procedure ShowSummary(const ASummary: string);
  end;

implementation

{$R *.dfm}

procedure TFrame1.SetProgress(ACompletedLines, ATotalLines: Integer);
begin
  if ATotalLines <= 0 then
    Exit;

  ProgressBar1.Max := ATotalLines;
  var LPosition := ACompletedLines;
  if LPosition < ProgressBar1.Min then
    LPosition := ProgressBar1.Min
  else if LPosition > ProgressBar1.Max then
    LPosition := ProgressBar1.Max;
  ProgressBar1.Position := LPosition;
  ProgressBar1.Update;
end;

procedure TFrame1.SetStatus(const AStatus: string);
begin
  HighlighterControl1.SetText(AStatus);
  ProgressBar1.Min := 0;
  ProgressBar1.Max := 100;
  ProgressBar1.Position := 0;
  ProgressBar1.Update;
end;

procedure TFrame1.ShowSummary(const ASummary: string);
begin
  HighlighterControl1.SetText(ASummary);
  ProgressBar1.Position := ProgressBar1.Max;
  ProgressBar1.Update;
end;

end.
