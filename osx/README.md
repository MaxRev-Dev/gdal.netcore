# Building GDAL bindings on OSX (macOS)
 
  * [Prerequisites](#prerequisites)
    + [**1. Environment**](#1-environment)
    + [**2. Check for required libraries**](#2-check-for-required-libraries)
    + [**3. Compiling**](#3-compiling)
    + [**How to check dependencies:**](#6-how-to-check-dependencies)

## Prerequisites

1. Install [**homebrew**](https://docs.brew.sh/Installation) and [**macports**](https://www.macports.org/install.php) (for hdf4 hdf5 netcdf drivers).
2. Install base packages with `./before-install.sh`
3. Install [dotnet](https://dotnet.microsoft.com/en-us/download) to build Nuget packages

### **1. Environment**
There two types of builds **arm64** (Apple Silicon M1 & M2 chipsets) and **x86_64** (Intel chipsets). GH Actions runner is using a x64 3-core instances.
This build was built using a self-hosted runner on a 10 CPU M2 Mac (arm64).
 
### **2. Check for required libraries**
 **VPKG** will install all requirements defined in `shared/GdalCore.opt` file. Latest versions, no collisions with other dynamic libraries.

### **3. Compiling**

Simply run `make` in current folder to start GNUmakefile which constists of steps described below.
Still, you can execute them sequentially if needed.

```bash
# install libraries with VCPKG
make -f vcpkg-makefile

# install main libraries (proj,gdal)
# > optional use [target]-force to run from scratch, ex. gdal-force
make -f gdal-makefile

# collect dynamic libraries 
make -f collect-deps-makefile

# create packages (output to 'nuget' folder)
make -f publish-makefile pack

# testing packages
# > optional PRERELEASE=1 - testing pre-release versions
# > optional APP_RUN=1 - testing via console app run (quick, to ensure deps were loaded correctly)
make -f test-makefile test
```

### **How to check dependencies:**
Run tests from the latest step. If everything loads correctly - you're good.

Or after collecting libraries, run **otool** to view dependencies .
Don't forget to set **DYLD_LIBRARY_PATH**. See **copy-deps** target in **collect-deps-makefile** for details. Assumming the repo path is `/root/gdal.netcore`.
```bash
otool -L "/root/gdal.netcore/build-osx/gdal-build/lib/libgdal.dylib"
```
