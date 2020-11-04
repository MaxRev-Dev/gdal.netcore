using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;

namespace MaxRev.Gdal.Core
{
    /// <summary>
    /// Configures all variables and options for GDAL including plugins and Proj6.db path
    /// </summary>
    public static class GdalBase
    {
        /// <summary>
        /// Shows if gdal is already initialized.
        /// </summary>
        public static bool IsConfigured { get; private set; }

        /// <summary>
        /// Setups gdalplugins and calls Gdal.AllRegister(), Ogr.RegisterAll(), Proj6.Configure(). 
        /// </summary>
        public static void ConfigureAll()
        {
            if (IsConfigured) return;

            var thisName = Assembly.GetExecutingAssembly().FullName;
            try
            {
                if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                {
                    Assembly asm;
                    try
                    {
                        asm = Assembly.Load(new AssemblyName("MaxRev.Gdal.WindowsRuntime.Minimal"));
                    }
                    catch (Exception)
                    {
                        Console.WriteLine("Couldn't find 'MaxRev.Gdal.Core.Windows' assembly in loaded assemblies of current domain. Is it installed?");
                        Console.WriteLine("Failed to configure Gdal for windows runtime");
                        return;
                    }

                    var asmLocation = asm.Location;
                    var assemblyDir = new FileInfo(asmLocation).Directory;

                    var executingDir = new FileInfo(Assembly.GetEntryAssembly().Location).Directory;
                    var targetDir = new DirectoryInfo(Path.Combine(executingDir.FullName));
                    targetDir.Create();


                    if (!assemblyDir.EnumerateFiles("gdal_*.dll").Any())
                    {
                        string Sources(string s) => Path.Combine(s, "runtimes", "win-x64", "native");
                        var cdir = new DirectoryInfo(Sources(assemblyDir.FullName));
                        if (!cdir.Exists)
                        {
                            var primarySource = assemblyDir.Parent.Parent.FullName;
                            cdir = new DirectoryInfo(Sources(primarySource));
                            if (!cdir.Exists)
                            {
                                cdir = new DirectoryInfo(Sources(executingDir.FullName));
                            }
                        }

                        if (cdir.Exists)
                        {
                            var targetDrivers = Path.Combine(cdir.FullName, "gdalplugins");
                            // here hdf4 driver requires jpeg library to be loaded
                            // and I won't copy all libraries on each startup
                            var targetJpeg = Path.Combine(executingDir.FullName, "jpeg.dll");
							var sourceJpeg = Path.Combine(cdir.FullName, "jpeg.dll");
                            if (!File.Exists(targetJpeg) &&File.Exists(sourceJpeg))
                            {
                                File.Copy(sourceJpeg, Path.Combine(executingDir.FullName, "jpeg.dll"));
                            }

                            OSGeo.GDAL.Gdal.SetConfigOption("GDAL_DRIVER_PATH", targetDrivers);
                        }
                        else
                        {
                            Console.WriteLine($"{thisName}: Can't find runtime libraries");
                        }
                    }
                    else
                    {
                        var drs = executingDir.EnumerateFiles("gdal_*.dll").Where(x => !x.Name.Contains("wrap"));
                        var tr = Path.Combine(targetDir.FullName, "gdalplugins");
                        Directory.CreateDirectory(tr);
                        foreach (var dr in drs)
                        {
                            var dest = Path.Combine(tr, dr.Name);
                            if (File.Exists(dest)) File.Delete(dest);
                            File.Copy(dr.FullName, dest, true);
                        }
                        OSGeo.GDAL.Gdal.SetConfigOption("GDAL_DRIVER_PATH", tr);
                    }
                }

                OSGeo.GDAL.Gdal.AllRegister();
                OSGeo.OGR.Ogr.RegisterAll();
                Proj6.Configure();
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error in " + thisName);
                Console.WriteLine(ex);
                throw;
            }

            IsConfigured = true;
        }
    }
}
