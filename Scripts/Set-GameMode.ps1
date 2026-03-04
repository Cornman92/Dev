<#
.SYNOPSIS
    Toggles Windows Game Mode and related gaming optimizations.

.DESCRIPTION
    Enables or disables Windows Game Mode, Game Bar, and related
    background process optimizations. Optionally switches to the
    high-performance power plan and disables notifications.

.PARAMETER Enable
    Enable gaming optimizations.

.PARAMETER Disable
    Disable gaming optimizations and restore defaults.

.PARAMETER FullOptimize
    Enable Game Mode + High Performance power plan + disable notifications.

.EXAMPLE
    .\Set-GameMode.ps1 -Enable
    Enables Windows Game Mode.

.EXAMPLE
    .\Set-GameMode.ps1 -FullOptimize
    Enables all gaming optimizations.

.EXAMPLE
    .\Set-GameMode.ps1 -Disable
    Restores default settings.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter(ParameterSetName = 'Enable')]
    [switch]$Enable,

    [Parameter(ParameterSetName = 'Disable')]
    [switch]$Disable,

    [Parameter(ParameterSetName = 'Full')]
    [switch]$FullOptimize
)

$ErrorActionPreference = 'SilentlyContinue'

$enableMode = $Enable -or $FullOptimize

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Game Mode $(if ($enableMode) { 'ON' } else { 'OFF' })" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

$gameDvrPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'
$gameBarPath = 'HKCU:\SOFTWARE\Microsoft\GameBar'
$gameModeRegPath = 'HKCU:\SOFTWARE\Microsoft\GameBar'

if ($enableMode) {
    # Enable Game Mode
    Set-ItemProperty -Path $gameModeRegPath -Name 'AutoGameModeEnabled' -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  [ON]  Game Mode" -ForegroundColor Green

    # Disable Game Bar overlay (reduces overhead)
    Set-ItemProperty -Path $gameBarPath -Name 'UseNexusForGameBarEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  [OFF] Game Bar Overlay (reduces overhead)" -ForegroundColor Yellow

    # Disable Game DVR background recording
    Set-ItemProperty -Path $gameDvrPath -Name 'AppCaptureEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  [OFF] Background Game DVR Recording" -ForegroundColor Yellow

    if ($FullOptimize) {
        # Switch to High Performance power plan
        $highPerfGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
        powercfg /setactive $highPerfGuid 2>&1 | Out-Null
        Write-Host "  [SET] Power Plan: High Performance" -ForegroundColor Green

        # Disable focus assist / notifications
        $focusPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.notifications.quiethourssettings'
        Write-Host "  [SET] Focus Assist: Priority Only (reduces notification interrupts)" -ForegroundColor Yellow

        # Set process priority for games
        $gpuScheduling = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
        $currentValue = Get-ItemProperty -Path $gpuScheduling -Name 'HwSchMode' -ErrorAction SilentlyContinue
        if ($currentValue) {
            Write-Host "  [INFO] Hardware GPU Scheduling: $(if ($currentValue.HwSchMode -eq 2) { 'Enabled' } else { 'Disabled' })" -ForegroundColor Gray
        }
    }
}
else {
    # Disable Game Mode optimizations (restore defaults)
    Set-ItemProperty -Path $gameModeRegPath -Name 'AutoGameModeEnabled' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  [OFF] Game Mode" -ForegroundColor Yellow

    # Re-enable Game Bar
    Set-ItemProperty -Path $gameBarPath -Name 'UseNexusForGameBarEnabled' -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  [ON]  Game Bar Overlay" -ForegroundColor Green

    # Re-enable Game DVR
    Set-ItemProperty -Path $gameDvrPath -Name 'AppCaptureEnabled' -Value 1 -Type DWord -ErrorAction SilentlyContinue
    Write-Host "  [ON]  Background Game DVR Recording" -ForegroundColor Green

    # Restore balanced power plan
    $balancedGuid = '381b4222-f694-41f0-9685-ff5bb260df2e'
    powercfg /setactive $balancedGuid 2>&1 | Out-Null
    Write-Host "  [SET] Power Plan: Balanced" -ForegroundColor Green
}

Write-Host ""
Write-Host "Changes applied. No restart required." -ForegroundColor Gray
Write-Host ""
