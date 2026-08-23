@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem Generates parser fixtures from the checked-in sample binaries through the
rem project's runner console, exercising TDUMP discovery, process capture, and
rem parser projection as part of fixture generation.

set "PROJECT_ROOT=%~dp0.."
for %%I in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fI"
set "BINARIES_DIR=%PROJECT_ROOT%\binaries"
set "OUTPUT_DIR=%~dp0generated"
set "RUNNER_EXE=%PROJECT_ROOT%\tests\TDumpRunnerConsole.exe"

call :RequireFile "%RUNNER_EXE%"
if errorlevel 1 exit /b 1

call :RequireFile "%BINARIES_DIR%\VCL.Win32.exe"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\Dll.Win32.dll"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\Package.Win32.bpl"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\VCL.Win64.exe"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\Dll.Win64.dll"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\Package.Win64.bpl"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\DCU.Win32.dcu"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\OMF.Object.Win32.obj"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\OMF.Library.Win32.lib"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\COFF.Object.Win64.obj"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\COFF.Object.Win64.MinGW.obj"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\ELF.Object.Win64.zutil.o"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\AR.Library.Win64.a"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\DCU.System.Win32.dcu"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\Mach.Universal.Rad23.dylib"
if errorlevel 1 exit /b 1
call :RequireFile "%BINARIES_DIR%\Mach.Universal.Rad37.dylib"
if errorlevel 1 exit /b 1

if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"
if not exist "%OUTPUT_DIR%" (
  echo ERROR: Could not create "%OUTPUT_DIR%".
  exit /b 1
)

set /a FAILURE_COUNT=0

rem PE core views retain headers, directories, sections, imports, exports,
rem resources, and relocations while excluding bulky debug data.
call :Dump "32" "%BINARIES_DIR%\VCL.Win32.exe" "%OUTPUT_DIR%\VCL.Win32.pe-core.tdump" "-e -ed"
call :Dump "32" "%BINARIES_DIR%\Dll.Win32.dll" "%OUTPUT_DIR%\Dll.Win32.pe-core.tdump" "-e -ed"
call :Dump "32" "%BINARIES_DIR%\Package.Win32.bpl" "%OUTPUT_DIR%\Package.Win32.pe-core.tdump" "-e -ed"
call :Dump "64" "%BINARIES_DIR%\VCL.Win64.exe" "%OUTPUT_DIR%\VCL.Win64.pe-core.tdump" "-e -ed"
call :Dump "64" "%BINARIES_DIR%\Dll.Win64.dll" "%OUTPUT_DIR%\Dll.Win64.pe-core.tdump" "-e -ed"
call :Dump "64" "%BINARIES_DIR%\Package.Win64.bpl" "%OUTPUT_DIR%\Package.Win64.pe-core.tdump" "-e -ed"

rem Focused PE views exercise table-specific output layouts.
call :Dump "32" "%BINARIES_DIR%\VCL.Win32.exe" "%OUTPUT_DIR%\VCL.Win32.imports.tdump" "-em"
call :Dump "32" "%BINARIES_DIR%\VCL.Win32.exe" "%OUTPUT_DIR%\VCL.Win32.exports.tdump" "-ee"
call :Dump "32" "%BINARIES_DIR%\VCL.Win32.exe" "%OUTPUT_DIR%\VCL.Win32.relocations.tdump" "-e -ed -R"
call :Dump "32" "%BINARIES_DIR%\VCL.Win32.exe" "%OUTPUT_DIR%\VCL.Win32.strings.tdump" "-s6" "allow-exit-1"
call :Dump "32" "%BINARIES_DIR%\Dll.Win32.dll" "%OUTPUT_DIR%\Dll.Win32.imports.tdump" "-em"
call :Dump "32" "%BINARIES_DIR%\Dll.Win32.dll" "%OUTPUT_DIR%\Dll.Win32.exports.tdump" "-ee"
call :Dump "32" "%BINARIES_DIR%\Package.Win32.bpl" "%OUTPUT_DIR%\Package.Win32.exports.tdump" "-ee"
call :Dump "32" "%BINARIES_DIR%\Package.Win32.bpl" "%OUTPUT_DIR%\Package.Win32.debug.tdump" "-e"
call :Dump "64" "%BINARIES_DIR%\VCL.Win64.exe" "%OUTPUT_DIR%\VCL.Win64.imports.tdump" "-em"
call :Dump "64" "%BINARIES_DIR%\VCL.Win64.exe" "%OUTPUT_DIR%\VCL.Win64.exports.tdump" "-ee"
call :Dump "64" "%BINARIES_DIR%\VCL.Win64.exe" "%OUTPUT_DIR%\VCL.Win64.relocations.tdump" "-e -ed -R"
call :Dump "64" "%BINARIES_DIR%\Dll.Win64.dll" "%OUTPUT_DIR%\Dll.Win64.imports.tdump" "-em"
call :Dump "64" "%BINARIES_DIR%\Dll.Win64.dll" "%OUTPUT_DIR%\Dll.Win64.exports.tdump" "-ee"
call :Dump "64" "%BINARIES_DIR%\Package.Win64.bpl" "%OUTPUT_DIR%\Package.Win64.exports.tdump" "-ee"
call :Dump "64" "%BINARIES_DIR%\Package.Win64.bpl" "%OUTPUT_DIR%\Package.Win64.debug.tdump" "-e"

