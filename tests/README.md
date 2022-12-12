# Tests of GDAL.NETCORE

This folder contains tests related to Docker, Azure Pipelines and native tests.

## Docker
If you want to run any .NET app in docker you can use the [Dockerfile](MaxRev.Gdal.Core.Tests/Dockerfile) and [docker-compose.yml](docker-compose.yml) files as samples.
```
docker-compose run --rm maxrev.gdal.core.tests
```
## Azure Pipelines
View the [MaxRev.Gdal.Core.AzurePipelines](MaxRev.Gdal.Core.AzurePipelines) folder with a sample of creating function with GDAL.

