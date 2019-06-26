set back=%cd%
call %~dp0configvars
set key=libz
if not exist %key%-source git clone https://github.com/madler/zlib.git  "%_buildroot_%/%key%-source"
cd  "%_buildroot_%/%key%-source"
set source=%cd%
git checkout master
git reset --hard
git clean -fdx
call %__%\trysetvcenv
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"
mkdir %bindir%

nmake /f win32/Makefile.msc 

call %__%\copyrecursive %source%
echo Trying to create %key%-build
call %__%\copyrecursiveasbuild %source% %key%
call %__%\copyrecursiveasbuild %bindir% %key%

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!