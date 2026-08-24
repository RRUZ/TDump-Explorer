unit TDump.Explorer.TinyParser;

interface

uses
  System.SysUtils,
  System.Generics.Collections;

type
  TTinyParserMode = (tpmTDumpValues, tpmCppBuilderMethod);

  TTinyTokenKind = (
    ttkWhitespace,
    ttkString,
    ttkInteger,
    ttkHexadecimal,
    ttkFloat,
    ttkDate,
    ttkTime,
    ttkDateTime,
    ttkSymbol,
    ttkKeyword,
    ttkNamespace,
    ttkTypeName,
    ttkMethodName
  );

  TTinyToken = record
    Kind: TTinyTokenKind;
    StartIndex: Integer;
    Length: Integer;
    Text: string;
  end;

  TTinyTokenList = TList<TTinyToken>;

  TTinyParser = class
  private
    class function IsDateSeparator(ACharacter: Char): Boolean; static;
    class function IsCppBuilderKeyword(const AText: string): Boolean; static;
    class function IsCppBuilderTypeName(const AText: string): Boolean; static;
    class function IsHexadecimalCharacter(ACharacter: Char): Boolean; static;
    class function IsIdentifierCharacter(ACharacter: Char): Boolean; static;
    class function IsIdentifierStart(ACharacter: Char): Boolean; static;
    class function IsTextInRange(const AText: string; AStartIndex,
      ACount: Integer): Boolean; static;
    class function TryReadDate(const AText: string; AStartIndex: Integer;
      out AEndIndex: Integer): Boolean; static;
    class function TryReadDateTime(const AText: string; AStartIndex: Integer;
      out AEndIndex: Integer): Boolean; static;
    class function TryReadHexadecimal(const AText: string; AStartIndex: Integer;
      out AEndIndex: Integer): Boolean; static;
    class function TryReadNumber(const AText: string; AStartIndex: Integer;
      out AEndIndex: Integer; out AKind: TTinyTokenKind): Boolean; static;
    class function TryReadTime(const AText: string; AStartIndex: Integer;
      out AEndIndex: Integer): Boolean; static;
    procedure ApplyCppBuilderMethodMode(AResult: TTinyTokenList);
    procedure AddToken(AResult: TTinyTokenList; AKind: TTinyTokenKind;
      const AText: string; AStartIndex, AEndIndex: Integer);
  public
    function Tokenize(const AText: string;
      AMode: TTinyParserMode = tpmTDumpValues): TTinyTokenList;
  end;

implementation

procedure TTinyParser.AddToken(AResult: TTinyTokenList; AKind: TTinyTokenKind;
  const AText: string; AStartIndex, AEndIndex: Integer);
begin
  var LToken: TTinyToken;
  LToken.Kind := AKind;
  LToken.StartIndex := AStartIndex;
  LToken.Length := AEndIndex - AStartIndex;
  LToken.Text := Copy(AText, AStartIndex, LToken.Length);
  AResult.Add(LToken);
end;

procedure TTinyParser.ApplyCppBuilderMethodMode(AResult: TTinyTokenList);
begin
  for var LIndex := 0 to AResult.Count - 1 do
  begin
    var LToken := AResult[LIndex];
    if LToken.Kind <> ttkString then
      Continue;

    if IsCppBuilderKeyword(LToken.Text) then
      LToken.Kind := ttkKeyword
    else
    begin
      var LNextIndex := LIndex + 1;
      while (LNextIndex < AResult.Count) and
        (AResult[LNextIndex].Kind = ttkWhitespace) do
        Inc(LNextIndex);
      var LPreviousIndex := LIndex - 1;
      while (LPreviousIndex >= 0) and
        (AResult[LPreviousIndex].Kind = ttkWhitespace) do
        Dec(LPreviousIndex);
      var LIsQualifiedIdentifier := (LPreviousIndex >= 0) and
        (AResult[LPreviousIndex].Text = ':');
      if LIsQualifiedIdentifier then
      begin
        Dec(LPreviousIndex);
        while (LPreviousIndex >= 0) and
          (AResult[LPreviousIndex].Kind = ttkWhitespace) do
          Dec(LPreviousIndex);
        LIsQualifiedIdentifier := (LPreviousIndex >= 0) and
          (AResult[LPreviousIndex].Text = ':');
      end;

      if (LNextIndex < AResult.Count) and (AResult[LNextIndex].Text = '(') then
        LToken.Kind := ttkMethodName
      else if (LNextIndex + 1 < AResult.Count) and
        (AResult[LNextIndex].Text = ':') and
        (AResult[LNextIndex + 1].Text = ':') then
        LToken.Kind := ttkNamespace
      else if IsCppBuilderTypeName(LToken.Text) or
        (LIsQualifiedIdentifier and CharInSet(LToken.Text[1], ['A'..'Z'])) then
        LToken.Kind := ttkTypeName;
      if LToken.Kind = ttkString then
        LToken.Kind := ttkMethodName;
    end;
    AResult[LIndex] := LToken;
  end;
