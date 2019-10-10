@echo off
set back=%cd%
call %~dp0configvars
set key=geos
if not exist "%_buildroot_%/%key%-source" git clone %GEOS_REPO% "%_buildroot_%/%key%-source"
cd %_buildroot_%/%key%-source
git checkout -q %GEOS_COMMIT_VER%
git reset --hard
git clean -fdx
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"
md build && cd build

rem MinGW64 must be installed and available in path
rem tested with  x86_x64_posix_seh
cmake -S .. -G "Unix Makefiles" -DCMAKE_MAKE_PROGRAM=mingw32-make -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++ -DCMAKE_BUILD_TYPE=Release -DHAVE_LONG_LONG_INT_64=1 -DCMAKE_INSTALL_PREFIX=%cd%/geos-build -DDISABLE_GEOS_INLINE=ON -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++ -Wl,-allow-multiple-definition -Wno-maybe-uninitialized -Wno-unused-but-set-variable"
cmake --build .
cmake --install . --prefix %key%-build
move /Y %key%-build %bindir%/..

call %__%\copyrecursive %bindir%

if defined _rmsource_ rd /s /q %_buildroot_%/%key%-source
cd %back%
echo %key% installation complete!