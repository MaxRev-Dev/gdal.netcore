using GdalNetcore.Build;
using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection.PortableExecutable;
using System.Text;
using Xunit;

namespace GdalCore_XUnit
{
    // Exercises win/PeImportRenamer.cs directly (compiled into this project, see the
    // csproj's linked Compile item) instead of only through the Windows-only build
    // pipeline. Since every real rename appends "-maxrev" and therefore lengthens the
    // DLL name, the "doesn't fit in place, append a new section" path
    // (PeImportRenamer.AppendNameSection) is what every production rename actually
    // exercises, so that is what this test targets.
    //
    // A copy of this test assembly (or any other managed .NET PE) does not work as
    // the input: the CLR tools pack the PE header tightly, leaving no slack for an
    // extra section header, so AppendNameSection always throws "no room in the PE
    // header for an extra section" for those files. Instead this test builds a
    // minimal, hand-crafted PE32 image with one section and a single import
    // descriptor for mscoree.dll, with deliberate header slack, mirroring the real
    // DLLs this tool patches in CI closely enough to validate the append-section path
    // end to end on any OS (no Windows runtime is needed to parse or write a PE).
    public class PeImportRenamerTests
    {
        private const string DllName = "mscoree.dll";

        [Fact]
        public void RewriteDllNames_AppendsSectionAndIsReadableAndIdempotent()
        {
            var dir = Directory.CreateDirectory(Path.Combine(Path.GetTempPath(), "PeImportRenamerTests-" + Guid.NewGuid().ToString("N")));
            var path = Path.Combine(dir.FullName, "synthetic.dll");
            try
            {
                File.WriteAllBytes(path, BuildSyntheticPe32WithImport(DllName));

                var before = PeImportRenamer.GetImportedDllNames(path);
                Assert.Contains(DllName, before, StringComparer.OrdinalIgnoreCase);

                int originalSectionCount;
                using (var stream = File.OpenRead(path))
                using (var reader = new PEReader(stream))
                {
                    originalSectionCount = reader.PEHeaders.SectionHeaders.Length;
                }

                var renames = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
                {
                    [DllName] = "mscoree-maxrev.dll"
                };

                var changed = PeImportRenamer.RewriteDllNames(path, renames, null);
                Assert.True(changed > 0, "Expected at least one import name to be rewritten");

                var after = PeImportRenamer.GetImportedDllNames(path);
                Assert.Contains("mscoree-maxrev.dll", after, StringComparer.OrdinalIgnoreCase);
                Assert.DoesNotContain(DllName, after, StringComparer.OrdinalIgnoreCase);

                byte[] patchedBytes;
                using (var stream = File.OpenRead(path))
                using (var reader = new PEReader(stream))
                {
                    var headers = reader.PEHeaders;
                    // The new name is longer than "mscoree.dll", so it does not fit
                    // in place and must go into an appended ".dllname" section.
                    Assert.Equal(originalSectionCount + 1, headers.SectionHeaders.Length);

                    var lastSection = headers.SectionHeaders[headers.SectionHeaders.Length - 1];
                    var expectedMinSizeOfImage = lastSection.VirtualAddress + lastSection.VirtualSize;
                    Assert.True(headers.PEHeader.SizeOfImage >= expectedMinSizeOfImage,
                        $"SizeOfImage ({headers.PEHeader.SizeOfImage}) must cover the appended section (ends at {expectedMinSizeOfImage})");
                }
                patchedBytes = File.ReadAllBytes(path);

                // A second run renaming the same (already renamed) import is a no-op:
                // there is nothing left named "mscoree.dll" to rewrite, so the file
                // must come out byte-identical.
                var secondRunChanged = PeImportRenamer.RewriteDllNames(path, renames, null);
                Assert.Equal(0, secondRunChanged);
                var afterSecondRun = File.ReadAllBytes(path);
                Assert.Equal(patchedBytes, afterSecondRun);
            }
            finally
            {
                try { Directory.Delete(dir.FullName, true); } catch { /* best-effort cleanup */ }
            }
        }

