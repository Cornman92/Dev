# System-Utilities.psm1
# Comprehensive system monitoring and management utilities
# Version: 2.0.0

#region Module Setup
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]

# Import required modules
#Requires -Version 5.1
#Requires -RunAsAdministrator
#Requires -Modules @{ ModuleName='PSFramework'; ModuleVersion='1.0.0' }

# Set strict mode
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Module variables
$script:ModuleName = 'System-Utilities'
$script:ModuleVersion = '2.0.0'
$script:ModuleConfigPath = "$env:APPDATA\\$ModuleName\\Config"

# Create config directory if it doesn't exist
if (-not (Test-Path -Path $script:ModuleConfigPath)) {
    $null = New-Item -Path $script:ModuleConfigPath -ItemType Directory -Force
}

# Import helper modules
$privateFunctions = @(Get-ChildItem -Path "$PSScriptRoot\\Private\\*.ps1" -ErrorAction SilentlyContinue)
$publicFunctions = @(Get-ChildItem -Path "$PSScriptRoot\\Public\\*.ps1" -ErrorAction SilentlyContinue)

# Dot source all private functions
foreach ($function in $privateFunctions) {
    try {
        . $function.FullName
        Write-Debug "Imported private function: $($function.Name)"
    }
    catch {
        Write-Error "Failed to import private function $($function.Name): $_"
    }
}

# Export public functions
export-modulemember -Function ($publicFunctions | Select-Object -ExpandProperty BaseName) -Alias *

# Initialize module
$script:InitializationComplete = $false

function Initialize-Module {
    [CmdletBinding()]
    param()
    
    if ($script:InitializationComplete) { return }
    
    try {
        # Load configuration
        $script:ModuleConfig = Import-Configuration
        
        # Initialize logging
        Initialize-Logging
        
        # Initialize performance counters
        Initialize-PerformanceMonitoring
        
        $script:InitializationComplete = $true
        Write-PSFMessage -Level Verbose -Message 'Module initialization complete'
    }
    catch {
        Write-Error "Failed to initialize module: $_"
        throw $_
    }
}

# Initialize the module
$null = Initialize-Module
#endregion

