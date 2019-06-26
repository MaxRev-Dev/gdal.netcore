# gdal.netcore

#### NuGet: [MaxRev.Gdal.Core](https://www.nuget.org/packages/MaxRev.Gdal.Core/) <br/>
#### NuGet: [MaxRev.Gdal.LinuxRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.LinuxRuntime.Minimal/) <br/>
#### NuGet: [MaxRev.Gdal.WindowsRuntime.Minimal](https://www.nuget.org/packages/MaxRev.Gdal.WindowsRuntime.Minimal/)

## **How to compile on Windows**

It's quite tricky. Enter [win](win/README.md) directory to find out how.

## **How to compile on Unix**

Current version targets GDAL 3.0.0 with minimal drivers

Drivers included PROJ6 with sqlite3, GEOS(3.8), GEOTIFF, JPEG, PNG, LIBZ, LERC

##### Prerequisites

First of all I wish you to be patient & bring your snacks. Compilation from scratch takes nearly for 2 hours.

I'm compiling in WSL - Debian 9.7 distro, cause It has GLIBC 2.2.5 natively.

My root directory - /mnt/e/dev/builds/ 

To link SO libraries against exec dir: 

​	`sudo apt-get install patchelf -y`

Please issue, if of I forgot to mention any other packages

#### Soo.. Let's start

You can compile Gdal & Proj6 using **GdalMakefile**, but before any actions you must setup paths in **GdalCore.opt** file.

(TODO: I will provide guide here in few days)

If you have libsqlite3-dev installed you may skip this step

### Compile SQLite3 (optional)

1. [Download SQLite3 Autoconf](https://www.sqlite.org/download.html) & unpack 
2. `./configure --prefix=/mnt/e/dev/builds/sqlite3-bin`  
3. `make && make install`

### Compile PROJ6 

1. [Download proj](https://proj.org/download.html) & unpack 
2. `./configure CFLAGS="-fPIC" --prefix=/mnt/e/dev/builds/proj6-bin`
3.  `make LDFLAGS="-Wl,-rpath '-Wl,\$\$ORIGIN' -L/mnt/e/dev/sqlite3-bin/lib" && make install`        

  Note: you must specify sqlite lib custom location with -L flag

### Clone & Compile GDAL

1. `git clone https://github.com/OSGeo/gdal.git gdal-source && cd gdal-source/gdal`
2. `./configure CFLAGS="-fPIC"  --with-geos --with-geotiff=internal --with-hide-internal-symbols --with-libtiff=internal --with-libz=internal --with-jpeg=internal  --with-threads --without-cfitsio --without-cryptopp --without-curl --without-ecw --without-expat --without-fme --without-freexl --without-gif --without-gnm --without-grass --without-hdf4 --without-hdf5 --without-idb --without-ingres --without-jasper --without-jp2mrsid --without-kakadu --without-libgrass --without-libkml --without-libtool --without-mrsid --without-mysql --without-netcdf --without-odbc --without-ogdi --without-openjpeg --without-pcidsk --without-pcraster --without-pcre --without-perl --without-pg --without-python --without-qhull --without-sde --without-sqlite3 --without-webp --without-xerces --without-xml2 --without-poppler --without-crypto --prefix=$(pwd)/build --with-proj=/mnt/e/dev/builds/proj6-bin`              

After you have gdal installed, you can proceed to netcore build                                                                           

### Clone this repo

1. `git clone https://github.com/MaxRev-Dev/gdal.netcore.git gdal-netcore-idle && cd gdal-netcore-idle `

2. Edit library path for proj & gdal (configured above) in **GNUMakefile**

3. `make interface` 

4. `make RID=linux-x64`

5. Cheers!

   

   If you want to create nuget packages 

   ### **Install dotnet sdk for PCL builds** >> [dotnet](https://dotnet.microsoft.com/learn/dotnet/hello-world-tutorial/install)

   Im using debian for example

   `wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.asc.gpg`
   `sudo mv microsoft.asc.gpg /etc/apt/trusted.gpg.d/`
   `wget -q https://packages.microsoft.com/config/debian/9/prod.list`
   `sudo mv prod.list /etc/apt/sources.list.d/microsoft-prod.list`
   `sudo chown root:root /etc/apt/trusted.gpg.d/microsoft.asc.gpg`
   `sudo chown root:root /etc/apt/sources.list.d/microsoft-prod.list`
   `sudo apt-get install apt-transport-https && apt-get update && apt-get install dotnet-sdk-2.2`

   And then just

   `make pack`

based on https://github.com/OSGeo/gdal && https://github.com/jgoday/gdal

Contact me: [Telegram - MaxRev](http://t.me/maxrev)

Enjoy!

