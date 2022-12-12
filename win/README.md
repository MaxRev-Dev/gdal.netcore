## Windows build scripts for GDAL

## Table of contents

- [Windows build scripts for GDAL](#windows-build-scripts-for-gdal)
  * [Prerequisites:](#prerequisites-)
  * [Building: (in PowerShell)](#building---in-powershell-)

Table of contents generated with [markdown-toc](http://ecotrust-canada.github.io/markdown-toc/).

In this folder contains Powershell and NMake scripts for building Windows runtime packages.

### Prerequisites:

1. [Visual Studio Build Tools (with ATL)](https://visualstudio.microsoft.com/thank-you-downloading-visual-studio/?sku=BuildTools&rel=16). Recommended versions - vs16.0(2019) and vs17.0(2022) or greater (**nmake** and to retarget **libpng** to v143 toolset)

2. [.NET Core SDK](https://dotnet.microsoft.com/en-us/download/dotnet/7.0) and [Nuget.exe](https://docs.microsoft.com/en-us/nuget/install-nuget-client-tools) - for building and publishing packages respectively.

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

2. Call `./test.ps1` to test runtime and core packages. <br/> 
If everything runs smoothly, you can use a local nuget feed to include packages in your project.

### Troubleshooting dependencies:
Use **dumpbin** or [**dependency walker**](https://www.dependencywalker.com/) to check gdal's dependencies. Please ensure the tests are passing before bringing them to prod.

Have fun)

Contact me: [Telegram - MaxRev](http://t.me/maxrev)