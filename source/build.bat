@echo off
setlocal EnableExtensions

rem Build entry point for the TDump Explorer parser while the console harness is the only target.
set "STUDIO_ROOT=C:\Program Files (x86)\Embarcadero\Studio\37.0"
set "RSVARS=%STUDIO_ROOT%\bin\rsvars.bat"
set "PROJECT_ROOT=%~dp0.."
set "CONSOLE_SOURCE=%PROJECT_ROOT%\tests\TDumpParserConsole.dpr"
set "CONSOLE_EXE=%PROJECT_ROOT%\tests\TDumpParserConsole.exe"
set "TESTS_SOURCE=%PROJECT_ROOT%\tests\TDumpParserTests.dpr"
set "TESTS_EXE=%PROJECT_ROOT%\tests\TDumpParserTests.exe"
set "RUNNER_SOURCE=%PROJECT_ROOT%\tests\TDumpRunnerConsole.dpr"
set "RUNNER_EXE=%PROJECT_ROOT%\tests\TDumpRunnerConsole.exe"
set "FINDER_SOURCE=%PROJECT_ROOT%\tests\TDumpFinderConsole.dpr"
set "FINDER_EXE=%PROJECT_ROOT%\tests\TDumpFinderConsole.exe"
set "PROFILER_SOURCE=%PROJECT_ROOT%\tests\TDumpParserProfiler.dpr"
set "PROFILER_EXE=%PROJECT_ROOT%\tests\TDumpParserProfiler.exe"
set "RELATIONS_SOURCE=%PROJECT_ROOT%\tests\TDumpRelationsConsole.dpr"
set "RELATIONS_EXE=%PROJECT_ROOT%\tests\TDumpRelationsConsole.exe"
set "INTERMEDIATE_ROOT=%PROJECT_ROOT%\build\dcu\win32-debug"
set "DEFAULT_FIXTURE=%PROJECT_ROOT%\fixtures\PlainVanilla.Delphi.Package.bpl.tdump"

if /I "%~1"=="" goto BUILD
if /I "%~1"=="build" goto BUILD
if /I "%~1"=="run" goto RUN
if /I "%~1"=="runner" goto RUNNER
if /I "%~1"=="finder" goto FINDER
if /I "%~1"=="test" goto TEST
if /I "%~1"=="profile" goto PROFILE
if /I "%~1"=="relations" goto RELATIONS
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
set "INTERMEDIATE_DIR=%INTERMEDIATE_ROOT%\%RANDOM%%RANDOM%"
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

:BUILD_TESTS
call :INIT_RAD_STUDIO
if errorlevel 1 exit /b 1

if not exist "%TESTS_SOURCE%" (
  echo Parser assertion source was not found:
  echo   %TESTS_SOURCE%
  exit /b 1
)

echo Building TDumpParserTests ^(Win32 Debug^)...
set "INTERMEDIATE_DIR=%INTERMEDIATE_ROOT%\%RANDOM%%RANDOM%"
if not exist "%INTERMEDIATE_DIR%" mkdir "%INTERMEDIATE_DIR%"
if not exist "%INTERMEDIATE_DIR%" (
  echo Unable to create the intermediate output directory:
  echo   %INTERMEDIATE_DIR%
  exit /b 1
)
pushd "%PROJECT_ROOT%\tests"
if errorlevel 1 exit /b 1
dcc32.exe -B -Q -N"%INTERMEDIATE_DIR%" "TDumpParserTests.dpr"
set "BUILD_RESULT=%ERRORLEVEL%"
popd
if not "%BUILD_RESULT%"=="0" exit /b %BUILD_RESULT%

if not exist "%TESTS_EXE%" (
  echo Build completed, but the expected assertion executable was not found:
  echo   %TESTS_EXE%
  exit /b 1
)

echo Build succeeded: %TESTS_EXE%
exit /b 0

