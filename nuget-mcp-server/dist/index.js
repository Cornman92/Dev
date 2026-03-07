/**
 * NuGet MCP Server — search, get package, compare versions, list installed, check updates.
 */
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { registerNuGetTools } from './tools/nuget-tools.js';
const server = new Server({ name: 'nuget-mcp-server', version: '1.0.0' }, { capabilities: { tools: {} } });
registerNuGetTools(server);
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
}
main().catch((err) => {
    console.error(err);
    process.exit(1);
});
