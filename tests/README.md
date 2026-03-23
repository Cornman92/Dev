# Dev workspace shared test utilities

- **integration-helpers.ts** — Shared helpers for MCP server integration tests: `createToolCapture`, `invokeTool`, `assertValidContent`, `requireWindows`, `isDotNetAvailable`, `isPSModuleAvailable`. Used by code-analysis, powershell, system-info, winget, dotnet-cli, nuget, and time-utils MCP servers.
- Each MCP server package also has a copy of the helper under its own `tests/integration-helpers.ts` so that `../../tests/integration-helpers.js` resolves when running vitest from the server directory.

Run integration tests from a specific server, e.g.:

```bash
cd D:\Dev\time-utils-mcp-server
npm install
npm run build
npm run test:integration
```
