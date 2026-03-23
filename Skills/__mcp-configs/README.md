# MCP Server Configuration Package

## Overview
Complete MCP server configuration for Claude Desktop App with DXT extension optimization, and optional Cursor IDE deployment so the same logical set of servers (windows-mcp, filesystem, desktop commander, GitHub, Notion) is available in both. Cursor uses a single `mcp.json` file (no DXT extensions); the deploy script can merge these servers into your global Cursor config.

## Included Configs

### New MCP Servers (via claude_desktop_config.json)
| Server | Purpose | API Key Required |
|--------|---------|-----------------|
| GitHub | Repo management, issues, PRs, code search | Yes - GitHub PAT |
| Brave Search | Web search with privacy | Yes - Brave API key |
| PowerShell MCP | PowerShell execution in Claude | No |
| WinGet MCP | Package management | No |
| System Info MCP | Hardware/system queries | No |
| Code Analysis MCP | Codebase analysis | No |
| .NET CLI MCP | dotnet commands | No |
| NuGet MCP | NuGet package operations | No |
| Project Scaffolder MCP | Project generation | No |

### DXT Extension Settings
| Extension | Status | Notes |
|-----------|--------|-------|
| Desktop Commander | Enabled | Optimize limits via chat |
| Context7 | Enabled | Up-to-date docs |
| Filesystem | **Enabled** | Was disabled, now has project dirs |
| Windows-MCP | Enabled | CursorTouch automation |
| Socket | **Enabled** | Was disabled, needs API key |

---

## Cursor MCP Configuration

The same set of capabilities (windows-mcp, filesystem, desktop commander, GitHub, Notion) can be enabled in Cursor via the canonical config and the deploy script.

### Cursor servers (cursor_mcp.json)

| Server | Purpose | API Key / Prereqs |
|--------|---------|-------------------|
| **windows-mcp** | Windows UI automation, window control, input simulation | Python 3.12+ and [uv](https://docs.astral.sh/uv/) (`uvx windows-mcp`) |
| **filesystem-mcp** | Read/write files, list dirs, search; sandboxed to allowed dirs | None (allowed dirs set in args) |
| **desktopcommander-mcp** | Terminal, file edit, code run, Excel/PDF, process management | None |
| **github** | Repos, issues, PRs, code search | GitHub PAT |
| **notion-mcp** | Notion workspace and pages | Notion integration token |

- **Config file:** `cursor_mcp.json` in this folder.  
- **Deploy target:** `%USERPROFILE%\.cursor\mcp.json` (Cursor’s global MCP config).  
- The deploy script substitutes `<USER_HOME>` in filesystem allowed directories with your actual user profile path and can **merge** these five servers into an existing `mcp.json` so other Cursor-only servers are preserved.

### Prerequisites (Cursor)

- **Node.js and npx** – required for filesystem, desktop-commander, GitHub, and Notion servers.
- **Python 3.12+ and uv** – required for **windows-mcp**. Install uv: `pip install uv` or from [astral.sh](https://docs.astral.sh/uv/).
- **Secrets:** Set `GITHUB_PERSONAL_ACCESS_TOKEN` and `NOTION_TOKEN` in `cursor_mcp.json`, or pass `-GitHubPAT` and `-NotionToken` to the deploy script so they are injected at deploy time.

### Deploying to Cursor

Run the deploy script with `-IncludeCursor`:

```powershell
.\Deploy-McpConfigs.ps1 -IncludeCursor
```

To inject secrets from the command line:

```powershell
.\Deploy-McpConfigs.ps1 -IncludeCursor -GitHubPAT "ghp_..." -NotionToken "ntn_..."
```

**Manual fallback:** Copy `cursor_mcp.json` to `%USERPROFILE%\.cursor\mcp.json`, replace `<USER_HOME>` in the filesystem server args with your profile path (e.g. `C:\Users\YourName`), and fill in the GitHub and Notion placeholders.

**Important:** Restart Cursor after changing `mcp.json`; changes are not applied until Cursor is restarted.
