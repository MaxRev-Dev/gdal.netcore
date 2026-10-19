//
//  gdal.netcore package automation
//
//  Minimal PE (Portable Executable) import-table editor, loaded by partials.psm1
//  via Add-Type. It is the Windows counterpart of `patchelf --replace-needed` in
//  unix/collect-deps-makefile: it lets the build ship bundled DLLs under unique
//  names, so a foreign DLL with the same base name (already loaded in the process,
//  or found in System32/PATH) can no longer satisfy our imports (see #253).
//
//  Only names are rewritten: import and delay-import descriptor DLL names, plus the
//  export directory name of the renamed DLL itself. Names that do not fit in place
//  go into a new read-only section appended to the image. Kept to plain C# so it
//  compiles with Add-Type in any PowerShell host.
//
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace GdalNetcore.Build
{
    public static class PeImportRenamer
    {
        private const int DirExport = 0;
        private const int DirImport = 1;
        private const int DirSecurity = 4;
        private const int DirBoundImport = 11;
        private const int DirDelayImport = 13;
        private const int SectionHeaderSize = 40;
        private const string NewSectionName = ".dllname";
        // IMAGE_SCN_CNT_INITIALIZED_DATA | IMAGE_SCN_MEM_READ
        private const uint NewSectionCharacteristics = 0x40000040;

        private sealed class Image
        {
            public byte[] Data;
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
            var lookup = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
            foreach (var kv in renames) lookup[kv.Key] = kv.Value;

            var data = File.ReadAllBytes(path);
            var image = Load(data, path);

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
            if (edits.Count == 0) return 0;

            if (GetDirectorySize(image, DirSecurity) != 0)
                throw new InvalidOperationException(path + ": file is Authenticode-signed; rewriting imports would invalidate the signature.");

            // Same-length or shorter names are written over the old string. Longer
            // names are collected and placed in a new section.
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
            if (pending.Count > 0) image = AppendNameSection(image, pending, path);

            // Bound imports cache addresses per DLL name; stale entries for renamed
            // DLLs are dropped so the loader binds normally.
            SetDirectory(image, DirBoundImport, 0, 0);

            WriteUInt32(image.Data, image.OptionalHeader + 64, ComputeChecksum(image.Data, image.OptionalHeader + 64));
            File.WriteAllBytes(path, image.Data);
            return edits.Count;
        }

        private static Image AppendNameSection(Image image, List<KeyValuePair<NameRef, string>> pending, string path)
        {
            var data = image.Data;
            int opt = image.OptionalHeader;
            uint sectionAlignment = ReadUInt32(data, opt + 32);
            uint fileAlignment = ReadUInt32(data, opt + 36);
            uint sizeOfHeaders = ReadUInt32(data, opt + 60);

            // A new section header needs 40 free (zero) bytes after the section table,
            // inside SizeOfHeaders and before the first section's raw data.
            int newHeader = image.SectionTable + image.NumberOfSections * SectionHeaderSize;
            uint firstRaw = sizeOfHeaders;
            uint lastVirtualEnd = 0;
            uint rawEnd = sizeOfHeaders;
            for (int i = 0; i < image.NumberOfSections; i++)
            {
                int s = image.SectionTable + i * SectionHeaderSize;
                uint virtualSize = ReadUInt32(data, s + 8);
                uint virtualAddress = ReadUInt32(data, s + 12);
                uint rawSize = ReadUInt32(data, s + 16);
                uint rawPointer = ReadUInt32(data, s + 20);
                if (rawSize != 0 && rawPointer < firstRaw) firstRaw = rawPointer;
                // The loader requires sections to be virtually contiguous, so the new
                // one starts where it maps the last one to end (VirtualSize, or the raw
                // size when VirtualSize is 0).
                lastVirtualEnd = Math.Max(lastVirtualEnd, virtualAddress + (virtualSize != 0 ? virtualSize : rawSize));
                rawEnd = Math.Max(rawEnd, rawPointer + rawSize);
            }
            if (newHeader + SectionHeaderSize > Math.Min(sizeOfHeaders, firstRaw))
                throw new InvalidOperationException(path + ": no room in the PE header for an extra section.");
            for (int i = newHeader; i < newHeader + SectionHeaderSize; i++)
                if (data[i] != 0)
                    throw new InvalidOperationException(path + ": PE header slack after the section table is not empty.");
            if (data.Length > rawEnd)
                throw new InvalidOperationException(path + ": file has trailing (overlay) data after the last section.");

            // Section payload: each distinct name once, NUL-terminated.
            var payload = new MemoryStream();
            var nameOffsets = new Dictionary<string, int>(StringComparer.Ordinal);
            foreach (var e in pending)
            {
                if (nameOffsets.ContainsKey(e.Value)) continue;
                nameOffsets[e.Value] = (int)payload.Length;
                var bytes = Encoding.ASCII.GetBytes(e.Value);
                payload.Write(bytes, 0, bytes.Length);
                payload.WriteByte(0);
            }
            uint virtualSizeNew = (uint)payload.Length;
            uint rawSizeNew = Align(virtualSizeNew, fileAlignment);
            uint rawPointerNew = Align(rawEnd, fileAlignment);
            uint virtualAddressNew = Align(lastVirtualEnd, sectionAlignment);

            var grown = new byte[rawPointerNew + rawSizeNew];
            Buffer.BlockCopy(data, 0, grown, 0, data.Length);
            Buffer.BlockCopy(payload.ToArray(), 0, grown, (int)rawPointerNew, (int)virtualSizeNew);

            var nameBytes = Encoding.ASCII.GetBytes(NewSectionName);
            Buffer.BlockCopy(nameBytes, 0, grown, newHeader, Math.Min(8, nameBytes.Length));
            WriteUInt32(grown, newHeader + 8, virtualSizeNew);
            WriteUInt32(grown, newHeader + 12, virtualAddressNew);
            WriteUInt32(grown, newHeader + 16, rawSizeNew);
            WriteUInt32(grown, newHeader + 20, rawPointerNew);
            WriteUInt32(grown, newHeader + 36, NewSectionCharacteristics);

            int coff = image.OptionalHeader - 20;
            WriteUInt16(grown, coff + 2, (ushort)(image.NumberOfSections + 1));
            WriteUInt32(grown, opt + 8, ReadUInt32(grown, opt + 8) + rawSizeNew); // SizeOfInitializedData
            WriteUInt32(grown, opt + 56, Align(virtualAddressNew + virtualSizeNew, sectionAlignment)); // SizeOfImage

            image.Data = grown;
            image.NumberOfSections += 1;
            foreach (var e in pending)
            {
                uint rva = virtualAddressNew + (uint)nameOffsets[e.Value];
                if (e.Key.IsVa)
                {
                    ulong va = image.ImageBase + rva;
                    if (va > uint.MaxValue)
                        throw new InvalidOperationException(path + ": delay-import VA does not fit in 32 bits.");
                    WriteUInt32(grown, e.Key.FieldOffset, (uint)va);
                }
                else
                {
                    WriteUInt32(grown, e.Key.FieldOffset, rva);
                }
            }
            return image;
        }

        private static Image Load(byte[] data, string path)
        {
            if (data.Length < 0x40 || data[0] != 'M' || data[1] != 'Z')
                throw new InvalidDataException(path + ": not a PE file (no MZ header).");
            int peHeader = (int)ReadUInt32(data, 0x3C);
            if (peHeader <= 0 || peHeader + 24 > data.Length || ReadUInt32(data, peHeader) != 0x00004550)
                throw new InvalidDataException(path + ": not a PE file (no PE signature).");
            int coff = peHeader + 4;
            int opt = coff + 20;
            ushort magic = ReadUInt16(data, opt);
            if (magic != 0x10B && magic != 0x20B)
                throw new InvalidDataException(path + ": unknown optional header magic 0x" + magic.ToString("X"));
            var image = new Image();
            image.Data = data;
            image.OptionalHeader = opt;
            image.Is64 = magic == 0x20B;
            image.ImageBase = image.Is64 ? ReadUInt64(data, opt + 24) : ReadUInt32(data, opt + 28);
            image.NumberOfSections = ReadUInt16(data, coff + 2);
            image.SectionTable = opt + ReadUInt16(data, coff + 16);
            image.DataDirectories = opt + (image.Is64 ? 112 : 96);
            image.NumberOfDataDirectories = (int)ReadUInt32(data, opt + (image.Is64 ? 108 : 92));
            return image;
        }

        private static List<NameRef> GetImportRefs(Image image, string path)
        {
            var refs = new List<NameRef>();
            uint importRva = GetDirectoryRva(image, DirImport);
            if (importRva != 0)
            {
                // IMAGE_IMPORT_DESCRIPTOR (20 bytes), Name RVA at +12; zero-terminated.
                for (int d = RvaToOffset(image, importRva, path); ; d += 20)
                {
                    uint nameRva = ReadUInt32(image.Data, d + 12);
                    if (nameRva == 0 && ReadUInt32(image.Data, d + 16) == 0) break;
                    refs.Add(new NameRef { FieldOffset = d + 12, IsVa = false, Name = ReadName(image, nameRva, path) });
                }
            }
            uint delayRva = GetDirectoryRva(image, DirDelayImport);
            if (delayRva != 0)
            {
                // IMAGE_DELAYLOAD_DESCRIPTOR (32 bytes), DllNameRVA at +4. Attribute
                // bit 0 clear means the old VC6 format that stores VAs, not RVAs.
                for (int d = RvaToOffset(image, delayRva, path); ; d += 32)
                {
                    uint nameField = ReadUInt32(image.Data, d + 4);
                    if (nameField == 0) break;
                    bool isVa = (ReadUInt32(image.Data, d) & 1) == 0;
                    uint nameRva = isVa ? (uint)(nameField - image.ImageBase) : nameField;
                    refs.Add(new NameRef { FieldOffset = d + 4, IsVa = isVa, Name = ReadName(image, nameRva, path) });
                }
            }
            return refs;
        }

        private static NameRef GetExportNameRef(Image image, string path)
        {
            uint exportRva = GetDirectoryRva(image, DirExport);
            if (exportRva == 0) return null;
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

        private static uint GetDirectoryRva(Image image, int index)
        {
            if (index >= image.NumberOfDataDirectories) return 0;
            return ReadUInt32(image.Data, image.DataDirectories + index * 8);
        }

        private static uint GetDirectorySize(Image image, int index)
        {
            if (index >= image.NumberOfDataDirectories) return 0;
            return ReadUInt32(image.Data, image.DataDirectories + index * 8 + 4);
        }

        private static void SetDirectory(Image image, int index, uint rva, uint size)
        {
            if (index >= image.NumberOfDataDirectories) return;
            WriteUInt32(image.Data, image.DataDirectories + index * 8, rva);
            WriteUInt32(image.Data, image.DataDirectories + index * 8 + 4, size);
        }

        private static int RvaToOffset(Image image, uint rva, string path)
        {
            var data = image.Data;
            if (rva < ReadUInt32(data, image.OptionalHeader + 60)) return (int)rva;
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
