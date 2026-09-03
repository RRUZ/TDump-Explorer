program TDumpExplorerComponentTests;

{$APPTYPE CONSOLE}

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.StrUtils,
  System.Math,
  System.Types,
  System.IOUtils,
  System.JSON,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.StdCtrls,
  Vcl.Forms,
  DUnitX.TestFramework,
  DUnitX.Loggers.Xml.NUnit,
  TDump.Explorer.Tabs in '..\source\common\TDump.Explorer.Tabs.pas',
  TDump.Explorer.UI in '..\source\common\TDump.Explorer.UI.pas',
  TDump.Explorer.Phosphor.Font in '..\source\common\TDump.Explorer.Phosphor.Font.pas',
  TDump.Explorer.Export in '..\source\common\TDump.Explorer.Export.pas',
  TDump.Explorer.TinyParser in '..\source\common\TDump.Explorer.TinyParser.pas',
  TDump.Explorer.Highlighter in '..\source\common\TDump.Explorer.Highlighter.pas',
  TDump.Explorer.HighlighterControl in '..\source\gui\TDump.Explorer.HighlighterControl.pas',
  TDump.Explorer.LogControl in '..\source\gui\TDump.Explorer.LogControl.pas',
  TDump.Explorer.Settings in '..\source\gui\TDump.Explorer.Settings.pas',
  TDump.Explorer.About in '..\source\gui\TDump.Explorer.About.pas',
  TDump.Explorer.Resources in '..\source\gui\TDump.Explorer.Resources.pas',
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
  private
    FIconDrawCount: Integer;
    FIconRect: TRect;
    FIconColor: TColor;
    FRejectResize: Boolean;
    FResizeCalls: Integer;
    FMovedCalls: Integer;
    procedure CheckResizeEvent(Sender: TObject; var NewSize: Integer; var Accept: Boolean);
    procedure CheckMovedEvent(Sender: TObject);
    procedure RecordItemIcon(Sender: TObject; AIndex: Integer; ACanvas: TCanvas;
      const ARect: TRect; AColor: TColor);
    function ItemTrailingText(AIndex: Integer): string;
  public
    [Test] procedure HighlightThemes;
    [Test] procedure TextFormatDrawing;
    [Test] procedure ViewExportFormats;
    [Test] procedure HighlighterSortingAndLayouts;
    [Test] procedure HighlighterSortGlyphPlacement;
    [Test] procedure DocumentIconClassification;
    [Test] procedure HighlighterCustomIcons;
    [Test] procedure HighlighterTrailingText;
    [Test] procedure HighlighterFontDpi;
    [Test] procedure LogFontDpi;
    [Test] procedure DialogFontDpi;
    [Test] procedure SplitterGripDrawing;
    [Test] procedure SplitterHoverPolicy;
    [Test] procedure SplitterLineGradient;
    [Test] procedure SplitterDragGuide;
    [Test] procedure LogFilteringNavigation;
    [Test] procedure BadgeMeasurementBeforeParenting;
    [Test] procedure RoundedLogLayout;
    [Test] procedure FocusScrollBarVisibility;
    [Test] procedure SettingsDialogLayout;
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

procedure TestHighlighterSortGlyphPlacement;
var
  LDrawItem: TDrawItemStruct;
