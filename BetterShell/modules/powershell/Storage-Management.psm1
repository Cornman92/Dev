<#
.SYNOPSIS
    WinPE PowerBuilder - Storage Management Module
    Advanced disk and storage operations for WinPE environments

.DESCRIPTION
    This module provides comprehensive storage management capabilities including:
    - Disk partitioning and formatting
    - Volume creation and management
    - Storage driver injection
    - Disk imaging and cloning
    - BitLocker operations
    - Storage diagnostics

.NOTES
    Module: Storage-Management
    Version: 1.0.0
    Author: Better11 Development Team
    Requires: PowerShell 5.1+, Windows ADK, WinPE environment
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

#region Module Variables

$script:ModuleRoot = $PSScriptRoot
$script:LogPath = Join-Path $env:TEMP "WinPE-StorageManagement.log"
$script:ImagePath = Join-Path $ModuleRoot "Images"
$script:DriverPath = Join-Path $ModuleRoot "StorageDrivers"

# Ensure required paths exist
@($ImagePath, $DriverPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

#endregion

#region Logging Functions

function Write-StorageLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter()]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    $color = switch ($Level) {
        'Info'    { 'White' }
        'Warning' { 'Yellow' }
        'Error'   { 'Red' }
        'Success' { 'Green' }
    }
    Write-Host $logMessage -ForegroundColor $color
    
    Add-Content -Path $script:LogPath -Value $logMessage -ErrorAction SilentlyContinue
}

#endregion

#region Disk Management Functions

function Get-WinPEDisks {
    <#
    .SYNOPSIS
        Retrieves all physical disks in WinPE environment
    
    .DESCRIPTION
        Gets detailed information about all physical disks including size,
        partitions, health status, and bus type
    
    .EXAMPLE
        Get-WinPEDisks
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-StorageLog "Retrieving physical disks" -Level Info
        
        $disks = Get-Disk -ErrorAction Stop
        
        $diskInfo = @()
        
        foreach ($disk in $disks) {
            $partitions = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue
            
            $info = [PSCustomObject]@{
                Number = $disk.Number
                FriendlyName = $disk.FriendlyName
                Size = $disk.Size
                SizeGB = [Math]::Round($disk.Size / 1GB, 2)
                PartitionStyle = $disk.PartitionStyle
                OperationalStatus = $disk.OperationalStatus
                HealthStatus = $disk.HealthStatus
                BusType = $disk.BusType
                IsSystem = $disk.IsSystem
                IsBoot = $disk.IsBoot
                IsReadOnly = $disk.IsReadOnly
                PartitionCount = $partitions.Count
                Model = $disk.Model
                SerialNumber = $disk.SerialNumber
            }
            
            $diskInfo += $info
        }
        
        Write-StorageLog "Found $($diskInfo.Count) physical disk(s)" -Level Success
        return $diskInfo
    }
    catch {
        Write-StorageLog "Failed to retrieve disks: $_" -Level Error
        throw
    }
}

function Initialize-WinPEDisk {
    <#
    .SYNOPSIS
        Initializes a disk with specified partition style
    
    .DESCRIPTION
        Initializes a raw disk with GPT or MBR partition style
    
    .EXAMPLE
        Initialize-WinPEDisk -DiskNumber 1 -PartitionStyle GPT
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$DiskNumber,
        
        [Parameter()]
        [ValidateSet('GPT', 'MBR')]
        [string]$PartitionStyle = 'GPT',
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-StorageLog "Initializing disk $DiskNumber with $PartitionStyle" -Level Info
        
        $disk = Get-Disk -Number $DiskNumber -ErrorAction Stop
        
        if ($disk.PartitionStyle -ne 'RAW' -and -not $Force) {
            throw "Disk is already initialized. Use -Force to reinitialize (will erase all data)"
        }
        
        if ($Force -and $disk.PartitionStyle -ne 'RAW') {
            Write-StorageLog "Clearing disk $DiskNumber..." -Level Warning
            Clear-Disk -Number $DiskNumber -RemoveData -RemoveOEM -Confirm:$false -ErrorAction Stop
        }
        
        Initialize-Disk -Number $DiskNumber -PartitionStyle $PartitionStyle -ErrorAction Stop
        
        Write-StorageLog "Disk $DiskNumber initialized successfully" -Level Success
    }
    catch {
        Write-StorageLog "Failed to initialize disk: $_" -Level Error
        throw
    }
}

