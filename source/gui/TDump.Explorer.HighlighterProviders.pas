//**************************************************************************************************
//
// Unit TDump.Explorer.HighlighterProviders
//
// Indexed row providers for highlighter controls.
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.HighlighterProviders;

interface

uses
  System.Generics.Collections,
  TDump.Explorer.Parser,
  TDump.Explorer.HighlighterControl;

type
  THighlighterTextGetter = reference to function(AIndex: Integer): string;
  THighlighterIntegerGetter = reference to function(AIndex: Integer): Integer;
  THighlighterLineFilter = reference to function(const ALine: string): Boolean;

  // General virtual provider used by semantic tables. It retains the model and
  // row access callbacks, never a second set of display strings.
  TCallbackHighlighterRowProvider = class(TInterfacedObject,
    IHighlighterRowProvider)
  private
    FCount: Integer;
    FTextGetter: THighlighterTextGetter;
    FImageNameGetter: THighlighterTextGetter;
    FParserModeGetter: THighlighterIntegerGetter;
    FLineNumberGetter: THighlighterIntegerGetter;
  public
    constructor Create(ACount: Integer; const ATextGetter: THighlighterTextGetter;
      const AImageNameGetter: THighlighterTextGetter = nil;
      const AParserModeGetter: THighlighterIntegerGetter = nil;
      const ALineNumberGetter: THighlighterIntegerGetter = nil);
    function GetCount: Integer;
    function GetText(AIndex: Integer): string;
    function GetImageName(AIndex: Integer): string;
    function GetParserMode(AIndex: Integer): Integer;
    function GetLineNumber(AIndex: Integer): Integer;
  end;

  // Retains source indexes only. Text is decoded from the document mapping for
  // the row that TControlList is currently painting, copying, or measuring.
  TDocumentLineRowProvider = class(TInterfacedObject,
    IHighlighterRowProvider)
  private
    FDocument: TDumpDocument;
    FFirstIndex: Integer;
    FCount: Integer;
    FIndexes: TList<Integer>;
    FOwnsIndexes: Boolean;
    function SourceIndex(AIndex: Integer): Integer;
  public
    constructor CreateRange(ADocument: TDumpDocument; AFirstIndex,
      ACount: Integer);
    constructor CreateFilteredRange(ADocument: TDumpDocument; AFirstIndex,
      ACount: Integer; const ALineFilter: THighlighterLineFilter);
    constructor CreateIndexes(ADocument: TDumpDocument;
      AIndexes: TList<Integer>);
    destructor Destroy; override;
    function GetCount: Integer;
    function GetText(AIndex: Integer): string;
    function GetImageName(AIndex: Integer): string;
    function GetParserMode(AIndex: Integer): Integer;
    function GetLineNumber(AIndex: Integer): Integer;
  end;

implementation

uses
  System.Math,
  TDump.Explorer.TinyParser;

constructor TCallbackHighlighterRowProvider.Create(ACount: Integer;
  const ATextGetter: THighlighterTextGetter;
  const AImageNameGetter: THighlighterTextGetter;
  const AParserModeGetter, ALineNumberGetter: THighlighterIntegerGetter);
begin
  inherited Create;
  FCount := Max(0, ACount);
  FTextGetter := ATextGetter;
  FImageNameGetter := AImageNameGetter;
  FParserModeGetter := AParserModeGetter;
  FLineNumberGetter := ALineNumberGetter;
end;

function TCallbackHighlighterRowProvider.GetCount: Integer;
begin
  Result := FCount;
end;

function TCallbackHighlighterRowProvider.GetText(AIndex: Integer): string;
begin
  if Assigned(FTextGetter) and (AIndex >= 0) and (AIndex < FCount) then
    Exit(FTextGetter(AIndex));
  Result := '';
end;

function TCallbackHighlighterRowProvider.GetImageName(AIndex: Integer): string;
begin
  if Assigned(FImageNameGetter) then
    Exit(FImageNameGetter(AIndex));
  Result := '';
end;

function TCallbackHighlighterRowProvider.GetParserMode(AIndex: Integer): Integer;
begin
  if Assigned(FParserModeGetter) then
    Exit(FParserModeGetter(AIndex));
  Result := -1;
end;

function TCallbackHighlighterRowProvider.GetLineNumber(AIndex: Integer): Integer;
begin
  if Assigned(FLineNumberGetter) then
    Exit(FLineNumberGetter(AIndex));
  Result := AIndex;
end;

constructor TDocumentLineRowProvider.CreateRange(ADocument: TDumpDocument;
  AFirstIndex, ACount: Integer);
begin
  inherited Create;
  FDocument := ADocument;
  FFirstIndex := Max(0, AFirstIndex);
  FCount := Max(0, ACount);
  if (FDocument = nil) or (FDocument.TextSource = nil) then
    FCount := 0
  else
    FCount := Max(0, Min(FCount,
      FDocument.TextSource.LineCount - FFirstIndex));
end;

constructor TDocumentLineRowProvider.CreateIndexes(ADocument: TDumpDocument;
  AIndexes: TList<Integer>);
begin
  inherited Create;
  FDocument := ADocument;
  FIndexes := AIndexes;
end;

constructor TDocumentLineRowProvider.CreateFilteredRange(
  ADocument: TDumpDocument; AFirstIndex, ACount: Integer;
  const ALineFilter: THighlighterLineFilter);
begin
  inherited Create;
  FDocument := ADocument;
  FIndexes := TList<Integer>.Create;
  FOwnsIndexes := True;
  if (FDocument = nil) or (FDocument.TextSource = nil) then
    Exit;

  var LFirstIndex := Max(0, AFirstIndex);
  var LLastIndex := Min(FDocument.TextSource.LineCount,
    LFirstIndex + Max(0, ACount));
  for var LSourceIndex := LFirstIndex to LLastIndex - 1 do
    if not Assigned(ALineFilter) or ALineFilter(FDocument.TextSource[LSourceIndex]) then
      FIndexes.Add(LSourceIndex);
end;

destructor TDocumentLineRowProvider.Destroy;
begin
  if FOwnsIndexes then
    FIndexes.Free;
  inherited;
end;

function TDocumentLineRowProvider.SourceIndex(AIndex: Integer): Integer;
begin
  if FIndexes <> nil then
    Exit(FIndexes[AIndex]);
  Result := FFirstIndex + AIndex;
end;

function TDocumentLineRowProvider.GetCount: Integer;
begin
  if FIndexes <> nil then
    Exit(FIndexes.Count);
  Result := FCount;
end;

function TDocumentLineRowProvider.GetText(AIndex: Integer): string;
begin
  Result := FDocument.TextSource[SourceIndex(AIndex)];
end;

function TDocumentLineRowProvider.GetImageName(AIndex: Integer): string;
begin
  Result := '';
end;

function TDocumentLineRowProvider.GetParserMode(AIndex: Integer): Integer;
begin
  Result := -1;
  var LSourceIndex := SourceIndex(AIndex);
  case FDocument.Lines[LSourceIndex].SourceSpan.SyntaxHint of
    rshCppBuilderMethod:
      Result := Ord(tpmCppBuilderMethod);
    rshMachLinker:
      Result := Ord(tpmMachLinker);
  end;
end;

function TDocumentLineRowProvider.GetLineNumber(AIndex: Integer): Integer;
begin
  Result := SourceIndex(AIndex);
end;

end.
