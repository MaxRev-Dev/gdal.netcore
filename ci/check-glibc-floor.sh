#!/usr/bin/env bash
# Asserts that no shipped ELF requires a glibc symbol newer than the supported floor.
#
# The floor is a support promise, not a build-image property: the build base may ship
# a newer glibc than the oldest distro we still target, and a single dependency that
# pulls in a newer symbol raises the runtime requirement for the whole package. That
# is why shared/vcpkg.json pins expat (2.8.x uses arc4random, a glibc 2.36 symbol).
# Without this check that kind of regression only surfaces as a user load failure.
#
# Usage: check-glibc-floor.sh <path>...
#   <path> may be a directory (scanned recursively) or a .nupkg (unpacked and scanned).
# Env:
#   GLIBC_FLOOR  override the floor (default: GLIBC_FLOOR from shared/GdalCore.opt)

set -euo pipefail

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
opt_file="$script_dir/../shared/GdalCore.opt"

floor="${GLIBC_FLOOR:-}"
if [ -z "$floor" ] && [ -f "$opt_file" ]; then
    floor=$(sed -n 's/^GLIBC_FLOOR=\([0-9][0-9.]*\).*/\1/p' "$opt_file" | head -1)
fi
if [ -z "$floor" ]; then
    echo "error: no glibc floor configured (set GLIBC_FLOOR or add GLIBC_FLOOR= to shared/GdalCore.opt)" >&2
    exit 2
fi

if command -v readelf >/dev/null 2>&1; then
    readelf_bin=readelf
elif command -v llvm-readelf >/dev/null 2>&1; then
    readelf_bin=llvm-readelf
else
    echo "error: readelf not found; install binutils" >&2
    exit 2
fi

if [ "$#" -eq 0 ]; then
    echo "usage: $(basename "$0") <dir-or-nupkg>..." >&2
    exit 2
fi

work_dir=$(mktemp -d)
trap 'rm -rf "$work_dir"' EXIT

# Collect roots to scan, unpacking any nupkg as we go.
scan_roots=()
for target in "$@"; do
    if [ -d "$target" ]; then
        scan_roots+=("$target")
    elif [ -f "$target" ]; then
        case "$target" in
            *.nupkg | *.zip)
                dest="$work_dir/$(basename "$target").unpacked"
                mkdir -p "$dest"
                unzip -qq "$target" -d "$dest"
                scan_roots+=("$dest")
                echo "unpacked $(basename "$target")"
                ;;
            *) scan_roots+=("$target") ;;
        esac
    else
        echo "error: no such path: $target" >&2
        exit 2
    fi
done

is_elf() {
    [ "$(head -c 4 "$1" 2>/dev/null | od -An -tx1 | tr -d ' \n')" = "7f454c46" ]
}

# Highest of two dotted versions.
version_max() {
    printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1
}

elf_count=0
violations=0
highest="0.0"
highest_file=""

while IFS= read -r -d '' file; do
    is_elf "$file" || continue
    elf_count=$((elf_count + 1))

    # Imported symbols carry a single @ (definitions use @@). Extract clean
    # "name@GLIBC_x.y" tokens once; the raw readelf lines have a trailing " (N)"
    # index that makes anchored matching against them fail.
    imports=$("$readelf_bin" --wide --dyn-syms "$file" 2>/dev/null |
        grep -oE '[A-Za-z_][A-Za-z0-9_]*@GLIBC_[0-9]+\.[0-9]+' |
        grep -v '@@' | sort -u) || true

    [ -n "$imports" ] || continue

    required=$(printf '%s\n' "$imports" | sed 's/.*@GLIBC_//' | sort -uV) || true
    file_max=$(printf '%s\n' "$required" | tail -1)

    if [ "$(version_max "$file_max" "$highest")" != "$highest" ]; then
        highest="$file_max"
        highest_file="$file"
    fi

    if [ "$(version_max "$file_max" "$floor")" != "$floor" ]; then
        violations=$((violations + 1))
        echo
        echo "FAIL ${file#./} requires GLIBC_$file_max (floor is $floor)"
        # Name the symbols that force it, so the offending dependency is obvious.
        while IFS= read -r over; do
            [ -n "$over" ] || continue
            [ "$(version_max "$over" "$floor")" != "$floor" ] || continue
            echo "  GLIBC_$over is required by:"
            printf '%s\n' "$imports" |
                grep -E "@GLIBC_${over//./\\.}\$" |
                sed 's/@GLIBC_.*//' | sort -u | sed 's/^/    /' || true
        done <<EOF
$required
EOF
    fi
done < <(find "${scan_roots[@]}" -type f -print0)

echo
if [ "$elf_count" -eq 0 ]; then
    echo "error: no ELF binaries found under: $*" >&2
    echo "       the check would pass vacuously, so treating this as a failure" >&2
    exit 2
fi

if [ "$violations" -gt 0 ]; then
    echo "glibc floor check FAILED: $violations of $elf_count ELF binaries exceed GLIBC_$floor"
    exit 1
fi

echo "glibc floor check passed: $elf_count ELF binaries, highest requirement GLIBC_$highest (floor $floor)"
[ -n "$highest_file" ] && echo "  set by ${highest_file#./}"
exit 0
