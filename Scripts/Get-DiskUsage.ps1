<#
.SYNOPSIS
    Analyzes and reports disk space usage.

.DESCRIPTION
    Scans local fixed drives and reports total, used, and free space.
    Optionally drills into a specific directory to find the largest
    files and subdirectories consuming the most space.

.PARAMETER DrillPath
    Optional path to analyze in detail. Shows top consumers.

.PARAMETER Top
    Number of largest items to display. Defaults to 20.

.PARAMETER MinSizeMB
    Minimum file size in MB to include in drill-down results. Defaults to 10.

.EXAMPLE
    .\Get-DiskUsage.ps1
    Reports space on all local fixed drives.

.EXAMPLE
    .\Get-DiskUsage.ps1 -DrillPath "C:\Users" -Top 15
    Shows the 15 largest items under C:\Users.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$DrillPath,

    [Parameter()]
    [int]$Top = 20,

    [Parameter()]
    [int]$MinSizeMB = 10
)

$ErrorActionPreference = 'Stop'

# ---- Drive Overview ----
Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Disk Space Overview" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

$drives = Get-CimInstance -ClassName Win32_LogicalDisk -Filter "DriveType=3"

foreach ($drive in $drives) {
    $totalGB = [math]::Round($drive.Size / 1GB, 2)
    $freeGB  = [math]::Round($drive.FreeSpace / 1GB, 2)
    $usedGB  = [math]::Round(($drive.Size - $drive.FreeSpace) / 1GB, 2)
    $usedPct = if ($drive.Size -gt 0) { [math]::Round(($drive.Size - $drive.FreeSpace) / $drive.Size * 100, 1) } else { 0 }

    # Color based on usage
    $color = if ($usedPct -ge 90) { 'Red' }
             elseif ($usedPct -ge 75) { 'Yellow' }
             else { 'Green' }

    Write-Host "Drive $($drive.DeviceID)" -ForegroundColor White
    Write-Host "  Total:  $totalGB GB" -ForegroundColor Gray
    Write-Host "  Used:   $usedGB GB ($usedPct%)" -ForegroundColor $color
    Write-Host "  Free:   $freeGB GB" -ForegroundColor Gray

    # Simple bar
    $barLength = 40
    $filledLength = [math]::Round($usedPct / 100 * $barLength)
    $emptyLength = $barLength - $filledLength
    $bar = "[" + ("=" * $filledLength) + (" " * $emptyLength) + "]"
    Write-Host "  $bar $usedPct%" -ForegroundColor $color
    Write-Host ""
}

# ---- Directory Drill-Down ----
if ($DrillPath) {
    if (-not (Test-Path $DrillPath)) {
        Write-Error "Path not found: $DrillPath"
    }

    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host "  Drill-Down: $DrillPath" -ForegroundColor Cyan
    Write-Host "=============================" -ForegroundColor Cyan
    Write-Host ""

    # Top directories by size
    Write-Host "Top $Top directories by size:" -ForegroundColor White
    Write-Host ""

    $dirs = Get-ChildItem -Path $DrillPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $size = (Get-ChildItem -Path $_.FullName -Recurse -File -ErrorAction SilentlyContinue |
                 Measure-Object -Property Length -Sum).Sum
        [PSCustomObject]@{
            Name   = $_.Name
            Path   = $_.FullName
            SizeMB = [math]::Round(($size / 1MB), 2)
            SizeGB = [math]::Round(($size / 1GB), 2)
        }
    } | Sort-Object SizeMB -Descending | Select-Object -First $Top

    foreach ($dir in $dirs) {
        $sizeDisplay = if ($dir.SizeGB -ge 1) { "$($dir.SizeGB) GB" } else { "$($dir.SizeMB) MB" }
        Write-Host ("  {0,-40} {1,10}" -f $dir.Name, $sizeDisplay) -ForegroundColor Gray
    }

    Write-Host ""

    # Top files by size
    Write-Host "Top $Top files over $MinSizeMB MB:" -ForegroundColor White
    Write-Host ""

    $files = Get-ChildItem -Path $DrillPath -Recurse -File -ErrorAction SilentlyContinue |
             Where-Object { $_.Length -ge ($MinSizeMB * 1MB) } |
             Sort-Object Length -Descending |
             Select-Object -First $Top

    foreach ($file in $files) {
        $sizeMB = [math]::Round($file.Length / 1MB, 2)
        $relativePath = $file.FullName.Replace($DrillPath, '.')
        Write-Host ("  {0,-60} {1,10} MB" -f $relativePath, $sizeMB) -ForegroundColor Gray
    }

    if (-not $files) {
        Write-Host "  No files larger than $MinSizeMB MB found." -ForegroundColor Yellow
    }
}

Write-Host ""
