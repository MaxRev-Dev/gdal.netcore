#!/usr/bin/env bash
# Gives every bundled third-party shared library a unique "-maxrev" name (issue #9).
#
# The runtime package ships its libraries flat in runtimes/<rid>/native, and .NET copies
# that folder flat into the app output. A same-named .so from another NuGet package
# (NetVips, SkiaSharp, ...) can overwrite ours there, or the other way round. glibc also
# reuses any already loaded object whose SONAME equals a DT_NEEDED entry, ignoring
# RUNPATH, so a libz.so.1 or libproj.so.25 loaded first by other code would satisfy
# our imports too. Renaming the file and its SONAME, and rewriting every DT_NEEDED that
# points at it, makes both directions impossible.
#
# Suffix goes into the stem so the soname keeps its lib*.so[.N] shape:
#   libproj.so.25 -> libproj-maxrev.so.25, libsqlite3.so -> libsqlite3-maxrev.so
#
# Only top-level bundled libraries are renamed, matching Windows; runtime-loaded
# plugins in subdirectories retain their names. Current packaging is flat.
# Kept under their original names (KEEP_REGEX, mirrored in
# tests/MaxRev.Gdal.Core.Tests.XUnit/UniqueNativeNamesTests.cs):
#   libgdal.so.N        NEEDED by the wraps, the tools and third-party GDAL plugins
#   lib*_wrap.so        P/Invoked by name from managed code (DllImport("gdal_wrap"))
#   libgomp.so.N        GCC OpenMP runtime; one shared runtime per process is preferred
#
# Usage:
#   unique-native-names.sh rename <native-dir> [<tools-dir>]
#       Renames in place and rewrites SONAME / DT_NEEDED / verneed of every ELF in both
#       folders. Also sets the libraries' RUNPATH to $ORIGIN:$ORIGIN/runtimes/<rid>/native.
#       Idempotent.
#   unique-native-names.sh verify <dir-or-nupkg>...
#       Fails if a packaged library still uses its original name, or any packaged ELF
#       needs a library that is neither packaged nor a glibc/toolchain system library.
#       Pass the runtime and CLI packages together: tools need the runtime's libraries.
#   unique-native-names.sh smoke <native-dir> <tools-dir> [<proj-data-dir>]
#       Loads libgdal_wrap and libgdal with an empty LD_LIBRARY_PATH and runs
#       gdalinfo --version and gdalsrsinfo EPSG:4326 against the renamed set.
# Exit: 0 = ok, 1 = check failed, 2 = could not run (misuse/environment)

set -euo pipefail

SUFFIX="-maxrev"
KEEP_REGEX='^lib(gdal\.so\.[0-9]+|.+_wrap\.so|gomp\.so\.[0-9]+)$'
WRAPS="libgdal_wrap.so libogr_wrap.so libosr_wrap.so libgdalconst_wrap.so"
# glibc and the GCC runtime; LIBS_TO_REMOVE in collect-deps-makefile keeps them out of
# the package, so they are the only libraries a packaged ELF may need from the system.
SYSTEM_LIBS="libc.so.6 libm.so.6 libdl.so.2 libpthread.so.0 librt.so.1 libresolv.so.2
libutil.so.1 libcrypt.so.1 libstdc++.so.6 libgcc_s.so.1 ld-linux-x86-64.so.2
ld-linux-aarch64.so.1 linux-vdso.so.1"

die() { echo "error: $*" >&2; exit 2; }

is_elf() {
    [ "$(head -c 4 "$1" 2>/dev/null | od -An -tx1 | tr -d ' \n')" = "7f454c46" ]
}
is_lib_name() { [[ "$1" =~ \.so(\.[0-9]+)*$ ]]; }
is_kept() { [[ "$1" =~ $KEEP_REGEX ]]; }
in_list() { case " $(printf '%s' "$2" | tr '\n' ' ') " in *" $1 "*) return 0 ;; esac; return 1; }

