# SystemInfo.psm1 - PowerShell module for system information utilities
# Requires -Version 5.1
#Requires -RunAsAdministrator

# Set strict mode for better coding practices
Set-StrictMode -Version Latest

# Define module variables
$script:ModuleName = 'SystemInfo'
$script:ModuleVersion = '1.0.0'

function Get-SystemInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [switch]$IncludeDisks,
        [switch]$IncludeNetworkAdapters
    )
    
    try {
        Write-Verbose "[$($script:ModuleName)] Getting system information..."
        
        # Get basic system information
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        $cpu = Get-CimInstance -ClassName Win32_Processor -ErrorAction Stop | Select-Object -First 1
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
        $memory = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        
        $systemInfo = [PSCustomObject]@{
            ComputerName = $env:COMPUTERNAME
            OS = $os.Caption
            OSVersion = $os.Version
            OSArchitecture = $os.OSArchitecture
            LastBootTime = $os.LastBootUpTime
            Manufacturer = $memory.Manufacturer
            Model = $memory.Model
            CPU = $cpu.Name.Trim()
            CPUManufacturer = $cpu.Manufacturer
            CPUCores = $cpu.NumberOfCores
            CPUThreads = $cpu.NumberOfLogicalProcessors
            CPUMaxClockSpeed = "$($cpu.MaxClockSpeed) MHz"
            BIOSManufacturer = $bios.Manufacturer
            BIOSVersion = $bios.Version
            TotalPhysicalMemory = "{0:N2} GB" -f ($memory.TotalPhysicalMemory / 1GB)
        }
        
        # Add disk information if requested
        if ($IncludeDisks) {
            $disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue | ForEach-Object {
                [PSCustomObject]@{
                    DeviceID = $_.DeviceID
                    Size = "{0:N2} GB" -f ($_.Size / 1GB)
                    FreeSpace = "{0:N2} GB" -f ($_.FreeSpace / 1GB)
                    UsedSpace = "{0:N2} GB" -f (($_.Size - $_.FreeSpace) / 1GB)
                    FreePercent = "{0:P0}" -f ($_.FreeSpace / $_.Size)
                }
            }
            $systemInfo | Add-Member -MemberType NoteProperty -Name 'Disks' -Value $disks
        }
        
        # Add network adapter information if requested
        if ($IncludeNetworkAdapters) {
            $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | ForEach-Object {
                $ipConfig = Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
                [PSCustomObject]@{
                    Name = $_.Name
                    InterfaceDescription = $_.InterfaceDescription
                    Status = $_.Status
                    MacAddress = $_.MacAddress
                    LinkSpeed = "{0} Mbps" -f ($_.LinkSpeed -replace '\D+')
                    IPv4Address = $ipConfig.IPAddress
                    IPv4Subnet = $ipConfig.PrefixLength
                }
            }
            $systemInfo | Add-Member -MemberType NoteProperty -Name 'NetworkAdapters' -Value $adapters
        }
        
        return $systemInfo
    }
    catch {
        Write-Error "[$($script:ModuleName)] Failed to get system information: $_"
        throw $_.Exception
    }
}

function Get-ProcessInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [string]$Name,
        [int]$Top = 10,
        [switch]$Detailed
    )
    
    try {
        Write-Verbose "[$($script:ModuleName)] Getting process information..."
        
        $processParams = @{
            ErrorAction = 'Stop'
        }
        
        if ($Name) {
            $processParams['Name'] = $Name
        }
        
        $processes = Get-Process @processParams | 
            Sort-Object -Property CPU -Descending | 
            Select-Object -First $Top
        
        if (-not $processes) {
            Write-Warning "No processes found matching the specified criteria"
            return $null
        }
        
        $result = foreach ($process in $processes) {
            $processInfo = [PSCustomObject]@{
                Name = $process.ProcessName
                ID = $process.Id
                CPU = "{0:N2} %" -f $process.CPU
                Memory = "{0:N2} MB" -f ($process.WorkingSet64 / 1MB)
                Handles = $process.Handles
                StartTime = $process.StartTime
            }
            
            if ($Detailed) {
                try {
                    $owner = $process.GetOwner()
                    $processInfo | Add-Member -MemberType NoteProperty -Name 'UserName' -Value "$($owner.Domain)\$($owner.UserName)"
                    $processInfo | Add-Member -MemberType NoteProperty -Name 'CommandLine' -Value (Get-CimInstance -ClassName Win32_Process -Filter "ProcessId = $($process.Id)" -ErrorAction SilentlyContinue).CommandLine
                }
                catch {
                    # Silently continue if we can't get detailed info
                }
            }
            
            $processInfo
        }
        
        return $result
    }
    catch {
        Write-Error "[$($script:ModuleName)] Failed to get process information: $_"
        throw $_.Exception
    }
}

