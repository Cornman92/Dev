<#
.SYNOPSIS
    Lists and switches Windows power plans.

.DESCRIPTION
    Displays available power plans and allows switching between them.
    Supports creating a custom high-performance plan for gaming or
    intensive workloads.

.PARAMETER Plan
    Name of the power plan to activate: 'Balanced', 'HighPerformance',
    'PowerSaver', or 'Ultimate'. Omit to list available plans.

.PARAMETER List
    List all available power plans and their status.

.EXAMPLE
    .\Set-PowerPlan.ps1 -List
    Shows all power plans.

.EXAMPLE
    .\Set-PowerPlan.ps1 -Plan HighPerformance
    Switches to the High Performance plan.

.NOTES
    Author: C-Man
    Date:   2026-02-28
    Requires: Run as Administrator for plan changes
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Balanced', 'HighPerformance', 'PowerSaver', 'Ultimate')]
    [string]$Plan,

    [Parameter()]
    [switch]$List
)

$ErrorActionPreference = 'Stop'

# Known plan GUIDs
$planGuids = @{
    'Balanced'        = '381b4222-f694-41f0-9685-ff5bb260df2e'
    'HighPerformance' = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
    'PowerSaver'      = 'a1841308-3541-4fab-bc81-f71556f20b4a'
    'Ultimate'        = 'e9a42b02-d5df-448d-aa00-03f14749eb61'
}

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Power Plan Manager" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Parse powercfg output for current plans
$rawOutput = powercfg /list 2>&1
$currentPlans = @()
$activeGuid = $null

foreach ($line in $rawOutput) {
    if ($line -match 'GUID:\s+([a-f0-9-]+)\s+\((.+?)\)(\s+\*)?$') {
        $guid = $Matches[1]
        $name = $Matches[2]
        $isActive = $null -ne $Matches[3]

        if ($isActive) { $activeGuid = $guid }

        $currentPlans += [PSCustomObject]@{
            Name     = $name
            GUID     = $guid
            Active   = $isActive
        }
    }
}

if ($List -or -not $Plan) {
    Write-Host "Available Power Plans:" -ForegroundColor White
    Write-Host ""

    foreach ($p in $currentPlans) {
        $marker = if ($p.Active) { '*' } else { ' ' }
        $color = if ($p.Active) { 'Green' } else { 'Gray' }
        Write-Host ("  $marker {0,-35} {1}" -f $p.Name, $p.GUID) -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "  * = currently active" -ForegroundColor Gray
    Write-Host ""
    return
}

# ---- Set Power Plan ----
$targetGuid = $planGuids[$Plan]

# Check if it exists
$existing = $currentPlans | Where-Object { $_.GUID -eq $targetGuid }

if (-not $existing) {
    # For Ultimate Performance, try to unhide it
    if ($Plan -eq 'Ultimate') {
        Write-Host "Ultimate Performance plan not found. Attempting to enable it..." -ForegroundColor Yellow
        powercfg /duplicatescheme $targetGuid 2>&1 | Out-Null

        # Refresh
        $rawOutput = powercfg /list 2>&1
        $existing = $rawOutput | Where-Object { $_ -match $targetGuid }
        if (-not $existing) {
            Write-Error "Ultimate Performance plan is not available on this system."
        }
    }
    else {
        Write-Error "Power plan '$Plan' (GUID: $targetGuid) not found on this system."
    }
}

Write-Host "Switching to: $Plan" -ForegroundColor Yellow
powercfg /setactive $targetGuid

# Verify
$verifyOutput = powercfg /getactivescheme
Write-Host "Active plan: $verifyOutput" -ForegroundColor Green
Write-Host ""
