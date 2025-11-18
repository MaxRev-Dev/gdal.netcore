#!/bin/bash
set -e

arch="$(dpkg --print-architecture)"
case "$arch" in
     amd64)
          header_pkg="linux-headers-amd64"
          ;;
     arm64)
          header_pkg="linux-headers-arm64"
          ;;
     *)
          header_pkg="linux-headers-$(uname -r)"
          echo "Unknown architecture '$arch', falling back to $header_pkg" >&2
          ;;
esac

sudo apt-get install g++ make cmake git curl \
      zip unzip tar pkg-config "$header_pkg" \
      autoconf automake python3 autoconf-archive swig patchelf