rem Build destination
set _buildroot_=%~dp0..\..

rem Which components to install
set features=curl sqlite3 geos proj6

rem Remove sources after build?
set _rmsource_=

rem Path to vcvars bat configurators
set _vcvars_="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64

rem Bat helpers scripts root 
set __=%~dp0misc
set _pre_=%~dp0presource