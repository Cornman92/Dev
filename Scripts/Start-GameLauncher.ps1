<#
.SYNOPSIS
    Scans for installed games and provides a launcher interface.

.DESCRIPTION
    Discovers games from common install directories (Steam, Epic Games,
    GOG Galaxy, and custom paths). Lists installed games with metadata,
    supports launching by name, and tracks play sessions in a JSON catalog.

.PARAMETER Launch
    Name (or partial name) of the game to launch.

.PARAMETER Catalog
    Export the full game inventory to a JSON catalog file.

.PARAMETER ScanPaths
    Additional directories to scan for installed games.

.PARAMETER CatalogFile
    Path to the game catalog JSON. Defaults to C:\Dev\Assets\game-catalog.json.

.EXAMPLE
    .\Start-GameLauncher.ps1
    Lists all discovered games.

.EXAMPLE
    .\Start-GameLauncher.ps1 -Launch "Cyberpunk"
    Launches the first game matching "Cyberpunk".

.EXAMPLE
    .\Start-GameLauncher.ps1 -Catalog
    Exports full game inventory to the catalog file.

.NOTES
    Author: C-Man
    Date:   2026-03-23
#>
[CmdletBinding(DefaultParameterSetName = 'List')]
param(
    [Parameter(ParameterSetName = 'Launch', Position = 0)]
    [string]$Launch,

    [Parameter(ParameterSetName = 'Catalog')]
    [switch]$Catalog,

    [Parameter()]
    [string[]]$ScanPaths,

    [Parameter()]
    [string]$CatalogFile = "C:\Dev\Assets\game-catalog.json"
)

$ErrorActionPreference = 'SilentlyContinue'

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "  Game Launcher" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Default scan locations
$defaultPaths = @(
    "C:\Program Files (x86)\Steam\steamapps\common"
    "C:\Program Files\Epic Games"
    "C:\Program Files (x86)\GOG Galaxy\Games"
    "$env:LOCALAPPDATA\Programs"
    "D:\Games"
    "D:\SteamLibrary\steamapps\common"
    "E:\Games"
)

$allPaths = $defaultPaths
if ($ScanPaths) {
    $allPaths += $ScanPaths
}

# Discover games
$games = [System.Collections.Generic.List[PSCustomObject]]::new()

foreach ($scanPath in $allPaths) {
    if (-not (Test-Path $scanPath)) { continue }

    $dirs = Get-ChildItem -Path $scanPath -Directory -ErrorAction SilentlyContinue
    foreach ($dir in $dirs) {
        # Look for executables
        $exes = Get-ChildItem -Path $dir.FullName -Filter "*.exe" -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -notmatch '(?i)(unins|setup|install|crash|report|update|redist|vc_redist|dxsetup)' } |
                Sort-Object Length -Descending |
                Select-Object -First 1

        if (-not $exes) { continue }

        $sizeBytes = (Get-ChildItem -Path $dir.FullName -Recurse -File -ErrorAction SilentlyContinue |
                      Measure-Object -Property Length -Sum).Sum
        $sizeGB = [math]::Round($sizeBytes / 1GB, 2)

        # Determine store
        $store = 'Unknown'
        if ($scanPath -match 'Steam') { $store = 'Steam' }
        elseif ($scanPath -match 'Epic') { $store = 'Epic Games' }
        elseif ($scanPath -match 'GOG') { $store = 'GOG' }

        $games.Add([PSCustomObject]@{
            Name       = $dir.Name
            Path       = $dir.FullName
            Executable = $exes.FullName
            SizeGB     = $sizeGB
            Store      = $store
            LastPlayed = $null
            PlayTimeMin = 0
        })
    }
}

# Load existing catalog data (merge play history)
if (Test-Path $CatalogFile) {
    $existingCatalog = Get-Content $CatalogFile -Raw | ConvertFrom-Json
    foreach ($game in $games) {
        $existing = $existingCatalog | Where-Object { $_.Name -eq $game.Name }
        if ($existing) {
            $game.LastPlayed = $existing.LastPlayed
            $game.PlayTimeMin = $existing.PlayTimeMin
        }
    }
}

Write-Host "  Discovered $($games.Count) games across $($allPaths.Count) scan paths" -ForegroundColor Gray
Write-Host ""

# --- Launch Mode ---
if ($Launch) {
    $match = $games | Where-Object { $_.Name -like "*$Launch*" } | Select-Object -First 1

    if (-not $match) {
        Write-Host "  [ERROR] No game matching '$Launch' found." -ForegroundColor Red
        Write-Host ""
        return
    }

    Write-Host "  Launching: $($match.Name)" -ForegroundColor Green
    Write-Host "  Path: $($match.Executable)" -ForegroundColor Gray

    $startTime = Get-Date
    Start-Process -FilePath $match.Executable -WorkingDirectory (Split-Path $match.Executable -Parent)

    # Update play tracking
    $match.LastPlayed = $startTime.ToString('yyyy-MM-dd HH:mm:ss')

    # Save updated catalog
    $catalogDir = Split-Path $CatalogFile -Parent
    if (-not (Test-Path $catalogDir)) {
        New-Item -ItemType Directory -Path $catalogDir -Force | Out-Null
    }
    $games | ConvertTo-Json -Depth 3 | Set-Content -Path $CatalogFile -Encoding UTF8

    Write-Host "  Play session logged." -ForegroundColor Gray
    Write-Host ""
    return
}

# --- Catalog Export Mode ---
if ($Catalog) {
    $catalogDir = Split-Path $CatalogFile -Parent
    if (-not (Test-Path $catalogDir)) {
        New-Item -ItemType Directory -Path $catalogDir -Force | Out-Null
    }
    $games | ConvertTo-Json -Depth 3 | Set-Content -Path $CatalogFile -Encoding UTF8

    Write-Host "  Catalog exported to: $CatalogFile" -ForegroundColor Green
    Write-Host "  Total games: $($games.Count)" -ForegroundColor White
    Write-Host ""
    return
}

# --- List Mode (default) ---
if ($games.Count -eq 0) {
    Write-Host "  No games found. Try adding paths with -ScanPaths." -ForegroundColor Yellow
    Write-Host ""
    return
}

$games | Sort-Object Store, Name | ForEach-Object {
    $lastPlayed = if ($_.LastPlayed) { $_.LastPlayed } else { 'Never' }
    $storeTag = "[{0,-10}]" -f $_.Store
    Write-Host ("  {0} {1,-40} {2,7} GB  Last: {3}" -f $storeTag, $_.Name, $_.SizeGB, $lastPlayed) -ForegroundColor White
}

Write-Host ""
Write-Host "  Use -Launch '<name>' to start a game." -ForegroundColor Gray
Write-Host ""
