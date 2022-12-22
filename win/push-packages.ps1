dotnet nuget push ../nuget/MaxRev.Gdal.Core.$env:VERSION.nupkg -s nuget.org -k $env:API_KEY_NUGET --skip-duplicate
dotnet nuget push ../nuget/MaxRev.Gdal.LinuxRuntime.Minimal.$env:VERSION.nupkg -s nuget.org -k $env:API_KEY_NUGET --skip-duplicate
dotnet nuget push ../nuget/MaxRev.Gdal.WindowsRuntime.Minimal.$env:VERSION.nupkg -s nuget.org -k $env:API_KEY_NUGET --skip-duplicate

dotnet nuget push ../nuget/MaxRev.Gdal.Core.$env:VERSION.nupkg -s github -k $env:API_KEY_GITHUB --skip-duplicate
dotnet nuget push ../nuget/MaxRev.Gdal.LinuxRuntime.Minimal.$env:VERSION.nupkg -s github -k $env:API_KEY_GITHUB --skip-duplicate
dotnet nuget push ../nuget/MaxRev.Gdal.WindowsRuntime.Minimal.$env:VERSION.nupkg -s github -k $env:API_KEY_GITHUB --skip-duplicate