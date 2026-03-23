# Network Module - Performance Optimized
# Implements best practices for PowerShell module development

#region Module Initialization

# Check if running as admin
$script:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Helper function to check admin rights for specific functions with helpful messages
function Test-AdminRequirement {
    [CmdletBinding()]
    param(
        [string]$FunctionName,
        [string]$AdditionalInfo = $null
    )
    
    if (-not $script:IsAdmin) {
        $message = "The function '$FunctionName' requires administrator privileges."
        if ($AdditionalInfo) {
            $message += " $AdditionalInfo"
        } else {
            $message += " Please run PowerShell as Administrator and try again."
        }
        Write-Warning $message
        return $false
    }
    return $true
}

#endregion

#region Private Helper Functions

<#
.SYNOPSIS
    Tests TCP port connectivity asynchronously with timeout.
.DESCRIPTION
    Uses .NET's TcpClient for efficient, non-blocking port checking.
    Does not require admin privileges.
#>
function Test-TcpPort {
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory = $true)]
        [int]$Port,
        
        [Parameter()]
        [int]$Timeout = 1000
    )
    
    $tcpClient = $null
    try {
        $tcpClient = [System.Net.Sockets.TcpClient]::new()
        $connectTask = $tcpClient.ConnectAsync($ComputerName, $Port)
        
        # Use Task.Wait with timeout for better performance
        if (-not $connectTask.Wait($Timeout, [System.Threading.CancellationToken]::None)) {
            return $false
        }
        
        return $tcpClient.Connected
    }
    catch {
        return $false
    }
    finally {
        if ($null -ne $tcpClient) { 
            $tcpClient.Dispose() 
        }
    }
}

#endregion

#region Public Functions

<#
.SYNOPSIS
    Tests network connectivity to specified computers.
.DESCRIPTION
    Performs ping and optional TCP port tests against one or more computers.
    Returns detailed connection information including ping status, latency, and port availability.
    Does not require admin privileges for basic functionality.
.PARAMETER ComputerName
    Specifies the target computer(s). Accepts multiple values from the pipeline.
.PARAMETER Port
    Optional. Specifies the TCP port(s) to test.
.PARAMETER Timeout
    Specifies the timeout in milliseconds for each test. Default is 3000ms.
.PARAMETER ResolveHostname
    If specified, resolves and includes the IP address of the target computer.
.EXAMPLE
    Test-NetworkConnectivity -ComputerName 'example.com' -Port 80
    Tests connectivity to example.com on port 80.
.EXAMPLE
    'server1', 'server2' | Test-NetworkConnectivity -Port 443, 3389
    Tests connectivity to multiple servers on multiple ports.