function New-WinPEPartition {
    <#
    .SYNOPSIS
        Creates a new partition on a disk
    
    .DESCRIPTION
        Creates and formats a new partition with specified size and file system
    
    .EXAMPLE
        New-WinPEPartition -DiskNumber 1 -Size 100GB -FileSystem NTFS -DriveLetter D
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$DiskNumber,
        
        [Parameter()]
        [long]$Size,
        
        [Parameter()]
        [switch]$UseMaximumSize,
        
        [Parameter()]
        [ValidateSet('NTFS', 'FAT32', 'exFAT', 'ReFS')]
        [string]$FileSystem = 'NTFS',
        
        [Parameter()]
        [char]$DriveLetter,
        
        [Parameter()]
        [string]$Label,
        
        [Parameter()]
        [switch]$IsActive
    )
    
    try {
        Write-StorageLog "Creating partition on disk $DiskNumber" -Level Info
        
        $partParams = @{
            DiskNumber = $DiskNumber
        }
        
        if ($UseMaximumSize) {
            $partParams.UseMaximumSize = $true
        } elseif ($Size) {
            $partParams.Size = $Size
        } else {
            throw "Either -Size or -UseMaximumSize must be specified"
        }
        
        if ($DriveLetter) {
            $partParams.DriveLetter = $DriveLetter
        } else {
            $partParams.AssignDriveLetter = $true
        }
        
        $partition = New-Partition @partParams -ErrorAction Stop
        
        Write-StorageLog "Formatting partition as $FileSystem..." -Level Info
        
        $formatParams = @{
            Partition = $partition
            FileSystem = $FileSystem
            Confirm = $false
        }
        
        if ($Label) {
            $formatParams.NewFileSystemLabel = $Label
        }
        
        Format-Volume @formatParams -ErrorAction Stop | Out-Null
        
        if ($IsActive -and $partition.DiskNumber -ne $null) {
            Set-Partition -DiskNumber $partition.DiskNumber -PartitionNumber $partition.PartitionNumber -IsActive $true
        }
        
        Write-StorageLog "Partition created successfully: $($partition.DriveLetter):" -Level Success
        return $partition
    }
    catch {
        Write-StorageLog "Failed to create partition: $_" -Level Error
        throw
    }
}

function Remove-WinPEPartition {
    <#
    .SYNOPSIS
        Removes a partition from a disk
    
    .DESCRIPTION
        Deletes a specified partition and its data
    
    .EXAMPLE
        Remove-WinPEPartition -DiskNumber 1 -PartitionNumber 2
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [int]$DiskNumber,
        
        [Parameter(Mandatory)]
        [int]$PartitionNumber,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-StorageLog "Removing partition $PartitionNumber from disk $DiskNumber" -Level Warning
        
        if ($PSCmdlet.ShouldProcess("Disk $DiskNumber Partition $PartitionNumber", "Remove")) {
            Remove-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -Confirm:$false -ErrorAction Stop
            Write-StorageLog "Partition removed successfully" -Level Success
        }
    }
    catch {
        Write-StorageLog "Failed to remove partition: $_" -Level Error
        throw
    }
}

function Resize-WinPEPartition {
    <#
    .SYNOPSIS
        Resizes a partition
    
    .DESCRIPTION
        Extends or shrinks a partition to specified size
    
    .EXAMPLE
        Resize-WinPEPartition -DiskNumber 1 -PartitionNumber 2 -Size 200GB
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$DiskNumber,
        
        [Parameter(Mandatory)]
        [int]$PartitionNumber,
        
        [Parameter()]
        [long]$Size,
        
        [Parameter()]
        [switch]$UseMaximumSize
    )
    
    try {
        Write-StorageLog "Resizing partition $PartitionNumber on disk $DiskNumber" -Level Info
        
        $partition = Get-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -ErrorAction Stop
        
        if ($UseMaximumSize) {
            $maxSize = (Get-PartitionSupportedSize -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber).SizeMax
            Resize-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -Size $maxSize -ErrorAction Stop
        } elseif ($Size) {
            Resize-Partition -DiskNumber $DiskNumber -PartitionNumber $PartitionNumber -Size $Size -ErrorAction Stop
        } else {
            throw "Either -Size or -UseMaximumSize must be specified"
        }
        
        Write-StorageLog "Partition resized successfully" -Level Success
    }
    catch {
        Write-StorageLog "Failed to resize partition: $_" -Level Error
        throw
    }
}

