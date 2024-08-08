#!/bin/sh

set -e

# requirements for CI runner. Removed python3 as it is already installed and causes symlink issues
brew install make pkg-config autoconf automake \
    autoconf-archive swig libtool dylibbundler gsed pipx

# issue with libtool on macOS https://github.com/Homebrew/homebrew-core/issues/180040
brew reinstall libtool