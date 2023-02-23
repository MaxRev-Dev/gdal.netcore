using System.IO;
using System.Linq;

#nullable enable

namespace MaxRev.Gdal.Core
{
    /// <summary>
    /// Configures all variables and options for GDAL including plugins and proj.db path
    /// </summary>
    public static class GdalBase
    {
        /// <summary>
        /// Shows if gdal is already initialized.
        /// </summary>
        public static bool IsConfigured { get; private set; }

        /// <summary>
        /// Performs search for gdalplugins and calls 
        /// <see cref="OSGeo.GDAL.Gdal.AllRegister"/> and <see cref="OSGeo.OGR.Ogr.RegisterAll"/>
        /// <param name="gdalDataFolder">path to set as GDAL_DATA option</param>
        /// </summary>
        public static void ConfigureGdalDrivers(string? gdalDataFolder = null)
        {
            if (IsConfigured) return;

            OSGeo.GDAL.Gdal.AllRegister();
            OSGeo.OGR.Ogr.RegisterAll();

            ConfigureGdalData(gdalDataFolder);
            // set flag only on success
            IsConfigured = true;
        }

        /// <summary>
        /// Set path for GDAL_DATA option.
        /// </summary>
        /// <param name="gdalDataFolder"></param>
        public static void ConfigureGdalData(string? gdalDataFolder = null)
        {
            if (gdalDataFolder is null)
            {
                var runtimes = $"runtimes/any-x64/native";
                var helperLocations = GdalBaseExtensions.GetPackageDataPossibleLocations(runtimes, "gdal-data");
                gdalDataFolder = helperLocations.FirstOrDefault(Directory.Exists);
            }
            OSGeo.GDAL.Gdal.SetConfigOption("GDAL_DATA", gdalDataFolder);
        }

        /// <summary>
        /// Calls <see cref="ConfigureGdalDrivers"/> and <see cref="Proj.Configure"/>
        /// </summary> 
        public static void ConfigureAll()
        {
            if (IsConfigured) return;

            ConfigureGdalDrivers();

            Proj.Configure();
        }
    }
}
