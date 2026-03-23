<#
.SYNOPSIS
    Better11.Drivers - Driver management for Better11 Suite

.DESCRIPTION
    Provides driver detection, installation, backup, and management functionality.
    Supports Windows Update, OEM sources, and manual driver installation.

.NOTES
    Version: 1.0.0
    Author: Windows Automation Workspace
    Copyright: (c) 2024 Windows Automation Workspace. All rights reserved.
#>

#region Module Variables
$script:ModuleVersion = '1.0.0'
$script:ModuleName = 'Better11.Drivers'
#endregion

#region Module Initialization
# Import Better11.Core for common functionality
$better11CorePath = Join-Path $PSScriptRoot 'Better11.Core.psm1'
if (Test-Path $better11CorePath) {
    try {
        Import-Module $better11CorePath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Could not import Better11.Core: $_"
    }
}

# Import Better11.Retry for retry logic
$better11RetryPath = Join-Path $PSScriptRoot 'Better11.Retry.psm1'
if (Test-Path $better11RetryPath) {
    try {
        Import-Module $better11RetryPath -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Could not import Better11.Retry: $_"
    }
}
#endregion

#region Hardware Detection

function Get-Better11Hardware {
    <#
    .SYNOPSIS
        Gets hardware information for driver management
    
    .DESCRIPTION
        Retrieves hardware information using WMI/CIM to identify devices that may need drivers.
    
    .PARAMETER DeviceClass
        Filter by device class (e.g., 'Display', 'Network', 'Audio')
    
    .EXAMPLE
        Get-Better11Hardware
    
    .EXAMPLE
        Get-Better11Hardware -DeviceClass 'Display'
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param(
        [Parameter()]
        [string]$DeviceClass
    )
    
    try {
        $devices = Get-CimInstance -ClassName Win32_PnPEntity | Where-Object {
            $_.Status -ne 'OK' -or $_.ConfigManagerErrorCode -ne 0
        }
        
        $hardware = @()
        foreach ($device in $devices) {
            $deviceInfo = @{
                Name = $device.Name
                DeviceID = $device.DeviceID
                PNPDeviceID = $device.PNPDeviceID
                Status = $device.Status
                ErrorCode = $device.ConfigManagerErrorCode
                Class = $device.Class
                Manufacturer = $device.Manufacturer
                Description = $device.Description
            }
            
            if (-not $DeviceClass -or $device.Class -eq $DeviceClass) {
                $hardware += [PSCustomObject]$deviceInfo
            }
        }
        
        return $hardware
    }
    catch {
        Write-Error "Failed to get hardware information: $_"
        throw
    }
}

function Get-Better11DriverStatus {
    <#
    .SYNOPSIS
        Gets driver status for all devices
    
    .DESCRIPTION
        Checks driver status for all hardware devices and identifies those needing drivers.
    
    .EXAMPLE
        Get-Better11DriverStatus
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param()
    
    try {
        $devices = Get-CimInstance -ClassName Win32_PnPEntity
        $status = @()
        
        foreach ($device in $devices) {
            $driverStatus = @{
                DeviceName = $device.Name
                DeviceID = $device.DeviceID
                Status = $device.Status
                NeedsDriver = ($device.Status -ne 'OK' -or $device.ConfigManagerErrorCode -ne 0)
                ErrorCode = $device.ConfigManagerErrorCode
                DriverProvider = $null
                DriverVersion = $null
                DriverDate = $null
            }
            
            # Get driver information if available
            try {
                $driver = Get-CimInstance -ClassName Win32_PnPSignedDriver | Where-Object {
                    $_.DeviceID -eq $device.PNPDeviceID
                } | Select-Object -First 1
                
                if ($driver) {
                    $driverStatus.DriverProvider = $driver.DriverProviderName
                    $driverStatus.DriverVersion = $driver.DriverVersion
                    $driverStatus.DriverDate = $driver.DriverDate
                }
            }
            catch {
                # Driver info not available
            }
            
            $status += [PSCustomObject]$driverStatus
        }
        
        return $status
    }
    catch {
        Write-Error "Failed to get driver status: $_"
        throw
    }
}

#endregion

#region Driver Installation

