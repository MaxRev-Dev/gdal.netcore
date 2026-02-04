using MaxRev.Gdal.CLI;
using System.Runtime.InteropServices;

namespace MaxRev.GdalCore.Tests.CLI
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

                GdalCli.EnsureEnvironment();
                var toolsToCheck = new[] { "gdalinfo", "ogr2ogr", "gdal_translate" };
                foreach (var tool in toolsToCheck)
                {
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

        
    }
}
