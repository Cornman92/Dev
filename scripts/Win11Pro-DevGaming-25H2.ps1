<#
Win11Pro-DevGaming-25H2.ps1
Everything added is toggle-controlled via C:\ProgramData\PostInstall\postinstall-toggles.json

- WinGet usage & install flags [6](https://svrooij.io/2022/02/18/winget/)[7](https://community.fabric.microsoft.com/t5/Fabric-Ideas/winget-upgrade-id-Microsoft-PowerBI/idi-p/4505089)
- VS Code CLI extension installation [1](https://www.greghilston.com/post/windows-11-install-and-configure/)[2](https://lpndev.github.io/wpis/)[3](https://github.com/reinaldogpn/windows-post-install)
- DISM optional feature enable/disable concepts, including TFTP [4](https://github.com/Homebrew/brew/blob/main/docs/Brew-Bundle-and-Brewfile.md)[5](https://miguelcrespo.co/posts/automate-installation-and-configuration-of-macos/)
#>

#region Config
$Config = [ordered]@{
  LogRoot        = "$env:ProgramData\PostInstall"
  TranscriptName = "postinstall-transcript.txt"
  ToggleFilePath = "$env:ProgramData\PostInstall\postinstall-toggles.json"

  # WinGet
  WingetSource    = "winget"

  # Apps (WinGet IDs)
  Apps = @{
    Essentials = @(
      "Microsoft.WindowsTerminal",
      "Microsoft.PowerToys",
      "7zip.7zip",
      @{ Id="Git.Git"; Scope="machine"; Silent=$true },
      "Notepad++.Notepad++",
      "Mozilla.Firefox",
      "VideoLAN.VLC",
      "voidtools.Everything"
    )
    DevCore = @(
      "Microsoft.VisualStudioCode",
      "ZedIndustries.Zed",
      "Microsoft.VisualStudio.2022.Community",
      "Microsoft.VisualStudio.2022.BuildTools",
      "Microsoft.DotNet.SDK.8",
      "OpenJS.NodeJS.LTS",
      "GitHub.cli",
      "GitHub.GitHubDesktop",
      "Docker.DockerDesktop"
    )
    AITools = @(
      "Anthropic.Claude",
      "Anthropic.ClaudeCode",
      "Anysphere.Cursor",
      "Codeium.Windsurf",
      "Google.Antigravity"
    )
    GameLaunchers = @(
      "Valve.Steam",
      "Blizzard.BattleNet",
      "Ubisoft.Connect",
      "ElectronicArts.EADesktop",
      "EpicGames.EpicGamesLauncher",
      "GOG.Galaxy"
    )
    Productivity = @(
      "Discord.Discord",
      "SlackTechnologies.Slack",
      "Postman.Postman",
      "ShareX.ShareX",
      "OBSProject.OBSStudio",
      "Obsidian.Obsidian"
    )
  }
}
#endregion Config

#region Helpers
$ErrorActionPreference = "Stop"

function Assert-Admin {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p  = New-Object Security.Principal.WindowsPrincipal($id)
  if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Run in an elevated (Administrator) PowerShell/Terminal."
  }
}

function Start-Logging {
  New-Item -ItemType Directory -Force -Path $Config.LogRoot | Out-Null
  $transcriptPath = Join-Path $Config.LogRoot $Config.TranscriptName
  Start-Transcript -Path $transcriptPath -Append | Out-Null
  Write-Host "Logging to $transcriptPath"
}

function Stop-Logging { Stop-Transcript | Out-Null }

function Ensure-WinGet {
  if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "winget not found. WinGet ships via App Installer on Windows 11. [6](https://svrooij.io/2022/02/18/winget/)"
  }
}

function Read-Toggles {
  if (-not (Test-Path $Config.ToggleFilePath)) {
    throw "Toggle file not found: $($Config.ToggleFilePath). Create it using the JSON template I provided."
  }
  return (Get-Content $Config.ToggleFilePath -Raw | ConvertFrom-Json)
}

function ModuleEnabled($t, $name) {
  try { return [bool]$t.modules.$name.Enabled } catch { return $false }
}

function Winget-Show([string]$Id) {
  & winget show --id $Id --exact --source $Config.WingetSource 2>$null
  return ($LASTEXITCODE -eq 0)
}

function Winget-InstallOne($item) {
  $id = $item
  $scope = "machine"
  $silent = $true

  if ($item -is [hashtable]) {
    $id = $item.Id
    if ($item.ContainsKey("Scope"))  { $scope  = $item.Scope }
    if ($item.ContainsKey("Silent")) { $silent = [bool]$item.Silent }
  }

  if (-not (Winget-Show $id)) {
    Write-Host "Skipping (not found in winget source): $id" -ForegroundColor Yellow
    return
  }

  $args = @("install","--id",$id,"--exact","--source",$Config.WingetSource,
            "--accept-source-agreements","--accept-package-agreements")
  if ($silent) { $args += "--silent" }  # supported [7](https://community.fabric.microsoft.com/t5/Fabric-Ideas/winget-upgrade-id-Microsoft-PowerBI/idi-p/4505089)
  if ($scope)  { $args += @("--scope",$scope) }

  Write-Host "Installing: $id (scope=$scope, silent=$silent)"
  & winget @args
}

function Winget-UpgradeAll {
  & winget upgrade --all --source $Config.WingetSource --accept-source-agreements --accept-package-agreements
}

function Get-OptionalFeatures { Get-WindowsOptionalFeature -Online | Select-Object FeatureName, State }
function Get-Capabilities     { Get-WindowsCapability -Online     | Select-Object Name, State }
function Get-Packages         { Get-WindowsPackage -Online        | Select-Object PackageName, PackageState, ReleaseType }

function Enable-SelectedOptionalFeatures($t) {
  if (-not (ModuleEnabled $t "OptionalFeaturesEnable")) { return }
  $enableAll = $false
  try { $enableAll = [bool]$t.modules.OptionalFeaturesEnable.EnableAll } catch {}

  foreach ($f in (Get-OptionalFeatures)) {
    $name = $f.FeatureName
    $enabled = $false
    if ($enableAll) { $enabled = $true }
    elseif ($t.optionalFeatures.PSObject.Properties.Name -contains $name) { $enabled = [bool]$t.optionalFeatures.$name }

    if ($enabled -and $f.State -ne "Enabled") {
      Write-Host "Enabling Optional Feature: $name"
      # DISM feature enable model [4](https://github.com/Homebrew/brew/blob/main/docs/Brew-Bundle-and-Brewfile.md)
      dism.exe /online /enable-feature /featurename:$name /all /norestart | Out-Host
    }
  }
}

function Disable-RemoveSelectedOptionalFeatures($t) {
  if (-not (ModuleEnabled $t "OptionalFeaturesDisableRemove")) { return }

  foreach ($f in (Get-OptionalFeatures)) {
    $name = $f.FeatureName
    if ($t.optionalFeaturesRemove.PSObject.Properties.Name -contains $name) {
      $doRemove = [bool]$t.optionalFeaturesRemove.$name
      if ($doRemove) {
        try {
          # Disable + remove payload (PowerShell wrapper supports -Remove) [5](https://miguelcrespo.co/posts/automate-installation-and-configuration-of-macos/)
          Disable-WindowsOptionalFeature -Online -FeatureName $name -Remove -NoRestart | Out-Null
          Write-Host "Disabled+Removed payload: $name"
        } catch {
          Write-Host "Failed to disable/remove $name :: $($_.Exception.Message)" -ForegroundColor Yellow
        }
      }
    }
  }
}

function Enable-SelectedCapabilities($t) {
  if (-not (ModuleEnabled $t "CapabilitiesEnable")) { return }
  $enableAll = $false
  try { $enableAll = [bool]$t.modules.CapabilitiesEnable.EnableAll } catch {}

  foreach ($c in (Get-Capabilities)) {
    $name = $c.Name
    $enabled = $false
    if ($enableAll) { $enabled = $true }
    elseif ($t.capabilities.PSObject.Properties.Name -contains $name) { $enabled = [bool]$t.capabilities.$name }

    if ($enabled -and $c.State -ne "Installed") {
      Write-Host "Adding Capability: $name"
      Add-WindowsCapability -Online -Name $name -ErrorAction Continue | Out-Null
    }
  }
}

function Set-RegistryDword($path, $name, $value) {
  New-Item -Path $path -Force | Out-Null
  Set-ItemProperty -Path $path -Name $name -Type DWord -Value $value -Force
}

function Apply-QoLTweaks($t) {
  if (-not (ModuleEnabled $t "QoLTweaks")) { return }
  $q = $t.qolTweaks
  if ($null -eq $q) { return }

  Write-Host "Applying QoL/Performance toggles..." -ForegroundColor Cyan

  if ($q.EnableDeveloperMode) {
    Set-RegistryDword "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" "AllowDevelopmentWithoutDevLicense" 1
    Set-RegistryDword "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" "AllowAllTrustedApps" 1
  }
  if ($q.EnableLongPaths) {
    Set-RegistryDword "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" "LongPathsEnabled" 1
  }
  if ($q.ShowFileExtensions) {
    Set-RegistryDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" 0
  }
  if ($q.ShowHiddenFiles) {
    Set-RegistryDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" 1
  }
  if ($q.EnableClipboardHistory) {
    Set-RegistryDword "HKCU:\Software\Microsoft\Clipboard" "EnableClipboardHistory" 1
  }
  if ($q.DisableStickyKeysPrompt) {
    Set-ItemProperty -Path "HKCU:\Control Panel\Accessibility\StickyKeys" -Name "Flags" -Value "506" -Force -ErrorAction SilentlyContinue
  }

  switch ($q.SetPowerPlan) {
    "Ultimate" {
      $ultimate = "e9a42b02-d5df-448d-aa00-03f14749eb61"
      & powercfg -duplicatescheme $ultimate | Out-Null
      & powercfg -setactive $ultimate | Out-Null
    }
    "High" {
      $high = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
      & powercfg -setactive $high | Out-Null
    }
    default { }
  }

  if ($q.DisableHibernation) { & powercfg /hibernate off | Out-Null }

  if ($q.ReduceVisualEffects) {
    Set-RegistryDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" "VisualFXSetting" 2
  }
  if ($q.DisableTransparency) {
    Set-RegistryDword "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" "EnableTransparency" 0
  }

  Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
  Start-Process explorer.exe
}

function Ensure-FolderBootstrap($t) {
  if (-not (ModuleEnabled $t "FolderBootstrap")) { return }
  $fb = $t.folderBootstrap
  if ($null -eq $fb) { return }

  Write-Host "Folder bootstrap..." -ForegroundColor Cyan
  foreach ($p in $fb.Folders) {
    try {
      $drive = (Split-Path $p -Qualifier)
      if ($drive -and -not (Test-Path $drive)) {
        Write-Host "Skipping (drive missing): $p" -ForegroundColor Yellow
        continue
      }
      New-Item -ItemType Directory -Force -Path $p | Out-Null
    } catch {
      Write-Host "Folder create failed: $p :: $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }

  if ($fb.SetEnvVars) {
    foreach ($k in $fb.EnvVars.PSObject.Properties.Name) {
      [System.Environment]::SetEnvironmentVariable($k, $fb.EnvVars.$k, "User")
      Write-Host "Set User env var: $k=$($fb.EnvVars.$k)"
    }
  }
}

function Apply-GamingTweaks($t) {
  if (-not (ModuleEnabled $t "GamingTweaks")) { return }
  $g = $t.gamingTweaks
  if ($null -eq $g) { return }

  Write-Host "Applying Gaming QoL tweaks..." -ForegroundColor Cyan

  if ($g.EnableGameMode) {
    Set-RegistryDword "HKCU:\Software\Microsoft\GameBar" "AutoGameModeEnabled" 1
  }
  if ($g.DisableGameDVR) {
    Set-RegistryDword "HKCU:\System\GameConfigStore" "GameDVR_Enabled" 0
    Set-RegistryDword "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" 0
  }
  if ($g.DisableMouseAcceleration) {
    Set-ItemProperty "HKCU:\Control Panel\Mouse" "MouseSpeed" "0" -Force
    Set-ItemProperty "HKCU:\Control Panel\Mouse" "MouseThreshold1" "0" -Force
    Set-ItemProperty "HKCU:\Control Panel\Mouse" "MouseThreshold2" "0" -Force
  }
  if ($g.DisableWidgets) {
    Set-RegistryDword "HKLM:\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests" 0
  }
}

function Ensure-VSCodeExtensions($t) {
  if (-not (ModuleEnabled $t "VSCodeExtensions")) { return }
  $exts = $t.vscodeExtensions
  if ($null -eq $exts -or $exts.Count -eq 0) { return }

  # VS Code CLI supports installing extensions via code --install-extension <id> [1](https://www.greghilston.com/post/windows-11-install-and-configure/)[2](https://lpndev.github.io/wpis/)[3](https://github.com/reinaldogpn/windows-post-install)
  $codeCmd = Get-Command code -ErrorAction SilentlyContinue
  if (-not $codeCmd) {
    $fallback = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"
    if (Test-Path $fallback) {
      $env:PATH = "$($env:PATH);$(Split-Path $fallback)"
      $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    }
  }

  if (-not $codeCmd) {
    Write-Host "VS Code CLI 'code' not found yet; skipping extension install this run." -ForegroundColor Yellow
    return
  }

  Write-Host "Installing VS Code extensions..." -ForegroundColor Cyan
  foreach ($e in $exts) {
    try {
      & code --install-extension $e --force | Out-Null
      Write-Host "Installed/updated: $e"
    } catch {
      Write-Host "Extension failed: $e :: $($_.Exception.Message)" -ForegroundColor Yellow
    }
  }
}

function Enable-WindowsComponentsByCapabilityMatch($t) {
  if (-not (ModuleEnabled $t "WindowsComponentEnablement")) { return }
  $wc = $t.windowsComponentEnablement
  if ($null -eq $wc) { return }

  $caps = Get-WindowsCapability -Online
  function EnableCapByPattern([string]$pattern) {
    $matches = $caps | Where-Object { $_.Name -like $pattern }
    if (-not $matches) {
      Write-Host "No capability matched pattern: $pattern" -ForegroundColor Yellow
      return
    }
    foreach ($m in $matches) {
      if ($m.State -ne "Installed") {
        Write-Host "Adding capability: $($m.Name)"
        Add-WindowsCapability -Online -Name $m.Name -ErrorAction Continue | Out-Null
      } else {
        Write-Host "Capability already installed: $($m.Name)"
      }
    }
  }

  if ($wc.EnableHelloFace)       { EnableCapByPattern "*Hello*Face*" }
  if ($wc.EnableHandwritingEnUS) { EnableCapByPattern "*Language*Handwriting*en-US*" }
  if ($wc.EnableSpeechEnUS)      { EnableCapByPattern "*Language*Speech*en-US*" }
}

function Audit-PackagesGrouped($t) {
  if (-not (ModuleEnabled $t "PackageAudit")) { return }
  $pa = $t.packageAudit
  if ($null -eq $pa -or $null -eq $pa.Packages) { return }

  $pkgs = Get-Packages
  $results = foreach ($p in $pa.Packages) {
    $found = $pkgs | Where-Object { $_.PackageName -eq $p }
    if ($found) {
      [pscustomobject]@{ PackageName=$found.PackageName; PackageState=$found.PackageState; ReleaseType=$found.ReleaseType }
    } else {
      [pscustomobject]@{ PackageName=$p; PackageState="NotFound"; ReleaseType="" }
    }
  }

  if (ModuleEnabled $t "PackageAuditSummary") {
    Write-Host "Package audit summary (grouped by state)..." -ForegroundColor Cyan
    $groups = $results | Group-Object PackageState | Sort-Object Name
    foreach ($g in $groups) {
      Write-Host ("- {0}: {1}" -f $g.Name, $g.Count) -ForegroundColor Green
      foreach ($item in ($g.Group | Sort-Object PackageName)) {
        if ($item.PackageState -eq "NotFound") {
          Write-Host ("    NOT FOUND: {0}" -f $item.PackageName) -ForegroundColor Yellow
        } else {
          Write-Host ("    {0} (ReleaseType={1})" -f $item.PackageName, $item.ReleaseType)
        }
      }
    }
  }
}

function PackageRemovalReportOnly($t) {
  if (-not (ModuleEnabled $t "PackageRemoval")) { return }
  $pr = $t.packageRemoval
  if ($null -eq $pr) { return }

  # Toggle exists, but Mode=report_only only
  $out = Join-Path $Config.LogRoot "package-removal-report.txt"
  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("PackageRemoval module: ENABLED")
  $lines.Add("Mode: $($t.modules.PackageRemoval.Mode)")
  $lines.Add("")
  $lines.Add("This script does not generate or execute package-removal commands for network/driver packages.")
  $lines.Add("Use your supported driver/device management workflow for removal if needed.")
  $lines.Add("")
  $lines.Add("Packages listed for review:")
  foreach ($p in $pr.Packages) { $lines.Add(" - $p") }

  $lines | Set-Content -Path $out -Encoding UTF8
  Write-Host "Wrote package removal report: $out" -ForegroundColor Yellow
}

function Install-AppGroups($t) {
  if (-not (ModuleEnabled $t "WinGet")) { return }
  $installCfg = $t.wingetInstall
  $groupsEnabled = $installCfg.GroupsEnabled

  foreach ($groupName in $Config.Apps.Keys) {
    $doGroup = $true
    if ($null -ne $groupsEnabled -and $groupsEnabled.PSObject.Properties.Name -contains $groupName) {
      $doGroup = [bool]$groupsEnabled.$groupName
    }
    if (-not $doGroup) { continue }

    Write-Host ""
    Write-Host "=== Installing group: $groupName ===" -ForegroundColor Green
    foreach ($item in $Config.Apps[$groupName]) {
      try { Winget-InstallOne $item }
      catch { Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red }
    }
  }
}
#endregion Helpers

#region Main
Assert-Admin
Start-Logging

try {
  $t = Read-Toggles

  if (ModuleEnabled $t "WinGet") {
    Ensure-WinGet
    if ([bool]$t.modules.WinGet.UpgradeAllFirst) { Winget-UpgradeAll }
  }

  Enable-SelectedOptionalFeatures $t
  Disable-RemoveSelectedOptionalFeatures $t
  Enable-SelectedCapabilities $t

  Apply-QoLTweaks $t
  Ensure-FolderBootstrap $t
  Apply-GamingTweaks $t
  Enable-WindowsComponentsByCapabilityMatch $t

  Install-AppGroups $t

  # After VS Code install attempt
  Ensure-VSCodeExtensions $t

  Audit-PackagesGrouped $t
  PackageRemovalReportOnly $t

  Write-Host ""
  Write-Host "Done. Reboot recommended if you enabled/removed features or changed system settings." -ForegroundColor Yellow
  Write-Host "Toggles: $($Config.ToggleFilePath)"
}
finally {
  Stop-Logging
}
#endregion Main
