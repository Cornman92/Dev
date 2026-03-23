# ARCHITECTURE.md — Better11 System Architecture

> **Last Updated:** March 1, 2026

---

## Layer Diagram

```
┌────────────────────────────────────────────────────────┐
│  UI Layer: Better11.App (WinUI 3 / XAML)              │
│  45+ pages, NavigationView shell, Command Palette     │
├────────────────────────────────────────────────────────┤
│  Presentation: Better11.ViewModels (MVVM)             │
│  CommunityToolkit.Mvvm, async commands, validation    │
├────────────────────────────────────────────────────────┤
│  Business: Better11.Services                          │
│  Service interfaces + implementations, PowerShell bridge│
├────────────────────────────────────────────────────────┤
│  Domain: Better11.Core                                │
│  Models, Enums, Result<T>, Configuration, Logging     │
├────────────────────────────────────────────────────────┤
│  Infrastructure: PowerShell Modules (42+)             │
│  Windows API wrappers, WMI/CIM, Registry, DISM        │
├────────────────────────────────────────────────────────┤
│  External: MCP Servers (16 TypeScript)                │
│  Claude integration for development workflows          │
└────────────────────────────────────────────────────────┘
```

---

## Data Flow

```
User Action → XAML Page → ViewModel (Command)
                              ↓
                        C# Service (async)
                              ↓
                  PowerShellService.InvokeAsync()
                              ↓
                    RunspacePool → B11.* Module
                              ↓
                  Windows API / WMI / Registry
                              ↓
                    Result<T> → ViewModel → UI
```

---

## Key Design Decisions

1. **RunspacePool over single runspace:** Enables parallel PS execution without UI blocking
2. **Result<T> over exceptions:** Explicit error handling, no surprise throws
3. **Module-per-feature:** Each PS module is independently loadable and testable
4. **Service abstraction:** C# services wrap PS calls, enabling unit testing with mocks
5. **Undo journal:** All optimization operations are reversible via registry snapshots
6. **WinPE 5.1 fallback:** BetterPE modules use PS 5.1 syntax for PE compatibility

---

## Startup and performance

- **Startup measurement:** The app logs startup time in two phases: (1) from App constructor to DI ready, and (2) from App to MainWindow activated. Check log output for `Startup (constructor to DI ready)` and `Startup (App to MainWindow activated)` to baseline and track regressions. Target: under 3 seconds to main window.
- **PowerShell lazy-load:** `PowerShellService` does not load any PowerShell modules at construction. Modules are imported on **first use** via `EnsureModuleImportedAsync` when a command from that module is invoked. This keeps startup fast; the first call to a given module may be slower while the module loads.
