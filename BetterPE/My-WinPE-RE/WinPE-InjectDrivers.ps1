<#
.SYNOPSIS
    Injects drivers into mounted WinPE or WinRE images.

.DESCRIPTION
    This script injects device drivers (.inf files and associated binaries)
    into a mounted Windows Preinstallation Environment (WinPE) or
    Windows Recovery Environment (WinRE) image using DISM.
    
    Supports recursive driver folder scanning, validation, and comprehensive
    error handling with detailed logging.

.PARAMETER MountPath
    Path to the mounted WIM image directory.

.PARAMETER DriverPath
    Path to the directory containing driver files (.inf).
    Can be a single driver or a folder tree.

.PARAMETER Recurse
    Recursively search for drivers in subdirectories.

.PARAMETER ForceUnsigned
    Allow injection of unsigned drivers.

.EXAMPLE
    .\WinPE-InjectDrivers.ps1 -MountPath "C:\Mount" -DriverPath "C:\Drivers"
    Injects drivers from C:\Drivers into mounted WinPE.

.EXAMPLE
    .\WinPE-InjectDrivers.ps1 -MountPath "C:\Mount" -DriverPath "C:\Drivers" -Recurse
    Recursively injects all drivers from C:\Drivers and subdirectories.

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
    [ValidateScript({ Test-Path $_ })]
    [string]$DriverPath,

    [Parameter(Mandatory = $false)]
    [switch]$Recurse,

    [Parameter(Mandatory = $false)]
    [switch]$ForceUnsigned
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# INITIALIZATION
# ============================================================================

$ErrorActionPreference = 'Stop'
$scriptName = 'WinPE-InjectDrivers'
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

function Get-DriverFiles {
    <#
    .SYNOPSIS
        Discovers driver .inf files in the specified path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [bool]$RecursiveSearch
    )

    Write-Log "Scanning for driver files..." -Level 'INFO'
    Write-Log "  Path: $Path" -Level 'INFO'
    Write-Log "  Recursive: $RecursiveSearch" -Level 'INFO'

    try {
        if ($RecursiveSearch) {
            $driverFiles = Get-ChildItem -Path $Path -Filter "*.inf" -Recurse -File -ErrorAction SilentlyContinue
        } else {
            $driverFiles = Get-ChildItem -Path $Path -Filter "*.inf" -File -ErrorAction SilentlyContinue
        }

        if ($driverFiles) {
            Write-Log "Found $($driverFiles.Count) driver file(s)" -Level 'SUCCESS'
            return $driverFiles
        } else {
            Write-Log "No driver files (.inf) found in specified path" -Level 'WARN'
            return @()
        }
    } catch {
        Write-Log "Error scanning for drivers: $($_.Exception.Message)" -Level 'ERROR'
        return @()
    }
}

# ============================================================================
# DRIVER INJECTION FUNCTIONS
# ============================================================================

function Add-DriverToImage {
    <#
    .SYNOPSIS
        Injects a single driver into the mounted WIM image.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

        [Parameter(Mandatory = $true)]
        [string]$DriverInfPath,

        [Parameter(Mandatory = $false)]
        [bool]$AllowUnsigned
    )

    $driverName = Split-Path $DriverInfPath -Leaf
    Write-Log "Injecting driver: $driverName" -Level 'INFO'

    # Build DISM command
    $dismArgs = @(
        '/Image:' + $ImagePath,
        '/Add-Driver',
        '/Driver:' + $DriverInfPath
    )

    if ($AllowUnsigned) {
        $dismArgs += '/ForceUnsigned'
    }

    try {
        $driverResult = & dism $dismArgs 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Log "  ✓ Successfully injected: $driverName" -Level 'SUCCESS'
            $script:stats.Successful++
            return $true
        } elseif ($exitCode -eq 3010) {
            Write-Log "  ✓ Driver injected (reboot would be required): $driverName" -Level 'SUCCESS'
            $script:stats.Successful++
            return $true
        } else {
            Write-Log "  ✗ Failed to inject: $driverName (Exit code: $exitCode)" -Level 'ERROR'
            
            # Log first few lines of error
            $errorLines = $driverResult | Select-Object -First 5
            foreach ($line in $errorLines) {
                if ($line -and $line.ToString().Trim()) {
                    Write-Log "    $line" -Level 'ERROR'
                }
            }
            
            $script:stats.Failed++
            return $false
        }
    } catch {
        Write-Log "  ✗ Error injecting driver: $($_.Exception.Message)" -Level 'ERROR'
        $script:stats.Failed++
        return $false
    }
}

