/**
 * Shared integration test helpers for MCP server test suites.
 * Schema-agnostic: matches handlers by schema.method so no SDK import is required here.
 */
import { spawnSync } from 'node:child_process';
import { platform } from 'node:os';

export interface CallToolResult {
    content: Array<{ type: 'text'; text: string }>;
    isError?: boolean;
}

export function requireWindows(): void {
    if (platform() !== 'win32') {
        throw new Error('These integration tests require Windows');
    }
}

export async function isDotNetAvailable(): Promise<boolean> {
    try {
        const r = spawnSync('dotnet', ['--version'], {
            encoding: 'utf8',
            timeout: 5000,
            windowsHide: true,
        });
        return r.status === 0 && (r.stdout?.trim()?.length ?? 0) > 0;
    } catch {
        return false;
    }
}

export async function isPSModuleAvailable(name: string): Promise<boolean> {
    try {
        const r = spawnSync(
            'pwsh',
            ['-NoProfile', '-Command', `Get-Module -ListAvailable -Name '${name}' | Select-Object -First 1`],
            { encoding: 'utf8', timeout: 10_000, windowsHide: true }
        );
        return r.status === 0 && (r.stdout?.trim()?.length ?? 0) > 0;
    } catch {
        return false;
    }
}

type ListToolsHandler = () => Promise<{ tools: Array<{ name: string; description?: string; inputSchema?: unknown }> }>;
type CallToolHandler = (request: { params: { name: string; arguments?: unknown } }) => Promise<CallToolResult>;

export interface ToolCaptureServer {
    setRequestHandler(schema: unknown, handler: ListToolsHandler | CallToolHandler): void;
}

export interface ToolsInvoker {
    invoke(name: string, args: Record<string, unknown>): Promise<CallToolResult>;
}

function getSchemaMethod(schema: unknown): string | undefined {
    if (schema && typeof schema === 'object' && 'method' in schema && typeof (schema as { method: unknown }).method === 'string') {
        return (schema as { method: string }).method;
    }
    return undefined;
}

export function createToolCapture(): { server: ToolCaptureServer; tools: ToolsInvoker } {
    const handlers: { listTools?: ListToolsHandler; callTool?: CallToolHandler } = {};
    let callCount = 0;

    const server: ToolCaptureServer = {
        setRequestHandler(schema: unknown, handler: ListToolsHandler | CallToolHandler) {
            const method = getSchemaMethod(schema);
            if (method === 'tools/list') {
                handlers.listTools = handler as ListToolsHandler;
            } else if (method === 'tools/call') {
                handlers.callTool = handler as CallToolHandler;
            } else {
                callCount++;
                if (callCount === 1) handlers.listTools = handler as ListToolsHandler;
                else if (callCount === 2) handlers.callTool = handler as CallToolHandler;
            }
        },
    };

    const tools: ToolsInvoker = {
        async invoke(name: string, args: Record<string, unknown>): Promise<CallToolResult> {
            if (!handlers.callTool) {
                return {
                    content: [{ type: 'text', text: 'No CallTool handler registered' }],
                    isError: true,
                };
            }
            return handlers.callTool({
                params: { name, arguments: args },
            } as Parameters<CallToolHandler>[0]);
        },
    };

    return { server, tools };
}

export async function invokeTool(
    tools: ToolsInvoker,
    name: string,
    args: Record<string, unknown>
): Promise<CallToolResult> {
    return tools.invoke(name, args);
}

export function assertValidContent(result: CallToolResult): void {
    if (!result || typeof result !== 'object') {
        throw new Error('Tool result must be an object');
    }
    if (!Array.isArray(result.content) || result.content.length === 0) {
        throw new Error('Tool result must have at least one content item');
    }
    const first = result.content[0];
    if (!first || first.type !== 'text' || typeof first.text !== 'string') {
        throw new Error('First content item must be { type: "text", text: string }');
    }
}
