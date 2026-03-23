# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Identity

**Better11** is an all-in-one Windows System Enhancement Suite — a hybrid C# WinUI 3 desktop app + PowerShell module backend for optimizing, customizing, and deploying Windows (live and offline images).

- **Target:** Power users, gamers, developers (C-Man is the lead/owner)
- **Interfaces:** WinUI 3 GUI (desktop) + PowerShell TUI (WinPE + Windows)
- **Lead architect:** Claude Code | **Dev assistant:** Cursor AI

> See **CLAUDE-CODE.md** for detailed how-to guides, patterns, and current known issues.

## Dev Workspace Context

Better11 lives under **D:\Dev**. The workspace root has MCP servers, dev-dashboard, migration/consolidation scripts, and automations. See **D:\Dev\README.md**, **D:\Dev\FEATURES-AND-AUTOMATIONS-PLAN.md**, **D:\Dev\docs\USER-GUIDE.md**, and **D:\Dev\docs\ROADMAP-300.md** for the full picture.

## Repository Layout

```
D:\Dev\Better11\
├── Better11/                     # .NET solution root
│   ├── Better11.sln              # Primary solution file
│   ├── Directory.Build.props     # Shared MSBuild props (net8.0, nullable, StyleCop, TreatWarningsAsErrors)
│   ├── global.json               # SDK pin (8.0.x)
│   ├── src/
│   │   ├── Better11.Core/        # Interfaces, DTOs, Result<T>, Constants
│   │   ├── Better11.Services/    # 11 PowerShell-backed service implementations
│   │   ├── Better11.ViewModels/  # 14 MVVM ViewModels (CommunityToolkit.Mvvm)
│   │   └── Better11.App/         # WinUI 3 shell, NavigationView, 14 XAML pages, DI
│   └── tests/
│       ├── Better11.Core.Tests/
│       ├── Better11.Services.Tests/
│       ├── Better11.ViewModels.Tests/
│       └── Better11.IntegrationTests/
├── PowerShell/Modules/           # 20+ B11.* PowerShell modules
│   ├── B11.BetterShell/          # Terminal framework (6 sub-modules, 77 exported functions)
│   ├── B11.BetterPE/             # WinPE imaging + PXE/WDS deployment
│   └── B11.{Feature}/            # Per-feature modules (B11.Network, B11.Privacy, etc.)
├── config/                       # stylecop.json, Better11.ruleset, PSScriptAnalyzerSettings.psd1
├── build/                        # Build-Better11.ps1 unified build script
└── docs/                         # ARCHITECTURE.md, DEDUPLICATION-REPORT.md, CHANGELOG.md
```

## Build & Test Commands

```powershell
# From D:\Dev\Better11\Better11\

# Restore + build (warnings are errors)
dotnet restore Better11.sln
dotnet build Better11.sln -c Release

# Run C# tests
dotnet test Better11.sln -c Release --verbosity normal

# Single test project
dotnet test tests/Better11.Services.Tests -c Release

# PowerShell linting (0 violations required)
pwsh -c "Invoke-ScriptAnalyzer -Path ../PowerShell -Recurse -Settings ../config/PSScriptAnalyzerSettings.psd1"

# Pester tests
pwsh -c "Invoke-Pester -Path ../PowerShell/Modules -Output Detailed"

# Full unified build
pwsh -File ../build/Build-Better11.ps1 -Configuration Release -RunTests -RunAnalyzers
```

## Architecture

### C# Layer Dependency Flow
```
App (WinUI 3) → ViewModels → Services → Core
                                ↓
                         PowerShellService → B11.* Modules
```

### Full-Stack Feature Pattern (mandatory for every new feature)
```
PowerShell Module (.psm1 + .psd1)
  → C# Models (sealed records + enums in Better11.Core)
    → Interface (IXxxService.cs in Better11.Core/Interfaces)
      → Service (XxxService.cs in Better11.Services) — ConcurrentDictionary, SemaphoreSlim, ILogger
        → ViewModel (XxxViewModel.cs) — [ObservableProperty], [RelayCommand]
          → XAML Page (.xaml + .xaml.cs in Better11.App)
            → xUnit Tests (ServiceTests + ViewModelTests)
              → Pester Tests (.Tests.ps1)
```

