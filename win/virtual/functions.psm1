function exec {
    param ( [ScriptBlock] $ScriptBlock )
    & $ScriptBlock 2>&1 | ForEach-Object -Process { "$_" }
    if ($LastExitCode -ne 0) { exit $LastExitCode }
}

function Add-EnvPath {
    param(
        [Parameter(Mandatory = $true)]
        [string] $Path, 

        [Parameter(Mandatory = $False)]
        [Switch] $Prepend
    )

    if (Test-Path -path "$Path") { 
        $envPaths = $env:Path -split ';'
        if ($envPaths -notcontains $Path) {
            if ($Prepend) {
                $envPaths = , $Path + $envPaths | where { $_ }
                $env:Path = $envPaths -join ';'
            }
            else {
                $envPaths = $envPaths + $Path | where { $_ }
                $env:Path = $envPaths -join ';'
            }
        }
    }
}

function Assert-DetectIfAVX2 {
    cl  ./detect-avx2.c
    & ./detect-avx2.exe 
    if ($LastExitCode -eq 0) {
        echo "AVX2 available on CPU"
        echo "ARCH_FLAGS=/arch:AVX2" >> $GITHUB_ENV 
    }
    else {
        echo "AVX2 not available on CPU."
        echo "ARCH_FLAGS=" >> $GITHUB_ENV
    }
}

function Reset-PsSession { 
    # clear current session as i'm testing this on a windows 11 machine. 
    Remove-Variable * -ErrorAction SilentlyContinue; 
    Remove-Module *
    $error.Clear()
}

function Install-ModuleRequirements {    
    Import-PackageProvider NuGet -Force
    Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    Install-Module -Name 7Zip4PowerShell -Force
    Install-Module Pscx -AllowClobber  
    Install-Module VSSetup -Scope CurrentUser

    if (!(Get-Module "7Zip4Powershell")) {
        Install-Module -Name 7Zip4Powershell -RequiredVersion 2.2.0 -Scope CurrentUser
    }

    if (!(Get-Module "WebKitDev")) {
        Install-Module -Name WebKitDev -RequiredVersion 0.4.0 -Force -Scope CurrentUser
    }
    
    if ($null -eq (Get-Command "choco" -ErrorAction SilentlyContinue)) {
        Install-Module -Name Choco
    } 
}

function New-FolderIfNotExists {
    param (
        [Parameter(Mandatory = $true)]
        [string] $Path
    )
    if (-Not (Test-Path -Path $Path -PathType Container)) { 
        # create folder sdk 
        New-Item $Path -ItemType "directory"
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
    
    if (-Not (Test-Path -Path $Path -PathType Container)) { 
        git clone --depth=1 -b $Branch $Url $Path 
    }
    
    Push-Location -StackName "gdal.netcore|root"
    Set-Location $Path
    git checkout -fq $Branch
    git reset --hard
    git clean -fdx
    Pop-Location -StackName "gdal.netcore|root"
}