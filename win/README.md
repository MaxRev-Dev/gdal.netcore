## Windows build scripts for GDAL

**ATTENTION**: *In plans to use **nmake** instead of batch scripts for future releases. Some of main batch files are not complete currently. For HDF4 driver - JPEG library must be copied to drivers folder on startup.*

## Table of contents

- [Windows build scripts for GDAL](#windows-build-scripts-for-gdal)
  * [Prerequisites:](#prerequisites-)
  * [Building: (in cmd)](#building---in-cmd-)
  * [ISSUES](#issues)

Table of contents generated with [markdown-toc](http://ecotrust-canada.github.io/markdown-toc/).

In this folder you can find bat scripts to fetch sources and build some GDAL drivers dependencies like GEOS, jpeg, tiff, png, zlib...

### Prerequisites:

1. [Visual Studio Build Tools](https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=BuildTools&rel=16). Recommended versions - vs15.6 (2017) and vs16.5(2019) (**nmake** and to retarget **libpng** to v142 toolset)

2. [CMake](https://cmake.org/download/) and MinGW-w64 must be installed and available in PATH. I'm using [x86_x64_posix_seh](https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-posix/seh/x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z) (required almost all drivers)

3. [.NET Core SDK](https://dotnet.microsoft.com/download/dotnet-core/thank-you/sdk-3.1.201-windows-x64-installer)  and [Nuget.exe](https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools) - for building and publishing packages

4. Check `CONFIGVARS.bat` first! **vcvars** variable must point to the actual location of **vcvarsall.bat** build environment configurator.

5. It's **recommended** to use **presource** folder that contains configuration files for **gdal** and **geotiff**, instead of direct modifying files in repo. They will be automatically replaced when the source is refreshed from repo via batch file. Call `fetchgdal.bat` to refresh/reset gdal repo. 

6. Check build-output folders in  **presource/gdal-nmake.opt**. For example (all instructions are available in **presource/gdal-nmake.opt**): 

   ```makefile
   # for jpeg library
   JPEGDIR = $(BUILD_ROOT)\libjpeg-build\include
   JPEG_LIB = $(BUILD_ROOT)\libjpeg-build\lib\jpeg.lib
   ```

### Building: (in cmd)

1. ```ALL_INSTALL.bat ```- installs all configured drivers (check output, some of them may fail when config in wrong).

2. ```gdal-fetch.bat``` - fetches gdal source.

3. ```gdal-build.bat``` - attempts to build gdal.

4. ```gdal-csharp.bat``` - generates interface and copies gdal lib and wrappers to the package output folder.

5. ```final-copydrivers.bat``` - copies all gdal drivers to the package output folder.

   Optional (build PCL)

6. ```cd .. && dotnet pack -c Release -o nuget gdalcore.windowsruntime.csproj``` - to create a package

And finally.

Use **dumpbin** or **dependency walker** to check gdal's dependencies. Test packages before bringing them to prod. 

### ISSUES

1.  On .NET Core 3.1.200 SDK update - `dotnet pack` throws an error with MSBump: https://github.com/dotnet/core/issues/4404#issuecomment-605962124 

   ​	Workaround on this:  `set MSBUILDSINGLELOADCONTEXT=1`

Have fun)

Contact me: [Telegram - MaxRev](http://t.me/maxrev)