# gdal.netcore

#### NuGet: [MaxRev.Gdal.Core](https://www.nuget.org/packages/MaxRev.Gdal.Core/) <br/>
#### NuGet: [MaxRev.Gdal.LinuxRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.LinuxRuntime.Minimal/) <br/>
#### NuGet: [MaxRev.Gdal.WindowsRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.WindowsRuntime.Minimal/)

## **How to compile on Windows**

It's quite tricky. Enter [win](win/) directory to find out how.

## **How to compile on Unix**

Current version targets GDAL 3.0.0 with minimal drivers

Drivers included PROJ6 with sqlite3, GEOS(3.8), HDF4, HDF5, GEOTIFF, JPEG, PNG, LIBZ, LERC

NOTE: Windows and Linux drivers avialability may differ, ask me of specific driver for runtime.

##### Prerequisites

First of all I wish you to be patient & bring your snacks. Compilation from scratch takes nearly for 2 hours.

I'm compiling in WSL - **Debian 9.7 distro, cause It has GLIBC 2.24 (2016) natively**.
For next release I will recompile to all libs using **CentOS 7 with GLIBC 2.17 (2012)**

To link SO libraries against exec dir: 

  `sudo apt-get install patchelf -y`

Please issue, if of I forgot to mention any other packages

#### Soo.. Let's start

If you have installed sqlite3 and proj6 goto step #3.

If you have libsqlite3-dev installed you may skip first step.

Set a root variable for convenience
``export gc_root=`pwd` ``

### 1. Compile SQLite3 (optional)

1. [Download SQLite3 Autoconf](https://www.sqlite.org/download.html) & unpack  <br>
  `curl -o sqlite.tar.gz "https://www.sqlite.org/2019/sqlite-autoconf-3290000.tar.gz"` <br>
  `tar xfv sqlite.tar.gz && mv sqlite-autoconf-3290000 sqlite3-source && cd sqlite3-source`
2. `./configure --prefix=$gc_root/sqlite3-bin`  
3. `make && make install && cd $gc_root`

### 2. Compile PROJ6 

1. [Download proj](https://proj.org/download.html) & unpack <br>
  `curl -o proj-6.1.0.tar.gz "https://download.osgeo.org/proj/proj-6.1.0.tar.gz"` <br>
  `tar xfv proj-6.1.0.tar.gz && mv proj-6.1.0 proj6-source && cd proj6-source`
2. `./configure CFLAGS="-fPIC" --prefix=$gc_root/proj6-bin`
3.  `make LDFLAGS="-Wl,-rpath '-Wl,\$\$ORIGIN' -L$gc_root/sqlite3-bin/lib" && make install && cd $gc_root`        

  Note: you must specify the sqlite lib custom location with -L flag

### 3. Clone & Compile GDAL

You can build gdal using **GdalMakefile**, but before you must setup paths in **GdalCore.opt** file.
Also you must change **configuregdal.sh** script to setup necessary drivers.

Then you may just call `make -f GdalMakefile build` - this will sync gdal repository, configure it and finaly build.

Or alternatively...
1. `git clone https://github.com/OSGeo/gdal.git gdal-source && cd gdal-source/gdal`
2. `./configuregdal.sh`   - **change** before you go!
3. `make -f GdalMakefile full`

After you have gdal installed, you can proceed to netcore build                                                                           

### 4. Clone this repo and build a wrapper

1. `git clone https://github.com/MaxRev-Dev/gdal.netcore.git gdal-netcore-idle && cd gdal-netcore-idle `
2. Edit library path for proj & gdal (configured above) in **GNUMakefile**
3. `make interface` 
4. `make RID=linux-x64`
5. Cheers!

   

   If you want to create nuget packages 

   ### **Install dotnet sdk for PCL builds** >> [dotnet](https://dotnet.microsoft.com/learn/dotnet/hello-world-tutorial/install)

   Im using debian for example

   ```bash
   wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg
   sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/
   wget -q https://packages.microsoft.com/config/debian/9/prod.list
   sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list
   sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg
   sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list
   sudo apt-get install apt-transport-https && apt-get update && apt-get install dotnet-sdk-2.2
   ```

   And then just

   `make pack`

based on https://github.com/OSGeo/gdal && https://github.com/jgoday/gdal

Contact me: [Telegram - MaxRev](http://t.me/maxrev)

Enjoy!

