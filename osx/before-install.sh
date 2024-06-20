#!/bin/sh

set -e

# requirements for CI runner. Removed python3 as it is already installed and causes symlink issues
brew install make pkg-config autoconf automake \
    autoconf-archive swig libtool dylibbundler gsed pipx