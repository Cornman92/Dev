<#
.SYNOPSIS
    Injects Windows updates and packages into mounted WinPE or WinRE images.

.DESCRIPTION
    This script injects Windows update packages (.cab, .msu files) into
    a mounted Windows Preinstallation Environment (WinPE) or
    Windows Recovery Environment (WinRE) image using DISM.
    
    Supports cumulative updates, servicing stack updates, optional components,
    and language packs with comprehensive validation and error handling.

.PARAMETER MountPath
    Path to the mounted WIM image directory.

.PARAMETER UpdatePath
    Path to update file(s). Can be a file, directory, or comma-separated list.

.PARAMETER Recurse
    Recursively search for update packages in subdirectories.

.PARAMETER IgnoreErrors
    Continue processing even if individual updates fail.

.PARAMETER PreventPending
    Prevent reboot requirements (where applicable).

.EXAMPLE
    .\WinPE-InjectUpdates.ps1 -MountPath "C:\Mount" -UpdatePath "C:\Updates"
    Injects all updates from C:\Updates into mounted WinPE.

.EXAMPLE
    .\WinPE-InjectUpdates.ps1 -MountPath "C:\Mount" -UpdatePath "C:\Updates\SSU.msu,C:\Updates\CU.msu"
    Injects specific updates in order (SSU first, then CU).

.NOTES
    Author: Better11 Development Team
    Version: 1.0.0
    Part of: WinPE PowerBuilder Suite
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$MountPath,

    [Parameter(Mandatory = $true)]
    [string]$UpdatePath,

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [switch]$IgnoreErrors,

    [Parameter(Mandatory = $false)]
    [switch]$PreventPending
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# INITIALIZATION
# ============================================================================

$ErrorActionPreference = 'Stop'
$scriptName = 'WinPE-InjectUpdates'
$scriptVersion = '1.0.0'

# Statistics tracking
$script:stats = @{
    TotalAttempted = 0
    Successful = 0
    Failed = 0
    Skipped = 0
}

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        Writes formatted log messages to console.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS')]
        [string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'INFO'    { Write-Host $logMessage -ForegroundColor Cyan }
        'WARN'    { Write-Host $logMessage -ForegroundColor Yellow }
        'ERROR'   { Write-Host $logMessage -ForegroundColor Red }
        'SUCCESS' { Write-Host $logMessage -ForegroundColor Green }
    }
}

# ============================================================================
# VALIDATION FUNCTIONS
# ============================================================================

function Test-MountPoint {
    <#
    .SYNOPSIS
        Validates that the specified path is a mounted WIM.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $dismInfo = dism /Get-MountedWimInfo 2>&1 | Out-String
        
        if ($dismInfo -match [regex]::Escape($Path)) {
            return $true
        }
        
        return $false
    } catch {
        Write-Log "Error checking mount point: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Get-UpdateFiles {
    <#
    .SYNOPSIS
        Discovers update package files (.cab, .msu) in the specified path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RecursiveSearch
    )

    Write-Log "Scanning for update packages..." -Level 'INFO'
    Write-Log "  Path: $Path" -Level 'INFO'
    Write-Log "  Recursive: $RecursiveSearch" -Level 'INFO'

    $updateFiles = @()

    try {
        # Handle comma-separated paths
        if ($Path -like '*,*') {
            Write-Log "Processing multiple paths..." -Level 'INFO'
            $paths = $Path -split ',' | ForEach-Object { $_.Trim() }
            
            foreach ($p in $paths) {
                if (Test-Path $p) {
                    $item = Get-Item $p
                    if ($item.PSIsContainer) {
                        $files = Get-ChildItem -Path $p -Include @('*.cab', '*.msu') -File -Recurse:$RecursiveSearch -ErrorAction SilentlyContinue
                        $updateFiles += $files
                    } else {
                        $updateFiles += $item
                    }
                } else {
                    Write-Log "Path not found: $p" -Level 'WARN'
                }
            }
        } else {
            # Single path
            $pathItem = Get-Item $Path -ErrorAction Stop
            
            if ($pathItem.PSIsContainer) {
                # Directory
                $updateFiles = Get-ChildItem -Path $Path -Include @('*.cab', '*.msu') -File -Recurse:$RecursiveSearch -ErrorAction SilentlyContinue
            } else {
                # Single file
                if ($pathItem.Extension -in @('.cab', '.msu')) {
                    $updateFiles = @($pathItem)
                } else {
                    Write-Log "Invalid file type: $($pathItem.Extension). Must be .cab or .msu" -Level 'ERROR'
                }
            }
        }

        # Sort updates by priority (SSU first, then others)
        $sortedUpdates = $updateFiles | Sort-Object {
            $name = $_.Name.ToLower()
            if ($name -match 'ssu|servicing|stack') { 0 }
            elseif ($name -match 'cu|cumulative') { 1 }
            elseif ($name -match 'lp|language') { 2 }
            else { 3 }
        }

        if ($sortedUpdates) {
            Write-Log "Found $($sortedUpdates.Count) update package(s)" -Level 'SUCCESS'
            
            # Display update order
            for ($i = 0; $i -lt $sortedUpdates.Count; $i++) {
                Write-Log "  [$($i + 1)] $($sortedUpdates[$i].Name) ($([math]::Round($sortedUpdates[$i].Length / 1MB, 2)) MB)" -Level 'INFO'
            }
            
            return $sortedUpdates
        } else {
            Write-Log "No update packages (.cab, .msu) found" -Level 'WARN'
            return @()
        }
    } catch {
        Write-Log "Error scanning for updates: $($_.Exception.Message)" -Level 'ERROR'
        return @()
    }
}

