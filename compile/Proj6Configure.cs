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
				string rid;
				switch (Environment.OSVersion.Platform)
				{
					case PlatformID.MacOSX:
						rid = "osx-x64";
						break;
					case PlatformID.Unix:
						rid = "linux-x64";
						break;
					case PlatformID.Win32NT:
						rid = "win-x64";
						break;
					default:
						throw new PlatformNotSupportedException();
				}

				const string libshared = "maxrev.gdal.core.libshared";
				var runtimes = $"runtimes/{rid}/native";

				var entryRoot =
					new FileInfo(Assembly.GetEntryAssembly()!.Location)
						.Directory!.FullName;
				var executingRoot =
					new FileInfo(Assembly.GetExecutingAssembly()!.Location)
						.Directory!.FullName;

                // this list is sorted according to expected 
                // contents location related to
                // published binaries location
				var possibleLocations = new[] {
                    // test runner use this and docker containers
					Path.Combine(executingRoot, runtimes, libshared),
					Path.Combine(executingRoot, libshared),
                    // self-contained published package 
                    // with custom working directory
					Path.Combine(entryRoot, runtimes, libshared),
					Path.Combine(entryRoot, libshared),

                    // These cases are last hope solututions: 
                    // some environments may have flat structure
                    // let's try to search in root directories
					entryRoot,
					executingRoot,
					runtimes,
					libshared,
				}.Select(x => new DirectoryInfo(x).FullName);
				string found = default;
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
				if (found != default)
					OSGeo.OSR.Osr.SetPROJSearchPaths(new[] { found });
				else
				{
					throw new FileNotFoundException($"Can't find proj.db. Tried to search in {string.Join(", ", possibleLocations)}");
				}
			}
			catch (FileNotFoundException) { throw; }
			catch (Exception ex)
			{
				Console.WriteLine("Failed to configure PROJ search paths");
				Console.WriteLine(ex.Message);
			}
		}
	}
}