#!/bin/sh
source=`pwd`/../build-unix
cd ${source}/gdal-source/gdal
vcdir=${source}/vcpkg/installed/x64-linux
chmod +x  ./configure 
export PKG_CONFIG_PATH="${vcdir}/lib/pkgconfig"

# hdf5 path - only this works.
# tried with vcpkg static and other HDF5_LIBS

./configure  --prefix=${source}/gdal-build  \
CFLAGS="-fPIC" \
 --with-geos=${source}/geos-build/bin/geos-config \
 --with-proj=${source}/proj-build \
 --with-liblzma \
 --with-libtool \
 --with-geotiff=internal \
 --with-hide-internal-symbols \
 --with-threads \
 --with-curl \
 --with-png  \
 --with-sqlite3 \
 --with-hdf4 \
 --with-hdf5="/usr/lib64" \
 --with-libz=${vcdir} \
 --with-jpeg=${vcdir}  \
 --with-expat=${vcdir} \
 --with-libtiff=${vcdir} \
 --with-xerces=${vcdir} \
 --without-cfitsio \
 --without-cryptopp \
 --without-ecw \
 --without-fme \
 --without-freexl \
 --without-gif \
 --without-gnm \
 --without-grass \
 --without-idb \
 --without-ingres \
 --without-jasper \
 --without-jp2mrsid \
 --without-kakadu \
 --without-libgrass \
 --without-libkml \
 --without-mrsid \
 --without-mysql \
 --without-netcdf \
 --without-odbc \
 --without-ogdi \
 --without-openjpeg \
 --without-pcidsk \
 --without-pcraster \
 --without-pcre \
 --without-perl \
 --without-pg \
 --without-python \
 --without-qhull \
 --without-sde \
 --without-webp \
 --without-xml2 \
 --without-poppler \
 --without-crypto