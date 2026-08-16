$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
$workRoot = Join-Path $repoRoot 'build-clean-runtime'
$sourceRoot = Join-Path $workRoot 'source'
$gdalSource = Join-Path $sourceRoot 'gdal'
$projSource = Join-Path $sourceRoot 'proj'
$vcpkgRoot = Join-Path $workRoot 'vcpkg'
$vcpkgInstalled = Join-Path $vcpkgRoot 'installed\x64-windows'
$projBuild = Join-Path $workRoot 'proj-build'
$projInstall = Join-Path $workRoot 'proj-install'
$gdalBuild = Join-Path $workRoot 'gdal-build'
$runtimeRoot = Join-Path $workRoot 'runtime'
$outRoot = Join-Path $repoRoot 'out'

function Invoke-External {
    param([Parameter(Mandatory)] [scriptblock] $Command)

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "External command failed with exit code $LASTEXITCODE."
    }
}

function Clone-Release {
    param(
        [Parameter(Mandatory)] [string] $Repository,
        [Parameter(Mandatory)] [string] $Tag,
        [Parameter(Mandatory)] [string] $Destination)

    Invoke-External { git clone --depth 1 --branch $Tag $Repository $Destination }
}

New-Item -ItemType Directory -Force -Path $sourceRoot, $outRoot | Out-Null

# GDAL 3.13.2 is the current stable release. PROJ 9.8.1 is its current
# stable companion. Both are built from their official source repositories.
Clone-Release 'https://github.com/OSGeo/gdal.git' 'v3.13.2' $gdalSource
Clone-Release 'https://github.com/OSGeo/PROJ.git' '9.8.1' $projSource
Clone-Release 'https://github.com/microsoft/vcpkg.git' '2026.03.18' $vcpkgRoot

Invoke-External { & (Join-Path $vcpkgRoot 'bootstrap-vcpkg.bat') '-disableMetrics' }
Invoke-External {
    & (Join-Path $vcpkgRoot 'vcpkg.exe') install 'sqlite3[tool]' 'nlohmann-json' --triplet x64-windows
}

# PROJ's documented source-build requirements are SQLite and nlohmann/json.
# Network and GeoTIFF support are intentionally excluded from this first,
# license-auditable runtime profile.
Invoke-External {
    cmake -S $projSource -B $projBuild -G 'Visual Studio 17 2022' -A x64 `
        "-DCMAKE_INSTALL_PREFIX=$projInstall" `
        "-DCMAKE_PREFIX_PATH=$vcpkgInstalled" `
        "-DEXE_SQLITE3=$(Join-Path $vcpkgInstalled 'tools\sqlite3\sqlite3.exe')" `
        -DBUILD_SHARED_LIBS=ON `
        -DBUILD_APPS=OFF `
        -DBUILD_TESTING=OFF `
        -DENABLE_CURL=OFF `
        -DENABLE_TIFF=OFF `
        -DEMBED_PROJ_DATA_PATH=OFF
}
Invoke-External { cmake --build $projBuild --config Release --parallel }
Invoke-External { cmake --install $projBuild --config Release }

# These are GDAL's documented minimal-driver options. GeoJSON is built in;
# DXF is the one required optional vector driver. GDAL uses its internal
# mandatory libraries and the explicitly supplied PROJ dependency only.
Invoke-External {
    cmake -S $gdalSource -B $gdalBuild -G 'Visual Studio 17 2022' -A x64 `
        "-DCMAKE_INSTALL_PREFIX=$runtimeRoot" `
        "-DCMAKE_PREFIX_PATH=$projInstall" `
        "-DPROJ_DIR=$(Join-Path $projInstall 'lib\cmake\proj')" `
        -DGDAL_BUILD_OPTIONAL_DRIVERS=OFF `
        -DOGR_BUILD_OPTIONAL_DRIVERS=OFF `
        -DOGR_ENABLE_DRIVER_DXF=ON `
        -DGDAL_USE_EXTERNAL_LIBS=OFF `
        -DGDAL_USE_INTERNAL_LIBS=ON `
        -DGDAL_USE_PROJ=ON `
        -DBUILD_CSHARP_BINDINGS=ON `
        -DGDAL_CSHARP_APPS=OFF `
        -DGDAL_CSHARP_TESTS=OFF `
        -DGDAL_CSHARP_BUILD_NUPKG=OFF
}
Invoke-External { cmake --build $gdalBuild --config Release --parallel }
Invoke-External { cmake --install $gdalBuild --config Release }

Copy-Item -Force (Join-Path $projInstall 'bin\*.dll') (Join-Path $runtimeRoot 'bin')
Copy-Item -Recurse -Force (Join-Path $projInstall 'share\proj') (Join-Path $runtimeRoot 'share\proj')
Copy-Item -Force (Join-Path $gdalSource 'LICENSE.TXT') (Join-Path $runtimeRoot 'LICENSE-GDAL.txt')
Copy-Item -Force (Join-Path $projSource 'COPYING') (Join-Path $runtimeRoot 'LICENSE-PROJ.txt')
Copy-Item -Force (Join-Path $vcpkgInstalled 'share\sqlite3\copyright') (Join-Path $runtimeRoot 'LICENSE-SQLITE3.txt')
Copy-Item -Force (Join-Path $vcpkgInstalled 'share\nlohmann-json\copyright') (Join-Path $runtimeRoot 'LICENSE-NLOHMANN-JSON.txt')

$ogrInfo = Join-Path $runtimeRoot 'bin\ogrinfo.exe'
$runtimePath = (Join-Path $runtimeRoot 'bin') + ';' + $env:PATH
$formats = & { $env:PATH = $runtimePath; & $ogrInfo --formats }
if ($LASTEXITCODE -ne 0) {
    throw "ogrinfo --formats failed with exit code $LASTEXITCODE."
}
if ($formats -notmatch 'GeoJSON') {
    throw 'GeoJSON driver is not available in the runtime.'
}
if ($formats -notmatch 'DXF') {
    throw 'DXF driver is not available in the runtime.'
}

$forbidden = 'poppler|mysql|geos|pdfium|openjpeg|hdf|netcdf|arrow|spatialite'
$forbiddenFiles = Get-ChildItem -Path $runtimeRoot -Recurse -File | Where-Object { $_.Name -match $forbidden }
if ($forbiddenFiles) {
    throw "The clean runtime contains excluded dependencies: $($forbiddenFiles.Name -join ', ')"
}

$zipPath = Join-Path $outRoot 'gdal-windows-x64-clean-runtime.zip'
Remove-Item -Force $zipPath -ErrorAction SilentlyContinue
Compress-Archive -Path (Join-Path $runtimeRoot '*') -DestinationPath $zipPath
