# Task Sequence Loading Test Script

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Task Sequence Loading Tests              ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

Import-Module Deployment.TaskSequence -Force

$expectedSequences = @(
    'baremetal-basic',
    'baremetal-with-drivers',
    'postsetup-optimize-dev',
    'apps-dev-workstation'
)

$allPassed = $true
$results = @()

# Test Get-TaskSequenceCatalog
Write-Host 'Testing Get-TaskSequenceCatalog...' -ForegroundColor Yellow
try {
    $catalog = Get-TaskSequenceCatalog
    Write-Host "  Found $($catalog.Count) task sequence(s)" -ForegroundColor Green
    
    if ($catalog.Count -eq 0) {
        Write-Host '  WARNING: No task sequences found!' -ForegroundColor Yellow
        $allPassed = $false
    }
}
catch {
    Write-Host "  ERROR: $($_.Exception.Message)" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ''

# Test each expected sequence
foreach ($seqId in $expectedSequences) {
    Write-Host "Testing task sequence: $seqId" -NoNewline
    
    try {
        $ts = Get-TaskSequence -Id $seqId
        
        # Validate structure
        $errors = @()
        if (-not $ts.id) { $errors += 'Missing id' }
        if (-not $ts.name) { $errors += 'Missing name' }
        if (-not $ts.steps) { $errors += 'Missing steps array' }
        if ($ts.steps -isnot [System.Collections.IEnumerable]) { $errors += 'Steps is not an array' }
        
        if ($errors.Count -eq 0) {
            Write-Host " - PASSED" -ForegroundColor Green
            Write-Host "  Name: $($ts.name)" -ForegroundColor Gray
            Write-Host "  Steps: $($ts.steps.Count)" -ForegroundColor Gray
            
            $results += [pscustomobject]@{
                Id = $seqId
                Status = 'PASSED'
                Name = $ts.name
                StepCount = $ts.steps.Count
                Errors = $null
            }
        }
        else {
            Write-Host " - FAILED" -ForegroundColor Red
            Write-Host "  Errors: $($errors -join ', ')" -ForegroundColor Red
            
            $results += [pscustomobject]@{
                Id = $seqId
                Status = 'FAILED'
                Name = $null
                StepCount = 0
                Errors = ($errors -join ', ')
            }
            $allPassed = $false
        }
    }
    catch {
        Write-Host " - FAILED" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        
        $results += [pscustomobject]@{
            Id = $seqId
            Status = 'FAILED'
            Name = $null
            StepCount = 0
            Errors = $_.Exception.Message
        }
        $allPassed = $false
    }
}

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Test Summary                             ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$passed = ($results | Where-Object { $_.Status -eq 'PASSED' }).Count
$failed = ($results | Where-Object { $_.Status -eq 'FAILED' }).Count

Write-Host "Total sequences tested: $($expectedSequences.Count)"
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Green' })
Write-Host ''

if ($allPassed) {
    Write-Host 'All task sequences loaded and validated successfully!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Some task sequences failed validation. See errors above.' -ForegroundColor Red
    exit 1
}

