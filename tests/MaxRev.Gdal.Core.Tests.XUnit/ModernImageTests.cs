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
                // GDAL uses YUV444 at QUALITY=100, even for grayscale input; only
                // YUV400 reopens as one band. Exercise explicit RGB instead.
                using var source = memory.Create("", 8, 8, 3, DataType.GDT_Byte, null);
                var expected = new byte[3][];
                for (var bandIndex = 0; bandIndex < expected.Length; bandIndex++)
                {
                    expected[bandIndex] = new byte[64];
                    for (var i = 0; i < expected[bandIndex].Length; i++)
                        expected[bandIndex][i] = (byte)((i * 4 + bandIndex * 37) % 256);
                    using var band = source.GetRasterBand(bandIndex + 1);
                    Assert.Equal(CPLErr.CE_None, band.WriteRaster(0, 0, 8, 8, expected[bandIndex], 8, 8, 0, 0));
                }
                // Full-quality YUV444 uses an identity matrix and full range,
                // so RGB samples must survive exactly without a tolerance.
                using (var copy = avif.CreateCopy(path, source, 0,
                    new[] { "QUALITY=100", "YUV_SUBSAMPLING=444" }, null, null))
                    Assert.NotNull(copy);

                using var reopened = Gdal.Open(path, Access.GA_ReadOnly);
                Assert.NotNull(reopened);
                Assert.Equal(8, reopened.RasterXSize);
                Assert.Equal(8, reopened.RasterYSize);
                Assert.Equal(3, reopened.RasterCount);
                for (var bandIndex = 0; bandIndex < expected.Length; bandIndex++)
                {
                    var actual = new byte[64];
                    using var decoded = reopened.GetRasterBand(bandIndex + 1);
                    Assert.Equal(CPLErr.CE_None, decoded.ReadRaster(0, 0, 8, 8, actual, 8, 8, 0, 0));
                    Assert.Equal(expected[bandIndex], actual);
                }
            }
            finally
            {
                File.Delete(path);
                File.Delete(path + ".aux.xml");
            }
        }
    }
}
