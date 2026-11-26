param([string] $DestinationDirectory)

$ErrorActionPreference = 'Stop'

# Names shipped by MaxRev.Gdal.WindowsRuntime.Minimal 3.13.3.611. Keep this
# explicit: copying *.dll would change the package when VS adds another DLL.
function Get-VcRuntimeDllNames {
    @(
        'concrt140.dll', 'msvcp140.dll', 'msvcp140_1.dll', 'msvcp140_2.dll',
        'msvcp140_atomic_wait.dll', 'msvcp140_codecvt_ids.dll', 'vccorlib140.dll',
        'vcruntime140.dll', 'vcruntime140_1.dll', 'vcruntime140_threads.dll'
    )
}

function Get-VcRuntimeDirectory {
    $redistRoot = $null
    $discoverySource = 'vswhere'
    # Prefer the toolset initialized by vcvarsall, when it supplies a valid root.
    if ($env:VCToolsRedistDir -and (Test-Path -LiteralPath $env:VCToolsRedistDir -PathType Container)) {
        $redistRoot = $env:VCToolsRedistDir
        $discoverySource = 'VCToolsRedistDir'
    }
    if (-not $redistRoot -and ${env:ProgramFiles(x86)}) {
        $vswhere = Join-Path ${env:ProgramFiles(x86)} 'Microsoft Visual Studio/Installer/vswhere.exe'
        if (Test-Path -LiteralPath $vswhere -PathType Leaf) {
            $vsPath = & $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath |
                Select-Object -First 1
            if ($LASTEXITCODE -eq 0 -and $vsPath) {
                $versionsRoot = Join-Path $vsPath.Trim() 'VC/Redist/MSVC'
                if (Test-Path -LiteralPath $versionsRoot -PathType Container) {
                    $redistRoot = Get-ChildItem -LiteralPath $versionsRoot -Directory -ErrorAction Stop |
                        Where-Object { $_.Name -match '^\d+\.\d+\.\d+(\.\d+)?$' } |
                        Sort-Object { [version]$_.Name } -Descending |
                        Select-Object -First 1 -ExpandProperty FullName
                }
            }
        }
    }

    if (-not $redistRoot -or -not (Test-Path -LiteralPath $redistRoot -PathType Container)) {
        throw 'Visual Studio MSVC redist directory not found via vswhere or VCToolsRedistDir. Install the C++ redistributable build tools.'
    }
    $x64Root = Join-Path $redistRoot 'x64'
    $crt = Get-ChildItem -LiteralPath $x64Root -Directory -ErrorAction Stop |
        Where-Object { $_.Name -match '^Microsoft\.VC14\d*\.CRT$' } |
        Sort-Object { [int]($_.Name -replace '\D', '') } -Descending |
        Select-Object -First 1 -ExpandProperty FullName
    if (-not $crt) {
        throw "No x64 Microsoft.VC14*.CRT directory found under '$redistRoot'."
    }
    Write-Host "MSVC runtime redist ($discoverySource): $crt"
    return $crt
}

function Copy-VcRuntimeDlls {
    param([Parameter(Mandatory)] [string] $DestinationDirectory)
    $crt = Get-VcRuntimeDirectory
    # Validate the whole set before copying anything. Never fall back to SDK/bin.
    foreach ($name in (Get-VcRuntimeDllNames)) {
        if (-not (Test-Path -LiteralPath (Join-Path $crt $name) -PathType Leaf)) {
            throw "Missing expected MSVC runtime DLL '$name' in '$crt'."
        }
    }
    New-Item -ItemType Directory -Path $DestinationDirectory -Force -ErrorAction Stop | Out-Null
    foreach ($name in (Get-VcRuntimeDllNames)) {
        $source = Join-Path $crt $name
        $version = (Get-Item -LiteralPath $source).VersionInfo.FileVersion
        Write-Host "MSVC runtime: $name version=$version source=$source"
        Copy-Item -LiteralPath $source -Destination $DestinationDirectory -Force -ErrorAction Stop
    }
}

function Confirm-VcRuntimeDlls {
    param([Parameter(Mandatory)] [string] $DestinationDirectory)
    $crt = Get-VcRuntimeDirectory
    foreach ($name in (Get-VcRuntimeDllNames)) {
        $source = Join-Path $crt $name
        $packaged = Join-Path $DestinationDirectory $name
        if (-not (Test-Path -LiteralPath $source -PathType Leaf) -or
            -not (Test-Path -LiteralPath $packaged -PathType Leaf) -or
            (Get-FileHash -LiteralPath $source -ErrorAction Stop).Hash -ne
            (Get-FileHash -LiteralPath $packaged -ErrorAction Stop).Hash) {
            throw "Packaged MSVC runtime '$name' does not match '$source'."
        }
    }
    Write-Host 'Verified all ten packaged MSVC runtime DLLs come from Visual Studio redist.'
}

if ($DestinationDirectory) {
    Copy-VcRuntimeDlls -DestinationDirectory $DestinationDirectory
}
