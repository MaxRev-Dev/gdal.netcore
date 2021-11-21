set BUILD_ENGINE_ROOT=%~dp0..
rem Build destination
set _buildroot_=%~dp0..\build-win

set PROJ_REPO=https://github.com/OSGeo/PROJ.git
set PROJ_COMMIT_VER=dd91c93ca44cbe3cf4f6f7c94a8f225aefa4b408

set GEOS_REPO=https://github.com/libgeos/geos.git 
set GEOS_COMMIT_VER=ff05d9755d189771147acb3105bd9c9cfff730ff

set LIBRARIES=%_buildroot_%/vcpkg/installed/x64-windows

rem Which components to install 
set features=hdf4 geos proj

rem Remove sources after build? (init for true)
set _rmsource_=

rem Path to vcvars bat configurators
set _vcvars_="C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" amd64

set _libshared_=libshared
set NUGET_LIBSHARED=maxrev.gdal.core.libshared

set __=%~dp0misc
set _pre_=%~dp0presource