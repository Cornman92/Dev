/**
 * .NET CLI MCP Server — build, restore, list projects, publish, test.
 */
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { registerDotNetCliTools } from './tools/dotnet-cli-tools.js';
const server = new Server({ name: 'dotnet-cli-mcp-server', version: '1.0.0' }, { capabilities: { tools: {} } });
registerDotNetCliTools(server);
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
}
main().catch((err) => {
    console.error(err);
    process.exit(1);
});
