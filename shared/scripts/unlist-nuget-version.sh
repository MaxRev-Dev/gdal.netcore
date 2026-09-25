#!/usr/bin/env bash
# Unlist every MaxRev.Gdal.* package published at a given version on nuget.org.
#
# nuget.org never deletes packages: `dotnet nuget delete` unlists them, so they
# disappear from search and floating-version restores, but existing lock files
# that pin the exact version keep restoring.
#
# Usage:
#   NUGET_API_KEY=... shared/scripts/unlist-nuget-version.sh 3.13.3.573          # dry run
#   NUGET_API_KEY=... shared/scripts/unlist-nuget-version.sh 3.13.3.573 --yes    # unlist
#   shared/scripts/unlist-nuget-version.sh 3.13.3.573 --yes MaxRev.Gdal.Core    # only these IDs
#
# Without explicit package IDs, the script searches nuget.org for MaxRev.Gdal.*
# packages and keeps the ones that actually have the requested version.

set -euo pipefail

SOURCE="https://api.nuget.org/v3/index.json"
SEARCH="https://azuresearch-usnc.nuget.org/query"
FLAT="https://api.nuget.org/v3-flatcontainer"

usage() {
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit "${1:-1}"
}

version=""
apply=0
ids=()
for arg in "$@"; do
    case "$arg" in
        -h|--help) usage 0 ;;
        -y|--yes) apply=1 ;;
        -*) echo "unknown option: $arg" >&2; usage ;;
        *) if [[ -z "$version" ]]; then version="$arg"; else ids+=("$arg"); fi ;;
    esac
done

[[ -n "$version" ]] || usage
[[ "$version" =~ ^[0-9]+(\.[0-9]+){2,3}(-[0-9A-Za-z.-]+)?$ ]] || { echo "not a version: $version" >&2; exit 1; }
for tool in curl jq dotnet; do
    command -v "$tool" >/dev/null || { echo "missing required tool: $tool" >&2; exit 1; }
done

if [[ ${#ids[@]} -eq 0 ]]; then
    while IFS= read -r id; do ids+=("$id"); done < <(
        curl -fsS "$SEARCH?q=MaxRev.Gdal&prerelease=true&semVerLevel=2.0.0&take=1000" |
            jq -r '.data[].id | select(startswith("MaxRev.Gdal."))' | sort -u)
    [[ ${#ids[@]} -gt 0 ]] || { echo "no MaxRev.Gdal.* packages found on nuget.org" >&2; exit 1; }
fi

# Keep only IDs that have this exact version (the flat container lists unlisted versions too).
targets=()
for id in "${ids[@]}"; do
    lower=$(tr '[:upper:]' '[:lower:]' <<<"$id")
    if curl -fsS "$FLAT/$lower/index.json" 2>/dev/null | jq -e --arg v "$version" '.versions | index($v)' >/dev/null; then
        targets+=("$id")
    fi
done

if [[ ${#targets[@]} -eq 0 ]]; then
    echo "no packages found at version $version"
    exit 0
fi

echo "packages at $version:"
printf '  %s\n' "${targets[@]}"

if [[ $apply -eq 0 ]]; then
    echo "dry run: re-run with --yes to unlist them"
    exit 0
fi

[[ -n "${NUGET_API_KEY:-}" ]] || { echo "NUGET_API_KEY is not set" >&2; exit 1; }

failed=0
for id in "${targets[@]}"; do
    if dotnet nuget delete "$id" "$version" -s "$SOURCE" -k "$NUGET_API_KEY" --non-interactive; then
        echo "unlisted $id $version"
    else
        echo "FAILED to unlist $id $version" >&2
        failed=1
    fi
done
exit $failed
