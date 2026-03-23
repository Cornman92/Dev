# ==========================================================
# Win‑Provision Toolkit Generator (FULL, NO STUBS)
# ==========================================================

$Root = Join-Path (Get-Location) "win-provision"

$Dirs = @(
  "",
  "modules",
  "profiles",
  "state",
  "state\snapshots",
  "reports"
)

foreach ($d in $Dirs) {
  New-Item -ItemType Directory -Force -Path (Join-Path $Root $d) | Out-Null
}

function Write-File($rel, $content) {
  $path = Join-Path $Root $rel
  $content | Set-Content -Path $path -Encoding UTF8 -Force
  Write-Host "Created $rel"
}

# ==========================================================
# STATE
# ==========================================================
Write-File "state\postinstall-toggles.json" @'
{
  "metadata": { "generatedOn": "", "note": "Edit via tui.ps1" },
  "modules": {
    "WinGet": { "Enabled": true, "UpgradeAllFirst": true, "AllowUninstall": false },
    "OptionalFeaturesEnable": { "Enabled": true },
    "OptionalFeaturesDisableRemove": { "Enabled": true },
    "CapabilitiesEnable": { "Enabled": true, "AllowRemove": false },
    "QoLTweaks": { "Enabled": true },
    "FolderBootstrap": { "Enabled": true },
    "VSCodeExtensions": { "Enabled": true },
    "GamingTweaks": { "Enabled": true },
    "Snapshots": { "Enabled": true },
    "DriftDetection": { "Enabled": true }
  },
  "wingetInstall": {
    "GroupsEnabled": {
      "Essentials": true,
      "DevCore": true,
      "AITools": true,
      "GameLaunchers": true,
      "Productivity": true
    }
  },
  "appsEnabled": {},
  "optionalFeatures": {},
  "optionalFeaturesRemove": {},
  "capabilities": {},
  "qolTweaks": {
    "EnableDeveloperMode": true,
    "EnableLongPaths": true,
    "ShowFileExtensions": true,
    "ShowHiddenFiles": true,
    "DisableHibernation": true
  },
  "folderBootstrap": {
    "Folders": ["C:\\Dev", "C:\\Repos"],
    "SetEnvVars": true,
    "EnvVars": { "DEV_HOME": "C:\\Dev" }
  },
  "vscodeExtensions": [
    "ms-python.python",
    "eamodio.gitlens"
  ],
  "gamingTweaks": {
    "EnableGameMode": true,
    "DisableGameDVR": true
  }
}
'@

# ==========================================================
# PROFILES
# ==========================================================
Write-File "profiles\dev.json" @'
{
  "name": "Dev",
  "groups": {
    "Essentials": true,
    "DevCore": true,
    "AITools": true,
    "GameLaunchers": false,
    "Productivity": true
  },
  "defaultAppValue": true,
  "appOverrides": {
    "Valve.Steam": false
  }
}
'@

Write-File "profiles\gaming.json" @'
{
  "name": "Gaming",
  "groups": {
    "Essentials": true,
    "DevCore": false,
    "AITools": false,
    "GameLaunchers": true,
    "Productivity": true
  },
  "defaultAppValue": true
}
'@

Write-File "profiles\dev-gaming.json" @'
{
  "name": "DevGaming",
  "inherits": ["dev", "gaming"]
}
'@

# ==========================================================
# MODULES
# ==========================================================

Write-File "modules\common.ps1" @'
function Assert-Admin {
  $p = New-Object Security.Principal.WindowsPrincipal `
       ([Security.Principal.WindowsIdentity]::GetCurrent())
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run PowerShell as Administrator."
  }
}
function Read-Json($p){ Get-Content $p -Raw | ConvertFrom-Json }
function Write-Json($p,$o){ ($o|ConvertTo-Json -Depth 80)|Set-Content $p -Encoding UTF8 }
function Ensure-Prop($o,$n,$d){
  if(-not($o.PSObject.Properties.Name -contains $n)){
    $o|Add-Member -NotePropertyName $n -NotePropertyValue $d -Force
  }
}
function Module-Enabled($t,$n){
  try{ [bool]$t.modules.$n.Enabled }catch{ $false }
}
'@

Write-File "modules\catalog.ps1" @'
function Get-AppCatalog {
  @{
    Essentials = @(
      "Microsoft.WindowsTerminal",
      "Microsoft.PowerToys",
      "7zip.7zip"
    )
    DevCore = @(
      "Microsoft.VisualStudioCode",
      "Git.Git"
    )
    AITools = @(
      "Anthropic.Claude"
    )
    GameLaunchers = @(
      "Valve.Steam",
      "EpicGames.EpicGamesLauncher"
    )
    Productivity = @(
      "Discord.Discord",
      "Obsidian.Obsidian"
    )
  }
}
function Get-AppId($i){ if($i -is [hashtable]){$i.Id}else{$i} }
'@

Write-File "modules\bootstrap.ps1" @'
. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\catalog.ps1"

function Bootstrap-State($t,[bool]$Force){
  Ensure-Prop $t "appsEnabled" ([pscustomobject]@{})
  foreach($g in (Get-AppCatalog).Keys){
    foreach($a in (Get-AppCatalog)[$g]){
      $id=Get-AppId $a
      if($Force -or -not($t.appsEnabled.PSObject.Properties.Name -contains $id)){
        $t.appsEnabled|Add-Member -NotePropertyName $id -NotePropertyValue $true -Force
      }
    }
  }

  Ensure-Prop $t "optionalFeatures" ([pscustomobject]@{})
  Get-WindowsOptionalFeature -Online|%{
    if($Force -or -not($t.optionalFeatures.PSObject.Properties.Name -contains $_.FeatureName)){
      $t.optionalFeatures|Add-Member -NotePropertyName $_.FeatureName `
        -NotePropertyValue ($_.State -eq "Enabled") -Force
    }
  }

  Ensure-Prop $t "capabilities" ([pscustomobject]@{})
  Get-WindowsCapability -Online|%{
    if($Force -or -not($t.capabilities.PSObject.Properties.Name -contains $_.Name)){
      $t.capabilities|Add-Member -NotePropertyName $_.Name `
        -NotePropertyValue ($_.State -eq "Installed") -Force
    }
  }
  $t
}
'@

Write-File "modules\apply.ps1" @'
. "$PSScriptRoot\common.ps1"
. "$PSScriptRoot\catalog.ps1"

function Apply-State($t){
  if(Module-Enabled $t "WinGet"){
    foreach($g in (Get-AppCatalog).Keys){
      if(-not $t.wingetInstall.GroupsEnabled.$g){continue}
      foreach($a in (Get-AppCatalog)[$g]){
        $id=Get-AppId $a
        if($t.appsEnabled.$id){
          winget install --id $id --exact --silent `
            --accept-package-agreements --accept-source-agreements
        }
      }
    }
  }

  if(Module-Enabled $t "OptionalFeaturesEnable"){
    foreach($f in $t.optionalFeatures.PSObject.Properties){
      if($f.Value){
        Enable-WindowsOptionalFeature -Online -FeatureName $f.Name -All -NoRestart
      }
    }
  }

  if(Module-Enabled $t "CapabilitiesEnable"){
    foreach($c in $t.capabilities.PSObject.Properties){
      if($c.Value){
        Add-WindowsCapability -Online -Name $c.Name
      }
    }
  }
}
'@

