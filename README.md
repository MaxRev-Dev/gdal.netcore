# gdal.netcore [![Mentioned in Awesome Geospatial](https://raw.githubusercontent.com/sindresorhus/awesome/main/media/mentioned-badge.svg)](https://github.com/sacridini/Awesome-Geospatial) 

[![Linux Build](https://img.shields.io/github/actions/workflow/status/MaxRev-Dev/gdal.netcore/unix.yml?label=Linux%20Build)](https://github.com/MaxRev-Dev/gdal.netcore/actions/workflows/unix.yml)
[![MacOS Build](https://img.shields.io/github/actions/workflow/status/MaxRev-Dev/gdal.netcore/macos.yml?label=MacOS%20Build)](https://github.com/MaxRev-Dev/gdal.netcore/actions/workflows/macos.yml)
[![Windows Build](https://img.shields.io/github/actions/workflow/status/MaxRev-Dev/gdal.netcore/windows.yml?label=Windows%20Build)](https://github.com/MaxRev-Dev/gdal.netcore/actions/workflows/windows.yml)

A simple (as is) build engine of [GDAL](https://gdal.org/) library for [.NET](https://dotnet.microsoft.com/download). 

Provides a minimal setup without requirements to install heavy [GDAL binaries](https://gdal.org/download.html#binaries) into your system.

## Packages (NuGet)

[MaxRev.Gdal.Core](https://www.nuget.org/packages/MaxRev.Gdal.Core/) 
![NuGet Version](https://img.shields.io/nuget/v/MaxRev.Gdal.Core) 
![NuGet Downloads](https://img.shields.io/nuget/dt/MaxRev.Gdal.Core) <br>

[MaxRev.Gdal.WindowsRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.WindowsRuntime.Minimal/) 
![NuGet Version](https://img.shields.io/nuget/v/MaxRev.Gdal.WindowsRuntime.Minimal)
![NuGet Downloads](https://img.shields.io/nuget/dt/MaxRev.Gdal.WindowsRuntime.Minimal) <br>

[MaxRev.Gdal.LinuxRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.LinuxRuntime.Minimal/)
![NuGet Version](https://img.shields.io/nuget/v/MaxRev.Gdal.LinuxRuntime.Minimal)
![NuGet Downloads](https://img.shields.io/nuget/dt/MaxRev.Gdal.LinuxRuntime.Minimal) <br>
-  [MaxRev.Gdal.LinuxRuntime.Minimal.x64](https://www.nuget.org/packages/MaxRev.Gdal.LinuxRuntime.Minimal.x64/)
![NuGet Version](https://img.shields.io/nuget/v/MaxRev.Gdal.LinuxRuntime.Minimal.x64)
![NuGet Downloads](https://img.shields.io/nuget/dt/MaxRev.Gdal.LinuxRuntime.Minimal.x64) <br>
- [MaxRev.Gdal.LinuxRuntime.Minimal.arm64](https://www.nuget.org/packages/MaxRev.Gdal.LinuxRuntime.Minimal.arm64/) 
![NuGet Version](https://img.shields.io/nuget/v/MaxRev.Gdal.LinuxRuntime.Minimal.arm64)
![NuGet Downloads](https://img.shields.io/nuget/dt/MaxRev.Gdal.LinuxRuntime.Minimal.arm64) <br>


[MaxRev.Gdal.MacosRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.MacosRuntime.Minimal/)
![NuGet Version](https://img.shields.io/nuget/v/MaxRev.Gdal.MacosRuntime.Minimal)
![NuGet Downloads](https://img.shields.io/nuget/dt/MaxRev.Gdal.MacosRuntime.Minimal) <br>
- [MaxRev.Gdal.MacosRuntime.Minimal.x64](https://www.nuget.org/packages/MaxRev.Gdal.MacosRuntime.Minimal.x64/) 
![NuGet Version](https://img.shields.io/nuget/v/MaxRev.Gdal.MacosRuntime.Minimal.x64)
![NuGet Downloads](https://img.shields.io/nuget/dt/MaxRev.Gdal.MacosRuntime.Minimal.x64) <br> 
- [MaxRev.Gdal.MacosRuntime.Minimal.arm64](https://www.nuget.org/packages/MaxRev.Gdal.MacosRuntime.Minimal.arm64/)
![NuGet Version](https://img.shields.io/nuget/v/MaxRev.Gdal.MacosRuntime.Minimal.arm64)
![NuGet Downloads](https://img.shields.io/nuget/dt/MaxRev.Gdal.MacosRuntime.Minimal.arm64)

## Table Of Contents
  * [Packages (NuGet)](#packages-nuget)
  * [Table Of Contents](#table-of-contents)
  * [**About this library**](#about-this-library)
    + [What is this library](#what-is-this-library)
    + [What is not](#what-is-not)
  * [**How to use**](#how-to-use)
  * [**Using GDAL functions**](#using-gdal-functions)
  * [**Development**](#--development--)
  * [How to compile on Windows](#how-to-compile-on-windows)
  * [How to compile on Unix](#how-to-compile-on-unix)
  * [About build configuration](#about-build-configuration)
  * [Building runtime libraries](#building-runtime-libraries)
  * [FAQ](#faq)
      - [Q: Packages do not work on CentOS 7, Ubuntu 18.04](#q-packages-does-not-work-on-centos-7-ubuntu-1804)
      - [Q: Can I compile it on Ubuntu or another Unix-based system?](#q-can-i-compile-it-on-ubuntu-or-another-unix-based-system-)
      - [Q: Projections are not working as expected](#q-projections-are-not-working-as-expected)
      - [Q: Some drivers complain about missing data files](#q-some-drivers-complain-about-missing-data-files)
      - [Q: Missing {some} drivers, can you add more?](#q-missing--some--drivers--can-you-add-more-)
      - [Q: GDAL functions are not working as expected](#q-gdal-functions-are-not-working-as-expected)
      - [Q: Some types throw exceptions from SWIG on Windows](#q-some-types-throw-exceptions-from-swig-on-windows)
      - [Q: In some methods performance is slower on Unix](#q-in-some-methods-performance-is-slower-on-unix)
      - [Q: OSGeo.OGR.SpatialReference throws System.EntryPointNotFoundException exception](#q-osgeoogrspatialreference-throws-systementrypointnotfoundexception-exception) 
      - [Q: Packages does not work on MacOS Catalina or lower](#q-packages-does-not-work-on-macos-catalina-or-lower)
      - [Q: The first run on MacOS is slow and takes more than 3 seconds](#q-the-first-run-on-macos-is-slow-and-takes-more-than-3-seconds)
  * [About and Contacts](#about-and-contacts)
  * [Acknowledgements](#acknowledgements)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## **About this library**

### What is this library

- Only generates assemblies and binds everything into one package.
- Provides easy access to GDAL by installing **only core and runtime package**
- DOES NOT require installation of GDAL. From 3.7.0 version GDAL_DATA is also shipped. While it contains the `proj.db` database you can require `proj-data` grid shifts.

### What is not

- Does not compile all drivers. Only configured, they are listed [below](#how-to-compile-on-unix). By default GDAL has a lot of internal drivers. 
- Does not change GDAL source code.
- Does not extend GDAL methods.

## **How to use**

1. Install core package - [MaxRev.Gdal.Core](https://www.nuget.org/packages/MaxRev.Gdal.Core/) 
```shell
dotnet add package MaxRev.Gdal.Core
```
2. Install [libraries](#packages-nuget) for your runtime. You can install one of them or all with no conflicts.
There is no requirement to install all of them or GDAL binaries. If you work on Windows and Linux you can skip MacOS package and vice versa.
```shell
# windows supported only for x64
dotnet add package MaxRev.Gdal.WindowsRuntime.Minimal 

# install linux bundle which references both arm64 and x64 binaries
dotnet add package MaxRev.Gdal.LinuxRuntime.Minimal 
# or install a specific runtime
dotnet add package MaxRev.Gdal.LinuxRuntime.Minimal.arm64
dotnet add package MaxRev.Gdal.LinuxRuntime.Minimal.x64

# install macos bundle which references both arm64 and x64 binaries
dotnet add package MaxRev.Gdal.MacosRuntime.Minimal 
# or install a specific runtime
dotnet add package MaxRev.Gdal.MacosRuntime.Minimal.arm64
dotnet add package MaxRev.Gdal.MacosRuntime.Minimal.x64
```
3. Initialize libraries in runtime
```csharp
using MaxRev.Gdal.Core;
// call it once, before using GDAL
// this will initialize all GDAL drivers and set PROJ6 shared library paths
GdalBase.ConfigureAll();
```
4. Profit! Use it in ordinary flow. See the section below for more info.


## **Using GDAL functions**
If you're struggling using GDAL functions.
Here's a good place to start:
 - [Vector related operations](https://github.com/OSGeo/gdal/tree/master/doc/source/api/csharp/csharp_vector.rst)
 - [Raster related operations](https://github.com/OSGeo/gdal/tree/master/doc/source/api/csharp/csharp_raster.rst)
 - [Sample Apps](https://github.com/OSGeo/gdal/tree/master/swig/csharp/apps)


## **Development**
## How to compile on Windows

Enter [win](win/) directory to find out how.

## How to compile on Unix

Detailed guide is here - [unix](unix/).

## How to compile on macOS

Detailed guide is here - [osx](osx/).

## About build configuration

The package configuration is marked as **minimal**. That means you don't have to install [GDAL binaries](https://gdal.org/download.html#binaries). Also, some uncommon drivers are not available (were not built).

Drivers included PROJ, GEOS, and more than 200 other drivers.
To view full list of drivers, To view the complete list of drivers, you can view the full list with GDAL's API or see property `DriversInCurrentVersion` [here](tests/MaxRev.Gdal.Core.Tests.XUnit/CommonTests.cs).

**NOTE**: Runtime drivers availability may differ. Ask me about a specific driver for runtime. Please issue if I need to mention any packages.

## Building runtime libraries

Each runtime has to be build separately, but this can be done concurrently as they are using different contexts (build folders). Primary operating bindings (in gdal.core package) are build from **windows**. Still, the resulting core bindings are the same on each runtime package (OS).

To make everything work smoothly, each configuration targets the same drivers and their versions, respectively.

To start building for a specific runtime, see the **README.md** in a respective directory.

## FAQ

#### Q: Packages does not work on CentOS 7, Ubuntu 18.04
A: These are old distros and are out of support (EOL). Use docker (see [this Dockerfile](tests/MaxRev.Gdal.Core.Tests/Dockerfile) how to package your app) or a newer distro (GLIBC 2.31+). Packages for older systems are difficult to maintain. From 3.6.x version the Debian 11 distro is used. See [this](https://github.com/MaxRev-Dev/gdal.netcore/issues/87#issuecomment-1377995387) for more info.

#### Q: Can I compile it on Ubuntu or another Unix-based system?

A: Yes, you can (see [unix](/unix/) folder for readme). All you have to do, is to choose one of the latest distros like Ubuntu 22.04 or Debian 11 (recommended). From the 3.6.x version the Debian 11 distro is used by default. It was changed because of EOL of the previous distro (see answer above). Prior to 3.6.x version packages were built on CentOS - glibc of version 2.17. It's the lowest version [(in my opinion)](https://github.com/MaxRev-Dev/gdal.netcore/issues/1#issuecomment-522817778) that suits all common systems (Ubuntu, Debian, Fedora).

#### Q: Projections are not working as expected
A: This package only contains the [`proj.db` database](https://proj.org/resource_files.html#proj-db). Make sure you have installed `proj-data` package. It contains aditional grid shifts and other data required for projections. Add path to your data folder with `MaxRev.Gdal.Core.Proj.Configure()`. See [this](https://proj.org/resource_files.html) for more info.

#### Q: Some drivers complain about missing data files
A: This is related to the previous package versions (prior to 3.7.0). From 3.7.0 version, `GDAL_DATA` folder is also shipped with core package.

#### Q: Missing {some} drivers, can you add more?

A: Feel free to contribute and I will help you you to add them. Here's the my additional [answer](https://github.com/MaxRev-Dev/gdal.netcore/issues/8#issuecomment-569864199).

#### Q: GDAL functions are not working as expected

A: Try to search an [issue on github](https://github.com/OSGeo/gdal/issues). In 98% of cases, they are working fine.

#### Q: Some types throw exceptions from SWIG on Windows

A: Yes, currently there are [some redundant](https://github.com/MaxRev-Dev/gdal.netcore/issues/11) types in OGR namespace. This will be fixed in the next builds.

#### Q: In some methods performance is slower on Unix 

A: Apparently, it's not a fault of the build engine. I did not face this issue and I use this packages in several production environments.

#### Q: OSGeo.OGR.SpatialReference throws System.EntryPointNotFoundException exception

A: That's a problem with swig bindings. Please, use **SpatialReference** type from **OSR** namespace. More info [here](https://github.com/MaxRev-Dev/gdal.netcore/issues/2#issuecomment-539716268) and [here](https://github.com/MaxRev-Dev/gdal.netcore/issues/11#issuecomment-651465581).

#### Q: Packages does not work on MacOS Catalina or lower

A: The current version of packages was compiled on MacOS Ventura and 11.3 SDK respectively. Consider updating your system to at least MacOS 13. The systems that reached [EOL](https://endoflife.date/macos) (end-of-life) won't be supported.

#### Q: The first run on MacOS is slow and takes more than 3 seconds

A: It's a known issue related to the linking of the shared libraries. If you find any solution/workaround, please let me know.
Currently, linker tries to find all shared libraries in the `@loader_path/`. It should point to the executable directory.

## About and Contacts

This work is based on [GDAL](https://github.com/OSGeo/gdal) and [GDAL bindings by jgoday](https://github.com/jgoday/gdal).

Contact me in Telegram - [MaxRev](http://t.me/maxrev).

Enjoy!

## Acknowledgements

As the maintainer of this repository, I want to express my heartfelt thanks to [Verge Agriculture Inc.](https://vergeag.com/). They generously provided the necessary resources that made compiling the **macOS** bindings and the latest versions of GDAL possible.