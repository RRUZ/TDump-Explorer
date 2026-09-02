program TDumpExplorerComponentTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.StrUtils,
  System.Types,
  System.IOUtils,
  System.JSON,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Forms,
  DUnitX.TestFramework,
  DUnitX.Loggers.Xml.NUnit,
  TDump.Explorer.Tabs in '..\source\common\TDump.Explorer.Tabs.pas',
  TDump.Explorer.UI in '..\source\common\TDump.Explorer.UI.pas',
  TDump.Explorer.Export in '..\source\common\TDump.Explorer.Export.pas',
  TDump.Explorer.TinyParser in '..\source\common\TDump.Explorer.TinyParser.pas',
  TDump.Explorer.Highlighter in '..\source\common\TDump.Explorer.Highlighter.pas',
  TDump.Explorer.HighlighterControl in '..\source\gui\TDump.Explorer.HighlighterControl.pas',
  TDump.Explorer.LogControl in '..\source\gui\TDump.Explorer.LogControl.pas',
  TDump.Explorer.Settings in '..\source\gui\TDump.Explorer.Settings.pas',
  TDumpExplorerComponentTestHost in 'TDumpExplorerComponentTestHost.pas';

const
  cTestResultsDirectory = 'C:\dev\TDump-Explorer\tests\test-results';
  cTestResultsFile = cTestResultsDirectory +
    '\TDumpExplorerComponentTests.nunit.xml';

{ TEST TODO:
  - Raw View: host TRawViewFrame through TDumpDocumentFrame in an attached tab,
    then assert debounce, cancellation, filtered source-index mapping, and the
    double-click filter-clear jump. Its virtual highlighter is created while
    the document frame receives its runtime parent, so an isolated TForm host
    does not reproduce the supported initialization path.
  - Main input queue: cover recent-menu, command-line, file-dialog, and
    multi-file drag/drop activation rules with a deterministic runner stub.
  - Popup/menu chrome: cover theme/titlebar colors in an actual styled app
    window; component tests cover the reusable content, not custom-titlebar
    composition.
  - Release resources: after the Win64 Release artifact is built, inspect its
    icon, VERSIONINFO, manifest, per-monitor-v2 DPI, and supported-OS entries.
  - TDUMP discovery: use an injectable filesystem/registry probe to cover
    invalid stored paths and best-candidate selection without machine state.
}

type
  [TestFixture]
  TExplorerComponentFixture = class
  public
    [Test] procedure HighlightThemes;
    [Test] procedure TextFormatDrawing;
    [Test] procedure ViewExportFormats;
    [Test] procedure HighlighterSortingAndLayouts;
    [Test] procedure LogFilteringNavigation;
    [Test] procedure SettingsRoundTrip;
  end;

procedure Require(ACondition: Boolean; const AMessage: string);
begin
  Assert.IsTrue(ACondition, AMessage);
end;

procedure TestHighlightThemes;
begin
  var LLightTheme := TExplorerTheme.LightTheme;
  var LDarkTheme := TExplorerTheme.DarkTheme;
  Require(LLightTheme.StringLiteralColor <> LDarkTheme.StringLiteralColor,
    'Light and dark highlighter themes must have distinct token palettes.');
  Require(LLightTheme.HexadecimalColor <> LLightTheme.NumberColor,
    'The light theme must distinguish hexadecimal and decimal values.');
  Require(LDarkTheme.DateTimeColor <> LDarkTheme.TextColor,
    'The dark theme must distinguish date/time and string values.');
  Require(LDarkTheme.StringLiteralColor <> LDarkTheme.MethodColor,
    'The dark theme must distinguish string literals and methods.');
  Require(LLightTheme.MethodColor <> LLightTheme.KeywordColor,
    'The light theme must distinguish demangled methods and keywords.');
end;

