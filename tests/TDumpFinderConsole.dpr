program TDumpFinderConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  TDump.Explorer.Finder in '..\source\common\TDump.Explorer.Finder.pas';

procedure WriteInstallation(const AInstallation: TDumpInstallation);
begin
  Writeln('Studio ', AInstallation.StudioVersion);
  Writeln('  Root: ', AInstallation.StudioRoot);
  Writeln('  Bin:  ', AInstallation.BinPath);
  if AInstallation.HasTDump then
    Writeln('  TDUMP:   ', AInstallation.TDumpPath)
  else
    Writeln('  TDUMP:   not installed');
  if AInstallation.HasTDump64 then
    Writeln('  TDUMP64: ', AInstallation.TDump64Path)
  else
    Writeln('  TDUMP64: not installed');
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    var LFinder := TDumpFinder.Create;
    try
      var LInstallations := LFinder.Find;
      try
        Writeln('TDUMP installations: ', LInstallations.Count);
        var LDefaultInstallation := LFinder.FindDefault(LInstallations);
        if LDefaultInstallation <> nil then
        begin
          var LDefaultPath := LDefaultInstallation.TDumpPath;
          if LDefaultInstallation.HasTDump64 then
            LDefaultPath := LDefaultInstallation.TDump64Path;
          Writeln('Recommended default: Studio ',
            LDefaultInstallation.StudioVersion);
          Writeln('  ', LDefaultPath);
        end;
        for var LInstallation in LInstallations do
          WriteInstallation(LInstallation);
        if LInstallations.Count = 0 then
          ExitCode := 1;
      finally
        LInstallations.Free;
      end;
    finally
      LFinder.Free;
    end;
    Readln;
  except
    on LException: Exception do
    begin
      Writeln(ErrOutput, LException.ClassName, ': ', LException.Message);
      ExitCode := 1;
    end;
  end;
end.
