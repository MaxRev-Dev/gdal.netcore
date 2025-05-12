using MaxRev.Gdal.Core;
using OSGeo.GDAL;
using OSGeo.OGR;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
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

        [Theory]
        [MemberData(nameof(DriversInCurrentVersion))]
        public void AllDriversAvailable(string driver)
        {
            var driverByName = Gdal.GetDriverByName(driver);
            _outputHelper.WriteLine(
                driverByName != default ? $"{driver} loaded successfully" : $"Failed to load {driver}");
            Assert.NotNull(driverByName);
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
            var valid = geom.MakeValid(null);
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

        internal static string GetEnvRID()
        {
            var isArm = RuntimeInformation.ProcessArchitecture is Architecture.Arm64;
            if (File.Exists(@"/System/Library/CoreServices/SystemVersion.plist"))
            {
                return isArm ? "osx-arm64" : "osx-x64";
            }

            return Environment.OSVersion.Platform switch
            {
                PlatformID.Unix => isArm ? "unix-arm64" : "unix-x64",
                PlatformID.Win32NT => "win",
                _ => throw new PlatformNotSupportedException(),
            };
        }

        public static IEnumerable<object[]> DriversInCurrentVersion
        {
            get => GetDriversInCurrentVersion();
        }

        private static IEnumerable<object[]> GetDriversInCurrentVersion()
        {
            var folder = Extensions.GetTestDataFolder("../gdal-formats");
            var rid = GetEnvRID();
            var ridTrimmed = rid.Substring(0, rid.IndexOf('-'));
            var formats = new List<string>();
            foreach (var type in new[] { "raster", "vector" })
            {
                var ciFolder = Path.Combine(folder, $"formats-{rid}");
                // check if the folder exists in CI environment
                if (!Directory.Exists(ciFolder))
                {
                    ciFolder = folder; // fallback to the default path
                }
                var file = Path.Combine(ciFolder, $"gdal-formats-{ridTrimmed}-{type}.txt");
                if (!File.Exists(file))
                {
                    throw new FileNotFoundException($"File not found: {file}");
                }
                formats.AddRange(File.ReadAllLines(file)
                   .Where(x => x.Contains(type))
                   .Select(x => x[..x.IndexOf('-')].Trim())
                   .Where(x => !string.IsNullOrWhiteSpace(x))
                   .ToArray());
            }
            return formats.Distinct().Select(x => new[] { x });
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
