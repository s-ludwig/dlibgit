@echo off
setlocal EnableDelayedExpansion

set thisPath=%~dp0
set binPath=%thisPath%\..\bin
set srcPath=%thisPath%\..\src
cd %srcPath%

set "files="
for /r %%i in (git\*.d) do set files=%%i !files!
for /r %%i in (git\c\*.d) do set files=%%i !files!
for /r %%i in (git\c\sys\*.d) do set files=%%i !files!

rem set compiler=dmd.exe
set compiler=dmd_msc.exe
rem set compiler=ldmd2.exe

set "implibFile=%binPath%\libgit2_implib.lib"

set "flags=%implibFile%"

if not exist %implibFile% cd %binPath% && call make_implib.bat > NUL && cd %srcPath%

rem Note: -g option disabled due to CodeView bugs which crash linkers
rem (both Optlink and Unilink will ICE)
set dtest=rdmd -g --main -debug -unittest --force -of%binPath%\dlibgit_test.exe

%dtest% --compiler=%compiler% %flags% -Isrc git\package.d && echo Success: dlibgit tested ok.
rem %compiler% -of%binPath%\dlibgit.lib -lib %flags% %files% && echo Success: dlibgit built ok.
