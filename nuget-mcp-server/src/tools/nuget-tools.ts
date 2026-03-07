/**
 * NuGet tools: search (NuGet API), get package, compare versions, list installed, check updates.
 */

import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import type { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';

const NUGET_SEARCH_URL = 'https://azuresearch-usnc.nuget.org/query';

async function nugetSearch(
    query: string,
    options: { includePrerelease?: boolean; take?: number } = {}
): Promise<string> {
    const take = options.take ?? 20;
    const url = `${NUGET_SEARCH_URL}?q=${encodeURIComponent(query)}&prerelease=${options.includePrerelease ?? false}&take=${take}`;
    const res = await fetch(url);
    if (!res.ok) return `Search failed: ${res.status} ${res.statusText}`;
    const data = (await res.json()) as { data?: Array<{ id?: string; version?: string; description?: string }> };
    const items = data.data ?? [];
    return JSON.stringify(items.map((p) => ({ id: p.id, version: p.version, description: (p.description ?? '').slice(0, 200) })), null, 2);
}

async function nugetPackageVersions(packageId: string): Promise<string[]> {
    const url = `https://api.nuget.org/v3-flatcontainer/${packageId.toLowerCase()}/index.json`;
    const res = await fetch(url);
    if (!res.ok) return [];
    const data = (await res.json()) as { versions?: string[] };
    return data.versions ?? [];
}

function runDotnet(args: string[], cwd?: string): Promise<{ stdout: string; stderr: string; code: number }> {
    return new Promise((resolve) => {
        const proc = spawn('dotnet', args, { shell: true, windowsHide: true, cwd });
        let stdout = '';
        let stderr = '';
        proc.stdout?.on('data', (d) => (stdout += d.toString()));
        proc.stderr?.on('data', (d) => (stderr += d.toString()));
        proc.on('close', (code) => resolve({ stdout, stderr, code: code ?? -1 }));
        proc.on('error', (e) => resolve({ stdout, stderr: String(e), code: -1 }));
    });
}

function compareVersions(a: string, b: string): number {
    const pa = a.split('.').map(Number);
    const pb = b.split('.').map(Number);
    for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
        const va = pa[i] ?? 0;
        const vb = pb[i] ?? 0;
        if (va !== vb) return va < vb ? -1 : 1;
    }
    return 0;
}

export function registerNuGetTools(server: Server): void {
    server.setRequestHandler(ListToolsRequestSchema, async () => ({
        tools: [
            {
                name: 'nuget_search',
                description: 'Search NuGet packages by name.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        query: { type: 'string' },
                        include_prerelease: { type: 'boolean', default: false },
                        max_results: { type: 'number', default: 20 },
                    },
                    required: ['query'],
                },
            },
            {
                name: 'nuget_get_package',
                description: 'Get package metadata and optionally versions.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        package_id: { type: 'string' },
                        include_versions: { type: 'boolean', default: false },
                    },
                    required: ['package_id'],
                },
            },
            {
                name: 'nuget_compare_versions',
                description: 'Compare two versions of a package.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        package_id: { type: 'string' },
                        version_a: { type: 'string' },
                        version_b: { type: 'string' },
                    },
                    required: ['package_id', 'version_a', 'version_b'],
                },
            },
            {
                name: 'nuget_list_installed',
                description: 'List NuGet packages installed in a project.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        project_path: { type: 'string' },
                        include_transitive: { type: 'boolean', default: false },
                    },
                    required: ['project_path'],
                },
            },
            {
                name: 'nuget_check_updates',
                description: 'Check for package updates in a project.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        project_path: { type: 'string' },
                        include_prerelease: { type: 'boolean', default: false },
                    },
                    required: ['project_path'],
                },
            },
        ],
    }));

    server.setRequestHandler(CallToolRequestSchema, async (request) => {
        const { name, arguments: args } = request.params;
        const a = (args as Record<string, unknown>) ?? {};

        try {
            switch (name) {
                case 'nuget_search': {
                    const query = String(a.query ?? '');
                    const includePrerelease = Boolean(a.include_prerelease);
                    const maxResults = Number(a.max_results) || 20;
                    const text = await nugetSearch(query, { includePrerelease, take: maxResults });
                    return { content: [{ type: 'text', text }] };
                }
                case 'nuget_get_package': {
                    const packageId = String(a.package_id ?? '');
                    const includeVersions = Boolean(a.include_versions);
                    const metaUrl = `https://api.nuget.org/v3-flatcontainer/${packageId.toLowerCase()}/index.json`;
                    const res = await fetch(metaUrl);
                    if (!res.ok) {
                        return {
                            content: [{ type: 'text', text: `Package not found: ${packageId}` }],
                            isError: true,
                        };
                    }
                    const index = (await res.json()) as { versions?: string[] };
                    const versions = index.versions ?? [];
                    let text = `Package: ${packageId}\nVersions count: ${versions.length}`;
                    if (includeVersions && versions.length > 0) {
                        const recent = versions.slice(-20).reverse();
                        text += `\nRecent versions: ${recent.join(', ')}`;
                    }
                    return { content: [{ type: 'text', text }] };
                }
                case 'nuget_compare_versions': {
                    const packageId = String(a.package_id ?? '');
                    const versionA = String(a.version_a ?? '');
                    const versionB = String(a.version_b ?? '');
                    const cmp = compareVersions(versionA, versionB);
                    const result = cmp < 0 ? `${versionA} < ${versionB}` : cmp > 0 ? `${versionA} > ${versionB}` : `${versionA} == ${versionB}`;
                    const text = `Package: ${packageId}\nCompare: ${result}`;
                    return { content: [{ type: 'text', text }] };
                }
                case 'nuget_list_installed': {
                    const projectPath = String(a.project_path ?? '');
                    const includeTransitive = Boolean(a.include_transitive);
                    if (!existsSync(projectPath)) {
                        return {
                            content: [{ type: 'text', text: `Project path not found: ${projectPath}` }],
                            isError: true,
                        };
                    }
                    const argsArr = ['list', 'package', '--project', projectPath];
                    if (includeTransitive) argsArr.push('--include-transitive');
                    const r = await runDotnet(argsArr, projectPath);
                    const text = r.stdout || r.stderr || 'No output.';
                    return {
                        content: [{ type: 'text', text }],
                        isError: r.code !== 0,
                    };
                }
                case 'nuget_check_updates': {
                    const projectPath = String(a.project_path ?? '');
                    const includePrerelease = Boolean(a.include_prerelease);
                    if (!existsSync(projectPath)) {
                        return {
                            content: [{ type: 'text', text: `Project path not found: ${projectPath}` }],
                            isError: true,
                        };
                    }
                    const argsArr = ['list', 'package', '--outdated', '--project', projectPath];
                    if (includePrerelease) argsArr.push('--prerelease');
                    const r = await runDotnet(argsArr, projectPath);
                    const text = r.stdout || r.stderr || 'No output.';
                    return {
                        content: [{ type: 'text', text }],
                        isError: r.code !== 0,
                    };
                }
                default:
                    return {
                        content: [{ type: 'text', text: `Unknown tool: ${name}` }],
                        isError: true,
                    };
            }
        } catch (err) {
            const message = err instanceof Error ? err.message : String(err);
            return {
                content: [{ type: 'text', text: `Error: ${message}` }],
                isError: true,
            };
        }
    });
}
