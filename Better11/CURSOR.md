# CURSOR.md — Better11 Co-Creation Guide for Cursor AI

## Your Role

You are a development assistant on **Better11**, an all-in-one Windows System Enhancement Suite. **Claude Code (claude.ai/code, model: claude-sonnet-4-6) is the lead architect** and has built the majority of the codebase (~115K+ LOC). Your job is to assist with bug fixes, maintenance, and new work. You take direction from Claude Code's architecture decisions documented in CLAUDE.md.

## Working with Claude Code

**Claude Code is always the lead.** When working alongside Claude Code on this project:

- **Read `CLAUDE.md` first** — it is the authoritative source for all architecture, patterns, and conventions
- **Do not refactor** without asking — the architecture is intentional and Claude Code may be working in related areas
- **Do not add new dependencies** — the stack is locked (CommunityToolkit.Mvvm, FluentAssertions, Moq, xUnit, Pester)
- **Do not create new abstractions** — use existing patterns documented in CLAUDE.md
- **Defer on interface changes** — multiple files depend on interfaces; flag before changing and coordinate with Claude Code
- **Keep changes minimal** — fix what was asked, nothing more
- **Focus on different files** — to avoid merge conflicts, check what Claude Code is currently working on before starting
- **Claude Code has final say** on all architecture and design decisions

If you find a bug, fix it and document the fix clearly. If you're unsure about a pattern, check `CLAUDE.md` before inventing something new.

## Project Overview

**Better11** is a hybrid C# WinUI 3 + PowerShell platform for Windows power users. It lives in **D:\Dev\Better11**. The Dev workspace root (D:\Dev) includes MCP servers, dev-dashboard, and automations — see **D:\Dev\README.md**, **D:\Dev\docs\USER-GUIDE.md**, and **D:\Dev\docs\ROADMAP-300.md**. It optimizes, customizes, and personalizes both live and offline Windows installations.

