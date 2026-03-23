<#
.SYNOPSIS
    WinPE PowerBuilder - Network Configuration Module
    Advanced network setup and configuration for WinPE environments

.DESCRIPTION
    This module provides comprehensive network configuration capabilities including:
    - Network adapter configuration
    - Static IP and DHCP setup
    - DNS and WINS configuration
    - Network driver injection
    - Network share mounting
    - PXE boot configuration
    - Network troubleshooting and diagnostics

.NOTES
    Module: Network-Configuration
    Version: 1.0.0
    Author: Better11 Development Team
    Requires: PowerShell 5.1+, Windows ADK, WinPE environment
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

#region Module Variables

$script:ModuleRoot = $PSScriptRoot
$script:LogPath = Join-Path $env:TEMP "WinPE-NetworkConfiguration.log"
$script:NetworkConfigPath = Join-Path $ModuleRoot "NetworkConfigs"
$script:DriverCachePath = Join-Path $ModuleRoot "DriverCache"

# Ensure required paths exist
@($NetworkConfigPath, $DriverCachePath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -Path $_ -ItemType Directory -Force | Out-Null
    }
}

#endregion

#region Logging Functions

function Write-NetLog {
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

#region Network Adapter Configuration

function Get-WinPENetworkAdapters {
    <#
    .SYNOPSIS
        Retrieves all network adapters in WinPE environment
    
    .DESCRIPTION
        Gets detailed information about all network adapters including
        status, MAC address, driver information, and configuration
    
    .EXAMPLE
        Get-WinPENetworkAdapters
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-NetLog "Retrieving network adapters" -Level Info
        
        $adapters = Get-NetAdapter -ErrorAction SilentlyContinue
        
        if ($null -eq $adapters) {
            Write-NetLog "No network adapters found" -Level Warning
            return @()
        }
        
        $adapterInfo = @()
        
        foreach ($adapter in $adapters) {
            $config = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
            $ipv4 = Get-NetIPAddress -InterfaceIndex $adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            
            $info = [PSCustomObject]@{
                Name = $adapter.Name
                InterfaceDescription = $adapter.InterfaceDescription
                Status = $adapter.Status
                MacAddress = $adapter.MacAddress
                LinkSpeed = $adapter.LinkSpeed
                InterfaceIndex = $adapter.ifIndex
                IPAddress = if ($ipv4) { $ipv4.IPAddress } else { "Not configured" }
                SubnetMask = if ($ipv4) { $ipv4.PrefixLength } else { $null }
                DefaultGateway = if ($config.IPv4DefaultGateway) { $config.IPv4DefaultGateway.NextHop } else { "Not configured" }
                DNSServers = if ($config.DNSServer) { $config.DNSServer.ServerAddresses -join ', ' } else { "Not configured" }
                DHCPEnabled = $adapter.Dhcp
                DriverVersion = $adapter.DriverVersion
                DriverDate = $adapter.DriverDate
                DriverProvider = $adapter.DriverProvider
            }
            
            $adapterInfo += $info
        }
        
        Write-NetLog "Found $($adapterInfo.Count) network adapter(s)" -Level Success
        return $adapterInfo
    }
    catch {
        Write-NetLog "Failed to retrieve network adapters: $_" -Level Error
        throw
    }
}

