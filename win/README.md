## Windows build scripts for GDAL

## Table of contents

- [Windows build scripts for GDAL](#windows-build-scripts-for-gdal)
  * [Prerequisites:](#prerequisites-)
  * [Building: (in cmd)](#building---in-cmd-)
  * [ISSUES](#issues)

Table of contents generated with [markdown-toc](http://ecotrust-canada.github.io/markdown-toc/).

In this folder you can find bat scripts to fetch sources and build some GDAL drivers dependencies like GEOS, jpeg, tiff, png, zlib...

### Prerequisites:

1. [Visual Studio Build Tools (with ATL)](https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=BuildTools&rel=16). Recommended versions - vs15.6 (2017) and vs16.5(2019) (**nmake** and to retarget **libpng** to v142 toolset)

2. [CMake](https://cmake.org/download/) and MinGW-w64 must be installed and available in PATH. I'm using [x86_x64_posix_seh](https://sourceforge.net/projects/mingw-w64/files/Toolchains%20targetting%20Win64/Personal%20Builds/mingw-builds/8.1.0/threads-posix/seh/x86_64-8.1.0-release-posix-seh-rt_v6-rev0.7z) (required almost all drivers)

3. [.NET Core SDK](https://dotnet.microsoft.com/download/dotnet/5.0)  and [Nuget.exe](https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools) - for building and publishing packages

6. Check build-output folders in **gdal-nmake.opt**. For example: 

   ```makefile
   # for jpeg library
   JPEGDIR = $(BUILD_ROOT_VCPKG)\libjpeg-build\include
   JPEG_LIB = $(BUILD_ROOT_VCPKG)\libjpeg-build\lib\jpeg.lib
   ```

### Building: (in cmd)

1. `init.bat` - calls initializer **vcvars64.bat**
2. `nmake -f vcpkg-makefile.vc` - installs libraries specified in `GdalCore.opt` .
3. `nmake build-proj` - configures and builds PROJ
4. `nmake build-geos` - configures and builds GEOS
5. `nmake build-gdal` - configures and builds GDAL
6. `nmake collect interface` - generates bindings and creates packages


   Optional (build PCL)

6. `nmake pack` - generates bindings and creates packages
7. `nmake test` - run tests for created packages

And finally.

You can use **dumpbin** or **dependency walker** to check gdal's dependencies. Please ensure the tests are passing before bringing them to prod. 

### ISSUES

1.  On .NET Core 3.1.200 SDK update - `dotnet pack` throws an error with MSBump: https://github.com/dotnet/core/issues/4404#issuecomment-605962124 

   ​	Workaround on this:  `set MSBUILDSINGLELOADCONTEXT=1`

Have fun)

Contact me: [Telegram - MaxRev](http://t.me/maxrev)