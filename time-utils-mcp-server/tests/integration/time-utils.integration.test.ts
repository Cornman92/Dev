/**
 * Integration tests for Time Utils MCP Server.
 * Run: npx vitest run --config vitest.integration.config.ts
 */
import { describe, it, expect, beforeAll } from 'vitest';
import {
    createToolCapture,
    invokeTool,
    assertValidContent,
} from '../../tests/integration-helpers.js';
import { registerTimeTools } from '../../src/tools/time-tools.js';
import type { Server } from '@modelcontextprotocol/sdk/server/index.js';

describe('Time Utils MCP Server - Integration', () => {
    const { server, tools } = createToolCapture();

    beforeAll(() => {
        registerTimeTools(server as unknown as Server);
    });

    describe('time_current', () => {
        it('should return current time in ISO and Unix', async () => {
            const result = await invokeTool(tools, 'time_current', {});

            assertValidContent(result);
            const text = result.content[0].text;
            const parsed = JSON.parse(text);
            expect(parsed).toHaveProperty('iso8601');
            expect(parsed).toHaveProperty('unixSeconds');
            expect(parsed.unixSeconds).toBeGreaterThan(0);
        });

        it('should accept timezone parameter', async () => {
            const result = await invokeTool(tools, 'time_current', {
                timezone: 'America/New_York',
            });

            assertValidContent(result);
            const parsed = JSON.parse(result.content[0].text);
            expect(parsed.timezone).toBe('America/New_York');
        });
    });

    describe('time_format', () => {
        it('should format ISO string', async () => {
            const result = await invokeTool(tools, 'time_format', {
                input: '2025-03-01T12:00:00Z',
                format: 'iso',
            });

            assertValidContent(result);
            expect(result.content[0].text).toContain('2025');
        });

        it('should format Unix timestamp', async () => {
            const result = await invokeTool(tools, 'time_format', {
                input: '1730376000',
                format: 'unix',
            });

            assertValidContent(result);
            expect(result.content[0].text).toBe('1730376000');
        });

        it('should return error for invalid input', async () => {
            const result = await invokeTool(tools, 'time_format', {
                input: 'not-a-date',
            });

            expect(result.isError).toBe(true);
            expect(result.content[0].text).toContain('Invalid');
        });
    });

    describe('time_list_timezones', () => {
        it('should list timezones', async () => {
            const result = await invokeTool(tools, 'time_list_timezones', {});

            assertValidContent(result);
            const arr = JSON.parse(result.content[0].text);
            expect(Array.isArray(arr)).toBe(true);
            expect(arr.length).toBeGreaterThan(0);
        });

        it('should filter by region', async () => {
            const result = await invokeTool(tools, 'time_list_timezones', {
                region: 'America',
            });

            assertValidContent(result);
            const arr = JSON.parse(result.content[0].text);
            expect(arr.every((z: string) => z.startsWith('America'))).toBe(true);
        });
    });
});