function Set-WinPEStaticIP {
    <#
    .SYNOPSIS
        Configures static IP address for a network adapter
    
    .DESCRIPTION
        Sets static IP configuration including IP address, subnet mask,
        default gateway, and DNS servers
    
    .EXAMPLE
        Set-WinPEStaticIP -InterfaceIndex 12 -IPAddress "192.168.1.100" -SubnetMask 24 -Gateway "192.168.1.1" -DNSServers @("8.8.8.8","8.8.4.4")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$InterfaceIndex,
        
        [Parameter(Mandatory)]
        [string]$IPAddress,
        
        [Parameter(Mandatory)]
        [int]$SubnetMask,
        
        [Parameter()]
        [string]$Gateway,
        
        [Parameter()]
        [string[]]$DNSServers = @("8.8.8.8", "8.8.4.4"),
        
        [Parameter()]
        [switch]$SkipGateway
    )
    
    try {
        Write-NetLog "Configuring static IP on interface $InterfaceIndex" -Level Info
        
        # Remove existing IP configuration
        Remove-NetIPAddress -InterfaceIndex $InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceIndex $InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
        
        # Set static IP address
        New-NetIPAddress -InterfaceIndex $InterfaceIndex `
                        -IPAddress $IPAddress `
                        -PrefixLength $SubnetMask `
                        -DefaultGateway $(if ($Gateway -and -not $SkipGateway) { $Gateway } else { $null }) `
                        -ErrorAction Stop | Out-Null
        
        Write-NetLog "IP address set: $IPAddress/$SubnetMask" -Level Info
        
        # Set DNS servers
        if ($DNSServers.Count -gt 0) {
            Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses $DNSServers -ErrorAction Stop
            Write-NetLog "DNS servers configured: $($DNSServers -join ', ')" -Level Info
        }
        
        # Verify configuration
        Start-Sleep -Seconds 2
        $config = Get-NetIPConfiguration -InterfaceIndex $InterfaceIndex -ErrorAction SilentlyContinue
        
        if ($config) {
            Write-NetLog "Static IP configuration completed successfully" -Level Success
            return $config
        } else {
            throw "Failed to verify IP configuration"
        }
    }
    catch {
        Write-NetLog "Failed to configure static IP: $_" -Level Error
        throw
    }
}

function Enable-WinPEDHCP {
    <#
    .SYNOPSIS
        Enables DHCP on a network adapter
    
    .DESCRIPTION
        Configures the network adapter to obtain IP address automatically via DHCP
    
    .EXAMPLE
        Enable-WinPEDHCP -InterfaceIndex 12
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$InterfaceIndex,
        
        [Parameter()]
        [int]$Timeout = 30
    )
    
    try {
        Write-NetLog "Enabling DHCP on interface $InterfaceIndex" -Level Info
        
        # Remove static IP configuration
        Remove-NetIPAddress -InterfaceIndex $InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
        Remove-NetRoute -InterfaceIndex $InterfaceIndex -Confirm:$false -ErrorAction SilentlyContinue
        
        # Enable DHCP
        Set-NetIPInterface -InterfaceIndex $InterfaceIndex -Dhcp Enabled -ErrorAction Stop
        
        # Set DNS to automatic
        Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ResetServerAddresses -ErrorAction SilentlyContinue
        
        Write-NetLog "DHCP enabled, waiting for IP address..." -Level Info
        
        # Wait for DHCP lease
        $waitStart = Get-Date
        $configured = $false
        
        while (((Get-Date) - $waitStart).TotalSeconds -lt $Timeout -and -not $configured) {
            Start-Sleep -Seconds 2
            
            $ipAddress = Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            
            if ($ipAddress -and $ipAddress.IPAddress -ne "0.0.0.0") {
                $configured = $true
                Write-NetLog "DHCP lease obtained: $($ipAddress.IPAddress)" -Level Success
            }
        }
        
        if (-not $configured) {
            Write-NetLog "DHCP configuration timed out after $Timeout seconds" -Level Warning
        }
        
        return $configured
    }
    catch {
        Write-NetLog "Failed to enable DHCP: $_" -Level Error
        throw
    }
}

function Reset-WinPENetworkAdapter {
    <#
    .SYNOPSIS
        Resets a network adapter to default state
    
    .DESCRIPTION
        Disables and re-enables the network adapter, clearing all configuration
    
    .EXAMPLE
        Reset-WinPENetworkAdapter -InterfaceIndex 12
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$InterfaceIndex
    )
    
    try {
        Write-NetLog "Resetting network adapter $InterfaceIndex" -Level Info
        
        # Disable adapter
        Disable-NetAdapter -InterfaceIndex $InterfaceIndex -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 2
        
        # Enable adapter
        Enable-NetAdapter -InterfaceIndex $InterfaceIndex -Confirm:$false -ErrorAction Stop
        Start-Sleep -Seconds 3
        
        Write-NetLog "Network adapter reset successfully" -Level Success
    }
    catch {
        Write-NetLog "Failed to reset network adapter: $_" -Level Error
        throw
    }
}

