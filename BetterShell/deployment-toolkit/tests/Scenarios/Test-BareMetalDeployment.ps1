# Test-BareMetalDeployment.ps1
# Scenario test for bare metal deployment workflow

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Core -Force
Import-Module Deployment.TaskSequence -Force
Import-Module Deployment.Validation -Force

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Bare Metal Deployment Scenario Test      ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$testResults = @{
    Passed = $true
    Tests = @()
}

# Test 1: Load bare metal task sequence
Write-Host "Test 1: Load bare metal task sequence..." -ForegroundColor Yellow
try {
    $ts = Get-TaskSequence -Id 'baremetal-basic'
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

# Test 2: Validate task sequence structure
Write-Host ''
Write-Host "Test 2: Validate task sequence structure..." -ForegroundColor Yellow
try {
    $validation = Test-TaskSequence -TaskSequenceId 'baremetal-basic'
    $testResults.Tests += [pscustomobject]@{
        Name = 'Task Sequence Validation'
        Status = if ($validation.Passed) { 'Pass' } else { 'Fail' }
        Details = "$($validation.StepCount) step(s), $($validation.Errors.Count) error(s)"
    }
    
    if ($validation.Passed) {
        Write-Host "  ✓ Task sequence structure is valid" -ForegroundColor Green
    }
    else {
        Write-Host "  ✗ Validation errors found" -ForegroundColor Red
        $testResults.Passed = $false
    }
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Check for required steps
Write-Host ''
Write-Host "Test 3: Check for required steps..." -ForegroundColor Yellow
try {
    $ts = Get-TaskSequence -Id 'baremetal-basic'
    $stepTypes = $ts.steps | ForEach-Object { $_.type }
    
    $required = @('PartitionDisk', 'ApplyImage', 'ConfigureBoot')
    $missing = @()
    
    foreach ($req in $required) {
        if ($req -notin $stepTypes) {
            $missing += $req
        }
    }
    
    if ($missing.Count -eq 0) {
        $testResults.Tests += [pscustomobject]@{
            Name = 'Required Steps Check'
            Status = 'Pass'
            Details = "All required steps present"
        }
        Write-Host "  ✓ All required steps present" -ForegroundColor Green
    }
    else {
        $testResults.Passed = $false
        $testResults.Tests += [pscustomobject]@{
            Name = 'Required Steps Check'
            Status = 'Fail'
            Details = "Missing steps: $($missing -join ', ')"
        }
        Write-Host "  ✗ Missing required steps: $($missing -join ', ')" -ForegroundColor Red
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
    Write-Host 'Bare metal deployment scenario test passed!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Scenario test failed. See details above.' -ForegroundColor Red
    exit 1
}