#>
function Test-NetworkConnectivity {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true, 
                  ValueFromPipeline = $true,
                  ValueFromPipelineByPropertyName = $true,
                  Position = 0,
                  HelpMessage = 'The target computer name or IP address')]
        [ValidateNotNullOrEmpty()]
        [Alias('CN', 'Computer')]
        [string[]]$ComputerName,
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [ValidateRange(1, 65535)]
        [int[]]$Port,
        
        [Parameter()]
        [ValidateRange(100, 30000)]
        [int]$Timeout = 3000,
        
        [Parameter()]
        [switch]$ResolveHostname,
        
        [Parameter()]
        [switch]$AsJob
    )
    
    begin {
        $ping = [System.Net.NetworkInformation.Ping]::new()
        $computerCount = 0
        
        # Initialize progress tracking
        $totalComputers = if ($ComputerName) { $ComputerName.Count } else { 1 }
        $progressParams = @{
            Activity = 'Testing Network Connectivity'
            Status = 'Starting...'
            PercentComplete = 0
        }
    }
    
    process {
        foreach ($computer in $ComputerName) {
            $computerCount++
            $progressParams.Status = "Testing $computer ($computerCount of $totalComputers)"
            $progressParams.PercentComplete = ($computerCount / $totalComputers) * 100
            Write-Progress @progressParams
            
            $result = [PSCustomObject]@{
                ComputerName = $computer
                PingSuccess  = $false
                PingLatency  = $null
                PortOpen     = $null
                IPAddress    = $null
                Timestamp    = [DateTime]::UtcNow
            }
            
            try {
                # Resolve hostname if requested
                if ($ResolveHostname) {
                    try {
                        $ipAddress = [System.Net.Dns]::GetHostAddresses($computer) | 
                            Where-Object { $_.AddressFamily -eq 'InterNetwork' } | 
                            Select-Object -First 1 -ErrorAction Stop
                        if ($ipAddress) {
                            $result.IPAddress = $ipAddress.ToString()
                        }
                    }
                    catch [System.Net.Sockets.SocketException] {
                        Write-Verbose "Could not resolve hostname: $computer"
                    }
                }
                
                # Ping test with timeout
                $pingReply = $null
                try {
                    $pingReply = $ping.Send($computer, $Timeout)
                    if ($pingReply.Status -eq 'Success') {
                        $result.PingSuccess = $true
                        $result.PingLatency = $pingReply.RoundtripTime
                    }
                }
                catch {
                    Write-Debug "Ping failed for $computer : $_"
                }
                
                # Port test if specified
                if ($Port) {
                    $portResults = @{}
                    foreach ($p in $Port) {
                        $portResults[$p] = Test-TcpPort -ComputerName $computer -Port $p -Timeout $Timeout
                    }
                    $result.PortOpen = $portResults
                }
                
                $result
            }
            catch {
                Write-Error -Message "Error testing $computer : $_" -ErrorAction Continue
                $result
            }
        }
    }
    
    end {
        $ping.Dispose()
        Write-Progress -Activity 'Testing Network Connectivity' -Completed
    }
}

<#
.SYNOPSIS
    Performs a port scan on the specified computer.
.DESCRIPTION
    Scans one or more ports on a computer using runspace pools for concurrency.
    Does not require admin privileges unless scanning privileged ports (1-1024).
#>
function Start-PortScan {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$ComputerName,
        
        [Parameter(Position = 1)]
        [int[]]$Ports = @(21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 993, 995, 1723, 3306, 3389, 5900, 8080),
        
        [Parameter()]
        [int]$Timeout = 1000,
        
        [Parameter()]
        [int]$MaxThreads = 20
    )
    
    begin {
        # Check for privileged ports
        $privilegedPorts = $Ports | Where-Object { $_ -lt 1025 }
        if ($privilegedPorts -and -not $script:IsAdmin) {
            Write-Warning "Scanning privileged ports (1-1024) requires administrator privileges. These ports will be skipped."
            $Ports = $Ports | Where-Object { $_ -ge 1025 }
        }
        
        # Initialize runspace pool
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $MaxThreads)
        $runspacePool.Open()
        $runspaces = @()
    }
    
    process {
        foreach ($port in $Ports) {
            $scriptBlock = {
                param($ComputerName, $Port, $Timeout)
                
                $result = [PSCustomObject]@{
                    ComputerName = $ComputerName
                    Port = $Port
                    IsOpen = $false
                    Protocol = 'TCP'
                    Timestamp = [DateTime]::UtcNow
                }
                
                try {
                    $tcpClient = [System.Net.Sockets.TcpClient]::new()
                    $connectTask = $tcpClient.ConnectAsync($ComputerName, $Port)
                    
                    if ($connectTask.Wait($Timeout, [System.Threading.CancellationToken]::None)) {
                        $result.IsOpen = $tcpClient.Connected
                    }
                    
                    $tcpClient.Dispose()
                }
                catch {
                    # Port is likely closed or filtered
                }
                
                $result
            }
            
            $runspace = [powershell]::Create().AddScript($scriptBlock).AddArgument($ComputerName).AddArgument($port).AddArgument($Timeout)
            $runspace.RunspacePool = $runspacePool
            $runspaces += [PSCustomObject]@{
                Runspace = $runspace
                Handle = $runspace.BeginInvoke()
            }
        }
    }
    
    end {
        # Process results
        while ($runspaces.Handle.IsCompleted -contains $false) {
            Start-Sleep -Milliseconds 100
        }
        
        foreach ($runspace in $runspaces) {
            try {
                $runspace.Runspace.EndInvoke($runspace.Handle)
            }
            finally {
                $runspace.Runspace.Dispose()
            }
        }
        
        $runspacePool.Close()
        $runspacePool.Dispose()
    }
}