#endregion

#region Network Driver Management

function Add-WinPENetworkDriver {
    <#
    .SYNOPSIS
        Adds network drivers to WinPE image
    
    .DESCRIPTION
        Injects network drivers into mounted WinPE image for hardware support
    
    .EXAMPLE
        Add-WinPENetworkDriver -MountPath "C:\Mount\WinPE" -DriverPath "C:\Drivers\Network"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter(Mandatory)]
        [string]$DriverPath,
        
        [Parameter()]
        [switch]$Recurse
    )
    
    try {
        Write-NetLog "Adding network drivers to WinPE" -Level Info
        
        if (-not (Test-Path $MountPath)) {
            throw "Mount path not found: $MountPath"
        }
        
        if (-not (Test-Path $DriverPath)) {
            throw "Driver path not found: $DriverPath"
        }
        
        $addDriverParams = @{
            Path = $MountPath
            Driver = $DriverPath
            ForceUnsigned = $true
        }
        
        if ($Recurse) {
            $addDriverParams.Recurse = $true
        }
        
        Add-WindowsDriver @addDriverParams -ErrorAction Stop | Out-Null
        
        Write-NetLog "Network drivers added successfully" -Level Success
    }
    catch {
        Write-NetLog "Failed to add network drivers: $_" -Level Error
        throw
    }
}

function Get-WinPENetworkDrivers {
    <#
    .SYNOPSIS
        Lists network drivers in WinPE image
    
    .DESCRIPTION
        Retrieves information about installed network drivers in mounted WinPE image
    
    .EXAMPLE
        Get-WinPENetworkDrivers -MountPath "C:\Mount\WinPE"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath
    )
    
    try {
        Write-NetLog "Retrieving network drivers from WinPE" -Level Info
        
        if (-not (Test-Path $MountPath)) {
            throw "Mount path not found: $MountPath"
        }
        
        $drivers = Get-WindowsDriver -Path $MountPath -ErrorAction Stop
        
        # Filter for network drivers
        $networkDrivers = $drivers | Where-Object {
            $_.ClassName -eq 'Net' -or 
            $_.ClassName -eq 'NetService' -or
            $_.ClassName -eq 'NetTrans'
        }
        
        Write-NetLog "Found $($networkDrivers.Count) network driver(s)" -Level Success
        return $networkDrivers
    }
    catch {
        Write-NetLog "Failed to retrieve network drivers: $_" -Level Error
        throw
    }
}

function Export-NetworkDriverPackage {
    <#
    .SYNOPSIS
        Exports network drivers from current system
    
    .DESCRIPTION
        Exports all network drivers from the current system to a folder for WinPE injection
    
    .EXAMPLE
        Export-NetworkDriverPackage -OutputPath "C:\Drivers\Network"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    try {
        Write-NetLog "Exporting network drivers from current system" -Level Info
        
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
        }
        
        # Get all network adapters
        $adapters = Get-NetAdapter -ErrorAction Stop
        
        $exportedCount = 0
        
        foreach ($adapter in $adapters) {
            try {
                # Get PnP device
                $pnpDevice = Get-PnpDevice | Where-Object { 
                    $_.FriendlyName -eq $adapter.InterfaceDescription 
                }
                
                if ($pnpDevice) {
                    # Export driver using DISM
                    $driverPath = Join-Path $OutputPath $adapter.Name
                    
                    if (-not (Test-Path $driverPath)) {
                        New-Item -Path $driverPath -ItemType Directory -Force | Out-Null
                    }
                    
                    Export-WindowsDriver -Online -Destination $driverPath -ErrorAction SilentlyContinue
                    
                    $exportedCount++
                    Write-NetLog "Exported driver for: $($adapter.InterfaceDescription)" -Level Info
                }
            }
            catch {
                Write-NetLog "Failed to export driver for $($adapter.InterfaceDescription): $_" -Level Warning
            }
        }
        
        Write-NetLog "Exported $exportedCount network driver package(s)" -Level Success
        return $exportedCount
    }
    catch {
        Write-NetLog "Failed to export network drivers: $_" -Level Error
        throw
    }
}

