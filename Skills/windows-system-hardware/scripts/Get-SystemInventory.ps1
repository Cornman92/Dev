#Requires -Version 5.1
<#
.SYNOPSIS
    Comprehensive Windows system hardware inventory collection.

.DESCRIPTION
    Collects detailed hardware information across all system components using
    CIM/WMI queries with registry supplementation. Supports multiple output
    formats and includes health status indicators.

.PARAMETER Full
    Include extended details for all categories.

.PARAMETER Categories
    Specific categories to collect. Default: All
    Valid: CPU, GPU, Memory, Storage, Network, Audio, USB, Motherboard, BIOS, TPM

.PARAMETER OutputFormat
    Output format: Object, JSON, HTML, CSV. Default: Object

.PARAMETER OutputPath
    Path for file output (required for HTML/CSV).

.PARAMETER IncludeDrivers
    Include driver information for each device.

.EXAMPLE
    .\Get-SystemInventory.ps1 -Full
    
.EXAMPLE
    .\Get-SystemInventory.ps1 -Categories CPU,GPU,Memory -OutputFormat JSON
#>

[CmdletBinding()]
param(
    [switch]$Full,
    
    [ValidateSet('CPU', 'GPU', 'Memory', 'Storage', 'Network', 'Audio', 'USB', 'Motherboard', 'BIOS', 'TPM', 'All')]
    [string[]]$Categories = @('All'),
    
    [ValidateSet('Object', 'JSON', 'HTML', 'CSV')]
    [string]$OutputFormat = 'Object',
    
    [string]$OutputPath,
    
    [switch]$IncludeDrivers
)

#region Helper Functions
function Get-ElevationStatus {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-CimInstanceSafe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ClassName,
        [string]$Namespace = 'root/cimv2',
        [string]$Filter,
        [string[]]$Property
    )
    
    try {
        $params = @{
            ClassName = $ClassName
            Namespace = $Namespace
            ErrorAction = 'Stop'
        }
        if ($Filter) { $params.Filter = $Filter }
        if ($Property) { $params.Property = $Property }
        
        Get-CimInstance @params
    }
    catch {
        Write-Warning "CIM query failed for $ClassName`: $_"
        $null
    }
}

function Format-Bytes {
    param([long]$Bytes)
    
    switch ($Bytes) {
        { $_ -ge 1TB } { "{0:N2} TB" -f ($_ / 1TB); break }
        { $_ -ge 1GB } { "{0:N2} GB" -f ($_ / 1GB); break }
        { $_ -ge 1MB } { "{0:N2} MB" -f ($_ / 1MB); break }
        { $_ -ge 1KB } { "{0:N2} KB" -f ($_ / 1KB); break }
        default { "$_ Bytes" }
    }
}
#endregion

#region Category Collection Functions
function Get-CPUInfo {
    [CmdletBinding()]
    param([switch]$Detailed)
    
    Write-Verbose "Collecting CPU information..."
    
    $processors = Get-CimInstanceSafe -ClassName Win32_Processor
    
    foreach ($cpu in $processors) {
        $info = [ordered]@{
            Category = 'CPU'
            Name = $cpu.Name.Trim()
            Manufacturer = $cpu.Manufacturer
            DeviceID = $cpu.DeviceID
            Cores = $cpu.NumberOfCores
            LogicalProcessors = $cpu.NumberOfLogicalProcessors
            MaxClockSpeedMHz = $cpu.MaxClockSpeed
            CurrentClockSpeedMHz = $cpu.CurrentClockSpeed
            L2CacheKB = $cpu.L2CacheSize
            L3CacheKB = $cpu.L3CacheSize
            Architecture = switch ($cpu.Architecture) {
                0 { 'x86' }
                5 { 'ARM' }
                9 { 'x64' }
                12 { 'ARM64' }
                default { "Unknown ($($cpu.Architecture))" }
            }
            SocketDesignation = $cpu.SocketDesignation
            Status = $cpu.Status
            VirtualizationEnabled = $cpu.VirtualizationFirmwareEnabled
            VMMonitorModeExtensions = $cpu.VMMonitorModeExtensions
        }
        
        if ($Detailed) {
            $info.ProcessorId = $cpu.ProcessorId
            $info.Revision = $cpu.Revision
            $info.Family = $cpu.Family
            $info.Stepping = $cpu.Stepping
            $info.AddressWidth = $cpu.AddressWidth
            $info.DataWidth = $cpu.DataWidth
        }
        
        [PSCustomObject]$info
    }
}

