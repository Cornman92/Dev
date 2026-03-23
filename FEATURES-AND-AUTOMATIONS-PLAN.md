# Dev Workspace: New Features, Functionalities & Automations Plan

This document lists all proposed changes, updates, and new functionality before implementation. It is organized by area and includes automation opportunities across the workspace.

---

## 1. Workspace Overview (Current State)

| Area | Contents |
|------|----------|
| **Root** | `package.json` (MCP test scripts), migration/lint/fix scripts, `workspace_report.json`, `consolidate_workspace.ps1` |
| **MCP Servers** | time-utils, code-analysis, powershell, system-info, winget, dotnet-cli, nuget, project-scaffolder, unified |
| **Projects** | Better11 (.NET), BetterShell, BetterPE, dev-dashboard (Node/Express), claude-agents |
| **Data/Config** | Config, configs, data, docs, DotFiles, GoldenImage, Skills, Skills-MCP, tests |

---

## 2. Dev Dashboard – New Features & Functionality

### 2.1 Completed Gaps (from README “In Progress / Planned”)

| # | Feature | Description | Implementation Notes |
|---|---------|-------------|----------------------|
| 2.1.1 | **Test coverage charts and trends** | Charts for coverage over time per project; trend lines and thresholds | Use existing `test_coverage` table; add route `GET /api/projects/:id/coverage` and frontend chart component (e.g. Chart.js or existing coverage-chart.js completion) |
| 2.1.2 | **Deployment status tracking** | Show deployment state (success/fail/pending) per project/env | Use existing `deployments` table; add routes for deployments, sync from CI or manual; complete deployment-status component |
| 2.1.3 | **Customizable dashboard layouts/widgets** | Drag-and-drop or preset layouts; show/hide widgets per user | Backend: user/preference store (SQLite or JSON); frontend: layout engine (grid); persist layout per session or user id |
| 2.1.4 | **Authentication/authorization** | Login, optional GitHub OAuth; role-based access to projects/actions | Add auth middleware, sessions or JWT; protect API and WebSocket; optional GitHub OAuth provider |
| 2.1.5 | **Advanced metrics visualization** | Custom metrics, histograms, comparisons across projects | New metrics API (aggregations, time ranges); frontend charts for custom metrics and comparisons |

### 2.2 Additional Dashboard Features

| # | Feature | Description |
|---|---------|-------------|
| 2.2.1 | **Workspace report integration** | Ingest `workspace_report.json` (or regenerate via script); show project types, file stats, repo status in dashboard. **Done:** `GET /api/workspace-report` serves report; frontend panel optional. |
| 2.2.2 | **MCP server status** | Panel showing each MCP server (from root `package.json` or config): up/down, last test run result. **Done:** `GET /api/mcp-status` runs `Invoke-McpHealthCheck.ps1 -AsJson`; frontend panel optional. |
| 2.2.3 | **Quick actions** | Buttons to run workspace scripts (e.g. “Run all MCP tests”, “Lint migration script”) with output in UI or logs |
| 2.2.4 | **Alerts and notifications** | Configurable alerts (e.g. build failed, coverage drop); optional browser/desktop notifications or webhook |
| 2.2.5 | **Export/reports** | Export project health, builds, commits to CSV/JSON/PDF on demand or scheduled |

---

## 3. MCP Ecosystem – New Features & Automations

### 3.1 Root Workspace Scripts and Tooling

| # | Change | Description |
|---|--------|-------------|
| 3.1.1 | **Unified MCP test runner** | Single script/command (e.g. `npm run test:mcp-all`) that runs all MCP integration tests and reports pass/fail per server |
| 3.1.2 | **MCP health check script** | PowerShell or Node script that pings/checks each MCP server (or spawns and validates) and outputs status for dashboard or CLI |
| 3.1.3 | **Add project-scaffolder to root package.json** | Add `test:mcp-project-scaffolder` (and any other missing servers) so all MCPs are testable from root |
| 3.1.4 | **Unified MCP server** | If `unified-mcp-server` is intended to aggregate other MCPs: document its role, implement or wire aggregation, and add tests |

### 3.2 Per-Server Enhancements (Optional)

| # | Area | Idea |
|---|------|------|
| 3.2.1 | **project-scaffolder** | **Done:** `project-scaffolder-mcp-server/templates/dev-workspace-mcp-stub.md` checklist for new MCP server. |
| 3.2.2 | **powershell-mcp-server** | **Done:** Dashboard `POST /api/quick-action` runs workspace scripts (mcp-tests, lint, report) with timeout. |
| 3.2.3 | **code-analysis-mcp-server** | **Done:** Dashboard `GET /api/code-analysis?path=...` runs PSScriptAnalyzer and returns diagnostics. |

---

## 4. Automation – Scripts and Scheduled Tasks

### 4.1 Migration and Maintenance

| # | Automation | Description |
|---|------------|-------------|
| 4.1.1 | **Scheduled workspace report** | **Done:** `Schedule-WorkspaceReport.ps1`; see `docs/scheduled-tasks-windows.md`. |
| 4.1.2 | **Lint-on-save or pre-commit** | **Done:** `docs/pre-commit-hooks.md`; optional Git hook runs `_lint-migrate.ps1`. |
| 4.1.3 | **Consolidation check** | **Done:** `Test-ConsolidationState.ps1`. |
| 4.1.4 | **Migration dry-run job** | **Done:** `Invoke-MigrationDryRun.ps1`; schedule via Task Scheduler or nightly. |

