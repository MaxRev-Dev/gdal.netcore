function Set-GdalVariables {
    $env:VS_VERSION = "Visual Studio 17 2022"
    $env:SDK = "release-1930-x64" #2022 x64
    $env:SDK_ZIP = "$env:SDK" + "-dev.zip"
    $env:SDK_URL = "http://download.gisinternals.com/sdk/downloads/$env:SDK_ZIP"
    $env:LIBWEBP_URL = "https://storage.googleapis.com/downloads.webmproject.org/releases/webp/libwebp-1.3.2-windows-x64.zip"
    $env:LIBZSTD_URL = "https://github.com/facebook/zstd/releases/download/v1.5.5/zstd-v1.5.5-win64.zip"
    $env:LIBDEFLATE_URL = "https://github.com/ebiggers/libdeflate/releases/download/v1.19/libdeflate-1.19-windows-x86_64-bin.zip"
    $env:VS_VER = "2022"
    $env:ARCHITECTURE = "amd64"
    $env:WIN64_ARG = "WIN64=YES"
    $env:CMAKE_ARCHITECTURE = "x64"
    $env:CMAKE_PARALLEL_JOBS = 4

    $env:GitBash = "C:\Program Files\Git\bin\bash.exe"
    $env:BUILD_ROOT = (Get-ForceResolvePath "$PSScriptRoot\..\build-win")
    $env:PROJ_INSTALL_DIR = (Get-ForceResolvePath "$env:BUILD_ROOT\proj-build") 
    $env:DOWNLOADS_DIR = (Get-ForceResolvePath "$env:BUILD_ROOT\downloads") 
    $env:SDK_PREFIX = "$env:BUILD_ROOT\sdk\$env:SDK"
    $env:GDAL_SOURCE = "$env:BUILD_ROOT\gdal-source"
    $env:PROJ_SOURCE = "$env:BUILD_ROOT\proj-source"
    $env:GDAL_DATA = "$env:GDAL_INSTALL_DIR\share\gdal"
    $env:GDAL_DRIVER_PATH = "$env:GDAL_INSTALL_DIR\share\gdal"
    $env:PROJ_LIB = "$env:PROJ_INSTALL_DIR\share\proj"
    $env:GdalCmakeBuild = "$env:BUILD_ROOT\gdal-cmake-temp"
    $env:SDK_LIB = "$env:SDK_PREFIX\lib"
    $env:SDK_BIN = "$env:SDK_PREFIX\bin"
    $env:GDAL_INSTALL_DIR = "$env:BUILD_ROOT\gdal-build"
    $env:VCPKG_INSTALLED = "$env:BUILD_ROOT\vcpkg\installed\x64-windows"
    $env:VCPKG_INSTALLED_PKGCONFIG = "$env:VCPKG_INSTALLED\lib\pkgconfig"   
    
    $env:WEBP_ROOT = Get-ForceResolvePath("$env:BUILD_ROOT\sdk\libwebp*")
    $env:BUILD_ROOT = (Get-ForceResolvePath "$PSScriptRoot\..\build-win")
    $env:7Z_ROOT = (Get-ForceResolvePath "$env:BUILD_ROOT\7z")
    Add-EnvPath $env:7Z_ROOT
    $env:VCPKG_ROOT_GDAL = (Get-ForceResolvePath "$env:BUILD_ROOT\vcpkg")
    Add-EnvPath $env:VCPKG_ROOT_GDAL -Prepend
}

function Get-7ZipInstallation {   
    Write-BuildStep "Checking for 7z installation"
    New-FolderIfNotExists $env:7Z_ROOT 
    $env:7Z_URL = "https://www.7-zip.org/a/7z2107-extra.7z"
    if (-Not (Test-Path -Path "$env:7Z_ROOT\7za.exe" -PathType Leaf)) { 
        Invoke-WebRequest "$env:7Z_URL" -OutFile "$env:7Z_ROOT\7z.7z"
        Expand-PscxArchive -Path "$env:7Z_ROOT\7z.7z" -OutputPath "$env:7Z_ROOT\"
        Write-BuildStep "Installed 7z into $env:7Z_ROOT"
    }
    else {
        Write-BuildStep "7z is available at $env:7Z_ROOT"
    }
    $env:PATH += ";$env:7Z_ROOT"
}