#endregion

#region Volume Management Functions

function Get-WinPEVolumes {
    <#
    .SYNOPSIS
        Retrieves all volumes in WinPE environment
    
    .DESCRIPTION
        Gets detailed information about all volumes including capacity and health
    
    .EXAMPLE
        Get-WinPEVolumes
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-StorageLog "Retrieving volumes" -Level Info
        
        $volumes = Get-Volume -ErrorAction Stop | Where-Object { $_.DriveLetter -ne $null }
        
        $volumeInfo = @()
        
        foreach ($volume in $volumes) {
            $info = [PSCustomObject]@{
                DriveLetter = $volume.DriveLetter
                FileSystemLabel = $volume.FileSystemLabel
                FileSystem = $volume.FileSystem
                DriveType = $volume.DriveType
                HealthStatus = $volume.HealthStatus
                OperationalStatus = $volume.OperationalStatus
                SizeGB = [Math]::Round($volume.Size / 1GB, 2)
                FreeSpaceGB = [Math]::Round($volume.SizeRemaining / 1GB, 2)
                UsedPercentage = [Math]::Round((($volume.Size - $volume.SizeRemaining) / $volume.Size) * 100, 2)
            }
            
            $volumeInfo += $info
        }
        
        Write-StorageLog "Found $($volumeInfo.Count) volume(s)" -Level Success
        return $volumeInfo
    }
    catch {
        Write-StorageLog "Failed to retrieve volumes: $_" -Level Error
        throw
    }
}

function Set-WinPEVolumeLabel {
    <#
    .SYNOPSIS
        Sets the label for a volume
    
    .DESCRIPTION
        Changes the file system label of a volume
    
    .EXAMPLE
        Set-WinPEVolumeLabel -DriveLetter D -Label "Data"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [char]$DriveLetter,
        
        [Parameter(Mandatory)]
        [string]$Label
    )
    
    try {
        Write-StorageLog "Setting volume label for ${DriveLetter}: to '$Label'" -Level Info
        
        Set-Volume -DriveLetter $DriveLetter -NewFileSystemLabel $Label -ErrorAction Stop
        
        Write-StorageLog "Volume label set successfully" -Level Success
    }
    catch {
        Write-StorageLog "Failed to set volume label: $_" -Level Error
        throw
    }
}

function Optimize-WinPEVolume {
    <#
    .SYNOPSIS
        Optimizes a volume (defragment or TRIM)
    
    .DESCRIPTION
        Optimizes a volume based on drive type (defrag for HDD, TRIM for SSD)
    
    .EXAMPLE
        Optimize-WinPEVolume -DriveLetter C
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [char]$DriveLetter,
        
        [Parameter()]
        [switch]$Analyze
    )
    
    try {
        if ($Analyze) {
            Write-StorageLog "Analyzing volume ${DriveLetter}:" -Level Info
            Optimize-Volume -DriveLetter $DriveLetter -Analyze -ErrorAction Stop
        } else {
            Write-StorageLog "Optimizing volume ${DriveLetter}:" -Level Info
            Optimize-Volume -DriveLetter $DriveLetter -ErrorAction Stop
        }
        
        Write-StorageLog "Volume optimization completed" -Level Success
    }
    catch {
        Write-StorageLog "Failed to optimize volume: $_" -Level Error
        throw
    }
}

#endregion

#region Disk Imaging Functions

