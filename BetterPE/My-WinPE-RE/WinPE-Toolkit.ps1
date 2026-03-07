<#
.SYNOPSIS
    Comprehensive WinPE/WinRE PowerBuilder Toolkit - All-in-one utility.

.DESCRIPTION
    This monolithic script combines all WinPE PowerBuilder Suite functionality
    into a single convenient tool. It provides a unified interface for:
    
    - Detecting ADK WinPE and WinRE environments
    - Mounting and unmounting WIM images
    - Injecting drivers and updates
    - Creating bootable USB drives
    - Customizing WinRE with toolkit integration
    
    Use the -Command parameter to select which operation to perform,
    or run interactively for a menu-driven experience.

.PARAMETER Command
    The operation to perform: Detect, Mount, Unmount, InjectDrivers,
    InjectUpdates, CreateUSB, CustomizeWinRE, or Interactive.

.EXAMPLE
    .\WinPE-Toolkit.ps1 -Command Detect
    Detects available WinPE/WinRE environments.

.EXAMPLE
    .\WinPE-Toolkit.ps1 -Command Mount -WimPath "C:\winpe.wim" -MountPath "C:\Mount"
    Mounts a WIM image.

.EXAMPLE
    .\WinPE-Toolkit.ps1 -Command Interactive
    Launches interactive menu mode.

.NOTES
    Author: Better11 Development Team
    Version: 1.0.0
    Part of: WinPE PowerBuilder Suite
    
    This is a monolithic version containing all helper functions.
    Individual modular scripts are also available in their respective folders.
#>

