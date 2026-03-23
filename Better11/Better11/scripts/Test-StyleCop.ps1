#Requires -Version 5.1
<#
.SYNOPSIS
    Validates zero StyleCop and analyzer violations.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$SolutionRoot = Split-Path $PSScriptRoot -Parent
$SolutionFile = Join-Path $SolutionRoot 'Better11.sln'

Write-Host "StyleCop Validation" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

# Build with TreatWarningsAsErrors
$output = dotnet build $SolutionFile --configuration Release --no-restore 2>&1
$exitCode = $LASTEXITCODE

$warnings = $output | Select-String -Pattern 'warning (SA|CS|CA|IDE)' | Measure-Object
$errors = $output | Select-String -Pattern 'error (SA|CS|CA|IDE)' | Measure-Object

Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow
Write-Host "  Analyzer warnings: $($warnings.Count)" -ForegroundColor $(if ($warnings.Count -eq 0) { 'Green' } else { 'Red' })
Write-Host "  Analyzer errors:   $($errors.Count)" -ForegroundColor $(if ($errors.Count -eq 0) { 'Green' } else { 'Red' })
Write-Host "  Build exit code:   $exitCode" -ForegroundColor $(if ($exitCode -eq 0) { 'Green' } else { 'Red' })

if ($exitCode -ne 0 -or $warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "VIOLATIONS FOUND:" -ForegroundColor Red
    $output | Select-String -Pattern 'warning (SA|CS|CA|IDE)|error (SA|CS|CA|IDE)' | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""
Write-Host "ZERO VIOLATIONS - All clear!" -ForegroundColor Green