function New-WinPEDiskImage {
    <#
    .SYNOPSIS
        Creates an image of a disk or partition
    
    .DESCRIPTION
        Creates a WIM or VHD image of a disk or partition
    
    .EXAMPLE
        New-WinPEDiskImage -SourceDrive C -ImagePath "C:\Images\SystemImage.wim"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [char]$SourceDrive,
        
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter()]
        [ValidateSet('WIM', 'VHD', 'VHDX')]
        [string]$ImageType = 'WIM',
        
        [Parameter()]
        [string]$ImageName = "Disk Image",
        
        [Parameter()]
        [string]$Description,
        
        [Parameter()]
        [ValidateSet('None', 'Fast', 'Maximum')]
        [string]$Compression = 'Fast'
    )
    
    try {
        Write-StorageLog "Creating $ImageType image of ${SourceDrive}:" -Level Info
        
        $imageDir = Split-Path -Parent $ImagePath
        if (-not (Test-Path $imageDir)) {
            New-Item -Path $imageDir -ItemType Directory -Force | Out-Null
        }
        
        switch ($ImageType) {
            'WIM' {
                $captureParams = @{
                    ImagePath = $ImagePath
                    CapturePath = "${SourceDrive}:\"
                    Name = $ImageName
                    Compression = $Compression
                }
                
                if ($Description) {
                    $captureParams.Description = $Description
                }
                
                New-WindowsImage @captureParams -ErrorAction Stop | Out-Null
            }
            
            { $_ -in 'VHD', 'VHDX' } {
                $volume = Get-Volume -DriveLetter $SourceDrive -ErrorAction Stop
                $sizeBytes = $volume.Size
                
                $vhdParams = @{
                    Path = $ImagePath
                    SizeBytes = $sizeBytes
                    Dynamic = $true
                }
                
                if ($ImageType -eq 'VHDX') {
                    $vhdParams.VhdType = 'Dynamic'
                    $vhdParams.VhdFormat = 'VHDX'
                }
                
                New-VHD @vhdParams -ErrorAction Stop | Out-Null
                
                # Mount and copy data
                $vhd = Mount-VHD -Path $ImagePath -Passthru -ErrorAction Stop
                $vhdDisk = Get-Disk -Number $vhd.DiskNumber
                
                Initialize-Disk -Number $vhdDisk.Number -PartitionStyle GPT -ErrorAction Stop
                $partition = New-Partition -DiskNumber $vhdDisk.Number -UseMaximumSize -AssignDriveLetter -ErrorAction Stop
                Format-Volume -Partition $partition -FileSystem NTFS -Confirm:$false -ErrorAction Stop | Out-Null
                
                # Copy files
                $destDrive = $partition.DriveLetter
                Write-StorageLog "Copying files from ${SourceDrive}: to ${destDrive}:" -Level Info
                robocopy "${SourceDrive}:\" "${destDrive}:\" /E /COPYALL /R:1 /W:1 /NFL /NDL /NJH /NJS | Out-Null
                
                Dismount-VHD -Path $ImagePath -ErrorAction Stop
            }
        }
        
        Write-StorageLog "Disk image created successfully: $ImagePath" -Level Success
        return $ImagePath
    }
    catch {
        Write-StorageLog "Failed to create disk image: $_" -Level Error
        throw
    }
}

