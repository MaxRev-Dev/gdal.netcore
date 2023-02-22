using MaxRev.Gdal.Core;
using OSGeo.GDAL;
using System;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using Xunit;
using Xunit.Abstractions;
using Xunit.Sdk;

namespace GdalCore_XUnit
{

    [Collection("Sequential")]
    public class Utf8Tests
    {
        private readonly ITestOutputHelper _outputHelper;
        private readonly string dataDirectoryPath;
        private readonly string englishInputFilePath;
        private readonly string cyrillicInputFilePath;

        public Utf8Tests(ITestOutputHelper outputHelper)
        {
            _outputHelper = outputHelper;
            GdalBase.ConfigureAll();

            dataDirectoryPath = Extensions.GetTestDataFolder("utf8-data");
            englishInputFilePath = Path.Combine(dataDirectoryPath, "input.tif");
            cyrillicInputFilePath = Path.Combine(dataDirectoryPath, "тест.tif");
        }

        [Fact]
        public void LatinSymbols_YES_OptionDefault()
        {
            Gdal.SetConfigOption("GDAL_FILENAME_IS_UTF8", "YES");

            var currentState = Gdal.GetConfigOption("GDAL_FILENAME_IS_UTF8", "YES");

            _outputHelper.WriteLine($"Test 1 - GDAL_FILENAME_IS_UTF8 is set to {currentState} by default");

            var outputFilePath = Path.Combine(dataDirectoryPath, "test1.vrt");
            Assert.True(RunTest(englishInputFilePath, dataDirectoryPath, outputFilePath));
        }

        [Fact]
        public void CyrillicSymbols_YES_OptionDefault()
        {
            Gdal.SetConfigOption("GDAL_FILENAME_IS_UTF8", "YES");

            var currentState = Gdal.GetConfigOption("GDAL_FILENAME_IS_UTF8", "YES");

            _outputHelper.WriteLine($"Test 2 - GDAL_FILENAME_IS_UTF8 is set to {currentState} before the test");

            var outputFilePath = Path.Combine(dataDirectoryPath, "test2.vrt");
            Assert.True(RunTest(cyrillicInputFilePath, dataDirectoryPath, outputFilePath));
        }

        [Fact]
        public void LatinSymbols_NO_Option()
        {
            Gdal.SetConfigOption("GDAL_FILENAME_IS_UTF8", "NO");

            var currentState = Gdal.GetConfigOption("GDAL_FILENAME_IS_UTF8", "YES");

            _outputHelper.WriteLine($"Test 3 - GDAL_FILENAME_IS_UTF8 is set to {currentState} before the test");

            var outputFilePath = Path.Combine(dataDirectoryPath, "test3.vrt");
            Assert.True(RunTest(englishInputFilePath, dataDirectoryPath, outputFilePath));
        }

        [Fact]
        public void CyrillicSymbols_NO_Option()
        {
            Gdal.SetConfigOption("GDAL_FILENAME_IS_UTF8", "NO");

            var currentState = Gdal.GetConfigOption("GDAL_FILENAME_IS_UTF8", "YES");

            _outputHelper.WriteLine($"Test 4 - GDAL_FILENAME_IS_UTF8 is set to {currentState} before the test");

            var outputFilePath = Path.Combine(dataDirectoryPath, "test4.vrt");

            var result = RunTest(cyrillicInputFilePath, dataDirectoryPath, outputFilePath);

            // this works like a charm on linux even without config flag
            if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                Assert.True(result);
            }

            // windows can't find a file though
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                Assert.False(result);
            }
            else
            {
                throw new XunitException("This test was not created for current os platform");
            }
        }

        [Fact]
        public void GdalDataFolderIsSet()
        {
            var gdalDataFolder = Gdal.GetConfigOption("GDAL_DATA", null);
            Assert.NotNull(gdalDataFolder);
            Assert.True(Directory.Exists(gdalDataFolder));
        }

        private bool GdalBuildVrt(string[] inputFilesPaths, string outputFilePath, string[] options, Gdal.GDALProgressFuncDelegate callback)
        {
            try
            {
                using var result = Gdal.wrapper_GDALBuildVRT_names(outputFilePath, inputFilesPaths, new GDALBuildVRTOptions(options), callback, null);
            }
            catch (Exception exception)
            {
                _outputHelper.WriteLine(exception.Message);

                return false;
            }

            return true;
        }

        private bool OpenDataset(string inputFilePath)
        {
            try
            {
                using var inputDataset = Gdal.Open(inputFilePath, Access.GA_ReadOnly);
            }
            catch (Exception exception)
            {
                _outputHelper.WriteLine(exception.Message);

                return false;
            }

            return true;
        }

        private bool RunTest(string inputFilePath, string inputDirectoryPath, string outputFilePath)
        {
            var isTestSuccessful = OpenDataset(inputFilePath);

            var inputFilesPaths = new DirectoryInfo(inputDirectoryPath)
                                      .EnumerateFiles().Select(fileInfo => fileInfo.FullName).ToArray();
            if (!GdalBuildVrt(inputFilesPaths, outputFilePath, null, null))
            {
                _outputHelper.WriteLine($"GdalBuildVrt error on processing {inputFilesPaths} to {outputFilePath}");
                isTestSuccessful = false;
            }
            // Check if .vrt file was created, because GdalBuildVrt doesn't throw exceptions in that case
            if (!File.Exists(outputFilePath))
            {
                _outputHelper.WriteLine($"File not found {outputFilePath}");
                isTestSuccessful = false;
            }

            return isTestSuccessful;
        }
    }
}