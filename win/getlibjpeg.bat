@echo off
set back=%cd%
call %~dp0configvars
set key=libjpeg

if not exist "%_buildroot_%/%key%-source" git clone https://github.com/LuaDist/libjpeg.git "%_buildroot_%/%key%-source"
cd  "%_buildroot_%/%key%-source"
set source=%cd%
 git fetch origin pull/3/head:lof
 git checkout lof
git clean -fdx
rem -DZLIB_LIBRARY=%_buildroot_%/libz-source/zlib.lib -DZLIB_INCLUDE_DIR=%_buildroot_%/libz-source
cmake  -S . -B build -A x64 -DCMAKE_GENERATOR_TOOLSET=host=x64
cmake --build build --config Release 
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"
md %key%-build
cmake --install build --prefix %key%-build
move /Y %key%-build %bindir%/..

call %__%\copyrecursive %bindir%

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!
