set back=%cd%
call %~dp0configvars
set key=curl
if not exist "%_buildroot_%\%key%-source" git clone https://github.com/curl/curl.git "%_buildroot_%\%key%-source"
cd "%_buildroot_%\%key%-source"
git checkout master
git reset --hard
git clean -fdx
call %__%\buildconf
cd winbuild
set bindir=%_buildroot_%\%key%-build
if exist "%bindir%" rd /S /Q "%bindir%"
call  %__%\trysetvcenv
nmake /f Makefile.vc mode=dll WITH_PREFIX="%key%-build"  MACHINE=x64
move /Y "%key%-build" %bindir%/..

call  %__%\copyrecursive %bindir%

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!