# libproj.so.25 -> libproj-maxrev.so.25
unique_name() {
    [[ "$1" =~ ^(.+)(\.so(\.[0-9]+)*)$ ]] || die "not a shared library name: $1"
    echo "${BASH_REMATCH[1]}$SUFFIX${BASH_REMATCH[2]}"
}

find_readelf() {
    if command -v readelf >/dev/null 2>&1; then echo readelf
    elif command -v llvm-readelf >/dev/null 2>&1; then echo llvm-readelf
    else die "readelf not found; install binutils"
    fi
}

# Top-level ELF files of a folder (regular files only).
elf_files() {
    local f
    for f in "$1"/*; do
        [ -f "$f" ] && [ ! -L "$f" ] && is_elf "$f" && echo "$f"
    done
    return 0
}

dyn_values() { # <file> <tag text>, e.g. "Shared library" or "Library soname"
    "$READELF" -dW "$1" | sed -n "s/.*$2: \[\(.*\)\]/\1/p"
}
verneed_files() {
    "$READELF" -VW "$1" | sed -n 's/.*File: \([^ ]*\).*/\1/p' | sort -u
}

cmd_rename() {
    [ "$#" -ge 1 ] && [ "$#" -le 2 ] || die "usage: rename <native-dir> [<tools-dir>]"
    local native=$1 tools=${2:-}
    [ -d "$native" ] || die "no such directory: $native"
    [ -z "$tools" ] || [ -d "$tools" ] || die "no such directory: $tools"
    command -v patchelf >/dev/null 2>&1 || die "patchelf not found"

    # RUNPATH needs the RID: take it from <root>/runtimes/<rid>/native, else from $RID
    local rid
    native=$(cd "$native" && pwd -P)
    if [ "$(basename "$native")" = native ] && [ "$(basename "$(dirname "$(dirname "$native")")")" = runtimes ]; then
        rid=$(basename "$(dirname "$native")")
    else
        rid=${RID:-}
    fi
    [ -n "$rid" ] || die "cannot tell the RID of $native; set RID"
    local runpath="\$ORIGIN:\$ORIGIN/runtimes/$rid/native"

    # NuGet dereferences symlinks into full copies, and a symlink would keep an
    # original name alive next to the renamed file.
    local links
    links=$(find "$native" -maxdepth 1 -type l)
    [ -z "$links" ] || die "symlinks in $native are not supported:"$'\n'"$links"
    ls "$native"/libgdal.so.[0-9]* >/dev/null 2>&1 || die "libgdal.so.N not found in $native"

    local f name renames="" already=0
    for f in $(elf_files "$native"); do
        name=$(basename "$f")
        is_lib_name "$name" || continue
        if [[ "$name" == *"$SUFFIX"* ]]; then already=$((already + 1)); continue; fi
        is_kept "$name" && continue
        [ ! -e "$native/$(unique_name "$name")" ] || die "both $name and $(unique_name "$name") exist in $native"
        renames="$renames $name"
    done
    [ -n "$renames" ] || [ "$already" -gt 0 ] || die "nothing to rename in $native"

    # patchelf 0.14 (Debian 12) mis-applies --set-soname or --set-rpath combined with
    # --replace-needed in one call (the SONAME ends up as one of the new NEEDED names),
    # so each kind of edit gets its own call. Several --replace-needed in one call are fine.
    local count=0 needed replace
    for f in $(elf_files "$native") ${tools:+$(elf_files "$tools")}; do
        name=$(basename "$f")
        replace=()
        for needed in $(patchelf --print-needed "$f"); do
            if in_list "$needed" "$renames"; then
                replace+=(--replace-needed "$needed" "$(unique_name "$needed")")
            fi
        done
        if [ "$(dirname "$f")" = "$native" ] && is_lib_name "$name"; then
            patchelf --set-rpath "$runpath" "$f" || { echo "patchelf --set-rpath failed on $f" >&2; exit 1; }
            if in_list "$name" "$renames"; then
                patchelf --set-soname "$(unique_name "$name")" "$f" || { echo "patchelf --set-soname failed on $f" >&2; exit 1; }
            fi
        fi
        if [ "${#replace[@]}" -gt 0 ]; then
            patchelf "${replace[@]}" "$f" || { echo "patchelf --replace-needed failed on $f" >&2; exit 1; }
            count=$((count + 1))
        fi
    done

    for name in $renames; do
        mv "$native/$name" "$native/$(unique_name "$name")"
    done
    echo "renamed $(echo "$renames" | wc -w | tr -d ' ') libraries to *$SUFFIX*, rewrote DT_NEEDED in $count ELF files"
    echo "kept:$(for f in $(elf_files "$native"); do n=$(basename "$f"); is_kept "$n" && printf ' %s' "$n"; done)"
}

