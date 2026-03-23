# TestHarness.ps1
# Main test runner for deployment toolkit scenarios

[CmdletBinding()]
param(
    [Parameter()]
    [string[]] $Scenarios,

    [Parameter()]
    [switch] $All,

    [Parameter()]
    [switch] $Detailed
)

$ErrorActionPreference = 'Stop'

$toolkitRoot = if ($PSScriptRoot) {
    Split-Path -Parent $PSScriptRoot
}
else {
    $PWD
}

$modulePath = Join-Path $toolkitRoot 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Better11 Deployment Toolkit Test Harness ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

# Discover test scenarios
$scenarioPath = Join-Path $toolkitRoot 'tests\Scenarios'
$availableScenarios = @()

if (Test-Path $scenarioPath) {
    $scenarioFiles = Get-ChildItem -Path $scenarioPath -Filter 'Test-*.ps1' -File
    $availableScenarios = $scenarioFiles | ForEach-Object { $_.BaseName }
}

# Determine which scenarios to run
$scenariosToRun = @()

if ($All) {
    $scenariosToRun = $availableScenarios
}
elseif ($Scenarios) {
    $scenariosToRun = $Scenarios
}
else {
    # Default: run all integration tests
    $scenariosToRun = @('FullDeploymentWorkflow', 'DriverInjection', 'AppInstallation', 'OptimizationWorkflow')
}

$testResults = @{
    Total = 0
    Passed = 0
    Failed = 0
    Warnings = 0
    Scenarios = @()
}

# Run integration tests
Write-Host "Running integration tests..." -ForegroundColor Yellow
Write-Host ''

$integrationPath = Join-Path $toolkitRoot 'tests\Integration'
if (Test-Path $integrationPath) {
    $integrationTests = @(
        'Test-FullDeploymentWorkflow',
        'Test-DriverInjection',
        'Test-AppInstallation',
        'Test-OptimizationWorkflow'
    )

    foreach ($test in $integrationTests) {
        $testFile = Join-Path $integrationPath "$test.ps1"
        if (Test-Path $testFile) {
            Write-Host "Running: $test" -ForegroundColor Cyan
            try {
                & $testFile
                $exitCode = $LASTEXITCODE
                
                $testResults.Total++
                if ($exitCode -eq 0) {
                    $testResults.Passed++
                    $testResults.Scenarios += [pscustomobject]@{
                        Name = $test
                        Status = 'Pass'
                        Details = 'Integration test passed'
                    }
                }
                else {
                    $testResults.Failed++
                    $testResults.Scenarios += [pscustomobject]@{
                        Name = $test
                        Status = 'Fail'
                        Details = "Exit code: $exitCode"
                    }
                }
            }
            catch {
                $testResults.Total++
                $testResults.Failed++
                $testResults.Scenarios += [pscustomobject]@{
                    Name = $test
                    Status = 'Error'
                    Details = $_.Exception.Message
                }
            }
            Write-Host ''
        }
    }
}

# Run scenario tests
if ($scenariosToRun.Count -gt 0 -and (Test-Path $scenarioPath)) {
    Write-Host "Running scenario tests..." -ForegroundColor Yellow
    Write-Host ''

    foreach ($scenario in $scenariosToRun) {
        $scenarioFile = Join-Path $scenarioPath "Test-$scenario.ps1"
        
        if (Test-Path $scenarioFile) {
            Write-Host "Running scenario: $scenario" -ForegroundColor Cyan
            try {
                & $scenarioFile
                $exitCode = $LASTEXITCODE
                
                $testResults.Total++
                if ($exitCode -eq 0) {
                    $testResults.Passed++
                    $testResults.Scenarios += [pscustomobject]@{
                        Name = $scenario
                        Status = 'Pass'
                        Details = 'Scenario test passed'
                    }
                }
                else {
                    $testResults.Failed++
                    $testResults.Scenarios += [pscustomobject]@{
                        Name = $scenario
                        Status = 'Fail'
                        Details = "Exit code: $exitCode"
                    }
                }
            }
            catch {
                $testResults.Total++
                $testResults.Failed++
                $testResults.Scenarios += [pscustomobject]@{
                    Name = $scenario
                    Status = 'Error'
                    Details = $_.Exception.Message
                }
            }
            Write-Host ''
        }
        else {
            Write-Host "Scenario not found: $scenario" -ForegroundColor Yellow
        }
    }
}

# Summary
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Test Harness Summary                     ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host ''

Write-Host "Total tests: $($testResults.Total)"
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) { 'Red' } else { 'Green' })
Write-Host ''

if ($Detailed -and $testResults.Scenarios.Count -gt 0) {
    Write-Host "Test results:" -ForegroundColor Cyan
    $testResults.Scenarios | Format-Table -AutoSize
    Write-Host ''
}

if ($testResults.Failed -eq 0) {
    Write-Host 'All tests passed!' -ForegroundColor Green
    exit 0
}
else {
    Write-Host 'Some tests failed. See details above.' -ForegroundColor Red
    exit 1
}

