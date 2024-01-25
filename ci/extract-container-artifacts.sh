# GDAL.NETCORE Builder - Extract container artifacts
# Usage: ./extract-container-artifacts.sh 

outputDir="$(dirname "$0")/.."
arch=$1
containerName=$(docker create ghcr.io/maxrev-dev/gdal.netcore.builder.$arch:latest)
echo "Extracting artifacts from container $containerName to $outputDir" 
# extract nuget packages
docker cp $containerName:/build/nuget "$outputDir/"

rm -rf $outputDir/ci/cache/
# extract build cache (gdal, proj, vcpkg and others)
mkdir -p "$outputDir/ci/cache/build-unix"
docker cp $containerName:/build/build-unix/gdal-source "$outputDir/ci/cache/build-unix"
docker cp $containerName:/build/build-unix/proj-source "$outputDir/ci/cache/build-unix"
mkdir -p "$outputDir/ci/cache/build-unix/vcpkg"
docker cp $containerName:/build/build-unix/vcpkg/.git "$outputDir/ci/cache/build-unix/vcpkg"

# extract dotnet sdk
rm -rf "$outputDir/ci/cache/dotnet"
mkdir -p "$outputDir/ci/cache/dotnet"
docker cp $containerName:/usr/share/dotnet  "$outputDir/ci/cache/"

# extract vcpkg cache
docker cp $containerName:/build/ci/cache/vcpkg-archives "$outputDir/ci/cache/"

# extract metadata
mkdir -p "$outputDir/shared/bundle"
docker cp $containerName:/build/shared/bundle/targets "$outputDir/shared/bundle/"

mkdir -p "$outputDir/package-build"
docker cp $containerName:/build/package-build/ "$outputDir/"

docker rm -f $containerName