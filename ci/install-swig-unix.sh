#!/bin/sh

set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
SWIG_LOCK_FILE=${SWIG_LOCK_FILE:-"$script_dir/../shared/swig.lock"}
SWIG_INSTALL_PREFIX=${SWIG_INSTALL_PREFIX:-/usr/local}

IFS=' ' read -r SWIG_VERSION SWIG_SHA256 extra < "$SWIG_LOCK_FILE"
if [ -n "${extra:-}" ] || ! echo "$SWIG_VERSION" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || ! echo "$SWIG_SHA256" | grep -Eq '^[0-9a-f]{64}$'; then
    echo "Invalid SWIG lock file: $SWIG_LOCK_FILE" >&2
    exit 1
fi

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
