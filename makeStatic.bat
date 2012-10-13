@echo off
setlocal EnableDelayedExpansion
cd src
for /r %%i in (*.d) do set files=%%i !files!
cd..

rem echo %files%
dmd -lib -ofbin\dlibgit.lib -Isrc %files%
