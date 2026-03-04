<#
.SYNOPSIS
    Tests network connectivity with multiple diagnostic checks.

.DESCRIPTION
    Performs a series of network tests: ping, DNS resolution, HTTP
    connectivity, and port checks. Generates a summary report of
    network health.

.PARAMETER Targets
    Hostnames or IPs to test. Defaults to common public services.

.PARAMETER Ports
    TCP ports to test on each target. Defaults to 80, 443.

.PARAMETER Count
    Number of ping attempts per target. Defaults to 4.

.EXAMPLE
    .\Test-NetworkConnectivity.ps1
    Runs default diagnostics against common endpoints.

.EXAMPLE
    .\Test-NetworkConnectivity.ps1 -Targets "192.168.1.1","myserver.local" -Ports 22,3389
    Tests custom hosts on SSH and RDP ports.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string[]]$Targets = @('8.8.8.8', '1.1.1.1', 'google.com', 'github.com'),

    [Parameter()]
    [int[]]$Ports = @(80, 443),

    [Parameter()]
    [int]$Count = 4
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Network Diagnostics" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# ---- Basic Connectivity (Ping) ----
Write-Host "Ping Tests ($Count attempts each):" -ForegroundColor White
Write-Host ""

foreach ($target in $Targets) {
    $result = Test-Connection -ComputerName $target -Count $Count -ErrorAction SilentlyContinue
    if ($result) {
        $avgMs = [math]::Round(($result | Measure-Object -Property ResponseTime -Average).Average, 1)
        $minMs = ($result | Measure-Object -Property ResponseTime -Minimum).Minimum
        $maxMs = ($result | Measure-Object -Property ResponseTime -Maximum).Maximum
        $loss = [math]::Round((1 - ($result.Count / $Count)) * 100, 0)

        $color = if ($avgMs -lt 50) { 'Green' } elseif ($avgMs -lt 200) { 'Yellow' } else { 'Red' }
        Write-Host ("  {0,-25} Avg: {1,6}ms  Min: {2,4}ms  Max: {3,4}ms  Loss: {4}%" -f `
            $target, $avgMs, $minMs, $maxMs, $loss) -ForegroundColor $color
    }
    else {
        Write-Host ("  {0,-25} UNREACHABLE" -f $target) -ForegroundColor Red
    }
}

Write-Host ""

# ---- DNS Resolution ----
Write-Host "DNS Resolution:" -ForegroundColor White
Write-Host ""

$dnsTargets = $Targets | Where-Object { $_ -notmatch '^\d+\.\d+\.\d+\.\d+$' }

foreach ($target in $dnsTargets) {
    try {
        $dns = Resolve-DnsName -Name $target -Type A -ErrorAction Stop
        $ips = ($dns | Where-Object { $_.QueryType -eq 'A' }).IPAddress -join ', '
        Write-Host ("  {0,-25} -> {1}" -f $target, $ips) -ForegroundColor Green
    }
    catch {
        Write-Host ("  {0,-25} -> FAILED" -f $target) -ForegroundColor Red
    }
}

Write-Host ""

# ---- Port Connectivity ----
Write-Host "Port Tests:" -ForegroundColor White
Write-Host ""

foreach ($target in $Targets) {
    foreach ($port in $Ports) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $connect = $tcp.BeginConnect($target, $port, $null, $null)
            $wait = $connect.AsyncWaitHandle.WaitOne(3000, $false)

            if ($wait -and $tcp.Connected) {
                Write-Host ("  {0,-25} Port {1,5}  OPEN" -f $target, $port) -ForegroundColor Green
                $tcp.EndConnect($connect)
            }
            else {
                Write-Host ("  {0,-25} Port {1,5}  CLOSED/FILTERED" -f $target, $port) -ForegroundColor Red
            }
            $tcp.Close()
        }
        catch {
            Write-Host ("  {0,-25} Port {1,5}  ERROR" -f $target, $port) -ForegroundColor Red
        }
    }
}

Write-Host ""

# ---- HTTP Connectivity ----
Write-Host "HTTP Tests:" -ForegroundColor White
Write-Host ""

$httpTargets = $Targets | Where-Object { $_ -notmatch '^\d+\.\d+\.\d+\.\d+$' }

foreach ($target in $httpTargets) {
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-WebRequest -Uri "https://$target" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
        $stopwatch.Stop()

        Write-Host ("  https://{0,-22} Status: {1}  Time: {2}ms" -f `
            $target, $response.StatusCode, $stopwatch.ElapsedMilliseconds) -ForegroundColor Green
    }
    catch {
        Write-Host ("  https://{0,-22} FAILED: {1}" -f $target, $_.Exception.Message.Substring(0, [Math]::Min(60, $_.Exception.Message.Length))) -ForegroundColor Red
    }
}

Write-Host ""
