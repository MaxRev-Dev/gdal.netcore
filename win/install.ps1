# Usage .\install.ps1 -cleanGdalBuild:$true -cleanGdalIntermediate:$true -cleanProjBuild:$true -bootstrapVcpkg:$true
param (
    [bool] $cleanGdalBuild = $true,  # clean gdal build files
    [bool] $cleanGdalIntermediate = $true,  # clean gdal intermediate files
    [bool] $cleanProjBuild = $true,  # clean proj build files
    [bool] $cleanProjIntermediate = $true, # clean proj intermediate files
    [bool] $fetchGdal = $true, # fetch gdal from git, otherwise use local copy
    [bool] $bootstrapVcpkg = $true, # bootstrap vcpkg, otherwise use local copy
    [bool] $installVcpkgPackages = $true, # install vcpkg packages, otherwise use local copy
    [bool] $isDebug = $false # build debug version of csharp bindings
)

# reset previous imports
Remove-Module *
# using predefined set of helper functions
Import-Module (Resolve-Path "functions.psm1") -Force
# reset session
Reset-PsSession

Import-Module (Resolve-Path "partials.psm1") -Force

Push-Location -StackName "gdal.netcore|root"

$existingVariables = Get-Variable
try { 
    $ErrorActionPreference = 'Stop'
    # $ConfirmPreference = 'Low'
    # $VerbosePreference = Continue
    Install-PwshModuleRequirements 

    $env:BUILD_ROOT = (Get-ForceResolvePath "$PSScriptRoot\..\build-win")
    $env:7Z_ROOT = (Get-ForceResolvePath "$env:BUILD_ROOT\7z")
    Add-EnvPath $env:7Z_ROOT

    $env:VCPKG_ROOT = (Get-ForceResolvePath "$env:BUILD_ROOT\vcpkg")
    Add-EnvPath $env:VCPKG_ROOT 

    Get-VcpkgInstallation -bootstrapVcpkg $bootstrapVcpkg
    
    Set-GdalVariables 
    
    Write-BuildStep "Setting Visual Studio Environment"
    Import-VisualStudioVars -VisualStudioVersion $env:VS_VER -Architecture $env:ARCHITECTURE
    Write-BuildStep "Visual Studio Environment was initialized"

    Install-VcpkgPackagesSharedConfig $installVcpkgPackages
    
    Get-7ZipInstallation
    Get-GdalSdkIsAvailable
    Resolve-GdalThidpartyLibs
    Install-Proj -cleanProjBuild $cleanProjBuild -cleanProjIntermediate $cleanProjIntermediate 
    
    Get-ProjDatum

    $env:INCLUDE = Add-EnvVar $env:INCLUDE "$env:SDK_PREFIX\include"
    $env:LIB = Add-EnvVar $env:LIB "$env:SDK_PREFIX\lib"
    Build-Gdal -cleanGdalBuild $cleanGdalBuild -cleanGdalIntermediate $cleanGdalIntermediate -fetchGdal $fetchGdal

    Build-CsharpBindings -isDebug $isDebug
} 
catch
{
    Write-BuildError "Something threw an exception"
    Write-Output $_
}
finally {
    Pop-Location -StackName "gdal.netcore|root"
    Get-Variable | Where-Object Name -notin $existingVariables.Name | Remove-Variable -ErrorAction SilentlyContinue
}