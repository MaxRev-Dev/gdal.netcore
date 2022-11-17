@echo off
set back=%cd%
call %~dp0configvars
set key=proj
set bindir=%_buildroot_%/%key%-build

if not exist "%_buildroot_%/%key%-source" git clone %PROJ_REPO% "%_buildroot_%/%key%-source"

nmake -f makefile.vc fetch-proj
cd "%_buildroot_%/%key%-source"
mkdir build
cd build 
cmake -DSQLITE3_INCLUDE_DIR="%LIBRARIES%/include"^
 -DTIFF_INCLUDE_DIR="%LIBRARIES%/include"^
 -DCURL_INCLUDE_DIR="%LIBRARIES%/include"^
 -DTIFF_LIBRARY="%LIBRARIES%/lib/tiff.lib"^
 -DCURL_LIBRARY="%LIBRARIES%/lib/libcurl.lib"^
 -DSQLITE3_LIBRARY="%LIBRARIES%/lib/sqlite3.lib"^
 -DEXE_SQLITE3="%LIBRARIES%/tools/sqlite3.exe"^
 -DBUILD_TESTING=OFF .. || goto :error
cmake --build . --target ALL_BUILD --config Release || goto :error
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"
cmake --install . --prefix %bindir%   --config Release || goto :error

call %__%\copyrecursive %bindir% 
rem copy proj.db to maxrev.gdal.core.libshared
xcopy /Y /R /F  "%bindir%/share/proj/proj.db" "%BUILD_ENGINE_ROOT%\%NUGET_LIBSHARED%\win-x64"

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!
goto :EOF

:error
echo Failed with error #%errorlevel%.
exit /b %errorlevel%