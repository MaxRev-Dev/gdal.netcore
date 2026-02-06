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

                    string? output = null;
                    var exitCode = GdalCli.Run(tool, new[] { "--version" },
                        workingDirectory: AppContext.BaseDirectory,
                        stdout: s => output = s,
                        stderr: Console.Error.Write);

                    if (!string.IsNullOrEmpty(output))
                    {
                        Console.WriteLine(output.TrimEnd());
                    }

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
