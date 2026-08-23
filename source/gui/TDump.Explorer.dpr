program TDump.Explorer;

uses
  Vcl.Forms,
  TDump.Explorer.Phosphor.Font in '..\common\TDump.Explorer.Phosphor.Font.pas',
  TDump.Explorer.Finder in '..\common\TDump.Explorer.Finder.pas',
  TDump.Explorer.Parser in '..\parser\TDump.Explorer.Parser.pas',
  TDump.Explorer.Runner in '..\common\TDump.Explorer.Runner.pas',
  TDump.Explorer.Main in 'TDump.Explorer.Main.pas' {FrmMain};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.Run;
end.
