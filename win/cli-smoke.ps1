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
    dotnet build -c Release --no-restore

    $binRelease = Join-Path $CliTestDir 'bin\Release'
    $cliTool = Get-ChildItem -Path $binRelease -Recurse -Filter 'gdalinfo.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cliTool) {
        $toolsFallback = Join-Path $CliTestDir ("tools\{0}\gdalinfo.exe" -f $CliRid)
        if (Test-Path -Path $toolsFallback) {
            $cliTool = Get-Item -Path $toolsFallback
        }
    }
    if (-not $cliTool) {
        throw "gdalinfo.exe not found under $binRelease or tools\\$CliRid"
    }

    Write-Host "CLI_TOOL=$($cliTool.FullName)"
    & $cliTool.FullName --version
}
finally {
    Pop-Location
}
