## Windows build scripts for GDAL

In this folder you can find bat scripts to fetch and build 

some GDAL drivers dependencies like GEOS, jpeg, tiff, png, zlib...

​	Check **CONFIGVARS** first!!!

Default installation location is parent folder to this repo location.

​	It's **recommended** to use **presource **folder that contains configuration files for gdal and geotiff, instead of direct modifying files in repo. They will be automatically replaced when source is refreshed from repo via bat file. Use **fetchgdal.bat** to refresh/reset gdal repo. It's **recommended** to use presource files 

After build they all build folders must be linked in **nmake.opt** file in gdal's source

