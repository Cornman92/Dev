# Auto-Suite Function Mapping

This document maps each discovered PowerShell-style function to:

- its original name as found in the export
- its Auto-Suite–normalized name
- its inferred Auto-Suite module
- a suggested canonical PowerShell signature (based on any detected `param(...)` block)

---

## WAS.Core

- **Original:** `Add-Anom`
  - **Renamed:** *(unchanged)* `Add-Anom`
  - **Suggested signature:** `function Add-Anom($desc, $tag)`
- **Original:** `Add-Component`
  - **Renamed:** *(unchanged)* `Add-Component`
  - **Suggested signature:** `function Add-Component($Parent, $Name, $Pass, $ProcessorArchitecture)`
- **Original:** `Add-Drift`
  - **Renamed:** *(unchanged)* `Add-Drift`
  - **Suggested signature:** `function Add-Drift($Metric, $Current, $Baseline, $Delta)`
- **Original:** `Apply-GameOptimizations`
  - **Renamed:** *(unchanged)* `Apply-GameOptimizations`
  - **Suggested signature:** `function Apply-GameOptimizations()`
- **Original:** `Check`
  - **Renamed:** *(unchanged)* `Check`
  - **Suggested signature:** `function Check($metric, $baseline, $threshold, $label)`
- **Original:** `Disable-AuroraTweaks`
  - **Renamed:** `Disable-WASTweaks`
  - **Suggested signature:** `function Disable-WASTweaks()`
- **Original:** `Download-And-ExtractZip`
  - **Renamed:** *(unchanged)* `Download-And-ExtractZip`
  - **Suggested signature:** `function Download-And-ExtractZip($Name, $Url, $DownloadRoot, $DestinationRoot)`
- **Original:** `Enable-AuroraTweaks`
  - **Renamed:** `Enable-WASTweaks`
  - **Suggested signature:** `function Enable-WASTweaks()`
- **Original:** `Enable-UltimatePerformancePlan`
  - **Renamed:** *(unchanged)* `Enable-UltimatePerformancePlan`
  - **Suggested signature:** `function Enable-UltimatePerformancePlan()`
- **Original:** `Ensure-ParentDirectory`
  - **Renamed:** *(unchanged)* `Ensure-ParentDirectory`
  - **Suggested signature:** `function Ensure-ParentDirectory()`
- **Original:** `Get-`
  - **Renamed:** *(unchanged)* `Get-`
  - **Suggested signature:** `function Get-()`
- **Original:** `Get-AuroraAppState`
  - **Renamed:** `Get-WASAppState`
  - **Suggested signature:** `function Get-WASAppState()`
- **Original:** `Get-AuroraConfig`
  - **Renamed:** `Get-WASConfig`
  - **Suggested signature:** `function Get-WASConfig()`
- **Original:** `Get-LogPath`
  - **Renamed:** *(unchanged)* `Get-LogPath`
  - **Suggested signature:** `function Get-LogPath()`
- **Original:** `Get-OrCreateComponentNode`
  - **Renamed:** *(unchanged)* `Get-OrCreateComponentNode`
  - **Suggested signature:** `function Get-OrCreateComponentNode($Document, $NsMgr, $SettingsNode, $Name, $Arch)`
- **Original:** `Get-OrCreateSettingsNode`
  - **Renamed:** *(unchanged)* `Get-OrCreateSettingsNode`
  - **Suggested signature:** `function Get-OrCreateSettingsNode($Document, $NsMgr, $Pass)`
- **Original:** `Get-Sigma`
  - **Renamed:** *(unchanged)* `Get-Sigma`
  - **Suggested signature:** `function Get-Sigma($var, $n)`
- **Original:** `Invoke-AuroraJob`
  - **Renamed:** `Invoke-WASJob`
  - **Suggested signature:** `function Invoke-WASJob()`
- **Original:** `Is-Spike`
  - **Renamed:** *(unchanged)* `Is-Spike`
  - **Suggested signature:** `function Is-Spike($value, $avg, $threshold)`
- **Original:** `Mount-AuroraWim`
  - **Renamed:** `Mount-WASWim`
  - **Suggested signature:** `function Mount-WASWim($ImagePath, $Index, $MountPath)`
- **Original:** `New-AuroraPpkgProject`
  - **Renamed:** `New-WASPpkgProject`
  - **Suggested signature:** `function New-WASPpkgProject($OutDir)`
