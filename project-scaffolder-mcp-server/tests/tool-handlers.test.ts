import { describe, it, expect, vi, beforeEach } from 'vitest';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { registerScaffolderTools } from '../src/tools/scaffolder-tools.js';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
type ToolHandler = (params: any) => Promise<{ content: Array<{ type: string; text: string }>; isError?: boolean }>;

function captureHandlers(server: McpServer): Map<string, ToolHandler> {
    const handlers = new Map<string, ToolHandler>();
    const spy = vi.spyOn(server, 'registerTool');
    registerScaffolderTools(server);
    for (const call of spy.mock.calls) {
        const name = call[0] as string;
        const handler = call[2] as ToolHandler;
        handlers.set(name, handler);
    }
    return handlers;
}

describe('Tool handler invocations', () => {
    let handlers: Map<string, ToolHandler>;

    beforeEach(() => {
        vi.clearAllMocks();
        const server = new McpServer({ name: 'test', version: '1.0.0' });
        handlers = captureHandlers(server);
    });

    // ── scaffold_ps_module ──────────────────────────────────────

    describe('scaffold_ps_module handler', () => {
        it('should generate PS module files', async () => {
            const handler = handlers.get('scaffold_ps_module')!;
            const result = await handler({
                moduleName: 'Better11.TestMod',
                description: 'Test module',
                author: 'Tester',
                version: '1.0.0',
                functions: [{
                    name: 'Get-TestInfo',
                    description: 'Gets test info',
                    parameters: [],
                    returnType: 'PSObject',
                    supportsShouldProcess: false,
                }],
                dependencies: [],
                tags: [],
                includeManifest: true,
                includeTests: true,
            });
            expect(result.content[0]!.text).toContain('✅');
            expect(result.content[0]!.text).toContain('Better11.TestMod');
            expect(result.isError).toBeUndefined();
        });

        it('should handle errors gracefully', async () => {
            const handler = handlers.get('scaffold_ps_module')!;
            const result = await handler({
                moduleName: '',
                description: '',
                functions: [],
            });
            // Functions expects min(1), so this may error in zod or template
            expect(result.content[0]!.text).toBeDefined();
        });
    });

    // ── scaffold_cs_viewmodel ───────────────────────────────────

    describe('scaffold_cs_viewmodel handler', () => {
        it('should generate ViewModel files', async () => {
            const handler = handlers.get('scaffold_cs_viewmodel')!;
            const result = await handler({
                className: 'TestViewModel',
                namespace: 'Better11',
                description: '',
                baseClass: 'ObservableObject',
                properties: [{ name: 'Status', type: 'string', isObservable: true, description: 'Status text' }],
                commands: [{ name: 'Refresh', isAsync: true, description: 'Refresh data' }],
                injectedServices: [],
                includeNavigation: false,
                includeValidation: false,
            });
            expect(result.content[0]!.text).toContain('✅');
            expect(result.content[0]!.text).toContain('TestViewModel');
        });

        it('should use className as default description', async () => {
            const handler = handlers.get('scaffold_cs_viewmodel')!;
            const result = await handler({
                className: 'MyVm',
                namespace: 'Better11',
                description: '',
                baseClass: 'ObservableObject',
                properties: [],
                commands: [],
                injectedServices: [],
                includeNavigation: false,
                includeValidation: false,
            });
            expect(result.content[0]!.text).toContain('✅');
        });
    });

    // ── scaffold_cs_service ─────────────────────────────────────

    describe('scaffold_cs_service handler', () => {
        it('should generate service + interface files', async () => {
            const handler = handlers.get('scaffold_cs_service')!;
            const result = await handler({
                className: 'TestService',
                interfaceName: 'ITestService',
                namespace: 'Better11',
                description: '',
                methods: [{
                    name: 'DoWork',
                    returnType: 'Task<bool>',
                    isAsync: true,
                    parameters: [],
                    description: 'Does work',
                }],
                injectedServices: [],
                lifetime: 'Singleton',
                includeLogging: true,
                includeTests: true,
            });
            expect(result.content[0]!.text).toContain('✅');
            expect(result.content[0]!.text).toContain('TestService');
            expect(result.content[0]!.text).toContain('ITestService');
        });

        it('should use className as default description', async () => {
            const handler = handlers.get('scaffold_cs_service')!;
            const result = await handler({
                className: 'Svc',
                interfaceName: 'ISvc',
                namespace: 'Better11',
                description: '',
                methods: [{ name: 'Run', returnType: 'void', isAsync: false, parameters: [], description: '' }],
                injectedServices: [],
                lifetime: 'Transient',
                includeLogging: false,
                includeTests: false,
            });
            expect(result.content[0]!.text).toContain('✅');
        });
    });

    // ── scaffold_readme ─────────────────────────────────────────

    describe('scaffold_readme handler', () => {
        it('should generate README.md', async () => {
            const handler = handlers.get('scaffold_readme')!;
            const result = await handler({
                projectName: 'TestProject',
                description: 'A test project',
                features: ['Feature A', 'Feature B'],
                prerequisites: ['Node.js'],
                installSteps: ['npm install'],
                usageExamples: ['node index.js'],
                author: 'Tester',
                license: 'MIT',
                badges: [{ label: 'version', value: '1.0', color: 'blue' }],
            });
            expect(result.content[0]!.text).toContain('✅');
            expect(result.content[0]!.text).toContain('README.md');
        });
    });

    // ── scaffold_changelog ──────────────────────────────────────

    describe('scaffold_changelog handler', () => {
        it('should generate CHANGELOG.md', async () => {
            const handler = handlers.get('scaffold_changelog')!;
            const result = await handler({
                projectName: 'TestProject',
                version: '1.0.0',
                date: '2025-01-01',
                added: ['Initial release'],
                changed: [],
                fixed: [],
                deprecated: [],
                removed: [],
            });
            expect(result.content[0]!.text).toContain('✅');
            expect(result.content[0]!.text).toContain('CHANGELOG.md');
        });
    });

    // ── scaffold_full_module ────────────────────────────────────

    describe('scaffold_full_module handler', () => {
        it('should generate full module with all layers', async () => {
            const handler = handlers.get('scaffold_full_module')!;
            const result = await handler({
                moduleName: 'DriverManager',
                description: 'Manages drivers',
                author: 'Tester',
                version: '1.0.0',
                psFunctions: [{
                    name: 'Get-Driver',
                    description: 'Gets drivers',
                    parameters: [],
                    returnType: 'PSObject',
                    supportsShouldProcess: false,
                }],
                psDependencies: [],
                vmProperties: [{ name: 'IsLoading', type: 'bool', isObservable: true, description: '' }],
                vmCommands: [{ name: 'LoadDrivers', isAsync: true, description: '' }],
                svcMethods: [{ name: 'GetAll', returnType: 'Task<List<Driver>>', isAsync: true, parameters: [], description: '' }],
                svcDependencies: [],
                includeReadme: true,
                includeChangelog: true,
            });
            expect(result.content[0]!.text).toContain('✅');
            expect(result.content[0]!.text).toContain('DriverManager');
        });

        it('should handle module with no PS functions', async () => {
            const handler = handlers.get('scaffold_full_module')!;
            const result = await handler({
                moduleName: 'SimpleModule',
                description: 'Simple',
                author: 'Tester',
                version: '1.0.0',
                psFunctions: [],
                psDependencies: [],
                vmProperties: [],
                vmCommands: [],
                svcMethods: [],
                svcDependencies: [],
                includeReadme: false,
                includeChangelog: false,
            });
            expect(result.content[0]!.text).toContain('✅');
        });
    });

    // ── scaffold_validate_name ──────────────────────────────────

    describe('scaffold_validate_name handler', () => {
        it('should validate PS function name', async () => {
            const handler = handlers.get('scaffold_validate_name')!;
            const result = await handler({ name: 'GetSystemInfo', nameType: 'ps-function' });
            expect(result.content[0]!.text).toContain('✅');
            expect(result.content[0]!.text).toContain('PascalCase');
        });

        it('should validate C# class name', async () => {
            const handler = handlers.get('scaffold_validate_name')!;
            const result = await handler({ name: 'DriverManager', nameType: 'cs-class' });
            expect(result.content[0]!.text).toContain('✅');
        });

        it('should report issues for invalid names', async () => {
            const handler = handlers.get('scaffold_validate_name')!;
            const result = await handler({ name: 'class', nameType: 'cs-class' });
            expect(result.content[0]!.text).toContain('❌');
            expect(result.content[0]!.text).toContain('Error');
        });
    });

    // ── scaffold_list_templates ─────────────────────────────────

    describe('scaffold_list_templates handler', () => {
        it('should list all templates', async () => {
            const handler = handlers.get('scaffold_list_templates')!;
            const result = await handler({ category: 'all' });
            expect(result.content[0]!.text).toContain('Available Templates (6)');
            expect(result.content[0]!.text).toContain('scaffold_ps_module');
            expect(result.content[0]!.text).toContain('scaffold_cs_viewmodel');
            expect(result.content[0]!.text).toContain('scaffold_full_module');
        });

        it('should filter by category', async () => {
            const handler = handlers.get('scaffold_list_templates')!;
            const result = await handler({ category: 'powershell' });
            expect(result.content[0]!.text).toContain('Available Templates (1)');
            expect(result.content[0]!.text).toContain('PowerShell Module');
        });

        it('should filter documentation category', async () => {
            const handler = handlers.get('scaffold_list_templates')!;
            const result = await handler({ category: 'documentation' });
            expect(result.content[0]!.text).toContain('Available Templates (2)');
        });

        it('should filter composite category', async () => {
            const handler = handlers.get('scaffold_list_templates')!;
            const result = await handler({ category: 'composite' });
            expect(result.content[0]!.text).toContain('Available Templates (1)');
        });
    });
});
