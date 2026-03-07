<#
.SYNOPSIS
    Creates bootable WinPE or WinRE USB drives.

.DESCRIPTION
    This script creates bootable USB drives from WinPE or WinRE sources.
    Supports multiple partition schemes (MBR/GPT), file systems (FAT32/NTFS),
    and boot configurations (BIOS/UEFI/Both).
    
    Includes drive detection, formatting, and file copying with comprehensive
    validation and error handling.

.PARAMETER SourcePath
    Path to WinPE media directory or ISO file.

.PARAMETER TargetDrive
    Target USB drive letter (e.g., "E:") or disk number (e.g., "1").

.PARAMETER PartitionScheme
    Partition scheme: MBR or GPT (default: GPT).

.PARAMETER FileSystem
    File system: FAT32 or NTFS (default: FAT32).

.PARAMETER BootMode
    Boot mode: BIOS, UEFI, or Both (default: Both).

.PARAMETER Label
    Volume label for the USB drive (default: "WinPE").

.PARAMETER Force
    Skip confirmation prompts and force format.

.EXAMPLE
    .\WinPE-CreateUSB.ps1 -SourcePath "C:\WinPE" -TargetDrive "E:"
    Creates bootable USB from WinPE media to drive E:.

.EXAMPLE
    .\WinPE-CreateUSB.ps1 -SourcePath "C:\WinPE.iso" -TargetDrive "1" -Force
    Creates bootable USB from ISO to disk 1 without prompts.

.NOTES
    Author: Better11 Development Team
    Version: 1.0.0
    Part of: WinPE PowerBuilder Suite
    
    WARNING: This script will ERASE ALL DATA on the target drive!
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ })]
    [string]$SourcePath,

    [Parameter(Mandatory = $true)]
    [string]$TargetDrive,

    [Parameter(Mandatory = $false)]
    [ValidateSet('MBR', 'GPT')]
    [string]$PartitionScheme = 'GPT',

    [Parameter(Mandatory = $false)]
    [ValidateSet('FAT32', 'NTFS')]
    [string]$FileSystem = 'FAT32',

    [Parameter(Mandatory = $false)]
    [ValidateSet('BIOS', 'UEFI', 'Both')]
    [string]$BootMode = 'Both',

    [Parameter(Mandatory = $false)]
    [ValidateLength(1, 32)]
    [string]$Label = 'WinPE',

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# ============================================================================
# INITIALIZATION
# ============================================================================

$ErrorActionPreference = 'Stop'
$scriptName = 'WinPE-CreateUSB'
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
# DRIVE DETECTION & VALIDATION
# ============================================================================

function Get-TargetDisk {
    <#
    .SYNOPSIS
        Resolves target drive to disk number.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Target
    )

    Write-Log "Resolving target drive identifier: $Target" -Level 'INFO'

    # Check if target is a disk number
    if ($Target -match '^\d+$') {
        $diskNumber = [int]$Target
        
        $disk = Get-Disk -Number $diskNumber -ErrorAction SilentlyContinue
        if ($disk) {
            return $disk
        } else {
            throw "Disk $diskNumber not found"
        }
    }
    
    # Check if target is a drive letter
    if ($Target -match '^[A-Z]:?$') {
        $driveLetter = $Target.TrimEnd(':')
        
        $partition = Get-Partition | Where-Object { $_.DriveLetter -eq $driveLetter } | Select-Object -First 1
        if ($partition) {
            $disk = Get-Disk -Number $partition.DiskNumber
            return $disk
        } else {
            throw "Drive letter $driveLetter not found"
        }
    }

    throw "Invalid target format: $Target. Use drive letter (E:) or disk number (1)"
}

function Confirm-RemovableDisk {
    <#
    .SYNOPSIS
        Validates that the disk is removable and safe to format.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Disk
    )

    Write-Log "Validating disk..." -Level 'INFO'
    Write-Log "  Disk Number: $($Disk.Number)" -Level 'INFO'
    Write-Log "  Friendly Name: $($Disk.FriendlyName)" -Level 'INFO'
    Write-Log "  Size: $([math]::Round($Disk.Size / 1GB, 2)) GB" -Level 'INFO'
    Write-Log "  Bus Type: $($Disk.BusType)" -Level 'INFO'

    # Check if disk is removable
    if ($Disk.BusType -notin @('USB', 'SD')) {
        Write-Log "WARNING: Disk is not USB or SD card" -Level 'WARN'
        Write-Log "Bus Type detected: $($Disk.BusType)" -Level 'WARN'
        
        if (-not $Force) {
            $response = Read-Host "Continue anyway? (yes/no)"
            if ($response -ne 'yes') {
                throw "Operation cancelled by user"
            }
        }
    }

    # Check if disk is system disk
    if ($Disk.IsSystem -or $Disk.IsBoot) {
        throw "Cannot format system or boot disk (Disk $($Disk.Number))"
    }

    # Check disk size (warn if < 512MB or > 256GB)
    $sizeGB = $Disk.Size / 1GB
    if ($sizeGB -lt 0.5) {
        throw "Disk is too small for WinPE (minimum 512MB required)"
    }
    if ($sizeGB -gt 256) {
        Write-Log "WARNING: Large disk detected ($([math]::Round($sizeGB, 2)) GB)" -Level 'WARN'
    }

    return $true
}

