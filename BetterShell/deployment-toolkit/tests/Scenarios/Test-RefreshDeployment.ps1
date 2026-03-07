# Test-RefreshDeployment.ps1
# Scenario test for refresh deployment workflow

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Core -Force
Import-Module Deployment.TaskSequence -Force
Import-Module Deployment.Validation -Force

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Refresh Deployment Scenario Test         ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$testResults = @{
    Passed = $true
    Tests = @()
}

# Test 1: Load refresh task sequence
Write-Host "Test 1: Load refresh task sequence..." -ForegroundColor Yellow
try {
    $ts = Get-TaskSequence -Id 'refresh-deployment'
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

# Test 2: Validate refresh-specific steps
Write-Host ''
Write-Host "Test 2: Validate refresh-specific steps..." -ForegroundColor Yellow
try {
    $ts = Get-TaskSequence -Id 'refresh-deployment'
    $stepTypes = $ts.steps | ForEach-Object { $_.type }
    
    $hasHealthSnapshot = 'HealthSnapshot' -in $stepTypes
    $hasAppInstall = 'InstallAppSet' -in $stepTypes
    
    if ($hasHealthSnapshot -and $hasAppInstall) {
        $testResults.Tests += [pscustomobject]@{
            Name = 'Refresh Steps Check'
            Status = 'Pass'
            Details = "Contains health snapshots and app installation"
        }
        Write-Host "  ✓ Refresh-specific steps present" -ForegroundColor Green
    }
    else {
        $testResults.Passed = $false
        Write-Host "  ✗ Missing refresh-specific steps" -ForegroundColor Red
    }
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
    Write-Host 'Refresh deployment scenario test passed!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Scenario test failed. See details above.' -ForegroundColor Red
    exit 1
}

