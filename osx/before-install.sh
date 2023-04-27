#!/bin/sh

set -e

brew install make pkg-config autoconf automake \
    autoconf-archive swig libtool dylibbundler

# also we need these libraries
sudo port install hdf4 hdf5 netcdf