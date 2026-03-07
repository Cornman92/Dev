# Contributing to Better11

Thank you for your interest in contributing. This document covers build, test, style, and how to contribute code and report issues.

## Build and Test

- **Build:** See [BUILD.md](BUILD.md). From `Better11\Better11` run:
  ```powershell
  .\scripts\Build-Better11.ps1 -Configuration Release -Test
  ```
- **Tests:** All C# tests must pass (`dotnet test`). Use `.\scripts\Build-Better11.ps1 -Configuration Release -Test` to run with code coverage. Coverage reports are in `TestResults/`; aim for 90%+ on Better11.Core where practical. PowerShell modules should pass Pester and PSScriptAnalyzer (zero violations). See BUILD.md for commands.

## Code Standards

- **C#:** Follow the patterns in [CLAUDE.md](CLAUDE.md) and [CURSOR.md](CURSOR.md). StyleCop and treat-warnings-as-errors are enabled; no warnings.
- **PowerShell:** PSScriptAnalyzer with project settings; no violations. Use approved verbs and comment-based help.
- **Architecture:** New features use the full-stack pattern: PowerShell module → Core models → Interface → Service → ViewModel → XAML → tests. Use `Result<T>` for fallible operations; use DI and CommunityToolkit.Mvvm in the app.

## Reporting Bugs

- **Where:** GitHub Issues (or the project’s issue tracker).
- **Include:** OS version, Better11 version (from About), steps to reproduce, expected vs actual behavior, and any error text or logs (no passwords or secrets).

## Pull Requests

- Branch from `main` or `develop`, keep changes focused.
- Ensure the solution builds and all tests pass. Run StyleCop and PSScriptAnalyzer locally.
- Update documentation if you change behavior or add features. Follow existing style (file-scoped namespaces, XML docs for public APIs).

## Branch Strategy

- `main` — stable, always builds
- `develop` — integration branch
- `feature/{module}-{description}` — feature work
- `fix/{issue-number}` — bug fixes

## Commit Messages

```
type(scope): description

feat(B11.Security): add Windows Defender ASR rule management
fix(BetterPE): correct driver injection path for WinPE x64
test(B11.Network): add DNS configuration edge case tests
docs(CLAUDE.md): update module inventory
```

## Documentation

- **Architecture:** [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- **Style:** [STYLE-GUIDE.md](STYLE-GUIDE.md)
- **Versioning:** [docs/VERSIONING.md](docs/VERSIONING.md)
- **Release process:** [RELEASE.md](RELEASE.md)

## Development Team

- **Claude Code** (claude.ai/code) — Lead architect
- **Cursor AI** — Development assistant
- **Windsurf** — Development assistant

Questions about architecture or patterns should refer to CLAUDE.md and CURSOR.md.
