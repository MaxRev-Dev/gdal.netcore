using MaxRev.Gdal.Core;
using OSGeo.GDAL;
using System;
using System.IO;
using Xunit;

namespace GdalCore_XUnit
{
    [Collection("Sequential")]
    public class ModernImageTests
    {
        public ModernImageTests()
        {
            GdalBase.ConfigureAll();
        }

        [Theory]
        [InlineData("AVIF")]
        [InlineData("HEIF")]
        public void DriverIsRegistered(string name)
        {
            using var driver = Gdal.GetDriverByName(name);
            Assert.NotNull(driver);
        }

        [Fact]
        public void HeifHasHevcDecoderWithoutEncoder()
        {
            using var driver = Gdal.GetDriverByName("HEIF");
            Assert.NotNull(driver);
            Assert.Equal("YES", driver.GetMetadataItem("SUPPORTS_HEVC", "HEIF"));
            Assert.NotEqual("YES", driver.GetMetadataItem("SUPPORTS_HEVC_WRITE", "HEIF"));
        }

        [Fact]
        public void AvifLosslessRoundTrip()
        {
            var path = Path.Combine(Path.GetTempPath(), $"gdal-{Guid.NewGuid():N}.avif");
            try
            {
                using var memory = Gdal.GetDriverByName("MEM");
                using var avif = Gdal.GetDriverByName("AVIF");
                Assert.NotNull(avif);
                using var source = memory.Create("", 8, 8, 1, DataType.GDT_Byte, null);
                var expected = new byte[64];
                for (var i = 0; i < expected.Length; i++)
                    expected[i] = (byte)(i * 4);
                using (var band = source.GetRasterBand(1))
                    Assert.Equal(CPLErr.CE_None, band.WriteRaster(0, 0, 8, 8, expected, 8, 8, 0, 0));
                using (var copy = avif.CreateCopy(path, source, 0, new[] { "QUALITY=100" }, null, null))
                    Assert.NotNull(copy);

                using var reopened = Gdal.Open(path, Access.GA_ReadOnly);
                Assert.NotNull(reopened);
                Assert.Equal(8, reopened.RasterXSize);
                Assert.Equal(8, reopened.RasterYSize);
                Assert.Equal(1, reopened.RasterCount);
                var actual = new byte[64];
                using var decoded = reopened.GetRasterBand(1);
                Assert.Equal(CPLErr.CE_None, decoded.ReadRaster(0, 0, 8, 8, actual, 8, 8, 0, 0));
                Assert.Equal(expected, actual);
            }
            finally
            {
                File.Delete(path);
                File.Delete(path + ".aux.xml");
            }
        }
    }
}