function Get-PackageType {
    <#
    .SYNOPSIS
        Determines the type of update package.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileInfo]$File
    )

    $name = $File.Name.ToLower()
    
    if ($name -match 'ssu|servicing.?stack') {
        return 'ServicingStack'
    }
    elseif ($name -match 'cu|cumulative') {
        return 'Cumulative'
    }
    elseif ($name -match 'lp|language') {
        return 'LanguagePack'
    }
    elseif ($name -match 'fod|feature.?on.?demand') {
        return 'FeatureOnDemand'
    }
    elseif ($File.Extension -eq '.cab') {
        return 'Package'
    }
    elseif ($File.Extension -eq '.msu') {
        return 'Update'
    }
    else {
        return 'Unknown'
    }
}

# ============================================================================
# UPDATE INJECTION FUNCTIONS
# ============================================================================

function Add-PackageToImage {
    <#
    .SYNOPSIS
        Injects a single update package into the mounted WIM image.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

        [Parameter(Mandatory = $true)]
        [string]$PackagePath,

        [Parameter(Mandatory = $false)]
        [bool]$PreventReboot,

        [Parameter(Mandatory = $false)]
        [bool]$IgnoreError
    )

    $packageName = Split-Path $PackagePath -Leaf
    $packageType = Get-PackageType -File (Get-Item $PackagePath)
    
    Write-Log "Injecting package: $packageName" -Level 'INFO'
    Write-Log "  Type: $packageType" -Level 'INFO'
    Write-Log "  Size: $([math]::Round((Get-Item $PackagePath).Length / 1MB, 2)) MB" -Level 'INFO'

    # Build DISM command
    $dismArgs = @(
        '/Image:' + $ImagePath,
        '/Add-Package',
        '/PackagePath:' + $PackagePath
    )

    if ($PreventReboot) {
        $dismArgs += '/PreventPending'
    }

    # Set longer timeout for large updates
    $dismArgs += '/NoRestart'
    $dismArgs += '/Quiet'

    try {
        $startTime = Get-Date
        Write-Log "  Installing package..." -Level 'INFO'
        
        $packageResult = & dism $dismArgs 2>&1
        $exitCode = $LASTEXITCODE
        
        $duration = (Get-Date) - $startTime
        Write-Log "  Installation took $([math]::Round($duration.TotalSeconds, 1)) seconds" -Level 'INFO'

        if ($exitCode -eq 0) {
            Write-Log "  ✓ Successfully injected: $packageName" -Level 'SUCCESS'
            $script:stats.Successful++
            return $true
        }
        elseif ($exitCode -eq 3010) {
            Write-Log "  ✓ Package injected (pending restart): $packageName" -Level 'SUCCESS'
            $script:stats.Successful++
            return $true
        }
        elseif ($exitCode -eq 1641) {
            Write-Log "  ✓ Package injected successfully: $packageName" -Level 'SUCCESS'
            $script:stats.Successful++
            return $true
        }
        elseif ($exitCode -eq -2146498529 -or $exitCode -eq 0x800f081e) {
            Write-Log "  ⚠ Package already installed or not applicable: $packageName" -Level 'WARN'
            $script:stats.Skipped++
            return $true
        }
        else {
            Write-Log "  ✗ Failed to inject: $packageName (Exit code: $exitCode)" -Level 'ERROR'
            
            # Log error details
            $errorLines = $packageResult | Select-Object -Last 10
            foreach ($line in $errorLines) {
                if ($line -and $line.ToString().Trim()) {
                    Write-Log "    $line" -Level 'ERROR'
                }
            }
            
            $script:stats.Failed++
            
            if (-not $IgnoreError) {
                throw "Package injection failed for: $packageName"
            }
            
            return $false
        }
    } catch {
        Write-Log "  ✗ Error injecting package: $($_.Exception.Message)" -Level 'ERROR'
        $script:stats.Failed++
        
        if (-not $IgnoreError) {
            throw
        }
        
        return $false
    }
}