function Get-GPUInfo {
    [CmdletBinding()]
    param([switch]$Detailed)
    
    Write-Verbose "Collecting GPU information..."
    
    $adapters = Get-CimInstanceSafe -ClassName Win32_VideoController
    
    foreach ($gpu in $adapters) {
        $info = [ordered]@{
            Category = 'GPU'
            Name = $gpu.Name
            Manufacturer = $gpu.AdapterCompatibility
            DeviceID = $gpu.DeviceID
            DriverVersion = $gpu.DriverVersion
            DriverDate = $gpu.DriverDate
            AdapterRAM = Format-Bytes -Bytes $gpu.AdapterRAM
            AdapterRAMBytes = $gpu.AdapterRAM
            VideoProcessor = $gpu.VideoProcessor
            VideoModeDescription = $gpu.VideoModeDescription
            CurrentResolution = "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)"
            CurrentRefreshRate = "$($gpu.CurrentRefreshRate) Hz"
            CurrentBitsPerPixel = $gpu.CurrentBitsPerPixel
            Status = $gpu.Status
            Availability = switch ($gpu.Availability) {
                1 { 'Other' }
                2 { 'Unknown' }
                3 { 'Running/Full Power' }
                4 { 'Warning' }
                5 { 'In Test' }
                6 { 'Not Applicable' }
                7 { 'Power Off' }
                8 { 'Off Line' }
                default { $gpu.Availability }
            }
        }
        
        if ($Detailed) {
            $info.PNPDeviceID = $gpu.PNPDeviceID
            $info.InfFilename = $gpu.InfFilename
            $info.InfSection = $gpu.InfSection
            $info.VideoArchitecture = $gpu.VideoArchitecture
            $info.VideoMemoryType = $gpu.VideoMemoryType
        }
        
        [PSCustomObject]$info
    }
}

function Get-MemoryInfo {
    [CmdletBinding()]
    param([switch]$Detailed)
    
    Write-Verbose "Collecting memory information..."
    
    $modules = Get-CimInstanceSafe -ClassName Win32_PhysicalMemory
    $array = Get-CimInstanceSafe -ClassName Win32_PhysicalMemoryArray
    
    $results = @()
    
    # Memory summary
    $totalCapacity = ($modules | Measure-Object -Property Capacity -Sum).Sum
    $summary = [ordered]@{
        Category = 'Memory'
        Type = 'Summary'
        TotalCapacity = Format-Bytes -Bytes $totalCapacity
        TotalCapacityBytes = $totalCapacity
        ModuleCount = $modules.Count
        MaxCapacity = if ($array) { Format-Bytes -Bytes ($array.MaxCapacity * 1KB) } else { 'Unknown' }
        TotalSlots = if ($array) { $array.MemoryDevices } else { 'Unknown' }
    }
    $results += [PSCustomObject]$summary
    
    # Individual modules
    foreach ($mem in $modules) {
        $info = [ordered]@{
            Category = 'Memory'
            Type = 'Module'
            DeviceLocator = $mem.DeviceLocator
            BankLabel = $mem.BankLabel
            Capacity = Format-Bytes -Bytes $mem.Capacity
            CapacityBytes = $mem.Capacity
            SpeedMHz = $mem.Speed
            ConfiguredSpeedMHz = $mem.ConfiguredClockSpeed
            Manufacturer = $mem.Manufacturer
            PartNumber = $mem.PartNumber?.Trim()
            SerialNumber = $mem.SerialNumber
            MemoryType = switch ($mem.SMBIOSMemoryType) {
                20 { 'DDR' }
                21 { 'DDR2' }
                22 { 'DDR2 FB-DIMM' }
                24 { 'DDR3' }
                26 { 'DDR4' }
                34 { 'DDR5' }
                default { "Type $($mem.SMBIOSMemoryType)" }
            }
            FormFactor = switch ($mem.FormFactor) {
                8 { 'DIMM' }
                12 { 'SODIMM' }
                default { "FormFactor $($mem.FormFactor)" }
            }
        }
        
        if ($Detailed) {
            $info.DataWidth = $mem.DataWidth
            $info.TotalWidth = $mem.TotalWidth
            $info.TypeDetail = $mem.TypeDetail
        }
        
        $results += [PSCustomObject]$info
    }
    
    $results
}

