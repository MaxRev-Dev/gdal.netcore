@echo off
call %~dp0configvars

set sources=%features%

set _out_=%~dp0..\runtimes\win-x64\native

xcopy /Y /F /R "%~dp0..\build-win\libshared\bin" "%_out_%\"
xcopy /Y /F /R "%~dp0..\build-win\gdal-build\bin\gdalplugins" "%_out_%\gdalplugins\"

rem Copy VC runtime. Currently I had copied them manually from
rem C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Redist\MSVC\14.24.28127\x64\Microsoft.VC142.CRT
rem ISSUE: https://developercommunity.visualstudio.com/content/problem/852548/vcruntime140-1dll-is-missing.html#
xcopy /Y /F /R "%VCToolsRedistDir%x64\Microsoft.VC142.CRT\*.dll" "%_out_%\"


cd %back%