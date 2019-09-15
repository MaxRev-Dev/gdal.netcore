using System;
using System.Diagnostics;
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
#if DEBUG
            Debugger.Launch();
#endif
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
                    var targetDir = new DirectoryInfo(Path.Combine(executingDir.FullName, "gdalplugins"));

                    targetDir.Create();

                    string name = targetDir.FullName;
                    if (!assemblyDir.EnumerateFiles("gdal_*.dll").Any())
                    {
                        Func<string, string> sources = s => Path.Combine(s, "runtimes", "win-x64", "native");
                        var cdir = new DirectoryInfo(sources(assemblyDir.FullName));
                        if (!cdir.Exists)
                        {
                            var primarySource = assemblyDir.Parent.Parent.FullName;
                            cdir = new DirectoryInfo(sources(primarySource));
                            if (!cdir.Exists)
                            {
                                cdir = new DirectoryInfo(sources(executingDir.FullName));
                            }
                        }

                        if (cdir.Exists)
                        {
                            CopyAll(cdir, targetDir);
                        }
                        else
                        {
                            Console.WriteLine(thisName + ": Can't find runtime libraries");
                        }

                        void CopyAll(DirectoryInfo fromDir, DirectoryInfo target)
                        {
                            Directory.CreateDirectory(target.FullName);

                            foreach (var fi in fromDir.GetFiles())
                            {
                                fi.CopyTo(Path.Combine(target.FullName, fi.Name), true);
                            }

                            foreach (var diSourceSubDir in fromDir.GetDirectories())
                            {
                                CopyAll(diSourceSubDir, target.CreateSubdirectory(diSourceSubDir.Name));
                            }
                        }

                    }
                    else
                    { 
                        var drs = executingDir.GetFiles("gdal_*.dll").Where(x => !x.Name.Contains("wrap"));

                        foreach (var dr in drs)
                        {
                            File.Copy(dr.FullName, Path.Combine(targetDir.FullName, dr.Name), true);
                        }
                    }

                    OSGeo.GDAL.Gdal.SetConfigOption("GDAL_DRIVER_PATH", name);
                }

                OSGeo.GDAL.Gdal.AllRegister();
                Ogr.RegisterAll();
                Proj6.Configure();
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error in " + thisName);
                Console.WriteLine(ex);
            }
        }
    }
}
