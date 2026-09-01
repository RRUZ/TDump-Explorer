program TDump.Explorer;

uses
  System.Classes,
  Vcl.Themes,
  Vcl.Styles,
  Vcl.Forms,
  TDump.Explorer.Phosphor.Font in '..\common\TDump.Explorer.Phosphor.Font.pas',
  TDump.Explorer.Finder in '..\common\TDump.Explorer.Finder.pas',
  TDump.Explorer.TextSource in '..\parser\TDump.Explorer.TextSource.pas',
  TDump.Explorer.Parser in '..\parser\TDump.Explorer.Parser.pas',
  TDump.Explorer.Runner in '..\common\TDump.Explorer.Runner.pas',
  TDump.Explorer.Main in 'TDump.Explorer.Main.pas' {FrmMain},
  TDump.Explorer.Frame in 'TDump.Explorer.Frame.pas' {DumpDocumentFrame: TFrame},
  TDump.Explorer.CrossReferences in 'TDump.Explorer.CrossReferences.pas' {CrossReferencesFrame: TFrame},
  TDump.Explorer.RawView in 'TDump.Explorer.RawView.pas' {RawViewFrame: TFrame},
  TDump.Explorer.HighlighterControl in 'TDump.Explorer.HighlighterControl.pas' {HighlighterControl: TFrame},
  TDump.Explorer.HighlighterProviders in 'TDump.Explorer.HighlighterProviders.pas',
  TDump.Explorer.TinyParser in '..\common\TDump.Explorer.TinyParser.pas',
  TDump.Explorer.Highlighter in '..\common\TDump.Explorer.Highlighter.pas',
  TDump.Explorer.UI in '..\common\TDump.Explorer.UI.pas',
  TDump.Explorer.GlassTabs in '..\common\TDump.Explorer.GlassTabs.pas',
  TDump.Explorer.LogControl in 'TDump.Explorer.LogControl.pas' {LogControl: TFrame},
  TDump.Explorer.Relations in '..\common\TDump.Explorer.Relations.pas',
  TDump.Explorer.Resources in 'TDump.Explorer.Resources.pas' {DataModule1: TDataModule},
  TDump.Explorer.Utils in '..\common\TDump.Explorer.Utils.pas',
  TDump.Explorer.View.ELF in 'TDump.Explorer.View.ELF.pas',
  TDump.Explorer.View.Mach in 'TDump.Explorer.View.Mach.pas',
  TDump.Explorer.View.OMF in 'TDump.Explorer.View.OMF.pas',
  TDump.Explorer.View.PE in 'TDump.Explorer.View.PE.pas',
  TDump.Explorer.View.Shared in 'TDump.Explorer.View.Shared.pas',
  TDump.Explorer.PopupMenu in 'TDump.Explorer.PopupMenu.pas',
  TDump.Explorer.Settings in 'TDump.Explorer.Settings.pas' {FrmSettings},
  TDump.Explorer.View.Borland in 'TDump.Explorer.View.Borland.pas';

{$R *.res}
{$R TDump.Explorer.rc.res}

begin
  ReportMemoryLeaksOnShutdown := True;
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.CreateForm(TDataModule1, DataModule1);
  FrmMain.InitializeTabImages;
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
