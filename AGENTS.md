# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Workspace Overview

Root workspace at `D:\Dev`. Contains MCP servers, the dev-dashboard, migration/consolidation scripts, and major project trees (Better11, BetterShell, BetterPE).

**Platform:** Windows-only. Many operations require administrator privileges.

## Common Commands

### From `D:\Dev` (workspace root)

```bash
# MCP testing
npm run test:mcp-all                           # All MCP integration tests
npm run test:mcp-<name>                        # Single server (e.g. test:mcp-powershell)

# Workspace
npm run report:workspace                       # Regenerate workspace_report.json
npm run dashboard:start                        # Start dev-dashboard at http://localhost:3000
```

```powershell
.\Generate-WorkspaceReport.ps1                 # Regenerate workspace_report.json
.\Invoke-McpHealthCheck.ps1                    # Check MCP server status
.\Invoke-AllMcpTests.ps1                       # Run all MCP tests (PowerShell runner)
.\Invoke-MigrationDryRun.ps1                   # Dry-run migration check

# Lint / fix
.\_lint-migrate.ps1                            # PSScriptAnalyzer on migration script
.\_lint-migrate.ps1 -Path 'D:\Dev\SomeScript.ps1'

# Migration (always run -WhatIf first)
.\Invoke-DevMigration.ps1 -WhatIf
.\consolidate_workspace.ps1 -WhatIf
```

### MCP servers (per-server, from their directory)

```bash
npm run build        # Compile TypeScript → dist/
npm test             # Unit tests (Vitest)
npm run test:integration   # Integration tests
```

### Better11 (.NET / WinUI 3) — from `D:\Dev\Better11\Better11\`

```powershell
# Recommended build (uses MSBuild, falls back to dotnet)
.\scripts\Build-Better11.ps1 -Configuration Release

# Manual restore + build (MSBuild required for WinUI 3 XAML)
dotnet restore Better11.sln
& "C:\Program Files\Microsoft Visual Studio\2022\Community\MSBuild\Current\Bin\MSBuild.exe" Better11.sln -p:Configuration=Release -p:Platform=x64 -t:Build -v:minimal -nologo

# Test
dotnet test Better11.sln -c Release -p:Platform=x64 --no-build

# Package (MSIX)
.\scripts\Build-Better11.ps1 -Configuration Release -Package
```

> Better11 is **x64-only**. `dotnet build` can fail on the App project due to the WinUI XAML compiler — prefer MSBuild.

### dev-dashboard — from `D:\Dev\dev-dashboard\`

```bash
npm install
cp config/env.example .env   # configure GITHUB_TOKEN, PORT, etc.
npm run setup-db
npm start                    # production
npm run dev                  # nodemon (auto-reload)
npm test
```

## Architecture

### Workspace layout

| Area | Location |
|------|----------|
| MCP servers | `*-mcp-server/` (time-utils, code-analysis, powershell, system-info, winget, dotnet-cli, nuget, project-scaffolder, unified) |
| Dev dashboard | `dev-dashboard/` — Node/Express + SQLite + WebSocket |
| Better11 | `Better11/Better11/` — WinUI 3 C# solution |
| BetterShell | `BetterShell/` — PowerShell platform/profile/deployment |
| BetterPE | `BetterPE/` — Custom WinPE environment |
| Scripts | Root `.ps1` files — migration, consolidation, lint, reporting |
| Docs | `docs/` — comprehensive architecture and runbook docs |

### MCP servers

Each server under `*-mcp-server/` is a standalone TypeScript/Node project:
- Build: `tsc` → `dist/index.js`
- Run: `node dist/index.js` (stdio transport, MCP protocol)
- Test: Vitest (unit) + Vitest integration config
- Cursor config: `.cursor/mcp.json` (wires servers by absolute path)

The **unified-mcp-server** is a Python stub/aggregator (`pip install -e .`, test with `pytest`); not included in `test:mcp-all`.

### dev-dashboard architecture

- **Backend:** `backend/server.js` (Express), routes under `backend/routes/`, services under `backend/services/`, SQLite via `backend/models/`, WebSocket at `ws://localhost:3000/ws`
- **Frontend:** `frontend/` (vanilla JS/HTML), connects via REST + WebSocket
- **Key endpoints:** `/api/projects`, `/api/builds`, `/api/commits`, `/api/workspace-report` (reads `workspace_report.json`), `/api/mcp-status` (runs `Invoke-McpHealthCheck.ps1 -AsJson`), `/api/quick-action`, `/api/code-analysis`

### Better11 architecture

Stack: WinUI 3 / C# (.NET 8+) / PowerShell 5.1+. Pattern: MVVM via CommunityToolkit.Mvvm + DI (Microsoft.Extensions.DependencyInjection). 102 PowerShell modules bridged via `IPowerShellService`.

```
UI Layer (WinUI 3 / TUI)
  → ViewModels (CommunityToolkit, [ObservableProperty], [RelayCommand])
    → Services (15+ C# services, Result<T> error handling)
      → IPowerShellService → PowerShell modules
```

- Source: `Better11/Better11/src/`
- Tests: `Better11/Better11/tests/` (xUnit, ~1800+ tests)
- Theme: dark (#111111 bg, #0078D4 accent, 24px rows); see `Better11/Better11/STYLE-GUIDE.md`
- Detailed agent instructions: `Better11/AGENTS.md`

### PowerShell conventions (workspace-wide)

- Use approved verbs; support `-WhatIf`/`-Confirm` for state-changing ops
- Lint with PSScriptAnalyzer (`.\_lint-migrate.ps1 -Path <script>`)
- System/registry operations require administrator elevation

## Key documentation

| File | Purpose |
|------|---------|
| `docs/MCP-SERVER-INDEX.md` | MCP server directory, run/test instructions |
| `docs/AUTOMATION-RUNBOOK.md` | Scheduled tasks, logs, manual runs |
| `docs/ROADMAP-300.md` | 300-step workspace roadmap |
| `docs/USER-GUIDE.md` | Workspace usage guide |
| `FEATURES-AND-AUTOMATIONS-PLAN.md` | Planned features and implementation status |
| `Better11/AGENTS.md` | Better11-specific Codex instructions |
| `dev-dashboard/README.md` | Dashboard setup, API reference, WebSocket events |
