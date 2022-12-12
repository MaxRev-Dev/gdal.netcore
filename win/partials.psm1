function Set-GdalVariables {
    $env:GDAL_REPO = "https://github.com/OSGeo/gdal.git"
    $env:GDAL_COMMIT_VER = "release/3.6"

    $env:PROJ_REPO = "https://github.com/OSGeo/PROJ.git"
    $env:PROJ_COMMIT_VER = "7.2"

    $env:VS_VERSION = "Visual Studio 17 2022"
    $env:SDK = "release-1930-x64" #2022 x64
    $env:SDK_ZIP = "$env:SDK" + "-dev.zip"
    $env:PROJ_DATUM = "proj-datumgrid-1.8.zip"
    $env:PROJ_DATUM_URL = "http://download.osgeo.org/proj/$env:PROJ_DATUM"
    $env:SDK_URL = "http://download.gisinternals.com/sdk/downloads/$env:SDK_ZIP"
    $env:LIBWEBP_URL = "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.0.3-windows-x86.zip"
    $env:LIBZSTD_URL = "https://github.com/facebook/zstd/releases/download/v1.4.5/zstd-v1.4.5-win32.zip"
    $env:LIBDEFLATE_URL = "https://github.com/ebiggers/libdeflate/releases/download/v1.6/libdeflate-1.6-windows-i686-bin.zip"
    $env:VS_VER = "2022"
    $env:ARCHITECTURE = "amd64"
    $env:WIN64_ARG = "WIN64=YES"
    $env:platform = "x64"
    $env:CMAKE_ARCHITECTURE = "x64"
    $env:CMAKE_PARALLEL_JOBS = 4

    $env:PROJ_INSTALL_DIR = (Get-ForceResolvePath "$env:BUILD_ROOT\proj-build") 
    $env:DOWNLOADS_DIR = (Get-ForceResolvePath "$env:BUILD_ROOT\downloads") 
    $env:SDK_PREFIX = "$env:BUILD_ROOT\sdk\$env:SDK"
}

function Get-7ZipInstallation {   
    Write-BuildStep "Checking for 7z installation"
    New-FolderIfNotExists $env:7Z_ROOT 
    $env:7Z_URL = "https://www.7-zip.org/a/7z2107-extra.7z"
    if (-Not (Test-Path -Path "$env:7Z_ROOT\7za.exe" -PathType Leaf)) { 
        Invoke-WebRequest "$env:7Z_URL" -OutFile "$env:7Z_ROOT\7z.7z"
        Install-Module -Name PS7Zip -AllowClobber -RequiredVersion 2.2.0
        Import-Module PS7Zip
        Expand-7Zip -FullName "$env:7Z_ROOT\7z.7z" -DestinationPath "$env:7Z_ROOT\"
        Write-BuildStep "Installed 7z into $env:7Z_ROOT"
    }
    else {
        Write-BuildStep "7z is available at $env:7Z_ROOT"
    }
}

function Get-GdalSdkIsAvailable {
    New-FolderIfNotExistsAndSetCurrentLocation $env:DOWNLOADS_DIR
    Write-BuildStep "Checking for GDAL SDK from GisInternals"
    if (-Not (Test-Path -Path $env:SDK_ZIP )) { 
        Write-BuildInfo "Downloading GDAL SDK from GisInternals"
        Invoke-WebRequest "$env:SDK_URL" -OutFile "$env:SDK_ZIP" 
        Write-BuildStep "GDAL SDK was downloaded"
    }
    New-FolderIfNotExistsAndSetCurrentLocation "$env:BUILD_ROOT\sdk" 
    exec { 7za x "$env:DOWNLOADS_DIR\$env:SDK_ZIP" -aoa }
}

