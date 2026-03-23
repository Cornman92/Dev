/**
 * Code Analysis MCP Server — PSScriptAnalyzer and StyleCop (dotnet build) linting.
 */
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { registerCodeAnalysisTools } from './tools/code-analysis-tools.js';
const server = new Server({ name: 'code-analysis-mcp-server', version: '1.0.0' }, { capabilities: { tools: {} } });
registerCodeAnalysisTools(server);
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
}
main().catch((err) => {
    console.error(err);
    process.exit(1);
});
