# Better11 PowerShell Modules

This document lists the main PowerShell modules used by the Better11 suite and their roles. The C# app invokes these via `IPowerShellService` and the corresponding C# services.

## Module Layout

- **Better11\Better11** solution uses C# services that call into PowerShell. Module paths may be under `PowerShell\Modules\`, `modules\`, or as specified in the app configuration.
- Each feature area typically has a **B11.\*** module (e.g. B11.Packages, B11.Drivers).

## Core / App-Backed Modules

| Module | Purpose | Main C# Service |
|--------|---------|------------------|
| B11.Packages | Package (e.g. winget) list, install, uninstall, update | PackageService |
| B11.Drivers | Driver list, scan, update, backup, rollback | DriverService |
| B11.Startup | Startup items (registry/folder) list, enable, disable, remove | StartupService |
| B11.Tasks | Scheduled tasks list, enable, disable, run | ScheduledTaskService |
| B11.Network | Adapters, DNS get/set, presets, flush DNS, diagnostics | NetworkService |
| B11.DiskCleanup | Scan cleanup categories, clean, disk space | DiskCleanupService |
| B11.SystemInfo | System info and performance metrics | SystemInfoService |
| B11.Optimization | Optimization categories, apply tweaks, restore point | OptimizationService |
| B11.Privacy | Privacy audit, profiles, setting toggles | PrivacyService |
| B11.Security | Security status, scan, hardening | SecurityService |
| B11.Update | Windows Update check, install, history | UpdateService |

## Supporting Modules

- **B11.BetterPE** — WinPE imaging and related operations.
- **B11.Gaming** — Gaming-related optimizations (some placeholders may remain).
- **B11.BetterShell** — Terminal/shell framework and submodules (e.g. DevTools).

## Aurora.* Modules

The **Aurora.*** modules (e.g. Aurora.Core, Aurora.Drivers, Aurora.Install, Aurora.Retry, Aurora.Tweaks) may exist under `modules\`. Some are placeholders; see the codebase and PLAN.md for implementation status.

## Loading and Testing

- **Import main module:** `Import-Module .\modules\Better11\Better11.psd1` (path may vary).
- **List exported functions:** `Get-Command -Module B11.*` (or the specific module name).
- **Pester tests:** Run from the repo root or module folder; see BUILD.md for the recommended Pester path.
- **PSScriptAnalyzer:** Run with the project’s settings file; zero violations required.

## Adding a New Module

1. Add the `.psm1` and `.psd1` in the appropriate folder.
2. Implement functions with comment-based help and PSScriptAnalyzer compliance.
3. Add C# models, interface, service, ViewModel, and XAML page following the full-stack pattern (see CLAUDE.md).
4. Add xUnit tests for the service and Pester tests for the module.
5. Register the service and ViewModel in DI and add the page to navigation.
