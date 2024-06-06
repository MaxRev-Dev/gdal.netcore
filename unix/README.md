# Building GDAL bindings on unix

  * [Prerequisites](#prerequisites)
    + [**1. Environment**](#1-environment)
    + [**2. Base packages**](#2-base-packages-vcpkg-and-pipeline-scripts-won-t-work-without-them)
    + [3. **Install .NET**](#3-install-net)
    + [4. **Installing libraries**.](#4-installing-libraries)
      - [Optional libraries](#optional-libraries)
    + [5. **Compiling**](#5-compiling)
    + [6. **How to check dependencies:**](#6-how-to-check-dependencies)

## Prerequisites

First of all, I wish you to be patient & bring your snacks. Compilation from scratch takes nearly for 1 hour. But from version 3.6 it looks faster with CMake.

> NOTE: this pipeline will build **only** dynamic libraries package.<br>
> C# Bindings (aka Core) are currently build in windows

### **1. Environment**
I'm compiling on **Debian 11 with GLIBC 2.31 (2020)**. See CI/CD pipeline for details.

### **2. Base packages**. VCPKG and pipeline scripts won't work without them:

```bash
sudo apt-get install g++ make cmake git curl zip unzip tar pkg-config linux-headers-amd64 autoconf automake python3 autoconf-archive swig patchelf 
```

### 3. **Install .NET**
https://learn.microsoft.com/en-us/dotnet/core/install/linux-debian#debian-11. 

### 4. **Installing libraries**. 
Libraries can be installed in two ways.

1. **VPKG** - recommended. Latest versions, no collisions with other dynamic libraries.
2. **APT package manager** - if vcpkg does not provide any. Can create conficts with other library dependencies. 

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