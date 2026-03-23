<#
.SYNOPSIS
    Unmounts WinPE or WinRE WIM images with commit or discard options.

.DESCRIPTION
    This script safely unmounts Windows Preinstallation Environment (WinPE) or
    Windows Recovery Environment (WinRE) WIM images, allowing you to either
    commit changes or discard them.
    
    Includes validation, error handling, and cleanup operations to ensure
    the WIM image is properly unmounted and no residual mounts remain.

.PARAMETER MountPath
    Directory where the WIM is currently mounted.

.PARAMETER Commit
    Commit changes to the WIM file (default behavior).

.PARAMETER Discard
    Discard all changes made to the mounted WIM.

.PARAMETER Force
    Force unmount even if errors occur during standard unmount.

.EXAMPLE
    .\WinPE-Unmount.ps1 -MountPath "C:\Mount" -Commit
    Unmounts WIM and commits all changes.

.EXAMPLE
    .\WinPE-Unmount.ps1 -MountPath "C:\Mount" -Discard
    Unmounts WIM and discards all changes.

.EXAMPLE
    .\WinPE-Unmount.ps1 -MountPath "C:\Mount" -Force
    Force unmounts WIM with commit.

.NOTES
    Author: Better11 Development Team
    Version: 1.0.0
    Part of: WinPE PowerBuilder Suite
#>

[CmdletBinding(DefaultParameterSetName = 'Commit')]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$MountPath,

    [Parameter(ParameterSetName = 'Commit')]
    [switch]$Commit,

    [Parameter(ParameterSetName = 'Discard')]
    [switch]$Discard,

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# INITIALIZATION
# ============================================================================

$ErrorActionPreference = 'Stop'
$scriptName = 'WinPE-Unmount'
$scriptVersion = '1.0.0'

# Default to commit if neither specified
if (-not $Commit -and -not $Discard) {
    $Commit = $true
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
# UNMOUNT FUNCTIONS
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

function Get-MountedWimInfo {
    <#
    .SYNOPSIS
        Retrieves information about the mounted WIM.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Write-Log "Retrieving mounted WIM information..." -Level 'INFO'

    try {
        $dismInfo = dism /Get-MountedWimInfo 2>&1 | Out-String

        if ($LASTEXITCODE -eq 0) {
            # Parse mount info
            $info = @{
                Found = $false
            }

            # Split into sections for each mounted image
            $sections = $dismInfo -split 'Mount Dir :'
            
            foreach ($section in $sections) {
                if ($section -match [regex]::Escape($Path)) {
                    $info.Found = $true

                    if ($section -match 'Image File\s*:\s*(.+)') {
                        $info.ImageFile = $matches[1].Trim()
                    }

                    if ($section -match 'Image Index\s*:\s*(\d+)') {
                        $info.ImageIndex = [int]$matches[1]
                    }

                    if ($section -match 'Mounted Read/Write\s*:\s*(.+)') {
                        $info.ReadWrite = $matches[1].Trim() -eq 'Yes'
                    }

                    if ($section -match 'Status\s*:\s*(.+)') {
                        $info.Status = $matches[1].Trim()
                    }

                    break
                }
            }

            if ($info.Found) {
                Write-Log "Found mounted WIM:" -Level 'INFO'
                Write-Log "  Image File: $($info.ImageFile)" -Level 'INFO'
                Write-Log "  Image Index: $($info.ImageIndex)" -Level 'INFO'
                Write-Log "  Read/Write: $($info.ReadWrite)" -Level 'INFO'
                Write-Log "  Status: $($info.Status)" -Level 'INFO'
            }

            return [PSCustomObject]$info
        } else {
            Write-Log "Failed to retrieve mounted WIM information" -Level 'WARN'
            return $null
        }
    } catch {
        Write-Log "Error retrieving mounted WIM info: $($_.Exception.Message)" -Level 'WARN'
        return $null
    }
}

function Dismount-WimImage {
    <#
    .SYNOPSIS
        Dismounts a WIM image with commit or discard option.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MountDirectory,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Commit', 'Discard')]
        [string]$Action
    )

    Write-Log "Unmounting WIM image..." -Level 'INFO'
    Write-Log "  Mount Directory: $MountDirectory" -Level 'INFO'
    Write-Log "  Action: $Action" -Level 'INFO'

    # Build DISM command
    $dismArgs = @(
        '/Unmount-Wim',
        "/MountDir:$MountDirectory"
    )

    if ($Action -eq 'Commit') {
        $dismArgs += '/Commit'
        Write-Log "Changes will be saved to the WIM file" -Level 'WARN'
    } else {
        $dismArgs += '/Discard'
        Write-Log "Changes will be discarded" -Level 'WARN'
    }

    try {
        # Execute unmount command
        Write-Log "Executing DISM unmount operation..." -Level 'INFO'
        $unmountResult = & dism $dismArgs 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Log "WIM unmounted successfully" -Level 'SUCCESS'
            return $true
        } else {
            Write-Log "DISM unmount failed (Exit code: $exitCode)" -Level 'ERROR'
            $unmountResult | ForEach-Object { Write-Log $_ -Level 'ERROR' }
            return $false
        }
    } catch {
        Write-Log "Error executing DISM: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

function Invoke-CleanupWim {
    <#
    .SYNOPSIS
        Performs cleanup operations on mounted WIM images.
    #>
    [CmdletBinding()]
    param()

    Write-Log "Performing WIM cleanup operations..." -Level 'INFO'

    try {
        $cleanupResult = dism /Cleanup-Wim 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            Write-Log "WIM cleanup completed successfully" -Level 'SUCCESS'
            return $true
        } else {
            Write-Log "WIM cleanup reported warnings or errors (Exit code: $exitCode)" -Level 'WARN'
            $cleanupResult | ForEach-Object { Write-Log $_ -Level 'WARN' }
            return $false
        }
    } catch {
        Write-Log "Error during WIM cleanup: $($_.Exception.Message)" -Level 'WARN'
        return $false
    }
}

