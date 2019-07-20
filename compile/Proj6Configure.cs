using System;
using System.IO;
using System.Reflection;
using System.Linq;

namespace MaxRev.Gdal.Core
{

    /// <summary>
    ///  Configurator for Proj6. Use with <see cref="OSGeo.OGR.Ogr.RegisterAll"/> 
    /// </summary>
    public static class Proj6
    {
        /// <summary>
        ///  Configures Proj6 search paths 
        /// </summary>
        public static void Configure()
        {
            try
            {
                var h = Assembly.GetAssembly(typeof(OSGeo.OSR.Osr)).Location;
                var di = new FileInfo(h).Directory;
                var sh = "maxrev.gdal.core.libshared";
                string f = default;
                if (di.GetDirectories().Any(x => x.Name == sh))
                {
                    f = Path.Combine(di.FullName, sh);
                }
                else
                {
                    var root = di.Parent.Parent;
                    f = Path.Combine(root.FullName, sh);
                }

                var e = Path.Combine(new FileInfo(Assembly.GetEntryAssembly().Location).Directory.FullName, sh);
                OSGeo.OSR.Osr.SetPROJSearchPaths(new[] { f, e });
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Console.WriteLine("Can't find proj.db folder from package in project output directory");
            }
        }
    }
}