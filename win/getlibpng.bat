set back=%cd%
call %~dp0configvars
set key=libpng

if not exist %key%-source git clone https://github.com/glennrp/libpng.git "%_buildroot_%/%key%-source"
cd  "%_buildroot_%/%key%-source"
set source=%cd%
git checkout master
git reset --hard
git clean -fdx
call %__%\trysetvcenv
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"
mkdir "%bindir%"

devenv projects/vstudio/vstudio.sln  /upgrade
msbuild projects/vstudio/vstudio.sln  /p:configuration="Release" /p:ZLibSrcDir="%_buildroot_%/libz-source" /p:TreatWarningAsError=false   /p:Platform="Win32" /p:OutDir=%bindir%/ /p:PlatformToolset=v142   /clp:NoSummary;NoItemAndPropertyList;ErrorsOnly /verbosity:quiet
rem /clp:ErrorsOnly

call %__%\copyrecursive %bindir%
echo Trying to create %key%-build
call %__%\copyrecursiveasbuild %source% %key%
call %__%\copyrecursiveasbuild %bindir% %key%
cd "%bindir%"
rem del *.* /q 


cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!