function Get-GdalSdkIsAvailable {
    New-FolderIfNotExistsAndSetCurrentLocation $env:DOWNLOADS_DIR
    Write-BuildStep "Checking for GDAL SDK from GisInternals"
    if (-Not (Test-Path -Path $env:SDK_ZIP -PathType Leaf)) { 
        Write-BuildInfo "Downloading GDAL SDK from GisInternals"
        Invoke-WebRequest "$env:SDK_URL" -OutFile "$env:SDK_ZIP" 
        Write-BuildStep "GDAL SDK was downloaded"
    }
    New-FolderIfNotExistsAndSetCurrentLocation "$env:BUILD_ROOT\sdk" 

    if (-Not (Test-Path -Path "$env:BUILD_ROOT\sdk\release-*" -PathType Container)) {
        exec { 7za x "$env:DOWNLOADS_DIR\$env:SDK_ZIP" -aoa }
    }
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

    # Force VCPKG_ROOT to a workspace-local path to avoid VS's bundled vcpkg under Program Files
    if (-not $env:VCPKG_ROOT_GDAL -or ($env:VCPKG_ROOT_GDAL -notlike "$env:BUILD_ROOT*")) {
        $env:VCPKG_ROOT_GDAL = (Get-ForceResolvePath "$env:BUILD_ROOT\vcpkg")
    }

    if ($null -eq $env:VCPKG_DEFAULT_BINARY_CACHE) {
        $env:VCPKG_DEFAULT_BINARY_CACHE = "$env:BUILD_ROOT\vcpkg-cache"
    }
    New-FolderIfNotExists $env:VCPKG_DEFAULT_BINARY_CACHE

    Write-BuildStep "Checking for VCPKG installation"    
    if ($bootstrapVcpkg) {
        Get-CloneAndCheckoutCleanGitRepo https://github.com/Microsoft/vcpkg.git master $env:VCPKG_ROOT_GDAL
    }
    if (-Not (Test-Path -Path "$env:VCPKG_ROOT_GDAL/vcpkg.exe" -PathType Leaf)) { 
        Write-BuildInfo "Installing VCPKG" 
        exec { & "$env:VCPKG_ROOT_GDAL\bootstrap-vcpkg.bat" }
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
            Remove-Item -Path "$env:BUILD_ROOT\proj-build" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }    
    Write-BuildInfo "Checking out PROJ repo..."

    Set-Location "$PSScriptRoot"
    nmake -f fetch-makefile.vc fetch-proj
 
    $env:ProjCmakeBuild = "$env:BUILD_ROOT\proj-cmake-temp"
    if ($cleanProjIntermediate) {
        Write-BuildInfo "Cleaning GDAL intermediate folder"
        Remove-Item -Path $env:ProjCmakeBuild -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ((Test-Path -Path "$env:ProjCmakeBuild\CMakeCache.txt" -PathType Leaf)) {
        Write-BuildInfo "Removing build cache (CMakeCache.txt)"
        Remove-Item "$env:ProjCmakeBuild\CMakeCache.txt" -ErrorAction SilentlyContinue
    }
 
    Write-BuildInfo "Configuring PROJ..."
    New-FolderIfNotExistsAndSetCurrentLocation $env:ProjCmakeBuild

    cmake -G "$env:VS_VERSION" -A $env:CMAKE_ARCHITECTURE "${env:PROJ_SOURCE}" `
        -DCMAKE_INSTALL_PREFIX="${env:PROJ_INSTALL_DIR}" `
        -DCMAKE_BUILD_TYPE=Release -Wno-dev `
        -DCMAKE_C_FLAGS="/w" `
        -DCMAKE_CXX_FLAGS="/w" `
        -DBUILD_TESTING=OFF `
        -DCMAKE_TOOLCHAIN_FILE="${env:VCPKG_ROOT_GDAL}\scripts\buildsystems\vcpkg.cmake" `
        -DCMAKE_PREFIX_PATH="${env:VCPKG_INSTALLED};${env:SDK_PREFIX}" `
        -DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF `
        -DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF `
        -DBUILD_SHARED_LIBS=ON -DENABLE_CURL=ON -DENABLE_TIFF=ON `

    exec { cmake --build . -j $env:CMAKE_PARALLEL_JOBS --config Release --target install }
    Write-BuildStep "Done building PROJ"
}

function Get-GdalVersion {
    return (Get-Content "$env:GDAL_SOURCE\VERSION")
}

function Reset-GdalSourceBindings {

    # remove swig/csharp/[gdal|ogr|osr|const]/obj folders
    $env:GdalCsharpBindings = "$env:GdalCmakeBuild\swig\csharp\gdal\obj"
    $env:OgrCsharpBindings = "$env:GdalCmakeBuild\swig\csharp\ogr\obj"
    $env:OsrCsharpBindings = "$env:GdalCmakeBuild\swig\csharp\osr\obj"
    $env:ConstCsharpBindings = "$env:GdalCmakeBuild\swig\csharp\const\obj"

    Write-BuildInfo "Cleaning up GDAL source bindings..."
    Remove-Item -Path $env:GdalCsharpBindings -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $env:OgrCsharpBindings -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $env:OsrCsharpBindings -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -Path $env:ConstCsharpBindings -Recurse -Force -ErrorAction SilentlyContinue
    Write-BuildInfo "GDAL source bindings were cleaned up"
}

function Build-Gdal {
    param (
        [bool] $cleanGdalBuild = $true,
        [bool] $cleanGdalIntermediate = $true,
        [bool] $fetchGdal = $true
    )
    Set-GdalVariables 
    $env:PATH = "$env:BUILD_ROOT\proj-build\bin;$env:SDK_BIN;$env:PATH" 
    $env:CMAKE_INSTALL_PREFIX = "-DCMAKE_INSTALL_PREFIX=$env:GDAL_INSTALL_DIR"
    $env:PROJ_ROOT = "-DPROJ_ROOT=$env:PROJ_INSTALL_DIR"
    $env:MYSQL_LIBRARY = "-DMYSQL_LIBRARY=$env:SDK_LIB\libmysql.lib"
    $env:WEBP_INCLUDE = "-DWEBP_INCLUDE_DIR=$env:WEBP_ROOT\include"
    $env:WEBP_LIB = "-DWEBP_LIBRARY=$env:WEBP_ROOT\lib\libwebp.lib"

    $env:Poppler_INCLUDE_DIR = "-DPoppler_INCLUDE_DIR=$env:VCPKG_INSTALLED\include\poppler"
    $env:Poppler_LIBRARY = "-DPoppler_LIBRARY=$env:VCPKG_INSTALLED\lib\poppler.lib"
    $env:TIFF_INCLUDE_DIR = "-DTIFF_INCLUDE_DIR=$env:VCPKG_INSTALLED\include\tiff"
    $env:TIFF_LIBRARY = "-DTIFF_LIBRARY_RELEASE=$env:VCPKG_INSTALLED\lib\tiff.lib"

    Write-BuildStep "Configuring GDAL"
    Set-Location "$env:BUILD_ROOT"

    if ($cleanGdalBuild) {
        Write-BuildInfo "Cleaning GDAL build folder"
        if (Test-Path -Path "$env:BUILD_ROOT\gdal-build" -PathType Container) {
            Remove-Item -Path "$env:BUILD_ROOT\gdal-build" -Recurse -Force  -ErrorAction SilentlyContinue
        } 
    }
    
    if ($cleanGdalIntermediate) {
        Write-BuildInfo "Cleaning GDAL intermediate folder"
        Remove-Item -Path $env:GdalCmakeBuild -Recurse -Force  -ErrorAction SilentlyContinue
    }
    
    Set-Location "$PSScriptRoot"

    if ($fetchGdal) {
        Write-BuildInfo "Fetching GDAL source"
        exec { nmake -f fetch-makefile.vc fetch-gdal }
    } 
            
    if ((Test-Path -Path "$env:GdalCmakeBuild\CMakeCache.txt" -PathType Leaf)) {
        Write-BuildInfo "Removing build cache (CMakeCache.txt)"
        Remove-Item "$env:GdalCmakeBuild\CMakeCache.txt"  -ErrorAction SilentlyContinue
    }

    # PATCH 1: replace build root of SDK with our own
    Set-ReplaceContentInFiles -Path $env:SDK_PREFIX `
        -FileFilter "*.pc", "*.cmake", "*.opt" `
        -What "E:/buildsystem/$env:SDK", "E:\buildsystem\$env:SDK" `
        -With $env:SDK_PREFIX.Replace("\", "/")  

    Set-Location "$env:GDAL_SOURCE"

    Remove-Item -Path $env:GDAL_SOURCE/autotest -Recurse -Force  -ErrorAction SilentlyContinue
    # PATCH 2: apply patch to cmake pipeline. remove redundant compile steps
    git apply "$PSScriptRoot\..\shared\patch\CMakeLists.txt.patch"

    New-FolderIfNotExistsAndSetCurrentLocation $env:GdalCmakeBuild
    New-FolderIfNotExists "$PSScriptRoot\..\nuget"
    
    $env:ARCH_FLAGS = "/arch:AVX2 /Ob2 /Oi /Os /Oy /w"
    # disabling KEA driver as it causes build issues on Windows
    # https://github.com/OSGeo/gdal/blob/3b232ee17d8f3d93bf3535b77fbb436cb9a9c2e0/.github/workflows/windows_build.yml#L178

    # for the same reason, we are disabling OpenEXR
    # -DOpenEXR_LIBRARY="$env:VCPKG_INSTALLED\lib\OpenEXR-3_2.lib" `
    # -DOpenEXR_INCLUDE_DIR="$env:VCPKG_INSTALLED\include\OpenEXR" `
    # -DOpenEXR_UTIL_LIBRARY="$env:VCPKG_INSTALLED\lib\OpenEXRUtil-3_2.lib" `
    # -DOpenEXR_HALF_LIBRARY="$env:VCPKG_INSTALLED\lib\Imath-3_1.lib" `
    # -DOpenEXR_IEX_LIBRARY="$env:VCPKG_INSTALLED\lib\Iex-3_2.lib" `

    cmake -G "$env:VS_VERSION" -A $env:CMAKE_ARCHITECTURE "$env:GDAL_SOURCE" `
        $env:CMAKE_INSTALL_PREFIX -DCMAKE_BUILD_TYPE=Release -Wno-dev `
        -DCMAKE_C_FLAGS="$env:ARCH_FLAGS" `
        -DCMAKE_CXX_FLAGS="$env:ARCH_FLAGS" `
        -DCMAKE_PREFIX_PATH="${env:VCPKG_INSTALLED};${env:SDK_PREFIX}" `
        -DCMAKE_FIND_USE_PACKAGE_REGISTRY=OFF `
        -DCMAKE_FIND_USE_SYSTEM_PACKAGE_REGISTRY=OFF `
        -DGDAL_USE_OPENEXR=OFF `
        $env:WEBP_INCLUDE  $env:WEBP_LIB `
        $env:PROJ_ROOT $env:MYSQL_LIBRARY `
        $env:Poppler_INCLUDE_DIR $env:Poppler_LIBRARY `
        -DGDAL_USE_KEA=OFF `
        -DGDAL_USE_ZLIB_INTERNAL=ON `
        -DGDAL_CSHARP_APPS=ON `
        -DGDAL_CSHARP_TESTS=OFF `
        -DGDAL_CSHARP_BUILD_NUPKG=OFF `
        -DBUILD_CSHARP_BINDINGS=ON `
        -DBUILD_JAVA_BINDINGS=OFF `
        -DBUILD_PYTHON_BINDINGS=OFF


    Write-BuildStep "Building GDAL"
    exec { cmake --build . -j $env:CMAKE_PARALLEL_JOBS --config Release --target install }

    # remove source. this was added by GDAL
    exec { dotnet nuget remove source local }
    Write-BuildStep "GDAL was built successfully"
}

function Build-GenerateProjectFiles {
    param (
        [string] $packageVersion
    )
    Set-GdalVariables
    Set-Location "$PSScriptRoot/../unix" 
    $vcpkgInstalled = Get-PathRelative -inputPath:$env:VCPKG_INSTALLED_PKGCONFIG -relativePath:"../build-win"
    $geosVersion = (& $env:GitBash -c "make -f generate-projects-makefile get-version IN_FILE=$("$vcpkgInstalled/geos.pc")")

    # generate project files for C# bindings
    Write-BuildStep "Generating project files for GDAL C# bindings"
    exec { & $env:GitBash -c "make -f generate-projects-makefile CAT_NAME=win RUNTIME_PACKAGE_PARTIAL=WindowsRuntime TARGET_OS=win BUILD_NUMBER_TAIL=$packageVersion GEOS_VERSION=$geosVersion BUILD_ARCH=$env:CMAKE_ARCHITECTURE" }
    Write-BuildStep "Done generating project files"
}

function Build-CsharpBindings {   
    param (
        [bool] $isDebug = $false,
        [string] $packageVersion
    )
    Set-GdalVariables
    Write-BuildStep "Building GDAL C# bindings"
    
    Get-VisualStudioVars

    Set-Location $PSScriptRoot
    
    Write-GdalFormats

    Set-Location $PSScriptRoot

    $outputPath = & nmake -f collect-deps-makefile.vc get-output
    Write-BuildInfo "Output path: $outputPath"
    exec { & nmake -f collect-deps-makefile.vc }

    Get-CollectDeps "$env:GDAL_INSTALL_DIR\bin\gdal.dll" "$outputPath"
    
    Build-GenerateProjectFiles -packageVersion $packageVersion 

    Set-Location $PSScriptRoot
    if ($isDebug) {
        exec { & nmake -f publish-makefile.vc pack-dev DEBUG=1 PACKAGE_BUILD_NUMBER=$packageVersion }
    }
    else {
        exec { & nmake -f publish-makefile.vc pack PACKAGE_BUILD_NUMBER=$packageVersion }
    }
}

function Convert-ToUnixPath($path) {
    $unixPath = $path -replace "\\", "/"
    if ($unixPath -match "^([a-zA-Z]):") {
        $unixPath = $unixPath -replace "^([a-zA-Z]):", { "/$($matches[1].ToLower())" }
    }
    if ($unixPath -match "\s") {
        $unixPath = "`"$unixPath`""
    }
    return $unixPath
}

# Function to find and copy dependent DLLs recursively
function Copy-DependentDLLs {
    param (
        [string]$dllFileInternal,
        [string[]]$dllDirectories,
        [string]$destinationDir,     
        [string]$overridePath = $null # Optional parameter for path override
    )
    $dllProcessed = @{}
    $targetDll = [System.IO.Path]::GetFileName($dllFileInternal)
    Write-BuildStep "Copying dependent DLLs for $dllFileInternal"
    # Convert Windows paths to Unix paths for Git Bash and construct LD_LIBRARY_PATH
    $ldLibraryPath = ($dllDirectories | ForEach-Object { Convert-ToUnixPath $_ }) -join ":"
    # Use overridePath if provided, otherwise use an empty string
    $combinedPath = if ($overridePath) { "${overridePath}:${ldLibraryPath}" } else { $ldLibraryPath }

    $dllFileUnix = Convert-ToUnixPath $dllFileInternal
    Write-BuildInfo "DLL file unix: $dllFileUnix"
    
    # Get the list of dependent DLLs using ldd
    Write-BuildInfo "Dry run ldd command: "
    & $env:GitBash -c "PATH=${combinedPath}:`$PATH ldd $dllFileUnix"

    # Construct the LDD string
    $bashCommand = if ($combinedPath) { "PATH=${combinedPath}:`$PATH ldd $dllFileUnix" } else { "ldd $dllFileUnix" }

    $lddOutput = & $env:GitBash -c "$bashCommand"

    $lddLines = $lddOutput -split "`n"
    $dllPaths = @()
    foreach ($line in $lddLines) {
        if ($line -match "=>\s+(\/[a-z]\/.+\.dll)") {
            if ($matches.Count -gt 1) {
                $dllPath = $matches[1]
                $dllName = [System.IO.Path]::GetFileName($dllPath)
                    
                # we don't need system DLLs, so drop 'em if name starts with api-
                if ($dllName -match "^api-") {
                    continue
                }
                # mingw64, lib, usr are also system paths, so skip them
                if ($dllPath -match "^\/usr\/" -or $dllPath -match "^\/lib\/" -or $dllPath -match "^\/mingw64\/") {
                    continue
                }

                $dllPath = $dllPath -replace "/", "\"
                
                if ($dllPath -match "^\\c\\Windows\\System32" -or $dllPath -match "^\\c\\Windows\\SysWOW64") {
                    foreach ($dir in $dllDirectories) {
                        $candidatePath = Join-Path -Path $dir -ChildPath $dllName
                        if (Test-Path -Path $candidatePath) {
                            Write-BuildInfo "Overriding system DLL with version from '$dir': $candidatePath"
                            $dllPath = $candidatePath
                            break
                        }
                    }
                }
                    
                # Skip system paths and include msodbcsql17.dll and other specific DLLs
                $dllsToRestore = @("msodbcsql17.dll", "OpenCL.dll", "libcrypto*", "libssl*")
                $shouldInclude = $false
                foreach ($pattern in $dllsToRestore) {
                    if ($dllName -like $pattern) {
                        $shouldInclude = $true
                        break
                    }
                }
                if ($dllPath -notmatch "^\\c\\Windows" -or $shouldInclude) {
                    if ($dllPath -match "^\\([a-z])\\") {
                        $dllPath = $dllPath -replace "^\\([a-z])\\", { "$($matches[1].ToUpper()):\" }
                    }  
                    Write-BuildInfo "Found candidate for copy: $dllPath"
                    $dllPaths += $dllPath
                }
            }
        }
    }

    $fileName = [System.IO.Path]::GetFileName($dllFileInternal)
    $destinationPath = Join-Path -Path $destinationDir -ChildPath $fileName
    Copy-Item -Path $dllFileInternal -Destination $destinationPath -Force
    $dllProcessed[$fileName] = $true
    Write-BuildInfo "Copied main DLL: $dllFileInternal => $dllPaths"

    # Copy each dependent DLL to the destination directory
    foreach ($dllPathLocal in $dllPaths) {
        $fileName = [System.IO.Path]::GetFileName($dllPathLocal)
        $destinationPath = Join-Path -Path $destinationDir -ChildPath $fileName
            
        if (-Not (Test-Path -Path $destinationPath) -or (-not $dllProcessed.ContainsKey($fileName))) {
            Copy-Item -Path $dllPathLocal -Destination $destinationPath -Force
            Write-Output "$targetDll > Copied: $dllPathLocal to $destinationPath"
                
            $dllProcessed[$fileName] = $true
        }        
    }
}

function Get-CollectDeps {
    param (
        [string] $dllFile,
        [string] $destinationDir
    ) 

    Set-GdalVariables
    $env:GDAL_DATA = "$env:GDAL_INSTALL_DIR\share\gdal"
    $env:GDAL_DRIVER_PATH = "$env:GDAL_INSTALL_DIR\share\gdal"
    $env:PROJ_LIB = "$env:PROJ_INSTALL_DIR\share\proj"

    $dllDirectories = @("$env:GDAL_INSTALL_DIR\bin", "$env:PROJ_INSTALL_DIR\bin", "$env:VCPKG_INSTALLED\bin", "$env:SDK_PREFIX\bin", $env:VCToolsRedistDir + "x64\")
    Write-BuildInfo "Using DLL directories: $dllDirectories"

    Write-BuildInfo "Collecting dependent DLLs for $dllFile"
    
    Write-BuildInfo "Destination directory: $destinationDir"

    if (-Not (Test-Path -Path $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir
    }

    # Start the recursive copying process
    Copy-DependentDLLs -dllFileInternal $dllFile -destinationDir $destinationDir -dllDirectories $dllDirectories

    Write-BuildInfo "All dependent DLLs have been copied to $destinationDir"
}

function Write-GdalFormats {
    Set-GdalVariables

    $dllDirectories = @("$env:GDAL_INSTALL_DIR\bin", "$env:VCPKG_INSTALLED\bin", "$env:SDK_PREFIX\bin", "$env:PROJ_INSTALL_DIR\bin", "$webpRoot\bin")
    $originalPath = [System.Environment]::GetEnvironmentVariable("PATH", [System.EnvironmentVariableTarget]::Process)
    $newPath = ($dllDirectories -join ";") + ";" + $originalPath 
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, [System.EnvironmentVariableTarget]::Process)

    $formats_path = (Get-ForceResolvePath "$PSScriptRoot\..\tests\gdal-formats\formats-win") 
    New-FolderIfNotExists $formats_path
    
    Set-Location "$env:GDAL_INSTALL_DIR\bin" 
    try {
        (& .\gdalinfo.exe --formats) | Set-Content $formats_path\gdal-formats-win-raster.txt -Force
        (& .\ogrinfo.exe --formats) | Set-Content $formats_path\gdal-formats-win-vector.txt -Force

        # Fix windows style paths in gdal-config
        Write-FixShellScriptOnWindows -shellScriptPath "$env:GDAL_INSTALL_DIR\bin\gdal-config" -variableName "CONFIG_DEP_LIBS"
        
        (& $env:GitBash -c "./gdal-config --formats") | Set-Content -Path "$formats_path\gdal-formats-win.txt" -Force
    }
    catch {
        Write-BuildError "Failed to write GDAL formats"
        Write-BuildError $_.Exception.Message
    }
    
    # Restore the original PATH
    [System.Environment]::SetEnvironmentVariable("PATH", $originalPath, [System.EnvironmentVariableTarget]::Process)
}

function  Write-FixShellScriptOnWindows {
    param (
        [string] $shellScriptPath, 
        [string] $variableName
    )
    $shellScriptContent = Get-Content -Path $shellScriptPath -Raw
    $pattern = [regex]::Escape($variableName) + '="([^""].*)"'
    if ($shellScriptContent -match $pattern) {
        $value = $matches[1]
        if ($value.Contains("\(") -or $value.Contains('\"')) {
            Write-Output "Variable $variableName already fixed in the script."
            return
        }
        $paths = $value -split ' (?=(?:[^"]*"[^"]*")*[^"]*$)'
        $escapedPaths = $paths | ForEach-Object {
            $_.Replace(" ", "\\ ").Replace("(", "\(").Replace(")", "\)").Replace('"', '\"');
        }
        $escapedValue = ($escapedPaths -join ' ')
        $newLine = "$variableName=""$escapedValue"""
        $shellScriptContent = $shellScriptContent -replace "$variableName=""[^""].*""", $newLine
        Set-Content -Path $shellScriptPath -Value $shellScriptContent
    
        Write-Output "Shell script has been updated successfully."
    
    }
    else {
        Write-Output "Variable $variableName not found in the script."
    }
}
