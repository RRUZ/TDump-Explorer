//**************************************************************************************************
//
// Unit TDump.Explorer.Finder
//
// Locates installed RAD Studio TDUMP executables through the BDS registry and
// the standard Embarcadero Studio installation tree.
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.Finder;

interface

uses
  System.Generics.Collections;

type
  TDumpExecutableKind = (tekTDump, tekTDump64);

  // Describes one Studio installation with one or both TDUMP executable paths.
  // The finder owns instances returned in its TObjectList result.
  TDumpInstallation = class
  public
    StudioVersion: string;
    StudioRoot: string;
    BinPath: string;
    TDumpPath: string;
    TDump64Path: string;
    function HasTDump: Boolean;
    function HasTDump64: Boolean;
  end;

  // Enumerates TDUMP executables installed in Delphi's standard bin directory.
  // Registry discovery is supplemented by Program Files enumeration for repairs
  // and portable installs that do not have an App registry value.
  TDumpFinder = class
  private
    procedure AddInstallation(AInstallations: TObjectList<TDumpInstallation>;
      const AVersion, ARootPath: string);
    procedure ScanBDSRegistry(AInstallations: TObjectList<TDumpInstallation>;
      ARootKey: NativeUInt);
    procedure ScanProgramFiles(AInstallations: TObjectList<TDumpInstallation>);
  public
    function Find: TObjectList<TDumpInstallation>;
    function FindNewest(const AInstallations: TObjectList<TDumpInstallation>;
      AExecutableKind: TDumpExecutableKind): TDumpInstallation;
    function FindDefault(const AInstallations: TObjectList<TDumpInstallation>):
      TDumpInstallation;
  end;

implementation

uses
  System.Classes,
  System.IOUtils,
  System.SysUtils,
  System.Win.Registry,
  Winapi.Windows;

const
  CBDSRegistryPath = 'Software\Embarcadero\BDS';
  CStudioRelativePath = 'Embarcadero\Studio';
  CTDumpExecutableName = 'tdump.exe';
  CTDump64ExecutableName = 'tdump64.exe';

function TDumpInstallation.HasTDump: Boolean;
begin
  Result := TDumpPath <> '';
end;

function TDumpInstallation.HasTDump64: Boolean;
begin
  Result := TDump64Path <> '';
end;

function StudioVersionRank(const AVersion: string): Integer;
begin
  var LDotPosition := Pos('.', AVersion);
  var LMajorVersion := AVersion;
  if LDotPosition > 0 then
    LMajorVersion := Copy(AVersion, 1, LDotPosition - 1);
  if not TryStrToInt(LMajorVersion, Result) then
    Result := -1;
end;

procedure TDumpFinder.AddInstallation(
  AInstallations: TObjectList<TDumpInstallation>; const AVersion,
  ARootPath: string);
begin
  if ARootPath = '' then
    Exit;

  var LRootPath := ExcludeTrailingPathDelimiter(ExpandFileName(ARootPath));
  var LBinPath := TPath.Combine(LRootPath, 'bin');
  var LTDumpPath := TPath.Combine(LBinPath, CTDumpExecutableName);
  var LTDump64Path := TPath.Combine(LBinPath, CTDump64ExecutableName);
  if not FileExists(LTDumpPath) then
    LTDumpPath := '';
  if not FileExists(LTDump64Path) then
    LTDump64Path := '';
  if (LTDumpPath = '') and (LTDump64Path = '') then
    Exit;

  for var LInstallation in AInstallations do
    if SameText(LInstallation.StudioRoot, LRootPath) then
    begin
      if LInstallation.StudioVersion = '' then
        LInstallation.StudioVersion := AVersion;
      if LInstallation.TDumpPath = '' then
        LInstallation.TDumpPath := LTDumpPath;
      if LInstallation.TDump64Path = '' then
        LInstallation.TDump64Path := LTDump64Path;
      Exit;
    end;

  var LInstallation := TDumpInstallation.Create;
  LInstallation.StudioVersion := AVersion;
  LInstallation.StudioRoot := LRootPath;
  LInstallation.BinPath := LBinPath;
  LInstallation.TDumpPath := LTDumpPath;
  LInstallation.TDump64Path := LTDump64Path;
  AInstallations.Add(LInstallation);