- **Frontend:** WinUI 3 (.NET 8+) with CommunityToolkit.Mvvm
- **Backend:** 102 PowerShell modules invoked via `IPowerShellService`
- **Architecture:** MVVM + DI container + Result<T> pattern
- **UI Style:** Dense dark WinUtil-inspired (#111111 bg, #0078D4 accent, 24px rows)
- **LOC:** ~115K+ across 550+ files

## Directory Structure

```
D:\Dev\Better11\Better11\
├── src\
│   ├── Better11.App\          # WinUI 3 GUI (XAML pages, controls, converters, themes)
│   │   ├── Views\             # All page XAML + code-behind
│   │   ├── Controls\          # Custom controls (DenseCheckboxGrid, ConsoleOutputPanel, etc.)
│   │   ├── Converters\        # Value converters
│   │   ├── Themes\            # DarkTheme.xaml, LightTheme.xaml
│   │   └── Extensions\        # ServiceCollectionExtensions.cs (DI registration)
│   ├── Better11.Core\         # Shared foundation
│   │   ├── Common\            # Result.cs, ErrorInfo, ErrorCodes
│   │   ├── Constants\         # AppConstants.cs, SettingsConstants.cs
│   │   └── Interfaces\        # All service interfaces + DTOs (IServiceInterfaces.cs)
│   ├── Better11.Services\     # Service implementations (one folder per domain)
│   │   ├── Optimization\      # OptimizationService.cs
│   │   ├── Privacy\           # PrivacyService.cs
│   │   ├── Security\          # SecurityService.cs
│   │   ├── Package\           # PackageService.cs
│   │   ├── Driver\            # DriverService.cs
│   │   ├── Network\           # NetworkService.cs
│   │   ├── DiskCleanup\       # DiskCleanupService.cs
│   │   ├── Startup\           # StartupService.cs
│   │   ├── ScheduledTask\     # ScheduledTaskService.cs
│   │   ├── SystemInfo\        # SystemInfoService.cs
│   │   ├── Update\            # UpdateService.cs
│   │   └── PowerShell\        # PowerShellService.cs (420 LOC, core PS bridge)
│   └── Better11.ViewModels\   # MVVM ViewModels (one folder per page)
│       ├── Base\              # BaseViewModel.cs (271 LOC — ALL VMs inherit from this)
│       ├── Dashboard\         # DashboardViewModel.cs
│       ├── Optimization\      # OptimizationViewModel.cs
│       ├── Privacy\           # PrivacyViewModel.cs
│       ├── Wizard\            # FirstRunWizardViewModel.cs
│       └── ... (14 more)
├── tests\
│   ├── Better11.Core.Tests\          # Result<T> tests
│   ├── Better11.Services.Tests\      # Service unit tests (11 files)
│   ├── Better11.ViewModels.Tests\    # ViewModel tests (14 files)
│   └── Better11.IntegrationTests\    # 6 integration test suites (138+ tests)
└── configs\                          # JSON configuration files
```

## Critical Patterns — You MUST Follow These

### 1. Result<T> Pattern
Every service method returns `Result` or `Result<T>`:
```csharp
// Success
return Result<T>.Success(value);
return Result.Success();

// Failure
return Result<T>.Failure("error message");
return Result<T>.Failure(ErrorCodes.PowerShell, "PS command failed");
return Result.Failure(exception);
```

### 2. ViewModel Base Class
ALL ViewModels inherit from `BaseViewModel`:
```csharp
public sealed partial class MyViewModel : BaseViewModel
{
    public MyViewModel(IMyService service, ILogger<MyViewModel> logger)
        : base(logger)
    {
        _service = service ?? throw new ArgumentNullException(nameof(service));
        PageTitle = "My Page";
    }

    [ObservableProperty]
    private string _someValue = string.Empty;

    [RelayCommand]
    private async Task DoSomethingAsync(CancellationToken cancellationToken = default)
    {
        await SafeExecuteAsync(
            async ct =>
            {
                var result = await _service.DoThingAsync(ct).ConfigureAwait(false);
                if (result.IsSuccess) { /* update state */ }
                else { SetErrorFromResult(result); }
            },
            "Doing something...",
            cancellationToken).ConfigureAwait(false);
    }
}
```

### 3. Service Pattern
```csharp
public sealed class MyService : IMyService
{
    private readonly IPowerShellService _ps;
    private readonly ILogger<MyService> _logger;

    public async Task<Result<T>> GetDataAsync(CancellationToken ct = default)
    {
        try
        {
            return await _ps.InvokeCommandAsync<T>(
                "Better11.ModuleName", "Get-B11DataName",
                parameters, ct).ConfigureAwait(false);
        }
        catch (OperationCanceledException)
        {
            return Result<T>.Failure(ErrorCodes.Cancelled, "Cancelled");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get data");
            return Result<T>.Failure(ex);
        }
    }
}
```

### 4. Test Pattern
```csharp
public sealed class MyServiceTests
{
    private readonly Mock<IPowerShellService> _mockPs;
    private readonly MyService _service;

    [Fact]
    public async Task Method_ReturnsSuccess_WhenPowerShellSucceeds()
    {
        _mockPs.Setup(x => x.InvokeCommandAsync<MyDto>(
            "Better11.Module", "Get-B11Command",
            It.IsAny<IDictionary<string, object>>(), It.IsAny<CancellationToken>()))
            .ReturnsAsync(Result<MyDto>.Success(new MyDto()));

        var result = await _service.MethodAsync(CancellationToken.None);
        result.IsSuccess.Should().BeTrue();
    }
}
```

### 5. XAML Theme Usage
Always use B11 theme resources, never hardcode:
```xml
<Border Style="{StaticResource B11DenseCardStyle}">
    <TextBlock Text="Title"
               FontSize="{StaticResource B11FontSizeTitle}"
               Foreground="{StaticResource B11TextPrimaryBrush}"/>
</Border>
```

## Coding Standards

### C#
- File-scoped namespaces
- `sealed` classes (services, ViewModels, DTOs)
- `// Copyright (c) Better11. All rights reserved.` header
- XML docs on all public members
- `CancellationToken` on every async method
- `ConfigureAwait(false)` in services, NOT in ViewModels
- `ArgumentException.ThrowIfNullOrWhiteSpace()` for validation
- Zero StyleCop violations

### PowerShell
- `#Requires -Version 5.1`
- `Set-StrictMode -Version Latest`
- `[CmdletBinding()]` + `[OutputType()]` on every function
- `SupportsShouldProcess` on mutating functions
- Module naming: `Better11.*`
- Zero PSScriptAnalyzer violations

### Tests
- xUnit with `[Fact]`
- FluentAssertions (`.Should().Be()`)
- Moq for mocking
- Pester v5 for PowerShell

## Current Status (2026-03-01)

- **WS1-WS7: COMPLETE** — All 7 work streams done, production-ready
- **Code Quality:** 0 StyleCop/PSScriptAnalyzer violations
- **Test Coverage:** 1,800+ tests

## Coding Rules

### C#
- File-scoped namespaces: `namespace Better11.Services.Foo;`
- Enable nullable reference types everywhere
- `sealed` classes for services, ViewModels, DTOs
- `Result<T>` for all fallible operations (see `src/Better11.Core/Common/Result.cs`)
- `[ObservableProperty]` / `[RelayCommand]` from CommunityToolkit.Mvvm
- All services registered via DI in `ServiceCollectionExtensions.cs`
- Every async method accepts `CancellationToken`
- `ConfigureAwait(false)` in services; NOT in ViewModels
- `Copyright (c) Better11. All rights reserved.` header on every file
- Zero StyleCop violations

### PowerShell
- `#Requires -Version 5.1` + `Set-StrictMode -Version Latest`
- `[CmdletBinding()]` + `[OutputType()]` on every function
- `SupportsShouldProcess` on all state-changing functions
- Naming: `Verb-B11Noun` (approved verbs only), module prefix `Better11.*`
- Zero PSScriptAnalyzer violations

### Tests
- xUnit + FluentAssertions + Moq
- Pester v5 for PowerShell
- Naming: `Method_Scenario_ExpectedResult`
- Mock all external dependencies

## Key Files to Reference

| When working on | Read first |
|----------------|-----------|
| New C# service | `src/Better11.Core/Interfaces/IServiceInterfaces.cs`, any existing service |
| New ViewModel | `src/Better11.ViewModels/Base/BaseViewModel.cs` |
| New XAML page | `src/Better11.App/Themes/DarkTheme.xaml`, existing page |
| New PS module | Any existing `Better11.*.psm1` + `.psd1` |
| UI/theme | `STYLE-GUIDE.md`, `src/Better11.App/Themes/DarkTheme.xaml` |
| DI registration | `src/Better11.App/Extensions/ServiceCollectionExtensions.cs` |
| Error handling | `src/Better11.Core/Common/Result.cs` |

## Common Tasks

### Add a new PowerShell module
1. Create `PowerShell/Modules/Better11.{Name}/Better11.{Name}.psm1` + `.psd1`
2. Create `PowerShell/Modules/Better11.{Name}/Tests/Better11.{Name}.Tests.ps1`
3. Add C# service interface in `src/Better11.Core/Interfaces/IServiceInterfaces.cs`
4. Add C# service in `src/Better11.Services/{Name}/`
5. Register in `ServiceCollectionExtensions.cs`

### Add a new WinUI 3 page
1. Create ViewModel in `src/Better11.ViewModels/{Feature}/{Feature}ViewModel.cs`
2. Create page in `src/Better11.App/Views/{Feature}Page.xaml` + `.xaml.cs`
3. Register ViewModel as transient in `ServiceCollectionExtensions.cs`
4. Add NavigationViewItem in `MainWindow.xaml`
5. Write ViewModel tests in `tests/Better11.ViewModels.Tests/`

## Key Files to Read First

1. `CLAUDE.md` — Full project documentation
2. `PLAN.md` — Work stream status and deliverables
3. `STYLE-GUIDE.md` — UI design system
4. `src/Better11.Core/Common/Result.cs` — The Result pattern
5. `src/Better11.Core/Interfaces/IServiceInterfaces.cs` — All service contracts + DTOs
6. `src/Better11.ViewModels/Base/BaseViewModel.cs` — ViewModel base class
7. `src/Better11.App/Themes/DarkTheme.xaml` — Theme resource dictionary
8. `src/Better11.Services/PowerShell/PowerShellService.cs` — Core PS bridge
9. `.cursor/rules/*.mdc` — Cursor rule files for create/use/post phases

## Working Alongside Claude Code

- **Claude Code is the lead architect** — defer to CLAUDE.md for all architecture decisions
- Do not duplicate work — check what Claude is currently working on
- Focus on different files/areas to avoid merge conflicts
- If you find a bug, fix it and note the fix clearly in comments
- If you need to change an interface, flag it — multiple files depend on interfaces
- For questions about patterns or architecture, reference CLAUDE.md first
