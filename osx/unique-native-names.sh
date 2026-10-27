#!/usr/bin/env bash
# Gives every bundled third-party dylib a unique "-maxrev" name (issue #9) and points
# the packaged CLI tools at the files we actually ship.
#
# The runtime package ships its dylibs flat in runtimes/<rid>/native, and .NET copies
# that folder flat into the app output, so a same-named dylib from another NuGet package
# can overwrite ours there, or the other way round. A unique file name plus a unique
# install id also keeps dyld from treating another package's libpng16.16.dylib as ours.
#
# Suffix goes into the stem, before the version tail:
#   libproj.25.9.8.1.dylib -> libproj-maxrev.25.9.8.1.dylib, libsqlite3.dylib -> libsqlite3-maxrev.dylib
#
# Kept under their original names (KEEP_REGEX, mirrored in
# tests/MaxRev.Gdal.Core.Tests.XUnit/UniqueNativeNamesTests.cs):
#   libgdal.N.x.y.z.dylib  linked by the wraps, the tools and third-party GDAL plugins
#   lib*_wrap.dylib        P/Invoked by name from managed code (DllImport("gdal_wrap"))
#
# Tools are linked against build-time names such as @rpath/libproj.25.dylib and
# @rpath/libgdal.39.dylib, which are symlinks in the build tree and are not shipped.
# rename resolves each of them to the shipped file and rewrites the load command, so
# this is also what makes gdalsrsinfo (which links PROJ directly) loadable.
#
# Every modified Mach-O is ad-hoc re-signed (CODESIGN_IDENTITY, default "-"); on Apple
# Silicon the kernel kills a process that maps a binary with a stale signature.
#
# Usage (bash 3.2 compatible, it runs with the stock macOS /bin/bash):
#   unique-native-names.sh rename <native-dir> <tools-dir> [<lib-search-dir>...]
#       Renames in place and rewrites install ids and load commands of every Mach-O in
#       both folders. <lib-search-dir>s are the build lib folders used to resolve tool
#       references through their symlinks. Idempotent.
#   unique-native-names.sh verify <dir-or-nupkg>...
#       Fails if a packaged dylib still uses its original name or a foreign install id,
#       if any packaged Mach-O loads something that is neither packaged nor in /usr/lib
#       or /System/Library, or if a signature does not verify.
#       Pass the runtime and CLI packages together: tools need the runtime's dylibs.
#   unique-native-names.sh smoke <native-dir> <tools-dir> [<proj-data-dir>]
#       Loads libgdal_wrap and libgdal with no DYLD_* variables set and runs
#       gdalinfo --version and gdalsrsinfo EPSG:4326 against the renamed set.
# Exit: 0 = ok, 1 = check failed, 2 = could not run (misuse/environment)

set -euo pipefail

SUFFIX="-maxrev"
KEEP_REGEX='^lib(gdal\.[0-9]+(\.[0-9]+)*\.dylib|.+_wrap\.dylib)$'
WRAPS="libgdal_wrap.dylib libogr_wrap.dylib libosr_wrap.dylib libgdalconst_wrap.dylib"
CODESIGN_IDENTITY=${CODESIGN_IDENTITY:--}

die() { echo "error: $*" >&2; exit 2; }

is_macho() { file -b "$1" 2>/dev/null | grep -q '^Mach-O'; }
is_dylib() { file -b "$1" 2>/dev/null | grep -q '^Mach-O.*shared library'; }
is_kept() { [[ "$1" =~ $KEEP_REGEX ]]; }
in_list() { case " $(echo $2) " in *" $1 "*) return 0 ;; esac; return 1; }

# libproj.25.9.8.1.dylib -> libproj-maxrev.25.9.8.1.dylib: move every trailing
# ".<digits>" in front of ".dylib" into the tail, the rest is the stem.
unique_name() {
    local stem=${1%.dylib} tail=.dylib
    [ "$stem" != "$1" ] || die "not a dylib name: $1"
    while [[ "$stem" =~ ^(.+)(\.[0-9]+)$ ]]; do
        stem=${BASH_REMATCH[1]}
        tail=${BASH_REMATCH[2]}$tail
    done
    echo "$stem$SUFFIX$tail"
}

