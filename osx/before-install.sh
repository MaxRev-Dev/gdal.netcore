#!/bin/sh

set -e

# requirements for CI runner
brew install make pkg-config autoconf automake \
    autoconf-archive swig libtool dylibbundler gsed python3 pipx