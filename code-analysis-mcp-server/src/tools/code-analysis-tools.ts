/**
 * Code analysis tools: PSScriptAnalyzer (PowerShell) and StyleCop/dotnet build (C#).
 */

import { spawn } from 'node:child_process';
import { existsSync } from 'node:fs';
import type { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';

function run(
    command: string,
    args: string[],
    options: { timeout?: number; cwd?: string } = {}
): Promise<{ stdout: string; stderr: string; code: number }> {
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
        const t = options.timeout ?? 60_000;
        const timer = setTimeout(() => {
            proc.kill('SIGTERM');
            resolve({ stdout, stderr, code: -1 });
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

export function registerCodeAnalysisTools(server: Server): void {
    server.setRequestHandler(ListToolsRequestSchema, async () => ({
        tools: [
            {
                name: 'lint_analyze_powershell',
                description: 'Run PSScriptAnalyzer on a PowerShell script or directory.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        path: { type: 'string', description: 'Path to .ps1 file or directory' },
                        recurse: { type: 'boolean', default: false },
                        fix: { type: 'boolean', default: false },
                        include_default_rules: { type: 'boolean', default: true },
                        severity: { type: 'array', items: { type: 'string' }, description: 'Error, Warning, Information' },
                    },
                    required: ['path'],
                },
            },
            {
                name: 'lint_analyze_csharp',
                description: 'Run dotnet build (StyleCop/analyzers) on a C# project.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        project_path: { type: 'string' },
                        treat_warnings_as_errors: { type: 'boolean', default: false },
                        configuration: { type: 'string', default: 'Debug' },
                        verbosity: { type: 'string', default: 'minimal' },
                    },
                    required: ['project_path'],
                },
            },
            {
                name: 'lint_get_rules',
                description: 'List rules for PSScriptAnalyzer or StyleCop categories.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        analyzer: { type: 'string', enum: ['psscriptanalyzer', 'stylecop'] },
                        severity: { type: 'string', description: 'Error, Warning, Information' },
                    },
                    required: ['analyzer'],
                },
            },
            {
                name: 'lint_format_report',
                description: 'Generate a lint report for a path (PowerShell scripts).',
                inputSchema: {
                    type: 'object',
                    properties: {
                        project_path: { type: 'string' },
                        output_format: { type: 'string', enum: ['markdown', 'json'], default: 'markdown' },
                        include_passing: { type: 'boolean', default: false },
                    },
                    required: ['project_path'],
                },
            },
        ],
    }));

    server.setRequestHandler(CallToolRequestSchema, async (request) => {
        const { name, arguments: args } = request.params;
        const a = (args as Record<string, unknown>) ?? {};

        const text = (out: string, err: string, code: number) =>
            code === 0 ? out || err : `Exit ${code}\n${err}\n${out}`;

        try {
            switch (name) {
                case 'lint_analyze_powershell': {
                    const path = String(a.path ?? '');
                    const recurse = Boolean(a.recurse);
                    const fix = Boolean(a.fix);
                    const includeDefault = Boolean(a.include_default_rules ?? true);
                    const severity = a.severity as string[] | undefined;
                    if (!path || !existsSync(path)) {
                        return {
                            content: [{ type: 'text', text: `Path not found: ${path}` }],
                            isError: true,
                        };
                    }
                    const psArgs = [
                        '-NoProfile',
                        '-Command',
                        `Invoke-ScriptAnalyzer -Path '${path.replace(/'/g, "''")}'${recurse ? ' -Recurse' : ''}${fix ? ' -Fix' : ''}${includeDefault ? '' : ' -ExcludeDefaultRules'}${severity?.length ? ` -Severity @(${severity.map((s: string) => "'" + s + "'").join(',')})` : ''} | ConvertTo-Json -Depth 5`,
                    ];
                    const r = await run('pwsh', psArgs, { timeout: 120_000 });
                    const out = r.stdout || r.stderr || 'No output (PSScriptAnalyzer may not be installed: Install-Module PSScriptAnalyzer -Scope CurrentUser)';
                    return {
                        content: [{ type: 'text', text: out }],
                        isError: r.code !== 0,
                    };
                }
                case 'lint_analyze_csharp': {
                    const projectPath = String(a.project_path ?? '');
                    const treatWarningsAsErrors = Boolean(a.treat_warnings_as_errors);
                    const configuration = String(a.configuration ?? 'Debug');
                    const verbosity = String(a.verbosity ?? 'minimal');
                    const buildArgs = ['build', projectPath, '-c', configuration, `-v:${verbosity}`];
                    if (treatWarningsAsErrors) buildArgs.push('-warnaserror');
                    if (!existsSync(projectPath)) {
                        return {
                            content: [{ type: 'text', text: `Project path not found: ${projectPath}` }],
                            isError: true,
                        };
                    }
                    const r = await run('dotnet', buildArgs, { timeout: 120_000 });
                    return {
                        content: [{ type: 'text', text: text(r.stdout, r.stderr, r.code) }],
                        isError: r.code !== 0,
                    };
                }
                case 'lint_get_rules': {
                    const analyzer = String(a.analyzer ?? '').toLowerCase();
                    const severity = a.severity as string | undefined;
                    if (analyzer === 'stylecop') {
                        const categories = 'Spacing, Readability, Ordering, Naming, Maintainability, Documentation';
                        return {
                            content: [{ type: 'text', text: `StyleCop rule categories: ${categories}. Use dotnet build with StyleCop.Analyzers package for details.` }],
                        };
                    }
                    if (analyzer === 'psscriptanalyzer') {
                        const psCmd = severity
                            ? `Get-ScriptAnalyzerRule -Severity '${severity}' | ConvertTo-Json -Depth 3`
                            : 'Get-ScriptAnalyzerRule | ConvertTo-Json -Depth 3';
                        const r = await run('pwsh', ['-NoProfile', '-Command', psCmd], { timeout: 15_000 });
                        const out = r.stdout || r.stderr || 'Install-Module PSScriptAnalyzer -Scope CurrentUser';
                        return { content: [{ type: 'text', text: out }] };
                    }
                    return {
                        content: [{ type: 'text', text: `Unknown analyzer: ${analyzer}. Use psscriptanalyzer or stylecop.` }],
                        isError: true,
                    };
                }
                case 'lint_format_report': {
                    const projectPath = String(a.project_path ?? '');
                    const outputFormat = String(a.output_format ?? 'markdown');
                    const includePassing = Boolean(a.include_passing);
                    if (!existsSync(projectPath)) {
                        return {
                            content: [{ type: 'text', text: `Path not found: ${projectPath}` }],
                            isError: true,
                        };
                    }
                    const psCmd = `$r = Invoke-ScriptAnalyzer -Path '${projectPath.replace(/'/g, "''")}' -Recurse; ${outputFormat === 'json' ? '$r | ConvertTo-Json -Depth 4' : '$r | Format-List | Out-String'}`;
                    const r = await run('pwsh', ['-NoProfile', '-Command', psCmd], { timeout: 120_000 });
                    let out = r.stdout || r.stderr || 'No output.';
                    if (outputFormat === 'markdown' && out.length > 0) {
                        out = '## Lint Report\n\n```\n' + out + '\n```';
                    }
                    return {
                        content: [{ type: 'text', text: out }],
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
