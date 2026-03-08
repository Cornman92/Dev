# Better11

**All-in-one Windows System Enhancement Suite** — Optimize, customize, and personalize Windows installations (live and offline) through a powerful hybrid C#/PowerShell platform.

## Overview

Better11 provides power users, developers, and gaming enthusiasts with comprehensive Windows system management through two interfaces:

- **WinUI 3 GUI** — Dense, dark desktop application with 16+ functional pages
- **PowerShell TUI** — Deferred in the current repo-root solution; TUI tests exist in `tests\TUI`, but the implementation is not part of `Better11.sln`

## Key Features

- **System Optimization** — CPU, memory, disk, GPU, power, and service tuning
- **Privacy & Security** — Telemetry control, firewall, audit policies, compliance scanning
- **Package Management** — Install, update, and manage software packages
- **Driver Management** — Scan, update, backup, and rollback drivers
- **Network Configuration** — DNS presets, diagnostics, adapter management
- **Disk Cleanup** — Temp files, Windows Update cache, system cleanup
- **Startup & Scheduled Tasks** — Manage boot programs and system tasks
- **System Reporting** — HTML/JSON/Markdown/CSV/TXT reports of system state
- **WIM Editing** (Better.Wim) — Create custom WinPE/WinRE images
- **Deployment Pipeline** (BetterBoot) — 12-stage image deployment from WinPE to post-boot
- **Appearance Customizer** — Wallpaper, accent colors, taskbar, Start menu, visual effects
- **RAM Disk** — Memory-backed storage with folder redirects
- **Certificate Manager** — Browse stores, import/export, self-signed creation
- **First Run Wizard** — Guided setup for new installations

## System Requirements

- **OS:** Windows 10 version 1809+ or Windows 11 (x64)
- **Architecture:** x64
- **.NET:** 8.0 (included with the app when installed)
- **PowerShell:** 5.1+ (for PowerShell module usage)

## Quick Start

```powershell
# Build the solution (see BUILD.md for full details)
cd Better11
.\scripts\Build-Better11.ps1 -Configuration Release -Test

# Or manually:
dotnet restore Better11.sln
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" Better11.sln -p:Configuration=Release -p:Platform=x64 -t:Build -v:minimal -nologo
dotnet test Better11.sln --configuration Release -p:Platform=x64

# Import PowerShell modules
Import-Module .\modules\Better11\Better11.psd1
```

## Architecture

| Layer | Technology | Details |
|-------|-----------|---------|
| Frontend | WinUI 3 (.NET 8+) | MVVM, CommunityToolkit.Mvvm, 16+ XAML pages |
| Backend | PowerShell 5.1+ | 102 modules, invoked via IPowerShellService |
| DI | Microsoft.Extensions.DependencyInjection | Full service registration |
| Error Handling | Result<T> pattern | Consistent success/failure propagation |
| Testing | xUnit + FluentAssertions + Moq + Pester v5 | 218+ test methods |
| UI Theme | Dense dark layout | #111111 bg, #0078D4 accent, 24px rows |

## Project Status

| Metric | Value |
|--------|-------|
| Codebase | ~115,000+ LOC, 550+ files |
| Current focus | GUI stabilization and repo-truth cleanup |
| Verified on 2026-03-08 | Repo-root `Better11.sln` builds via `.\scripts\Build-Better11.ps1 -Configuration Release` |
| In-solution tests | 336 passing xUnit tests across the 3 test projects in `Better11.sln` |
| App launch | Release/x64 executable opened successfully with window title `Better11 System Enhancement Suite` |
| Deferred scope | `tests\TUI` exists in the repo but is not part of `Better11.sln` |

See [PLAN.md](PLAN.md) for historical work-stream context and [BUILD.md](BUILD.md) for the currently verified build path.

## Documentation

### Core Documentation
| File | Purpose |
|------|---------|
| [Better11.md](Better11.md) | Project identity and current status |
| [CLAUDE.md](CLAUDE.md) | Agent instructions (architecture, patterns, conventions) |
| [CURSOR.md](CURSOR.md) | Co-development guide for Cursor AI |
| [PLAN.md](PLAN.md) | Work stream tracking and deliverables |
| [Better11-STATUS.md](Better11-STATUS.md) | Build metrics |
| [STYLE-GUIDE.md](STYLE-GUIDE.md) | UI design system |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System architecture and data flow |
| [BUILD.md](BUILD.md) | Build, test, and package instructions |
| [docs/INSTALL.md](docs/INSTALL.md) | Installation guide (download, sideload, uninstall) |
| [RELEASE.md](RELEASE.md) | Release process and sideload installation |
| [docs/VERSIONING.md](docs/VERSIONING.md) | Semantic versioning (SemVer) |
| [docs/SIDELOAD.md](docs/SIDELOAD.md) | Sideload MSIX installation |
| [docs/EULA.md](docs/EULA.md) | End User License Agreement (placeholder) |
| [docs/PRIVACY.md](docs/PRIVACY.md) | Privacy policy (placeholder) |
| [docs/USER-GUIDE.md](docs/USER-GUIDE.md) | User guide and getting started |
| [docs/MODULES.md](docs/MODULES.md) | PowerShell modules and C# service mapping |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Build, test, and contribution guidelines |
| [CHANGELOG.md](CHANGELOG.md) | Version history and release notes |
| [docs/SOURCE-TREES.md](docs/SOURCE-TREES.md) | Canonical source tree and deferred alternate tree notes |

### Development Environment
| File | Purpose |
|------|---------|
| [Windsurf.md](Windsurf.md) / [docs/Windsurf.md](docs/Windsurf.md) | Development with Windsurf IDE and AI assistance; MCP (windows, filesystem, desktopcommander) enabled in `.cursor/mcp.json` |

### Experimental Features
| File | Purpose |
|------|---------|
| [Antigravity.md](Antigravity.md) / [docs/Antigravity.md](docs/Antigravity.md) | Quantum-gravitational performance enhancement (⚠️ Experimental) |

## Directory Structure

```
D:\Dev\Better11\
├── src\                   # Canonical C# source (App, Core, Services, ViewModels)
├── tests\                 # In-solution xUnit projects plus deferred TUI tests
├── scripts\               # Build and utility scripts
├── Better11.sln           # Repo-root solution file
├── configs\               # JSON configuration files
├── modules\               # PowerShell modules (102 total)
├── Better11\              # Alternate/deprecated source tree kept for reference
├── .cursor\               # Cursor IDE rules, skills, MCP config
├── tools\                 # MCP servers (better11, collab)
└── docs\                  # Reference documentation
```

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Development Team

- **Claude Code** (Anthropic Claude) — Lead architect
- **Cursor AI** (Cursor IDE) — Development assistant

## Build Commands

See [BUILD.md](BUILD.md) for full build, test, and package commands. Summary:

```powershell
cd Better11
.\scripts\Build-Better11.ps1 -Configuration Release -Test -Package

# Or manually: restore, build, test, then publish for MSIX
dotnet restore Better11.sln
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" Better11.sln -p:Configuration=Release -p:Platform=x64 -t:Build -v:minimal -nologo
dotnet test Better11.sln -c Release -p:Platform=x64
# Import and use modules
Import-Module .\modules\Better11\Better11.psd1
```
---

*Last Updated: 2026-03-08*