end;

class function TTinyParser.IsDateSeparator(ACharacter: Char): Boolean;
begin
  Result := CharInSet(ACharacter, ['-', '/', '.']);
end;

class function TTinyParser.IsCppBuilderKeyword(const AText: string): Boolean;
begin
  Result := SameText(AText, '__cdecl') or SameText(AText, '__fastcall') or
    SameText(AText, '__linkproc__') or SameText(AText, '__stdcall') or
    SameText(AText, '__thiscall') or SameText(AText, 'const') or
    SameText(AText, 'volatile');
end;

class function TTinyParser.IsCppBuilderTypeName(const AText: string): Boolean;
begin
  Result := SameText(AText, 'signed') or SameText(AText, 'unsigned') or
    SameText(AText, 'short') or SameText(AText, 'long') or
    SameText(AText, 'void') or SameText(AText, 'char') or
    SameText(AText, 'int') or SameText(AText, 'float') or
    SameText(AText, 'double') or SameText(AText, 'bool') or
    SameText(AText, 'wchar_t') or
    ((Length(AText) >= 2) and (AText[1] = 'T') and
      CharInSet(AText[2], ['A'..'Z']));
end;

class function TTinyParser.IsHexadecimalCharacter(ACharacter: Char): Boolean;
begin
  Result := CharInSet(ACharacter, ['0'..'9', 'a'..'f', 'A'..'F']);
end;

class function TTinyParser.IsIdentifierCharacter(ACharacter: Char): Boolean;
begin
  Result := IsIdentifierStart(ACharacter) or CharInSet(ACharacter, ['0'..'9']);
end;

class function TTinyParser.IsIdentifierStart(ACharacter: Char): Boolean;
begin
  Result := CharInSet(ACharacter, ['a'..'z', 'A'..'Z', '_']);
end;

class function TTinyParser.IsTextInRange(const AText: string; AStartIndex,
  ACount: Integer): Boolean;
begin
  Result := (AStartIndex >= 1) and (ACount >= 0) and
    (AStartIndex + ACount - 1 <= Length(AText));
end;

function TTinyParser.Tokenize(const AText: string;
  AMode: TTinyParserMode): TTinyTokenList;
