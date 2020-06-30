FROM mcr.microsoft.com/dotnet/core/sdk:3.1

WORKDIR /src
COPY ["GdalCoreTest/GdalCoreTest.csproj", "GdalCoreTest/"]
COPY ./nuget/ ./GdalCoreTest/nuget
RUN dotnet restore "GdalCoreTest/GdalCoreTest.csproj"  -s ./nuget -s "https://api.nuget.org/v3/index.json"
COPY . .

WORKDIR "/src/GdalCoreTest"

RUN dotnet publish "GdalCoreTest.csproj" -c Release -o /app

ENTRYPOINT ["dotnet", "/app/GdalCoreTest.dll"]