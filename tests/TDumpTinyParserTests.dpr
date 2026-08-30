program TDumpTinyParserTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Types,
  Vcl.Graphics,
  DUnitX.TestFramework,
  DUnitX.Loggers.Xml.NUnit,
  TDump.Explorer.UI in '..\source\common\TDump.Explorer.UI.pas',
  TDump.Explorer.TinyParser in '..\source\common\TDump.Explorer.TinyParser.pas',
  TDump.Explorer.Highlighter in '..\source\common\TDump.Explorer.Highlighter.pas';

const
  CTestResultsDirectory = 'C:\dev\TDump-Explorer\tests\test-results';
  CTestResultsFile = CTestResultsDirectory + '\TDumpTinyParserTests.nunit.xml';

type
  [TestFixture]
  TTinyParserFixture = class
  public
    [Test] procedure TDumpValueTokenization;
    [Test] procedure HighlightThemes;
    [Test] procedure CppBuilderMethodTokenization;
    [Test] procedure TextFormatDrawing;
  end;

procedure Require(ACondition: Boolean; const AMessage: string);
begin
  Assert.IsTrue(ACondition, AMessage);
end;

function HasToken(const ATokens: TTinyTokenList; AKind: TTinyTokenKind;
  const AText: string): Boolean;
begin
  for var LToken in ATokens do
    if (LToken.Kind = AKind) and (LToken.Text = AText) then
      Exit(True);
  Result := False;
end;

procedure TestTDumpValueTokenization;
const
  CText = 'Name="Turbo Dump" Hex=0x1A2B Legacy=BAF4C9h Magic=CAFEBABE ' +
    'Count=-42 Ratio=3.1415 Date=2026-08-23 Time=23:59:59.123 ' +
    'Stamp=2026-08-23T23:59:59.123 Path=C:\temp Mode=32bit RVA=00002010';
begin
  var LParser := TTinyParser.Create;
  try
    var LTokens := LParser.Tokenize(CText);
    try
      Require(HasToken(LTokens, ttkStringLiteral, '"Turbo Dump"'),
        'Double-quoted TDUMP text must be classified as a string literal.');
      var LSingleQuoteTokens := LParser.Tokenize('Linker name: ''@Unit@Method$qqrv''');
      try
        Require(HasToken(LSingleQuoteTokens, ttkStringLiteral,
          '''@Unit@Method$qqrv'''),
          'Single-quoted TDUMP text must be classified as a string literal.');
      finally
        LSingleQuoteTokens.Free;
      end;
      Require(HasToken(LTokens, ttkString, 'C'),
        'A path drive letter must remain a string rather than bare hexadecimal.');
      Require(HasToken(LTokens, ttkHexadecimal, '0x1A2B'),
        '0x-prefixed values must be hexadecimal tokens.');
      Require(HasToken(LTokens, ttkHexadecimal, 'BAF4C9h'),
        'TDUMP H-suffixed values must be hexadecimal tokens.');
      Require(HasToken(LTokens, ttkHexadecimal, 'CAFEBABE'),
        'Bare TDUMP hexadecimal values must be hexadecimal tokens.');
      Require(HasToken(LTokens, ttkHexadecimal, '00002010'),
        'Zero-padded TDUMP RVAs must be hexadecimal tokens.');
      Require(HasToken(LTokens, ttkInteger, '-42'),
        'Signed whole numbers must be integer tokens.');
      Require(HasToken(LTokens, ttkFloat, '3.1415'),
        'Decimal fractions must be float tokens.');
      Require(HasToken(LTokens, ttkDate, '2026-08-23'),
        'ISO dates must be date tokens.');
      Require(HasToken(LTokens, ttkTime, '23:59:59.123'),
        'Times with milliseconds must be time tokens.');
      Require(HasToken(LTokens, ttkDateTime, '2026-08-23T23:59:59.123'),
        'ISO timestamps must be datetime tokens.');
      Require(HasToken(LTokens, ttkString, '32bit'),
        'Digit-leading TDUMP words must remain text tokens.');
      Require(not HasToken(LTokens, ttkInteger, '32'),
        'The numeric prefix of a digit-leading word must not be highlighted.');
      Require(HasToken(LTokens, ttkSymbol, '='),
        'TDUMP separators must be symbol tokens.');
    finally
      LTokens.Free;
    end;
  finally
    LParser.Free;
  end;
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

procedure TestCppBuilderMethodTokenization;
const
  CMethod = 'System::__linkproc__ __fastcall PackageLoad(' +
    'System::PackageInfoTable * const, System::TLibModule *)';
