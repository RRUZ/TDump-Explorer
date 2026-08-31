program TDumpTinyParserTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.StrUtils,
  System.Types,
  System.IOUtils,
  System.RegularExpressions,
  System.Generics.Collections,
  Vcl.Graphics,
  DUnitX.TestFramework,
  DUnitX.Loggers.Xml.NUnit,
  TDump.Explorer.UI in '..\source\common\TDump.Explorer.UI.pas',
  TDump.Explorer.TinyParser in '..\source\common\TDump.Explorer.TinyParser.pas',
  TDump.Explorer.Highlighter in '..\source\common\TDump.Explorer.Highlighter.pas';

const
  CTestResultsDirectory = 'C:\dev\TDump-Explorer\tests\test-results';
  CTestResultsFile = CTestResultsDirectory + '\TDumpTinyParserTests.nunit.xml';
  CMachFixture = 'C:\dev\TDump-Explorer\fixtures\generated\Mach.Universal.Rad37.tdump';

type
  [TestFixture]
  TTinyParserFixture = class
  public
    [Test] procedure TDumpValueTokenization;
    [Test] procedure HighlightThemes;
    [Test] procedure CppBuilderMethodTokenization;
    [Test] procedure MachFixtureLinkerTokenization;
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
  CGenericMethod = 'System::Generics::Collections::TDictionary__2<' +
    'System::UnicodeString, System::Variant>::TKeyEnumerator::MoveNext()';
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
      var LDemangledGenericTokens := LParser.Tokenize(CGenericMethod,
        tpmCppBuilderMethod);
      try
        Require(HasToken(LDemangledGenericTokens, ttkTypeName,
          'UnicodeString') and HasToken(LDemangledGenericTokens, ttkTypeName,
          'Variant'),
          'Demangled Delphi generic arguments must use their shared semantic type tokens.');
      finally
        LDemangledGenericTokens.Free;
      end;
      var LMachDemangledGenericTokens := LParser.Tokenize(
        'symbol: ' + CGenericMethod, tpmMachLinker);
      try
        Require(HasToken(LMachDemangledGenericTokens, ttkTypeName,
          'UnicodeString') and HasToken(LMachDemangledGenericTokens,
          ttkTypeName, 'Variant'),
          'Mach demangled generic arguments must match the Itanium type coloring.');
      finally
        LMachDemangledGenericTokens.Free;
      end;
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
      var LVTableTokens := LParser.Tokenize(
        'symbol: __ZTVN3Fmx8Treeview9TTreeViewE (flags = 0x0)',
        tpmMachLinker);
      try
        Require(HasToken(LVTableTokens, ttkNamespace, 'Fmx') and
          HasToken(LVTableTokens, ttkNamespace, 'Treeview'),
          'Itanium vtable names must preserve each owner namespace.');
        Require(HasToken(LVTableTokens, ttkTypeName, 'TTreeView'),
          'Itanium vtable names must classify the described class as a type.');
        Require(HasToken(LVTableTokens, ttkKeyword, 'symbol') and
          HasToken(LVTableTokens, ttkKeyword, 'flags'),
          'Mach symbol labels must be semantic keywords, not method names.');
        Require(not HasToken(LVTableTokens, ttkMethodName,
          '__ZTVN3Fmx8Treeview9TTreeViewE'),
          'An Itanium vtable name must not be rendered as one unparsed method.');
      finally
        LVTableTokens.Free;
      end;
      var LBindingTokens := LParser.Tokenize(
        'BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM'#13#10 +
        '  symbol: dyld_stub_binder (flags = 0x0)', tpmMachLinker);
      try
        Require(HasToken(LBindingTokens, ttkKeyword,
          'BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM'),
          'Mach bind opcodes must be semantic keywords, not method names.');
        Require(HasToken(LBindingTokens, ttkMethodName, 'dyld_stub_binder'),
          'A plain Mach linker symbol following symbol: must be highlighted as a method.');
      finally
        LBindingTokens.Free;
      end;
      var LMachDemangledTokens := LParser.Tokenize(
        '518 Fmx::Fontglyphs::Mac::Finalization()', tpmMachLinker);
      try
        Require(HasToken(LMachDemangledTokens, ttkNamespace, 'Fmx') and
          HasToken(LMachDemangledTokens, ttkNamespace, 'Fontglyphs') and
          HasToken(LMachDemangledTokens, ttkNamespace, 'Mac'),
          'Mach demangled qualified names must keep every owner as a namespace.');
        Require(HasToken(LMachDemangledTokens, ttkMethodName, 'Finalization'),
          'The terminal call in a Mach demangled qualified name must be a method.');
      finally
        LMachDemangledTokens.Free;
      end;
      var LMachNestedSignatureTokens := LParser.Tokenize(
        'symbol: __ZN3Fmx5Forms17TCommonCustomForm12DoMouseWheelEN6System3SetINS2_7Classes15TShiftStateItemELS5_0ELS5_10EEEiRb (flags = 0x0)',
        tpmMachLinker);
      try
        Require(HasToken(LMachNestedSignatureTokens, ttkNamespace, 'Fmx') and
          HasToken(LMachNestedSignatureTokens, ttkNamespace, 'Forms') and
          HasToken(LMachNestedSignatureTokens, ttkNamespace, 'System') and
          HasToken(LMachNestedSignatureTokens, ttkNamespace, 'Classes'),
          'Nested Mach signatures must preserve owner namespaces.');
        Require(HasToken(LMachNestedSignatureTokens, ttkTypeName,
          'TCommonCustomForm') and HasToken(LMachNestedSignatureTokens,
          ttkTypeName, 'Set') and HasToken(LMachNestedSignatureTokens,
          ttkTypeName, 'TShiftStateItem'),
          'Nested Mach signatures must preserve owner and generic argument types.');
        Require(HasToken(LMachNestedSignatureTokens, ttkMethodName,
          'DoMouseWheel'),
          'Nested Mach signatures must preserve the terminal method name.');
      finally
        LMachNestedSignatureTokens.Free;
      end;
      var LMachObjectiveCSymbolTokens := LParser.Tokenize(
        'symbol: _NSAccessibilityActionDescription (flags = 0x0)',
        tpmMachLinker);
      try
        Require(HasToken(LMachObjectiveCSymbolTokens, ttkMethodName,
          '_NSAccessibilityActionDescription'),
          'Ordinary Mach and Objective-C linker symbols must receive method highlighting.');
      finally
        LMachObjectiveCSymbolTokens.Free;
      end;
      var LMachGenericConstructorTokens := LParser.Tokenize(
        '__ZN6Macapi10Objectivec19TOCGenericImport__2IN6System15DelphiInterfaceINS_6Appkit17NSPageLayoutClassEEENS3_INS4_12NSPageLayoutEEEEv04cctrEv',
        tpmCppBuilderMethod);
      try
        Require(HasToken(LMachGenericConstructorTokens, ttkNamespace, 'Macapi'),
          'Mach generic linker names must retain their namespace components.');
        Require(HasToken(LMachGenericConstructorTokens, ttkTypeName,
          'TOCGenericImport__2'),
          'Delphi cctr generic linker names must classify the outer generic class as a type.');
        Require(HasToken(LMachGenericConstructorTokens, ttkTypeName,
          'NSPageLayoutClass'),
          'Mach generic linker names must tokenize embedded template types.');
        Require(HasToken(LMachGenericConstructorTokens, ttkKeyword, 'cctr'),
          'Delphi cctr must remain a visibly highlighted generated-member marker.');
      finally
        LMachGenericConstructorTokens.Free;
      end;
      var LMachGenericDestructorTokens := LParser.Tokenize(
        'symbol: __ZN6Macapi10Objectivec19TOCGenericImport__2IN6System15DelphiInterfaceINS_10Foundation19NSOutputStreamClassEEENS3_INS4_14NSOutputStreamEEEEv04cdtrEv (flags = 0x0)',
        tpmMachLinker);
      try
        Require(HasToken(LMachGenericDestructorTokens, ttkNamespace,
          'Foundation') and HasToken(LMachGenericDestructorTokens,
          ttkTypeName, 'NSOutputStreamClass') and
          HasToken(LMachGenericDestructorTokens, ttkTypeName,
          'NSOutputStream'),
          'Delphi cdtr generic linker names must preserve Objective-C nested template types.');
        Require(not HasToken(LMachGenericDestructorTokens, ttkMethodName,
          'cdtr'),
          'Delphi cdtr is generated mangling, not a user-facing method name.');
        Require(HasToken(LMachGenericDestructorTokens, ttkKeyword, 'cdtr'),
          'Delphi cdtr must remain a visibly highlighted generated-member marker.');
      finally
        LMachGenericDestructorTokens.Free;
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

