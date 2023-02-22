#nullable enable
using System;
using System.IO;
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

            try
            {
                var runtimes = $"runtimes/{GdalBaseExtensions.GetEnvRID()}/native";
                var helperLocations = GdalBaseExtensions.GetPackageDataPossibleLocations(runtimes, libshared);
                var possibleLocations = additionalSearchPaths.Concat(helperLocations).Distinct().ToArray();

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
