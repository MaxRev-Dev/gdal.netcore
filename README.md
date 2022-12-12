# gdal.netcore [![Mentioned in Awesome Geospatial](https://awesome.re/mentioned-badge.svg)](https://github.com/sacridini/Awesome-Geospatial) ![Packages CI](https://github.com/MaxRev-Dev/gdal.netcore/workflows/CI/badge.svg?branch=master)

A simple (as is) build engine of [GDAL](https://gdal.org/) 3.6.0 library for [.NET](https://dotnet.microsoft.com/download). 

## Packages

NuGet: [MaxRev.Gdal.Core](https://www.nuget.org/packages/MaxRev.Gdal.Core/) <br/>

NuGet: [MaxRev.Gdal.LinuxRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.LinuxRuntime.Minimal/) <br/>

NuGet: [MaxRev.Gdal.WindowsRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.WindowsRuntime.Minimal/)

## Table Of Contents
  * [**Packages**](#packages)
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
      - [Q: Missing {some} drivers, can you add more?](#q-missing--some--drivers--can-you-add-more-)
      - [Q: GDAL functions are not working as expected](#q-gdal-functions-are-not-working-as-expected)
      - [Q: Some types throw exceptions from SWIG on Windows](#q-some-types-throw-exceptions-from-swig-on-windows)
      - [Q: Can I compile it on Ubuntu or another Unix-based system?](#q-can-i-compile-it-on-ubuntu-or-another-unix-based-system-)
      - [Q: In some methods performance is slower on Unix](#q-in-some-methods-performance-is-slower-on-unix)
      - [Q: OSGeo.OGR.SpatialReference throws System.EntryPointNotFoundException exception](#q-osgeoogrspatialreference-throws-systementrypointnotfoundexception-exception)
  * [About and Contacts](#about-and-contacts)

<small><i><a href='http://ecotrust-canada.github.io/markdown-toc/'>Table of contents generated with markdown-toc</a></i></small>

## **About this library**

### What is this library

- Only generates assemblies and binds everything into one package.
- Provides easy access to GDAL by installing **only core and runtime package**
- DOES NOT require installation of GDAL 

### What is not

- Does not compile all drivers. Only configured, they are listed [below](#how-to-compile-on-unix). By default GDAL has a lot of internal drivers. 
- Does not change GDAL source code.
- Does not extend GDAL methods.

## **How to use**

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

## About build configuration

Current version targets **GDAL 3.6.0** with **minimal drivers**. What stands for 'minimal' - drivers that require no additional dependencies (mainly boost). For example, `MySQL` driver is not included, because it requires 15+ boost deps. Same goes for `Poppler` driver. They will be included upon request.

Drivers included PROJ(7.2.1), GEOS(3.11.1) and more than 200 other drivers.
To view full list of drivers, see property `DriversInCurrentVersion` [here](tests/MaxRev.Gdal.Core.Tests.XUnit/CommonTests.cs).

**NOTE**: Windows and Linux drivers availability may differ, ask me of specific driver for runtime. Please issue, if I forgot to mention any other packages.

## Building runtime libraries

Current version is targeting **GDAL 3.6.0** version. Each runtime has to be build separately, but this can be done concurrently as they are using different contexts (build folders). Main operating bindings (in gdal.core package) are build from **windows**.

To make everything work smoothly, each configuration targets same drivers and their versions respectively.

To start building for a specific runtime, see the **README.md** in a respective directory.

## FAQ

#### Q: Missing {some} drivers, can you add more?

A: Feel free to contribute and I will help you you to add them. Here's the my additional [answer](https://github.com/MaxRev-Dev/gdal.netcore/issues/8#issuecomment-569864199).

#### Q: GDAL functions are not working as expected

A: Try to search an [issue on github](https://github.com/OSGeo/gdal/issues). In 98% cases, I'm sure they are working fine.  

#### Q: Some types throw exceptions from SWIG on Windows

A: Yes, currently there are [some redundant](https://github.com/MaxRev-Dev/gdal.netcore/issues/11) types in OGR namespace. This will be fixed in the next builds.

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