#region Core Functions
function Get-SystemInfo {
    <#
    .SYNOPSIS
        Gets comprehensive system information
    .DESCRIPTION
        Retrieves detailed system information including hardware, OS, and performance metrics
        with support for remote computers and custom output formats.
    .PARAMETER ComputerName
        Specifies the target computer. Default is localhost.
    .PARAMETER AsJson
        Output results as JSON format.
    .PARAMETER IncludePerformance
        Include performance metrics (CPU, Memory, Disk usage).
    .EXAMPLE
        Get-SystemInfo
        Get basic system information for the local computer.
    .EXAMPLE
        Get-SystemInfo -ComputerName 'SERVER01', 'SERVER02' -IncludePerformance -AsJson | ConvertFrom-Json
        Get detailed system information from multiple computers and convert from JSON.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [Alias('CN', 'Computer')]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [switch]$AsJson,
        
        [switch]$IncludePerformance
    )
    
    begin {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $results = [System.Collections.Generic.List[PSObject]]::new()
        
        # Common parameters for CIM sessions
        $cimParams = @{
            ErrorAction = 'Stop'
            ErrorVariable = 'cimError'
        }
    }
    
    process {
        foreach ($computer in $ComputerName) {
            try {
                Write-Progress -Activity 'Collecting System Information' -Status $computer -PercentComplete 0
                
                # Get basic system information
                $os = Get-CimInstance -ClassName Win32_OperatingSystem @cimParams -ComputerName $computer
                $cs = Get-CimInstance -ClassName Win32_ComputerSystem @cimParams -ComputerName $computer
                $bios = Get-CimInstance -ClassName Win32_BIOS @cimParams -ComputerName $computer
                $proc = Get-CimInstance -ClassName Win32_Processor @cimParams -ComputerName $computer | Select-Object -First 1
                
                # Calculate memory metrics
                $totalMemory = [math]::Round(($cs.TotalPhysicalMemory / 1GB), 2)
                $freeMemory = [math]::Round(($os.FreePhysicalMemory / 1MB), 2)
                $usedMemory = $totalMemory - $freeMemory
                $memoryUsage = if ($totalMemory -gt 0) { [math]::Round(($usedMemory / $totalMemory) * 100, 2) } else { 0 }
                
                # Build result object
                $systemInfo = [PSCustomObject]@{
                    PSTypeName = 'System.Info'
                    ComputerName = $computer
                    Status = 'Online'
                    LastUpdated = [DateTime]::Now
                    OS = @{
                        Name = $os.Caption
                        Version = $os.Version
                        Build = $os.BuildNumber
                        Architecture = if ([Environment]::Is64BitOperatingSystem) { '64-bit' } else { '32-bit' }
                        InstallDate = $os.InstallDate
                        LastBootTime = $os.LastBootUpTime
                        Uptime = (Get-Date) - $os.LastBootUpTime
                        Timezone = (Get-TimeZone).DisplayName
                    }
                    Hardware = @{
                        Manufacturer = $cs.Manufacturer
                        Model = $cs.Model
                        SystemType = $cs.SystemType
                        BIOS = @{
                            Version = $bios.SMBIOSBIOSVersion
                            SerialNumber = $bios.SerialNumber
                            ReleaseDate = $bios.ReleaseDate
                        }
                        Processor = @{
                            Name = $proc.Name
                            Cores = $proc.NumberOfCores
                            LogicalProcessors = $proc.NumberOfLogicalProcessors
                            MaxClockSpeed = "$($proc.MaxClockSpeed) MHz"
                            Socket = $proc.SocketDesignation
                        }
                        Memory = @{
                            TotalGB = $totalMemory
                            FreeGB = $freeMemory
                            UsedGB = $usedMemory
                            UsagePercent = $memoryUsage
                        }
                    }
                }
                
                # Add performance metrics if requested
                if ($IncludePerformance) {
                    $cpuUsage = Get-Counter -Counter '\\$computer\\Processor(_Total)\\% Processor Time' -ErrorAction SilentlyContinue | 
                        Select-Object -ExpandProperty CounterSamples | 
                        Select-Object -ExpandProperty CookedValue
                    
                    $diskUsage = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" @cimParams -ComputerName $computer | 
                        ForEach-Object {
                            $sizeGB = [math]::Round(($_.Size / 1GB), 2)
                            $freeGB = [math]::Round(($_.FreeSpace / 1GB), 2)
                            $usedGB = $sizeGB - $freeGB
                            $usage = if ($sizeGB -gt 0) { [math]::Round(($usedGB / $sizeGB) * 100, 2) } else { 0 }
                            
                            [PSCustomObject]@{
                                Drive = $_.DeviceID
                                SizeGB = $sizeGB
                                FreeGB = $freeGB
                                UsedGB = $usedGB
                                UsagePercent = $usage
                                Label = $_.VolumeName
                                FileSystem = $_.FileSystem
                            }
                        }
                    
                    $systemInfo | Add-Member -NotePropertyName 'Performance' -NotePropertyValue @{
                        Timestamp = [DateTime]::Now
                        CpuUsage = [math]::Round($cpuUsage, 2)
                        MemoryUsage = $memoryUsage
                        DiskUsage = $diskUsage
                    }
                }
                
                # Add to results
                $results.Add($systemInfo)
                
                Write-Progress -Activity 'Collecting System Information' -Status "Completed: $computer" -PercentComplete 100
            }
            catch {
                Write-Error "Failed to get system information for $computer : $_"
                $results.Add([PSCustomObject]@{
                    ComputerName = $computer
                    Status = 'Error'
                    Error = $_.Exception.Message
                    LastUpdated = [DateTime]::Now
                })
            }
        }
    }
    
    end {
        $stopwatch.Stop()
        Write-Verbose "System information collected in $($stopwatch.Elapsed.TotalSeconds) seconds"
        
        # Output results
        if ($AsJson) {
            return $results | ConvertTo-Json -Depth 5 -Compress
        }
        return $results
    }
}

