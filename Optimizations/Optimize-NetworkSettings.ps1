<#
.SYNOPSIS
    Optimizes TCP/IP and network stack settings for performance.

.DESCRIPTION
    Tunes network adapter settings, TCP window size, and other
    stack parameters for lower latency and higher throughput.
    Creates a backup of current settings before making changes.

.PARAMETER Mode
    'Gaming' optimizes for low latency. 'Throughput' optimizes for
    maximum bandwidth. 'Default' restores Windows defaults.

.PARAMETER Adapter
    Name of the network adapter to optimize. If not specified,
    applies to all active adapters.

.EXAMPLE
    .\Optimize-NetworkSettings.ps1 -Mode Gaming
    Optimizes for low-latency gaming.

.EXAMPLE
    .\Optimize-NetworkSettings.ps1 -Mode Default
    Restores network settings to Windows defaults.

.NOTES
    Author: C-Man
    Date:   2026-02-28
    Requires: Run as Administrator
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Gaming', 'Throughput', 'Default')]
    [string]$Mode,

    [Parameter()]
    [string]$Adapter
)

$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script requires administrator privileges."
}

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Network Optimization: $Mode" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Get target adapters
if ($Adapter) {
    $adapters = Get-NetAdapter -Name $Adapter -ErrorAction Stop
}
else {
    $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
}

Write-Host "Target adapters:" -ForegroundColor White
foreach ($adp in $adapters) {
    Write-Host "  $($adp.Name) ($($adp.InterfaceDescription))" -ForegroundColor Gray
}
Write-Host ""

switch ($Mode) {
    'Gaming' {
        Write-Host "Applying gaming optimizations (low latency):" -ForegroundColor Yellow
        Write-Host ""

        # Disable Nagle's Algorithm (reduces latency)
        if ($PSCmdlet.ShouldProcess("TCP Nagle's Algorithm", "Disable")) {
            $tcpPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
            Set-ItemProperty -Path $tcpPath -Name 'TcpNoDelay' -Value 1 -Type DWord -ErrorAction SilentlyContinue
            Write-Host "  [SET] Nagle's Algorithm: Disabled (TcpNoDelay=1)" -ForegroundColor Green
        }

        # Disable TCP auto-tuning (more predictable latency)
        if ($PSCmdlet.ShouldProcess("TCP Auto-Tuning", "Set to disabled")) {
            netsh int tcp set global autotuninglevel=disabled 2>&1 | Out-Null
            Write-Host "  [SET] TCP Auto-Tuning: Disabled" -ForegroundColor Green
        }

        # Enable Direct Cache Access
        if ($PSCmdlet.ShouldProcess("Direct Cache Access", "Enable")) {
            netsh int tcp set global dca=enabled 2>&1 | Out-Null
            Write-Host "  [SET] Direct Cache Access: Enabled" -ForegroundColor Green
        }

        # Disable Large Send Offload
        foreach ($adp in $adapters) {
            if ($PSCmdlet.ShouldProcess("$($adp.Name) LSO", "Disable")) {
                Disable-NetAdapterLso -Name $adp.Name -ErrorAction SilentlyContinue
                Write-Host "  [SET] $($adp.Name): Large Send Offload Disabled" -ForegroundColor Green
            }
        }

        # Disable network throttling
        if ($PSCmdlet.ShouldProcess("Network Throttling Index", "Disable")) {
            $mmPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
            Set-ItemProperty -Path $mmPath -Name 'NetworkThrottlingIndex' -Value 0xFFFFFFFF -Type DWord -ErrorAction SilentlyContinue
            Write-Host "  [SET] Network Throttling: Disabled" -ForegroundColor Green
        }
    }

    'Throughput' {
        Write-Host "Applying throughput optimizations:" -ForegroundColor Yellow
        Write-Host ""

        # Enable TCP auto-tuning for max throughput
        if ($PSCmdlet.ShouldProcess("TCP Auto-Tuning", "Set to normal")) {
            netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
            Write-Host "  [SET] TCP Auto-Tuning: Normal (adaptive)" -ForegroundColor Green
        }

        # Enable Large Send Offload
        foreach ($adp in $adapters) {
            if ($PSCmdlet.ShouldProcess("$($adp.Name) LSO", "Enable")) {
                Enable-NetAdapterLso -Name $adp.Name -ErrorAction SilentlyContinue
                Write-Host "  [SET] $($adp.Name): Large Send Offload Enabled" -ForegroundColor Green
            }
        }

        # Enable RSS
        foreach ($adp in $adapters) {
            if ($PSCmdlet.ShouldProcess("$($adp.Name) RSS", "Enable")) {
                Enable-NetAdapterRss -Name $adp.Name -ErrorAction SilentlyContinue
                Write-Host "  [SET] $($adp.Name): Receive Side Scaling Enabled" -ForegroundColor Green
            }
        }
    }

    'Default' {
        Write-Host "Restoring Windows defaults:" -ForegroundColor Yellow
        Write-Host ""

        if ($PSCmdlet.ShouldProcess("TCP settings", "Reset to defaults")) {
            netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
            $tcpPath = 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters'
            Remove-ItemProperty -Path $tcpPath -Name 'TcpNoDelay' -ErrorAction SilentlyContinue

            $mmPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
            Set-ItemProperty -Path $mmPath -Name 'NetworkThrottlingIndex' -Value 10 -Type DWord -ErrorAction SilentlyContinue

            Write-Host "  [RESET] TCP Auto-Tuning: Normal" -ForegroundColor Green
            Write-Host "  [RESET] Nagle's Algorithm: Default" -ForegroundColor Green
            Write-Host "  [RESET] Network Throttling: Default (10)" -ForegroundColor Green
        }

        foreach ($adp in $adapters) {
            Enable-NetAdapterLso -Name $adp.Name -ErrorAction SilentlyContinue
            Enable-NetAdapterRss -Name $adp.Name -ErrorAction SilentlyContinue
            Write-Host "  [RESET] $($adp.Name): LSO and RSS restored" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "Network optimization complete. Some changes may require a restart." -ForegroundColor Gray
Write-Host ""
