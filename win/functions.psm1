function exec {
    param ( [ScriptBlock] $ScriptBlock )
    & $ScriptBlock 2>&1 | ForEach-Object -Process { "$_" }
    if ($LastExitCode -ne 0) { exit $LastExitCode }
}

function Write-BuildInfo {
    param ( [string] $Message )
    Write-Host "[INFO] GDAL.NETCORE >> $Message" -ForegroundColor White
}

function Write-BuildStep {
    param ( [string] $Message )
    Write-Host "[STEP] GDAL.NETCORE >> $Message" -ForegroundColor Green
}

function Write-BuildError {
    param ( [string] $Message )
    Write-Host "[ERROR] GDAL.NETCORE >> $Message" -ForegroundColor Red
}

function Write-BuildWarn {
    param ( [string] $Message )
    Write-Host "[WARN] GDAL.NETCORE >> $Message" -ForegroundColor Yellow
}

function Add-EnvPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path, 

        [Parameter(Mandatory = $False)]
        [Switch] $Prepend
    )

    if (Test-Path -path "$Path") { 
        $envPaths = $env:PATH -split ';'
        if ($envPaths -notcontains $Path) {
            if ($Prepend) {
                $envPaths = , $Path + $envPaths | Where-Object { $_ }
                $env:PATH = $envPaths -join ';'
            }
            else {
                $envPaths = $envPaths + $Path | Where-Object { $_ }
                $env:PATH = $envPaths -join ';'
            }
        }
    }
}

function Add-EnvVar {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Target,     

        [Parameter(Mandatory = $true)]
        [string] $Path,    

        [Parameter(Mandatory = $False)]
        [Switch] $Prepend
    )

    if (Test-Path -path "$Path") { 
        $envPaths = $Target -split ';'
        if ($envPaths -notcontains $Path) {
            if ($Prepend) {
                $envPaths = , $Path + $envPaths | Where-Object { $_ }
                return $envPaths -join ';'
            }
            else {
                $envPaths = $envPaths + $Path | Where-Object { $_ }
                return $envPaths -join ';'
            }
        }
    }
    return $Target
}

function Set-ReplaceContentInFiles {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string[]] $FileFilter, 
        [Parameter(Mandatory = $true)]
        [string[]] $What,
        [Parameter(Mandatory = $true)]
        [string] $With
    )
    $fileNames = Get-ChildItem -Path $Path -Recurse -Include $FileFilter
    foreach ($file in $fileNames) { 
        $content = [System.IO.File]::ReadAllText($file.FullName);  
        foreach ($whatTo in $What) { 
            $content = $content.Replace($whatTo, $with)
        } 
        [System.IO.File]::WriteAllText($file.FullName, $content)
    }
}
function Set-ReplaceContentInFilesByRegex {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path,
        [Parameter(Mandatory = $true)]
        [string[]] $FileFilter, 
        [Parameter(Mandatory = $true)]
        [string[]] $Pattern,
        [Parameter(Mandatory = $true)]
        [string] $With
    )
    $fileNames = Get-ChildItem -Path $Path -Recurse -Include $FileFilter
    foreach ($file in $fileNames) { 
        # <input> -replace <original>, <substitute>
        $content = [System.IO.File]::ReadAllText($file.FullName);         
        $content = $content -replace $Pattern, $With            
        [System.IO.File]::WriteAllText($file.FullName, $content)
    }
}

function Reset-PsSession { 
    # clear current session as i'm testing this on a windows 11 machine. 
    Remove-Variable * -ErrorAction SilentlyContinue; 
    Remove-Module * 
    $error.Clear()
    # reload env path variable
    $env:PATH = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" `
        + [System.Environment]::GetEnvironmentVariable("Path", "User")  
}

function Install-PwshModuleRequirements {    
    Import-PackageProvider NuGet -Force
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    
    if (!(Get-Module "Pscx")) {        
        Install-Module Pscx -AllowClobber  
    }  
    
    if (!(Get-Module "VSSetup")) {  
        Install-Module VSSetup -Scope CurrentUser
    }
    
    if (!(Get-Module "7Zip4Powershell")) {
        Install-Module -Name 7Zip4Powershell -RequiredVersion 2.2.0 -Scope CurrentUser
    }

    if (!(Get-Module "WebKitDev")) {
        Install-Module -Name WebKitDev -RequiredVersion 0.4.0 -Force -Scope CurrentUser
    }
    
    if ($null -eq (Get-Command "choco" -ErrorAction SilentlyContinue)) {
        Install-Module -Name Choco
    } 
    
    if ($null -eq (Get-Command "swig" -ErrorAction SilentlyContinue)) {
        exec { cinst -y --no-progress --force swig }
    }
}

function New-FolderIfNotExistsAndSetCurrentLocation {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )
    if (!(Test-Path -Path $Path)) {
        New-Item -ItemType Directory -Path $Path
    }
    Set-Location -Path $Path
}

function New-FolderIfNotExists {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )
    if (-Not (Test-Path -Path $Path -PathType Container)) { 
        # create folder sdk 
        [System.IO.Directory]::CreateDirectory($Path) | Out-Null
    }      
}

function Get-CloneAndCheckoutCleanGitRepo {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Url, 
        [Parameter(Mandatory = $true)]
        [string] $Branch,
        [Parameter(Mandatory = $true)]
        [string] $Path 
    )
    
    Push-Location -StackName "gdal.netcore|root"
    New-FolderIfNotExistsAndSetCurrentLocation $Path
 
    if (-Not (Test-Path -Path $Path -PathType Container) -or 
         (Get-ChildItem $Path | Measure-Object).Count -eq 0) { 
        git clone -b $Branch -c core.longpaths=true $Url .
    } 
    git checkout -fq $Branch
    git reset --hard
    git clean -fdx
    Pop-Location -StackName "gdal.netcore|root"
}

function Get-ForceResolvePath {
    <#
    .SYNOPSIS
        Calls Resolve-Path but works for files that don't exist.
    .REMARKS
        From http://devhawk.net/blog/2010/1/22/fixing-powershells-busted-resolve-path-cmdlet
    #>
    param (
        [string] $FileName
    )

    $FileName = Resolve-Path $FileName -ErrorAction SilentlyContinue `
        -ErrorVariable _frperror
    if (-not($FileName)) {
        $FileName = $_frperror[0].TargetObject
    }

    return $FileName
}