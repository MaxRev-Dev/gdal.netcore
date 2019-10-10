@echo off
call %~dp0configvars

set sources=%features%

set _out_=%~dp0..\runtimes\win-x64\native

xcopy /Y /F /R "%~dp0..\build-win\libshared\bin" "%_out_%\"
xcopy /Y /F /R "%~dp0..\build-win\gdal-build\bin\gdalplugins" "%_out_%\gdalplugins\"


cd %back%