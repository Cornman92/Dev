import { describe, it, expect, vi, beforeEach } from 'vitest';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { registerScaffolderTools } from '../src/tools/scaffolder-tools.js';

describe('registerScaffolderTools', () => {
    let server: McpServer;

    beforeEach(() => {
        vi.clearAllMocks();
        server = new McpServer({ name: 'test', version: '1.0.0' });
    });

    it('should register all 8 tools without throwing', () => {
        expect(() => registerScaffolderTools(server)).not.toThrow();
    });

    it('should register tools with expected names', () => {
        const registerSpy = vi.spyOn(server, 'registerTool');
        registerScaffolderTools(server);

        const toolNames = registerSpy.mock.calls.map(call => call[0]);
        expect(toolNames).toContain('scaffold_ps_module');
        expect(toolNames).toContain('scaffold_cs_viewmodel');
        expect(toolNames).toContain('scaffold_cs_service');
        expect(toolNames).toContain('scaffold_readme');
        expect(toolNames).toContain('scaffold_changelog');
        expect(toolNames).toContain('scaffold_full_module');
        expect(toolNames).toContain('scaffold_validate_name');
        expect(toolNames).toContain('scaffold_list_templates');
        expect(toolNames).toHaveLength(8);
    });

    it('should mark all tools as readOnly', () => {
        const registerSpy = vi.spyOn(server, 'registerTool');
        registerScaffolderTools(server);

        for (const call of registerSpy.mock.calls) {
            const meta = call[1] as Record<string, unknown>;
            const annotations = meta.annotations as Record<string, boolean>;
            expect(annotations.readOnlyHint, `${call[0]} should be readOnly`).toBe(true);
        }
    });

    it('should not mark any tools as destructive', () => {
        const registerSpy = vi.spyOn(server, 'registerTool');
        registerScaffolderTools(server);

        for (const call of registerSpy.mock.calls) {
            const meta = call[1] as Record<string, unknown>;
            const annotations = meta.annotations as Record<string, boolean>;
            expect(annotations.destructiveHint).toBeFalsy();
        }
    });
});
