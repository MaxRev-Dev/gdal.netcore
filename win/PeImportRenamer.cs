//
//  gdal.netcore package automation
//
//  Minimal PE (Portable Executable) import-table editor, loaded by partials.psm1
//  via Add-Type. It is the Windows counterpart of `patchelf --replace-needed` in
//  unix/collect-deps-makefile (see also delvewheel: https://github.com/adang1345/delvewheel,
//  which uses the same "append a section when the new name does not fit" trick for
//  its `--mangle` option): it lets the build ship bundled DLLs under unique names,
//  so a foreign DLL with the same base name (already loaded in the process, or
//  found earlier in the DLL search order, e.g. System32) can no longer satisfy our
//  imports (#253). See the Windows DLL search order docs for why the default
//  search order makes a same-named DLL elsewhere on the machine a real risk:
//  https://learn.microsoft.com/en-us/windows/win32/dlls/dynamic-link-library-search-order
//
//  Only names are rewritten: import and delay-import descriptor DLL names, plus the
//  export directory name of the renamed DLL itself. Names that do not fit in place
//  go into a new read-only section appended to the image. Kept to plain C# 5 so it
//  compiles with Add-Type under Windows PowerShell 5.1 as well as pwsh.
//
//  PE layout reference throughout: Microsoft PE Format spec,
//  https://learn.microsoft.com/en-us/windows/win32/debug/pe-format
//
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace GdalNetcore.Build
{
    public static class PeImportRenamer
    {
        // Data directory indices (PE Format: "Optional Header Data Directories").
        private const int DirExport = 0;
        private const int DirImport = 1;
        private const int DirSecurity = 4; // certificate table (Authenticode)
        private const int DirBoundImport = 11;
        private const int DirDelayImport = 13;

        // IMAGE_SECTION_HEADER (PE Format: "Section Table") is a fixed 40 bytes.
        private const int SectionHeaderSize = 40;
        private const string NewSectionName = ".dllname";
        // IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ
        private const uint NewSectionCharacteristics = 0x40000040;

        // IMAGE_IMPORT_DESCRIPTOR (PE Format: "Import Directory Table") is 20 bytes;
        // Name RVA is the 4th DWORD field (offset 12).
        private const int ImportDescriptorSize = 20;
        private const int ImportDescriptorNameOffset = 12;

        // IMAGE_DELAYLOAD_DESCRIPTOR (PE Format: "Delay-Load Import Tables (Image
        // Only)") is 32 bytes; DllNameRVA is the 2nd DWORD field.
        private const int DelayImportDescriptorSize = 32;
        private const int DelayImportDescriptorNameOffset = 4;
        private const int DelayImportDescriptorAttributesOffset = 0;

        // Optional header field offsets, relative to the start of the optional
        // header (PE Format: "Optional Header Standard/Windows-Specific Fields").
        // Common to both PE32 and PE32+:
        private const int OptSectionAlignment = 32;
        private const int OptFileAlignment = 36;
        private const int OptSizeOfInitializedData = 8;
        private const int OptSizeOfImage = 56;
        private const int OptSizeOfHeaders = 60;
        private const int OptCheckSum = 64;
        // PE32+ (64-bit) has an 8-byte wider ImageBase and pushes the data
        // directory count/array 16 bytes later than PE32.
        private const int OptImageBase32 = 28;
        private const int OptImageBase64 = 24;
        private const int OptNumberOfDataDirectories32 = 92;
        private const int OptNumberOfDataDirectories64 = 108;
        private const int OptDataDirectories32 = 96;
        private const int OptDataDirectories64 = 112;
        private const int DataDirectoryEntrySize = 8; // RVA (4) + Size (4)

        // COFF file header (PE Format: "COFF File Header (Object and Image)").
        private const int CoffNumberOfSectionsOffset = 2;
        private const int CoffSizeOfOptionalHeaderOffset = 16;

        private const ushort OptionalHeaderMagicPe32 = 0x10B;
        private const ushort OptionalHeaderMagicPe32Plus = 0x20B;
        private const uint PeSignature = 0x00004550; // "PE\0\0"
        private const int DosHeaderLfanewOffset = 0x3C;

        private sealed class Image
        {
            public byte[] Data;
            public int CoffHeader;
            public int OptionalHeader;
            public bool Is64;
            public ulong ImageBase;
            public int NumberOfSections;
            public int SectionTable;
            public int DataDirectories;
            public int NumberOfDataDirectories;
        }

        // A field in the file that holds the RVA (or, for old-style delay imports,
        // the VA) of a DLL name string.
        private sealed class NameRef
        {
            public int FieldOffset;
            public bool IsVa;
            public string Name;
        }

        /// <summary>DLL names from the import and delay-import tables of a PE file.</summary>
        public static string[] GetImportedDllNames(string path)
        {
            var image = Load(File.ReadAllBytes(path), path);
            var names = new List<string>();
            foreach (var r in GetImportRefs(image, path)) names.Add(r.Name);
            return names.ToArray();
        }

        /// <summary>
        /// Rewrites imported DLL names found in <paramref name="renames"/> (keys are
        /// matched case-insensitively). If <paramref name="newExportName"/> is set, the
        /// export directory name is replaced too. Returns how many names changed; the
        /// file is not written when nothing matched.
        /// </summary>
        public static int RewriteDllNames(string path, IDictionary<string, string> renames, string newExportName)
        {
            var data = File.ReadAllBytes(path);
            var image = Load(data, path);

            var edits = PlanEdits(image, path, renames, newExportName);
            if (edits.Count == 0) return 0;

            // The certificate table (PE Format: "The Attribute Certificate Table
            // (Image Only)") covers the whole file via Authenticode; patching
            // name bytes or the checksum would invalidate the signature.
            if (GetDirectorySize(image, DirSecurity) != 0)
                throw new InvalidOperationException(path + ": file is Authenticode-signed; rewriting imports would invalidate the signature.");

            image = ApplyEdits(image, edits, path);

            // Bound imports (PE Format: "Bound Import Table") cache addresses per
            // DLL name; stale entries for renamed DLLs are dropped so the loader
            // binds normally instead of trusting a cached address for the old name.
            SetDirectory(image, DirBoundImport, 0, 0);

            RecomputeChecksum(image);
            File.WriteAllBytes(path, image.Data);
            return edits.Count;
        }

        // patch planning

        private static List<KeyValuePair<NameRef, string>> PlanEdits(
            Image image, string path, IDictionary<string, string> renames, string newExportName)
        {
            var lookup = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var kv in renames) lookup[kv.Key] = kv.Value;

            var edits = new List<KeyValuePair<NameRef, string>>();
            foreach (var r in GetImportRefs(image, path))
            {
                string target;
                if (lookup.TryGetValue(r.Name, out target) && !string.Equals(r.Name, target, StringComparison.Ordinal))
                    edits.Add(new KeyValuePair<NameRef, string>(r, target));
            }
            if (!string.IsNullOrEmpty(newExportName))
            {
                var exportRef = GetExportNameRef(image, path);
                if (exportRef != null && !string.Equals(exportRef.Name, newExportName, StringComparison.Ordinal))
                    edits.Add(new KeyValuePair<NameRef, string>(exportRef, newExportName));
            }
            return edits;
        }

        // Same-length or shorter names are written over the old string in place.
        // Longer names do not fit in the gap after the NUL terminator (the next
        // string in .rdata follows immediately), so they are collected and placed
        // in a new section appended to the image.
        private static Image ApplyEdits(Image image, List<KeyValuePair<NameRef, string>> edits, string path)
        {
            var pending = new List<KeyValuePair<NameRef, string>>();
            foreach (var e in edits)
            {
                int oldOffset = RvaToOffset(image, RefToRva(image, e.Key), path);
                var newBytes = Encoding.ASCII.GetBytes(e.Value);
                if (newBytes.Length <= Encoding.ASCII.GetByteCount(e.Key.Name))
                {
                    Array.Clear(image.Data, oldOffset, e.Key.Name.Length);
                    Buffer.BlockCopy(newBytes, 0, image.Data, oldOffset, newBytes.Length);
                }
                else
                {
                    pending.Add(e);
                }
            }
            return pending.Count > 0 ? AppendNameSection(image, pending, path) : image;
        }

        // section append (PE Format: "Section Table (Section Headers)")

        private static Image AppendNameSection(Image image, List<KeyValuePair<NameRef, string>> pending, string path)
        {
            var data = image.Data;
            int opt = image.OptionalHeader;
            uint sectionAlignment = ReadUInt32(data, opt + OptSectionAlignment);
            uint fileAlignment = ReadUInt32(data, opt + OptFileAlignment);
            uint sizeOfHeaders = ReadUInt32(data, opt + OptSizeOfHeaders);

            int newHeader = image.SectionTable + image.NumberOfSections * SectionHeaderSize;
            uint firstRaw, lastVirtualEnd, rawEnd;
            ScanSections(image, sizeOfHeaders, out firstRaw, out lastVirtualEnd, out rawEnd);

            // A new section header needs 40 free (zero) bytes after the section
            // table, inside SizeOfHeaders and before the first section's raw data.
            if (newHeader + SectionHeaderSize > Math.Min(sizeOfHeaders, firstRaw))
                throw new InvalidOperationException(path + ": no room in the PE header for an extra section.");
            for (int i = newHeader; i < newHeader + SectionHeaderSize; i++)
                if (data[i] != 0)
                    throw new InvalidOperationException(path + ": PE header slack after the section table is not empty.");
            if (data.Length > rawEnd)
                throw new InvalidOperationException(path + ": file has trailing (overlay) data after the last section.");

            byte[] payload;
            Dictionary<string, int> nameOffsets;
            BuildNamePayload(pending, out payload, out nameOffsets);

            uint virtualSizeNew = (uint)payload.Length;
            uint rawSizeNew = Align(virtualSizeNew, fileAlignment);
            uint rawPointerNew = Align(rawEnd, fileAlignment);
            // The loader requires sections to be virtually contiguous, so the new
            // one starts where the loader maps the last one to end.
            uint virtualAddressNew = Align(lastVirtualEnd, sectionAlignment);

            var grown = new byte[rawPointerNew + rawSizeNew];
            Buffer.BlockCopy(data, 0, grown, 0, data.Length);
            Buffer.BlockCopy(payload, 0, grown, (int)rawPointerNew, payload.Length);

            WriteSectionHeader(grown, newHeader, virtualSizeNew, virtualAddressNew, rawSizeNew, rawPointerNew);

            WriteUInt16(grown, image.CoffHeader + CoffNumberOfSectionsOffset, (ushort)(image.NumberOfSections + 1));
            WriteUInt32(grown, opt + OptSizeOfInitializedData, ReadUInt32(grown, opt + OptSizeOfInitializedData) + rawSizeNew);
            WriteUInt32(grown, opt + OptSizeOfImage, Align(virtualAddressNew + virtualSizeNew, sectionAlignment));

            image.Data = grown;
            image.NumberOfSections += 1;
            RepointNameRefs(image, pending, nameOffsets, virtualAddressNew, path);
            return image;
        }

        private static void ScanSections(Image image, uint sizeOfHeaders, out uint firstRaw, out uint lastVirtualEnd, out uint rawEnd)
        {
            var data = image.Data;
            firstRaw = sizeOfHeaders;
            lastVirtualEnd = 0;
            rawEnd = sizeOfHeaders;
            for (int i = 0; i < image.NumberOfSections; i++)
            {
                int s = image.SectionTable + i * SectionHeaderSize;
                uint virtualSize = ReadUInt32(data, s + 8);
                uint virtualAddress = ReadUInt32(data, s + 12);
                uint rawSize = ReadUInt32(data, s + 16);
                uint rawPointer = ReadUInt32(data, s + 20);
                if (rawSize != 0 && rawPointer < firstRaw) firstRaw = rawPointer;
                lastVirtualEnd = Math.Max(lastVirtualEnd, virtualAddress + (virtualSize != 0 ? virtualSize : rawSize));
                rawEnd = Math.Max(rawEnd, rawPointer + rawSize);
            }
        }

        // Section payload: each distinct name once, NUL-terminated.
        private static void BuildNamePayload(List<KeyValuePair<NameRef, string>> pending, out byte[] payload, out Dictionary<string, int> nameOffsets)
        {
            var stream = new MemoryStream();
            nameOffsets = new Dictionary<string, int>(StringComparer.Ordinal);
            foreach (var e in pending)
            {
                if (nameOffsets.ContainsKey(e.Value)) continue;
                nameOffsets[e.Value] = (int)stream.Length;
                var bytes = Encoding.ASCII.GetBytes(e.Value);
                stream.Write(bytes, 0, bytes.Length);
                stream.WriteByte(0);
            }
            payload = stream.ToArray();
        }

        private static void WriteSectionHeader(byte[] grown, int newHeader, uint virtualSize, uint virtualAddress, uint rawSize, uint rawPointer)
        {
            var nameBytes = Encoding.ASCII.GetBytes(NewSectionName);
            Buffer.BlockCopy(nameBytes, 0, grown, newHeader, Math.Min(8, nameBytes.Length));
            WriteUInt32(grown, newHeader + 8, virtualSize);
            WriteUInt32(grown, newHeader + 12, virtualAddress);
            WriteUInt32(grown, newHeader + 16, rawSize);
            WriteUInt32(grown, newHeader + 20, rawPointer);
            WriteUInt32(grown, newHeader + 36, NewSectionCharacteristics);
        }

        private static void RepointNameRefs(Image image, List<KeyValuePair<NameRef, string>> pending, Dictionary<string, int> nameOffsets, uint sectionRva, string path)
        {
            foreach (var e in pending)
            {
                uint rva = sectionRva + (uint)nameOffsets[e.Value];
                if (e.Key.IsVa)
                {
                    ulong va = image.ImageBase + rva;
                    if (va > uint.MaxValue)
                        throw new InvalidOperationException(path + ": delay-import VA does not fit in 32 bits.");
                    WriteUInt32(image.Data, e.Key.FieldOffset, (uint)va);
                }
                else
                {
                    WriteUInt32(image.Data, e.Key.FieldOffset, rva);
                }
            }
        }

        // header parsing (PE Format: "COFF File Header", "Optional Header")

        private static Image Load(byte[] data, string path)
        {
            if (data.Length < 0x40 || data[0] != 'M' || data[1] != 'Z')
                throw new InvalidDataException(path + ": not a PE file (no MZ header).");
            int peHeader = (int)ReadUInt32(data, DosHeaderLfanewOffset);
            if (peHeader <= 0 || peHeader + 24 > data.Length || ReadUInt32(data, peHeader) != PeSignature)
                throw new InvalidDataException(path + ": not a PE file (no PE signature).");
            int coff = peHeader + 4;
            int opt = coff + 20;
            ushort magic = ReadUInt16(data, opt);
            if (magic != OptionalHeaderMagicPe32 && magic != OptionalHeaderMagicPe32Plus)
                throw new InvalidDataException(path + ": unknown optional header magic 0x" + magic.ToString("X"));

            var image = new Image();
            image.Data = data;
            image.CoffHeader = coff;
            image.OptionalHeader = opt;
            image.Is64 = magic == OptionalHeaderMagicPe32Plus;
            image.ImageBase = image.Is64 ? ReadUInt64(data, opt + OptImageBase64) : ReadUInt32(data, opt + OptImageBase32);
            image.NumberOfSections = ReadUInt16(data, coff + CoffNumberOfSectionsOffset);
            image.SectionTable = opt + ReadUInt16(data, coff + CoffSizeOfOptionalHeaderOffset);
            image.DataDirectories = opt + (image.Is64 ? OptDataDirectories64 : OptDataDirectories32);
            image.NumberOfDataDirectories = (int)ReadUInt32(data, opt + (image.Is64 ? OptNumberOfDataDirectories64 : OptNumberOfDataDirectories32));
            return image;
        }

        // import / delay-import / export enumeration (PE Format: "Import
        // Directory Table", "Delay-Load Import Tables (Image Only)", "Export
        // Directory Table")

        private static List<NameRef> GetImportRefs(Image image, string path)
        {
            var refs = new List<NameRef>();
            uint importRva = GetDirectoryRva(image, DirImport);
            if (importRva != 0)
            {
                for (int d = RvaToOffset(image, importRva, path); ; d += ImportDescriptorSize)
                {
                    uint nameRva = ReadUInt32(image.Data, d + ImportDescriptorNameOffset);
                    if (nameRva == 0 && ReadUInt32(image.Data, d + 16) == 0) break; // null descriptor terminates the array
                    refs.Add(new NameRef { FieldOffset = d + ImportDescriptorNameOffset, IsVa = false, Name = ReadName(image, nameRva, path) });
                }
            }
            uint delayRva = GetDirectoryRva(image, DirDelayImport);
            if (delayRva != 0)
            {
                for (int d = RvaToOffset(image, delayRva, path); ; d += DelayImportDescriptorSize)
                {
                    uint nameField = ReadUInt32(image.Data, d + DelayImportDescriptorNameOffset);
                    if (nameField == 0) break; // null descriptor terminates the array
                    // Attribute bit 0 clear means the legacy VC6 format that stores
                    // VAs instead of RVAs in the descriptor fields.
                    bool isVa = (ReadUInt32(image.Data, d + DelayImportDescriptorAttributesOffset) & 1) == 0;
                    uint nameRva = isVa ? (uint)(nameField - image.ImageBase) : nameField;
                    refs.Add(new NameRef { FieldOffset = d + DelayImportDescriptorNameOffset, IsVa = isVa, Name = ReadName(image, nameRva, path) });
                }
            }
            return refs;
        }

        private static NameRef GetExportNameRef(Image image, string path)
        {
            uint exportRva = GetDirectoryRva(image, DirExport);
            if (exportRva == 0) return null;
            // IMAGE_EXPORT_DIRECTORY.Name RVA is the 4th DWORD field (offset 12).
            int field = RvaToOffset(image, exportRva, path) + 12;
            uint nameRva = ReadUInt32(image.Data, field);
            if (nameRva == 0) return null;
            return new NameRef { FieldOffset = field, IsVa = false, Name = ReadName(image, nameRva, path) };
        }

        private static uint RefToRva(Image image, NameRef r)
        {
            uint value = ReadUInt32(image.Data, r.FieldOffset);
            return r.IsVa ? (uint)(value - image.ImageBase) : value;
        }

        // data directory and RVA/offset helpers

        private static uint GetDirectoryRva(Image image, int index)
        {
            if (index >= image.NumberOfDataDirectories) return 0;
            return ReadUInt32(image.Data, image.DataDirectories + index * DataDirectoryEntrySize);
        }

        private static uint GetDirectorySize(Image image, int index)
        {
            if (index >= image.NumberOfDataDirectories) return 0;
            return ReadUInt32(image.Data, image.DataDirectories + index * DataDirectoryEntrySize + 4);
        }

        private static void SetDirectory(Image image, int index, uint rva, uint size)
        {
            if (index >= image.NumberOfDataDirectories) return;
            WriteUInt32(image.Data, image.DataDirectories + index * DataDirectoryEntrySize, rva);
            WriteUInt32(image.Data, image.DataDirectories + index * DataDirectoryEntrySize + 4, size);
        }

        private static int RvaToOffset(Image image, uint rva, string path)
        {
            var data = image.Data;
            if (rva < ReadUInt32(data, image.OptionalHeader + OptSizeOfHeaders)) return (int)rva;
            for (int i = 0; i < image.NumberOfSections; i++)
            {
                int s = image.SectionTable + i * SectionHeaderSize;
                uint virtualSize = ReadUInt32(data, s + 8);
                uint virtualAddress = ReadUInt32(data, s + 12);
                uint rawSize = ReadUInt32(data, s + 16);
                uint rawPointer = ReadUInt32(data, s + 20);
                if (rva >= virtualAddress && rva < virtualAddress + Math.Max(virtualSize, rawSize))
                {
                    uint delta = rva - virtualAddress;
                    if (delta >= rawSize) break;
                    return (int)(rawPointer + delta);
                }
            }
            throw new InvalidDataException(path + ": RVA 0x" + rva.ToString("X") + " is not backed by file data.");
        }

        private static string ReadName(Image image, uint rva, string path)
        {
            int start = RvaToOffset(image, rva, path);
            int end = start;
            while (end < image.Data.Length && image.Data[end] != 0) end++;
            return Encoding.ASCII.GetString(image.Data, start, end - start);
        }

        // checksum (PE Format: "The .debug Section", CheckSum field of the
        // optional header; algorithm matches imagehlp!CheckSumMappedFile)

        private static void RecomputeChecksum(Image image)
        {
            WriteUInt32(image.Data, image.OptionalHeader + OptCheckSum, ComputeChecksum(image.Data, image.OptionalHeader + OptCheckSum));
        }

        // Same algorithm as imagehlp!CheckSumMappedFile: 16-bit one's complement sum
        // of the file with the CheckSum field treated as zero, plus the file length.
        private static uint ComputeChecksum(byte[] data, int checksumOffset)
        {
            ulong sum = 0;
            for (int i = 0; i < data.Length; i += 2)
            {
                if (i == checksumOffset || i == checksumOffset + 2) continue;
                uint word = data[i];
                if (i + 1 < data.Length) word |= (uint)data[i + 1] << 8;
                sum += word;
                sum = (sum & 0xFFFF) + (sum >> 16);
            }
            sum = (sum & 0xFFFF) + (sum >> 16);
            return (uint)(sum + (ulong)data.Length);
        }

        // primitive read/write helpers

        private static uint Align(uint value, uint alignment)
        {
            return alignment == 0 ? value : (value + alignment - 1) / alignment * alignment;
        }

        private static ushort ReadUInt16(byte[] b, int o) { return (ushort)(b[o] | b[o + 1] << 8); }
        private static uint ReadUInt32(byte[] b, int o) { return (uint)(b[o] | b[o + 1] << 8 | b[o + 2] << 16 | b[o + 3] << 24); }
        private static ulong ReadUInt64(byte[] b, int o) { return ReadUInt32(b, o) | (ulong)ReadUInt32(b, o + 4) << 32; }
        private static void WriteUInt16(byte[] b, int o, ushort v) { b[o] = (byte)v; b[o + 1] = (byte)(v >> 8); }
        private static void WriteUInt32(byte[] b, int o, uint v) { b[o] = (byte)v; b[o + 1] = (byte)(v >> 8); b[o + 2] = (byte)(v >> 16); b[o + 3] = (byte)(v >> 24); }
    }
}
