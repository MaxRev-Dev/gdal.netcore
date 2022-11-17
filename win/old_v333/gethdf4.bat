@echo off
set back=%cd%
call %~dp0configvars
set key=hdf4
set _ver_=4.2.14

set _filever_=CMake-hdf-%_ver_%
if not exist %_buildroot_%/%key%-source/%_filever_%/hdf-%_ver_% (
mkdir "%_buildroot_%/%key%-source"
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://support.hdfgroup.org/ftp/HDF/releases/HDF%_ver_%/src/%_filever_%.zip', '%_buildroot_%/%key%-source/%_filever_%.zip')"
powershell Expand-Archive "%_buildroot_%/%key%-source/%_filever_%.zip" -DestinationPath "%_buildroot_%/%key%-source/" -Force
)
cd %_buildroot_%/%key%-source/%_filever_%/hdf-%_ver_%
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"

if not exist build mkdir build
cd build

cmake -S ..  -DCMAKE_BUILD_TYPE:STRING=Release -DBUILD_SHARED_LIBS=ON^
 -DHDF_CFG_NAME=Release^
 -DJPEG_LIBRARY=%LIBRARIES%/lib/jpeg.lib^
 -DJPEG_DIR=%LIBRARIES%^
 -DJPEG_INCLUDE_DIR=%LIBRARIES%/include^
 -DZLIB_LIBRARY=%LIBRARIES%/lib/zlib.lib^
 -DZLIB_INCLUDE_DIR=%LIBRARIES%/include^
 -DHDF4_BUILD_FORTRAN:BOOL=OFF || goto :error
cmake --build . --config Release || goto :error
cmake --install . --prefix %key%-build || goto :error
move /Y %key%-build %bindir%/..

call  %__%\copyrecursive %bindir%

if defined _rmsource_ rd /s /q %_buildroot_%/%key%-source
cd %back%
echo %key% installation complete!
goto :EOF

:error
echo Failed with error #%errorlevel%.
exit /b %errorlevel%