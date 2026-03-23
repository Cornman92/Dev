<#
.SYNOPSIS
    Disables Windows telemetry and data collection services.

.DESCRIPTION
    Stops and disables telemetry-related services and scheduled tasks.
    Can also set registry keys to minimize data collection level.
    Reversible with the -Enable switch.

.PARAMETER Enable
    Re-enables telemetry services and restores defaults.

.PARAMETER WhatIf
    Preview changes without applying them.

.EXAMPLE
    .\Disable-Telemetry.ps1
    Disables telemetry services and tasks.

.EXAMPLE
    .\Disable-Telemetry.ps1 -Enable
    Re-enables telemetry services.

.NOTES
    Author: C-Man
    Date:   2026-02-28
    Requires: Run as Administrator
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$Enable
)

$ErrorActionPreference = 'SilentlyContinue'

# Check admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Error "This script requires administrator privileges."
}

$action = if ($Enable) { "Enabling" } else { "Disabling" }

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  $action Telemetry" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# ---- Services ----
$telemetryServices = @(
    'DiagTrack',              # Connected User Experiences and Telemetry
    'dmwappushservice',       # WAP Push Message Routing Service
    'diagnosticshub.standardcollector.service'  # Diagnostics Hub
)

Write-Host "Services:" -ForegroundColor White
foreach ($svcName in $telemetryServices) {
    $svc = Get-Service -Name $svcName -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Host "  [SKIP] $svcName - not found" -ForegroundColor Gray
        continue
    }

    if ($Enable) {
        if ($PSCmdlet.ShouldProcess($svcName, "Enable and start")) {
            Set-Service -Name $svcName -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $svcName -ErrorAction SilentlyContinue
            Write-Host "  [ON]  $svcName" -ForegroundColor Green
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess($svcName, "Stop and disable")) {
            Stop-Service -Name $svcName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $svcName -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "  [OFF] $svcName" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# ---- Scheduled Tasks ----
$telemetryTasks = @(
    '\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
    '\Microsoft\Windows\Application Experience\ProgramDataUpdater',
    '\Microsoft\Windows\Customer Experience Improvement Program\Consolidator',
    '\Microsoft\Windows\Customer Experience Improvement Program\UsbCeip',
    '\Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector'
)

Write-Host "Scheduled Tasks:" -ForegroundColor White
foreach ($taskPath in $telemetryTasks) {
    $taskName = Split-Path $taskPath -Leaf
    $task = Get-ScheduledTask -TaskPath (Split-Path $taskPath -Parent).Replace('\', '\') -TaskName $taskName -ErrorAction SilentlyContinue
    if (-not $task) {
        Write-Host "  [SKIP] $taskName - not found" -ForegroundColor Gray
        continue
    }

    if ($Enable) {
        if ($PSCmdlet.ShouldProcess($taskName, "Enable")) {
            Enable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  [ON]  $taskName" -ForegroundColor Green
        }
    }
    else {
        if ($PSCmdlet.ShouldProcess($taskName, "Disable")) {
            Disable-ScheduledTask -TaskName $task.TaskName -TaskPath $task.TaskPath -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  [OFF] $taskName" -ForegroundColor Yellow
        }
    }
}
Write-Host ""

# ---- Registry ----
Write-Host "Registry (Telemetry Level):" -ForegroundColor White
$regPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'

if ($Enable) {
    if ($PSCmdlet.ShouldProcess('DataCollection registry key', "Remove")) {
        Remove-ItemProperty -Path $regPath -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
        Write-Host "  [RESET] Telemetry level restored to default" -ForegroundColor Green
    }
}
else {
    if ($PSCmdlet.ShouldProcess('DataCollection registry key', "Set to Security (0)")) {
        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }
        Set-ItemProperty -Path $regPath -Name 'AllowTelemetry' -Value 0 -Type DWord
        Write-Host "  [SET]  AllowTelemetry = 0 (Security/Required only)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "$action telemetry complete." -ForegroundColor $(if ($Enable) { 'Green' } else { 'Yellow' })
Write-Host ""