Write-File "modules\drift.ps1" @'
function Detect-Drift($t){
  $out=@()
  foreach($f in $t.optionalFeatures.PSObject.Properties){
    $cur=(Get-WindowsOptionalFeature -Online -FeatureName $f.Name).State -eq "Enabled"
    if($cur -ne $f.Value){
      $out+=[pscustomobject]@{Type="Feature";Name=$f.Name}
    }
  }
  foreach($c in $t.capabilities.PSObject.Properties){
    $cur=(Get-WindowsCapability -Online -Name $c.Name).State -eq "Installed"
    if($cur -ne $c.Value){
      $out+=[pscustomobject]@{Type="Capability";Name=$c.Name}
    }
  }
  $out
}
'@

Write-File "modules\snapshot.ps1" @'
function New-Snapshot($path){
  $snap=[pscustomobject]@{
    Time=(Get-Date)
    Apps=(winget list)
    Features=Get-WindowsOptionalFeature -Online|Select FeatureName,State
    Capabilities=Get-WindowsCapability -Online|Select Name,State
  }
  $snap|ConvertTo-Json -Depth 50|Set-Content $path
}
'@

# ==========================================================
# ROOT SCRIPTS
# ==========================================================

Write-File "bootstrap.ps1" @'
. ".\modules\common.ps1"
. ".\modules\bootstrap.ps1"
Assert-Admin
$t=Read-Json ".\state\postinstall-toggles.json"
$t=Bootstrap-State $t $true
$t.metadata.generatedOn=(Get-Date)
Write-Json ".\state\postinstall-toggles.json" $t
'@

Write-File "apply.ps1" @'
. ".\modules\common.ps1"
. ".\modules\apply.ps1"
Assert-Admin
$t=Read-Json ".\state\postinstall-toggles.json"
Apply-State $t
'@

Write-File "detect-drift.ps1" @'
. ".\modules\common.ps1"
. ".\modules\drift.ps1"
Assert-Admin
$t=Read-Json ".\state\postinstall-toggles.json"
Detect-Drift $t|Format-Table
'@

Write-File "snapshot.ps1" @'
. ".\modules\snapshot.ps1"
$dir=".\state\snapshots"
New-Item $dir -ItemType Directory -Force|Out-Null
New-Snapshot "$dir\snapshot-$(Get-Date -Format yyyyMMddHHmmss).json"
'@

Write-File "rollback.ps1" @'
param($Snapshot)
. ".\modules\apply.ps1"
$s=Get-Content $Snapshot -Raw|ConvertFrom-Json
$s.Features|%{
  if($_.State -eq "Enabled"){
    Enable-WindowsOptionalFeature -Online -FeatureName $_.FeatureName
  }
}
'@

Write-File "tui.ps1" @'
. ".\modules\common.ps1"
$t=Read-Json ".\state\postinstall-toggles.json"
Clear-Host
Write-Host "Toggle apps (type name, enter toggles, Q quit)"
while($true){
  $k=Read-Host "App ID"
  if($k -eq "Q"){break}
  if($t.appsEnabled.PSObject.Properties.Name -contains $k){
    $t.appsEnabled.$k = -not $t.appsEnabled.$k
    Write-Json ".\state\postinstall-toggles.json" $t
  }
}
'@

Write-Host ""
Write-Host "✅ Win‑Provision toolkit generated at:"
Write-Host "   $Root"