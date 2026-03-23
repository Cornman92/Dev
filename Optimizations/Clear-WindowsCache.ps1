<#
.SYNOPSIS
    Clears various Windows system caches.

.DESCRIPTION
    Flushes DNS resolver cache, icon cache, font cache, thumbnail
    cache, and Windows Store cache. Useful for troubleshooting
    display issues or freeing disk space.

.PARAMETER All
    Clear all cache types. Default behavior.

.PARAMETER DnsOnly
    Only flush the DNS resolver cache.

.PARAMETER WhatIf
    Preview what would be cleared without applying.

.EXAMPLE
    .\Clear-WindowsCache.ps1
    Clears all system caches.

.EXAMPLE
    .\Clear-WindowsCache.ps1 -DnsOnly
    Only flushes the DNS cache.

.NOTES
    Author: C-Man
    Date:   2026-02-28
    Requires: Run as Administrator for full cache clearing
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$All,

    [Parameter()]
    [switch]$DnsOnly
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Windows Cache Cleaner" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# ---- DNS Cache ----
Write-Host "DNS Cache:" -ForegroundColor White
if ($PSCmdlet.ShouldProcess("DNS Resolver Cache", "Flush")) {
    ipconfig /flushdns 2>&1 | Out-Null
    Clear-DnsClientCache -ErrorAction SilentlyContinue
    Write-Host "  [DONE] DNS resolver cache flushed" -ForegroundColor Green
}
Write-Host ""

if ($DnsOnly) { return }

# ---- Thumbnail Cache ----
Write-Host "Thumbnail Cache:" -ForegroundColor White
$thumbPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
if ($PSCmdlet.ShouldProcess("Thumbnail cache", "Clear")) {
    $thumbFiles = Get-ChildItem -Path $thumbPath -Filter "thumbcache_*" -ErrorAction SilentlyContinue
    $thumbSize = ($thumbFiles | Measure-Object -Property Length -Sum).Sum
    $thumbFiles | Remove-Item -Force -ErrorAction SilentlyContinue
    $freedMB = [math]::Round($thumbSize / 1MB, 2)
    Write-Host "  [DONE] Cleared thumbnail cache ($freedMB MB)" -ForegroundColor Green
}
Write-Host ""

# ---- Icon Cache ----
Write-Host "Icon Cache:" -ForegroundColor White
if ($PSCmdlet.ShouldProcess("Icon cache", "Clear")) {
    $iconCache = "$env:LOCALAPPDATA\IconCache.db"
    $iconCacheDir = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache_*"
    Remove-Item $iconCache -Force -ErrorAction SilentlyContinue
    Remove-Item $iconCacheDir -Force -ErrorAction SilentlyContinue
    Write-Host "  [DONE] Icon cache cleared (rebuild on restart)" -ForegroundColor Green
}
Write-Host ""

# ---- Font Cache ----
Write-Host "Font Cache:" -ForegroundColor White
if ($PSCmdlet.ShouldProcess("Font cache service", "Restart")) {
    Stop-Service -Name 'FontCache' -Force -ErrorAction SilentlyContinue
    $fontCachePath = "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache"
    Remove-Item "$fontCachePath\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name 'FontCache' -ErrorAction SilentlyContinue
    Write-Host "  [DONE] Font cache cleared and service restarted" -ForegroundColor Green
}
Write-Host ""

# ---- Windows Store Cache ----
Write-Host "Windows Store Cache:" -ForegroundColor White
if ($PSCmdlet.ShouldProcess("Windows Store cache", "Reset")) {
    Start-Process 'wsreset.exe' -WindowStyle Hidden -Wait -ErrorAction SilentlyContinue
    Write-Host "  [DONE] Windows Store cache reset" -ForegroundColor Green
}
Write-Host ""

# ---- Windows Update Cache ----
Write-Host "Windows Update Cache:" -ForegroundColor White
if ($PSCmdlet.ShouldProcess("Windows Update cache", "Clear")) {
    Stop-Service -Name 'wuauserv' -Force -ErrorAction SilentlyContinue
    $wuPath = "C:\Windows\SoftwareDistribution\Download"
    $wuSize = (Get-ChildItem $wuPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item "$wuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name 'wuauserv' -ErrorAction SilentlyContinue
    $freedMB = [math]::Round($wuSize / 1MB, 2)
    Write-Host "  [DONE] Windows Update download cache cleared ($freedMB MB)" -ForegroundColor Green
}
Write-Host ""

Write-Host "Cache clearing complete." -ForegroundColor Green
Write-Host "A restart may be required for icon/font caches to fully rebuild." -ForegroundColor Gray
Write-Host ""
