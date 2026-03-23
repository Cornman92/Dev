/**
 * @module system-info-integration
 * @description Integration tests for System Info MCP Server that execute
 * live WMI/CIM queries and registry reads on the local Windows machine.
 *
 * Prerequisites:
 *   - Windows OS with WMI/CIM subsystem available
 *   - Standard user permissions (no admin required for read-only)
 *
 * Run: npx vitest run --config ../../vitest.integration.config.ts
 */
import { describe, it, expect, beforeAll } from 'vitest';
import {
    requireWindows,
    createToolCapture,
    invokeTool,
    assertValidContent,
} from '../../tests/integration-helpers.js';
import { registerSystemInfoTools } from '../../src/tools/system-info-tools.js';

describe('System Info MCP Server - Integration', () => {
    const { server, tools } = createToolCapture();

    beforeAll(() => {
        requireWindows();
        registerSystemInfoTools(server as never);
    });

    describe('sysinfo_get_system', () => {
        it('should return comprehensive system information', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_system', {
                categories: ['os', 'hardware', 'network'],
            });

            assertValidContent(result);
            const text = result.content[0].text;
            // OS info should contain Windows version
            expect(text.toLowerCase()).toMatch(/windows/i);
        });

        it('should return OS information only', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_system', {
                categories: ['os'],
            });

            assertValidContent(result);
            const text = result.content[0].text;
            expect(text.length).toBeGreaterThan(50);
        });

        it('should return hardware information', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_system', {
                categories: ['hardware'],
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(50);
        });

        it('should return all categories when requested', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_system', {
                categories: ['os', 'hardware', 'memory', 'disk', 'network'],
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(200);
        });
    });

    describe('sysinfo_query_wmi', () => {
        it('should query Win32_OperatingSystem', async () => {
            const result = await invokeTool(tools, 'sysinfo_query_wmi', {
                class_name: 'Win32_OperatingSystem',
                properties: ['Caption', 'Version', 'BuildNumber', 'OSArchitecture'],
            });

            assertValidContent(result);
            const text = result.content[0].text;
            expect(text).toMatch(/windows/i);
        });

        it('should query Win32_Processor', async () => {
            const result = await invokeTool(tools, 'sysinfo_query_wmi', {
                class_name: 'Win32_Processor',
                properties: ['Name', 'NumberOfCores', 'NumberOfLogicalProcessors', 'MaxClockSpeed'],
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(20);
        });

        it('should query Win32_PhysicalMemory', async () => {
            const result = await invokeTool(tools, 'sysinfo_query_wmi', {
                class_name: 'Win32_PhysicalMemory',
                properties: ['Capacity', 'Speed', 'Manufacturer'],
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(10);
        });

        it('should query Win32_LogicalDisk with filter', async () => {
            const result = await invokeTool(tools, 'sysinfo_query_wmi', {
                class_name: 'Win32_LogicalDisk',
                properties: ['DeviceID', 'Size', 'FreeSpace', 'FileSystem'],
                filter: "DriveType=3",
            });

            assertValidContent(result);
            expect(result.content[0].text).toContain('C:');
        });

        it('should query Win32_NetworkAdapterConfiguration', async () => {
            const result = await invokeTool(tools, 'sysinfo_query_wmi', {
                class_name: 'Win32_NetworkAdapterConfiguration',
                properties: ['Description', 'IPAddress', 'MACAddress'],
                filter: "IPEnabled=True",
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(10);
        });

        it('should handle non-existent WMI class gracefully', async () => {
            const result = await invokeTool(tools, 'sysinfo_query_wmi', {
                class_name: 'Win32_FakeClass_DoesNotExist',
                properties: ['Name'],
            });

            assertValidContent(result);
            // Should return error info without crashing
        });
    });

    describe('sysinfo_get_services', () => {
        it('should list running services', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_services', {
                status: 'Running',
            });

            assertValidContent(result);
            const text = result.content[0].text.toLowerCase();
            // Should find at least some core Windows services
            expect(text.length).toBeGreaterThan(100);
        });

        it('should find a specific service by name', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_services', {
                name: 'WinRM',
            });

            assertValidContent(result);
            expect(result.content[0].text.toLowerCase()).toContain('winrm');
        });

        it('should list stopped services', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_services', {
                status: 'Stopped',
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(50);
        });
    });

    describe('sysinfo_get_drivers', () => {
        it('should list system drivers', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_drivers', {});

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(100);
        });

        it('should list signed drivers only', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_drivers', {
                signed_only: true,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(50);
        });
    });

    describe('sysinfo_query_registry', () => {
        it('should read HKLM\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion', async () => {
            const result = await invokeTool(tools, 'sysinfo_query_registry', {
                path: 'HKLM:\\SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion',
                value_name: 'ProductName',
            });

            assertValidContent(result);
            expect(result.content[0].text.toLowerCase()).toMatch(/windows/i);
        });

        it('should enumerate registry subkeys', async () => {
            const result = await invokeTool(tools, 'sysinfo_query_registry', {
                path: 'HKLM:\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion',
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(50);
        });

        it('should handle non-existent registry path gracefully', async () => {
            const result = await invokeTool(tools, 'sysinfo_query_registry', {
                path: 'HKLM:\\SOFTWARE\\NonExistent_IntegrationTest_Path_12345',
            });

            assertValidContent(result);
            // Should return error info without crashing
        });
    });

    describe('sysinfo_get_software', () => {
        it('should list installed software', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_software', {});

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(100);
        });

        it('should filter software by name pattern', async () => {
            const result = await invokeTool(tools, 'sysinfo_get_software', {
                name: 'Microsoft',
            });

            assertValidContent(result);
            expect(result.content[0].text.toLowerCase()).toContain('microsoft');
        });
    });
});
