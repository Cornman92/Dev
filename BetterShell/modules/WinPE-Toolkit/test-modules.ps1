# Module Loading Test Script
# Tests that all deployment modules load correctly

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path $PSScriptRoot 'src\Modules'

# Add module path to PSModulePath for dependency resolution
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Module Loading Tests                     ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

$modules = @(
    'Deployment.Core',
    'Deployment.Imaging',
    'Deployment.TaskSequence',
    'Deployment.Drivers',
    'Deployment.Packages',
    'Deployment.Optimization',
    'Deployment.Health',
    'Deployment.Autounattend',
    'Deployment.Provisioning',
    'Deployment.UI'
)

$results = @()
$allPassed = $true

foreach ($moduleName in $modules) {
    $moduleDir = Join-Path $modulePath $moduleName
    $moduleFile = Join-Path $moduleDir "$moduleName.psd1"
    
    Write-Host "Testing module: $moduleName" -NoNewline
    
    try {
        if (-not (Test-Path $moduleFile)) {
            throw "Module file not found: $moduleFile"
        }
        
        # Import module by directory path to handle dependencies
        Import-Module $moduleDir -Force -ErrorAction Stop
        
        # Get exported functions
        $manifest = Import-PowerShellDataFile -Path $moduleFile
        $exportedFunctions = $manifest.FunctionsToExport
        
        Write-Host " - PASSED" -ForegroundColor Green
        Write-Host "  Exported functions: $($exportedFunctions.Count)" -ForegroundColor Gray
        
        $results += [pscustomobject]@{
            Module = $moduleName
            Status = 'PASSED'
            Functions = $exportedFunctions.Count
            Error = $null
        }
    }
    catch {
        Write-Host " - FAILED" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        
        $results += [pscustomobject]@{
            Module = $moduleName
            Status = 'FAILED'
            Functions = 0
            Error = $_.Exception.Message
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

Write-Host "Total modules tested: $($modules.Count)"
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Green' })
Write-Host ''

if ($allPassed) {
    Write-Host 'All modules loaded successfully!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Some modules failed to load. See errors above.' -ForegroundColor Red
    exit 1
}

