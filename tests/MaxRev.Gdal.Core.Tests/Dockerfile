FROM mcr.microsoft.com/dotnet/sdk:7.0

WORKDIR /src
COPY ["tests/MaxRev.Gdal.Core.Tests/MaxRev.Gdal.Core.Tests.csproj", "MaxRev.Gdal.Core.Tests/"]
COPY nuget nuget
RUN dotnet restore "MaxRev.Gdal.Core.Tests/MaxRev.Gdal.Core.Tests.csproj"  -s ./nuget -s "https://api.nuget.org/v3/index.json"
COPY tests .

WORKDIR "/src/MaxRev.Gdal.Core.Tests"

RUN dotnet publish "MaxRev.Gdal.Core.Tests.csproj" -c Release -o /app

ENTRYPOINT ["dotnet", "/app/MaxRev.Gdal.Core.Tests.dll"]