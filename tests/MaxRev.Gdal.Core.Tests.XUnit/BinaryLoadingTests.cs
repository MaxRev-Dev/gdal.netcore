using MaxRev.Gdal.Core;
using OSGeo.GDAL;
using OSGeo.OGR;
using OSGeo.OSR;
using System.IO;
using Xunit;
using Xunit.Abstractions;

namespace GdalCore_XUnit
{
    [Collection("Sequential")]
    public class BinaryLoadingTests
    {
        private readonly ITestOutputHelper _outputHelper;

        public BinaryLoadingTests(ITestOutputHelper outputHelper)
        {
            _outputHelper = outputHelper;
        }

        [Fact]
        public void ConfigureAll_CanBeCalledMultipleTimes()
        {
            // Call ConfigureAll first time
            GdalBase.ConfigureAll();
            var firstDriverCount = Gdal.GetDriverCount();

            // Call ConfigureAll second time
            GdalBase.ConfigureAll();
            var secondDriverCount = Gdal.GetDriverCount();

            // Assert both counts are equal and greater than 0
            Assert.True(firstDriverCount > 0, "First call should register drivers");
            Assert.Equal(firstDriverCount, secondDriverCount);
            _outputHelper.WriteLine($"ConfigureAll idempotency verified: {firstDriverCount} drivers on both calls");
        }

        [Fact]
        public void ConfigureAll_RegistersDrivers()
        {
            // Call ConfigureAll
            GdalBase.ConfigureAll();

            // Assert raster drivers registered
            var rasterDriverCount = Gdal.GetDriverCount();
            Assert.True(rasterDriverCount > 0, "Raster drivers should be registered");
            _outputHelper.WriteLine($"Raster drivers registered: {rasterDriverCount}");

            // Assert vector drivers registered
            var vectorDriverCount = Ogr.GetDriverCount();
            Assert.True(vectorDriverCount > 0, "Vector drivers should be registered");
            _outputHelper.WriteLine($"Vector drivers registered: {vectorDriverCount}");

            // Assert GdalBase.IsConfigured flag is set
            Assert.True(GdalBase.IsConfigured, "GdalBase.IsConfigured should be true after ConfigureAll");
        }

        [Fact]
        public void GDAL_DATA_PathExists_AfterConfigure()
        {
            // Call ConfigureAll
            GdalBase.ConfigureAll();

            // Get GDAL_DATA path
            var gdalDataPath = Gdal.GetConfigOption("GDAL_DATA", null);

            // Assert path is not null
            Assert.NotNull(gdalDataPath);

            // Assert directory exists
            Assert.True(Directory.Exists(gdalDataPath), $"GDAL_DATA path should exist: {gdalDataPath}");

            // Log the path
            _outputHelper.WriteLine($"GDAL_DATA path: {gdalDataPath}");
        }

        [Fact]
        public void PROJ_LIB_PathExists_AndContainsProjDb()
        {
            // Call Proj.Configure
            Proj.Configure();

            // Verify proj.db exists and is functional by importing EPSG codes
            // This validates that:
            // 1. proj.db file exists and is accessible
            // 2. PROJ_LIB path is correctly configured
            // 3. The database contains required EPSG definitions

            var sr = new SpatialReference(null);
            var result = sr.ImportFromEPSG(4326); // WGS 84
            Assert.Equal(0, result); // OGRERR_NONE - import succeeded

            // Export to WKT to verify the import was valid
            sr.ExportToWkt(out string wkt, null);
            Assert.Contains("WGS 84", wkt);

            // Test a second EPSG code to verify database integrity
            var sr2 = new SpatialReference(null);
            var result2 = sr2.ImportFromEPSG(3857); // Web Mercator
            Assert.Equal(0, result2); // OGRERR_NONE

            sr2.ExportToWkt(out string wkt2, null);
            Assert.Contains("WGS 84", wkt2); // Web Mercator is based on WGS 84

            _outputHelper.WriteLine("proj.db verified through successful EPSG imports (4326, 3857)");
        }

        [Fact]
        public void RuntimePackage_IsAvailable()
        {
            // Assert runtime package is available
            var isAvailable = AssemblyValidator.CheckIfRuntimeAvailable();
            Assert.True(isAvailable, "Runtime package should be available");

            _outputHelper.WriteLine("Runtime package validation passed");
        }
    }
}