function Get-NetworkInfo {
    <#
    .SYNOPSIS
        Gets comprehensive network configuration and statistics
    .DESCRIPTION
        Retrieves detailed network adapter configurations, active connections,
        and network statistics with support for remote computers.
    .EXAMPLE
        Get-NetworkInfo -Detailed
        Get detailed network information including active connections.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [switch]$Detailed,
        
        [ValidateSet('IPv4', 'IPv6', 'All')]
        [string]$AddressFamily = 'All'
    )
    
    begin {
        $results = [System.Collections.Generic.List[PSObject]]::new()
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    }
    
    process {
        foreach ($computer in $ComputerName) {
            try {
                Write-Progress -Activity 'Collecting Network Information' -Status $computer -PercentComplete 0
                
                # Get network adapters
                $adapters = Get-NetAdapter -CimSession $computer -ErrorAction Stop | 
                    Where-Object { $_.Status -eq 'Up' }
                
                $networkInfo = [PSCustomObject]@{
                    ComputerName = $computer
                    Status = 'Online'
                    LastUpdated = [DateTime]::Now
                    NetworkAdapters = @()
                    ActiveConnections = @()
                    NetworkStatistics = $null
                }
                
                # Process each adapter
                foreach ($adapter in $adapters) {
                    $ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.InterfaceIndex -ErrorAction SilentlyContinue
                    
                    if ($ipConfig) {
                        $adapterInfo = [PSCustomObject]@{
                            Name = $adapter.Name
                            InterfaceAlias = $adapter.InterfaceAlias
                            InterfaceIndex = $adapter.InterfaceIndex
                            Status = $adapter.Status
                            MacAddress = $adapter.MacAddress
                            LinkSpeed = $adapter.LinkSpeed
                            
                            # IP Configuration
                            IPv4Address = ($ipConfig.IPv4Address | Where-Object { $_.AddressFamily -eq 'IPv4' }).IPAddress -join ', '
                            IPv6Address = ($ipConfig.IPv6Address | Where-Object { $_.AddressFamily -eq 'IPv6' }).IPAddress -join ', '
                            SubnetMask = ($ipConfig.IPv4Address | Where-Object { $_.AddressFamily -eq 'IPv4' }).PrefixLength -join ', '
                            DefaultGateway = $ipConfig.IPv4DefaultGateway.NextHop -join ', '
                            
                            # DNS Configuration
                            DNSServers = $ipConfig.DNSServer.ServerAddresses -join ', '
                            DNSSuffix = $ipConfig.DNSSuffix
                            
                            # DHCP Information
                            DHCPEnabled = $ipConfig.NetAdapter.DHCP
                            DHCPServer = $ipConfig.NetIPv4Interface.DHCPServer
                            LeaseObtained = $ipConfig.NetIPv4Interface.DHCPLeaseObtainedTime
                            LeaseExpires = $ipConfig.NetIPv4Interface.DHCPLeaseExpiresTime
                        }
                        
                        $networkInfo.NetworkAdapters += $adapterInfo
                    }
                }
                
                # Get active connections if detailed
                if ($Detailed) {
                    $tcpConnections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | 
                        Where-Object { $_.OwningProcess -ne 0 } | 
                        Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, State, 
                            @{Name='Process';Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}}
                    
                    $udpConnections = Get-NetUDPEndpoint -ErrorAction SilentlyContinue | 
                        Where-Object { $_.OwningProcess -ne 0 } | 
                        Select-Object LocalAddress, LocalPort, 
                            @{Name='Process';Expression={(Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName}}
                    
                    $networkInfo.ActiveConnections = @{
                        TCP = $tcpConnections
                        UDP = $udpConnections
                    }
                    
                    # Get network statistics
                    $networkInfo.NetworkStatistics = Get-NetAdapterStatistics | 
                        Select-Object Name, ReceivedBytes, SentBytes, ReceivedPacketsUnicastPerSecond, 
                            SentPacketsUnicastPerSecond, ReceivedPacketsPerSecond, SentPacketsPerSecond
                }
                
                $results.Add($networkInfo)
                Write-Progress -Activity 'Collecting Network Information' -Status "Completed: $computer" -PercentComplete 100
            }
            catch {
                Write-Error "Failed to get network information for $computer : $_"
                $results.Add([PSCustomObject]@{
                    ComputerName = $computer
                    Status = 'Error'
                    Error = $_.Exception.Message
                    LastUpdated = [DateTime]::Now
                })
            }
        }
    }
    
    end {
        $stopwatch.Stop()
        Write-Verbose "Network information collected in $($stopwatch.Elapsed.TotalSeconds) seconds"
        return $results
    }
}

