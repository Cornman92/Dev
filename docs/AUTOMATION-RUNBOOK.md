# Automation Runbook

Short runbook for scheduled and manual automations in the Dev workspace. See [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) for the full automation plan.

## Scheduled tasks (planned / optional)

| Task | What it does | How to run | Logs / output |
|------|----------------|------------|----------------|
| **Workspace report** | Regenerates `workspace_report.json` | `.\Generate-WorkspaceReport.ps1` or `npm run report:workspace` | Overwrites `D:\Dev\workspace_report.json` |
| **MCP tests** | Runs all MCP integration tests | `npm run test:mcp-all` (or `.\Invoke-AllMcpTests.ps1`) | Console; optional log to file |
| **Migration what-if** | Dry run of OneDrive→Dev migration | `.\Invoke-DevMigration.ps1 -WhatIf` | Console; optional log path |
| **Consolidation check** | Verifies consolidate_workspace sources | `.\Test-ConsolidationState.ps1` | Console |
| **Dashboard sync** | Sync GitHub commits/builds for projects | Dashboard backend / scheduled job | Dashboard DB and UI |

## Manual runs

### From `D:\Dev` (PowerShell)

```powershell
# Workspace report
.\Generate-WorkspaceReport.ps1

# Lint migration script (default path) or another script
.\_lint-migrate.ps1
.\_lint-migrate.ps1 -Path 'D:\Dev\consolidate_workspace.ps1'

# Consolidation (preview then run)
.\consolidate_workspace.ps1 -WhatIf
.\consolidate_workspace.ps1

# Migration (preview then run)
.\Invoke-DevMigration.ps1 -WhatIf
.\Invoke-DevMigration.ps1

# MCP health check
.\Invoke-McpHealthCheck.ps1

# All MCP tests (npm from root)
npm run test:mcp-all
```

### From root (npm)

```bash
npm run report:workspace   # Regenerate workspace_report.json
npm run test:mcp-all      # All MCP integration tests
npm run dashboard:start   # Start dev-dashboard server
```

## Where logs go

- **Invoke-DevMigration.ps1** — Log path defaults to `D:\Dev\migration-<yyyyMMdd-HHmmss>.log`; override with `-LogPath`.
- **Workspace report** — No separate log; output is `workspace_report.json`.
- **MCP tests** — Console only unless you redirect: `npm run test:mcp-all > mcp-tests.log 2>&1`.
- **Dashboard** — Server logs to console; configure logging in dashboard backend if needed.

## Interpreting results

- **Workspace report:** Open `workspace_report.json` or use dashboard “Workspace report” integration (when implemented). Each entry: Name, Type, IsGitRepo, Stats.
- **MCP tests:** Exit code 0 = all passed; non-zero = at least one failed. Check which `test:mcp-*` failed from output.
- **Invoke-McpHealthCheck.ps1:** Lists each server as Up/Down or similar; use for dashboard MCP status panel (when implemented).
- **Consolidation check:** Reports missing or unexpected folders vs. `consolidate_workspace.ps1` expectations.

## Dashboard API (workspace integration)

When the dev-dashboard is running, you can query workspace data via API:

- **GET /api/workspace-report** — Returns `workspace_report.json` (project list, types, stats). Regenerate with `.\Generate-WorkspaceReport.ps1` or `npm run report:workspace`.
- **GET /api/mcp-status** — Returns MCP server status (runs `Invoke-McpHealthCheck.ps1 -AsJson`). Requires dashboard to have access to workspace root (set `WORKSPACE_ROOT` if needed).

## References

- [README](../README.md) — Layout and main scripts
- [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) — Full plan and implementation order
- [MCP-SERVER-INDEX.md](./MCP-SERVER-INDEX.md) — MCP servers and test commands
