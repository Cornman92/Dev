# Test-OptimizationOnly.ps1
# Scenario test for optimization-only workflow

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Core -Force
Import-Module Deployment.TaskSequence -Force
Import-Module Deployment.Optimization -Force

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Optimization-Only Scenario Test          ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$testResults = @{
    Passed = $true
    Tests = @()
}

# Test 1: Load optimization task sequence
Write-Host "Test 1: Load optimization task sequence..." -ForegroundColor Yellow
try {
    $ts = Get-TaskSequence -Id 'postsetup-optimize-dev'
    $testResults.Tests += [pscustomobject]@{
        Name = 'Task Sequence Load'
        Status = 'Pass'
        Details = "Loaded '$($ts.name)' with $($ts.steps.Count) step(s)"
    }
    Write-Host "  ✓ Loaded task sequence: $($ts.name)" -ForegroundColor Green
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Validate optimization profiles exist
Write-Host ''
Write-Host "Test 2: Validate optimization profiles..." -ForegroundColor Yellow
try {
    $profiles = Get-OptimizationProfiles
    $requiredProfiles = @('perf-desktop', 'minimal')
    $found = 0
    
    foreach ($req in $requiredProfiles) {
        $profile = $profiles | Where-Object { $_.id -eq $req }
        if ($profile) {
            $found++
        }
    }
    
    if ($found -eq $requiredProfiles.Count) {
        $testResults.Tests += [pscustomobject]@{
            Name = 'Optimization Profiles'
            Status = 'Pass'
            Details = "All required profiles found"
        }
        Write-Host "  ✓ All required optimization profiles found" -ForegroundColor Green
    }
    else {
        $testResults.Passed = $false
        Write-Host "  ✗ Some optimization profiles missing" -ForegroundColor Red
    }
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Validate debloat profiles
Write-Host ''
Write-Host "Test 3: Validate debloat profiles..." -ForegroundColor Yellow
try {
    $light = Get-DebloatProfile -Id 'light'
    $aggressive = Get-DebloatProfile -Id 'aggressive'
    
    $testResults.Tests += [pscustomobject]@{
        Name = 'Debloat Profiles'
        Status = 'Pass'
        Details = "Light and aggressive profiles available"
    }
    Write-Host "  ✓ Debloat profiles available" -ForegroundColor Green
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Scenario Test Summary                    ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

foreach ($test in $testResults.Tests) {
    $color = if ($test.Status -eq 'Pass') { 'Green' } else { 'Red' }
    Write-Host "$($test.Status): $($test.Name) - $($test.Details)" -ForegroundColor $color
}

Write-Host ''
if ($testResults.Passed) {
    Write-Host 'Optimization-only scenario test passed!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Scenario test failed. See details above.' -ForegroundColor Red
    exit 1
}

