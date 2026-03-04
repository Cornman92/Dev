<#
.SYNOPSIS
    Monitors memory usage of specified processes.

.DESCRIPTION
    Watches one or more processes and reports memory consumption at
    a specified interval. Supports alerting when a threshold is
    exceeded. Useful for detecting memory leaks or high-usage apps.

.PARAMETER ProcessName
    One or more process names to monitor (without .exe).

.PARAMETER IntervalSeconds
    Polling interval in seconds. Defaults to 5.

.PARAMETER DurationMinutes
    Total monitoring duration in minutes. Defaults to 5. Use 0 for indefinite.

.PARAMETER ThresholdMB
    Alert threshold in MB. Prints a warning if a process exceeds this.

.PARAMETER OutputPath
    Optional CSV file to log all readings.

.EXAMPLE
    .\Watch-ProcessMemory.ps1 -ProcessName "chrome"
    Monitors Chrome memory usage for 5 minutes.

.EXAMPLE
    .\Watch-ProcessMemory.ps1 -ProcessName "code","pwsh" -ThresholdMB 500 -DurationMinutes 10
    Monitors VS Code and PowerShell for 10 minutes, alerting over 500 MB.

.NOTES
    Author: C-Man
    Date:   2026-02-28
    Press Ctrl+C to stop early.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string[]]$ProcessName,

    [Parameter()]
    [int]$IntervalSeconds = 5,

    [Parameter()]
    [int]$DurationMinutes = 5,

    [Parameter()]
    [int]$ThresholdMB = 0,

    [Parameter()]
    [string]$OutputPath
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Process Memory Monitor" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Watching: $($ProcessName -join ', ')"
Write-Host "  Interval: ${IntervalSeconds}s | Duration: $(if ($DurationMinutes -eq 0) { 'indefinite' } else { "${DurationMinutes}m" })"
if ($ThresholdMB -gt 0) { Write-Host "  Alert threshold: ${ThresholdMB} MB" -ForegroundColor Yellow }
Write-Host ""

$readings = [System.Collections.Generic.List[PSCustomObject]]::new()
$startTime = Get-Date
$endTime = if ($DurationMinutes -gt 0) { $startTime.AddMinutes($DurationMinutes) } else { [datetime]::MaxValue }

try {
    while ((Get-Date) -lt $endTime) {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

        foreach ($name in $ProcessName) {
            $procs = Get-Process -Name $name -ErrorAction SilentlyContinue

            if (-not $procs) {
                Write-Host "[$timestamp] $name - NOT RUNNING" -ForegroundColor Gray
                continue
            }

            $totalWorkingSetMB = [math]::Round(($procs | Measure-Object WorkingSet64 -Sum).Sum / 1MB, 2)
            $totalPrivateMB = [math]::Round(($procs | Measure-Object PrivateMemorySize64 -Sum).Sum / 1MB, 2)
            $instanceCount = $procs.Count

            $reading = [PSCustomObject]@{
                Timestamp      = $timestamp
                ProcessName    = $name
                Instances      = $instanceCount
                WorkingSetMB   = $totalWorkingSetMB
                PrivateMemMB   = $totalPrivateMB
            }
            $readings.Add($reading)

            # Color based on threshold
            $color = 'White'
            $alert = ''
            if ($ThresholdMB -gt 0 -and $totalWorkingSetMB -ge $ThresholdMB) {
                $color = 'Red'
                $alert = ' ** THRESHOLD EXCEEDED **'
            }

            Write-Host ("[$timestamp] {0,-20} Instances: {1,3}  WorkingSet: {2,8} MB  Private: {3,8} MB{4}" -f `
                $name, $instanceCount, $totalWorkingSetMB, $totalPrivateMB, $alert) -ForegroundColor $color
        }

        Start-Sleep -Seconds $IntervalSeconds
    }
}
catch {
    # Ctrl+C or other interruption
}
finally {
    Write-Host ""
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host "  Monitoring Complete" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan

    $elapsed = (Get-Date) - $startTime
    Write-Host "  Duration: $([math]::Round($elapsed.TotalMinutes, 1)) minutes"
    Write-Host "  Readings: $($readings.Count)"

    if ($OutputPath -and $readings.Count -gt 0) {
        $outputDir = Split-Path -Parent $OutputPath
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        $readings | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "  Log saved: $OutputPath" -ForegroundColor Green
    }

    Write-Host ""
}
