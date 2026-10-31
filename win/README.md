## Windows build scripts for GDAL

## Table of contents

- [Windows build scripts for GDAL](#windows-build-scripts-for-gdal)
  * [Prerequisites:](#prerequisites)
  * [Building: (in PowerShell)](#building-in-powershell)
  * [Troubleshooting dependencies:](#troubleshooting-dependencies)

Table of contents generated with [markdown-toc](http://ecotrust-canada.github.io/markdown-toc/).

In this folder contains Powershell and NMake scripts for building Windows runtime packages.

### Prerequisites:

1. [Visual Studio Build Tools (with ATL)](https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=BuildTools&rel=16). Recommended versions - vs16.0(2019) and vs17.0(2022) or greater (**nmake** and to retarget **libpng** to v143 toolset)

   The scripts locate it with `vswhere.exe`, which the Visual Studio Installer places in `%ProgramFiles(x86)%\Microsoft Visual Studio\Installer`. No PowerShell Gallery modules are needed.

2. [.NET Core SDK](https://dotnet.microsoft.com/en-us/download/dotnet/7.0) and [Nuget.exe](https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools) - for building and publishing packages respectively.

The Windows build uses the same shared VCPKG manifest authority as Unix and macOS:

- `../shared/vcpkg.json`
- `../shared/vcpkg-configuration.json`
- `../shared/vcpkg-lock.json`

### Building: (in PowerShell)

1. Call `./install.ps1` to install all required packages and tools. <br/>
Possible options:
   ```powershell
    [bool] $cleanGdalBuild = $true,  # clean gdal-build folder (output) before build
    [bool] $cleanGdalIntermediate = $true, # clean gdal-cmake-temp (cache) folder
    [bool] $cleanProjBuild = $true, # clean proj-build folder (output) before build    
    [bool] $cleanProjIntermediate = $true, # clean proj-cmake-temp (cache) folder
    [bool] $bootstrapVcpkg = $true, # bootstrap VCPKG from scratch
    [bool] $installVcpkgPackages = $true, # install VCPKG packages
    [bool] $isDebug = $false # build debug version of packages
    ```
   Example: 
   ```powershell 
   ./install.ps1 -cleanGdalBuild:$true -cleanGdalIntermediate:$true -isDebug:$true
   ```
This will install all required VCPKG packages and tools, build GDAL and PROJ, and build runtime and core packages.

On CI, cache-warm runs restore the VCPKG archive cache separately from the Windows build-output cache. When the manifest/build inputs match, the build-state stamps allow the workflow to reuse cached VCPKG, PROJ, and GDAL outputs instead of recompiling them from scratch.

#### GisInternals SDK mirror

`download.gisinternals.com` is a single-maintainer host that is frequently unreachable, which breaks Windows CI whenever the SDK cache misses. `win/partials.psm1` first tries to download `release-1930-x64-dev.zip` from a mirror release on this repo (`deps-gisinternals-sdk`) and only falls back to GisInternals if that fails. Both URLs are configurable via the `SDK_MIRROR_URL` and `SDK_URL` environment variables. Windows CI also caches the pristine downloaded zip under its own cache key (`gis-sdk-<os>-release-1930-x64-dev`) so build-script changes do not force a re-download.

To refresh the mirror, either run the `Mirror GisInternals SDK` workflow (`.github/workflows/mirror-gisinternals-sdk.yml`, manual `workflow_dispatch`) or, from a machine that already has the zip:

```
gh release upload deps-gisinternals-sdk release-1930-x64-dev.zip --clobber
```

After uploading, set `$script:SDK_ZIP_SHA256` in `win/partials.psm1` to the zip's SHA256 so the build can verify it. Until that value is set away from its placeholder, checksum verification is skipped with a warning.

2. Call `./test.ps1` to test runtime and core packages. <br/> 
If everything runs smoothly, you can use a local nuget feed to include packages in your project.

### Troubleshooting dependencies:
Use **dumpbin** or [**dependency walker**](https://www.dependencywalker.com/) to check gdal's dependencies. Please ensure the tests are passing before bringing them to prod.

Every bundled third-party DLL is renamed to `<name>-maxrev.dll` (for example `libcrypto-3-x64-maxrev.dll`, `zlib-maxrev.dll`, `proj_9-maxrev.dll`), and the import tables of every packaged binary (DLLs and tools) are rewritten to match (`Rename-BundledDLLs` in `partials.psm1`, `PeImportRenamer.cs`). Windows binds imports by base name and reuses a same-named module that is already loaded, so without this a DLL from another application (already loaded, or found in System32/PATH) could be used instead of ours (see #253). Unique names also keep our DLLs from overwriting, or being overwritten by, same-named DLLs of other NuGet packages in the shared `runtimes/win-x64/native` output folder.

These keep their original names (`$BundledDllKeepPatterns`): `gdal.dll` and the SWIG `*_wrap.dll` (loaded by name from managed code and by consumers), the VC++ runtime and `msodbcsql17.dll` (Microsoft-signed redistributables), `OpenCL.dll` (OS ICD loader), and any other Authenticode-signed DLL. DLLs in subdirectories, such as GDAL plugins loaded by path, keep their names too but get their imports rewritten. Code that loads a bundled DLL by its old name (for example `NativeLibrary.Load("sqlite3.dll")`) no longer binds to our copy.

New names that do not fit in place go into a small read-only section appended to the DLL. If the PE header has no room for another section header, they go into the zero padding at the end of existing read-only data sections instead; the build fails only if neither fits. `Confirm-PackagedDllImports` then fails the build if a bundled DLL still ships under its original name, or any packaged binary imports an original name or a DLL that is neither packaged nor a system DLL.

Have fun)

Contact me: [Telegram - MaxRev](http://t.me/maxrev)