function Get-StorageInfo {
    [CmdletBinding()]
    param([switch]$Detailed, [switch]$HealthCheck)
    
    Write-Verbose "Collecting storage information..."
    
    $results = @()
    
    # Physical disks
    $disks = Get-CimInstanceSafe -ClassName Win32_DiskDrive
    
    foreach ($disk in $disks) {
        $info = [ordered]@{
            Category = 'Storage'
            Type = 'PhysicalDisk'
            Model = $disk.Model
            DeviceID = $disk.DeviceID
            Index = $disk.Index
            Size = Format-Bytes -Bytes $disk.Size
            SizeBytes = $disk.Size
            MediaType = $disk.MediaType
            InterfaceType = $disk.InterfaceType
            SerialNumber = $disk.SerialNumber?.Trim()
            FirmwareRevision = $disk.FirmwareRevision
            Partitions = $disk.Partitions
            BytesPerSector = $disk.BytesPerSector
            SectorsPerTrack = $disk.SectorsPerTrack
            Status = $disk.Status
        }
        
        if ($HealthCheck) {
            # Try to get SMART data via storage reliability counter
            try {
                $reliability = Get-CimInstanceSafe -ClassName MSStorageDriver_FailurePredictStatus -Namespace 'root/wmi' |
                    Where-Object { $_.InstanceName -match $disk.PNPDeviceID.Replace('\', '\\') }
                $info.PredictFailure = if ($reliability) { $reliability.PredictFailure } else { 'Unknown' }
            }
            catch {
                $info.PredictFailure = 'Unavailable'
            }
        }
        
        $results += [PSCustomObject]$info
    }
    
    # Logical volumes
    $volumes = Get-CimInstanceSafe -ClassName Win32_LogicalDisk -Filter "DriveType=3"
    
    foreach ($vol in $volumes) {
        $info = [ordered]@{
            Category = 'Storage'
            Type = 'Volume'
            DeviceID = $vol.DeviceID
            VolumeName = $vol.VolumeName
            FileSystem = $vol.FileSystem
            Size = Format-Bytes -Bytes $vol.Size
            SizeBytes = $vol.Size
            FreeSpace = Format-Bytes -Bytes $vol.FreeSpace
            FreeSpaceBytes = $vol.FreeSpace
            UsedSpace = Format-Bytes -Bytes ($vol.Size - $vol.FreeSpace)
            PercentFree = if ($vol.Size -gt 0) { [math]::Round(($vol.FreeSpace / $vol.Size) * 100, 1) } else { 0 }
            Compressed = $vol.Compressed
            VolumeSerialNumber = $vol.VolumeSerialNumber
        }
        
        $results += [PSCustomObject]$info
    }
    
    $results
}

function Get-NetworkInfo {
    [CmdletBinding()]
    param([switch]$Detailed)
    
    Write-Verbose "Collecting network adapter information..."
    
    $adapters = Get-CimInstanceSafe -ClassName Win32_NetworkAdapter -Filter "PhysicalAdapter=True"
    $configs = Get-CimInstanceSafe -ClassName Win32_NetworkAdapterConfiguration
    
    foreach ($adapter in $adapters) {
        $config = $configs | Where-Object { $_.Index -eq $adapter.Index }
        
        $info = [ordered]@{
            Category = 'Network'
            Name = $adapter.Name
            Description = $adapter.Description
            DeviceID = $adapter.DeviceID
            Index = $adapter.Index
            MACAddress = $adapter.MACAddress
            Manufacturer = $adapter.Manufacturer
            NetConnectionID = $adapter.NetConnectionID
            NetConnectionStatus = switch ($adapter.NetConnectionStatus) {
                0 { 'Disconnected' }
                1 { 'Connecting' }
                2 { 'Connected' }
                3 { 'Disconnecting' }
                4 { 'Hardware Not Present' }
                5 { 'Hardware Disabled' }
                6 { 'Hardware Malfunction' }
                7 { 'Media Disconnected' }
                8 { 'Authenticating' }
                9 { 'Authentication Succeeded' }
                10 { 'Authentication Failed' }
                11 { 'Invalid Address' }
                12 { 'Credentials Required' }
                default { "Unknown ($($adapter.NetConnectionStatus))" }
            }
            Speed = if ($adapter.Speed) { "$([math]::Round($adapter.Speed / 1000000)) Mbps" } else { 'Unknown' }
            SpeedBps = $adapter.Speed
            AdapterType = $adapter.AdapterType
        }
        
        if ($config) {
            $info.DHCPEnabled = $config.DHCPEnabled
            $info.IPAddress = $config.IPAddress -join ', '
            $info.IPSubnet = $config.IPSubnet -join ', '
            $info.DefaultIPGateway = $config.DefaultIPGateway -join ', '
            $info.DNSServerSearchOrder = $config.DNSServerSearchOrder -join ', '
            $info.DHCPServer = $config.DHCPServer
        }
        
        if ($Detailed) {
            $info.PNPDeviceID = $adapter.PNPDeviceID
            $info.ServiceName = $adapter.ServiceName
            $info.GUID = $adapter.GUID
        }
        
        [PSCustomObject]$info
    }
}

function Get-MotherboardInfo {
    [CmdletBinding()]
    param([switch]$Detailed)
    
    Write-Verbose "Collecting motherboard information..."
    
    $board = Get-CimInstanceSafe -ClassName Win32_BaseBoard
    $system = Get-CimInstanceSafe -ClassName Win32_ComputerSystem
    $systemEnclosure = Get-CimInstanceSafe -ClassName Win32_SystemEnclosure
    
    $info = [ordered]@{
        Category = 'Motherboard'
        Manufacturer = $board.Manufacturer
        Product = $board.Product
        SerialNumber = $board.SerialNumber
        Version = $board.Version
        SystemManufacturer = $system.Manufacturer
        SystemModel = $system.Model
        SystemType = $system.SystemType
        PCSystemType = switch ($system.PCSystemType) {
            0 { 'Unspecified' }
            1 { 'Desktop' }
            2 { 'Mobile' }
            3 { 'Workstation' }
            4 { 'Enterprise Server' }
            5 { 'SOHO Server' }
            6 { 'Appliance PC' }
            7 { 'Performance Server' }
            8 { 'Maximum' }
            default { "Unknown ($($system.PCSystemType))" }
        }
        ChassisType = switch ($systemEnclosure.ChassisTypes[0]) {
            1 { 'Other' }
            2 { 'Unknown' }
            3 { 'Desktop' }
            4 { 'Low Profile Desktop' }
            5 { 'Pizza Box' }
            6 { 'Mini Tower' }
            7 { 'Tower' }
            8 { 'Portable' }
            9 { 'Laptop' }
            10 { 'Notebook' }
            11 { 'Hand Held' }
            12 { 'Docking Station' }
            13 { 'All in One' }
            14 { 'Sub Notebook' }
            15 { 'Space-Saving' }
            16 { 'Lunch Box' }
            17 { 'Main System Chassis' }
            18 { 'Expansion Chassis' }
            19 { 'SubChassis' }
            20 { 'Bus Expansion Chassis' }
            21 { 'Peripheral Chassis' }
            22 { 'Storage Chassis' }
            23 { 'Rack Mount Chassis' }
            24 { 'Sealed-Case PC' }
            30 { 'Tablet' }
            31 { 'Convertible' }
            32 { 'Detachable' }
            default { "Type $($systemEnclosure.ChassisTypes[0])" }
        }
        TotalPhysicalMemory = Format-Bytes -Bytes $system.TotalPhysicalMemory
    }
    
    if ($Detailed) {
        $info.Tag = $board.Tag
        $info.Status = $board.Status
        $info.HostingBoard = $board.HostingBoard
        $info.RequiresDaughterBoard = $board.RequiresDaughterBoard
        $info.Removable = $board.Removable
        $info.Replaceable = $board.Replaceable
    }
    
    [PSCustomObject]$info
}

function Get-BIOSInfo {
    [CmdletBinding()]
    param([switch]$Detailed)
    
    Write-Verbose "Collecting BIOS/UEFI information..."
    
    $bios = Get-CimInstanceSafe -ClassName Win32_BIOS
    
    $info = [ordered]@{
        Category = 'BIOS'
        Manufacturer = $bios.Manufacturer
        Name = $bios.Name
        Version = $bios.Version
        SMBIOSBIOSVersion = $bios.SMBIOSBIOSVersion
        SMBIOSMajorVersion = $bios.SMBIOSMajorVersion
        SMBIOSMinorVersion = $bios.SMBIOSMinorVersion
        ReleaseDate = $bios.ReleaseDate
        SerialNumber = $bios.SerialNumber
        Status = $bios.Status
        PrimaryBIOS = $bios.PrimaryBIOS
    }
    
    # Check for UEFI
    try {
        $firmware = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot\State' -ErrorAction Stop
        $info.SecureBootEnabled = $firmware.UEFISecureBootEnabled -eq 1
        $info.FirmwareType = 'UEFI'
    }
    catch {
        $info.SecureBootEnabled = $false
        $info.FirmwareType = 'Legacy BIOS'
    }
    
    if ($Detailed) {
        $info.BIOSVersion = $bios.BIOSVersion
        $info.BuildNumber = $bios.BuildNumber
        $info.Caption = $bios.Caption
        $info.CurrentLanguage = $bios.CurrentLanguage
        $info.InstallableLanguages = $bios.InstallableLanguages
    }
    
    [PSCustomObject]$info
}

function Get-TPMInfo {
    [CmdletBinding()]
    param([switch]$Detailed)
    
    Write-Verbose "Collecting TPM information..."
    
    try {
        $tpm = Get-CimInstanceSafe -ClassName Win32_Tpm -Namespace 'root/cimv2/Security/MicrosoftTpm'
        
        if ($tpm) {
            $info = [ordered]@{
                Category = 'TPM'
                IsPresent = $true
                IsActivated = $tpm.IsActivated_InitialValue
                IsEnabled = $tpm.IsEnabled_InitialValue
                IsOwned = $tpm.IsOwned_InitialValue
                ManufacturerId = $tpm.ManufacturerId
                ManufacturerIdTxt = $tpm.ManufacturerIdTxt
                ManufacturerVersion = $tpm.ManufacturerVersion
                ManufacturerVersionFull20 = $tpm.ManufacturerVersionFull20
                PhysicalPresenceVersionInfo = $tpm.PhysicalPresenceVersionInfo
                SpecVersion = $tpm.SpecVersion
            }
            
            if ($Detailed) {
                $info.ManufacturerVersionInfo = $tpm.ManufacturerVersionInfo
            }
            
            [PSCustomObject]$info
        }
        else {
            [PSCustomObject]@{
                Category = 'TPM'
                IsPresent = $false
                Status = 'TPM not detected'
            }
        }
    }
    catch {
        [PSCustomObject]@{
            Category = 'TPM'
            IsPresent = 'Unknown'
            Status = "Error querying TPM: $_"
        }
    }
}

function Get-AudioInfo {
    [CmdletBinding()]
    param([switch]$Detailed)
    
    Write-Verbose "Collecting audio device information..."
    
    $audioDevices = Get-CimInstanceSafe -ClassName Win32_SoundDevice
    
    foreach ($device in $audioDevices) {
        $info = [ordered]@{
            Category = 'Audio'
            Name = $device.Name
            ProductName = $device.ProductName
            Manufacturer = $device.Manufacturer
            DeviceID = $device.DeviceID
            Status = $device.Status
            StatusInfo = switch ($device.StatusInfo) {
                1 { 'Other' }
                2 { 'Unknown' }
                3 { 'Enabled' }
                4 { 'Disabled' }
                5 { 'Not Applicable' }
                default { $device.StatusInfo }
            }
        }
        
        if ($Detailed) {
            $info.PNPDeviceID = $device.PNPDeviceID
            $info.Caption = $device.Caption
            $info.Description = $device.Description
        }
        
        [PSCustomObject]$info
    }
}

function Get-USBInfo {
    [CmdletBinding()]
    param([switch]$Detailed)
    
    Write-Verbose "Collecting USB information..."
    
    $results = @()
    
    # USB Controllers
    $controllers = Get-CimInstanceSafe -ClassName Win32_USBController
    
    foreach ($ctrl in $controllers) {
        $info = [ordered]@{
            Category = 'USB'
            Type = 'Controller'
            Name = $ctrl.Name
            Manufacturer = $ctrl.Manufacturer
            DeviceID = $ctrl.DeviceID
            Status = $ctrl.Status
            ProtocolSupported = switch ($ctrl.ProtocolSupported) {
                15 { 'USB 1.x' }
                16 { 'USB 2.0' }
                default { "Protocol $($ctrl.ProtocolSupported)" }
            }
        }
        
        if ($Detailed) {
            $info.PNPDeviceID = $ctrl.PNPDeviceID
            $info.Caption = $ctrl.Caption
        }
        
        $results += [PSCustomObject]$info
    }
    
    # USB Hubs
    $hubs = Get-CimInstanceSafe -ClassName Win32_USBHub
    
    foreach ($hub in $hubs) {
        $info = [ordered]@{
            Category = 'USB'
            Type = 'Hub'
            Name = $hub.Name
            DeviceID = $hub.DeviceID
            Status = $hub.Status
            NumberOfPorts = $hub.NumberOfPorts
        }
        
        if ($Detailed) {
            $info.PNPDeviceID = $hub.PNPDeviceID
            $info.USBVersion = $hub.USBVersion
        }
        
        $results += [PSCustomObject]$info
    }
    
    $results
}
#endregion

#region Main Execution
function Invoke-SystemInventory {
    [CmdletBinding()]
    param()
    
    $isAdmin = Get-ElevationStatus
    if (-not $isAdmin) {
        Write-Warning "Running without administrator privileges. Some information may be limited."
    }
    
    $allCategories = @('CPU', 'GPU', 'Memory', 'Storage', 'Network', 'Motherboard', 'BIOS', 'TPM', 'Audio', 'USB')
    $selectedCategories = if ($Categories -contains 'All') { $allCategories } else { $Categories }
    
    $inventory = [ordered]@{
        CollectionTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ComputerName = $env:COMPUTERNAME
        CollectedAsAdmin = $isAdmin
        Categories = @{}
    }
    
    $totalCategories = $selectedCategories.Count
    $currentCategory = 0
    
    foreach ($category in $selectedCategories) {
        $currentCategory++
        Write-Progress -Activity "Collecting System Inventory" -Status "Processing $category" -PercentComplete (($currentCategory / $totalCategories) * 100)
        
        $categoryData = switch ($category) {
            'CPU' { Get-CPUInfo -Detailed:$Full }
            'GPU' { Get-GPUInfo -Detailed:$Full }
            'Memory' { Get-MemoryInfo -Detailed:$Full }
            'Storage' { Get-StorageInfo -Detailed:$Full -HealthCheck }
            'Network' { Get-NetworkInfo -Detailed:$Full }
            'Motherboard' { Get-MotherboardInfo -Detailed:$Full }
            'BIOS' { Get-BIOSInfo -Detailed:$Full }
            'TPM' { Get-TPMInfo -Detailed:$Full }
            'Audio' { Get-AudioInfo -Detailed:$Full }
            'USB' { Get-USBInfo -Detailed:$Full }
        }
        
        if ($categoryData) {
            $inventory.Categories[$category] = @($categoryData)
        }
    }
    
    Write-Progress -Activity "Collecting System Inventory" -Completed
    
    # Output based on format
    switch ($OutputFormat) {
        'Object' {
            foreach ($cat in $inventory.Categories.Keys) {
                $inventory.Categories[$cat]
            }
        }
        'JSON' {
            $json = $inventory | ConvertTo-Json -Depth 10
            if ($OutputPath) {
                $json | Set-Content -Path $OutputPath -Encoding UTF8
                Write-Host "JSON saved to: $OutputPath" -ForegroundColor Green
            }
            else {
                $json
            }
        }
        'HTML' {
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>System Inventory - $($inventory.ComputerName)</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 20px; background: #1a1a2e; color: #eee; }
        h1 { color: #00d4ff; border-bottom: 2px solid #00d4ff; padding-bottom: 10px; }
        h2 { color: #00d4ff; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin: 15px 0; background: #16213e; }
        th, td { border: 1px solid #0f3460; padding: 10px; text-align: left; }
        th { background: #0f3460; color: #00d4ff; }
        tr:nth-child(even) { background: #1a1a3e; }
        .info { color: #888; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1>System Inventory Report</h1>
    <p class="info">Computer: $($inventory.ComputerName) | Collected: $($inventory.CollectionTime) | Admin: $($inventory.CollectedAsAdmin)</p>
"@
            foreach ($cat in $inventory.Categories.Keys) {
                $html += "<h2>$cat</h2>"
                $html += ($inventory.Categories[$cat] | ConvertTo-Html -Fragment)
            }
            $html += "</body></html>"
            
            if ($OutputPath) {
                $html | Set-Content -Path $OutputPath -Encoding UTF8
                Write-Host "HTML saved to: $OutputPath" -ForegroundColor Green
            }
            else {
                $html
            }
        }
        'CSV' {
            if (-not $OutputPath) {
                Write-Error "OutputPath required for CSV format"
                return
            }
            $allData = foreach ($cat in $inventory.Categories.Keys) {
                $inventory.Categories[$cat]
            }
            $allData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
            Write-Host "CSV saved to: $OutputPath" -ForegroundColor Green
        }
    }
}

# Execute
Invoke-SystemInventory
#endregion
