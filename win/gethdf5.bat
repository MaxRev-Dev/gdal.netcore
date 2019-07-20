set back=%cd%
call %~dp0configvars
set key=hdf5
set _mver_=1.10
set _ver_=%_mver_%.5

set _filever_=CMake-hdf5-%_ver_%
if not exist %_buildroot_%/%key%-source/%_filever_%/hdf5-%_ver_% (
mkdir "%_buildroot_%/%key%-source"
powershell -Command "(New-Object Net.WebClient).DownloadFile('https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-%_mver_%/hdf5-%_ver_%/src/%_filever_%.zip', '%_buildroot_%/%key%-source/%_filever_%.zip')"
powershell Expand-Archive "%_buildroot_%/%key%-source/%_filever_%.zip" -DestinationPath "%_buildroot_%/%key%-source/" -Force
)
cd %_buildroot_%/%key%-source/%_filever_%/%key%-%_ver_%
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"

if not exist build mkdir build
cd build

cmake -S .. -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=ON -DHDF_CFG_NAME=Release -DCMAKE_INSTALL_PREFIX=%cd%/%key%-build  
cmake --build . --config Release
cmake --install . --prefix %key%-build
move /Y %key%-build %bindir%/..

if defined _rmsource_ rd /s /q %_buildroot_%/%key%-source
cd %back%
echo %key% installation complete!