function Get-DiskInfo {
    <#
    .SYNOPSIS
        Gets detailed disk and volume information
    .DESCRIPTION
        Retrieves comprehensive disk, volume, and partition information
        with support for health monitoring and performance metrics.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        
        [switch]$IncludePerformance,
        
        [switch]$CheckHealth
    )
    
    begin {
        $results = [System.Collections.Generic.List[PSObject]]::new()
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    }
    
    process {
        foreach ($computer in $ComputerName) {
            try {
                Write-Progress -Activity 'Collecting Disk Information' -Status $computer -PercentComplete 0
                
                $disks = Get-Disk -CimSession $computer -ErrorAction Stop
                $diskInfo = [PSCustomObject]@{
                    ComputerName = $computer
                    Status = 'Online'
                    LastUpdated = [DateTime]::Now
                    Disks = @()
                    Volumes = @()
                    StoragePools = @()
                }
                
                # Process each disk
                foreach ($disk in $disks) {
                    $partitions = $disk | Get-Partition -ErrorAction SilentlyContinue
                    $volumes = $partitions | Get-Volume -ErrorAction SilentlyContinue
                    
                    $diskDetails = [PSCustomObject]@{
                        Number = $disk.Number
                        FriendlyName = $disk.FriendlyName
                        Model = $disk.Model
                        SerialNumber = $disk.SerialNumber
                        SizeGB = [math]::Round(($disk.Size / 1GB), 2)
                        PartitionStyle = $disk.PartitionStyle
                        HealthStatus = $disk.HealthStatus
                        OperationalStatus = $disk.OperationalStatus -join ', '
                        BusType = $disk.BusType
                        IsSystem = $disk.IsSystem
                        IsBoot = $disk.IsBoot
                        IsReadOnly = $disk.IsReadOnly
                        PartitionCount = $partitions.Count
                        VolumeCount = $volumes.Count
                    }
                    
                    # Add SMART data if available
                    if ($CheckHealth) {
                        $smartData = Get-DiskSMARTData -DiskNumber $disk.Number -ErrorAction SilentlyContinue
                        $diskDetails | Add-Member -NotePropertyName 'SMART' -NotePropertyValue $smartData
                    }
                    
                    $diskInfo.Disks += $diskDetails
                    
                    # Process volumes on this disk
                    foreach ($volume in $volumes) {
                        $partition = $partitions | Where-Object { $_.VolumeId -eq $volume.ObjectId } | Select-Object -First 1
                        $sizeGB = [math]::Round(($volume.Size / 1GB), 2)
                        $freeGB = [math]::Round(($volume.SizeRemaining / 1GB), 2)
                        $usedGB = $sizeGB - $freeGB
                        $usagePercent = if ($sizeGB -gt 0) { [math]::Round(($usedGB / $sizeGB) * 100, 2) } else { 0 }
                        
                        $volumeInfo = [PSCustomObject]@{
                            DriveLetter = $volume.DriveLetter
                            FileSystemLabel = $volume.FileSystemLabel
                            FileSystem = $volume.FileSystem
                            SizeGB = $sizeGB
                            UsedGB = $usedGB
                            FreeGB = $freeGB
                            UsagePercent = $usagePercent
                            HealthStatus = $volume.HealthStatus
                            OperationalStatus = $volume.OperationalStatus -join ', '
                            PartitionStyle = $partition.PartitionStyle
                            PartitionNumber = $partition.PartitionNumber
                            DiskNumber = $disk.Number
                        }
                        
                        # Add performance data if requested
                        if ($IncludePerformance) {
                            $perfData = Get-VolumePerformance -DriveLetter $volume.DriveLetter -ErrorAction SilentlyContinue
                            $volumeInfo | Add-Member -NotePropertyName 'Performance' -NotePropertyValue $perfData
                        }
                        
                        $diskInfo.Volumes += $volumeInfo
                    }
                }
                
                # Get storage pools if available
                if (Get-Command -Name Get-StoragePool -ErrorAction SilentlyContinue) {
                    $storagePools = Get-StoragePool -IsPrimordial $false -CimSession $computer -ErrorAction SilentlyContinue | 
                        ForEach-Object {
                            [PSCustomObject]@{
                                FriendlyName = $_.FriendlyName
                                HealthStatus = $_.HealthStatus
                                OperationalStatus = $_.OperationalStatus -join ', '
                                SizeGB = [math]::Round(($_.Size / 1GB), 2)
                                AllocatedSizeGB = [math]::Round(($_.AllocatedSize / 1GB), 2)
                                NumberOfDisks = $_.NumberOfDisks
                            }
                        }
                    
                    $diskInfo.StoragePools = $storagePools
                }
                
                $results.Add($diskInfo)
                Write-Progress -Activity 'Collecting Disk Information' -Status "Completed: $computer" -PercentComplete 100
            }
            catch {
                Write-Error "Failed to get disk information for $computer : $_"
                $results.Add([PSCustomObject]@{
                    ComputerName = $computer
                    Status = 'Error'
                    Error = $_.Exception.Message
                    LastUpdated = [DateTime]::Now
                })
            }
        }
    }
    
    end {
        $stopwatch.Stop()
        Write-Verbose "Disk information collected in $($stopwatch.Elapsed.TotalSeconds) seconds"
        return $results
    }
}

