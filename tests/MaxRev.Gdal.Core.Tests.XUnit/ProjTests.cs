using MaxRev.Gdal.Core;
using OSGeo.OSR; 
using Xunit;

namespace GdalCore_XUnit
{
    public class ProjTests
    {
        [Fact]
        public void TransformPointIsOk()
        {
            var x = 826158.063;
            var y = 2405844.125;

            var sourceWkt =
                "PROJCS[\"OSGB_1936_British_National_Grid\",GEOGCS[\"GCS_OSGB 1936\",DATUM[\"D_OSGB_1936\",SPHEROID[\"Airy_1830\",6377563.396,299.3249646]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.017453292519943295]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",49],PARAMETER[\"central_meridian\",-2],PARAMETER[\"scale_factor\",0.9996012717],PARAMETER[\"false_easting\",400000],PARAMETER[\"false_northing\",-100000],UNIT[\"Meter\",1]]";
            var targetWkt =
                "PROJCS[\"ETRS89_LAEA_Europe\",GEOGCS[\"GCS_ETRS_1989\",DATUM[\"D_ETRS_1989\",SPHEROID[\"GRS_1980\",6378137,298.257222101]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.017453292519943295]],PROJECTION[\"Lambert_Azimuthal_Equal_Area\"],PARAMETER[\"latitude_of_origin\",52],PARAMETER[\"central_meridian\",10],PARAMETER[\"false_easting\",4321000],PARAMETER[\"false_northing\",3210000],UNIT[\"Meter\",1]]";

            Proj.Configure();

            var sourceSr = new SpatialReference(string.Empty);
            sourceSr.ImportFromWkt(ref sourceWkt);
            sourceSr.SetAxisMappingStrategy(AxisMappingStrategy.OAMS_TRADITIONAL_GIS_ORDER);

            var targetSr = new SpatialReference(string.Empty);
            targetSr.ImportFromWkt(ref targetWkt);
            targetSr.SetAxisMappingStrategy(AxisMappingStrategy.OAMS_TRADITIONAL_GIS_ORDER);
            
            var transformation = new CoordinateTransformation(sourceSr, targetSr); 

            var projected = new double[3];
            transformation.TransformPoint(projected, x, y, 0.0);
            var px = projected[0];
            var py = projected[1];

            var ex = 4316331.55;
            var ey = 5331101.98;
            Assert.Equal(ex, px, 0);
            Assert.Equal(ey, py, 0);
        }
    }
}