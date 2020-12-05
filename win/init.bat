@echo off
echo "gdal.netcore > Initializing build environment..."
set __error="gdal.netcore > Failed to initialize build evironment"
set __success="gdal.netcore > Build environment is ready!"
call  %~dp0/misc/trysetvcenv.bat && (echo %__success%) || (echo %__error%)
 