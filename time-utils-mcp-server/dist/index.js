/**
 * Time Utils MCP Server — entry point.
 * Exposes time/date tools: current time, timezone list, format, parse.
 */
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { registerTimeTools } from './tools/time-tools.js';
const server = new Server({
    name: 'time-utils-mcp-server',
    version: '1.0.0',
}, {
    capabilities: {
        tools: {},
    },
});
registerTimeTools(server);
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
}
main().catch((err) => {
    console.error(err);
    process.exit(1);
});
