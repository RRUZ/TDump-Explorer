//**************************************************************************************************
//
// Unit TDump.Explorer.View.Diagnostics
//
// Diagnostic detail view population
//
// https://github.com/RRUZ/TDump-Explorer
//
// The Initial Developer of the Original Code is Rodrigo Ruz  Copyright (C) 2026
// All Rights Reserved.
//
//**************************************************************************************************
unit TDump.Explorer.View.Diagnostics;

interface

uses
  TDump.Explorer.Parser,
  TDump.Explorer.HighlighterControl;

type
  TDiagnosticsView = record
    class procedure Populate(AControl: THighlighterControl;
      ADocument: TDumpDocument); static;
    class function Caption(ADocument: TDumpDocument): string; static;
  end;

implementation

uses
  System.SysUtils,
  TDump.Explorer.Highlighter,
  TDump.Explorer.TinyParser;

class procedure TDiagnosticsView.Populate(AControl: THighlighterControl;
  ADocument: TDumpDocument);
begin
  if (AControl = nil) or (ADocument = nil) then
    Exit;
  AControl.ParserMode := tpmTDumpValues;
  AControl.BeginUpdate;
  try
    AControl.Clear;
    AControl.SetColumnHeaders(['Severity', 'Line', 'Message']);
    AControl.SetColumnDataTypes([thdtText, thdtInteger, thdtText]);
    for var LDiagnostic in ADocument.Diagnostics do
    begin
      var LSeverity := '';
      case LDiagnostic.Severity of
        dsInfo: LSeverity := 'Info';
        dsWarning: LSeverity := 'Warning';
        dsError: LSeverity := 'Error';
      end;
      var LMessage := LDiagnostic.Message;
      if LMessage = '' then
        LMessage := LDiagnostic.RawLine;
      AControl.AddColumns([LSeverity, LDiagnostic.LineNumber.ToString,
        LMessage]);
    end;
  finally
    AControl.EndUpdate;
  end;
end;

class function TDiagnosticsView.Caption(ADocument: TDumpDocument): string;
begin
  Result := Format('Diagnostics [%d]', [ADocument.Diagnostics.Count]);
end;

end.