[CmdletBinding(DefaultParameterSetName='Interactive')]
param(
    [Parameter(ParameterSetName='Command', Mandatory=$true)]
    [ValidateSet('Detect', 'Mount', 'Unmount', 'InjectDrivers', 'InjectUpdates', 
                 'CreateUSB', 'CustomizeWinRE', 'Interactive')]
    [string]$Command,

    # Common parameters
    [Parameter(ParameterSetName='Command')]
    [string]$WimPath,

    [Parameter(ParameterSetName='Command')]
    [string]$MountPath,

    [Parameter(ParameterSetName='Command')]
    [string]$DriverPath,

    [Parameter(ParameterSetName='Command')]
    [string]$UpdatePath,

    [Parameter(ParameterSetName='Command')]
    [string]$SourcePath,

    [Parameter(ParameterSetName='Command')]
    [string]$TargetDrive,

    [Parameter(ParameterSetName='Command')]
    [switch]$Recurse,

    [Parameter(ParameterSetName='Command')]
    [switch]$Force,

    [Parameter(ParameterSetName='Command')]
    [switch]$Commit,

    [Parameter(ParameterSetName='Command')]
    [switch]$Discard
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# GLOBAL INITIALIZATION
# ============================================================================

$ErrorActionPreference = 'Stop'
$script:ToolkitVersion = '1.0.0'
$script:ToolkitName = 'WinPE PowerBuilder Toolkit'

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================

function Write-Log {
    <#
    .SYNOPSIS
        Centralized logging function for the toolkit.
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

function Show-Banner {
    <#
    .SYNOPSIS
        Displays the toolkit banner.
    #>
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "║          WinPE PowerBuilder Toolkit v$script:ToolkitVersion          ║" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "║    Complete Windows Preinstallation Environment Suite    ║" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# DETECTION FUNCTIONS
# ============================================================================

function Invoke-WinPEDetect {
    <#
    .SYNOPSIS
        Detects available WinPE environments (ADK WinPE and WinRE).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$CustomADKPath,

        [Parameter(Mandatory = $false)]
        [string]$CustomWinREPath
    )

    Write-Log "Detecting WinPE environments..." -Level 'INFO'

    # Detect ADK WinPE
    $defaultADKPath = "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
    $adkPath = if ($CustomADKPath) { $CustomADKPath } else { $defaultADKPath }

    $adkResult = $null
    if (Test-Path $adkPath) {
        $copypeCmd = Join-Path $adkPath "copype.cmd"
        $winpeWim = Join-Path $adkPath "amd64\en-us\winpe.wim"

        if ((Test-Path $copypeCmd) -and (Test-Path $winpeWim)) {
            Write-Log "✓ ADK WinPE detected" -Level 'SUCCESS'
            $adkResult = [PSCustomObject]@{
                Type = 'ADK'
                Path = $adkPath
                WimPath = $winpeWim
                Available = $true
            }
        }
    }

    # Detect WinRE
    $winreLocations = @(
        "$env:SystemRoot\System32\Recovery\Winre.wim",
        "C:\Recovery\WindowsRE\Winre.wim"
    )

    if ($CustomWinREPath) {
        $winreLocations = @($CustomWinREPath) + $winreLocations
    }

    $winreResult = $null
    foreach ($location in $winreLocations) {
        if (Test-Path $location) {
            Write-Log "✓ WinRE detected at: $location" -Level 'SUCCESS'
            $winreResult = [PSCustomObject]@{
                Type = 'WinRE'
                WimPath = $location
                Available = $true
                SizeMB = [math]::Round((Get-Item $location).Length / 1MB, 2)
            }
            break
        }
    }

    return [PSCustomObject]@{
        ADK = $adkResult
        WinRE = $winreResult
        HasADK = ($null -ne $adkResult)
        HasWinRE = ($null -ne $winreResult)
    }
}

# ============================================================================
# MOUNT/UNMOUNT FUNCTIONS
# ============================================================================

function Invoke-WinPEMount {
    <#
    .SYNOPSIS
        Mounts a WIM image for customization.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WimFile,

        [Parameter(Mandatory = $true)]
        [string]$MountDirectory,

        [Parameter(Mandatory = $false)]
        [int]$Index = 1,

        [Parameter(Mandatory = $false)]
        [switch]$ReadOnly
    )

    Write-Log "Mounting WIM: $WimFile" -Level 'INFO'
    Write-Log "Mount Point: $MountDirectory" -Level 'INFO'

    # Create mount directory
    if (-not (Test-Path $MountDirectory)) {
        New-Item -Path $MountDirectory -ItemType Directory -Force | Out-Null
    }

    # Build DISM command
    $dismArgs = @(
        '/Mount-Wim',
        "/WimFile:$WimFile",
        "/Index:$Index",
        "/MountDir:$MountDirectory"
    )

    if ($ReadOnly) {
        $dismArgs += '/ReadOnly'
    }

    # Execute mount
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
}

function Invoke-WinPEUnmount {
    <#
    .SYNOPSIS
        Unmounts a WIM image with commit or discard option.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MountDirectory,

        [Parameter(Mandatory = $false)]
        [switch]$CommitChanges,

        [Parameter(Mandatory = $false)]
        [switch]$DiscardChanges
    )

    Write-Log "Unmounting: $MountDirectory" -Level 'INFO'

    $action = if ($DiscardChanges) { '/Discard' } else { '/Commit' }
    Write-Log "Action: $($action.TrimStart('/'))" -Level 'INFO'

    $dismArgs = @(
        '/Unmount-Wim',
        "/MountDir:$MountDirectory",
        $action
    )

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
}

# ============================================================================
# INJECTION FUNCTIONS
# ============================================================================

function Invoke-DriverInjection {
    <#
    .SYNOPSIS
        Injects drivers into a mounted WIM image.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MountDirectory,

        [Parameter(Mandatory = $true)]
        [string]$DriverSource,

        [Parameter(Mandatory = $false)]
        [switch]$Recursive
    )

    Write-Log "Injecting drivers..." -Level 'INFO'
    Write-Log "Source: $DriverSource" -Level 'INFO'

    $dismArgs = @(
        '/Image:' + $MountDirectory,
        '/Add-Driver',
        '/Driver:' + $DriverSource
    )

    if ($Recursive) {
        $dismArgs += '/Recurse'
    }

    $driverResult = & dism $dismArgs 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0 -or $exitCode -eq 3010) {
        Write-Log "Driver injection completed successfully" -Level 'SUCCESS'
        return $true
    } else {
        Write-Log "Driver injection failed (Exit code: $exitCode)" -Level 'ERROR'
        return $false
    }
}

