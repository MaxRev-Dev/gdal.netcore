# Dot-source before collection. Record actual dependency-copy sources, recover
# nmake copy sources by name + SHA256, and check before import renaming.
# Remove retired allowances after warnings; add new SDK dependencies deliberately
# in sdk-allowlist.txt in the same PR. Entries are exact, case-insensitive names.
function Initialize-CollectedSources {
    param([string[]] $OutputDirectories, [string[]] $SourceDirectories)
    $ErrorActionPreference = 'Stop'
    $candidates = @{}
    foreach ($directory in $SourceDirectories) {
        if (-not $directory -or -not (Test-Path -LiteralPath $directory)) { continue }
        foreach ($file in Get-ChildItem -LiteralPath $directory -File -Recurse) {
            $candidates[$file.Name] = @($candidates[$file.Name]) + $file.FullName
        }
    }
    $sources = @{}
    foreach ($directory in $OutputDirectories) {
        foreach ($file in Get-ChildItem -LiteralPath $directory -File -Recurse) {
            $hash = (Get-FileHash -LiteralPath $file.FullName).Hash
            $matches = @($candidates[$file.Name] | Where-Object {
                $_ -and (Get-FileHash -LiteralPath $_).Hash -eq $hash
            })
            if (-not $matches.Count) { throw "Cannot identify collected source: $($file.FullName)" }
            $sources[$file.FullName] = $matches
        }
    }
    return $sources
}

function Confirm-NoUnexpectedSdkFiles {
    param(
        [string[]] $OutputDirectories,
        [hashtable] $Sources,
        [string] $SdkRoot,
        [string] $Allowlist = "$PSScriptRoot/sdk-allowlist.txt"
    )
    $ErrorActionPreference = 'Stop'
    $sdkPrefix = (Resolve-Path -LiteralPath $SdkRoot).Path.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    $allowed = @(Get-Content -LiteralPath $Allowlist | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') })
    $leaks = @{}
    $files = @(foreach ($directory in $OutputDirectories) {
        if (-not (Test-Path -LiteralPath $directory -PathType Container)) { throw "Missing output: $directory" }
        Get-ChildItem -LiteralPath $directory -File -Recurse
    })
    if (-not $files.Count) { throw 'No collected files to inspect' }
    foreach ($file in $files) {
        if (-not $Sources.ContainsKey($file.FullName)) { throw "Missing source provenance: $($file.FullName)" }
        # Hash recovery may find identical SDK and VS/vcpkg copies. An actual
        # dependency-copy record has one source; ambiguous recovered copies are
        # classified as SDK only when every candidate lives under the SDK.
        $sdkSources = @()
        $otherSources = @()
        foreach ($source in $Sources[$file.FullName]) {
            Write-Host "Collected: $($file.FullName) <= $source"
            if ([IO.Path]::GetFullPath($source).StartsWith($sdkPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                $sdkSources += $source
            }
            else { $otherSources += $source }
        }
        if ($sdkSources.Count -and -not $otherSources.Count) {
            $leaks[$file.Name] = $true
            Write-Host "SDK file: $($file.Name) <= $($sdkSources -join ', ')"
        }
    }
    foreach ($file in $files | Where-Object { $_.Extension -in '.dll', '.exe' }) {
        $imports = & dumpbin /nologo /dependents $file.FullName
        if ($LASTEXITCODE -ne 0) { throw "dumpbin failed for $($file.FullName)" }
        foreach ($line in $imports) {
            if ($line -notmatch '^\s+([^\s]+\.dll)\s*$') { continue }
            $name = $Matches[1]
            # Packaged DLLs take precedence over PATH/SDK; checking only SDK
            # filenames would falsely flag dependencies already moved to vcpkg.
            $packaged = @($files | Where-Object { $_.Name -ieq $name })
            if ($packaged.Count) {
                if ($leaks.ContainsKey($name)) { Write-Host "SDK import: $($file.Name) -> $name (packaged)" }
            }
            else {
                $resolved = $null
                foreach ($directory in @($file.DirectoryName) + @($env:PATH -split ';')) {
                    if (-not $directory) { continue }
                    $candidate = Join-Path $directory $name
                    if (Test-Path -LiteralPath $candidate -PathType Leaf) { $resolved = (Resolve-Path -LiteralPath $candidate).Path; break }
                }
                if ($resolved -and $resolved.StartsWith($sdkPrefix, [StringComparison]::OrdinalIgnoreCase)) {
                    $leaks[$name] = $true
                    Write-Host "SDK import: $($file.Name) -> $resolved (not packaged)"
                }
            }
        }
    }
    $unexpected = @($leaks.Keys | Where-Object { $_ -notin $allowed } | Sort-Object)
    foreach ($entry in $allowed) {
        if (-not $leaks.ContainsKey($entry)) { Write-Warning "SDK allowance no longer used: $entry (remove it from $Allowlist)" }
    }
    if ($unexpected.Count) { throw "Unexpected GisInternals SDK dependencies: $($unexpected -join ', ')" }
    Write-Host "SDK check passed: $($leaks.Count) allowlisted dependencies"
}
