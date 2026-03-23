<#
.SYNOPSIS
    Manages game mods with enable/disable and backup support.

.DESCRIPTION
    Organizes mods in per-game directories with active/inactive subfolders.
    Supports enabling, disabling, listing, and backing up mod configurations.
    Configuration is driven by a JSON file.

.PARAMETER Game
    Name of the game to manage mods for.

.PARAMETER Enable
    Name or pattern of mod(s) to enable.

.PARAMETER Disable
    Name or pattern of mod(s) to disable.

.PARAMETER List
    List all mods for the specified game.

.PARAMETER Backup
    Create a backup of the current mod state for the specified game.

.PARAMETER Restore
    Restore mods from the most recent backup for the specified game.

.PARAMETER ConfigFile
    Path to mod manager configuration JSON. Defaults to C:\Dev\Assets\mod-config.json.

.EXAMPLE
    .\Invoke-ModManager.ps1 -Game "Skyrim" -List
    Lists all mods for Skyrim.

.EXAMPLE
    .\Invoke-ModManager.ps1 -Game "Skyrim" -Enable "SkyUI"
    Enables the SkyUI mod for Skyrim.

.EXAMPLE
    .\Invoke-ModManager.ps1 -Game "Skyrim" -Backup
    Backs up the current mod state.

.NOTES
    Author: C-Man
    Date:   2026-03-23
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string]$Game,

    [Parameter(ParameterSetName = 'Enable')]
    [string]$Enable,

    [Parameter(ParameterSetName = 'Disable')]
    [string]$Disable,

    [Parameter(ParameterSetName = 'List')]
    [switch]$List,

    [Parameter(ParameterSetName = 'Backup')]
    [switch]$Backup,

    [Parameter(ParameterSetName = 'Restore')]
    [switch]$Restore,

    [Parameter()]
    [string]$ConfigFile = "C:\Dev\Assets\mod-config.json"
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Mod Manager - $Game" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Load or create config
$defaultModRoot = "C:\Dev\Artifacts\Mods"
$config = $null

if (Test-Path $ConfigFile) {
    $config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
}

# Find game config or use default
$gameConfig = $null
if ($config -and $config.Games) {
    $gameConfig = $config.Games | Where-Object { $_.Name -like "*$Game*" } | Select-Object -First 1
}

$modRoot = if ($config -and $config.ModRoot) { $config.ModRoot } else { $defaultModRoot }
$gameDir = if ($gameConfig -and $gameConfig.ModPath) { $gameConfig.ModPath } else { Join-Path $modRoot $Game }
$activeDir = Join-Path $gameDir "active"
$inactiveDir = Join-Path $gameDir "inactive"
$backupDir = Join-Path $gameDir "backups"

# Ensure directories exist
foreach ($dir in @($activeDir, $inactiveDir, $backupDir)) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
}

