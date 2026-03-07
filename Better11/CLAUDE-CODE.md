# CLAUDE-CODE.md — Better11 Claude Code Onboarding Guide

> **Purpose:** This document is specifically for Claude Code CLI sessions working on the Better11 project.
> It provides everything needed to understand, build, test, and extend this codebase.
> **Last Updated:** March 1, 2026

---

## Quick Orientation

Better11 is **three platforms in one codebase**:

1. **Windows System Optimization** — WinUI 3 desktop app with registry tweaks, debloat, privacy, drivers, packages
2. **Windows Imaging & Deployment Toolkit (BetterPE)** — WIM/ESD/WinPE management, PXE/WDS network deploy
3. **Workflow Automation (BetterShell)** — PowerShell terminal framework with 101 functions across 6 sub-modules

The developer is **C-Man** — a power user and project lead with deep Windows/PowerShell/C# expertise.
Target audience: power users, enthusiasts, gamers, developers. **Not** corporate/enterprise.

---

## Repository Structure

```
Better11/
├── CLAUDE.md                          # AI context (general — Cursor/Windsurf/Claude Code)
├── CLAUDE-CODE.md                     # THIS FILE — Claude Code specific guide
├── README.md                          # Project overview
├── Better11.sln                       # .NET solution file
├── Directory.Build.props              # Shared MSBuild properties (net8.0, nullable, StyleCop)
├── global.json                        # .NET SDK version pin (8.0.x)
├── NuGet.config                       # Package sources
├── .editorconfig                      # Code style enforcement
├── .gitignore                         # Standard .NET + PS ignores
│
├── config/
│   ├── stylecop.json                  # StyleCop rules (company name, header reqs)
│   ├── Better11.ruleset               # C# analyzer severity overrides
│   └── PSScriptAnalyzerSettings.psd1  # PS linting rules
│
├── docs/
│   ├── ARCHITECTURE.md                # Full architecture deep-dive
│   ├── MERGE-GUIDE.md                 # Module consolidation strategy
│   ├── DEDUPLICATION-REPORT.md        # Resolved duplicate functions
│   ├── CHANGELOG.md                   # Version history
│   ├── CONTRIBUTING.md                # Dev workflow and standards
│   └── cursor.md                      # Cursor-specific AI context
│
├── src/
│   ├── Better11.Core/                 # Models, Enums, Helpers, Result<T>
│   ├── Better11.Services/             # Service implementations + PowerShellService
│   ├── Better11.ViewModels/           # MVVM ViewModels (CommunityToolkit.Mvvm)
│   ├── Better11.App/                  # WinUI 3 app (XAML pages, MainWindow)
│   └── Better11.Tests/               # xUnit test project
│
├── PowerShell/
│   └── Modules/
│       ├── B11.BetterShell/           # Terminal framework (v3.0)
│       │   ├── B11.BetterShell.psd1   # Module manifest (77 exported functions)
│       │   ├── B11.BetterShell.psm1   # Root module loader
│       │   ├── SubModules/
│       │   │   ├── Watcher/           # File system monitoring (16 functions)
│       │   │   ├── Scheduler/         # In-process task scheduling (14 functions)
│       │   │   ├── Parallel/          # Concurrent execution (10 functions)
│       │   │   ├── FileTools/         # File operations & analysis (13 functions)
│       │   │   ├── DevTools/          # Script analysis & scaffolding (11 functions)
│       │   │   └── Plugin/            # Plugin registry & loading (13 functions)
│       │   └── Tests/                 # Pester test files
│       │
│       └── B11.BetterPE/             # Imaging & deployment toolkit
│           ├── B11.BetterPE.psd1      # Module manifest (8 exported functions)
│           ├── B11.BetterPE.psm1      # Root module loader
│           ├── Public/
│           │   └── NetworkDeploy.ps1  # PXE/WDS Phase 4 (8 functions)
│           └── Tests/                 # Pester test files
│
├── build/
│   └── Build-Better11.ps1            # Unified build script (restore, build, analyze, test)
│
└── .github/workflows/
    └── ci.yml                         # GitHub Actions CI pipeline
```

---

## First Commands After Clone

```bash
# Verify .NET SDK
dotnet --version   # Should be 8.0.x

# Restore and build
dotnet restore Better11.sln
dotnet build Better11.sln -c Debug

# Run C# tests
dotnet test Better11.sln --verbosity normal

# Run PowerShell linting (requires PSScriptAnalyzer module)
pwsh -c "Invoke-ScriptAnalyzer -Path ./PowerShell -Recurse -Settings ./config/PSScriptAnalyzerSettings.psd1"

# Run Pester tests (requires Pester 5.5+)
pwsh -c "Invoke-Pester -Path ./PowerShell/Modules -Output Detailed"

# Full unified build
pwsh -File ./build/Build-Better11.ps1 -Configuration Debug -RunTests -RunAnalyzers
```

---

## Code Standards (MUST follow — zero tolerance)

