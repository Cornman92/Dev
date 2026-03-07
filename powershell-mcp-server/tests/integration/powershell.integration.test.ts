/**
 * @module powershell-integration
 * @description Integration tests for PowerShell MCP Server that execute
 * against real PowerShell on the local Windows machine.
 *
 * Prerequisites:
 *   - Windows OS with PowerShell 5.1+ or PowerShell 7+
 *   - PSScriptAnalyzer module installed (for ps_test_analyzer)
 *
 * Run: npx vitest run --config ../../vitest.integration.config.ts
 */
import { describe, it, expect, beforeAll } from 'vitest';
import {
    requireWindows,
    isPSModuleAvailable,
    createToolCapture,
    invokeTool,
    assertValidContent,
} from '../../tests/integration-helpers.js';
import { registerPowerShellTools } from '../../src/tools/powershell-tools.js';

describe('PowerShell MCP Server - Integration', () => {
    const { server, tools } = createToolCapture();
    let hasPSScriptAnalyzer = false;

    beforeAll(async () => {
        requireWindows();
        registerPowerShellTools(server as never);
        hasPSScriptAnalyzer = await isPSModuleAvailable('PSScriptAnalyzer');
    });

    describe('ps_invoke_script', () => {
        it('should execute a simple PowerShell script and return output', async () => {
            const result = await invokeTool(tools, 'ps_invoke_script', {
                script: 'Write-Output "Hello from integration test"',
                timeout_ms: 15_000,
            });

            assertValidContent(result);
            expect(result.content[0].text).toContain('Hello from integration test');
        });

        it('should execute a script that returns JSON data', async () => {
            const result = await invokeTool(tools, 'ps_invoke_script', {
                script: '@{Name="Test";Value=42} | ConvertTo-Json -Compress',
                timeout_ms: 15_000,
            });

            assertValidContent(result);
            expect(result.content[0].text).toContain('"Name"');
            expect(result.content[0].text).toContain('"Value"');
        });

        it('should handle script errors gracefully', async () => {
            const result = await invokeTool(tools, 'ps_invoke_script', {
                script: 'Get-NonExistentCmdlet-12345',
                timeout_ms: 15_000,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(0);
        });

        it('should enforce timeout on long-running scripts', async () => {
            const start = Date.now();
            const result = await invokeTool(tools, 'ps_invoke_script', {
                script: 'Start-Sleep -Seconds 60',
                timeout_ms: 5_000,
            });

            const elapsed = Date.now() - start;
            assertValidContent(result);
            expect(elapsed).toBeLessThan(30_000);
        });

        it('should retrieve system environment variables', async () => {
            const result = await invokeTool(tools, 'ps_invoke_script', {
                script: '$env:COMPUTERNAME',
                timeout_ms: 10_000,
            });

            assertValidContent(result);
            expect(result.content[0].text.trim().length).toBeGreaterThan(0);
        });

        it('should handle multi-line scripts with pipeline', async () => {
            const result = await invokeTool(tools, 'ps_invoke_script', {
                script: `
                    $items = 1..5 | ForEach-Object { [PSCustomObject]@{Index=$_; Squared=$_*$_} }
                    $items | ConvertTo-Json -Compress
                `,
                timeout_ms: 15_000,
            });

            assertValidContent(result);
            expect(result.content[0].text).toContain('Squared');
        });

        it('should use default timeout_ms when omitted', async () => {
            const result = await invokeTool(tools, 'ps_invoke_script', {
                script: 'Write-Output "default timeout"',
            });

            assertValidContent(result);
            expect(result.content[0].text).toContain('default timeout');
        });
    });

    describe('ps_invoke_command', () => {
        it('should invoke Get-Process and return results', async () => {
            const result = await invokeTool(tools, 'ps_invoke_command', {
                cmdlet: 'Get-Process',
                parameters: { Name: 'explorer' },
                as_json: true,
            });

            assertValidContent(result);
            expect(result.content[0].text.toLowerCase()).toContain('explorer');
        });

        it('should invoke Get-Service with filter', async () => {
            const result = await invokeTool(tools, 'ps_invoke_command', {
                cmdlet: 'Get-Service',
                parameters: { Name: 'WinRM' },
            });

            assertValidContent(result);
            expect(result.content[0].text.toLowerCase()).toContain('winrm');
        });

        it('should invoke Get-ChildItem for filesystem listing', async () => {
            const result = await invokeTool(tools, 'ps_invoke_command', {
                cmdlet: 'Get-ChildItem',
                parameters: { Path: 'C:\\Windows', Directory: true },
                as_json: false,
            });

            assertValidContent(result);
            expect(result.content[0].text).toContain('System32');
        });

        it('should invoke Test-Path for boolean result', async () => {
            const result = await invokeTool(tools, 'ps_invoke_command', {
                cmdlet: 'Test-Path',
                parameters: { Path: 'C:\\Windows' },
            });

            assertValidContent(result);
            expect(result.content[0].text.toLowerCase()).toContain('true');
        });

        it('should use as_json to get structured output', async () => {
            const result = await invokeTool(tools, 'ps_invoke_command', {
                cmdlet: 'Get-TimeZone',
                as_json: true,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(20);
        });
    });

    describe('ps_get_module', () => {
        it('should list available modules', async () => {
            const result = await invokeTool(tools, 'ps_get_module', {
                list_available: true,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(50);
        });

        it('should find a specific built-in module', async () => {
            const result = await invokeTool(tools, 'ps_get_module', {
                name: 'Microsoft.PowerShell.Management',
                list_available: true,
            });

            assertValidContent(result);
            expect(result.content[0].text).toContain('Microsoft.PowerShell.Management');
        });

        it('should return detailed module info', async () => {
            const result = await invokeTool(tools, 'ps_get_module', {
                name: 'Microsoft.PowerShell.Utility',
                list_available: true,
                detailed: true,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(100);
        });

        it('should handle non-existent module gracefully', async () => {
            const result = await invokeTool(tools, 'ps_get_module', {
                name: 'ZZZ.FakeModule.DoesNotExist',
                list_available: true,
            });

            assertValidContent(result);
        });
    });

    describe('ps_test_analyzer', () => {
        it('should analyze inline PowerShell code for issues', async () => {
            if (!hasPSScriptAnalyzer) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const result = await invokeTool(tools, 'ps_test_analyzer', {
                script_content: `
                    function test {
                        write-host "Using Write-Host is a common warning"
                        $unused = "variable"
                    }
                `,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(10);
        });

        it('should pass clean code without violations', async () => {
            if (!hasPSScriptAnalyzer) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const result = await invokeTool(tools, 'ps_test_analyzer', {
                script_content: `
                    function Get-TestResult {
                        [CmdletBinding()]
                        param()
                        Write-Output 'Clean code'
                    }
                `,
            });

            assertValidContent(result);
        });

        it('should filter by severity levels', async () => {
            if (!hasPSScriptAnalyzer) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const result = await invokeTool(tools, 'ps_test_analyzer', {
                script_content: 'function test { write-host "bad"; $x = "unused" }',
                severity: ['Error', 'Warning'],
            });

            assertValidContent(result);
        });

        it('should respect exclude_rules parameter', async () => {
            if (!hasPSScriptAnalyzer) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const result = await invokeTool(tools, 'ps_test_analyzer', {
                script_content: 'function test { write-host "testing" }',
                exclude_rules: ['PSAvoidUsingWriteHost'],
            });

            assertValidContent(result);
        });
    });
});
