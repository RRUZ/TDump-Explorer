program TDumpRunnerConsole;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.IOUtils,
  TDump.Explorer.Finder in '..\source\common\TDump.Explorer.Finder.pas',
  TDump.Explorer.TextSource in '..\source\parser\TDump.Explorer.TextSource.pas',
  TDump.Explorer.Parser in '..\source\parser\TDump.Explorer.Parser.pas',
  TDump.Explorer.Runner in '..\source\common\TDump.Explorer.Runner.pas';

const
  CDefaultInputFile = '..\binaries\Package.Win64.bpl';

procedure WriteUsage;
begin
  Writeln('Usage: TDumpRunnerConsole [input-file] [32|64] [tdump-options|--] [output-file] [parse|no-parse]');
  Writeln('Example: TDumpRunnerConsole C:\dev\TDump-Explorer\binaries\VCL.Win64.exe 64 -e -ed report.tdump no-parse');
end;

procedure WriteDocumentSummary(const ADocument: TDumpDocument);
begin
  Writeln('Parsed lines: ', ADocument.Lines.Count);
  Writeln('Headers: ', ADocument.Headers.Count);
  Writeln('Sections: ', ADocument.Sections.Count);
  Writeln('Import modules: ', ADocument.Imports.Count);
  Writeln('Exports: ', ADocument.ExportList.Count);
  Writeln('Resources: ', ADocument.Resources.Count);
  Writeln('Relocations: ', ADocument.Relocations.Count);
  Writeln('Strings: ', ADocument.Strings.Count);
  Writeln('Object records: ', ADocument.ObjectRecords.Count);
  Writeln('Library members: ', ADocument.LibraryMembers.Count);
  Writeln('Mach load commands: ', ADocument.MachLoadCommands.Count);
  if ADocument.DebugInformation <> nil then
    Writeln('Normalized methods: ', ADocument.DebugInformation.Methods.Count)
  else
    Writeln('Normalized methods: 0');
  Writeln('Diagnostics: ', ADocument.Diagnostics.Count);
  Writeln('Unsupported structures: ', ADocument.UnsupportedStructures.Count);
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    var LInputFileName := CDefaultInputFile;
    if ParamCount >= 1 then
      LInputFileName := ParamStr(1);

    var LToolRequested := ParamCount >= 2;
    var LToolKind := tkUnknown;
    if LToolRequested then
    begin
      if SameText(ParamStr(2), '32') then
        LToolKind := tkTDump32
      else if SameText(ParamStr(2), '64') then
        LToolKind := tkTDump64
      else
      begin
        WriteUsage;
        ExitCode := 1;
        Exit;
      end;
    end;

    var LUseBestOptions := ParamCount < 3;
    var LOptions := '';
    if not LUseBestOptions then
      LOptions := ParamStr(3);
    if LOptions = '--' then
      LOptions := '';
    var LOutputFileName := '';
    if ParamCount >= 4 then
      LOutputFileName := ParamStr(4);
    var LParseResult := True;
    if ParamCount >= 5 then
    begin
      if SameText(ParamStr(5), 'parse') then
        LParseResult := True
      else if SameText(ParamStr(5), 'no-parse') then
        LParseResult := False
      else
      begin
        WriteUsage;
        ExitCode := 1;
        Exit;
      end;
    end;

    var LFinder := TDumpFinder.Create;
    try
      var LInstallations := LFinder.Find;
      try
        var LInstallation: TDumpInstallation;
        if LToolRequested then
        begin
          if LToolKind = tkTDump64 then
            LInstallation := LFinder.FindNewest(LInstallations, tekTDump64)
          else
            LInstallation := LFinder.FindNewest(LInstallations, tekTDump);
        end
        else
        begin
          LInstallation := LFinder.FindDefault(LInstallations);
          if (LInstallation <> nil) and LInstallation.HasTDump64 then
            LToolKind := tkTDump64
          else
            LToolKind := tkTDump32;
        end;

        var LToolName := 'TDUMP';
        if LToolKind = tkTDump64 then
          LToolName := 'TDUMP64';
        if LInstallation = nil then
          raise Exception.CreateFmt('No installed %s executable was found.',
            [LToolName]);
        var LToolPath := LInstallation.TDumpPath;
        if LToolKind = tkTDump64 then
          LToolPath := LInstallation.TDump64Path;
        Writeln('Selected Studio ', LInstallation.StudioVersion, ' as the newest ',
          LToolName, ' installation.');

        var LRunner := TDumpRunner.Create;
        try
          var LRun: TDumpRunResult;
          if LParseResult then
          begin
            if LUseBestOptions then
              LRun := LRunner.RunAndParse(LInputFileName, LToolPath, LToolKind)
            else
              LRun := LRunner.RunAndParse(LInputFileName, LToolPath, LToolKind,
                LOptions);
          end
          else
          begin
            if LUseBestOptions then
              LRun := LRunner.Run(LInputFileName, LToolPath, LToolKind)
            else
              LRun := LRunner.Run(LInputFileName, LToolPath, LToolKind, LOptions);
          end;
          try
            if LOutputFileName <> '' then
            begin
              TFile.WriteAllText(LOutputFileName, LRun.OutputText,
                TEncoding.Default);
              Writeln('Output: ', ExpandFileName(LOutputFileName));
            end;
            Writeln('Input: ', LRun.InputFileName);
            Writeln('Tool: ', LRun.ToolPath);
            Writeln('Options: ', LRun.Options);
            Writeln('Exit code: ', LRun.ExitCode);
            Writeln('Captured characters: ', Length(LRun.OutputText));
            if LRun.Document <> nil then
              WriteDocumentSummary(LRun.Document)
            else
              Writeln('Parsing: skipped');
            ExitCode := Integer(LRun.ExitCode);
          finally
            LRun.Free;
          end;
        finally
          LRunner.Free;
        end;
      finally
        LInstallations.Free;
      end;
    finally
      LFinder.Free;
    end;
    if LOutputFileName = '' then
      Readln;
  except
    on LException: Exception do
    begin
      Writeln(ErrOutput, LException.ClassName, ': ', LException.Message);
      ExitCode := 1;
    end;
  end;
end.