        /// <summary>
        /// Builds a minimal valid PE32 image: DOS header/stub, COFF + optional
        /// headers (16 data directories), one ".text" section containing a single
        /// import descriptor (plus its null terminator) for <paramref name="dllName"/>,
        /// and deliberate zero-filled slack between the section table and
        /// SizeOfHeaders so a new section header can be appended later.
        /// </summary>
        private static byte[] BuildSyntheticPe32WithImport(string dllName)
        {
            const int peHeaderOffset = 0x80;
            const int coffOffset = peHeaderOffset + 4;
            const int optOffset = coffOffset + 20;
            const int optionalHeaderSize = 224; // PE32, 16 data directories
            const int sectionTableOffset = optOffset + optionalHeaderSize;
            const uint sizeOfHeaders = 0x200;
            const uint fileAlignment = 0x200;
            const uint sectionAlignment = 0x1000;
            const uint sectionVirtualAddress = 0x1000;

            var nameBytes = Encoding.ASCII.GetBytes(dllName + "\0");
            uint nameRva = sectionVirtualAddress + 40; // right after the 2 import descriptors
            uint sectionVirtualSize = (uint)(40 + nameBytes.Length);
            uint sectionRawSize = Align(sectionVirtualSize, fileAlignment);
            uint sectionRawPointer = sizeOfHeaders;

            var data = new byte[sectionRawPointer + sectionRawSize];

            // DOS header
            data[0] = (byte)'M';
            data[1] = (byte)'Z';
            WriteUInt32(data, 0x3C, peHeaderOffset);

            // PE signature + COFF header
            WriteUInt32(data, peHeaderOffset, 0x00004550); // "PE\0\0"
            WriteUInt16(data, coffOffset, 0x014C); // Machine = IMAGE_FILE_MACHINE_I386
            WriteUInt16(data, coffOffset + 2, 1); // NumberOfSections
            WriteUInt16(data, coffOffset + 16, optionalHeaderSize); // SizeOfOptionalHeader
            WriteUInt16(data, coffOffset + 18, 0x0102); // Characteristics: EXECUTABLE_IMAGE | 32BIT_MACHINE

            // Optional header (PE32)
            WriteUInt16(data, optOffset, 0x10B); // Magic = PE32
            WriteUInt32(data, optOffset + 28, 0x00400000); // ImageBase
            WriteUInt32(data, optOffset + 32, sectionAlignment); // SectionAlignment
            WriteUInt32(data, optOffset + 36, fileAlignment); // FileAlignment
            WriteUInt32(data, optOffset + 56, Align(sectionVirtualAddress + sectionVirtualSize, sectionAlignment)); // SizeOfImage
            WriteUInt32(data, optOffset + 60, sizeOfHeaders); // SizeOfHeaders
            WriteUInt32(data, optOffset + 92, 16); // NumberOfRvaAndSizes
            // Data directory 1 (Import Table): RVA + Size, covering the descriptor + terminator
            WriteUInt32(data, optOffset + 96 + 1 * 8, sectionVirtualAddress);
            WriteUInt32(data, optOffset + 96 + 1 * 8 + 4, 40);

            // Section header: ".text"
            var sectionName = Encoding.ASCII.GetBytes(".text");
            Buffer.BlockCopy(sectionName, 0, data, sectionTableOffset, sectionName.Length);
            WriteUInt32(data, sectionTableOffset + 8, sectionVirtualSize);
            WriteUInt32(data, sectionTableOffset + 12, sectionVirtualAddress);
            WriteUInt32(data, sectionTableOffset + 16, sectionRawSize);
            WriteUInt32(data, sectionTableOffset + 20, sectionRawPointer);
            WriteUInt32(data, sectionTableOffset + 36, 0x60000020); // CODE | MEM_EXECUTE | MEM_READ

            // Section content: one import descriptor (20 bytes) + null terminator
            // (20 bytes), then the DLL name string.
            int descriptor = (int)sectionRawPointer;
            WriteUInt32(data, descriptor + 12, nameRva); // Name RVA (4th DWORD field)
            WriteUInt32(data, descriptor + 16, nameRva); // FirstThunk (non-zero so this isn't read as the terminator)
            Buffer.BlockCopy(nameBytes, 0, data, (int)sectionRawPointer + 40, nameBytes.Length);

            return data;
        }

        private static uint Align(uint value, uint alignment) => (value + alignment - 1) / alignment * alignment;
        private static void WriteUInt16(byte[] b, int o, ushort v) { b[o] = (byte)v; b[o + 1] = (byte)(v >> 8); }
        private static void WriteUInt32(byte[] b, int o, uint v) { b[o] = (byte)v; b[o + 1] = (byte)(v >> 8); b[o + 2] = (byte)(v >> 16); b[o + 3] = (byte)(v >> 24); }
    }
}