function Invoke-UpdateInjection {
    <#
    .SYNOPSIS
        Injects Windows updates into a mounted WIM image.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MountDirectory,

        [Parameter(Mandatory = $true)]
        [string]$UpdateSource
    )

    Write-Log "Injecting updates..." -Level 'INFO'
    Write-Log "Source: $UpdateSource" -Level 'INFO'

    # Get update files
    $updateFiles = Get-ChildItem -Path $UpdateSource -Include @('*.cab', '*.msu') -Recurse -File

    if ($updateFiles.Count -eq 0) {
        Write-Log "No update files found" -Level 'WARN'
        return $false
    }

    Write-Log "Found $($updateFiles.Count) update package(s)" -Level 'INFO'

    $successCount = 0
    foreach ($update in $updateFiles) {
        Write-Log "Installing: $($update.Name)" -Level 'INFO'

        $dismArgs = @(
            '/Image:' + $MountDirectory,
            '/Add-Package',
            '/PackagePath:' + $update.FullName
        )

        $updateResult = & dism $dismArgs 2>&1
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0 -or $exitCode -eq 3010) {
            Write-Log "  ✓ Installed successfully" -Level 'SUCCESS'
            $successCount++
        } else {
            Write-Log "  ✗ Installation failed (Exit code: $exitCode)" -Level 'ERROR'
        }
    }

    Write-Log "Installed $successCount of $($updateFiles.Count) updates" -Level 'INFO'
    return ($successCount -gt 0)
}

# ============================================================================
# USB CREATION FUNCTIONS
# ============================================================================

function Invoke-USBCreation {
    <#
    .SYNOPSIS
        Creates a bootable WinPE USB drive.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    Write-Log "Creating bootable USB..." -Level 'INFO'
    Write-Log "Source: $Source" -Level 'INFO'
    Write-Log "Target: $Target" -Level 'INFO'

    # This is a simplified version - full implementation in WinPE-CreateUSB.ps1
    Write-Log "USB creation requires detailed disk operations" -Level 'WARN'
    Write-Log "Please use the dedicated WinPE-CreateUSB.ps1 script for full functionality" -Level 'WARN'

    return $false
}

# ============================================================================
# INTERACTIVE MENU FUNCTIONS
# ============================================================================

function Show-MainMenu {
    <#
    .SYNOPSIS
        Displays the main interactive menu.
    #>
    Clear-Host
    Show-Banner

    Write-Host "Main Menu:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Detect WinPE/WinRE Environments" -ForegroundColor White
    Write-Host "  2. Mount WIM Image" -ForegroundColor White
    Write-Host "  3. Unmount WIM Image" -ForegroundColor White
    Write-Host "  4. Inject Drivers" -ForegroundColor White
    Write-Host "  5. Inject Updates" -ForegroundColor White
    Write-Host "  6. Create Bootable USB" -ForegroundColor White
    Write-Host "  7. Customize WinRE" -ForegroundColor White
    Write-Host ""
    Write-Host "  0. Exit" -ForegroundColor Gray
    Write-Host ""

    $choice = Read-Host "Select an option"
    return $choice
}

