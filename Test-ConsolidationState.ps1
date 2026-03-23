#Requires -Version 5.1
<#
.SYNOPSIS
    Verifies folders referenced by consolidate_workspace.ps1 exist in expected locations.

.DESCRIPTION
    Checks that source folders (BetterShell and BetterPE sources) either exist
    under D:\Dev (to be moved) or under BetterShell/BetterPE (already consolidated).
    Reports drift: missing sources or unexpected state.

.PARAMETER WorkspaceRoot
    Workspace root (default: D:\Dev).

.EXAMPLE
    .\Test-ConsolidationState.ps1
#>

[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string] $WorkspaceRoot = 'D:\Dev'
)

$ErrorActionPreference = 'Stop'

$betterShellSources = @(
    'platform', 'PowerShell', 'modules', 'deployment-toolkit', 'deployment',
    'scripts', 'ProfileMega', 'ConnorOS'
)
$betterPESources = @('My-WinPE-RE', 'DeployForge')

$baseDir = $WorkspaceRoot
$betterShellDir = Join-Path $baseDir 'BetterShell'
$betterPEDir = Join-Path $baseDir 'BetterPE'

$issues = @()
foreach ($name in $betterShellSources) {
    $atRoot = Test-Path -LiteralPath (Join-Path $baseDir $name) -PathType Container
    $atDest = Test-Path -LiteralPath (Join-Path $betterShellDir $name) -PathType Container
    if (-not $atRoot -and -not $atDest) {
        $issues += "BetterShell source missing everywhere: $name"
    } elseif ($atRoot -and $atDest) {
        $issues += "BetterShell source exists at both root and BetterShell: $name"
    }
}
foreach ($name in $betterPESources) {
    $atRoot = Test-Path -LiteralPath (Join-Path $baseDir $name) -PathType Container
    $atDest = Test-Path -LiteralPath (Join-Path $betterPEDir $name) -PathType Container
    if (-not $atRoot -and -not $atDest) {
        $issues += "BetterPE source missing everywhere: $name"
    } elseif ($atRoot -and $atDest) {
        $issues += "BetterPE source exists at both root and BetterPE: $name"
    }
}

if ($issues.Count -eq 0) {
    Write-Host "Consolidation state OK: no drift detected." -ForegroundColor Green
    exit 0
}
$issues | ForEach-Object { Write-Host $_ -ForegroundColor Yellow }
exit 1
