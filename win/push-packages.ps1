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

$buildNumber = $buildNumberTail + 100
$version = "$gdalVersion.$buildNumber"
$packages = @(
    "MaxRev.Gdal.Core.$version.nupkg"
    "MaxRev.Gdal.LinuxRuntime.Minimal.$version.nupkg"
    "MaxRev.Gdal.WindowsRuntime.Minimal.$version.nupkg"
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