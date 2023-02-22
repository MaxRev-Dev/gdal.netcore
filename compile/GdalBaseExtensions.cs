using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;

namespace MaxRev.Gdal.Core
{
    internal static class GdalBaseExtensions
    {
        internal static string GetSourceLocation(this Assembly asm)
        {
            return !string.IsNullOrEmpty(asm.Location) ? asm.Location : AppContext.BaseDirectory;
        }

        internal static string GetEnvRID()
        {
            return Environment.OSVersion.Platform switch
            {
                PlatformID.Unix => "linux-x64",
                PlatformID.Win32NT => "win-x64",
                _ => throw new PlatformNotSupportedException(),
            };
        } 
        
        internal static IEnumerable<string> GetPackageDataPossibleLocations(string runtimesPath, string libsharedFolder)
        {
            var entryAsm = Assembly.GetEntryAssembly() ?? Assembly.GetCallingAssembly();
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
            return new[]
            {
                // test runner use this and docker containers
                Path.Combine(executingRoot, runtimesPath, libsharedFolder),
                Path.Combine(executingRoot, libsharedFolder),
                // self-contained published package 
                // with custom working directory
                Path.Combine(entryRoot, runtimesPath, libsharedFolder),
                Path.Combine(entryRoot, libsharedFolder),

                // azure functions
                Path.Combine(executingRoot, "..", runtimesPath, libsharedFolder),

                // These cases are last hope solutions: 
                // some environments may have flat structure
                // let's try to search in root directories
                entryRoot,
                executingRoot,
                runtimesPath,
                libsharedFolder,
            }.Select(x => new DirectoryInfo(x).FullName);
        }
    }
}