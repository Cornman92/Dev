/**
 * PowerShell MCP Server — run scripts, invoke cmdlets, list modules, PSScriptAnalyzer.
 */
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { registerPowerShellTools } from './tools/powershell-tools.js';
const server = new Server({ name: 'powershell-mcp-server', version: '1.0.0' }, { capabilities: { tools: {} } });
registerPowerShellTools(server);
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
}
main().catch((err) => {
    console.error(err);
    process.exit(1);
});
