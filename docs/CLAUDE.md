# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Better11 System Enhancement Suite** is a comprehensive Windows system optimization, management, and customization platform. The project combines multiple technologies (C#/.NET, PowerShell, TypeScript/React, Tauri) to provide tools for driver management, registry editing, package management, system optimization, and more.

**Target Platform:** Windows 10/11
**Architecture:** Multi-technology suite with MVVM pattern
**Primary Languages:** C# (.NET 8/10), PowerShell 7+, TypeScript, Rust (Tauri backend)

## Repository Structure

This repository contains multiple interconnected projects:

- **Better11/** - Main WinUI 3 application suite
  - Core C# libraries and services
  - PowerShell modules for system operations
  - WinUI 3 GUI applications

- **platform/** - Platform workflows and applications
  - Shared components and utilities
  - Development tools and scaffolding
  - Various sub-applications

- **tools/** - Utility tools and third-party dependencies
  - Build and deployment tools
  - Testing utilities

- **Dev workspace root (D:\Dev)** - Scripts, MCP servers, dashboard
  - `package.json`: `npm run test:mcp-all`, `report:workspace`, `dashboard:start`
  - Scripts: `Generate-WorkspaceReport.ps1`, `Invoke-McpHealthCheck.ps1`, `Invoke-AllMcpTests.ps1`, `Test-ConsolidationState.ps1`, `Schedule-WorkspaceReport.ps1`, `Invoke-MigrationDryRun.ps1`
  - Migration: `Invoke-DevMigration.ps1`, `consolidate_workspace.ps1` (use `-WhatIf` first)
  - See **FEATURES-AND-AUTOMATIONS-PLAN.md**, **docs/ROADMAP-300.md**, **docs/USER-GUIDE.md**

- **dev-dashboard/** - Node/Express dashboard at http://localhost:3000
  - API: `/api/projects`, `/api/workspace-report`, `/api/mcp-status`, `/api/quick-action`, `/api/code-analysis`, `/api/projects/:id/coverage`, `/api/projects/:id/deployments`

- **docs/** - Comprehensive documentation
  - Architecture documentation
  - Development guides
  - API references

## Technology Stack

### C# / .NET Projects
- **.NET 8/10** - Primary framework
- **WinUI 3** - Modern Windows UI framework
- **MVVM Pattern** - Architecture pattern using CommunityToolkit.Mvvm
- **Dependency Injection** - Microsoft.Extensions.DependencyInjection
- **PowerShell SDK** - For PowerShell integration from C#

### TypeScript / JavaScript Projects
- **React 18** - UI framework
- **Tauri 2.0** - Desktop application framework
- **Vite** - Build tool and dev server
- **TypeScript 5.3+** - Type-safe JavaScript
- **TanStack Query** - Data fetching and state management
- **Radix UI** - Accessible component primitives
- **Tailwind CSS** - Utility-first CSS framework

### PowerShell
- **PowerShell 7.4+** - Automation and system operations
- Modular architecture with 14+ modules
- Integration with C# via PowerShell SDK

### Supporting Tools
- **Spectre.Console** - Rich terminal UI for C# console apps
- **Playwright** - E2E testing
- **Vitest** - Unit testing for TypeScript
- **xUnit** - Unit testing for C#

## Common Development Commands

### TypeScript/React Projects (Root & Sub-projects)

```bash
# Development
npm run dev              # Start Vite dev server
npm run tauri:dev        # Start Tauri app in dev mode

# Building
npm run build            # TypeScript compile + Vite build
npm run tauri:build      # Build Tauri production binary

# Code Quality
npm run lint             # Run ESLint
npm run lint:fix         # Auto-fix ESLint issues
npm run format           # Format with Prettier
npm run format:check     # Check Prettier formatting
npm run typecheck        # Run TypeScript type checking

# Testing
npm test                 # Run Vitest tests
npm run test:ui          # Vitest UI mode
npm run test:coverage    # Generate coverage report
npm run test:unit        # Unit tests only
npm run test:integration # Integration tests only
npm run test:e2e         # Playwright E2E tests
```

### C# / .NET Projects

```bash
# Building
dotnet restore           # Restore NuGet packages
dotnet build             # Build solution
dotnet build -c Release  # Release build

# Running
dotnet run --project Better11.UI              # Run WinUI app
dotnet run --project Better11.TUI             # Run console TUI

# Testing
dotnet test                                   # Run all tests
dotnet test --filter "Category=Unit"          # Unit tests only
dotnet test --logger "console;verbosity=detailed"

# Publishing
dotnet publish -c Release                     # Publish release build
dotnet publish -c Release -r win-x64 --self-contained
```

### PowerShell Development

```powershell
# Module Development
Import-Module .\Better11.PowerShell\Modules\ModuleName.psm1
Get-Command -Module ModuleName

# Testing Modules
Invoke-Pester .\Tests\ModuleName.Tests.ps1

# Running Scripts
Set-ExecutionPolicy Bypass -Scope Process
.\scripts\script-name.ps1

# For system operations (run as Administrator)
Start-Process pwsh -Verb RunAs -ArgumentList "-File .\script.ps1"
```

### Multi-Project Workflows

```bash
# Build all .NET projects
dotnet build Better11.sln

# Build TypeScript projects
npm install && npm run build

# Full clean build
dotnet clean && dotnet restore && dotnet build
rm -rf node_modules && npm install && npm run build
```

## Architecture Principles

### MVVM Pattern (C# Projects)

The codebase follows strict MVVM separation:

1. **Models** (`Better11.Models/`) - Data structures and business entities
2. **ViewModels** (`Better11.ViewModels/`) - Presentation logic, commands, observable properties
3. **Views** (`Better11.UI/Views/`) - XAML UI definitions
4. **Services** (`Better11.Services/`) - Business logic, data access, external integrations

**Key Points:**
- ViewModels use `CommunityToolkit.Mvvm` attributes (`[ObservableProperty]`, `[RelayCommand]`)
- ViewModels are UI-agnostic and can be reused between WinUI 3 and TUI versions
- All dependencies injected via constructor
- Services registered in DI container at startup

### PowerShell Integration

C# projects integrate with PowerShell modules through `PowerShellService`:

```csharp
// C# calls PowerShell modules
var drivers = await _psService.ExecuteCommandAsync<Driver>(
    "DriverManagement",      // Module name
    "Get-InstalledDrivers",  // Function name
    parameters               // Parameters dictionary
);
```

**PowerShell modules are located in:**
- `Better11.PowerShell/Modules/` (main modules)
- `Better11/powershell/GaymerPC/` (legacy/additional modules)

### Project Dependencies

**Typical dependency flow:**
```
UI Layer (WinUI/TUI)
  → ViewModels
    → Services
      → PowerShell Modules / External APIs
      → Repositories
        → Models
```

### Error Handling

- Use `Result<T>` pattern for operation results
- Custom exceptions inherit from `Better11Exception`
- Structured logging with `ILogger<T>`
- User-friendly error messages in UI layer

## Important Patterns

### Async/Await
- All I/O operations must be async
- Use `ConfigureAwait(false)` in library code
- Support `CancellationToken` for long-running operations
- Provide `IProgress<T>` for progress reporting

### Dependency Injection
Services registered in `Program.cs` or `App.xaml.cs`:
```csharp
services.AddSingleton<IPowerShellService, PowerShellService>();
services.AddSingleton<IPackageService, PackageService>();
services.AddTransient<PackageManagerViewModel>();
```

### Resource Management
- Use `using` statements for `IDisposable`
- Implement `IAsyncDisposable` for async cleanup
- Properly dispose PowerShell runspaces

## Code Quality Standards

### C# Standards
- Follow Microsoft C# coding conventions
- Use nullable reference types
- XML documentation for public APIs
- Target .NET 8 minimum (.NET 10 preferred)
- EditorConfig enforces style

### TypeScript Standards
- Strict TypeScript mode enabled
- ESLint with React hooks rules
- Prettier for consistent formatting
- Props interfaces for all components
- Type inference over explicit types where clear

### PowerShell Standards
- Use approved verbs (Get, Set, New, Remove, Install, Optimize, etc.)
- Comment-based help for all exported functions
- Support `-WhatIf` and `-Confirm` for state-changing operations
- Proper error handling with try/catch
- Parameter validation attributes

## Testing Strategy

### C# Testing
- **xUnit** for unit tests
- **Moq** for mocking
- Test naming: `MethodName_Scenario_ExpectedResult`
- Integration tests in separate project

### TypeScript Testing
- **Vitest** for unit/integration tests
- **Testing Library** for component tests
- **Playwright** for E2E tests
- Tests colocated with source or in `__tests__/`

### PowerShell Testing
- **Pester v5+** for module testing
- Tests in `Tests/` directory
- Mock external dependencies

## Administrator Privileges

⚠️ **CRITICAL:** Many system operations require administrator privileges:
- Driver management
- Registry modifications (HKLM)
- System optimization
- Windows image operations (DISM)

Always check and request elevation when needed. Use UAC prompts appropriately.

## Multi-Language Project Coordination

This repository contains projects in multiple languages that work together:

1. **PowerShell modules** provide system-level operations
2. **C# services** wrap PowerShell and provide business logic
3. **C# ViewModels** handle presentation logic
4. **WinUI 3 views** provide rich GUI (some projects)
5. **React/Tauri** provide cross-platform desktop UI (some projects)
6. **Console TUI** with Spectre.Console (development tools)

When modifying functionality:
- Start with PowerShell module if system operations change
- Update C# service layer
- Modify ViewModel if UI logic changes
- Update View only for visual changes

## Key Files and Locations

- **INDEX.md** - Master documentation index
- **GETTING_STARTED.md** - Setup and onboarding
- **02-CODE-STANDARDS.md** - Comprehensive coding standards
- **Better11.sln** - Main C# solution (multiple locations)
- **package.json** - Root NPM project configuration
- **global.json** - .NET SDK version pinning

## Development Environment

**Required:**
- Windows 10 (Build 22621+) or Windows 11
- Visual Studio 2022 or VS Code with C# extensions
- .NET 8/10 SDK
- PowerShell 7.4+
- Node.js 20+ and npm 10+
- Git

**Optional:**
- Windows SDK
- Tauri CLI
- Windows ADK (for image operations)

## Git Workflow

- Repository synced via OneDrive (`D:\OneDrive\Dev`)
- Standard Git workflow with feature branches
- Commit frequently with descriptive messages
- Pre-commit hooks run linting and formatting

## Performance Considerations

- PowerShell operations can be slow - show progress for long operations
- DISM operations require significant time - support cancellation
- Large file operations - stream when possible
- UI must remain responsive - all heavy work on background threads

## Security Notes

- Never log sensitive information (passwords, API keys)
- Validate all user input
- Use parameterized queries/commands
- Store secrets in Windows Credential Manager
- ProtectedData API for local encryption
- Elevated operations require explicit user consent

## Common Pitfalls

1. **Blocking on async code** - Never use `.Result` or `.Wait()`
2. **Missing admin check** - Check privileges before system operations
3. **Unhandled PowerShell errors** - Always wrap in try/catch
4. **Memory leaks** - Dispose PowerShell runspaces and WMI objects
5. **Path separators** - Use `Path.Combine()`, not string concatenation
6. **Hard-coded paths** - Use configuration or environment variables

## Project Naming

Projects follow patterns:
- **GaymerPC-[Feature]** - Original naming convention (legacy)
- **Better11.[Layer]** - Modern C# project naming
- Module names descriptive of functionality

## Notes for Claude Code

- This is a **Windows-only** development environment
- Many operations require **administrator privileges**
- Multiple **sub-projects** may need individual attention
- Respect the **MVVM pattern** strictly in C# projects
- **PowerShell integration** is a core architectural component
- Consult **02-CODE-STANDARDS.md** for detailed coding guidelines
- Check **INDEX.md** for documentation navigation
- Test C# changes with both WinUI and TUI interfaces where applicable
- TypeScript projects use strict mode - respect type safety
- Long-running operations must support cancellation and progress reporting
