using MaxRev.Gdal.Core;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using Xunit;
using Xunit.Abstractions;

namespace GdalCore_XUnit
{
    // The Linux and macOS runtimes ship every bundled third-party library as
    // "<name>-maxrev" (libproj-maxrev.so.25, libproj-maxrev.25.9.8.1.dylib), so a
    // same-named library of another package can neither overwrite ours in the flat
    // runtimes/<rid>/native output nor satisfy our imports at load time (see #9).
    [Collection("Sequential")]
    public class UniqueNativeNamesTests
    {
        private const string Suffix = "-maxrev";

        // Libraries shipped under their original names. Keep in sync with KEEP_REGEX in
        // unix/unique-native-names.sh and osx/unique-native-names.sh: libgdal is linked
        // by the wraps, tools and GDAL plugins, the SWIG *_wrap libs are loaded by name
        // from managed code, libgomp is the shared GCC OpenMP runtime.
        private static readonly Regex KeptLinuxLibName = new Regex(
            @"^lib(gdal\.so\.\d+|.+_wrap\.so|gomp\.so\.\d+)$", RegexOptions.CultureInvariant);
        private static readonly Regex KeptMacOSLibName = new Regex(
            @"^lib(gdal\.\d+(\.\d+)*\.dylib|.+_wrap\.dylib)$", RegexOptions.CultureInvariant);

        private static readonly Regex LinuxGdalLib = new Regex(@"^libgdal\.so\.\d+$", RegexOptions.CultureInvariant);
        private static readonly Regex MacOSGdalLib = new Regex(@"^libgdal\.\d+(\.\d+)*\.dylib$", RegexOptions.CultureInvariant);
        private static readonly Regex LinuxSharedLib = new Regex(@"\.so(\.\d+)*$", RegexOptions.CultureInvariant);

        private readonly ITestOutputHelper _outputHelper;

        public UniqueNativeNamesTests(ITestOutputHelper outputHelper)
        {
            _outputHelper = outputHelper;
        }

        [Fact]
        public void Linux_LoadsUniquelyNamedBundledLibs()
        {
            if (!OperatingSystem.IsLinux())
            {
                _outputHelper.WriteLine("Skipped: Linux-only check");
                return;
            }

            GdalBase.ConfigureAll();
            // column 6 of /proc/self/maps is the path of the mapped file
            var mapped = File.ReadLines("/proc/self/maps")
                .Select(line => line.Split((char[])null, 6, StringSplitOptions.RemoveEmptyEntries))
                .Where(columns => columns.Length == 6 && columns[5].StartsWith("/"))
                .Select(columns => columns[5].Trim())
                .Distinct()
                .ToList();

            AssertUniquelyNamed(mapped, LinuxGdalLib, KeptLinuxLibName, name => LinuxSharedLib.IsMatch(name), ".so");
        }

        [Fact]
        public void MacOS_LoadsUniquelyNamedBundledLibs()
        {
            if (!OperatingSystem.IsMacOS())
            {
                _outputHelper.WriteLine("Skipped: macOS-only check");
                return;
            }

            GdalBase.ConfigureAll();
            // Process.Modules does not list dylibs on macOS; ask dyld directly
            var images = new List<string>();
            var count = _dyld_image_count();
            for (uint i = 0; i < count; i++)
            {
                var name = Marshal.PtrToStringUTF8(_dyld_get_image_name(i));
                if (!string.IsNullOrEmpty(name))
                {
                    images.Add(name);
                }
            }

            AssertUniquelyNamed(images, MacOSGdalLib, KeptMacOSLibName, name => name.EndsWith(".dylib", StringComparison.Ordinal), ".dylib");
        }

        private void AssertUniquelyNamed(IReadOnlyCollection<string> loaded, Regex gdalLib, Regex keptLib, Func<string, bool> isLibrary, string extension)
        {
            var gdal = loaded.FirstOrDefault(p => gdalLib.IsMatch(Path.GetFileName(p)));
            Assert.True(gdal != null, $"No libgdal{extension} is loaded");
            var nativeDir = Path.GetDirectoryName(gdal);

            var fromNativeDir = loaded
                .Where(p => string.Equals(Path.GetDirectoryName(p), nativeDir, StringComparison.Ordinal))
                .Select(Path.GetFileName)
                .Where(isLibrary)
                .Distinct()
                .ToList();
            var notUnique = fromNativeDir
                .Where(n => !keptLib.IsMatch(n) && !n.Contains(Suffix, StringComparison.Ordinal))
                .ToList();
            Assert.True(notUnique.Count == 0, $"Bundled libraries loaded under their original names: {string.Join(", ", notUnique)}");
            var renamed = fromNativeDir.Where(n => n.Contains(Suffix, StringComparison.Ordinal)).ToList();
            Assert.NotEmpty(renamed);
            _outputHelper.WriteLine($"Loaded {renamed.Count} uniquely named libraries from {nativeDir}: {string.Join(", ", renamed)}");

            // No copy of a renamed library may also ship under its original name.
            var generic = Directory.GetFiles(nativeDir, $"*{Suffix}*")
                .Select(f => Path.GetFileName(f).Replace(Suffix, string.Empty, StringComparison.Ordinal))
                .Where(n => File.Exists(Path.Combine(nativeDir, n)))
                .ToList();
            Assert.True(generic.Count == 0, $"Bundled libraries are also packaged under their original names: {string.Join(", ", generic)}");
        }

        [DllImport("/usr/lib/libSystem.dylib")]
        private static extern uint _dyld_image_count();

        [DllImport("/usr/lib/libSystem.dylib")]
        private static extern IntPtr _dyld_get_image_name(uint imageIndex);
    }
}
