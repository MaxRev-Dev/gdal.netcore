#!/usr/bin/env bash
# Asserts that no shipped ELF requires a glibc symbol newer than the supported floor.
#
# The floor is a support promise, not a build-image property: the build base may ship
# a newer glibc than the oldest distro we still target, and a single dependency that
# pulls in a newer symbol raises the runtime requirement for the whole package.
#
# That is why shared/vcpkg.json holds expat below 2.8. expat has called arc4random in
# xmlparse.c since well before 2.8 (it is there in 2.7.4), so the version alone is not
# the issue; what changed is that 2.8.0 added CMake detection for it
# (EXPAT_WITH_ARC4RANDOM, default AUTO). vcpkg builds expat with CMake, so 2.7.x never
# links it, while 2.8.0+ resolves AUTO to ON against a glibc 2.36 base and imports
# arc4random_buf@GLIBC_2.36. To un-pin, build expat with
# -DEXPAT_WITH_ARC4RANDOM=OFF -DEXPAT_WITH_ARC4RANDOM_BUF=OFF and keep this gate green.
#
# This gate must never pass without having actually read symbol versions: a wrong path,
# an unreadable file, or a readelf that fails all exit 2 rather than reporting success.
#
# Usage: check-glibc-floor.sh <path>...
#   <path> may be a directory (scanned recursively) or a .nupkg/.zip (unpacked, scanned).
# Env:
#   GLIBC_FLOOR  override the floor (default: GLIBC_FLOOR from shared/GdalCore.opt)
# Exit: 0 = within floor, 1 = floor exceeded, 2 = could not determine (misuse/environment)

set -euo pipefail

die() { echo "error: $*" >&2; exit 2; }

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
opt_file="$script_dir/../shared/GdalCore.opt"

floor="${GLIBC_FLOOR:-}"
floor_source="GLIBC_FLOOR env"
if [ -z "$floor" ] && [ -f "$opt_file" ]; then
    # grep first so a stray second definition cannot SIGPIPE sed under pipefail
    floor=$(grep -m1 '^GLIBC_FLOOR=' "$opt_file" | cut -d= -f2 | tr -d '[:space:]' || true)
    floor_source="shared/GdalCore.opt"
fi
[ -n "$floor" ] || die "no glibc floor configured (set GLIBC_FLOOR or add GLIBC_FLOOR= to shared/GdalCore.opt)"

# Validate whatever the source was. An unexpanded template or typo must not silently
# disable the gate: sort -V ranks letters above digits, so a non-numeric floor would
# make every binary compare as compliant.
case "$floor" in
    *[!0-9.]* | .* | *. | "") die "floor from $floor_source is not a version: '$floor'" ;;
esac
[[ "$floor" == *.* ]] || die "floor from $floor_source is not a version: '$floor'"

if command -v readelf >/dev/null 2>&1; then
    readelf_bin=readelf
elif command -v llvm-readelf >/dev/null 2>&1; then
    readelf_bin=llvm-readelf
else
    die "readelf not found; install binutils"
fi
command -v unzip >/dev/null 2>&1 || die "unzip not found"

[ "$#" -gt 0 ] || { echo "usage: $(basename "$0") <dir-or-nupkg>..." >&2; exit 2; }

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
                unzip -qq "$target" -d "$dest" || die "failed to unpack $target"
                scan_roots+=("$dest")
                echo "unpacked $(basename "$target")"
                ;;
            *) scan_roots+=("$target") ;;
        esac
    else
        die "no such path: $target"
    fi
done

is_elf() {
    [ "$(head -c 4 "$1" 2>/dev/null | od -An -tx1 | tr -d ' \n')" = "7f454c46" ]
}

# Highest of two dotted versions.
version_max() {
    printf '%s\n%s\n' "$1" "$2" | sort -V | tail -1
}

# Every glibc version this ELF requires, from two independent sources:
#  - undefined (imported) symbols, which also give us names for diagnostics
#  - the .gnu.version_r needs block, which additionally carries non-symbol ABI tags
glibc_imports() {
    "$readelf_bin" --wide --dyn-syms "$1" \
        | awk '$7 == "UND"' \
        | grep -oE '[A-Za-z_][A-Za-z0-9_]*@GLIBC_[0-9]+(\.[0-9]+)+' || true
}
glibc_needs() {
    "$readelf_bin" --wide -V "$1" \
        | awk '/Version needs section/ {inblk=1} /^Version (definition|symbols) section/ {inblk=0} inblk' \
        | grep -oE 'Name: GLIBC_[A-Za-z0-9_.]+' | sed 's/^Name: //' || true
}

