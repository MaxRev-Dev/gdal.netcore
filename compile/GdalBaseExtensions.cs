using System;
using System.Reflection;

namespace MaxRev.Gdal.Core
{
    internal static class GdalBaseExtensions
    {
        public static string GetSourceLocation(this Assembly asm)
        {
            return !string.IsNullOrEmpty(asm.Location) ? asm.Location : AppContext.BaseDirectory;
        }

        public static string GetEnvRID()
        {
            return Environment.OSVersion.Platform switch
            {
                PlatformID.Unix => "linux-x64",
                PlatformID.Win32NT => "win-x64",
                _ => throw new PlatformNotSupportedException(),
            };
        }
    }
}