# Top-level Mach-O files of a folder (regular files only).
macho_files() {
    local f
    for f in "$1"/*; do
        [ -f "$f" ] && [ ! -L "$f" ] && is_macho "$f" && echo "$f"
    done
    return 0
}

install_id() { otool -D "$1" | sed -n 2p; }

# Every dylib this Mach-O loads (not its own id), one per line.
macho_deps() {
    otool -l "$1" | awk '
        $1 == "cmd" { cmd = $2 }
        $1 == "name" && cmd ~ /^LC_(LOAD_DYLIB|LOAD_WEAK_DYLIB|REEXPORT_DYLIB|LOAD_UPWARD_DYLIB|LAZY_LOAD_DYLIB)$/ { print $2 }'
}

resign() {
    local out
    if ! out=$(codesign --force --sign "$CODESIGN_IDENTITY" "$1" 2>&1); then
        echo "$out" >&2
        echo "codesign failed on $1" >&2
        exit 1
    fi
}

# Follows a symlink chain to the leaf file name.
real_name() {
    local p=$1 t
    while [ -L "$p" ]; do
        t=$(readlink "$p")
        case "$t" in /*) p=$t ;; *) p=$(dirname "$p")/$t ;; esac
    done
    basename "$p"
}

# Maps a referenced leaf name to the shipped file it means (before renaming).
resolve_leaf() { # <native> <leaf> <search dirs...>
    local native=$1 leaf=$2 dir real
    shift 2
    if [ -f "$native/$leaf" ]; then echo "$leaf"; return; fi
    # already rewritten by an earlier run that stopped before renaming the files
    if [[ "$leaf" == *"$SUFFIX"* ]] && [ -f "$native/${leaf/$SUFFIX/}" ]; then echo "${leaf/$SUFFIX/}"; return; fi
    for dir in "$@"; do
        [ -e "$dir/$leaf" ] || [ -L "$dir/$leaf" ] || continue
        real=$(real_name "$dir/$leaf")
        if [ -f "$native/$real" ]; then echo "$real"; return; fi
    done
    # no build tree (or it disagrees): libproj.25.dylib means the one shipped libproj.25.*.dylib
    local matches
    matches=$(cd "$native" && ls "${leaf%.dylib}".*.dylib 2>/dev/null || true)
    if [ -n "$matches" ] && [ "$(echo "$matches" | wc -l | tr -d ' ')" = 1 ]; then echo "$matches"; return; fi
    return 1
}

cmd_rename() {
    [ "$#" -ge 2 ] || die "usage: rename <native-dir> <tools-dir> [<lib-search-dir>...]"
    local native=$1 tools=$2
    shift 2
    [ -d "$native" ] || die "no such directory: $native"
    [ -d "$tools" ] || die "no such directory: $tools"
    native=$(cd "$native" && pwd -P)
    tools=$(cd "$tools" && pwd -P)
    command -v install_name_tool >/dev/null 2>&1 || die "install_name_tool not found"
    case "$native$tools" in *[[:space:]]*) die "paths with whitespace are not supported" ;; esac

    # NuGet dereferences symlinks into full duplicate copies, and a symlink would keep
    # an original name alive next to the renamed file.
    local links
    links=$(find "$native" -maxdepth 1 -type l)
    [ -z "$links" ] || die "symlinks in $native are not supported:"$'\n'"$links"
    ls "$native"/libgdal.[0-9]*.dylib >/dev/null 2>&1 || die "libgdal.N.dylib not found in $native"

    local f name renames="" already=0
    for f in $(macho_files "$native"); do
        name=$(basename "$f")
        case "$name" in *.dylib) ;; *) continue ;; esac
        if [[ "$name" == *"$SUFFIX"* ]]; then already=$((already + 1)); continue; fi
        is_kept "$name" && continue
        [ ! -e "$native/$(unique_name "$name")" ] || die "both $name and $(unique_name "$name") exist in $native"
        renames="$renames $name"
    done
    [ -n "$renames" ] || [ "$already" -gt 0 ] || die "nothing to rename in $native"

    # Resolve every edit first and apply them after, so an unresolvable reference
    # fails the build before any file is touched.
    local dep leaf target new args id out count=0
    # global, so the EXIT trap still sees it after this function returns
    plan=$(mktemp)
    trap 'rm -f "$plan"' EXIT
    for f in $(macho_files "$native") $(macho_files "$tools"); do
        name=$(basename "$f")
        args=()
        if [ "$(dirname "$f")" = "$native" ] && in_list "$name" "$renames"; then
            id=$(install_id "$f")
            case "$id" in */*) args+=(-id "${id%/*}/$(unique_name "$name")") ;; *) args+=(-id "$(unique_name "$name")") ;; esac
        fi
        for dep in $(macho_deps "$f"); do
            case "$dep" in
                @loader_path/* | @rpath/* | @executable_path/*) ;;
                *) continue ;; # system libraries; verify rejects anything else
            esac
            leaf=${dep##*/}
            if [ "$#" -gt 0 ]; then
                target=$(resolve_leaf "$native" "$leaf" "$@") || die "$name loads $dep, which does not resolve to a shipped library"
            else
                target=$(resolve_leaf "$native" "$leaf") || die "$name loads $dep, which does not resolve to a shipped library"
            fi
            new=$target
            in_list "$target" "$renames" && new=$(unique_name "$target")
            [ "$new" = "$leaf" ] || args+=(-change "$dep" "${dep%/*}/$new")
        done
        [ "${#args[@]}" -eq 0 ] || echo "$f ${args[*]}" >> "$plan"
    done

    while read -r f rest; do
        # shellcheck disable=SC2206 # names and load paths never contain whitespace
        args=($rest)
        # fails if the new names do not fit the header padding; never relink silently
        if ! out=$(install_name_tool "${args[@]}" "$f" 2>&1); then
            echo "$out" >&2
            echo "install_name_tool failed on $f" >&2
            exit 1
        fi
        # the "will invalidate the code signature" warning is expected, we re-sign next
        echo "$out" | grep -v -e '^$' -e 'invalidate the code signature' >&2 || true
        resign "$f"
        count=$((count + 1))
    done < "$plan"

    for name in $renames; do
        mv "$native/$name" "$native/$(unique_name "$name")"
    done
    echo "renamed $(echo $renames | wc -w | tr -d ' ') dylibs to *$SUFFIX*, patched and re-signed $count Mach-O files"
    echo "kept:$(for f in $(macho_files "$native"); do n=$(basename "$f"); is_kept "$n" && printf ' %s' "$n"; done)"
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
        is_macho "$f" || continue
        if is_dylib "$f"; then echo "$f" >> "$work_dir/libs"; else echo "$f" >> "$work_dir/bins"; fi
    done < <(find "${roots[@]}" -type f -print0)

    local lib_count bin_count
    lib_count=$(wc -l < "$work_dir/libs" | tr -d ' ')
    bin_count=$(wc -l < "$work_dir/bins" | tr -d ' ')
    [ "$lib_count" -gt 0 ] || die "no dylibs found under: $*"$'\n'"       (verify the runtime package together with the CLI package)"

    local packaged
    packaged=$(xargs -n1 basename < "$work_dir/libs" | sort -u | tr '\n' ' ')

    fails=0
    fail() { echo "FAIL $*"; fails=$((fails + 1)); }

    local w
    echo "$packaged" | tr ' ' '\n' | grep -qE '^libgdal\.[0-9]+(\.[0-9]+)*\.dylib$' || fail "libgdal.N.dylib is not packaged"
    for w in $WRAPS; do in_list "$w" "$packaged" || fail "$w is not packaged"; done

    local name id dir
    while IFS= read -r f; do
        name=$(basename "$f"); dir=$(dirname "$f")
        if ! is_kept "$name" && [[ "$name" != *"$SUFFIX"* ]]; then
            fail "$name ships under its original name"
        fi
        if [[ "$name" == *"$SUFFIX"* ]] && [ -e "$dir/${name/$SUFFIX/}" ]; then
            fail "${name/$SUFFIX/} ships next to $name"
        fi
        id=$(install_id "$f")
        [ "${id##*/}" = "$name" ] || fail "$name has install id $id"
    done < "$work_dir/libs"

    local dep
    while IFS= read -r f; do
        name=$(basename "$f")
        for dep in $(macho_deps "$f"); do
            case "$dep" in
                /usr/lib/* | /System/Library/*) ;;
                @loader_path/* | @rpath/*)
                    [ "${dep%/*}" = @loader_path ] || [ "${dep%/*}" = @rpath ] \
                        || fail "$name loads $dep from a subfolder"
                    in_list "${dep##*/}" "$packaged" || fail "$name loads $dep, which is not packaged" ;;
                *) fail "$name loads $dep, which is neither packaged nor a system library" ;;
            esac
        done
        codesign --verify --strict "$f" 2>/dev/null || fail "$name has no valid code signature"
    done < <(cat "$work_dir/libs" "$work_dir/bins")

    echo
    if [ "$fails" -gt 0 ]; then
        echo "unique native names check FAILED: $fails problem(s) in $lib_count dylibs and $bin_count executables"
        exit 1
    fi
    echo "unique native names check passed: $lib_count dylibs, $bin_count executables"
    echo "  $(echo "$packaged" | tr ' ' '\n' | grep -c -- "$SUFFIX") renamed, kept: $(echo "$packaged" | tr ' ' '\n' | grep -E "$KEEP_REGEX" | tr '\n' ' ')"
}

