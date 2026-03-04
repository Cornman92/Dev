<#
.SYNOPSIS
    Parses FPS log files and calculates performance statistics.

.DESCRIPTION
    Reads FPS data from FrameView, FRAPS, MSI Afterburner, or
    generic CSV log files and computes min, max, average, 1% low,
    and 0.1% low frame rates. Supports multiple log formats.

.PARAMETER LogPath
    Path to the FPS log file or directory containing log files.

.PARAMETER Format
    Log format: 'Auto', 'FRAPS', 'FrameView', 'CSV'. Defaults to Auto.

.PARAMETER Column
    Column name or index containing FPS/frametime data in CSV files.

.PARAMETER FrameTime
    If specified, treats the data as frame times (ms) instead of FPS.

.EXAMPLE
    .\Get-FpsStats.ps1 -LogPath "C:\FPSLogs\benchmark.csv"
    Parses and displays FPS statistics.

.EXAMPLE
    .\Get-FpsStats.ps1 -LogPath "C:\FPSLogs" -Format FrameView
    Processes all FrameView logs in the directory.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$LogPath,

    [Parameter()]
    [ValidateSet('Auto', 'FRAPS', 'FrameView', 'CSV')]
    [string]$Format = 'Auto',

    [Parameter()]
    [string]$Column,

    [Parameter()]
    [switch]$FrameTime
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  FPS Statistics Analyzer" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Gather files
if (Test-Path $LogPath -PathType Container) {
    $files = Get-ChildItem -Path $LogPath -File -Filter "*.csv" -ErrorAction Stop
    if (-not $files) {
        $files = Get-ChildItem -Path $LogPath -File -Include "*.txt","*.log" -ErrorAction Stop
    }
}
else {
    $files = Get-Item $LogPath -ErrorAction Stop
}

if (-not $files -or $files.Count -eq 0) {
    Write-Error "No log files found at: $LogPath"
}

function Get-FpsFromData {
    param([double[]]$Values, [bool]$IsFrameTime)

    if ($IsFrameTime) {
        # Convert frame times (ms) to FPS
        $Values = $Values | Where-Object { $_ -gt 0 } | ForEach-Object { 1000.0 / $_ }
    }

    $sorted = $Values | Sort-Object
    $count = $sorted.Count

    if ($count -eq 0) { return $null }

    # Percentile calculations
    $onePercentIdx = [math]::Max(0, [math]::Floor($count * 0.01) - 1)
    $pointOnePercentIdx = [math]::Max(0, [math]::Floor($count * 0.001) - 1)

    return [PSCustomObject]@{
        Samples     = $count
        Average     = [math]::Round(($sorted | Measure-Object -Average).Average, 2)
        Median      = [math]::Round($sorted[[math]::Floor($count / 2)], 2)
        Min         = [math]::Round($sorted[0], 2)
        Max         = [math]::Round($sorted[-1], 2)
        OnePercLow  = [math]::Round($sorted[$onePercentIdx], 2)
        PointOneLow = [math]::Round($sorted[$pointOnePercentIdx], 2)
        StdDev      = [math]::Round(
            [math]::Sqrt(
                ($sorted | ForEach-Object {
                    $diff = $_ - ($sorted | Measure-Object -Average).Average
                    $diff * $diff
                } | Measure-Object -Average).Average
            ), 2)
    }
}

foreach ($file in $files) {
    Write-Host "File: $($file.Name)" -ForegroundColor White
    Write-Host ("-" * 50) -ForegroundColor Gray

    try {
        $content = Get-Content $file.FullName -ErrorAction Stop
        $fpsValues = @()

        # Auto-detect format
        $detectedFormat = $Format
        if ($Format -eq 'Auto') {
            $firstLine = $content[0]
            if ($firstLine -match 'MsBetweenPresents') { $detectedFormat = 'FrameView' }
            elseif ($firstLine -match 'Frame.*Time') { $detectedFormat = 'FRAPS' }
            else { $detectedFormat = 'CSV' }
        }

        switch ($detectedFormat) {
            'FrameView' {
                $csv = $content | ConvertFrom-Csv
                $colName = if ($Column) { $Column } else { 'MsBetweenPresents' }
                $fpsValues = $csv.$colName | Where-Object { $_ -match '^\d+\.?\d*$' } | ForEach-Object { [double]$_ }
                $FrameTime = $true
            }
            'FRAPS' {
                # FRAPS format: first column is frame number, second is time
                $lines = $content | Select-Object -Skip 1
                $fpsValues = $lines | Where-Object { $_ -match '^\d+' } | ForEach-Object {
                    $parts = $_ -split '\s*,\s*|\s+'
                    if ($parts.Count -ge 2) { [double]$parts[1] }
                } | Where-Object { $_ -gt 0 }
                $FrameTime = $true
            }
            'CSV' {
                $csv = $content | ConvertFrom-Csv
                if ($Column) {
                    $fpsValues = $csv.$Column | Where-Object { $_ -match '^\d+\.?\d*$' } | ForEach-Object { [double]$_ }
                }
                else {
                    # Try common column names
                    $possibleCols = @('FPS', 'fps', 'FrameRate', 'Framerate', 'MsBetweenPresents')
                    foreach ($col in $possibleCols) {
                        $vals = $csv.$col | Where-Object { $_ -match '^\d+\.?\d*$' }
                        if ($vals) {
                            $fpsValues = $vals | ForEach-Object { [double]$_ }
                            if ($col -match 'Ms|frametime') { $FrameTime = $true }
                            break
                        }
                    }
                }
            }
        }

        if ($fpsValues.Count -eq 0) {
            Write-Host "  No valid FPS data found in this file." -ForegroundColor Yellow
            Write-Host ""
            continue
        }

        $stats = Get-FpsFromData -Values $fpsValues -IsFrameTime:$FrameTime

        Write-Host "  Format:       $detectedFormat" -ForegroundColor Gray
        Write-Host "  Samples:      $($stats.Samples)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Average FPS:  $($stats.Average)" -ForegroundColor Green
        Write-Host "  Median FPS:   $($stats.Median)" -ForegroundColor Green
        Write-Host "  Min FPS:      $($stats.Min)" -ForegroundColor $(if ($stats.Min -lt 30) { 'Red' } else { 'Yellow' })
        Write-Host "  Max FPS:      $($stats.Max)" -ForegroundColor Green
        Write-Host "  1% Low:       $($stats.OnePercLow)" -ForegroundColor $(if ($stats.OnePercLow -lt 30) { 'Red' } else { 'Yellow' })
        Write-Host "  0.1% Low:     $($stats.PointOneLow)" -ForegroundColor $(if ($stats.PointOneLow -lt 20) { 'Red' } else { 'Yellow' })
        Write-Host "  Std Dev:      $($stats.StdDev)" -ForegroundColor Gray
    }
    catch {
        Write-Host "  Error parsing file: $_" -ForegroundColor Red
    }

    Write-Host ""
}
