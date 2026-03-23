# MCP Servers – Configured & How to Activate

All MCP servers for this workspace are configured in **`.cursor/mcp.json`**.

## Configured servers

| Server        | Purpose                          |
|---------------|-----------------------------------|
| time-utils    | Time/date, timezone, format       |
| code-analysis | PSScriptAnalyzer, StyleCop lint   |
| powershell    | Run scripts, cmdlets, PSScriptAnalyzer |
| system-info   | WMI, registry, services, software |
| winget        | Package search, list, upgrades    |
| dotnet-cli    | Build, restore, test, publish     |
| nuget         | NuGet search, versions, list/outdated |
| windows-mcp   | Windows utilities (uvx)           |
| filesystem-mcp| Read/write files under allowed paths   |
| desktopcommander-mcp | Desktop automation (npx)    |

## Activate (use the servers in Cursor)

1. **Restart Cursor**  
   Fully quit Cursor and open it again, then open this folder (`D:\Dev`).  
   **Or** use **Developer: Reload Window** (Ctrl+Shift+P → “Reload Window”).

2. **Confirm**  
   In chat, you can ask: “What MCP tools do you have?” or “What time is it in UTC?” to confirm time-utils (and others) are available.

Servers are started by Cursor when needed; no extra steps after reload.
