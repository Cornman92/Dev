/**
 * Project Scaffolder MCP Server — entry point.
 * Generates Better11 project patterns: PS modules, C# ViewModels/Services, docs.
 */
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { SERVER_NAME, SERVER_VERSION } from './constants.js';
import { registerScaffolderTools } from './tools/scaffolder-tools.js';
const server = new McpServer({
    name: SERVER_NAME,
    version: SERVER_VERSION,
});
registerScaffolderTools(server);
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error(`${SERVER_NAME} v${SERVER_VERSION} running on stdio`);
}
main().catch((error) => {
    console.error('Fatal error:', error);
    process.exit(1);
});
//# sourceMappingURL=index.js.map