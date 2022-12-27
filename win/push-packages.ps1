param (
    [string] $version
)
$packages = @(
    "MaxRev.Gdal.Core.$version.nupkg"
    "MaxRev.Gdal.LinuxRuntime.Minimal.$version.nupkg"
    "MaxRev.Gdal.WindowsRuntime.Minimal.$version.nupkg"
)
foreach ($package in $packages) {
    $packagePath = "$PSScriptRoot/../nuget/$package"
    if (Test-Path -Path $packagePath -PathType Leaf) {
        dotnet nuget push $packagePath -s nuget.org -k $env:API_KEY_NUGET --skip-duplicate
        dotnet nuget push $packagePath -s github -k $env:API_KEY_GITHUB --skip-duplicate
    }
}