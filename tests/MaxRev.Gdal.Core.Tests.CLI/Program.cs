using MaxRev.Gdal.CLI;
using System.IO;
using System.Runtime.InteropServices;

namespace MaxRev.Gdal.Core.Tests.CLI
{
    internal static class Program
    {
        private static int Main()
        {
            try
            {
                Console.WriteLine($"Base directory: {AppContext.BaseDirectory}");
                Console.WriteLine($"OS: {RuntimeInformation.OSDescription}");
                Console.WriteLine($"Arch: {RuntimeInformation.OSArchitecture}");

                var runtimeNativeDir = GetRuntimeNativeDirectory(AppContext.BaseDirectory);
                if (!string.IsNullOrEmpty(runtimeNativeDir))
                {
                    Console.WriteLine($"Runtime native dir: {runtimeNativeDir}");
                }
                else
                {
                    Console.WriteLine("Runtime native dir: <not found>");
                }

                GdalCli.EnsureEnvironment();
                var toolsToCheck = new[] { "gdalinfo", "ogr2ogr", "gdal_translate" };
                foreach (var tool in toolsToCheck)
                {
                    Console.WriteLine($"Running {tool} --version");
                    var toolPath = GdalCli.GetToolPath(tool);
                    Console.WriteLine($"Tool path: {toolPath ?? "<not found>"}");
                    if (string.IsNullOrEmpty(toolPath))
                    {
                        return 1;
                    }
                    var exitCode = GdalCli.Run(tool, new[] { "--version" },
                        stdout: Console.Write,
                        stderr: Console.Error.Write);
                    if (exitCode != 0)
                    {
                        Console.Error.WriteLine($"{tool} failed with exit code {exitCode}");
                        return exitCode;
                    }
                }

                Console.WriteLine("gdalinfo executed successfully.");
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(ex);
                return 1;
            }
        }

        private static string? GetRuntimeNativeDirectory(string baseDir)
        {
            var runtimeBase = Path.Combine(baseDir, "runtimes");
            if (!Directory.Exists(runtimeBase))
            {
                return null;
            }

            string? rid = null;
            if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            {
                rid = RuntimeInformation.OSArchitecture == Architecture.Arm64 ? "osx-arm64" : "osx-x64";
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                rid = RuntimeInformation.OSArchitecture == Architecture.Arm64 ? "linux-arm64" : "linux-x64";
            }
            else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                rid = "win-x64";
            }

            if (string.IsNullOrEmpty(rid))
            {
                return null;
            }

            var nativeDir = Path.Combine(runtimeBase, rid, "native");
            return Directory.Exists(nativeDir) ? nativeDir : null;
        }

        
    }
}
