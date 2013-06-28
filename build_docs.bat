@echo off
setlocal EnableDelayedExpansion

set "this_path=%~dp0"
cd %this_path%

rem for /r %%i in (src\git\*.d) do echo %%i
rem for /r %%i in (src\git\c\*.d) do echo %%i
rem for /r %%i in (src\git\c\sys\*.d) do echo %%i

rem echo %files%
rem dmd -o- -D -Dddocs docs\viola.ddoc -Isrc %files%

rdmd -d ..\bootDoc\generate.d src --bootdoc=docs\config --modules=docs\config\modules.ddoc --settings=docs\config\settings.ddoc --output=docs

rem echo.
echo Build ok.
