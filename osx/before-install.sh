#!/bin/sh

set -e

# requirements for CI runner
brew install make pkg-config autoconf automake \
    autoconf-archive swig libtool dylibbundler gsed bison

# Install pipx without upgrading python dependencies
brew install --ignore-dependencies pipx || python3 -m pip install --user pipx

# issue with libtool on macOS https://github.com/Homebrew/homebrew-core/issues/180040
brew reinstall libtool

if [ -n "${GITHUB_PATH:-}" ]; then
  for formula in make libtool; do
    prefix=$(brew --prefix "$formula" 2>/dev/null || true)
    if [ -n "$prefix" ] && [ -d "$prefix/libexec/gnubin" ]; then
      echo "$prefix/libexec/gnubin" >> "$GITHUB_PATH"
    fi
  done
fi
