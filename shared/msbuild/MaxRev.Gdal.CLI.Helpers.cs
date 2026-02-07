using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;

namespace MaxRev.Gdal.CLI
{
    public static class GdalCli
    {
        public static void EnsureEnvironment()
        {
            PathInitializer.Initialize();
        }

        public static string? GetToolPath(string toolName, string? baseDir = null)
        {
            if (string.IsNullOrWhiteSpace(toolName))
            {
                return null;
            }

            baseDir = string.IsNullOrWhiteSpace(baseDir) ? AppContext.BaseDirectory : baseDir;
            var exeName = RuntimeInformation.IsOSPlatform(OSPlatform.Windows) && !toolName.EndsWith(".exe", StringComparison.OrdinalIgnoreCase)
                ? toolName + ".exe"
                : toolName;

            var direct = Path.Combine(baseDir, exeName);
            if (File.Exists(direct))
            {
                return direct;
            }

            var rid = GetRuntimeRid();
            if (string.IsNullOrEmpty(rid))
            {
                return null;
            }

            var toolPath = Path.Combine(baseDir, "tools", rid, exeName);
            return File.Exists(toolPath) ? toolPath : null;
        }

        public static IReadOnlyList<string> GetAvailableTools(string? baseDir = null)
        {
            baseDir = string.IsNullOrWhiteSpace(baseDir) ? AppContext.BaseDirectory : baseDir;
            var isWindows = RuntimeInformation.IsOSPlatform(OSPlatform.Windows);
            var tools = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

            CollectTools(baseDir, isWindows, tools);

            var rid = GetRuntimeRid();
            if (!string.IsNullOrEmpty(rid))
            {
                var toolsDir = Path.Combine(baseDir, "tools", rid);
                CollectTools(toolsDir, isWindows, tools);
            }

            var result = tools.ToList();
            result.Sort(StringComparer.OrdinalIgnoreCase);
            return result;
        }

        private static void CollectTools(string directory, bool isWindows, HashSet<string> tools)
        {
            if (!Directory.Exists(directory))
            {
                return;
            }

            foreach (var file in Directory.GetFiles(directory))
            {
                var fileName = Path.GetFileName(file);
                if (isWindows)
                {
                    if (!fileName.EndsWith(".exe", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }
                }
                else
                {
                    if (fileName.Contains('.'))
                    {
                        continue;
                    }
                }

                var name = Path.GetFileNameWithoutExtension(file);
                if (!string.IsNullOrEmpty(name))
                {
                    tools.Add(name);
                }
            }
        }

        public static int Run(string toolName,
            IEnumerable<string>? args = null,
            string? workingDirectory = null,
            Action<string>? stdout = null,
            Action<string>? stderr = null)
        {
            EnsureEnvironment();

            var toolPath = GetToolPath(toolName);
            if (string.IsNullOrEmpty(toolPath))
            {
                throw new FileNotFoundException($"Tool '{toolName}' not found.");
            }

            var startInfo = new ProcessStartInfo
            {
                FileName = toolPath,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
                UseShellExecute = false
            };

            if (!string.IsNullOrWhiteSpace(workingDirectory))
            {
                startInfo.WorkingDirectory = workingDirectory;
            }

            if (args != null)
            {
                startInfo.Arguments = string.Join(" ", EscapeArgs(args));
            }

            using var process = Process.Start(startInfo);
            if (process == null)
            {
                throw new InvalidOperationException("Failed to start CLI tool.");
            }

            var output = process.StandardOutput.ReadToEnd();
            var error = process.StandardError.ReadToEnd();
            process.WaitForExit();

            if (!string.IsNullOrWhiteSpace(output))
            {
                stdout?.Invoke(output);
            }

            if (!string.IsNullOrWhiteSpace(error))
            {
                stderr?.Invoke(error);
            }
            
            return process.ExitCode;
        }

        private static IEnumerable<string> EscapeArgs(IEnumerable<string> args)
        {
            foreach (var arg in args)
            {
                if (string.IsNullOrEmpty(arg))
                {
                    yield return "\"\"";
                }
                else if (arg.IndexOfAny(new[] { ' ', '\t', '\n', '"' }) >= 0)
                {
                    yield return "\"" + arg.Replace("\"", "\\\"") + "\"";
                }
                else
                {
                    yield return arg;
                }
            }
        }

        private static string? GetRuntimeRid()
        {
            if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
            {
                return RuntimeInformation.OSArchitecture == Architecture.Arm64 ? "osx-arm64" : "osx-x64";
            }

            if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
            {
                return RuntimeInformation.OSArchitecture == Architecture.Arm64 ? "linux-arm64" : "linux-x64";
            }

            if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
            {
                return "win-x64";
            }

            return null;
        }
    }
}
