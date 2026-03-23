# MCP Server Index

Index of MCP (Model Context Protocol) servers in the Dev workspace. Unified test runner, health check, and dashboard integration are implemented. See [unified-mcp-server/README.md](../unified-mcp-server/README.md) for the aggregator stub.

## Overview

| Server | Purpose | Run | Test from root |
|--------|---------|-----|----------------|
| time-utils-mcp-server | Time, date, timezone, formatting | `node dist/index.js` (after build) | `npm run test:mcp-time-utils` |
| code-analysis-mcp-server | PSScriptAnalyzer, StyleCop, code analysis | (see project) | `npm run test:mcp-code-analysis` |
| powershell-mcp-server | Run PowerShell scripts/commands | (see project) | `npm run test:mcp-powershell` |
| system-info-mcp-server | WMI, registry, system/hardware info | (see project) | `npm run test:mcp-system-info` |
| winget-mcp-server | Winget search, list, upgrade | (see project) | `npm run test:mcp-winget` |
| dotnet-cli-mcp-server | .NET build, test, restore | (see project) | `npm run test:mcp-dotnet-cli` |
| nuget-mcp-server | NuGet search, package info | (see project) | `npm run test:mcp-nuget` |
| project-scaffolder-mcp-server | Scaffold Better11 patterns (PS, C#, README) | `npm run start` (from project dir) | `npm run test:mcp-project-scaffolder` |
| unified-mcp-server | Placeholder/aggregator for MCPs (Python stub) | `pip install -e .` then run server | `cd unified-mcp-server && pytest` (not in test:mcp-all) |

## Running and testing

- **From workspace root (`D:\Dev`):**
  - Run all MCP integration tests: `npm run test:mcp-all`
  - Run a single server’s tests: `npm run test:mcp-<name>` (e.g. `npm run test:mcp-powershell`)
- **Health check:** Run `.\Invoke-McpHealthCheck.ps1` from `D:\Dev` to get status of each server (for dashboard or CLI).
- **Cursor:** Configure servers in `.cursor/mcp.json`; reload Cursor to activate. See [Skills/MCP usage](../Skills/mcp-servers-usage/) for when to use which server.

## Directory layout

All MCP servers live under `D:\Dev` as `*-mcp-server/` (e.g. `D:\Dev\powershell-mcp-server`). Each project has its own `package.json`, build, and test scripts.

## References

- Workspace [README](../README.md)
- [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) — MCP test runner, health check, dashboard MCP panel
- [AUTOMATION-RUNBOOK.md](./AUTOMATION-RUNBOOK.md) — Scheduled runs and logs
