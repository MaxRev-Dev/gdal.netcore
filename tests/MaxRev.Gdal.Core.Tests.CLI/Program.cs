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
                    if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                    {
                        var gdalDll = Path.Combine(runtimeNativeDir, "gdal.dll");
                        Console.WriteLine($"gdal.dll exists: {File.Exists(gdalDll)}");
                        Console.WriteLine($"PATH: {Environment.GetEnvironmentVariable("PATH")}");
                    }
                    else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
                    {
                        var gdalSo = Directory.GetFiles(runtimeNativeDir, "libgdal.so*").FirstOrDefault();
                        Console.WriteLine($"libgdal.so exists: {gdalSo ?? "<not found>"}");
                        Console.WriteLine($"LD_LIBRARY_PATH: {Environment.GetEnvironmentVariable("LD_LIBRARY_PATH")}");
                    }
                    else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
                    {
                        var gdalDylib = Directory.GetFiles(runtimeNativeDir, "libgdal*.dylib").FirstOrDefault();
                        Console.WriteLine($"libgdal.dylib exists: {gdalDylib ?? "<not found>"}");
                        Console.WriteLine($"DYLD_LIBRARY_PATH: {Environment.GetEnvironmentVariable("DYLD_LIBRARY_PATH")}");
                    }
                }
                else
                {
                    Console.WriteLine("Runtime native dir: <not found>");
                }

                GdalCli.EnsureEnvironment();

                // Print environment AFTER EnsureEnvironment sets it up
                if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
                {
                    Console.WriteLine($"LD_LIBRARY_PATH (after init): {Environment.GetEnvironmentVariable("LD_LIBRARY_PATH")}");
                }
                else if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
                {
                    Console.WriteLine($"DYLD_LIBRARY_PATH (after init): {Environment.GetEnvironmentVariable("DYLD_LIBRARY_PATH")}");
                }
                else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                {
                    Console.WriteLine($"PATH (after init): {Environment.GetEnvironmentVariable("PATH")}");
                }

                var toolsToCheck = new[] { "gdalinfo", "ogr2ogr", "gdal_translate" };
                foreach (var tool in toolsToCheck)
                {
                    Console.WriteLine($"Running {tool} --version");
                    var toolPath = GdalCli.GetToolPath(tool);
                    Console.WriteLine($"Tool path: {toolPath ?? "<not found>"}");

                    // On Linux, check if tool is executable and show file info
                    if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux) && !string.IsNullOrEmpty(toolPath))
                    {
                        var fileInfo = new FileInfo(toolPath);
                        Console.WriteLine($"Tool size: {fileInfo.Length} bytes");
                    }
                    if (string.IsNullOrEmpty(toolPath))
                    {
                        return 1;
                    }

                    string? stdoutContent = null;
                    string? stderrContent = null;
                    var exitCode = GdalCli.Run(tool, new[] { "--version" },
                        workingDirectory: AppContext.BaseDirectory,
                        stdout: s => { stdoutContent = s; },
                        stderr: s => { stderrContent = s; });

                    Console.WriteLine($"[DEBUG] stdout length: {stdoutContent?.Length ?? 0}, stderr length: {stderrContent?.Length ?? 0}");
                    Console.Out.Flush();
                    if (!string.IsNullOrEmpty(stdoutContent))
                    {
                        Console.WriteLine($"[STDOUT] {stdoutContent}");
                        Console.Out.Flush();
                    }
                    if (!string.IsNullOrEmpty(stderrContent))
                    {
                        Console.WriteLine($"[STDERR] {stderrContent}");
                        Console.Out.Flush();
                    }

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
