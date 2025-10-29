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

function Get-VisualStudioVars {
    Write-BuildStep "Setting Visual Studio Environment"
    Import-VisualStudioVars -Architecture $env:CMAKE_ARCHITECTURE
    Write-BuildStep "Visual Studio Environment was initialized"
}

function Clear-EnvPathDuplicates {
    $envPaths = $env:PATH -split ';' | Where-Object { $_ } | Select-Object -Unique
    $env:PATH = $envPaths -join ';'
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
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        exec { Set-ExecutionPolicy Bypass -Scope Process -Force; `
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; `
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')) }
    }

    if (!(Get-Command make -ErrorAction SilentlyContinue)) {
        exec { choco install -y --no-progress --force make } 
        Write-Information "GNUmake was installed"
    }
    
    if (!(Get-Command cmake -ErrorAction SilentlyContinue)) {
        exec { choco install cmake.install --force -y --no-progress --installargs '"ADD_CMAKE_TO_PATH=System"' } 
        Write-Information "CMake was installed"
    }

    if (!(Get-PackageProvider -Name "NuGet" -Force -ErrorAction SilentlyContinue)) {
        Import-PackageProvider NuGet -Scope CurrentUser
    } 

    if (!(Get-PSRepository -Name "PSGallery" -ErrorAction SilentlyContinue)) {
        Set-PSRepository -Name PSGallery -InstallationPolicy Trusted
    }

    if (!(Get-Module -Name "VSSetup" -ErrorAction SilentlyContinue)) {
        Install-Module -Name VSSetup -RequiredVersion 2.2.5 -Scope CurrentUser -Force
    } 

    if (!(Get-Module -Name "Pscx" -ErrorAction SilentlyContinue)) {        
        Install-Module -Name Pscx -AllowClobber -AllowPrerelease -Scope CurrentUser -Force
    }

    if (!(Get-Command "Invoke-WebRequest" -ErrorAction SilentlyContinue)) {
        Install-Module -Name WebKitDev -RequiredVersion 0.4.0 -Force -Scope CurrentUser
    }
    
    if (!(Get-Command "choco" -ErrorAction SilentlyContinue)) {
        Install-Module -Name Choco -Scope CurrentUser -Force
    } 
    
    if (!(Get-Command "swig" -ErrorAction SilentlyContinue)) {
        exec { choco install -y --no-progress --force swig }
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
        [string] $CurrentPath 
    )
    
    Write-BuildStep "Cloning/updating Git repository from $Url (branch: $Branch)"
    Push-Location -StackName "gdal.netcore|root"
    
    try {
        New-FolderIfNotExistsAndSetCurrentLocation $CurrentPath

        $isEmpty = (Get-ChildItem $CurrentPath -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0
        $isGitRepo = Test-Path -Path (Join-Path $CurrentPath ".git") -PathType Container
        if (-Not (Test-Path -Path $CurrentPath -PathType Container) -or $isEmpty -or -Not $isGitRepo) {
            Write-BuildInfo "Cloning repository into $CurrentPath"
            exec { git clone -b $Branch -c core.longpaths=true $Url . }
        } else {
            Write-BuildInfo "Repository already exists, updating..."
        }
        
        exec { git checkout -fq $Branch }
        exec { git reset --hard }
        exec { git clean -fdx }
        
        Write-BuildInfo "Repository ready at $CurrentPath"
    }
    catch {
        Write-BuildError "Failed to clone/update repository: $_"
        throw
    }
    finally {
        Pop-Location -StackName "gdal.netcore|root"
    }
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

function Get-PathRelative {
    param (
        [bool] $isDebug = $false,
        [string] $inputPath,
        [string] $relativePath
    )
    $path = $inputPath -replace [regex]::escape($env:BUILD_ROOT), $relativePath ;
    return $path -replace '\\', '/'
}