#endregion

#region Network Share Management

function Mount-WinPENetworkShare {
    <#
    .SYNOPSIS
        Mounts a network share in WinPE
    
    .DESCRIPTION
        Connects to a network share and maps it to a drive letter in WinPE environment
    
    .EXAMPLE
        Mount-WinPENetworkShare -SharePath "\\server\share" -DriveLetter "Z" -Credential (Get-Credential)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SharePath,
        
        [Parameter()]
        [string]$DriveLetter,
        
        [Parameter()]
        [PSCredential]$Credential,
        
        [Parameter()]
        [switch]$Persistent
    )
    
    try {
        Write-NetLog "Mounting network share: $SharePath" -Level Info
        
        $netUseParams = @{
            RemotePath = $SharePath
            Persistent = $Persistent.IsPresent
        }
        
        if ($DriveLetter) {
            $netUseParams.LocalPath = "${DriveLetter}:"
        }
        
        if ($Credential) {
            $username = $Credential.UserName
            $password = $Credential.GetNetworkCredential().Password
            
            $netCmd = "net use"
            if ($DriveLetter) { $netCmd += " ${DriveLetter}:" }
            $netCmd += " $SharePath /user:$username $password"
            if ($Persistent) { $netCmd += " /persistent:yes" }
            
            $result = Invoke-Expression $netCmd 2>&1
            
            if ($LASTEXITCODE -ne 0) {
                throw "Failed to mount share: $result"
            }
        } else {
            New-PSDrive @netUseParams -PSProvider FileSystem -ErrorAction Stop | Out-Null
        }
        
        Write-NetLog "Network share mounted successfully" -Level Success
        
        if ($DriveLetter) {
            Write-NetLog "Mapped to drive: ${DriveLetter}:" -Level Info
        }
    }
    catch {
        Write-NetLog "Failed to mount network share: $_" -Level Error
        throw
    }
}

function Dismount-WinPENetworkShare {
    <#
    .SYNOPSIS
        Dismounts a network share
    
    .DESCRIPTION
        Disconnects from a mapped network share
    
    .EXAMPLE
        Dismount-WinPENetworkShare -DriveLetter "Z"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DriveLetter
    )
    
    try {
        Write-NetLog "Dismounting network share: ${DriveLetter}:" -Level Info
        
        net use "${DriveLetter}:" /delete /yes | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-NetLog "Network share dismounted successfully" -Level Success
        } else {
            throw "Failed to dismount share"
        }
    }
    catch {
        Write-NetLog "Failed to dismount network share: $_" -Level Error
        throw
    }
}

function Get-WinPENetworkShares {
    <#
    .SYNOPSIS
        Lists all mounted network shares
    
    .DESCRIPTION
        Retrieves information about all currently mounted network shares
    
    .EXAMPLE
        Get-WinPENetworkShares
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-NetLog "Retrieving mounted network shares" -Level Info
        
        $shares = net use | Select-String -Pattern "^\w+\s+\w:" | ForEach-Object {
            $parts = $_.Line -split '\s+' | Where-Object { $_ }
            
            [PSCustomObject]@{
                Status = $parts[0]
                Local = $parts[1]
                Remote = $parts[2]
                Network = if ($parts.Count -gt 3) { $parts[3] } else { "N/A" }
            }
        }
        
        Write-NetLog "Found $($shares.Count) network share(s)" -Level Success
        return $shares
    }
    catch {
        Write-NetLog "Failed to retrieve network shares: $_" -Level Error
        throw
    }
}

#endregion

#region Network Diagnostics