### C# Rules
- **StyleCop:** 0 warnings. `TreatWarningsAsErrors` is ON in Directory.Build.props
- **Nullable:** Enabled everywhere. No `null` without `?` annotation
- **File-scoped namespaces:** Always `namespace Better11.Core.Models;` (not block style)
- **Primary constructors:** Use for simple DI injection classes
- **Result<T>:** Use for all fallible operations. Never throw for expected failures
- **Async:** All I/O methods async with `CancellationToken` parameter
- **DI:** Constructor injection only. Register in `ServiceCollectionExtensions.cs`

### PowerShell Rules
- **PSScriptAnalyzer:** 0 warnings against `config/PSScriptAnalyzerSettings.psd1`
- **[CmdletBinding()]:** On EVERY function, no exceptions
- **SupportsShouldProcess:** On ALL state-changing functions (Set, New, Remove, Start, Stop, etc.)
- **[OutputType()]:** On every function
- **Verb-B11Noun:** All functions use approved verbs with `B11` noun prefix
- **Comment-based help:** `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE` on all public functions

### Testing Rules
- **100% coverage** for all new code
- **C#:** xUnit + FluentAssertions + Moq
- **PS:** Pester 5.x with `Describe/Context/It` blocks
- **Naming:** `{Method}_Should_{Expected}_When_{Condition}`

---

## Architecture Patterns

### C# Layer Dependency Flow
```
App (WinUI 3) → ViewModels → Services → Core
     ↓              ↓            ↓
   XAML Pages    Commands    PowerShellService → B11.* Modules
```

### Result<T> Pattern (used everywhere)
```csharp
// In Better11.Core/Models/Result.cs
public record Result<T>(bool IsSuccess, T? Value, string? Error, Exception? Exception = null)
{
    public static Result<T> Success(T value) => new(true, value, null);
    public static Result<T> Failure(string error) => new(false, default, error);
    public Result<TNew> Map<TNew>(Func<T, TNew> mapper) =>
        IsSuccess ? Result<TNew>.Success(mapper(Value!)) : Result<TNew>.Failure(Error!);
}
```

### PowerShell Module Pattern
```powershell
function Verb-B11Noun {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )
    begin { }
    process {
        if ($PSCmdlet.ShouldProcess($Name, 'Doing action')) {
            [PSCustomObject]@{
                PSTypeName = 'B11.ResultType'
                Name       = $Name
                Status     = 'Complete'
            }
        }
    }
    end { }
}
```

### ViewModel Pattern (CommunityToolkit.Mvvm)
```csharp
public partial class FeatureViewModel : BaseViewModel
{
    private readonly IFeatureService _service;
    [ObservableProperty] private string _searchText = string.Empty;
    [ObservableProperty] private bool _isLoading;

    public FeatureViewModel(IFeatureService service) => _service = service;

    [RelayCommand]
    private async Task LoadAsync(CancellationToken ct)
    {
        IsLoading = true;
        try { /* call _service */ }
        finally { IsLoading = false; }
    }
}
```

---

## How To: Common Tasks

