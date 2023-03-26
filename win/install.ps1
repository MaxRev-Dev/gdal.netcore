# Usage .\install.ps1 -cleanGdalBuild:$true -cleanGdalIntermediate:$true -cleanProjBuild:$true -bootstrapVcpkg:$true
param (
    [bool] $cleanGdalBuild = $true, 
    [bool] $cleanGdalIntermediate = $true, 
    [bool] $cleanProjBuild = $true,
    [bool] $cleanProjIntermediate = $true,
    [bool] $bootstrapVcpkg = $true,
    [bool] $installVcpkgPackages = $true,
    [bool] $isDebug = $false
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
    Install-PwshModuleRequirements
    
    # echo $env:PATH
    # echo $env:ARCH_FLAGS
    # echo $env:LIB
    # echo $env:INCLUDE 

    $env:BUILD_ROOT = (Get-ForceResolvePath "$PSScriptRoot\..\build-win")
    $env:7Z_ROOT = (Get-ForceResolvePath "$env:BUILD_ROOT\7z")
    Add-EnvPath $env:7Z_ROOT

    $env:VCPKG_ROOT = (Get-ForceResolvePath "$env:BUILD_ROOT\vcpkg")
    Add-EnvPath $env:VCPKG_ROOT 

    Get-VcpkgInstallation $bootstrapVcpkg
    
    $ErrorActionPreference = 'Stop'
    # $ConfirmPreference = 'Low'
    # $VerbosePreference = Continue
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
    Build-Gdal $cleanGdalBuild $cleanGdalIntermediate

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