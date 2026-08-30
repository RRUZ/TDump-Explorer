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
      var LMultiNamespaceBorlandTokens := LParser.Tokenize(
        '@Winapi\@Windows\@RegCloseKey$qqsp6HKEY__', tpmCppBuilderMethod);
      try
        Require(HasToken(LMultiNamespaceBorlandTokens, ttkMethodName,
          'RegCloseKey'),
          'The final Borland namespace separator must identify the method name.');
        Require(not HasToken(LMultiNamespaceBorlandTokens, ttkMethodName,
          'Windows'),
          'Intermediate Borland namespace segments must not be classified as methods.');
      finally
        LMultiNamespaceBorlandTokens.Free;
      end;
      var LNestedBorlandMethodTokens := LParser.Tokenize(
        '@System@TExtended80Rec@internalGetWords', tpmCppBuilderMethod);
      try
        Require(HasToken(LNestedBorlandMethodTokens, ttkTypeName,
          'TExtended80Rec'),
          'Nested Borland owner types must be classified independently.');
        Require(HasToken(LNestedBorlandMethodTokens, ttkMethodName,
          'internalGetWords'),
          'The final component of nested Borland names must be a method.');
      finally
        LNestedBorlandMethodTokens.Free;
      end;
      var LGenericBorlandMethodTokens := LParser.Tokenize(
        '@System\@Generics\@Collections@%TDictionary__2$ynpqqrxp14System\@TObjectxp29System\@Messaging\@TMessageBase$vp46System\@Messaging\@TMessageManager\@TListenerData%@TKeyEnumerator\@MoveNext',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LGenericBorlandMethodTokens, ttkTypeName,
          'TDictionary__2') and HasToken(LGenericBorlandMethodTokens,
          ttkTypeName, 'TKeyEnumerator'),
          'Borland generic linker names must preserve embedded type components.');
        Require(HasToken(LGenericBorlandMethodTokens, ttkMethodName,
          'MoveNext'),
          'Borland generic linker names must identify the final method after generic mangling.');
      finally
        LGenericBorlandMethodTokens.Free;
      end;
      var LItaniumMethodTokens := LParser.Tokenize(
        'S_LPROC32  _ZN6System11CloseHandleEy [013]', tpmCppBuilderMethod);
      try
        Require(HasToken(LItaniumMethodTokens, ttkMethodName, 'CloseHandle'),
          'Itanium nested names must classify the final component as a method.');
        Require(HasToken(LItaniumMethodTokens, ttkMangledSignature, 'Ey'),
          'Itanium method parameter and return encodings must be a signature token.');
      finally
        LItaniumMethodTokens.Free;
      end;
      var LItaniumTypeTokens := LParser.Tokenize(
        'S_UDT  _ZTRN6Winapi7Windows9PWideCharE [995]', tpmCppBuilderMethod);
      try
        Require(HasToken(LItaniumTypeTokens, ttkTypeName, 'PWideChar'),
          'Delphi _ZTRN nested names must classify the final component as a type.');
        Require(not HasToken(LItaniumTypeTokens, ttkMethodName, 'PWideChar'),
          'Delphi _ZTRN nested names must not classify the final component as a method.');
      finally
        LItaniumTypeTokens.Free;
      end;
      var LItaniumGenericTypeTokens := LParser.Tokenize(
        'S_UDT  _ZTRN6System12DynamicArrayIhEE [4BA]', tpmCppBuilderMethod);
      try
        Require(HasToken(LItaniumGenericTypeTokens, ttkTypeName,
          'DynamicArray'),
          'Generic Delphi _ZTRN names must preserve the outer type token.');
      finally
        LItaniumGenericTypeTokens.Free;
      end;
      var LItaniumNestedTypeTokens := LParser.Tokenize(
        'S_UDT  _ZTRN6System12DynamicArrayINS_11TPtrWrapperEEE [4BA]',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LItaniumNestedTypeTokens, ttkTypeName,
          'DynamicArray'),
          'Nested Itanium template arguments and S_ substitutions must preserve the outer type token.');
      finally
        LItaniumNestedTypeTokens.Free;
      end;
      var LItaniumPointerTemplateTokens := LParser.Tokenize(
        'S_UDT  _ZTRN6System12DynamicArrayIPPEE [4BA]',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LItaniumPointerTemplateTokens, ttkTypeName,
          'DynamicArray'),
          'Itanium template arguments containing pointer type encodings must be balanced.');
      finally
        LItaniumPointerTemplateTokens.Free;
      end;
      var LItaniumMethodSubstitutionTokens := LParser.Tokenize(
        'S_LPROC32  _ZN6System8ReadFileEyPvjRjS0_ [013]',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LItaniumMethodSubstitutionTokens, ttkMethodName,
          'ReadFile'),
          'Itanium function names must remain identified when the signature uses substitutions.');
        Require(HasToken(LItaniumMethodSubstitutionTokens, ttkMangledSignature,
          'EyPvjRjS0_'),
          'Itanium substituted function arguments must remain a signature token.');
      finally
        LItaniumMethodSubstitutionTokens.Free;
      end;
      var LItaniumTypedParametersTokens := LParser.Tokenize(
        'S_LPROC32  _ZN6System23_WriteUnicodeStringProcERNS_8TTextRecENS_13UnicodeStringEi [15F]',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LItaniumTypedParametersTokens, ttkMethodName,
          '_WriteUnicodeStringProc'),
          'The final Itanium nested-name component must remain the method token.');
        Require(HasToken(LItaniumTypedParametersTokens, ttkNamespace,
          'System'),
          'The outer Itanium owner must be emitted as a separate namespace token.');
        Require(not HasToken(LItaniumTypedParametersTokens, ttkNamespace,
          '_ZN6System23'),
          'The Itanium prefix, source-name lengths, and owner must not be merged into one namespace token.');
        Require(HasToken(LItaniumTypedParametersTokens, ttkTypeName,
          'TTextRec'),
          'A referenced nested Itanium parameter type must receive a separate type token.');
        Require(HasToken(LItaniumTypedParametersTokens, ttkTypeName,
          'UnicodeString'),
          'Each nested Itanium parameter type must receive its own type token.');
      finally
        LItaniumTypedParametersTokens.Free;
      end;
      var LItaniumConstructorTokens := LParser.Tokenize(
        'S_GPROC32  _ZN6System7TObjectC3Ev [196]', tpmCppBuilderMethod);
      try
        Require(HasToken(LItaniumConstructorTokens, ttkNamespace, 'System'),
          'An Itanium constructor must retain its owner namespace token.');
        Require(HasToken(LItaniumConstructorTokens, ttkTypeName, 'TObject'),
          'An Itanium constructor must classify its owning class as a type.');
        Require(not HasToken(LItaniumConstructorTokens, ttkMethodName,
          'TObject'),
          'An Itanium constructor class name must not be emitted as an ordinary method.');
      finally
        LItaniumConstructorTokens.Free;
      end;
      var LItaniumConstructorParameterTokens := LParser.Tokenize(
        'S_GPROC32  _ZN6System8Sysutils9ExceptionC3ENS_13UnicodeStringE [196]',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LItaniumConstructorParameterTokens, ttkTypeName,
          'Exception'),
          'A nested Itanium constructor must classify its class as a type.');
        Require(HasToken(LItaniumConstructorParameterTokens, ttkTypeName,
          'UnicodeString'),
          'Itanium constructor parameter type names must be tokenized separately.');
      finally
        LItaniumConstructorParameterTokens.Free;
      end;
      var LItaniumDestructorTokens := LParser.Tokenize(
        'S_GPROC32  _ZN6System7TObjectD0Ev [196]', tpmCppBuilderMethod);
      try
        Require(HasToken(LItaniumDestructorTokens, ttkTypeName, 'TObject'),
          'An Itanium destructor must classify its owning class as a type.');
      finally
        LItaniumDestructorTokens.Free;
      end;
      var LMachOItaniumTokens := LParser.Tokenize(
        'S_LPROC32  __ZN6System11CloseHandleEy [013]',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LMachOItaniumTokens, ttkMethodName, 'CloseHandle'),
          'The double-underscore Itanium spelling must classify the final method name.');
      finally
        LMachOItaniumTokens.Free;
      end;
      var LMalformedItaniumTokens := LParser.Tokenize(
        'S_UDT  _ZTRN6System12DynamicArrayIhE [4BA]', tpmCppBuilderMethod);
      try
        Require(not HasToken(LMalformedItaniumTokens, ttkTypeName,
          'DynamicArray'),
          'An unterminated Itanium template must not be accepted as a valid nested type name.');
      finally
        LMalformedItaniumTokens.Free;
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
