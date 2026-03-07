/**
 * WinGet MCP Server — search, show, list, list upgradable.
 */
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { registerWinGetTools } from './tools/winget-tools.js';
const server = new Server({ name: 'winget-mcp-server', version: '1.0.0' }, { capabilities: { tools: {} } });
registerWinGetTools(server);
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
}
main().catch((err) => {
    console.error(err);
    process.exit(1);
});
