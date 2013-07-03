@echo off
setlocal EnableDelayedExpansion

set thisPath=%~dp0
set binPath=%thisPath%\..\bin

cd %thisPath%\..\src

set "files="
for /r %%i in (git\*.d) do set files=%%i !files!
for /r %%i in (git\c\*.d) do set files=%%i !files!
for /r %%i in (git\c\sys\*.d) do set files=%%i !files!

rem set compiler=dmd.exe
set compiler=dmd_msc.exe
rem set compiler=ldmd2.exe

set "flags=%binPath%\libgit2_implib.lib"

rem Note: -g option disabled due to CodeView bugs which crash linkers
rem (both Optlink and Unilink will ICE)
set dtest=rdmd -g --main -debug -unittest --force -of%binPath%\dlibgit_test.exe

%dtest% --compiler=%compiler% %flags% -Isrc git\package.d
rem &&
rem echo %compiler% -of%binPath%\dlibgit.lib -lib %flags% -g %files%
