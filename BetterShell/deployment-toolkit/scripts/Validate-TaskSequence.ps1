# Validate-TaskSequence.ps1
# Validates task sequence structure and dependencies

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string] $TaskSequenceId
)

$ErrorActionPreference = 'Stop'
$modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

Import-Module Deployment.TaskSequence -Force
Import-Module Deployment.Validation -Force

Write-Host "Validating task sequence: $TaskSequenceId" -ForegroundColor Cyan
Write-Host ''

$result = Test-TaskSequence -TaskSequenceId $TaskSequenceId

Write-Host "Status: $($result.Status)" -ForegroundColor $(if ($result.Passed) { 'Green' } else { 'Red' })
Write-Host "Steps: $($result.StepCount)" -ForegroundColor White
Write-Host ''

if ($result.Errors.Count -gt 0) {
    Write-Host "Errors:" -ForegroundColor Red
    foreach ($error in $result.Errors) {
        Write-Host "  ✗ $error" -ForegroundColor Red
    }
    Write-Host ''
}

if ($result.Warnings.Count -gt 0) {
    Write-Host "Warnings:" -ForegroundColor Yellow
    foreach ($warning in $result.Warnings) {
        Write-Host "  ⚠ $warning" -ForegroundColor Yellow
    }
    Write-Host ''
}

if ($result.Passed) {
    Write-Host "Task sequence '$TaskSequenceId' is valid!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "Task sequence '$TaskSequenceId' has validation errors." -ForegroundColor Red
    exit 1
}

