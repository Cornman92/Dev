# Better11 MCP Server

Model Context Protocol server for **Better11** in three phases:

| Phase | Prefix | Purpose |
|-------|--------|---------|
| **Create** | `better11_create_*` | Developing and building Better11 (build, test, work streams) |
| **Use** | `better11_use_*` | Using Better11 to optimize a Windows system (presets, modules, system info) |
| **Post** | `better11_post_*` | After optimization (reports, health check, next steps) |

## Setup

1. Install dependencies and build (from repo root, e.g. `Better11`):

   ```bash
   cd tools/mcp-server
   npm install
   npm run build
   ```

2. Ensure Cursor is using the project MCP config (`.cursor/mcp.json`). Restart Cursor after adding the server.

3. From repo root, the server is started by Cursor with:

   ```bash
   node tools/mcp-server/dist/index.js
   ```

   So open the **Better11** folder as the workspace (so `tools/mcp-server` resolves).

## Tools

- **better11_create_build** — Build the solution (Debug/Release).
- **better11_create_test** — Run xUnit tests (optional filter).
- **better11_create_list_workstreams** — List WS1–WS7 status.
- **better11_use_system_info** — Get OS/CPU/RAM via PowerShell.
- **better11_use_list_presets** — List optimization presets.
- **better11_use_list_modules** — List Better11 modules.
- **better11_post_export_report** — Suggest report export (html/json/md).
- **better11_post_health_check** — Quick build/health check.
- **better11_post_suggest_next_steps** — Next steps after optimization.

## Requirements

- Node.js 18+
- .NET SDK (for build/test tools)
- PowerShell (for use_system_info; optional)