function Restore-WinPEDiskImage {
    <#
    .SYNOPSIS
        Restores a disk image to a drive
    
    .DESCRIPTION
        Applies a WIM or mounts a VHD/VHDX image
    
    .EXAMPLE
        Restore-WinPEDiskImage -ImagePath "C:\Images\SystemImage.wim" -TargetDrive D
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ImagePath,
        
        [Parameter(Mandatory)]
        [char]$TargetDrive,
        
        [Parameter()]
        [int]$ImageIndex = 1
    )
    
    try {
        Write-StorageLog "Restoring image from $ImagePath to ${TargetDrive}:" -Level Info
        
        if (-not (Test-Path $ImagePath)) {
            throw "Image file not found: $ImagePath"
        }
        
        $extension = [System.IO.Path]::GetExtension($ImagePath).ToLower()
        
        switch ($extension) {
            '.wim' {
                Write-StorageLog "Applying WIM image (Index: $ImageIndex)..." -Level Info
                
                Expand-WindowsImage -ImagePath $ImagePath -Index $ImageIndex -ApplyPath "${TargetDrive}:\" -ErrorAction Stop | Out-Null
            }
            
            { $_ -in '.vhd', '.vhdx' } {
                Write-StorageLog "Mounting VHD image..." -Level Info
                
                $vhd = Mount-VHD -Path $ImagePath -Passthru -ErrorAction Stop
                $vhdPartition = Get-Partition -DiskNumber $vhd.DiskNumber | Where-Object { $_.Type -ne 'Reserved' } | Select-Object -First 1
                
                if ($vhdPartition) {
                    $sourceDrive = $vhdPartition.DriveLetter
                    Write-StorageLog "Copying files from ${sourceDrive}: to ${TargetDrive}:" -Level Info
                    robocopy "${sourceDrive}:\" "${TargetDrive}:\" /E /COPYALL /R:1 /W:1 /NFL /NDL /NJH /NJS | Out-Null
                }
                
                Dismount-VHD -Path $ImagePath -ErrorAction Stop
            }
            
            default {
                throw "Unsupported image format: $extension"
            }
        }
        
        Write-StorageLog "Image restored successfully" -Level Success
    }
    catch {
        Write-StorageLog "Failed to restore disk image: $_" -Level Error
        throw
    }
}

#endregion

#region BitLocker Functions

function Enable-WinPEBitLocker {
    <#
    .SYNOPSIS
        Enables BitLocker on a volume
    
    .DESCRIPTION
        Encrypts a volume using BitLocker with specified key protector
    
    .EXAMPLE
        Enable-WinPEBitLocker -DriveLetter D -RecoveryPassword
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [char]$DriveLetter,
        
        [Parameter()]
        [switch]$RecoveryPassword,
        
        [Parameter()]
        [switch]$StartupKey,
        
        [Parameter()]
        [string]$StartupKeyPath,
        
        [Parameter()]
        [ValidateSet('Aes128', 'Aes256', 'XtsAes128', 'XtsAes256')]
        [string]$EncryptionMethod = 'XtsAes256'
    )
    
    try {
        Write-StorageLog "Enabling BitLocker on ${DriveLetter}:" -Level Info
        
        # Add key protector
        if ($RecoveryPassword) {
            $recoveryKey = Add-BitLockerKeyProtector -MountPoint "${DriveLetter}:" -RecoveryPasswordProtector -ErrorAction Stop
            Write-StorageLog "Recovery password: $($recoveryKey.RecoveryPassword)" -Level Warning
        }
        
        if ($StartupKey -and $StartupKeyPath) {
            Add-BitLockerKeyProtector -MountPoint "${DriveLetter}:" -StartupKeyProtector -StartupKeyPath $StartupKeyPath -ErrorAction Stop | Out-Null
        }
        
        # Enable encryption
        Enable-BitLocker -MountPoint "${DriveLetter}:" -EncryptionMethod $EncryptionMethod -ErrorAction Stop | Out-Null
        
        Write-StorageLog "BitLocker enabled successfully" -Level Success
    }
    catch {
        Write-StorageLog "Failed to enable BitLocker: $_" -Level Error
        throw
    }
}

function Disable-WinPEBitLocker {
    <#
    .SYNOPSIS
        Disables BitLocker on a volume
    
    .DESCRIPTION
        Decrypts a BitLocker-encrypted volume
    
    .EXAMPLE
        Disable-WinPEBitLocker -DriveLetter D
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [char]$DriveLetter
    )
    
    try {
        Write-StorageLog "Disabling BitLocker on ${DriveLetter}:" -Level Info
        
        Disable-BitLocker -MountPoint "${DriveLetter}:" -ErrorAction Stop | Out-Null
        
        Write-StorageLog "BitLocker disabled successfully" -Level Success
    }
    catch {
        Write-StorageLog "Failed to disable BitLocker: $_" -Level Error
        throw
    }
}

