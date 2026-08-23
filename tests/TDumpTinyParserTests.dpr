program TDumpTinyParserTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Types,
  Vcl.Graphics,
  TDump.Explorer.TinyParser in '..\source\common\TDump.Explorer.TinyParser.pas',
  TDump.Explorer.Highlighter in '..\source\common\TDump.Explorer.Highlighter.pas';

procedure Require(ACondition: Boolean; const AMessage: string);
begin
  if not ACondition then
    raise Exception.Create(AMessage);
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
    'Stamp=2026-08-23T23:59:59.123 Path=C:\temp';
begin
  var LParser := TTinyParser.Create;
  try
    var LTokens := LParser.Tokenize(CText);
    try
      Require(HasToken(LTokens, ttkString, '"Turbo Dump"'),
        'Quoted TDUMP text must be classified as a string.');
      Require(HasToken(LTokens, ttkString, 'C'),
        'A path drive letter must remain a string rather than bare hexadecimal.');
      Require(HasToken(LTokens, ttkHexadecimal, '0x1A2B'),
        '0x-prefixed values must be hexadecimal tokens.');
      Require(HasToken(LTokens, ttkHexadecimal, 'BAF4C9h'),
        'TDUMP H-suffixed values must be hexadecimal tokens.');
      Require(HasToken(LTokens, ttkHexadecimal, 'CAFEBABE'),
        'Bare TDUMP hexadecimal values must be hexadecimal tokens.');
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
  var LLightTheme := TTinyHighlighter.LightTheme;
  var LDarkTheme := TTinyHighlighter.DarkTheme;
  Require(LLightTheme.BackgroundColor <> LDarkTheme.BackgroundColor,
    'Light and dark highlighter themes must have distinct backgrounds.');
  Require(LLightTheme.HexadecimalColor <> LLightTheme.NumberColor,
    'The light theme must distinguish hexadecimal and decimal values.');
  Require(LDarkTheme.DateTimeColor <> LDarkTheme.StringColor,
    'The dark theme must distinguish date/time and string values.');
end;

procedure TestTextFormatDrawing;
begin
  var LBitmap := TBitmap.Create;
  try
    LBitmap.SetSize(180, 24);
    var LTheme := TTinyHighlighter.DarkTheme;
    LBitmap.Canvas.Brush.Color := LTheme.BackgroundColor;
    LBitmap.Canvas.FillRect(Rect(0, 0, LBitmap.Width, LBitmap.Height));
    var LHighlighter := TTinyHighlighter.Create;
    try
      LHighlighter.TextRect(LBitmap.Canvas,
        Rect(0, 0, LBitmap.Width, LBitmap.Height), 'Value=0xCAFEBABE',
        thtDark, [tfRight, tfVerticalCenter, tfEndEllipsis]);
    finally
      LHighlighter.Free;
    end;
  finally
    LBitmap.Free;
  end;
end;

begin
  ReportMemoryLeaksOnShutdown := True;
  try
    TestTDumpValueTokenization;
    TestHighlightThemes;
    TestTextFormatDrawing;
    Writeln('TDump tiny parser assertions passed.');
    Readln;
  except
    on LException: Exception do
    begin
      Writeln(ErrOutput, LException.Message);
      ExitCode := 1;
    end;
  end;
end.
