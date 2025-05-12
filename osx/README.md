# Building GDAL bindings on OSX (macOS)
 
  * [Prerequisites](#prerequisites)
    + [**1. Environment**](#1-environment)
    + [**2. Check for required libraries**](#2-check-for-required-libraries)
    + [**3. Compiling**](#3-compiling)
    + [**How to check dependencies:**](#6-how-to-check-dependencies)
    + [**macOS signing](#macos-signing)

## Prerequisites

1. Install [**homebrew**](https://docs.brew.sh/Installation) and [**macports**](https://www.macports.org/install.php) (for hdf4 hdf5 netcdf drivers).
2. Install base packages with `./before-install.sh`
3. Install [dotnet](https://dotnet.microsoft.com/en-us/download) to build Nuget packages

### **1. Environment**
There two types of builds **arm64** (Apple Silicon M1 & M2 chipsets) and **x86_64** (Intel chipsets). GH Actions runner is using a x64 3-core instances.
This build was compiled using a `ubuntu-24.04-arm` runner (arm64).
 
### **2. Check for required libraries**
 **VPKG** will install all requirements defined in `shared/GdalCore.opt` file. Latest versions, no collisions with other dynamic libraries.

### **3. Compiling**

Simply run `make` in current folder to start GNUmakefile which constists of steps described below.
Still, you can execute them sequentially if needed.

```bash
# install libraries with VCPKG
make -f vcpkg-makefile BUILD_ARCH=arm64

# install main libraries (proj,gdal)
# > optional use [target]-force to run from scratch, ex. gdal-force
make -f gdal-makefile BUILD_ARCH=arm64

# collect dynamic libraries 
make -f collect-deps-makefile BUILD_ARCH=arm64

# create packages (output to 'nuget' folder)
make -f publish-makefile pack BUILD_ARCH=arm64

# testing packages
# > optional PRERELEASE=1 - testing pre-release versions
# > optional APP_RUN=1 - testing via console app run (quick, to ensure deps were loaded correctly)
make -f test-makefile test BUILD_ARCH=arm64
```

### **How to check dependencies:**
Run tests from the latest step. If everything loads correctly - you're good.

Or after collecting libraries, run **otool** to view dependencies .
Don't forget to set **DYLD_LIBRARY_PATH**. See **copy-deps** target in **collect-deps-makefile** for details. Assumming the repo path is `/root/gdal.netcore`.
```bash
otool -L "/root/gdal.netcore/build-osx/gdal-build/lib/libgdal.dylib"
```

### **macOS code signing**
To sign the binaries, you need to have a valid Apple Developer ID certificate. You can create a self-signed certificate for testing purposes, but for distribution, you will need a valid certificate from Apple.

Usage of this library in newer macOS versions with enabled Gatekeeper requires addressing this security warning. Here are some approaches to handle this:

1. **For development environments:**
   ```shell
   # Remove quarantine attributes from the libraries
   xattr -d com.apple.quarantine /path/to/your/project/bin/Debug/net*/runtimes/osx*/native/*.dylib
   ```

2. **For production apps:**
   - If you have an Apple Developer account, sign the libraries as part of your build process:
     ```shell
     # Add to your post-build script
     codesign --force --deep --sign "Your Developer ID" --options runtime /path/to/your/app/runtimes/osx*/native/*.dylib
     ```
   - Without a Developer account, you can add a build step that removes quarantine attributes:
     ```xml
     <!-- In your .csproj file -->
     <Target Name="RemoveQuarantineAttributes" AfterTargets="Build" Condition="$([MSBuild]::IsOSPlatform('OSX'))">
       <Exec Command="xattr -d com.apple.quarantine &quot;$(OutputPath)runtimes/osx*/native/*.dylib&quot; 2>/dev/null || true" ContinueOnError="true" />
     </Target>
     ```

3. **For end users:**
   - Instruct users to right-click on the app and select "Open" the first time (this creates an exception)
   - Or provide instructions to run: `sudo xattr -rd com.apple.quarantine /Applications/YourApp.app`

4. **Try to build this library and codesign the packages yourself.**
   - You can build the library and sign it with your own Apple Developer ID. This way, you can ensure that the libraries are trusted by macOS.
   - To do this, clone the repository and follow the build instructions. After building, but before creating a nuget package, use the `codesign` command to sign the libraries with your Developer ID.

Note: The manual approach in your build script is generally safer than advising end users to bypass security measures.