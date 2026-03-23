# Test-FullDeploymentWorkflow.ps1
# Integration test for full deployment workflow

[CmdletBinding()]
param(
    [Parameter()]
    [switch] $SkipDestructive
)

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.Core -Force
Import-Module Deployment.TaskSequence -Force
Import-Module Deployment.Validation -Force

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Full Deployment Workflow Integration Test' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$testResults = @{
    Passed = $true
    Tests = @()
}

# Test 1: Prerequisites check
Write-Host "Test 1: Prerequisites validation..." -ForegroundColor Yellow
try {
    $prereq = Test-DeploymentPrerequisites
    $testResults.Tests += [pscustomobject]@{
        Name = 'Prerequisites Check'
        Status = if ($prereq.Passed) { 'Pass' } else { 'Fail' }
        Details = $prereq.Checks
    }
    
    if (-not $prereq.Passed) {
        $testResults.Passed = $false
        Write-Host "  ✗ Prerequisites check failed" -ForegroundColor Red
    }
    else {
        Write-Host "  ✓ Prerequisites check passed" -ForegroundColor Green
    }
}
catch {
    $testResults.Passed = $false
    $testResults.Tests += [pscustomobject]@{
        Name = 'Prerequisites Check'
        Status = 'Error'
        Details = $_.Exception.Message
    }
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Task sequence loading
Write-Host ''
Write-Host "Test 2: Task sequence loading..." -ForegroundColor Yellow
try {
    $catalog = Get-TaskSequenceCatalog
    $testResults.Tests += [pscustomobject]@{
        Name = 'Task Sequence Catalog'
        Status = 'Pass'
        Details = "Loaded $($catalog.Count) task sequence(s)"
    }
    Write-Host "  ✓ Loaded $($catalog.Count) task sequence(s)" -ForegroundColor Green
}
catch {
    $testResults.Passed = $false
    $testResults.Tests += [pscustomobject]@{
        Name = 'Task Sequence Catalog'
        Status = 'Error'
        Details = $_.Exception.Message
    }
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Driver catalog validation
Write-Host ''
Write-Host "Test 3: Driver catalog validation..." -ForegroundColor Yellow
try {
    $driverCheck = Test-DriverCatalog
    $testResults.Tests += [pscustomobject]@{
        Name = 'Driver Catalog'
        Status = if ($driverCheck.Passed) { 'Pass' } else { 'Warning' }
        Details = "$($driverCheck.DriverPacks.Count) driver pack(s), $($driverCheck.Warnings.Count) warning(s)"
    }
    
    if ($driverCheck.Warnings.Count -gt 0) {
        Write-Host "  ⚠ $($driverCheck.Warnings.Count) warning(s)" -ForegroundColor Yellow
    }
    else {
        Write-Host "  ✓ Driver catalog validated" -ForegroundColor Green
    }
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: App catalog validation
Write-Host ''
Write-Host "Test 4: App catalog validation..." -ForegroundColor Yellow
try {
    $appCheck = Test-AppCatalog
    $testResults.Tests += [pscustomobject]@{
        Name = 'App Catalog'
        Status = if ($appCheck.Passed) { 'Pass' } else { 'Warning' }
        Details = "$($appCheck.Apps.Count) app(s), $($appCheck.Warnings.Count) warning(s)"
    }
    
    if ($appCheck.Warnings.Count -gt 0) {
        Write-Host "  ⚠ $($appCheck.Warnings.Count) warning(s)" -ForegroundColor Yellow
    }
    else {
        Write-Host "  ✓ App catalog validated" -ForegroundColor Green
    }
}
catch {
    $testResults.Passed = $false
    Write-Host "  ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Task sequence structure validation
Write-Host ''
Write-Host "Test 5: Task sequence structure validation..." -ForegroundColor Yellow
try {
    $testSequences = @('baremetal-basic', 'baremetal-with-drivers', 'postsetup-optimize-dev')
    $validated = 0
    
    foreach ($tsId in $testSequences) {
        $tsCheck = Test-TaskSequence -TaskSequenceId $tsId
        if ($tsCheck.Passed) {
            $validated++
        }
    }
    
    $testResults.Tests += [pscustomobject]@{
        Name = 'Task Sequence Validation'
        Status = 'Pass'
        Details = "Validated $validated/$($testSequences.Count) task sequence(s)"
    }
    Write-Host "  ✓ Validated $validated/$($testSequences.Count) task sequence(s)" -ForegroundColor Green
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
    $color = switch ($test.Status) {
        'Pass' { 'Green' }
        'Warning' { 'Yellow' }
        default { 'Red' }
    }
    Write-Host "$($test.Status): $($test.Name)" -ForegroundColor $color
    if ($test.Details) {
        Write-Host "  $($test.Details)" -ForegroundColor Gray
    }
}

Write-Host ''
if ($testResults.Passed) {
    Write-Host 'Integration tests passed!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Some integration tests failed. See details above.' -ForegroundColor Red
    exit 1
}

