<#
.SYNOPSIS
    Mounts WinPE or WinRE WIM images for customization.

.DESCRIPTION
    This script mounts Windows Preinstallation Environment (WinPE) or
    Windows Recovery Environment (WinRE) WIM images to a specified mount point
    for customization and modification.
    
    Supports both ADK-based WinPE and extracted WinRE images with full
    validation and error handling.

.PARAMETER WimPath
    Path to the WIM file to mount (winpe.wim or winre.wim).

.PARAMETER MountPath
    Directory where the WIM will be mounted. Created if it doesn't exist.

.PARAMETER Index
    WIM image index to mount (default: 1).

.PARAMETER ReadOnly
    Mount the WIM in read-only mode.

.PARAMETER Force
    Force remount if path is already in use.

.EXAMPLE
    .\WinPE-Mount.ps1 -WimPath "C:\WinPE\winpe.wim" -MountPath "C:\Mount"
    Mounts WinPE image to C:\Mount directory.

.EXAMPLE
    .\WinPE-Mount.ps1 -WimPath "C:\Recovery\winre.wim" -MountPath "C:\Mount" -ReadOnly
    Mounts WinRE image in read-only mode.

.NOTES
    Author: Better11 Development Team
    Version: 1.0.0
    Part of: WinPE PowerBuilder Suite
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Leaf })]
    [string]$WimPath,

    [Parameter(Mandatory = $true)]
    [string]$MountPath,

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 10)]
    [int]$Index = 1,

    [Parameter(Mandatory = $false)]
    [switch]$ReadOnly,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# INITIALIZATION
# ============================================================================

$ErrorActionPreference = 'Stop'
$scriptName = 'WinPE-Mount'
$scriptVersion = '1.0.0'

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
# MOUNT FUNCTIONS
# ============================================================================

function Test-MountPoint {
    <#
    .SYNOPSIS
        Checks if a mount point is currently in use.
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
        Write-Log "Error checking mount point status: $($_.Exception.Message)" -Level 'WARN'
        return $false
    }
}

