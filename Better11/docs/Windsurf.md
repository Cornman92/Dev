# Better11 Development with Windsurf

**Last Updated:** 2026-03-01  
**IDE Support:** Windsurf (Cursor-based development environment)

---

## Overview

Better11 is fully compatible with Windsurf, providing an enhanced development experience with AI-assisted coding, intelligent refactoring, and seamless project management. The Dev workspace root (D:\Dev) includes MCP servers, dev-dashboard, and automations — see **D:\Dev\README.md** and **D:\Dev\docs\USER-GUIDE.md**.

---

## Windsurf Configuration

### Recommended Settings

Create `.windsurf/settings.json` in your Better11 workspace:

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.stylecop.analyzers": true,
    "source.organizeImports": true
  },
  "csharp.format.enable": true,
  "csharp.semanticHighlighting.enabled": true,
  "powershell.codeFormatting.autoCorrectAliases": true,
  "powershell.codeFormatting.preset": "Allman",
  "files.exclude": {
    "**/bin": true,
    "**/obj": true,
    "**/TestResults": true
  }
}
```

(This file is already created at `.windsurf/settings.json` in this repo.)

### Workspace Setup

1. **Open Better11 in Windsurf:**
   ```bash
   windsurf d:\Dev\Better11
   ```

2. **Install recommended extensions:**
   - C# Dev Kit
   - PowerShell
   - StyleCop Analyzers
   - XAML Tools
   - .NET Runtime Install Tool

---

## Development Workflow

### 1. Project Navigation

Windsurf provides intelligent project navigation:

```windsurf
# Navigate to key project areas
/src/Better11.App/          # WinUI 3 Application
/src/Better11.Core/         # Core abstractions and Result<T> pattern
/src/Better11.Services/     # PowerShell bridge services
/src/Better11.ViewModels/   # MVVM ViewModels
/PowerShell/Modules/        # PowerShell backend modules
/tests/                     # xUnit and Pester tests
```

### 2. AI-Assisted Development

Better11 leverages Windsurf's AI capabilities for code generation, refactoring, and testing. See [ARCHITECTURE.md](ARCHITECTURE.md) for patterns.

---

## Debugging

Use `.vscode/launch.json` (already configured in this repo):

- **Debug Better11 App** — Builds `Better11/Better11.sln` and launches the WinUI app
- **Debug Better11 App (root src)** — Builds root `Better11.sln` and launches
- **Debug PowerShell Module** — Runs Pester tests for PowerShell modules

---

## Working with Claude Code

**Claude Code (claude.ai/code, model: claude-sonnet-4-6) is the lead architect.** When using Windsurf alongside Claude Code, always read `CLAUDE.md` first and defer to it on all architecture decisions. See [`../CURSOR.md`](../CURSOR.md) for full collaboration guidelines.

---

## Conclusion

Windsurf provides an exceptional development experience for Better11 with AI-assisted coding, refactoring, testing, and debugging. See [Windsurf.md](../Windsurf.md) in the repo root for the full detailed guide including the Claude Code collaboration section.
