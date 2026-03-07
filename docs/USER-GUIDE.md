# Dev Workspace — User Guide

How to use the Dev workspace: scripts, dashboard, MCP servers, and automations. See [ROADMAP-300.md](./ROADMAP-300.md) for the full checklist and [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) for the plan.

---

## 1. Workspace layout

- **Root (`D:\Dev`):** Main scripts, `package.json`, `workspace_report.json`, plan and docs.
- **MCP servers:** `*-mcp-server/` (time-utils, code-analysis, powershell, system-info, winget, dotnet-cli, nuget, project-scaffolder, unified).
- **Projects:** Better11, BetterShell, BetterPE, dev-dashboard, claude-agents.
- **Docs:** `docs/`, `README.md`, `FEATURES-AND-AUTOMATIONS-PLAN.md`, `ROADMAP-300.md`, this guide.

---

## 2. Daily commands

### From PowerShell at `D:\Dev`

| Goal | Command |
|------|--------|
| Regenerate project list/stats | `.\Generate-WorkspaceReport.ps1` or `npm run report:workspace` |
| Run all MCP tests | `npm run test:mcp-all` or `.\Invoke-AllMcpTests.ps1` |
| Check MCP server status | `.\Invoke-McpHealthCheck.ps1` |
| Lint migration script | `.\_lint-migrate.ps1` or `.\_lint-migrate.ps1 -Path 'D:\Dev\Invoke-DevMigration.ps1'` |
| Check consolidation state | `.\Test-ConsolidationState.ps1` |
| Preview consolidation | `.\consolidate_workspace.ps1 -WhatIf` |
| Preview migration | `.\Invoke-DevMigration.ps1 -WhatIf` |
| Start dashboard | `npm run dashboard:start` or `cd dev-dashboard && npm start` |

### From npm at root

- `npm run test:mcp-time-utils` … `npm run test:mcp-project-scaffolder` — single MCP test.
- `npm run test:mcp-all` — all MCP tests.
- `npm run report:workspace` — regenerate workspace report.
- `npm run dashboard:start` — start dev-dashboard.

---

## 3. Development dashboard

### Start

1. `cd D:\Dev\dev-dashboard`
2. `npm install` (first time)
3. Copy `config/env.example` to `.env` and set `GITHUB_TOKEN`, `WORKSPACE_ROOT` (optional).
4. `npm start` — server at http://localhost:3000

Or from root: `npm run dashboard:start`.

### Main URLs

- **UI:** http://localhost:3000  
- **Health:** http://localhost:3000/health  
- **Projects:** http://localhost:3000/api/projects  
- **Workspace report:** http://localhost:3000/api/workspace-report  
- **MCP status:** http://localhost:3000/api/mcp-status  

### API quick reference

- **Projects:** GET/POST /api/projects, GET/PUT/DELETE /api/projects/:id  
- **Project coverage:** GET /api/projects/:id/coverage  
- **Project deployments:** GET /api/projects/:id/deployments, POST /api/projects/:id/deployments  
- **Builds:** GET /api/builds, GET /api/builds/project/:projectId, POST sync  
- **Commits:** GET /api/commits, GET /api/commits/project/:projectId  
- **Quick action:** POST /api/quick-action with body `{ "action": "mcp-tests" }` (or "lint", "report")  
- **Code analysis:** GET /api/code-analysis?path=relative/or/absolute/path  

---

## 4. MCP servers

- **List and test:** See [MCP-SERVER-INDEX.md](./MCP-SERVER-INDEX.md).  
- **Test all:** `npm run test:mcp-all`.  
- **Health:** `.\Invoke-McpHealthCheck.ps1` or GET /api/mcp-status in the dashboard.  
- **Cursor:** Configure in `.cursor/mcp.json`; reload Cursor to use tools.  

---

## 5. Scheduled tasks (Windows)

- **Workspace report (daily):** Use [scheduled-tasks-windows.md](./scheduled-tasks-windows.md) to schedule `Schedule-WorkspaceReport.ps1`.  
- **Migration dry-run:** Schedule `Invoke-MigrationDryRun.ps1` (e.g. daily) and check logs.  
- **Pre-commit lint:** See [pre-commit-hooks.md](./pre-commit-hooks.md).  

---

## 6. CI/CD

- **Root CI:** `.github/workflows/ci.yml` — on push/PR: MCP tests, workspace report, dashboard install/test.  
- **Nightly:** `.github/workflows/nightly.yml` — report, MCP tests, migration what-if, dashboard tests; artifacts uploaded.  

---

## 7. Troubleshooting

| Issue | What to do |
|-------|------------|
| Workspace report 404 in dashboard | Run `.\Generate-WorkspaceReport.ps1`; set `WORKSPACE_ROOT` in dashboard `.env` if dashboard is not under D:\Dev. |
| MCP status fails | Ensure `Invoke-McpHealthCheck.ps1` is at workspace root and PowerShell can run it. |
| Quick-action times out | Increase timeout in `dev-dashboard/backend/routes/workspace.js` or run the script manually. |
| Consolidation drift | Run `.\Test-ConsolidationState.ps1`; fix folder locations per consolidate_workspace.ps1. |
| Lint fails on script | Run `.\_lint-migrate.ps1 -Path 'path\to\script.ps1'` and fix PSScriptAnalyzer findings. |

---

## 8. Where to read more

- [README](../README.md) — Layout and main scripts  
- [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) — Plan and implementation order  
- [AUTOMATION-RUNBOOK.md](./AUTOMATION-RUNBOOK.md) — Manual runs and logs  
- [ROADMAP-300.md](./ROADMAP-300.md) — 300-step roadmap  
- [dev-dashboard/README.md](../dev-dashboard/README.md) — Dashboard setup and API  
