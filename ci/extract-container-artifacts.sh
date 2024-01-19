# GDAL.NETCORE Builder - Extract container artifacts
# Usage: ./extract-container-artifacts.sh 

outputDir="$(dirname "$0")/.."
containerName=$(docker create ghcr.io/maxrev-dev/gdal.netcore.builder.arm64:latest)
echo "Extracting artifacts from container $containerName to $outputDir" 
# extract nuget packages
docker cp $containerName:/build/nuget "$outputDir/"

rm -rf $outputDir/ci/cache
# extract build cache (gdal, proj, vcpkg and others)
mkdir -p "$outputDir/ci/cache/build-unix"
docker cp $containerName:/build/build-unix/gdal-source "$outputDir/ci/cache/build-unix"
docker cp $containerName:/build/build-unix/proj-source "$outputDir/ci/cache/build-unix"
mkdir -p "$outputDir/ci/cache/build-unix/vcpkg"
docker cp $containerName:/build/build-unix/vcpkg/.git "$outputDir/ci/cache/build-unix/vcpkg/.git"

# extract dotnet sdk
rm -rf "$outputDir/ci/cache/dotnet"
mkdir -p "$outputDir/ci/cache/dotnet"
docker cp $containerName:/usr/share/dotnet  "$outputDir/ci/cache/"

# extract vcpkg cache
mkdir -p "$outputDir/ci/cache/vcpkg/archives"
docker cp $containerName:/root/.cache/vcpkg/archives "$outputDir/ci/cache/vcpkg/"
docker rm -f $containerName