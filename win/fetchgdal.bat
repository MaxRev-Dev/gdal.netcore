@echo off
call %~dp0configvars
set key=gdal
set _rx_=%_buildroot_%\%key%-source
set back=%cd%
cd "%_rx_%"
if not exist %_rx_%/gdal git clone https://github.com/OSGeo/gdal.git %_rx_%
git checkout release/3.0
git clean -fdx
echo Populating gdal source with nmake.opt options..
copy /y "%_pre_%\gdal-nmake.opt" nmake.opt
cd %back%