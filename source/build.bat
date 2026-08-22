@echo off
setlocal EnableExtensions

rem Build entry point for the TDump Explorer parser while the console harness is the only target.
set "STUDIO_ROOT=C:\Program Files (x86)\Embarcadero\Studio\37.0"
set "RSVARS=%STUDIO_ROOT%\bin\rsvars.bat"
set "PROJECT_ROOT=%~dp0.."
set "CONSOLE_SOURCE=%PROJECT_ROOT%\tests\TDumpParserConsole.dpr"
set "CONSOLE_EXE=%PROJECT_ROOT%\tests\TDumpParserConsole.exe"
set "INTERMEDIATE_DIR=%PROJECT_ROOT%\build\dcu\win32-debug"
set "DEFAULT_FIXTURE=%PROJECT_ROOT%\fixtures\PlainVanilla.Delphi.Package.bpl.tdump"

if /I "%~1"=="" goto BUILD
if /I "%~1"=="build" goto BUILD
if /I "%~1"=="run" goto RUN
if /I "%~1"=="test" goto TEST
goto USAGE

:INIT_RAD_STUDIO
if exist "%RSVARS%" goto INIT_RAD_STUDIO_READY
echo RAD Studio 13.1 environment script was not found:
echo   %RSVARS%
exit /b 1

:INIT_RAD_STUDIO_READY
call "%RSVARS%"
if not errorlevel 1 exit /b 0
echo Unable to initialize the RAD Studio 13.1 command-line environment.
exit /b 1

:BUILD_CONSOLE
call :INIT_RAD_STUDIO
if errorlevel 1 exit /b 1

if not exist "%CONSOLE_SOURCE%" (
  echo Console source file was not found:
  echo   %CONSOLE_SOURCE%
  exit /b 1
)

echo Building TDumpParserConsole ^(Win32 Debug^)...
if not exist "%INTERMEDIATE_DIR%" mkdir "%INTERMEDIATE_DIR%"
if not exist "%INTERMEDIATE_DIR%" (
  echo Unable to create the intermediate output directory:
  echo   %INTERMEDIATE_DIR%
  exit /b 1
)
pushd "%PROJECT_ROOT%\tests"
if errorlevel 1 exit /b 1
dcc32.exe -B -Q -N"%INTERMEDIATE_DIR%" "TDumpParserConsole.dpr"
set "BUILD_RESULT=%ERRORLEVEL%"
popd
if not "%BUILD_RESULT%"=="0" exit /b %BUILD_RESULT%

if not exist "%CONSOLE_EXE%" (
  echo Build completed, but the expected console executable was not found:
  echo   %CONSOLE_EXE%
  exit /b 1
)

echo Build succeeded: %CONSOLE_EXE%
exit /b 0

:BUILD
call :BUILD_CONSOLE
exit /b %ERRORLEVEL%

:RUN_CONSOLE
set "FIXTURE=%~1"
if "%FIXTURE%"=="" set "FIXTURE=%DEFAULT_FIXTURE%"
if not exist "%FIXTURE%" (
  echo TDUMP fixture was not found:
  echo   %FIXTURE%
  exit /b 1
)

echo Running TDumpParserConsole with %FIXTURE%
"%CONSOLE_EXE%" "%FIXTURE%"
exit /b %ERRORLEVEL%

:RUN
call :BUILD_CONSOLE
if errorlevel 1 exit /b 1
call :RUN_CONSOLE "%~2"
exit /b %ERRORLEVEL%

:TEST
call :BUILD_CONSOLE
if errorlevel 1 exit /b 1

rem Extend this fixture list as assertion-based parser tests are added.
for %%F in (
  "%PROJECT_ROOT%\fixtures\PlainVanilla.Delphi.Package.bpl.tdump"
  "%PROJECT_ROOT%\fixtures\PlainVanilla.VCL.Application.tdump"
) do (
  echo Running console smoke test: %%~nxF
  echo.|"%CONSOLE_EXE%" "%%~fF"
  if errorlevel 1 exit /b 1
)
exit /b 0

:USAGE
echo Usage: build.bat [build^|run [fixture]^|test]
echo.
echo   build  Build the Win32 Debug console harness ^(default^).
echo   run    Build, then run the console harness with an optional fixture.
echo   test   Build, then run non-interactive smoke tests for registered fixtures.
exit /b 1