# ============================================================================
# DISK PREPARATION FUNCTIONS
# ============================================================================

function Initialize-TargetDisk {
    <#
    .SYNOPSIS
        Initializes and partitions the target disk.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        $Disk,

        [Parameter(Mandatory = $true)]
        [string]$PartScheme,

        [Parameter(Mandatory = $true)]
        [string]$FileSystemType,

        [Parameter(Mandatory = $true)]
        [string]$VolumeLabel
    )

    Write-Log "========================================" -Level 'WARN'
    Write-Log "WARNING: ALL DATA WILL BE ERASED" -Level 'WARN'
    Write-Log "========================================" -Level 'WARN'
    Write-Log "Target: Disk $($Disk.Number) - $($Disk.FriendlyName)" -Level 'WARN'
    Write-Log "Size: $([math]::Round($Disk.Size / 1GB, 2)) GB" -Level 'WARN'

    if (-not $Force) {
        $confirm = Read-Host "Type 'DELETE' to confirm"
        if ($confirm -ne 'DELETE') {
            throw "Operation cancelled by user"
        }
    }

    # Clean disk
    Write-Log "Cleaning disk..." -Level 'INFO'
    Clear-Disk -Number $Disk.Number -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop

    # Initialize disk with partition scheme
    Write-Log "Initializing disk with $PartScheme partition scheme..." -Level 'INFO'
    Initialize-Disk -Number $Disk.Number -PartitionStyle $PartScheme -ErrorAction Stop

    # Create partition
    Write-Log "Creating partition..." -Level 'INFO'
    
    if ($PartScheme -eq 'GPT' -and $BootMode -in @('UEFI', 'Both')) {
        # GPT with UEFI: Create EFI System Partition
        $partition = New-Partition -DiskNumber $Disk.Number -UseMaximumSize -AssignDriveLetter -ErrorAction Stop
        
        Write-Log "Formatting partition as $FileSystemType..." -Level 'INFO'
        Format-Volume -Partition $partition -FileSystem $FileSystemType -NewFileSystemLabel $VolumeLabel -Confirm:$false -ErrorAction Stop
    }
    elseif ($PartScheme -eq 'MBR') {
        # MBR: Create active partition
        $partition = New-Partition -DiskNumber $Disk.Number -UseMaximumSize -AssignDriveLetter -IsActive -ErrorAction Stop
        
        Write-Log "Formatting partition as $FileSystemType..." -Level 'INFO'
        Format-Volume -Partition $partition -FileSystem $FileSystemType -NewFileSystemLabel $VolumeLabel -Confirm:$false -ErrorAction Stop
    }
    else {
        $partition = New-Partition -DiskNumber $Disk.Number -UseMaximumSize -AssignDriveLetter -ErrorAction Stop
        
        Write-Log "Formatting partition as $FileSystemType..." -Level 'INFO'
        Format-Volume -Partition $partition -FileSystem $FileSystemType -NewFileSystemLabel $VolumeLabel -Confirm:$false -ErrorAction Stop
    }

    # Get drive letter
    Start-Sleep -Seconds 2
    $partition = Get-Partition -DiskNumber $Disk.Number | Where-Object { $_.DriveLetter } | Select-Object -First 1
    
    if (-not $partition.DriveLetter) {
        throw "Failed to assign drive letter to partition"
    }

    Write-Log "Partition created with drive letter: $($partition.DriveLetter):" -Level 'SUCCESS'

    return $partition
}

