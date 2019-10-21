using MaxRev.Gdal.Core;
using OSGeo.GDAL;
using OSGeo.OSR;
using System;

namespace GdalCoreTest
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                Console.WriteLine("Trying to configure all twice");
                GdalBase.ConfigureAll();
                GdalBase.ConfigureAll();
                Console.WriteLine("GDAL configured");

                Console.WriteLine(string.Join('\n',
                    "GDAL Version: " + Gdal.VersionInfo("RELEASE_NAME"),
                    "GDAL INFO: " + Gdal.VersionInfo("")));
                var spatialReference = new SpatialReference(null);
                spatialReference.SetWellKnownGeogCS("wgs84");

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
