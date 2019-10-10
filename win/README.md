## Windows build scripts for GDAL

**ATTENTION**: Plans to use **nmake** instead of batch scripts for future releases. Some of main batch files are not complete currently. For HDF4 - JPEG library must be copied to drivers folder on startup.

**Prerequisites:**

1. Visual Studio 2017 (to retarget **libpng** to v142 toolset)

In this folder you can find bat scripts to fetch sources and build some GDAL drivers dependencies like GEOS, jpeg, tiff, png, zlib...

​	=> Check **CONFIGVARS** first!!

​	It's **recommended** to use **presource ** folder that contains configuration files for gdal and geotiff, instead of direct modifying files in repo. They will be automatically replaced when source is refreshed from repo via bat file. Use **fetchgdal.bat** to refresh/reset gdal repo. 

**Building:** (in cmd)

1. ```ALL_INSTALL.bat ```- installs all configured drivers (check output, some of them may fail when config in wrong).

   Check build-output folders in  **presource/gdal-nmake.opt**. For example (all instructions are available in **presource/gdal-nmake.opt**): 

   ```makefile
   # for jpeg library
   JPEGDIR = $(BUILD_ROOT)\libjpeg-build\include
   JPEG_LIB = $(BUILD_ROOT)\libjpeg-build\lib\jpeg.lib
   ```

2. ```gdal-fetch.bat``` - fetches gdal source.

3. ```gdal-build.bat``` - attempts to build gdal.

4. ```gdal-csharp.bat``` - generates interface and copies gdal lib and wrappers to the package output folder.

5. ```final-copydrivers.bat``` - copies all gdal drivers to the package output folder.

6. ```cd .. && dotnet pack -c Release -o nuget gdalcore.windowsruntime.csproj``` - to create a package

And finally.

Use **dumpbin** or **dependency walker** to check gdal's dependencies. Check nuget packages before bringing them to prod. 

Have fun)

Contact me: [Telegram - MaxRev](http://t.me/maxrev)