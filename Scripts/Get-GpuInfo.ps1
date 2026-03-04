<#
.SYNOPSIS
    Retrieves GPU information and driver details.

.DESCRIPTION
    Queries system GPU(s) for model name, driver version, driver date,
    VRAM, resolution, and refresh rate. Useful for verifying drivers
    are up to date and checking hardware specs.

.PARAMETER Detailed
    Include additional adapter properties and display modes.

.EXAMPLE
    .\Get-GpuInfo.ps1
    Shows basic GPU information.

.EXAMPLE
    .\Get-GpuInfo.ps1 -Detailed
    Shows extended GPU and display information.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter()]
    [switch]$Detailed
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  GPU Information" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

$gpus = Get-CimInstance -ClassName Win32_VideoController

foreach ($gpu in $gpus) {
    $vramGB = [math]::Round($gpu.AdapterRAM / 1GB, 2)
    # AdapterRAM can overflow for large VRAM, check via registry
    if ($vramGB -le 0 -or $vramGB -gt 128) {
        $vramGB = "N/A (query overflow)"
    }

    $driverDate = if ($gpu.DriverDate) {
        $gpu.DriverDate.ToString('yyyy-MM-dd')
    } else { 'Unknown' }

    Write-Host "GPU: $($gpu.Name)" -ForegroundColor White
    Write-Host "  Status:          $($gpu.Status)" -ForegroundColor Gray
    Write-Host "  Driver Version:  $($gpu.DriverVersion)" -ForegroundColor Gray
    Write-Host "  Driver Date:     $driverDate" -ForegroundColor Gray
    Write-Host "  VRAM:            $vramGB GB" -ForegroundColor Gray
    Write-Host "  Resolution:      $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution)" -ForegroundColor Gray
    Write-Host "  Refresh Rate:    $($gpu.CurrentRefreshRate) Hz" -ForegroundColor Gray
    Write-Host "  Bits/Pixel:      $($gpu.CurrentBitsPerPixel)" -ForegroundColor Gray
    Write-Host "  Adapter Type:    $($gpu.AdapterCompatibility)" -ForegroundColor Gray

    if ($Detailed) {
        Write-Host "  Video Processor: $($gpu.VideoProcessor)" -ForegroundColor Gray
        Write-Host "  Video Mode:      $($gpu.VideoModeDescription)" -ForegroundColor Gray
        Write-Host "  DAC Type:        $($gpu.AdapterDACType)" -ForegroundColor Gray
        Write-Host "  INF File:        $($gpu.InfFilename)" -ForegroundColor Gray
        Write-Host "  PNP Device ID:   $($gpu.PNPDeviceID)" -ForegroundColor Gray
    }

    Write-Host ""
}

# Driver age warning
foreach ($gpu in $gpus) {
    if ($gpu.DriverDate) {
        $driverAge = (Get-Date) - $gpu.DriverDate
        if ($driverAge.TotalDays -gt 180) {
            Write-Host "Warning: $($gpu.Name) driver is $([math]::Round($driverAge.TotalDays)) days old. Consider updating." -ForegroundColor Yellow
        }
        else {
            Write-Host "$($gpu.Name) driver is current ($([math]::Round($driverAge.TotalDays)) days old)." -ForegroundColor Green
        }
    }
}

Write-Host ""
