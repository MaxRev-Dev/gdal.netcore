param (
    [bool] $preRelease = $true ,
    [int] $buildNumberTail = 0 
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
    Set-GdalVariables

    Install-PwshModuleRequirements
    
    if (!(Get-Command "nmake" -ErrorAction SilentlyContinue)) {
        Import-VisualStudioVars -VisualStudioVersion $env:VS_VER -Architecture $env:ARCHITECTURE
    }

    $preReleaseArg = ""
    if ($preRelease){
        $preReleaseArg = "PRERELEASE=1"
    }
    if ($null -eq $env:GDAL_VERSION) {
        $env:GDAL_VERSION = Get-GdalVersion
    }
    $buildNumber = $buildNumberTail + 100
    $env:GDAL_PACKAGE_VERSION = "$env:GDAL_VERSION.$buildNumber"
    Write-BuildStep "Executing tests for $env:GDAL_PACKAGE_VERSION"
    exec { nmake -f "$PSScriptRoot/test-makefile.vc" $preReleaseArg GDAL_VERSION=$env:GDAL_VERSION PACKAGE_BUILD_NUMBER=$buildNumber }
}
finally {
    Pop-Location -StackName "gdal.netcore|root"
    Get-Variable | Where-Object Name -notin $existingVariables.Name | Remove-Variable -ErrorAction SilentlyContinue
}