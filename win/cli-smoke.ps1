param(
    [Parameter(Mandatory = $true)][string] $CliTestDir,
    [Parameter(Mandatory = $true)][string] $CliRid,
    [Parameter(Mandatory = $true)][string] $GdalVersion,
    [Parameter(Mandatory = $true)][string] $PackageBuildNumber,
    [Parameter(Mandatory = $true)][string] $NugetPath,
    [Parameter(Mandatory = $true)][string] $RuntimePackage
)

$ErrorActionPreference = 'Stop'

if (Test-Path -Path $CliTestDir) {
    Remove-Item -Path $CliTestDir -Recurse -Force
}
New-Item -Path $CliTestDir -ItemType Directory | Out-Null

Push-Location $CliTestDir
try {
    dotnet new console --no-restore
    dotnet add package "MaxRev.Gdal.CLI.$CliRid" -v "$GdalVersion.$PackageBuildNumber" -s "$NugetPath" --no-restore
    dotnet add package "$RuntimePackage" -v "$GdalVersion.$PackageBuildNumber" -s "$NugetPath" --no-restore
    dotnet restore -s "$NugetPath" --ignore-failed-sources
    $publishDir = Join-Path $CliTestDir 'publish'
    dotnet publish -c Release -o "$publishDir" --no-restore

    $cliTool = Get-ChildItem -Path $publishDir -Recurse -Filter 'gdalinfo.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cliTool) {
        $toolsFallback = Join-Path $publishDir ("tools\{0}\gdalinfo.exe" -f $CliRid)
        if (Test-Path -Path $toolsFallback) {
            $cliTool = Get-Item -Path $toolsFallback
        }
    }
    if (-not $cliTool) {
        throw "gdalinfo.exe not found under $publishDir"
    }

    Write-Host "CLI_TOOL=$($cliTool.FullName)"
    $runtimePath = Join-Path $publishDir ("runtimes\{0}\native" -f $CliRid)
    $env:PATH = "$runtimePath;$env:PATH"
    & $cliTool.FullName --version
}
finally {
    Pop-Location
}
