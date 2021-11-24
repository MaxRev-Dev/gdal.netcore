using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;

namespace MaxRev.Gdal.Core
{
    /// <summary>
    /// Configures all variables and options for GDAL including plugins and proj.db path
    /// </summary>
    public static class GdalBase
    {
        /// <summary>
        /// Shows if gdal is already initialized.
        /// </summary>
        public static bool IsConfigured { get; private set; }

        /// <summary>
        /// Performs search for gdalplugins and calls <see cref="OSGeo.GDAL.Gdal.AllRegister"/> and <see cref="OSGeo.OGR.Ogr.RegisterAll"/>
        /// </summary>
        public static void ConfigureGdalDrivers()
        {
            if (IsConfigured) return;

            var thisName = Assembly.GetExecutingAssembly().FullName;

            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                Assembly asm;

                try
                {
                    asm = Assembly.Load(new AssemblyName("MaxRev.Gdal.WindowsRuntime.Minimal"));
                }
                catch (Exception)
                {
                    Console.WriteLine("Couldn't find 'MaxRev.Gdal.WindowsRuntime.Minimal'" +
                        " assembly in loaded assemblies of current domain. Is it installed?");
                    Console.WriteLine("Failed to configure Gdal for windows runtime");
                    return;
                }

                try
                {
                    var asmLocation = asm.GetSourceLocation();
                    var assemblyDir = new FileInfo(asmLocation).Directory!;

                    // workaround on https://github.com/MaxRev-Dev/gdal.netcore/issues/40 for non-.NET caller dlls 
                    var asmEntry = Assembly.GetEntryAssembly() ??
                                    Assembly.GetCallingAssembly();

                    // assembly location can be empty with bundled assemblies
                    var executingDir = new FileInfo(asmEntry.GetSourceLocation()).Directory!;

                    var targetDir = new DirectoryInfo(Path.Combine(executingDir.FullName));

                    string finalDriversPath = null!;

                    if (!assemblyDir.EnumerateFiles("gdal_*.dll").Any())
                    {
                        finalDriversPath = TryFindDriversInPackages(assemblyDir, executingDir);
                    }
                    else
                    {
                        finalDriversPath = TryFindDriversInExecutingDirectory(executingDir, targetDir);
                    }

                    if (finalDriversPath != null)
                    {
                        OSGeo.GDAL.Gdal.SetConfigOption("GDAL_DRIVER_PATH", finalDriversPath);
                    }
                    else
                    {
                        Console.WriteLine($"{thisName}: Can't find runtime libraries");
                        return;
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Error in " + thisName);
                    Console.WriteLine(ex);
                    throw;
                }
            }

            OSGeo.GDAL.Gdal.AllRegister();
            OSGeo.OGR.Ogr.RegisterAll();

            // set flag only on success
            IsConfigured = true;
        }

        private static string TryFindDriversInExecutingDirectory(DirectoryInfo executingDir, DirectoryInfo targetDir)
        {
            var drs = executingDir.EnumerateFiles("gdal_*.dll").Where(x => !x.Name.Contains("wrap"));
            var targetDrivers = Path.Combine(targetDir.FullName, "gdalplugins");
            bool hasDirectory = false;
            try
            {
                Directory.CreateDirectory(targetDrivers);
                hasDirectory = true;
            }
            catch (UnauthorizedAccessException)
            {
                Console.WriteLine("The directory is not writable to move drivers.");
                Console.WriteLine("Gdal by default searches for gdalplugins/{driverName}.dll");
            }

            if (!hasDirectory)
                return null;

            foreach (var dr in drs)
            {
                var dest = Path.Combine(targetDrivers, dr.Name);
                if (File.Exists(dest)) File.Delete(dest);
                File.Copy(dr.FullName, dest, true);
            }
            return targetDrivers;
        }

        private static string TryFindDriversInPackages(DirectoryInfo assemblyDir, DirectoryInfo executingDir)
        {
            static string Sources(string s) => Path.Combine(s, "runtimes", GdalBaseExtensions.GetEnvRID(), "native");

            var originDir = new DirectoryInfo(Sources(assemblyDir.FullName));
            if (!originDir.Exists)
            {
                var primarySource = assemblyDir.Parent!.Parent!.FullName;
                originDir = new DirectoryInfo(Sources(primarySource));
                if (!originDir.Exists)
                {
                    originDir = new DirectoryInfo(Sources(executingDir.FullName));
                }
            }

            if (!originDir.Exists)
                return null;
                
            var targetDrivers = Path.Combine(originDir.FullName, "gdalplugins");
            // here hdf4 driver requires jpeg library to be loaded
            // and I won't copy all libraries on each startup
            var targetJpeg = Path.Combine(executingDir.FullName, "jpeg.dll");
            var sourceJpeg = Path.Combine(originDir.FullName, "jpeg.dll");
            try
            {
                if (!File.Exists(targetJpeg) && File.Exists(sourceJpeg))
                {
                    File.Copy(sourceJpeg, Path.Combine(executingDir.FullName, "jpeg.dll"));
                }
            }
            catch (UnauthorizedAccessException)
            {
                Console.WriteLine("Can't move jpeg driver. " +
                    "It should be in location relative to the executable e.g. gdalplugins/jpeg.dll");
            }
            return targetDrivers;
        }

        /// <summary>
        /// Calls <see cref="ConfigureGdalDrivers"/> and <see cref="Proj.Configure"/>
        /// </summary> 
        public static void ConfigureAll()
        {
            if (IsConfigured) return;

            ConfigureGdalDrivers();

            Proj.Configure();
        }
    }
}
