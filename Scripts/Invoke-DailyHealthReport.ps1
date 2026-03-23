<#
.SYNOPSIS
    Generates a daily system health report.

.DESCRIPTION
    Collects system uptime, disk usage, top memory-consuming processes,
    recent event log errors, and pending updates. Outputs an HTML or
    plain-text report to Artifacts/HealthReports/. Optionally registers
    as a Windows Scheduled Task for daily execution.

.PARAMETER OutputFormat
    Report format: 'Html' or 'Text'. Defaults to Html.

.PARAMETER OutputDir
    Directory for report files. Defaults to C:\Dev\Artifacts\HealthReports.

.PARAMETER RegisterTask
    Register a Windows Scheduled Task to run this report daily at the specified time.

.PARAMETER TaskTime
    Time for the scheduled task (HH:mm format). Defaults to 08:00.

.PARAMETER TopProcesses
    Number of top memory-consuming processes to include. Defaults to 10.

.EXAMPLE
    .\Invoke-DailyHealthReport.ps1
    Generates an HTML health report.

.EXAMPLE
    .\Invoke-DailyHealthReport.ps1 -OutputFormat Text
    Generates a plain-text report.

.EXAMPLE
    .\Invoke-DailyHealthReport.ps1 -RegisterTask -TaskTime "07:00"
    Registers a daily scheduled task at 7 AM.

.NOTES
    Author: C-Man
    Date:   2026-03-23
    Reuses: Get-SystemInfo, Write-Log
#>
[CmdletBinding()]
param(
    [Parameter()]
    [ValidateSet('Html', 'Text')]
    [string]$OutputFormat = 'Html',

    [Parameter()]
    [string]$OutputDir = "C:\Dev\Artifacts\HealthReports",

    [Parameter()]
    [switch]$RegisterTask,

    [Parameter()]
    [string]$TaskTime = "08:00",

    [Parameter()]
    [int]$TopProcesses = 10
)

$ErrorActionPreference = 'Stop'

# --- Register Scheduled Task Mode ---
if ($RegisterTask) {
    $scriptPath = $MyInvocation.MyCommand.Path
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -Daily -At $TaskTime
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

    Register-ScheduledTask -TaskName 'DailyHealthReport' -Action $action -Trigger $trigger -Settings $settings -Description 'Generates daily system health report' -Force

    Write-Host "Scheduled task 'DailyHealthReport' registered for daily execution at $TaskTime." -ForegroundColor Green
    return
}

# Ensure output directory
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$reportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Daily Health Report" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# --- Collect Data ---

# 1. System info
$os = Get-CimInstance -ClassName Win32_OperatingSystem
$cpu = Get-CimInstance -ClassName Win32_Processor | Select-Object -First 1
$cs = Get-CimInstance -ClassName Win32_ComputerSystem
$uptime = (Get-Date) - $os.LastBootUpTime
$uptimeStr = "{0}d {1}h {2}m" -f $uptime.Days, $uptime.Hours, $uptime.Minutes
$totalMemGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
$freeMemGB = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedMemPct = [math]::Round((1 - ($os.FreePhysicalMemory * 1KB / $cs.TotalPhysicalMemory)) * 100, 1)

Write-Host "  [OK] System info collected" -ForegroundColor Green

# 2. Disk usage
$disks = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
    [PSCustomObject]@{
        Drive    = $_.DeviceID
        SizeGB   = [math]::Round($_.Size / 1GB, 2)
        FreeGB   = [math]::Round($_.FreeSpace / 1GB, 2)
        UsedPct  = if ($_.Size -gt 0) { [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1) } else { 0 }
    }
}

Write-Host "  [OK] Disk usage collected" -ForegroundColor Green

# 3. Top memory processes
$topProcs = Get-Process | Sort-Object WorkingSet64 -Descending |
            Select-Object -First $TopProcesses |
            ForEach-Object {
                [PSCustomObject]@{
                    Name      = $_.ProcessName
                    PID       = $_.Id
                    MemoryMB  = [math]::Round($_.WorkingSet64 / 1MB, 1)
                    CPU_Sec   = [math]::Round($_.CPU, 1)
                }
            }

Write-Host "  [OK] Top processes collected" -ForegroundColor Green

# 4. Recent event log errors (last 24h)
$eventStartTime = (Get-Date).AddHours(-24)
$recentErrors = @()
foreach ($logName in @('Application', 'System')) {
    $events = Get-WinEvent -FilterHashtable @{
        LogName   = $logName
        StartTime = $eventStartTime
        Level     = 1..2
    } -MaxEvents 10 -ErrorAction SilentlyContinue

    if ($events) {
        $recentErrors += $events | ForEach-Object {
            [PSCustomObject]@{
                Log       = $logName
                Level     = switch ($_.Level) { 1 { 'Critical' } 2 { 'Error' } default { 'Unknown' } }
                Time      = $_.TimeCreated.ToString('yyyy-MM-dd HH:mm')
                Source    = $_.ProviderName
                Message   = if ($_.Message.Length -gt 100) { $_.Message.Substring(0, 100) + '...' } else { $_.Message }
            }
        }
    }
}

Write-Host "  [OK] Event log errors collected" -ForegroundColor Green