cmd_smoke() {
    [ "$#" -ge 2 ] && [ "$#" -le 3 ] || die "usage: smoke <native-dir> <tools-dir> [<proj-data-dir>]"
    local native tools=$2 projdata=${3:-}
    native=$(cd "$1" && pwd -P)
    command -v python3 >/dev/null 2>&1 || die "python3 not found"
    local gdal
    gdal=$(ls "$native"/libgdal.[0-9]*.dylib | head -n 1)

    # Load with no DYLD_* search paths so only the rewritten @loader_path load
    # commands can resolve dependencies, then check which images dyld mapped.
    (
        unset DYLD_LIBRARY_PATH DYLD_FALLBACK_LIBRARY_PATH DYLD_INSERT_LIBRARIES
        python3 - "$native" "$gdal" "$KEEP_REGEX" "$SUFFIX" <<'EOF'
import ctypes, os, re, sys
native, gdal_path, keep, suffix = sys.argv[1:5]
ctypes.CDLL(os.path.join(native, "libgdal_wrap.dylib"))
gdal = ctypes.CDLL(gdal_path)
gdal.GDALAllRegister()
gdal.GDALVersionInfo.restype = ctypes.c_char_p
drivers = gdal.GDALGetDriverCount()
dyld = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
dyld._dyld_get_image_name.restype = ctypes.c_char_p
images = [dyld._dyld_get_image_name(i).decode() for i in range(dyld._dyld_image_count())]
ours = sorted(os.path.basename(p) for p in images if os.path.dirname(os.path.realpath(p)) == native)
bad = [n for n in ours if not re.match(keep, n) and suffix not in n]
if bad or drivers <= 0 or not any(suffix in n for n in ours):
    sys.exit("smoke load FAILED: drivers=%d, loaded under original names: %s" % (drivers, bad))
print("loaded GDAL %s: %d drivers, %d dylibs from %s" % (
    gdal.GDALVersionInfo(b"RELEASE_NAME").decode(), drivers, len(ours), native))
EOF
    ) || exit 1

    # Tools carry @rpath references and no LC_RPATH (the CLI package's MSBuild targets
    # add one in the consumer's output), so point dyld at the native folder here.
    (
        export DYLD_LIBRARY_PATH="$native"
        [ -z "$projdata" ] || export PROJ_DATA="$projdata"
        "$tools/gdalinfo" --version
        "$tools/gdalsrsinfo" -o proj4 EPSG:4326
    ) || { echo "smoke run of packaged tools FAILED"; exit 1; }
}

[ "$#" -gt 0 ] || die "usage: $(basename "$0") rename|verify|smoke ..."
command -v otool >/dev/null 2>&1 || die "otool not found; install the Xcode command line tools"
command=$1; shift
case "$command" in
    rename) cmd_rename "$@" ;;
    verify) cmd_verify "$@" ;;
    smoke) cmd_smoke "$@" ;;
    *) die "unknown command: $command" ;;
esac
