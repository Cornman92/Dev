/**
 * PowerShell tools: invoke script, invoke cmdlet, get module, test analyzer.
 */
import { spawn } from 'node:child_process';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
const DEFAULT_TIMEOUT_MS = 30_000;
function runPs(script, options = {}) {
    return new Promise((resolve) => {
        const timeoutMs = options.timeoutMs ?? DEFAULT_TIMEOUT_MS;
        const proc = spawn('pwsh', ['-NoProfile', '-NonInteractive', '-Command', script], {
            shell: false,
            windowsHide: true,
        });
        let stdout = '';
        let stderr = '';
        proc.stdout?.on('data', (d) => (stdout += d.toString()));
        proc.stderr?.on('data', (d) => (stderr += d.toString()));
        const timer = setTimeout(() => {
            proc.kill('SIGTERM');
            resolve({ stdout, stderr: stderr || 'Timeout', code: -1 });
        }, timeoutMs);
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
function escapePsArg(s) {
    return s.replace(/'/g, "''");
}
export function registerPowerShellTools(server) {
    server.setRequestHandler(ListToolsRequestSchema, async () => ({
        tools: [
            {
                name: 'ps_invoke_script',
                description: 'Execute a PowerShell script string and return output.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        script: { type: 'string' },
                        timeout_ms: { type: 'number', default: 30000 },
                    },
                    required: ['script'],
                },
            },
            {
                name: 'ps_invoke_command',
                description: 'Invoke a PowerShell cmdlet with parameters.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        cmdlet: { type: 'string' },
                        parameters: { type: 'object', additionalProperties: true },
                        as_json: { type: 'boolean', default: false },
                    },
                    required: ['cmdlet'],
                },
            },
            {
                name: 'ps_get_module',
                description: 'List or get PowerShell module info.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        name: { type: 'string' },
                        list_available: { type: 'boolean', default: false },
                        detailed: { type: 'boolean', default: false },
                    },
                },
            },
            {
                name: 'ps_test_analyzer',
                description: 'Run PSScriptAnalyzer on inline script content.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        script_content: { type: 'string' },
                        severity: { type: 'array', items: { type: 'string' } },
                        exclude_rules: { type: 'array', items: { type: 'string' } },
                    },
                    required: ['script_content'],
                },
            },
        ],
    }));
    server.setRequestHandler(CallToolRequestSchema, async (request) => {
        const { name, arguments: args } = request.params;
        const a = args ?? {};
        try {
            switch (name) {
                case 'ps_invoke_script': {
                    const script = String(a.script ?? '');
                    const timeoutMs = Number(a.timeout_ms) || DEFAULT_TIMEOUT_MS;
                    const r = await runPs(script, { timeoutMs });
                    const out = (r.stdout + (r.stderr ? '\n' + r.stderr : '')).replace(/\r\n/g, '\n').trim();
                    return {
                        content: [{ type: 'text', text: out || `Exit ${r.code}` }],
                        isError: r.code !== 0,
                    };
                }
                case 'ps_invoke_command': {
                    const cmdlet = String(a.cmdlet ?? '');
                    const parameters = a.parameters ?? {};
                    const asJson = Boolean(a.as_json);
                    const paramStr = Object.entries(parameters)
                        .map(([k, v]) => {
                        if (v === true)
                            return `-${k}`;
                        if (v === false)
                            return `-${k}:$false`;
                        const val = typeof v === 'string' ? `'${escapePsArg(v)}'` : String(v);
                        return `-${k} ${val}`;
                    })
                        .join(' ');
                    const script = paramStr
                        ? `${cmdlet} ${paramStr}${asJson ? ' | ConvertTo-Json -Depth 5' : ' | Out-String'}`
                        : cmdlet + (asJson ? ' | ConvertTo-Json -Depth 5' : ' | Out-String');
                    const r = await runPs(script);
                    const out = r.stdout + (r.stderr ? '\n' + r.stderr : '');
                    return {
                        content: [{ type: 'text', text: out.trim() || `Exit ${r.code}` }],
                        isError: r.code !== 0,
                    };
                }
                case 'ps_get_module': {
                    const modName = a.name;
                    const listAvailable = Boolean(a.list_available);
                    const detailed = Boolean(a.detailed);
                    let script;
                    if (modName) {
                        script = listAvailable
                            ? `Get-Module -ListAvailable -Name '${escapePsArg(modName)}'${detailed ? ' | Format-List' : ''} | Out-String`
                            : `Get-Module -Name '${escapePsArg(modName)}' | Out-String`;
                    }
                    else {
                        script = `Get-Module -ListAvailable | Out-String`;
                    }
                    const r = await runPs(script);
                    const out = r.stdout || r.stderr || '';
                    return { content: [{ type: 'text', text: out.trim() }] };
                }
                case 'ps_test_analyzer': {
                    const scriptContent = String(a.script_content ?? '');
                    const severity = a.severity;
                    const excludeRules = a.exclude_rules;
                    const sevArg = severity?.length ? ` -Severity @(${severity.map((s) => `'${s}'`).join(',')})` : '';
                    const excludeArg = excludeRules?.length ? ` -ExcludeRule @(${excludeRules.map((r) => `'${r}'`).join(',')})` : '';
                    const script = `Invoke-ScriptAnalyzer -ScriptDefinition @'\n${scriptContent.replace(/'/g, "''")}\n'@${sevArg}${excludeArg} | ConvertTo-Json -Depth 4`;
                    const r = await runPs(script);
                    const out = r.stdout || r.stderr || 'No output (Install-Module PSScriptAnalyzer -Scope CurrentUser)';
                    return {
                        content: [{ type: 'text', text: out.trim() }],
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