<#
.SYNOPSIS
    Retrieves network adapter information.
.DESCRIPTION
    Gets detailed information about network adapters on the local computer.
    Works without admin privileges but provides more details when run as admin.
#>
function Get-NetworkAdapter {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param (
        [Parameter()]
        [string]$Name = '*',
        
        [Parameter()]
        [switch]$PhysicalOnly,
        
        [Parameter()]
        [switch]$IncludeHidden
    )
    
    try {
        $adapters = Get-NetAdapter -Name $Name -IncludeHidden:$IncludeHidden -ErrorAction SilentlyContinue |
            Where-Object { -not $PhysicalOnly -or $_.MediaType -ne 'None' }
        
        foreach ($adapter in $adapters) {
            $ipAddresses = @()
            $dnsServers = @()
            $gateways = @()
            
            try {
                $ipConfig = Get-NetIPConfiguration -InterfaceIndex $adapter.ifIndex -ErrorAction SilentlyContinue
                if ($ipConfig) {
                    $ipAddresses = $ipConfig.IPv4Address.IPAddress
                    $dnsServers = $ipConfig.DNSServer | Where-Object { $_.AddressFamily -eq 2 } | Select-Object -ExpandProperty ServerAddresses
                    $gateways = $ipConfig.IPv4DefaultGateway.NextHop
                }
            }
            catch {
                Write-Debug "Could not get detailed IP configuration for $($adapter.Name): $_"
            }
            
            [PSCustomObject]@{
                Name = $adapter.Name
                InterfaceDescription = $adapter.InterfaceDescription
                Status = $adapter.Status
                MacAddress = $adapter.MacAddress
                LinkSpeed = if ($adapter.LinkSpeed) { $adapter.LinkSpeed.TrimEnd(' Mbps') } else { $null }
                IPAddresses = $ipAddresses
                DNSServers = $dnsServers
                Gateways = $gateways
                IsPhysical = $adapter.MediaType -ne 'None'
                IsVirtual = $adapter.MediaType -eq 'None'
                IsAdminEnabled = $adapter.Status -ne 'Disabled'
            }
        }
    }
    catch {
        Write-Error "Failed to get network adapter information: $_"
        throw $_
    }
}

<#
.SYNOPSIS
    Flushes the DNS resolver cache.
.DESCRIPTION
    Clears the DNS client resolver cache. Requires administrator privileges.
.EXAMPLE
    Clear-DnsClientCache -Confirm:$false
#>
function Clear-DnsClientCache {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([bool])]
    param()
    
    if (-not (Test-AdminRequirement -FunctionName 'Clear-DnsClientCache' -AdditionalInfo "This function requires administrator privileges to clear the DNS cache.")) {
        return $false
    }
    
    if ($PSCmdlet.ShouldProcess('DNS client cache', 'Clear')) {
        try {
            # Try the most reliable method first
            try {
                Clear-DnsClientCache -ErrorAction Stop
                return $true
            }
            catch {
                Write-Debug "Primary DNS cache clear method failed: $_"
            }
            
            # Fallback to ipconfig
            try {
                $null = ipconfig /flushdns 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $true
                }
                throw "ipconfig failed with exit code $LASTEXITCODE"
            }
            catch {
                Write-Debug "ipconfig fallback failed: $_"
            }
            
            # Last resort - WMI
            try {
                $null = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | 
                    Where-Object { $_.IPEnabled } | 
                    ForEach-Object { $_.FlushDNSResolvers() }
                return $true
            }
            catch {
                Write-Debug "WMI fallback failed: $_"
            }
            
            throw "All methods to clear DNS cache failed"
        }
        catch {
            Write-Error "Failed to clear DNS cache: $_"
            return $false
        }
    }
    
    return $false
}

# Export public functions
Export-ModuleMember -Function Test-NetworkConnectivity, Start-PortScan, Get-NetworkAdapter, Clear-DnsClientCache
