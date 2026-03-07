# Auto-Suite Modules and Functions

This document lists discovered PowerShell-style functions from the chat export,
organized into WAS modules by naming heuristics. All identifiers have been
normalized so that any legacy `Aurora`/`AutoSuite` namespace is renamed to `WAS`.

## Modules Overview

- **WAS.Core** — 44 functions
- **WAS.Health** — 1 functions
- **WAS.Installers** — 2 functions
- **WAS.Profile** — 1 functions

---

## WAS.Core

- `Add-Anom`
- `Add-Component`
- `Add-Drift`
- `Apply-GameOptimizations`
- `Check`  <!-- non-standard name, kept for completeness -->
- `Disable-WASTweaks`
- `Download-And-ExtractZip`
- `Enable-WASTweaks`
- `Enable-UltimatePerformancePlan`
- `Ensure-ParentDirectory`
- `Get-`
- `Get-WASAppState`
- `Get-WASConfig`
- `Get-LogPath`
- `Get-OrCreateComponentNode`
- `Get-OrCreateSettingsNode`
- `Get-Sigma`
- `Invoke-WASJob`
- `Is-Spike`
- `Mount-WASWim`
- `New-WASPpkgProject`
- `New-WASSnapshot`
- `Refresh-Log`
- `Refresh-Stats`
- `Resolve-Cert`
- `Resolve-RootPath`
- `Save-WASConfig`
- `Start-Log`
- `Stop-Log`
- `Test-WASElevation`
- `Update-RunningStats`
- `Write-WASEvent`
- `Write-WASEventEx`
- `Write-Log`
- `Z`  <!-- non-standard name, kept for completeness -->
- `awsl`  <!-- non-standard name, kept for completeness -->
- `azl`  <!-- non-standard name, kept for completeness -->
- `d`  <!-- non-standard name, kept for completeness -->
- `dc`  <!-- non-standard name, kept for completeness -->
- `dps`  <!-- non-standard name, kept for completeness -->
- `gcl`  <!-- non-standard name, kept for completeness -->
- `k`  <!-- non-standard name, kept for completeness -->
- `kg`  <!-- non-standard name, kept for completeness -->
- `z`  <!-- non-standard name, kept for completeness -->

---

## WAS.Health

- `GetNowMetric`  <!-- non-standard name, kept for completeness -->

---

## WAS.Installers

- `Download-And-RunInstaller`
- `Install-WASApps`

---

## WAS.Profile

- `Load-Profiles`
