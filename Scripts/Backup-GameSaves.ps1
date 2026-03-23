<#
.SYNOPSIS
    Backs up game save files to a specified directory.

.DESCRIPTION
    Scans common game save locations and copies save files to a
    backup directory with timestamped folders. Supports custom
    save paths via a configuration file.

.PARAMETER BackupRoot
    Root directory for game save backups. Defaults to C:\Dev\Artifacts\GameSaveBackups.

.PARAMETER ConfigFile
    Path to a JSON config listing custom game save paths.
    Each entry: { "Game": "name", "Path": "save/path", "Pattern": "*.sav" }

.PARAMETER Game
    Back up saves for a specific game only.

.EXAMPLE
    .\Backup-GameSaves.ps1
    Backs up all known game save locations.

.EXAMPLE
    .\Backup-GameSaves.ps1 -Game "Minecraft"
    Backs up Minecraft saves only.

.EXAMPLE
    .\Backup-GameSaves.ps1 -ConfigFile "C:\Dev\Assets\gamesaves.json"
    Uses custom save path configuration.

.NOTES
    Author: C-Man
    Date:   2026-02-28
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$BackupRoot = "C:\Dev\Artifacts\GameSaveBackups",

    [Parameter()]
    [string]$ConfigFile,

    [Parameter()]
    [string]$Game
)

$ErrorActionPreference = 'Stop'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Game Save Backup" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Default known save locations
$defaultGames = @(
    @{ Game = 'Minecraft';       Path = "$env:APPDATA\.minecraft\saves";           Pattern = '*' }
    @{ Game = 'Terraria';        Path = "$env:USERPROFILE\Documents\My Games\Terraria\Worlds"; Pattern = '*' }
    @{ Game = 'Stardew Valley';  Path = "$env:APPDATA\StardewValley\Saves";       Pattern = '*' }
    @{ Game = 'Skyrim SE';       Path = "$env:USERPROFILE\Documents\My Games\Skyrim Special Edition\Saves"; Pattern = '*.ess' }
    @{ Game = 'Fallout 4';       Path = "$env:USERPROFILE\Documents\My Games\Fallout4\Saves"; Pattern = '*.fos' }
    @{ Game = 'Elden Ring';      Path = "$env:APPDATA\EldenRing";                 Pattern = '*' }
    @{ Game = 'Dark Souls III';  Path = "$env:APPDATA\DarkSoulsIII";              Pattern = '*' }
    @{ Game = 'Cyberpunk 2077';  Path = "$env:USERPROFILE\Saved Games\CD Projekt Red\Cyberpunk 2077"; Pattern = '*' }
    @{ Game = 'Witcher 3';       Path = "$env:USERPROFILE\Documents\The Witcher 3\gamesaves"; Pattern = '*' }
    @{ Game = 'Baldurs Gate 3';  Path = "$env:LOCALAPPDATA\Larian Studios\Baldur's Gate 3\PlayerProfiles"; Pattern = '*' }
)

# Load custom config if provided
$games = $defaultGames
if ($ConfigFile) {
    if (-not (Test-Path $ConfigFile)) {
        Write-Error "Config file not found: $ConfigFile"
    }
    $customGames = Get-Content $ConfigFile | ConvertFrom-Json
    $games = $customGames | ForEach-Object {
        @{ Game = $_.Game; Path = $_.Path; Pattern = if ($_.Pattern) { $_.Pattern } else { '*' } }
    }
}

# Filter to specific game
if ($Game) {
    $games = $games | Where-Object { $_.Game -like "*$Game*" }
    if (-not $games) {
        Write-Error "No game matching '$Game' found in configuration."
    }
}

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$totalFiles = 0
$totalSize = 0

foreach ($g in $games) {
    if (-not (Test-Path $g.Path)) {
        Write-Host "  [SKIP] $($g.Game) - save path not found" -ForegroundColor Gray
        continue
    }

    $files = Get-ChildItem -Path $g.Path -Filter $g.Pattern -Recurse -File -ErrorAction SilentlyContinue
    if (-not $files -or $files.Count -eq 0) {
        Write-Host "  [SKIP] $($g.Game) - no save files found" -ForegroundColor Gray
        continue
    }

    $backupDir = Join-Path $BackupRoot "$($g.Game)\$timestamp"
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

    $fileCount = 0
    $gameSize = 0
    foreach ($file in $files) {
        $relativePath = $file.FullName.Replace($g.Path, '').TrimStart('\')
        $destPath = Join-Path $backupDir $relativePath
        $destDir = Split-Path $destPath -Parent

        if (-not (Test-Path $destDir)) {
            New-Item -ItemType Directory -Path $destDir -Force | Out-Null
        }

        Copy-Item -Path $file.FullName -Destination $destPath -Force
        $fileCount++
        $gameSize += $file.Length
    }

    $sizeMB = [math]::Round($gameSize / 1MB, 2)
    Write-Host "  [DONE] $($g.Game) - $fileCount files ($sizeMB MB)" -ForegroundColor Green
    $totalFiles += $fileCount
    $totalSize += $gameSize
}

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Backup Summary" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
$totalMB = [math]::Round($totalSize / 1MB, 2)
Write-Host "  Files backed up: $totalFiles"
Write-Host "  Total size: $totalMB MB"
Write-Host "  Backup root: $BackupRoot"
Write-Host ""
