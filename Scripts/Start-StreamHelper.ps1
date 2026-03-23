<#
.SYNOPSIS
    Prepares the system for streaming or recording sessions.

.DESCRIPTION
    Optimizes system settings for streaming/recording by enabling Game Mode,
    switching to a high-performance power plan, killing non-essential background
    processes, and optionally sending OBS scene change commands. Use -Stop to
    restore defaults after a stream.

.PARAMETER Start
    Begin stream optimizations (default action).

.PARAMETER Stop
    Restore default settings after streaming.

.PARAMETER KillList
    Additional process names to terminate during stream setup.

.PARAMETER KeepList
    Process names that should never be killed.

.PARAMETER ObsProfile
    OBS profile name to switch to (requires OBS WebSocket or CLI).

.PARAMETER ObsScene
    OBS scene name to switch to (requires OBS WebSocket or CLI).

.EXAMPLE
    .\Start-StreamHelper.ps1
    Applies all streaming optimizations.

.EXAMPLE
    .\Start-StreamHelper.ps1 -Stop
    Restores default settings after streaming.

.EXAMPLE
    .\Start-StreamHelper.ps1 -KillList "Discord","Spotify"
    Starts stream mode and also kills Discord and Spotify.

.NOTES
    Author: C-Man
    Date:   2026-03-23
#>
[CmdletBinding(DefaultParameterSetName = 'Start')]
param(
    [Parameter(ParameterSetName = 'Start')]
    [switch]$Start,

    [Parameter(ParameterSetName = 'Stop')]
    [switch]$Stop,

    [Parameter()]
    [string[]]$KillList,

    [Parameter()]
    [string[]]$KeepList = @('explorer', 'svchost', 'csrss', 'smss', 'lsass', 'services', 'System', 'wininit', 'dwm', 'obs64', 'obs32', 'obs'),

    [Parameter()]
    [string]$ObsProfile,

    [Parameter()]
    [string]$ObsScene
)

$ErrorActionPreference = 'SilentlyContinue'

# Default non-essential processes to kill during streaming
$defaultKillTargets = @(
    'OneDrive'
    'SearchUI'
    'SearchApp'
    'YourPhone'
    'PhoneExperienceHost'
    'GameBarPresenceWriter'
    'Microsoft.Photos'
    'CalculatorApp'
    'HxTsr'
    'HxOutlook'
    'SkypeApp'
    'Cortana'
    'MicrosoftEdgeUpdate'
    'GoogleUpdate'
    'AdobeARM'
    'jusched'
)

Write-Host ""
Write-Host "=============================" -ForegroundColor Magenta
Write-Host "  Stream Helper" -ForegroundColor Magenta
Write-Host "=============================" -ForegroundColor Magenta
Write-Host ""

if ($Stop) {
    # --- Restore Defaults ---
    Write-Host "  Restoring default settings..." -ForegroundColor Yellow
    Write-Host ""

    # Restore Game Mode defaults
    $gameModeRegPath = 'HKCU:\SOFTWARE\Microsoft\GameBar'
    $gameDvrPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'

    Set-ItemProperty -Path $gameModeRegPath -Name 'AutoGameModeEnabled' -Value 0 -Type DWord
    Write-Host "  [OFF] Game Mode" -ForegroundColor Yellow

    Set-ItemProperty -Path $gameModeRegPath -Name 'UseNexusForGameBarEnabled' -Value 1 -Type DWord
    Write-Host "  [ON]  Game Bar Overlay" -ForegroundColor Green

    Set-ItemProperty -Path $gameDvrPath -Name 'AppCaptureEnabled' -Value 1 -Type DWord
    Write-Host "  [ON]  Game DVR Recording" -ForegroundColor Green

    # Restore Balanced power plan
    $balancedGuid = '381b4222-f694-41f0-9685-ff5bb260df2e'
    powercfg /setactive $balancedGuid 2>&1 | Out-Null
    Write-Host "  [SET] Power Plan: Balanced" -ForegroundColor Green

    # Re-enable Windows Search
    Start-Service -Name 'WSearch' -ErrorAction SilentlyContinue
    Write-Host "  [ON]  Windows Search" -ForegroundColor Green

    Write-Host ""
    Write-Host "  Defaults restored. Stream mode OFF." -ForegroundColor Green
    Write-Host ""
    return
}

# --- Stream Start Mode ---
Write-Host "  Optimizing for streaming..." -ForegroundColor Yellow
Write-Host ""

# 1. Enable Game Mode + disable overlays
$gameModeRegPath = 'HKCU:\SOFTWARE\Microsoft\GameBar'
$gameDvrPath = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR'

Set-ItemProperty -Path $gameModeRegPath -Name 'AutoGameModeEnabled' -Value 1 -Type DWord
Write-Host "  [ON]  Game Mode" -ForegroundColor Green

Set-ItemProperty -Path $gameModeRegPath -Name 'UseNexusForGameBarEnabled' -Value 0 -Type DWord
Write-Host "  [OFF] Game Bar Overlay" -ForegroundColor Yellow

Set-ItemProperty -Path $gameDvrPath -Name 'AppCaptureEnabled' -Value 0 -Type DWord
Write-Host "  [OFF] Background Game DVR" -ForegroundColor Yellow

# 2. High Performance power plan
$highPerfGuid = '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'
powercfg /setactive $highPerfGuid 2>&1 | Out-Null
Write-Host "  [SET] Power Plan: High Performance" -ForegroundColor Green

# 3. Stop non-essential services
Stop-Service -Name 'WSearch' -Force -ErrorAction SilentlyContinue
Write-Host "  [OFF] Windows Search (frees disk I/O)" -ForegroundColor Yellow

# 4. Kill non-essential processes
$killTargets = $defaultKillTargets
if ($KillList) { $killTargets += $KillList }

$killed = 0
foreach ($procName in $killTargets) {
    if ($procName -in $KeepList) { continue }

    $procs = Get-Process -Name $procName -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        $killed++
    }
}
Write-Host "  [KILL] Stopped $killed non-essential process groups" -ForegroundColor Yellow

# 5. Show memory freed
$availableMemGB = [math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory / 1MB, 2)
Write-Host "  [INFO] Available RAM: $availableMemGB GB" -ForegroundColor Gray

# 6. OBS integration (if specified)
if ($ObsProfile -or $ObsScene) {
    $obsCliPath = Get-Command 'obs-cli' -ErrorAction SilentlyContinue
    if ($obsCliPath) {
        if ($ObsProfile) {
            & obs-cli profile set --name $ObsProfile 2>&1 | Out-Null
            Write-Host "  [OBS] Profile: $ObsProfile" -ForegroundColor Magenta
        }
        if ($ObsScene) {
            & obs-cli scene switch --name $ObsScene 2>&1 | Out-Null
            Write-Host "  [OBS] Scene: $ObsScene" -ForegroundColor Magenta
        }
    }
    else {
        Write-Host "  [SKIP] OBS CLI not found. Install obs-cli or use OBS WebSocket." -ForegroundColor Gray
    }
}

# 7. Set process priority for OBS
$obsProcess = Get-Process -Name 'obs64', 'obs32', 'obs' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($obsProcess) {
    $obsProcess.PriorityClass = 'AboveNormal'
    Write-Host "  [SET] OBS process priority: Above Normal" -ForegroundColor Magenta
}

Write-Host ""
Write-Host "  Stream mode ON. Use -Stop to restore defaults." -ForegroundColor Green
Write-Host ""