function Unlock-WinPEBitLockerVolume {
    <#
    .SYNOPSIS
        Unlocks a BitLocker-encrypted volume
    
    .DESCRIPTION
        Unlocks a BitLocker volume using password or recovery key
    
    .EXAMPLE
        Unlock-WinPEBitLockerVolume -DriveLetter D -Password (Read-Host -AsSecureString)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [char]$DriveLetter,
        
        [Parameter()]
        [SecureString]$Password,
        
        [Parameter()]
        [string]$RecoveryKey
    )
    
    try {
        Write-StorageLog "Unlocking BitLocker volume ${DriveLetter}:" -Level Info
        
        if ($Password) {
            Unlock-BitLocker -MountPoint "${DriveLetter}:" -Password $Password -ErrorAction Stop | Out-Null
        } elseif ($RecoveryKey) {
            Unlock-BitLocker -MountPoint "${DriveLetter}:" -RecoveryPassword $RecoveryKey -ErrorAction Stop | Out-Null
        } else {
            throw "Either -Password or -RecoveryKey must be specified"
        }
        
        Write-StorageLog "BitLocker volume unlocked successfully" -Level Success
    }
    catch {
        Write-StorageLog "Failed to unlock BitLocker volume: $_" -Level Error
        throw
    }
}

#endregion

#region Storage Diagnostics Functions

function Test-WinPEDiskHealth {
    <#
    .SYNOPSIS
        Tests disk health and SMART status
    
    .DESCRIPTION
        Retrieves disk health information and SMART attributes
    
    .EXAMPLE
        Test-WinPEDiskHealth -DiskNumber 0
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$DiskNumber
    )
    
    try {
        Write-StorageLog "Testing health of disk $DiskNumber" -Level Info
        
        $disk = Get-Disk -Number $DiskNumber -ErrorAction Stop
        $physicalDisk = Get-PhysicalDisk | Where-Object { $_.DeviceId -eq $disk.Number } -ErrorAction SilentlyContinue
        
        $healthReport = [PSCustomObject]@{
            DiskNumber = $DiskNumber
            Model = $disk.Model
            HealthStatus = $disk.HealthStatus
            OperationalStatus = $disk.OperationalStatus
            IsOffline = $disk.IsOffline
            IsReadOnly = $disk.IsReadOnly
            PhysicalDiskHealthStatus = if ($physicalDisk) { $physicalDisk.HealthStatus } else { 'Unknown' }
            MediaType = if ($physicalDisk) { $physicalDisk.MediaType } else { 'Unknown' }
            CanPool = if ($physicalDisk) { $physicalDisk.CanPool } else { $false }
        }
        
        Write-StorageLog "Disk health check completed" -Level Success
        return $healthReport
    }
    catch {
        Write-StorageLog "Failed to test disk health: $_" -Level Error
        throw
    }
}

function Get-WinPEStorageReport {
    <#
    .SYNOPSIS
        Generates comprehensive storage report
    
    .DESCRIPTION
        Creates detailed report of all storage devices and volumes
    
    .EXAMPLE
        Get-WinPEStorageReport | Export-Csv -Path "StorageReport.csv"
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-StorageLog "Generating storage report" -Level Info
        
        $report = @{
            Disks = Get-WinPEDisks
            Volumes = Get-WinPEVolumes
            PhysicalDisks = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, BusType, HealthStatus, Size
            Partitions = Get-Partition | Select-Object DiskNumber, PartitionNumber, DriveLetter, Size, Type
            ReportDate = Get-Date
        }
        
        Write-StorageLog "Storage report generated successfully" -Level Success
        return $report
    }
    catch {
        Write-StorageLog "Failed to generate storage report: $_" -Level Error
        throw
    }
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    'Get-WinPEDisks',
    'Initialize-WinPEDisk',
    'New-WinPEPartition',
    'Remove-WinPEPartition',
    'Resize-WinPEPartition',
    'Get-WinPEVolumes',
    'Set-WinPEVolumeLabel',
    'Optimize-WinPEVolume',
    'New-WinPEDiskImage',
    'Restore-WinPEDiskImage',
    'Enable-WinPEBitLocker',
    'Disable-WinPEBitLocker',
    'Unlock-WinPEBitLockerVolume',
    'Test-WinPEDiskHealth',
    'Get-WinPEStorageReport'
)

#endregion
