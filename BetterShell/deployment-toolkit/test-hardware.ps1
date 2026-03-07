# Hardware Detection Test Script

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Hardware Detection Test                  ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

Import-Module Deployment.Drivers -Force

try {
    Write-Host 'Running Get-HardwareProfile...' -ForegroundColor Yellow
    $hw = Get-HardwareProfile
    
    Write-Host ''
    Write-Host 'Hardware Profile Results:' -ForegroundColor Green
    Write-Host "  Manufacturer     : $($hw.Manufacturer)"
    Write-Host "  Model            : $($hw.Model)"
    Write-Host "  BIOS Version     : $($hw.BIOSVersion)"
    Write-Host "  BIOS Vendor      : $($hw.BIOSVendor)"
    Write-Host "  CPU Name         : $($hw.CPUName)"
    Write-Host "  CPU Cores        : $($hw.CPUCores)"
    Write-Host "  CPU Threads      : $($hw.CPUThreads)"
    Write-Host "  Total Memory     : $($hw.TotalMemoryGB) GB ($($hw.TotalMemoryBytes) bytes)"
    Write-Host "  OS Version       : $($hw.OSVersion)"
    Write-Host "  OS Edition       : $($hw.OSEdition)"
    Write-Host "  Video Controllers: $($hw.VideoControllers.Count)"
    Write-Host "  Network Adapters : $($hw.NetworkAdapters.Count)"
    Write-Host "  PNP IDs          : $($hw.PnpIds.Count)"
    
    # Validate required properties
    $requiredProps = @('Manufacturer', 'Model', 'CPUName', 'TotalMemoryGB', 'OSVersion')
    $missing = @()
    
    foreach ($prop in $requiredProps) {
        if (-not $hw.$prop) {
            $missing += $prop
        }
    }
    
    Write-Host ''
    if ($missing.Count -eq 0) {
        Write-Host 'All required properties present: PASSED' -ForegroundColor Green
        exit 0
    }
    else {
        Write-Host "Missing required properties: $($missing -join ', ')" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}