function Resolve-GdalThidpartyLibs {
    New-FolderIfNotExistsAndSetCurrentLocation $env:DOWNLOADS_DIR
    Write-BuildStep "Checking for ZSTD, Webp, Deflate libraries"
    $env:LIBZSTD_ZIP = "libzstd.zip"
    if (-Not (Test-Path -Path $env:LIBZSTD_ZIP -PathType Leaf)) { 
        Invoke-WebRequest "$env:LIBZSTD_URL" -OutFile "$env:LIBZSTD_ZIP" 
    }
    $env:LIBWEBP_ZIP = "libwebp.zip"
    if (-Not (Test-Path -Path $env:LIBWEBP_ZIP -PathType Leaf)) { 
        Invoke-WebRequest "$env:LIBWEBP_URL" -OutFile "$env:LIBWEBP_ZIP" 
    }
    $env:LIBDEFLATE_ZIP = "libdeflate.zip"
    if (-Not (Test-Path -Path $env:LIBDEFLATE_ZIP -PathType Leaf)) { 
        Invoke-WebRequest "$env:LIBDEFLATE_URL" -OutFile "$env:LIBDEFLATE_ZIP" 
    }
    
    New-FolderIfNotExistsAndSetCurrentLocation "$env:BUILD_ROOT\sdk"
    exec { 7za x "$env:DOWNLOADS_DIR\$env:LIBWEBP_ZIP" -aoa }
    exec { 7za x "$env:DOWNLOADS_DIR\$env:LIBDEFLATE_ZIP" -aoa }
    exec { 7za x "$env:DOWNLOADS_DIR\$env:LIBZSTD_ZIP" -aoa }
}
function Get-VcpkgInstallation {
    param (
        [bool] $bootstrapVcpkg = $true
    )

    Write-BuildStep "Checking for VCPKG installation"    
    if ($bootstrapVcpkg) {
        Get-CloneAndCheckoutCleanGitRepo https://github.com/Microsoft/vcpkg.git master $env:VCPKG_ROOT
    }
    if (-Not (Test-Path -Path "$env:VCPKG_ROOT/vcpkg.exe" -PathType Leaf)) { 
        Write-BuildInfo "Installing VCPKG" 
        exec { & "$env:VCPKG_ROOT\bootstrap-vcpkg.bat" }
    }
    else {
        Write-BuildInfo "VCPKG is already installed"
    }    
}

function Install-VcpkgPackagesSharedConfig {
    param (
        [bool] $installVcpkgPackages = $true
    )
    
    if ($installVcpkgPackages) {
        exec { & nmake -f ./vcpkg-makefile.vc install_requirements }
    }
}

function Install-Proj {
    param (
        [bool] $cleanProjBuild = $true,
        [bool] $cleanProjIntermediate = $true
    )
    Write-BuildStep "Building PROJ"
    if ($cleanProjBuild) {
        Write-BuildInfo "Cleaning PROJ build folder"
        if (Test-Path -Path "$env:BUILD_ROOT\proj-build" -PathType Container) {
            Remove-Item -Path "$env:BUILD_ROOT\proj-build" -Recurse -Force
        }
    }    
    $env:PROJ_SOURCE = "$env:BUILD_ROOT\proj-source"
    Write-BuildInfo "Checking out PROJ repo..."

    nmake -f fetch-makefile.vc fetch-proj
    #Get-CloneAndCheckoutCleanGitRepo $env:PROJ_REPO $env:PROJ_COMMIT_VER $env:PROJ_SOURCE
 
    $env:ProjCmakeBuild = "$env:BUILD_ROOT\proj-cmake-temp"
    if ($cleanProjIntermediate) {
        Write-BuildInfo "Cleaning GDAL intermediate folder"
        Remove-Item -Path $env:ProjCmakeBuild -Recurse -Force
    }
    if ((Test-Path -Path "$env:ProjCmakeBuild\CMakeCache.txt" -PathType Leaf)) {
        Write-BuildInfo "Removing build cache (CMakeCache.txt)"
        Remove-Item "$env:ProjCmakeBuild\CMakeCache.txt"
    }
 
    Write-BuildInfo "Configuring PROJ..."
    New-FolderIfNotExistsAndSetCurrentLocation $env:ProjCmakeBuild

    cmake -G $env:VS_VERSION -A $env:CMAKE_ARCHITECTURE $env:PROJ_SOURCE `
        -DCMAKE_INSTALL_PREFIX=$env:PROJ_INSTALL_DIR `
        -DCMAKE_BUILD_TYPE=Release -Wno-dev `
        -DPROJ_TESTS=OFF -DBUILD_LIBPROJ_SHARED=ON `
        -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake" `
        -DBUILD_SHARED_LIBS=ON -DENABLE_CURL=ON -DENABLE_TIFF=ON

    exec { cmake --build . -j $env:CMAKE_PARALLEL_JOBS --config Release --target install }
    Write-BuildStep "Done building PROJ"
}

function Get-ProjDatum {   
    Write-BuildStep "Checking for PROJ datum grid"
    Set-Location "$env:BUILD_ROOT\proj-build\share\proj"
    if (-Not (Test-Path -Path $env:PROJ_DATUM -PathType Leaf)) { 
        Write-BuildInfo "Downloading PROJ datum grid"
        Invoke-WebRequest $env:PROJ_DATUM_URL -OutFile $env:PROJ_DATUM
        Write-BuildStep "PROJ datum grid was downloaded"
    }
    else {
        Write-BuildStep "PROJ datum grid already exists"
    }
}