### Result\<T\> Pattern (all fallible service methods)
```csharp
// Never throw for expected failures — use Result<T>
Result<T>.Success(value)
Result<T>.Failure("error message")
result.Map(v => transform(v))
```

### Error handling and code patterns
- **Services:** Catch exceptions in async methods; log with `_logger.LogError(ex, ...)` then return `Result.Failure(ex)` or `Result<T>.Failure(ErrorCodes.Exception, ex.Message)`. Do not let exceptions bubble to the UI unhandled.
- **ViewModels:** Use `SetErrorFromResult(result)` (from BaseViewModel) when a service returns a failed Result; this sets the status message for the user. Use `SafeExecuteAsync` for command handlers so exceptions are caught and surfaced.
- **Consistency:** Avoid duplicating "invoke PowerShell module then map to DTO" logic across services; use shared helpers or base patterns. Use `ArgumentNullException.ThrowIfNull(x)` for constructor and public API null checks. Follow existing naming (e.g. `XxxService`, `IXxxService`, `XxxViewModel`).

### ViewModel Pattern
```csharp
public partial class FeatureViewModel : BaseViewModel
{
    [ObservableProperty] private bool _isLoading;
    [RelayCommand]
    private async Task LoadAsync(CancellationToken ct) { ... }
}
```

### PowerShell Module Pattern
```powershell
function Verb-B11Noun {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([PSCustomObject])]
    param([Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$Name)
    process { if ($PSCmdlet.ShouldProcess($Name, 'Action')) { ... } }
}
```

## Code Standards (zero tolerance)

### C#
- `TreatWarningsAsErrors` is ON — **0 StyleCop warnings**
- Nullable enabled — no `null` without `?`
- File-scoped namespaces (`namespace Better11.Core.Models;`)
- `Result<T>` for all fallible ops — never throw for expected failures
- All async methods take `CancellationToken`; services use `ConfigureAwait(false)`, ViewModels use `ConfigureAwait(true)`
- Register all services in `ServiceCollectionExtensions.cs` (constructor injection only)

### PowerShell
- **0 PSScriptAnalyzer violations** against `config/PSScriptAnalyzerSettings.psd1`
- `[CmdletBinding(SupportsShouldProcess)]` on every function; `[OutputType()]` required
- `SupportsShouldProcess` on ALL state-changing functions (Set, New, Remove, Start, Stop)
- All public functions: `Verb-B11Noun` naming + comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
- `#Requires -Version 5.1`, `Set-StrictMode -Version Latest`, `$ErrorActionPreference = 'Stop'`

### Tests
- 100% coverage of all new public API surface
- C#: xUnit + FluentAssertions + Moq | naming: `Method_Should_Expected_When_Condition`
- PS: Pester 5.x `Describe/Context/It` blocks

## Current State

**WS7 (Final Zero-Error Pass) is the sole remaining work stream.**

Tasks: `dotnet build -warnaserrors` → 0 errors; StyleCop sweep → 0 warnings; PSScriptAnalyzer sweep → 0 violations; full test pass (218 xUnit + 21+ Pester); XML doc on all public APIs; verify all services registered in `ServiceCollectionExtensions`.

Previously built (WS1–WS6 complete): 11 services, 14 ViewModels, 14 XAML pages, 218 C# test methods, BetterShell v3.0 (77 functions), BetterPE Phase 4 (PXE/WDS), First Run Wizard, integration test suites.

## Agent Rules

1. All work lives inside `Better11/` — never create loose files at the repo root
2. Prefer editing existing files over creating new ones
3. Check `Better11.Core/` for existing helpers before creating new utilities
4. Check `docs/DEDUPLICATION-REPORT.md` before adding new PS modules (avoid re-duplicating)
5. `configs/` for JSON config — never hardcode values in scripts
6. Deliverables: C-Man prefers **.zip archives** for file delivery