function Remove-EmptyMountDirectory {
    <#
    .SYNOPSIS
        Removes the mount directory if it's empty.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    try {
        $contents = Get-ChildItem -Path $Path -Force -ErrorAction SilentlyContinue
        
        if (-not $contents) {
            Write-Log "Removing empty mount directory..." -Level 'INFO'
            Remove-Item -Path $Path -Force -ErrorAction Stop
            Write-Log "Mount directory removed successfully" -Level 'SUCCESS'
        } else {
            Write-Log "Mount directory is not empty, leaving it in place" -Level 'INFO'
        }
    } catch {
        Write-Log "Could not remove mount directory: $($_.Exception.Message)" -Level 'WARN'
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level 'INFO'
    Write-Log "$scriptName v$scriptVersion" -Level 'INFO'
    Write-Log "WIM Image Unmount Utility" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    # Validate mount path
    Write-Log "Validating mount path: $MountPath" -Level 'INFO'
    
    if (-not (Test-Path $MountPath)) {
        throw "Mount path not found: $MountPath"
    }

    # Check if mount point is actually mounted
    if (-not (Test-MountPoint -Path $MountPath)) {
        Write-Log "No WIM image is mounted at: $MountPath" -Level 'WARN'
        
        # Try cleanup anyway
        Write-Log "Attempting cleanup operations..." -Level 'INFO'
        Invoke-CleanupWim | Out-Null
        
        Write-Log "No active mount found at specified path" -Level 'INFO'
        exit 0
    }

    # Get mounted WIM information
    $mountInfo = Get-MountedWimInfo -Path $MountPath

    if (-not $mountInfo -or -not $mountInfo.Found) {
        Write-Log "Could not retrieve mount information" -Level 'WARN'
    }

    # Determine action
    $action = if ($Discard) { 'Discard' } else { 'Commit' }

    # Confirm action if committing
    if ($action -eq 'Commit' -and $mountInfo.ReadWrite) {
        Write-Log "========================================" -Level 'WARN'
        Write-Log "WARNING: About to commit changes to WIM" -Level 'WARN'
        Write-Log "========================================" -Level 'WARN'
        
        if ($mountInfo.ImageFile) {
            Write-Log "Target WIM: $($mountInfo.ImageFile)" -Level 'WARN'
        }
        
        Start-Sleep -Seconds 2
    }

    # Unmount the WIM
    $unmountSuccess = Dismount-WimImage `
        -MountDirectory $MountPath `
        -Action $action

    if (-not $unmountSuccess) {
        if ($Force) {
            Write-Log "Standard unmount failed, attempting force cleanup..." -Level 'WARN'
            
            # Try cleanup
            Invoke-CleanupWim | Out-Null
            
            # Check if mount is still present
            if (Test-MountPoint -Path $MountPath) {
                throw "Force unmount failed - mount point still in use"
            } else {
                Write-Log "Force cleanup successful" -Level 'SUCCESS'
            }
        } else {
            throw "Failed to unmount WIM image. Use -Force to attempt cleanup."
        }
    }

    # Perform cleanup
    Write-Log "Running post-unmount cleanup..." -Level 'INFO'
    Invoke-CleanupWim | Out-Null

    # Verify unmount
    Write-Log "Verifying unmount..." -Level 'INFO'
    
    $stillMounted = Test-MountPoint -Path $MountPath
    if ($stillMounted) {
        Write-Log "WARNING: Mount point may still be in use" -Level 'WARN'
    } else {
        Write-Log "Unmount verified successfully" -Level 'SUCCESS'
    }

    # Optionally remove mount directory
    Remove-EmptyMountDirectory -Path $MountPath

    # Display completion information
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Unmount Operation Complete" -Level 'SUCCESS'
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Mount Path: $MountPath" -Level 'INFO'
    Write-Log "Action: $action" -Level 'INFO'
    
    if ($mountInfo -and $mountInfo.ImageFile) {
        Write-Log "WIM File: $($mountInfo.ImageFile)" -Level 'INFO'
    }
    
    Write-Log "========================================" -Level 'INFO'

    # Return unmount information
    return [PSCustomObject]@{
        Success = $true
        MountPath = $MountPath
        Action = $action
        WimFile = $mountInfo.ImageFile
        Timestamp = Get-Date -Format 'o'
    }

} catch {
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "Unmount operation failed" -Level 'ERROR'
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "Error: $($_.Exception.Message)" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
    
    # Emergency cleanup attempt
    Write-Log "Attempting emergency cleanup..." -Level 'WARN'
    try {
        dism /Cleanup-Wim 2>&1 | Out-Null
    } catch {
        Write-Log "Emergency cleanup failed: $($_.Exception.Message)" -Level 'ERROR'
    }
    
    exit 1
}
