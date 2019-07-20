using System;
using System.IO;
using System.Reflection;
using System.Linq;
using System.Runtime.CompilerServices;

namespace MaxRev.Gdal.Core
{
    /// <summary>
    /// Configures all variables and options for gdal including plugins and Proj6.db path
    /// </summary>
    public static class GdalBase
    {
        /// <summary>
        /// Setups gdalplugins and calls Gdal.AllRegister() & Ogr.RegisterAll() & Proj6.Configure()
        /// </summary>
        public static void ConfigureAll()
        {
            try
            {
                var loc = Assembly.GetAssembly(typeof(InternalGdalBaseMarker)).Location;
                var gj = new FileInfo(loc).Directory;
                var name = gj.FullName;

                if (!gj.EnumerateFiles("gdal_*.dll").Any())
                {
                    var t = gj.Parent.Parent.FullName;
                    name = Path.Combine(name, "runtimes", "win-x64", "native", "gdalplugins");
                }
                else
                {
                    var fi = new FileInfo(Assembly.GetEntryAssembly().Location);
                    var drs = fi.Directory.GetFiles("gdal_*.dll").Where(x => !x.Name.Contains("wrap"));
                    Directory.CreateDirectory("gdalplugins");
                    foreach (var dr in drs)
                    {
                        File.Move(dr.FullName, Path.Combine("gdalplugins", dr.Name));
                    }

                    name = Path.Combine(Directory.GetCurrentDirectory(), "gdalplugins");
                }

                Gdal.SetConfigOption("GDAL_DRIVER_PATH", name);
                Gdal.AllRegister();
                Ogr.RegisterAll();
                Proj6.Configure();
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex);
            }
        }
    }
}