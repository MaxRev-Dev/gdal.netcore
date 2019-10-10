set BUILD_ENGINE_ROOT=%~dp0..
rem Build destination
set _buildroot_=%~dp0..\build-win

set GDAL_REPO=https://github.com/OSGeo/gdal.git
set GDAL_COMMIT_VER=558f8a7aa15498ac25fb4a8227b220c1d4fecf29

set PROJ6_REPO=https://github.com/OSGeo/PROJ.git
set PROJ6_COMMIT_VER=2228592582910d866b8c1b5187bc2ef50955b281

set GEOS_REPO=https://github.com/libgeos/geos.git 
set GEOS_COMMIT_VER=ff05d9755d189771147acb3105bd9c9cfff730ff

rem Which components to install 
set features=curl sqlite3  libz libjpeg libpng geos proj6 hdf4 hdf5

rem Remove sources after build? (init for true)
set _rmsource_=

rem Path to vcvars bat configurators
set _vcvars_="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64

set _libshared_=libshared
rem Bat helpers scripts root 
set tclsh="%~dp0tcl\tclsh.exe"
set __=%~dp0misc
set _pre_=%~dp0presource