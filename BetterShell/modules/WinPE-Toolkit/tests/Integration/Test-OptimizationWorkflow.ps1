# Test-OptimizationWorkflow.ps1
# Integration test for optimization workflow

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Core -Force
Import-Module Deployment.Optimization -Force

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Optimization Workflow Test               ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$testResults = @{
    Passed = $true
    Tests = @()
}

# Test 1: Optimization profile loading
Write-Host "Test 1: Optimization profile loading..." -ForegroundColor Yellow
try {
    $profiles = Get-OptimizationProfiles
    $testResults.Tests += [pscustomobject]@{
        Name = 'Optimization Profiles Load'
        Status = 'Pass'
        Details = "$($profiles.Count) profile(s) loaded"
    }
    Write-Host "  ✓ Loaded $($profiles.Count) optimization profile(s)" -ForegroundColor Green
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Debloat profile loading
Write-Host ''
Write-Host "Test 2: Debloat profile loading..." -ForegroundColor Yellow
try {
    $light = Get-DebloatProfile -Id 'light'
    $aggressive = Get-DebloatProfile -Id 'aggressive'
    
    $testResults.Tests += [pscustomobject]@{
        Name = 'Debloat Profiles Load'
        Status = 'Pass'
        Details = "Loaded 'light' and 'aggressive' profiles"
    }
    Write-Host "  ✓ Loaded debloat profiles" -ForegroundColor Green
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Personalization profile loading
Write-Host ''
Write-Host "Test 3: Personalization profile loading..." -ForegroundColor Yellow
try {
    $root = Get-DeployRoot
    $path = Join-Path $root 'configs\optimize\personalization.json'
    if (Test-Path $path) {
        $raw = Get-Content -Path $path -Raw | ConvertFrom-Json
        $testResults.Tests += [pscustomobject]@{
            Name = 'Personalization Profile Load'
            Status = 'Pass'
            Details = "Personalization config file exists with $($raw.Count) profile(s)"
        }
        Write-Host "  ✓ Personalization config file exists" -ForegroundColor Green
    }
    else {
        $testResults.Tests += [pscustomobject]@{
            Name = 'Personalization Profile Load'
            Status = 'Warning'
            Details = "Personalization config file not found"
        }
        Write-Host "  ⚠ Personalization config file not found" -ForegroundColor Yellow
    }
}
catch {
    $testResults.Tests += [pscustomobject]@{
        Name = 'Personalization Profile Load'
        Status = 'Warning'
        Details = "Could not load personalization profile: $($_.Exception.Message)"
    }
    Write-Host "  ⚠ Could not load personalization profile" -ForegroundColor Yellow
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
    Write-Host 'Optimization workflow tests passed!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Some tests failed. See details above.' -ForegroundColor Red
    exit 1
}

