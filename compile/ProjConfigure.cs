using System;
using System.IO;
using System.Reflection;
using System.Linq;

namespace MaxRev.Gdal.Core
{
    [Obsolete]
    /// <summary>
    ///  Configurator for Proj. Use with <see cref="OSGeo.OGR.Ogr.RegisterAll"/> 
    /// </summary>
    public static class Proj6
    {

        [Obsolete]
        /// <summary>
        /// Performs search for proj.db in project directories and sets search paths for Proj. 
        /// You can call <see cref="OSGeo.OSR.Osr.SetPROJSearchPaths"/> alternatively.
        /// </summary>
        /// <param name="additionalSearchPaths">optional additional paths</param>
        public static void Configure(params string[] additionalSearchPaths)
        {
            Proj.Configure(additionalSearchPaths);
        }
    }

    /// <summary>
    ///  Configurator for Proj. Use with <see cref="OSGeo.OGR.Ogr.RegisterAll"/> 
    /// </summary>
    public static class Proj
    {
        /// <summary>
        /// Performs search for proj.db in project directories and sets search paths for Proj. 
        /// You can call <see cref="OSGeo.OSR.Osr.SetPROJSearchPaths"/> alternatively.
        /// </summary>
        /// <param name="additionalSearchPaths">optional additional paths</param>
        public static void Configure(params string[] additionalSearchPaths)
        {
            const string libshared = "maxrev.gdal.core.libshared";
            var runtimes = $"runtimes/{GdalBaseExtensions.GetEnvRID()}/native";
            var entryAsm = Assembly.GetEntryAssembly() ?? Assembly.GetCallingAssembly();

            try
            {
                // assembly location can be empty with bundled assemblies
                var entryRoot =
                    new FileInfo(entryAsm.GetSourceLocation())
                        .Directory!.FullName;

                var executingRoot =
                    new FileInfo(Assembly.GetExecutingAssembly().GetSourceLocation())
                        .Directory!.FullName;


                // this list is sorted according to expected 
                // contents location related to
                // published binaries location
                var possibleLocations = new[]
                {
                    // test runner use this and docker containers
                    Path.Combine(executingRoot, runtimes, libshared),
                    Path.Combine(executingRoot, libshared),
                    // self-contained published package 
                    // with custom working directory
                    Path.Combine(entryRoot, runtimes, libshared),
                    Path.Combine(entryRoot, libshared),

                    // azure functions
                    Path.Combine(executingRoot, "..", runtimes, libshared),

                    // These cases are last hope solututions: 
                    // some environments may have flat structure
                    // let's try to search in root directories
                    entryRoot,
                    executingRoot,
                    runtimes,
                    libshared,
                }.Select(x => new DirectoryInfo(x).FullName);

                string found = "";
                foreach (var item in possibleLocations)
                {
                    if (!Directory.Exists(item))
                        continue;
                    var search = Directory.EnumerateFiles(item, "proj.db");
                    if (search.Any())
                    {
                        found = item;
                        break;
                    }
                }

                if (found != "")
                {
                    OSGeo.OSR.Osr.SetPROJSearchPaths(new[] { found }.Concat(additionalSearchPaths).ToArray());
                    return;
                }

                // we did not found anything
                throw new FileNotFoundException($"Can't find proj.db. Tried to search in {string.Join(", ", possibleLocations)}");
            }
            catch (Exception ex) when (ex is not FileNotFoundException)
            {
                Console.WriteLine($"Failed to configure PROJ search paths. {ex.GetType().Name} was thrown");
                Console.WriteLine(ex.Message);
            }
        }
    }
}
