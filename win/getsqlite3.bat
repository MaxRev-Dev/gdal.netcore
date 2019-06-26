set back=%cd%
call %~dp0configvars
set key=sqlite3

if not exist %key%-source git clone https://github.com/sqlite/sqlite.git  "%_buildroot_%/%key%-source"
cd  "%_buildroot_%/%key%-source"
set source=%cd%
git checkout branch-3.28
git reset --hard
git clean -fdx
call %__%\trysetvcenv
cd %source%

nmake /f %source%\Makefile.msc TOP=%source%
nmake /f %source%\Makefile.msc %key%.c  TOP=%source%
nmake /f %source%\Makefile.msc %key%.dll  TOP=%source%
nmake /f %source%\Makefile.msc %key%.exe  TOP=%source%

call %__%\copyrecursive %source%
call %__%\copyrecursiveasbuild %source% %key% %key%

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!