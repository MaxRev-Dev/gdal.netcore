set back=%cd%
call %~dp0configvars
set key=libgeotiff
if not exist %key%-source git clone https://github.com/OSGeo/libgeotiff.git "%_buildroot_%/%key%-source"
cd "%_buildroot_%/%key%-source"
git checkout master
git reset --hard
git clean -fdx
cd libgeotiff
set source=%cd%
set _buildroot_=%_buildroot_:\=/%
call %__%\trysetvcenv
xcopy /Y /R /F "%_pre_%\geotiff-makefile.vc" .\makefile.vc

set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"
nmake /f makefile.vc
nmake /f makefile.vc devinstall

rem cmake -DLDLIBS=-I"%_buildroot_%/sqlite3-build/lib/libsqlite3.lib"  -DTIFF_LIBRARY=%_buildroot_%/libtiff-build/lib/tiff.lib -DTIFF_INCLUDE_DIR=%_buildroot_%/libtiff-build/include -DPROJ_LIBRARY=%_buildroot_%/proj6-build/lib/proj_6_1.lib -DPROJ_INCLUDE_DIR=%_buildroot_%/proj6-build/include .. 
rem cmake --build . --target ALL_BUILD --config Release

call %__%\copyrecursive %bindir%

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!
