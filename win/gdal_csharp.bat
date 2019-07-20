@echo off
call %~dp0configvars
set key=gdal
set _rx_=%_buildroot_%\%key%-source
set back=%cd%
cd %_rx_%/gdal/swig/csharp
call %__%/trysetvcenv
nmake /f makefile.vc interface WIN64=1
nmake /f makefile.vc WIN64=1
nmake /f makefile.vc install WIN64=1

set _out_=%~dp0..\runtimes\win-x64\native

xcopy /Y /F /R "%_buildroot_%\shared\bin"  %_out_%
xcopy /Y /F /R "%_buildroot_%\gdal-source\gdal\gdal*.dll"  %_out_%
xcopy /Y /F /R "%_buildroot_%\gdal-build\csharp\*wrap.dll"  %_out_%

cd %back%