# --- Generate Report ---
if ($OutputFormat -eq 'Html') {
    $outputFile = Join-Path $OutputDir "HealthReport-$timestamp.html"

    $diskRows = ($disks | ForEach-Object {
        $color = if ($_.UsedPct -gt 90) { '#ff4444' } elseif ($_.UsedPct -gt 75) { '#ffaa00' } else { '#44cc44' }
        "<tr><td>$($_.Drive)</td><td>$($_.SizeGB) GB</td><td>$($_.FreeGB) GB</td><td style='color:$color'>$($_.UsedPct)%</td></tr>"
    }) -join "`n"

    $procRows = ($topProcs | ForEach-Object {
        "<tr><td>$($_.Name)</td><td>$($_.PID)</td><td>$($_.MemoryMB) MB</td><td>$($_.CPU_Sec)s</td></tr>"
    }) -join "`n"

    $eventRows = if ($recentErrors) {
        ($recentErrors | ForEach-Object {
            $color = if ($_.Level -eq 'Critical') { '#ff4444' } else { '#ffaa00' }
            "<tr><td>$($_.Log)</td><td style='color:$color'>$($_.Level)</td><td>$($_.Time)</td><td>$($_.Source)</td><td>$($_.Message)</td></tr>"
        }) -join "`n"
    }
    else {
        "<tr><td colspan='5' style='color:#44cc44'>No errors in the last 24 hours</td></tr>"
    }

    $html = @"
<!DOCTYPE html>
<html>
<head>
<title>Health Report - $reportDate</title>
<style>
body { font-family: 'Segoe UI', sans-serif; background: #1e1e1e; color: #ddd; padding: 20px; }
h1 { color: #4fc3f7; }
h2 { color: #81c784; border-bottom: 1px solid #444; padding-bottom: 5px; }
table { border-collapse: collapse; width: 100%; margin: 10px 0 20px 0; }
th, td { padding: 8px 12px; text-align: left; border: 1px solid #444; }
th { background: #333; color: #4fc3f7; }
tr:nth-child(even) { background: #2a2a2a; }
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin: 10px 0 20px 0; }
.info-item { background: #2a2a2a; padding: 10px 15px; border-radius: 4px; }
.label { color: #888; font-size: 0.85em; }
.value { font-size: 1.1em; font-weight: bold; }
</style>
</head>
<body>
<h1>System Health Report</h1>
<p>Generated: $reportDate | Host: $($env:COMPUTERNAME)</p>

<h2>System Overview</h2>
<div class="info-grid">
<div class="info-item"><div class="label">OS</div><div class="value">$($os.Caption)</div></div>
<div class="info-item"><div class="label">CPU</div><div class="value">$($cpu.Name.Trim())</div></div>
<div class="info-item"><div class="label">Uptime</div><div class="value">$uptimeStr</div></div>
<div class="info-item"><div class="label">Memory</div><div class="value">$freeMemGB / $totalMemGB GB ($usedMemPct% used)</div></div>
</div>

<h2>Disk Usage</h2>
<table>
<tr><th>Drive</th><th>Total</th><th>Free</th><th>Used %</th></tr>
$diskRows
</table>

<h2>Top $TopProcesses Processes by Memory</h2>
<table>
<tr><th>Process</th><th>PID</th><th>Memory</th><th>CPU Time</th></tr>
$procRows
</table>

<h2>Recent Errors (24h)</h2>
<table>
<tr><th>Log</th><th>Level</th><th>Time</th><th>Source</th><th>Message</th></tr>
$eventRows
</table>

</body>
</html>
"@

    $html | Set-Content -Path $outputFile -Encoding UTF8
}
else {
    $outputFile = Join-Path $OutputDir "HealthReport-$timestamp.txt"

    $lines = @()
    $lines += "=================================="
    $lines += "  System Health Report"
    $lines += "  Generated: $reportDate"
    $lines += "  Host: $($env:COMPUTERNAME)"
    $lines += "=================================="
    $lines += ""
    $lines += "--- System Overview ---"
    $lines += "  OS:      $($os.Caption)"
    $lines += "  CPU:     $($cpu.Name.Trim())"
    $lines += "  Uptime:  $uptimeStr"
    $lines += "  Memory:  $freeMemGB / $totalMemGB GB ($usedMemPct% used)"
    $lines += ""
    $lines += "--- Disk Usage ---"
    foreach ($d in $disks) {
        $lines += "  $($d.Drive)  $($d.SizeGB) GB total  |  $($d.FreeGB) GB free  |  $($d.UsedPct)% used"
    }
    $lines += ""
    $lines += "--- Top $TopProcesses Processes by Memory ---"
    foreach ($p in $topProcs) {
        $lines += ("  {0,-25} PID:{1,-8} {2,8} MB  CPU:{3}s" -f $p.Name, $p.PID, $p.MemoryMB, $p.CPU_Sec)
    }
    $lines += ""
    $lines += "--- Recent Errors (24h) ---"
    if ($recentErrors) {
        foreach ($e in $recentErrors) {
            $lines += "  [$($e.Level)] $($e.Time) [$($e.Log)] $($e.Source): $($e.Message)"
        }
    }
    else {
        $lines += "  No errors in the last 24 hours."
    }

    $lines -join "`r`n" | Set-Content -Path $outputFile -Encoding UTF8
}

Write-Host "  [DONE] Report saved: $outputFile" -ForegroundColor Green
Write-Host ""
