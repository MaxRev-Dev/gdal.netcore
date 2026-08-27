#!/bin/bash
set -e 
sudo apt-get update
sudo apt-get install g++ make cmake git curl \
      zip unzip tar pkg-config linux-headers-generic libltdl-dev \
      autoconf automake python3 autoconf-archive libpcre2-dev patchelf bison -y

swig_prefix="${RUNNER_TEMP:-$HOME/.local}/swig-4.4.1"
SWIG_INSTALL_PREFIX="$swig_prefix" "$(dirname "$0")/../ci/install-swig-unix.sh"
export PATH="$swig_prefix/bin:$PATH"

if [ -n "${GITHUB_PATH:-}" ]; then
      echo "$swig_prefix/bin" >> "$GITHUB_PATH"
fi