function Get-InstalledPackages {
    <#
    .SYNOPSIS
        Lists packages currently installed in the WIM image.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )

    Write-Log "Retrieving installed packages from image..." -Level 'INFO'

    try {
        $packageInfo = dism /Image:$ImagePath /Get-Packages 2>&1 | Out-String

        if ($LASTEXITCODE -eq 0) {
            # Count packages
            $packageMatches = [regex]::Matches($packageInfo, 'Package Identity\s*:\s*(.+)')
            $packageCount = $packageMatches.Count

            Write-Log "Image contains $packageCount package(s)" -Level 'INFO'

            return [PSCustomObject]@{
                Success = $true
                PackageCount = $packageCount
                RawOutput = $packageInfo
            }
        } else {
            Write-Log "Failed to retrieve package information" -Level 'WARN'
            return $null
        }
    } catch {
        Write-Log "Error retrieving packages: $($_.Exception.Message)" -Level 'WARN'
        return $null
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level 'INFO'
    Write-Log "$scriptName v$scriptVersion" -Level 'INFO'
    Write-Log "WinPE/WinRE Update Injection Utility" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    # Validate mount point
    Write-Log "Validating mount point: $MountPath" -Level 'INFO'
    
    if (-not (Test-MountPoint -Path $MountPath)) {
        throw "No WIM image is mounted at: $MountPath"
    }

    Write-Log "Mount point validated successfully" -Level 'SUCCESS'

    # Get update files
    $updateFiles = Get-UpdateFiles -Path $UpdatePath -RecursiveSearch:$Recurse

    if ($updateFiles.Count -eq 0) {
        throw "No update packages found to inject"
    }

    $script:stats.TotalAttempted = $updateFiles.Count

    # Get baseline package count
    Write-Log "Getting baseline package inventory..." -Level 'INFO'
    $baselinePackages = Get-InstalledPackages -ImagePath $MountPath

    # Inject updates
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Beginning Update Injection" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    $overallSuccess = $true

    for ($i = 0; $i -lt $updateFiles.Count; $i++) {
        $update = $updateFiles[$i]
        $progress = [math]::Round((($i + 1) / $updateFiles.Count) * 100, 1)
        
        Write-Log "----------------------------------------" -Level 'INFO'
        Write-Log "Progress: [$($i + 1)/$($updateFiles.Count)] ($progress%)" -Level 'INFO'
        Write-Log "----------------------------------------" -Level 'INFO'

        $success = Add-PackageToImage `
            -ImagePath $MountPath `
            -PackagePath $update.FullName `
            -PreventReboot:$PreventPending `
            -IgnoreError:$IgnoreErrors

        if (-not $success -and -not $IgnoreErrors) {
            $overallSuccess = $false
            break
        }
    }

    # Get post-injection package count
    Write-Log "Getting final package inventory..." -Level 'INFO'
    $finalPackages = Get-InstalledPackages -ImagePath $MountPath

    # Calculate changes
    $packagesAdded = if ($finalPackages -and $baselinePackages) {
        $finalPackages.PackageCount - $baselinePackages.PackageCount
    } else {
        'Unknown'
    }

    # Display results
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Update Injection Complete" -Level $(if ($overallSuccess) { 'SUCCESS' } else { 'WARN' }) 
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Statistics:" -Level 'INFO'
    Write-Log "  Total Attempted: $($script:stats.TotalAttempted)" -Level 'INFO'
    Write-Log "  Successful: $($script:stats.Successful)" -Level 'INFO'
    Write-Log "  Failed: $($script:stats.Failed)" -Level 'INFO'
    Write-Log "  Skipped: $($script:stats.Skipped)" -Level 'INFO'
    Write-Log "  Packages Added: $packagesAdded" -Level 'INFO'
    Write-Log "  Total Packages: $($finalPackages.PackageCount)" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    if ($script:stats.Failed -gt 0 -and -not $IgnoreErrors) {
        Write-Log "Some updates failed to install" -Level 'ERROR'
    }

    # Return results
    return [PSCustomObject]@{
        Success = $overallSuccess
        MountPath = $MountPath
        UpdatePath = $UpdatePath
        Statistics = $script:stats
        BaselinePackageCount = $baselinePackages.PackageCount
        FinalPackageCount = $finalPackages.PackageCount
        PackagesAdded = $packagesAdded
        Timestamp = Get-Date -Format 'o'
    }

} catch {
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "Update injection failed" -Level 'ERROR'
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "Error: $($_.Exception.Message)" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
    exit 1
}
