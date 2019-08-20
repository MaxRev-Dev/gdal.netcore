using System;
using MaxRev.Gdal.Core;
using OSGeo.GDAL;

namespace GdalCoreTest
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                GdalBase.ConfigureAll();

                Console.WriteLine(string.Join('\n', 
                    "GDAL Version: " + Gdal.VersionInfo("RELEASE_NAME"),
                    "GDAL INFO: " + Gdal.VersionInfo("")));

                var drivers = new[] { "hdf4", "hdf5", "gtiff", "hf2", "ceos", "ESRI Shapefile" };

                foreach (var driver in drivers)
                {
                    var driverByName = Gdal.GetDriverByName(driver);
                    Console.WriteLine(
                        driverByName != default ? $"{driver} loaded successfully" : $"Failed to load {driver}");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex);
            } 
        }
    }
}
