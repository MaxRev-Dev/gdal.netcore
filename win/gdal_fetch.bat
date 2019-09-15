@echo off
call %~dp0configvars
set key=gdal
set _rx_=%_buildroot_%\%key%-source
set back=%cd%
cd "%_rx_%"
if not exist %_rx_%/gdal git clone https://github.com/OSGeo/gdal.git %_rx_%
git checkout -q 558f8a7aa15498ac25fb4a8227b220c1d4fecf29
git clean -fdx
echo Populating gdal source with nmake.opt options..
copy /y "%_pre_%\gdal-nmake.opt" gdal\nmake.opt
echo Populating gdal source with makefile.vc..
copy /y "%_pre_%\gdal-makefile.vc" gdal\makefile.vc
cd %back%