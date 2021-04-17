using MaxRev.Gdal.Core;
using OSGeo.GDAL;
using OSGeo.OGR;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Xunit;
using Xunit.Abstractions;

namespace GdalCore_XUnit
{
    [Collection("Sequential")]
    public class CommonTests
    {
        private readonly ITestOutputHelper _outputHelper;

        public CommonTests(ITestOutputHelper outputHelper)
        {
            _outputHelper = outputHelper;
            GdalBase.ConfigureAll();
        }

        [Fact]
        public void AllDriversAvailable()
        {
            // list of common drivers
            var drivers = new[]
            {
                "hdf4", "hdf5", "gtiff", "aaigrid", "adrg", "airsar", "arg", "blx", "bmp", "bsb", "cals", "ceos",
                "coasp", "cosar", "ctg", "dimap", "dted", "e00grid", "elas", "ers", "fit", "gff", "gxf", "hf2",
                "idrisi", "ignfheightasciigrid", "ilwis", "ingr", "iris", "jaxapalsar", "jdem", "kmlsuperoverlay",
                "l1b", "leveller", "map", "mrf", "msgn", "ngsgeoid", "nitf", "pds", "prf", "r", "rmf", "rs2",
                "safe", "saga", "sdts", "sentinel2", "sgi", "sigdem", "srtmhgt", "terragen", "til", "tsx",
                "usgsdem", "xpm", "xyz", "zmap", "rik", "ozi", "grib", "rasterlite", "mbtiles", "pdf", "aeronavfaa",
                "arcgen", "bna", "cad", "csv", "dgn", "dxf", "edigeo", "geoconcept", "georss", "gml", "gpsbabel",
                "gpx", "htf", "jml", "mvt", "openair", "openfilegdb", "pgdump", "rec", "s57", "segukooa", "segy",
                "selafin", "ESRI Shapefile", "sua", "svg", "sxf", "tiger", "vdv", "wasp", "xplane", "idrisi", "pds",
                "sdts", "gpkg", "vfk", "osm", "PostgreSQL"
            };

            foreach (var driver in drivers)
            {
                var driverByName = Gdal.GetDriverByName(driver);
                _outputHelper.WriteLine(
                    driverByName != default ? $"{driver} loaded successfully" : $"Failed to load {driver}");
                Assert.NotNull(driverByName);
            }

        }

        [Theory]
        [MemberData(nameof(ValidTestData))]
        public void GetProjString(string file)
        {
            using var dataset = Gdal.Open(file, Access.GA_ReadOnly);

            string wkt = dataset.GetProjection();

            using var spatialReference = new OSGeo.OSR.SpatialReference(wkt);

            spatialReference.ExportToProj4(out string projString);

            Assert.False(string.IsNullOrWhiteSpace(projString));
        }


        [Theory]
        [MemberData(nameof(ValidTestData))]
        public void GetGdalInfoRaster(string file)
        {
            using var inputDataset = Gdal.Open(file, Access.GA_ReadOnly);

            var info = Gdal.GDALInfo(inputDataset, new GDALInfoOptions(null));

            Assert.NotNull(info);
        }


        [Theory]
        [MemberData(nameof(ValidTestDataVector))]
        public void GetGdalInfoVector(string file)
        {
            var f = OSGeo.OGR.Ogr.Open(file, 0);

            Assert.NotNull(f);

            for (var i = 0; i < f.GetLayerCount(); i++)
            {
                Assert.NotNull(f.GetLayerByIndex(i));
            }
        }

        [Fact]
        public void GdalDoesNotFailOnMakeValid()
        {
            var wkt = _staticWkt;
            var geom = Geometry.CreateFromWkt(wkt);
            Assert.False(geom.IsValid());
            var valid = geom.MakeValid();
            Assert.True(valid.IsValid());
        }

        private static string _staticWkt =
                "POLYGON((8.39475541866082 18.208975124406155,24.390849168660818 39.41962323304138,43.19944291866082 27.430752179449893,3.9123335436608198 22.736137385695233,8.39475541866082 18.208975124406155))";

        public static IEnumerable<object[]> ValidTestData
        {
            get
            {
                var names = Directory.EnumerateFiles(Extensions.GetTestDataFolder("samples-raster"), "*_valid.tif");
                return names.Select(x => new[] { x });
            }
        }

        public static IEnumerable<object[]> ValidTestDataVector
        {
            get
            {
                var names = Directory.EnumerateFiles(Extensions.GetTestDataFolder("samples-vector"), "*.shp");
                return names.Select(x => new[] { x });
            }
        }
    }
}