function Test-WinPENetworkConnectivity {
    <#
    .SYNOPSIS
        Tests network connectivity in WinPE
    
    .DESCRIPTION
        Performs comprehensive network connectivity tests including ping, DNS, and gateway tests
    
    .EXAMPLE
        Test-WinPENetworkConnectivity -TestInternet
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$TestHost = "8.8.8.8",
        
        [Parameter()]
        [switch]$TestInternet,
        
        [Parameter()]
        [switch]$TestDNS,
        
        [Parameter()]
        [switch]$Detailed
    )
    
    try {
        Write-NetLog "Testing network connectivity" -Level Info
        
        $results = [PSCustomObject]@{
            Timestamp = Get-Date
            Adapters = @()
            PingTest = $null
            DNSTest = $null
            InternetTest = $null
            Gateway Test = $null
            OverallStatus = "Unknown"
        }
        
        # Test each adapter
        $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        
        foreach ($adapter in $adapters) {
            $config = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
            
            $adapterResult = [PSCustomObject]@{
                Name = $adapter.Name
                Status = $adapter.Status
                IPAddress = if ($config.IPv4Address) { $config.IPv4Address.IPAddress } else { "None" }
                Gateway = if ($config.IPv4DefaultGateway) { $config.IPv4DefaultGateway.NextHop } else { "None" }
                DNS = if ($config.DNSServer) { $config.DNSServer.ServerAddresses -join ', ' } else { "None" }
                LinkSpeed = $adapter.LinkSpeed
            }
            
            $results.Adapters += $adapterResult
        }
        
        # Ping test
        $pingResult = Test-Connection -ComputerName $TestHost -Count 4 -ErrorAction SilentlyContinue
        
        if ($pingResult) {
            $avgLatency = ($pingResult | Measure-Object -Property ResponseTime -Average).Average
            $results.PingTest = [PSCustomObject]@{
                Target = $TestHost
                Success = $true
                AverageLatency = $avgLatency
                PacketLoss = 0
            }
            Write-NetLog "Ping test successful - Average latency: $([Math]::Round($avgLatency, 2))ms" -Level Success
        } else {
            $results.PingTest = [PSCustomObject]@{
                Target = $TestHost
                Success = $false
                Error = "Ping failed"
            }
            Write-NetLog "Ping test failed" -Level Error
        }
        
        # DNS test
        if ($TestDNS) {
            try {
                $dnsResult = Resolve-DnsName -Name "www.microsoft.com" -ErrorAction Stop
                $results.DNSTest = [PSCustomObject]@{
                    Success = $true
                    ResolvedIP = $dnsResult[0].IPAddress
                }
                Write-NetLog "DNS resolution successful" -Level Success
            }
            catch {
                $results.DNSTest = [PSCustomObject]@{
                    Success = $false
                    Error = $_.Exception.Message
                }
                Write-NetLog "DNS resolution failed: $_" -Level Error
            }
        }
        
        # Internet connectivity test
        if ($TestInternet) {
            try {
                $webRequest = Invoke-WebRequest -Uri "http://www.msftconnecttest.com/connecttest.txt" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
                $results.InternetTest = [PSCustomObject]@{
                    Success = $true
                    StatusCode = $webRequest.StatusCode
                }
                Write-NetLog "Internet connectivity confirmed" -Level Success
            }
            catch {
                $results.InternetTest = [PSCustomObject]@{
                    Success = $false
                    Error = $_.Exception.Message
                }
                Write-NetLog "Internet connectivity test failed: $_" -Level Warning
            }
        }
        
        # Determine overall status
        if ($results.PingTest.Success) {
            $results.OverallStatus = "Connected"
        } else {
            $results.OverallStatus = "Disconnected"
        }
        
        return $results
    }
    catch {
        Write-NetLog "Network connectivity test failed: $_" -Level Error
        throw
    }
}

