param (
    [string] $gdalVersion = "3.7.0",
    [int] $buildNumber = 0
)
# reset previous imports
Remove-Module *
# using predefined set of helper functions
Import-Module (Resolve-Path "functions.psm1") -Force
# reset session
Reset-PsSession

if ($null -eq $env:GDAL_VERSION) { 
    $env:GDAL_VERSION = Get-GdalVersion
}
$buildNumber = $buildNumberTail + 100
$version = "$env:GDAL_VERSION.$buildNumber"
Write-BuildStep "Publishing version $version"
$packages = @(
    "MaxRev.Gdal.Core.$version.nupkg"
    "MaxRev.Gdal.LinuxRuntime.Minimal.x64.$version.nupkg"
    "MaxRev.Gdal.LinuxRuntime.Minimal.arm64.$version.nupkg"
    "MaxRev.Gdal.MacosRuntime.Minimal.x64.$version.nupkg"
    "MaxRev.Gdal.MacosRuntime.Minimal.arm64.$version.nupkg"
    "MaxRev.Gdal.WindowsRuntime.Minimal.$version.nupkg"
    "MaxRev.Gdal.CLI.linux-x64.$version.nupkg"
    "MaxRev.Gdal.CLI.linux-arm64.$version.nupkg"
    "MaxRev.Gdal.CLI.osx-x64.$version.nupkg"
    "MaxRev.Gdal.CLI.osx-arm64.$version.nupkg"
    "MaxRev.Gdal.CLI.win-x64.$version.nupkg"
)
foreach ($package in $packages) {
    Write-BuildInfo "Trying to find $package"
    $packagePath = "$PSScriptRoot/../nuget/$package"
    if (Test-Path -Path $packagePath -PathType Leaf) {
        Write-BuildInfo "[FOUND] Pushing $package"
        dotnet nuget push $packagePath -s nuget.org -k $env:API_KEY_NUGET --skip-duplicate
        dotnet nuget push $packagePath -s github -k $env:API_KEY_GITHUB --skip-duplicate
        Write-BuildStep "Successfully pushed $package"
    }
    else {
        Write-BuildError "[NOT FOUND] Package $package was not found"
    }
}
