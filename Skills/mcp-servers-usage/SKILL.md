---
name: mcp-servers-usage
description: Guides when and how to use MCP (Model Context Protocol) servers available in the Dev workspace. Use when the user asks about MCP servers, wants to activate or configure MCP, or needs to call tools provided by time-utils, code-analysis, PowerShell, system-info, winget, dotnet-cli, NuGet, or other configured MCP servers.
---

# MCP Servers Usage

## When to Use This Skill

- User asks to use or activate MCP servers
- User needs current time, timezone, or date formatting (use **time-utils-mcp-server**)
- User needs code analysis (PSScriptAnalyzer, StyleCop) — **code-analysis-mcp-server**
- User needs to run PowerShell scripts or commands — **powershell-mcp-server**
- User needs system/hardware info (WMI, registry, services) — **system-info-mcp-server**
- User needs Winget search/list/upgrade — **winget-mcp-server**
- User needs .NET build/test/restore — **dotnet-cli-mcp-server**
- User needs NuGet search or package info — **nuget-mcp-server**
- User asks how to configure or enable MCP in Cursor

## Configuration

MCP servers are configured in:

- **Project-level**: `.cursor/mcp.json` in the project root
- **Global**: `~/.cursor/mcp.json` (Windows: `%USERPROFILE%\.cursor\mcp.json`)

Format:

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["path/to/dist/index.js"],
      "env": {}
    }
  }
}
```

After changing `mcp.json`, **restart Cursor** for changes to take effect.

## Available Servers in Dev

| Server | Purpose | Command (example) |
|--------|---------|-------------------|
| time-utils-mcp-server | Time/date, timezone, format | `node D:\Dev\time-utils-mcp-server\dist\index.js` |
| code-analysis-mcp-server | Lint PowerShell/C# | (see project dist path) |
| powershell-mcp-server | Run PowerShell | (see project dist path) |
| system-info-mcp-server | WMI, registry, services | (see project dist path) |
| winget-mcp-server | Winget packages | (see project dist path) |
| dotnet-cli-mcp-server | .NET CLI | (see project dist path) |
| nuget-mcp-server | NuGet packages | (see project dist path) |

## Activating MCP

1. **Configured**: All Dev MCP servers are listed in `D:\Dev\.cursor\mcp.json`.
2. **Activate**: Restart Cursor completely, or run **Developer: Reload Window** (Ctrl+Shift+P).
3. Open the `D:\Dev` folder so Cursor loads this project-level config.
4. Ask the agent to use a tool (e.g. "What time is it in New York?" for time-utils).

No other activation step is required after restart/reload.
