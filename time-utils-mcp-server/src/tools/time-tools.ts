/**
 * Time/date tools for the Time Utils MCP server.
 */

import type { Server } from '@modelcontextprotocol/sdk/server/index.js';
import {
    CallToolRequestSchema,
    ListToolsRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

const TOOLS = [
    {
        name: 'time_current',
        description: 'Get current date/time in ISO 8601 and Unix timestamp. Optionally specify a timezone (IANA, e.g. America/New_York).',
        inputSchema: {
            type: 'object' as const,
            properties: {
                timezone: { type: 'string', description: 'IANA timezone (e.g. UTC, America/New_York)' },
            },
        },
    },
    {
        name: 'time_format',
        description: 'Format a date/time string or Unix timestamp into a human-readable string.',
        inputSchema: {
            type: 'object' as const,
            properties: {
                input: { type: 'string', description: 'ISO 8601 date string or Unix timestamp (seconds)' },
                format: { type: 'string', description: 'Format: iso, locale, unix, relative' },
                timezone: { type: 'string', description: 'IANA timezone for output' },
            },
            required: ['input'],
        },
    },
    {
        name: 'time_list_timezones',
        description: 'List common IANA timezone identifiers (optionally filter by region).',
        inputSchema: {
            type: 'object' as const,
            properties: {
                region: { type: 'string', description: 'Filter by region prefix (e.g. America, Europe)' },
            },
        },
    },
];

export function registerTimeTools(server: Server): void {
    server.setRequestHandler(ListToolsRequestSchema, async () => ({
        tools: TOOLS,
    }));

    server.setRequestHandler(CallToolRequestSchema, async (request) => {
        const { name, arguments: args } = request.params;
        const a = (args as Record<string, unknown>) ?? {};

        try {
            switch (name) {
                case 'time_current': {
                    const tz = (a.timezone as string) ?? 'UTC';
                    const date = new Date();
                    const formatter = new Intl.DateTimeFormat('en-CA', {
                        timeZone: tz,
                        year: 'numeric',
                        month: '2-digit',
                        day: '2-digit',
                        hour: '2-digit',
                        minute: '2-digit',
                        second: '2-digit',
                        hour12: false,
                    });
                    const iso = date.toLocaleString('sv-SE', { timeZone: tz }).replace(' ', 'T') + 'Z';
                    const unix = Math.floor(date.getTime() / 1000);
                    const text = JSON.stringify(
                        { iso8601: iso, unixSeconds: unix, timezone: tz, formatted: formatter.format(date) },
                        null,
                        2
                    );
                    return { content: [{ type: 'text', text }] };
                }
                case 'time_format': {
                    const input = String(a.input ?? '');
                    const format = (a.format as string) ?? 'iso';
                    const tz = (a.timezone as string) ?? 'UTC';
                    let date: Date;
                    if (/^\d+$/.test(input.trim())) {
                        date = new Date(Number(input.trim()) * 1000);
                    } else {
                        date = new Date(input);
                    }
                    if (Number.isNaN(date.getTime())) {
                        return {
                            content: [{ type: 'text', text: `Invalid date input: ${input}` }],
                            isError: true,
                        };
                    }
                    let out: string;
                    if (format === 'unix') {
                        out = String(Math.floor(date.getTime() / 1000));
                    } else if (format === 'locale') {
                        out = date.toLocaleString(undefined, { timeZone: tz });
                    } else if (format === 'relative') {
                        const now = new Date();
                        const diffMs = date.getTime() - now.getTime();
                        const diffSec = Math.round(diffMs / 1000);
                        const diffMin = Math.round(diffSec / 60);
                        const diffHour = Math.round(diffMin / 60);
                        const diffDay = Math.round(diffHour / 24);
                        if (Math.abs(diffSec) < 60) out = `${diffSec} seconds`;
                        else if (Math.abs(diffMin) < 60) out = `${diffMin} minutes`;
                        else if (Math.abs(diffHour) < 24) out = `${diffHour} hours`;
                        else out = `${diffDay} days`;
                        out = (diffMs >= 0 ? 'in ' : '') + out + (diffMs < 0 ? ' ago' : '');
                    } else {
                        out = date.toISOString();
                    }
                    return { content: [{ type: 'text', text: out }] };
                }
                case 'time_list_timezones': {
                    const region = (a.region as string) ?? '';
                    const zones = Intl.supportedValuesOf('timeZone');
                    const filtered = region
                        ? zones.filter((z) => z.toLowerCase().startsWith(region.toLowerCase()))
                        : zones.slice(0, 80);
                    const text = JSON.stringify(filtered, null, 2);
                    return { content: [{ type: 'text', text }] };
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
