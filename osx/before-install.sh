#!/bin/sh

set -e

# Homebrew classifies macOS 15 x86_64 as Tier 3: no bottles, so anything it decides
# to (re)build is compiled from source and fetched from third-party mirrors that time
# out. Installing a formula that is present-but-outdated is enough to trigger that
# (pkgconf 3.0.5 -> source build -> http://fresh-center.net timeout), and upgrading a
# shared dependency drags unrelated dependents (ant, kotlin, selenium-server) along
# with it. Keep brew from updating and from touching dependents, install only what is
# genuinely missing, and retry whatever downloads remain.
export HOMEBREW_NO_AUTO_UPDATE=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1

brew_retry() {
    n=0
    until brew "$@"; do
        n=$((n + 1))
        if [ "$n" -ge 3 ]; then
            echo "brew $* failed after $n attempts" >&2
            return 1
        fi
        echo "brew $* failed, retrying ($n/3) in 15s" >&2
        sleep 15
    done
}

# requirements for CI runner
for formula in make pkg-config autoconf automake \
    autoconf-archive pcre2 libtool dylibbundler gsed bison; do
    brew list --formula --versions "$formula" >/dev/null 2>&1 || brew_retry install "$formula"
done

swig_prefix="${RUNNER_TEMP:-$HOME/.local}/swig"
SWIG_INSTALL_PREFIX="$swig_prefix" "$(dirname "$0")/../ci/install-swig-unix.sh"
export PATH="$swig_prefix/bin:$PATH"

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$swig_prefix/bin" >> "$GITHUB_PATH"
fi

# Install pipx without upgrading python dependencies
brew install --ignore-dependencies pipx || python3 -m pip install --user pipx

# issue with libtool on macOS https://github.com/Homebrew/homebrew-core/issues/180040
brew_retry reinstall libtool

if [ -n "${GITHUB_PATH:-}" ]; then
  for formula in make libtool; do
    prefix=$(brew --prefix "$formula" 2>/dev/null || true)
    if [ -n "$prefix" ] && [ -d "$prefix/libexec/gnubin" ]; then
      echo "$prefix/libexec/gnubin" >> "$GITHUB_PATH"
    fi
  done
fi
