@echo off
set back=%cd%
call %~dp0configvars
set key=proj6

if not exist "%_buildroot_%/%key%-source" git clone %PROJ6_REPO% "%_buildroot_%/%key%-source"
cd "%_buildroot_%/%key%-source"
git checkout -q %PROJ6_COMMIT_VER%
git reset --hard
git clean -fdx
mkdir build
cd build
cmake -DSQLITE3_INCLUDE_DIR="%_buildroot_%/sqlite3-build/include" -DSQLITE3_LIBRARY="%_buildroot_%/sqlite3-build/lib/sqlite3.lib" -DEXE_SQLITE3="%_buildroot_%/sqlite3-build/bin/sqlite3.exe" ..
cmake --build . --target ALL_BUILD --config Release
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"
cmake --install . --prefix %bindir%   --config Release

call %__%\copyrecursive %bindir%

rem copy proj.db to maxrev.gdal.core.libshared
xcopy /Y "%bindir%/share/proj/proj.db" "%BUILD_ENGINE_ROOT%\maxrev.gdal.core.libshared\"

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!