cmd_verify() {
    [ "$#" -gt 0 ] || die "usage: verify <dir-or-nupkg>..."

    # global, so the EXIT trap still sees it after this function returns
    work_dir=$(mktemp -d)
    trap 'rm -rf "$work_dir"' EXIT

    local target dest roots=()
    for target in "$@"; do
        if [ -d "$target" ]; then
            roots+=("$target")
        elif [ -f "$target" ]; then
            case "$target" in
                *.nupkg | *.zip)
                    command -v unzip >/dev/null 2>&1 || die "unzip not found"
                    dest="$work_dir/$(basename "$target").unpacked"
                    mkdir -p "$dest"
                    unzip -qq "$target" -d "$dest" || die "failed to unpack $target"
                    roots+=("$dest") ;;
                *) die "not a directory or package: $target" ;;
            esac
        else
            die "no such path: $target"
        fi
    done

    local f
    : > "$work_dir/libs"; : > "$work_dir/bins"
    while IFS= read -r -d '' f; do
        [ -r "$f" ] || die "unreadable: $f"
        is_elf "$f" || continue
        if is_lib_name "$(basename "$f")"; then echo "$f" >> "$work_dir/libs"; else echo "$f" >> "$work_dir/bins"; fi
    done < <(find "${roots[@]}" -type f -print0)

    local lib_count bin_count
    lib_count=$(wc -l < "$work_dir/libs" | tr -d ' ')
    bin_count=$(wc -l < "$work_dir/bins" | tr -d ' ')
    [ "$lib_count" -gt 0 ] || die "no shared libraries found under: $*"$'\n'"       (verify the runtime package together with the CLI package)"

    local packaged
    packaged=$(xargs -n1 basename < "$work_dir/libs" | sort -u | tr '\n' ' ')

    local fails=0
    fail() { echo "FAIL $*"; fails=$((fails + 1)); }

    local w
    echo "$packaged" | tr ' ' '\n' | grep -qE '^libgdal\.so\.[0-9]+$' || fail "libgdal.so.N is not packaged"
    for w in $WRAPS; do in_list "$w" "$packaged" || fail "$w is not packaged"; done

    local name soname runpath dir
    while IFS= read -r f; do
        name=$(basename "$f"); dir=$(dirname "$f")
        if ! is_kept "$name" && [[ "$name" != *"$SUFFIX"* ]]; then
            fail "$name ships under its original name"
        fi
        if [[ "$name" == *"$SUFFIX"* ]] && [ -e "$dir/${name/$SUFFIX/}" ]; then
            fail "${name/$SUFFIX/} ships next to $name"
        fi
        soname=$(dyn_values "$f" "Library soname")
        if [ -n "$soname" ] && [ "$soname" != "$name" ]; then
            fail "$name has SONAME $soname"
        elif [ -z "$soname" ] && ! is_kept "$name"; then
            fail "$name has no SONAME"
        fi
        runpath=$(dyn_values "$f" "Library runpath")
        # shellcheck disable=SC2016 # Match the literal loader token.
        [[ ":$runpath:" == *':$ORIGIN:'* ]] || fail "$name RUNPATH '$runpath' lacks \$ORIGIN"
    done < "$work_dir/libs"

    local dep
    while IFS= read -r f; do
        name=$(basename "$f")
        for dep in $(dyn_values "$f" "Shared library"); do
            in_list "$dep" "$packaged" || in_list "$dep" "$SYSTEM_LIBS" \
                || fail "$name needs $dep, which is neither packaged nor a system library"
        done
        # glibc refuses to bind a versioned symbol whose verneed file is not loaded,
        # so the version requirements must follow the renamed DT_NEEDED entries
        for dep in $(verneed_files "$f"); do
            in_list "$dep" "$packaged" || in_list "$dep" "$SYSTEM_LIBS" \
                || fail "$name has a version requirement on $dep, which is neither packaged nor a system library"
        done
    done < <(cat "$work_dir/libs" "$work_dir/bins")

    echo
    if [ "$fails" -gt 0 ]; then
        echo "unique native names check FAILED: $fails problem(s) in $lib_count libraries and $bin_count executables"
        exit 1
    fi
    echo "unique native names check passed: $lib_count libraries, $bin_count executables"
    echo "  $(echo "$packaged" | tr ' ' '\n' | grep -c -- "$SUFFIX") renamed, kept: $(echo "$packaged" | tr ' ' '\n' | grep -E "$KEEP_REGEX" | tr '\n' ' ')"
}