begin
  var LHost := TComponentTestHostForm.Create(nil);
  try
    LHost.SetBounds(-32000, -32000, 640, 480);
    LHost.Show;
    Application.ProcessMessages;
    var LControl := LHost.HighlighterControl;
    LControl.AutoSizeColumns := False;
    LControl.SetColumnHeaders(['Severity', 'Line', 'Message']);
    LControl.Add('Error' + #9 + '4' + #9 + 'Invalid data');
    var LHeader := LControl.HeaderControl1;
    var LBitmap := TBitmap.Create;
    try
      LBitmap.SetSize(LHeader.Width, LHeader.Height);
      var LAccent := ColorToRGB(TExplorerTheme.ActiveTheme.SelectionColor);
      // Cover the caption-overlap regression, an ellipsized caption, a roomy
      // header, and a column too narrow to display a complete sort glyph.
      for var LWidth in TArray<Integer>.Create(76, 52, 160, 20) do
      begin
        LHeader.Sections[0].Width := Round(LWidth * LControl.ScaleFactor);
        LHeader.OnSectionResize(LHeader, LHeader.Sections[0]);
        for var LDirection := 0 to 1 do
        begin
          LHeader.OnSectionClick(LHeader, LHeader.Sections[0]);
          // Send the same owner-draw notification as the native header,
          // targeting the test bitmap rather than its on-screen window DC.
          LDrawItem := Default(TDrawItemStruct);
          LDrawItem.itemID := 0;
          LDrawItem.hwndItem := LHeader.Handle;
          LDrawItem.hDC := LBitmap.Canvas.Handle;
          LDrawItem.rcItem := Rect(0, 0, LHeader.Sections[0].Width, LHeader.Height);
          LHeader.Perform(CN_DRAWITEM, 0, LPARAM(@LDrawItem));
          var LFirstGlyphX := LHeader.Sections[0].Width;
          for var LY := 0 to LBitmap.Height - 1 do
            for var LX := 0 to LHeader.Sections[0].Width - 1 do
              if ColorToRGB(LBitmap.Canvas.Pixels[LX, LY]) = LAccent then
                LFirstGlyphX := Min(LFirstGlyphX, LX);
          var LGlyphSlotWidth := Round(18 * LControl.ScaleFactor);
          if LHeader.Sections[0].Width < 16 + LGlyphSlotWidth then
            Require(LFirstGlyphX = LHeader.Sections[0].Width,
              'A tiny header must not draw a clipped sort arrow.')
          else
          begin
            Require(LFirstGlyphX < LHeader.Sections[0].Width,
              'Sorted header must display its sort arrow.');
            LBitmap.Canvas.Font.Assign(LHeader.Font);
            var LTextRight := Min(LHeader.Sections[0].Width - 8 - LGlyphSlotWidth,
              8 + LBitmap.Canvas.TextWidth('Severity'));
            Require(LFirstGlyphX >= LTextRight + Round(3 * LControl.ScaleFactor),
              'Sort arrow must follow the text/ellipsis without overlapping it.');
          end;
        end;
      end;
    finally
      LBitmap.Free;
    end;
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

procedure TestBadgeMeasurementBeforeParenting;
begin
  var LBadge := TExplorerBadgeLabel.Create(nil);
  try
    LBadge.Font.Name := TExplorerTheme.FontName;
    LBadge.Font.Size := TExplorerTheme.FontSize;
    LBadge.Height := 28;
    LBadge.Caption := '1 line';
    var LShortWidth := LBadge.NaturalWidth;
    LBadge.Caption := '1,000 / 10,000 matches';
    Require(LBadge.NaturalWidth > LShortWidth,
      'Badge measurement must work before a frame has a parent window.');
    var LNormalWidth := LBadge.NaturalWidth;
    LBadge.Font.Size := 18;
    Require(LBadge.NaturalWidth > LNormalWidth,
      'Badge measurement must use the current font, including DPI scaling.');
    Require((LBadge.Width = LBadge.NaturalWidth) and (LBadge.Height = 28),
      'Caption/font changes must resize badge width without changing its height.');
    var LBitmap := TBitmap.Create;
    try
      LBitmap.Canvas.Font.Assign(LBadge.Font);
      Require(LBadge.NaturalWidth = LBitmap.Canvas.TextWidth(LBadge.Caption) +
        2 * MulDiv(8, LBadge.CurrentPPI, 96),
        'Badge width must include exactly eight design pixels on each side.');
    finally
      LBitmap.Free;
    end;
  finally
    LBadge.Free;
  end;
end;

procedure TestRoundedLogLayout;
begin
  var LHost := TComponentTestHostForm.Create(nil);
  try
    LHost.SetBounds(-32000, -32000, 640, 480);
    LHost.Show;
    Application.ProcessMessages;
    var LLog := LHost.LogControl;
    var LBadge := TExplorerBadgeLabel(LLog.FindComponent('FilterCountBadge'));
    Require(LBadge <> nil, 'Log count must use the shared badge label.');
    Require(LLog.SearchFilterBox.BorderStyle = bsNone,
      'The custom rounded search border must not retain a native rectangle.');
    Require(LLog.SearchFilterBox.ButtonWidth = 0,
      'The native black glyph must not overlap the theme-aware search glyph.');
    for var LWidth in TArray<Integer>.Create(640, 950, 1200) do
    begin
      LHost.ClientWidth := LWidth;
      LLog.Height := 160;
      LLog.Add('A searchable entry');
      Require(LLog.pbSurface.BoundsRect = LLog.ClientRect,
        'Pane decoration must follow the full frame bounds after resizing.');
      Require((LLog.ControlList1.Left > 0) and
        (LLog.ControlList1.BoundsRect.Bottom < LLog.ClientHeight),
        'Content must leave room for the rounded pane corners.');
      Require((LBadge.Left >= LLog.Label1.BoundsRect.Right) and
        (LBadge.BoundsRect.Right < LLog.pnSearch.Left),
        'Count badge must not overlap the title or search field.');
    end;
    LLog.SearchFilterBox.Text := 'searchable';
    Require(LBadge.Caption = '3 / 3 matches', 'Filtered badge count is incorrect.');
    LLog.ControlList1.SetFocus;
    LLog.SearchBorderMouseDown(LLog.pbSearchBorder, mbLeft, [], 2, 2);
    Require(LLog.SearchFilterBox.Focused, 'Clicking search padding must focus the edit.');
    LLog.SearchFilterBox.Text := '';
    Require(LBadge.Caption = '3 entries', 'Clearing a filter must restore the entry count.');
  finally
    LHost.Free;
  end;
end;

procedure TestFocusScrollBarVisibility;
begin
  var LHost := TComponentTestHostForm.Create(nil);
  try
    // Off-screen: the real pointer cannot accidentally hover this list.
    LHost.SetBounds(-32000, -32000, 640, 480);
    LHost.Show;
    var LLog := LHost.LogControl;
    LLog.Height := 160;
    LLog.SearchFilterBox.SetFocus;
    for var LIndex := 1 to 100 do
      LLog.Add('Entry ' + IntToStr(LIndex));
    Application.ProcessMessages;
    var LList := LLog.ControlList1;
    Require((GetWindowLong(LList.Handle, GWL_STYLE) and WS_VSCROLL) = 0,
      'Unfocused, unhovered log must hide its scrollbar after content updates.');
    var LScrollPos := GetScrollPos(LList.Handle, SB_VERT);
    var LClientHeight := LList.ClientHeight;
    Require(LScrollPos > 0, 'Hiding must not reset the current scroll position.');
    LList.SetFocus;
    Application.ProcessMessages;
    Require((GetWindowLong(LList.Handle, GWL_STYLE) and WS_VSCROLL) <> 0,
      'Focusing a scrollable log must show its scrollbar.');
    Require(((GetWindowLong(LList.Handle, GWL_STYLE) and WS_HSCROLL) = 0) and
      (LList.ClientHeight = LClientHeight),
      'Hover/focus must not introduce an unused horizontal scrollbar.');
    Require(GetScrollPos(LList.Handle, SB_VERT) = LScrollPos,
      'Showing the scrollbar must preserve the scroll position.');
    LList.Perform(WM_KEYDOWN, VK_HOME, 0);
    Application.ProcessMessages;
    Require(LList.ItemIndex = 0, 'Keyboard navigation must remain intact.');
    LList.Perform(WM_VSCROLL, SB_LINEDOWN, 0);
    Require(GetScrollPos(LList.Handle, SB_VERT) > 0,
      'The native scrollbar must still scroll the list.');
    LScrollPos := GetScrollPos(LList.Handle, SB_VERT);
    LList.Perform(WM_MOUSEWHEEL, MakeWParam(0, WHEEL_DELTA), 0);
    Application.ProcessMessages;
    Require(GetScrollPos(LList.Handle, SB_VERT) < LScrollPos,
      'Mouse-wheel scrolling must remain intact.');
    LLog.SearchFilterBox.SetFocus;
    LLog.Height := 200;
    LLog.Add('New entry while inactive');
    Application.ProcessMessages;
    Require((GetWindowLong(LList.Handle, GWL_STYLE) and WS_VSCROLL) = 0,
      'Resize and appending rows must not reveal an inactive scrollbar.');
    LLog.SearchFilterBox.Text := 'New entry while inactive';
    LList.SetFocus;
    Application.ProcessMessages;
    Require((LList.ItemCount = 1) and
      ((GetWindowLong(LList.Handle, GWL_STYLE) and WS_VSCROLL) = 0),
      'Focus must not show a scrollbar when the filtered content fits.');
    LLog.SearchFilterBox.Text := '';
    Application.ProcessMessages;
    Require((GetWindowLong(LList.Handle, GWL_STYLE) and WS_VSCROLL) <> 0,
      'Clearing the filter must restore a needed, focused scrollbar.');
  finally
    LHost.Free;
  end;
end;

procedure TestSettingsDialogLayout;
begin
  TSettings.SetSettingsFolderOverride(cTestResultsDirectory + '\settings-dialog');
  try
    var LResources := TDataModule1.Create(nil);
    try
      var LPreviousResources := DataModule1;
      DataModule1 := LResources;
      try
        var LForm := TFrmSettings.Create(nil);
        try
          LForm.Position := poDesigned;
          LForm.SetBounds(-32000, -32000, LForm.Width, LForm.Height);
          LForm.Show;
          for var LPPI in TArray<Integer>.Create(96, 120, 144) do
          begin
            LForm.ScaleForPPI(LPPI);
            Application.ProcessMessages;
            Require(LForm.pbCard.BoundsRect = LForm.pnContent.ClientRect,
              'Settings card must cover the actual scaled content panel.');
            Require(LForm.pnlAppearance.BoundsRect.Bottom <=
              LForm.pnContent.ClientHeight - LForm.pnContent.Padding.Bottom,
              'Theme list must leave room for the complete bottom card border.');
            for var LCheckBox in TArray<TCheckBox>.Create(
              LForm.cbRememberWindowPlacement, LForm.cbRestorePreviousSession) do
            begin
              Require((LCheckBox.StyleName = '') and
                not (seFont in LCheckBox.StyleElements) and
                (LCheckBox.Font.Color = TExplorerTheme.ActiveTheme.TextColor),
                'Settings checkboxes must use the app style and explicit theme text color.');
              LCheckBox.Checked := False;
              LCheckBox.Perform(BM_CLICK, 0, 0);
              Require(LCheckBox.Checked, 'Themed checkboxes must remain interactive.');
            end;
          end;
        finally
          LForm.Free;
        end;
      finally
        DataModule1 := LPreviousResources;
      end;
    finally
      LResources.Free;
    end;
  finally
    TSettings.SetSettingsFolderOverride('');
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
    LSettings.RememberWindowPlacement := True;
    LSettings.RestorePreviousSession := True;
    LSettings.SetWindowBounds(Rect(120, 80, 1320, 880));
    LSettings.ClearLastSessionFiles;
    LSettings.AddLastSessionFile(LFirstFile);
    LSettings.AddLastSessionFile(LSecondFile);
    LSettings.LastSessionActiveIndex := 1;
    LSettings.Save;

    LSettings.ClearRecentItems;
    LSettings.TDumpPath := '';
    LSettings.ThemeOption := toLight;
    LSettings.ShowLogPanel := True;
    LSettings.ShowRawPanel := False;
    LSettings.FollowRawSelection := True;
    LSettings.RememberWindowPlacement := False;
    LSettings.RestorePreviousSession := False;
    LSettings.ClearWindowBounds;
    LSettings.ClearLastSessionFiles;
    LSettings.Load;
    Require((LSettings.RecentItemCount = 2) and
      SameText(LSettings.RecentItem(0), ExpandFileName(LFirstFile)) and
      SameText(LSettings.RecentItem(1), ExpandFileName(LSecondFile)) and
      SameText(LSettings.TDumpPath, TPath.Combine(LFolder, 'tdump.exe')) and
      (LSettings.ThemeOption = toDark) and not LSettings.ShowLogPanel and
      LSettings.ShowRawPanel and not LSettings.FollowRawSelection and
      LSettings.RememberWindowPlacement and LSettings.RestorePreviousSession and
      LSettings.HasWindowBounds and (LSettings.WindowBounds.Left = 120) and
      (LSettings.WindowBounds.Top = 80) and (LSettings.WindowBounds.Width = 1200) and
      (LSettings.WindowBounds.Height = 800) and
      (LSettings.LastSessionFileCount = 2) and
      SameText(LSettings.LastSessionFile(0), ExpandFileName(LFirstFile)) and
      SameText(LSettings.LastSessionFile(1), ExpandFileName(LSecondFile)) and
      (LSettings.LastSessionActiveIndex = 1),
      'Settings must persist MRU ordering, workspace options, window placement, and session tabs.');
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

procedure TExplorerComponentFixture.HighlighterSortGlyphPlacement;
begin
  TestHighlighterSortGlyphPlacement;
end;

procedure TExplorerComponentFixture.LogFilteringNavigation;
begin
  TestLogFilteringNavigation;
end;

procedure TExplorerComponentFixture.DocumentIconClassification;
begin
  for var LFileName in TArray<string>.Create('report.tdump', 'report.TDUMP',
    'C:\reports\module.bpl.tdump', 'report.TxT') do
    Require(ExplorerDocumentIconName(LFileName) = 'file-text',
      'Report inputs must share the file-text icon in tabs, headers and MRU.');
  for var LFileName in TArray<string>.Create('app.exe', 'library.dll',
    'package.bpl', 'unit.dcu', 'module.obj', 'library.so', '') do
    Require(ExplorerDocumentIconName(LFileName) = 'binary',
      'Binary inputs and pending documents must share the binary icon.');
end;

procedure TExplorerComponentFixture.RecordItemIcon(Sender: TObject;
  AIndex: Integer; ACanvas: TCanvas; const ARect: TRect; AColor: TColor);
begin
  Inc(FIconDrawCount);
  FIconRect := ARect;
  FIconColor := AColor;
  DrawExplorerDocumentIcon(ACanvas, 'report.tdump', ARect, AColor);
end;

procedure TExplorerComponentFixture.HighlighterCustomIcons;
begin
  var LHost := TComponentTestHostForm.Create(nil);
  try
    LHost.SetBounds(-32000, -32000, 640, 480);
    LHost.Show;
    var LControl := LHost.HighlighterControl;
    LControl.UseColumnMode := False;
    LControl.ShowLineNumbers := False;
    LControl.OnDrawItemIcon := RecordItemIcon;
    LControl.CustomIconSize := 24;
    LControl.Add('Report', 'file-text');
    LControl.Add('No icon');
    var LBitmap := TBitmap.Create;
    try
      for var LPPI in TArray<Integer>.Create(96, 120, 144) do
      begin
        LHost.ScaleForPPI(LPPI);
        Application.ProcessMessages;
        var LRowRect := Rect(0, 0, 500, MulDiv(32, LPPI, 96));
        LBitmap.SetSize(LRowRect.Width, LRowRect.Height);
        var LExpectedSize := MulDiv(24, LPPI, 96);
        Require(LControl.ItemIconWidth(0) = LExpectedSize,
          'Custom icon measurement must scale the 24-pixel design size once.');
        Require(LControl.ItemIconWidth(1) = 0,
          'A row without an icon must not reserve an icon gutter.');
        LControl.SetInactiveItems([]);
        FIconDrawCount := 0;
        LControl.ControlList1.OnBeforeDrawItem(0, LBitmap.Canvas, LRowRect, []);
        Require(LBitmap.Canvas.Font.Height = LControl.Font.Height,
          'Row painting must preserve the same scaled font height used for measurement.');
        Require((FIconDrawCount = 1) and
          (FIconRect.Width = LExpectedSize) and
          (FIconRect.Height = LExpectedSize) and
          (FIconRect.Top = (LRowRect.Height - LExpectedSize) div 2),
          'Custom icons must be square, DPI-scaled and vertically centered.');
        Require(FIconColor = TExplorerTheme.ActiveTheme.TextColor,
          'Normal icons must use the active theme text color.');
        LControl.SetInactiveItems([0]);
        LControl.ControlList1.OnBeforeDrawItem(0, LBitmap.Canvas, LRowRect, []);
        Require(FIconColor = TExplorerTheme.ActiveTheme.InactiveText,
          'Unavailable files must use the inactive icon color.');
        LControl.ControlList1.OnBeforeDrawItem(0, LBitmap.Canvas, LRowRect,
          [odSelected]);
        Require(FIconColor = TExplorerTheme.ActiveTheme.SelectionColor,
          'Selection color must apply to icons, including unavailable files.');
        FIconDrawCount := 0;
        LControl.ControlList1.OnBeforeDrawItem(1, LBitmap.Canvas, LRowRect, []);
        Require(FIconDrawCount = 0,
          'Rows without icons must not invoke the custom renderer.');
      end;
      LControl.OnDrawItemIcon := nil;
      Require(LControl.ItemIconWidth(0) = 0,
        'Without a renderer or image list, the icon gutter must remain empty.');
    finally
      LBitmap.Free;
    end;
  finally
    LHost.Free;
  end;
end;

function TExplorerComponentFixture.ItemTrailingText(AIndex: Integer): string;
begin
  if AIndex in [0, 1] then
    Result := 'Alt+1'
  else
    Result := '';
end;

procedure TExplorerComponentFixture.HighlighterTrailingText;
begin
  var LHost := TComponentTestHostForm.Create(nil);
  try
    LHost.SetBounds(-32000, -32000, 640, 480);
    LHost.Show;
    var LControl := LHost.HighlighterControl;
    LControl.UseColumnMode := False;
    LControl.ShowLineNumbers := False;
    LControl.Add(StringOfChar('W', 200));
    LControl.Add('');
    LControl.Add('No shortcut');
    LControl.OnGetItemTrailingText := ItemTrailingText;
    var LPathBitmap := TBitmap.Create;
    try
      var LEmptyBitmap := TBitmap.Create;
      try
        for var LPPI in TArray<Integer>.Create(96, 120, 144, 192) do
        begin
          LHost.ScaleForPPI(LPPI);
          Application.ProcessMessages;
          var LRowRect := Rect(0, 0, MulDiv(320, LPPI, 96), MulDiv(32, LPPI, 96));
          LPathBitmap.SetSize(LRowRect.Width, LRowRect.Height);
          LEmptyBitmap.SetSize(LRowRect.Width, LRowRect.Height);
          LPathBitmap.Canvas.Font.Assign(LControl.Font);
          var LTextWidth := LPathBitmap.Canvas.TextWidth('Alt+1');
          Require(LControl.ItemTrailingTextWidth(0) = LTextWidth + MulDiv(24, LPPI, 96),
            'Shortcut measurement must include its scaled font and gap.');
          Require((LControl.ItemTrailingTextWidth(2) = 0) and
            (LControl.ItemTrailingTextWidth(-1) = 0) and
            (LControl.ItemTrailingTextWidth(3) = 0),
            'Empty and invalid rows must not reserve shortcut space.');
          for var LInactive in TArray<Boolean>.Create(False, True) do
          begin
            if LInactive then
              LControl.SetInactiveItems([0, 1])
            else
              LControl.SetInactiveItems([]);
            for var LSelected in TArray<Boolean>.Create(False, True) do
            begin
              for var LBitmap in TArray<TBitmap>.Create(LPathBitmap, LEmptyBitmap) do
              begin
                LBitmap.Canvas.Brush.Style := bsSolid;
                LBitmap.Canvas.Brush.Color := TExplorerTheme.ActiveTheme.BackgroundColor;
                LBitmap.Canvas.FillRect(LRowRect);
              end;
              var LState: TOwnerDrawState := [];
              if LSelected then
                Include(LState, odSelected);
              LControl.ControlList1.OnBeforeDrawItem(0, LPathBitmap.Canvas, LRowRect, LState);
              LControl.ControlList1.OnBeforeDrawItem(1, LEmptyBitmap.Canvas, LRowRect, LState);
              var LTextLeft := LRowRect.Right - 8 - LTextWidth;
              var LHasTextPixels := False;
              for var LX := LTextLeft - MulDiv(12, LPPI, 96) to LRowRect.Right - 9 do
                for var LY := 2 to LRowRect.Bottom - 3 do
                begin
                  Require(LPathBitmap.Canvas.Pixels[LX, LY] = LEmptyBitmap.Canvas.Pixels[LX, LY],
                    'Long paths must not overlap or move the right-aligned shortcut.');
                  if (LX >= LTextLeft) and (LPathBitmap.Canvas.Pixels[LX, LY] <>
                    ColorToRGB(TExplorerTheme.ActiveTheme.BackgroundColor)) then
                    LHasTextPixels := True;
                end;
              Require(LHasTextPixels, 'The right-aligned shortcut must be painted.');
              Require((LPathBitmap.Canvas.Brush.Style = bsSolid) and
                (LEmptyBitmap.Canvas.Brush.Style = bsSolid),
                'Shortcut painting must restore the brush for all row states.');
            end;
          end;
        end;
        LControl.OnGetItemTrailingText := nil;
        Require(LControl.ItemTrailingTextWidth(0) = 0,
          'Existing highlighters without annotations must retain the full row width.');
      finally
        LEmptyBitmap.Free;
      end;
    finally
      LPathBitmap.Free;
    end;
  finally
    LHost.Free;
  end;
end;

procedure TExplorerComponentFixture.HighlighterFontDpi;
begin
  var LHost := TComponentTestHostForm.Create(nil);
  try
    LHost.SetBounds(-32000, -32000, 1200, 600);
    LHost.Show;
    var LControl := LHost.HighlighterControl;
    LControl.SetColumnHeaders(['Long header caption', 'Value']);
    LControl.AddColumns(['Sample text', '1']);
    var LBitmap := TBitmap.Create;
    try
      for var LPPI in TArray<Integer>.Create(96, 120, 144, 192, 144, 120, 96) do
      begin
        LHost.ScaleForPPI(LPPI);
        Application.ProcessMessages;
        for var LFontName in TArray<string>.Create('Consolas', 'Segoe UI') do
        begin
          SetExplorerFont(LControl, LFontName, 9);
          SetExplorerFont(LControl, LFontName, 9);
          Require((LControl.Font.Height = -MulDiv(12, LPPI, 96)) and
            (LControl.Font.PixelsPerInch = LPPI),
            'Runtime font setup must be DPI-correct and idempotent.');
          LBitmap.Canvas.Font.Assign(LControl.HeaderControl1.Font);
          Require(LControl.HeaderControl1.Sections[0].Width >=
            LBitmap.Canvas.TextWidth('Long header caption') + 16 + MulDiv(18, LPPI, 96),
            'Column measurements must refresh after font and DPI changes.');
          LBitmap.SetSize(500, LControl.ControlList1.ItemHeight);
          LBitmap.Canvas.Font.PixelsPerInch := 96;
          LBitmap.Canvas.Font.Height := -12;
          LControl.ControlList1.OnBeforeDrawItem(0, LBitmap.Canvas,
            Rect(0, 0, LBitmap.Width, LBitmap.Height), []);
          Require(LBitmap.Canvas.Font.Height = LControl.Font.Height,
            'Highlighter painting must use the scaled control font.');
          Require(LBitmap.Canvas.TextHeight('Ag') <= LControl.ControlList1.ItemHeight,
            'Highlighter rows must contain the scaled text.');
        end;
      end;
      LControl.SetViewLayoutId('dpi-widths');
      LControl.HeaderControl1.Sections[0].Width := 240;
      LControl.HeaderControl1.OnSectionResize(LControl.HeaderControl1,
        LControl.HeaderControl1.Sections[0]);
      LHost.ScaleForPPI(192);
      Require(LControl.HeaderControl1.Sections[0].Width = 480,
        'User-sized columns must scale with the font.');
      LControl.SetViewLayoutId('other-view');
      LControl.SetViewLayoutId('dpi-widths');
      Require(LControl.HeaderControl1.Sections[0].Width = 480,
        'Cached column layouts must retain the new DPI.');
    finally
      LBitmap.Free;
    end;
  finally
    LHost.Free;
  end;
end;

procedure TExplorerComponentFixture.LogFontDpi;
begin
  var LHost := TComponentTestHostForm.Create(nil);
  try
    LHost.SetBounds(-32000, -32000, 1200, 600);
    LHost.Show;
    var LLog := LHost.LogControl;
    LLog.Add('DPI font regression', letSuccess);
    var LBadge := TExplorerBadgeLabel(LLog.FindComponent('FilterCountBadge'));
    var LBitmap := TBitmap.Create;
    try
      for var LPPI in TArray<Integer>.Create(96, 120, 144, 192, 144, 120, 96) do
      begin
        LHost.ScaleForPPI(LPPI);
        Application.ProcessMessages;
        LLog.ApplyTheme;
        Require(LLog.SearchFilterBox.Font.Height = -MulDiv(12, LPPI, 96),
          'Search font must follow layout DPI after theme refresh.');
        Require((LBadge.Font.Height = LLog.SearchFilterBox.Font.Height) and
          (LLog.Label1.Font.Height = -MulDiv(13, LPPI, 96)),
          'Log badge and title must not accumulate DPI rounding.');
        LBitmap.SetSize(1000, LLog.ControlList1.ItemHeight);
        LBitmap.Canvas.Font.PixelsPerInch := 96;
        LBitmap.Canvas.Font.Height := -12;
        LLog.ControlList1BeforeDrawItem(0, LBitmap.Canvas,
          Rect(0, 0, LBitmap.Width, LBitmap.Height), [odSelected]);
        Require(LBitmap.Canvas.Font.Height = LLog.ControlList1.Font.Height,
          'Log painting must copy the scaled font, not set canvas point size.');
        Require(LBitmap.Canvas.TextHeight('Ag') <= LLog.ControlList1.ItemHeight,
          'Log rows must contain the scaled text.');
        Require(LBitmap.Canvas.TextWidth('23:59:59.999') < MulDiv(92, LPPI, 96),
          'Timestamp column must have room for its scaled font.');
        Require(LBitmap.Canvas.Font.Color = TExplorerTheme.ActiveTheme.SelectionColor,
          'DPI fixes must preserve selected text colors.');
      end;
    finally
      LBitmap.Free;
    end;
  finally
    LHost.Free;
  end;
end;

procedure TExplorerComponentFixture.DialogFontDpi;
begin
  TSettings.SetSettingsFolderOverride(cTestResultsDirectory + '\font-dialog');
  try
    var LResources := TDataModule1.Create(nil);
    try
      var LPreviousResources := DataModule1;
      DataModule1 := LResources;
      try
        var LSettings := TFrmSettings.Create(nil);
        try
          var LAbout := TFrmAbout.Create(nil);
          try
            LSettings.Position := poDesigned;
            LAbout.Position := poDesigned;
            LSettings.SetBounds(-32000, -32000, LSettings.Width, LSettings.Height);
            LAbout.SetBounds(-32000, -32000, LAbout.Width, LAbout.Height);
            LSettings.Show;
            LAbout.Show;
            for var LPPI in TArray<Integer>.Create(96, 120, 144, 192, 144, 120, 96) do
            begin
              LSettings.ScaleForPPI(LPPI);
              LAbout.ScaleForPPI(LPPI);
              Application.ProcessMessages;
              Require(LAbout.TitleBarPanel1.Height > 0,
                'About title-bar painting must retain a nonempty client strip.');
              Require((LSettings.Font.Height = -MulDiv(12, LPPI, 96)) and
                (LAbout.Font.Height = LSettings.Font.Height),
                'Dialog body fonts must scale once.');
              Require((LSettings.lblGeneral.Font.Height = -MulDiv(13, LPPI, 96)) and
                (LAbout.lblProduct.Font.Height = -MulDiv(22, LPPI, 96)) and
                (LAbout.lblVersion.Font.Height = -MulDiv(15, LPPI, 96)),
                'Heading fonts must return to their original design heights.');
              Require((LSettings.edTDumpPath.Font.Height = LSettings.Font.Height) and
                (LSettings.cbRememberWindowPlacement.Font.Height = LSettings.Font.Height),
                'Settings inputs and checkboxes must match the body font.');
              var LClose := TSimpleUIButton(LAbout.FindComponent('btnClose'));
              var LSave := TSimpleUIButton(LSettings.FindComponent('btnSave'));
              Require((LClose.Font.Height = LAbout.Font.Height) and
                (LSave.Font.Height = LSettings.Font.Height),
                'Runtime buttons must inherit the scaled dialog font.');
            end;
          finally
            LAbout.Free;
          end;
        finally
          LSettings.Free;
        end;
      finally
        DataModule1 := LPreviousResources;
      end;
    finally
      LResources.Free;
    end;
  finally
    TSettings.SetSettingsFolderOverride('');
  end;
end;

procedure TExplorerComponentFixture.SettingsRoundTrip;
begin
  TestSettingsRoundTrip;
end;

procedure TExplorerComponentFixture.SplitterGripDrawing;
begin
  var LBitmap := TBitmap.Create;
  try
    var LBaseline := TBitmap.Create;
    try
      var LTheme := TExplorerTheme.ActiveTheme;
      for var LPPI in TArray<Integer>.Create(96, 120, 144) do
        for var LVertical in TArray<Boolean>.Create(False, True) do
        begin
          var LScale: Single := LPPI / 96;
          if LVertical then
            LBitmap.SetSize(MulDiv(12, LPPI, 96), MulDiv(200, LPPI, 96))
          else
            LBitmap.SetSize(MulDiv(200, LPPI, 96), MulDiv(12, LPPI, 96));
          var LBounds := Rect(0, 0, LBitmap.Width, LBitmap.Height);
          LBitmap.Canvas.Brush.Color := LTheme.BackgroundColor;
          LBitmap.Canvas.FillRect(LBounds);
          LBaseline.Assign(LBitmap);
          DrawFadedSplitterLine(LBaseline.Canvas, LBounds, LVertical,
            LTheme.GhostColor, LScale);
          DrawExplorerSplitter(LBitmap.Canvas, LBounds, LVertical, LScale);
          var LChangedPixels := 0;
          var LCenter := LBounds.CenterPoint;
          for var LY := 0 to LBitmap.Height - 1 do
            for var LX := 0 to LBitmap.Width - 1 do
              if LBitmap.Canvas.Pixels[LX, LY] <> LBaseline.Canvas.Pixels[LX, LY] then
              begin
                Inc(LChangedPixels);
                var LDistance := if LVertical then Abs(LY - LCenter.Y)
                  else Abs(LX - LCenter.X);
                Require(LDistance <= MulDiv(26, LPPI, 96),
                  'The rounded grip must remain centered within its scaled 48-pixel span.');
              end;
          Require(LChangedPixels > 24,
            'Both splitter orientations must show a grip, not just the old line.');
          Require(ColorToRGB(LBitmap.Canvas.Pixels[0, 0]) =
            ColorToRGB(LTheme.BackgroundColor),
            'The grip must leave room around the splitter edges.');
        end;
      DrawExplorerSplitter(LBitmap.Canvas, Rect(0, 0, 0, 0), False, 1);
      DrawExplorerSplitter(LBitmap.Canvas, Rect(0, 0, 2, 8), True, 1);
    finally
      LBaseline.Free;
    end;
  finally
    LBitmap.Free;
  end;
end;

procedure TExplorerComponentFixture.BadgeMeasurementBeforeParenting;
begin
  TestBadgeMeasurementBeforeParenting;
end;

procedure TExplorerComponentFixture.SplitterHoverPolicy;
begin
  var LSplitter := TSplitter.Create(nil);
  try
    var LStyle := TExplorerSplitterStyle.Create(LSplitter);
    Require(LSplitter.ResizeStyle = rsNone,
      'Splitter must disable XOR while retaining native release-to-resize.');
    Require(not LStyle.Hot, 'Splitter must start in the neutral state.');
    LSplitter.Perform(CM_MOUSEENTER, 0, 0);
    Require(LStyle.Hot, 'Mouse enter must activate the accent palette.');
    LSplitter.Perform(CM_MOUSELEAVE, 0, 0);
    Require(not LStyle.Hot, 'Mouse leave must restore the neutral palette.');
    var LBitmap := TBitmap.Create;
    try
      LBitmap.SetSize(120, 12);
      var LBounds := Rect(0, 0, LBitmap.Width, LBitmap.Height);
      DrawExplorerSplitter(LBitmap.Canvas, LBounds, False, 1, False);
      // Sample a dot's interior, where the idle palette is explicitly gray.
      var LIdle := ColorToRGB(LBitmap.Canvas.Pixels[57, 5]);
      Require((GetRValue(LIdle) = GetGValue(LIdle)) and
        (GetGValue(LIdle) = GetBValue(LIdle)),
        'Idle splitter dots must be grayscale.');
      DrawExplorerSplitter(LBitmap.Canvas, LBounds, False, 1, True);
      Require(ColorToRGB(LBitmap.Canvas.Pixels[57, 5]) <> LIdle,
        'Hover must visibly change the grip to the active theme accent.');
    finally
      LBitmap.Free;
    end;
  finally
    LSplitter.Free;
  end;
end;

procedure TExplorerComponentFixture.SplitterLineGradient;

  function Contrast(AColor, ABackground: TColor): Integer;
  begin
    var LColor := ColorToRGB(AColor);
    var LBackground := ColorToRGB(ABackground);
    Result := Abs(Integer(GetRValue(LColor)) - Integer(GetRValue(LBackground))) +
      Abs(Integer(GetGValue(LColor)) - Integer(GetGValue(LBackground))) +
      Abs(Integer(GetBValue(LColor)) - Integer(GetBValue(LBackground)));
  end;

  function LinePixel(ABitmap: TBitmap; const ABounds: TRect;
    AVertical: Boolean; AOffset: Integer): TColor;
  begin
    var LPoint := ABounds.CenterPoint;
    if AVertical then
      LPoint.Y := ABounds.Top + AOffset
    else
      LPoint.X := ABounds.Left + AOffset;
    Result := ABitmap.Canvas.Pixels[LPoint.X, LPoint.Y];
  end;

begin
  var LBitmap := TBitmap.Create;
  try
    var LReference := TBitmap.Create;
    try
      var LTheme := TExplorerTheme.ActiveTheme;
      for var LPPI in TArray<Integer>.Create(96, 120, 144) do
        for var LVertical in TArray<Boolean>.Create(False, True) do
          for var LHot in TArray<Boolean>.Create(False, True) do
          begin
            var LScale: Single := LPPI / 96;
            var LSpan := MulDiv(400, LPPI, 96);
            var LThickness := MulDiv(12, LPPI, 96);
            var LBounds := Rect(7, 11, 7 + LSpan, 11 + LThickness);
            if LVertical then
              LBounds := Rect(7, 11, 7 + LThickness, 11 + LSpan);
            LBitmap.SetSize(LBounds.Right + 7, LBounds.Bottom + 11);
            LBitmap.Canvas.Brush.Color := LTheme.BackgroundColor;
            LBitmap.Canvas.FillRect(Rect(0, 0, LBitmap.Width, LBitmap.Height));
            LReference.Assign(LBitmap);
            DrawExplorerSplitter(LBitmap.Canvas, LBounds, LVertical, LScale, LHot);
            var LColor := if LHot then LTheme.SelectionColor else LTheme.GhostColor;
            DrawFadedSplitterLine(LReference.Canvas, LBounds, LVertical, LColor, LScale);
            var LOpaqueOffset := MulDiv(80, LPPI, 96);
            Require(LinePixel(LBitmap, LBounds, LVertical, LOpaqueOffset) =
              LinePixel(LReference, LBounds, LVertical, LOpaqueOffset),
              'The whole hovered splitter line must use SelectionColor.');
            var LOpaqueContrast := Contrast(LinePixel(LBitmap, LBounds,
              LVertical, LOpaqueOffset), LTheme.BackgroundColor);
            Require(LOpaqueContrast > 10, 'The middle splitter line must remain visible.');
            for var LFromEnd in TArray<Boolean>.Create(False, True) do
            begin
              var LEdge := 0;
              var LFadeMid := MulDiv(32, LPPI, 96);
              if LFromEnd then
              begin
                LEdge := LSpan - 1;
                LFadeMid := LSpan - 1 - LFadeMid;
              end;
              var LEdgeContrast := Contrast(LinePixel(LBitmap, LBounds,
                LVertical, LEdge), LTheme.BackgroundColor);
              var LMidContrast := Contrast(LinePixel(LBitmap, LBounds,
                LVertical, LFadeMid), LTheme.BackgroundColor);
              Require((LEdgeContrast < LMidContrast) and
                (LMidContrast < LOpaqueContrast div 2),
                'Each line end must blend through the tab baseline low-alpha stop.');
            end;
          end;
    finally
      LReference.Free;
    end;
  finally
    LBitmap.Free;
  end;
end;

procedure TExplorerComponentFixture.CheckResizeEvent(Sender: TObject;
  var NewSize: Integer; var Accept: Boolean);
begin
  Inc(FResizeCalls);
  Accept := not FRejectResize;
end;

procedure TExplorerComponentFixture.CheckMovedEvent(Sender: TObject);
begin
  Inc(FMovedCalls);
end;

procedure TExplorerComponentFixture.SplitterDragGuide;
var
  LStage: string;

  function Guide(AStyle: TExplorerSplitterStyle): TCustomForm;
  begin
    Result := nil;
    for var LIndex := 0 to AStyle.ComponentCount - 1 do
      if AStyle.Components[LIndex] is TCustomForm then
        Exit(TCustomForm(AStyle.Components[LIndex]));
    Require(False, 'Guide missing during ' + LStage);
  end;

  procedure DragMessage(ASplitter: TSplitter; AMessage: Cardinal; ADelta: Integer);
  begin
    var LPoint := ASplitter.ClientRect.CenterPoint;
    case ASplitter.Align of
      alLeft: Inc(LPoint.X, ADelta);
      alRight: Dec(LPoint.X, ADelta);
      alTop: Inc(LPoint.Y, ADelta);
      alBottom: Dec(LPoint.Y, ADelta);
    end;
    ASplitter.Perform(AMessage, if AMessage = WM_LBUTTONUP then 0 else MK_LBUTTON,
      MakeLParam(LPoint.X, LPoint.Y));
  end;

begin
  for var LPPI in TArray<Integer>.Create(96, 120, 144) do
    for var LAlign in TArray<TAlign>.Create(alLeft, alRight, alTop, alBottom) do
    begin
      var LHost := TForm.CreateNew(nil);
      try
        LStage := Format('start, DPI %d, alignment %d', [LPPI, Ord(LAlign)]);
        LHost.SetBounds(100, 100, 640, 500);
        var LPane := TPanel.Create(LHost);
        LPane.Parent := LHost;
        LPane.SetBounds(0, 0, 120, 120);
        LPane.Align := LAlign;
        var LSplitter := TSplitter.Create(LHost);
        LSplitter.Parent := LHost;
        LSplitter.Align := LAlign;
        LSplitter.SetBounds(0, 0, 12, 12);
        case LAlign of
          alLeft: LSplitter.Left := LPane.BoundsRect.Right;
          alRight: LSplitter.Left := LPane.Left - LSplitter.Width;
          alTop: LSplitter.Top := LPane.BoundsRect.Bottom;
          alBottom: LSplitter.Top := LPane.Top - LSplitter.Height;
        end;
        var LEdit := TEdit.Create(LHost);
        LEdit.Parent := LPane;
        LEdit.SetBounds(8, 8, 100, 24);
        LSplitter.OnCanResize := CheckResizeEvent;
        LSplitter.OnMoved := CheckMovedEvent;
        var LStyle := TExplorerSplitterStyle.Create(LSplitter);
        LHost.Show;
        LHost.ScaleForPPI(LPPI);
        LEdit.SetFocus;
        FRejectResize := False;
        FResizeCalls := 0;
        FMovedCalls := 0;
        var LVertical := LAlign in [alLeft, alRight];
        var LBounds := LPane.BoundsRect;
        var LFocus := GetFocus;
        DragMessage(LSplitter, WM_LBUTTONDOWN, 0);
        Require(LStyle.Dragging and (LSplitter.Control = LPane),
          'Guide must start on the native adjacent pane for each alignment.');
        DragMessage(LSplitter, WM_MOUSEMOVE, 20);
        Require(LPane.BoundsRect = LBounds, 'Preview must not resize before release.');
        Require(GetFocus = LFocus, 'The guide must not take keyboard focus.');
        var LGuide := Guide(LStyle);
        Require((LGuide <> nil) and IsWindowVisible(LGuide.Handle), 'Guide must be visible.');
        var LGuideHandle := LGuide.Handle;
        Require((if LVertical then LGuide.Width else LGuide.Height) =
          Max(2, Round(3 * LSplitter.ScaleFactor)), 'Guide width must scale once from 3 design pixels.');
        DragMessage(LSplitter, WM_LBUTTONUP, 20);
        Require((if LVertical then LPane.Width = LBounds.Width + 20 else
          LPane.Height = LBounds.Height + 20), 'Release must commit the accepted size.');
        Require(not LStyle.Dragging and not IsWindow(LGuideHandle),
          'Release must destroy the guide.');
        Require((FResizeCalls > 0) and (FMovedCalls > 0), 'Original callbacks must still run.');
        LBounds := LPane.BoundsRect;
        // Native focused-control Escape invokes StopSizing and the shared cleanup.
        DragMessage(LSplitter, WM_LBUTTONDOWN, 0);
        DragMessage(LSplitter, WM_MOUSEMOVE, 15);
        LEdit.Perform(WM_KEYDOWN, VK_ESCAPE, 0);
        Require(not LStyle.Dragging and (LSplitter.Control = nil) and
          (LPane.BoundsRect = LBounds) and (GetCaptureControl <> LSplitter),
          'Escape must cancel without resizing or retaining capture.');
        // Capture may transfer to another control; do not release its capture.
        DragMessage(LSplitter, WM_LBUTTONDOWN, 0);
        DragMessage(LSplitter, WM_MOUSEMOVE, 15);
        SetCapture(LEdit.Handle);
        Require(not LStyle.Dragging and (LSplitter.Control = nil) and
          (LPane.BoundsRect = LBounds) and (GetCapture = LEdit.Handle),
          'Capture loss must cancel and preserve the new capture owner.');
        ReleaseCapture;
        DragMessage(LSplitter, WM_LBUTTONDOWN, 0);
        DragMessage(LSplitter, WM_MOUSEMOVE, 15);
        LHost.Perform(WM_CANCELMODE, 0, 0);
        Require(not LStyle.Dragging and (LPane.BoundsRect = LBounds),
          'Cancel mode must not accidentally commit a resize.');
        FRejectResize := True;
        LStage := Format('veto, DPI %d, alignment %d', [LPPI, Ord(LAlign)]);
        DragMessage(LSplitter, WM_LBUTTONDOWN, 0);
        var LOriginalGuide := Guide(LStyle).BoundsRect;
        DragMessage(LSplitter, WM_MOUSEMOVE, 40);
        Require(Guide(LStyle).BoundsRect = LOriginalGuide, 'A vetoed size must not move the guide.');
        DragMessage(LSplitter, WM_LBUTTONUP, 40);
        Require(LPane.BoundsRect = LBounds, 'OnCanResize veto must be respected.');
        FRejectResize := False;
        var LMaximum := (if LVertical then LPane.Width else LPane.Height) + 30;
        LStage := Format('constraints, DPI %d, alignment %d', [LPPI, Ord(LAlign)]);
        if LVertical then LPane.Constraints.MaxWidth := LMaximum
        else LPane.Constraints.MaxHeight := LMaximum;
        DragMessage(LSplitter, WM_LBUTTONDOWN, 0);
        DragMessage(LSplitter, WM_MOUSEMOVE, 200);
        var LExpectedPoint := LSplitter.ClientToScreen(LSplitter.ClientRect.CenterPoint);
        case LAlign of
          alLeft: Inc(LExpectedPoint.X, 30);
          alRight: Dec(LExpectedPoint.X, 30);
          alTop: Inc(LExpectedPoint.Y, 30);
          alBottom: Dec(LExpectedPoint.Y, 30);
        end;
        var LGuidePoint := Guide(LStyle).BoundsRect.CenterPoint;
        Require((if LVertical then LGuidePoint.X = LExpectedPoint.X else
          LGuidePoint.Y = LExpectedPoint.Y), 'Guide must honor target size constraints.');
        DragMessage(LSplitter, WM_LBUTTONUP, 200);
        Require((if LVertical then LPane.Width else LPane.Height) = LMaximum,
          'Committed size must match the constrained guide.');
        LStage := Format('minimum/snap, DPI %d, alignment %d', [LPPI, Ord(LAlign)]);
        if LVertical then LPane.Constraints.MinWidth := 20
        else LPane.Constraints.MinHeight := 20;
        DragMessage(LSplitter, WM_LBUTTONDOWN, 0);
        DragMessage(LSplitter, WM_MOUSEMOVE, -1000);
        LGuidePoint := Guide(LStyle).BoundsRect.CenterPoint;
        Require(LSplitter.AutoSnap, 'Temporary snap suppression must be restored after movement.');
        DragMessage(LSplitter, WM_LBUTTONUP, -1000);
        LExpectedPoint := LSplitter.ClientToScreen(LSplitter.ClientRect.CenterPoint);
        Require(((if LVertical then LPane.Width else LPane.Height) = 20) and
          (if LVertical then LGuidePoint.X = LExpectedPoint.X else
            LGuidePoint.Y = LExpectedPoint.Y),
          'A nonzero target minimum must match both guide and committed edge.');
        if LVertical then LPane.Constraints.MinWidth := 0
        else LPane.Constraints.MinHeight := 0;
        DragMessage(LSplitter, WM_LBUTTONDOWN, 0);
        DragMessage(LSplitter, WM_MOUSEMOVE, -1000);
        DragMessage(LSplitter, WM_LBUTTONUP, -1000);
        Require((if LVertical then LPane.Width else LPane.Height) = 0,
          'AutoSnap must still collapse a pane when its constraints allow zero.');
        // Re-expand only to exercise teardown, not another resize commit.
        if LVertical then LPane.Width := 120 else LPane.Height := 120;
        // Teardown during a drag must restore the borrowed splitter state.
        LStage := Format('teardown, DPI %d, alignment %d', [LPPI, Ord(LAlign)]);
        DragMessage(LSplitter, WM_LBUTTONDOWN, 0);
        LGuideHandle := Guide(LStyle).Handle;
        LStyle.Free;
        Require((LSplitter.ResizeStyle = rsPattern) and (LSplitter.Control = nil) and
          not IsWindow(LGuideHandle), 'Helper destruction must restore state and remove its guide.');
        LStage := Format('target destruction, DPI %d, alignment %d', [LPPI, Ord(LAlign)]);
        LStyle := TExplorerSplitterStyle.Create(LSplitter);
        DragMessage(LSplitter, WM_LBUTTONDOWN, 0);
        LGuideHandle := Guide(LStyle).Handle;
        LPane.Free;
        Require(not LStyle.Dragging and (LSplitter.Control = nil) and
          not IsWindow(LGuideHandle), 'Destroying the target must cancel and clean up its guide.');
      finally
        LHost.Free;
      end;
    end;
end;

procedure TExplorerComponentFixture.RoundedLogLayout;
begin
  TestRoundedLogLayout;
end;

procedure TExplorerComponentFixture.FocusScrollBarVisibility;
begin
  TestFocusScrollBarVisibility;
end;

procedure TExplorerComponentFixture.SettingsDialogLayout;
begin
  TestSettingsDialogLayout;
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
