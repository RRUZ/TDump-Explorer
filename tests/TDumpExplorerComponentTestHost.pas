unit TDumpExplorerComponentTestHost;

interface

uses
  Vcl.Forms,
  TDump.Explorer.HighlighterControl,
  TDump.Explorer.LogControl;

type
  TComponentTestHostForm = class(TForm)
    HighlighterControl: THighlighterControl;
    LogControl: TLogControl;
  end;

implementation

{$R *.dfm}

end.