procedure TestTextFormatDrawing;
begin
  var LBitmap := TBitmap.Create;
  try
    LBitmap.SetSize(180, 24);
    var LTheme := TExplorerTheme.DarkTheme;
    LBitmap.Canvas.Brush.Color := LTheme.BackgroundColor;
    LBitmap.Canvas.FillRect(Rect(0, 0, LBitmap.Width, LBitmap.Height));
    var LHighlighter := TTinyHighlighter.Create;
    try
      LHighlighter.TextRect(LBitmap.Canvas,
        Rect(0, 0, LBitmap.Width, LBitmap.Height), 'Value=0xCAFEBABE',
        thtDark, [tfRight, tfVerticalCenter, tfEndEllipsis],
        tpmCppBuilderMethod);
      Assert.Pass('Highlighted text rendering completed without an exception.');
    finally
      LHighlighter.Free;
    end;
  finally
    LBitmap.Free;
  end;
end;

procedure TestViewExportFormats;
const
  cEscapedTextValue = 'Comma, "double", ''single'', slash ' + #92 + #92 +
    ' tab ' + #92 + 'tend';
  cEscapedTextLine = 'Line 1' + #92 + 'r' + #92 + 'nLine 2 | markdown';
var
  LHeaders: TArray<string>;
  LRows: TDumpExportRows;
