rem Build destination
set _buildroot_=%~dp0..\..

rem Which components to install 
set features=curl sqlite3 libjpeg libz proj6 geos hdf4 hdf5

rem Remove sources after build? (init for true)
set _rmsource_=

rem Path to vcvars bat configurators
set _vcvars_="C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" amd64

set _libshared_=maxrev.gdal.core.libshared
rem Bat helpers scripts root 
set __=%~dp0misc
set _pre_=%~dp0presource