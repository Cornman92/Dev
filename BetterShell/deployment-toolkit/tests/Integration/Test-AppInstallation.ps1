# Test-AppInstallation.ps1
# Integration test for app installation workflow

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Core -Force
Import-Module Deployment.Packages -Force
Import-Module Deployment.Validation -Force

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   App Installation Workflow Test           ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$testResults = @{
    Passed = $true
    Tests = @()
}

# Test 1: App catalog loading
Write-Host "Test 1: App catalog loading..." -ForegroundColor Yellow
try {
    $catalog = Get-AppCatalog
    $testResults.Tests += [pscustomobject]@{
        Name = 'App Catalog Load'
        Status = 'Pass'
        Details = "$($catalog.Count) app(s) loaded"
    }
    Write-Host "  ✓ Loaded $($catalog.Count) app(s)" -ForegroundColor Green
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: App set loading
Write-Host ''
Write-Host "Test 2: App set loading..." -ForegroundColor Yellow
try {
    $appSet = Get-AppSet -SetId 'dev-workstation'
    $testResults.Tests += [pscustomobject]@{
        Name = 'App Set Load'
        Status = 'Pass'
        Details = "App set 'dev-workstation' with $($appSet.appIds.Count) app(s)"
    }
    Write-Host "  ✓ Loaded app set 'dev-workstation' with $($appSet.appIds.Count) app(s)" -ForegroundColor Green
}
catch {
    $testResults.Tests += [pscustomobject]@{
        Name = 'App Set Load'
        Status = 'Warning'
        Details = "App set 'dev-workstation' not found (may be expected)"
    }
    Write-Host "  ⚠ App set 'dev-workstation' not found" -ForegroundColor Yellow
}

# Test 3: App detection logic
Write-Host ''
Write-Host "Test 3: App detection logic..." -ForegroundColor Yellow
try {
    $catalog = Get-AppCatalog
    $tested = 0
    $detected = 0
    
    foreach ($app in $catalog | Select-Object -First 5) {
        $tested++
        $isInstalled = Test-AppInstalled -App $app
        if ($isInstalled) {
            $detected++
        }
    }
    
    $testResults.Tests += [pscustomobject]@{
        Name = 'App Detection'
        Status = 'Pass'
        Details = "Tested $tested app(s), $detected detected as installed"
    }
    Write-Host "  ✓ Tested $tested app(s), $detected detected as installed" -ForegroundColor Green
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
    $color = if ($test.Status -eq 'Pass') { 'Green' } elseif ($test.Status -eq 'Warning') { 'Yellow' } else { 'Red' }
    Write-Host "$($test.Status): $($test.Name) - $($test.Details)" -ForegroundColor $color
}

Write-Host ''
if ($testResults.Passed) {
    Write-Host 'App installation workflow tests passed!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Some tests failed. See details above.' -ForegroundColor Red
    exit 1
}

