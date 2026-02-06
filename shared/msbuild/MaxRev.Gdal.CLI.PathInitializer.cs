using System;
using System.Collections.Generic;
using System.IO;
using System.Runtime.CompilerServices;
using System.Runtime.InteropServices;

namespace MaxRev.Gdal.CLI
{
    internal static class PathInitializer
    {
        private static volatile bool _initialized;

        [ModuleInitializer]
        internal static void Initialize()
        {
            if (_initialized) return;
            try
            {
                var baseDir = AppContext.BaseDirectory;
                if (string.IsNullOrWhiteSpace(baseDir) || !Directory.Exists(baseDir))
                {
                    return;
                }

                var comparer = RuntimeInformation.IsOSPlatform(OSPlatform.Windows)
                    ? StringComparer.OrdinalIgnoreCase
                    : StringComparer.Ordinal;

                var runtimeNativeDir = GetRuntimeNativeDirectory(baseDir);
                if (!string.IsNullOrEmpty(runtimeNativeDir))
                {
                    if (RuntimeInformation.IsOSPlatform(OSPlatform.OSX))
                    {
                        PrependEnv("DYLD_LIBRARY_PATH", runtimeNativeDir, comparer);
                    }
                    else if (RuntimeInformation.IsOSPlatform(OSPlatform.Linux))
                    {
                        PrependEnv("LD_LIBRARY_PATH", runtimeNativeDir, comparer);
                    }
                    else if (RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                    {
                        PrependEnv("PATH", runtimeNativeDir, comparer);
                    }

                    var projLib = Path.Combine(runtimeNativeDir, "maxrev.gdal.core.libshared");
                    if (Directory.Exists(projLib))
                    {
                        Environment.SetEnvironmentVariable("PROJ_LIB", projLib, EnvironmentVariableTarget.Process);
                    }
                }

                var gdalData = Path.Combine(baseDir, "runtimes", "any", "native", "gdal-data");
                if (Directory.Exists(gdalData))
                {
                    Environment.SetEnvironmentVariable("GDAL_DATA", gdalData, EnvironmentVariableTarget.Process);
                }

                _initialized = true;
            }
            catch
            {
                // ignore initialization errors
            }
        }

        private static void PrependEnv(string key, string value, StringComparer comparer)
        {
            var existing = Environment.GetEnvironmentVariable(key) ?? string.Empty;
            var parts = new HashSet<string>(
                existing.Split(new[] { Path.PathSeparator }, StringSplitOptions.RemoveEmptyEntries),
                comparer);

            if (parts.Contains(value))
            {
                return;
            }

            var newValue = string.Concat(
                value,
                existing.Length > 0 ? Path.PathSeparator.ToString() : string.Empty,
                existing);
            Environment.SetEnvironmentVariable(key, newValue, EnvironmentVariableTarget.Process);
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
                rid = RuntimeInformation.OSArchitecture == Architecture.Arm64 ? "win-arm64" : "win-x64";
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

#if !NET5_0_OR_GREATER
namespace System.Runtime.CompilerServices
{
    [AttributeUsage(AttributeTargets.Method, Inherited = false)]
    internal sealed class ModuleInitializerAttribute : Attribute
    {
    }
}
#endif
