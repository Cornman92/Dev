#Requires -Version 7.0

<#
.SYNOPSIS
    Better11 unified build script.
.DESCRIPTION
    Builds the complete Better11 solution, runs analyzers, and executes tests.
.PARAMETER Configuration
    Build configuration (Debug or Release).
.PARAMETER RunTests
    Execute all test suites after build.
.PARAMETER RunAnalyzers
    Run StyleCop and PSScriptAnalyzer.
#>
[CmdletBinding()]
param(
    [ValidateSet('Debug', 'Release')]
    [string]$Configuration = 'Debug',

    [switch]$RunTests,

    [switch]$RunAnalyzers
)

$ErrorActionPreference = 'Stop'
$rootDir = Split-Path -Parent $PSScriptRoot
$startTime = Get-Date

Write-Host "`n╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host '║     Better11 System Enhancement Suite        ║' -ForegroundColor Cyan
Write-Host '║     Unified Build Script                     ║' -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝`n" -ForegroundColor Cyan

# Step 1: Restore
Write-Host '► Step 1: Restoring NuGet packages...' -ForegroundColor Yellow
dotnet restore "$rootDir\Better11.sln" --verbosity quiet
if ($LASTEXITCODE -ne 0) { throw 'NuGet restore failed' }
Write-Host '  ✓ Packages restored' -ForegroundColor Green

# Step 2: Build
Write-Host '► Step 2: Building solution...' -ForegroundColor Yellow
dotnet build "$rootDir\Better11.sln" -c $Configuration --no-restore -v minimal
if ($LASTEXITCODE -ne 0) { throw 'Build failed' }
Write-Host '  ✓ Build succeeded' -ForegroundColor Green

# Step 3: Analyzers
if ($RunAnalyzers) {
    Write-Host '► Step 3: Running PSScriptAnalyzer...' -ForegroundColor Yellow
    $psaResults = Invoke-ScriptAnalyzer -Path "$rootDir\PowerShell" -Recurse `
        -Settings "$rootDir\config\PSScriptAnalyzerSettings.psd1" -ErrorAction SilentlyContinue
    if ($psaResults) {
        $psaResults | Format-Table -AutoSize
        Write-Warning "PSScriptAnalyzer found $($psaResults.Count) issue(s)"
    } else {
        Write-Host '  ✓ PSScriptAnalyzer: 0 issues' -ForegroundColor Green
    }
}

# Step 4: Tests
if ($RunTests) {
    Write-Host '► Step 4: Running xUnit tests...' -ForegroundColor Yellow
    dotnet test "$rootDir\Better11.sln" -c $Configuration --no-build `
        --collect:"XPlat Code Coverage" --results-directory "$rootDir\TestResults"
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Some xUnit tests failed' }

    Write-Host '► Step 5: Running Pester tests...' -ForegroundColor Yellow
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = "$rootDir\PowerShell\Modules"
    $pesterConfig.Run.Passthru = $true
    $pesterConfig.Output.Verbosity = 'Normal'
    $pesterResult = Invoke-Pester -Configuration $pesterConfig

    Write-Host "`n  Pester: $($pesterResult.PassedCount) passed, $($pesterResult.FailedCount) failed" `
        -ForegroundColor $(if ($pesterResult.FailedCount -gt 0) { 'Red' } else { 'Green' })
}

# Summary
$duration = (Get-Date) - $startTime
Write-Host "`n╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║  Build Complete: $($duration.ToString('mm\:ss'))                       ║" -ForegroundColor Cyan
Write-Host "║  Configuration: $Configuration                        ║" -ForegroundColor Cyan
Write-Host "╚══════════════════════════════════════════════╝`n" -ForegroundColor Cyan