# --- List Mode ---
if ($List -or (-not $Enable -and -not $Disable -and -not $Backup -and -not $Restore)) {
    $activeMods = Get-ChildItem -Path $activeDir -Directory -ErrorAction SilentlyContinue
    $inactiveMods = Get-ChildItem -Path $inactiveDir -Directory -ErrorAction SilentlyContinue

    Write-Host "  Active Mods ($($activeMods.Count)):" -ForegroundColor Green
    if ($activeMods) {
        foreach ($mod in $activeMods | Sort-Object Name) {
            $modSize = (Get-ChildItem -Path $mod.FullName -Recurse -File -ErrorAction SilentlyContinue |
                        Measure-Object -Property Length -Sum).Sum
            $sizeMB = [math]::Round($modSize / 1MB, 2)
            Write-Host ("    [ON]  {0,-35} {1,8} MB" -f $mod.Name, $sizeMB) -ForegroundColor Green
        }
    }
    else {
        Write-Host "    (none)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "  Inactive Mods ($($inactiveMods.Count)):" -ForegroundColor Yellow
    if ($inactiveMods) {
        foreach ($mod in $inactiveMods | Sort-Object Name) {
            $modSize = (Get-ChildItem -Path $mod.FullName -Recurse -File -ErrorAction SilentlyContinue |
                        Measure-Object -Property Length -Sum).Sum
            $sizeMB = [math]::Round($modSize / 1MB, 2)
            Write-Host ("    [OFF] {0,-35} {1,8} MB" -f $mod.Name, $sizeMB) -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "    (none)" -ForegroundColor Gray
    }

    Write-Host ""
    Write-Host "  Mod directory: $gameDir" -ForegroundColor Gray
    Write-Host ""
    return
}

# --- Enable Mode ---
if ($Enable) {
    $modsToEnable = Get-ChildItem -Path $inactiveDir -Directory -Filter "*$Enable*" -ErrorAction SilentlyContinue

    if (-not $modsToEnable) {
        Write-Host "  [WARN] No inactive mod matching '$Enable' found." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    foreach ($mod in $modsToEnable) {
        $dest = Join-Path $activeDir $mod.Name
        Move-Item -Path $mod.FullName -Destination $dest -Force
        Write-Host "  [ON]  Enabled: $($mod.Name)" -ForegroundColor Green
    }
    Write-Host ""
    return
}

# --- Disable Mode ---
if ($Disable) {
    $modsToDisable = Get-ChildItem -Path $activeDir -Directory -Filter "*$Disable*" -ErrorAction SilentlyContinue

    if (-not $modsToDisable) {
        Write-Host "  [WARN] No active mod matching '$Disable' found." -ForegroundColor Yellow
        Write-Host ""
        return
    }

    foreach ($mod in $modsToDisable) {
        $dest = Join-Path $inactiveDir $mod.Name
        Move-Item -Path $mod.FullName -Destination $dest -Force
        Write-Host "  [OFF] Disabled: $($mod.Name)" -ForegroundColor Yellow
    }
    Write-Host ""
    return
}

# --- Backup Mode ---
if ($Backup) {
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupTarget = Join-Path $backupDir $timestamp

    New-Item -ItemType Directory -Path $backupTarget -Force | Out-Null

    # Save state manifest
    $activeMods = Get-ChildItem -Path $activeDir -Directory -ErrorAction SilentlyContinue |
                  Select-Object -ExpandProperty Name
    $inactiveMods = Get-ChildItem -Path $inactiveDir -Directory -ErrorAction SilentlyContinue |
                    Select-Object -ExpandProperty Name

    $manifest = @{
        Game        = $Game
        Timestamp   = $timestamp
        ActiveMods  = @($activeMods)
        InactiveMods = @($inactiveMods)
    }

    $manifest | ConvertTo-Json -Depth 3 | Set-Content -Path (Join-Path $backupTarget "manifest.json") -Encoding UTF8

    # Copy active mods
    if ($activeMods) {
        $activeBackup = Join-Path $backupTarget "active"
        Copy-Item -Path $activeDir -Destination $activeBackup -Recurse -Force
    }

    Write-Host "  [DONE] Backup created: $backupTarget" -ForegroundColor Green
    Write-Host "  Active mods backed up: $($activeMods.Count)" -ForegroundColor White
    Write-Host ""
    return
}

# --- Restore Mode ---
if ($Restore) {
    $latestBackup = Get-ChildItem -Path $backupDir -Directory -ErrorAction SilentlyContinue |
                    Sort-Object Name -Descending |
                    Select-Object -First 1

    if (-not $latestBackup) {
        Write-Host "  [ERROR] No backups found for $Game." -ForegroundColor Red
        Write-Host ""
        return
    }

    $manifestPath = Join-Path $latestBackup.FullName "manifest.json"
    if (-not (Test-Path $manifestPath)) {
        Write-Host "  [ERROR] Backup manifest not found." -ForegroundColor Red
        Write-Host ""
        return
    }

    $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

    # Move all current mods to inactive
    Get-ChildItem -Path $activeDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $dest = Join-Path $inactiveDir $_.Name
        Move-Item -Path $_.FullName -Destination $dest -Force
    }

    # Re-enable mods from backup manifest
    foreach ($modName in $manifest.ActiveMods) {
        $source = Join-Path $inactiveDir $modName
        if (Test-Path $source) {
            $dest = Join-Path $activeDir $modName
            Move-Item -Path $source -Destination $dest -Force
            Write-Host "  [ON]  Restored: $modName" -ForegroundColor Green
        }
    }

    Write-Host ""
    Write-Host "  [DONE] Restored from backup: $($latestBackup.Name)" -ForegroundColor Green
    Write-Host ""
}