function Get-NetworkInfo {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [switch]$IncludeConnections,
        [switch]$IncludeAdapters
    )
    
    try {
        Write-Verbose "[$($script:ModuleName)] Getting network information..."
        
        $networkInfo = [PSCustomObject]@{
            HostName = [System.Net.Dns]::GetHostName()
            Domain = (Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop).Domain
            IPv4Addresses = @()
            IPv6Addresses = @()
            DNS = @()
            Gateways = @()
        }
        
        # Get IP configuration
        $ipConfig = Get-NetIPConfiguration -Detailed -ErrorAction Stop
        
        foreach ($ip in $ipConfig) {
            # IPv4 Addresses
            if ($ip.IPv4Address.IPAddress) {
                $networkInfo.IPv4Addresses += [PSCustomObject]@{
                    InterfaceAlias = $ip.InterfaceAlias
                    IPAddress = $ip.IPv4Address.IPAddress
                    SubnetMask = $ip.IPv4Address.PrefixLength
                    InterfaceIndex = $ip.InterfaceIndex
                }
            }
            
            # IPv6 Addresses
            if ($ip.IPv6Address.IPAddress) {
                $networkInfo.IPv6Addresses += [PSCustomObject]@{
                    InterfaceAlias = $ip.InterfaceAlias
                    IPAddress = $ip.IPv6Address.IPAddress
                    PrefixLength = $ip.IPv6Address.PrefixLength
                    InterfaceIndex = $ip.InterfaceIndex
                }
            }
            
            # DNS Servers
            if ($ip.DNSServer.ServerAddresses) {
                $networkInfo.DNS += $ip.DNSServer.ServerAddresses | Select-Object -Unique
            }
            
            # Gateways
            if ($ip.IPv4DefaultGateway) {
                $networkInfo.Gateways += $ip.IPv4DefaultGateway.NextHop | Select-Object -Unique
            }
        }
        
        # Get active TCP connections if requested
        if ($IncludeConnections) {
            $connections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue | ForEach-Object {
                [PSCustomObject]@{
                    LocalAddress = $_.LocalAddress
                    LocalPort = $_.LocalPort
                    RemoteAddress = $_.RemoteAddress
                    RemotePort = $_.RemotePort
                    State = $_.State
                    OwningProcess = (Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue).ProcessName
                }
            }
            $networkInfo | Add-Member -MemberType NoteProperty -Name 'ActiveConnections' -Value $connections
        }
        
        # Get network adapter details if requested
        if ($IncludeAdapters) {
            $adapters = Get-NetAdapter -Physical -ErrorAction SilentlyContinue | ForEach-Object {
                $adapter = $_
                $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
                
                [PSCustomObject]@{
                    Name = $adapter.Name
                    InterfaceDescription = $adapter.InterfaceDescription
                    Status = $adapter.Status
                    MacAddress = $adapter.MacAddress
                    LinkSpeed = $adapter.LinkSpeed
                    IPv4Address = ($ipConfig | Where-Object { $_.AddressFamily -eq 'IPv4' }).IPAddress -join ', '
                    IPv6Address = ($ipConfig | Where-Object { $_.AddressFamily -eq 'IPv6' -and -not $_.IPAddress.StartsWith('fe80::') }).IPAddress -join ', '
                    DNS = (Get-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue).ServerAddresses -join ', '
                }
            }
            $networkInfo | Add-Member -MemberType NoteProperty -Name 'NetworkAdapters' -Value $adapters
        }
        
        return $networkInfo
    }
    catch {
        Write-Error "[$($script:ModuleName)] Failed to get network information: $_"
        throw $_.Exception
    }
}

# Export the module members to be available when the module is imported
Export-ModuleMember -Function Get-SystemInfo, Get-ProcessInfo, Get-NetworkInfo