function Dismount-ExistingWim {
    <#
    .SYNOPSIS
        Dismounts an existing WIM from a mount point.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Log "Attempting to dismount existing WIM from: $Path" -Level 'WARN'

    try {
        $dismountResult = dism /Unmount-Wim /MountDir:$Path /Discard 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Log "Successfully dismounted existing WIM" -Level 'SUCCESS'
            return $true
        } else {
            Write-Log "Failed to dismount existing WIM (Exit code: $exitCode)" -Level 'ERROR'
            $dismountResult | ForEach-Object { Write-Log $_ -Level 'ERROR' }
            return $false
        }
    } catch {
        Write-Log "Error during dismount: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Mount-WimImage {
    <#
    .SYNOPSIS
        Mounts a WIM image to the specified mount point.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WimFile,

        [Parameter(Mandatory = $true)]
        [string]$MountDirectory,

        [Parameter(Mandatory = $true)]
        [int]$ImageIndex,

        [Parameter(Mandatory = $false)]
        [bool]$IsReadOnly
    )

    Write-Log "Mounting WIM image..." -Level 'INFO'
    Write-Log "  WIM File: $WimFile" -Level 'INFO'
    Write-Log "  Mount Point: $MountDirectory" -Level 'INFO'
    Write-Log "  Index: $ImageIndex" -Level 'INFO'
    Write-Log "  Read-Only: $IsReadOnly" -Level 'INFO'

    # Build DISM command
    $dismArgs = @(
        '/Mount-Wim',
        "/WimFile:$WimFile",
        "/Index:$ImageIndex",
        "/MountDir:$MountDirectory"
    )

    if ($IsReadOnly) {
        $dismArgs += '/ReadOnly'
    }

    try {
        # Execute mount command
        $mountResult = & dism $dismArgs 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Log "WIM mounted successfully" -Level 'SUCCESS'
            return $true
        } else {
            Write-Log "DISM mount failed (Exit code: $exitCode)" -Level 'ERROR'
            $mountResult | ForEach-Object { Write-Log $_ -Level 'ERROR' }
            return $false
        }
    } catch {
        Write-Log "Error executing DISM: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Get-WimImageInfo {
    <#
    .SYNOPSIS
        Retrieves information about a WIM file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WimFile,

        [Parameter(Mandatory = $true)]
        [int]$ImageIndex
    )

    Write-Log "Retrieving WIM image information..." -Level 'INFO'

    try {
        $wimInfo = dism /Get-WimInfo /WimFile:$WimFile /Index:$ImageIndex 2>&1 | Out-String

        if ($LASTEXITCODE -eq 0) {
            # Parse WIM info
            $info = @{
                Valid = $true
            }

            if ($wimInfo -match 'Name\s*:\s*(.+)') {
                $info.Name = $matches[1].Trim()
            }

            if ($wimInfo -match 'Description\s*:\s*(.+)') {
                $info.Description = $matches[1].Trim()
            }

            if ($wimInfo -match 'Size\s*:\s*([\d,]+)') {
                $sizeStr = $matches[1].Replace(',', '')
                $info.SizeBytes = [long]$sizeStr
                $info.SizeMB = [math]::Round([long]$sizeStr / 1MB, 2)
            }

            if ($wimInfo -match 'Architecture\s*:\s*(.+)') {
                $info.Architecture = $matches[1].Trim()
            }

            Write-Log "WIM Image Name: $($info.Name)" -Level 'INFO'
            Write-Log "WIM Image Size: $($info.SizeMB) MB" -Level 'INFO'
            Write-Log "WIM Architecture: $($info.Architecture)" -Level 'INFO'

            return [PSCustomObject]$info
        } else {
            Write-Log "Failed to retrieve WIM information" -Level 'ERROR'
            return $null
        }
    } catch {
        Write-Log "Error retrieving WIM info: $($_.Exception.Message)" -Level 'ERROR'
        return $null
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level 'INFO'
    Write-Log "$scriptName v$scriptVersion" -Level 'INFO'
    Write-Log "WIM Image Mount Utility" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    # Validate WIM file
    Write-Log "Validating WIM file: $WimPath" -Level 'INFO'
    
    if (-not (Test-Path $WimPath)) {
        throw "WIM file not found: $WimPath"
    }

    $wimFileInfo = Get-Item $WimPath
    Write-Log "WIM file size: $([math]::Round($wimFileInfo.Length / 1MB, 2)) MB" -Level 'INFO'

    # Get WIM image information
    $wimImageInfo = Get-WimImageInfo -WimFile $WimPath -ImageIndex $Index

    if (-not $wimImageInfo -or -not $wimImageInfo.Valid) {
        throw "Invalid WIM file or index: $WimPath (Index: $Index)"
    }

    # Create mount directory if it doesn't exist
    if (-not (Test-Path $MountPath)) {
        Write-Log "Creating mount directory: $MountPath" -Level 'INFO'
        New-Item -Path $MountPath -ItemType Directory -Force | Out-Null
    }

    # Check if mount point is already in use
    if (Test-MountPoint -Path $MountPath) {
        Write-Log "Mount point is already in use: $MountPath" -Level 'WARN'

        if ($Force) {
            if (-not (Dismount-ExistingWim -Path $MountPath)) {
                throw "Failed to dismount existing WIM from mount point"
            }
        } else {
            throw "Mount point is already in use. Use -Force to dismount existing image."
        }
    }

    # Ensure mount directory is empty
    $mountContents = Get-ChildItem -Path $MountPath -Force -ErrorAction SilentlyContinue
    if ($mountContents) {
        Write-Log "Mount directory is not empty" -Level 'WARN'
        
        if ($Force) {
            Write-Log "Cleaning mount directory..." -Level 'INFO'
            Remove-Item -Path "$MountPath\*" -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            throw "Mount directory is not empty. Use -Force to clean it."
        }
    }

    # Mount the WIM
    $mountSuccess = Mount-WimImage `
        -WimFile $WimPath `
        -MountDirectory $MountPath `
        -ImageIndex $Index `
        -IsReadOnly:$ReadOnly

    if (-not $mountSuccess) {
        throw "Failed to mount WIM image"
    }

    # Verify mount
    Write-Log "Verifying mount..." -Level 'INFO'
    
    $mountVerify = Test-MountPoint -Path $MountPath
    if ($mountVerify) {
        Write-Log "Mount verified successfully" -Level 'SUCCESS'
    } else {
        Write-Log "Mount verification failed" -Level 'ERROR'
        throw "Mount verification failed"
    }

    # Display mount information
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Mount Operation Complete" -Level 'SUCCESS'
    Write-Log "========================================" -Level 'INFO'
    Write-Log "WIM Path: $WimPath" -Level 'INFO'
    Write-Log "Mount Path: $MountPath" -Level 'INFO'
    Write-Log "Index: $Index" -Level 'INFO'
    Write-Log "Read-Only: $ReadOnly" -Level 'INFO'
    Write-Log "Image Name: $($wimImageInfo.Name)" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    # Return mount information
    return [PSCustomObject]@{
        Success = $true
        WimPath = $WimPath
        MountPath = $MountPath
        Index = $Index
        ReadOnly = $ReadOnly.IsPresent
        ImageInfo = $wimImageInfo
        Timestamp = Get-Date -Format 'o'
    }

} catch {
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "Mount operation failed" -Level 'ERROR'
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "Error: $($_.Exception.Message)" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
    
    # Cleanup on failure
    if (Test-Path $MountPath) {
        Write-Log "Attempting cleanup of mount directory..." -Level 'WARN'
        try {
            dism /Cleanup-Wim 2>&1 | Out-Null
        } catch {
            Write-Log "Cleanup failed: $($_.Exception.Message)" -Level 'WARN'
        }
    }
    
    exit 1
}
