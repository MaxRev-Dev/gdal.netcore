FROM mcr.microsoft.com/dotnet/core/runtime:2.2-stretch-slim AS base
WORKDIR /app

FROM mcr.microsoft.com/dotnet/core/sdk:2.2-stretch AS build
WORKDIR /src
COPY ["GdalCoreTest/GdalCoreTest.csproj", "GdalCoreTest/"]
RUN dotnet restore "GdalCoreTest/GdalCoreTest.csproj"
COPY . .
WORKDIR "/src/GdalCoreTest"
RUN dotnet build "GdalCoreTest.csproj" -c Release -o /app

FROM build AS publish
RUN dotnet publish "GdalCoreTest.csproj" -c Release -o /app

FROM base AS final
WORKDIR /app
COPY --from=publish /app .
ENTRYPOINT ["dotnet", "GdalCoreTest.dll"]
