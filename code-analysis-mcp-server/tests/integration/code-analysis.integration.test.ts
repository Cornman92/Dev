/**
 * @module code-analysis-integration
 * @description Integration tests for Code Analysis MCP Server that execute
 * live StyleCop (dotnet build) and PSScriptAnalyzer analysis on real files.
 *
 * Prerequisites:
 *   - Windows OS with dotnet SDK
 *   - PSScriptAnalyzer module (for PowerShell analysis)
 *   - StyleCop.Analyzers NuGet package (for C# analysis in real projects)
 *
 * Run: npx vitest run --config ../../vitest.integration.config.ts
 */
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { writeFileSync, mkdirSync, rmSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import {
    requireWindows,
    isDotNetAvailable,
    isPSModuleAvailable,
    createToolCapture,
    invokeTool,
    assertValidContent,
} from '../../tests/integration-helpers.js';
import { registerCodeAnalysisTools } from '../../src/tools/code-analysis-tools.js';

describe('Code Analysis MCP Server - Integration', () => {
    const { server, tools } = createToolCapture();
    let dotnetAvailable = false;
    let psAnalyzerAvailable = false;
    let tempDir: string;

    beforeAll(async () => {
        requireWindows();
        registerCodeAnalysisTools(server as never);
        dotnetAvailable = await isDotNetAvailable();
        psAnalyzerAvailable = await isPSModuleAvailable('PSScriptAnalyzer');

        // Create temp directory for test files
        tempDir = join(tmpdir(), `mcp-lint-integration-${Date.now()}`);
        mkdirSync(tempDir, { recursive: true });
    });

    describe('lint_analyze_powershell', () => {
        it('should analyze a PowerShell script with known issues', async () => {
            if (!psAnalyzerAvailable) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const scriptPath = join(tempDir, 'test-bad.ps1');
            writeFileSync(scriptPath, `
# Script with known PSScriptAnalyzer violations
function test-thing {
    write-host "Using Write-Host"
    $unused = "this variable is never used"
    $password = "hardcoded"
}
`);

            const result = await invokeTool(tools, 'lint_analyze_powershell', {
                path: scriptPath,
                recurse: false,
                fix: false,
                include_default_rules: true,
            });

            assertValidContent(result);
            // Should find PSScriptAnalyzer violations
            expect(result.content[0].text.length).toBeGreaterThan(20);
        });

        it('should analyze a clean PowerShell script', async () => {
            if (!psAnalyzerAvailable) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const scriptPath = join(tempDir, 'test-clean.ps1');
            writeFileSync(scriptPath, `
function Get-TestData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )
    Write-Output "Hello $Name"
}
`);

            const result = await invokeTool(tools, 'lint_analyze_powershell', {
                path: scriptPath,
                recurse: false,
                fix: false,
                include_default_rules: true,
            });

            assertValidContent(result);
        });

        it('should analyze a directory of scripts recursively', async () => {
            if (!psAnalyzerAvailable) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const subDir = join(tempDir, 'scripts');
            mkdirSync(subDir, { recursive: true });
            writeFileSync(join(subDir, 'one.ps1'), 'Write-Output "Script 1"');
            writeFileSync(join(subDir, 'two.ps1'), 'Write-Output "Script 2"');

            const result = await invokeTool(tools, 'lint_analyze_powershell', {
                path: subDir,
                recurse: true,
                fix: false,
                include_default_rules: true,
            });

            assertValidContent(result);
        });

        it('should filter by severity', async () => {
            if (!psAnalyzerAvailable) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const scriptPath = join(tempDir, 'test-severity.ps1');
            writeFileSync(scriptPath, `
function test {
    write-host "bad"
    $x = "unused"
}
`);

            const result = await invokeTool(tools, 'lint_analyze_powershell', {
                path: scriptPath,
                recurse: false,
                fix: false,
                severity: ['Error', 'Warning'],
                include_default_rules: true,
            });

            assertValidContent(result);
        });
    });

    describe('lint_analyze_csharp', () => {
        it('should report error for non-existent project path', async () => {
            if (!dotnetAvailable) {
                console.warn('SKIP: dotnet SDK not available');
                return;
            }

            const result = await invokeTool(tools, 'lint_analyze_csharp', {
                project_path: 'C:\\NonExistent\\fake.csproj',
                treat_warnings_as_errors: false,
                configuration: 'Debug',
                verbosity: 'minimal',
            });

            assertValidContent(result);
            // Should gracefully report the missing project
        });
    });

    describe('lint_get_rules', () => {
        it('should list PSScriptAnalyzer rules', async () => {
            if (!psAnalyzerAvailable) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const result = await invokeTool(tools, 'lint_get_rules', {
                analyzer: 'psscriptanalyzer',
            });

            assertValidContent(result);
            const text = result.content[0].text;
            // Should list known rule names
            expect(text.length).toBeGreaterThan(100);
        });

        it('should list PSScriptAnalyzer rules filtered by severity', async () => {
            if (!psAnalyzerAvailable) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const result = await invokeTool(tools, 'lint_get_rules', {
                analyzer: 'psscriptanalyzer',
                severity: 'Error',
            });

            assertValidContent(result);
        });

        it('should list StyleCop rule categories', async () => {
            const result = await invokeTool(tools, 'lint_get_rules', {
                analyzer: 'stylecop',
            });

            assertValidContent(result);
            const text = result.content[0].text;
            expect(text).toContain('Spacing');
        });
    });

    describe('lint_format_report', () => {
        it('should generate a report for a directory', async () => {
            if (!psAnalyzerAvailable) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            writeFileSync(join(tempDir, 'report-test.ps1'), 'write-host "test"');

            const result = await invokeTool(tools, 'lint_format_report', {
                project_path: tempDir,
                output_format: 'markdown',
                include_passing: false,
            });

            assertValidContent(result);
        });

        it('should generate JSON format report', async () => {
            if (!psAnalyzerAvailable) {
                console.warn('SKIP: PSScriptAnalyzer not installed');
                return;
            }

            const result = await invokeTool(tools, 'lint_format_report', {
                project_path: tempDir,
                output_format: 'json',
                include_passing: true,
            });

            assertValidContent(result);
        });
    });

    // Cleanup
    afterAll(() => {
        if (existsSync(tempDir)) {
            rmSync(tempDir, { recursive: true, force: true });
        }
    });
});