function Install-Better11Driver {
    <#
    .SYNOPSIS
        Installs a driver for a device
    
    .DESCRIPTION
        Installs a driver from various sources including Windows Update, local path, or INF file.
    
    .PARAMETER DeviceID
        Device ID or PNP Device ID
    
    .PARAMETER DriverPath
        Path to driver INF file or driver package
    
    .PARAMETER UseWindowsUpdate
        Attempt to find and install driver via Windows Update
    
    .PARAMETER Force
        Force reinstallation even if driver is already installed
    
    .EXAMPLE
        Install-Better11Driver -DeviceID 'PCI\VEN_10DE&DEV_1B80' -UseWindowsUpdate
    
    .EXAMPLE
        Install-Better11Driver -DriverPath 'C:\Drivers\NVIDIA\driver.inf' -Force
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(ParameterSetName = 'ByDevice')]
        [string]$DeviceID,
        
        [Parameter(ParameterSetName = 'ByPath', Mandatory)]
        [string]$DriverPath,
        
        [Parameter(ParameterSetName = 'ByDevice')]
        [switch]$UseWindowsUpdate,
        
        [Parameter()]
        [switch]$Force
    )
    
    if ($PSCmdlet.ShouldProcess($DeviceID ?? $DriverPath, "Install driver")) {
        try {
            if ($DriverPath) {
                return Install-Better11DriverFromPath -DriverPath $DriverPath -Force:$Force
            }
            elseif ($UseWindowsUpdate) {
                return Install-Better11DriverFromWindowsUpdate -DeviceID $DeviceID -Force:$Force
            }
            else {
                throw "Either DriverPath or UseWindowsUpdate must be specified"
            }
        }
        catch {
            if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                Write-Better11Log -Level 'ERROR' -Message "Failed to install driver: $_"
            }
            Write-Error "Failed to install driver: $_"
            throw
        }
    }
    
    return $false
}

function Install-Better11DriverFromPath {
    <#
    .SYNOPSIS
        Installs driver from local path
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DriverPath,
        
        [Parameter()]
        [switch]$Force
    )
    
    if (-not (Test-Path $DriverPath)) {
        throw "Driver path not found: $DriverPath"
    }
    
    try {
        $fullPath = Resolve-Path $DriverPath
        
        if (Get-Command 'Invoke-Better11Retry' -ErrorAction SilentlyContinue) {
            return Invoke-Better11Retry -Action {
                if ($fullPath.Path.EndsWith('.inf')) {
                    # Install from INF file
                    $result = pnputil.exe /add-driver $fullPath.Path /install
                    if ($LASTEXITCODE -ne 0) {
                        throw "pnputil failed with exit code $LASTEXITCODE"
                    }
                }
                else {
                    # Install from driver package directory
                    $result = pnputil.exe /add-driver "$fullPath\*.inf" /install /subdirs
                    if ($LASTEXITCODE -ne 0) {
                        throw "pnputil failed with exit code $LASTEXITCODE"
                    }
                }
                return $true
            } -RetryCount 2 -RetryDelay 2
        }
        else {
            if ($fullPath.Path.EndsWith('.inf')) {
                $result = pnputil.exe /add-driver $fullPath.Path /install
            }
            else {
                $result = pnputil.exe /add-driver "$fullPath\*.inf" /install /subdirs
            }
            
            if ($LASTEXITCODE -ne 0) {
                throw "pnputil failed with exit code $LASTEXITCODE"
            }
            
            return $true
        }
    }
    catch {
        Write-Error "Failed to install driver from path: $_"
        throw
    }
}

function Install-Better11DriverFromWindowsUpdate {
    <#
    .SYNOPSIS
        Installs driver from Windows Update
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DeviceID,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        # Use Windows Update to find and install driver
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        
        # Search for driver updates
        $searchResult = $updateSearcher.Search("IsInstalled=0 and Type='Driver'")
        
        $driverFound = $false
        foreach ($update in $searchResult.Updates) {
            if ($update.Title -match [regex]::Escape($DeviceID)) {
                $driverFound = $true
                
                # Download and install
                $updatesToDownload = New-Object -ComObject Microsoft.Update.UpdateColl
                $updatesToDownload.Add($update) | Out-Null
                
                $downloader = $updateSession.CreateUpdateDownloader()
                $downloader.Updates = $updatesToDownload
                $downloadResult = $downloader.Download()
                
                if ($downloadResult.ResultCode -eq 2) {
                    $installer = $updateSession.CreateUpdateInstaller()
                    $installer.Updates = $updatesToDownload
                    $installResult = $installer.Install()
                    
                    if ($installResult.ResultCode -eq 2) {
                        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                            Write-Better11Log -Level 'INFO' -Message "Successfully installed driver from Windows Update for $DeviceID"
                        }
                        return $true
                    }
                }
            }
        }
        
        if (-not $driverFound) {
            Write-Warning "No driver found in Windows Update for device $DeviceID"
            return $false
        }
    }
    catch {
        Write-Error "Failed to install driver from Windows Update: $_"
        throw
    }
}

#endregion

#region Driver Backup and Restore

