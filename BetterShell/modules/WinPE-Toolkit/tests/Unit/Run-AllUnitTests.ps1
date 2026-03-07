# Run all Pester unit tests

[CmdletBinding()]
param(
    [Parameter()]
    [switch] $CodeCoverage,

    [Parameter()]
    [string] $OutputFormat = 'NUnitXml',

    [Parameter()]
    [string] $OutputFile
)

$ErrorActionPreference = 'Stop'

# Check if Pester is installed
if (-not (Get-Module -ListAvailable -Name Pester)) {
    Write-Host "Installing Pester module..." -ForegroundColor Yellow
    Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck
}

Import-Module Pester -MinimumVersion 5.0 -Force

$testPath = Join-Path $PSScriptRoot '*.Tests.ps1'
$tests = Get-ChildItem -Path $testPath

if ($tests.Count -eq 0) {
    Write-Host "No test files found in $testPath" -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($tests.Count) test file(s)" -ForegroundColor Cyan
Write-Host ''

$pesterConfig = New-PesterConfiguration
$pesterConfig.Run.Path = $PSScriptRoot
$pesterConfig.Run.PassThru = $true
$pesterConfig.Output.Verbosity = 'Detailed'

if ($CodeCoverage) {
    $modulePath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'src\Modules'
    $pesterConfig.CodeCoverage.Enabled = $true
    $pesterConfig.CodeCoverage.Path = "$modulePath\**\*.psm1"
    $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
    $pesterConfig.CodeCoverage.OutputPath = Join-Path $PSScriptRoot 'CodeCoverage.xml'
}

if ($OutputFormat -and $OutputFile) {
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputFormat = $OutputFormat
    $pesterConfig.TestResult.OutputPath = $OutputFile
}

$result = Invoke-Pester -Configuration $pesterConfig

Write-Host ''
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host '   Test Summary                             ' -ForegroundColor Cyan
Write-Host '=============================================' -ForegroundColor Cyan
Write-Host "Total: $($result.TotalCount)"
Write-Host "Passed: $($result.PassedCount)" -ForegroundColor Green
Write-Host "Failed: $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -gt 0) { 'Red' } else { 'Green' })
Write-Host "Skipped: $($result.SkippedCount)" -ForegroundColor Yellow

if ($CodeCoverage -and $result.CodeCoverage) {
    $coverage = [math]::Round($result.CodeCoverage.CoveragePercent, 2)
    Write-Host "Code Coverage: $coverage%" -ForegroundColor Cyan
}

if ($result.FailedCount -gt 0) {
    exit 1
}
else {
    exit 0
}

