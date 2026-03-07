/**
 * WinGet tools: search, show, list, list upgradable.
 */
import { spawn } from 'node:child_process';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
function runWinget(args, timeout = 60_000) {
    return new Promise((resolve) => {
        const proc = spawn('winget', args, { shell: true, windowsHide: true });
        let stdout = '';
        let stderr = '';
        proc.stdout?.on('data', (d) => (stdout += d.toString()));
        proc.stderr?.on('data', (d) => (stderr += d.toString()));
        const timer = setTimeout(() => {
            proc.kill('SIGTERM');
            resolve({ stdout, stderr: stderr || 'Timeout', code: -1 });
        }, timeout);
        proc.on('close', (code) => {
            clearTimeout(timer);
            resolve({ stdout, stderr, code: code ?? -1 });
        });
        proc.on('error', (e) => {
            clearTimeout(timer);
            resolve({ stdout, stderr: String(e), code: -1 });
        });
    });
}
export function registerWinGetTools(server) {
    server.setRequestHandler(ListToolsRequestSchema, async () => ({
        tools: [
            {
                name: 'winget_search',
                description: 'Search for packages using winget.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        query: { type: 'string' },
                        count: { type: 'number', default: 20 },
                        exact: { type: 'boolean', default: false },
                        source: { type: 'string', description: 'e.g. winget' },
                    },
                    required: ['query'],
                },
            },
            {
                name: 'winget_show',
                description: 'Show details for a package by id.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        package_id: { type: 'string' },
                        versions: { type: 'boolean', default: false },
                    },
                    required: ['package_id'],
                },
            },
            {
                name: 'winget_list',
                description: 'List installed packages.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        count: { type: 'number' },
                        query: { type: 'string' },
                    },
                },
            },
            {
                name: 'winget_list_upgradable',
                description: 'List packages that have updates available.',
                inputSchema: {
                    type: 'object',
                    properties: { include_unknown: { type: 'boolean', default: false } },
                },
            },
        ],
    }));
    server.setRequestHandler(CallToolRequestSchema, async (request) => {
        const { name, arguments: args } = request.params;
        const a = args ?? {};
        try {
            switch (name) {
                case 'winget_search': {
                    const query = String(a.query ?? '');
                    const count = Number(a.count) ?? 20;
                    const exact = Boolean(a.exact);
                    const source = a.source;
                    const argsArr = ['search', query, '--accept-source-agreements'];
                    if (count > 0)
                        argsArr.push('--count', String(count));
                    if (exact)
                        argsArr.push('--exact');
                    if (source)
                        argsArr.push('--source', source);
                    const r = await runWinget(argsArr);
                    const text = r.stdout || r.stderr || 'No output.';
                    return {
                        content: [{ type: 'text', text }],
                        isError: r.code !== 0,
                    };
                }
                case 'winget_show': {
                    const packageId = String(a.package_id ?? '');
                    const versions = Boolean(a.versions);
                    const argsArr = ['show', packageId, '--accept-source-agreements'];
                    if (versions)
                        argsArr.push('--versions');
                    const r = await runWinget(argsArr);
                    const text = r.stdout || r.stderr || 'No output.';
                    return {
                        content: [{ type: 'text', text }],
                        isError: r.code !== 0,
                    };
                }
                case 'winget_list': {
                    const count = a.count;
                    const query = a.query;
                    const argsArr = ['list', '--accept-source-agreements'];
                    if (count != null && count > 0)
                        argsArr.push('--count', String(count));
                    if (query)
                        argsArr.push('--query', query);
                    const r = await runWinget(argsArr);
                    const text = r.stdout || r.stderr || 'No output.';
                    return { content: [{ type: 'text', text }] };
                }
                case 'winget_list_upgradable': {
                    const includeUnknown = Boolean(a.include_unknown);
                    const argsArr = ['list', '--upgrade-available', '--accept-source-agreements'];
                    if (includeUnknown)
                        argsArr.push('--include-unknown');
                    const r = await runWinget(argsArr);
                    const text = r.stdout || r.stderr || 'No output.';
                    return { content: [{ type: 'text', text }] };
                }
                default:
                    return {
                        content: [{ type: 'text', text: `Unknown tool: ${name}` }],
                        isError: true,
                    };
            }
        }
        catch (err) {
            const message = err instanceof Error ? err.message : String(err);
            return {
                content: [{ type: 'text', text: `Error: ${message}` }],
                isError: true,
            };
        }
    });
}
