@echo off
setlocal EnableDelayedExpansion

set "this_path=%~dp0"
cd %thisPath%..\

rdmd -d ..\bootDoc\generate.d src --bootdoc=docs\config --modules=docs\config\modules.ddoc --settings=docs\config\settings.ddoc --output=docs

rem echo.
echo Build ok.
