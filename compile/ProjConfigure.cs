#nullable enable
using System;
using System.IO;
using System.Reflection;
using System.Linq;

namespace MaxRev.Gdal.Core
{
    /// <summary>
    ///  Configurator for Proj. Use with <see cref="OSGeo.OGR.Ogr.RegisterAll"/> 
    /// </summary>
    public static class Proj
    {
        /// <summary>
        /// Performs search for proj.db in project directories and sets search paths for Proj. <br/>
        /// If the proj.db exists in user directory, it will be used. Otherwise, the first found proj.db will be used.
        /// <para>
        /// Search order: <br/>
        /// - User defined paths <br/>
        /// - Executable directory (current working directory) <br/>
        /// - Entry assembly directory  
        /// - runtimes/&lt;platform&gt;/native/ directory
        /// </para> 
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
                var possibleLocations = additionalSearchPaths.Concat(new[]
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

                    // These cases are last hope solutions: 
                    // some environments may have flat structure
                    // let's try to search in root directories
                    entryRoot,
                    executingRoot,
                    runtimes,
                    libshared,
                }).Select(x => new DirectoryInfo(x).FullName).ToArray();

                string? found = default;

                foreach (var item in possibleLocations)
                {
                    if (!Directory.Exists(item))
                        continue;
                    var search = Directory.EnumerateFiles(item, "proj.db");
                    if (!search.Any())
                        continue;
                    found = item;
                    break;
                }

                if (found is null)
                {
                    // we did not find anything
                    throw new FileNotFoundException(
                        $"Can not find proj.db. Tried to search in {string.Join(", ", possibleLocations)}");
                }

                // as we search in the user defined paths first 
                // there will be always proj.db from a user defined path 
                // other proj grid files will be searched in additional directories
                OSGeo.OSR.Osr.SetPROJSearchPaths(new[] { found }.Concat(additionalSearchPaths).Distinct().ToArray());
            }
            catch (Exception ex) when (ex is not FileNotFoundException)
            {
                Console.WriteLine($"Failed to configure PROJ search paths. {ex.GetType().Name} was thrown");
                Console.WriteLine(ex.Message);
            }
        }
    }
}
