# GDAL.NETCORE Builder - Extract container artifacts
# Usage: ./extract-container-artifacts.sh 

outputDir="$(dirname "$0")/.."
containerName=$(docker create maxrev-dev/gdal.netcore.builder:latest)
echo "Extracting artifacts from container $containerName to $outputDir" 
# extract nuget packages
docker cp $containerName:/build/nuget "$outputDir/nuget"

# extract build cache (gdal, proj, vcpkg and others)
mkdir -p "$outputDir/ci/cache/build-unix"
docker cp $containerName:/build/build-unix "$outputDir/ci/cache/build-unix"

# extract dotnet sdk
rm -rf "$outputDir/ci/cache/dotnet"
mkdir -p "$outputDir/ci/cache/dotnet"
docker cp $containerName:/usr/share/dotnet  "$outputDir/ci/cache/dotnet"

# extract vcpkg cache
mkdir -p "$outputDir/ci/cache/vcpkg/archives"
docker cp $containerName:/root/.cache/vcpkg/archives "$outputDir/ci/cache/vcpkg/archives"
docker rm -f $containerName