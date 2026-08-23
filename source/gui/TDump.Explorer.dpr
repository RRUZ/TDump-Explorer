program TDump.Explorer;

uses
  System.Classes,
  Vcl.Forms,
  TDump.Explorer.Phosphor.Font in '..\common\TDump.Explorer.Phosphor.Font.pas',
  TDump.Explorer.Finder in '..\common\TDump.Explorer.Finder.pas',
  TDump.Explorer.Parser in '..\parser\TDump.Explorer.Parser.pas',
  TDump.Explorer.Runner in '..\common\TDump.Explorer.Runner.pas',
  TDump.Explorer.Main in 'TDump.Explorer.Main.pas' {FrmMain};

{$R *.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMain, FrmMain);
  if ParamCount > 0 then
  begin
    var LInputFileName := ParamStr(1);
    TThread.ForceQueue(nil,
      procedure
      begin
        FrmMain.OpenInputFile(LInputFileName);
      end);
  end;
  Application.Run;
end.
