# Dev Workspace

Root workspace at `D:\Dev` containing MCP servers, the development dashboard, migration/consolidation scripts, and project trees (Better11, BetterShell, BetterPE).

## Layout

| Area | Description |
|------|-------------|
| **Root** | `package.json` (MCP test scripts, workspace commands), migration/lint/fix scripts, `workspace_report.json`, [FEATURES-AND-AUTOMATIONS-PLAN.md](./FEATURES-AND-AUTOMATIONS-PLAN.md) |
| **MCP Servers** | `*-mcp-server/` — time-utils, code-analysis, powershell, system-info, winget, dotnet-cli, nuget, project-scaffolder, unified. See [docs/MCP-SERVER-INDEX.md](./docs/MCP-SERVER-INDEX.md). |
| **Projects** | Better11 (.NET), BetterShell, BetterPE, **dev-dashboard** (Node/Express), claude-agents |
| **Config/Data** | Config, configs, data, docs, DotFiles, GoldenImage, Skills, Skills-MCP, tests |

## Main Scripts

### Migration and consolidation

- **Invoke-DevMigration.ps1** — Migrates `C:\Users\...\OneDrive\Dev` → `D:\Dev` with diff-merge for Better11. Run with `-WhatIf` first.
- **consolidate_workspace.ps1** — Moves platform, PowerShell, modules, etc. into BetterShell/BetterPE. Supports `-WhatIf`.
- **Migrate-OneDriveDevToLocal.ps1** — OneDrive Dev → local Dev migration (legacy/detailed).

### Lint and fix

- **_lint-migrate.ps1** — Runs PSScriptAnalyzer on a script (default: `Migrate-OneDriveDevToLocal.ps1`). Usage: `.\_lint-migrate.ps1` or `.\_lint-migrate.ps1 -Path 'D:\Dev\SomeScript.ps1'`.
- **_fix-migrate.ps1** — Reverts Console output to Write-Host and adds SuppressMessageAttribute in the migration script.

### Workspace report and MCP

- **Generate-WorkspaceReport.ps1** — Regenerates `workspace_report.json` (project types, file stats, Git status). Run from `D:\Dev`.
- **npm run report:workspace** — Same, via root `package.json` (calls script if present).
- **npm run test:mcp-all** — Runs all MCP integration tests from root. Individual: `npm run test:mcp-time-utils`, `test:mcp-powershell`, etc.
- **Invoke-McpHealthCheck.ps1** — Checks MCP server status (for dashboard or CLI).

## Development dashboard

- **Location:** `D:\Dev\dev-dashboard`
- **Start:** From root run `npm run dashboard:start`, or `cd dev-dashboard && npm install && npm start`.
- **URL:** http://localhost:3000 — projects, builds, commits, health; optional GitHub sync and WebSocket updates.
- **Docs:** [dev-dashboard/README.md](./dev-dashboard/README.md), [SETUP.md](./dev-dashboard/SETUP.md), [QUICK-START.md](./dev-dashboard/QUICK-START.md).

## Automations

- **Scheduled workspace report** — Regenerate `workspace_report.json` (e.g. daily) via Task Scheduler or cron calling `Generate-WorkspaceReport.ps1` or `npm run report:workspace`.
- **Lint / pre-commit** — Optionally run `_lint-migrate.ps1` on key scripts (or broader PSScriptAnalyzer).
- **CI** — Root-level workflow can run `npm run test:mcp-all`, lint, and report generation. See [docs/AUTOMATION-RUNBOOK.md](./docs/AUTOMATION-RUNBOOK.md).

## Documentation

- [FEATURES-AND-AUTOMATIONS-PLAN.md](./FEATURES-AND-AUTOMATIONS-PLAN.md) — Planned features, automations, and implementation order.
- [docs/USER-GUIDE.md](./docs/USER-GUIDE.md) — How to use the workspace, dashboard, and scripts.
- [docs/ROADMAP-300.md](./docs/ROADMAP-300.md) — 300-step roadmap checklist.
- [docs/MCP-SERVER-INDEX.md](./docs/MCP-SERVER-INDEX.md) — MCP servers, purpose, how to run and test.
- [docs/AUTOMATION-RUNBOOK.md](./docs/AUTOMATION-RUNBOOK.md) — Scheduled tasks, logs, manual runs.
- [docs/INDEX.md](./docs/INDEX.md) — Master documentation index (includes Better11).

## Quick reference

```powershell
# From D:\Dev
.\Invoke-DevMigration.ps1 -WhatIf
.\consolidate_workspace.ps1 -WhatIf
.\_lint-migrate.ps1
.\Generate-WorkspaceReport.ps1
.\Invoke-McpHealthCheck.ps1
```

```bash
npm run test:mcp-all
npm run report:workspace
npm run dashboard:start
```
