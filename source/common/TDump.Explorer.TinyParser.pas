//**************************************************************************************************
//
// Unit TDump.Explorer.TinyParser
//
// Tiny parser for Tdump Values and C++Builder-style demangled syntax
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.TinyParser;

interface

uses
  System.SysUtils,
  System.StrUtils,
  System.Generics.Collections;

type
  TTinyParserMode = (tpmTDumpValues, tpmCppBuilderMethod, tpmMachLinker,
    tpmExtractedString, tpmELFRelocation, tpmOMFRecord, tpmOMFLEData,
    tpmPEImportProperty);

  TTinyTokenKind = (
    ttkWhitespace,
    ttkString,
    ttkStringLiteral,
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
    ttkMethodName,
    ttkMangledSignature
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
    class function IsItaniumSpecialMember(const AText: string;
      AStartIndex: Integer): Boolean; static;
    class function IsMachLinkerKeyword(const AText: string): Boolean; static;
    class function IsTextInRange(const AText: string; AStartIndex,
      ACount: Integer): Boolean; static;
    class function TryReadDate(const AText: string; AStartIndex: Integer;
      out AEndIndex: Integer): Boolean; static;
    class function TryReadDateTime(const AText: string; AStartIndex: Integer;
      out AEndIndex: Integer): Boolean; static;
    class function TryReadBorlandMethod(const AText: string;
      AStartIndex: Integer; out AMethodStartIndex, AMethodEndIndex,
      AEndIndex: Integer): Boolean; static;
    class function TryReadItaniumNestedName(const AText: string;
      AStartIndex: Integer; const APrefix: string; out ANameStartIndex,
      ANameEndIndex, AEndIndex: Integer): Boolean; static;
    class function TryReadItaniumMethod(const AText: string;
      AStartIndex: Integer; out AMethodStartIndex, AMethodEndIndex,
      AEndIndex: Integer): Boolean; static;
    class function TryReadItaniumType(const AText: string;
      AStartIndex: Integer; out ATypeStartIndex, ATypeEndIndex,
      AEndIndex: Integer): Boolean; static;
    procedure AddBorlandOwnerTokens(AResult: TTinyTokenList;
      const AText: string; AStartIndex, AEndIndex: Integer);
    procedure AddItaniumNestedNameTokens(AResult: TTinyTokenList;
      const AText: string; AStartIndex, ANameStartIndex: Integer);
    procedure AddItaniumSignatureTokens(AResult: TTinyTokenList;
      const AText: string; AStartIndex, AEndIndex: Integer);
    procedure AddBorlandSignatureTokens(AResult: TTinyTokenList;
      const AText: string; AStartIndex, AEndIndex: Integer);
    procedure ApplyMachLinkerMode(AResult: TTinyTokenList);
    procedure ApplyExtractedStringMode(AResult: TTinyTokenList);
    procedure ApplyELFRelocationMode(AResult: TTinyTokenList);
    procedure ApplyOMFRecordMode(AResult: TTinyTokenList);
    procedure ApplyOMFLEDataMode(AResult: TTinyTokenList);
    procedure ApplyPEImportPropertyMode(AResult: TTinyTokenList);
    procedure PromoteItaniumGeneratedOwners(AResult: TTinyTokenList);
    class function TryReadHexadecimal(const AText: string; AStartIndex: Integer;
      out AEndIndex: Integer): Boolean; static;
    class function TryReadNumber(const AText: string; AStartIndex: Integer;
      out AEndIndex: Integer; out AKind: TTinyTokenKind): Boolean; static;
    class function TryReadQuotedString(const AText: string;
      AStartIndex: Integer; out AEndIndex: Integer): Boolean; static;
    class function TryReadTime(const AText: string; AStartIndex: Integer;
      out AEndIndex: Integer): Boolean; static;
    procedure ApplyCppBuilderMethodMode(AResult: TTinyTokenList);
    procedure AddToken(AResult: TTinyTokenList; AKind: TTinyTokenKind;
      const AText: string; AStartIndex, AEndIndex: Integer);
  public
    function Tokenize(const AText: string;
      AMode: TTinyParserMode = tpmTDumpValues): TTinyTokenList; overload;
    procedure Tokenize(const AText: string; AMode: TTinyParserMode;
      AResult: TTinyTokenList); overload;
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

procedure TTinyParser.AddBorlandOwnerTokens(AResult: TTinyTokenList;
  const AText: string; AStartIndex, AEndIndex: Integer);
begin
  // Generic Borland linker names embed type arguments and mangling between
  // their @-qualified components.  Tokenize the owner chain component by
  // component so T-prefixed types do not collapse into a single namespace.
  var LIndex := AStartIndex;
  while LIndex < AEndIndex do
  begin
    var LTokenStart := LIndex;
    if IsIdentifierStart(AText[LIndex]) then
    begin
      repeat
        Inc(LIndex);
      until (LIndex >= AEndIndex) or not IsIdentifierCharacter(AText[LIndex]);
      if IsCppBuilderTypeName(Copy(AText, LTokenStart, LIndex - LTokenStart)) then
        AddToken(AResult, ttkTypeName, AText, LTokenStart, LIndex)
      else
        AddToken(AResult, ttkNamespace, AText, LTokenStart, LIndex);
      Continue;
    end;

    Inc(LIndex);
    if CharInSet(AText[LTokenStart], ['@', '\', '%']) then
      AddToken(AResult, ttkNamespace, AText, LTokenStart, LIndex)
    else
      AddToken(AResult, ttkMangledSignature, AText, LTokenStart, LIndex);
  end;
end;

procedure TTinyParser.AddBorlandSignatureTokens(AResult: TTinyTokenList;
  const AText: string; AStartIndex, AEndIndex: Integer);
begin
  // Borland signatures retain qualified type names after the $ delimiter,
  // for example $qqrp19Vcl@Menus@TMenuItem.  Preserve unknown encoding as a
  // signature, while exposing only names with an unambiguous boundary (@ or
  // a source-name length digit followed by an uppercase identifier).
  var LCursor := AStartIndex;
  var LIndex := AStartIndex;
  while LIndex < AEndIndex do
  begin
    var LNameStart := 0;
    if (AText[LIndex] = '@') and (LIndex + 1 < AEndIndex) and
      IsIdentifierStart(AText[LIndex + 1]) then
      LNameStart := LIndex + 1
    else if (LIndex > AStartIndex) and
      CharInSet(AText[LIndex - 1], ['0'..'9']) and
      CharInSet(AText[LIndex], ['A'..'Z']) then
      LNameStart := LIndex
    else if (LIndex > AStartIndex) and
      CharInSet(AText[LIndex - 1], ['%', '\']) and
      CharInSet(AText[LIndex], ['A'..'Z']) then
      LNameStart := LIndex;

    if LNameStart = 0 then
    begin
      Inc(LIndex);
      Continue;
    end;

    var LNameEnd := LNameStart;
    while (LNameEnd < AEndIndex) and IsIdentifierCharacter(AText[LNameEnd]) do
      Inc(LNameEnd);
    if LCursor < LNameStart then
      AddToken(AResult, ttkMangledSignature, AText, LCursor, LNameStart);
    var LName := Copy(AText, LNameStart, LNameEnd - LNameStart);
    if IsCppBuilderTypeName(LName) then
      AddToken(AResult, ttkTypeName, AText, LNameStart, LNameEnd)
    else
      AddToken(AResult, ttkNamespace, AText, LNameStart, LNameEnd);
    LCursor := LNameEnd;
    LIndex := LNameEnd;
  end;
  if LCursor < AEndIndex then
    AddToken(AResult, ttkMangledSignature, AText, LCursor, AEndIndex);
end;

procedure TTinyParser.ApplyCppBuilderMethodMode(AResult: TTinyTokenList);
begin
  PromoteItaniumGeneratedOwners(AResult);
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
        (AResult[LPreviousIndex].Text = '.');
      if not LIsQualifiedIdentifier then
        LIsQualifiedIdentifier := (LPreviousIndex >= 0) and
        (AResult[LPreviousIndex].Text = ':');
      if LIsQualifiedIdentifier then
      begin
        if AResult[LPreviousIndex].Text = ':' then
        begin
          Dec(LPreviousIndex);
          while (LPreviousIndex >= 0) and
            (AResult[LPreviousIndex].Kind = ttkWhitespace) do
            Dec(LPreviousIndex);
          LIsQualifiedIdentifier := (LPreviousIndex >= 0) and
            (AResult[LPreviousIndex].Text = ':');
        end;
      end;

      if (LNextIndex < AResult.Count) and (AResult[LNextIndex].Text = '(') then
        LToken.Kind := ttkMethodName
      else if IsCppBuilderTypeName(LToken.Text) or
        (LIsQualifiedIdentifier and CharInSet(LToken.Text[1], ['A'..'Z'])) then
        LToken.Kind := ttkTypeName
      else if ((LNextIndex < AResult.Count) and
        (AResult[LNextIndex].Text = '.')) or
        ((LNextIndex + 1 < AResult.Count) and
        (AResult[LNextIndex].Text = ':') and
        (AResult[LNextIndex + 1].Text = ':')) then
        LToken.Kind := ttkNamespace;
      if LToken.Kind = ttkString then
        LToken.Kind := ttkMethodName;
    end;
    AResult[LIndex] := LToken;
  end;
end;

procedure TTinyParser.ApplyExtractedStringMode(AResult: TTinyTokenList);
begin
  // A Strings table is mixed content.  Unlike a dedicated method view, it
  // must not promote every plain word to a method.  Preserve only structure
  // that can be established from syntax.
  PromoteItaniumGeneratedOwners(AResult);
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
        (AResult[LPreviousIndex].Text = '.');
      if not LIsQualifiedIdentifier then
        LIsQualifiedIdentifier := (LPreviousIndex >= 0) and
          (AResult[LPreviousIndex].Text = ':');
      if LIsQualifiedIdentifier and (AResult[LPreviousIndex].Text = ':') then
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
      else if IsCppBuilderTypeName(LToken.Text) or
        (LIsQualifiedIdentifier and CharInSet(LToken.Text[1], ['A'..'Z'])) then
        LToken.Kind := ttkTypeName
      else if ((LNextIndex < AResult.Count) and
        (AResult[LNextIndex].Text = '.')) or
        ((LNextIndex + 1 < AResult.Count) and
        (AResult[LNextIndex].Text = ':') and
        (AResult[LNextIndex + 1].Text = ':')) then
        LToken.Kind := ttkNamespace;
    end;
    AResult[LIndex] := LToken;
  end;
end;

procedure TTinyParser.ApplyELFRelocationMode(AResult: TTinyTokenList);
begin
  // ELF relocation rows have a stable column layout.  Apply the same
  // semantics used by the structured relocation grid, but only after the
  // first two fields positively identify a relocation row.
  var LFirstTokenIndex := -1;
  var LSecondTokenIndex := -1;
  for var LIndex := 0 to AResult.Count - 1 do
    if AResult[LIndex].Kind <> ttkWhitespace then
      if LFirstTokenIndex < 0 then
        LFirstTokenIndex := LIndex
      else
      begin
        LSecondTokenIndex := LIndex;
        Break;
      end;

  if (LFirstTokenIndex < 0) or (LSecondTokenIndex < 0) or
    (AResult[LFirstTokenIndex].Kind <> ttkInteger) or
    not StartsText('R_', AResult[LSecondTokenIndex].Text) then
    Exit;

  var LFieldIndex := 0;
  for var LIndex := 0 to AResult.Count - 1 do
  begin
    var LToken := AResult[LIndex];
    if LToken.Kind = ttkWhitespace then
      Continue;
    case LFieldIndex of
      0, 5:
        LToken.Kind := ttkInteger;
      1:
        LToken.Kind := ttkSymbol;
      2..4, 6:
        LToken.Kind := ttkHexadecimal;
    else
      // The final name cell is rendered in the grid's semantic method mode.
      // Only promote textual tokens so punctuation in versioned names remains
      // symbol-colored.
      if LToken.Kind = ttkString then
        LToken.Kind := ttkMethodName;
    end;
    AResult[LIndex] := LToken;
    Inc(LFieldIndex);
  end;
end;

procedure TTinyParser.ApplyOMFRecordMode(AResult: TTinyTokenList);
  function IsOMFLabel(const AText: string): Boolean;
  begin
    Result := MatchText(AText, ['FixUp', 'Mode', 'Loc', 'Frame', 'Target',
      'Segment', 'Offset', 'Length', 'Type', 'Purpose', 'List', 'Class',
      'SubClass', 'Record', 'Purge', 'Imported', 'by', 'Internal', 'Name',
      'Module', 'Detail']);
  end;

  function IsUppercaseSymbol(const AText: string): Boolean;
  begin
    Result := Length(AText) > 1;
    if not Result then
      Exit;
    for var LCharacter in AText do
      if not CharInSet(LCharacter, ['A'..'Z', '0'..'9', '_']) then
        Exit(False);
  end;

  function NextVisibleToken(AIndex: Integer): Integer;
  begin
    Inc(AIndex);
    while (AIndex < AResult.Count) and
      (AResult[AIndex].Kind = ttkWhitespace) do
      Inc(AIndex);
    if AIndex < AResult.Count then
      Result := AIndex
    else
      Result := -1;
  end;

  procedure PromoteValueAfterLabel(const AFirstLabel, ASecondLabel: string;
    AKind: TTinyTokenKind);
  begin
    for var LIndex := 0 to AResult.Count - 1 do
    begin
      if not SameText(AResult[LIndex].Text, AFirstLabel) then
        Continue;
      var LSecondIndex := NextVisibleToken(LIndex);
      if (LSecondIndex < 0) or
        not SameText(AResult[LSecondIndex].Text, ASecondLabel) then
        Continue;
      var LColonIndex := NextVisibleToken(LSecondIndex);
      if (LColonIndex < 0) or (AResult[LColonIndex].Text <> ':') then
        Continue;
      var LValueIndex := NextVisibleToken(LColonIndex);
      while LValueIndex >= 0 do
      begin
        var LValueToken := AResult[LValueIndex];
        if LValueToken.Kind in [ttkString, ttkNamespace, ttkTypeName] then
        begin
          LValueToken.Kind := AKind;
          AResult[LValueIndex] := LValueToken;
        end;
        LValueIndex := NextVisibleToken(LValueIndex);
      end;
    end;
  end;

  procedure PromoteTheadrModule;
  begin
    for var LIndex := 0 to AResult.Count - 1 do
      if SameText(AResult[LIndex].Text, 'THEADR') then
      begin
        var LValueIndex := NextVisibleToken(LIndex);
        if (LValueIndex >= 0) and (AResult[LValueIndex].Kind in
          [ttkString, ttkNamespace, ttkTypeName]) then
        begin
          var LValueToken := AResult[LValueIndex];
          LValueToken.Kind := ttkSymbol;
          AResult[LValueIndex] := LValueToken;
        end;
      end;
  end;

  procedure PromoteModuleFileNames;
  begin
    for var LIndex := 0 to AResult.Count - 1 do
    begin
      var LDotIndex := NextVisibleToken(LIndex);
      if (LDotIndex < 0) or (AResult[LDotIndex].Text <> '.') then
        Continue;
      var LExtensionIndex := NextVisibleToken(LDotIndex);
      if (LExtensionIndex < 0) or not MatchText(AResult[LExtensionIndex].Text,
        ['dll', 'drv', 'ocx', 'exe']) then
        Continue;
      if AResult[LIndex].Kind in [ttkString, ttkNamespace, ttkTypeName] then
      begin
        var LNameToken := AResult[LIndex];
        LNameToken.Kind := ttkSymbol;
        AResult[LIndex] := LNameToken;
      end;
      if AResult[LExtensionIndex].Kind in
        [ttkString, ttkNamespace, ttkTypeName] then
      begin
        var LExtensionToken := AResult[LExtensionIndex];
        LExtensionToken.Kind := ttkSymbol;
        AResult[LExtensionIndex] := LExtensionToken;
      end;
    end;
  end;

  procedure PromoteStandaloneMethod;
  begin
    var LTokenIndex := -1;
    for var LIndex := 0 to AResult.Count - 1 do
      if AResult[LIndex].Kind <> ttkWhitespace then
      begin
        if LTokenIndex >= 0 then
          Exit;
        LTokenIndex := LIndex;
      end;
    if (LTokenIndex < 0) or (AResult[LTokenIndex].Kind <> ttkString) or
      (Length(AResult[LTokenIndex].Text) < 3) or
      not CharInSet(AResult[LTokenIndex].Text[1], ['A'..'Z']) then
      Exit;

    var LUppercaseCount := 0;
    var LHasLowercase := False;
    for var LCharacter in AResult[LTokenIndex].Text do
    begin
      LUppercaseCount := LUppercaseCount + Ord(CharInSet(LCharacter,
        ['A'..'Z']));
      LHasLowercase := LHasLowercase or CharInSet(LCharacter, ['a'..'z']);
    end;
    if (LUppercaseCount >= 2) and LHasLowercase then
    begin
      var LMethodToken := AResult[LTokenIndex];
      LMethodToken.Kind := ttkMethodName;
      AResult[LTokenIndex] := LMethodToken;
    end;
  end;

begin
  // OMF rows mix plain record metadata with embedded C++Builder names.  The
  // conservative extracted-string mode handles the latter without turning
  // descriptive field values into methods; add the OMF record vocabulary on
  // top for the structural portions of the row.
  ApplyExtractedStringMode(AResult);
  for var LIndex := 0 to AResult.Count - 1 do
  begin
    var LToken := AResult[LIndex];
    if IsOMFLabel(LToken.Text) then
      LToken.Kind := ttkKeyword
    else if (LToken.Kind = ttkString) and
      (IsUppercaseSymbol(LToken.Text) or StartsText('_', LToken.Text)) then
      LToken.Kind := ttkSymbol;
    AResult[LIndex] := LToken;
  end;
  PromoteTheadrModule;
  PromoteModuleFileNames;
  PromoteValueAfterLabel('Internal', 'Name', ttkMethodName);
  PromoteValueAfterLabel('Module', 'Name', ttkSymbol);
  PromoteStandaloneMethod;
end;

procedure TTinyParser.ApplyOMFLEDataMode(AResult: TTinyTokenList);
  function IsHexText(const AText: string): Boolean;
  begin
    Result := AText <> '';
    for var LCharacter in AText do
      if not CharInSet(LCharacter, ['0'..'9', 'A'..'F', 'a'..'f']) then
        Exit(False);
  end;

begin
  // LEDATA rows have three stable visual columns: offset, byte payload, and
  // printable ASCII.  Keep RAW output consistent with the structured grid.
  var LOffsetIndex := -1;
  var LColonIndex := -1;
  for var LIndex := 0 to AResult.Count - 1 do
    if AResult[LIndex].Kind <> ttkWhitespace then
      if LOffsetIndex < 0 then
        LOffsetIndex := LIndex
      else
      begin
        LColonIndex := LIndex;
        Break;
      end;
  if (LOffsetIndex < 0) or (LColonIndex < 0) or
    not IsHexText(AResult[LOffsetIndex].Text) or
    (AResult[LColonIndex].Text <> ':') then
    Exit;

  var LOffsetToken := AResult[LOffsetIndex];
  LOffsetToken.Kind := ttkHexadecimal;
  AResult[LOffsetIndex] := LOffsetToken;
  var LInASCII := False;
  var LByteCount := 0;
  for var LIndex := LColonIndex + 1 to AResult.Count - 1 do
  begin
    var LToken := AResult[LIndex];
    if LInASCII then
    begin
      if LToken.Kind <> ttkWhitespace then
        LToken.Kind := ttkString;
    end
    else if LToken.Kind = ttkWhitespace then
    begin
      if (LByteCount > 0) and (Length(LToken.Text) >= 3) then
        LInASCII := True;
    end
    else if (Length(LToken.Text) = 2) and IsHexText(LToken.Text) then
    begin
      LToken.Kind := ttkHexadecimal;
      Inc(LByteCount);
    end
    else
      Exit;
    AResult[LIndex] := LToken;
  end;
end;

procedure TTinyParser.ApplyPEImportPropertyMode(AResult: TTinyTokenList);
begin
  // TDUMP emits import-descriptor addresses as bare eight-digit values.  A
  // value such as 40347540 is hexadecimal even though it happens not to
  // contain A..F, so the lexical default alone cannot distinguish it from a
  // decimal number.  This mode is applied only to parser-confirmed PE import
  // property rows, keeping ordinary report counts numeric.
  for var LIndex := 0 to AResult.Count - 1 do
  begin
    var LToken := AResult[LIndex];
    if (LToken.Kind = ttkInteger) and (Length(LToken.Text) = 8) and
      (LToken.Text[1] <> '-') then
    begin
      LToken.Kind := ttkHexadecimal;
      AResult[LIndex] := LToken;
    end;
  end;
end;

procedure TTinyParser.ApplyMachLinkerMode(AResult: TTinyTokenList);
begin
  PromoteItaniumGeneratedOwners(AResult);
  for var LIndex := 0 to AResult.Count - 1 do
  begin
    var LToken := AResult[LIndex];
    if LToken.Kind <> ttkString then
      Continue;

    if IsMachLinkerKeyword(LToken.Text) then
      LToken.Kind := ttkKeyword
    else if StartsText('_', LToken.Text) then
      LToken.Kind := ttkMethodName
    else
    begin
      var LPreviousIndex := LIndex - 1;
      while (LPreviousIndex >= 0) and
        (AResult[LPreviousIndex].Kind = ttkWhitespace) do
        Dec(LPreviousIndex);
      if (LPreviousIndex >= 0) and (AResult[LPreviousIndex].Text = ':') then
      begin
        Dec(LPreviousIndex);
        while (LPreviousIndex >= 0) and
          (AResult[LPreviousIndex].Kind = ttkWhitespace) do
          Dec(LPreviousIndex);
        if (LPreviousIndex >= 0) and
          SameText(AResult[LPreviousIndex].Text, 'symbol') then
          LToken.Kind := ttkMethodName;
      end;
      if LToken.Kind = ttkString then
      begin
        var LNextIndex := LIndex + 1;
        while (LNextIndex < AResult.Count) and
          (AResult[LNextIndex].Kind = ttkWhitespace) do
          Inc(LNextIndex);
        if (LNextIndex < AResult.Count) and
          (AResult[LNextIndex].Text = '(') then
          LToken.Kind := ttkMethodName
        else if (LNextIndex + 1 < AResult.Count) and
          (AResult[LNextIndex].Text = ':') and
          (AResult[LNextIndex + 1].Text = ':') then
          LToken.Kind := ttkNamespace
        else if IsCppBuilderTypeName(LToken.Text) then
          LToken.Kind := ttkTypeName;
      end;
    end;
    AResult[LIndex] := LToken;
  end;
end;

procedure TTinyParser.PromoteItaniumGeneratedOwners(AResult: TTinyTokenList);
begin
  for var LIndex := 0 to AResult.Count - 1 do
  begin
    var LToken := AResult[LIndex];
    if (LToken.Kind <> ttkMethodName) or
      not MatchText(LToken.Text, ['cctr', 'cdtr']) then
      Continue;

    // These are Delphi compiler member markers, not source-level methods.
    // Give them a semantic color even when there is no generic owner to
    // promote below.
    LToken.Kind := ttkKeyword;
    AResult[LIndex] := LToken;

    // Delphi's Mach-O generic constructor/destructor encoding makes
    // cctr/cdtr look like the final Itanium component.  The actual user
    // facing symbol is the preceding generic owner, whose compiler suffix
    // ends in __2.  Promote that owner and its recognisable template types.
    for var LOwnerIndex := LIndex - 1 downto 0 do
    begin
      var LOwnerToken := AResult[LOwnerIndex];
      if (LOwnerToken.Kind in [ttkNamespace, ttkTypeName]) and
        ContainsText(LOwnerToken.Text, '__') then
      begin
        LOwnerToken.Kind := ttkTypeName;
        AResult[LOwnerIndex] := LOwnerToken;
        for var LTemplateIndex := LOwnerIndex + 1 to LIndex - 1 do
        begin
          var LTemplateToken := AResult[LTemplateIndex];
          if (LTemplateToken.Kind = ttkNamespace) and
            (IsCppBuilderTypeName(LTemplateToken.Text) or
             StartsText('NS', LTemplateToken.Text) or
             EndsText('Class', LTemplateToken.Text) or
             EndsText('Interface', LTemplateToken.Text)) then
          begin
            LTemplateToken.Kind := ttkTypeName;
            AResult[LTemplateIndex] := LTemplateToken;
          end;
        end;
        Break;
      end;
    end;
  end;
end;

class function TTinyParser.IsDateSeparator(ACharacter: Char): Boolean;
begin
  Result := CharInSet(ACharacter, ['-', '/', '.']);
end;

class function TTinyParser.IsCppBuilderKeyword(const AText: string): Boolean;
begin
  Result := MatchText(AText, ['__cdecl', '__fastcall', '__linkproc__',
    '__stdcall', '__thiscall', 'const', 'volatile']);
end;

class function TTinyParser.IsCppBuilderTypeName(const AText: string): Boolean;
begin
  Result := MatchText(AText, ['signed', 'unsigned', 'short', 'long', 'void',
    'char', 'int', 'float', 'double', 'bool', 'wchar_t',
    // Delphi system types also appear verbatim in the demangled Mach report.
    // Keep their classification independent of whether the same type was
    // recovered from an Itanium source-name component.
    'string', 'AnsiString', 'RawByteString', 'ShortString', 'UnicodeString',
    'WideString', 'Variant', 'OleVariant', 'Currency', 'Extended', 'Real',
    'Real48', 'Comp', 'Single', 'NativeInt', 'NativeUInt', 'Integer',
    'Cardinal', 'Int64', 'UInt64', 'Byte', 'Word', 'LongWord', 'LongInt',
    'ShortInt', 'SmallInt', 'Boolean', 'ByteBool', 'WordBool', 'LongBool',
    'Char', 'AnsiChar', 'WideChar', 'PChar', 'PAnsiChar', 'PWideChar',
    // TDUMP preserves two legacy suffix bytes from the Delphi RTL string
    // table. They still denote pointer types, not separate identifiers.
    'PAnsiChar0', 'PWideCharL', 'PFixedUInt', 'HRESULT', 'Pointer']) or
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

class function TTinyParser.IsItaniumSpecialMember(const AText: string;
  AStartIndex: Integer): Boolean;
begin
  Result := IsTextInRange(AText, AStartIndex, 3) and
    (AText[AStartIndex + 2] = 'E') and
    (((AText[AStartIndex] = 'C') and
      CharInSet(AText[AStartIndex + 1], ['1'..'3'])) or
     ((AText[AStartIndex] = 'D') and
      CharInSet(AText[AStartIndex + 1], ['0'..'2'])));
end;

class function TTinyParser.IsMachLinkerKeyword(const AText: string): Boolean;
begin
  Result := StartsText('BIND_OPCODE_', AText) or
    StartsText('REBASE_OPCODE_', AText) or
    MatchText(AText, ['symbol', 'flags', 'addr', 'seg', 'ordinal', 'dylib']);
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
  Tokenize(AText, AMode, Result);
end;

procedure TTinyParser.Tokenize(const AText: string; AMode: TTinyParserMode;
  AResult: TTinyTokenList);
begin
  AResult.Clear;
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
      AddToken(AResult, ttkWhitespace, AText, LStartIndex, LIndex);
      Continue;
    end;

    var LEndIndex := 0;
    if TryReadQuotedString(AText, LIndex, LEndIndex) then
    begin
      AddToken(AResult, ttkStringLiteral, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    var LMethodStartIndex := 0;
    var LMethodEndIndex := 0;
    // Strings extracted from an image can retain one byte immediately before
    // a valid Borland linker name (for example Y@System@...).  That byte is
    // extraction residue, never a source-level method identifier.
    if (LIndex < Length(AText)) and (AText[LIndex + 1] = '@') and
      TryReadBorlandMethod(AText, LIndex + 1, LMethodStartIndex,
        LMethodEndIndex, LEndIndex) then
    begin
      AddToken(AResult, ttkMangledSignature, AText, LStartIndex,
        LStartIndex + 1);
      AddBorlandOwnerTokens(AResult, AText, LIndex + 1, LMethodStartIndex);
      AddToken(AResult, ttkMethodName, AText, LMethodStartIndex,
        LMethodEndIndex);
      if LMethodEndIndex < LEndIndex then
        AddBorlandSignatureTokens(AResult, AText, LMethodEndIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    if TryReadBorlandMethod(AText, LIndex, LMethodStartIndex,
      LMethodEndIndex, LEndIndex) then
    begin
      if LStartIndex < LMethodStartIndex then
        AddBorlandOwnerTokens(AResult, AText, LStartIndex, LMethodStartIndex);
      AddToken(AResult, ttkMethodName, AText, LMethodStartIndex,
        LMethodEndIndex);
      if LMethodEndIndex < LEndIndex then
        AddBorlandSignatureTokens(AResult, AText, LMethodEndIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    if TryReadItaniumMethod(AText, LIndex, LMethodStartIndex,
      LMethodEndIndex, LEndIndex) then
    begin
      AddItaniumNestedNameTokens(AResult, AText, LStartIndex,
        LMethodStartIndex);
      if IsItaniumSpecialMember(AText, LMethodEndIndex) then
        AddToken(AResult, ttkTypeName, AText, LMethodStartIndex,
          LMethodEndIndex)
      else
        AddToken(AResult, ttkMethodName, AText, LMethodStartIndex,
          LMethodEndIndex);
      if LMethodEndIndex < LEndIndex then
        AddItaniumSignatureTokens(AResult, AText, LMethodEndIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    if TryReadItaniumType(AText, LIndex, LMethodStartIndex,
      LMethodEndIndex, LEndIndex) then
    begin
      AddItaniumNestedNameTokens(AResult, AText, LStartIndex,
        LMethodStartIndex);
      AddToken(AResult, ttkTypeName, AText, LMethodStartIndex,
        LMethodEndIndex);
      if LMethodEndIndex < LEndIndex then
        AddItaniumSignatureTokens(AResult, AText, LMethodEndIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    if TryReadDateTime(AText, LIndex, LEndIndex) then
    begin
      AddToken(AResult, ttkDateTime, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    if TryReadDate(AText, LIndex, LEndIndex) then
    begin
      AddToken(AResult, ttkDate, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    if TryReadTime(AText, LIndex, LEndIndex) then
    begin
      AddToken(AResult, ttkTime, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;
    if TryReadHexadecimal(AText, LIndex, LEndIndex) then
    begin
      AddToken(AResult, ttkHexadecimal, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;

    var LNumberKind := ttkInteger;
    if TryReadNumber(AText, LIndex, LEndIndex, LNumberKind) then
    begin
      AddToken(AResult, LNumberKind, AText, LStartIndex, LEndIndex);
      LIndex := LEndIndex;
      Continue;
    end;

    if CharInSet(LCharacter, ['0'..'9']) then
    begin
      repeat
        Inc(LIndex);
      until (LIndex > Length(AText)) or not IsIdentifierCharacter(AText[LIndex]);
      AddToken(AResult, ttkString, AText, LStartIndex, LIndex);
      Continue;
    end;

    if IsIdentifierStart(LCharacter) then
    begin
      repeat
        Inc(LIndex);
      until (LIndex > Length(AText)) or not IsIdentifierCharacter(AText[LIndex]);
      AddToken(AResult, ttkString, AText, LStartIndex, LIndex);
      Continue;
    end;

    Inc(LIndex);
    AddToken(AResult, ttkSymbol, AText, LStartIndex, LIndex);
  end;
  case AMode of
    tpmCppBuilderMethod:
      ApplyCppBuilderMethodMode(AResult);
    tpmMachLinker:
      ApplyMachLinkerMode(AResult);
    tpmExtractedString:
      ApplyExtractedStringMode(AResult);
    tpmELFRelocation:
      ApplyELFRelocationMode(AResult);
    tpmOMFRecord:
      ApplyOMFRecordMode(AResult);
    tpmOMFLEData:
      ApplyOMFLEDataMode(AResult);
    tpmPEImportProperty:
      ApplyPEImportPropertyMode(AResult);
  end;
end;

procedure TTinyParser.AddItaniumNestedNameTokens(AResult: TTinyTokenList;
  const AText: string; AStartIndex, ANameStartIndex: Integer);
begin
  var LIndex := AStartIndex;
  while (LIndex < ANameStartIndex) and (AText[LIndex] = '_') do
    Inc(LIndex);
  if (LIndex < ANameStartIndex) and (AText[LIndex] = 'Z') then
  begin
    Inc(LIndex);
    if (LIndex + 2 < ANameStartIndex) and
      (Copy(AText, LIndex, 3) = 'TRN') then
      Inc(LIndex, 3)
    else if (LIndex < ANameStartIndex) and (AText[LIndex] = 'N') then
      Inc(LIndex);
  end;

  var LCursor := AStartIndex;
  while LIndex < ANameStartIndex do
  begin
    // A substitution can include digits (S3_, S4_, ...).  It is not a
    // length-prefixed source name, so consume it before looking for the next
    // actual component in a nested generic linker name.
    if AText[LIndex] = 'S' then
    begin
      Inc(LIndex);
      while (LIndex < ANameStartIndex) and
        CharInSet(AText[LIndex], ['0'..'9', 'A'..'Z']) do
        Inc(LIndex);
      if (LIndex < ANameStartIndex) and (AText[LIndex] = '_') then
        Inc(LIndex);
      Continue;
    end;
    if not CharInSet(AText[LIndex], ['0'..'9']) then
    begin
      Inc(LIndex);
      Continue;
    end;

    var LLengthStart := LIndex;
    repeat
      Inc(LIndex);
    until (LIndex >= ANameStartIndex) or
      not CharInSet(AText[LIndex], ['0'..'9']);
    var LComponentLength: Integer;
    if not TryStrToInt(Copy(AText, LLengthStart, LIndex - LLengthStart),
      LComponentLength) or (LComponentLength <= 0) or
      (LIndex + LComponentLength > ANameStartIndex) then
      Continue;

    if LCursor < LIndex then
      AddToken(AResult, ttkMangledSignature, AText, LCursor, LIndex);
    var LComponentText := Copy(AText, LIndex, LComponentLength);
    if IsCppBuilderTypeName(LComponentText) or
      StartsText('NS', LComponentText) or
      EndsText('Class', LComponentText) or
      EndsText('Interface', LComponentText) then
      AddToken(AResult, ttkTypeName, AText, LIndex,
        LIndex + LComponentLength)
    else
      AddToken(AResult, ttkNamespace, AText, LIndex,
        LIndex + LComponentLength);
    Inc(LIndex, LComponentLength);
    LCursor := LIndex;
  end;
  if LCursor < ANameStartIndex then
    AddToken(AResult, ttkMangledSignature, AText, LCursor, ANameStartIndex);
end;

procedure TTinyParser.AddItaniumSignatureTokens(AResult: TTinyTokenList;
  const AText: string; AStartIndex, AEndIndex: Integer);
begin
  var LCursor := AStartIndex;
  var LIndex := AStartIndex;
  while LIndex < AEndIndex do
  begin
    // Itanium substitutions use S..._ and can contain digits.  Consume the
    // complete substitution before scanning length-prefixed source names, so
    // S2_7Classes is tokenized as the substitution plus Classes—not _7.
    if AText[LIndex] = 'S' then
    begin
      Inc(LIndex);
      while (LIndex < AEndIndex) and
        CharInSet(AText[LIndex], ['0'..'9', 'A'..'Z']) do
        Inc(LIndex);
      if (LIndex < AEndIndex) and (AText[LIndex] = '_') then
        Inc(LIndex);
      Continue;
    end;
    if not CharInSet(AText[LIndex], ['0'..'9']) then
    begin
      Inc(LIndex);
      Continue;
    end;

    var LLengthStart := LIndex;
    repeat
      Inc(LIndex);
    until (LIndex >= AEndIndex) or not CharInSet(AText[LIndex], ['0'..'9']);
    var LComponentLength: Integer;
    if not TryStrToInt(Copy(AText, LLengthStart, LIndex - LLengthStart),
      LComponentLength) or (LComponentLength <= 0) or
      (LIndex + LComponentLength > AEndIndex) then
      Continue;

    if LCursor < LIndex then
      AddToken(AResult, ttkMangledSignature, AText, LCursor, LIndex);
    var LComponentEndIndex := LIndex + LComponentLength;
    // In an N...E nested name, consecutive source names are owners.  The
    // final source name (before I/E) is the type; previous components remain
    // namespaces.  This preserves System::Set<Classes::TShiftStateItem>.
    if (LComponentEndIndex < AEndIndex) and
      CharInSet(AText[LComponentEndIndex], ['0'..'9']) then
      AddToken(AResult, ttkNamespace, AText, LIndex, LComponentEndIndex)
    else
      AddToken(AResult, ttkTypeName, AText, LIndex, LComponentEndIndex);
    Inc(LIndex, LComponentLength);
    LCursor := LIndex;
  end;
  if LCursor < AEndIndex then
    AddToken(AResult, ttkMangledSignature, AText, LCursor, AEndIndex);
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

class function TTinyParser.TryReadBorlandMethod(const AText: string;
  AStartIndex: Integer; out AMethodStartIndex, AMethodEndIndex,
  AEndIndex: Integer): Boolean;
begin
  Result := False;
  AMethodStartIndex := AStartIndex;
  AMethodEndIndex := AStartIndex;
  AEndIndex := AStartIndex;
  if (AStartIndex > Length(AText)) or (AText[AStartIndex] <> '@') then
    Exit;

  var LIndex := AStartIndex + 1;
  var LMethodStart := LIndex;
  var LInSignature := False;
  while LIndex <= Length(AText) do
  begin
    if AText[LIndex] = '$' then
    begin
      LInSignature := True;
      Inc(LIndex);
      Continue;
    end;
    if (AText[LIndex] = '\') and (LIndex < Length(AText)) and
      (AText[LIndex + 1] = '@') then
    begin
      if (LIndex + 2 <= Length(AText)) and
        IsIdentifierStart(AText[LIndex + 2]) then
        LMethodStart := LIndex + 2;
      Inc(LIndex, 2);
      Continue;
    end;
    if (AText[LIndex] = '@') and (LIndex > AStartIndex + 1) then
    begin
      if not LInSignature and (LIndex + 1 <= Length(AText)) and
        IsIdentifierStart(AText[LIndex + 1]) then
        LMethodStart := LIndex + 1;
      Inc(LIndex);
      Continue;
    end;
    if not (IsIdentifierCharacter(AText[LIndex]) or
      CharInSet(AText[LIndex], ['.', '@', '\', '%', '$'])) then
      Break;
    Inc(LIndex);
  end;

  var LNameEnd := LIndex;

  if LMethodStart = 0 then
    Exit;
  while (LMethodStart <= Length(AText)) and (AText[LMethodStart] = '@') do
    Inc(LMethodStart);
  if (LMethodStart > Length(AText)) or
    not IsIdentifierStart(AText[LMethodStart]) then
    Exit;

  LIndex := LMethodStart;
  while (LIndex <= Length(AText)) and IsIdentifierCharacter(AText[LIndex]) do
    Inc(LIndex);
  AMethodStartIndex := LMethodStart;
  AMethodEndIndex := LIndex;
  if AMethodEndIndex > AMethodStartIndex then
  begin
    // The first scan already consumed the whole linker name, including any
    // generic instantiation and mangled suffix.
    AEndIndex := LNameEnd;
    Result := True;
  end;
end;

class function TTinyParser.TryReadItaniumMethod(const AText: string;
  AStartIndex: Integer; out AMethodStartIndex, AMethodEndIndex,
  AEndIndex: Integer): Boolean;
begin
  Result := TryReadItaniumNestedName(AText, AStartIndex, 'ZN',
    AMethodStartIndex, AMethodEndIndex, AEndIndex);
  if not Result then
    Exit;

  var LIndex := AEndIndex;
  while (LIndex <= Length(AText)) and
    (IsIdentifierCharacter(AText[LIndex]) or (AText[LIndex] = '$')) do
    Inc(LIndex);
  AEndIndex := LIndex;
  Result := True;
end;

class function TTinyParser.TryReadItaniumType(const AText: string;
  AStartIndex: Integer; out ATypeStartIndex, ATypeEndIndex,
  AEndIndex: Integer): Boolean;
begin
  Result := TryReadItaniumNestedName(AText, AStartIndex, 'ZTRN',
    ATypeStartIndex, ATypeEndIndex, AEndIndex);
  if not Result then
    Result := TryReadItaniumNestedName(AText, AStartIndex, 'ZTVN',
      ATypeStartIndex, ATypeEndIndex, AEndIndex);
  if not Result then
    Result := TryReadItaniumNestedName(AText, AStartIndex, 'ZTIN',
      ATypeStartIndex, ATypeEndIndex, AEndIndex);
  if not Result then
    Result := TryReadItaniumNestedName(AText, AStartIndex, 'ZTSN',
      ATypeStartIndex, ATypeEndIndex, AEndIndex);
end;

class function TTinyParser.TryReadItaniumNestedName(const AText: string;
  AStartIndex: Integer; const APrefix: string; out ANameStartIndex,
  ANameEndIndex, AEndIndex: Integer): Boolean;
begin
  Result := False;
  ANameStartIndex := AStartIndex;
  ANameEndIndex := AStartIndex;
  AEndIndex := AStartIndex;

  var LPrefixIndex := AStartIndex;
  while (LPrefixIndex <= Length(AText)) and (AText[LPrefixIndex] = '_') do
    Inc(LPrefixIndex);
  if not IsTextInRange(AText, LPrefixIndex, Length(APrefix)) or
    (Copy(AText, LPrefixIndex, Length(APrefix)) <> APrefix) then
    Exit;

  var LIndex := LPrefixIndex + Length(APrefix);
  var LLastComponentStart := 0;
  var LLastComponentEnd := 0;
  var LScopes := TList<Char>.Create;
  try
    while LIndex <= Length(AText) do
    begin
      if (LScopes.Count = 0) and IsItaniumSpecialMember(AText, LIndex) then
      begin
        Inc(LIndex, 2);
        Continue;
      end;
      if CharInSet(AText[LIndex], ['0'..'9']) then
      begin
        var LLengthStart := LIndex;
        repeat
          Inc(LIndex);
        until (LIndex > Length(AText)) or
          not CharInSet(AText[LIndex], ['0'..'9']);
        var LComponentLength: Integer;
        if not TryStrToInt(Copy(AText, LLengthStart, LIndex - LLengthStart),
          LComponentLength) or (LComponentLength <= 0) or
          (LIndex + LComponentLength - 1 > Length(AText)) then
          Exit;
        if LScopes.Count = 0 then
          LLastComponentStart := LIndex;
        Inc(LIndex, LComponentLength);
        if LScopes.Count = 0 then
          LLastComponentEnd := LIndex;
        Continue;
      end;

      case AText[LIndex] of
        'E':
          begin
            if LScopes.Count = 0 then
            begin
              if LLastComponentStart = 0 then
                Exit;
              ANameStartIndex := LLastComponentStart;
              ANameEndIndex := LLastComponentEnd;
              AEndIndex := LIndex + 1;
              Result := True;
              Exit;
            end;
            LScopes.Delete(LScopes.Count - 1);
            Inc(LIndex);
          end;
        'I', 'N', 'F', 'L', 'X', 'Z':
          begin
            LScopes.Add(AText[LIndex]);
            Inc(LIndex);
          end;
        'S':
          begin
            Inc(LIndex);
            if (LIndex <= Length(AText)) and
              CharInSet(AText[LIndex], ['a'..'z']) then
              Inc(LIndex)
            else
            begin
              while (LIndex <= Length(AText)) and
                CharInSet(AText[LIndex], ['0'..'9', 'A'..'Z']) do
                Inc(LIndex);
              if (LIndex <= Length(AText)) and (AText[LIndex] = '_') then
                Inc(LIndex);
            end;
          end;
      else
        Inc(LIndex);
      end;
    end;
  finally
    LScopes.Free;
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

class function TTinyParser.TryReadQuotedString(const AText: string;
  AStartIndex: Integer; out AEndIndex: Integer): Boolean;
begin
  Result := False;
  AEndIndex := AStartIndex;
  if (AStartIndex > Length(AText)) or
    not CharInSet(AText[AStartIndex], ['''', '"']) then
    Exit;

  var LQuote := AText[AStartIndex];
  var LIndex := AStartIndex + 1;
  while LIndex <= Length(AText) do
  begin
    if (AText[LIndex] = '\') and (LIndex < Length(AText)) then
      Inc(LIndex, 2)
    else if AText[LIndex] = LQuote then
    begin
      Inc(LIndex);
      if (LIndex <= Length(AText)) and (AText[LIndex] = LQuote) then
        Inc(LIndex)
      else
        Break;
    end
    else
      Inc(LIndex);
  end;
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
