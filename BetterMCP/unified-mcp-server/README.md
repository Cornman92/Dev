# Unified MCP Server

**Status:** Placeholder / future aggregator for Dev workspace MCP servers.

## Purpose (FEATURES-AND-AUTOMATIONS-PLAN 3.1.4)

This project is intended to aggregate or orchestrate other MCP servers in the Dev workspace (time-utils, code-analysis, powershell, system-info, winget, dotnet-cli, nuget, project-scaffolder) so a single MCP endpoint can expose all tools. Currently it is a Python stub; full implementation is planned.

## Current State

- **Runtime:** Python (see `pyproject.toml`, `src/server/main.py`).
- **Tests:** `pytest` in `tests/`.
- **Integration with root:** Not yet included in root `npm run test:mcp-all` (Node-based); run manually: `cd unified-mcp-server && pytest`.

## Usage

```bash
cd D:\Dev\unified-mcp-server
pip install -e .
pytest
```

## References

- [MCP Server Index](../docs/MCP-SERVER-INDEX.md)
- [FEATURES-AND-AUTOMATIONS-PLAN.md](../FEATURES-AND-AUTOMATIONS-PLAN.md) § 3.1.4
