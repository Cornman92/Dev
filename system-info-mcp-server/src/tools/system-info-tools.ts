/**
 * System info tools: WMI/CIM, registry, services, drivers, installed software.
 */

import { spawn } from 'node:child_process';
import type { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';

function runPs(command: string): Promise<{ stdout: string; stderr: string; code: number }> {
    return new Promise((resolve) => {
        const proc = spawn('pwsh', ['-NoProfile', '-NonInteractive', '-Command', command], {
            shell: true,
            windowsHide: true,
        });
        let stdout = '';
        let stderr = '';
        proc.stdout?.on('data', (d) => (stdout += d.toString()));
        proc.stderr?.on('data', (d) => (stderr += d.toString()));
        proc.on('close', (code) => resolve({ stdout, stderr, code: code ?? -1 }));
        proc.on('error', (e) => resolve({ stdout, stderr: String(e), code: -1 }));
    });
}

function escapeSingle(s: string): string {
    return s.replace(/'/g, "''");
}

export function registerSystemInfoTools(server: Server): void {
    server.setRequestHandler(ListToolsRequestSchema, async () => ({
        tools: [
            {
                name: 'sysinfo_get_system',
                description: 'Get OS, hardware, memory, disk, network summary.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        categories: {
                            type: 'array',
                            items: { type: 'string', enum: ['os', 'hardware', 'memory', 'disk', 'network'] },
                        },
                    },
                },
            },
            {
                name: 'sysinfo_query_wmi',
                description: 'Query WMI/CIM class with optional properties and filter.',
                inputSchema: {
                    type: 'object',
                    properties: {
                        class_name: { type: 'string' },
                        properties: { type: 'array', items: { type: 'string' } },
                        filter: { type: 'string' },
                    },
                    required: ['class_name'],
                },
            },
            {
                name: 'sysinfo_get_services',
                description: 'List Windows services (optional filter by name or status).',
                inputSchema: {
                    type: 'object',
                    properties: {
                        name: { type: 'string' },
                        status: { type: 'string', enum: ['Running', 'Stopped', 'All'] },
                    },
                },
            },
            {
                name: 'sysinfo_get_drivers',
                description: 'List system drivers (optional signed only).',
                inputSchema: {
                    type: 'object',
                    properties: { signed_only: { type: 'boolean', default: false } },
                },
            },
            {
                name: 'sysinfo_query_registry',
                description: 'Read registry path (optional value name).',
                inputSchema: {
                    type: 'object',
                    properties: {
                        path: { type: 'string' },
                        value_name: { type: 'string' },
                    },
                    required: ['path'],
                },
            },
            {
                name: 'sysinfo_get_software',
                description: 'List installed software (optional name filter).',
                inputSchema: {
                    type: 'object',
                    properties: { name: { type: 'string' } },
                },
            },
        ],
    }));

    server.setRequestHandler(CallToolRequestSchema, async (request) => {
        const { name, arguments: args } = request.params;
        const a = (args as Record<string, unknown>) ?? {};

        try {
            switch (name) {
                case 'sysinfo_get_system': {
                    const categories = (a.categories as string[]) ?? ['os', 'hardware', 'network'];
                    const parts: string[] = [];
                    if (categories.includes('os')) {
                        const r = await runPs(
                            "Get-CimInstance Win32_OperatingSystem | Select-Object Caption,Version,BuildNumber,OSArchitecture | ConvertTo-Json"
                        );
                        parts.push('OS: ' + (r.stdout || r.stderr));
                    }
                    if (categories.includes('hardware')) {
                        const r = await runPs(
                            "Get-CimInstance Win32_ComputerSystem | Select-Object Manufacturer,Model,NumberOfLogicalProcessors | ConvertTo-Json"
                        );
                        parts.push('Hardware: ' + (r.stdout || r.stderr));
                    }
                    if (categories.includes('memory')) {
                        const r = await runPs(
                            "Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum | Select-Object @{N='TotalGB';E={[math]::Round($_.Sum/1GB,2)}} | ConvertTo-Json"
                        );
                        parts.push('Memory: ' + (r.stdout || r.stderr));
                    }
                    if (categories.includes('disk')) {
                        const r = await runPs(
                            "Get-CimInstance Win32_LogicalDisk -Filter \"DriveType=3\" | Select-Object DeviceID,Size,FreeSpace,FileSystem | ConvertTo-Json"
                        );
                        parts.push('Disk: ' + (r.stdout || r.stderr));
                    }
                    if (categories.includes('network')) {
                        const r = await runPs(
                            "Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True' | Select-Object Description,IPAddress,MACAddress | ConvertTo-Json"
                        );
                        parts.push('Network: ' + (r.stdout || r.stderr));
                    }
                    return { content: [{ type: 'text', text: parts.join('\n\n') }] };
                }
                case 'sysinfo_query_wmi': {
                    const className = String(a.class_name ?? '');
                    const properties = (a.properties as string[]) ?? [];
                    const filter = a.filter as string | undefined;
                    const propList = properties.length ? properties.map((p) => `'${escapeSingle(p)}'`).join(',') : '*';
                    const filterClause = filter ? ` -Filter '${escapeSingle(filter)}'` : '';
                    const cmd = `Get-CimInstance -ClassName '${escapeSingle(className)}'${filterClause} | Select-Object ${propList} | ConvertTo-Json -Depth 3`;
                    const r = await runPs(cmd);
                    const text = r.stdout || r.stderr || 'No instances or error.';
                    return {
                        content: [{ type: 'text', text }],
                        isError: r.code !== 0,
                    };
                }
                case 'sysinfo_get_services': {
                    const svcName = a.name as string | undefined;
                    const status = a.status as string | undefined;
                    let cmd = 'Get-Service';
                    if (svcName) cmd += ` -Name '${escapeSingle(svcName)}'`;
                    if (status && status !== 'All') cmd += ` | Where-Object Status -eq '${status}'`;
                    cmd += ' | Select-Object Name,DisplayName,Status | ConvertTo-Json';
                    const r = await runPs(cmd);
                    return { content: [{ type: 'text', text: r.stdout || r.stderr }] };
                }
                case 'sysinfo_get_drivers': {
                    const signedOnly = Boolean(a.signed_only);
                    let cmd = 'Get-WmiObject Win32_PnPSignedDriver | Select-Object DeviceName,DriverVersion,Manufacturer -First 200';
                    if (signedOnly) cmd = 'Get-WmiObject Win32_PnPSignedDriver | Where-Object { $_.IsSigned -eq $true } | Select-Object DeviceName,DriverVersion -First 200';
                    cmd += ' | ConvertTo-Json';
                    const r = await runPs(cmd);
                    return { content: [{ type: 'text', text: r.stdout || r.stderr }] };
                }
                case 'sysinfo_query_registry': {
                    const path = String(a.path ?? '');
                    const valueName = a.value_name as string | undefined;
                    let cmd: string;
                    if (valueName) {
                        cmd = `(Get-ItemProperty -Path '${escapeSingle(path)}' -ErrorAction SilentlyContinue).'${escapeSingle(valueName)}' | Out-String`;
                    } else {
                        cmd = `Get-Item -Path '${escapeSingle(path)}' -ErrorAction SilentlyContinue | Get-ItemProperty | ConvertTo-Json`;
                    }
                    const r = await runPs(cmd);
                    return { content: [{ type: 'text', text: (r.stdout || r.stderr).trim() }] };
                }
                case 'sysinfo_get_software': {
                    const nameFilter = a.name as string | undefined;
                    const paths = [
                        'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*',
                        'HKLM:\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\*',
                    ];
                    let cmd = `$p = @(${paths.map((p) => `'${p}'`).join(',')}); Get-ItemProperty $p -ErrorAction SilentlyContinue | Where-Object DisplayName | Select-Object DisplayName,DisplayVersion -First 300`;
                    if (nameFilter) cmd += ` | Where-Object DisplayName -like '*${escapeSingle(nameFilter)}*'`;
                    cmd += ' | ConvertTo-Json';
                    const r = await runPs(cmd);
                    return { content: [{ type: 'text', text: r.stdout || r.stderr }] };
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
