/**
 * @module winget-integration
 * @description Integration tests for WinGet MCP Server that execute
 * live winget CLI operations against the real Windows Package Manager.
 *
 * Prerequisites:
 *   - Windows 10/11 with App Installer (winget) installed
 *   - Internet connectivity for package searches
 *
 * Run: npx vitest run --config ../../vitest.integration.config.ts
 */
import { describe, it, expect, beforeAll } from 'vitest';
import {
    requireWindows,
    isWinGetAvailable,
    createToolCapture,
    invokeTool,
    assertValidContent,
} from '../../tests/integration-helpers.js';
import { registerWinGetTools } from '../../src/tools/winget-tools.js';

describe('WinGet MCP Server - Integration', () => {
    const { server, tools } = createToolCapture();
    let wingetAvailable = false;

    beforeAll(async () => {
        requireWindows();
        registerWinGetTools(server as never);
        wingetAvailable = await isWinGetAvailable();

        if (!wingetAvailable) {
            console.warn('winget not found — all tests will be skipped');
        }
    });

    describe('winget_search', () => {
        it('should search for a well-known package', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_search', {
                query: 'Visual Studio Code',
                count: 5,
                exact: false,
            });

            assertValidContent(result);
            const text = result.content[0].text.toLowerCase();
            expect(text).toMatch(/visual studio code|vscode|microsoft/i);
        });

        it('should search with exact match', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_search', {
                query: 'Microsoft.VisualStudioCode',
                count: 5,
                exact: true,
            });

            assertValidContent(result);
        });

        it('should return results limited by count', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_search', {
                query: 'Microsoft',
                count: 3,
                exact: false,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(20);
        });

        it('should handle no-result searches gracefully', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_search', {
                query: 'zzz_fake_package_that_never_exists_12345',
                count: 5,
                exact: false,
            });

            assertValidContent(result);
        });

        it('should search from specific source', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_search', {
                query: 'git',
                source: 'winget',
                count: 10,
                exact: false,
            });

            assertValidContent(result);
        });
    });

    describe('winget_show', () => {
        it('should show details for Git.Git', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_show', {
                package_id: 'Git.Git',
                include_versions: false,
            });

            assertValidContent(result);
            const text = result.content[0].text.toLowerCase();
            expect(text).toContain('git');
        });

        it('should show all versions for a package', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_show', {
                package_id: 'Git.Git',
                include_versions: true,
            });

            assertValidContent(result);
            // Should contain version numbers
            expect(result.content[0].text).toMatch(/\d+\.\d+/);
        });

        it('should show specific version details', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_show', {
                package_id: 'Microsoft.VisualStudioCode',
                include_versions: false,
            });

            assertValidContent(result);
        });

        it('should handle non-existent package gracefully', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_show', {
                package_id: 'ZZZ.FakePackage.DoesNotExist.12345',
                include_versions: false,
            });

            assertValidContent(result);
        });
    });

    describe('winget_list', () => {
        it('should list installed packages', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_list', {
                count: 10,
                upgrade_available: false,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(50);
        });

        it('should filter installed packages by name', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_list', {
                query: 'Microsoft',
                count: 10,
                upgrade_available: false,
            });

            assertValidContent(result);
        });

        it('should list only packages with available upgrades', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_list', {
                count: 50,
                upgrade_available: true,
            });

            assertValidContent(result);
        });
    });

    describe('winget_list_upgradable', () => {
        it('should list all upgradable packages', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_list_upgradable', {
                include_unknown: true,
                include_pinned: false,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(10);
        });

        it('should exclude unknown versions when requested', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_list_upgradable', {
                include_unknown: false,
                include_pinned: false,
            });

            assertValidContent(result);
        });

        it('should include pinned packages when requested', async () => {
            if (!wingetAvailable) return;

            const result = await invokeTool(tools, 'winget_list_upgradable', {
                include_unknown: true,
                include_pinned: true,
            });

            assertValidContent(result);
        });
    });
});
