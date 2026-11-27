#!/usr/bin/env bash
# Intentional removal: update and commit the corresponding tests/gdal-formats/
# baseline in the same PR, then rebuild. HEAD is used because Windows generation
# overwrites the baseline's working-tree path. For a temporary deliberate bypass,
# set GDAL_ALLOW_DRIVER_LOSS=1 in the build environment; losses print warnings.
# Missing/empty/unparseable lists and missing baselines still fail.
set -euo pipefail
if [[ $# != 3 ]]; then
    echo "Usage: $0 <unix|osx|win> <x64|arm64> <generated-directory>" >&2
    exit 2
fi
platform=$1
arch=$2
actual=$3
case "$platform:$arch" in
    unix:x64|unix:arm64|osx:x64|osx:arm64) baseline="formats-$platform-$arch" ;;
    win:x64) baseline=formats-win ;;
    *) echo "Unsupported platform/architecture: $platform:$arch" >&2; exit 2 ;;
esac
root=$(cd "$(dirname "$0")/../.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
failed=0
for kind in config raster vector; do
    suffix="-$kind"
    [[ $kind != config ]] || suffix=""
    name="gdal-formats-$platform$suffix.txt"
    git -C "$root" show "HEAD:tests/gdal-formats/$baseline/$name" > "$scratch/baseline"
    [[ -s "$actual/$name" ]] || { echo "Missing or empty generated list: $actual/$name" >&2; exit 1; }
    for source in baseline actual; do
        input="$scratch/baseline"
        [[ $source != actual ]] || input="$actual/$name"
        if [[ $kind == config ]]; then
            awk '{ for (i=1; i<=NF; i++) { sub(/\r$/, "", $i); print $i } }' "$input"
        else
            awk '/^[[:space:]]+[^[:space:]]+[[:space:]]+-(raster|vector)/ { print $1 }' "$input"
        fi | LC_ALL=C sort -u > "$scratch/$source.names"
        [[ -s "$scratch/$source.names" ]] || { echo "No drivers parsed from $input" >&2; exit 1; }
    done
    LC_ALL=C comm -23 "$scratch/baseline.names" "$scratch/actual.names" > "$scratch/missing"
    LC_ALL=C comm -13 "$scratch/baseline.names" "$scratch/actual.names" > "$scratch/new"
    if [[ -s "$scratch/missing" ]]; then
        echo "Drivers missing from $name ($baseline):" >&2
        cat "$scratch/missing" >&2
        if [[ ${GDAL_ALLOW_DRIVER_LOSS:-0} == 1 ]]; then
            echo "WARNING: GDAL_ALLOW_DRIVER_LOSS=1 bypasses driver regression failure for $name" >&2
        else
            failed=1
        fi
    fi
    if [[ -s "$scratch/new" ]]; then
        echo "NOTICE: new drivers in $name ($baseline):"
        cat "$scratch/new"
    fi
done
exit "$failed"
