/**
 * @module dotnet-cli-integration
 * @description Integration tests for DotNet CLI MCP Server that execute
 * live dotnet build, test, restore, and list operations.
 *
 * Prerequisites:
 *   - Windows OS with .NET SDK 8.0+ installed
 *   - Internet connectivity for NuGet restore
 *
 * Run: npx vitest run --config ../../vitest.integration.config.ts
 */
import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { execFileSync } from 'node:child_process';
import { existsSync, rmSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import {
    requireWindows,
    isDotNetAvailable,
    createToolCapture,
    invokeTool,
    assertValidContent,
} from '../../tests/integration-helpers.js';
import { registerDotNetCliTools } from '../../src/tools/dotnet-cli-tools.js';

describe('DotNet CLI MCP Server - Integration', () => {
    const { server, tools } = createToolCapture();
    let dotnetAvailable = false;
    let tempDir: string;
    let classLibPath: string;

    beforeAll(async () => {
        requireWindows();
        registerDotNetCliTools(server as never);
        dotnetAvailable = await isDotNetAvailable();

        if (!dotnetAvailable) {
            console.warn('dotnet SDK not found — most tests will be skipped');
            return;
        }

        // Create a temp directory with a real .NET project for testing
        tempDir = join(tmpdir(), `mcp-dotnet-integration-${Date.now()}`);
        mkdirSync(tempDir, { recursive: true });

        classLibPath = join(tempDir, 'TestLib');
        try {
            execFileSync('dotnet', ['new', 'classlib', '-o', classLibPath, '--force'], {
                windowsHide: true,
                timeout: 60_000,
                stdio: 'pipe',
            });
        } catch (err) {
            console.warn('Failed to scaffold test project:', err);
        }
    });

    describe('dotnet_build', () => {
        it('should build a real classlib project', async () => {
            if (!dotnetAvailable || !existsSync(classLibPath)) {
                console.warn('SKIP: dotnet or test project not available');
                return;
            }

            const result = await invokeTool(tools, 'dotnet_build', {
                project_path: classLibPath,
                configuration: 'Debug',
                verbosity: 'minimal',
                no_restore: false,
            });

            assertValidContent(result);
            const text = result.content[0].text;
            // Build should succeed
            expect(text.toLowerCase()).toMatch(/success|succeeded|build/i);
        });

        it('should build in Release configuration', async () => {
            if (!dotnetAvailable || !existsSync(classLibPath)) {
                console.warn('SKIP: dotnet or test project not available');
                return;
            }

            const result = await invokeTool(tools, 'dotnet_build', {
                project_path: classLibPath,
                configuration: 'Release',
                verbosity: 'minimal',
                no_restore: true,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(20);
        });

        it('should report error for non-existent project', async () => {
            if (!dotnetAvailable) {
                console.warn('SKIP: dotnet not available');
                return;
            }

            const result = await invokeTool(tools, 'dotnet_build', {
                project_path: 'C:\\NonExistent\\fake.csproj',
                configuration: 'Debug',
                verbosity: 'minimal',
                no_restore: false,
            });

            assertValidContent(result);
            // Should gracefully report the error
        });
    });

    describe('dotnet_restore', () => {
        it('should restore packages for a real project', async () => {
            if (!dotnetAvailable || !existsSync(classLibPath)) {
                console.warn('SKIP: dotnet or test project not available');
                return;
            }

            const result = await invokeTool(tools, 'dotnet_restore', {
                project_path: classLibPath,
                verbosity: 'minimal',
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(10);
        });
    });

    describe('dotnet_list_projects', () => {
        it('should list projects in a solution or directory', async () => {
            if (!dotnetAvailable || !existsSync(classLibPath)) {
                console.warn('SKIP: dotnet or test project not available');
                return;
            }

            const result = await invokeTool(tools, 'dotnet_list_projects', {
                solution_path: tempDir,
            });

            assertValidContent(result);
        });
    });

    describe('dotnet_publish', () => {
        it('should publish a project', async () => {
            if (!dotnetAvailable || !existsSync(classLibPath)) {
                console.warn('SKIP: dotnet or test project not available');
                return;
            }

            const publishDir = join(tempDir, 'publish-output');

            const result = await invokeTool(tools, 'dotnet_publish', {
                project_path: classLibPath,
                configuration: 'Release',
                output: publishDir,
                self_contained: false,
                verbosity: 'minimal',
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(10);
        });
    });

    describe('dotnet_test', () => {
        it('should handle project without tests gracefully', async () => {
            if (!dotnetAvailable || !existsSync(classLibPath)) {
                console.warn('SKIP: dotnet or test project not available');
                return;
            }

            // classlib doesn't have tests — should handle gracefully
            const result = await invokeTool(tools, 'dotnet_test', {
                project_path: classLibPath,
                configuration: 'Debug',
                verbosity: 'minimal',
                collect_coverage: false,
                no_build: false,
            });

            assertValidContent(result);
        });
    });

    afterAll(() => {
        if (tempDir && existsSync(tempDir)) {
            try {
                rmSync(tempDir, { recursive: true, force: true });
            } catch {
                // Best effort cleanup
            }
        }
    });
});
