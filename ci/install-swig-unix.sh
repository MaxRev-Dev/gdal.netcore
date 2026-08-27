#!/bin/sh

set -eu

SWIG_VERSION=4.4.1
SWIG_SHA256=40162a706c56f7592d08fd52ef5511cb7ac191f3593cf07306a0a554c6281fcf
SWIG_INSTALL_PREFIX=${SWIG_INSTALL_PREFIX:-/usr/local}

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

archive="$work_dir/swig-$SWIG_VERSION.tar.gz"
curl --fail --location --silent --show-error --retry 3 \
    "https://downloads.sourceforge.net/project/swig/swig/swig-$SWIG_VERSION/swig-$SWIG_VERSION.tar.gz" \
    --output "$archive"

if command -v sha256sum >/dev/null 2>&1; then
    actual_sha256=$(sha256sum "$archive" | awk '{print $1}')
else
    actual_sha256=$(shasum -a 256 "$archive" | awk '{print $1}')
fi

if [ "$actual_sha256" != "$SWIG_SHA256" ]; then
    echo "SWIG $SWIG_VERSION checksum mismatch: expected $SWIG_SHA256, got $actual_sha256" >&2
    exit 1
fi

tar -xzf "$archive" -C "$work_dir"
cd "$work_dir/swig-$SWIG_VERSION"
./configure --prefix="$SWIG_INSTALL_PREFIX"
make -j2
make install

"$SWIG_INSTALL_PREFIX/bin/swig" -version
