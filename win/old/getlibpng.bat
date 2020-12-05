@echo off
set back=%cd%
call %~dp0configvars
set key=libpng

if not exist "%_buildroot_%/%key%-source" git clone https://github.com/glennrp/libpng.git "%_buildroot_%/%key%-source"
cd  "%_buildroot_%/%key%-source"
set source=%cd%
git fetch
git checkout master
git reset --hard
git clean -fdx
call %__%\trysetvcenv
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"
mkdir "%bindir%"

if not exist build mkdir build
cd build

cmake -S .. -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=%cd%/%key%-build  -DZLIB_LIBRARY=%_buildroot_%/libz-build/lib/zlib.lib -DZLIB_INCLUDE_DIR=%_buildroot_%/libz-build/include 
cmake --build . --config Release
cmake --install . --prefix %bindir%

rem  devenv projects/vstudio/vstudio.sln  /upgrade
rem  msbuild projects/vstudio/vstudio.sln  /p:configuration="Release" /p:ZLibSrcDir="%_buildroot_%/libz-source" /p:TreatWarningAsError=false   /p:Platform="Win32"  /p:PlatformToolset=v142   /clp:NoSummary;NoItemAndPropertyList;ErrorsOnly /verbosity:quiet
rem /clp:ErrorsOnly /p:OutDir=%bindir%

call %__%\copyrecursive %bindir%

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!
