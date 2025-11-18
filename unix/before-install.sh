#!/bin/bash
set -e 
sudo apt-get update
sudo apt-get install g++ make cmake git curl \
      zip unzip tar pkg-config linux-headers-generic libltdl-dev \
      autoconf automake python3 autoconf-archive swig patchelf -y