- **Original:** `New-AuroraSnapshot`
  - **Renamed:** `New-WASSnapshot`
  - **Suggested signature:** `function New-WASSnapshot()`
- **Original:** `Refresh-Log`
  - **Renamed:** *(unchanged)* `Refresh-Log`
  - **Suggested signature:** `function Refresh-Log()`
- **Original:** `Refresh-Stats`
  - **Renamed:** *(unchanged)* `Refresh-Stats`
  - **Suggested signature:** `function Refresh-Stats()`
- **Original:** `Resolve-Cert`
  - **Renamed:** *(unchanged)* `Resolve-Cert`
  - **Suggested signature:** `function Resolve-Cert($PfxPath, $PfxPassword, $Subject)`
- **Original:** `Resolve-RootPath`
  - **Renamed:** *(unchanged)* `Resolve-RootPath`
  - **Suggested signature:** `function Resolve-RootPath()`
- **Original:** `Save-AuroraConfig`
  - **Renamed:** `Save-WASConfig`
  - **Suggested signature:** `function Save-WASConfig()`
- **Original:** `Start-Log`
  - **Renamed:** *(unchanged)* `Start-Log`
  - **Suggested signature:** `function Start-Log($Path, $Title)`
- **Original:** `Stop-Log`
  - **Renamed:** *(unchanged)* `Stop-Log`
  - **Suggested signature:** `function Stop-Log($SampleIntervalSeconds, $Samples, $AIAnalyze, $Profile, $OutputDir, $scriptDir)`
- **Original:** `Test-AuroraElevation`
  - **Renamed:** `Test-WASElevation`
  - **Suggested signature:** `function Test-WASElevation()`
- **Original:** `Update-RunningStats`
  - **Renamed:** *(unchanged)* `Update-RunningStats`
  - **Suggested signature:** `function Update-RunningStats($avg, $var, $n, $x)`
- **Original:** `Write-AuroraEvent`
  - **Renamed:** `Write-WASEvent`
  - **Suggested signature:** `function Write-WASEvent()`
- **Original:** `Write-AuroraEventEx`
  - **Renamed:** `Write-WASEventEx`
  - **Suggested signature:** `function Write-WASEventEx()`
- **Original:** `Write-Log`
  - **Renamed:** *(unchanged)* `Write-Log`
  - **Suggested signature:** `function Write-Log()`
- **Original:** `Z`
  - **Renamed:** *(unchanged)* `Z`
  - **Suggested signature:** `function Z($x, $avg, $sigma)`
- **Original:** `awsl`
  - **Renamed:** *(unchanged)* `awsl`
  - **Suggested signature:** `function awsl()`
- **Original:** `azl`
  - **Renamed:** *(unchanged)* `azl`
  - **Suggested signature:** `function azl()`
- **Original:** `d`
  - **Renamed:** *(unchanged)* `d`
  - **Suggested signature:** `function d()`
- **Original:** `dc`
  - **Renamed:** *(unchanged)* `dc`
  - **Suggested signature:** `function dc()`
- **Original:** `dps`
  - **Renamed:** *(unchanged)* `dps`
  - **Suggested signature:** `function dps()`
- **Original:** `gcl`
  - **Renamed:** *(unchanged)* `gcl`
  - **Suggested signature:** `function gcl()`
- **Original:** `k`
  - **Renamed:** *(unchanged)* `k`
  - **Suggested signature:** `function k()`
- **Original:** `kg`
  - **Renamed:** *(unchanged)* `kg`
  - **Suggested signature:** `function kg($kind, $ns)`
- **Original:** `z`
  - **Renamed:** *(unchanged)* `z`
  - **Suggested signature:** `function z()`

---

## WAS.Health

- **Original:** `GetNowMetric`
  - **Renamed:** *(unchanged)* `GetNowMetric`
  - **Suggested signature:** `function GetNowMetric()`

---

## WAS.Installers

- **Original:** `Download-And-RunInstaller`
  - **Renamed:** *(unchanged)* `Download-And-RunInstaller`
  - **Suggested signature:** `function Download-And-RunInstaller($Name, $Url, $Args, $DownloadRoot)`
- **Original:** `Install-AuroraApps`
  - **Renamed:** `Install-WASApps`
  - **Suggested signature:** `function Install-WASApps()`

---

## WAS.Profile

- **Original:** `Load-Profiles`
  - **Renamed:** *(unchanged)* `Load-Profiles`
  - **Suggested signature:** `function Load-Profiles()`