begin
  var LParser := TTinyParser.Create;
  try
    var LTokens := LParser.Tokenize(CMethod, tpmCppBuilderMethod);
    try
      Require(HasToken(LTokens, ttkKeyword, '__fastcall'),
        'Calling conventions must be classified as method keywords.');
      Require(HasToken(LTokens, ttkNamespace, 'System'),
        'Qualified owners must be classified as namespaces.');
      Require(HasToken(LTokens, ttkMethodName, 'PackageLoad'),
        'Identifiers followed by parentheses must be classified as methods.');
      Require(HasToken(LTokens, ttkTypeName, 'PackageInfoTable'),
        'Qualified C++Builder parameter types must be classified as types.');
      Require(HasToken(LTokens, ttkTypeName, 'TLibModule'),
        'C++Builder T-prefixed classes must be classified as types.');
      Require(HasToken(LTokens, ttkKeyword, 'const'),
        'C++ type qualifiers must be classified as keywords.');
      var LBorlandMethodTokens := LParser.Tokenize(
        '@Sysinit@InterlockedExchange$qqsrii', tpmCppBuilderMethod);
      try
        Require(HasToken(LBorlandMethodTokens, ttkMethodName,
          'InterlockedExchange'),
          'Borland linker method names must be classified as methods.');
        Require(HasToken(LBorlandMethodTokens, ttkMangledSignature, '$qqsrii'),
          'Borland mangled signatures must have a stable token kind.');
      finally
        LBorlandMethodTokens.Free;
      end;
      var LBorlandSlashMethodTokens := LParser.Tokenize(
        '@Sysinit\@InterlockedExchange$qqsrii', tpmCppBuilderMethod);
      try
        Require(HasToken(LBorlandSlashMethodTokens, ttkMethodName,
          'InterlockedExchange'),
          'Borland linker names using \\@ must classify the method name.');
      finally
        LBorlandSlashMethodTokens.Free;
      end;
      for var LMode in [tpmTDumpValues, tpmCppBuilderMethod] do
      begin
        var LInitProcessTokens := LParser.Tokenize(
          '@Sysinit@InitProcessTLS$qqrv', LMode);
        try
          Require(HasToken(LInitProcessTokens, ttkMethodName, 'InitProcessTLS'),
            'Borland method names must be mode-independent.');
          Require(HasToken(LInitProcessTokens, ttkMangledSignature, '$qqrv'),
            'Borland mangled suffixes must be mode-independent.');
        finally
          LInitProcessTokens.Free;
        end;

        var LSlashTokens := LParser.Tokenize(
          '@Sysinit\@InterlockedExchange$qqsrii', LMode);
        try
          Require(HasToken(LSlashTokens, ttkMethodName, 'InterlockedExchange'),
            'The Borland \\@ method name must be mode-independent.');
          Require(HasToken(LSlashTokens, ttkMangledSignature, '$qqsrii'),
            'The Borland \\@ mangled suffix must be mode-independent.');
        finally
          LSlashTokens.Free;
        end;
      end;
      var LQuotedLinkerTokens := LParser.Tokenize(
        'Linker name: ''@Sysinit@InterlockedExchange$qqsrii''',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LQuotedLinkerTokens, ttkStringLiteral,
          '''@Sysinit@InterlockedExchange$qqsrii'''),
          'Quoted linker names must remain string literals in method mode.');
      finally
        LQuotedLinkerTokens.Free;
      end;
      var LBareImportTokens := LParser.Tokenize('GetLastError',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LBareImportTokens, ttkMethodName, 'GetLastError'),
          'Bare PE import names must be classified as methods.');
      finally
        LBareImportTokens.Free;
      end;
      var LPrimitiveTokens := LParser.Tokenize('__fastcall RunError(unsigned char)',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LPrimitiveTokens, ttkMethodName, 'RunError'),
          'Methods must be detected independently of their parameter types.');
        Require(HasToken(LPrimitiveTokens, ttkTypeName, 'unsigned') and
          HasToken(LPrimitiveTokens, ttkTypeName, 'char'),
          'C++ primitive parameter types must be classified as types.');
      finally
        LPrimitiveTokens.Free;
      end;
    finally
      LTokens.Free;
    end;
  finally
    LParser.Free;
  end;
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

procedure TTinyParserFixture.TDumpValueTokenization;
begin
  TestTDumpValueTokenization;
end;

procedure TTinyParserFixture.HighlightThemes;
begin
  TestHighlightThemes;
end;

procedure TTinyParserFixture.CppBuilderMethodTokenization;
begin
  TestCppBuilderMethodTokenization;
end;

procedure TTinyParserFixture.TextFormatDrawing;
begin
  TestTextFormatDrawing;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  TDUnitX.RegisterTestFixture(TTinyParserFixture);
  var LRunner := TDUnitX.CreateRunner;
  LRunner.UseRTTI := False;
  LRunner.FailsOnNoAsserts := True;
  ForceDirectories(CTestResultsDirectory);
  LRunner.AddLogger(TDUnitXXMLNUnitFileLogger.Create(CTestResultsFile));
  var LResults := LRunner.Execute;
  if not LResults.AllPassed then
    ExitCode := EXIT_ERRORS;
end.
