(cd ../.. && dotnet new nugetconfig --force)
dotnet nuget remove source local > /dev/null || :
dotnet nuget remove source local.ci > /dev/null || :
dotnet nuget remove source github > /dev/null || :
dotnet nuget remove source nuget.org > /dev/null || :        