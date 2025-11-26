# GDAL.NETCORE Builder - Extract container artifacts
# Usage: ./extract-container-artifacts.sh <arch> [container-name] [--nuget] [--cache] [--dotnet] [--vcpkg] [--metadata] [--formats] [--package-build] [--all]

outputDir="$(dirname "$0")/.."
arch=$1
shift

# Parse arguments
containerName=""
extract_nuget=false
extract_cache=false
extract_dotnet=false
extract_vcpkg=false
extract_metadata=false
extract_formats=false
extract_package_build=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --nuget)
            extract_nuget=true
            shift
            ;;
        --cache)
            extract_cache=true
            shift
            ;;
        --dotnet)
            extract_dotnet=true
            shift
            ;;
        --vcpkg)
            extract_vcpkg=true
            shift
            ;;
        --metadata)
            extract_metadata=true
            shift
            ;;
        --formats)
            extract_formats=true
            shift
            ;;
        --package-build)
            extract_package_build=true
            shift
            ;;
        --all)
            extract_nuget=true
            extract_cache=true
            extract_dotnet=true
            extract_vcpkg=true
            extract_metadata=true
            extract_formats=true
            extract_package_build=true
            shift
            ;;
        *)
            if [[ -z "$containerName" ]]; then
                containerName=$1
            fi
            shift
            ;;
    esac
done

# If no container name provided, create one
if [[ -z "$containerName" ]]; then
    containerName=$(docker create ghcr.io/maxrev-dev/gdal.netcore.builder.$arch:latest)
fi

# If no extraction options specified, extract all
if ! $extract_nuget && ! $extract_cache && ! $extract_dotnet && ! $extract_vcpkg && ! $extract_metadata && ! $extract_formats && ! $extract_package_build; then
    extract_nuget=true
    extract_cache=true
    extract_dotnet=true
    extract_vcpkg=true
    extract_metadata=true
    extract_formats=true
    extract_package_build=true
fi

echo "Extracting artifacts from container $containerName to $outputDir"

# extract nuget packages
if $extract_nuget; then
    echo "Extracting nuget packages..."
    docker cp $containerName:/build/nuget "$outputDir/"
fi

# extract build cache (gdal, proj, vcpkg and others)
if $extract_cache; then
    echo "Extracting build cache..."
    rm -rf $outputDir/ci/cache/
    mkdir -p "$outputDir/ci/cache/build-unix"
    docker cp $containerName:/build/build-unix/gdal-source "$outputDir/ci/cache/build-unix"
    docker cp $containerName:/build/build-unix/proj-source "$outputDir/ci/cache/build-unix"
    mkdir -p "$outputDir/ci/cache/build-unix/vcpkg"
    docker cp $containerName:/build/build-unix/vcpkg/.git "$outputDir/ci/cache/build-unix/vcpkg"
fi

# extract dotnet sdk
if $extract_dotnet; then
    echo "Extracting dotnet SDK..."
    rm -rf "$outputDir/ci/cache/dotnet"
    mkdir -p "$outputDir/ci/cache/dotnet"
    docker cp $containerName:/usr/share/dotnet  "$outputDir/ci/cache/"
fi

# extract vcpkg cache
if $extract_vcpkg; then
    echo "Extracting vcpkg cache..."
    docker cp $containerName:/build/ci/cache/vcpkg-archives "$outputDir/ci/cache/"
fi

# extract metadata
if $extract_metadata; then
    echo "Extracting metadata..."
    mkdir -p "$outputDir/shared/bundle"
    docker cp $containerName:/build/shared/bundle/targets "$outputDir/shared/bundle/"
fi

# extract gdal formats
if $extract_formats; then
    echo "Extracting gdal formats..."
    mkdir -p "$outputDir/tests/gdal-formats"
    docker cp $containerName:/build/tests/gdal-formats/ "$outputDir/tests/"
fi

# extract package build
if $extract_package_build; then
    echo "Extracting package build..."
    mkdir -p "$outputDir/package-build"
    docker cp $containerName:/build/package-build/ "$outputDir/"
fi

docker rm -f $containerName