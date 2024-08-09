
using System;
using System.IO;
using System.Reflection;
using System.Runtime.InteropServices;

namespace MaxRev.Gdal.Core
{
    public class AssemblyValidator
    {
        private static bool IsAssemblyExists(string assemblyName)
        {
            try
            {
                var asm = Assembly.Load(assemblyName);
                return asm != null;
            }
            catch (Exception)
            {
                return false;
            }
        }

        /// <summary>
        /// Throws an exception if the expected package which contains GDAL drivers is not available.
        /// The package name is determined by the current OS platform and architecture.
        /// </summary>
        /// <exception cref="DllNotFoundException">Missing runtime package</exception>
        public static void AssertRuntimeAvailable()
        {
            if (!CheckIfRuntimeAvailable(out var runtimeName))
            {
                var helpLink= "https://github.com/MaxRev-Dev/gdal.netcore";
                var ex = new DllNotFoundException($"Expected drivers package was not found.\n" +
                    $"Please, install the corresponding nuget package '{runtimeName}'.\n" +
                    $"More information at {helpLink}")
                {
                    HelpLink = helpLink
                };
                throw ex;
            }
        }

        /// <summary>
        /// Checks if the expected package which contains GDAL drivers is available.
        /// The package name is determined by the current OS platform and architecture.
        /// </summary>
        /// <returns>true if the package assembly is available and loaded</returns>
        public static bool CheckIfRuntimeAvailable() => CheckIfRuntimeAvailable(out _); 

        private static bool CheckIfRuntimeAvailable(out string runtimeName)
        {
            var isArm = RuntimeInformation.ProcessArchitecture is Architecture.Arm64;
            if (File.Exists(@"/System/Library/CoreServices/SystemVersion.plist"))
            {
                runtimeName = "MacosRuntime";
            }
            else
            {
                runtimeName = Environment.OSVersion.Platform switch
                {
                    PlatformID.Unix => "LinuxRuntime",
                    PlatformID.Win32NT => "WindowsRuntime",
                    _ => throw new PlatformNotSupportedException(),
                };
            }
            var armTail = Environment.OSVersion.Platform != PlatformID.Win32NT ? (isArm ? ".arm64" : ".x64") : "";
            runtimeName = $"MaxRev.Gdal.{runtimeName}.Minimal{armTail}";
            return IsAssemblyExists(runtimeName);
        }
    }
}