using System;
using System.IO;
using System.Reflection;
using System.Linq;
using System.Runtime.InteropServices;
using OSGeo.OGR;

namespace MaxRev.Gdal.Core
{
    /// <summary>
    /// Configures all variables and options for GDAL including plugins and Proj6.db path
    /// </summary>
    public static class GdalBase
    {
        /// <summary>
        /// Setups gdalplugins and calls Gdal.AllRegister(), Ogr.RegisterAll(), Proj6.Configure().
        /// NOTE: on Windows runtime on Debug it must copy dependent drivers to entry directory 
        /// </summary>
        public static void ConfigureAll()
        {
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
                    string name;

                    if (!assemblyDir.EnumerateFiles("gdal_*.dll").Any())
                    {
                        var t = assemblyDir.Parent.Parent.FullName;
                        var tmp = Path.Combine(t, "runtimes", "win-x64", "native");

                        void CopyAll(DirectoryInfo source, DirectoryInfo target)
                        {
                            Directory.CreateDirectory(target.FullName);

                            foreach (var fi in source.GetFiles())
                            {
                                fi.CopyTo(Path.Combine(target.FullName, fi.Name), true);
                            }

                            foreach (var diSourceSubDir in source.GetDirectories())
                            {
                                CopyAll(diSourceSubDir, target.CreateSubdirectory(diSourceSubDir.Name));
                            }
                        }

                        CopyAll(new DirectoryInfo(tmp), new DirectoryInfo(Directory.GetCurrentDirectory()));
                        name = Path.Combine(Directory.GetCurrentDirectory(), "gdalplugins");
                    }
                    else
                    {
                        var fi = new FileInfo(Assembly.GetEntryAssembly().Location);
                        var drs = fi.Directory.GetFiles("gdal_*.dll").Where(x => !x.Name.Contains("wrap"));
                        Directory.CreateDirectory("gdalplugins");
                        foreach (var dr in drs)
                        {
                            File.Copy(dr.FullName, Path.Combine("gdalplugins", dr.Name), true);
                        }

                        name = Path.Combine(Directory.GetCurrentDirectory(), "gdalplugins");
                    }

                    OSGeo.GDAL.Gdal.SetConfigOption("GDAL_DRIVER_PATH", name);
                }

                OSGeo.GDAL.Gdal.AllRegister();
                Ogr.RegisterAll();
                Proj6.Configure();
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error in " + Assembly.GetExecutingAssembly().FullName);
                Console.WriteLine(ex);
            }
        }
    }
}
