# Collab MCP Server

MCP server for **Claude–Cursor collaboration**: shared handoff notes and workspace awareness so both agents can coordinate and stay in sync.

## Purpose

- **Handoff notes:** Leave context for the other agent (e.g. "Claude: finished X. Cursor: please run tests.").
- **Workspace summary:** Shared view of git branch, status, and root so both agents use the same context.
- **Project list:** Top-level folders in the workspace so both agents agree on layout.

## Setup

From the **Better11** repo root (or the workspace root where this server lives):

```bash
cd tools/collab-mcp-server
npm install
npm run build
```

**Cursor:** The server is registered in `.cursor/mcp.json`. Restart Cursor after adding or changing it. The server runs with the workspace folder as its working directory.

**Claude Desktop:** Add to your MCP config (e.g. `%APPDATA%\Claude\claude_desktop_config.json` on Windows):

```json
"collab": {
  "command": "node",
  "args": ["C:/path/to/Better11/tools/collab-mcp-server/dist/index.js"],
  "cwd": "C:/path/to/Better11",
  "env": {}
}
```

Optional: set `WORKSPACE_ROOT` in `env` if you want a fixed workspace root instead of the process cwd.

## Tools

| Tool | Description |
|------|-------------|
| `collab_handoff_read` | Read shared handoff notes between Claude and Cursor. |
| `collab_handoff_write` | Write or append to handoff notes (`content`, optional `append`). |
| `collab_workspace_summary` | Get workspace root, git branch, and short status. |
| `collab_list_projects` | List top-level directories in the workspace. |

## Handoff file

Handoff notes are stored at `.cursor/claude-cursor-handoff.md` under the workspace root. Either agent can read or write this file via the tools (or directly). Use it for task handoffs, next steps, or shared context.

## Resources (if supported)

If the MCP SDK supports resources, the server also exposes `workspace://handoff` so clients can subscribe to the handoff notes.