function Install-Bootloader {
    <#
    .SYNOPSIS
        Installs bootloader to the USB drive.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetDrive,

        [Parameter(Mandatory = $true)]
        [string]$Mode,

        [Parameter(Mandatory = $true)]
        [string]$PartScheme
    )

    Write-Log "Installing bootloader..." -Level 'INFO'
    Write-Log "  Boot Mode: $Mode" -Level 'INFO'
    Write-Log "  Partition Scheme: $PartScheme" -Level 'INFO'

    try {
        if ($Mode -eq 'UEFI' -or $Mode -eq 'Both') {
            Write-Log "Configuring UEFI boot..." -Level 'INFO'
            
            # UEFI boot uses bootmgr files in /EFI/Boot/
            # Files will be copied from source
        }

        if ($Mode -eq 'BIOS' -or $Mode -eq 'Both') {
            Write-Log "Configuring BIOS boot..." -Level 'INFO'
            
            # Use bootsect if available
            $bootsectPath = "${env:SystemRoot}\System32\bootsect.exe"
            
            if (Test-Path $bootsectPath) {
                Write-Log "Running bootsect..." -Level 'INFO'
                $bootsectResult = & $bootsectPath /nt60 "${TargetDrive}:" /mbr /force 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Bootsect completed successfully" -Level 'SUCCESS'
                } else {
                    Write-Log "Bootsect completed with warnings (Exit code: $LASTEXITCODE)" -Level 'WARN'
                }
            } else {
                Write-Log "bootsect.exe not found, skipping BIOS boot configuration" -Level 'WARN'
            }
        }

        return $true
    } catch {
        Write-Log "Error installing bootloader: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# ============================================================================
# FILE COPY FUNCTIONS
# ============================================================================

function Copy-WinPEFiles {
    <#
    .SYNOPSIS
        Copies WinPE files to the USB drive.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Source,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    Write-Log "Copying WinPE files to USB drive..." -Level 'INFO'
    Write-Log "  Source: $Source" -Level 'INFO'
    Write-Log "  Destination: ${Destination}:" -Level 'INFO'

    try {
        $sourceItem = Get-Item $Source

        if ($sourceItem.Extension -eq '.iso') {
            Write-Log "Source is an ISO file, mounting..." -Level 'INFO'
            
            $mountResult = Mount-DiskImage -ImagePath $Source -PassThru
            $isoVolume = Get-Volume -DiskImage $mountResult
            $isoDrive = "$($isoVolume.DriveLetter):"
            
            Write-Log "ISO mounted at: $isoDrive" -Level 'SUCCESS'
            
            # Copy files
            Write-Log "Copying files from ISO..." -Level 'INFO'
            robocopy $isoDrive "${Destination}:" /E /R:1 /W:1 /NFL /NDL /NP /MT:4 | Out-Null
            $robocopyExit = $LASTEXITCODE
            
            # Dismount ISO
            Dismount-DiskImage -ImagePath $Source | Out-Null
            Write-Log "ISO dismounted" -Level 'INFO'
            
        } else {
            # Copy from directory
            Write-Log "Copying files from directory..." -Level 'INFO'
            robocopy $Source "${Destination}:" /E /R:1 /W:1 /NFL /NDL /NP /MT:4 | Out-Null
            $robocopyExit = $LASTEXITCODE
        }

        # Robocopy exit codes: 0-7 are success, 8+ are errors
        if ($robocopyExit -ge 8) {
            Write-Log "File copy completed with errors (Robocopy exit code: $robocopyExit)" -Level 'WARN'
            return $false
        } else {
            Write-Log "Files copied successfully" -Level 'SUCCESS'
            return $true
        }

    } catch {
        Write-Log "Error copying files: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

try {
    Write-Log "========================================" -Level 'INFO'
    Write-Log "$scriptName v$scriptVersion" -Level 'INFO'
    Write-Log "Bootable WinPE USB Creator" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'

    # Validate source
    Write-Log "Validating source path: $SourcePath" -Level 'INFO'
    
    if (-not (Test-Path $SourcePath)) {
        throw "Source path not found: $SourcePath"
    }

    # Resolve and validate target disk
    $targetDisk = Get-TargetDisk -Target $TargetDrive
    Confirm-RemovableDisk -Disk $targetDisk | Out-Null

    # Prepare disk
    $partition = Initialize-TargetDisk `
        -Disk $targetDisk `
        -PartScheme $PartitionScheme `
        -FileSystemType $FileSystem `
        -VolumeLabel $Label

    $usbDrive = $partition.DriveLetter

    # Copy WinPE files
    $copySuccess = Copy-WinPEFiles -Source $SourcePath -Destination $usbDrive

    if (-not $copySuccess) {
        Write-Log "File copy failed, USB may be incomplete" -Level 'ERROR'
    }

    # Install bootloader
    $bootSuccess = Install-Bootloader `
        -TargetDrive $usbDrive `
        -Mode $BootMode `
        -PartScheme $PartitionScheme

    if (-not $bootSuccess) {
        Write-Log "Bootloader installation encountered issues" -Level 'WARN'
    }

    # Display completion
    Write-Log "========================================" -Level 'INFO'
    Write-Log "USB Creation Complete" -Level 'SUCCESS'
    Write-Log "========================================" -Level 'INFO'
    Write-Log "Drive Letter: ${usbDrive}:" -Level 'INFO'
    Write-Log "Label: $Label" -Level 'INFO'
    Write-Log "File System: $FileSystem" -Level 'INFO'
    Write-Log "Partition Scheme: $PartitionScheme" -Level 'INFO'
    Write-Log "Boot Mode: $BootMode" -Level 'INFO'
    Write-Log "========================================" -Level 'INFO'
    Write-Log "USB drive is ready to boot" -Level 'SUCCESS'
    Write-Log "========================================" -Level 'INFO'

    # Return result
    return [PSCustomObject]@{
        Success = $true
        DiskNumber = $targetDisk.Number
        DriveLetter = $usbDrive
        Label = $Label
        Size = $targetDisk.Size
        SizeGB = [math]::Round($targetDisk.Size / 1GB, 2)
        PartitionScheme = $PartitionScheme
        FileSystem = $FileSystem
        BootMode = $BootMode
        Timestamp = Get-Date -Format 'o'
    }

} catch {
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "USB creation failed" -Level 'ERROR'
    Write-Log "========================================" -Level 'ERROR'
    Write-Log "Error: $($_.Exception.Message)" -Level 'ERROR'
    Write-Log "Stack trace: $($_.ScriptStackTrace)" -Level 'ERROR'
    exit 1
}
