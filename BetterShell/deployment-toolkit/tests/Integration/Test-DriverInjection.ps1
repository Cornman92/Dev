# Test-DriverInjection.ps1
# Integration test for driver injection workflow

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Core -Force
Import-Module Deployment.Drivers -Force
Import-Module Deployment.Validation -Force

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Driver Injection Workflow Test           ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$testResults = @{
    Passed = $true
    Tests = @()
}

# Test 1: Hardware detection
Write-Host "Test 1: Hardware detection..." -ForegroundColor Yellow
try {
    $hw = Get-HardwareProfile
    $testResults.Tests += [pscustomobject]@{
        Name = 'Hardware Detection'
        Status = 'Pass'
        Details = "$($hw.Manufacturer) $($hw.Model)"
    }
    Write-Host "  ✓ Hardware detected: $($hw.Manufacturer) $($hw.Model)" -ForegroundColor Green
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Driver catalog loading
Write-Host ''
Write-Host "Test 2: Driver catalog loading..." -ForegroundColor Yellow
try {
    $catalog = Get-DriverCatalog
    $testResults.Tests += [pscustomobject]@{
        Name = 'Driver Catalog Load'
        Status = 'Pass'
        Details = "$($catalog.Count) driver pack(s) loaded"
    }
    Write-Host "  ✓ Loaded $($catalog.Count) driver pack(s)" -ForegroundColor Green
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Driver pack matching
Write-Host ''
Write-Host "Test 3: Driver pack matching..." -ForegroundColor Yellow
try {
    $hw = Get-HardwareProfile
    $catalog = Get-DriverCatalog
    $matches = Find-DriverPacksForHardware -HardwareProfile $hw -DriverCatalog $catalog
    
    $testResults.Tests += [pscustomobject]@{
        Name = 'Driver Pack Matching'
        Status = 'Pass'
        Details = "$($matches.Count) matching driver pack(s) found"
    }
    Write-Host "  ✓ Found $($matches.Count) matching driver pack(s)" -ForegroundColor Green
    
    if ($matches.Count -gt 0) {
        Write-Host "  Top matches:" -ForegroundColor Gray
        foreach ($match in $matches | Select-Object -First 3) {
            Write-Host "    - $($match.DriverPack.id) (Score: $($match.Score))" -ForegroundColor Gray
        }
    }
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Test Summary                             ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

foreach ($test in $testResults.Tests) {
    Write-Host "$($test.Status): $($test.Name) - $($test.Details)" -ForegroundColor $(if ($test.Status -eq 'Pass') { 'Green' } else { 'Red' })
}

Write-Host ''
if ($testResults.Passed) {
    Write-Host 'Driver injection workflow tests passed!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Some tests failed. See details above.' -ForegroundColor Red
    exit 1
}