### 4.2 CI/CD and Testing

| # | Automation | Description |
|---|------------|-------------|
| 4.2.1 | **Root-level CI workflow** | If using GitHub Actions: workflow that runs `npm run test:mcp-*` (or unified MCP test), optional lint and workspace report generation. **Done:** `.github/workflows/ci.yml` runs MCP tests and workspace report job. |
| 4.2.2 | **Dashboard CI** | **Done:** Root `ci.yml` includes dashboard job (install + test). |
| 4.2.3 | **Better11 / BetterShell CI** | Better11 has `.github/workflows/ci.yml`; document in root. |
| 4.2.4 | **Nightly full run** | **Done:** `.github/workflows/nightly.yml` — report, MCP tests, migration what-if, dashboard tests; artifacts uploaded. |

### 4.3 Dashboard-Backed Automations

| # | Automation | Description |
|---|------------|-------------|
| 4.3.1 | **Sync jobs** | Scheduled sync of GitHub commits/builds for all registered projects (already partially in place; ensure configurable intervals and error handling) |
| 4.3.2 | **Webhook receivers** | GitHub webhooks for push/build/deploy events to update dashboard in real time and trigger notifications |
| 4.3.3 | **Scheduled reports** | Cron or Windows Task Scheduler: call dashboard export API and save reports to shared drive or email |

---

## 5. Scripts and Utilities – New or Updated

### 5.1 New Scripts

| # | Script | Purpose |
|---|--------|---------|
| 5.1.1 | **Generate-WorkspaceReport.ps1** | Regenerate `workspace_report.json`: scan D:\Dev subdirs, detect type (PS/.NET/Node/etc.), count files, detect Git; output JSON (for dashboard and 4.1.1) |
| 5.1.2 | **Invoke-McpHealthCheck.ps1** | Run MCP health checks (start servers or call health endpoints), output status (for dashboard 2.2.2 and 3.1.2) |
| 5.1.3 | **Invoke-AllMcpTests.ps1** | Run all `npm run test:mcp-*` from root, collect results, exit code and report (for 3.1.1 and CI) |
| 5.1.4 | **Test-ConsolidationState.ps1** | Verify folders referenced by `consolidate_workspace.ps1` exist in expected places; report missing or extra (for 4.1.3) |

### 5.2 Updates to Existing Scripts

| # | Script | Update |
|---|--------|--------|
| 5.2.1 | **package.json (root)** | Add `test:mcp-all`, optional `report:workspace`, `dashboard:start` (or link to dev-dashboard) |
| 5.2.2 | **_lint-migrate.ps1** | Optional: accept path parameter to lint any script; support multiple files for batch lint |
| 5.2.3 | **consolidate_workspace.ps1** | Add -WhatIf support if missing; optional log output; idempotency checks before move |

---

## 6. Documentation and Configuration

| # | Item | Description |
|---|------|-------------|
| 6.1 | **Workspace README** | Single README at D:\Dev describing layout, main scripts (migration, consolidate, lint, MCP tests), dashboard, and how to run key automations |
| 6.2 | **Dashboard config** | Document how to add projects (manual vs auto from workspace report); env vars and optional feature flags (auth, webhooks, alerts). See `dev-dashboard/config/env.example` and `dev-dashboard/README.md`. |
| 6.3 | **MCP server index** | Markdown or JSON listing each MCP server, purpose, how to run/test, and how they are used (Cursor, CLI, dashboard) |
| 6.4 | **Automation runbook** | Short runbook: which tasks are scheduled, where logs go, how to trigger manual runs and interpret results |

---

## 7. Implementation Order (Suggested)

1. **Quick wins (no new services)**  
   - 3.1.1 Unified MCP test runner  
   - 3.1.3 Add missing MCP test scripts to root package.json  
   - 5.1.1 Generate-WorkspaceReport.ps1  
   - 5.2.1 package.json updates  

2. **Dashboard completion**  
   - 2.1.1 Test coverage charts  
   - 2.1.2 Deployment status tracking  
   - 2.2.1 Workspace report integration  
   - 2.2.2 MCP server status panel  

3. **Automation foundation**  
   - 4.1.1 Scheduled workspace report  
   - 5.1.2 MCP health check script  
   - 4.2.1 Root-level CI (if using GitHub Actions)  

4. **Advanced dashboard**  
   - 2.1.3 Customizable layouts  
   - 2.1.4 Authentication  
   - 2.2.4 Alerts and notifications  

5. **Operational maturity**  
   - 4.3.1–4.3.3 Dashboard sync and webhooks, scheduled reports  
   - 6.1–6.4 Documentation and runbook  

---

## 8. Summary Table

| Category | New | Updates | Automations |
|----------|-----|---------|-------------|
| Dev Dashboard | 5 planned + 5 additional features | README/config | Sync jobs, webhooks, scheduled reports |
| MCP | 1 unified runner, 1 health check, index | Root package.json, optional per-server | CI run all MCP tests, nightly run |
| Scripts | 4 new PS scripts | 3 existing scripts | Lint, consolidation check, migration what-if |
| CI/CD | — | — | Root CI, dashboard CI, Better11/BetterShell CI, nightly |
| Docs/Config | README, MCP index, runbook | Dashboard config | — |

---

*This plan should be treated as the single source of proposed changes before implementation. Adjust priorities and scope per need; then implement in the order above or by dependency.*
