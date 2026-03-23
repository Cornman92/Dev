# cursor.md — Better11 AI Editor Configuration

> Configuration file for Cursor, Windsurf, and other AI-assisted editors.
> **Last Updated:** March 1, 2026
>
> **Full co-creation guide:** See [`../CURSOR.md`](../CURSOR.md) for the complete Cursor AI guide including architecture patterns, working with Claude Code, and detailed coding rules.

---

## Working with Claude Code

**Claude Code (claude.ai/code, model: claude-sonnet-4-6) is the lead architect.** Always read `CLAUDE.md` before making changes. See [`../CURSOR.md`](../CURSOR.md) for full collaboration guidelines.

---

## Project Context

Better11 is a Windows 11 system management platform comprising:
- C# WinUI 3 desktop app (.NET 8, MVVM with CommunityToolkit.Mvvm)
- 42+ PowerShell modules (B11.* prefix, 500+ cmdlets)
- 16 TypeScript MCP servers for Claude integration
- BetterPE imaging/deployment toolkit
- BetterShell terminal framework

**Dev workspace:** This repo lives under D:\Dev. For root scripts, MCP servers, dev-dashboard, and automations see **D:\Dev\README.md**, **D:\Dev\docs\USER-GUIDE.md**, **D:\Dev\docs\ROADMAP-300.md**.

---

## Rules

### General
- Always produce production-ready code, never placeholders or TODOs
- Follow existing patterns found in the codebase
- 100% test coverage for all new code
- Zero warnings from StyleCop (C#) and PSScriptAnalyzer (PowerShell)

### C# Rules
- Use file-scoped namespaces: `namespace Better11.Core.Models;`
- Enable nullable reference types everywhere
- Use `Result<T>` pattern for fallible operations (see src/Better11.Core/Models/Result.cs)
- Use `[ObservableProperty]` and `[RelayCommand]` from CommunityToolkit.Mvvm
- All services registered via DI in ServiceCollectionExtensions.cs
- Async methods must accept `CancellationToken` parameter
- Use primary constructors for simple DI: `public class Foo(IBar bar)`

### PowerShell Rules
- All cmdlets use `Verb-B11Noun` naming (approved verbs only)
- Every function requires `[CmdletBinding()]`, `[OutputType()]`, comment-based help
- State-changing functions must implement `SupportsShouldProcess`
- Use `[System.Collections.Generic.List[T]]` instead of `@() +=` for collections
- Module manifests (.psd1) must explicitly list all exported functions
- Private helper functions go in Private/ subfolder, not exported

### Testing Rules
- C# tests: xUnit + FluentAssertions + Moq
- PowerShell tests: Pester 5.x
- Test naming: `{Method}_Should_{Behavior}_When_{Condition}`
- Mock all external dependencies (filesystem, registry, network, processes)
- Include edge cases: null inputs, empty collections, permission failures

### File Organization
```
src/Better11.Core/          # Models, Enums, Interfaces, Helpers
src/Better11.Services/      # Service implementations
src/Better11.ViewModels/    # MVVM ViewModels
src/Better11.App/           # WinUI 3 shell, XAML pages
src/Better11.Tests/         # All test projects
PowerShell/Modules/B11.*/   # PowerShell modules
config/                     # Analyzer settings, CI config
build/                      # Build scripts
docs/                       # Project documentation
```

---

## Key Files to Reference

| When Working On | Reference These Files |
|----------------|----------------------|
| New C# model | `src/Better11.Core/Models/Result.cs`, existing models |
| New service | `src/Better11.Core/Services/Interfaces/ISystemOptimizationService.cs` |
| New ViewModel | `src/Better11.ViewModels/BaseViewModel.cs` |
| New XAML page | `src/Better11.App/Pages/DashboardPage.xaml` |
| New PS module | Any existing `B11.*.psm1` + its `.psd1` manifest |
| New PS test | Any existing `B11.*.Tests.ps1` |
| Build config | `Directory.Build.props`, `config/stylecop.json` |

---

## Dependencies

### NuGet Packages
- Microsoft.WindowsAppSDK (1.5+)
- CommunityToolkit.Mvvm (8.2+)
- Microsoft.Extensions.DependencyInjection (8.0+)
- System.Management.Automation (7.4+)
- xunit, Moq, FluentAssertions (test only)

### PowerShell Modules
- Pester (5.5+) — testing
- PSScriptAnalyzer (1.22+) — static analysis

---

## Common Tasks

### Add a new PowerShell module
1. Create `PowerShell/Modules/B11.{Name}/B11.{Name}.psm1`
2. Create `PowerShell/Modules/B11.{Name}/B11.{Name}.psd1`
3. Create `PowerShell/Modules/B11.{Name}/B11.{Name}.Tests.ps1`
4. Add C# service interface in `src/Better11.Core/Services/Interfaces/`
5. Add C# service implementation in `src/Better11.Services/Implementations/`
6. Register in `ServiceCollectionExtensions.cs`

### Add a new WinUI page
1. Create ViewModel in `src/Better11.ViewModels/{Feature}ViewModel.cs`
2. Create page in `src/Better11.App/Pages/{Feature}Page.xaml` + `.xaml.cs`
3. Register ViewModel as transient in `App.xaml.cs`
4. Add NavigationViewItem in `MainWindow.xaml`
5. Add page mapping in `NavigationConstants.cs`
6. Add tests for ViewModel
