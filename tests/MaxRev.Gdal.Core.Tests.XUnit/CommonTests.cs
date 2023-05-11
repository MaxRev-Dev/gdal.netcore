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

        public static IEnumerable<object[]> DriversInCurrentVersion
        {
            get
            {
                return new[]
                {
                   "AAIGrid","ACE2","ADRG","AIG","AirSAR","AmigoCloud","ARG",
                   "AVCBin","AVCE00","BAG","BIGGIF","BLX","BMP","BSB","BT",
                   "BYN","CAD","CALS","Carto","CEOS","COASP","COG","COSAR",
                   "CPG","CSV","CSW","CTable2","CTG","DAAS","DERIVED","DGN",
                   "DIMAP","DIPEx","DOQ1","DOQ2","DTED","DXF","ECRGTOC","EDIGEO",
                   "EEDA","EEDAI","EHdr","EIR","ELAS","Elasticsearch","ENVI","ERS",
                   "ESAT","ESRI Shapefile","ESRIC","ESRIJSON","FAST","FIT","FITS",
                   "FlatGeobuf","GenBin","Geoconcept","GeoJSON","GeoJSONSeq","GeoRSS",
                   "GFF","GIF","GML","GMLAS","GNMDatabase","GNMFile","GPKG","GPSBabel",
                   "GPX","GRASSASCIIGrid","GRIB","GS7BG","GSAG","GSBG","GSC","GTFS","GTiff",
                   "GTX","GXF","HDF4","HDF4Image","HDF5","HDF5Image","HF2","HFA",
                   "HTTP","Idrisi","ILWIS","Interlis 1","Interlis 2","IRIS","ISCE",
                   "ISG","ISIS2","ISIS3","JAXAPALSAR","JDEM","JML","JP2OpenJPEG",
                   "JPEG","KML","KMLSUPEROVERLAY","KRO","L1B","LAN","LCP","Leveller",
                   "LIBKML","LOSLAS","LVBAG","MAP","MapInfo File","MapML","MBTiles",
                   "MEM","Memory","MFF","MFF2","MRF","MSGN","MSSQLSpatial","MVT",
                   "MySQL","NAS","NDF","netCDF","NGSGEOID","NGW","NITF","NOAA_B",
                   "NSIDCbin","NTv2","NWT_GRC","NWT_GRD","OAPIF","ODBC","ODS","OGCAPI","OGR_GMT",
                   "OGR_PDS","OGR_SDTS","OGR_VRT","OpenFileGDB","OSM","OZI","PAux",
                   "PCIDSK","PCRaster","PDF","PDS","PDS4","PGDUMP","PGeo","PLMOSAIC",
                   "PLSCENES","PNG","PNM","PostGISRaster","PostgreSQL","PRF","R",
                   "Rasterlite","RIK","RMF","ROI_PAC","RPFTOC","RRASTER","RS2","RST",
                   "S57","SAFE","SAGA","SAR_CEOS","SDTS","Selafin","SENTINEL2","SGI",
                   "SIGDEM","SNODAS","SQLite","SRP","SRTMHGT","STACIT","STACTA","SVG",
                   "SXF","Terragen","TGA","TIGER","TIL","TopoJSON","TSX","UK .NTF",
                   "USGSDEM","VDV","VFK","VICAR","VRT","WAsP","WCS","WEBP","WFS",
                   "WMS","WMTS","XLS","XLSX","XPM","XYZ","Zarr","ZMap"
                }.Select(x => new[] { x });
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