cmd_smoke() {
    [ "$#" -ge 2 ] && [ "$#" -le 3 ] || die "usage: smoke <native-dir> <tools-dir> [<proj-data-dir>]"
    local native tools=$2 projdata=${3:-}
    native=$(cd "$1" && pwd -P)
    command -v python3 >/dev/null 2>&1 || die "python3 not found"
    local gdal
    local candidates=("$native"/libgdal.so.[0-9]*)
    gdal=${candidates[0]}

    # Load with nothing on LD_LIBRARY_PATH so only RUNPATH and the rewritten
    # DT_NEEDED entries can resolve dependencies, then check where they came from.
    (
        unset LD_LIBRARY_PATH LD_PRELOAD
        python3 - "$native" "$gdal" "$KEEP_REGEX" "$SUFFIX" <<'EOF'
import ctypes, os, re, sys
native, gdal_path, keep, suffix = sys.argv[1:5]
ctypes.CDLL(os.path.join(native, "libgdal_wrap.so"))
gdal = ctypes.CDLL(gdal_path)
gdal.GDALAllRegister()
gdal.GDALVersionInfo.restype = ctypes.c_char_p
drivers = gdal.GDALGetDriverCount()
with open("/proc/self/maps") as maps:
    mapped = {line.split(None, 5)[5].strip() for line in maps if len(line.split(None, 5)) == 6}
ours = sorted(os.path.basename(p) for p in mapped if os.path.dirname(p) == native and ".so" in p)
bad = [n for n in ours if not re.match(keep, n) and suffix not in n]
if bad or drivers <= 0 or not any(suffix in n for n in ours):
    sys.exit("smoke load FAILED: drivers=%d, loaded under original names: %s" % (drivers, bad))
print("loaded GDAL %s: %d drivers, %d libraries from %s" % (
    gdal.GDALVersionInfo(b"RELEASE_NAME").decode(), drivers, len(ours), native))
EOF
    ) || exit 1

    (
        export LD_LIBRARY_PATH="$native"
        [ -z "$projdata" ] || export PROJ_DATA="$projdata"
        "$tools/gdalinfo" --version
        "$tools/gdalsrsinfo" -o proj4 EPSG:4326
    ) || { echo "smoke run of packaged tools FAILED"; exit 1; }
}

[ "$#" -gt 0 ] || die "usage: $(basename "$0") rename|verify|smoke ..."
READELF=$(find_readelf)
command=$1; shift
case "$command" in
    rename) cmd_rename "$@" ;;
    verify) cmd_verify "$@" ;;
    smoke) cmd_smoke "$@" ;;
    *) die "unknown command: $command" ;;
esac
