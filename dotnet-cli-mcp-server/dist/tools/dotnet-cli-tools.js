/**
 * .NET CLI tools: build, restore, list projects, publish, test.
 */
import { spawn } from 'node:child_process';
import { existsSync, readdirSync } from 'node:fs';
import { join } from 'node:path';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
function run(command, args, options = {}) {
    return new Promise((resolve) => {
        const proc = spawn(command, args, {
            shell: true,
            windowsHide: true,
            cwd: options.cwd,
        });
        let stdout = '';
        let stderr = '';
        proc.stdout?.on('data', (d) => (stdout += d.toString()));
        proc.stderr?.on('data', (d) => (stderr += d.toString()));
        const t = options.timeout ?? 120_000;
        const timer = setTimeout(() => {
            proc.kill('SIGTERM');
            resolve({ stdout, stderr: stderr || 'Timeout', code: -1 });
        }, t);
        proc.on('close', (code) => {
            clearTimeout(timer);
            resolve({ stdout, stderr, code: code ?? -1 });
        });
        proc.on('error', () => {
            clearTimeout(timer);
            resolve({ stdout, stderr: 'Process error', code: -1 });
        });
    });
}
const text = (out, err, code) => (code === 0 ? out || err : `Exit ${code}\n${err}\n${out}`);
export function registerDotNetCliTools(server) {
    server.setRequestHandler(ListToolsRequestSchema, async () => ({
        tools: [
            {
                name: 'dotnet_build',
                description: 'Build a .NET project or solution.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        project_path: { type: 'string' },
                        configuration: { type: 'string', default: 'Debug' },
                        verbosity: { type: 'string', default: 'minimal' },
                        no_restore: { type: 'boolean', default: false },
                    },
                    required: ['project_path'],
                },
            },
            {
                name: 'dotnet_restore',
                description: 'Restore dependencies for a project.',
                inputSchema: {
                    type: 'object',
                    properties: { project_path: { type: 'string' } },
                    required: ['project_path'],
                },
            },
            {
                name: 'dotnet_list_projects',
                description: 'List projects in a solution or directory.',
                inputSchema: {
                    type: 'object',
                    properties: { solution_path: { type: 'string' } },
                    required: ['solution_path'],
                },
            },
            {
                name: 'dotnet_publish',
                description: 'Publish a .NET project.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        project_path: { type: 'string' },
                        configuration: { type: 'string', default: 'Release' },
                        output: { type: 'string' },
                    },
                    required: ['project_path'],
                },
            },
            {
                name: 'dotnet_test',
                description: 'Run tests for a project.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        project_path: { type: 'string' },
                        no_build: { type: 'boolean', default: false },
                        filter: { type: 'string' },
                    },
                    required: ['project_path'],
                },
            },
        ],
    }));
    server.setRequestHandler(CallToolRequestSchema, async (request) => {
        const { name, arguments: args } = request.params;
        const a = args ?? {};
        try {
            const projectPath = String(a.project_path ?? '');
            const solutionPath = String(a.solution_path ?? '');
            switch (name) {
                case 'dotnet_build': {
                    const configuration = String(a.configuration ?? 'Debug');
                    const verbosity = String(a.verbosity ?? 'minimal');
                    const noRestore = Boolean(a.no_restore);
                    const argsArr = ['build', projectPath, '-c', configuration, `-v:${verbosity}`];
                    if (noRestore)
                        argsArr.push('--no-restore');
                    const r = await run('dotnet', argsArr);
                    return {
                        content: [{ type: 'text', text: text(r.stdout, r.stderr, r.code) }],
                        isError: r.code !== 0,
                    };
                }
                case 'dotnet_restore': {
                    const path = projectPath || solutionPath || '.';
                    const r = await run('dotnet', ['restore', path]);
                    return {
                        content: [{ type: 'text', text: text(r.stdout, r.stderr, r.code) }],
                        isError: r.code !== 0,
                    };
                }
                case 'dotnet_list_projects': {
                    let path = solutionPath || '.';
                    if (path && existsSync(path)) {
                        const entries = readdirSync(path, { withFileTypes: true });
                        const sln = entries.find((e) => e.isFile() && e.name.endsWith('.sln'));
                        if (sln)
                            path = join(path, sln.name);
                    }
                    const r = await run('dotnet', ['sln', path, 'list']);
                    return {
                        content: [{ type: 'text', text: r.stdout || r.stderr }],
                        isError: r.code !== 0,
                    };
                }
                case 'dotnet_publish': {
                    const configuration = String(a.configuration ?? 'Release');
                    const output = a.output;
                    const argsArr = ['publish', projectPath, '-c', configuration];
                    if (output)
                        argsArr.push('-o', output);
                    const r = await run('dotnet', argsArr);
                    return {
                        content: [{ type: 'text', text: text(r.stdout, r.stderr, r.code) }],
                        isError: r.code !== 0,
                    };
                }
                case 'dotnet_test': {
                    const noBuild = Boolean(a.no_build);
                    const filter = a.filter;
                    const argsArr = ['test', projectPath];
                    if (noBuild)
                        argsArr.push('--no-build');
                    if (filter)
                        argsArr.push('--filter', filter);
                    const r = await run('dotnet', argsArr);
                    return {
                        content: [{ type: 'text', text: text(r.stdout, r.stderr, r.code) }],
                        isError: r.code !== 0,
                    };
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