:BUILD_RUNNER
call :INIT_RAD_STUDIO
if errorlevel 1 exit /b 1

if not exist "%RUNNER_SOURCE%" (
  echo Runner source file was not found:
  echo   %RUNNER_SOURCE%
  exit /b 1
)

echo Building TDumpRunnerConsole ^(Win32 Debug^)...
set "INTERMEDIATE_DIR=%INTERMEDIATE_ROOT%\%RANDOM%%RANDOM%"
if not exist "%INTERMEDIATE_DIR%" mkdir "%INTERMEDIATE_DIR%"
if not exist "%INTERMEDIATE_DIR%" (
  echo Unable to create the intermediate output directory:
  echo   %INTERMEDIATE_DIR%
  exit /b 1
)
pushd "%PROJECT_ROOT%\tests"
if errorlevel 1 exit /b 1
dcc32.exe -B -Q -N"%INTERMEDIATE_DIR%" "TDumpRunnerConsole.dpr"
set "BUILD_RESULT=%ERRORLEVEL%"
popd
if not "%BUILD_RESULT%"=="0" exit /b %BUILD_RESULT%

if not exist "%RUNNER_EXE%" (
  echo Build completed, but the expected runner executable was not found:
  echo   %RUNNER_EXE%
  exit /b 1
)

echo Build succeeded: %RUNNER_EXE%
exit /b 0

:BUILD_FINDER
call :INIT_RAD_STUDIO
if errorlevel 1 exit /b 1

if not exist "%FINDER_SOURCE%" (
  echo Finder-console source file was not found:
  echo   %FINDER_SOURCE%
  exit /b 1
)

echo Building TDumpFinderConsole ^(Win32 Debug^)...
set "INTERMEDIATE_DIR=%INTERMEDIATE_ROOT%\%RANDOM%%RANDOM%"
if not exist "%INTERMEDIATE_DIR%" mkdir "%INTERMEDIATE_DIR%"
if not exist "%INTERMEDIATE_DIR%" (
  echo Unable to create the intermediate output directory:
  echo   %INTERMEDIATE_DIR%
  exit /b 1
)
pushd "%PROJECT_ROOT%\tests"
if errorlevel 1 exit /b 1
dcc32.exe -B -Q -N"%INTERMEDIATE_DIR%" "TDumpFinderConsole.dpr"
set "BUILD_RESULT=%ERRORLEVEL%"
popd
if not "%BUILD_RESULT%"=="0" exit /b %BUILD_RESULT%

if not exist "%FINDER_EXE%" (
  echo Build completed, but the expected finder-console executable was not found:
  echo   %FINDER_EXE%
  exit /b 1
)

echo Build succeeded: %FINDER_EXE%
exit /b 0

:BUILD_RELATIONS
call :INIT_RAD_STUDIO
if errorlevel 1 exit /b 1

if not exist "%RELATIONS_SOURCE%" (
  echo Relation-console source file was not found:
  echo   %RELATIONS_SOURCE%
  exit /b 1
)

echo Building TDumpRelationsConsole ^(Win32 Debug^)...
set "INTERMEDIATE_DIR=%INTERMEDIATE_ROOT%\%RANDOM%%RANDOM%"
if not exist "%INTERMEDIATE_DIR%" mkdir "%INTERMEDIATE_DIR%"
if not exist "%INTERMEDIATE_DIR%" (
  echo Unable to create the intermediate output directory:
  echo   %INTERMEDIATE_DIR%
  exit /b 1
)
pushd "%PROJECT_ROOT%\tests"
if errorlevel 1 exit /b 1
dcc32.exe -B -Q -N"%INTERMEDIATE_DIR%" "TDumpRelationsConsole.dpr"
set "BUILD_RESULT=%ERRORLEVEL%"
popd
if not "%BUILD_RESULT%"=="0" exit /b %BUILD_RESULT%

