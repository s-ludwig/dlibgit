@echo off
setlocal EnableDelayedExpansion

set "this_path=%~dp0"
cd %this_path%

for /r %%i in (src\git\*.d) do set files=%%i !files!
for /r %%i in (src\git\c\*.d) do set files=%%i !files!
for /r %%i in (src\git\c\sys\*.d) do set files=%%i !files!

rem echo %files%
dmd -o- -D -Dddocs docs\viola.ddoc -Isrc %files%

rem echo.
echo Build ok.