function Backup-Better11Drivers {
    <#
    .SYNOPSIS
        Backs up installed drivers
    
    .DESCRIPTION
        Exports all installed drivers to a backup location for later restoration.
    
    .PARAMETER BackupPath
        Path to save driver backups
    
    .PARAMETER IncludeAll
        Include all drivers, not just third-party
    
    .EXAMPLE
        Backup-Better11Drivers -BackupPath 'C:\DriverBackup'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$BackupPath,
        
        [Parameter()]
        [switch]$IncludeAll
    )
    
    if ($PSCmdlet.ShouldProcess($BackupPath, "Backup drivers")) {
        try {
            if (-not (Test-Path $BackupPath)) {
                New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
            }
            
            $exportPath = Join-Path $BackupPath "drivers_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
            New-Item -ItemType Directory -Path $exportPath -Force | Out-Null
            
            # Use DISM to export drivers
            $dismArgs = @(
                '/online'
                '/export-driver'
                "/destination:$exportPath"
            )
            
            if ($IncludeAll) {
                $dismArgs += '/all'
            }
            
            $result = & dism.exe $dismArgs 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                    Write-Better11Log -Level 'INFO' -Message "Drivers backed up to $exportPath"
                }
                return $true
            }
            else {
                throw "DISM export failed: $result"
            }
        }
        catch {
            if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                Write-Better11Log -Level 'ERROR' -Message "Failed to backup drivers: $_"
            }
            Write-Error "Failed to backup drivers: $_"
            throw
        }
    }
    
    return $false
}

function Restore-Better11Drivers {
    <#
    .SYNOPSIS
        Restores drivers from backup
    
    .DESCRIPTION
        Restores drivers from a previously created backup.
    
    .PARAMETER BackupPath
        Path to driver backup
    
    .EXAMPLE
        Restore-Better11Drivers -BackupPath 'C:\DriverBackup\drivers_20240101_120000'
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$BackupPath
    )
    
    if ($PSCmdlet.ShouldProcess($BackupPath, "Restore drivers")) {
        try {
            if (-not (Test-Path $BackupPath)) {
                throw "Backup path not found: $BackupPath"
            }
            
            # Use DISM to add drivers
            $result = & dism.exe /online /add-driver "/driver:$BackupPath" /recurse 2>&1
            
            if ($LASTEXITCODE -eq 0) {
                if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                    Write-Better11Log -Level 'INFO' -Message "Drivers restored from $BackupPath"
                }
                return $true
            }
            else {
                throw "DISM restore failed: $result"
            }
        }
        catch {
            if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
                Write-Better11Log -Level 'ERROR' -Message "Failed to restore drivers: $_"
            }
            Write-Error "Failed to restore drivers: $_"
            throw
        }
    }
    
    return $false
}

#endregion

#region Driver Updates & Scanning

function Update-Better11Drivers {
    <#
    .SYNOPSIS
        Updates drivers for devices
    
    .DESCRIPTION
        Checks for and installs driver updates for all devices or specific device classes.
    
    .PARAMETER DeviceClass
        Filter by device class (e.g., 'Display', 'Network', 'Audio')
    
    .PARAMETER UseWindowsUpdate
        Use Windows Update to find driver updates
    
    .PARAMETER WhatIf
        Show what would be updated without actually updating
    
    .EXAMPLE
        Update-Better11Drivers -UseWindowsUpdate
    #>
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [string]$DeviceClass,
        
        [Parameter()]
        [switch]$UseWindowsUpdate,
        
        [Parameter()]
        [switch]$WhatIf
    )
    
    $results = @{
        Updated = @()
        Failed = @()
        Skipped = @()
        Total = 0
    }
    
    try {
        $devices = Get-Better11Hardware -DeviceClass $DeviceClass
        $results.Total = $devices.Count
        
        foreach ($device in $devices) {
            if ($WhatIf) {
                Write-Host "WhatIf: Would update driver for $($device.Name)"
                $results.Skipped += $device
                continue
            }
            
            if ($PSCmdlet.ShouldProcess($device.Name, "Update driver")) {
                try {
                    if ($UseWindowsUpdate) {
                        $success = Install-Better11Driver -DeviceID $device.PNPDeviceID -UseWindowsUpdate
                        if ($success) {
                            $results.Updated += $device
                        }
                        else {
                            $results.Failed += @{
                                Device = $device
                                Error = "Driver update not found or failed"
                            }
                        }
                    }
                    else {
                        Write-Warning "Windows Update is required for automatic driver updates"
                        $results.Skipped += $device
                    }
                }
                catch {
                    $results.Failed += @{
                        Device = $device
                        Error = $_.Exception.Message
                    }
                }
            }
        }
        
        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
            Write-Better11Log -Level 'INFO' -Message "Driver update completed: $($results.Updated.Count) updated, $($results.Failed.Count) failed, $($results.Skipped.Count) skipped"
        }
    }
    catch {
        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
            Write-Better11Log -Level 'ERROR' -Message "Failed to update drivers: $_"
        }
        Write-Error "Failed to update drivers: $_"
        throw
    }
    
    return $results
}

