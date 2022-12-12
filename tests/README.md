# Tests of GDAL.NETCORE

This folder contains tests related to Docker, Azure Pipelines and native tests.

## Docker
If you want to run any .NET app in docker you can use the [Dockerfile](MaxRev.Gdal.Core.Tests/Dockerfile) and [docker-compose.yml](docker-compose.yml) files as samples.
```
docker-compose run --rm maxrev.gdal.core.tests
```
## Azure Functions
View the [MaxRev.Gdal.Core.Tests.AzureFunctions](MaxRev.Gdal.Core.Tests.AzureFunctions) folder with a sample of creating function with GDAL.

## Functional Tests
Functional tests are located in [MaxRev.Gdal.Core.Tests.XUnit](MaxRev.Gdal.Core.Tests.XUnit) folder. They are divided into several parts:
- [CommonTests.cs](MaxRev.Gdal.Core.Tests.XUnit/CommonTests.cs) - tests that are common for all platforms
- [ProjTests.cs](MaxRev.Gdal.Core.Tests.XUnit/ProjTests.cs) - tests that are specific for projections
- [RasterTests.cs](MaxRev.Gdal.Core.Tests.XUnit/RasterTests.cs) - tests that are specific for raster operations