function Get-WinPENetworkStatistics {
    <#
    .SYNOPSIS
        Retrieves network statistics for all adapters
    
    .DESCRIPTION
        Gets detailed statistics including bytes sent/received, errors, and packet counts
    
    .EXAMPLE
        Get-WinPENetworkStatistics
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-NetLog "Retrieving network statistics" -Level Info
        
        $adapters = Get-NetAdapter
        $statistics = @()
        
        foreach ($adapter in $adapters) {
            $stats = Get-NetAdapterStatistics -Name $adapter.Name -ErrorAction SilentlyContinue
            
            if ($stats) {
                $statistics += [PSCustomObject]@{
                    AdapterName = $adapter.Name
                    Status = $adapter.Status
                    BytesReceived = $stats.ReceivedBytes
                    BytesSent = $stats.SentBytes
                    ReceivedUnicastPackets = $stats.ReceivedUnicastPackets
                    SentUnicastPackets = $stats.SentUnicastPackets
                    ReceivedDiscards = $stats.ReceivedDiscardedPackets
                    OutboundDiscards = $stats.OutboundDiscardedPackets
                    ReceivedErrors = $stats.ReceivedPacketErrors
                    OutboundErrors = $stats.OutboundPacketErrors
                }
            }
        }
        
        Write-NetLog "Retrieved statistics for $($statistics.Count) adapter(s)" -Level Success
        return $statistics
    }
    catch {
        Write-NetLog "Failed to retrieve network statistics: $_" -Level Error
        throw
    }
}

function Test-WinPEPortConnectivity {
    <#
    .SYNOPSIS
        Tests connectivity to a specific port on a remote host
    
    .DESCRIPTION
        Attempts to establish a TCP connection to test port availability
    
    .EXAMPLE
        Test-WinPEPortConnectivity -ComputerName "server.domain.com" -Port 445
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ComputerName,
        
        [Parameter(Mandatory)]
        [int]$Port,
        
        [Parameter()]
        [int]$Timeout = 5000
    )
    
    try {
        Write-NetLog "Testing port connectivity: ${ComputerName}:${Port}" -Level Info
        
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connect = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)
        $wait = $connect.AsyncWaitHandle.WaitOne($Timeout, $false)
        
        if ($wait) {
            try {
                $tcpClient.EndConnect($connect)
                $tcpClient.Close()
                
                Write-NetLog "Port $Port is open on $ComputerName" -Level Success
                return $true
            }
            catch {
                Write-NetLog "Port $Port is closed on $ComputerName" -Level Warning
                return $false
            }
        } else {
            $tcpClient.Close()
            Write-NetLog "Connection to ${ComputerName}:${Port} timed out" -Level Warning
            return $false
        }
    }
    catch {
        Write-NetLog "Port connectivity test failed: $_" -Level Error
        return $false
    }
}

#endregion

#region PXE Boot Configuration

function Enable-WinPEPXEBoot {
    <#
    .SYNOPSIS
        Configures WinPE image for PXE boot
    
    .DESCRIPTION
        Adds necessary components and configuration for PXE network boot
    
    .EXAMPLE
        Enable-WinPEPXEBoot -MountPath "C:\Mount\WinPE" -TFTPRoot "C:\TFTP"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$MountPath,
        
        [Parameter()]
        [string]$TFTPRoot,
        
        [Parameter()]
        [string]$BootFileName = "boot.wim"
    )
    
    try {
        Write-NetLog "Configuring WinPE for PXE boot" -Level Info
        
        if (-not (Test-Path $MountPath)) {
            throw "Mount path not found: $MountPath"
        }
        
        # Add WinPE-WDS-Tools optional component
        $packagePath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment\amd64\WinPE_OCs"
        
        if (Test-Path $packagePath) {
            $wdsPackage = Join-Path $packagePath "WinPE-WDS-Tools.cab"
            
            if (Test-Path $wdsPackage) {
                Add-WindowsPackage -Path $MountPath -PackagePath $wdsPackage -ErrorAction Stop | Out-Null
                Write-NetLog "WDS Tools package added" -Level Info
            }
        }
        
        # Configure startnet.cmd for network boot
        $startnetPath = Join-Path $MountPath "Windows\System32\startnet.cmd"
        
        if (Test-Path $startnetPath) {
            $pxeStartnet = @"
@echo off
wpeinit
wpeutil InitializeNetwork
ipconfig /renew
net use Z: \\server\share /user:domain\user password
Z:\setup.exe
"@
            $pxeStartnet | Add-Content -Path $startnetPath
            Write-NetLog "Startnet.cmd configured for PXE" -Level Info
        }
        
        # Copy to TFTP root if specified
        if ($TFTPRoot -and (Test-Path $TFTPRoot)) {
            $bootWim = Join-Path $MountPath "sources\boot.wim"
            $tfBootWim = Join-Path $TFTPRoot $BootFileName
            
            if (Test-Path $bootWim) {
                Copy-Item -Path $bootWim -Destination $tfBootWim -Force
                Write-NetLog "Boot image copied to TFTP root" -Level Info
            }
        }
        
        Write-NetLog "PXE boot configuration completed" -Level Success
    }
    catch {
        Write-NetLog "Failed to configure PXE boot: $_" -Level Error
        throw
    }
}

