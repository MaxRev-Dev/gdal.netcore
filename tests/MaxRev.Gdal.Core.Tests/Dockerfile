FROM mcr.microsoft.com/dotnet/sdk:7.0 as base
WORKDIR /src
COPY ["tests/MaxRev.Gdal.Core.Tests/MaxRev.Gdal.Core.Tests.csproj", "MaxRev.Gdal.Core.Tests/"]
COPY nuget nuget
RUN dotnet restore "MaxRev.Gdal.Core.Tests/MaxRev.Gdal.Core.Tests.csproj"  -s ./nuget -s "https://api.nuget.org/v3/index.json"
COPY tests/MaxRev.Gdal.Core.Tests .

FROM base AS publish
WORKDIR /src
RUN dotnet publish "MaxRev.Gdal.Core.Tests.csproj" -c Release -o /app/publish /p:UseAppHost=false
 
FROM mcr.microsoft.com/dotnet/runtime:7.0 as final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "MaxRev.Gdal.Core.Tests.dll"]