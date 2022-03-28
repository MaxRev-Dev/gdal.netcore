using System;
using System.Collections.Generic;
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
        /// Performs search for gdalplugins and calls 
        /// <see cref="OSGeo.GDAL.Gdal.AllRegister"/> and <see cref="OSGeo.OGR.Ogr.RegisterAll"/>
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
                    bool driversFound = false;

                    // if project output does not contain packages
                    // this could be a debug environment
                    if (!assemblyDir.EnumerateFiles("gdal_*.dll").Any())
                    {
                        if (TryFindDriversInPackages(assemblyDir, executingDir, out finalDriversPath))
                        {
                            driversFound = true;
                        }
                    }

                    if (!driversFound)
                    {
                        driversFound = TryFindDriversInExecutingDirectory(targetDir, executingDir, out finalDriversPath);
                    }

                    if (finalDriversPath != null)
                    {
                        OSGeo.GDAL.Gdal.SetConfigOption("GDAL_DRIVER_PATH", finalDriversPath);
                    }
                    else
                    {
                        Console.WriteLine($"{thisName}: Can't find GDAL driver libraries");
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

        private static bool TryFindDriversInExecutingDirectory
            (DirectoryInfo targetDir, DirectoryInfo executingDir, out string targetDrivers)
        {
            var drivers = executingDir.GetGdalPlugins();

            if (!drivers.Any())
            {
                throw new InvalidOperationException("Can't find drivers in executing directory.");
            }

            targetDrivers = Path.Combine(targetDir.FullName, "gdalplugins");
            
            // check if this folder is already populated with drivers
            var targetDirInfo = new DirectoryInfo(targetDrivers);
            if (!targetDirInfo.Exists ||
                !targetDirInfo.EnumerateFiles().Any())
            {
                MoveDriversTo(drivers, ref targetDrivers);
            }

            return true;
        }

        private static void MoveDriversTo(IEnumerable<FileInfo> drivers, ref string targetDrivers)
        {
            try
            {
                Directory.CreateDirectory(targetDrivers);
            }
            catch (UnauthorizedAccessException)
            {
                // create folder in a writable location
                targetDrivers = Path.Combine(Path.GetTempPath(), "gdalplugins");
                Directory.CreateDirectory(targetDrivers);
            }

            foreach (var driver in drivers)
            {
                var destDriverPath = Path.Combine(targetDrivers, driver.Name);
                if (File.Exists(destDriverPath)) File.Delete(destDriverPath);
                File.Copy(driver.FullName, destDriverPath, true);
            }
        }

        private static bool TryFindDriversInPackages
            (DirectoryInfo assemblyDir, DirectoryInfo executingDir, out string targetOrigin)
        {
            static string Sources(string s) => Path.Combine(s, "runtimes", GdalBaseExtensions.GetEnvRID(), "native");

            // origin directory is package root
            var originDir = new DirectoryInfo(Sources(assemblyDir.FullName));
            if (!originDir.Exists)
            {
                // search in nuget cache directory '{packageRoot}/lib/{tmf}/**'
                var primarySource = assemblyDir.Parent!.Parent!.FullName;
                originDir = new DirectoryInfo(Sources(primarySource));
            }

            // if nuget cache dir does not exists, weirdo but...
            if (!originDir.Exists)
            {
                // fallback to executing directory
                originDir = new DirectoryInfo(Sources(executingDir.FullName));
            }

            targetOrigin = Path.Combine(originDir.FullName, "gdalplugins");
            if (Directory.Exists(targetOrigin) && Directory.EnumerateFiles(targetOrigin).Any())
                return true;

            return false;
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
