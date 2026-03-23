# ================================
# Win Provision Toolkit Generator
# ================================

$Root = Join-Path (Get-Location) "win-provision"

$Dirs = @(
  "",
  "modules",
  "profiles",
  "state",
  "state\snapshots"
)

foreach ($d in $Dirs) {
  New-Item -ItemType Directory -Force -Path (Join-Path $Root $d) | Out-Null
}

function Write-File($relPath, $content) {
  $path = Join-Path $Root $relPath
  $content | Set-Content -Path $path -Encoding UTF8 -Force
  Write-Host "Created: $relPath"
}

# -------------------------------
# STATE (initial toggles)
# -------------------------------
Write-File "state\postinstall-toggles.json" @'
{
  "appsEnabled": {},
  "optionalFeatures": {},
  "optionalFeaturesRemove": {},
  "capabilities": {},
  "modules": {
    "WinGet": { "Enabled": true, "UpgradeAllFirst": true }
  }
}
'@

# -------------------------------
# PROFILES
# -------------------------------
Write-File "profiles\dev.json" @'
{
  "name": "Dev",
  "wingetGroups": ["Essentials", "DevCore"],
  "disableApps": ["Valve.Steam", "EpicGames.EpicGamesLauncher"]
}
'@

Write-File "profiles\gaming.json" @'
{
  "name": "Gaming",
  "wingetGroups": ["Essentials", "GameLaunchers"]
}
'@

Write-File "profiles\dev-gaming.json" @'
{
  "name": "DevGaming",
  "inherits": ["dev", "gaming"]
}
'@

# -------------------------------
# MODULES
# -------------------------------

Write-File "modules\apps.ps1" @'
function Apply-Apps($desired) {
  foreach ($app in $desired.appsEnabled.PSObject.Properties) {
    if ($app.Value) {
      winget install --id $app.Name --exact --silent --accept-package-agreements --accept-source-agreements
    }
  }
}

function Restore-AppsFromSnapshot($apps) {
  $current = winget list | Out-String
  foreach ($a in $apps) {
    if ($current -notmatch $a.Name) {
      winget install --id $a.Id --exact --silent --accept-package-agreements --accept-source-agreements
    }
  }
}
'@

Write-File "modules\optional-features.ps1" @'
function Apply-OptionalFeatures($desired) {
  foreach ($f in $desired.optionalFeatures.PSObject.Properties) {
    if ($f.Value) {
      Enable-WindowsOptionalFeature -Online -FeatureName $f.Name -All -NoRestart
    }
  }
}

function Restore-OptionalFeaturesFromSnapshot($snapshot) {
  foreach ($f in $snapshot) {
    if ($f.State -eq "Enabled") {
      Enable-WindowsOptionalFeature -Online -FeatureName $f.FeatureName -All -NoRestart
    } else {
      Disable-WindowsOptionalFeature -Online -FeatureName $f.FeatureName -NoRestart
    }
  }
}
'@

Write-File "modules\capabilities.ps1" @'
function Apply-Capabilities($desired) {
  foreach ($c in $desired.capabilities.PSObject.Properties) {
    if ($c.Value) {
      Add-WindowsCapability -Online -Name $c.Name -ErrorAction SilentlyContinue
    }
  }
}

function Restore-CapabilitiesFromSnapshot($snapshot) {
  foreach ($c in $snapshot) {
    if ($c.State -eq "Installed") {
      Add-WindowsCapability -Online -Name $c.Name -ErrorAction SilentlyContinue
    } else {
      Remove-WindowsCapability -Online -Name $c.Name -ErrorAction SilentlyContinue
    }
  }
}
'@

Write-File "modules\drift.ps1" @'
function Detect-FeatureDrift($desired) {
  Get-WindowsOptionalFeature -Online | Where-Object {
    $desired.optionalFeatures.$($_.FeatureName) -ne ($_.State -eq "Enabled")
  }
}

function Detect-CapabilityDrift($desired) {
  Get-WindowsCapability -Online | Where-Object {
    $desired.capabilities.$($_.Name) -ne ($_.State -eq "Installed")
  }
}
'@

Write-File "modules\snapshot.ps1" @'
function New-SystemSnapshot($path) {
  [pscustomobject]@{
    Timestamp = (Get-Date).ToString("s")
    Apps = winget list
    Features = Get-WindowsOptionalFeature -Online | Select FeatureName, State
    Capabilities = Get-WindowsCapability -Online | Select Name, State
  } | ConvertTo-Json -Depth 50 | Set-Content $path -Encoding UTF8
}
'@

# -------------------------------
# ROOT SCRIPTS
# -------------------------------

Write-File "snapshot.ps1" @'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$Root\modules\snapshot.ps1"
$SnapDir = Join-Path $Root "state\snapshots"
New-Item -ItemType Directory -Force -Path $SnapDir | Out-Null
$path = Join-Path $SnapDir ("snapshot-" + (Get-Date -Format "yyyyMMdd-HHmmss") + ".json")
New-SystemSnapshot $path
Write-Host "Snapshot created: $path"
'@

Write-File "rollback.ps1" @'
param([string]$Snapshot)
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$Root\modules\apps.ps1"
Import-Module "$Root\modules\optional-features.ps1"
Import-Module "$Root\modules\capabilities.ps1"
$s = Get-Content $Snapshot -Raw | ConvertFrom-Json
Restore-AppsFromSnapshot $s.Apps
Restore-OptionalFeaturesFromSnapshot $s.Features
Restore-CapabilitiesFromSnapshot $s.Capabilities
Write-Host "Rollback complete."
'@

Write-File "apply.ps1" @'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$Root\modules\apps.ps1"
Import-Module "$Root\modules\optional-features.ps1"
Import-Module "$Root\modules\capabilities.ps1"
$state = Get-Content "$Root\state\postinstall-toggles.json" -Raw | ConvertFrom-Json
Apply-Apps $state
Apply-OptionalFeatures $state
Apply-Capabilities $state
'@

Write-File "detect-drift.ps1" @'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$Root\modules\drift.ps1"
$state = Get-Content "$Root\state\postinstall-toggles.json" -Raw | ConvertFrom-Json
Detect-FeatureDrift $state
Detect-CapabilityDrift $state
'@

Write-File "bootstrap.ps1" @'
Write-Host "Bootstrap handled by previous versions."
'@

Write-File "tui.ps1" @'
Write-Host "Launch TUI from previous implementation."
'@

Write-Host ""
Write-Host "✅ Win Provision Toolkit generated successfully"
Write-Host "📁 Location: $Root"