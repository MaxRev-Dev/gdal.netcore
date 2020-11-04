@echo off
setlocal enabledelayedexpansion enableextensions

set back=%cd%
call %~dp0configvars
set key=geos
nmake -f gdal-makefile.vc fetch-geos
cd %_buildroot_%/%key%-source
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"

if not exist build md build 
cd build

rem MinGW64 must be installed and available in path
rem tested with  x86_x64_posix_seh
cmake -S .. -G "Unix Makefiles" -DCMAKE_MAKE_PROGRAM=mingw32-make^
 -DCMAKE_C_COMPILER=gcc -DCMAKE_CXX_COMPILER=g++^
 -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=%bindir%^
 -DDISABLE_GEOS_INLINE=ON^
 -DCMAKE_CXX_FLAGS="-static-libgcc -static-libstdc++ -Wl,-allow-multiple-definition -Wno-maybe-uninitialized -Wno-unused-but-set-variable"

rem  --- THIS IS NOT WORKING more than 16 errors with xmemory & xutility
rem cmake -S .. -B . -G "Visual Studio 16 2019" -A x64 -DCMAKE_GENERATOR_TOOLSET=host=x64
rem call %__%\trysetvcenv
rem msbuild geos.vcxproj  /p:configuration=Release /p:OutDir=%bindir% /p:PlatformToolset=v142
rem ----------------------

cmake --build . --config Release 
cmake --install .

rem copy mingw32 dependencies
for /f %%i in ('where mingw32-make') do set mingw32_path=%%i
call :getDirPath mingw32_dir !mingw32_path!
copy /Y "%mingw32_dir%libwinpthread-1.dll" "%bindir%/bin/"

call  %__%\copyrecursive %bindir%

if defined _rmsource_ rd /s /q %_buildroot_%/%key%-source
cd %back%
echo %key% installation complete!
goto eof
:getDirPath <resultVar> <pathVar>
(
    set "%~1=%~dp2"
    exit /b
)

:eof
endlocal