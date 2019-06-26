set back=%cd%
call %~dp0configvars
set key=proj6
if not exist %key%-source git clone https://github.com/OSGeo/PROJ.git "%_buildroot_%/%key%-source"
cd "%_buildroot_%/%key%-source"
git checkout 6.1
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

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!
