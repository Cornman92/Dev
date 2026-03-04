<#
.SYNOPSIS
    Summarizes recent Windows event log entries.

.DESCRIPTION
    Queries Application, System, and Security logs for recent errors,
    warnings, and critical events. Groups by source and provides a
    count-based summary for quick triage.

.PARAMETER Hours
    Number of hours to look back. Defaults to 24.

.PARAMETER LogName
    Specific log to query. Defaults to all three (Application, System, Security).

.PARAMETER Level
    Minimum severity level: Critical, Error, Warning, Information. Defaults to Warning.

.PARAMETER Top
    Number of top event sources to display. Defaults to 15.

.EXAMPLE
    .\Get-EventLogSummary.ps1
    Shows warnings and errors from the last 24 hours.

.EXAMPLE
    .\Get-EventLogSummary.ps1 -Hours 72 -Level Error
    Shows only errors from the last 3 days.

.EXAMPLE
    .\Get-EventLogSummary.ps1 -LogName System -Hours 12 -Top 10
    Shows top 10 System log issues from the last 12 hours.

.NOTES
    Author: C-Man
    Date:   2026-02-28
    Requires: Run as Administrator for Security log access
#>
[CmdletBinding()]
param(
    [Parameter()]
    [int]$Hours = 24,

    [Parameter()]
    [ValidateSet('Application', 'System', 'Security')]
    [string[]]$LogName = @('Application', 'System'),

    [Parameter()]
    [ValidateSet('Critical', 'Error', 'Warning', 'Information')]
    [string]$Level = 'Warning',

    [Parameter()]
    [int]$Top = 15
)

$ErrorActionPreference = 'SilentlyContinue'

# Map level names to numeric values (lower = more severe)
$levelMap = @{
    'Critical'    = 1
    'Error'       = 2
    'Warning'     = 3
    'Information' = 4
}
$maxLevel = $levelMap[$Level]

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Event Log Summary" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Time range: last $Hours hours"
Write-Host "  Logs: $($LogName -join ', ')"
Write-Host "  Min severity: $Level"
Write-Host ""

$startTime = (Get-Date).AddHours(-$Hours)

foreach ($log in $LogName) {
    Write-Host "--- $log Log ---" -ForegroundColor White
    Write-Host ""

    $events = Get-WinEvent -FilterHashtable @{
        LogName   = $log
        StartTime = $startTime
        Level     = 1..$maxLevel
    } -ErrorAction SilentlyContinue

    if (-not $events -or $events.Count -eq 0) {
        Write-Host "  No events found matching criteria." -ForegroundColor Green
        Write-Host ""
        continue
    }

    # Count by level
    $criticalCount = ($events | Where-Object { $_.Level -eq 1 }).Count
    $errorCount    = ($events | Where-Object { $_.Level -eq 2 }).Count
    $warningCount  = ($events | Where-Object { $_.Level -eq 3 }).Count

    $summaryColor = if ($criticalCount -gt 0) { 'Red' } elseif ($errorCount -gt 0) { 'Yellow' } else { 'White' }
    Write-Host "  Total: $($events.Count) events  |  Critical: $criticalCount  |  Errors: $errorCount  |  Warnings: $warningCount" -ForegroundColor $summaryColor
    Write-Host ""

    # Top sources
    Write-Host "  Top $Top sources:" -ForegroundColor Gray
    $topSources = $events | Group-Object ProviderName |
                  Sort-Object Count -Descending |
                  Select-Object -First $Top

    foreach ($source in $topSources) {
        $worstLevel = ($source.Group | Measure-Object -Property Level -Minimum).Minimum
        $color = switch ($worstLevel) {
            1 { 'Red' }
            2 { 'Yellow' }
            3 { 'DarkYellow' }
            default { 'Gray' }
        }
        Write-Host ("    {0,5}x  {1}" -f $source.Count, $source.Name) -ForegroundColor $color
    }
    Write-Host ""

    # Most recent critical/error events
    $recentSevere = $events | Where-Object { $_.Level -le 2 } | Select-Object -First 5
    if ($recentSevere) {
        Write-Host "  Recent errors/critical:" -ForegroundColor Gray
        foreach ($evt in $recentSevere) {
            $levelLabel = switch ($evt.Level) { 1 { 'CRIT' } 2 { 'ERR ' } default { 'WARN' } }
            $color = if ($evt.Level -eq 1) { 'Red' } else { 'Yellow' }
            $msgPreview = if ($evt.Message.Length -gt 80) { $evt.Message.Substring(0, 80) + '...' } else { $evt.Message }
            Write-Host ("    [{0}] {1} [{2}] {3}" -f $levelLabel, $evt.TimeCreated.ToString('MM/dd HH:mm'), $evt.ProviderName, $msgPreview) -ForegroundColor $color
        }
        Write-Host ""
    }
}
