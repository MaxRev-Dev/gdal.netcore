using MaxRev.Gdal.CLI;
using System.Runtime.InteropServices;

namespace MaxRev.Gdal.Core.Tests.CLI
{
    internal static class Program
    {
        private static int Main()
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

                var toolsToCheck = new[] { "gdalinfo", "ogr2ogr", "gdal_translate" };
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