function Build-Gdal {
    param (
        [bool] $cleanGdalBuild = $true,
        [bool] $cleanGdalIntermediate = $true
    )

    $env:SDK_LIB = "$env:SDK_PREFIX\lib"
    $env:SDK_BIN = "$env:SDK_PREFIX\bin"
    $env:PATH = "$env:BUILD_ROOT\proj-build\bin;$env:SDK_BIN;$env:PATH"
    $env:GDAL_INSTALL_DIR = "$env:BUILD_ROOT\gdal-build"
    $env:CMAKE_INSTALL_PREFIX = "-DCMAKE_INSTALL_PREFIX=$env:GDAL_INSTALL_DIR"
    $env:PROJ_ROOT = "-DPROJ_ROOT=$env:PROJ_INSTALL_DIR"
    $env:CMAKE_PREFIX_PATH = "-DCMAKE_PREFIX_PATH=$env:SDK_PREFIX"
    $env:MYSQL_LIBRARY = "-DMYSQL_LIBRARY=$env:SDK_LIB\libmysql.lib"
    $env:POPPLER_EXTRA_LIBRARIES = "-DPOPPLER_EXTRA_LIBRARIES=$env:SDK_LIB\freetype.lib;$env:SDK_LIB\harfbuzz.lib"
    $env:GDAL_SOURCE = "$env:BUILD_ROOT\gdal-source"
    $env:GdalCmakeBuild = "$env:BUILD_ROOT\gdal-cmake-temp"

    Write-BuildStep "Configuring GDAL"
    Set-Location "$env:BUILD_ROOT"

    if ($cleanGdalBuild) {
        Write-BuildInfo "Cleaning GDAL build folder"
        if (Test-Path -Path "$env:BUILD_ROOT\gdal-build" -PathType Container) {
            Remove-Item -Path "$env:BUILD_ROOT\gdal-build" -Recurse -Force
        } 
    }
    if ($cleanGdalIntermediate) {
        Write-BuildInfo "Cleaning GDAL intermediate folder"
        Remove-Item -Path $env:GdalCmakeBuild -Recurse -Force
    }
    
    nmake -f fetch-makefile.vc fetch-gdal
    #Get-CloneAndCheckoutCleanGitRepo $env:GDAL_REPO $env:GDAL_COMMIT_VER "$env:GDAL_SOURCE"

    if ((Test-Path -Path "$env:GdalCmakeBuild\CMakeCache.txt" -PathType Leaf)) {
        Write-BuildInfo "Removing build cache (CMakeCache.txt)"
        Remove-Item "$env:GdalCmakeBuild\CMakeCache.txt"
    }
 
    # PATCH 1: replace build root of SDK with our own
    Set-ReplaceContentInFiles -Path $env:SDK_PREFIX `
        -FileFilter "*.pc", "*.cmake", "*.opt" `
        -What "E:/buildsystem/$env:SDK", "E:\buildsystem\$env:SDK" `
        -With $env:SDK_PREFIX.Replace("\", "/")  

    Set-Location "$env:GDAL_SOURCE"

    Remove-Item -Path $env:GDAL_SOURCE/autotest -Recurse -Force
    # PATCH 2: apply patch to cmake pipeline. remove redundant compile steps
    git apply "$PSScriptRoot\..\shared\patch\CMakeLists.txt.patch"

    New-FolderIfNotExistsAndSetCurrentLocation $env:GdalCmakeBuild  

    cmake -G $env:VS_VERSION -A $env:CMAKE_ARCHITECTURE "$env:GDAL_SOURCE" `
        $env:CMAKE_INSTALL_PREFIX -DCMAKE_BUILD_TYPE=Release -Wno-dev `
        $env:CMAKE_PREFIX_PATH -DCMAKE_C_FLAGS=" /WX $env:ARCH_FLAGS" `
        -DCMAKE_CXX_FLAGS=" /WX $env:ARCH_FLAGS" -DGDAL_USE_DEFLATE=OFF `
        $env:PROJ_ROOT $env:MYSQL_LIBRARY $env:POPPLER_EXTRA_LIBRARIES `
        -DGDAL_USE_ZLIB_INTERNAL=ON -DECW_INTERFACE_COMPILE_DEFINITIONS="_MBCS;_UNICODE;UNICODE;_WINDOWS;LIBECWJ2;WIN32;_WINDLL;NO_X86_MMI" `
        -DBUILD_APPS=OFF -DBUILD_CSHARP_BINDINGS=ON -DBUILD_JAVA_BINDINGS=OFF

    Write-BuildStep "Building GDAL"
    exec { cmake --build . -j $env:CMAKE_PARALLEL_JOBS --config Release --target install }
    Write-BuildStep "GDAL was built successfully"
}

function Build-CsharpBindings {   
    param (
        [bool] $isDebug = $false
    )
    Write-BuildStep "Building GDAL C# bindings"
    
    Set-Location $PSScriptRoot
    
    nmake -f "$PSScriptRoot\collect-deps-makefile.vc"
    
    if ($isDebug) {
        nmake -f "$PSScriptRoot\publish-makefile.vc" pack-dev DEBUG=1
    }
    else {
        nmake -f "$PSScriptRoot\publish-makefile.vc" pack
    }
}