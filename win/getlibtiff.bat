set back=%cd%
call %~dp0configvars
set key=libtiff
if not exist "%_buildroot_%/%key%-source" git clone https://gitlab.com/libtiff/libtiff.git %_buildroot_%/%key%-source
cd %_buildroot_%/%key%-source
set source=%cd%
git fetch
git checkout master
git reset --hard
git clean -fdx

cmake -DJPEG_LIBRARY=%_buildroot_%/libjpeg-build/lib/jpeg.lib   -DJPEG_INCLUDE_DIR=%_buildroot_%/libjpeg-build/include  -DZLIB_LIBRARY=%_buildroot_%/libz-source/zlib.lib -DZLIB_INCLUDE_DIR=%_buildroot_%/libz-source -S . -B build -A x64 -DCMAKE_GENERATOR_TOOLSET=host=x64
cmake --build build --config Release 

set bindir=%_buildroot_%\%key%-build
if exist "%bindir%" rd /s /q "%bindir%"
cd build
call %__%\trysetvcenv

msbuild ALL_BUILD.vcxproj /p:configuration=Release  /p:WarningLevel=0
rem /p:OutDir="%key%-build/"

call %__%\copyrecursiveasbuild %source% %key%

if defined _rmsource_ rd /s /q %_buildroot_%/%key%-source
cd %back%
echo %key% installation complete!