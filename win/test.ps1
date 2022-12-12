param (
    [bool] $preRelease = $true 
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

    Import-VisualStudioVars -VisualStudioVersion $env:VS_VER -Architecture $env:ARCHITECTURE
    $preReleaseArg = ""
    if ($preRelease){
        $preReleaseArg = "PRE_RELEASE=1"
    }
    nmake -f "$PSScriptRoot/test-makefile.vc" $preReleaseArg
}
finally {
    Pop-Location -StackName "gdal.netcore|root"
    Get-Variable |
    Where-Object Name -notin $existingVariables.Name |
    Remove-Variable
}