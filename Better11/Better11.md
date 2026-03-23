# Better11 — Windows System Enhancement Suite

## Project Identity

**Better11** is an all-in-one Windows System Creator/Enhancer that enables power users to heavily optimize, customize, and personalize both live Windows installations and offline images.

| Field | Value |
|-------|-------|
| **Type** | Windows system management platform |
| **Stack** | WinUI 3 / C# (.NET 8+) / PowerShell 5.1+ |
| **Target Audience** | Power users, developers, gaming enthusiasts |
| **UI Style** | Dense, dark, WinUtil-inspired (Chris Titus Tech aesthetic) |
| **Codebase** | ~115,000+ LOC, 550+ files, 1,800+ tests |
| **Status** | 100% complete — All 7 work streams finished |
| **Date** | 2026-03-01 |

## Sub-Components

| Component | Purpose |
|-----------|---------|
| **Better.Wim** | Edit boot.wim/install.wim, create custom WinPE/WinRE images |
| **Better.XML** | Generate/edit XML files (especially unattend.xml) |
| **BetterPE** | Custom Gaming/Dev/Enthusiast WindowsPE with extensive tooling |
| **BetterBoot** | Full deployment pipeline from WinPE through post-boot optimization (12 stages) |

## Two User Interfaces

- **PowerShell TUI** — Terminal UI for WinPE + full Windows (primary for advanced/deployment)
- **C# WinUI 3 GUI** — Full graphical desktop application with 16+ pages

## Architecture

- **MVVM** via CommunityToolkit.Mvvm (ObservableObject, RelayCommand, [ObservableProperty])
- **DI container** (Microsoft.Extensions.DependencyInjection)
- **102 PowerShell modules** bridged via IPowerShellService
- **Result<T>** error handling pattern throughout
- **15+ C# services**, 18+ ViewModels, 16+ XAML pages
- **Theme system:** DarkTheme/LightTheme (#111111 bg, #0078D4 accent, 24px dense rows)

## Current Status

| Work Stream | Description | Status |
|-------------|-------------|--------|
| WS1 | Reporting & Analytics | COMPLETE |
| WS2 | Testing & Validation (C# + UI) | COMPLETE |
| WS3 | Certificate Manager + Credential Vault | COMPLETE |
| WS4 | Appearance Customizer + RAM Disk | COMPLETE |
| WS5 | Full UI Redesign | COMPLETE |
| WS6 | First Run Wizard + Integration QA | COMPLETE |
| WS7 | Final Zero-Error Compilation Pass | COMPLETE |

**Status:** All 7 work streams completed successfully. The project is now production-ready with zero code quality violations and comprehensive test coverage.

## Development Team

- **Claude Code** (Anthropic Claude) — Lead architect, built the majority of the codebase
- **Cursor AI** (Cursor IDE) — Development assistant for WS7 completion tasks

## Key Documentation

| File | Purpose |
|------|---------|
| [CLAUDE.md](CLAUDE.md) | Agent instructions for Claude Code (architecture, patterns, conventions) |
| [CURSOR.md](CURSOR.md) | Co-development guide for Cursor AI |
| [PLAN.md](PLAN.md) | Work stream status and detailed deliverables |
| [Better11-STATUS.md](Better11-STATUS.md) | Build metrics (C# layer) |
| [STYLE-GUIDE.md](STYLE-GUIDE.md) | UI design system specification |
| [README.md](README.md) | Project README (quick start, overview) |

## Repository Structure

```
D:\Dev\Better11\
├── Better11\                  # Main solution directory
│   ├── src\                   # Source code (App, Core, Services, ViewModels)
│   ├── tests\                 # Unit, integration, and scenario tests
│   ├── scripts\               # Build and utility scripts
│   └── Better11.sln           # Solution file
├── configs\                   # JSON configuration files
├── modules\                   # PowerShell modules (Aurora.*, Better11 submodules)
├── docs\                      # Reference docs (INSTALL, APP-UPDATE, SOURCE-TREES)
├── src\                       # Deprecated alternate source (see docs/SOURCE-TREES.md)
├── .cursor\                   # Cursor IDE rules, skills, MCP config
├── tools\                     # MCP servers (better11, collab)
├── CLAUDE.md                  # Claude Code agent instructions
├── CURSOR.md                  # Cursor AI guide
├── PLAN.md                    # Work stream plan
├── Better11.md                # This file
├── Better11-STATUS.md         # Build status metrics
├── STYLE-GUIDE.md             # UI design system
└── README.md                  # Project README
```
