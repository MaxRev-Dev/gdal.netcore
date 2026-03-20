using MaxRev.Gdal.Core;
using OSGeo.OSR;
using Xunit;

namespace GdalCore_XUnit
{
    [Collection("Sequential")]
    public class ProjTests
    {
        [Fact]
        public void TransformPointIsOk()
        {
            var x = 826158.063;
            var y = 2405844.125;

            var sourceWkt =
                "PROJCS[\"OSGB_1936_British_National_Grid\",GEOGCS[\"GCS_OSGB 1936\",DATUM[\"D_OSGB_1936\",SPHEROID[\"Airy_1830\",6377563.396,299.3249646]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.017453292519943295]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",49],PARAMETER[\"central_meridian\",-2],PARAMETER[\"scale_factor\",0.9996012717],PARAMETER[\"false_easting\",400000],PARAMETER[\"false_northing\",-100000],UNIT[\"Meter\",1]]";
            var targetWkt =
                "PROJCS[\"ETRS89_LAEA_Europe\",GEOGCS[\"GCS_ETRS_1989\",DATUM[\"D_ETRS_1989\",SPHEROID[\"GRS_1980\",6378137,298.257222101]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.017453292519943295]],PROJECTION[\"Lambert_Azimuthal_Equal_Area\"],PARAMETER[\"latitude_of_origin\",52],PARAMETER[\"central_meridian\",10],PARAMETER[\"false_easting\",4321000],PARAMETER[\"false_northing\",3210000],UNIT[\"Meter\",1]]";

            Proj.Configure();

            var sourceSr = new SpatialReference(string.Empty);
            sourceSr.ImportFromWkt(ref sourceWkt);
            sourceSr.SetAxisMappingStrategy(AxisMappingStrategy.OAMS_TRADITIONAL_GIS_ORDER);

            var targetSr = new SpatialReference(string.Empty);
            targetSr.ImportFromWkt(ref targetWkt);
            targetSr.SetAxisMappingStrategy(AxisMappingStrategy.OAMS_TRADITIONAL_GIS_ORDER);
            
            var transformation = new CoordinateTransformation(sourceSr, targetSr); 

            var projected = new double[3];
            transformation.TransformPoint(projected, x, y, 0.0);
            var px = projected[0];
            var py = projected[1];

            var ex = 4316331.55;
            var ey = 5331101.98;
            Assert.Equal(ex, px, 0);
            Assert.Equal(ey, py, 0);
        }

        [Fact]
        public void TransformEPSG_4326_To_EPSG_3857_WebMercator()
        {
            Proj.Configure();

            // Create WGS84 (EPSG:4326) source
            var sourceSr = new SpatialReference(null);
            sourceSr.ImportFromEPSG(4326);
            sourceSr.SetAxisMappingStrategy(AxisMappingStrategy.OAMS_TRADITIONAL_GIS_ORDER);

            // Create Web Mercator (EPSG:3857) target
            var targetSr = new SpatialReference(null);
            targetSr.ImportFromEPSG(3857);
            targetSr.SetAxisMappingStrategy(AxisMappingStrategy.OAMS_TRADITIONAL_GIS_ORDER);

            var transformation = new CoordinateTransformation(sourceSr, targetSr);

            // Transform London coordinates (lon=-0.1278, lat=51.5074)
            var projected = new double[3];
            transformation.TransformPoint(projected, -0.1278, 51.5074, 0.0);
            var px = projected[0];
            var py = projected[1];

            // Assert projected X is in range (-14300, -14200)
            Assert.InRange(px, -14300, -14200);
            // Assert projected Y is in range (6711000, 6712000)
            Assert.InRange(py, 6711000, 6712000);
        }

        [Fact]
        public void WGS84_RoundTrip_PreservesCoordinates()
        {
            Proj.Configure();

            // Create WGS84 (EPSG:4326)
            var wgs84 = new SpatialReference(null);
            wgs84.ImportFromEPSG(4326);
            wgs84.SetAxisMappingStrategy(AxisMappingStrategy.OAMS_TRADITIONAL_GIS_ORDER);

            // Create Web Mercator (EPSG:3857)
            var webMercator = new SpatialReference(null);
            webMercator.ImportFromEPSG(3857);
            webMercator.SetAxisMappingStrategy(AxisMappingStrategy.OAMS_TRADITIONAL_GIS_ORDER);

            // Original San Francisco coordinates
            var originalLon = -122.4194;
            var originalLat = 37.7749;

            // Transform to Web Mercator
            var toWebMercator = new CoordinateTransformation(wgs84, webMercator);
            var mercatorCoords = new double[3];
            toWebMercator.TransformPoint(mercatorCoords, originalLon, originalLat, 0.0);

            // Transform back to WGS84
            var backToWgs84 = new CoordinateTransformation(webMercator, wgs84);
            var roundTripped = new double[3];
            backToWgs84.TransformPoint(roundTripped, mercatorCoords[0], mercatorCoords[1], 0.0);

            // Assert round-tripped coordinates match originals to 6 decimal places
            Assert.Equal(originalLon, roundTripped[0], 6);
            Assert.Equal(originalLat, roundTripped[1], 6);
        }

        [Fact]
        public void PROJ_Database_Exists_And_IsValid()
        {
            Proj.Configure();

            // The test verifies proj.db exists and is functional by:
            // 1. Attempting to import from EPSG (requires proj.db to be present and valid)
            // 2. Verifying the import succeeds (OGRERR_NONE)
            // 3. Verifying the spatial reference exports correctly to WKT

            // Validate EPSG code lookup (verifies proj.db is functional)
            var sr = new SpatialReference(null);
            var result = sr.ImportFromEPSG(4326);
            Assert.Equal(0, result); // OGRERR_NONE - import succeeded

            // Export to WKT and verify it contains "WGS 84"
            sr.ExportToWkt(out string wkt, null);
            Assert.Contains("WGS 84", wkt);

            // Test a second EPSG code to verify database integrity
            var sr2 = new SpatialReference(null);
            var result2 = sr2.ImportFromEPSG(3857);
            Assert.Equal(0, result2); // OGRERR_NONE

            sr2.ExportToWkt(out string wkt2, null);
            Assert.Contains("WGS 84", wkt2); // Web Mercator is based on WGS 84
        }

        [Fact]
        public void TransformEPSG_4326_To_EPSG_32633_UTM()
        {
            Proj.Configure();

            // Create WGS84 (EPSG:4326) source
            var sourceSr = new SpatialReference(null);
            sourceSr.ImportFromEPSG(4326);
            sourceSr.SetAxisMappingStrategy(AxisMappingStrategy.OAMS_TRADITIONAL_GIS_ORDER);

            // Create UTM Zone 33N (EPSG:32633) target
            var targetSr = new SpatialReference(null);
            targetSr.ImportFromEPSG(32633);
            targetSr.SetAxisMappingStrategy(AxisMappingStrategy.OAMS_TRADITIONAL_GIS_ORDER);

            var transformation = new CoordinateTransformation(sourceSr, targetSr);

            // Transform coordinates (lon=15.0, lat=45.0) - near central meridian of zone 33
            var projected = new double[3];
            transformation.TransformPoint(projected, 15.0, 45.0, 0.0);
            var px = projected[0];
            var py = projected[1];

            // Assert projected X is in range (500000, 501000) - near central meridian
            Assert.InRange(px, 500000, 501000);
            // Assert projected Y is in range (4982000, 4983000)
            Assert.InRange(py, 4982000, 4983000);
        }
    }
}