rem OMF object and library output from Delphi's Win32 runtime libraries.
call :Dump "32" "%BINARIES_DIR%\OMF.Object.Win32.obj" "%OUTPUT_DIR%\OMF.Object.Win32.tdump" "-o"
call :Dump "32" "%BINARIES_DIR%\OMF.Library.Win32.lib" "%OUTPUT_DIR%\OMF.Library.Win32.tdump" "-l"

rem Current tools reject this newer DCU magic; preserve that diagnostic as a
rem negative fixture until a DCU compatible with the installed TDUMP is added.
call :Dump "32" "%BINARIES_DIR%\DCU.Win32.dcu" "%OUTPUT_DIR%\DCU.Win32.invalid-magic.tdump" "" "allow-nonzero"
call :Dump "64" "%BINARIES_DIR%\DCU.System.Win32.dcu" "%OUTPUT_DIR%\DCU.System.Win32.invalid-magic.tdump" "" "allow-nonzero"

rem These are real archive/COFF inputs. The installed TDUMP64 cannot parse
rem their Windows members, so fixtures retain its diagnostic output.
call :Dump "64" "%BINARIES_DIR%\AR.Library.Win64.a" "%OUTPUT_DIR%\AR.Library.Win64.invalid-data.tdump" "-lh"
call :Dump "64" "%BINARIES_DIR%\COFF.Object.Win64.obj" "%OUTPUT_DIR%\COFF.Object.Win64.invalid-machine.tdump" "-C" "allow-nonzero"

rem Small, valid object files from the installed toolchain provide real COFF
rem and ELF output for parser coverage.
call :Dump "64" "%BINARIES_DIR%\COFF.Object.Win64.MinGW.obj" "%OUTPUT_DIR%\COFF.Object.Win64.MinGW.tdump" "-C" "allow-nonzero"
call :Dump "64" "%BINARIES_DIR%\ELF.Object.Win64.zutil.o" "%OUTPUT_DIR%\ELF.Object.Win64.tdump" "-e" "allow-nonzero"

rem Universal Mach-O BPLs exercise FAT and individual Mach-header output.
call :Dump "64" "%BINARIES_DIR%\Mach.Universal.Rad23.dylib" "%OUTPUT_DIR%\Mach.Universal.Rad23.tdump" "-M" "allow-nonzero"
call :Dump "64" "%BINARIES_DIR%\Mach.Universal.Rad37.dylib" "%OUTPUT_DIR%\Mach.Universal.Rad37.tdump" "-M" "allow-nonzero"

if not "%FAILURE_COUNT%"=="0" (
  echo.
  echo Completed with %FAILURE_COUNT% failed fixture generation^(s^).
  exit /b 1
)

echo.
echo Generated fixtures in "%OUTPUT_DIR%".
exit /b 0

:RequireFile
if not exist "%~1" (
  echo ERROR: Required binary is missing: "%~1"
  exit /b 1
)
exit /b 0

:Dump
setlocal
set "LToolKind=%~1"
set "LInput=%~2"
set "LOutput=%~3"
set "LOptions=%~4"
set "LAllowedExitCode=%~5"
set "LTemporary=%LOutput%.tmp"
set "LRunnerOptions=%LOptions%"
if "%LRunnerOptions%"=="" set "LRunnerOptions=--"

echo Generating %~nx3
if exist "%LTemporary%" del /q "%LTemporary%"

"%RUNNER_EXE%" "%LInput%" "%LToolKind%" "%LRunnerOptions%" "%LTemporary%" "no-parse"

:DumpCaptureExit
set "LExitCode=%ERRORLEVEL%"
if "%LExitCode%"=="0" goto :DumpCheckResult
if /i "%LAllowedExitCode%"=="allow-nonzero" goto :DumpAcceptNonZero
if not "%LExitCode%"=="1" goto :DumpCheckResult
if /i not "%LAllowedExitCode%"=="allow-exit-1" goto :DumpCheckResult

:DumpAcceptNonZero
for %%I in ("%LTemporary%") do set "LTemporarySize=%%~zI"
if "%LTemporarySize%"=="0" goto :DumpCheckResult
echo WARNING: TDUMP returned exit code %LExitCode% after writing a non-empty diagnostic fixture; accepting its output.
set "LExitCode=0"

:DumpCheckResult
if not "%LExitCode%"=="0" (
  echo ERROR: TDUMP failed for "%LInput%" ^(exit code %LExitCode%^).
  if exist "%LTemporary%" del /q "%LTemporary%"
  endlocal & set /a FAILURE_COUNT+=1 & exit /b 1
)

move /y "%LTemporary%" "%LOutput%" >nul
if errorlevel 1 (
  echo ERROR: Could not publish "%LOutput%".
  endlocal & set /a FAILURE_COUNT+=1 & exit /b 1
)
endlocal & exit /b 0
