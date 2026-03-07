/**
 * @module nuget-integration
 * @description Integration tests for NuGet MCP Server that execute
 * live NuGet V3 API queries and dotnet CLI operations.
 *
 * Prerequisites:
 *   - Windows OS with dotnet SDK installed
 *   - Internet connectivity for NuGet API calls
 *
 * Run: npx vitest run --config ../../vitest.integration.config.ts
 */
import { describe, it, expect, beforeAll } from 'vitest';
import {
    requireWindows,
    isDotNetAvailable,
    createToolCapture,
    invokeTool,
    assertValidContent,
} from '../../tests/integration-helpers.js';
import { registerNuGetTools } from '../../src/tools/nuget-tools.js';

describe('NuGet MCP Server - Integration', () => {
    const { server, tools } = createToolCapture();
    let dotnetAvailable = false;

    beforeAll(async () => {
        requireWindows();
        registerNuGetTools(server as never);
        dotnetAvailable = await isDotNetAvailable();
    });

    describe('nuget_search', () => {
        it('should search for popular packages by name', async () => {
            const result = await invokeTool(tools, 'nuget_search', {
                query: 'Newtonsoft.Json',
                include_prerelease: false,
                max_results: 5,
            });

            assertValidContent(result);
            expect(result.content[0].text.toLowerCase()).toContain('newtonsoft');
        });

        it('should search for packages with prerelease', async () => {
            const result = await invokeTool(tools, 'nuget_search', {
                query: 'System.Text.Json',
                include_prerelease: true,
                max_results: 10,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(20);
        });

        it('should return limited results when max_results is small', async () => {
            const result = await invokeTool(tools, 'nuget_search', {
                query: 'Microsoft',
                include_prerelease: false,
                max_results: 3,
            });

            assertValidContent(result);
            expect(result.content[0].text.length).toBeGreaterThan(10);
        });

        it('should handle obscure search terms gracefully', async () => {
            const result = await invokeTool(tools, 'nuget_search', {
                query: 'zzz_nonexistent_package_integration_test_12345',
                include_prerelease: false,
                max_results: 5,
            });

            assertValidContent(result);
        });
    });

    describe('nuget_get_package', () => {
        it('should get details for Newtonsoft.Json', async () => {
            const result = await invokeTool(tools, 'nuget_get_package', {
                package_id: 'Newtonsoft.Json',
                include_versions: false,
            });

            assertValidContent(result);
            expect(result.content[0].text.toLowerCase()).toContain('newtonsoft');
        });

        it('should list versions for a package', async () => {
            const result = await invokeTool(tools, 'nuget_get_package', {
                package_id: 'Newtonsoft.Json',
                include_versions: true,
            });

            assertValidContent(result);
            // Should contain version numbers
            expect(result.content[0].text).toMatch(/\d+\.\d+/);
        });

        it('should handle non-existent package gracefully', async () => {
            const result = await invokeTool(tools, 'nuget_get_package', {
                package_id: 'ZZZ.NonExistent.Package.IntegrationTest.12345',
                include_versions: false,
            });

            assertValidContent(result);
        });
    });

    describe('nuget_compare_versions', () => {
        it('should compare two versions of Newtonsoft.Json', async () => {
            const result = await invokeTool(tools, 'nuget_compare_versions', {
                package_id: 'Newtonsoft.Json',
                version_a: '12.0.3',
                version_b: '13.0.3',
            });

            assertValidContent(result);
            const text = result.content[0].text;
            expect(text).toContain('12.0.3');
            expect(text).toContain('13.0.3');
        });
    });

    describe('nuget_list_installed (requires dotnet project)', () => {
        it('should attempt to list packages in a non-existent project gracefully', async () => {
            if (!dotnetAvailable) {
                console.warn('SKIP: dotnet SDK not available');
                return;
            }

            const result = await invokeTool(tools, 'nuget_list_installed', {
                project_path: 'C:\\NonExistentProject\\test.csproj',
                include_transitive: false,
            });

            assertValidContent(result);
            // Should return error info about missing project
        });
    });

    describe('nuget_check_updates (requires dotnet project)', () => {
        it('should attempt to check updates for non-existent project gracefully', async () => {
            if (!dotnetAvailable) {
                console.warn('SKIP: dotnet SDK not available');
                return;
            }

            const result = await invokeTool(tools, 'nuget_check_updates', {
                project_path: 'C:\\NonExistentProject\\test.csproj',
                include_prerelease: false,
            });

            assertValidContent(result);
        });
    });
});
