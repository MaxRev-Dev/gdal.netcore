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
            var valid = geom.MakeValid();
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
                    "HDF4","HDF4Image","HDF5","HDF5Image","BAG","VRT","DERIVED","GTiff","COG",
                    "NITF","RPFTOC","ECRGTOC","HFA","SAR_CEOS","CEOS","JAXAPALSAR","GFF","ELAS",
                    "ESRIC","AIG","AAIGrid","GRASSASCIIGrid","ISG","SDTS","DTED","PNG","JPEG",
                    "MEM","JDEM","GIF","BIGGIF","ESAT","BSB","XPM","BMP","DIMAP","AirSAR","RS2",
                    "SAFE","PCIDSK","PCRaster","ILWIS","SGI","SRTMHGT","Leveller","Terragen",
                    "ISIS3","ISIS2","PDS","PDS4","VICAR","TIL","ERS","JP2OpenJPEG","L1B","FIT",
                    "GRIB","RMF","WCS","WMS","MSGN","RST","INGR","GSAG","GSBG","GS7BG","COSAR",
                    "TSX","COASP","R","MAP","KMLSUPEROVERLAY","PDF","Rasterlite","MBTiles",
                    "PLMOSAIC","CALS","WMTS","SENTINEL2","MRF","PNM","DOQ1","DOQ2","PAux",
                    "MFF","MFF2","FujiBAS","GSC","FAST","BT","LAN","CPG","IDA","NDF","EIR",
                    "DIPEx","LCP","GTX","LOSLAS","NTv2","CTable2","ACE2","SNODAS","KRO","ROI_PAC",
                    "RRASTER","BYN","ARG","RIK","USGSDEM","GXF","NWT_GRD","NWT_GRC","ADRG","SRP",
                    "BLX","PostGISRaster","SAGA","XYZ","HF2","OZI","CTG","ZMap","NGSGEOID","IRIS",
                    "PRF","RDA","EEDAI","EEDA","DAAS","SIGDEM","TGA","OGCAPI","STACTA","GNMFile",
                    "GNMDatabase","ESRI Shapefile","MapInfo File","UK .NTF","LVBAG","OGR_SDTS",
                    "S57","DGN","OGR_VRT","REC","Memory","CSV","NAS","GML","GPX","KML","GeoJSON","GeoJSONSeq",
                    "ESRIJSON","TopoJSON","OGR_GMT","GPKG","SQLite","ODBC","WAsP","PGeo","MSSQLSpatial",
                    "PostgreSQL","OpenFileGDB","DXF","CAD","FlatGeobuf","Geoconcept","GeoRSS","GPSTrackMaker",
                    "VFK","PGDUMP","OSM","GPSBabel","OGR_PDS","WFS","OAPIF","Geomedia","EDIGEO","SVG","CouchDB",
                    "Cloudant","Idrisi","ARCGEN","ODS","XLSX","Elasticsearch","Walk","Carto","AmigoCloud","SXF",
                    "Selafin","JML","PLSCENES","CSW","VDV","GMLAS","MVT","NGW","MapML","TIGER","AVCBin","AVCE00",
                    "GenBin","ENVI","EHdr","ISCE","HTTP"
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
