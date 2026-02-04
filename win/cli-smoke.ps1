param(
    [Parameter(Mandatory = $true)][string] $CliTestDir,
    [Parameter(Mandatory = $true)][string] $CliRid,
    [Parameter(Mandatory = $true)][string] $GdalVersion,
    [Parameter(Mandatory = $true)][string] $PackageBuildNumber,
    [Parameter(Mandatory = $true)][string] $NugetPath,
    [Parameter(Mandatory = $true)][string] $RuntimePackage
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -Path $CliTestDir)) {
    throw "CLI test project not found at $CliTestDir"
}

$binPath = Join-Path $CliTestDir 'bin'
$objPath = Join-Path $CliTestDir 'obj'
if (Test-Path -Path $binPath) {
    Remove-Item -Path $binPath -Recurse -Force
}
if (Test-Path -Path $objPath) {
    Remove-Item -Path $objPath -Recurse -Force
}

Push-Location $CliTestDir
try {
    dotnet add package "MaxRev.Gdal.CLI.$CliRid" -v "$GdalVersion.$PackageBuildNumber" -s "$NugetPath" --no-restore
    dotnet add package "$RuntimePackage" -v "$GdalVersion.$PackageBuildNumber" -s "$NugetPath" --no-restore
    dotnet add package "MaxRev.Gdal.Core" -v "$GdalVersion.$PackageBuildNumber" -s "$NugetPath" --no-restore
    dotnet restore -s "$NugetPath" --ignore-failed-sources
    dotnet build -c Release --no-restore
    $outputDir = Join-Path $CliTestDir 'bin\Release\net10.0'
    $runtimePath = Join-Path $outputDir ("runtimes\{0}\native" -f $CliRid)
    $env:PATH = "$runtimePath;$env:PATH"

    $tools = @('gdalinfo.exe', 'ogr2ogr.exe', 'gdal_translate.exe')
    foreach ($tool in $tools) {
        $cliTool = Join-Path $outputDir $tool
        if (-not (Test-Path -Path $cliTool)) {
            $toolsFallback = Join-Path $outputDir ("tools\{0}\{1}" -f $CliRid, $tool)
            if (Test-Path -Path $toolsFallback) {
                $cliTool = $toolsFallback
            }
        }
        if (-not (Test-Path -Path $cliTool)) {
            throw "$tool not found under $outputDir"
        }

        Write-Host "CLI_TOOL=$cliTool"
        & $cliTool --version
    }
}
finally {
    Pop-Location
}