### Add a new PowerShell module
1. Create `PowerShell/Modules/B11.{Name}/` directory
2. Create `B11.{Name}.psm1` (root module that dot-sources Public/*.ps1)
3. Create `B11.{Name}.psd1` (manifest with `FunctionsToExport`)
4. Create `Public/` directory with function files
5. Create `Tests/B11.{Name}.Tests.ps1` with full Pester coverage
6. Follow `Verb-B11Noun` naming, `[CmdletBinding()]`, `[OutputType()]`, `SupportsShouldProcess`

### Add a new C# service
1. Define interface in `Better11.Core/Services/Interfaces/I{Name}Service.cs`
2. Implement in `Better11.Services/Implementations/{Name}Service.cs`
3. Register in `ServiceCollectionExtensions.cs`: `services.AddSingleton<I{Name}Service, {Name}Service>()`
4. Create ViewModel in `Better11.ViewModels/{Feature}ViewModel.cs`
5. Create test in `Better11.Tests/{Feature}/{Name}ServiceTests.cs`

### Add a new WinUI page
1. Create XAML: `Better11.App/Pages/{Feature}Page.xaml`
2. Code-behind: `Better11.App/Pages/{Feature}Page.xaml.cs`
3. ViewModel: `Better11.ViewModels/{Feature}ViewModel.cs`
4. Register in navigation: update `NavigationConstants.cs` and `MainWindow`
5. Tests for ViewModel in `Better11.Tests/ViewModels/`

### Add a BetterPE function
1. Add function to appropriate file in `PowerShell/Modules/B11.BetterPE/Public/`
2. Update `B11.BetterPE.psd1` FunctionsToExport list
3. Add Pester tests in `PowerShell/Modules/B11.BetterPE/Tests/`
4. Mock external tools (wdsutil, DISM, etc.) in tests

### Add a BetterShell sub-module function
1. Add to the appropriate `.psm1` in `SubModules/{SubModule}/`
2. Add to the `Export-ModuleMember` list at bottom of that file
3. Update `B11.BetterShell.psd1` FunctionsToExport count
4. Add Pester test in `Tests/B11.BetterShell.{SubModule}.Tests.ps1`

---

## What Exists vs What's Scaffolded

### Fully Implemented (in this repo)
- Complete C# solution structure (5 projects, builds clean)
- Core models: Result<T>, SystemInfo, Package, Driver, OptimizationItem, ServiceItem, StartupItem, UndoEntry
- Core enums: ModuleCategory
- Helpers: AdminHelper, LogHelper, NavigationConstants
- Service interfaces: 9 interfaces defined
- PowerShellService: Full RunspacePool implementation with async execution
- BaseViewModel + DashboardViewModel + SystemOptimizationViewModel
- xUnit tests: Result, Models, BaseViewModel, DashboardViewModel (20 test methods)
- BetterShell v3.0: 6 sub-modules with 77 exported functions + Pester tests
- BetterPE Phase 4: 8 PXE/WDS functions + Pester tests
- Build infrastructure: MSBuild props, StyleCop, PSScriptAnalyzer, CI/CD

### Exists In Prior Sessions (NOT in this repo — needs re-creation)
These modules were built across 80+ prior Claude conversation sessions. They are documented in CLAUDE.md and docs/ but their source files are NOT in this specific repository snapshot. They need to be rebuilt or imported from C-Man's local workspace:

- **42+ PowerShell modules** (B11.Security, B11.Privacy, B11.Network, etc.)
- **BetterPE Phases 1-3** (ImageManagement, DriverIntegration, WinPE, BootConfig, etc.)
- **BetterShell v1-v2** (Core, PromptEngine, CompletionSystem, History, Theme, Nav, Git, Cloud)
- **16 MCP servers** (TypeScript, two monorepos)
- **45+ WinUI XAML pages**
- **Additional service implementations** beyond PowerShellService
- **NTFSLinker** utility
- **BetterPE Phase 3** (ImageSlimmer, UpdateIntegrator, ToolCatalog)

C-Man's local workspace contains all of this. This repo is the **unified scaffold + newest modules** that everything integrates into.

---

## Key Dependencies

### NuGet Packages
| Package | Version | Purpose |
|---------|---------|---------|
| Microsoft.WindowsAppSDK | 1.5+ | WinUI 3 framework |
| CommunityToolkit.Mvvm | 8.x | MVVM source generators |
| Microsoft.Extensions.DependencyInjection | 8.x | DI container |
| System.Management.Automation | 7.4+ | PowerShell hosting |
| xUnit | 2.7+ | Test framework |
| FluentAssertions | 6.x | Test assertions |
| Moq | 4.x | Mocking framework |
| StyleCop.Analyzers | 1.2+ | Code style enforcement |

### PowerShell Modules (dev dependencies)
| Module | Version | Purpose |
|--------|---------|---------|
| Pester | 5.5+ | PowerShell test framework |
| PSScriptAnalyzer | 1.22+ | PowerShell linting |

---

## Current State & Known Issues (March 2026)

### Build Status
- C# solution: **Builds clean** (Debug & Release)
- StyleCop: **0 warnings** (verified)
- PSScriptAnalyzer: **0 warnings** (verified against custom settings)
- xUnit: **20 tests passing**
- Pester: **21 tests passing** (Watcher, Scheduler, NetworkDeploy)

### Tech Debt
1. **Missing service implementations** — Only PowerShellService is implemented; other 8 interfaces need concrete implementations
2. **No XAML pages yet** — App project has no pages, just the project file
3. **MCP servers not in repo** — 16 TypeScript MCP servers exist separately
4. **Prior modules not merged** — 42+ PS modules from earlier sessions need integration
5. **No installer** — MSIX/WiX packaging not yet created

### Priority Order for Development
1. Implement remaining service interfaces (SystemInfoService, DriverService, etc.)
2. Build out WinUI pages (Dashboard, System Optimization, Drivers, Packages)
3. Import and integrate existing PS modules from C-Man's workspace
4. MCP server consolidation
5. Installer packaging

---

## Claude Code Session Tips

### Useful Aliases
```bash
# Build
alias b11build="dotnet build Better11.sln -c Debug"
alias b11test="dotnet test Better11.sln --verbosity normal"
alias b11lint="pwsh -c \"Invoke-ScriptAnalyzer -Path ./PowerShell -Recurse -Settings ./config/PSScriptAnalyzerSettings.psd1\""
alias b11pester="pwsh -c \"Invoke-Pester -Path ./PowerShell/Modules -Output Detailed\""
```

### Before Making Changes
1. Read `CLAUDE.md` for full project context
2. Read `docs/ARCHITECTURE.md` for layer responsibilities
3. Check `docs/DEDUPLICATION-REPORT.md` before creating new modules (avoid re-duplicating)
4. Run `dotnet build` to confirm clean baseline

### After Making Changes
1. `dotnet build` — must be 0 errors, 0 warnings
2. `dotnet test` — all tests must pass
3. PSScriptAnalyzer — 0 findings on any new/modified PS files
4. Pester — all tests pass with new coverage for new functions

### File Delivery
- C-Man prefers deliverables as **.zip archives**
- Always provide fully functional, production-ready code
- Include tests with 100% coverage
- Include proper documentation (comment-based help for PS, XML docs for C#)
