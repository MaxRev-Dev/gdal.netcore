@echo off
call %~dp0configvars
set key=gdal
set _rx_=%_buildroot_%\%key%-source
set back=%cd%
cd "%_rx_%"
if not exist "%_rx_%/gdal" git clone %GDAL_REPO% %_rx_%
git checkout "release/3.0"
git checkout -q %GDAL_COMMIT_VER%
git clean -fdx
echo Populating gdal source with nmake.opt options..
copy /y "%_pre_%\gdal-nmake.opt" gdal\nmake.opt
echo Populating gdal source with makefile.vc..
copy /y "%_pre_%\gdal-makefile.vc" gdal\makefile.vc
cd %back%