begin
  SetLength(LHeaders, 2);
  LHeaders[0] := 'Name';
  LHeaders[1] := 'Value';
  SetLength(LRows, 2);
  SetLength(LRows[0], 2);
  LRows[0][0] := 'Alpha';
  LRows[0][1] := 'Comma, "double", ''single'', slash ' + #92 +
    ' tab ' + #9 + 'end';
  SetLength(LRows[1], 2);
  LRows[1][0] := 'Beta';
  LRows[1][1] := 'Line 1' + #13#10 + 'Line 2 | markdown';

  Require(ExportView(LHeaders, LRows, defText) =
    'Name' + #9 + 'Value' + sLineBreak +
    'Alpha' + #9 + cEscapedTextValue + sLineBreak +
    'Beta' + #9 + cEscapedTextLine,
    'Text export must retain headers while escaping row-breaking characters.');

  Require(ExportView(LHeaders, LRows, defCsv) =
    'Name,Value' + sLineBreak +
    'Alpha,"Comma, ""double"", ''single'', slash ' + #92 + ' tab ' +
    #9 + 'end"' + sLineBreak +
    'Beta,"Line 1' + #13#10 + 'Line 2 | markdown"',
    'CSV export must retain headers and quote commas, double quotes, tabs, and CR/LF.');

  var LJson := ExportView(LHeaders, LRows, defJson);
  Require(ContainsText(LJson, '"Name": "Alpha"') and
    ContainsText(LJson, '"Value": "Comma, ' + #92 + '"double' + #92 +
      '", ''single'', slash ' + #92 + #92 + ' tab ' + #92 + 'tend"') and
    ContainsText(LJson, 'Line 1' + #92 + 'r' + #92 + 'nLine 2 | markdown'),
    'JSON export must use column names and escape backslashes, quotes, tabs, and CR/LF.');

  Require(ExportView(LHeaders, LRows, defMarkdown) =
    '| Name | Value |' + sLineBreak +
    '| --- | --- |' + sLineBreak +
    '| Alpha | Comma, "double", ''single'', slash ' + #92 + #92 + ' tab ' +
      #9 + 'end |' + sLineBreak +
    '| Beta | Line 1<br>Line 2 ' + #92 + '| markdown |',
    'Markdown export must create a table and preserve quote, slash, pipe, tab, and CR/LF content.');

  SetLength(LHeaders, 0);
  SetLength(LRows, 1);
  SetLength(LRows[0], 1);
  LRows[0][0] := 'Unstructured report row';
  Require(ExportView(LHeaders, LRows, defText) =
    'Text' + sLineBreak + 'Unstructured report row',
    'Headless text export must still expose a fallback column name.');
  Require(ExportView(LHeaders, LRows, defCsv) =
    'Text' + sLineBreak + 'Unstructured report row',
    'Headless CSV export must still expose a fallback column name.');
  Require(ExportView(LHeaders, LRows, defMarkdown) =
    '| Text |' + sLineBreak + '| --- |' + sLineBreak +
    '| Unstructured report row |',
    'Headless Markdown export must still expose a fallback column name.');

  SetLength(LHeaders, 3);
  LHeaders[0] := '';
  LHeaders[1] := 'Name';
  LHeaders[2] := 'Name';
  SetLength(LRows, 1);
  SetLength(LRows[0], 2);
  LRows[0][0] := 'Unicode ✓ ' + #0;
  LRows[0][1] := 'First';
  LJson := ExportView(LHeaders, LRows, defJson);
  var LJsonValue := TJSONObject.ParseJSONValue(LJson);
  try
    Require(LJsonValue is TJSONArray,
      'JSON export must remain syntactically valid for Unicode, NUL, and duplicate headers.');
    var LJsonRows := TJSONArray(LJsonValue);
    Require(LJsonRows.Count = 1,
      'JSON export must retain the supplied row count.');
    var LJsonRow := TJSONObject(LJsonRows.Items[0]);
    Require((LJsonRow.GetValue<string>('Column 1') = 'Unicode ✓ ' + #0) and
      (LJsonRow.GetValue<string>('Name') = 'First') and
      (LJsonRow.GetValue<string>('Name (2)') = ''),
      'JSON export must preserve control characters, ragged rows, and unique duplicate keys.');
  finally
    LJsonValue.Free;
  end;
  SetLength(LRows, 0);
  Require(ExportView(LHeaders, LRows, defJson) = '[]',
    'JSON export must produce an empty array for an empty view.');
  Require(ExportView(LHeaders, LRows, defCsv) = 'Column 1,Name,Name',
    'CSV export must retain a header row for an empty view.');
end;

procedure TestHighlighterSortingAndLayouts;
begin
  var LHost := TComponentTestHostForm.Create(nil);
  try
    LHost.SetBounds(-32000, -32000, 640, 480);
    LHost.Show;
    Application.ProcessMessages;
    var LControl := LHost.HighlighterControl;
    LControl.AutoSizeColumns := False;
    LControl.SetViewLayoutId('component-highlighter-primary');
    LControl.SetColumnHeaders(['Name', 'Size']);
    LControl.SetColumnDataTypes([thdtText, thdtInteger]);
    LControl.Add('Zulu' + #9 + '20');
    LControl.SetLineNumber(0, 300);
    LControl.Add('Alpha' + #9 + '5');
    LControl.SetLineNumber(1, 100);
    LControl.Add('Beta' + #9 + '10');
    LControl.SetLineNumber(2, 200);
    LControl.SelectItem(0);

    LControl.HeaderControl1.OnSectionClick(LControl.HeaderControl1,
      LControl.HeaderControl1.Sections[1]);
    Require(LControl.SelectedItemLineNumber = 300,
      'Sorting must preserve the selected source row.');
    LControl.SelectItem(0);
    Require(LControl.SelectedItemLineNumber = 100,
      'Integer sorting must expose the smallest value first.');

    LControl.HeaderControl1.Sections[0].Width := 240;
    LControl.HeaderControl1.OnSectionResize(LControl.HeaderControl1,
      LControl.HeaderControl1.Sections[0]);
    LControl.SetViewLayoutId('component-highlighter-secondary');
    LControl.SetColumnHeaders(['Name', 'Size']);
    LControl.SetViewLayoutId('component-highlighter-primary');
    LControl.SetColumnHeaders(['Name', 'Size']);
    Require(LControl.HeaderControl1.Sections[0].Width = 240,
      'Column widths must be preserved per view layout.');
    LControl.ResetSortOrder;
    LControl.SelectItem(0);
    Require(LControl.SelectedItemLineNumber = 300,
      'Reset sort must restore source order.');
  finally
    LHost.Free;
  end;
end;

procedure TestLogFilteringNavigation;
begin
  var LHost := TComponentTestHostForm.Create(nil);
  try
    LHost.SetBounds(-32000, -32000, 640, 480);
    LHost.Show;
    Application.ProcessMessages;
    var LLog := LHost.LogControl;
    LLog.Add('First entry');
    LLog.Add('match one');
    LLog.Add('Middle entry');
    LLog.Add('match two');
    LLog.SearchFilterBox.Text := 'match';
    LLog.ApplyFilter;
    Require((LLog.ControlList1.ItemCount = 2) and
      (LLog.VisibleEntryIndex(0) = 1) and
      (LLog.VisibleEntryIndex(1) = 3),
      'Log filtering must retain original indexes for duplicate matches.');
    LLog.ControlList1.ItemIndex := 1;
    LLog.ControlList1DblClick(LLog.ControlList1);
    Application.ProcessMessages;
    Require((LLog.SearchFilterBox.Text = '') and
      (LLog.ControlList1.ItemIndex = 3),
      'Double-clicking a filtered log row must clear the filter and select its original row.');
  finally
    LHost.Free;
  end;
end;

procedure TestSettingsRoundTrip;
var
  LGuid: TGUID;
  LFolder: string;
  LSettings: TSettings;
  LFirstFile: string;
  LSecondFile: string;
begin
  CreateGUID(LGuid);
  LFolder := TPath.Combine(TPath.GetTempPath,
    'TDumpExplorerComponentTests-' + GUIDToString(LGuid));
  ForceDirectories(LFolder);
  TSettings.SetSettingsFolderOverride(LFolder);
  try
    LSettings := TSettings.Instance;
    LSettings.ClearRecentItems;
    LSettings.RecentItems := 2;
    LFirstFile := TPath.Combine(LFolder, 'first.tdump');
    LSecondFile := TPath.Combine(LFolder, 'second.tdump');
    LSettings.AddRecentItem(LFirstFile);
    LSettings.AddRecentItem(LSecondFile);
    LSettings.AddRecentItem(LFirstFile);
    LSettings.TDumpPath := TPath.Combine(LFolder, 'tdump.exe');
    LSettings.ThemeOption := toDark;
    LSettings.ShowLogPanel := False;
    LSettings.ShowRawPanel := True;
    LSettings.FollowRawSelection := False;
    LSettings.Save;

    LSettings.ClearRecentItems;
    LSettings.TDumpPath := '';
    LSettings.ThemeOption := toLight;
    LSettings.ShowLogPanel := True;
    LSettings.ShowRawPanel := False;
    LSettings.FollowRawSelection := True;
    LSettings.Load;
    Require((LSettings.RecentItemCount = 2) and
      SameText(LSettings.RecentItem(0), ExpandFileName(LFirstFile)) and
      SameText(LSettings.RecentItem(1), ExpandFileName(LSecondFile)) and
      SameText(LSettings.TDumpPath, TPath.Combine(LFolder, 'tdump.exe')) and
      (LSettings.ThemeOption = toDark) and not LSettings.ShowLogPanel and
      LSettings.ShowRawPanel and not LSettings.FollowRawSelection,
      'Settings must persist MRU ordering, TDUMP path, theme, and workspace options.');
  finally
    TSettings.SetSettingsFolderOverride('');
    TDirectory.Delete(LFolder, True);
  end;
end;

procedure TExplorerComponentFixture.HighlightThemes;
begin
  TestHighlightThemes;
end;

procedure TExplorerComponentFixture.TextFormatDrawing;
begin
  TestTextFormatDrawing;
end;

procedure TExplorerComponentFixture.ViewExportFormats;
begin
  TestViewExportFormats;
end;

procedure TExplorerComponentFixture.HighlighterSortingAndLayouts;
begin
  TestHighlighterSortingAndLayouts;
end;

procedure TExplorerComponentFixture.LogFilteringNavigation;
begin
  TestLogFilteringNavigation;
end;

procedure TExplorerComponentFixture.SettingsRoundTrip;
begin
  TestSettingsRoundTrip;
end;

begin
  Application.Initialize;
  ReportMemoryLeaksOnShutdown := True;
  TDUnitX.RegisterTestFixture(TExplorerComponentFixture);
  var LRunner := TDUnitX.CreateRunner;
  LRunner.UseRTTI := False;
  LRunner.FailsOnNoAsserts := True;
  ForceDirectories(cTestResultsDirectory);
  LRunner.AddLogger(TDUnitXXMLNUnitFileLogger.Create(cTestResultsFile));
  var LResults := LRunner.Execute;
  if not LResults.AllPassed then
    ExitCode := EXIT_ERRORS;
end.
