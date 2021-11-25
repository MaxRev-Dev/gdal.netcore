using System;
using System.IO;
using System.Linq;
using MaxRev.Gdal.Core;
using OSGeo.GDAL;
using Xunit;
using Xunit.Abstractions;

namespace GdalCore_XUnit
{

    [Collection("Sequential")]
    public class Utf8Tests
    {
        private readonly ITestOutputHelper _outputHelper;
        private string dataDirectoryPath;
        private string englishInputFilePath;
        private string cyrillicInputFilePath;

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

            string currentState = Gdal.GetConfigOption("GDAL_FILENAME_IS_UTF8", "YES"); 

            _outputHelper.WriteLine($"Test 1 - GDAL_FILENAME_IS_UTF8 is set to {currentState} by default");

            var outputFilePath = Path.Combine(dataDirectoryPath, "test1.vrt");
            Assert.True(RunTest(englishInputFilePath, dataDirectoryPath, outputFilePath));
        }

        [Fact]
        public void CyrillicSymbols_YES_OptionDefault()
        {
            Gdal.SetConfigOption("GDAL_FILENAME_IS_UTF8", "YES");

            string currentState = Gdal.GetConfigOption("GDAL_FILENAME_IS_UTF8", "YES");

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
            Assert.False(RunTest(cyrillicInputFilePath, dataDirectoryPath, outputFilePath));
        }

        private bool GdalBuildVrt(string[] inputFilesPaths, string outputFilePath, string[] options, Gdal.GDALProgressFuncDelegate callback)
        {
            try
            {
                using Dataset result = Gdal.wrapper_GDALBuildVRT_names(outputFilePath, inputFilesPaths, new GDALBuildVRTOptions(options), callback, null);
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
                using Dataset inputDataset = Gdal.Open(inputFilePath, Access.GA_ReadOnly);
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
            bool isTestSuccessful = OpenDataset(inputFilePath);

            string[] inputFilesPaths = new DirectoryInfo(inputDirectoryPath)
                                      .EnumerateFiles().Select(fileInfo => fileInfo.FullName).ToArray();
            if (!GdalBuildVrt(inputFilesPaths, outputFilePath, null, null))
                isTestSuccessful = false;

            // Check if .vrt file was created, because GdalBuildVrt doesn't throw exceptions in that case
            if (!File.Exists(outputFilePath))
                isTestSuccessful = false;

            return isTestSuccessful;
        }
    }
}