function Add-DriversFromPath {
    <#
    .SYNOPSIS
        Batch injects drivers from a directory using DISM /Recurse.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath,

        [Parameter(Mandatory = $true)]
        [string]$DriverDirectory,

        [Parameter(Mandatory = $false)]
        [bool]$RecursiveSearch,

        [Parameter(Mandatory = $false)]
        [bool]$AllowUnsigned
    )

    Write-Log "Batch injecting drivers from directory..." -Level 'INFO'
    Write-Log "  Directory: $DriverDirectory" -Level 'INFO'

    # Build DISM command for batch injection
    $dismArgs = @(
        '/Image:' + $ImagePath,
        '/Add-Driver',
        '/Driver:' + $DriverDirectory
    )

    if ($RecursiveSearch) {
        $dismArgs += '/Recurse'
    }

    if ($AllowUnsigned) {
        $dismArgs += '/ForceUnsigned'
    }

    try {
        Write-Log "Executing DISM batch driver injection..." -Level 'INFO'
        $batchResult = & dism $dismArgs 2>&1
        $exitCode = $LASTEXITCODE

        # Parse output for statistics
        $outputText = $batchResult | Out-String
        
        if ($outputText -match 'Successfully installed\s+(\d+)') {
            $successCount = [int]$matches[1]
            Write-Log "Batch injection completed: $successCount driver(s) installed" -Level 'SUCCESS'
            $script:stats.Successful += $successCount
        }

        if ($exitCode -eq 0 -or $exitCode -eq 3010) {
            Write-Log "Batch driver injection completed successfully" -Level 'SUCCESS'
            return $true
        } else {
            Write-Log "Batch driver injection completed with warnings (Exit code: $exitCode)" -Level 'WARN'
            
            # Log warnings
            $warningLines = $batchResult | Select-Object -First 10
            foreach ($line in $warningLines) {
                if ($line -and $line.ToString().Trim()) {
                    Write-Log "  $line" -Level 'WARN'
                }
            }
            
            return $false
        }
    } catch {
        Write-Log "Error during batch driver injection: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Get-InstalledDrivers {
    <#
    .SYNOPSIS
        Lists drivers currently installed in the WIM image.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImagePath
    )

    Write-Log "Retrieving installed drivers from image..." -Level 'INFO'

    try {
        $driverInfo = dism /Image:$ImagePath /Get-Drivers 2>&1 | Out-String

        if ($LASTEXITCODE -eq 0) {
            # Count drivers
            $driverMatches = [regex]::Matches($driverInfo, 'Published Name\s*:\s*(.+)')
            $driverCount = $driverMatches.Count

            Write-Log "Image contains $driverCount driver package(s)" -Level 'INFO'

            return [PSCustomObject]@{
                Success = $true
                DriverCount = $driverCount
                RawOutput = $driverInfo
            }
        } else {
            Write-Log "Failed to retrieve driver information" -Level 'WARN'
            return $null
        }
    } catch {
        Write-Log "Error retrieving drivers: $($_.Exception.Message)" -Level 'WARN'
        return $null
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level 'INFO'
    Write-Log "$scriptName v$scriptVersion" -Level 'INFO'
    Write-Log "WinPE/WinRE Driver Injection Utility" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    # Validate mount point
    Write-Log "Validating mount point: $MountPath" -Level 'INFO'
    
    if (-not (Test-MountPoint -Path $MountPath)) {
        throw "No WIM image is mounted at: $MountPath"
    }

    Write-Log "Mount point validated successfully" -Level 'SUCCESS'

    # Validate driver path
    Write-Log "Validating driver path: $DriverPath" -Level 'INFO'
    
    $driverPathItem = Get-Item $DriverPath
    $isDirectory = $driverPathItem.PSIsContainer

    # Get baseline driver count
    Write-Log "Getting baseline driver inventory..." -Level 'INFO'
    $baselineDrivers = Get-InstalledDrivers -ImagePath $MountPath

    # Inject drivers
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Beginning Driver Injection" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    if ($isDirectory) {
        # Directory - use batch injection
        Write-Log "Driver source is a directory" -Level 'INFO'
        
        $batchSuccess = Add-DriversFromPath `
            -ImagePath $MountPath `
            -DriverDirectory $DriverPath `
            -RecursiveSearch:$Recurse `
            -AllowUnsigned:$ForceUnsigned

        if (-not $batchSuccess) {
            Write-Log "Batch injection completed with warnings" -Level 'WARN'
        }

    } else {
        # Single INF file
        Write-Log "Driver source is a single .inf file" -Level 'INFO'
        
        if ($driverPathItem.Extension -ne '.inf') {
            throw "Driver file must be an .inf file"
        }

        $script:stats.TotalAttempted = 1
        
        $success = Add-DriverToImage `
            -ImagePath $MountPath `
            -DriverInfPath $DriverPath `
            -AllowUnsigned:$ForceUnsigned

        if (-not $success) {
            Write-Log "Driver injection failed" -Level 'ERROR'
        }
    }

    # Get post-injection driver count
    Write-Log "Getting final driver inventory..." -Level 'INFO'
    $finalDrivers = Get-InstalledDrivers -ImagePath $MountPath

    # Calculate changes
    $driversAdded = if ($finalDrivers -and $baselineDrivers) {
        $finalDrivers.DriverCount - $baselineDrivers.DriverCount
    } else {
        'Unknown'
    }

    # Display results
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Driver Injection Complete" -Level 'SUCCESS'
    Write-Log "========================================" -Level 'INFO'
    
    if ($script:stats.TotalAttempted -gt 0) {
        Write-Log "Statistics:" -Level 'INFO'
        Write-Log "  Attempted: $($script:stats.TotalAttempted)" -Level 'INFO'
        Write-Log "  Successful: $($script:stats.Successful)" -Level 'INFO'
        Write-Log "  Failed: $($script:stats.Failed)" -Level 'INFO'
    }
    
    Write-Log "  Drivers Added to Image: $driversAdded" -Level 'INFO'
    Write-Log "  Total Drivers in Image: $($finalDrivers.DriverCount)" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    # Return results
    return [PSCustomObject]@{
        Success = ($script:stats.Failed -eq 0)
        MountPath = $MountPath
        DriverPath = $DriverPath
        Statistics = $script:stats
        BaselineDriverCount = $baselineDrivers.DriverCount
        FinalDriverCount = $finalDrivers.DriverCount
        DriversAdded = $driversAdded
        Timestamp = Get-Date -Format 'o'
    }

} catch {
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "Driver injection failed" -Level 'ERROR'
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "Error: $($_.Exception.Message)" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
    exit 1
}
