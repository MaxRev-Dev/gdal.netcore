# Building GDAL bindings on unix

## Prerequisites

First of all I wish you to be patient & bring your snacks. Compilation from scratch takes nearly for 2 hours.

**Environment**: I'm compiling in WSL on **CentOS 7 with GLIBC 2.17 (2012)**

1. Dynamic linking
``` shell
yum install patchelf -y
```
2. Install dev tools > [link](https://github.com/microsoft/vcpkg#installing-linux-developer-tools)
``` shell
yum install centos-release-scl -y
yum install devtoolset-7 -y
scl enable devtoolset-7 bash
```
3. Install tools (required swig 3.0.12)
```shell
yum install swig3 -y
yum install automake -y
yum install libtool -y
yum install make -y
```

4. Install libraries
``` shell 
yum install xz-devel hdf-devel hdf5-devel libtiff sqlite-devel expat curl-devel -y
```

## Easy way compiling 

```shell
# don't forget to enable ONCE dev tools on CentOS 
scl enable devtoolset-7 bash
# install libraries with VCPKG
make -f vcpkg-makefile
# install main libraries (proj,geos,gdal)
make -f gdal-makefile
# generate bindings 
make 
# create packages
make pack
# test packages
make test
```