#region Helper Functions
function Get-DiskSMARTData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$DiskNumber
    )
    
    try {
        # Try to get SMART data using WMI
        $smartData = Get-CimInstance -Namespace 'root\wmi' -ClassName 'MSStorageDriver_FailurePredictData' `
            -Filter "InstanceName like '%$DiskNumber%'" -ErrorAction Stop | 
            Select-Object -ExpandProperty VendorSpecific
        
        if ($smartData) {
            # Parse SMART attributes
            $attributes = @()
            for ($i = 0; $i -lt $smartData.Length; $i += 12) {
                $attributeId = $smartData[$i + 0]
                if ($attributeId -eq 0) { continue }
                
                $attributes += [PSCustomObject]@{
                    ID = $attributeId
                    Name = (Get-SMARTAttributeName -Id $attributeId)
                    Current = $smartData[$i + 3]
                    Worst = $smartData[$i + 4]
                    Threshold = $smartData[$i + 5]
                    RawValue = [BitConverter]::ToUInt64($smartData, $i + 6)
                    IsOK = ($smartData[$i + 3] -ge $smartData[$i + 5])
                }
            }
            
            return [PSCustomObject]@{
                Status = 'OK'
                Attributes = $attributes
                LastUpdated = [DateTime]::Now
            }
        }
    }
    catch {
        Write-Verbose "Failed to get SMART data: $_"
    }
    
    return [PSCustomObject]@{
        Status = 'Not Available'
        Message = 'SMART data could not be retrieved'
    }
}

function Get-VolumePerformance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [char]$DriveLetter
    )
    
    try {
        $counter = Get-Counter -Counter "\\$env:COMPUTERNAME\PhysicalDisk($DriveLetter:)\\Disk Transfers/sec" -ErrorAction Stop
        
        return [PSCustomObject]@{
            DiskTransfersPerSec = $counter.CounterSamples[0].CookedValue
            Timestamp = $counter.Timestamp
        }
    }
    catch {
        Write-Verbose "Failed to get performance data for drive $DriveLetter : $_"
        return $null
    }
}

function Get-SMARTAttributeName {
    param([int]$Id)
    
    $smartAttributes = @{
        1 = 'Read Error Rate'
        2 = 'Throughput Performance'
        3 = 'Spin-Up Time'
        4 = 'Start/Stop Count'
        5 = 'Reallocated Sectors Count'
        7 = 'Seek Error Rate'
        9 = 'Power-On Hours'
        10 = 'Spin Retry Count'
        12 = 'Power Cycle Count'
        187 = 'Reported Uncorrectable Errors'
        188 = 'Command Timeout'
        190 = 'Temperature'
        194 = 'Temperature'
        197 = 'Current Pending Sector Count'
        198 = 'Uncorrectable Sector Count'
        199 = 'UDMA CRC Error Count'
        200 = 'Write Error Rate'
    }
    
    return $smartAttributes[$Id] ?? "Unknown ($Id)"
}
#endregion

# Export public functions
export-modulemember -Function Get-SystemInfo, Get-NetworkInfo, Get-DiskInfo

# Module cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Verbose "Cleaning up $script:ModuleName module..."
    # Clean up any temporary files, variables, or sessions
    Remove-Variable -Name ModuleConfig -Scope Script -ErrorAction SilentlyContinue
    Get-PSSession | Where-Object { $_.Name -like "$script:ModuleName-*" } | Remove-PSSession -ErrorAction SilentlyContinue
}
