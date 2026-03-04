<#
.SYNOPSIS
    Disables unnecessary Windows services for performance.

.DESCRIPTION
    Identifies and optionally disables Windows services that are
    typically unnecessary for desktop/gaming use. Creates a backup
    of current service states before making changes. Reversible.

.PARAMETER Apply
    Actually disable the services. Without this, only shows what would change.

.PARAMETER Restore
    Restore services from a previous backup file.

.PARAMETER BackupPath
    Path to save/load the service state backup. Defaults to Artifacts/.

.EXAMPLE
    .\Optimize-Services.ps1
    Preview which services would be disabled (dry run).

.EXAMPLE
    .\Optimize-Services.ps1 -Apply
    Disable unnecessary services (creates backup first).

.EXAMPLE
    .\Optimize-Services.ps1 -Restore
    Restore services from the most recent backup.

.NOTES
    Author: C-Man
    Date:   2026-02-28
    Requires: Run as Administrator
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [switch]$Apply,

    [Parameter()]
    [switch]$Restore,

    [Parameter()]
    [string]$BackupPath = "C:\Dev\Artifacts\ServiceBackup.json"
)

$ErrorActionPreference = 'Stop'

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin -and ($Apply -or $Restore)) {
    Write-Error "This script requires administrator privileges to modify services."
}

# Services safe to disable on most desktop/gaming systems
$targetServices = @(
    @{ Name = 'Fax';                      Reason = 'Fax service - rarely used' }
    @{ Name = 'lfsvc';                    Reason = 'Geolocation service' }
    @{ Name = 'MapsBroker';               Reason = 'Maps data broker' }
    @{ Name = 'RetailDemo';               Reason = 'Retail demo service' }
    @{ Name = 'WMPNetworkSvc';            Reason = 'Windows Media Player sharing' }
    @{ Name = 'XblAuthManager';           Reason = 'Xbox Live Auth Manager' }
    @{ Name = 'XblGameSave';              Reason = 'Xbox Live Game Save' }
    @{ Name = 'XboxGipSvc';               Reason = 'Xbox Accessory Management' }
    @{ Name = 'XboxNetApiSvc';            Reason = 'Xbox Live Networking' }
    @{ Name = 'WSearch';                  Reason = 'Windows Search indexer (CPU/disk heavy)' }
    @{ Name = 'SysMain';                  Reason = 'Superfetch/SysMain (can cause disk thrashing on HDDs)' }
    @{ Name = 'TabletInputService';       Reason = 'Touch keyboard/handwriting' }
    @{ Name = 'WbioSrvc';                 Reason = 'Windows Biometric Service' }
    @{ Name = 'wisvc';                    Reason = 'Windows Insider Service' }
)

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Service Optimizer" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# ---- Restore ----
if ($Restore) {
    if (-not (Test-Path $BackupPath)) {
        Write-Error "Backup file not found: $BackupPath"
    }

    Write-Host "Restoring services from: $BackupPath" -ForegroundColor Yellow
    $backup = Get-Content $BackupPath | ConvertFrom-Json

    foreach ($entry in $backup) {
        $svc = Get-Service -Name $entry.Name -ErrorAction SilentlyContinue
        if ($svc) {
            Set-Service -Name $entry.Name -StartupType $entry.StartType -ErrorAction SilentlyContinue
            if ($entry.WasRunning) {
                Start-Service -Name $entry.Name -ErrorAction SilentlyContinue
            }
            Write-Host "  [RESTORED] $($entry.Name) -> $($entry.StartType)" -ForegroundColor Green
        }
    }
    Write-Host ""
    Write-Host "Service restore complete." -ForegroundColor Green
    return
}

# ---- Audit / Apply ----
$backupData = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($target in $targetServices) {
    $svc = Get-Service -Name $target.Name -ErrorAction SilentlyContinue
    if (-not $svc) {
        Write-Host "  [SKIP] $($target.Name) - not found" -ForegroundColor Gray
        continue
    }

    $startType = (Get-CimInstance -ClassName Win32_Service -Filter "Name='$($target.Name)'" -ErrorAction SilentlyContinue).StartMode

    if ($svc.Status -eq 'Stopped' -and $startType -eq 'Disabled') {
        Write-Host "  [DONE] $($target.Name) - already disabled" -ForegroundColor Green
        continue
    }

    # Save backup entry
    $backupData.Add([PSCustomObject]@{
        Name       = $target.Name
        StartType  = $startType
        WasRunning = $svc.Status -eq 'Running'
    })

    if ($Apply) {
        if ($PSCmdlet.ShouldProcess($target.Name, "Disable ($($target.Reason))")) {
            Stop-Service -Name $target.Name -Force -ErrorAction SilentlyContinue
            Set-Service -Name $target.Name -StartupType Disabled -ErrorAction SilentlyContinue
            Write-Host "  [OFF] $($target.Name) - $($target.Reason)" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "  [WOULD DISABLE] $($target.Name) - $($target.Reason) (currently: $startType)" -ForegroundColor Cyan
    }
}

# Save backup if applying
if ($Apply -and $backupData.Count -gt 0) {
    $backupDir = Split-Path $BackupPath -Parent
    if (-not (Test-Path $backupDir)) {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
    }
    $backupData | ConvertTo-Json | Set-Content -Path $BackupPath -Encoding UTF8
    Write-Host ""
    Write-Host "  Backup saved: $BackupPath" -ForegroundColor Green
}

if (-not $Apply) {
    Write-Host ""
    Write-Host "  This was a dry run. Use -Apply to make changes." -ForegroundColor Yellow
}

Write-Host ""