begin
  Result := TTinyTokenList.Create;
  var LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    var LStartIndex := LIndex;
    var LCharacter := AText[LIndex];
    if CharInSet(LCharacter, [#0..#32]) then
    begin
      repeat
        Inc(LIndex);
      until (LIndex > Length(AText)) or not CharInSet(AText[LIndex], [#0..#32]);
      AddToken(Result, ttkWhitespace, AText, LStartIndex, LIndex);
      Continue;
    end;

    if CharInSet(LCharacter, ['''', '"']) then
    begin
      var LQuote := LCharacter;
      Inc(LIndex);
      while LIndex <= Length(AText) do
      begin
        if (AText[LIndex] = '\') and (LIndex < Length(AText)) then
          Inc(LIndex, 2)
        else
        begin
          Inc(LIndex);
          if AText[LIndex - 1] = LQuote then
            Break;
        end;
      end;
      AddToken(Result, ttkString, AText, LStartIndex, LIndex);
      Continue;
    end;

    var LEndIndex := 0;
    if TryReadDateTime(AText, LIndex, LEndIndex) then
    begin
      AddToken(Result, ttkDateTime, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    if TryReadDate(AText, LIndex, LEndIndex) then
    begin
      AddToken(Result, ttkDate, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    if TryReadTime(AText, LIndex, LEndIndex) then
    begin
      AddToken(Result, ttkTime, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    if TryReadHexadecimal(AText, LIndex, LEndIndex) then
    begin
      AddToken(Result, ttkHexadecimal, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;

    var LNumberKind := ttkInteger;
    if TryReadNumber(AText, LIndex, LEndIndex, LNumberKind) then
    begin
      AddToken(Result, LNumberKind, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;

    if CharInSet(LCharacter, ['0'..'9']) then
    begin
      repeat
        Inc(LIndex);
      until (LIndex > Length(AText)) or not IsIdentifierCharacter(AText[LIndex]);
      AddToken(Result, ttkString, AText, LStartIndex, LIndex);
      Continue;
    end;

    if IsIdentifierStart(LCharacter) then
    begin
      repeat
        Inc(LIndex);
      until (LIndex > Length(AText)) or not IsIdentifierCharacter(AText[LIndex]);
      AddToken(Result, ttkString, AText, LStartIndex, LIndex);
      Continue;
    end;

    Inc(LIndex);
    AddToken(Result, ttkSymbol, AText, LStartIndex, LIndex);
  end;
  if AMode = tpmCppBuilderMethod then
    ApplyCppBuilderMethodMode(Result);
end;

class function TTinyParser.TryReadDate(const AText: string;
  AStartIndex: Integer; out AEndIndex: Integer): Boolean;
begin
  Result := False;
  AEndIndex := AStartIndex;
  if IsTextInRange(AText, AStartIndex, 10) and
    IsTextInRange(AText, AStartIndex, 4) and
    CharInSet(AText[AStartIndex], ['0'..'9']) and
    CharInSet(AText[AStartIndex + 1], ['0'..'9']) and
    CharInSet(AText[AStartIndex + 2], ['0'..'9']) and
    CharInSet(AText[AStartIndex + 3], ['0'..'9']) and
    IsDateSeparator(AText[AStartIndex + 4]) and
    CharInSet(AText[AStartIndex + 5], ['0'..'9']) and
    CharInSet(AText[AStartIndex + 6], ['0'..'9']) and
    (AText[AStartIndex + 4] = AText[AStartIndex + 7]) and
    CharInSet(AText[AStartIndex + 8], ['0'..'9']) and
    CharInSet(AText[AStartIndex + 9], ['0'..'9']) then
  begin
    var LMonth := StrToInt(Copy(AText, AStartIndex + 5, 2));
    var LDay := StrToInt(Copy(AText, AStartIndex + 8, 2));
    if (LMonth in [1..12]) and (LDay in [1..31]) then
    begin
      AEndIndex := AStartIndex + 10;
      Exit(True);
    end;
  end;

  if IsTextInRange(AText, AStartIndex, 10) and
    CharInSet(AText[AStartIndex], ['0'..'9']) and
    CharInSet(AText[AStartIndex + 1], ['0'..'9']) and
    IsDateSeparator(AText[AStartIndex + 2]) and
    CharInSet(AText[AStartIndex + 3], ['0'..'9']) and
    CharInSet(AText[AStartIndex + 4], ['0'..'9']) and
    (AText[AStartIndex + 2] = AText[AStartIndex + 5]) and
    CharInSet(AText[AStartIndex + 6], ['0'..'9']) and
    CharInSet(AText[AStartIndex + 7], ['0'..'9']) and
    CharInSet(AText[AStartIndex + 8], ['0'..'9']) and
    CharInSet(AText[AStartIndex + 9], ['0'..'9']) then
  begin
    var LDay := StrToInt(Copy(AText, AStartIndex, 2));
    var LMonth := StrToInt(Copy(AText, AStartIndex + 3, 2));
    if (LMonth in [1..12]) and (LDay in [1..31]) then
    begin
      AEndIndex := AStartIndex + 10;
      Result := True;
    end;
  end;
end;

class function TTinyParser.TryReadDateTime(const AText: string;
  AStartIndex: Integer; out AEndIndex: Integer): Boolean;
begin
  Result := False;
  AEndIndex := AStartIndex;
  var LDateEndIndex := 0;
  if not TryReadDate(AText, AStartIndex, LDateEndIndex) then
    Exit;

  var LTimeStartIndex := LDateEndIndex;
  if (LTimeStartIndex <= Length(AText)) and
    (AText[LTimeStartIndex] = 'T') then
    Inc(LTimeStartIndex)
  else if (LTimeStartIndex <= Length(AText)) and
    (AText[LTimeStartIndex] = ' ') then
    Inc(LTimeStartIndex)
  else
    Exit;

  Result := TryReadTime(AText, LTimeStartIndex, AEndIndex);
end;

class function TTinyParser.TryReadHexadecimal(const AText: string;
  AStartIndex: Integer; out AEndIndex: Integer): Boolean;
begin
  Result := False;
  AEndIndex := AStartIndex;
  if (AStartIndex + 2 <= Length(AText)) and (AText[AStartIndex] = '0') and
    CharInSet(AText[AStartIndex + 1], ['x', 'X']) then
  begin
    var LIndex := AStartIndex + 2;
    while (LIndex <= Length(AText)) and IsHexadecimalCharacter(AText[LIndex]) do
      Inc(LIndex);
    if LIndex > AStartIndex + 2 then
    begin
      AEndIndex := LIndex;
      Exit(True);
    end;
  end;

  if (AStartIndex <= Length(AText)) and (AText[AStartIndex] = '$') then
  begin
    var LIndex := AStartIndex + 1;
    while (LIndex <= Length(AText)) and IsHexadecimalCharacter(AText[LIndex]) do
      Inc(LIndex);
    if LIndex > AStartIndex + 1 then
    begin
      AEndIndex := LIndex;
      Exit(True);
    end;
  end;

  if (AStartIndex <= Length(AText)) and
    IsHexadecimalCharacter(AText[AStartIndex]) then
  begin
    var LIndex := AStartIndex;
    var LContainsHexLetter := False;
    while (LIndex <= Length(AText)) and IsHexadecimalCharacter(AText[LIndex]) do
    begin
      LContainsHexLetter := LContainsHexLetter or
        CharInSet(AText[LIndex], ['a'..'f', 'A'..'F']);
      Inc(LIndex);
    end;

    if (LIndex <= Length(AText)) and CharInSet(AText[LIndex], ['h', 'H']) and
      ((LIndex = Length(AText)) or not IsIdentifierCharacter(AText[LIndex + 1])) then
    begin
      AEndIndex := LIndex + 1;
      Exit(True);
    end;

    if (LIndex - AStartIndex >= 4) and (AText[AStartIndex] = '0') and
      ((LIndex > Length(AText)) or not IsIdentifierCharacter(AText[LIndex])) then
    begin
      AEndIndex := LIndex;
      Exit(True);
    end;

    if (LIndex - AStartIndex >= 2) and LContainsHexLetter and
      ((LIndex > Length(AText)) or
      not IsIdentifierCharacter(AText[LIndex])) then
    begin
      AEndIndex := LIndex;
      Result := True;
    end;
  end;
end;

class function TTinyParser.TryReadNumber(const AText: string;
  AStartIndex: Integer; out AEndIndex: Integer;
  out AKind: TTinyTokenKind): Boolean;
begin
  Result := False;
  AEndIndex := AStartIndex;
  AKind := ttkInteger;
  var LIndex := AStartIndex;
  if (LIndex <= Length(AText)) and CharInSet(AText[LIndex], ['+', '-']) then
    Inc(LIndex);
  var LDigitStartIndex := LIndex;
  while (LIndex <= Length(AText)) and CharInSet(AText[LIndex], ['0'..'9']) do
    Inc(LIndex);
  if LIndex = LDigitStartIndex then
    Exit;

  if (LIndex < Length(AText)) and (AText[LIndex] = '.') and
    CharInSet(AText[LIndex + 1], ['0'..'9']) then
  begin
    AKind := ttkFloat;
    Inc(LIndex);
    while (LIndex <= Length(AText)) and CharInSet(AText[LIndex], ['0'..'9']) do
      Inc(LIndex);
  end;
  if (LIndex < Length(AText)) and CharInSet(AText[LIndex], ['e', 'E']) then
  begin
    var LExponentIndex := LIndex + 1;
    if (LExponentIndex <= Length(AText)) and
      CharInSet(AText[LExponentIndex], ['+', '-']) then
      Inc(LExponentIndex);
    var LExponentDigitIndex := LExponentIndex;
    while (LExponentIndex <= Length(AText)) and
      CharInSet(AText[LExponentIndex], ['0'..'9']) do
      Inc(LExponentIndex);
    if LExponentIndex > LExponentDigitIndex then
    begin
      AKind := ttkFloat;
      LIndex := LExponentIndex;
    end;
  end;

  if (LIndex <= Length(AText)) and IsIdentifierCharacter(AText[LIndex]) then
    Exit;

  AEndIndex := LIndex;
  Result := True;
end;

class function TTinyParser.TryReadTime(const AText: string;
  AStartIndex: Integer; out AEndIndex: Integer): Boolean;
begin
  Result := False;
  AEndIndex := AStartIndex;
  if not IsTextInRange(AText, AStartIndex, 5) or
    not CharInSet(AText[AStartIndex], ['0'..'9']) or
    not CharInSet(AText[AStartIndex + 1], ['0'..'9']) or
    (AText[AStartIndex + 2] <> ':') or
    not CharInSet(AText[AStartIndex + 3], ['0'..'9']) or
    not CharInSet(AText[AStartIndex + 4], ['0'..'9']) then
    Exit;

  var LHour := StrToInt(Copy(AText, AStartIndex, 2));
  var LMinute := StrToInt(Copy(AText, AStartIndex + 3, 2));
  if (LHour > 23) or (LMinute > 59) then
    Exit;

  var LIndex := AStartIndex + 5;
  if IsTextInRange(AText, LIndex, 3) and (AText[LIndex] = ':') and
    CharInSet(AText[LIndex + 1], ['0'..'9']) and
    CharInSet(AText[LIndex + 2], ['0'..'9']) then
  begin
    var LSecond := StrToInt(Copy(AText, LIndex + 1, 2));
    if LSecond > 59 then
      Exit;
    Inc(LIndex, 3);
  end;
  if (LIndex < Length(AText)) and (AText[LIndex] = '.') and
    CharInSet(AText[LIndex + 1], ['0'..'9']) then
  begin
    Inc(LIndex);
    while (LIndex <= Length(AText)) and CharInSet(AText[LIndex], ['0'..'9']) do
      Inc(LIndex);
  end;

  AEndIndex := LIndex;
  Result := True;
end;

end.
