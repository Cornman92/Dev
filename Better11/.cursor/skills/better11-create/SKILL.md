---
name: better11-create
description: Guides development and contribution to Better11 (codebase, build, tests, work streams WS1–WS7). Use when creating, extending, or fixing Better11; building or testing the solution; or discussing architecture, C#/WinUI/PowerShell patterns, or work stream status.
---

# Better11 — Create (Development)

Use this skill when **creating or contributing to Better11**: building the app, writing code, running tests, or planning work streams.

## Key Files

- **CLAUDE.md** — Project identity, architecture, mandatory patterns.
- **CURSOR.md** — Co-developer guide, Result/ViewModel/Service patterns, key files.
- **PLAN.md** — Work stream status (WS1–WS7), deliverables.
- **STYLE-GUIDE.md** — UI design (B11 tokens, dense layout, WinUtil aesthetic).
- **src/Better11.Core/Common/Result.cs** — Result pattern.
- **src/Better11.Core/Interfaces/IServiceInterfaces.cs** — Service contracts.
- **src/Better11.ViewModels/Base/BaseViewModel.cs** — ViewModel base.

## Patterns (Mandatory)

- **Result&lt;T&gt;** for all service returns; **BaseViewModel** for all VMs; **CancellationToken** on async; **ConfigureAwait(false)** in services only.
- **No new dependencies** — stack is set (CommunityToolkit.Mvvm, FluentAssertions, Moq, xUnit).
- **No refactor without asking** — architecture is intentional.
- **Tests:** xUnit + FluentAssertions + Moq for C#; Pester v5 for PowerShell.

## MCP Tools (Create Phase)

When the Better11 MCP server is enabled, use:

- **better11_create_build** — Build solution (Debug/Release).
- **better11_create_test** — Run tests (optional filter).
- **better11_create_list_workstreams** — List WS1–WS7 status.

## Work Streams (Quick Reference)

| WS | Status | Focus |
|----|--------|--------|
| WS1–WS6 | Complete | Reporting, Testing, Certificates, Appearance/RAM Disk, UI Redesign, First Run Wizard |
| WS7 | Active focus | Zero-error pass (StyleCop, PSScriptAnalyzer, tests) |

## Commands

```bash
dotnet build Better11/Better11.sln
dotnet test Better11/Better11.sln --no-build
```