#endregion

#region Configuration Management

function Export-WinPENetworkConfig {
    <#
    .SYNOPSIS
        Exports current network configuration to file
    
    .DESCRIPTION
        Saves current network adapter configuration to JSON file for reuse
    
    .EXAMPLE
        Export-WinPENetworkConfig -OutputPath "C:\Configs\network.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    try {
        Write-NetLog "Exporting network configuration" -Level Info
        
        $adapters = Get-WinPENetworkAdapters
        
        $config = @{
            ExportDate = (Get-Date).ToString('o')
            Adapters = $adapters
        }
        
        $config | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Force
        
        Write-NetLog "Network configuration exported to: $OutputPath" -Level Success
        return $OutputPath
    }
    catch {
        Write-NetLog "Failed to export network configuration: $_" -Level Error
        throw
    }
}

function Import-WinPENetworkConfig {
    <#
    .SYNOPSIS
        Imports and applies network configuration from file
    
    .DESCRIPTION
        Loads network configuration from JSON file and applies it to adapters
    
    .EXAMPLE
        Import-WinPENetworkConfig -ConfigPath "C:\Configs\network.json"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ConfigPath,
        
        [Parameter()]
        [switch]$Force
    )
    
    try {
        Write-NetLog "Importing network configuration from: $ConfigPath" -Level Info
        
        if (-not (Test-Path $ConfigPath)) {
            throw "Configuration file not found: $ConfigPath"
        }
        
        $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
        
        foreach ($adapterConfig in $config.Adapters) {
            $adapter = Get-NetAdapter | Where-Object { $_.MacAddress -eq $adapterConfig.MacAddress }
            
            if ($adapter) {
                Write-NetLog "Applying configuration to adapter: $($adapter.Name)" -Level Info
                
                if ($adapterConfig.DHCPEnabled) {
                    Enable-WinPEDHCP -InterfaceIndex $adapter.ifIndex
                } else {
                    $params = @{
                        InterfaceIndex = $adapter.ifIndex
                        IPAddress = $adapterConfig.IPAddress
                        SubnetMask = $adapterConfig.SubnetMask
                    }
                    
                    if ($adapterConfig.DefaultGateway -ne "Not configured") {
                        $params.Gateway = $adapterConfig.DefaultGateway
                    }
                    
                    if ($adapterConfig.DNSServers -ne "Not configured") {
                        $params.DNSServers = $adapterConfig.DNSServers -split ', '
                    }
                    
                    Set-WinPEStaticIP @params
                }
            } else {
                Write-NetLog "Adapter with MAC $($adapterConfig.MacAddress) not found" -Level Warning
            }
        }
        
        Write-NetLog "Network configuration imported successfully" -Level Success
    }
    catch {
        Write-NetLog "Failed to import network configuration: $_" -Level Error
        throw
    }
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    'Get-WinPENetworkAdapters',
    'Set-WinPEStaticIP',
    'Enable-WinPEDHCP',
    'Reset-WinPENetworkAdapter',
    'Add-WinPENetworkDriver',
    'Get-WinPENetworkDrivers',
    'Export-NetworkDriverPackage',
    'Mount-WinPENetworkShare',
    'Dismount-WinPENetworkShare',
    'Get-WinPENetworkShares',
    'Test-WinPENetworkConnectivity',
    'Get-WinPENetworkStatistics',
    'Test-WinPEPortConnectivity',
    'Enable-WinPEPXEBoot',
    'Export-WinPENetworkConfig',
    'Import-WinPENetworkConfig'
)

#endregion
