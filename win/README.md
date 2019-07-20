## Windows build scripts for GDAL

**ATTENTION**: some main batch files are not complete currently. gdalplugins must be copied to the root of repo from gdal-build. 

In this folder you can find bat scripts to fetch and build 

some GDAL drivers dependencies like GEOS, jpeg, tiff, png, zlib...

​	=> Check **CONFIGVARS** first!!!

Default installation location is parent folder to this repo location.

​	It's **recommended** to use **presource ** folder that contains configuration files for gdal and geotiff, instead of direct modifying files in repo. They will be automatically replaced when source is refreshed from repo via bat file. Use **fetchgdal.bat** to refresh/reset gdal repo. 

After build they all build folders must be linked in **nmake.opt** file in gdal's source

And finaly.

Use **dumpbin** to gdal's dependencies. Check nuget packages before bringing them to prod. 

Have fun)

Contact me: [Telegram - MaxRev](http://t.me/maxrev)