/**
 * System Info MCP Server — WMI/CIM, registry, services, drivers, installed software.
 */

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { registerSystemInfoTools } from './tools/system-info-tools.js';

const server = new Server(
    { name: 'system-info-mcp-server', version: '1.0.0' },
    { capabilities: { tools: {} } }
);

registerSystemInfoTools(server);

async function main(): Promise<void> {
    const transport = new StdioServerTransport();
    await server.connect(transport);
}

main().catch((err) => {
    console.error(err);
    process.exit(1);
});
