# Building GDAL bindings on unix

## Prerequisites

First of all, I wish you to be patient & bring your snacks. Compilation from scratch takes nearly for 1 hour. But from version 3.6 it possibly faster with CMake.

> NOTE: this pipeline will build **only** dynamic libraries package.<br>
> C# Bindings (aka Core) are currently build in windows

### **1. Environment**
I'm compiling in WSL on **Debian 11 with GLIBC 2.31 (2020)**

### **2. Base packages**. VCPKG and pipeline scripts won't work without them:

```bash
sudo apt-get install g++ make cmake git curl zip unzip tar pkg-config linux-headers-amd64 autoconf automake swig patchelf 
```


### 3. **Install .NET**
https://learn.microsoft.com/en-us/dotnet/core/install/linux-debian#debian-11

### 4. **Installing libraries**. 
Libraries can be installed in two ways.

1. **VPKG** - recommended. Latest versions, no collisions with other dynamic libraries.
2. **APT package manager** - if vcpkg does not provide any. Can create conficts with other library dependencies. 

Each library enables one driver
```bash 
sudo apt-get install libhdf4-dev
```
#### Optional libraries
```bash
sudo apt-get install libnetcdf-dev libspatialite-dev libpoppler-dev libmysql++-dev 
```

### 5. **Compiling**

```bash
# install libraries with VCPKG
make -f vcpkg-makefile

# install main libraries (proj,gdal)
make -f gdal-makefile

# collect dynamic libraries 
make -f collect-deps-makefile

# create packages (output to 'nuget' folder)
make -f publish-makefile pack

# testing packages
# optional PRERELEASE=1 - testing pre-release versions
# optional APP_RUN=1 - testing via console app run (quick, to ensure deps were loaded correctly)
make -f test-makefile test
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