procedure TestMachFixtureLinkerTokenization;
const
  CItaniumSymbolPattern = '_{1,2}Z(?:N|TRN|TVN|TIN|TSN)[A-Za-z0-9_]+';
begin
  Require(TFile.Exists(CMachFixture),
    'The generated Mach fixture must be available for linker-tokenization coverage.');

  var LNames := TDictionary<string, Byte>.Create;
  var LParser := TTinyParser.Create;
  var LSpecialMemberCount := 0;
  try
    for var LMatch in TRegEx.Matches(TFile.ReadAllText(CMachFixture),
      CItaniumSymbolPattern) do
      LNames.TryAdd(LMatch.Value, 0);
    Require(LNames.Count > 1000,
      'The Mach fixture must provide broad Itanium linker-name coverage.');

    for var LName in LNames.Keys do
    begin
      var LTokens := LParser.Tokenize(LName, tpmMachLinker);
      try
        var LHasStructure := False;
        for var LToken in LTokens do
        begin
          LHasStructure := LHasStructure or
            (LToken.Kind in [ttkNamespace, ttkTypeName, ttkMethodName]);
          Require(not ((LToken.Kind in [ttkNamespace, ttkTypeName]) and
            (Length(LToken.Text) > 1) and (LToken.Text[1] = '_') and
            CharInSet(LToken.Text[2], ['0'..'9'])),
            'Itanium substitutions must not become pseudo type/namespace tokens: ' + LName);
        end;
        Require(LHasStructure,
          'Every supported Mach Itanium linker name must expose semantic structure: ' + LName);
        Require(not HasToken(LTokens, ttkMethodName, LName),
          'A supported Mach Itanium linker name must not collapse into one method token: ' + LName);
        if ContainsText(LName, 'cctr') then
        begin
          Inc(LSpecialMemberCount);
          Require(HasToken(LTokens, ttkKeyword, 'cctr'),
            'Every Mach cctr marker must remain visibly highlighted: ' + LName);
        end;
        if ContainsText(LName, 'cdtr') then
        begin
          Inc(LSpecialMemberCount);
          Require(HasToken(LTokens, ttkKeyword, 'cdtr'),
            'Every Mach cdtr marker must remain visibly highlighted: ' + LName);
        end;
      finally
        LTokens.Free;
      end;
    end;
    Require(LSpecialMemberCount > 0,
      'The Mach fixture must contain generated constructor/destructor markers.');
  finally
    LParser.Free;
    LNames.Free;
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

procedure TTinyParserFixture.MachFixtureLinkerTokenization;
begin
  TestMachFixtureLinkerTokenization;
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
