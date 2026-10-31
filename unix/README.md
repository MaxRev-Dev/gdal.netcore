# Building GDAL bindings on unix

  * [Prerequisites](#prerequisites)
    + [**1. Environment**](#1-environment)
    + [**2. Base packages**](#2-base-packages-vcpkg-and-pipeline-scripts-won-t-work-without-them)
    + [3. **Install .NET**](#3-install-net)
    + [4. **Installing libraries**.](#4-installing-libraries)
      - [Optional libraries](#optional-libraries)
    + [5. **Compiling**](#5-compiling)
    + [6. **How to check dependencies:**](#6-how-to-check-dependencies)
    + [7. **Bundled library names**](#7-bundled-library-names)

## Prerequisites

First of all, I wish you to be patient & bring your snacks. Compilation from scratch takes nearly for 1 hour. But from version 3.6 it looks faster with CMake.

> NOTE: this pipeline will build **only** dynamic libraries package.<br>
> C# Bindings (aka Core) are currently build in windows

### **1. Environment**
I'm compiling on **Debian 12 (2023) with GLIBC 2.36 (2022)**. Note that the build host's glibc is not the floor the artifacts require - a binary only requires the highest symbol version it actually references, which is why the packages still run on GLIBC 2.35. See CI/CD pipeline for details.

### **2. Base packages**. VCPKG and pipeline scripts won't work without them:

```bash
./before-install.sh
export PATH="$HOME/.local/swig/bin:$PATH"
```

### 3. **Install .NET**
https://learn.microsoft.com/en-us/dotnet/core/install/linux-debian#debian-12. 

### 4. **Installing libraries**. 
Libraries can be installed in two ways.

1. **VCPKG** - recommended. Latest versions, no collisions with other dynamic libraries.
2. **APT package manager** - if vcpkg does not provide any. Can create conflicts with other library dependencies. 

The Unix build uses the shared manifest bundle in `../shared/`:

- `../shared/vcpkg.json`
- `../shared/vcpkg-configuration.json`
- `../shared/vcpkg-lock.json`

That same bundle is also used by macOS and Windows so the dependency graph stays aligned across all runtimes.

Each library enables one driver
```bash 
sudo apt-get install libhdf4-dev libnetcdf-dev
```
#### Optional libraries
```bash
sudo apt-get install libspatialite-dev libpoppler-dev
```

### 5. **Compiling**

Simply run `make` in current folder to start GNUmakefile which constists of steps described below.
Still, you can execute them sequentially if needed.

```bash
# install libraries with VCPKG
make -f vcpkg-makefile BUILD_ARCH=arm64

# install main libraries (proj,gdal)
# > optional use [target]-force to run from scratch, ex. gdal-force
make -f gdal-makefile  BUILD_ARCH=arm64

# collect dynamic libraries 
make -f collect-deps-makefile BUILD_ARCH=arm64

# create packages (output to 'nuget' folder)
make -f publish-makefile pack  BUILD_ARCH=arm64

# testing packages
# > optional PRERELEASE=1 - testing pre-release versions
# > optional APP_RUN=1 - testing via console app run (quick, to ensure deps were loaded correctly)
make -f test-makefile test  BUILD_ARCH=arm64
```

On CI, cache-warm runs reuse both the VCPKG binary cache and the Docker Buildx layer cache for the selected architecture.

### 6. **How to check dependencies:**
Run tests. If everything loads correctly - you're good.

Or after collecting libraries, run **readelf**.
Don't forget to set **LD_LIBRARY_PATH**. See **copy-deps** target in **collect-deps** for details. Assumming the repo path is `/root/gdal.netcore`.
```bash
readelf -d "/root/gdal.netcore/build-unix/gdal-build/lib/libgdal.so" | grep NEEDED
```

Or using **ldd**:
```bash
ldd "/root/gdal.netcore/build-unix/gdal-build/lib/libgdal.so"
```

### 7. **Bundled library names**
Every bundled third-party library is renamed to `<name>-maxrev` with the suffix in the stem, so the soname keeps its usual shape (for example `libproj-maxrev.so.25`, `libssl-maxrev.so.3`, `libsqlite3-maxrev.so`). Its SONAME is changed to match, and the DT_NEEDED entries and symbol version requirements of every packaged library and CLI tool are rewritten (`unique-native-names.sh rename`, run by the `unique-native-names` target in `collect-deps-makefile`). The dynamic linker reuses any already loaded library whose SONAME equals a DT_NEEDED entry, regardless of RUNPATH, so without this a `libz.so.1` or `libproj.so.25` loaded first by other code would be used instead of ours, and the other way round. Unique names also keep our libraries from overwriting, or being overwritten by, same-named libraries of other NuGet packages in the shared `runtimes/linux-x64/native` output folder (#9). The OpenSSL rename for #224 is part of this: `libssl-maxrev.so.3` cannot shadow the system `libssl.so.3` that .NET uses for HTTPS.

These keep their original names: `libgdal.so.<N>` (linked by the wraps, the tools and third-party GDAL plugins), the SWIG `lib*_wrap.so` (loaded by name from managed code) and `libgomp.so.1` (the GCC OpenMP runtime, best shared with the rest of the process). Code that loads a bundled library by its old name (for example `NativeLibrary.Load("libproj.so.25")`) no longer gets our copy, and external plugins that link a standard soname, such as ODBC drivers needing `libodbcinst.so.2`, load the system library next to ours.

`unique-native-names.sh verify` then fails the build if a bundled library still ships under its original name, or any packaged binary needs an original name or a library that is neither packaged nor part of glibc and the GCC runtime; `unique-native-names.sh smoke` loads the result and runs `gdalinfo` and `gdalsrsinfo`. CI runs `verify` again on the finished packages:
```bash
./unique-native-names.sh verify ../nuget/*.nupkg
```
