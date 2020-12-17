using System;
using System.IO;
using MaxRev.Gdal.Core;
using OSGeo.GDAL;
using OSGeo.OSR;
using Xunit;
using Xunit.Abstractions;
using System.Collections.Generic;
using System.Linq;

namespace GdalCore_XUnit
{
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
                "sdts", "gpkg", "vfk", "osm"
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

            using var spatialReference = new SpatialReference(wkt);

            spatialReference.ExportToProj4(out string projString);

            Assert.False(string.IsNullOrWhiteSpace(projString));
        }


        [Theory]
        [MemberData(nameof(ValidTestData))]
        public void GetGdalInfo(string file)
        {
            using var inputDataset = Gdal.Open(file, Access.GA_ReadOnly);

            var info = Gdal.GDALInfo(inputDataset, new GDALInfoOptions(null));

            Assert.NotNull(info);
        }

        private static string GetTestDataFolder(string testDataFolder)
        {
            var startupPath = AppContext.BaseDirectory;
            var pathItems = startupPath.Split(Path.DirectorySeparatorChar);
            var pos = pathItems.Reverse().ToList().FindIndex(x => string.Equals("bin", x));
            var projectPath = string.Join(Path.DirectorySeparatorChar.ToString(),
                pathItems.Take(pathItems.Length - pos - 1));
            return Path.Combine(projectPath, testDataFolder);
        }

        public static IEnumerable<object[]> ValidTestData
        {
            get {
                var names = Directory.EnumerateFiles(GetTestDataFolder("samples"), "*_valid.tif");
                return names.Select(x => new[] { x });
            }
        }
    }
}
