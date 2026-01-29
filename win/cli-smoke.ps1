param(
    [Parameter(Mandatory = $true)][string] $CliTestDir,
    [Parameter(Mandatory = $true)][string] $CliRid,
    [Parameter(Mandatory = $true)][string] $GdalVersion,
    [Parameter(Mandatory = $true)][string] $PackageBuildNumber,
    [Parameter(Mandatory = $true)][string] $NugetPath
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
    dotnet restore -s "$NugetPath" --ignore-failed-sources
    dotnet build -c Release --no-restore

    $cliTool = Get-ChildItem -Path (Join-Path $CliTestDir 'bin\Release') -Recurse -Filter 'gdalinfo.exe' | Select-Object -First 1
    if (-not $cliTool) {
        throw "gdalinfo.exe not found under $CliTestDir\\bin\\Release"
    }

    Write-Host "CLI_TOOL=$($cliTool.FullName)"
    & $cliTool.FullName --version
}
finally {
    Pop-Location
}