function Get-Better11DriverRecommendations {
    <#
    .SYNOPSIS
        Gets driver update recommendations
    
    .DESCRIPTION
        Analyzes system and provides recommendations for driver updates.
    
    .EXAMPLE
        Get-Better11DriverRecommendations
    #>
    [CmdletBinding()]
    [OutputType([array])]
    param()
    
    $recommendations = @()
    $driverStatus = Get-Better11DriverStatus
    
    foreach ($device in $driverStatus) {
        if ($device.NeedsDriver) {
            $recommendation = @{
                DeviceName = $device.DeviceName
                DeviceID = $device.DeviceID
                Priority = 'High'
                Reason = "Device needs driver (Error Code: $($device.ErrorCode))"
                Recommendation = "Install driver via Windows Update or manual installation"
            }
            
            # Check if device is critical
            if ($device.DeviceName -match 'Display|Network|Audio|Storage') {
                $recommendation.Priority = 'Critical'
            }
            
            $recommendations += [PSCustomObject]$recommendation
        }
        elseif ($device.DriverVersion) {
            # Check if driver is outdated (simplified - would need version comparison)
            $recommendation = @{
                DeviceName = $device.DeviceName
                DeviceID = $device.DeviceID
                Priority = 'Medium'
                Reason = "Driver may be outdated"
                Recommendation = "Check for driver updates via Windows Update"
                CurrentVersion = $device.DriverVersion
            }
            
            $recommendations += [PSCustomObject]$recommendation
        }
    }
    
    return $recommendations
}

function Scan-Better11Drivers {
    <#
    .SYNOPSIS
        Scans system for driver issues
    
    .DESCRIPTION
        Performs a comprehensive scan of the system for driver-related issues.
    
    .PARAMETER IncludeDetails
        Include detailed information about each device
    
    .EXAMPLE
        Scan-Better11Drivers
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter()]
        [switch]$IncludeDetails
    )
    
    $scanResults = @{
        ScanDate = Get-Date
        TotalDevices = 0
        DevicesWithDrivers = 0
        DevicesNeedingDrivers = 0
        DevicesWithErrors = 0
        CriticalIssues = @()
        Warnings = @()
        Details = @()
    }
    
    try {
        $driverStatus = Get-Better11DriverStatus
        $scanResults.TotalDevices = $driverStatus.Count
        
        foreach ($device in $driverStatus) {
            if ($device.DriverVersion) {
                $scanResults.DevicesWithDrivers++
            }
            
            if ($device.NeedsDriver) {
                $scanResults.DevicesNeedingDrivers++
                
                if ($device.DeviceName -match 'Display|Network|Audio|Storage') {
                    $scanResults.CriticalIssues += @{
                        Device = $device.DeviceName
                        ErrorCode = $device.ErrorCode
                        Status = $device.Status
                    }
                }
                else {
                    $scanResults.Warnings += @{
                        Device = $device.DeviceName
                        ErrorCode = $device.ErrorCode
                        Status = $device.Status
                    }
                }
            }
            
            if ($device.ErrorCode -ne 0) {
                $scanResults.DevicesWithErrors++
            }
            
            if ($IncludeDetails) {
                $scanResults.Details += $device
            }
        }
        
        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
            Write-Better11Log -Level 'INFO' -Message "Driver scan completed: $($scanResults.DevicesNeedingDrivers) devices need drivers, $($scanResults.CriticalIssues.Count) critical issues"
        }
    }
    catch {
        if (Get-Command 'Write-Better11Log' -ErrorAction SilentlyContinue) {
            Write-Better11Log -Level 'ERROR' -Message "Driver scan failed: $_"
        }
        Write-Error "Driver scan failed: $_"
        throw
    }
    
    return $scanResults
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Get-Better11Hardware',
    'Get-Better11DriverStatus',
    'Install-Better11Driver',
    'Install-Better11DriverFromPath',
    'Install-Better11DriverFromWindowsUpdate',
    'Backup-Better11Drivers',
    'Restore-Better11Drivers',
    'Update-Better11Drivers',
    'Get-Better11DriverRecommendations',
    'Scan-Better11Drivers'
)
