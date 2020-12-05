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
                var projectLocation = Assembly.GetAssembly(typeof(OSGeo.OSR.Osr)).Location;
                var projectRoot = new FileInfo(projectLocation).Directory;
                var libshared = "maxrev.gdal.core.libshared";

                // Possible locations of package contents 
                // [projectRoot]/runtimes/win-x64/native/[libshared]
                // [projectRoot]/bin/[cfg]/[libshared]

                string finalFolder;
                if (projectRoot!.GetDirectories().Any(x =>
                    string.Equals(x.Name, libshared, 
                        StringComparison.InvariantCultureIgnoreCase)))
                {
                    finalFolder = Path.Combine(projectRoot.FullName, libshared);
                }
                else
                {
                    var root = projectRoot.Parent!.Parent;
                    finalFolder = Path.Combine(root!.FullName, libshared);
                }

                // some environments may have flat structure
                // try search in root directory
                var outputRoot =
                    new FileInfo(Assembly.GetEntryAssembly()!.Location)
                        .Directory!.FullName;

                var inProjectFolder = Path.Combine(outputRoot, libshared);

                OSGeo.OSR.Osr.SetPROJSearchPaths(
                    new[] { finalFolder, outputRoot, inProjectFolder });
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Console.WriteLine("Can't find proj.db folder from package in project output directory");
            }
        }
    }
}