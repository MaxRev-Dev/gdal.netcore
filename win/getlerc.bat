@echo off
set back=%cd%
call %~dp0configvars
set key=lerc

if not exist "%_buildroot_%/%key%-source" git clone https://github.com/Esri/lerc.git "%_buildroot_%/%key%-source"
cd  "%_buildroot_%/%key%-source"
set source=%cd%
git checkout master
git reset --hard
git clean -fdx
set bindir=%_buildroot_%/%key%-build
if exist "%bindir%" rd /s /q "%bindir%"
mkdir %bindir%
call %__%\trysetvcenv
devenv build/windows/MS_VS2017/Lerc.sln  /upgrade
msbuild build/windows/MS_VS2017/Lerc/Lerc.vcxproj  /p:configuration=Release /p:OutDir=%bindir% /p:PlatformToolset=v142

call %__%\copyrecursive %bindir%

cd %back%
if defined _rmsource_ rd /s /q "%_buildroot_%/%key%-source"
echo %key% installation complete!
