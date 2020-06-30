# Building GDAL bindings on unix

## Table Of Contents

* [Easy way compiling](#easy-way-compiling)
* [Alternate way](#alternate-way)
  + [1. Compile SQLite3 (optional)](#1-compile-sqlite3-optional)
  + [2. Compile PROJ6](#2-compile-proj6)
  + [3. Clone and Compile GDAL](#3-clone-and-compile-gdal)
  + [4. Build a wrapper](#4-build-a-wrapper)

### Prerequisites

First of all I wish you to be patient & bring your snacks. Compilation from scratch takes nearly for 2 hours.

**Environment**: I'm compiling in WSL on **CentOS 7 with GLIBC 2.17 (2012)**

1.  `yum install tcl tcl-devel -y`   - for building sqlite3 
2.  `yum install patchelf -y` - dynamic linking

If you have installed **libsqlite3-dev** and **proj6** - go forward to step **#3**

If you have **libsqlite3-dev** installed you may skip the first step.

Set a root variable for convenience 
``export gc_root=`pwd` ``

**Soo.. Let's start**

## Easy way compiling

Assuming you have `tclsh` for compiling `sqlite3` 

```shell
make -f GdalMakefile
```

this will compile `sqlite3, proj6, geos` and `gdal` from scratch

##  Alternate way

### 1. Compile SQLite3 (optional)

1. [Download SQLite3 Autoconf](https://www.sqlite.org/download.html) & unpack (GdalMakefile uses git for this)

   ```shell
   mkdir $gc_root/build-unix  
   curl -o sqlite.tar.gz "https://www.sqlite.org/2019/sqlite-autoconf-3290000.tar.gz"
   tar xfv sqlite.tar.gz && mv sqlite-autoconf-3290000 sqlite3-source && cd sqlite3-source
   ```

2. Configure sqlite3

   ```shell
   ./configure --prefix=$gc_root/sqlite3-build
   ```

3. Compile and install

   ```shell
   make && make install && cd $gc_root
   ```

   

### 2. Compile PROJ6 

1. [Download proj](https://proj.org/download.html) & unpack  (GdalMakefile uses git for this)

   ```shell
   mkdir $gc_root/build-unix
   curl -o proj-6.1.0.tar.gz "https://download.osgeo.org/proj/proj-6.1.0.tar.gz"
   tar xfv proj-6.1.0.tar.gz && mv proj-6.1.0 proj6-source && cd proj6-source
   ```

2. ```shell
   ./configure CFLAGS="-fPIC" --prefix=$gc_root/proj6-build
   ```

3. ```shell
   make LDFLAGS="-Wl,-rpath '-Wl,\$\$ORIGIN' -L$gc_root/sqlite3-build/lib" && make install && cd $gc_root  
   ```

  **Note**: you must specify the **sqlite3 library** custom location with **-L flag**

### 3. Clone and Compile GDAL

You can build gdal using **GdalMakefile**, but before you must setup paths in **GdalCore.opt** file.
Also you must change **configuregdal.sh** script to setup necessary drivers.

Then you may just call `make -f GdalMakefile gdal` - this will sync gdal repository, configure it and finaly build.

*Or alternatively...* (assuming you are in the root of this repo)

1. ```shell
   git clone https://github.com/OSGeo/gdal.git $gc_root/build-unix/gdal-source
   ```

2. ```shell
   cd $gc_root && make -f GdalMakefile configure_gdal #calls ./configuregdal.sh
   ```

3. ```shell
   make -f GdalMakefile build_gdal
   ```

After you have gdal installed, you can proceed to netcore bindings build.                                                                           

### 4. Build a wrapper

1. Edit library path for proj & gdal (configured above) in **GNUMakefile**

2. ```shell
   cd $gc_root && make interface
   ```

3. ```shell
   make RID=linux-x64 
   ```

4. Cheers!