using MaxRev.Gdal.CLI;
using System.Runtime.InteropServices;

namespace MaxRev.Gdal.Core.Tests.CLI
{
    internal static class Program
    {
        private static async Task<int> Main()
        {
            try
            {
                Console.WriteLine($"OS: {RuntimeInformation.OSDescription}");
                Console.WriteLine($"Arch: {RuntimeInformation.OSArchitecture}");
                
                var tools = GdalCli.GetAvailableTools();
                Console.WriteLine($"Found {tools.Count} available tools:");
                foreach (var tool in tools)
                {
                    Console.WriteLine($"Available tool: {tool}");
                }
                GdalCli.EnsureEnvironment();

                // gdalsrsinfo is included because it links PROJ directly
                // (@rpath/libproj.*.dylib on macOS), unlike gdalinfo/ogr2ogr/
                // gdal_translate which only link libgdal. This exercises the
                // dyld load path for a dependency other than libgdal itself.
                var toolsToCheck = new[] { "gdalinfo", "ogr2ogr", "gdal_translate", "gdalsrsinfo" };
                foreach (var tool in toolsToCheck)
                {
                    Console.WriteLine($"Running {tool} --version");
                    var toolPath = GdalCli.GetToolPath(tool);
                    Console.WriteLine($"Tool path: {toolPath ?? "<not found>"}");

                    if (string.IsNullOrEmpty(toolPath))
                    {
                        Console.Error.WriteLine($"Tool '{tool}' not found");
                        return 1;
                    }
                    
                    var exitCode = GdalCli.Run(tool, new[] { "--version" },
                        stdout: s => Console.WriteLine($"[GdalCli stdout] {s}"),
                        stderr: s => Console.Error.WriteLine($"[GdalCli stderr] {s}"));

                    if (exitCode != 0)
                    {
                        Console.Error.WriteLine($"{tool} failed with exit code {exitCode}");
                        return exitCode;
                    }
                }

                // Verify the async API returns the same successful exit codes.
                foreach (var tool in toolsToCheck)
                {
                    Console.WriteLine($"Running (async) {tool} --version");
                    var exitCode = await GdalCli.RunAsync(tool, new[] { "--version" },
                        stdout: s => Console.WriteLine($"[GdalCli async stdout] {s}"),
                        stderr: s => Console.Error.WriteLine($"[GdalCli async stderr] {s}"));

                    if (exitCode != 0)
                    {
                        Console.Error.WriteLine($"{tool} (async) failed with exit code {exitCode}");
                        return exitCode;
                    }
                }

                // Also exercise an actual PROJ lookup through gdalsrsinfo, not
                // just --version, since --version alone already proves dyld
                // could resolve libproj; this verifies the lookup works too.
                Console.WriteLine("Running gdalsrsinfo EPSG:4326");
                var srsInfoExitCode = GdalCli.Run("gdalsrsinfo", new[] { "EPSG:4326" },
                    stdout: s => Console.WriteLine($"[GdalCli stdout] {s}"),
                    stderr: s => Console.Error.WriteLine($"[GdalCli stderr] {s}"));

                if (srsInfoExitCode != 0)
                {
                    Console.Error.WriteLine($"gdalsrsinfo EPSG:4326 failed with exit code {srsInfoExitCode}");
                    return srsInfoExitCode;
                }

                Console.WriteLine("CLI tools executed successfully.");
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(ex);
                return 1;
            }
        }
    }
}