function Start-InteractiveMode {
    <#
    .SYNOPSIS
        Runs the toolkit in interactive menu mode.
    #>
    do {
        $choice = Show-MainMenu

        switch ($choice) {
            '1' {
                Write-Host ""
                $result = Invoke-WinPEDetect
                Write-Host ""
                Write-Host "Detection Results:" -ForegroundColor Yellow
                Write-Host "  ADK WinPE: $($result.HasADK)" -ForegroundColor $(if ($result.HasADK) { 'Green' } else { 'Red' })
                Write-Host "  WinRE: $($result.HasWinRE)" -ForegroundColor $(if ($result.HasWinRE) { 'Green' } else { 'Red' })
                Read-Host "`nPress Enter to continue"
            }

            '2' {
                Write-Host ""
                $wim = Read-Host "WIM File Path"
                $mount = Read-Host "Mount Directory"

                if ($wim -and $mount) {
                    Invoke-WinPEMount -WimFile $wim -MountDirectory $mount
                }
                Read-Host "`nPress Enter to continue"
            }

            '3' {
                Write-Host ""
                $mount = Read-Host "Mount Directory"
                $action = Read-Host "Commit changes? (yes/no)"

                if ($mount) {
                    if ($action -eq 'yes') {
                        Invoke-WinPEUnmount -MountDirectory $mount -CommitChanges
                    } else {
                        Invoke-WinPEUnmount -MountDirectory $mount -DiscardChanges
                    }
                }
                Read-Host "`nPress Enter to continue"
            }

            '4' {
                Write-Host ""
                $mount = Read-Host "Mount Directory"
                $drivers = Read-Host "Driver Path"
                $recurse = Read-Host "Recursive search? (yes/no)"

                if ($mount -and $drivers) {
                    $recurseSwitch = $recurse -eq 'yes'
                    Invoke-DriverInjection -MountDirectory $mount -DriverSource $drivers -Recursive:$recurseSwitch
                }
                Read-Host "`nPress Enter to continue"
            }

            '5' {
                Write-Host ""
                $mount = Read-Host "Mount Directory"
                $updates = Read-Host "Update Path"

                if ($mount -and $updates) {
                    Invoke-UpdateInjection -MountDirectory $mount -UpdateSource $updates
                }
                Read-Host "`nPress Enter to continue"
            }

            '6' {
                Write-Host ""
                Write-Host "USB creation requires the dedicated WinPE-CreateUSB.ps1 script" -ForegroundColor Yellow
                Write-Host "Located in: Scripts\WinPE\USB\" -ForegroundColor Cyan
                Read-Host "`nPress Enter to continue"
            }

            '7' {
                Write-Host ""
                Write-Host "WinRE customization requires the dedicated WinPE-CustomizeWinRE.ps1 script" -ForegroundColor Yellow
                Write-Host "Located in: Scripts\WinPE\Toolkit\" -ForegroundColor Cyan
                Read-Host "`nPress Enter to continue"
            }

            '0' {
                Write-Log "Exiting toolkit..." -Level 'INFO'
                return
            }

            default {
                Write-Host ""
                Write-Host "Invalid option. Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

# ============================================================================
# COMMAND DISPATCHER
# ============================================================================

function Invoke-Command {
    <#
    .SYNOPSIS
        Dispatches commands based on parameters.
    #>
    param(
        [string]$CommandName
    )

    switch ($CommandName) {
        'Detect' {
            $result = Invoke-WinPEDetect
            return $result
        }

        'Mount' {
            if (-not $WimPath -or -not $MountPath) {
                throw "Mount command requires -WimPath and -MountPath parameters"
            }
            Invoke-WinPEMount -WimFile $WimPath -MountDirectory $MountPath
        }

        'Unmount' {
            if (-not $MountPath) {
                throw "Unmount command requires -MountPath parameter"
            }
            
            if ($Discard) {
                Invoke-WinPEUnmount -MountDirectory $MountPath -DiscardChanges
            } else {
                Invoke-WinPEUnmount -MountDirectory $MountPath -CommitChanges
            }
        }

        'InjectDrivers' {
            if (-not $MountPath -or -not $DriverPath) {
                throw "InjectDrivers command requires -MountPath and -DriverPath parameters"
            }
            Invoke-DriverInjection -MountDirectory $MountPath -DriverSource $DriverPath -Recursive:$Recurse
        }

        'InjectUpdates' {
            if (-not $MountPath -or -not $UpdatePath) {
                throw "InjectUpdates command requires -MountPath and -UpdatePath parameters"
            }
            Invoke-UpdateInjection -MountDirectory $MountPath -UpdateSource $UpdatePath
        }

        'CreateUSB' {
            Write-Log "Please use the dedicated WinPE-CreateUSB.ps1 script for USB creation" -Level 'WARN'
            Write-Log "Located in: Scripts\WinPE\USB\WinPE-CreateUSB.ps1" -Level 'INFO'
        }

        'CustomizeWinRE' {
            Write-Log "Please use the dedicated WinPE-CustomizeWinRE.ps1 script for WinRE customization" -Level 'WARN'
            Write-Log "Located in: Scripts\WinPE\Toolkit\WinPE-CustomizeWinRE.ps1" -Level 'INFO'
        }

        'Interactive' {
            Start-InteractiveMode
        }
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Show-Banner

    if ($PSCmdlet.ParameterSetName -eq 'Interactive' -or $Command -eq 'Interactive') {
        Start-InteractiveMode
    } else {
        Invoke-Command -CommandName $Command
    }

    Write-Host ""
    Write-Log "Toolkit execution completed" -Level 'SUCCESS'

} catch {
    Write-Host ""
    Write-Log "Toolkit execution failed" -Level 'ERROR'
    Write-Log "Error: $($_.Exception.Message)" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
    exit 1
}
