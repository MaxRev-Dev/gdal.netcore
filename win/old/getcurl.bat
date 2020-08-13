@echo off
set back=%cd%
call %~dp0configvars
set key=curl
if not exist "%_buildroot_%\%key%-source" git clone https://github.com/curl/curl.git "%_buildroot_%\%key%-source"
cd "%_buildroot_%\%key%-source"
git fetch
git checkout -q 1ca91bcdb588dc6c25d345f2411fdba314433732
git reset --hard
git clean -fdx
call buildconf.bat
cd winbuild
set bindir=%_buildroot_%\%key%-build
if exist "%bindir%" rd /S /Q "%bindir%"
call  %__%\trysetvcenv
nmake /f Makefile.vc mode=dll WITH_PREFIX="%key%-build"  ENABLE_WIN_SSL=yes DEBUG=no MACHINE=x64
move /Y "%key%-build" %bindir%/..

call  %__%\copyrecursive %bindir%

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!