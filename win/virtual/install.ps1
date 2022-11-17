# reset previous imports
Remove-Module *
# using predefined set of helper functions
Import-Module ./functions.psm1 -Force
# reset session
Reset-PsSession

#Install-ModuleRequirements

if (-Not (Test-Path -Path ".\vcpkg" -PathType Container)) { 
    exec { git clone https://github.com/Microsoft/vcpkg.git vcpkg }
    exec { & .\vcpkg\bootstrap-vcpkg.bat }
}

$env:VCPKG_ROOT = (Resolve-Path ".\vcpkg")
Add-EnvPath $env:VCPKG_ROOT 
$env:CMAKE_ROOT = (Resolve-Path ".\vcpkg\downloads\tools\cmake-*\cmake-*\bin") 
Add-EnvPath $env:CMAKE_ROOT
$env:7Z_ROOT = (Resolve-Path ".\vcpkg\downloads\tools\7zip*\") 
Add-EnvPath $env:7Z_ROOT

# $VerbosePreference = Continue
$env:VS_VERSION = "Visual Studio 17 2022"
$env:SDK = "release-1928-x64" #2019 x64
$env:SDK_ZIP = "$env:SDK" + "-dev.zip"
$env:SDK_URL = "http://download.gisinternals.com/sdk/downloads/$env:SDK_ZIP"
$env:LIBWEBP_URL = "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.0.3-windows-x86.zip"
$env:LIBZSTD_URL = "https://github.com/facebook/zstd/releases/download/v1.4.5/zstd-v1.4.5-win32.zip"
$env:LIBDEFLATE_URL = "https://github.com/ebiggers/libdeflate/releases/download/v1.6/libdeflate-1.6-windows-i686-bin.zip"
$env:VS_VER = "2022"
$env:PROJ_BRANCH = "7.2"
$env:ARCHITECTURE = "amd64"
$env:WIN64_ARG = "WIN64=YES"
$env:platform = "x64"
$env:CMAKE_ARCHITECTURE = $env:platform 

Push-Location -StackName "gdal.netcore|root"
Import-VisualStudioVars -VisualStudioVersion $env:VS_VER -Architecture $env:ARCHITECTURE

# # Install SWIG by Choco
# exec { cinst -y --no-progress --force swig }

# Assert-DetectIfAVX2 

New-FolderIfNotExists downloads
Set-Location downloads

if (-Not (Test-Path -Path $env:SDK_ZIP )) { 
    Invoke-WebRequest "$env:SDK_URL" -OutFile "$env:SDK_ZIP" 
}

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

New-FolderIfNotExists sdk
# exec { Expand-7Zip -ArchiveFileName "../downloads/$env:SDK_ZIP" -TargetPath "sdk" }
Set-Location sdk
## exec { Expand-7Zip  -Path  ..\..\downloads\$env:LIBZSTD_ZIP -OutputPath "."}
# exec { Expand-7Zip  -ArchiveFileName "..\..\downloads\$env:LIBWEBP_ZIP" -TargetPath "." }
# exec { Expand-7Zip  -ArchiveFileName "..\..\downloads\$env:LIBDEFLATE_ZIP" -TargetPath "." }

Set-Location "$PSScriptRoot\build-proj\share\proj"
#Invoke-WebRequest "http://download.osgeo.org/proj/proj-datumgrid-1.8.zip" -OutFile "proj-datumgrid-1.8.zip"
exec { 7za x proj-datumgrid-1.8.zip -aoa }

Pop-Location -StackName "gdal.netcore|root"


Get-CloneAndCheckoutCleanGitRepo https://github.com/OSGeo/PROJ $env:PROJ_BRANCH proj 

Push-Location -StackName "gdal.netcore|root"

Set-Location proj

New-FolderIfNotExtists "build"
Set-Location build

$env:VCPKG_PLATFORM = "$env:platform" + "-windows"
exec { vcpkg install sqlite3[tool]:$env:VCPKG_PLATFORM }

$env:PROJ_INSTALL_DIR = "$PSScriptRoot" + "\build-proj"
$env:CMAKE_INSTALL_PREFIX = "-DCMAKE_INSTALL_PREFIX=" + $env:PROJ_INSTALL_DIR

cmake -G $env:VS_VERSION -A $env:CMAKE_ARCHITECTURE .. $env:CMAKE_INSTALL_PREFIX -DPROJ_TESTS=OFF -DCMAKE_BUILD_TYPE=Release -DBUILD_LIBPROJ_SHARED=ON -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" -DBUILD_SHARED_LIBS=ON -DENABLE_CURL=OFF -DENABLE_TIFF=OFF -DBUILD_PROJSYNC=OFF
exec { cmake --build . --config Release --target install }

Pop-Location -StackName "gdal.netcore|root"
