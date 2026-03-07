# Dev Workspace MCP Stub Template (3.2.1)

Use this checklist when scaffolding a **new MCP server** in the Dev workspace so it matches the existing pattern and can be wired into root `test:mcp-all` and the dashboard.

## 1. Project layout

- `package.json` with `name: "*-mcp-server"`, `test` and optionally `test:integration` scripts.
- `src/index.ts` (or `src/index.js`) — MCP server entry, tool registration.
- TypeScript: `tsconfig.json`, build output in `dist/`.

## 2. Root integration

- Add to root `package.json`: `"test:mcp-<name>": "cd <name>-mcp-server && npm run test"` (or `npm run test:integration` if present).
- Add to `run-all-mcp-tests.cjs` scripts array.
- Add to `Invoke-McpHealthCheck.ps1` `$mcpServers` array.
- Document in [docs/MCP-SERVER-INDEX.md](../../docs/MCP-SERVER-INDEX.md).

## 3. Dashboard (optional)

- If the server exposes runnable actions (e.g. lint, run script), consider adding a **quick action** in `dev-dashboard/backend/routes/workspace.js` that invokes it or a related script.

## 4. Existing scaffolder tools

Use **project-scaffolder-mcp-server** tools:

- `scaffold_ps_module` — new PowerShell module (Better11 style).
- `scaffold_csharp_viewmodel` / `scaffold_csharp_service` — C# ViewModel/Service.
- `scaffold_readme` / `scaffold_changelog` — docs.
- `scaffold_full_module` — full PS module + C# + README/CHANGELOG.

For a minimal MCP stub, create the Node/TypeScript project by hand and use this doc as the checklist.