if not exist "%RELATIONS_EXE%" (
  echo Build completed, but the expected relation-console executable was not found:
  echo   %RELATIONS_EXE%
  exit /b 1
)

echo Build succeeded: %RELATIONS_EXE%
exit /b 0

:BUILD_PROFILER
call :INIT_RAD_STUDIO
if errorlevel 1 exit /b 1

if not exist "%PROFILER_SOURCE%" (
  echo Parser profiler source file was not found:
  echo   %PROFILER_SOURCE%
  exit /b 1
)

echo Building TDumpParserProfiler ^(Win32 Debug^)...
set "INTERMEDIATE_DIR=%INTERMEDIATE_ROOT%\%RANDOM%%RANDOM%"
if not exist "%INTERMEDIATE_DIR%" mkdir "%INTERMEDIATE_DIR%"
if not exist "%INTERMEDIATE_DIR%" (
  echo Unable to create the intermediate output directory:
  echo   %INTERMEDIATE_DIR%
  exit /b 1
)
pushd "%PROJECT_ROOT%\tests"
if errorlevel 1 exit /b 1
dcc32.exe -B -Q -N"%INTERMEDIATE_DIR%" "TDumpParserProfiler.dpr"
set "BUILD_RESULT=%ERRORLEVEL%"
popd
if not "%BUILD_RESULT%"=="0" exit /b %BUILD_RESULT%

if not exist "%PROFILER_EXE%" (
  echo Build completed, but the expected profiler executable was not found:
  echo   %PROFILER_EXE%
  exit /b 1
)

echo Build succeeded: %PROFILER_EXE%
exit /b 0

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

:RUNNER
call :BUILD_RUNNER
if errorlevel 1 exit /b 1
"%RUNNER_EXE%" "%~2" "%~3" "%~4"
exit /b %ERRORLEVEL%

:FINDER
call :BUILD_FINDER
if errorlevel 1 exit /b 1
"%FINDER_EXE%"
exit /b %ERRORLEVEL%

:TEST
call :BUILD_TESTS
if errorlevel 1 exit /b 1

echo Running parser assertion suite...
"%TESTS_EXE%"
exit /b 0

:PROFILE
call :BUILD_PROFILER
if errorlevel 1 exit /b 1

if "%~2"=="" goto PROFILE_DEFAULT
if "%~3"=="" goto PROFILE_DIRECTORY
"%PROFILER_EXE%" "%~2" "%~3"
exit /b %ERRORLEVEL%

:PROFILE_DIRECTORY
"%PROFILER_EXE%" "%~2"
exit /b %ERRORLEVEL%

:PROFILE_DEFAULT
"%PROFILER_EXE%"
exit /b %ERRORLEVEL%

:RELATIONS
call :BUILD_RELATIONS
if errorlevel 1 exit /b 1

set "FIXTURE=%~2"
if "%FIXTURE%"=="" set "FIXTURE=%DEFAULT_FIXTURE%"
if not exist "%FIXTURE%" (
  echo TDUMP fixture was not found:
  echo   %FIXTURE%
  exit /b 1
)
"%RELATIONS_EXE%" "%FIXTURE%"
exit /b %ERRORLEVEL%

:USAGE
echo Usage: build.bat [build^|run [fixture]^|runner [input-file] [32^|64] [tdump-options]^|finder^|test^|profile [fixture-directory] [iterations]^|relations [fixture]]
echo.
echo   build  Build the Win32 Debug console harness ^(default^).
echo   run    Build, then run the console harness with an optional fixture.
echo   runner Build, run, capture, and parse one binary using the newest installed TDUMP.
echo   finder Enumerate installed TDUMP tools and print the recommended default.
echo   test   Build, then run non-interactive smoke tests for registered fixtures.
echo   profile Build and profile every *.tdump under fixtures, optionally using a
echo           fixture directory and positive iteration count.
echo   relations Build and exercise the cross-reference relation layer against an
echo             optional TDUMP fixture.
exit /b 1
