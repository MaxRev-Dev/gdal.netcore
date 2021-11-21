# gdal.netcore [![Mentioned in Awesome Geospatial](https://awesome.re/mentioned-badge.svg)](https://github.com/sacridini/Awesome-Geospatial) ![Packages CI](https://github.com/MaxRev-Dev/gdal.netcore/workflows/CI/badge.svg?branch=master)

A simple (as is) build engine of [GDAL](https://gdal.org/) 3.2 library for [.NET Core](https://dotnet.microsoft.com/download). 

## Packages

NuGet: [MaxRev.Gdal.Core](https://www.nuget.org/packages/MaxRev.Gdal.Core/) <br/>

NuGet: [MaxRev.Gdal.LinuxRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.LinuxRuntime.Minimal/) <br/>

NuGet: [MaxRev.Gdal.WindowsRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.WindowsRuntime.Minimal/)

## Table Of Contents

- [gdal.netcore](#gdalnetcore)
  * [Packages](#packages)
  * [Table Of Contents](#table-of-contents)
  * [About this library](#about-this-library)
    + [What is this library](#what-is-this-library)
    + [What is not](#what-is-not)
  * [How to use](#how-to-use)
  * [How to compile on Windows](#how-to-compile-on-windows)
  * [How to compile on Unix](#how-to-compile-on-unix)
  * [About build configuration](#about-build-configuration)
  * [Building runtime libraries](#building-runtime-libraries)
  * [Building Nuget Packages](#building-nuget-packages)
    + [Prerequisites](#prerequisites)
    + [Packaging](#packaging)
  * [FAQ](#faq)
      - [Q: Missing {some} drivers, can you add more?](#q-missing--some--drivers--can-you-add-more-)
      - [Q: GDAL functions are not working as expected](#q-gdal-functions-are-not-working-as-expected)
      - [Q: Some types throw exceptions from SWIG on Windows](#q-some-types-throw-exceptions-from-swig-on-windows)
      - [Q: Can't compile on Windows](#q-can-t-compile-on-windows)
      - [Q: Can I compile it on Ubuntu or another Unix-based system?](#q-can-i-compile-it-on-ubuntu-or-another-unix-based-system-)
      - [Q: In some methods performance is slower on Unix](#q-in-some-methods-performance-is-slower-on-unix)
      - [Q: OSGeo.OGR.SpatialReference throws System.EntryPointNotFoundException exception](#q-osgeoogrspatialreference-throws-systementrypointnotfoundexception-exception)
  * [About and Contacts](#about-and-contacts)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## About this library

### What is this library

- Only generates assemblies and binds everything into one package.
- Provides easy access to GDAL by installing **only core and runtime package**
- DOES NOT require installation of GDAL 

### What is not

- Does not compile all drivers. Only configured, they are listed [below](#how-to-compile-on-unix). By default GDAL has a lot of internal drivers. 
- Does not change GDAL source code.
- Does not extend GDAL methods.

## How to use

1. Install core package - [MaxRev.Gdal.Core](https://www.nuget.org/packages/MaxRev.Gdal.Core/) 
 ```powershell
 Install-Package MaxRev.Gdal.Core
 ```
2. Install [libraries](#packages) for your runtime. You can install one of them or both with no conflicts. 
```powershell
Install-Package MaxRev.Gdal.WindowsRuntime.Minimal
Install-Package MaxRev.Gdal.LinuxRuntime.Minimal
```
3. Initialize libraries in runtime
```csharp
using MaxRev.Gdal.Core;
...
// call it once, before using GDAL
// this will initialize all GDAL drivers and set PROJ6 shared library paths
GdalBase.ConfigureAll();

```
4. Profit! Use it in ordinary flow


## How to compile on Windows

Enter [win](win/) directory to find out how.

## How to compile on Unix

Detailed guide is here - [unix](unix/).

## About build configuration

Current version targets **GDAL 3.3.3** with **minimal drivers**

Drivers included PROJ(7.2.1), SQLITE3, GEOS(3.9.0), HDF4, HDF5, GEOTIFF, JPEG, PNG, LIBZ, LERC, CURL

<details>
  <summary>Configure summary of current version</summary>

      GDAL is now configured for x86_64-pc-linux-gnu
      Installation directory:    /mnt/e/dev/builds/gdal-netcore/build-unix/gdal-build
      C compiler:                gcc -DHAVE_AVX_AT_COMPILE_TIME -DHAVE_SSSE3_AT_COMPILE_TIME -DHAVE_SSE_AT_COMPILE_TIME -fPIC -fvisibility=hidden
      C++ compiler:              g++ -DHAVE_AVX_AT_COMPILE_TIME -DHAVE_SSSE3_AT_COMPILE_TIME -DHAVE_SSE_AT_COMPILE_TIME -g -O2 -fvisibility=hidden
      C++14 support:             no
    
      LIBTOOL support:           yes
      
      LIBZ support:              internal
      LIBLZMA support:           no
      ZSTD support:              no
      cryptopp support:          no
      crypto/openssl support:    no
      GRASS support:             no
      CFITSIO support:           no
      PCRaster support:          no
      LIBPNG support:            internal
      DDS support:               no
      GTA support:               no
      LIBTIFF support:           internal (BigTIFF=yes)
      LIBGEOTIFF support:        internal
      LIBJPEG support:           internal
      12 bit JPEG:               yes
      12 bit JPEG-in-TIFF:       yes
      LIBGIF support:            no
      JPEG-Lossless/CharLS:      no
      OGDI support:              no
      HDF4 support:              yes
      HDF5 support:              yes
      Kea support:               no
      NetCDF support:            no
      Kakadu support:            no
      JasPer support:            no
      OpenJPEG support:          no
      ECW support:               no
      MrSID support:             no
      MrSID/MG4 Lidar support:   no
      JP2Lura support:           no
      MSG support:               no
      EPSILON support:           no
      WebP support:              no
      cURL support (wms/wcs/...):yes
      PostgreSQL support:        no
      LERC support:              yes
      MySQL support:             no
      Ingres support:            no
      Xerces-C support:          no
      Expat support:             no
      libxml2 support:           no
      Google libkml support:     no
      ODBC support:              no
      FGDB support:              no
      MDB support:               no
      PCIDSK support:            no
      OCI support:               no
      GEORASTER support:         no
      SDE support:               no
      Rasdaman support:          no
      DODS support:              no
      SQLite support:            yes
      PCRE support:              no
      SpatiaLite support:        no
      RasterLite2 support:       no
      Teigha (DWG and DGNv8):    no
      INFORMIX DataBlade support:no
      GEOS support:              yes
      SFCGAL support:            no
      QHull support:             no
      Poppler support:           no
      Podofo support:            no
      PDFium support:            no
      OpenCL support:            no
      Armadillo support:         no
      FreeXL support:            no
      SOSI support:              no
      MongoDB support:           no
      MongoCXX v3 support:       no
      HDFS support:              no
      TileDB support:            no
      userfaultfd support:       yes
      misc. gdal formats:        aaigrid adrg aigrid airsar arg blx bmp bsb cals ceos ceos2 coasp cosar ctg dimap dted e00grid elas envisat ers fit gff gsg gxf hf2 idrisi ignfheightasciigrid ilwis ingr iris iso8211 jaxapalsar jdem kmlsuperoverlay l1b leveller map mrf msgn ngsgeoid nitf northwood pds prf r raw rmf rs2 safe saga sdts sentinel2 sgi sigdem srtmhgt terragen til tsx usgsdem xpm xyz zmap rik ozi grib eeda plmosaic rda wcs wms wmts daas rasterlite mbtiles pdf
      disabled gdal formats:
      misc. ogr formats:         aeronavfaa arcgen avc bna cad csv dgn dxf edigeo geoconcept georss gml gmt gpsbabel gpx gtm htf jml mvt ntf openair openfilegdb pgdump rec s57 segukooa segy selafin shape sua svg sxf tiger vdv wasp xplane idrisi pds sdts amigocloud carto cloudant couchdb csw elastic gft ngw plscenes wfs gpkg vfk osm
      disabled ogr formats:
      
      SWIG Bindings:             no
      
      PROJ >= 6:                 yes
      enable GNM building:       no
      enable pthread support:    yes
      enable POSIX iconv support:yes
      hide internal symbols:     yes
</details>

**NOTE**: Windows and Linux drivers availability may differ, ask me of specific driver for runtime. Please issue, if I forgot to mention any other packages.

## Building runtime libraries

Current version is targeting **GDAL 3.3.3** version. Each runtime has to be build separately, but this can be done concurrently as they are using different contexts (build folders). Main operating bindings (in gdalcore package) are build from **linux**.

To make everything work smoothly, each configuration targets same drivers and their versions respectively.

- After **VCPKG** integration finished, configuration is shared between runtimes - `shared/GdalCore.opt`
- Overrides for `nmake.opt` on windows - `win/presource/gdal-nmake.opt` 
- Patched makefile - `win/presource/gdal-makefile.vc`

To build for a specific runtime, see the **README.md** in respective directory.

## Building Nuget Packages

### Prerequisites

1. Install [.NET Core SDK](https://dotnet.microsoft.com/learn/dotnet/hello-world-tutorial/install)  (3.1 or 5.0) and [Nuget.exe](https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools) - for building and publishing packages
2. You have already built everything 

### Packaging

1. I'm using [CentOS 7](https://docs.microsoft.com/en-us/dotnet/core/install/linux-centos#centos-7-) for example:

```bash
rpm -Uvh https://packages.microsoft.com/config/centos/7/packages-microsoft-prod.rpm
sudo apt-get install apt-transport-https && apt-get update && apt-get install dotnet-sdk-5.0
```

2. And then just 

```shell
make pack
```

## FAQ

#### Q: Missing {some} drivers, can you add more?

A: Feel free to contribute and I will help you you to add them. Here's the my additional [answer](https://github.com/MaxRev-Dev/gdal.netcore/issues/8#issuecomment-569864199).

#### Q: GDAL functions are not working as expected

A: Try to search an [issue on github](https://github.com/OSGeo/gdal/issues). In 98% cases, I'm sure they are working fine.  

#### Q: Some types throw exceptions from SWIG on Windows

A: Yes, currently there are [some redundant](https://github.com/MaxRev-Dev/gdal.netcore/issues/11) types in OGR namespace. This will be fixed in the next builds.

#### Q: Can't compile on Windows

A: I've built it on my machine several times from scratch. Do you have installed all SDKs? If you know **cmake** or **nmake** [you can help to port](https://github.com/MaxRev-Dev/gdal.netcore/projects/1) batch files that are buggy.

#### Q: Can I compile it on Ubuntu or another Unix-based system?

A: The main reason I'm compiling it on CentOS - glibc of version 2.17. It's the lowest version [(in my opinion)](https://github.com/MaxRev-Dev/gdal.netcore/issues/1#issuecomment-522817778) that suits for all common systems (Ubuntu, Debian, Fedora)

#### Q: In some methods performance is slower on Unix 

A: Use of [older version](https://github.com/MaxRev-Dev/gdal.netcore/issues/1) of GLIBC might be [a reason](https://github.com/MaxRev-Dev/gdal.netcore/issues/6). But It's not a fault of build engine.

#### Q: OSGeo.OGR.SpatialReference throws System.EntryPointNotFoundException exception

A: That's a problem with swig bindings. Please, use **SpatialReference** type from **OSR** namespace. More info [here](https://github.com/MaxRev-Dev/gdal.netcore/issues/2#issuecomment-539716268) and [here](https://github.com/MaxRev-Dev/gdal.netcore/issues/11#issuecomment-651465581).


## About and Contacts

based on https://github.com/OSGeo/gdal && https://github.com/jgoday/gdal

Contact me: [Telegram - MaxRev](http://t.me/maxrev)

Enjoy!

