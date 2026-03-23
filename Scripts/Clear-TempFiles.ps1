<#
.SYNOPSIS
    Cleans temporary files and system caches.

.DESCRIPTION
    Removes files from common temp directories, browser caches,
    and Windows temp locations. Supports a dry-run mode to preview
    what would be deleted and reports total space reclaimed.

.PARAMETER WhatIf
    Preview what would be deleted without actually removing files.

.PARAMETER IncludeBrowserCache
    Also clear browser cache directories (Edge, Chrome, Firefox).

.PARAMETER OlderThanDays
    Only delete temp files older than this many days. Defaults to 0 (all).

.EXAMPLE
    .\Clear-TempFiles.ps1 -WhatIf
    Shows what would be deleted without removing anything.

.EXAMPLE
    .\Clear-TempFiles.ps1
    Cleans all temp files.

.EXAMPLE
    .\Clear-TempFiles.ps1 -IncludeBrowserCache -OlderThanDays 7
    Cleans temp and browser cache files older than 7 days.

.NOTES
    Author: C-Man
    Date:   2026-02-28
    Requires: Run as Administrator for full cleanup
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$IncludeBrowserCache,

    [Parameter()]
    [int]$OlderThanDays = 0
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Temp File Cleaner" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

$totalFreed = 0
$totalFiles = 0

function Remove-TempDirectory {
    param(
        [string]$Path,
        [string]$Label,
        [int]$AgeDays
    )

    if (-not (Test-Path $Path)) {
        Write-Host "  [SKIP] $Label - path not found" -ForegroundColor Gray
        return
    }

    $cutoff = if ($AgeDays -gt 0) { (Get-Date).AddDays(-$AgeDays) } else { $null }

    $files = Get-ChildItem -Path $Path -Recurse -File -ErrorAction SilentlyContinue
    if ($cutoff) {
        $files = $files | Where-Object { $_.LastWriteTime -lt $cutoff }
    }

    $sizeBytes = ($files | Measure-Object -Property Length -Sum).Sum
    $sizeMB = [math]::Round($sizeBytes / 1MB, 2)
    $count = ($files | Measure-Object).Count

    if ($count -eq 0) {
        Write-Host "  [CLEAN] $Label - already clean" -ForegroundColor Green
        return
    }

    if ($PSCmdlet.ShouldProcess("$Label ($count files, $sizeMB MB)", "Delete")) {
        $files | Remove-Item -Force -ErrorAction SilentlyContinue
        # Clean empty directories
        Get-ChildItem -Path $Path -Recurse -Directory -ErrorAction SilentlyContinue |
            Sort-Object { $_.FullName.Length } -Descending |
            Where-Object { (Get-ChildItem $_.FullName -ErrorAction SilentlyContinue).Count -eq 0 } |
            Remove-Item -Force -ErrorAction SilentlyContinue

        Write-Host "  [DONE] $Label - removed $count files ($sizeMB MB)" -ForegroundColor Green
    }
    else {
        Write-Host "  [PREVIEW] $Label - would remove $count files ($sizeMB MB)" -ForegroundColor Yellow
    }

    $script:totalFreed += $sizeBytes
    $script:totalFiles += $count
}

# ---- Windows Temp Directories ----
Write-Host "Windows Temp:" -ForegroundColor White
Remove-TempDirectory -Path $env:TEMP -Label "User Temp ($env:TEMP)" -AgeDays $OlderThanDays
Remove-TempDirectory -Path "C:\Windows\Temp" -Label "System Temp (C:\Windows\Temp)" -AgeDays $OlderThanDays
Remove-TempDirectory -Path "$env:LOCALAPPDATA\Temp" -Label "Local App Temp" -AgeDays $OlderThanDays
Write-Host ""

# ---- Windows Prefetch ----
Write-Host "Windows Prefetch:" -ForegroundColor White
Remove-TempDirectory -Path "C:\Windows\Prefetch" -Label "Prefetch Cache" -AgeDays $OlderThanDays
Write-Host ""

# ---- Recycle Bin ----
Write-Host "Recycle Bin:" -ForegroundColor White
if ($PSCmdlet.ShouldProcess("Recycle Bin", "Empty")) {
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Host "  [DONE] Recycle Bin emptied" -ForegroundColor Green
    }
    catch {
        Write-Host "  [SKIP] Could not empty Recycle Bin: $_" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  [PREVIEW] Would empty Recycle Bin" -ForegroundColor Yellow
}
Write-Host ""

# ---- Browser Caches ----
if ($IncludeBrowserCache) {
    Write-Host "Browser Caches:" -ForegroundColor White

    $browserPaths = @{
        'Chrome'  = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        'Edge'    = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        'Firefox' = "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles"
    }

    foreach ($browser in $browserPaths.Keys) {
        Remove-TempDirectory -Path $browserPaths[$browser] -Label "$browser Cache" -AgeDays $OlderThanDays
    }
    Write-Host ""
}

# ---- Summary ----
$totalMB = [math]::Round($totalFreed / 1MB, 2)
$totalGB = [math]::Round($totalFreed / 1GB, 2)
$sizeDisplay = if ($totalGB -ge 1) { "$totalGB GB" } else { "$totalMB MB" }

Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Summary" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Files processed: $totalFiles" -ForegroundColor White
Write-Host "  Space reclaimed: $sizeDisplay" -ForegroundColor Green
Write-Host ""
