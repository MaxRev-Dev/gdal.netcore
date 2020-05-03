@echo off
call %~dp0configvars
set key=gdal
set _rx_=%_buildroot_%\%key%-source
set back=%cd%
cd %_rx_%/gdal
call %__%/trysetvcenv
nmake /f makefile.vc MSVC_VER=1920 WIN64=1
nmake /f makefile.vc install WIN64=1
cd %back%