end;

procedure TDumpFinder.ScanBDSRegistry(
  AInstallations: TObjectList<TDumpInstallation>; ARootKey: NativeUInt);
begin
  var LRegistry := TRegistry.Create(KEY_READ);
  try
    LRegistry.RootKey := ARootKey;
    if not LRegistry.OpenKeyReadOnly(CBDSRegistryPath) then
      Exit;

    var LVersionNames := TStringList.Create;
    try
      LRegistry.GetKeyNames(LVersionNames);
      for var LVersionName in LVersionNames do
      begin
        // The BDS key is already open, so use an absolute path here rather
        // than resolving the version key below it a second time.
        var LKeyName := '\' + CBDSRegistryPath + '\' + LVersionName;
        if not LRegistry.OpenKeyReadOnly(LKeyName) then
          Continue;
        try
          if not LRegistry.ValueExists('App') then
            Continue;
          var LAppPath := LRegistry.ReadString('App');
          if not FileExists(LAppPath) then
            Continue;
          var LBinPath := ExtractFileDir(LAppPath);
          AddInstallation(AInstallations, LVersionName, ExtractFileDir(LBinPath));
        finally
          LRegistry.CloseKey;
        end;
      end;
    finally
      LVersionNames.Free;
    end;
  finally
    LRegistry.Free;
  end;
end;

procedure TDumpFinder.ScanProgramFiles(
  AInstallations: TObjectList<TDumpInstallation>);
begin
  var LProgramFilesPath := GetEnvironmentVariable('ProgramFiles(x86)');
  if LProgramFilesPath = '' then
    LProgramFilesPath := GetEnvironmentVariable('ProgramFiles');
  if LProgramFilesPath = '' then
    Exit;

  var LStudioPath := TPath.Combine(LProgramFilesPath, CStudioRelativePath);
  if not TDirectory.Exists(LStudioPath) then
    Exit;

  var LDirectories := TStringList.Create;
  try
    LDirectories.Sorted := True;
    LDirectories.Duplicates := dupIgnore;
    for var LDirectory in TDirectory.GetDirectories(LStudioPath) do
      LDirectories.Add(LDirectory);
    for var LDirectory in LDirectories do
      AddInstallation(AInstallations, ExtractFileName(LDirectory), LDirectory);
  finally
    LDirectories.Free;
  end;
end;

function TDumpFinder.Find: TObjectList<TDumpInstallation>;
begin
  Result := TObjectList<TDumpInstallation>.Create(True);
  try
    ScanBDSRegistry(Result, HKEY_CURRENT_USER);
    ScanBDSRegistry(Result, HKEY_LOCAL_MACHINE);
    ScanProgramFiles(Result);
  except
    Result.Free;
    raise;
  end;
end;

function TDumpFinder.FindNewest(
  const AInstallations: TObjectList<TDumpInstallation>;
  AExecutableKind: TDumpExecutableKind): TDumpInstallation;
begin
  Result := nil;
  for var LInstallation in AInstallations do
  begin
    var LSupportsRequestedTool :=
      ((AExecutableKind = tekTDump) and LInstallation.HasTDump) or
      ((AExecutableKind = tekTDump64) and LInstallation.HasTDump64);
    if not LSupportsRequestedTool then
      Continue;
    if (Result = nil) or
      (StudioVersionRank(LInstallation.StudioVersion) >
       StudioVersionRank(Result.StudioVersion)) then
      Result := LInstallation;
  end;
end;

function TDumpFinder.FindDefault(
  const AInstallations: TObjectList<TDumpInstallation>): TDumpInstallation;
begin
  // Prefer the newest 64-bit tool, then fall back to the newest TDUMP build.
  Result := FindNewest(AInstallations, tekTDump64);
  if Result = nil then
    Result := FindNewest(AInstallations, tekTDump);
end;

end.