elf_count=0
measured=0
violations=0
unreadable=0
read_failures=0
unknown_needs=""
highest="0.0"
highest_file=""

find "${scan_roots[@]}" -type f -print0 > "$work_dir/files" \
    || die "failed to enumerate files under: $*"

while IFS= read -r -d '' file; do
    # An unreadable file inside a package we just unpacked is an anomaly, not an
    # absence of risk. Treating it as "not an ELF" would hide it from the count.
    [ -r "$file" ] || { echo "unreadable: $file" >&2; unreadable=$((unreadable + 1)); continue; }
    is_elf "$file" || continue
    elf_count=$((elf_count + 1))

    if ! imports=$(glibc_imports "$file"); then
        echo "readelf --dyn-syms failed on $file" >&2
        read_failures=$((read_failures + 1)); continue
    fi
    if ! needs=$(glibc_needs "$file"); then
        echo "readelf -V failed on $file" >&2
        read_failures=$((read_failures + 1)); continue
    fi

    # Non-numeric requirements (e.g. GLIBC_ABI_DT_RELR, which implies glibc >= 2.36)
    # cannot be compared, so refuse to judge rather than pass silently.
    others=$(printf '%s\n' "$needs" | grep -vE '^GLIBC_[0-9]+(\.[0-9]+)+$' | grep -v '^$' || true)
    [ -z "$others" ] || unknown_needs="$unknown_needs$file: $(echo "$others" | tr '\n' ' ')"$'\n'

    required=$( { printf '%s\n' "$imports" | sed -n 's/.*@GLIBC_//p'
                  printf '%s\n' "$needs" | sed -n 's/^GLIBC_\([0-9][0-9.]*\)$/\1/p'
                } | grep -v '^$' | sort -uV || true)
    [ -n "$required" ] || continue
    measured=$((measured + 1))

    file_max=$(printf '%s\n' "$required" | tail -1)
    if [ "$(version_max "$file_max" "$highest")" != "$highest" ]; then
        highest="$file_max"; highest_file="$file"
    fi

    if [ "$(version_max "$file_max" "$floor")" != "$floor" ]; then
        violations=$((violations + 1))
        echo
        echo "FAIL ${file#./} requires GLIBC_$file_max (floor is $floor)"
        while IFS= read -r over; do
            [ -n "$over" ] || continue
            [ "$(version_max "$over" "$floor")" != "$floor" ] || continue
            echo "  GLIBC_$over is required by:"
            printf '%s\n' "$imports" | grep -E "@GLIBC_${over//./\\.}\$" \
                | sed 's/@GLIBC_.*//' | sort -u | sed 's/^/    /' || true
        done <<EOF
$required
EOF
    fi
done < "$work_dir/files"

echo
[ "$unreadable" -eq 0 ] || die "$unreadable file(s) were unreadable; cannot certify the floor"
[ "$read_failures" -eq 0 ] || die "readelf failed on $read_failures file(s); cannot certify the floor"
[ "$elf_count" -gt 0 ] || die "no ELF binaries found under: $*"$'\n'"       refusing to report success without inspecting anything"
[ "$measured" -gt 0 ] || die "found $elf_count ELF binaries but read no glibc requirement from any of them;"$'\n'"       readelf output is probably not being parsed as expected"
[ -z "$unknown_needs" ] || die "unrecognised non-numeric glibc requirement(s):"$'\n'"$unknown_needs"

if [ "$violations" -gt 0 ]; then
    echo "glibc floor check FAILED: $violations of $elf_count ELF binaries exceed GLIBC_$floor"
    exit 1
fi

echo "glibc floor check passed: $measured of $elf_count ELF binaries carry glibc requirements,"
echo "  highest is GLIBC_$highest (floor $floor, from $floor_source)"
[ -n "$highest_file" ] && echo "  set by ${highest_file#./}"
exit 0
